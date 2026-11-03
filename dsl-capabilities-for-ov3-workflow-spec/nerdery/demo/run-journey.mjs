// The first executable interview slice of the Nerdery wildlife application, through the declared SideFX capabilities:
// browse -> detail (restricted) -> upload photo -> record encounter -> browse and detail (unlocked) -> a second individual
// -> my individuals -> save a team -> home, then the refusals: a seven-member team, a citizen catalog addition, and a
// retry of the first encounter, which replays without a second write. Every call is a sfx-api run of the capability with
// {caller, request}; the capability verifies the caller's session against [identity].session itself.
//
// usage: node run-journey.mjs [path to sfx-api.mjs]      (signed in with: sfx-api login)
// Each run id prints beside its result; read any of them with: sfx-api run <id> --json --events
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
const here = path.dirname(fileURLToPath(import.meta.url));
const client = process.argv[2] || (() => {
  const dir = path.join(process.env.LOCALAPPDATA || "", "sfx", "api-client");
  const found = fs.readdirSync(dir).map((d) => path.join(dir, d, "sfx-api.mjs")).filter((f) => fs.existsSync(f)).sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);
  if (!found.length) throw new Error("sfx-api.mjs not found; pass its path");
  return found[0];
})();
const sfx = (argv, stdin = null) => {
  let out = "", err = "";
  try { out = execFileSync(process.execPath, [client, "--argv-stdin"], { input: JSON.stringify({ argv, stdin }), encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }); }
  catch (e) { out = String(e.stdout || ""); err = String(e.stderr || e.message); }
  return { out, err };
};
const who = JSON.parse(sfx(["whoami", "--json"]).out || "{}");
if (who.disposition !== "AUTHENTICATED") { console.error("Sign in first: sfx-api login"); process.exit(2); }
const caller = { principalId: who.principalId, sessionId: who.sessionId };
console.log(`caller ${who.principalId} (session ${who.sessionId.slice(0, 8)}..., expires ${who.expiresAt})\n`);

const photo = fs.readFileSync(path.resolve(here, "../../../nerdery-canonical-features/fixtures/media/photo-a.png")).toString("base64");
const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
const call = (label, capabilityId, request, show) => {
  const { out, err } = sfx(["capability", "observe", capabilityId, "--input", "-", "--json", "--auth", "user"], JSON.stringify({ caller, request }));
  const run = ((err + out).match(/Run ([0-9a-f-]{36})/) || [])[1] || "(no run id)";
  let result = null;
  try { const o = JSON.parse(out); result = o.outcome || o.result || o; if (result && result.value) result = typeof result.value === "string" ? JSON.parse(result.value) : result.value; } catch { result = null; }
  console.log(`${label}\n  ${capabilityId}  run ${run}`);
  console.log(`  ${result ? show(result) : (err || out).trim().slice(0, 400)}\n`);
  return result || {};
};
const brief = (r) => `${r.status}${r.reason ? " " + r.reason.code : ""}`;
call("1. Before collection: the catalog shows only the four permitted properties", "nerdery-browse-animal-collection", { search: "" },
  (r) => `${brief(r)} total=${r.total} ${JSON.stringify((r.items || []).map((i) => [i.definitionId, i.collectionState, Object.keys(i.animal)]))}`);
call("2. Before collection: the direct detail read is restricted the same way", "nerdery-view-animal-definition", { definitionId: "animal-001" },
  (r) => `${brief(r)} ${r.collectionState} animal=${JSON.stringify(r.animal)}`);
const up = call("3. Upload a photo (retained for later verification; nothing is verified now)", "nerdery-upload-encounter-photo",
  { fileName: "photo-a.png", mediaType: "image/png", contentBase64: photo }, (r) => `${brief(r)} ${JSON.stringify(r.photo)}`);
const first = { encounterId: `enc-${stamp}-1`, definitionId: "animal-001", location: { source: "manual", description: "Synthetic park, north path" }, photoRef: (up.photo || {}).photoRef, nickname: "Reed" };
call("4. Record the encounter", "nerdery-record-animal-encounter", first, (r) => `${brief(r)} ${JSON.stringify(r.encounter)} collectionState=${r.collectionState} applied=${r.mutation && r.mutation.applied}`);
call("5. After collection: the catalog entry is unlocked for this user", "nerdery-browse-animal-collection", { search: "Heron" },
  (r) => `${brief(r)} ${JSON.stringify((r.items || []).map((i) => [i.definitionId, i.collectionState, i.animal.scientificName, i.animal.types]))}`);
call("6. After collection: the detail shows the unlocked information", "nerdery-view-animal-definition", { definitionId: "animal-001" },
  (r) => `${brief(r)} ${r.collectionState} types=${JSON.stringify((r.animal || {}).types)} attributes=${JSON.stringify(((r.animal || {}).attributeDetails || []).map((a) => [a.name, a.selectedValues.map((v) => v.label)]))}`);
const up2 = call("7a. A second photo", "nerdery-upload-encounter-photo", { fileName: "photo-a.png", mediaType: "image/png", contentBase64: photo }, (r) => `${brief(r)} ${(r.photo || {}).photoRef}`);
call("7b. A second individual of the same animal", "nerdery-record-animal-encounter",
  { encounterId: `enc-${stamp}-2`, definitionId: "animal-001", location: { source: "device", latitude: 44.95, longitude: -93.09 }, photoRef: (up2.photo || {}).photoRef, nickname: "Sky" },
  (r) => `${brief(r)} ${JSON.stringify(r.encounter)}`);
call("8. My individuals: each with my photo and nickname", "nerdery-view-collected-animals", {},
  (r) => `${brief(r)} total=${r.total} ${JSON.stringify((r.items || []).map((i) => [i.encounterId, i.displayName, i.photoRef]))}`);
const home0 = call("9a. Home before a team", "nerdery-view-wildlife-home", {}, (r) => `${brief(r)} revision=${(r.team || {}).revision} size=${(r.team || {}).size}`);
call("9b. Save a team of two individuals", "nerdery-set-animal-team", { expectedRevision: (home0.team || {}).revision || 0, encounterIds: [`enc-${stamp}-1`, `enc-${stamp}-2`] },
  (r) => `${brief(r)} ${JSON.stringify(r.team)}`);
call("10. Home shows the saved team", "nerdery-view-wildlife-home", {}, (r) => `${brief(r)} ${JSON.stringify(((r.team || {}).members || []).map((m) => [m.encounterId, m.displayName]))}`);
call("11. Refusal: a seven-member team; the saved team is unchanged", "nerdery-set-animal-team",
  { expectedRevision: 1, encounterIds: [1, 2, 3, 4, 5, 6, 7].map((n) => `enc-${stamp}-${n}`) }, (r) => `${brief(r)} applied=${r.mutation && r.mutation.applied}`);
call("12. Refusal: a citizen cannot add to the catalog", "nerdery-add-animal-definition",
  { animal: { commonName: "Demo Owl", scientificName: "Synthetic scientific label 4", avatarPhotoRef: "avatar-001", collectionNumber: 4, range: ["county-a"], types: ["Flying"], stats: { Strength: 5, Size: 6, Speed: 7 }, attributes: [] } },
  (r) => `${brief(r)} applied=${r.mutation && r.mutation.applied}`);
call("13. Retry of the first encounter: the same key and content replay without a second write", "nerdery-record-animal-encounter", first,
  (r) => `${brief(r)} replayed=${r.replayed} applied=${r.mutation && r.mutation.applied}`);
