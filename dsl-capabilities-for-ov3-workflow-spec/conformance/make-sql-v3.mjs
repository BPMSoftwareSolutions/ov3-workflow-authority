// Writes the owner SQL of round 3 from the reviewed texts in this folder:
//   sql/dsl-06-test.sql                         runs every revision as session procedures; writes only inside a transaction it rolls back
//   sql/dsl-07-install-compiler-and-author-path(.commit).sql   installs the compiler and author path revisions
//   sql/dsl-08-specification(.commit).sql       lists the four new lines in capability-dsl-specification.v1
//   sql/dsl-09-check-promises(.commit).sql      the promises of the check's two flights (estate)
//   sql/dsl-10-check-build-plan(.commit).sql    the build flight: OV3 retains, installs and declares the check (sfx-identity)
//   sql/dsl-11-check-first-call-plan(.commit).sql   the first-call flight, recorded after the build closes (sfx-identity)
// and manifest.v3.json with every digest and the twins' parity.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (p) => fs.readFileSync(path.join(root, p), "utf8").replace(/\r\n/g, "\n");
const sha = (s) => crypto.createHash("sha256").update(Buffer.from(s, "utf8")).digest("hex");
const lit = (s) => {
  if (/^\s*GO\s*$/im.test(s)) throw new Error("a GO line inside a literal");
  if (/[^\x09\x0a\x20-\x7e]/.test(s)) throw new Error("non-ASCII inside a literal");
  return "N'" + s.split("'").join("''") + "'";
};
const swap = (text, a, b, what) => { const n = text.split(a).length - 1; if (n !== 1) throw new Error(`${what}: expected one, found ${n}`); return text.replace(a, () => b); };

const OWNER = "565de6d4-ebcd-408b-9359-04d21dc62183";
const MINT_BASE = "sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e";
const WRITER = { object: "model.replace_capability_dsl_specification", digest: "sha256:bc1aeb30cde0893965e1d9c7ecb4ebe640cf35e9943985ec568dfe06992686e4" };
const BASE = {
  compiler: { object: "analysis.compile_capability_dsl", digest: "sha256:e0fbb0387b5bd9f6f0c95c1eb36e8da3b3b0ac29e8bbdab86f8337e905cd3d5a", run: "86640e7b" },
  author: { object: "model.apply_capability_from_dsl", digest: "sha256:21db231877532886e39141d4515aa299aec4c493213c4278830dba838b6cbfd5", run: "44e9bf70" },
};
const CHECK = "analysis.check_capability_feature_conformance";
const CAP = "check-capability-feature-conformance";
const AGENT = "claude-code-opus-5-5-dsl-check-build";
const PROMISE_BUILD = "dsl-check-capability-feature-conformance-build";
const PROMISE_CALL = "dsl-check-capability-feature-conformance-first-call";

// ---------- the reviewed texts ----------
const cNew = read("source/analysis.compile_capability_dsl.v3.sql");
const aNew = read("source/model.apply_capability_from_dsl.v3.sql");
const checkBody = read("conformance/check_capability_feature_conformance.body.sql");
const checkParams = "  @input nvarchar(max),@estate_model_pk bigint=NULL,@result nvarchar(max)=NULL OUTPUT,@emit bit=1";
const checkInstall = `CREATE OR ALTER PROCEDURE ${CHECK}\n${checkParams}\nWITH EXECUTE AS OWNER\nAS\n${checkBody.replace(/\s+$/, "")}\n`;
const featureText = read("features/check-capability-feature-conformance.feature");
const checkDsl = read("conformance/check-capability-feature-conformance.dsl");
if (!checkDsl.includes(`feature ${CAP} sha256:${sha(featureText)}\n`)) throw new Error("the check DSL does not pin the check feature's current bytes; run make-dsl.mjs");
for (const [n, t] of [["compiler", cNew], ["author path", aNew], ["check", checkInstall], ["feature", featureText], ["dsl", checkDsl]])
  if (/[^\x09\x0a\x20-\x7e]/.test(t)) throw new Error(`${n}: non-ASCII`);

const installText = (body, object) => {
  const at = body.indexOf(`PROCEDURE ${object}`);
  if (at < 0 || body.slice(0, at).trim() !== "CREATE") throw new Error(`${object}: unexpected header`);
  return `CREATE OR ALTER ${body.slice(at)}`;
};
const verifyDigest = (body, object) => "sha256:" + sha(body.slice(body.indexOf(`PROCEDURE ${object}`)).replace(/\r\n/g, "\n").replace(/[\n\r \t]+$/, ""));
const cInstall = installText(cNew, BASE.compiler.object), aInstall = installText(aNew, BASE.author.object);
const cVerify = verifyDigest(cNew, BASE.compiler.object), aVerify = verifyDigest(aNew, BASE.author.object), kVerify = verifyDigest(checkInstall, CHECK);

// Session copies for the test: the body from AS on, under a session name, calling each other's session copies.
const tempCopy = (body, object, tempName, params, swaps) => {
  const head = `CREATE   PROCEDURE ${object}\n${params}\nWITH EXECUTE AS OWNER\nAS\n`;
  if (!body.startsWith(head)) throw new Error(`${object}: header differs from the reviewed form`);
  let rest = body.slice(head.length);
  for (const [a, b] of swaps) rest = swap(rest, a, b, `${object}: ${a}`);
  return `CREATE PROCEDURE ${tempName}\n${params}\nAS\n${rest}`;
};
const cTemp = tempCopy(cNew, BASE.compiler.object, "#dsl06_compile", "  @input nvarchar(max),@estate_model_pk bigint",
  [["DECLARE @check_procedure nvarchar(400)=N'analysis.check_capability_feature_conformance';", "DECLARE @check_procedure nvarchar(400)=N'#dsl06_check';"]]);
const aTemp = tempCopy(aNew, BASE.author.object, "#dsl06_apply", "  @document nvarchar(max)",
  [["EXEC analysis.compile_capability_dsl @input", "EXEC #dsl06_compile @input"], [`EXEC ${CHECK} @input`, "EXEC #dsl06_check @input"]]);
const kTemp = `CREATE PROCEDURE #dsl06_check\n${checkParams}\nAS\n${checkBody.replace(/\s+$/, "")}\n`;

