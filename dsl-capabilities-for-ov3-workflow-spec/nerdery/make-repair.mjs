// The runtime repair of the citizen slice, round 2: two SQL runs and one OV3 flight.
//   nerdery/sql/repair-3-estate(.commit).sql    estate: installs the compiler whose provider operations bind the carrying open
//                                               port, as every other statement chain in the estate does, and retains the
//                                               flight's promise
//   nerdery/sql/repair-4-identity(.commit).sql  sfx-identity: the flight's plan, revision 3 under the slice's planner agent
//   nerdery/flights/repair-2.steps.json         the plan: re-declare the eight slice capabilities and the check from their
//                                               unchanged sources, each proved by the digest of its stored document
// Why: round 1 (repair-1, repair-2, flight c0cd676c) gave the composing and outcome statements their commandTimeout; the next
// live call (run d37c4351) failed at the composing statement with DECLARED_PROVIDER_TARGET_MISSING:vault. The kernel runs the
// estate's PORT definitions, and the compiled open ports were sfx-vault-reference-open-port.v1, which replaces the vault and
// credential reference with the opened secret. Every other statement chain binds sfx-vault-reference-carry-port.v1, which
// carries them on to the run-statement provider that opens the credential itself (runs fa3d0621, b50b9384).
// Round 1's files (repair-1, repair-2, flights/repair.steps.json, manifest.repair.json) came from the previous revision of
// this generator and have run.
// Inputs: source/analysis.compile_capability_dsl.v3.sql (run conformance/make-compiler-v3.mjs first), the sources the
// fast-path flight declared, and repair-2-compile-cases.json (each source compiled read-only by this compiler).
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const read = (p) => fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n");
const sha = (s) => crypto.createHash("sha256").update(Buffer.from(s, "utf8")).digest("hex");
const lit = (s) => {
  if (/^\s*GO\s*$/im.test(s)) throw new Error("a GO line inside a literal");
  if (/[^\x09\x0a\x20-\x7e]/.test(s)) throw new Error("non-ASCII inside a literal");
  return "N'" + s.split("'").join("''") + "'";
};
const OWNER = "565de6d4-ebcd-408b-9359-04d21dc62183";
const AGENT = "claude-code-opus-5-5-nerdery-slice";
const PROMISE = "nerdery-citizen-slice-runtime-repair-2";
const COMPILER = "analysis.compile_capability_dsl";
const NAMES = { estate: "repair-3-estate", identity: "repair-4-identity", flight: "flights/repair-2.steps.json", manifest: "manifest.repair-2.json" };
const CARRY = "sfx-vault-reference-carry-port.v1";
// Live reads of 2026-11-03 (run 9dd74800 and 96691fff): the compiler round 1 installed, as a body from "PROCEDURE <name>" on
// with LF line ends (the owner's client stores CRLF, so the raw digest differs), the mint, and the agent's current plan,
// revision 2, which flew COMPLETE (recording c0cd676c). The fast-path plan holds the sources every round re-declares.
const BASE = { compiler: "sha256:7197986a4ed494670a66ac89fad4d46d52421976a23b0a2aeba3173785a3be7d",
  mint: "sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e",
  plan: "sha256:31a627482aa3cc6d285c485b6d22707f18283e69b10b0654454bc8750cbdecc4",
  fastPlan: "sha256:8ffc4ac2cab7fec7524ebd222f6696070f94d6c6f11e6668715c24e1489bcd1f" };
const stop = (tag, why) => ["BEGIN", ` RAISERROR(N'${tag}: ${why.split("'").join("''")}',16,1);`, " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END"];
const digestExpr = (object) => `'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'${object}')) COLLATE Latin1_General_100_BIN2_UTF8)),2))`;
const normalizedDigest = (object, v) => [`DECLARE @${v} nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'${object}')),NCHAR(13)+NCHAR(10),NCHAR(10));`,
  `SET @${v}=SUBSTRING(@${v},CHARINDEX(N'PROCEDURE ${object}',@${v}),DATALENGTH(@${v})/2);`,
  `WHILE DATALENGTH(@${v})>0 AND RIGHT(@${v},1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @${v}=LEFT(@${v},DATALENGTH(@${v})/2-1);`,
  `DECLARE @${v}_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@${v} COLLATE Latin1_General_100_BIN2_UTF8)),2));`];

