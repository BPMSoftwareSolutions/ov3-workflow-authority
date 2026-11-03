// Renders the wildlife pages in the SideFX shell itself (sfx-platform live-circuit/circuit: page.html, page.js,
// page-runtime.js, ui-components.js, site.css) and walks the journey in Chromium, saving a screenshot per step.
// Only the transport is stubbed. /workspace/pages serves nerdery/ui/pages/*.json, and /workspace/session serves a
// citizen session. /workspace/runs answers each admitted run with the slice mechanics' real outputs from the
// 77-case run (r3), switching to the collected outputs after the encounter is recorded.
// The hero circuits come from the estate database only when the gateway serves the pages, so here they show their
// pending state.
//
// usage: SFX_PLAYWRIGHT=<playwright-core dir> SFX_CHROMIUM=<chrome executable> node nerdery/ui/preview-pages.mjs <r3 report> <out dir>
import http from "node:http";
import fs from "node:fs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const shell = path.resolve(process.env.SFX_SHELL ?? "C:/lab/repos/sfx-platform/live-circuit/circuit");
const [reportFile, outDir] = process.argv.slice(2);
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.SFX_PLAYWRIGHT ?? "playwright-core");
const report = JSON.parse(fs.readFileSync(reportFile, "utf8"));
const result = (caseId) => (report.cases ?? report).find((c) => c.caseId === caseId).result;
const pages = Object.fromEntries(fs.readdirSync(path.join(here, "pages")).map((f) => {
  const doc = JSON.parse(fs.readFileSync(path.join(here, "pages", f), "utf8"));
  return [doc.path, doc];
}));
const TYPES = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8", ".png": "image/png", ".svg": "image/svg+xml", ".webp": "image/webp", ".woff2": "font/woff2" };
const SESSION = { authenticated: true, principalId: "565de6d4-ebcd-408b-9359-04d21dc62183", sessionId: "preview-session", expiresAt: "2026-11-03T15:04:43Z",
  observeRequiresSession: true };