const digestExpr = (object) => `'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'${object}')) COLLATE Latin1_General_100_BIN2_UTF8)),2))`;
const normalizedDigest = (object, v) => `DECLARE @${v} nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'${object}')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @${v}=SUBSTRING(@${v},CHARINDEX(N'PROCEDURE ${object}',@${v}),DATALENGTH(@${v})/2);
WHILE DATALENGTH(@${v})>0 AND RIGHT(@${v},1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @${v}=LEFT(@${v},DATALENGTH(@${v})/2-1);
DECLARE @${v}_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@${v} COLLATE Latin1_General_100_BIN2_UTF8)),2));`;
const banner = (commit) => commit
  ? ["-- ============================== COMMIT - THIS INSTALLS ==============================", "-- Byte-identical to the preflight twin except this banner and the terminal statement:", "-- COMMIT TRANSACTION here, ROLLBACK TRANSACTION there. Run the preflight first."]
  : ["-- ============================== PREFLIGHT - NOT AN INSTALL ==============================", "-- Byte-identical to the .commit twin except this banner and the terminal statement:", "-- ROLLBACK TRANSACTION here, COMMIT TRANSACTION there. Nothing is written."];
const files = {};
const pairs = [];
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

// ---------- the sources the test compiles ----------
const src = (p) => ({ path: p, text: read(p), sha256: sha(read(p)) });
const S = {
  topology: src("probes/dsl01-probe-topology.dsl"), refusals: src("probes/dsl01-probe-refusals.dsl"), binding: src("probes/dsl01-probe-binding.dsl"),
  revealDraft: src("reveal-estate-workflows/reveal-estate-workflows.dsl"),
  pin: src("conformance/fixtures/compile/feature-pin.dsl"), unretained: src("conformance/fixtures/compile/feature-pin-unretained.dsl"),
  drift: src("conformance/fixtures/compile/feature-drift.dsl"), unknown: src("conformance/fixtures/compile/uses-unknown-provider.dsl"),
  inputFrom: src("conformance/fixtures/compile/input-from.dsl"), greeting: src("conformance/fixtures/compile/greeting-pinned.dsl"),
  revealFirst: src("reveal-estate-workflows/reveal-estate-workflows.feature-first.dsl"), checkDsl: src("conformance/check-capability-feature-conformance.dsl"),
  probeFeature: src("conformance/fixtures/compile/feature-first-probe.feature"), revealFeature: src("reveal-estate-workflows/reveal-estate-workflows.feature"),
  checkFeature: src("features/check-capability-feature-conformance.feature"),
};
const check = (area, item, expected, actual, passed) =>
  `INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'${area}',N'${item.split("'").join("''")}',${expected},${actual},CASE WHEN ${passed} THEN 1 ELSE 0 END);`;
const compileWith = (proc, s, into) => `SET @in=(SELECT ${lit(s.text)} AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC ${proc} @input=@in,@estate_model_pk=@e;
SELECT @${into}=v FROM @t; DELETE @t;`;
const retain = (s) => `IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=CONVERT(binary(32),'0x${s.sha256}',1))
 INSERT source.content_object(content_digest,content_bytes,byte_length) SELECT HASHBYTES('SHA2_256',b),b,DATALENGTH(b) FROM (SELECT CONVERT(varbinary(max),CONVERT(varchar(max),${lit(s.text)} COLLATE Latin1_General_100_BIN2_UTF8)) AS b) x;`;
const regression = (s, label) => `DECLARE @in nvarchar(max),@t TABLE(v nvarchar(max)),@old nvarchar(max),@new nvarchar(max),@e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
${compileWith("analysis.compile_capability_dsl", s, "old")}
${compileWith("#dsl06_compile", s, "new")}
${check("regression", `${label}: the revision returns exactly the installed compiler's result`, "JSON_VALUE(@old,N'$.status')+N' '+ISNULL(JSON_VALUE(@old,N'$.documentDigest'),N'')", "JSON_VALUE(@new,N'$.status')+N' '+ISNULL(JSON_VALUE(@new,N'$.documentDigest'),N'')", "@old=@new COLLATE Latin1_General_100_BIN2")}
GO`;
const one = (s, label, expects) => `DECLARE @in nvarchar(max),@t TABLE(v nvarchar(max)),@r nvarchar(max),@e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
${compileWith("#dsl06_compile", s, "r")}
${expects.map(([path, eq]) => check("new lines", `${label}: ${path}`, lit(eq), `JSON_VALUE(@r,N'${path}')`, `ISNULL(JSON_VALUE(@r,N'${path}'),N'(absent)')=${lit(eq)}`)).join("\n")}`;

// The author path's change document, as apply-declared-change hands it to capability-from-dsl.
const change = (dsl) => JSON.stringify({ contractId: "capability-from-dsl-change.v1", source: dsl, isMcpTooling: false, verificationCapabilityId: "read-harness-authoring-state",
  preflight: { input: { changeKind: "capability-from-dsl", includeDefinitions: true }, expected: { disposition: "terminated" } }, route: { resolvedDisposition: "terminated" } });

const test = `-- dsl-06-test.sql
--
-- Run this first, once. It runs the reviewed revisions as session procedures and installs nothing:
--   analysis.compile_capability_dsl (source/analysis.compile_capability_dsl.v3.sql), model.apply_capability_from_dsl
--   (source/model.apply_capability_from_dsl.v3.sql) and ${CHECK} (conformance/check_capability_feature_conformance.body.sql).
-- 1. Regressions: four sources compile with the revision to exactly the installed compiler's result.
-- 2. The new lines: feature, uses provider, input ... from and outcome from, each source as features/compile-capability-dsl.feature
--    states it. Feature bytes a source pins are retained inside a transaction that rolls back.
-- 3. The author path: inside a transaction that always rolls back, it declares probe capability dsl02-probe-feature-first
--    from conformance/fixtures/compile/feature-pin.dsl, binds the feature bytes the source pins to the version it selected,
--    and the check finds the binding CONFORMANT; a source that drifts from its feature is refused and nothing is kept.
-- WHERE: the estate database; run the whole file in one session with no open transaction. About 8 minutes: each compile
-- takes about 22 s. RESULT SETS: base; the author path's own result sets; checks; verdict (PASSED when every check passed).
SET NOCOUNT ON;
IF @@TRANCOUNT>0
BEGIN
 RAISERROR(N'DSL06_OPEN_TRANSACTION: run this file in a session with no open transaction.',16,1);
 SET NOEXEC ON;