// ---------- the reviewed texts ----------
const compiler = read(path.join(root, "source/analysis.compile_capability_dsl.v3.sql"));
const at = compiler.indexOf(`PROCEDURE ${COMPILER}`);
if (at < 0 || compiler.slice(0, at).trim() !== "CREATE") throw new Error("compiler: unexpected header");
if ((compiler.match(/N'\$\.commandTimeout',30\)/g) || []).length !== 2) throw new Error("compiler: the two statements' commandTimeout; run conformance/make-compiler-v3.mjs");
if (compiler.split(CARRY).length - 1 !== 2 || compiler.includes("sfx-vault-reference-open-port.v1")) throw new Error("compiler: the two carrying open ports; run conformance/make-compiler-v3.mjs");
if (/[^\x09\x0a\x20-\x7e]/.test(compiler)) throw new Error("compiler: non-ASCII");
const install = `CREATE OR ALTER ${compiler.slice(at)}`;
const verify = "sha256:" + sha(compiler.slice(at).replace(/[\n\r \t]+$/, ""));
const fast = JSON.parse(read(path.join(here, "flights/fast-path.steps.json")));
if (fast.planDigest !== BASE.fastPlan) throw new Error("the fast-path plan moved");
const cases = JSON.parse(read(path.join(here, "repair-2-compile-cases.json")));
const expected = (c, p) => { const e = c.expect.find(([k]) => k === p); if (!e) throw new Error(`${c.name}: no ${p}`); return e[1]; };
// The eight slice capabilities first, then the check, whose declared document lacks the timeouts too.
const caps = cases.map((c, i) => {
  const step = fast.steps.find((s) => s.capabilityId === "apply-declared-change" && s.input.payload.source.startsWith(`capability ${c.name}\n`));
  if (!step || step.input.payload.source !== read(path.join(root, c.source))) throw new Error(`${c.name}: the source differs from the one the fast-path flight declared`);
  if (expected(c, "$.document.scenarios[0].portBindings[2].platformCapabilityId") !== CARRY || expected(c, "$.document.scenarios[0].portBindings[7].platformCapabilityId") !== CARRY)
    throw new Error(`${c.name}: the cases do not assert the carrying open ports`);
  return { capabilityId: c.name, file: c.source, step, ordinal: i + 1, feature: expected(c, "$.document.feature.digest"), document: expected(c, "$.documentDigest"),
    declared: c.declaredDocument, run: c.compiledRun, short: c.name.replace(/^nerdery-/, "") };
});
if (caps.length !== 9 || !caps.slice(0, 8).every((c) => c.capabilityId.startsWith("nerdery-")) || caps[8].capabilityId !== "check-capability-feature-conformance")
  throw new Error("the eight slice capabilities first, then the check");
const smoke = caps.find((c) => c.capabilityId === "nerdery-view-wildlife-home");

// ---------- one promise, one plan ----------
const change = (c) => c.capabilityId.startsWith("nerdery-") ? "the carrying open port on both open steps" : "the carrying open port on both open steps and commandTimeout 30 on both statements";
const promise = { contractId: "flight-promise.v1", promiseId: PROMISE, workClass: "owner-objective",
  statement: "OV3 re-declares the eight capabilities of the Nerdery citizen slice and check-capability-feature-conformance from their unchanged sources with the repaired compiler, whose provider operations bind the carrying open port that every other statement chain in the estate binds, so the run-statement provider receives the vault and credential reference it opens. Each stored document is exactly the reviewed one, feature pin kept, found CONFORMANT in the same change.",
  obligations: caps.map((c) => ({ obligationId: `O${c.ordinal}`,
    statement: `${c.capabilityId} is re-declared from ${c.file}, unchanged and pinned to its canonical feature ${c.feature}, and its stored document is ${c.document}: the document declared now (${c.declared}) with ${change(c)}, and no other difference.`,
    evidence: `apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest ${c.document}` })) };
