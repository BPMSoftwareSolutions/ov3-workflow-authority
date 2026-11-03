// The Wildlife Collection demo's local server. It serves the web application and forwards every operation to the
// SideFX API as the user the sfx-api client is signed in as (sfx-api login), so each answer is a run of a capability
// declared in the estate, on the estate's wildlife store. The server stores nothing durable.
//   GET  /                         the web application (public/)
//   GET  /api/session              the SideFX session of the sfx-api client, and the capabilities the estate declares
//   GET  /api/labels?locale=en|es  the interface labels (presentation only; no estate data)
//   POST /api/run/<capability-id>  a run of that declared capability with {caller: the session, request: the body};
//                                  the run id comes back in the x-sfx-run-id header
// Responsiveness: a run costs the API about four seconds whatever the capability, so the server answers reads from the
// runs it already made. It makes the runs every screen needs at start, refreshes an answer older than FRESH_MS in the
// background while serving it, and after a write re-runs only the reads that write can change. Runs still go one at a
// time; a run someone is waiting for goes ahead of background ones.
//
// usage: node server.mjs    PORT (default 4310), SFX_API_CLIENT (default: the newest installed sfx-api.mjs),
//                           TIMING=1 to log each run's time
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { randomUUID } from "node:crypto";
import { fileURLToPath, pathToFileURL } from "node:url";
import { LABELS } from "./lib/labels.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT ?? 4310);
const PUBLIC = path.join(here, "public");
const MAX_BODY = 16 * 1024 * 1024;
const TYPES = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8",
  ".svg": "image/svg+xml", ".png": "image/png", ".ico": "image/x-icon" };
const CLIENT = process.env.SFX_API_CLIENT ?? (() => {
  const dir = path.join(process.env.LOCALAPPDATA || "", "sfx", "api-client");
  const found = fs.existsSync(dir) ? fs.readdirSync(dir).map((d) => path.join(dir, d, "sfx-api.mjs")).filter((f) => fs.existsSync(f))
    .sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs) : [];
  if (!found.length) throw new Error("sfx-api.mjs not found; install the SideFX API client or set SFX_API_CLIENT");
  return found[0];
})();
// The capabilities the estate declares for the wildlife application: the slice (flight 9810b9af and the runtime repairs),
// the photo view (plan sha256:aa443b90), catalog maintenance with section access (plan sha256:0442d1cb), and sign-up
// with sign-in through DNR (plan sha256:e9ca57d9); each stored document was read back exactly.
const DECLARED = new Set(["nerdery-browse-animal-collection", "nerdery-view-animal-definition", "nerdery-upload-encounter-photo",
  "nerdery-record-animal-encounter", "nerdery-view-collected-animals", "nerdery-view-collected-animal", "nerdery-set-animal-team",
  "nerdery-view-wildlife-home", "nerdery-add-animal-definition", "nerdery-update-animal-definition", "nerdery-remove-animal-definition",
  "nerdery-add-animal-attribute", "nerdery-update-animal-attribute", "nerdery-remove-animal-attribute", "nerdery-view-catalog-for-maintenance",
  "nerdery-resolve-wildlife-access", "nerdery-sign-in-wildlife-user", "nerdery-register-wildlife-user"]);
// Each write, and the reads whose answers it can change. A read not listed keeps its answer.
const CATALOG_READS = ["nerdery-browse-animal-collection", "nerdery-view-animal-definition", "nerdery-view-catalog-for-maintenance",
  "nerdery-view-collected-animals", "nerdery-view-collected-animal", "nerdery-view-wildlife-home"];
