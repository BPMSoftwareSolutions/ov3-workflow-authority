// Finalizes the canonical features of the Nerdery citizen slice and writes their feature-first DSL:
//   nerdery/features/<capability>.feature   the owner-review candidates (nerdery-canonical-features, read only) with each
//                                           case's candidate-provider comment replaced by its exact provider tag, as the
//                                           implementation handoff directs, and @status:probed; requests, steps and
//                                           Then tables are byte-identical to the candidates (verified below)
//   nerdery/dsl/<capability>.dsl            pins those bytes; one sql-database-reader operation on sfx-identity
//   nerdery/compile-cases.json              the compile of each DSL against its retained feature (run-compile.mjs)
//   nerdery/slice.manifest.json             every digest
// usage: node make-slice.mjs <@cucumber/gherkin node_modules>
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const SRC = path.resolve(root, "..", "nerdery-canonical-features");
const require = createRequire(import.meta.url);
const modules = process.argv[2];
const gherkin = require(modules + "/@cucumber/gherkin");
const { IdGenerator } = require(modules + "/@cucumber/messages");
const sha = (s) => crypto.createHash("sha256").update(Buffer.from(s, "utf8")).digest("hex");
const read = (p) => fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n");
const pickles = (text) => {
  const id = IdGenerator.incrementing();
  return gherkin.compile(new gherkin.Parser(new gherkin.AstBuilder(id), new gherkin.GherkinClassicTokenMatcher()).parse(text), "f", id);
};
const RUNS = "84ff8efb, c901e190, 8e66151b, 7837a8f1, b28d02da, 25e64090";
const SLICE = ["nerdery-browse-animal-collection", "nerdery-view-animal-definition", "nerdery-upload-encounter-photo", "nerdery-record-animal-encounter",
  "nerdery-view-collected-animals", "nerdery-set-animal-team", "nerdery-view-wildlife-home", "nerdery-add-animal-definition"];
const swap = (text, a, b, what) => { if (!text.includes(a)) throw new Error(`${what}: missing ${a.slice(0, 70)}`); return text.split(a).join(b); };