const steps = [{ stepId: "plan-header", contractId: "estate-flight-plan.v1", promiseId: PROMISE, flightType: "execution", workClass: "owner-objective", unknowns: [] }];
for (const c of caps) {
  steps.push({ stepId: `redeclare-${c.short}`, capabilityId: "apply-declared-change",
    historicalBasis: `this source is declared COMMITTED (flights 9810b9af and c0cd676c); the live call after round 1 (run d37c4351) failed at the composing statement with DECLARED_PROVIDER_TARGET_MISSING:vault because the compiled open port was sfx-vault-reference-open-port.v1, while every other statement chain in the estate binds ${CARRY} (runs b50b9384, fa3d0621); the repaired compiler compiles this source COMPILED to ${c.document} (read-only run ${c.run}), the declared document with ${change(c)}; a declaration of an existing capability is recorded as scaffold EXISTING (flight c0cd676c)`,
    input: c.step.input, obligationIds: [`O${c.ordinal}`], expect: { path: "$.disposition", equals: "COMMITTED" } });
  steps.push({ stepId: `prove-${c.short}`, capabilityId: "read-declared-capability-document",
    historicalBasis: "read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler's documentDigest for the same source (flight c0cd676c proved all eight this way)",
    input: { capabilityId: c.capabilityId }, obligationIds: [`O${c.ordinal}`], expect: { path: "$.documentDigest", equals: c.document } });
}
const objective = "Repair the runtime of the Nerdery citizen slice through OV3's own changes: re-declare its eight capabilities and check-capability-feature-conformance from their unchanged sources with capability-from-dsl, now that the repaired compiler binds the carrying open port every other statement chain in the estate binds, so each composing and outcome statement receives the vault and credential reference it opens; each declaration binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT; prove each stored document is exactly the reviewed one by its digest.";
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
const smokeSource = smoke.step.input.payload.source;
emitPair(NAMES.estate, [
  "-- WHAT THIS DOES, in one transaction on the estate database:",
  "--   1. installs the repaired analysis.compile_capability_dsl. The only change from the installed revision: a provider",
  `--      operation's two open steps bind ${CARRY} (provider sfx-vault-secret-service-reference-carry), as every`,
  "--      other statement chain in the estate does. The opening port replaced the vault and credential reference with the",
  "--      secret, and the statement failed (run d37c4351, DECLARED_PROVIDER_TARGET_MISSING:vault);",
  "--   2. verifies the installed body by digest, and compiles nerdery-view-wildlife-home's declared source to the exact",
  "--      document the read-only compile produced, carrying open ports and timeouts included;",
  `--   3. retains the flight's promise flight-promise:${PROMISE}.`,
  "-- WHERE: the estate database. Run the whole file in one session; the transaction spans the batches (under a minute).",
  `-- BASES: compiler body ${BASE.compiler} (round 1), mint ${BASE.mint}.`,
  "-- RESULT SETS: base; verify (compiler_body = compiler_expected, smoke_document = smoke_expected, both open platforms the",
  "-- carry port, both timeouts 30); minted (1 row); readback (retained 1).",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  ...normalizedDigest(COMPILER, "cd"),
  `DECLARE @m varchar(80)=${digestExpr("model.mint_content_artifact")};`,
  `SELECT N'base' AS result_set,@cd_digest AS compiler_body,'${BASE.compiler}' AS compiler_expected,@m AS mint_installed,'${BASE.mint}' AS mint_expected;`,
  `IF @cd_digest IS NULL OR @cd_digest<>'${BASE.compiler}' OR @m IS NULL OR @m<>'${BASE.mint}'`,
  ...stop("REPAIR3_BASE_MOVED", "the installed compiler or mint is not the reviewed base; nothing is changed."), "GO", install.replace(/\n+$/, ""), "GO"], [
  "SET NOCOUNT ON;",
  ...normalizedDigest(COMPILER, "cd"),
  "DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);",
  "DECLARE @in nvarchar(max),@r nvarchar(max);", "DECLARE @t TABLE(v nvarchar(max));",
  `SET @in=(SELECT ${lit(smokeSource)} AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);`,
  "INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;", "SELECT @r=v FROM @t;",
  `SELECT N'verify' AS result_set,@cd_digest AS compiler_body,'${verify}' AS compiler_expected,JSON_VALUE(@r,N'$.status') AS smoke_status,`,
  ` JSON_VALUE(@r,N'$.documentDigest') AS smoke_document,'${smoke.document}' AS smoke_expected,`,
  " JSON_VALUE(@r,N'$.document.scenarios[0].portBindings[2].platformCapabilityId') AS compose_open_platform,",
  " JSON_VALUE(@r,N'$.document.scenarios[0].portBindings[7].platformCapabilityId') AS outcome_open_platform,",
  " JSON_VALUE(@r,N'$.document.scenarios[0].portBindings[3].configuration.commandTimeout') AS compose_timeout,",
  " JSON_VALUE(@r,N'$.document.scenarios[0].portBindings[8].configuration.commandTimeout') AS outcome_timeout;",
  `IF @cd_digest<>'${verify}' OR ISNULL(JSON_VALUE(@r,N'$.documentDigest'),N'')<>N'${smoke.document}'`,
  ...stop("REPAIR3_VERIFY_FAILED", "the installed body is not the reviewed revision, or the smoke compile did not produce the reviewed document; nothing is kept."),
  "DECLARE @minted TABLE(value nvarchar(max));",
  `INSERT @minted(value) EXEC model.mint_content_artifact @document=${lit(JSON.stringify({ artifactKind: `flight-promise:${PROMISE}`, text: promiseText }))};`,
  "SELECT N'minted' AS result_set,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,JSON_VALUE(value,'$.content_digest') AS content_digest FROM @minted;",
  `DECLARE @retained int=CASE WHEN EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=N'flight-promise:${PROMISE}' AND a.content_digest=CONVERT(binary(32),'${sha(promiseText)}',2)) THEN 1 ELSE 0 END;`,
  `SELECT N'readback' AS result_set,N'flight-promise:${PROMISE}' AS artifact_kind,'sha256:${sha(promiseText)}' AS digest,@retained AS retained;`,
  "IF @retained<>1",
  ...stop("REPAIR3_VERIFY_FAILED", "the promise is not retained under the digest of its reviewed bytes; nothing is kept.")]);
