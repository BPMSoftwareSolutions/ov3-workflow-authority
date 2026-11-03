// The Wildlife Collection demo: a local web application over the canonical features' operations.
//   GET  /                          the web application (public/)
//   GET  /api/session               who is signed in
//   GET  /api/identities            the DNR identity responses the local stand-in can return
//   GET  /api/reference             county names and animal types, for display
//   POST /api/sign-in               nerdery-sign-in-wildlife-user; a SIGNED_IN result starts a session (cookie)
//   POST /api/sign-out              ends the session
//   POST /api/run/<capability-id>   runs that operation for the signed-in user; the body is the feature's request
// The user an operation runs as comes only from the session this server established, never from the request.
//
// usage: node server.mjs [--reset]   PORT (default 4310), NERDERY_DATA (default ./data), NERDERY_FEATURES
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import { OPERATIONS, invoke } from "./lib/operations.mjs";
import { openDiskStore } from "./lib/store.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT ?? 4310);
const DATA = process.env.NERDERY_DATA ?? path.join(here, "data");
const PACKAGE = process.env.NERDERY_FEATURES ?? path.resolve(here, "../../../nerdery-canonical-features");
const PUBLIC = path.join(here, "public");
const MAX_BODY = 16 * 1024 * 1024;
const TYPES = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8",
  ".svg": "image/svg+xml", ".png": "image/png", ".ico": "image/x-icon" };

const store = openDiskStore(DATA, PACKAGE, { reset: process.argv.includes("--reset") });
const sessions = new Map();

const cookieSession = (req) => {
  const match = /(?:^|;\s*)nrd_session=([0-9a-f]{48})/.exec(req.headers.cookie || "");
  return match && sessions.has(match[1]) ? { id: match[1], ...sessions.get(match[1]) } : null;
};
const userOf = (userId) => store.state.users.find((u) => u.userId === userId) ?? null;
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
      const session = cookieSession(req), user = session ? userOf(session.userId) : null;
      return send(res, 200, user ? { authenticated: true, user: { userId: user.userId, firstName: user.firstName, lastName: user.lastName, roles: user.roles } }
        : { authenticated: false });
    }
    if (url.pathname === "/api/identities" && req.method === "GET") {
      const responses = store.state.identityResponses;
      return send(res, 200, Object.entries(responses).map(([ref, r]) => {
        const user = r.subject ? store.state.users.find((u) => u.identitySubject === r.subject) : null;
        return { identityResponseRef: ref, validation: r.validation, name: r.firstName ? `${r.firstName} ${r.lastName}` : null,
          roles: r.roles ?? [], registered: Boolean(user) };
      }));
    }
    if (url.pathname === "/api/reference" && req.method === "GET")
      return send(res, 200, { counties: store.state.counties, types: store.state.types });
    if (url.pathname === "/api/sign-in" && req.method === "POST") {
      const result = invoke(store, "nerdery-sign-in-wildlife-user", await readJson(req), null);
      if (result.status !== "SIGNED_IN") return send(res, 200, result);
      const id = crypto.randomBytes(24).toString("hex");
      sessions.set(id, { userId: result.user.userId, signedInAt: new Date().toISOString() });
      return send(res, 200, result, { "set-cookie": `nrd_session=${id}; HttpOnly; SameSite=Lax; Path=/` });
    }
    if (url.pathname === "/api/sign-out" && req.method === "POST") {
      const session = cookieSession(req);
      if (session) sessions.delete(session.id);
      return send(res, 200, { signedOut: true }, { "set-cookie": "nrd_session=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0" });
    }
    const run = /^\/api\/run\/([a-z0-9-]+)$/.exec(url.pathname);
    if (run && req.method === "POST") {
      const capability = run[1];
      if (!OPERATIONS[capability] || capability === "nerdery-sign-in-wildlife-user") return send(res, 404, { status: "REFUSED", reason: { code: "OPERATION_NOT_DECLARED" } });
      const session = cookieSession(req);
      return send(res, 200, invoke(store, capability, await readJson(req), session ? session.userId : null));
    }
    if (url.pathname.startsWith("/api/")) return send(res, 404, { error: "NOT_FOUND" });
    // The application: index.html for every other path, so a reload keeps its place.
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
server.listen(PORT, () => console.log(`Wildlife Collection on http://localhost:${PORT}  (data: ${DATA})`));