END
DECLARE @c varchar(80)=${digestExpr(BASE.compiler.object)};
DECLARE @a varchar(80)=${digestExpr(BASE.author.object)};
SELECT N'base' AS result_set,@c AS compiler_installed,'${BASE.compiler.digest}' AS compiler_expected,@a AS author_path_installed,'${BASE.author.digest}' AS author_path_expected;
IF @c IS NULL OR @c<>'${BASE.compiler.digest}' OR @a IS NULL OR @a<>'${BASE.author.digest}'
BEGIN
 RAISERROR(N'DSL06_BASE_MOVED: an installed procedure is not the base the revisions were drafted against; read it before running this file.',16,1);
 SET NOEXEC ON;
END
DROP PROCEDURE IF EXISTS #dsl06_apply;
DROP PROCEDURE IF EXISTS #dsl06_compile;
DROP PROCEDURE IF EXISTS #dsl06_check;
DROP TABLE IF EXISTS #dsl06_check_rows;
CREATE TABLE #dsl06_check_rows(o int IDENTITY(1,1) PRIMARY KEY,area nvarchar(40) NOT NULL,item nvarchar(400) NOT NULL,expected nvarchar(max) NULL,actual nvarchar(max) NULL,passed bit NOT NULL);
GO
${kTemp}GO
${cTemp}
GO
${aTemp}
GO
${regression(S.topology, "topology probe")}
${regression(S.refusals, "refusal probe")}
${regression(S.binding, "binding probe")}
${regression(S.revealDraft, "reveal draft DSL")}
SET NOCOUNT ON;
BEGIN TRANSACTION;
${retain(S.probeFeature)}
${retain(S.revealFeature)}
${retain(S.checkFeature)}
GO
${one(S.pin, "feature pin", [["$.status", "COMPILED"], ["$.document.feature.digest", `sha256:${S.probeFeature.sha256}`], ["$.document.scenarios[0].operations[4].providerCapabilityId", "sql-database-reader"]])}
GO
${one(S.unretained, "feature pin, nothing retained", [["$.status", "REFUSED"], ["$.diagnostics[0].code", "DSL_FEATURE_NOT_RETAINED"], ["$.diagnostics[0].line", "3"]])}
GO
${one(S.drift, "feature drift", [["$.status", "REFUSED"], ["$.diagnostics[0].code", "DSL_FEATURE_DRIFT"], ["$.diagnostics[0].message", "SCENARIO_STEP_NOT_IN_FEATURE: the result holds the value"]])}
GO
${one(S.unknown, "provider differing in case", [["$.status", "REFUSED"], ["$.diagnostics[0].code", "DSL_PROVIDER_UNKNOWN"], ["$.diagnostics[0].line", "12"]])}
GO
${one(S.inputFrom, "input from", [["$.status", "COMPILED"], ["$.document.scenarios[0].operations[9].inputs[0].from", "dsl02-probe-input-from.read"]])}
GO
${one(S.greeting, "greeting pinned", [["$.status", "REFUSED"], ["$.diagnostics[3].message", "EVENT_IDENTITY_MISMATCH: feature compile-capability-dsl, source compile-capability-dsl-requested"]])}
GO
${one(S.revealFirst, "reveal revision 2", [["$.status", "COMPILED"], ["$.document.feature.digest", `sha256:${S.revealFeature.sha256}`]])}
GO
${one(S.checkDsl, "the check's own source", [["$.status", "COMPILED"], ["$.document.feature.digest", `sha256:${S.checkFeature.sha256}`], ["$.document.scenarios[0].operations[4].providerCapabilityId", "sql-database-reader"]])}
ROLLBACK TRANSACTION;
GO
SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @doc nvarchar(max),@cap_after int,@bound nvarchar(80),@status nvarchar(40),@cr nvarchar(max),@err nvarchar(2048)=NULL;
BEGIN TRANSACTION;
${retain(S.probeFeature)}
SET @doc=${lit(change(S.pin.text))};
EXEC #dsl06_apply @document=@doc;
SELECT @bound=N'sha256:'+JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),env.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),N'$.semantics.content_digest')
FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
JOIN model.estate_capability_feature f ON f.estate_model_pk=ec.estate_model_pk AND f.capability_pk=ec.capability_pk AND f.capability_version_pk=ec.capability_version_pk AND f.binding_role=N'CANONICAL'
JOIN model.feature_version fv ON fv.feature_version_pk=f.feature_version_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=fv.semantic_object_definition_pk
JOIN source.content_object env ON env.content_object_pk=d.canonical_content_pk
WHERE ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1) AND c.capability_id=N'dsl02-probe-feature-first';
DECLARE @req nvarchar(max)=N'{"capabilityId":"dsl02-probe-feature-first"}';
EXEC #dsl06_check @input=@req,@result=@cr OUTPUT,@emit=0;
${check("author path", "the selected version is bound to the feature bytes the source pins", `N'sha256:${S.probeFeature.sha256}'`, "@bound", `ISNULL(@bound,N'')=N'sha256:${S.probeFeature.sha256}'`)}
${check("author path", "the check finds the binding CONFORMANT", "N'status=CONFORMANT'", "JSON_VALUE(@cr,N'$.summary.signature')", "ISNULL(JSON_VALUE(@cr,N'$.summary.signature'),N'')=N'status=CONFORMANT'")}
SET @doc=${lit(change(S.drift.text))};
BEGIN TRY
 EXEC #dsl06_apply @document=@doc;
END TRY
BEGIN CATCH
 SET @err=ERROR_MESSAGE();