let collected = false;
const outputFor = (body) => {
  const caller = body.input?.caller ?? {};
  if (caller.principalId !== SESSION.principalId) return result("nrd-collection-anonymous");
  const request = body.input?.request ?? {};
  switch (body.subject) {
    case "nerdery-browse-animal-collection": return collected ? result("nrd-collection-collected") : result("nrd-collection-uncollected");
    case "nerdery-view-animal-definition": return collected ? result("nrd-animal-detail-unlocked") : result("nrd-animal-detail-locked");
    case "nerdery-upload-encounter-photo": return result("nrd-photo-upload");
    case "nerdery-record-animal-encounter": collected = true; return result("nrd-encounter-manual");
    case "nerdery-view-collected-animals": return result("nrd-collected-individuals");
    case "nerdery-view-wildlife-home": return result("nrd-home-saved-team");
    case "nerdery-set-animal-team": return (request.encounterIds ?? []).length > 6 ? result("nrd-team-seven") : result("nrd-team-two-individuals");
    case "nerdery-add-animal-definition": return result("nrd-definition-citizen-add");
    default: return { status: "REFUSED", reason: { code: "UNKNOWN_SUBJECT" } };
  }
};
const runs = new Map();
const admitted = [];
const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, "http://local");
  const send = (status, body, type = "application/json") => { res.writeHead(status, { "content-type": type });
    res.end(typeof body === "string" || Buffer.isBuffer(body) ? body : JSON.stringify(body)); };
  if (url.pathname === "/workspace/session") return send(200, SESSION);
  if (url.pathname === "/workspace/pages") {
    const doc = pages[url.searchParams.get("path")];
    return doc ? send(200, { contractId: "ui-page.v1", status: "READ", pageDigest: "0".repeat(64), ...doc, source: "database" }) : send(404, { error: "PAGE_NOT_FOUND" });
  }
  if (url.pathname === "/workspace/circuits") return send(200, { capabilities: ["nerdery-browse-animal-collection", "nerdery-view-animal-definition",
    "nerdery-upload-encounter-photo", "nerdery-record-animal-encounter", "nerdery-view-collected-animals", "nerdery-set-animal-team",
    "nerdery-view-wildlife-home", "nerdery-add-animal-definition"].map((capabilityId) => ({ capabilityId, namespaceId: "sidefx:capabilities" })) });
  if (url.pathname === "/workspace/runs" && req.method === "POST") {
    let text = ""; for await (const chunk of req) text += chunk;
    const body = JSON.parse(text);
    const runId = `preview-${String(admitted.length + 1).padStart(2, "0")}-0000-0000-0000-000000000000`;
    admitted.push(body); runs.set(runId, outputFor(body));
    return send(202, { runId });
  }
  const run = /^\/workspace\/runs\/(preview-[0-9a-z-]+)(\/events\/stream|\/output)?$/.exec(url.pathname);
  if (run && runs.has(run[1])) {
    if (run[2] === "/events/stream") {
      res.writeHead(200, { "content-type": "text/event-stream" });
      res.write(`event: run.admitted\ndata: ${JSON.stringify({ eventId: `urn:sfx-api:run-event:${run[1]}:1`, cursor: 1, runId: run[1], kind: "run.admitted" })}\n\n`);
      setTimeout(() => res.end(`event: end\ndata: ${JSON.stringify({ runId: run[1] })}\n\n`), 120);
      return;
    }
    if (run[2] === "/output") return send(200, runs.get(run[1]));
    return send(200, { runId: run[1], state: "completed" });
  }
  if (pages[url.pathname]) return send(200, await readFile(path.join(shell, "page.html")), TYPES[".html"]);
  if (url.pathname.startsWith("/circuit/")) {
    const file = path.join(shell, url.pathname.slice("/circuit/".length));
    if (!file.startsWith(shell)) return send(404, { error: "NOT_FOUND" });
    try { return send(200, await readFile(file), TYPES[path.extname(file)] ?? "application/octet-stream"); } catch { return send(404, { error: "NOT_FOUND" }); }
  }
  return send(404, { error: "NOT_FOUND" });
});
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const origin = `http://127.0.0.1:${server.address().port}`;
fs.mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch({ executablePath: process.env.SFX_CHROMIUM, headless: true });
const errors = [];
const shots = [];
try {
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await context.newPage();
  const log = [];
  page.on("pageerror", (error) => { errors.push(error.message); log.push(`pageerror ${error.message}`); });
  page.on("console", (message) => log.push(`console.${message.type()} ${message.text()}`));
  page.on("response", (response) => { if (response.status() >= 400) log.push(`http ${response.status()} ${response.url()}`); });
  const open = async (p) => {
    await page.goto(origin + p);
    try { await page.waitForSelector("#page-root section", { timeout: 15000 }); }
    catch (error) { console.error(log.join("\n")); console.error((await page.$eval("#page-root", (n) => n.innerHTML)).slice(0, 2000)); throw error; }
    await page.waitForTimeout(250);
  };
  const shot = async (name) => { const file = path.join(outDir, `${String(shots.length + 1).padStart(2, "0")}-${name}.png`); await page.screenshot({ path: file, fullPage: true }); shots.push(file); };
  const settle = async (selector) => { await page.waitForSelector(selector, { timeout: 10000 }); await page.waitForTimeout(250); };

  await open("/circuit/wildlife"); await shot("overview");
  await open("/circuit/wildlife-collection"); await page.click("#search button[type=submit]"); await settle("#browse-rows tbody tr"); await shot("collection-before");
  await open("/circuit/wildlife-animal"); await page.click("#pick button[type=submit]"); await settle("#detail-fields dl"); await shot("animal-locked");
  await open("/circuit/wildlife-capture");
  await page.setInputFiles("#upload input[type=file]", { name: "heron.png", mimeType: "image/png", buffer: fs.readFileSync(path.resolve(here, "../../../nerdery-canonical-features/fixtures/media/photo-a.png")) });
  await page.click("#upload button[type=submit]"); await settle("#upload-result dl");
  await page.click("#record button[type=submit]"); await settle("#record-result dl"); await shot("capture-recorded");
  await open("/circuit/wildlife-animal"); await page.click("#pick button[type=submit]"); await settle("#detail-attributes tbody tr"); await shot("animal-unlocked");
  await open("/circuit/wildlife-collection"); await page.fill("#search input[name=search]", "Heron"); await page.click("#search button[type=submit]"); await settle("#browse-rows tbody tr"); await shot("collection-after");
  await open("/circuit/wildlife-mine"); await page.click("#load button"); await settle("#mine-cards .card"); await shot("my-animals");
  await open("/circuit/wildlife-team");
  const loaders = await page.$$("#load button"); await loaders[0].click(); await settle("#pick input[type=checkbox]");
  await loaders[1].click(); await settle("#current dl");
  await page.check("#pick input[type=checkbox] >> nth=0"); await page.check("#pick input[type=checkbox] >> nth=1");
  await page.click("#pick button[type=submit]"); await settle("#saved dl");
  await page.click("#seven button"); await settle("#seven-refused .notice"); await shot("team");
  await open("/circuit/wildlife-home"); await page.click("#load button"); await settle("#members .card"); await shot("home");
  await open("/circuit/wildlife-refusals"); await page.click("#add button"); await settle("#add-refused .notice");
  await page.click("#forged button"); await settle("#forged-refused .notice"); await shot("refusals");
  const phone = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  const mobile = await phone.newPage();
  await mobile.goto(origin + "/circuit/wildlife-collection"); await mobile.waitForSelector("#search form"); await mobile.click("#search button[type=submit]");
  await mobile.waitForSelector("#browse-rows tbody tr"); await mobile.waitForTimeout(250);
  const file = path.join(outDir, `${String(shots.length + 1).padStart(2, "0")}-collection-phone.png`); await mobile.screenshot({ path: file, fullPage: true }); shots.push(file);
} finally {
  await browser.close();
  server.close();
}
fs.writeFileSync(path.join(outDir, "admitted.json"), JSON.stringify(admitted, null, 1));
console.log(JSON.stringify({ screenshots: shots.map((s) => path.basename(s)), admitted: admitted.map((a) => `${a.subject} ${JSON.stringify(a.input?.request ?? {}).slice(0, 80)}`),
  pageErrors: errors }, null, 1));
