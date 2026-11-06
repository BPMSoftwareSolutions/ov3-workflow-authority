// Catalog maintenance and section access in the estate: seven capabilities, two SQL runs and one OV3 flight.
//   nerdery/features/<capability>.feature   the owner-review candidates of the five catalog changes and of section access,
//                                           finalized as make-slice.mjs finalizes the slice's (requests, steps and Then
//                                           tables unchanged, verified below), and nerdery-view-catalog-for-maintenance
//   nerdery/dsl/<capability>.dsl            pins each feature's bytes; one sql-database-reader operation on sfx-identity
//   nerdery/catalog-compile-cases.json      their read-only compiles (conformance/run-compile.mjs)
//   nerdery/sql/catalog-1-estate(.commit).sql   estate: retains the seven features and the flight's promise, and compiles
//                                               one source to its reviewed document against them
//   nerdery/sql/catalog-2-identity(.commit).sql sfx-identity: installs the seven procedures and the dispatcher that reaches
//                                               them, gives Avery the biologist role beside the citizen one, and records
//                                               the flight's plan
//   nerdery/flights/catalog.steps.json      the plan: declare each capability from its DSL, prove each stored document
// The mechanics met all 44 cases of these features read-only (runs 869e7203, 669ba146, dce56efb), and the nine declared
// capabilities' 83 cases again with them (nerdery/conformance/run-cases.mjs). Until COMPILED holds each compile, this
// writes only the features, the DSL and the compile cases.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import { readCases } from "./app/lib/cases.mjs";
const here = path.dirname(fileURLToPath(import.meta.url));
const SRC = path.resolve(here, "..", "..", "nerdery-canonical-features");
const read = (p) => fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n");
const sha = (s) => crypto.createHash("sha256").update(Buffer.from(s, "utf8")).digest("hex");
const lit = (s) => {
  if (/^\s*GO\s*$/im.test(s)) throw new Error("a GO line inside a literal");
  if (/[^\x09\x0a\x20-\x7e]/.test(s)) throw new Error("non-ASCII inside a literal");
  return "N'" + s.split("'").join("''") + "'";
};
const RUNS = "869e7203, 669ba146, dce56efb";
const FROM_PACKAGE = ["nerdery-update-animal-definition", "nerdery-remove-animal-definition", "nerdery-add-animal-attribute",
  "nerdery-update-animal-attribute", "nerdery-remove-animal-attribute", "nerdery-resolve-wildlife-access"];
const OWN = ["nerdery-view-catalog-for-maintenance"];
const CAPS = [...FROM_PACKAGE, ...OWN];
const PROCEDURES = ["update_animal_definition", "remove_animal_definition", "add_animal_attribute", "update_animal_attribute", "remove_animal_attribute",
  "view_catalog_for_maintenance", "resolve_wildlife_access"];
const OWNER = "565de6d4-ebcd-408b-9359-04d21dc62183";
const AGENT = "claude-code-opus-5-5-nerdery-slice";
const PROMISE = "nerdery-catalog-maintenance-and-access";
const CARRY = "sfx-vault-reference-carry-port.v1";
// Live reads and the photo flight's records: the dispatcher photo-2-identity installed, the agent's current plan (the photo
// flight's, flown), the compiler round 2 installed, and the mint.
const BASE = { invoke: "sha256:ba3aa04ed0e8eecbce3e0165db43365513f97e522853838ba174f78b9d90350a",
  plan: "sha256:aa443b90cf0930cc05349f65195280f42b8ef644dbe910fdc286896e57f96b70",
  compiler: "sha256:a437984d1e7691557b473adb9b1650467ecb67a40e9a6b1251f4f7c01d3a9a81",
  mint: "sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e" };
// The read-only compile of each DSL against its retained feature with the installed compiler.
const COMPILED = {
  "nerdery-update-animal-definition": { run: "23fd22c6", documentDigest: "sha256:d233ad634537615b209520768f2e4be93e3dd525000c87a6f682075fba533d28" },
  "nerdery-remove-animal-definition": { run: "54926d90", documentDigest: "sha256:d9a56175a0ceadc83e954266c801270f602c02eab30e49b0eebfc300a3527d5a" },
  "nerdery-add-animal-attribute": { run: "2e2e96a2", documentDigest: "sha256:35d6f9c153b73c0404a7d2c7ce312116e1b65b57d0829d2632110939d10fbb01" },
  "nerdery-update-animal-attribute": { run: "3c354cd6", documentDigest: "sha256:eda0c93e20cc3494b87b6b988c3ad5290c07b2c3f437dc271badb34ad2f5d483" },
  "nerdery-remove-animal-attribute": { run: "48ec1966", documentDigest: "sha256:c0bddb3d44760553adef2fd47c5acd0b1cc83e3a6cdb7865f6a3f8199d7c4334" },
  "nerdery-resolve-wildlife-access": { run: "69ecbca8", documentDigest: "sha256:335ef2af50f211bd846c403e9465299c989259114f34769bb4a3733014654c2e" },
  "nerdery-view-catalog-for-maintenance": { run: "a6f0c470", documentDigest: "sha256:80a4daab4d372f2a4025313631beb63bb96309f0f200268da49b88ab46ac3756" }
};