END CATCH
${check("author path", "a source that drifts from its feature is refused", "N'CAPABILITY_FROM_DSL_REFUSED: DSL_FEATURE_DRIFT at line 11: SCENARIO_STEP_NOT_IN_FEATURE: the result holds the value'", "@err", "ISNULL(@err,N'')=N'CAPABILITY_FROM_DSL_REFUSED: DSL_FEATURE_DRIFT at line 11: SCENARIO_STEP_NOT_IN_FEATURE: the result holds the value'")}
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
SET @cap_after=(SELECT COUNT(*) FROM model.capability WHERE capability_id=N'dsl02-probe-feature-first');
${check("author path", "nothing of the probe declaration remains", "N'0'", "CONVERT(nvarchar(10),@cap_after)", "@cap_after=0")}
GO
SELECT N'checks' AS result_set,o,area,item,expected,actual,passed FROM #dsl06_check_rows ORDER BY o;
SELECT N'verdict' AS result_set,CASE WHEN COUNT(*)=SUM(CONVERT(int,passed)) THEN N'PASSED' ELSE N'FAILED' END AS verdict,COUNT(*) AS checks,SUM(CONVERT(int,passed)) AS passed FROM #dsl06_check_rows;
DROP PROCEDURE IF EXISTS #dsl06_apply;
DROP PROCEDURE IF EXISTS #dsl06_compile;
DROP PROCEDURE IF EXISTS #dsl06_check;
GO
SET NOEXEC OFF;
`;
files["sql/dsl-06-test.sql"] = test;

// ---------- dsl-07: install the compiler and author path revisions ----------
emitPair("dsl-07-install-compiler-and-author-path", [
  "-- RUN dsl-06-test.sql FIRST: it tested exactly these bodies, and its verdict must read PASSED.",
  "--",
  "-- WHAT THIS CHANGES:",
  "--   analysis.compile_capability_dsl gains four lines: feature <capability-id> sha256:<hex> (the source pins the retained",
  "--   bytes of its canonical feature and is checked against them, each drift refusing as DSL_FEATURE_DRIFT), operation <id>",
  "--   uses provider <capability-id> (compiled to vault, credential, open, a composing statement and",
  "--   generic-capability-invocation.v1, the operation stating providerCapabilityId), input <member> from <scenario-or-",
  "--   operation> <json-path> and outcome from <operation> <json-path>. Every other source compiles exactly as before.",
  "--   model.apply_capability_from_dsl binds the feature a source pins to the capability version the change finally",
  "--   selected and commits only when analysis.check_capability_feature_conformance finds the binding CONFORMANT; a source",
  "--   that pins no feature has its bound feature re-pointed once more at the end, so the binding follows that version.",
  "-- The check itself is installed by OV3's flight (sql/dsl-10). Until then a source that pins a feature refuses with",
  "-- DSL_FEATURE_DRIFT CHECK_NOT_INSTALLED, and nothing else changes.",
  "--",
  "-- WHERE: the estate database. Run the whole file in one session; the transaction spans the batches. CREATE OR ALTER keeps",
  "-- each procedure's permissions. The procedures are locked for the seconds this file runs plus two smoke compiles (~45 s).",
  "--",
  `-- BASES (live reads 2026-11-02): ${BASE.compiler.object} ${BASE.compiler.digest} (run ${BASE.compiler.run}, the dsl-02 revision);`,
  `-- ${BASE.author.object} ${BASE.author.digest} (run ${BASE.author.run}). A moved base stops the file before any change.`,
  "--",
  `-- VERIFY (in the transaction): each installed body, from "PROCEDURE <name>" on with LF line ends, hashes to the reviewed body`,
  `-- (compiler ${cVerify}, author path ${aVerify}); the topology probe compiles to the same document as before`,
  "-- (sha256:202ebb9e...), and a source pinning a digest nothing is retained under refuses DSL_FEATURE_NOT_RETAINED. Otherwise",
  "-- nothing is kept. RESULT SETS: base; verify.",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  `DECLARE @c varchar(80)=${digestExpr(BASE.compiler.object)};`,
  `DECLARE @a varchar(80)=${digestExpr(BASE.author.object)};`,
  `SELECT N'base' AS result_set,@c AS compiler_installed,'${BASE.compiler.digest}' AS compiler_expected,@a AS author_path_installed,'${BASE.author.digest}' AS author_path_expected;`,
  `IF @c IS NULL OR @c<>'${BASE.compiler.digest}' OR @a IS NULL OR @a<>'${BASE.author.digest}'`, "BEGIN",
  " RAISERROR(N'DSL07_BASE_MOVED: an installed procedure is not the base the revisions were drafted against; nothing is changed.',16,1);",
  " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END", "GO", cInstall, "GO", aInstall, "GO"], [
  "SET NOCOUNT ON;",
  normalizedDigest(BASE.compiler.object, "cd"),
  normalizedDigest(BASE.author.object, "ad"),
  "DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);",
  "DECLARE @in nvarchar(max),@t TABLE(v nvarchar(max)),@r1 nvarchar(max),@r2 nvarchar(max);",
  `SET @in=(SELECT ${lit(S.topology.text)} AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);`,
  "INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;", "SELECT @r1=v FROM @t; DELETE @t;",
  `SET @in=(SELECT ${lit(S.unretained.text)} AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);`,
  "INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;", "SELECT @r2=v FROM @t; DELETE @t;",
  `SELECT N'verify' AS result_set,@cd_digest AS compiler_body,'${cVerify}' AS compiler_expected,@ad_digest AS author_path_body,'${aVerify}' AS author_path_expected,`,
  " JSON_VALUE(@r1,N'$.documentDigest') AS smoke_topology,JSON_VALUE(@r2,N'$.diagnostics[0].code') AS smoke_unretained_feature;",
  `IF @cd_digest<>'${cVerify}' OR @ad_digest<>'${aVerify}' OR ISNULL(JSON_VALUE(@r1,N'$.documentDigest'),N'')<>N'sha256:202ebb9e45e33997e88a0ede6d9721cc6047608216b39a717591e55daa482c15'`,
  " OR ISNULL(JSON_VALUE(@r2,N'$.diagnostics[0].code'),N'')<>N'DSL_FEATURE_NOT_RETAINED'", "BEGIN",
  " RAISERROR(N'DSL07_VERIFY_FAILED: an installed body is not the reviewed revision, or a smoke compile did not answer as tested; nothing is kept.',16,1);",
  " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END"]);

// ---------- dsl-08: the specification lists the four new lines ----------
const g0 = JSON.parse(read("specification/grammar.json"));
const add = JSON.parse(read("specification/grammar.v3.additions.json"));
const merge = (rows, extra) => { const out = rows.map((r) => extra.find((e) => e.constructId === r.constructId) || r); for (const e of extra) if (!rows.some((r) => r.constructId === e.constructId)) out.push(e); return out; };
const g3 = { constructs: merge(g0.constructs, add.constructs), documentSemantics: merge(g0.documentSemantics, add.documentSemantics) };
files["specification/grammar.v3.json"] = JSON.stringify(g3, null, 1) + "\n";
const g0Doc = JSON.stringify(g0.constructs), s0Doc = JSON.stringify(g0.documentSemantics), g3Doc = JSON.stringify({ grammar: g3 });
const constructCols = "WITH (id nvarchar(64) N'$.constructId',form nvarchar(200) N'$.form',att nvarchar(64) N'$.attachesTo',rl nvarchar(400) N'$.rule')";
const semanticCols = "WITH (id nvarchar(64) N'$.constructId',mem nvarchar(200) N'$.documentMember',map nvarchar(400) N'$.mapping')";
for (const r of g3.constructs) if (r.form.length > 200 || (r.rule || "").length > 400 || (r.attachesTo || "").length > 64) throw new Error(`construct ${r.constructId} too long`);
for (const r of g3.documentSemantics) if (r.documentMember.length > 200 || (r.mapping || "").length > 400) throw new Error(`semantics ${r.constructId} too long`);
const rowsDiffer = (aJson, bJson, cols, cmp) => `(SELECT COUNT(*) FROM OPENJSON(${aJson}) ${cols} g WHERE NOT EXISTS(SELECT 1 FROM OPENJSON(${bJson}) ${cols} n WHERE ${cmp}))`;
const cCmp = "n.id=g.id COLLATE Latin1_General_100_BIN2 AND n.form=g.form COLLATE Latin1_General_100_BIN2 AND ISNULL(n.att,N'')=ISNULL(g.att,N'') COLLATE Latin1_General_100_BIN2 AND ISNULL(n.rl,N'')=ISNULL(g.rl,N'') COLLATE Latin1_General_100_BIN2";
const sCmp = "n.id=g.id COLLATE Latin1_General_100_BIN2 AND n.mem=g.mem COLLATE Latin1_General_100_BIN2 AND ISNULL(n.map,N'')=ISNULL(g.map,N'') COLLATE Latin1_General_100_BIN2";
const specSelect = `SELECT TOP (1) @spec=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),@spec_digest='sha256:'+LOWER(CONVERT(varchar(64),co.content_digest,2))
FROM model.estate_definition ed
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
JOIN model.semantic_object so ON so.semantic_object_pk=d.semantic_object_pk
JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE ed.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1) AND so.object_kind=N'AUTHORITY'
 AND n.namespace_id=N'sidefx:authorities' COLLATE Latin1_General_100_BIN2 AND so.declared_id=N'capability-dsl-specification.v1' COLLATE Latin1_General_100_BIN2
