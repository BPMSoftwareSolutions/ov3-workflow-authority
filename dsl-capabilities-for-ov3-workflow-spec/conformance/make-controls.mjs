// Writes the acceptance records, the negative controls and the drift fixtures of
// features/check-capability-feature-conformance.feature, each pinned by sha256, and the runner's case lists.
// Every negative control changes exactly one thing in a positive control, and a changed evidence packet is pinned
// again in its own record, so the check can only fail on the defect under test.
// usage: node make-controls.mjs <cases output dir>
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const outDir = process.argv[2];
const sha = (s) => crypto.createHash("sha256").update(Buffer.from(s, "utf8")).digest("hex");
const rel = (p) => path.relative(root, p).split(path.sep).join("/");
const write = (p, text) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); return { $path: rel(p), sha256: sha(text) }; };
const json = (o) => JSON.stringify(o, null, 1) + "\n";
const textRef = (w) => ({ $textOf: w.$path, $sha256: w.sha256 });
const jsonRef = (w) => ({ $jsonOf: w.$path, $sha256: w.sha256 });
const manifest = [];
const note = (id, w, extra) => manifest.push({ id, path: w.$path, sha256: w.sha256, ...extra });

// Census-1: the positive control and its negative controls (the census acceptance contract of
// ov3-agentic-harness/features/ov3-owns-the-objective.feature, lines 339-390).
const controls = path.join(here, "controls");
const packetText = fs.readFileSync(path.join(controls, "census-1.bee2eee7.evidence.json"), "utf8");
const packet = JSON.parse(packetText);
const record = {
  kind: "flight",
  caseId: "census-1-provider-calls",
  runId: "bee2eee7-755d-c85f-2a1c-9b5506272cf7",
  evidenceDigest: "sha256:" + sha(packetText),
  plan: { agentId: "claude-code-opus-5-5-ov3-harness-census", planRevision: 1, planDigest: "sha256:698d488c222fd96af1d710c870e8145696b3a79f423eaace1731e9732ef72006" },
  steps: [
    { stepId: "write-census", providerTag: "@provider:ask-model", acceptedGraphDigest: "sha256:f6563ca4e5e09732a861f0743c092e8023df1cf31c57cc6144deb226d60e8751",
      returnedOutcome: "MODEL_RESPONSE_OBTAINED", expect: { path: "$.disposition", equals: "MODEL_RESPONSE_OBTAINED" } },
    { stepId: "check-census", providerTag: "@provider:sql-database-reader", acceptedGraphDigest: "sha256:dbb29dc8172312c3546bb706e32b30c32b59cb1ecad3b4dfff7e35826f6f0596",
      returnedOutcome: "READ", expect: { path: "$.value.status", equals: "CENSUS_READY" } },
  ],
};
const recW = write(path.join(controls, "census-1.acceptance.json"), json(record));
note("census-1-provider-calls", recW, { evidence: "census-1.bee2eee7.evidence.json" });
const packetW = { $path: "conformance/controls/census-1.bee2eee7.evidence.json", sha256: sha(packetText) };
const clone = (o) => JSON.parse(JSON.stringify(o));
const ev = (p, cursor) => p.events.find((e) => e.cursor === cursor);
const neg = path.join(controls, "census-negative");
const acceptanceCases = [{ id: "census-1-provider-calls", defect: "none: the recorded census provider calls", recW, evW: packetW, expect: "status=ACCEPTED" }];
const control = (id, defect, expect, mutateRecord, mutatePacket, tamper) => {
  const r = clone(record);
  let evW = packetW;
  if (mutatePacket) {
    const p = clone(packet);
    mutatePacket(p);
    const text = json(p);
    evW = write(path.join(neg, id + ".evidence.json"), text);
    r.evidenceDigest = "sha256:" + sha(text);
  }
  if (tamper) {
    const p = clone(packet);
    tamper(p);
    evW = write(path.join(neg, id + ".evidence.json"), json(p));
  }
  if (mutateRecord) mutateRecord(r);
  const rW = write(path.join(neg, id + ".acceptance.json"), json(r));
  note(id, rW, { evidence: evW.$path });
  acceptanceCases.push({ id, defect, recW: rW, evW, expect });
};
const write4 = (r) => r.steps[0];
control("capability-tag-only", "a required provider named only by a capability tag", "status=REJECTED;PROVIDER_TAG_MISSING=1",
  (r) => { write4(r).providerTag = "@capability:ask-model"; });
