// Runs the canonical acceptance cases against the application's operations. Each case starts from the pinned base
// state with its fixture's replacements, faults and arrangement, runs its operation as the fixture's authenticated
// subject, and passes when every Then row holds and the store agrees: a refusal or a read leaves it unchanged, and
// an applied write is read back as returned.
//
// usage: node test/run-features.mjs [capability-id ...]   (default: every capability the application implements)
//   NERDERY_FEATURES  the nerdery-canonical-features package (default: beside this repository's spec folder)
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { OPERATIONS, invoke } from "../lib/operations.mjs";
import { Store, faultsFromFixture, readFixtures, sha256, stateFromFixture } from "../lib/store.mjs";
import { at, equal, expected, readCases } from "../lib/cases.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const PACKAGE = process.env.NERDERY_FEATURES ?? path.resolve(here, "../../../../nerdery-canonical-features");
const OWN = path.resolve(here, "../.."); // nerdery/: features and fixtures written for the build
const capabilities = process.argv.slice(2).length ? process.argv.slice(2) : Object.keys(OPERATIONS);
const { base, media } = readFixtures(PACKAGE);

const featureOf = (cap) => {
  for (const [file, fixtures] of [[path.join(PACKAGE, "features/mvp", `${cap}.feature`), path.join(PACKAGE, "fixtures/cases")],
    [path.join(PACKAGE, "features/offline-candidate", `${cap}.feature`), path.join(PACKAGE, "fixtures/cases")],
    [path.join(OWN, "features", `${cap}.feature`), path.join(OWN, "fixtures/cases")]])
    if (fs.existsSync(file)) return { file, fixtures };
  throw new Error(`${cap}: no feature`);
};

let failed = 0, total = 0;
const show = (x) => (x === undefined ? "(absent)" : JSON.stringify(x));
for (const cap of capabilities) {
  const { file, fixtures } = featureOf(cap);
  const cases = readCases(fs.readFileSync(file, "utf8"));
  let passed = 0;
  for (const c of cases) {
    total += 1;
    const fixture = JSON.parse(fs.readFileSync(path.join(fixtures, `${c.caseId}.json`), "utf8"));
    const { state, blobs } = stateFromFixture(base, media, fixture);
    const store = new Store({ state, blobs, faults: faultsFromFixture(fixture) });
    const before = store.digest();
    const pre = (fixture.arrangement || {}).prewarmAuthenticatedRead;
    const findings = [];
    if (pre) invoke(store, cap, pre.request, pre.subject);
    let result;
    try { result = invoke(store, cap, c.request, fixture.authenticatedSubject ?? null); } catch (error) { findings.push(`threw ${error.stack}`); }
    const after = store.digest();
    for (const [operation, pointer, cell] of c.then) {
      if (!operation.startsWith(`${cap}.`)) findings.push(`operation ${operation} is not of ${cap}`);
      const want = expected(cell), got = at(result, pointer);
      if (want.absent ? got !== undefined : !equal(got, want.value)) findings.push(`${pointer}: ${show(got)} != ${cell}`);
    }
    if (result && result.mutation && result.mutation.applied === true) {
      if (before === after) findings.push("an applied write left the store unchanged");
      const s = store.state;
      if (result.photo) {
        const stored = s.photos.find((p) => p.photoRef === result.photo.photoRef), bytes = store.blobs.get(result.photo.photoRef);
        if (!stored || !bytes || `sha256:${sha256(bytes)}` !== result.photo.contentSha256 || stored.ownerUserId !== result.photo.ownerUserId) findings.push("read-back: stored photo");
      }
      if (result.encounter) {
        const stored = s.encounters.find((e) => e.ownerUserId === fixture.authenticatedSubject && e.encounterId === c.request.encounterId);
        if (!stored || !equal(stored, result.encounter)) findings.push(`read-back: stored encounter ${show(stored)}`);
      }
      if (result.team) {
        const stored = s.teams.find((t) => t.ownerUserId === fixture.authenticatedSubject);
        if (!stored || stored.revision !== result.team.revision || !equal(stored.encounterIds, result.team.encounterIds)) findings.push(`read-back: stored team ${show(stored)}`);
      }
      // A catalog write is read back member by member: the definition or attribute stored is the one returned.
      const readBack = (list, idField, id, returned, what) => {
        const stored = list.find((x) => x[idField] === id);
        if (!stored || Object.entries(returned).some(([key, value]) => value !== undefined && !equal(stored[key], value))) findings.push(`read-back: stored ${what} ${show(stored)}`);
      };
      if (result.definitionId || (result.animal && result.animal.definitionId))
        readBack(s.definitions, "definitionId", result.definitionId ?? result.animal.definitionId,
          { ...(result.animal || {}), active: result.active, revision: result.revision ?? (result.animal || {}).revision }, "definition");
      if (result.attribute || result.attributeId)
        readBack(s.attributes, "attributeId", result.attributeId ?? result.attribute.attributeId, result.attribute ?? { active: result.active, revision: result.revision }, "attribute");
    } else if (result && before !== after) findings.push(`${result.status} changed the store`);
    if (findings.length) failed += 1; else passed += 1;
    console.log(`${findings.length ? "FAIL" : "ok  "} ${c.caseId}: ${result ? result.status + (result.reason ? ` ${result.reason.code}` : "") : "(no result)"}`);
    for (const f of findings) console.log(`       ${f}`);
  }
  console.log(`== ${cap}: ${passed}/${cases.length}\n`);
}
console.log(`${total - failed}/${total} cases met their expectations`);
process.exit(failed ? 1 : 0);