const manifest = { generated: "2026-11-02", source: "nerdery-canonical-features/features/mvp", runs: RUNS.split(", "), capabilities: [] };
const compileCases = [];
for (const cap of SLICE) {
  const rel = `features/mvp/${cap}.feature`;
  const original = read(path.join(SRC, rel));
  let t = original;
  t = swap(t, "# Status: feature candidate. The proposed capability is absent from estate model 34 (inventory run 49ae8acb).\n",
    `# Status: finalized for the SideFX build of the citizen slice from the owner-review candidate\n# nerdery-canonical-features/${rel} (sha256:${sha(original)}).\n`, cap);
  t = swap(t, "# @status:not-built means this delivery contains no implementation or run evidence for the case.\n",
    `# @status:probed: the case ran read-only against the wildlife procedures through nerdery/conformance/run-cases.mjs\n# (runs ${RUNS}).\n`, cap);
  const providerLine = "# Provider: the operation is one sql-database-reader statement on sfx-identity (EXEC wildlife.serve), so every case is\n# tagged @provider:sql-database-reader.\n";
  if (t.includes("# Business provider candidates are named on each affected case. Bind and verify them before adding @provider tags.\n"))
    t = swap(t, "# Business provider candidates are named on each affected case. Bind and verify them before adding @provider tags.\n", providerLine, cap);
  else t = t.replace(/^# Expected business read: @provider:sql-database-reader\.[^\n]*\n/m, () => providerLine);
  t = swap(t, "# See review/provider-bindings.md for provider scope, evidence and open bindings. Fixture preparation is separate.\n",
    "# The JSON under Given is the request body. The declared API operation binds the caller from the session the frontdoor\n# validated; the capability input is {caller, request}. Fixture preparation is separate.\n", cap);
  t = t.replace(/^(\s*)# Proposed provider calls \(unbound\):[^\n]*\n/gm, "");
  t = t.replace(/^(\s*)# Local refusal before business-provider dispatch; acceptance requires no business call or mutation\.\n/gm,
    "$1# Refused inside the operation's one provider call; the stored state is unchanged.\n");
  t = t.replace(/^(\s*)# Arrangement: fixtures\/cases\//gm, "$1# Arrangement: nerdery-canonical-features/fixtures/cases/");
  t = t.replace(/^(\s*)@status:not-built\n(?!\1@provider:sql-database-reader\n)/gm, "$1@status:not-built\n$1@provider:sql-database-reader\n");
  t = t.replace(/^(\s*)@status:not-built\n/gm, "$1@status:probed\n");
  if (/unbound|@status:not-built/.test(t)) throw new Error(`${cap}: an unbound provider or a not-built case remains`);
  const before = pickles(original), after = pickles(t);
  if (before.length !== after.length) throw new Error(`${cap}: case count changed`);
  before.forEach((p, i) => {
    const q = after[i];
    if (JSON.stringify(p.steps.map((s) => [s.type, s.text, s.argument])) !== JSON.stringify(q.steps.map((s) => [s.type, s.text, s.argument]))) throw new Error(`${cap}: ${p.name} steps changed`);
    const tags = q.tags.map((x) => x.name);
    if (tags.filter((x) => x === "@provider:sql-database-reader").length !== 1 || !tags.includes("@status:probed")) throw new Error(`${cap}: ${p.name} tags ${tags}`);
  });
  // The circuit: the one Given, When and Then every case shares; the operation its Then rows name; the declared variants.
  const shared = (type) => { const v = [...new Set(after.map((p) => p.steps.find((s) => s.type === type).text))]; if (v.length !== 1) throw new Error(`${cap}: ${type} differs across cases`); return v[0]; };
  const ops = [...new Set(after.flatMap((p) => p.steps.find((s) => s.argument && s.argument.dataTable).argument.dataTable.rows.slice(1).map((r) => r.cells[0].value)))];
  if (ops.length !== 1) throw new Error(`${cap}: operations ${ops}`);
  const variants = t.match(/terminal variants: ([A-Z_]+(?:, [A-Z_]+)*)\./)[1].split(", ");
  const title = t.match(/^Feature: (.+)$/m)[1];
  const soThat = (t.match(/^\s*So that (.+)$/m) || [])[1] || "";
  fs.mkdirSync(path.join(here, "features"), { recursive: true });
  fs.writeFileSync(path.join(here, "features", `${cap}.feature`), t);
  const digest = sha(t);
  const input = { type: "object", additionalProperties: false, required: ["request"], properties: {
    caller: { type: "object", additionalProperties: false, properties: { principalId: { type: "string" }, sessionId: { type: "string" } } }, request: { type: "object" } } };
  const output = { type: "object", additionalProperties: true, required: ["contractId", "status"], properties: { contractId: { const: `${cap}-result.v1` }, status: { enum: variants } } };
  const config = { dataSource: "sfx-identity-database", statement: `EXEC wildlife.serve @operation=N'${cap}',@input=@input;`, resultColumn: "value" };
  const dsl = [`capability ${cap}`, `feature ${cap} sha256:${digest}`,
    `intent: ${title}, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)`,
    `outcome: ${cap}-result.v1 ${variants.join(" or ")}, each refusal named by its reason code${soThat ? `, so that ${soThat}` : ""}`,
    `input contract ${cap}-request.v1 ${JSON.stringify(input)}`, `output contract ${cap}-result.v1 ${JSON.stringify(output)}`, "cli display outcome as json",
    `scenario ${cap} root terminal`, `given: ${shared("Context")}`, `when: ${shared("Action")}`, `then: ${shared("Outcome")}`,
    `operation ${ops[0]} uses provider sql-database-reader`, `config: ${JSON.stringify(config)}`, `input input from ${cap} $`, `outcome from ${ops[0]} $.value`, ""].join("\n");
  if (/[^\x09\x0a\x20-\x7e]/.test(dsl)) throw new Error(`${cap}: non-ASCII DSL`);
  fs.mkdirSync(path.join(here, "dsl"), { recursive: true });
  fs.writeFileSync(path.join(here, "dsl", `${cap}.dsl`), dsl);
  manifest.capabilities.push({ capabilityId: cap, cases: after.length, operationId: ops[0], variants, candidate: `sha256:${sha(original)}`, feature: `sha256:${digest}`, dsl: `sha256:${sha(dsl)}` });
  compileCases.push({ name: `${cap} compiles against its feature`, source: `nerdery/dsl/${cap}.dsl`, retain: [`nerdery/features/${cap}.feature`],
    expect: [["$.status", "COMPILED"], ["$.document.feature.digest", `sha256:${digest}`], ["$.document.scenarios[0].operations[4].operationId", ops[0]],
      ["$.document.scenarios[0].operations[4].providerCapabilityId", "sql-database-reader"]] });
}
fs.writeFileSync(path.join(here, "compile-cases.json"), JSON.stringify(compileCases, null, 1) + "\n");
fs.writeFileSync(path.join(here, "slice.manifest.json"), JSON.stringify(manifest, null, 1) + "\n");
for (const c of manifest.capabilities) console.log(c.capabilityId.padEnd(36), String(c.cases).padStart(3), c.operationId.padEnd(46), c.variants.join("/"), c.feature.slice(7, 19), c.dsl.slice(7, 19));