ORDER BY d.semantic_object_definition_pk DESC;`;
emitPair("dsl-08-specification", [
  "-- RUN dsl-07 FIRST: the specification states the grammar of the installed compiler.",
  "--",
  `-- WHAT THIS CHANGES: capability-dsl-specification.v1 lists the grammar of the revised compiler: ${g3.constructs.length} constructs and`,
  `-- ${g3.documentSemantics.length} document-semantics rows. It adds feature, usesProvider, input and outcomeFrom and revises config, through the`,
  "-- installed writer model.replace_capability_dsl_specification, which replaces only constructs and documentSemantics. The",
  "-- conformance vectors, naming, validation codes and resolver placement are unchanged.",
  "-- WHERE: the estate database. Run the whole file in one session; the transaction spans the batches.",
  `-- BASES: the writer ${WRITER.digest}; the specification's ${g0.constructs.length} constructs and ${g0.documentSemantics.length} semantics rows equal, row for row,`,
  `-- specification/grammar.json (dsl-03); analysis.compile_capability_dsl is the dsl-07 revision (${cVerify}). Otherwise the`,
  `-- file stops before any change. VERIFY: the specification holds exactly specification/grammar.v3.json and its vectors are`,
  "-- unchanged. RESULT SETS: base; the writer's own row; readback.",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  `DECLARE @w varchar(80)=${digestExpr(WRITER.object)};`,
  normalizedDigest(BASE.compiler.object, "cd"),
  "DECLARE @spec nvarchar(max),@spec_digest varchar(80);", specSelect,
  `DECLARE @base_constructs nvarchar(max)=${lit(g0Doc)};`,
  `DECLARE @base_semantics nvarchar(max)=${lit(s0Doc)};`,
  "DECLARE @cur_constructs nvarchar(max)=JSON_QUERY(@spec,N'$.semantics.constructs'),@cur_semantics nvarchar(max)=JSON_QUERY(@spec,N'$.semantics.documentSemantics');",
  "DECLARE @c_count int=(SELECT COUNT(*) FROM OPENJSON(@cur_constructs)),@s_count int=(SELECT COUNT(*) FROM OPENJSON(@cur_semantics)),",
  ` @c_diff int=${rowsDiffer("@base_constructs", "@cur_constructs", constructCols, cCmp)},`,
  ` @s_diff int=${rowsDiffer("@base_semantics", "@cur_semantics", semanticCols, sCmp)};`,
  "DROP TABLE IF EXISTS #dsl08_vectors;",
  "SELECT JSON_QUERY(@spec,N'$.semantics.conformanceVectors') AS vectors INTO #dsl08_vectors;",
  `SELECT N'base' AS result_set,@w AS writer_installed,'${WRITER.digest}' AS writer_expected,@cd_digest AS compiler_body,'${cVerify}' AS compiler_expected,`,
  " @spec_digest AS specification_content,@c_count AS constructs,@s_count AS semantics,@c_diff AS constructs_differing,@s_diff AS semantics_differing;",
  `IF @w IS NULL OR @w<>'${WRITER.digest}' OR @cd_digest<>'${cVerify}' OR @spec IS NULL OR @c_count<>${g0.constructs.length} OR @s_count<>${g0.documentSemantics.length} OR @c_diff<>0 OR @s_diff<>0`, "BEGIN",
  " RAISERROR(N'DSL08_BASE_MOVED: the writer, the compiler or the specification is not the reviewed base (run dsl-07 first); nothing is changed.',16,1);",
  " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END", "GO"], [
  "SET NOCOUNT ON;",
  `DECLARE @doc nvarchar(max)=${lit(g3Doc)};`,
  `EXEC ${WRITER.object} @document=@doc;`,
  "DECLARE @spec nvarchar(max),@spec_digest varchar(80);", specSelect,
  "DECLARE @want_constructs nvarchar(max)=JSON_QUERY(@doc,N'$.grammar.constructs'),@want_semantics nvarchar(max)=JSON_QUERY(@doc,N'$.grammar.documentSemantics');",
  "DECLARE @cur_constructs nvarchar(max)=JSON_QUERY(@spec,N'$.semantics.constructs'),@cur_semantics nvarchar(max)=JSON_QUERY(@spec,N'$.semantics.documentSemantics');",
  "DECLARE @c_count int=(SELECT COUNT(*) FROM OPENJSON(@cur_constructs)),@s_count int=(SELECT COUNT(*) FROM OPENJSON(@cur_semantics)),",
  ` @c_diff int=${rowsDiffer("@want_constructs", "@cur_constructs", constructCols, cCmp)},`,
  ` @s_diff int=${rowsDiffer("@want_semantics", "@cur_semantics", semanticCols, sCmp)},`,
  " @v_same bit=CASE WHEN JSON_QUERY(@spec,N'$.semantics.conformanceVectors')=(SELECT vectors FROM #dsl08_vectors) COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END;",
  "SELECT N'readback' AS result_set,@spec_digest AS specification_content,@c_count AS constructs,@s_count AS semantics,@c_diff AS constructs_differing,@s_diff AS semantics_differing,@v_same AS vectors_unchanged;",
  `IF @c_count<>${g3.constructs.length} OR @s_count<>${g3.documentSemantics.length} OR @c_diff<>0 OR @s_diff<>0 OR @v_same<>1`, "BEGIN",
  " RAISERROR(N'DSL08_VERIFY_FAILED: the specification does not hold exactly the reviewed grammar with its vectors unchanged; nothing is kept.',16,1);",
  " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END",
  "DROP TABLE IF EXISTS #dsl08_vectors;"]);

