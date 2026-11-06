// The fast path: everything the citizen slice needs in two SQL runs and one OV3 flight.
//   nerdery/sql/fast-1-estate(.commit).sql    estate: installs the revised compiler and author path (dsl-07's batches),
//                                             then retains the check's source and feature, the eight finalized features
//                                             and the flight's promise
//   nerdery/sql/fast-2-identity(.commit).sql  sfx-identity: the wildlife store (nrd-01's batches), then the flight's plan
//   nerdery/flights/fast-path.steps.json      the plan: install and declare the check, then declare the eight
// They replace dsl-07, dsl-09, dsl-10 and nrd-01 to nrd-03. dsl-06 (a test, run before fast-1 if at all) and dsl-08 (the
// specification) stay separate. Run make-sql-v3.mjs, make-slice.mjs and make-sql.mjs first: this reuses their generated,
// validated batches and flight steps.
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
const PROMISE = "nerdery-citizen-slice-build";
const BASE = { compiler: "sha256:e0fbb0387b5bd9f6f0c95c1eb36e8da3b3b0ac29e8bbdab86f8337e905cd3d5a", author: "sha256:21db231877532886e39141d4515aa299aec4c493213c4278830dba838b6cbfd5",
  mint: "sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e" };
const stop = (tag, why) => ["BEGIN", ` RAISERROR(N'${tag}: ${why}',16,1);`, " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END"];
const digestExpr = (object) => `'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'${object}')) COLLATE Latin1_General_100_BIN2_UTF8)),2))`;

// ---------- the validated parts ----------
const split = (file, n) => { const b = read(file).split("\nGO\n"); if (b.length !== n) throw new Error(`${file}: ${b.length} batches, expected ${n}`); return b; };
const stripTerminal = (batch) => { if (!batch.endsWith("\nROLLBACK TRANSACTION;")) throw new Error("no terminal ROLLBACK"); return batch.slice(0, -"\nROLLBACK TRANSACTION;".length); };
const dsl07 = split(path.join(root, "sql/dsl-07-install-compiler-and-author-path.sql"), 5);
if (!dsl07[1].startsWith("CREATE OR ALTER PROCEDURE analysis.compile_capability_dsl\n") || !dsl07[2].startsWith("CREATE OR ALTER PROCEDURE model.apply_capability_from_dsl\n")) throw new Error("dsl-07 batches");
const nrd01 = split(path.join(here, "sql/nrd-01-wildlife-store.sql"), 15);
if (!nrd01[1].startsWith("CREATE TABLE wildlife.app_user(") || !nrd01[12].startsWith("SET NOCOUNT ON;\nINSERT wildlife.county") || !nrd01.slice(2, 12).every((b) => b.startsWith("CREATE OR ALTER PROCEDURE wildlife.")))
  throw new Error("nrd-01 batches");
const checkFlight = JSON.parse(read(path.join(root, "flights/check-build.steps.json")));
const slice = JSON.parse(read(path.join(here, "flights/slice-declare.steps.json")));
const manifest = JSON.parse(read(path.join(here, "slice.manifest.json")));

// The texts the flight reads by digest, each checked against the digest its step names.
const checkBody = read(path.join(root, "conformance/check_capability_feature_conformance.body.sql"));
const checkInstall = `CREATE OR ALTER PROCEDURE analysis.check_capability_feature_conformance\n  @input nvarchar(max),@estate_model_pk bigint=NULL,@result nvarchar(max)=NULL OUTPUT,@emit bit=1\nWITH EXECUTE AS OWNER\nAS\n${checkBody.replace(/\s+$/, "")}\n`;
const checkFeature = read(path.join(root, "features/check-capability-feature-conformance.feature"));
const install = checkFlight.steps.find((s) => s.stepId === "install-procedure"), proveCheck = checkFlight.steps.find((s) => s.stepId === "prove-declared");
if (install.input.sourceDigest !== `sha256:${sha(checkInstall)}` || proveCheck.expect.equals !== `sha256:${sha(checkFeature)}`) throw new Error("the check's texts differ from its flight; run make-sql-v3.mjs");
const features = manifest.capabilities.map((c) => ({ ...c, text: read(path.join(here, "features", `${c.capabilityId}.feature`)) }));
for (const f of features) if (`sha256:${sha(f.text)}` !== f.feature) throw new Error(`${f.capabilityId}: run make-slice.mjs`);