// ---------- the features ----------
const swap = (text, a, b, what) => { if (!text.includes(a)) throw new Error(`${what}: missing ${a.slice(0, 70)}`); return text.split(a).join(b); };
const sameCases = (a, b, what) => {
  const x = readCases(a), y = readCases(b);
  if (x.length !== y.length || x.some((c, i) => JSON.stringify([c.caseId, c.steps, c.request, c.then]) !== JSON.stringify([y[i].caseId, y[i].steps, y[i].request, y[i].then])))
    throw new Error(`${what}: the cases changed`);
};
const features = {};
for (const cap of FROM_PACKAGE) {
  const rel = `features/mvp/${cap}.feature`, original = read(path.join(SRC, rel));
  let t = original;
  t = swap(t, "# Status: feature candidate. The proposed capability is absent from estate model 34 (inventory run 49ae8acb).\n",
    `# Status: finalized for the SideFX build from the owner-review candidate\n# nerdery-canonical-features/${rel} (sha256:${sha(original)}).\n`, cap);
  t = swap(t, "# @status:not-built means this delivery contains no implementation or run evidence for the case.\n",
    `# @status:probed: the case ran read-only against the wildlife procedures through nerdery/conformance/run-cases.mjs\n# (runs ${RUNS}).\n`, cap);
  t = swap(t, "# Business provider candidates are named on each affected case. Bind and verify them before adding @provider tags.\n",
    "# Provider: the operation is one sql-database-reader statement on sfx-identity (EXEC wildlife.serve), so every case is\n# tagged @provider:sql-database-reader.\n", cap);
  t = t.replace(/^(\s*)# Proposed provider calls \(unbound\):[^\n]*\n/gm, "");
  t = t.replace(/^(\s*)# Local refusal before business-provider dispatch; acceptance requires no business call or mutation\.\n/gm,
    "$1# Refused inside the operation's one provider call; the stored state is unchanged.\n");
  t = t.replace(/^(\s*)# Arrangement: fixtures\/cases\//gm, "$1# Arrangement: nerdery-canonical-features/fixtures/cases/");
  t = t.replace(/^(\s*)@status:not-built\n(?!\1@provider:sql-database-reader\n)/gm, "$1@status:not-built\n$1@provider:sql-database-reader\n");
  t = t.replace(/^(\s*)@status:not-built\n/gm, "$1@status:probed\n");
  if (/unbound|@status:not-built/.test(t)) throw new Error(`${cap}: an unbound provider or a not-built case remains`);
  sameCases(original, t, cap);
  fs.writeFileSync(path.join(here, "features", `${cap}.feature`), t);
  features[cap] = { text: t, candidate: `sha256:${sha(original)}` };
}
for (const cap of OWN) features[cap] = { text: read(path.join(here, "features", `${cap}.feature`)) };
for (const cap of CAPS) {
  const t = features[cap].text, cases = readCases(t);
  if (cases.some((c) => !c.tags.includes("@status:probed") || c.tags.filter((x) => x === "@provider:sql-database-reader").length !== 1))
    throw new Error(`${cap}: every case needs @status:probed and one @provider:sql-database-reader`);
}

// ---------- the DSL, as make-slice.mjs writes the slice's ----------
const dslOf = (cap) => {
  const t = features[cap].text, cases = readCases(t);
  const shared = (keyword) => { const v = [...new Set(cases.map((c) => c.steps.find((s) => s.startsWith(`${keyword} `))))]; if (v.length !== 1) throw new Error(`${cap}: ${keyword} differs`); return v[0].slice(keyword.length + 1); };
  const ops = [...new Set(cases.flatMap((c) => c.then.map((r) => r[0])))];
  if (ops.length !== 1) throw new Error(`${cap}: operations ${ops}`);
  const variants = t.match(/terminal variants: ([A-Z_]+(?:, [A-Z_]+)*)\./)[1].split(", ");
  const title = t.match(/^Feature: (.+)$/m)[1], soThat = (t.match(/^\s*So that (.+)$/m) || [])[1] || "";
  const input = { type: "object", additionalProperties: false, required: ["request"], properties: {
    caller: { type: "object", additionalProperties: false, properties: { principalId: { type: "string" }, sessionId: { type: "string" } } }, request: { type: "object" } } };
  const output = { type: "object", additionalProperties: true, required: ["contractId", "status"], properties: { contractId: { const: `${cap}-result.v1` }, status: { enum: variants } } };
  const config = { dataSource: "sfx-identity-database", statement: `EXEC wildlife.serve @operation=N'${cap}',@input=@input;`, resultColumn: "value" };
  const dsl = [`capability ${cap}`, `feature ${cap} sha256:${sha(t)}`,
    `intent: ${title}, for the caller whose session the declared API operation verified (Nerdery wildlife application)`,
    `outcome: ${cap}-result.v1 ${variants.join(" or ")}, each refusal named by its reason code${soThat ? `, so that ${soThat}` : ""}`,
    `input contract ${cap}-request.v1 ${JSON.stringify(input)}`, `output contract ${cap}-result.v1 ${JSON.stringify(output)}`, "cli display outcome as json",
    `scenario ${cap} root terminal`, `given: ${shared("Given")}`, `when: ${shared("When")}`, `then: ${shared("Then")}`,
    `operation ${ops[0]} uses provider sql-database-reader`, `config: ${JSON.stringify(config)}`, `input input from ${cap} $`, `outcome from ${ops[0]} $.value`, ""].join("\n");
  if (/[^\x09\x0a\x20-\x7e]/.test(dsl)) throw new Error(`${cap}: non-ASCII DSL`);
  return { dsl, operation: ops[0], cases: cases.length };
};
const built = Object.fromEntries(CAPS.map((cap) => [cap, dslOf(cap)]));
for (const cap of CAPS) fs.writeFileSync(path.join(here, "dsl", `${cap}.dsl`), built[cap].dsl);
const compileCases = CAPS.map((cap) => ({ name: cap, source: `nerdery/dsl/${cap}.dsl`, retain: [`nerdery/features/${cap}.feature`],
  ...(COMPILED ? { compiledRun: COMPILED[cap].run } : {}),
  expect: [["$.status", "COMPILED"], ["$.document.feature.digest", `sha256:${sha(features[cap].text)}`],
    ["$.document.scenarios[0].operations[4].operationId", built[cap].operation], ["$.document.scenarios[0].operations[4].providerCapabilityId", "sql-database-reader"],
    ["$.document.scenarios[0].portBindings[2].platformCapabilityId", CARRY], ["$.document.scenarios[0].portBindings[7].platformCapabilityId", CARRY],
    ["$.document.scenarios[0].portBindings[3].configuration.commandTimeout", "30"], ["$.document.scenarios[0].portBindings[8].configuration.commandTimeout", "30"],
    ...(COMPILED ? [["$.documentDigest", COMPILED[cap].documentDigest]] : [])] }));
fs.writeFileSync(path.join(here, "catalog-compile-cases.json"), JSON.stringify(compileCases, null, 1) + "\n");
for (const cap of CAPS) console.log(cap.padEnd(40), String(built[cap].cases).padStart(3), `feature sha256:${sha(features[cap].text).slice(0, 12)}`, `dsl sha256:${sha(built[cap].dsl).slice(0, 12)}`);
if (!COMPILED) {
  console.log("compile them read-only: node conformance/run-compile.mjs nerdery/catalog-compile-cases.json <outBase>, then set COMPILED");
  process.exit(0);
}

// ---------- the mechanics ----------
const blocks = read(path.join(here, "wildlife/wildlife.procedures.sql")).split(/\nGO\n/).map((b) => b.replace(/^(--[^\n]*\n)+/, "").replace(/\s+$/, ""));
const block = (name) => { const b = blocks.find((x) => x.startsWith(`CREATE OR ALTER PROCEDURE ${name}\n`)); if (!b) throw new Error(`${name}: no block`); return b; };
const procs = PROCEDURES.map((p) => ({ name: `wildlife.${p}`, text: block(`wildlife.${p}`) }));
const invoke = block("wildlife.invoke_operation");
const verifyDigest = (b) => "sha256:" + sha(b.slice(b.indexOf("PROCEDURE ")).replace(/[\n\r \t]+$/, ""));
for (const b of [...procs.map((p) => p.text), invoke]) if (/[^\x09\x0a\x20-\x7e]/.test(b) || /^\s*GO\s*$/im.test(b)) throw new Error("a procedure text is not plain ASCII without GO");
const normalizedDigest = (object, v) => [`DECLARE @${v} nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'${object}')),NCHAR(13)+NCHAR(10),NCHAR(10));`,
  `SET @${v}=SUBSTRING(@${v},CHARINDEX(N'PROCEDURE ${object}',@${v}),DATALENGTH(@${v})/2);`,
  `WHILE DATALENGTH(@${v})>0 AND RIGHT(@${v},1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @${v}=LEFT(@${v},DATALENGTH(@${v})/2-1);`,
  `DECLARE @${v}_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@${v} COLLATE Latin1_General_100_BIN2_UTF8)),2));`];
const digestExpr = (object) => `'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'${object}')) COLLATE Latin1_General_100_BIN2_UTF8)),2))`;
const stop = (tag, why) => ["BEGIN", ` RAISERROR(N'${tag}: ${why.split("'").join("''")}',16,1);`, " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END"];

// ---------- one promise, one plan ----------
const fast = JSON.parse(read(path.join(here, "flights/fast-path.steps.json")));
const template = fast.steps.find((s) => s.stepId === "declare-view-collected-animals");
const short = (cap) => cap.replace(/^nerdery-/, "");
const promise = { contractId: "flight-promise.v1", promiseId: PROMISE, workClass: "owner-objective",
  statement: "OV3 declares the catalog maintenance of the Nerdery wildlife application (update and remove a definition; add, update and remove an attribute; the maintenance read) and its section access, feature first: each declaration binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT, and each stored document is exactly the reviewed one.",
  obligations: CAPS.map((cap, i) => ({ obligationId: `O${i + 1}`,
    statement: `${cap} is declared from nerdery/dsl/${cap}.dsl, pinned to its canonical feature sha256:${sha(features[cap].text)}, and its stored document is ${COMPILED[cap].documentDigest}.`,
    evidence: `apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest ${COMPILED[cap].documentDigest}` })) };
const steps = [{ stepId: "plan-header", contractId: "estate-flight-plan.v1", promiseId: PROMISE, flightType: "execution", workClass: "owner-objective", unknowns: [] }];
CAPS.forEach((cap, i) => {
  steps.push({ stepId: `declare-${short(cap)}`, capabilityId: "apply-declared-change",
    historicalBasis: `the slice's capabilities and nerdery-view-collected-animal were declared this way by capability-from-dsl (flight 9810b9af and the photo flight, plan sha256:aa443b90); this DSL compiles COMPILED to ${COMPILED[cap].documentDigest} against the retained bytes of its feature with the installed compiler (read-only run ${COMPILED[cap].run}), and its operation's mechanics met every case of that feature read-only (runs ${RUNS})`,
    input: { ...template.input, payload: { ...template.input.payload, source: built[cap].dsl } }, obligationIds: [`O${i + 1}`], expect: { path: "$.disposition", equals: "COMMITTED" } });
  steps.push({ stepId: `prove-${short(cap)}`, capabilityId: "read-declared-capability-document",
    historicalBasis: "read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler's documentDigest for the same source (the repair flights and the photo flight proved theirs this way)",
    input: { capabilityId: cap }, obligationIds: [`O${i + 1}`], expect: { path: "$.documentDigest", equals: COMPILED[cap].documentDigest } });
});
const objective = "Declare the catalog maintenance and section access of the Nerdery wildlife application, feature first through OV3's own changes: nerdery-update-animal-definition, nerdery-remove-animal-definition, nerdery-add-animal-attribute, nerdery-update-animal-attribute, nerdery-remove-animal-attribute, nerdery-resolve-wildlife-access and nerdery-view-catalog-for-maintenance, each with capability-from-dsl, which binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT; prove each stored document is exactly the reviewed one by its digest.";
const stepsJson = JSON.stringify(steps);
const planDigest = `sha256:${sha(`${objective}\u0000${stepsJson}`)}`;
const promiseText = JSON.stringify(promise);

// ---------- the files ----------
const files = {}, pairs = [];
const banner = (commit) => commit
  ? ["-- ============================== COMMIT - THIS WRITES ==============================", "-- Byte-identical to the preflight twin except this banner and the terminal statement:", "-- COMMIT TRANSACTION here, ROLLBACK TRANSACTION there. The preflight is optional: this file verifies everything inside", "-- its transaction and keeps nothing when a check fails."]
  : ["-- ============================== PREFLIGHT - NOT A WRITE ==============================", "-- Byte-identical to the .commit twin except this banner and the terminal statement:", "-- ROLLBACK TRANSACTION here, COMMIT TRANSACTION there. Nothing is written.", "--"];
const emitPair = (name, header, body) => {
  const texts = [];
  for (const commit of [false, true]) {
    const text = [`-- ${name}${commit ? ".commit" : ""}.sql`, "--", ...banner(commit), "--", ...header, ...body, commit ? "COMMIT TRANSACTION;" : "ROLLBACK TRANSACTION;", "GO", "SET NOEXEC OFF;", ""].join("\n");
    files[`sql/${name}${commit ? ".commit" : ""}.sql`] = text;
    texts.push(text);
  }
  const a = texts[0].split("\n"), b = texts[1].split("\n");
  if (a.length !== b.length) throw new Error("twin line counts");
  pairs.push({ name, differingLines: a.map((l, i) => (l === b[i] ? null : i + 1)).filter(Boolean) });
};
const retained = [...CAPS.map((cap) => [`capability-feature:${cap}`, features[cap].text]), [`flight-promise:${PROMISE}`, promiseText]];
const smoke = "nerdery-view-catalog-for-maintenance";
emitPair("catalog-1-estate", [
  "-- WHAT THIS DOES, in one transaction on the estate database:",
  "--   1. retains, through model.mint_content_artifact, the bytes of the canonical features of the seven capabilities the",
  `--      flight declares (catalog maintenance and section access) and the promise flight-promise:${PROMISE};`,
  `--   2. compiles ${smoke}'s DSL with the installed compiler against those bytes: COMPILED to`,
  `--      ${COMPILED[smoke].documentDigest}, the document the flight declares.`,
  "-- WHERE: the estate database. Run the whole file in one session (under a minute).",
  `-- BASES: compiler body ${BASE.compiler}, mint ${BASE.mint}, the no-drift check installed.`,
  `-- RESULT SETS: base; minted (${retained.length} rows); readback (retained 1 each); compile (status COMPILED, document = expected).`,
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  ...normalizedDigest("analysis.compile_capability_dsl", "cd"),
  `DECLARE @m varchar(80)=${digestExpr("model.mint_content_artifact")};`,
  "DECLARE @check int=CASE WHEN OBJECT_ID(N'analysis.check_capability_feature_conformance') IS NOT NULL THEN 1 ELSE 0 END;",
  `SELECT N'base' AS result_set,@cd_digest AS compiler_body,'${BASE.compiler}' AS compiler_expected,@m AS mint_installed,@check AS check_installed;`,
  `IF @cd_digest IS NULL OR @cd_digest<>'${BASE.compiler}' OR @m IS NULL OR @m<>'${BASE.mint}' OR @check<>1`,
  ...stop("CATALOG1_BASE", "the compiler, the mint or the check is not the reviewed base; nothing is changed."), "GO"], [
  "SET NOCOUNT ON;",
  "DECLARE @minted TABLE(ordinal int IDENTITY(1,1),value nvarchar(max));",
  ...retained.map(([kind, text]) => `INSERT @minted(value) EXEC model.mint_content_artifact @document=${lit(JSON.stringify({ artifactKind: kind, text }))};`),
  "SELECT N'minted' AS result_set,ordinal,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,JSON_VALUE(value,'$.content_digest') AS content_digest FROM @minted ORDER BY ordinal;",
  "DECLARE @want TABLE(ordinal int PRIMARY KEY,artifact_kind nvarchar(80),digest varchar(80));",
  `INSERT @want VALUES${retained.map(([kind, text], i) => `(${i + 1},N'${kind}','sha256:${sha(text)}')`).join(",")};`,
  "SELECT N'readback' AS result_set,w.ordinal,w.artifact_kind,w.digest,CASE WHEN EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=w.artifact_kind COLLATE Latin1_General_100_BIN2 AND a.content_digest=CONVERT(binary(32),SUBSTRING(w.digest,8,64),2)) THEN 1 ELSE 0 END AS retained FROM @want w ORDER BY w.ordinal;",
  "IF EXISTS(SELECT 1 FROM @want w WHERE NOT EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=w.artifact_kind COLLATE Latin1_General_100_BIN2 AND a.content_digest=CONVERT(binary(32),SUBSTRING(w.digest,8,64),2)))",
  ...stop("CATALOG1_VERIFY_FAILED", "a retained text is not under the digest of its reviewed bytes; nothing is kept."),
  "DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);",
  "DECLARE @in nvarchar(max),@r nvarchar(max);", "DECLARE @t TABLE(v nvarchar(max));",
  `SET @in=(SELECT ${lit(built[smoke].dsl)} AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);`,
  "INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;", "SELECT @r=v FROM @t;",
  `SELECT N'compile' AS result_set,JSON_VALUE(@r,N'$.status') AS status,JSON_VALUE(@r,N'$.documentDigest') AS document,'${COMPILED[smoke].documentDigest}' AS expected;`,
  `IF ISNULL(JSON_VALUE(@r,N'$.status'),N'')<>N'COMPILED' OR ISNULL(JSON_VALUE(@r,N'$.documentDigest'),N'')<>N'${COMPILED[smoke].documentDigest}'`,
  ...stop("CATALOG1_COMPILE_FAILED", "the DSL does not compile to the reviewed document against the retained feature; nothing is kept.")]);
const smokeCalls = [
  ["Casey reads the catalog for maintenance", "nerdery-view-catalog-for-maintenance", "{}", "user-bio", ["$.status", "VISIBLE"], ["$.definitions[0].definitionId", "animal-001"]],
  ["Blake reads the catalog for maintenance", "nerdery-view-catalog-for-maintenance", "{}", "user-b", ["$.reason.code", "BIOLOGIST_ROLE_REQUIRED"]],
  ["Casey opens the definitions administration", "nerdery-resolve-wildlife-access", `{"section":"animal-definitions-admin"}`, "user-bio", ["$.status", "ALLOWED"]],
  ["Blake opens the definitions administration", "nerdery-resolve-wildlife-access", `{"section":"animal-definitions-admin"}`, "user-b", ["$.reason.code", "BIOLOGIST_ROLE_REQUIRED"]],
  ["Blake opens his team", "nerdery-resolve-wildlife-access", `{"section":"team"}`, "user-b", ["$.status", "ALLOWED"]],
  ["Blake removes an attribute", "nerdery-remove-animal-attribute", `{"attributeId":"habitat","expectedRevision":1}`, "user-b", ["$.reason.code", "BIOLOGIST_ROLE_REQUIRED"]],
  ["Casey edits from a stale revision", "nerdery-update-animal-attribute", `{"attributeId":"habitat","expectedRevision":0,"attribute":{"name":"x","description":"x","selectableValues":[{"valueId":"x","label":"x"}]}}`, "user-bio", ["$.reason.code", "REVISION_CONFLICT"]]];
emitPair("catalog-2-identity", [
  "-- WHAT THIS DOES, in one transaction on the sfx-identity database:",
  "--   1. installs the mechanics of the seven capabilities: wildlife.update_animal_definition, remove_animal_definition,",
  "--      add_animal_attribute, update_animal_attribute, remove_animal_attribute, view_catalog_for_maintenance and",
  "--      resolve_wildlife_access. Their texts met all 44 cases of their features read-only (runs 869e7203, 669ba146,",
  "--      dce56efb);",
  "--   2. alters wildlife.invoke_operation to dispatch them and to answer a catalog change that cannot be stored as not applied;",
  "--   3. verifies every body by digest and calls the new operations as Casey (biologist) and Blake (citizen), changing nothing;",
  "--   4. gives Avery, the owner's principal, the biologist role beside the citizen one, so one SideFX session can show",
  "--      both the citizen journey and the catalog maintenance;",
  `--   5. records the plan of flight ${PROMISE} under planner agent ${AGENT} through evidence.upsert_flight_plan:`,
  "--      declare each capability from its DSL and prove its stored document. The plan is nerdery/flights/catalog.steps.json;",
  `--      its digest is ${planDigest}.`,
  "-- RUN catalog-1-estate FIRST. WHERE: sfx-identity. Run the whole file in one session (a few seconds).",
  `-- BASES: wildlife.invoke_operation ${BASE.invoke}, none of the seven procedures yet, the owner principal active and`,
  `-- mapped to user-a, the plan writer's four parameters, the agent's current plan ${BASE.plan} (the photo flight, flown).`,
  "-- RESULT SETS: base; verify (digest_matches 1 each); smoke (every passed 1); roles; plans (matches_reviewed_file 1).",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  `DECLARE @p uniqueidentifier='${OWNER}';`,
  ...normalizedDigest("wildlife.invoke_operation", "io"),
  `DECLARE @present int=(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'wildlife') AND name IN (${PROCEDURES.map((p) => `N'${p}'`).join(",")}));`,
  "DECLARE @owner int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id=@p AND active=1),",
  " @mapped int=(SELECT COUNT(*) FROM wildlife.app_user WHERE principal_id=@p AND user_id=N'user-a'),",
  " @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));",
  `DECLARE @current binary(32)=(SELECT plan_digest FROM evidence.flight_plan WHERE principal_id=@p AND agent_id=${lit(AGENT)});`,
  "SELECT N'base' AS result_set,@io_digest AS dispatcher_installed,@present AS new_procedures_present,@owner AS owner_principal_active,@mapped AS owner_is_user_a,",
  " @params AS plan_writer_parameters,N'sha256:'+LOWER(CONVERT(varchar(64),@current,2)) AS current_plan;",
  `IF @io_digest IS NULL OR @io_digest<>'${BASE.invoke}' OR @present<>0 OR @owner<>1 OR @mapped<>1 OR @params<>4 OR @current IS NULL OR @current<>CONVERT(binary(32),'${BASE.plan.slice(7)}',2)`,
  ...stop("CATALOG2_BASE", "the dispatcher, the procedures, the owner principal or its user, the plan writer or the agent's current plan is not the reviewed base; nothing is changed."),
  "GO", ...procs.flatMap((p) => [p.text, "GO"]), invoke, "GO"], [
  "SET NOCOUNT ON;",
  `DECLARE @p uniqueidentifier='${OWNER}';`,
  "DECLARE @digests TABLE(object_name nvarchar(200),digest varchar(80));",
  ...[...procs, { name: "wildlife.invoke_operation", text: invoke }].flatMap((p, i) => [...normalizedDigest(p.name, `v${i}`), `INSERT @digests VALUES(N'${p.name}',@v${i}_digest);`]),
  `DECLARE @want TABLE(object_name nvarchar(200),digest varchar(80)); INSERT @want VALUES${[...procs, { name: "wildlife.invoke_operation", text: invoke }].map((p) => `(N'${p.name}','${verifyDigest(p.text)}')`).join(",")};`,
  "SELECT N'verify' AS result_set,w.object_name,w.digest AS reviewed,d.digest AS installed,CASE WHEN d.digest=w.digest THEN 1 ELSE 0 END AS digest_matches FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name ORDER BY w.object_name;",
  "DECLARE @smoke TABLE(o int IDENTITY(1,1),item nvarchar(200),actual nvarchar(400),expected nvarchar(400),passed bit);",
  "DECLARE @r nvarchar(max);", "DECLARE @before varchar(64)=CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(SELECT (SELECT * FROM wildlife.attribute ORDER BY attribute_id FOR JSON PATH) AS a,(SELECT definition_id,revision,active FROM wildlife.animal_definition ORDER BY definition_id FOR JSON PATH) AS d FOR JSON PATH,WITHOUT_ARRAY_WRAPPER))),2);",
  ...smokeCalls.flatMap(([item, op, req, user, ...expects]) => [`EXEC wildlife.invoke_operation @operation=N'${op}',@request=${lit(req)},@user_id=N'${user}',@result=@r OUTPUT;`,
    ...expects.map(([p, eq]) => `INSERT @smoke(item,actual,expected,passed) VALUES(${lit(`${item}: ${p}`)},JSON_VALUE(@r,N'${p}'),N'${eq}',CASE WHEN JSON_VALUE(@r,N'${p}')=N'${eq}' THEN 1 ELSE 0 END);`)]),
  "DECLARE @after varchar(64)=CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(SELECT (SELECT * FROM wildlife.attribute ORDER BY attribute_id FOR JSON PATH) AS a,(SELECT definition_id,revision,active FROM wildlife.animal_definition ORDER BY definition_id FOR JSON PATH) AS d FOR JSON PATH,WITHOUT_ARRAY_WRAPPER))),2);",
  "INSERT @smoke(item,actual,expected,passed) VALUES(N'the refused and read calls changed no catalog row',@after,@before,CASE WHEN @after=@before THEN 1 ELSE 0 END);",
  "SELECT N'smoke' AS result_set,item,actual,expected,passed FROM @smoke ORDER BY o;",
  "IF EXISTS(SELECT 1 FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name WHERE d.digest IS NULL OR d.digest<>w.digest) OR EXISTS(SELECT 1 FROM @smoke WHERE passed=0)",
  ...stop("CATALOG2_VERIFY_FAILED", "an installed body is not the reviewed text, or a call did not answer as tested; nothing is kept."),
  "IF NOT EXISTS(SELECT 1 FROM wildlife.user_role WHERE user_id=N'user-a' AND role=N'biologist') INSERT wildlife.user_role(user_id,role) VALUES(N'user-a',N'biologist');",
  "SELECT N'roles' AS result_set,user_id,role FROM wildlife.user_role WHERE user_id=N'user-a' ORDER BY role;",
  "IF (SELECT COUNT(*) FROM wildlife.user_role WHERE user_id=N'user-a' AND role IN (N'citizen',N'biologist'))<>2",
  ...stop("CATALOG2_ROLES_FAILED", "Avery does not hold both the citizen and the biologist role; nothing is kept."),
  "DECLARE @plans TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));",
  `INSERT @plans EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=${lit(AGENT)},@objective=${lit(objective)},`, ` @steps_json=${lit(stepsJson)};`,
  `SELECT N'plans' AS result_set,${lit(AGENT)} AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'${planDigest.slice(7)}',2) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @plans;`,
  `IF NOT EXISTS(SELECT 1 FROM @plans WHERE plan_digest=CONVERT(binary(32),'${planDigest.slice(7)}',2))`,
  ...stop("CATALOG2_PLAN_MISMATCH", "the recorded plan is not the reviewed one; nothing is kept.")]);
files["flights/catalog.steps.json"] = JSON.stringify({ agentId: AGENT, promise, objective, planDigest, steps }, null, 2) + "\n";

// ---------- write and verify ----------
for (const [rel, text] of Object.entries(files)) {
  if (/[^\x09\x0a\x20-\x7e]/.test(text)) throw new Error(`${rel}: non-ASCII`);
  fs.writeFileSync(path.join(here, rel), text);
}
const unlit = (l) => l.slice(2, -1).split("''").join("'");
for (const suffix of ["", ".commit"]) {
  const t2 = files[`sql/catalog-2-identity${suffix}.sql`], m = t2.match(/@steps_json=(N'(?:[^']|'')*');/), o = t2.match(/@objective=(N'(?:[^']|'')*'),/);
  if (!m || unlit(m[1]) !== stepsJson || !o || unlit(o[1]) !== objective) throw new Error("catalog-2: plan literal round trip");
  const batches = t2.split("\nGO\n");
  if (procs.some((p, i) => batches[i + 1] !== p.text) || batches[procs.length + 1] !== invoke) throw new Error("catalog-2: the install batches are not the reviewed texts");
  const t1 = files[`sql/catalog-1-estate${suffix}.sql`];
  const docs = [...t1.matchAll(/@document=(N'(?:[^']|'')*');/g)].map((x) => JSON.parse(unlit(x[1])));
  if (docs.length !== retained.length || docs.some((d, i) => d.artifactKind !== retained[i][0] || d.text !== retained[i][1])) throw new Error("catalog-1: retained literal round trip");
}
const out = { generated: "2026-11-03", capabilities: CAPS.map((cap) => ({ capabilityId: cap, cases: built[cap].cases, feature: `sha256:${sha(features[cap].text)}`,
  dsl: `sha256:${sha(built[cap].dsl)}`, document: COMPILED[cap].documentDigest, compiledRun: COMPILED[cap].run, ...(features[cap].candidate ? { candidate: features[cap].candidate } : {}) })),
  plannerAgentId: AGENT, promiseId: PROMISE, promiseDigest: `sha256:${sha(promiseText)}`, planDigest, steps: steps.length - 1,
  procedures: [...procs, { name: "wildlife.invoke_operation", text: invoke }].map((p) => ({ name: p.name, verifyDigest: verifyDigest(p.text) })), twinParity: pairs,
  files: Object.keys(files).map((f) => ({ file: `nerdery/${f}`, bytes: Buffer.byteLength(files[f]), sha256: `sha256:${sha(files[f])}` })) };
fs.writeFileSync(path.join(here, "manifest.catalog.json"), JSON.stringify(out, null, 1) + "\n");
console.log(JSON.stringify({ planDigest, promiseDigest: out.promiseDigest, steps: out.steps, twinParity: pairs }, null, 1));
