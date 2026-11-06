// Sign-up and sign-in through the DNR identity service, in the estate: two capabilities, two SQL runs and one OV3 flight.
// The brief: users sign up for an account and log in with the DNR's existing identity technology; user roles are
// managed outside the application for MVP; citizens collect and build a team; biologists also maintain the catalog.
//   nerdery/features/<capability>.feature   the owner-review candidates of sign-in and registration, finalized as
//                                           make-slice.mjs finalizes the slice's (cases unchanged, verified below)
//   nerdery/dsl/<capability>.dsl            pins each feature's bytes; one sql-database-reader operation on sfx-identity
//   nerdery/identity-compile-cases.json     their read-only compiles (conformance/run-compile.mjs)
//   nerdery/sql/identity-1-estate(.commit).sql   estate: retains the two features and the flight's promise, and compiles
//                                                one source to its reviewed document against them
//   nerdery/sql/identity-2-identity(.commit).sql sfx-identity: the DNR stand-in (wildlife.identity_response, seeded with
//                                                the fixture's responses) and the sign-ins (wildlife.signed_in_session); the
//                                                two procedures; the dispatcher and wildlife.serve, which now answer a
//                                                verified session as the user it signed in as; Avery back to the citizen
//                                                role alone; and the flight's plan
//   nerdery/flights/identity.steps.json     the plan: declare each capability from its DSL, prove each stored document
// The mechanics met all 12 cases of these features read-only (runs 8a8f1f45, 59995dd3, e8a9ae1e, d6230231), and the
// sixteen declared capabilities' 127 cases again with them. Until COMPILED holds each compile, this writes only the
// features, the DSL and the compile cases.
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
const RUNS = "8a8f1f45, 59995dd3, e8a9ae1e, d6230231";
const CAPS = ["nerdery-sign-in-wildlife-user", "nerdery-register-wildlife-user"];
const NEW_PROCEDURES = ["sign_in_wildlife_user", "register_wildlife_user"];
const OWNER = "565de6d4-ebcd-408b-9359-04d21dc62183";
const AGENT = "claude-code-opus-5-5-nerdery-slice";
const PROMISE = "nerdery-dnr-sign-up-and-sign-in";
const CARRY = "sfx-vault-reference-carry-port.v1";
// Live records: the dispatcher catalog-2-identity installed, wildlife.serve as nrd-01 installed it (read 2026-11-03,
// run 7f37814a), the agent's current plan (the catalog flight's, flown), the compiler round 2 installed, and the mint.
const BASE = { invoke: "sha256:" + JSON.parse(read(path.join(here, "manifest.catalog.json"))).procedures.find((p) => p.name === "wildlife.invoke_operation").verifyDigest.slice(7),
  serve: "sha256:7a15adba12661fb75a59a9a92914082b96fdc8b834c45d7e4fb9c3703a9b6a2e",
  plan: "sha256:0442d1cbd50c5944662d30d85027fdd9fef4cf928ad558a8a8693b996c99b50f",
  compiler: "sha256:a437984d1e7691557b473adb9b1650467ecb67a40e9a6b1251f4f7c01d3a9a81",
  mint: "sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e" };
// The read-only compile of each DSL against its retained feature with the installed compiler.
const COMPILED = {
  "nerdery-sign-in-wildlife-user": { run: "1dd86a71", documentDigest: "sha256:8d80e177396ad14f72b937aab911022b68f12b34b25fcd03628a9b8c21f389d9" },
  "nerdery-register-wildlife-user": { run: "3a10274e", documentDigest: "sha256:a015138ada6c7327a6c802401f08a1e213d537d7c3b3dac8cee6be7ee555bb01" }
};