control("tag-case-differs", "a provider tag differing only in case", "status=REJECTED;PROVIDER_UNKNOWN=1",
  (r) => { write4(r).providerTag = "@provider:Ask-Model"; });
control("tag-not-step-binding", "a tag for a capability absent from the accepted step binding", "status=REJECTED;PROVIDER_TAG_NOT_STEP_BINDING=1",
  (r) => { write4(r).providerTag = "@provider:sql-database-reader"; });
control("other-plan-revision", "a different plan revision or digest", "status=REJECTED;PLAN_MISMATCH=1",
  (r) => { r.plan.planRevision = 2; });
control("other-graph-digest", "a different provider graph digest from the accepted pin", "status=REJECTED;GRAPH_DIGEST_MISMATCH=1",
  (r) => { write4(r).acceptedGraphDigest = "sha256:" + "0".repeat(64); });
control("substituted-provider", "a substituted provider returning a plausible census", "status=REJECTED;PROVIDER_SUBSTITUTED=1", null,
  (p) => { ev(p, 778).capabilityId = "census-shadow-model"; ev(p, 784).graphId = "graph:census-shadow-model"; ev(p, 784).canonicalGraphDigest = "sha256:" + "1".repeat(64); });
control("graph-without-outcome", "only a captured graph and no invocation outcome", "status=REJECTED;OUTCOME_NOT_RETURNED=1", null,
  (p) => { p.events = p.events.filter((e) => e.cursor !== 839); });
control("another-run", "the right provider invoked only in another run", "status=REJECTED;RUN_MISMATCH=1", null,
  (p) => { const other = "0d0d0d0d-0000-4000-8000-000000000001"; p.runId = other; for (const e of p.events) e.eventId = e.eventId.replace(record.runId, other); });
control("another-step", "the right provider invoked only in another step", "status=REJECTED;CALL_IN_ANOTHER_STEP=2", null,
  (p) => { ev(p, 778).cursor = 935; ev(p, 784).cursor = 936; ev(p, 839).cursor = 937; p.events.sort((a, b) => a.cursor - b.cursor); });
control("another-attempt", "the right provider invoked only in another attempt", "status=REJECTED;OUTCOME_MISMATCH=1", null,
  (p) => {
    const inv = ev(p, 778), g = ev(p, 784);
    const id = (c) => inv.eventId.replace(/:\d+$/, ":" + c);
    p.events.push({ ...inv, eventId: id(770), cursor: 770 }, { ...g, eventId: id(771), cursor: 771 },
      { eventId: id(772), cursor: 772, at: inv.at, kind: "execution-outcome-returned.v1", rootExecutionId: inv.rootExecutionId, disposition: "completed", outcomeVariant: "MODEL_REQUEST_FAILED", payloadKind: "return" });
    p.events.sort((a, b) => a.cursor - b.cursor);
    const s = p.steps.find((x) => x.stepId === "write-census");
    s.attempts = [{ attempt: 1, status: "FAILED", actual: "MODEL_REQUEST_FAILED", resultStatus: "MODEL_REQUEST_FAILED", receipt: null }, { ...s.attempts[0], attempt: 2 }];
  });
control("unsatisfying-outcome", "a returned outcome that does not satisfy the step", "status=REJECTED;OUTCOME_MISMATCH=1", null,
  (p) => { ev(p, 839).outcomeVariant = "MODEL_REQUEST_FAILED"; const a = p.steps.find((x) => x.stepId === "write-census").attempts[0]; a.status = "FAILED"; a.actual = "MODEL_REQUEST_FAILED"; });
control("attribution-gap", "an evidence gap that prevents attribution of the required call", "status=REJECTED;EVIDENCE_ATTRIBUTION_GAP=1", null,
  (p) => { p.events = p.events.filter((e) => e.cursor !== 660); });
control("tampered-evidence", "evidence bytes that are not the pinned bytes", "status=REJECTED;EVIDENCE_DIGEST_MISMATCH=1", null, null,
  (p) => { ev(p, 839).outcomeVariant = "MODEL_RESPONSE_OBTAINED_AGAIN"; });