// ---------- dsl-09..11: OV3's flights ----------
const route = { resolvedDisposition: "terminated" };
const pre = (kind) => ({ input: { changeKind: kind, includeDefinitions: true }, expected: { disposition: "terminated" } });
const procedureDigest = `sha256:${sha(checkInstall)}`;
const featureDigest = `sha256:${sha(featureText)}`;
const promiseBuild = { contractId: "flight-promise.v1", promiseId: PROMISE_BUILD, workClass: "capability-build",
  statement: `OV3 installs ${CHECK} from its retained source and declares ${CAP} from its DSL, compiled against the retained bytes of its canonical feature, bound to them and found CONFORMANT in the same change.`,
  obligations: [
    { obligationId: "O1", statement: `${CHECK} is installed from the source retained under ${procedureDigest}, with EXECUTE for the reader.`, evidence: "apply-engineering-change COMMITTED; read-declared-object-source kind PROCEDURE" },
    { obligationId: "O2", statement: `${CAP} is declared from conformance/check-capability-feature-conformance.dsl, which pins its canonical feature ${featureDigest}; the declaration binds those bytes and commits only when the check finds the binding CONFORMANT.`, evidence: `capability-from-dsl COMMITTED; read-declared-capability-document $.document.feature.digest ${featureDigest}` }] };
const promiseCall = { contractId: "flight-promise.v1", promiseId: PROMISE_CALL, workClass: "capability-build",
  statement: `${CAP} answers its first calls: CONFORMANT for itself, and the greeting drift of compile-capability-dsl.`,
  obligations: [
    { obligationId: "O1", statement: `${CAP} finds itself CONFORMANT to its canonical feature, providers and pin included.`, evidence: "$.status CONFORMANT" },
    { obligationId: "O2", statement: `${CAP} finds the greeting scaffold bound to compile-capability-dsl drift on its event, outcome, outcome contract and steps.`, evidence: "$.summary.signature as in case conf-greeting-drift" }] };
const promiseBuildText = JSON.stringify(promiseBuild), promiseCallText = JSON.stringify(promiseCall);
const retainStep = (stepId, kind, text, basis, obligation) => ({ stepId, capabilityId: "apply-declared-change", historicalBasis: basis,
  input: { contractId: "declared-change.v1", changeKind: "content-artifact-change", payload: { contractId: "content-artifact-change.v1", artifactKind: kind, text,
    verificationCapabilityId: "read-harness-authoring-state", preflight: pre("content-artifact-change"), route } },
  obligationIds: [obligation], expect: { path: "$.disposition", equals: "COMMITTED" } });