emitPair(NAMES.identity, [
  "-- WHAT THIS DOES, in one transaction on the sfx-identity database:",
  `--   records the plan of flight ${PROMISE} under planner agent ${AGENT} through evidence.upsert_flight_plan`,
  "--   (revision 3; revisions 1 and 2 have flown): re-declare the eight slice capabilities and the check from their unchanged",
  "--   sources, each proved by the digest of its stored document.",
  `--   The plan is nerdery/${NAMES.flight}; its digest is ${planDigest}.`,
  `-- RUN ${NAMES.estate} FIRST. WHERE: sfx-identity. Run the whole file in one session (a few seconds).`,
  "-- GUARDS: the owner principal is active; the plan writer has its four parameters; the agent's current plan is round 1's",
  "-- or this one. RESULT SETS: base; plans (matches_reviewed_file 1).",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  `DECLARE @p uniqueidentifier='${OWNER}';`,
  "DECLARE @owner int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id=@p AND active=1),",
  " @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));",
  `DECLARE @current binary(32)=(SELECT plan_digest FROM evidence.flight_plan WHERE principal_id=@p AND agent_id=${lit(AGENT)});`,
  "SELECT N'base' AS result_set,@owner AS owner_principal_active,@params AS plan_writer_parameters,N'sha256:'+LOWER(CONVERT(varchar(64),@current,2)) AS current_plan;",
  `IF @owner<>1 OR @params<>4 OR @current IS NULL OR @current NOT IN (CONVERT(binary(32),'${BASE.plan.slice(7)}',2),CONVERT(binary(32),'${planDigest.slice(7)}',2))`,
  ...stop("REPAIR4_BASE", "the owner principal, the plan writer or the agent's current plan is not as reviewed; nothing is changed.")], [
  "DECLARE @r TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));",
  `INSERT @r EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=${lit(AGENT)},@objective=${lit(objective)},`, ` @steps_json=${lit(stepsJson)};`,
  `SELECT N'plans' AS result_set,${lit(AGENT)} AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'${planDigest.slice(7)}',2) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @r;`,
  `IF NOT EXISTS(SELECT 1 FROM @r WHERE plan_digest=CONVERT(binary(32),'${planDigest.slice(7)}',2))`,
  ...stop("REPAIR4_PLAN_MISMATCH", "the recorded plan is not the reviewed one; nothing is kept.")]);