// ---------- one promise, one plan ----------
const renumber = (id) => `O${Number(id.slice(1)) + 2}`;
const promise = { contractId: "flight-promise.v1", promiseId: PROMISE, workClass: "owner-objective",
  statement: "OV3 installs analysis.check_capability_feature_conformance and declares check-capability-feature-conformance, then declares the eight capabilities of the Nerdery citizen slice, all feature first: each declaration binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT.",
  obligations: [...checkFlight.promise.obligations, ...slice.promise.obligations.map((o) => ({ ...o, obligationId: renumber(o.obligationId) }))] };
const retargetBasis = (s) => s.replace("retained under its digest by sql/dsl-09", "retained under its digest by nerdery/sql/fast-1-estate")
  .replace(", and sql/dsl-06-test.sql declared a pinned probe through the revised author path, bound its feature and found it CONFORMANT", "")
  .replace(" a declaration stores the whole document by digest, and sql/dsl-06-test.sql found the feature pin kept in it", " a declaration stores the whole document by digest, feature pin included");
const steps = [{ stepId: "plan-header", contractId: "estate-flight-plan.v1", promiseId: PROMISE, flightType: "execution", workClass: "owner-objective", unknowns: [] },
  ...checkFlight.steps.slice(1).map((s) => ({ ...s, historicalBasis: retargetBasis(s.historicalBasis) })),
  ...slice.steps.slice(1).map((s) => ({ ...s, obligationIds: s.obligationIds.map(renumber) }))];
if (steps.some((s) => /dsl-06|dsl-09/.test(s.historicalBasis || ""))) throw new Error("a basis still cites a file the fast path does not run");
const objective = "Install the no-drift check and declare it, then declare the eight capabilities of the Nerdery citizen slice, all feature first through OV3's own changes: install analysis.check_capability_feature_conformance from its retained source with apply-engineering-change and prove its definition; declare check-capability-feature-conformance and each slice capability from its DSL with capability-from-dsl, which binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT; and prove each declaration keeps its feature pin.";
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
const retained = [["engineering-revision", checkInstall], ["capability-feature:check-capability-feature-conformance", checkFeature],
  ...features.map((f) => [`capability-feature:${f.capabilityId}`, f.text]), [`flight-promise:${PROMISE}`, promiseText]];