const buildSteps = [
  { stepId: "plan-header", contractId: "estate-flight-plan.v1", promiseId: PROMISE_BUILD, flightType: "execution", workClass: "capability-build", unknowns: [] },
  retainStep("retain-procedure", "engineering-revision", checkInstall,
    "draft-capability-from-spec retains every drafted procedure this way before its install (content-artifact-change, artifactKind engineering-revision; drafts 56924a73, 7d836557, d39be3e0); this source is the body that met 54 of 54 probed cases read-only through sql-database-reader (runs c2d6f5b5, 0c9bcf2f, e08afb93, 6afa6b38) and then 54 of 54 again after its revision (runs 14b79d82, d8873ea7, 7a727462, 2b61e91c)", "O1"),
  { stepId: "install-procedure", capabilityId: "apply-engineering-change",
    historicalBasis: "ledger: 238 engineering-change installs, the newest analysis.objective_agent_step on 2026-11-02 (APPLIED); plan-capability-flight installs drafted procedures the same way, by source digest with EXECUTE for the reader (cap-count-owned-artifacts-by-kind-build-56924a73)",
    input: { contractId: "engineering-change.v1", sourceDigest: procedureDigest, mode: "commit", note: `Install ${CHECK}, the no-drift check of dsl-capabilities-for-ov3-workflow-spec.`,
      grantExecuteOn: [CHECK], verificationCapabilityId: "read-harness-authoring-state", preflight: pre("engineering-change"), route },
    obligationIds: ["O1"], expect: { path: "$.disposition", equals: "COMMITTED" } },
  { stepId: "prove-procedure", capabilityId: "read-declared-object-source",
    historicalBasis: "read-declared-object-source reads installed definitions (runs 86640e7b, 44e9bf70 and 2f45de31 on 2026-11-02)",
    input: { objectName: CHECK }, obligationIds: ["O1"], expect: { path: "$.kind", equals: "PROCEDURE" } },
  retainStep("retain-feature", "capability-feature", featureText,
    `the same content-artifact-change; these are the bytes conformance/check-capability-feature-conformance.dsl pins (${featureDigest}), and the revised compiler compiled that source against them COMPILED (run b369a594)`, "O2"),
  { stepId: "declare-capability", capabilityId: "apply-declared-change",
    historicalBasis: "ledger: 412 capability-from-dsl declarations; the revised author path ran this declaration on a probe capability in sql/dsl-06-test.sql, binding the pinned feature and finding it CONFORMANT",
    input: { contractId: "declared-change.v1", changeKind: "capability-from-dsl", payload: { contractId: "capability-from-dsl-change.v1", source: checkDsl, isMcpTooling: true,
      verificationCapabilityId: "read-harness-authoring-state", preflight: pre("capability-from-dsl"), route } },
    obligationIds: ["O2"], expect: { path: "$.disposition", equals: "COMMITTED" } },
  { stepId: "prove-declared", capabilityId: "read-declared-capability-document",
    historicalBasis: "read-declared-capability-document read-back after a capability-from-dsl declaration, as plan-capability-flight proves every build",
    input: { capabilityId: CAP }, obligationIds: ["O2"], expect: { path: "$.document.feature.digest", equals: featureDigest } },
];
const greetingSignature = "status=DRIFT;CASE_ASSERTION_MISSING=1;CASE_IDENTITY_MISSING=1;CASE_REQUEST_MISSING=1;EVENT_IDENTITY_MISMATCH=1;OUTCOME_CONTRACT_MISMATCH=1;OUTCOME_IDENTITY_MISMATCH=1;SCENARIO_STEP_NOT_IN_FEATURE=3";
const callSteps = [
  { stepId: "plan-header", contractId: "estate-flight-plan.v1", promiseId: PROMISE_CALL, flightType: "execution", workClass: "capability-build", unknowns: [] },
  { stepId: "first-call-self", capabilityId: CAP,
    historicalBasis: "the declaration committed only after this same request returned CONFORMANT inside it (the build flight's declare-capability step); case conf-self-conforms",
    input: { capabilityId: CAP }, obligationIds: ["O1"], expect: { path: "$.status", equals: "CONFORMANT" } },
  { stepId: "first-call-greeting", capabilityId: CAP,
    historicalBasis: "the body returned exactly this signature for this request read-only (runs e5dbe9ac, c2d6f5b5, 14b79d82); case conf-greeting-drift",
    input: { capabilityId: "compile-capability-dsl" }, obligationIds: ["O2"], expect: { path: "$.summary.signature", equals: greetingSignature } },
];
const objectiveBuild = `Install ${CHECK} and declare ${CAP} feature first, through OV3's own changes: retain the procedure's source and install it with apply-engineering-change, retain the canonical feature's bytes, and declare the capability from its DSL with capability-from-dsl, which binds those bytes and commits only when the check finds the binding CONFORMANT.`;
const objectiveCall = `Call ${CAP} for the first time: it finds itself CONFORMANT to its canonical feature, and the greeting scaffold bound to compile-capability-dsl drift.`;
const stepsBuild = JSON.stringify(buildSteps), stepsCall = JSON.stringify(callSteps);
const planDigest = (objective, steps) => `sha256:${sha(`${objective}\u0000${steps}`)}`;
const digests = { promiseBuild: `sha256:${sha(promiseBuildText)}`, promiseCall: `sha256:${sha(promiseCallText)}`,
  planBuild: planDigest(objectiveBuild, stepsBuild), planCall: planDigest(objectiveCall, stepsCall), procedure: procedureDigest, feature: featureDigest,
  dsl: `sha256:${sha(checkDsl)}`, checkVerify: kVerify };

const mintGuard = (tag) => ["SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  "DECLARE @installed varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'model.mint_content_artifact')) COLLATE Latin1_General_100_BIN2_UTF8)),2));",
  `SELECT N'base' AS result_set,@installed AS installed_digest,'${MINT_BASE}' AS expected_base;`,
  `IF @installed IS NULL OR @installed<>'${MINT_BASE}'`, "BEGIN",
  ` RAISERROR(N'${tag}_BASE_MOVED: model.mint_content_artifact is not the reviewed definition; nothing is written.',16,1);`,
  " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END", "GO"];
const mint = (promiseId, text) => [
  `INSERT @minted(value) EXEC model.mint_content_artifact @document=${lit(JSON.stringify({ artifactKind: `flight-promise:${promiseId}`, text }))};`,
  `SELECT N'readback' AS result_set,N'${promiseId}' AS promise_id,N'sha256:'+LOWER(CONVERT(varchar(64),x.content_digest,2)) AS newest_digest,CASE WHEN x.content_digest=CONVERT(binary(32),'0x${sha(text)}',1) THEN 1 ELSE 0 END AS matches`,
  `FROM (SELECT TOP (1) a.content_digest FROM model.content_artifact a WHERE a.artifact_kind=N'flight-promise:${promiseId}' COLLATE Latin1_General_100_BIN2 ORDER BY a.registered_date DESC,a.content_artifact_pk DESC) x;`];
emitPair("dsl-09-check-promises", [
  `-- WHAT THIS ADDS: the promises of the two flights of ${CAP}, flight-promise:${PROMISE_BUILD} and`,
  `-- flight-promise:${PROMISE_CALL}, through the installed writer model.mint_content_artifact. OV3 flies the flights; this`,
  "-- file only records what they promise. Re-running is harmless.",
  "-- WHERE: the estate database; run the whole file in one session.",
  `-- BASE: model.mint_content_artifact ${MINT_BASE} (run de256508). RESULT SETS: base; minted (2 rows); readback (matches = 1, twice).`,
  ...mintGuard("DSL09")], [
  "DECLARE @minted TABLE(ordinal int IDENTITY(1,1),value nvarchar(max));",
  ...mint(PROMISE_BUILD, promiseBuildText), ...mint(PROMISE_CALL, promiseCallText),
  "SELECT N'minted' AS result_set,ordinal,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,JSON_VALUE(value,'$.content_digest') AS content_digest FROM @minted;"]);
const planGuard = (tag) => ["SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  "DECLARE @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));",
  `DECLARE @active int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id='${OWNER}' AND active=1);`,
  "SELECT N'guard' AS result_set,@params AS writer_parameters,4 AS expected_parameters,@active AS owner_principal_active;",
  "IF @params<>4 OR @active<>1", "BEGIN",
  ` RAISERROR(N'${tag}_PLAN_GUARD: the plan writer or the owner principal is not as reviewed; nothing was recorded.',16,1);`,
  " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END", "GO"];