const WRITES = {
  "nerdery-upload-encounter-photo": [],
  "nerdery-record-animal-encounter": ["nerdery-view-collected-animals", "nerdery-browse-animal-collection", "nerdery-view-animal-definition"],
  "nerdery-set-animal-team": ["nerdery-view-wildlife-home"],
  "nerdery-add-animal-definition": CATALOG_READS, "nerdery-update-animal-definition": CATALOG_READS, "nerdery-remove-animal-definition": CATALOG_READS,
  "nerdery-add-animal-attribute": ["nerdery-view-catalog-for-maintenance", "nerdery-view-animal-definition"],
  "nerdery-update-animal-attribute": ["nerdery-view-catalog-for-maintenance", "nerdery-view-animal-definition"],
  "nerdery-remove-animal-attribute": ["nerdery-view-catalog-for-maintenance", "nerdery-view-animal-definition"]
};
// The photo view of one encounter changes only with a catalog change; its answer is not refreshed on age.
const STABLE = new Set(["nerdery-view-collected-animal"]);
// Every write goes through this server and re-runs what it changes, so a kept answer goes stale only by a change made
// elsewhere; a refresh holds the one-at-a-time queue for a run's 4–5 seconds, so it waits for answers five minutes old.
const FRESH_MS = 5 * 60000;
const RUN_WAIT_SECONDS = 90;
const TIMING = process.env.TIMING === "1";
const SECTIONS = ["home", "collection", "collected-animals", "team", "animal-definitions-admin", "animal-attributes-admin"];
// Sign-up and sign-in through the DNR identity service (nerdery/make-identity.mjs). After a sign-in every run answers
// as that wildlife user, so answers are kept per user, and a run queued for one user never runs after another has
// signed in. At start the server signs in as each registered user of the fixtures in turn, in the background, and
// runs their answers, so switching users later costs one sign-in; it stops the moment someone signs in themselves.
const IDENTITY = ["nerdery-sign-in-wildlife-user", "nerdery-register-wildlife-user"];
const PERSONAS = ["identity-a", "identity-bio"];
let bound = null, signedOut = true, someoneSignedIn = false;
const userKey = () => bound?.userId ?? "-";
const PACKAGE = process.env.NERDERY_FEATURES ?? path.resolve(here, "../../../nerdery-canonical-features");
const BASE_STATE = JSON.parse(fs.readFileSync(path.join(PACKAGE, "fixtures/base-state.json"), "utf8"));
const registeredSubjects = new Set(BASE_STATE.users.map((u) => u.identitySubject));

// ---------- the SideFX API, in this process ----------
// The installed client's own modules give the signed-in session; its token is decrypted once here, not per call.
const clientDir = path.dirname(CLIENT);
const { configuredEndpoint } = await import(pathToFileURL(CLIENT).href);
const { sessionStore } = await import(pathToFileURL(path.join(clientDir, "session-store.mjs")).href);
const { declaredRunBody } = await import(pathToFileURL(path.join(clientDir, "run-response.mjs")).href);

let signedIn = null, checkedAt = 0;
function session() {
  if (signedIn && Date.parse(signedIn.expiresAt) > Date.now()) return signedIn;
  if (!signedIn && Date.now() - checkedAt < 15000) return { authenticated: false };
  checkedAt = Date.now();
  try {
    const endpoint = configuredEndpoint({ auth: "user" });
    const s = sessionStore().read(endpoint);
    signedIn = { authenticated: true, endpoint, token: s.token, principalId: s.principalId, sessionId: s.sessionId, expiresAt: s.expiresAt };
  } catch { signedIn = null; }
  return signedIn ?? { authenticated: false };
}

async function api(s, route, init = {}, signal) {
  const url = new URL(s.endpoint + route);
  const response = await fetch(url.href, { ...init, redirect: "error", signal,
    headers: { authorization: `Bearer ${s.token}`, ...(init.body ? { "content-type": "application/json" } : {}), ...init.headers } });
  const text = await response.text();
  let data;
  try { data = JSON.parse(text); } catch { throw new Error(`API returned non-JSON (${response.status}).`); }
  if (response.status === 401) signedIn = null;
  return { ok: response.ok, status: response.status, data, url };
}

