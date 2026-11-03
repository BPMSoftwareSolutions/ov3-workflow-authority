// Writes the feature-first DSL sources, each pinning the sha256 of its canonical feature's bytes as they are now:
//   conformance/check-capability-feature-conformance.dsl       the no-drift check, declared by OV3's build flight
//   reveal-estate-workflows/reveal-estate-workflows.dsl         the Phase A lens, re-expressed for revision 2
//   conformance/fixtures/compile/greeting-pinned.dsl            a source pinned to the greeting scaffold, which must refuse
// Rerun after a feature changes: its pin must be its feature's current digest.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const digest = (p) => crypto.createHash("sha256").update(fs.readFileSync(path.join(root, p))).digest("hex");
const write = (p, text) => { fs.writeFileSync(path.join(root, p), text); console.log(p, crypto.createHash("sha256").update(Buffer.from(text, "utf8")).digest("hex")); };
const READER = (statement) => `config: ${JSON.stringify({ dataSource: "sfx-estate-database", statement, resultColumn: "value" })}`;

const check = `capability check-capability-feature-conformance
feature check-capability-feature-conformance sha256:${digest("features/check-capability-feature-conformance.feature")}
intent: Check a capability's circuit against its canonical feature by identity, and accept each case only from the pinned evidence of its own call
outcome: capability-feature-conformance.v1 CONFORMANT, DRIFT, WELL_FORMED, MALFORMED, NOT_BOUND, NOT_FOUND, ACCEPTED, REJECTED or BASELINE, with each finding named by its code and identity
inquiry: Does this capability's circuit drift from its canonical feature?
inquiry: Which identity, step or case drifted, and where?
inquiry: Does this run prove this case through its own call?
input contract check-capability-feature-conformance-request.v1 ${JSON.stringify({ type: "object", additionalProperties: false, properties: {
  capabilityId: { type: "string", minLength: 1, maxLength: 400 }, featureText: { type: "string", minLength: 1 },
  featureDigest: { type: "string", pattern: "^sha256:[0-9a-f]{64}$" }, document: { type: "object" }, acceptance: { type: "object" },
  evidenceText: { type: "string", minLength: 1 }, baseline: { type: "object" }, explain: { type: "boolean" } } })}
output contract capability-feature-conformance.v1 ${JSON.stringify({ type: "object", additionalProperties: true, required: ["contractId", "status"],
  properties: { contractId: { const: "capability-feature-conformance.v1" }, status: { type: "string" } } })}
cli display outcome as json
scenario check-capability-feature-conformance root terminal
variants: CONFORMANT:success,DRIFT:success,WELL_FORMED:success,MALFORMED:success,NOT_BOUND:success,NOT_FOUND:success,ACCEPTED:success,REJECTED:success,BASELINE:success
given: a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
when: the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
then: CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
operation check-capability-feature-conformance.check uses provider sql-database-reader
${READER("SET ARITHABORT ON; DECLARE @estate_model_pk bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1); EXEC analysis.check_capability_feature_conformance @input=@input,@estate_model_pk=@estate_model_pk;")}
input input from check-capability-feature-conformance $
outcome from check-capability-feature-conformance.check $.value
`;
write("conformance/check-capability-feature-conformance.dsl", check);

const draft = fs.readFileSync(path.join(root, "reveal-estate-workflows/reveal-estate-workflows.dsl"), "utf8");
const keep = draft.split("\n").filter((l) => /^(intent:|outcome:|inquiry:|input contract |output contract |cli display |scenario |given:|when:|then:)/.test(l));
const reveal = [`capability reveal-estate-workflows`,
  `feature reveal-estate-workflows sha256:${digest("reveal-estate-workflows/reveal-estate-workflows.feature")}`,
  ...keep,
  `operation reveal-estate-workflows.reveal uses provider sql-database-reader`,
  READER("SET ARITHABORT ON; DECLARE @estate_model_pk bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1); EXEC analysis.reveal_estate_workflows @input=@input,@estate_model_pk=@estate_model_pk;"),
  `input input from reveal-estate-workflows $`,
  `outcome from reveal-estate-workflows.reveal $.value`, ``].join("\n");
write("reveal-estate-workflows/reveal-estate-workflows.feature-first.dsl", reveal);

const greeting = `# Fixture of check case conf-compile-greeting-pin: a source for compile-capability-dsl that pins the greeting scaffold the
# estate retains under sha256:9f2f5b4e... It must refuse, naming each drift.
capability compile-capability-dsl
feature compile-capability-dsl sha256:9f2f5b4ea73e97b4b3134f56b845fe698587dcd536b5899ba9a388e98376f7ab
intent: Compile capability DSL into the declared document, or refuse with named diagnostics
outcome: compile-capability-dsl-result.v1 COMPILED or REFUSED
input contract compile-capability-dsl-request.v1 {"type":"object","additionalProperties":false,"required":["source"],"properties":{"source":{"type":"string","minLength":1,"maxLength":65536}}}
output contract compile-capability-dsl-result.v1 {"type":"object","required":["contractId","status"],"properties":{"status":{"enum":["COMPILED","REFUSED"]}}}
scenario compile-capability-dsl root terminal
given: DSL source text on the declared grammar
when: the resolver parses every line and validates the whole document
then: the compiled capability document with its digests, or the named DSL_* refusals with line numbers
operation compile-capability-dsl.compile uses provider sql-database-reader
${READER("EXEC analysis.compile_capability_dsl @input=@input,@estate_model_pk=NULL;")}
input input from compile-capability-dsl $
outcome from compile-capability-dsl.compile $.value
`;
write("conformance/fixtures/compile/greeting-pinned.dsl", greeting);