const plan = (objective, steps, digest) => [`DECLARE @p uniqueidentifier='${OWNER}';`,
  "DECLARE @r TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));",
  `INSERT @r EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=${lit(AGENT)},@objective=${lit(objective)},`,
  ` @steps_json=${lit(steps)};`,
  `SELECT N'plans' AS result_set,${lit(AGENT)} AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'0x${digest.slice(7)}',1) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @r;`];
emitPair("dsl-10-check-build-plan", [
  `-- WHAT THIS ADDS: the build plan of flight ${PROMISE_BUILD} under planner agent ${AGENT}, through the installed writer`,
  "-- evidence.upsert_flight_plan. It approves nothing and flies nothing. Re-running is harmless.",
  `-- OV3 flies six steps: it retains the source of ${CHECK} (${procedureDigest}), installs it with`,
  "-- apply-engineering-change and reads it back, retains the bytes of features/check-capability-feature-conformance.feature",
  `-- (${featureDigest}), declares ${CAP} from conformance/check-capability-feature-conformance.dsl with`,
  "-- capability-from-dsl, and reads the declaration back. RUN dsl-07 and dsl-09 FIRST.",
  "-- WHERE: the sfx-identity database. GUARD: the writer has its four parameters and the owner principal is active.",
  "-- RESULT SETS: guard; plans (plan_revision, matches_reviewed_file 1).",
  ...planGuard("DSL10")], plan(objectiveBuild, stepsBuild, digests.planBuild));
emitPair("dsl-11-check-first-call-plan", [
  `-- WHAT THIS ADDS: the first-call plan of flight ${PROMISE_CALL}, the next revision under planner agent ${AGENT}, through`,
  "-- the installed writer evidence.upsert_flight_plan. It approves nothing and flies nothing.",
  `-- RUN IT ONLY AFTER the build flight (dsl-10) closed: OV3 then calls ${CAP} twice, for itself and for`,
  "-- compile-capability-dsl.",
  "-- WHERE: the sfx-identity database. GUARD: the writer has its four parameters and the owner principal is active.",
  "-- RESULT SETS: guard; plans (plan_revision, matches_reviewed_file 1).",
  ...planGuard("DSL11")], plan(objectiveCall, stepsCall, digests.planCall));

// ---------- write and verify ----------
for (const [rel, text] of Object.entries(files)) {
  if (/[^\x09\x0a\x20-\x7e]/.test(text)) throw new Error(`${rel}: non-ASCII`);
  if (/\r/.test(text)) throw new Error(`${rel}: CR`);
  fs.mkdirSync(path.dirname(path.join(root, rel)), { recursive: true });
  fs.writeFileSync(path.join(root, rel), text);
}
const unlit = (l) => l.slice(2, -1).split("''").join("'");
for (const [name, text, steps] of [["dsl-10-check-build-plan", stepsBuild], ["dsl-11-check-first-call-plan", stepsCall]].map(([n, s]) => [n, files[`sql/${n}.sql`], s])) {
  const m = text.match(/@steps_json=(N'(?:[^']|'')*');/);
  if (!m || unlit(m[1]) !== steps) throw new Error(`${name}: steps literal round trip`);
}
if (JSON.parse(stepsBuild)[1].input.payload.text !== checkInstall || JSON.parse(stepsBuild)[4].input.payload.text !== featureText || JSON.parse(stepsBuild)[5].input.payload.source !== checkDsl)
  throw new Error("plan texts round trip");
if (!files["sql/dsl-07-install-compiler-and-author-path.sql"].includes(`\nGO\n${cInstall}\nGO\n${aInstall}\nGO\n`)) throw new Error("dsl-07 bodies");
if (!test.includes(cTemp) || !test.includes(aTemp) || !test.includes(kTemp)) throw new Error("dsl-06 bodies");
const objects = (sql) => { const out = []; const l = sql.toLowerCase();
  for (const h of ["create or alter procedure ", "create procedure ", "alter procedure ", "create table ", "alter table ", "drop table ", "create function ", "create or alter function ", "create view "]) {
    let p = l.indexOf(h); while (p >= 0) { const name = sql.slice(p + h.length).trim().split(/[\s(;,]/)[0].replace(/[[\]]/g, ""); if (/^[a-z_]/i.test(name) && !out.includes(name)) out.push(name); p = l.indexOf(h, p + h.length); } }
  return out; };
if (JSON.stringify(objects(checkInstall)) !== JSON.stringify([CHECK])) throw new Error(`the check source creates ${objects(checkInstall)}`);
const fileDigest = (rel) => ({ file: rel, bytes: Buffer.byteLength(files[rel]), sha256: `sha256:${sha(files[rel])}` });
const manifest = { pack: "dsl-capabilities-for-ov3-workflow-spec", part: "round 3: compiler lines, provider comparison, author path, the check through OV3", generated: "2026-11-02",
  bases: { ...BASE, specificationWriter: WRITER, specification: { constructs: g0.constructs.length, semantics: g0.documentSemantics.length, grammar: "specification/grammar.json" } },
  revisions: { compiler: { bodySha256: `sha256:${sha(cNew)}`, verifyDigest: cVerify }, authorPath: { bodySha256: `sha256:${sha(aNew)}`, verifyDigest: aVerify },
    check: { installSha256: procedureDigest, verifyDigest: kVerify }, grammar: { constructs: g3.constructs.length, semantics: g3.documentSemantics.length, documentSha256: `sha256:${sha(g3Doc)}` } },
  flights: { plannerAgentId: AGENT, build: { promiseId: PROMISE_BUILD, promiseDigest: digests.promiseBuild, planDigest: digests.planBuild, steps: buildSteps.length - 1, stepsJsonCharacters: stepsBuild.length },
    firstCall: { promiseId: PROMISE_CALL, promiseDigest: digests.promiseCall, planDigest: digests.planCall, steps: callSteps.length - 1 }, featureDigest, dslDigest: digests.dsl },
  sources: Object.fromEntries(Object.entries(S).map(([k, v]) => [k, { path: v.path, sha256: `sha256:${v.sha256}` }])),
  twinParity: pairs, files: Object.keys(files).filter((f) => f.startsWith("sql/")).map(fileDigest) };
fs.writeFileSync(path.join(root, "manifest.v3.json"), JSON.stringify(manifest, null, 1) + "\n");
console.log(JSON.stringify({ revisions: manifest.revisions, flights: manifest.flights, twinParity: pairs, files: manifest.files.map((f) => `${f.file} ${f.bytes}`) }, null, 1));