// One run: admit it, then read its output as soon as the estate holds it. The run is declared and executed by SideFX;
// the server only waits for its answer.
async function run(capability, request) {
  const s = session();
  if (!s.authenticated) return { result: { status: "REFUSED", reason: { code: "AUTHENTICATION_REQUIRED" } }, runId: null };
  const signal = AbortSignal.timeout(RUN_WAIT_SECONDS * 1000);
  const started = Date.now();
  let runId = null, admittedIn = null, reads = 0;
  // With TIMING=1 each run logs where its time went: admission, then the reads until its output.
  const timed = (done) => {
    if (TIMING) console.log(`${capability}: ${done.result?.status} in ${Date.now() - started} ms (admitted in ${admittedIn} ms, ${reads} reads)`);
    return done;
  };
  try {
    const admitted = await api(s, "/sfx/v1/runs", { method: "POST", headers: { "idempotency-key": randomUUID() },
      body: JSON.stringify({ object: "capability", operation: "observe", subject: capability,
        input: { caller: { principalId: s.principalId, sessionId: s.sessionId }, request } }) }, signal);
    if (!admitted.ok || !admitted.data.runId) throw new Error(`${admitted.data.error?.code ?? "HTTP_" + admitted.status}: ${admitted.data.error?.message ?? "admission failed"}`);
    runId = admitted.data.runId;
    admittedIn = Date.now() - started;
    const runPath = "/sfx/v1/runs/" + encodeURIComponent(runId);
    // The output is read every quarter second: a longer wait between reads only adds to what someone waits for.
    for (let tries = 1, wait = 100; ; tries += 1, wait = Math.min(wait * 2, 250)) {
      const read = await api(s, runPath + "/output", {}, signal);
      reads += 1;
      if (read.ok && read.data.status === "READ" && read.data.output) {
        let result = declaredRunBody(read.url, read.data);
        if (result && result.value !== undefined && result.status === undefined) result = typeof result.value === "string" ? JSON.parse(result.value) : result.value;
        return timed({ result, runId });
      }
      // A run that ended without an output has nothing to wait for: every few reads, its state says whether that happened.
      if (tries % 8 === 0) {
        const state = await api(s, runPath, {}, signal);
        if (state.ok && ["failed", "completed"].includes(state.data.run?.state) && !state.data.run?.output?.available)
          return timed({ result: { status: "FAILED", reason: { code: "API_RUN_FAILED" }, message: state.data.run?.failure?.message ?? "the run ended without an output" }, runId });
      }
      await new Promise((resolve) => setTimeout(resolve, wait));
    }
  } catch (error) {
    return timed({ result: { status: "FAILED", reason: { code: "API_RUN_FAILED" }, message: String(error.message).split(s.token ?? "\u0000").join("[redacted]").slice(0, 600) }, runId });
  }
}

// ---------- one run at a time: the ones someone waits for first ----------
const waiting = [], background = [];
let running = false;
// A run for a user other than the one signed in now is not made: it would answer as the wrong user.
const skipped = () => ({ result: { status: "FAILED", reason: { code: "API_RUN_FAILED" }, message: "another user signed in first" }, runId: null });
function schedule(task, urgent, user = userKey()) {
  return new Promise((resolve) => {
    (urgent ? waiting : background).push({ task, resolve, user });
    pump();
  });
}
async function pump() {
  if (running) return;
  const item = waiting.shift() ?? background.shift();
  if (!item) return;
  running = true;
  try { item.resolve(item.user === null || item.user === userKey() ? await item.task() : skipped()); }
  catch (error) { item.resolve({ result: { status: "FAILED", reason: { code: "API_RUN_FAILED" }, message: error.message }, runId: null }); }
  finally { running = false; pump(); }
}