// Reveal: one case proven only by its own call (reviewer's tests on reveal-stale-pin).
const revealFeature = "reveal-estate-workflows/reveal-estate-workflows.feature";
const revealText = fs.readFileSync(path.join(root, revealFeature), "utf8");
const revealW = { $path: revealFeature, sha256: sha(revealText) };
const staleRow = revealText.split("\n").find((l) => /\|\s*\$\.status\s*\|\s*STALE\s*\|/.test(l));
if (!staleRow) throw new Error("the STALE assertion row was not found");
const withoutStale = revealText.split("\n").filter((l) => l !== staleRow).join("\n");
const withoutW = write(path.join(here, "fixtures", "reveal-without-stale-assertion.feature"), withoutStale);
const staleText = fs.readFileSync(path.join(controls, "reveal-stale.d1175d72.evidence.json"), "utf8");
const resolvedText = fs.readFileSync(path.join(controls, "reveal-resolved.f6b88ab2.evidence.json"), "utf8");
const staleW = { $path: "conformance/controls/reveal-stale.d1175d72.evidence.json", sha256: sha(staleText) };
const resolvedW = { $path: "conformance/controls/reveal-resolved.f6b88ab2.evidence.json", sha256: sha(resolvedText) };
const wrong = JSON.parse(staleText); wrong.result.value.status = "RESOLVED";
const wrongW = write(path.join(controls, "reveal-negative", "stale-request-wrong-result.evidence.json"), json(wrong));
const callRecord = (runId, evText) => ({
  kind: "call", caseId: "reveal-stale-pin", runId, evidenceDigest: "sha256:" + sha(evText), operation: "reveal-estate-workflows.reveal",
  providerTag: "@provider:sql-database-reader", acceptedGraphDigest: "sha256:dbb29dc8172312c3546bb706e32b30c32b59cb1ecad3b4dfff7e35826f6f0596",
  returnedOutcome: "READ", requestPath: "$.input", valuePath: "$.value",
});
const staleRecW = write(path.join(controls, "reveal-stale-pin.acceptance.json"), json(callRecord("d1175d72-3312-0ecc-e80e-8eceabaf12e5", staleText)));
const resolvedRecW = write(path.join(controls, "reveal-negative", "resolved-run-as-stale-proof.acceptance.json"), json(callRecord("f6b88ab2-2071-a30f-15f7-94f4f73d5c51", resolvedText)));
const wrongRecW = write(path.join(controls, "reveal-negative", "stale-request-wrong-result.acceptance.json"), json(callRecord("d1175d72-3312-0ecc-e80e-8eceabaf12e5", json(wrong))));
note("reveal-stale-pin", staleRecW, { evidence: staleW.$path });
note("resolved-run-as-stale-proof", resolvedRecW, { evidence: resolvedW.$path });
note("stale-request-wrong-result", wrongRecW, { evidence: wrongW.$path });
note("reveal-without-stale-assertion", withoutW, {});
const revealCases = [
  { id: "reveal-stale-pin", defect: "none: the STALE run proves the STALE case", recW: staleRecW, featureW: revealW, evW: staleW, expect: "status=ACCEPTED" },
  { id: "resolved-run-as-stale-proof", defect: "the RESOLVED run offered as the STALE case's proof", recW: resolvedRecW, featureW: revealW, evW: resolvedW, expect: "status=REJECTED;EVIDENCE_REQUEST_MISMATCH=1" },
  { id: "stale-assertion-removed", defect: "the STALE case with its status assertion removed", recW: staleRecW, featureW: withoutW, evW: staleW, expect: "status=REJECTED;CASE_STATUS_UNASSERTED=1" },
  { id: "stale-request-wrong-result", defect: "the STALE case's own request with a result that is not STALE", recW: wrongRecW, featureW: revealW, evW: wrongW, expect: "status=REJECTED;ASSERTION_FAILED=1" },
];