// ---------- the features ----------
const swap = (text, a, b, what) => { if (!text.includes(a)) throw new Error(`${what}: missing ${a.slice(0, 70)}`); return text.split(a).join(b); };
const features = {};
for (const cap of CAPS) {
  const rel = `features/mvp/${cap}.feature`, original = read(path.join(SRC, rel));
  let t = original;
  t = swap(t, "# Status: feature candidate. The proposed capability is absent from estate model 34 (inventory run 49ae8acb).\n",
    `# Status: finalized for the SideFX build from the owner-review candidate\n# nerdery-canonical-features/${rel} (sha256:${sha(original)}).\n`, cap);
  t = swap(t, "# @status:not-built means this delivery contains no implementation or run evidence for the case.\n",
    `# @status:probed: the case ran read-only against the wildlife procedures through nerdery/conformance/run-cases.mjs\n# (runs ${RUNS}).\n`, cap);
  t = swap(t, "# Business provider candidates are named on each affected case. Bind and verify them before adding @provider tags.\n",
    "# Provider: the operation is one sql-database-reader statement on sfx-identity (EXEC wildlife.serve), so every case is\n" +
    "# tagged @provider:sql-database-reader. The DNR identity service is its stand-in, wildlife.identity_response, which holds\n" +
    "# the fixture's identity responses by reference (D02); a signed-in session is the verified SideFX session it binds.\n", cap);
  t = t.replace(/^(\s*)# Proposed provider calls \(unbound\):[^\n]*\n/gm, "");
  t = t.replace(/^(\s*)# Local refusal before business-provider dispatch; acceptance requires no business call or mutation\.\n/gm,
    "$1# Refused inside the operation's one provider call; the stored state is unchanged.\n");
  t = t.replace(/^(\s*)# Arrangement: fixtures\/cases\//gm, "$1# Arrangement: nerdery-canonical-features/fixtures/cases/");
  t = t.replace(/^(\s*)@status:not-built\n(?!\1@provider:sql-database-reader\n)/gm, "$1@status:not-built\n$1@provider:sql-database-reader\n");
  t = t.replace(/^(\s*)@status:not-built\n/gm, "$1@status:probed\n");
  if (/unbound|@status:not-built/.test(t)) throw new Error(`${cap}: an unbound provider or a not-built case remains`);
  const x = readCases(original), y = readCases(t);
  if (x.length !== y.length || x.some((c, i) => JSON.stringify([c.caseId, c.steps, c.request, c.then]) !== JSON.stringify([y[i].caseId, y[i].steps, y[i].request, y[i].then])))
    throw new Error(`${cap}: the cases changed`);
  if (y.some((c) => !c.tags.includes("@status:probed") || c.tags.filter((tag) => tag === "@provider:sql-database-reader").length !== 1)) throw new Error(`${cap}: tags`);
  fs.writeFileSync(path.join(here, "features", `${cap}.feature`), t);
  features[cap] = { text: t, candidate: `sha256:${sha(original)}` };
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
fs.writeFileSync(path.join(here, "identity-compile-cases.json"), JSON.stringify(compileCases, null, 1) + "\n");
for (const cap of CAPS) console.log(cap.padEnd(36), String(built[cap].cases).padStart(3), `feature sha256:${sha(features[cap].text).slice(0, 12)}`, `dsl sha256:${sha(built[cap].dsl).slice(0, 12)}`);
if (!COMPILED) {
  console.log("compile them read-only: node conformance/run-compile.mjs nerdery/identity-compile-cases.json <outBase>, then set COMPILED");
  process.exit(0);
}

// ---------- the store and the mechanics ----------
const tablesSql = read(path.join(here, "wildlife/wildlife.tables.sql"));
const tableBlock = (name) => { const m = tablesSql.match(new RegExp(`CREATE TABLE wildlife\\.${name}\\([\\s\\S]*?\\);`)); if (!m) throw new Error(`${name}: no table`); return m[0]; };
const newTables = ["identity_response", "signed_in_session"].map((name) => ({ name, text: tableBlock(name) }));
const blocks = read(path.join(here, "wildlife/wildlife.procedures.sql")).split(/\nGO\n/).map((b) => b.replace(/^(--[^\n]*\n)+/, "").replace(/\s+$/, ""));
const block = (name) => { const b = blocks.find((x) => x.startsWith(`CREATE OR ALTER PROCEDURE ${name}\n`)); if (!b) throw new Error(`${name}: no block`); return b; };
const procs = [...NEW_PROCEDURES.map((p) => `wildlife.${p}`), "wildlife.invoke_operation", "wildlife.serve"].map((name) => ({ name, text: block(name) }));
const verifyDigest = (b) => "sha256:" + sha(b.slice(b.indexOf("PROCEDURE ")).replace(/[\n\r \t]+$/, ""));
for (const b of [...procs.map((p) => p.text), ...newTables.map((t) => t.text)]) if (/[^\x09\x0a\x20-\x7e]/.test(b) || /^\s*GO\s*$/im.test(b)) throw new Error("a text is not plain ASCII without GO");
const base = JSON.parse(read(path.join(SRC, "fixtures/base-state.json")));
const q = (v) => (v === undefined || v === null ? "NULL" : lit(String(v)));
const responses = Object.entries(base.identityResponses).map(([ref, r]) =>
  `INSERT wildlife.identity_response(response_ref,validation,subject,first_name,last_name,email,roles_json) VALUES(${q(ref)},${q(r.validation)},${q(r.subject)},${q(r.firstName)},${q(r.lastName)},${q(r.email)},${r.roles ? lit(JSON.stringify(r.roles)) : "NULL"});`);
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
  statement: "OV3 declares sign-up and sign-in for the Nerdery wildlife application through the DNR identity service, feature first: each declaration binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT, and each stored document is exactly the reviewed one.",
  obligations: CAPS.map((cap, i) => ({ obligationId: `O${i + 1}`,
    statement: `${cap} is declared from nerdery/dsl/${cap}.dsl, pinned to its canonical feature sha256:${sha(features[cap].text)}, and its stored document is ${COMPILED[cap].documentDigest}.`,
    evidence: `apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest ${COMPILED[cap].documentDigest}` })) };
const steps = [{ stepId: "plan-header", contractId: "estate-flight-plan.v1", promiseId: PROMISE, flightType: "execution", workClass: "owner-objective", unknowns: [] }];
CAPS.forEach((cap, i) => {
  steps.push({ stepId: `declare-${short(cap)}`, capabilityId: "apply-declared-change",
    historicalBasis: `the wildlife capabilities were declared this way by capability-from-dsl (flight 9810b9af, the photo flight and the catalog flight, plan sha256:0442d1cb); this DSL compiles COMPILED to ${COMPILED[cap].documentDigest} against the retained bytes of its feature with the installed compiler (read-only run ${COMPILED[cap].run}), and its operation's mechanics met every case of that feature read-only (runs ${RUNS})`,
    input: { ...template.input, payload: { ...template.input.payload, source: built[cap].dsl } }, obligationIds: [`O${i + 1}`], expect: { path: "$.disposition", equals: "COMMITTED" } });
  steps.push({ stepId: `prove-${short(cap)}`, capabilityId: "read-declared-capability-document",
    historicalBasis: "read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler's documentDigest for the same source (the earlier wildlife flights proved theirs this way)",
    input: { capabilityId: cap }, obligationIds: [`O${i + 1}`], expect: { path: "$.documentDigest", equals: COMPILED[cap].documentDigest } });
});
const objective = "Declare sign-up and sign-in for the Nerdery wildlife application through the DNR identity service, feature first through OV3's own changes: nerdery-register-wildlife-user and nerdery-sign-in-wildlife-user, each with capability-from-dsl, which binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT; prove each stored document is exactly the reviewed one by its digest.";
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
const smoke = "nerdery-sign-in-wildlife-user";
emitPair("identity-1-estate", [
  "-- WHAT THIS DOES, in one transaction on the estate database:",
  "--   1. retains, through model.mint_content_artifact, the bytes of the canonical features of sign-up",
  `--      (nerdery-register-wildlife-user) and sign-in (nerdery-sign-in-wildlife-user) and the promise flight-promise:${PROMISE};`,
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
  ...stop("IDENTITY1_BASE", "the compiler, the mint or the check is not the reviewed base; nothing is changed."), "GO"], [
  "SET NOCOUNT ON;",
  "DECLARE @minted TABLE(ordinal int IDENTITY(1,1),value nvarchar(max));",
  ...retained.map(([kind, text]) => `INSERT @minted(value) EXEC model.mint_content_artifact @document=${lit(JSON.stringify({ artifactKind: kind, text }))};`),
  "SELECT N'minted' AS result_set,ordinal,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,JSON_VALUE(value,'$.content_digest') AS content_digest FROM @minted ORDER BY ordinal;",
  "DECLARE @want TABLE(ordinal int PRIMARY KEY,artifact_kind nvarchar(80),digest varchar(80));",
  `INSERT @want VALUES${retained.map(([kind, text], i) => `(${i + 1},N'${kind}','sha256:${sha(text)}')`).join(",")};`,
  "SELECT N'readback' AS result_set,w.ordinal,w.artifact_kind,w.digest,CASE WHEN EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=w.artifact_kind COLLATE Latin1_General_100_BIN2 AND a.content_digest=CONVERT(binary(32),SUBSTRING(w.digest,8,64),2)) THEN 1 ELSE 0 END AS retained FROM @want w ORDER BY w.ordinal;",
  "IF EXISTS(SELECT 1 FROM @want w WHERE NOT EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=w.artifact_kind COLLATE Latin1_General_100_BIN2 AND a.content_digest=CONVERT(binary(32),SUBSTRING(w.digest,8,64),2)))",
  ...stop("IDENTITY1_VERIFY_FAILED", "a retained text is not under the digest of its reviewed bytes; nothing is kept."),
  "DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);",
  "DECLARE @in nvarchar(max),@r nvarchar(max);", "DECLARE @t TABLE(v nvarchar(max));",
  `SET @in=(SELECT ${lit(built[smoke].dsl)} AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);`,
  "INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;", "SELECT @r=v FROM @t;",
  `SELECT N'compile' AS result_set,JSON_VALUE(@r,N'$.status') AS status,JSON_VALUE(@r,N'$.documentDigest') AS document,'${COMPILED[smoke].documentDigest}' AS expected;`,
  `IF ISNULL(JSON_VALUE(@r,N'$.status'),N'')<>N'COMPILED' OR ISNULL(JSON_VALUE(@r,N'$.documentDigest'),N'')<>N'${COMPILED[smoke].documentDigest}'`,
  ...stop("IDENTITY1_COMPILE_FAILED", "the DSL does not compile to the reviewed document against the retained feature; nothing is kept.")]);
const smokeCalls = [
  ["Casey signs in through DNR", "nerdery-sign-in-wildlife-user", `{"identityResponseRef":"identity-bio"}`, "NULL", ["$.status", "SIGNED_IN"], ["$.user.userId", "user-bio"]],
  ["An expired DNR response", "nerdery-sign-in-wildlife-user", `{"identityResponseRef":"identity-expired"}`, "NULL", ["$.reason.code", "IDENTITY_RESPONSE_EXPIRED"]],
  ["A DNR response that did not validate", "nerdery-sign-in-wildlife-user", `{"identityResponseRef":"identity-invalid"}`, "NULL", ["$.reason.code", "IDENTITY_NOT_VALIDATED"]],
  ["Drew signs in before registering", "nerdery-sign-in-wildlife-user", `{"identityResponseRef":"identity-new"}`, "NULL", ["$.reason.code", "REGISTRATION_REQUIRED"]],
  ["Avery registers again", "nerdery-register-wildlife-user", `{"identityResponseRef":"identity-a"}`, "NULL", ["$.reason.code", "ALREADY_REGISTERED"]],
  ["Avery opens the definitions administration", "nerdery-resolve-wildlife-access", `{"section":"animal-definitions-admin"}`, "N'user-a'", ["$.reason.code", "BIOLOGIST_ROLE_REQUIRED"]],
  ["Casey opens the definitions administration", "nerdery-resolve-wildlife-access", `{"section":"animal-definitions-admin"}`, "N'user-bio'", ["$.status", "ALLOWED"]],
  ["Avery opens her team", "nerdery-resolve-wildlife-access", `{"section":"team"}`, "N'user-a'", ["$.status", "ALLOWED"]]];
emitPair("identity-2-identity", [
  "-- WHAT THIS DOES, in one transaction on the sfx-identity database:",
  "--   1. creates the DNR identity service's stand-in, wildlife.identity_response, with the identity responses of the",
  "--      challenge fixtures (Avery, Casey, Drew, an invalid and an expired response), and wildlife.signed_in_session, the",
  "--      wildlife user each verified SideFX session signed in as;",
  "--   2. installs wildlife.sign_in_wildlife_user and wildlife.register_wildlife_user, whose texts met all 12 cases of",
  "--      their features read-only (runs 8a8f1f45, 59995dd3, e8a9ae1e, d6230231);",
  "--   3. alters wildlife.invoke_operation to dispatch them, and wildlife.serve to answer a verified session as the user",
  "--      it signed in as (otherwise as the user its principal maps to, as before); the sixteen declared capabilities'",
  "--      127 cases met their expectations again with these texts;",
  "--   4. takes the biologist role from Avery again, who is a citizen: roles are assigned outside the application, and",
  "--      Casey is the biologist;",
  "--   5. verifies every body by digest and calls the operations, then removes the one sign-in the calls made;",
  `--   6. records the plan of flight ${PROMISE} under planner agent ${AGENT} through evidence.upsert_flight_plan:`,
  "--      declare each capability from its DSL and prove its stored document. The plan is nerdery/flights/identity.steps.json;",
  `--      its digest is ${planDigest}.`,
  "-- RUN identity-1-estate FIRST. WHERE: sfx-identity. Run the whole file in one session (a few seconds).",
  `-- BASES: wildlife.invoke_operation ${BASE.invoke}, wildlife.serve ${BASE.serve}, neither new table nor`,
  `-- procedure yet, the owner principal active, the plan writer's four parameters, the agent's current plan ${BASE.plan}`,
  "-- (the catalog flight, flown).",
  "-- RESULT SETS: base; responses (5 rows); verify (digest_matches 1 each); smoke (every passed 1); roles; plans (matches_reviewed_file 1).",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  `DECLARE @p uniqueidentifier='${OWNER}';`,
  ...normalizedDigest("wildlife.invoke_operation", "io"), ...normalizedDigest("wildlife.serve", "sv"),
  "DECLARE @present int=(SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'wildlife') AND name IN (N'identity_response',N'signed_in_session',N'sign_in_wildlife_user',N'register_wildlife_user'));",
  "DECLARE @owner int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id=@p AND active=1),",
  " @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));",
  `DECLARE @current binary(32)=(SELECT plan_digest FROM evidence.flight_plan WHERE principal_id=@p AND agent_id=${lit(AGENT)});`,
  "SELECT N'base' AS result_set,@io_digest AS dispatcher_installed,@sv_digest AS serve_installed,@present AS new_objects_present,@owner AS owner_principal_active,",
  " @params AS plan_writer_parameters,N'sha256:'+LOWER(CONVERT(varchar(64),@current,2)) AS current_plan;",
  `IF @io_digest IS NULL OR @io_digest<>'${BASE.invoke}' OR @sv_digest IS NULL OR @sv_digest<>'${BASE.serve}' OR @present<>0 OR @owner<>1 OR @params<>4`,
  ` OR @current IS NULL OR @current<>CONVERT(binary(32),'${BASE.plan.slice(7)}',2)`,
  ...stop("IDENTITY2_BASE", "the dispatcher, serve, the new objects, the owner principal, the plan writer or the agent's current plan is not the reviewed base; nothing is changed."),
  ...newTables.map((t) => `EXEC(${lit(t.text.replace(/;$/, ""))});`),
  "GO", "SET NOCOUNT ON;", ...responses,
  "SELECT N'responses' AS result_set,response_ref,validation,subject,first_name,last_name,email,roles_json FROM wildlife.identity_response ORDER BY response_ref;",
  "GO", ...procs.flatMap((p) => [p.text, "GO"])], [
  "SET NOCOUNT ON;",
  `DECLARE @p uniqueidentifier='${OWNER}';`,
  "DELETE wildlife.user_role WHERE user_id=N'user-a' AND role=N'biologist';",
  "DECLARE @digests TABLE(object_name nvarchar(200),digest varchar(80));",
  ...procs.flatMap((p, i) => [...normalizedDigest(p.name, `v${i}`), `INSERT @digests VALUES(N'${p.name}',@v${i}_digest);`]),
  `DECLARE @want TABLE(object_name nvarchar(200),digest varchar(80)); INSERT @want VALUES${procs.map((p) => `(N'${p.name}','${verifyDigest(p.text)}')`).join(",")};`,
  "SELECT N'verify' AS result_set,w.object_name,w.digest AS reviewed,d.digest AS installed,CASE WHEN d.digest=w.digest THEN 1 ELSE 0 END AS digest_matches FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name ORDER BY w.object_name;",
  "DECLARE @smoke TABLE(o int IDENTITY(1,1),item nvarchar(200),actual nvarchar(400),expected nvarchar(400),passed bit);",
  "DECLARE @r nvarchar(max),@sid uniqueidentifier=NEWID();", "DECLARE @t TABLE(v nvarchar(max));",
  ...smokeCalls.flatMap(([item, op, req, user, ...expects]) => [`EXEC wildlife.invoke_operation @operation=N'${op}',@request=${lit(req)},@user_id=${user},@result=@r OUTPUT,@session_id=@sid;`,
    ...expects.map(([p, eq]) => `INSERT @smoke(item,actual,expected,passed) VALUES(${lit(`${item}: ${p}`)},JSON_VALUE(@r,N'${p}'),N'${eq}',CASE WHEN JSON_VALUE(@r,N'${p}')=N'${eq}' THEN 1 ELSE 0 END);`)]),
  "INSERT @smoke(item,actual,expected,passed) VALUES(N'the sign-in bound its session to Casey',(SELECT user_id FROM wildlife.signed_in_session WHERE session_id=@sid),N'user-bio',CASE WHEN (SELECT user_id FROM wildlife.signed_in_session WHERE session_id=@sid)=N'user-bio' THEN 1 ELSE 0 END);",
  "DELETE wildlife.signed_in_session WHERE session_id=@sid;",
  `INSERT @t EXEC wildlife.serve @operation=N'nerdery-browse-animal-collection',@input=N'{"request":{"search":""}}';`,
  "SELECT @r=v FROM @t; DELETE @t;",
  "INSERT @smoke(item,actual,expected,passed) VALUES(N'anonymous call: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'AUTHENTICATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'AUTHENTICATION_REQUIRED' THEN 1 ELSE 0 END);",
  `DECLARE @forged nvarchar(max)=N'{"caller":{"principalId":"${OWNER}","sessionId":"'+CONVERT(nvarchar(36),NEWID())+N'"},"request":{"search":""}}';`,
  "INSERT @t EXEC wildlife.serve @operation=N'nerdery-browse-animal-collection',@input=@forged;", "SELECT @r=v FROM @t; DELETE @t;",
  "INSERT @smoke(item,actual,expected,passed) VALUES(N'owner principal with an unknown session: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'AUTHENTICATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'AUTHENTICATION_REQUIRED' THEN 1 ELSE 0 END);",
  "SELECT N'smoke' AS result_set,item,actual,expected,passed FROM @smoke ORDER BY o;",
  "SELECT N'roles' AS result_set,user_id,role FROM wildlife.user_role ORDER BY user_id,role;",
  "IF EXISTS(SELECT 1 FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name WHERE d.digest IS NULL OR d.digest<>w.digest) OR EXISTS(SELECT 1 FROM @smoke WHERE passed=0)",
  " OR (SELECT COUNT(*) FROM wildlife.identity_response)<>5 OR EXISTS(SELECT 1 FROM wildlife.user_role WHERE user_id=N'user-a' AND role=N'biologist')",
  ...stop("IDENTITY2_VERIFY_FAILED", "an installed body, a call, the stand-in's responses or Avery's role is not as reviewed; nothing is kept."),
  "DECLARE @plans TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));",
  `INSERT @plans EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=${lit(AGENT)},@objective=${lit(objective)},`, ` @steps_json=${lit(stepsJson)};`,
  `SELECT N'plans' AS result_set,${lit(AGENT)} AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'${planDigest.slice(7)}',2) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @plans;`,
  `IF NOT EXISTS(SELECT 1 FROM @plans WHERE plan_digest=CONVERT(binary(32),'${planDigest.slice(7)}',2))`,
  ...stop("IDENTITY2_PLAN_MISMATCH", "the recorded plan is not the reviewed one; nothing is kept.")]);
files["flights/identity.steps.json"] = JSON.stringify({ agentId: AGENT, promise, objective, planDigest, steps }, null, 2) + "\n";

// ---------- write and verify ----------
for (const [rel, text] of Object.entries(files)) {
  if (/[^\x09\x0a\x20-\x7e]/.test(text)) throw new Error(`${rel}: non-ASCII`);
  fs.writeFileSync(path.join(here, rel), text);
}
const unlit = (l) => l.slice(2, -1).split("''").join("'");
for (const suffix of ["", ".commit"]) {
  const t2 = files[`sql/identity-2-identity${suffix}.sql`], m = t2.match(/@steps_json=(N'(?:[^']|'')*');/), o = t2.match(/@objective=(N'(?:[^']|'')*'),/);
  if (!m || unlit(m[1]) !== stepsJson || !o || unlit(o[1]) !== objective) throw new Error("identity-2: plan literal round trip");
  const batches = t2.split("\nGO\n");
  if (procs.some((p, i) => batches[i + 2] !== p.text)) throw new Error("identity-2: the install batches are not the reviewed texts");
  const t1 = files[`sql/identity-1-estate${suffix}.sql`];
  const docs = [...t1.matchAll(/@document=(N'(?:[^']|'')*');/g)].map((x) => JSON.parse(unlit(x[1])));
  if (docs.length !== retained.length || docs.some((d, i) => d.artifactKind !== retained[i][0] || d.text !== retained[i][1])) throw new Error("identity-1: retained literal round trip");
}
const out = { generated: "2026-11-03", capabilities: CAPS.map((cap) => ({ capabilityId: cap, cases: built[cap].cases, feature: `sha256:${sha(features[cap].text)}`,
  dsl: `sha256:${sha(built[cap].dsl)}`, document: COMPILED[cap].documentDigest, compiledRun: COMPILED[cap].run, candidate: features[cap].candidate })),
  plannerAgentId: AGENT, promiseId: PROMISE, promiseDigest: `sha256:${sha(promiseText)}`, planDigest, steps: steps.length - 1,
  procedures: procs.map((p) => ({ name: p.name, verifyDigest: verifyDigest(p.text) })), twinParity: pairs,
  files: Object.keys(files).map((f) => ({ file: `nerdery/${f}`, bytes: Buffer.byteLength(files[f]), sha256: `sha256:${sha(files[f])}` })) };
fs.writeFileSync(path.join(here, "manifest.identity.json"), JSON.stringify(out, null, 1) + "\n");
console.log(JSON.stringify({ planDigest, promiseDigest: out.promiseDigest, steps: out.steps, twinParity: pairs }, null, 1));