// ---------- the answers already run, per user ----------
const answers = new Map(), pending = new Map();
const keyOf = (capability, request, user = userKey()) => `${user}\u0000${capability}\u0000${JSON.stringify(request)}`;
const capabilityOf = (key) => key.split("\u0000")[1];
const ownerOf = (key) => key.split("\u0000")[0];
function fetchAnswer(capability, request, urgent) {
  const key = keyOf(capability, request), queued = pending.get(key);
  if (queued) {
    // Someone now waits for a run queued in the background: it moves ahead.
    if (urgent && queued.item && background.includes(queued.item)) { background.splice(background.indexOf(queued.item), 1); waiting.push(queued.item); }
    return queued.promise;
  }
  const entry = {};
  entry.promise = new Promise((resolve) => {
    entry.item = { task: () => run(capability, request), resolve, user: userKey() };
    (urgent ? waiting : background).push(entry.item);
    pump();
  }).then((done) => {
    pending.delete(key);
    if (done.result && done.result.status !== "FAILED") answers.set(key, { at: Date.now(), request, ...done });
    return done;
  });
  pending.set(key, entry);
  return entry.promise;
}
async function answer(capability, request) {
  if (WRITES[capability]) {
    const done = await schedule(() => run(capability, request), true);
    if (done.result?.mutation?.applied) afterWrite(capability, request, done.result);
    return done;
  }
  const kept = answers.get(keyOf(capability, request));
  if (kept) {
    if (!STABLE.has(capability) && Date.now() - kept.at > FRESH_MS) fetchAnswer(capability, request, false);
    return kept;
  }
  return fetchAnswer(capability, request, true);
}
// After a write, the answers it can change are dropped and run again in the background, with any the write makes
// newly visible: a recorded encounter's photo view, a definition's detail.
function afterWrite(capability, request, result) {
  const affected = new Set(WRITES[capability]);
  // A catalog change reaches every user's answers; the others reach only the writer's. Another user's are dropped and
  // run again when that user next signs in.
  const everyone = WRITES[capability] === CATALOG_READS;
  for (const [key, kept] of [...answers]) {
    if (!affected.has(capabilityOf(key))) continue;
    if (ownerOf(key) === userKey()) { answers.delete(key); fetchAnswer(capabilityOf(key), kept.request, false); }
    else if (everyone) answers.delete(key);
  }
  if (result.encounter?.encounterId) fetchAnswer("nerdery-view-collected-animal", { encounterId: result.encounter.encounterId }, false);
  const definitionId = result.definitionId ?? result.animal?.definitionId ?? result.encounter?.definitionId;
  if (definitionId) fetchAnswer("nerdery-view-animal-definition", { definitionId }, false);
  for (const read of ["nerdery-view-collected-animals", "nerdery-browse-animal-collection", "nerdery-view-wildlife-home", "nerdery-view-catalog-for-maintenance"])
    if (affected.has(read) && !answers.has(keyOf(read, read === "nerdery-browse-animal-collection" ? { search: "" } : {}))) fetchAnswer(read, read === "nerdery-browse-animal-collection" ? { search: "" } : {}, false);
}
// Every answer a screen can show that is not kept yet, run in the background: at start, and for each user who signs
// in. A kept answer is refreshed when its screen is shown, so after a sign-in the queue stays free for what someone waits for.
async function warm() {
  if (!session().authenticated || (DECLARED.has(IDENTITY[0]) && !bound)) return;
  const ensure = (capability, request) => answers.get(keyOf(capability, request)) ?? fetchAnswer(capability, request, false);
  const home = ensure("nerdery-view-wildlife-home", {});
  const mine = ensure("nerdery-view-collected-animals", {});
  const browse = ensure("nerdery-browse-animal-collection", { search: "" });
  for (const section of SECTIONS) ensure("nerdery-resolve-wildlife-access", { section });
  ensure("nerdery-view-catalog-for-maintenance", {});
  const [, collected, listed] = await Promise.all([home, mine, browse]);
  for (const item of collected.result?.items ?? []) ensure("nerdery-view-collected-animal", { encounterId: item.encounterId });
  for (const item of listed.result?.items ?? []) ensure("nerdery-view-animal-definition", { definitionId: item.definitionId });
  await Promise.all([...pending.values()].map((entry) => entry.promise));
}
// Each registered fixture user's answers, in the background, until someone signs in themselves.
async function warmPersonas() {
  for (const ref of PERSONAS) {
    if (someoneSignedIn) return;
    const done = await schedule(() => (someoneSignedIn ? skipped() : run(IDENTITY[0], { identityResponseRef: ref })), false, null);
    if (someoneSignedIn || done.result?.status !== "SIGNED_IN") return;
    bound = done.result.user;
    await warm();
  }
}
// Sign in through DNR: the run binds the SideFX session to the wildlife user, so it is never kept as an answer.
async function signIn(identityResponseRef) {
  someoneSignedIn = true;
  const asked = Date.now();
  const done = await schedule(() => run(IDENTITY[0], { identityResponseRef }), true, null);
  if (TIMING) console.log(`sign-in ${identityResponseRef}: answered ${Date.now() - asked} ms after the click reached the server`);
  if (done.result?.status === "SIGNED_IN") {
    bound = done.result.user;
    signedOut = false;
    warm().catch(() => {});
  }
  return done;
}