files[NAMES.flight] = JSON.stringify({ agentId: AGENT, promise, objective, planDigest, steps }, null, 2) + "\n";

// ---------- write and verify ----------
for (const [rel, text] of Object.entries(files)) {
  if (/[^\x09\x0a\x20-\x7e]/.test(text)) throw new Error(`${rel}: non-ASCII`);
  fs.mkdirSync(path.dirname(path.join(here, rel)), { recursive: true });
  fs.writeFileSync(path.join(here, rel), text);
}
const unlit = (l) => l.slice(2, -1).split("''").join("'");
for (const suffix of ["", ".commit"]) {
  const t2 = files[`sql/${NAMES.identity}${suffix}.sql`], m = t2.match(/@steps_json=(N'(?:[^']|'')*');/), o = t2.match(/@objective=(N'(?:[^']|'')*'),/);
  if (!m || unlit(m[1]) !== stepsJson || !o || unlit(o[1]) !== objective) throw new Error(`${NAMES.identity}: plan literal round trip`);
  const t1 = files[`sql/${NAMES.estate}${suffix}.sql`], d = t1.match(/@document=(N'(?:[^']|'')*');/);
  if (!d || JSON.parse(unlit(d[1])).text !== promiseText) throw new Error(`${NAMES.estate}: promise literal round trip`);
  if (t1.split("\nGO\n")[1] !== install.replace(/\n+$/, "")) throw new Error(`${NAMES.estate}: the install batch is not the reviewed text`);
}
const out = { generated: "2026-11-03", round: 2, plannerAgentId: AGENT, promiseId: PROMISE, promiseDigest: `sha256:${sha(promiseText)}`, planDigest, steps: steps.length - 1,
  stepsJsonCharacters: stepsJson.length, compilerVerify: verify, documents: caps.map((c) => ({ capabilityId: c.capabilityId, before: c.declared, after: c.document, compiledRun: c.run })),
  twinParity: pairs, files: Object.keys(files).map((f) => ({ file: `nerdery/${f}`, bytes: Buffer.byteLength(files[f]), sha256: `sha256:${sha(files[f])}` })) };
fs.writeFileSync(path.join(here, NAMES.manifest), JSON.stringify(out, null, 1) + "\n");
console.log(JSON.stringify({ planDigest, promiseDigest: out.promiseDigest, steps: out.steps, stepsJsonCharacters: out.stepsJsonCharacters, compilerVerify: verify, twinParity: pairs }, null, 1));