emitPair("fast-1-estate", [
  "-- WHAT THIS DOES, in one transaction on the estate database:",
  "--   1. installs the revised analysis.compile_capability_dsl (the feature, uses provider, input from and outcome from",
  "--      lines) and model.apply_capability_from_dsl (binds a pinned feature and commits only on CONFORMANT): dsl-07's",
  "--      batches, verified by body digest and two smoke compiles;",
  "--   2. retains, through model.mint_content_artifact, the source of analysis.check_capability_feature_conformance, the bytes",
  `--      of its canonical feature, the eight finalized Nerdery features and the promise flight-promise:${PROMISE}.`,
  "-- Until OV3's flight installs the check, a source that pins a feature refuses DSL_FEATURE_DRIFT CHECK_NOT_INSTALLED;",
  "-- every other source compiles exactly as before. If you run sql/dsl-06-test.sql, run it before this file.",
  "-- WHERE: the estate database. Run the whole file in one session; the transaction spans the batches (about 1 minute).",
  `-- BASES: compiler ${BASE.compiler}, author path ${BASE.author}, mint ${BASE.mint}.`,
  "-- RESULT SETS: base; verify (compiler_body = compiler_expected, author_path_body = author_path_expected, smoke_topology",
  `-- sha256:202ebb9e..., smoke_unretained_feature DSL_FEATURE_NOT_RETAINED); minted (${retained.length} rows); readback (retained 1 each).`,
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  `DECLARE @c varchar(80)=${digestExpr("analysis.compile_capability_dsl")};`, `DECLARE @a varchar(80)=${digestExpr("model.apply_capability_from_dsl")};`,
  `DECLARE @m varchar(80)=${digestExpr("model.mint_content_artifact")};`,
  `SELECT N'base' AS result_set,@c AS compiler_installed,'${BASE.compiler}' AS compiler_expected,@a AS author_path_installed,'${BASE.author}' AS author_path_expected,@m AS mint_installed,'${BASE.mint}' AS mint_expected;`,
  `IF @c IS NULL OR @c<>'${BASE.compiler}' OR @a IS NULL OR @a<>'${BASE.author}' OR @m IS NULL OR @m<>'${BASE.mint}'`,
  ...stop("FAST1_BASE_MOVED", "an installed procedure is not the reviewed base; nothing is changed."), "GO", dsl07[1], "GO", dsl07[2], "GO", stripTerminal(dsl07[3]), "GO"], [
  "SET NOCOUNT ON;", "DECLARE @minted TABLE(ordinal int IDENTITY(1,1),value nvarchar(max));",
  ...retained.map(([kind, text]) => `INSERT @minted(value) EXEC model.mint_content_artifact @document=${lit(JSON.stringify({ artifactKind: kind, text }))};`),
  "SELECT N'minted' AS result_set,ordinal,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,JSON_VALUE(value,'$.content_digest') AS content_digest FROM @minted ORDER BY ordinal;",
  "DECLARE @want TABLE(ordinal int PRIMARY KEY,artifact_kind nvarchar(80),digest varchar(80));",
  `INSERT @want VALUES${retained.map(([kind, text], i) => `(${i + 1},N'${kind}','sha256:${sha(text)}')`).join(",")};`,
  "SELECT N'readback' AS result_set,w.ordinal,w.artifact_kind,w.digest,CASE WHEN EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=w.artifact_kind COLLATE Latin1_General_100_BIN2 AND a.content_digest=CONVERT(binary(32),SUBSTRING(w.digest,8,64),2)) THEN 1 ELSE 0 END AS retained FROM @want w ORDER BY w.ordinal;",
  "IF EXISTS(SELECT 1 FROM @want w WHERE NOT EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=w.artifact_kind COLLATE Latin1_General_100_BIN2 AND a.content_digest=CONVERT(binary(32),SUBSTRING(w.digest,8,64),2)))",
  ...stop("FAST1_VERIFY_FAILED", "a retained text is not under the digest of its reviewed bytes; nothing is kept.")]);