// ---------- HTTP ----------
const send = (res, status, body, headers = {}) => {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store", ...headers });
  res.end(JSON.stringify(body));
};
const readJson = (req) => new Promise((resolve, reject) => {
  let size = 0; const chunks = [];
  req.on("data", (chunk) => { size += chunk.length; if (size > MAX_BODY) { reject(new Error("BODY_TOO_LARGE")); req.destroy(); } else chunks.push(chunk); });
  req.on("end", () => { try { resolve(chunks.length ? JSON.parse(Buffer.concat(chunks).toString("utf8")) : {}); } catch { reject(new Error("BODY_NOT_JSON")); } });
  req.on("error", reject);
});

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, "http://localhost");
  try {
    if (url.pathname === "/api/session" && req.method === "GET") {
      const s = session();
      const user = !signedOut && bound ? { userId: bound.userId, firstName: bound.firstName, lastName: bound.lastName, roles: bound.roles } : null;
      return send(res, 200, s.authenticated ? { authenticated: true, principalId: s.principalId, expiresAt: s.expiresAt, endpoint: s.endpoint, declared: [...DECLARED], user }
        : { authenticated: false, declared: [...DECLARED], user: null });
    }
    // The DNR identity service's stand-in: the identity responses it can return, as the fixtures define them.
    if (url.pathname === "/api/identities" && req.method === "GET")
      return send(res, 200, Object.entries(BASE_STATE.identityResponses).map(([ref, r]) => ({ identityResponseRef: ref, validation: r.validation,
        name: r.firstName ? `${r.firstName} ${r.lastName}` : null, roles: r.roles ?? [], registered: Boolean(r.subject && registeredSubjects.has(r.subject)) })));
    if (url.pathname === "/api/sign-in" && req.method === "POST") {
      const body = await readJson(req);
      const done = await signIn(body?.identityResponseRef);
      return send(res, 200, done.result, done.runId ? { "x-sfx-run-id": done.runId } : {});
    }
    // Registration, then sign-in with the same DNR response: two runs, one sign-in.
    if (url.pathname === "/api/register" && req.method === "POST") {
      const body = await readJson(req);
      const registration = await schedule(() => run(IDENTITY[1], { identityResponseRef: body?.identityResponseRef }), true, null);
      if (registration.result?.status !== "REGISTERED") return send(res, 200, { registration: registration.result });
      const subject = BASE_STATE.identityResponses[body.identityResponseRef]?.subject;
      if (subject) registeredSubjects.add(subject);
      const signedIn = await signIn(body.identityResponseRef);
      return send(res, 200, { registration: registration.result, signIn: signedIn.result });
    }
    if (url.pathname === "/api/sign-out" && req.method === "POST") { signedOut = true; return send(res, 200, { signedOut: true }); }
    if (url.pathname === "/api/labels" && req.method === "GET") {
      const locale = url.searchParams.get("locale") === "es" ? "es" : "en";
      return send(res, 200, { locale, labels: { ...LABELS.en, ...LABELS[locale] } });
    }
    const match = /^\/api\/run\/([a-z0-9-]+)$/.exec(url.pathname);
    if (match && req.method === "POST") {
      const capability = match[1], request = await readJson(req);
      if (!DECLARED.has(capability) || IDENTITY.includes(capability)) return send(res, 200, { status: "REFUSED", reason: { code: "CAPABILITY_NOT_DECLARED" } });
      // Signed out, nothing runs: the estate would answer as whoever signed in last.
      if (signedOut) return send(res, 200, { status: "REFUSED", reason: { code: "AUTHENTICATION_REQUIRED" } });
      const done = await answer(capability, request !== null && typeof request === "object" && !Array.isArray(request) ? request : {});
      return send(res, 200, done.result, done.runId ? { "x-sfx-run-id": done.runId } : {});
    }
    if (url.pathname.startsWith("/api/")) return send(res, 404, { error: "NOT_FOUND" });
    const file = path.join(PUBLIC, url.pathname === "/" ? "index.html" : path.normalize(url.pathname).replace(/^([\\/])+/, ""));
    const target = file.startsWith(PUBLIC) && fs.existsSync(file) && fs.statSync(file).isFile() ? file : path.join(PUBLIC, "index.html");
    res.writeHead(200, { "content-type": TYPES[path.extname(target)] ?? "application/octet-stream", "cache-control": "no-cache" });
    fs.createReadStream(target).pipe(res);
  } catch (error) {
    const code = error.message === "BODY_TOO_LARGE" ? 413 : error.message === "BODY_NOT_JSON" ? 400 : 500;
    if (code === 500) console.error(error);
    send(res, code, { error: code === 500 ? "SERVER_ERROR" : error.message });
  }
});
server.listen(PORT, () => {
  console.log(`Wildlife Collection on http://localhost:${PORT}, running the estate's capabilities through the SideFX API (${CLIENT})`);
  const started = Date.now();
  warmPersonas().then(() => console.log(`the registered users' answers ready in ${Math.round((Date.now() - started) / 1000)} s`), (error) => console.error("warming failed:", error.message));
});