// Static drift: each fixture changes one line of a feature that conforms to compile-capability-dsl's declared circuit.
const base = `# Drift fixture of check-capability-feature-conformance. The base conforms to the declared circuit of
# compile-capability-dsl; each fixture changes it in one place.

@capability:compile-capability-dsl
@root-scenario:compile-capability-dsl
Feature: Compile capability DSL

  @scenario:compile-capability-dsl
  @input:compile-capability-dsl-request
  @input-contract:compile-capability-dsl-request.v1
  @event:compile-capability-dsl-requested
  @event-authority:compile-capability-dsl.v1
  @outcome:compile-capability-dsl
  @outcome-contract:compile-capability-dsl-result.v1
  @outcome-terminal
  Rule: The declared circuit

    @case:drift-base
    Scenario: A source that is not on the grammar refuses
      Given DSL source text on the declared grammar
        """json
        {"source":"capability x"}
        """
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path     | equals  |
        | compile-capability-dsl.compile | $.status | REFUSED |
`;
const scenarioBlock = base.slice(base.indexOf("    @case:drift-base"));
const extraRule = (tags, caseId) => `
  ${tags}Rule: Another rule

    @case:${caseId}
` + scenarioBlock.split("\n").slice(1).join("\n");
const drift = [
  ["base-conforms", "nothing", "status=CONFORMANT", (t) => t],
  ["feature-capability", "a @capability tag naming another capability", "status=DRIFT;FEATURE_CAPABILITY_MISMATCH=1", (t) => t.replace("@capability:compile-capability-dsl\n", "@capability:compile-capability-dsl-v2\n")],
  ["root-scenario", "a @root-scenario that is not the declared entry", "status=DRIFT;ROOT_SCENARIO_MISMATCH=1", (t) => t.replace("@root-scenario:compile-capability-dsl\n", "@root-scenario:compile-capability-dsl-entry\n")],
  ["scenario-undeclared", "a feature scenario tag that names no declared scenario", "status=DRIFT;FEATURE_SCENARIO_UNDECLARED=1", (t) => t + extraRule("@scenario:compile-capability-dsl-extra\n  ", "drift-extra")],
  ["scenario-not-in-feature", "a declared scenario no case tags", "status=DRIFT;SCENARIO_NOT_IN_FEATURE=1", (t) => t.slice(0, t.indexOf("    @case:drift-base"))],
  ["scenario-tag-missing", "a case that tags no scenario", "status=DRIFT;SCENARIO_TAG_MISSING=1", (t) => t + extraRule("", "drift-untagged")],
  ["input-identity", "an @input the scenario does not declare", "status=DRIFT;INPUT_IDENTITY_MISMATCH=1", (t) => t.replace("@input:compile-capability-dsl-request\n", "@input:compile-capability-dsl-input\n")],
  ["input-contract", "an @input-contract the scenario does not declare", "status=DRIFT;INPUT_CONTRACT_MISMATCH=1", (t) => t.replace("@input-contract:compile-capability-dsl-request.v1", "@input-contract:compile-capability-dsl-request.v2")],
  ["event-identity", "the greeting's @event", "status=DRIFT;EVENT_IDENTITY_MISMATCH=1", (t) => t.replace("@event:compile-capability-dsl-requested", "@event:compile-capability-dsl")],
  ["event-authority", "an @event-authority the scenario does not declare", "status=DRIFT;EVENT_AUTHORITY_MISMATCH=1", (t) => t.replace("@event-authority:compile-capability-dsl.v1", "@event-authority:compile-capability-dsl.v2")],
  ["outcome-identity", "the greeting's @outcome", "status=DRIFT;OUTCOME_IDENTITY_MISMATCH=1", (t) => t.replace("@outcome:compile-capability-dsl\n", "@outcome:compile-capability-dsl-greeting\n")],
  ["outcome-contract", "the greeting's @outcome-contract", "status=DRIFT;OUTCOME_CONTRACT_MISMATCH=1", (t) => t.replace("@outcome-contract:compile-capability-dsl-result.v1", "@outcome-contract:compile-capability-dsl-greeting.v1")],
  ["outcome-terminal", "no @outcome-terminal on a terminal scenario", "status=DRIFT;OUTCOME_TERMINAL_MISMATCH=1", (t) => t.replace("  @outcome-terminal\n", "")],
  ["declared-step", "a declared step the feature does not hold", "status=DRIFT;SCENARIO_STEP_NOT_IN_FEATURE=1", (t) => t.replace("When the resolver parses every line and validates the whole document", "When the resolver parses each line")],
  ["provider-unknown", "a provider tag differing only in case", "status=DRIFT;PROVIDER_UNKNOWN=1", (t) => t.replace("    @case:drift-base\n", "    @case:drift-base\n    @provider:Sql-Database-Reader\n")],
  ["outcome-undeclared", "a status the circuit cannot return", "status=DRIFT;OUTCOME_UNDECLARED=1", (t) => t.replace("| $.status | REFUSED |", "| $.status | COMPILING |")],
  ["operation-undeclared", "an assertion on an operation the scenario does not declare", "status=DRIFT;ASSERTION_OPERATION_UNDECLARED=1", (t) => t.replace("        | compile-capability-dsl.compile | $.status", "        | compile-capability-dsl.parse   | $.status")],
  ["case-identity-missing", "a case without @case", "status=DRIFT;CASE_IDENTITY_MISSING=1", (t) => t.replace("    @case:drift-base\n", "")],
  ["case-identity-duplicate", "two cases with one @case", "status=DRIFT;CASE_IDENTITY_DUPLICATE=1", (t) => t + "\n" + scenarioBlock],
  ["case-identity-ambiguous", "one case with two @case tags", "status=DRIFT;CASE_IDENTITY_AMBIGUOUS=1", (t) => t.replace("    @case:drift-base\n", "    @case:drift-base\n    @case:drift-again\n")],
  ["case-request-missing", "a case without a json request", "status=DRIFT;CASE_REQUEST_MISSING=1", (t) => t.replace('        """json\n        {"source":"capability x"}\n        """\n', "")],
  ["case-request-invalid", "a json request that does not parse", "status=DRIFT;CASE_REQUEST_INVALID=1", (t) => t.replace('{"source":"capability x"}', '{source: capability x}')],
  ["case-assertion-missing", "a case without an operation | path | equals table", "status=DRIFT;CASE_ASSERTION_MISSING=1", (t) => t.slice(0, t.indexOf("        | operation"))],
  ["case-status-unasserted", "assertions that never read $.status", "status=DRIFT;CASE_STATUS_UNASSERTED=1", (t) => t.replace("| $.status | REFUSED |", "| $.sourceDigest | REFUSED |")],
  ["parse-error", "a tag line that no keyword follows", "status=DRIFT;GHERKIN_PARSE_ERROR=1", (t) => t.replace("      When the resolver", "      @stray\n      When the resolver")],
];
const driftCases = drift.map(([id, defect, expect, f]) => {
  const w = write(path.join(here, "fixtures", "drift", id + ".feature"), f(base));
  note("drift:" + id, w, {});
  return { id, defect, featureW: w, expect };
});