emitPair("fast-2-identity", [
  "-- WHAT THIS DOES, in one transaction on the sfx-identity database:",
  "--   1. installs the wildlife store of the Nerdery citizen slice: schema wildlife, 14 tables, 10 procedures and the synthetic",
  "--      seed (nrd-01's batches); Avery (citizen) is the owner's principal and starts with no encounters; verified by body",
  "--      digest, seed counts and smoke calls, including an anonymous and a forged caller;",
  `--   2. records the plan of flight ${PROMISE} under planner agent ${AGENT} through evidence.upsert_flight_plan:`,
  "--      install and declare the check, then declare the eight slice capabilities, each with its pin read back.",
  `--      The plan is nerdery/flights/fast-path.steps.json; its digest is ${planDigest}.`,
  "-- RUN fast-1-estate FIRST. WHERE: sfx-identity. Run the whole file in one session (a few seconds).",
  "-- GUARDS: no schema wildlife yet; the identity tables exist; the owner principal is active; the plan writer has its four",
  "-- parameters. RESULT SETS: base; verify; smoke (every passed 1); plans (matches_reviewed_file 1).",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  "DECLARE @schema int=SCHEMA_ID(N'wildlife'),@session int=CASE WHEN OBJECT_ID(N'[identity].session') IS NOT NULL AND OBJECT_ID(N'[identity].principal') IS NOT NULL THEN 1 ELSE 0 END,",
  ` @owner int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id='${OWNER}' AND active=1),`,
  " @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));",
  "SELECT N'base' AS result_set,@schema AS wildlife_schema_id,@session AS identity_tables,@owner AS owner_principal_active,@params AS plan_writer_parameters;",
  "IF @schema IS NOT NULL OR @session<>1 OR @owner<>1 OR @params<>4",
  ...stop("FAST2_BASE", "the schema wildlife already exists, or the identity tables, the owner principal or the plan writer are not as reviewed; nothing is changed."),
  "EXEC(N'CREATE SCHEMA wildlife AUTHORIZATION dbo');", "GO", ...nrd01.slice(1, 13).flatMap((b) => [b, "GO"]), stripTerminal(nrd01[13]), "GO"], [
  `DECLARE @p uniqueidentifier='${OWNER}';`, "DECLARE @r TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));",
  `INSERT @r EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=${lit(AGENT)},@objective=${lit(objective)},`, ` @steps_json=${lit(stepsJson)};`,
  `SELECT N'plans' AS result_set,${lit(AGENT)} AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'0x${planDigest.slice(7)}',1) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @r;`,
  `IF NOT EXISTS(SELECT 1 FROM @r WHERE plan_digest=CONVERT(binary(32),'0x${planDigest.slice(7)}',1))`,
  ...stop("FAST2_PLAN_MISMATCH", "the recorded plan is not the reviewed one; nothing is kept.")]);
files["flights/fast-path.steps.json"] = JSON.stringify({ agentId: AGENT, promise, objective, planDigest, steps }, null, 2) + "\n";

// ---------- write and verify ----------
for (const [rel, text] of Object.entries(files)) {
  if (/[^\x09\x0a\x20-\x7e]/.test(text)) throw new Error(`${rel}: non-ASCII`);
  fs.mkdirSync(path.dirname(path.join(here, rel)), { recursive: true });
  fs.writeFileSync(path.join(here, rel), text);
}
const unlit = (l) => l.slice(2, -1).split("''").join("'");
for (const suffix of ["", ".commit"]) {
  const t2 = files[`sql/fast-2-identity${suffix}.sql`], m = t2.match(/@steps_json=(N'(?:[^']|'')*');/), o = t2.match(/@objective=(N'(?:[^']|'')*'),/);
  if (!m || unlit(m[1]) !== stepsJson || !o || unlit(o[1]) !== objective) throw new Error("fast-2: plan literal round trip");
  const docs = [...files[`sql/fast-1-estate${suffix}.sql`].matchAll(/@document=(N'(?:[^']|'')*');/g)].map((x) => JSON.parse(unlit(x[1])));
  if (docs.length !== retained.length || docs.some((d, i) => d.artifactKind !== retained[i][0] || d.text !== retained[i][1])) throw new Error("fast-1: literal round trip");
}
const out = { generated: "2026-11-02", plannerAgentId: AGENT, promiseId: PROMISE, promiseDigest: `sha256:${sha(promiseText)}`, planDigest, steps: steps.length - 1, stepsJsonCharacters: stepsJson.length,
  replaces: ["sql/dsl-07", "sql/dsl-09", "sql/dsl-10", "nerdery/sql/nrd-01", "nerdery/sql/nrd-02", "nerdery/sql/nrd-03"], twinParity: pairs,
  files: Object.keys(files).map((f) => ({ file: `nerdery/${f}`, bytes: Buffer.byteLength(files[f]), sha256: `sha256:${sha(files[f])}` })) };
fs.writeFileSync(path.join(here, "manifest.fast.json"), JSON.stringify(out, null, 1) + "\n");
console.log(JSON.stringify(out, null, 1));