// Case lists for run-check.mjs.
const cases = {
  acceptance: acceptanceCases.map((c) => ({ name: c.id, request: { acceptance: jsonRef(c.recW), evidenceText: textRef(c.evW) }, expect: [["$.summary.signature", c.expect]] })),
  reveal: revealCases.map((c) => ({ name: c.id, request: { acceptance: jsonRef(c.recW), featureText: textRef(c.featureW), evidenceText: textRef(c.evW) }, expect: [["$.summary.signature", c.expect]] })),
  drift: driftCases.map((c) => ({ name: c.id, request: { capabilityId: "compile-capability-dsl", featureText: textRef(c.featureW) }, expect: [["$.summary.signature", c.expect]] })),
};
for (const [k, v] of Object.entries(cases)) fs.writeFileSync(path.join(outDir, "cases-" + k + ".json"), JSON.stringify(v, null, 1));
fs.writeFileSync(path.join(here, "controls", "manifest.json"), json({ note: "sha256 of every control and fixture file, written by conformance/make-controls.mjs", files: manifest }));
const table = (rows) => rows.map((r) => `${r.id} | ${r.defect} | ${r.expect}`).join("\n");
console.log("acceptance:\n" + table(acceptanceCases) + "\nreveal:\n" + table(revealCases) + "\ndrift:\n" + table(driftCases));
console.log("reveal feature sha256", revealW.sha256, "without-stale sha256", withoutW.sha256);
