// The photo view of one collected individual, nerdery-view-collected-animal: two SQL runs and one OV3 flight.
//   nerdery/dsl/nerdery-view-collected-animal.dsl  pins the bytes of its canonical feature (nerdery/features); one
//                                                  sql-database-reader operation on sfx-identity
//   nerdery/individual-compile-cases.json          its read-only compile (conformance/run-compile.mjs)
//   nerdery/sql/photo-1-estate(.commit).sql        estate: retains the feature's bytes and the flight's promise, compiles
//                                                  the DSL to the reviewed document, and publishes wildlife-mine revision 2
//                                                  (each card opens its individual) and wildlife-individual revision 1
//   nerdery/sql/photo-2-identity(.commit).sql      sfx-identity: installs wildlife.view_collected_animal and the
//                                                  dispatcher that reaches it, then records the flight's plan
//   nerdery/flights/individual.steps.json          the plan: declare the capability from its DSL, prove its stored document
// The feature's cases met the mechanics read-only (nerdery/conformance/run-cases.mjs, run ef3510aa). Run ui/make-pages.mjs
// first. Until COMPILED is set from a read-only compile of the DSL, this writes only the DSL and the compile case.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
const here = path.dirname(fileURLToPath(import.meta.url));
const read = (p) => fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n");
const sha = (s) => crypto.createHash("sha256").update(Buffer.from(s, "utf8")).digest("hex");
const lit = (s) => {
  if (/^\s*GO\s*$/im.test(s)) throw new Error("a GO line inside a literal");
  if (/[^\x09\x0a\x20-\x7e]/.test(s)) throw new Error("non-ASCII inside a literal");
  return "N'" + s.split("'").join("''") + "'";
};
const CAP = "nerdery-view-collected-animal";
const OWNER = "565de6d4-ebcd-408b-9359-04d21dc62183";
const AGENT = "claude-code-opus-5-5-nerdery-slice";
const PROMISE = "nerdery-collected-animal-photo-view";
const PUBLISHER = "owner:nerdery-citizen-slice";
const CARRY = "sfx-vault-reference-carry-port.v1";
// Live reads of 2026-11-03 (runs 7f37814a and 98dbb7fa): the installed dispatcher, the agent's current plan (round 2 of
// the runtime repair, flown), the compiler round 2 installed, the mint, and wildlife-mine's current revision 1.
const BASE = { invoke: "sha256:08ab8afd8e62318c55f718bbb953b80ecbb62359e8740ab74528acbf03c6ee62",
  plan: "sha256:d718a828997c60c867ae0b34c7202fc20c0f51b325dd4077e4ea351cb8605d56",
  compiler: "sha256:a437984d1e7691557b473adb9b1650467ecb67a40e9a6b1251f4f7c01d3a9a81",
  mint: "sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e",
  mine: "4610946505f48000ca9a781114f66993f1552b7dc4535e3e36978310ddb5919b",
  layout: { layoutId: "ui-layout-marketing.v1", digest: "e2591ca34ce894541132dccaca54fa77d8e98b84e7f8c8c8c93ff320fe9db58c" } };
// The read-only compile of the DSL against the retained feature with the installed compiler.
const COMPILED = { run: "2e4b4b4c", documentDigest: "sha256:e6f62d7eb71418ca3a2cd7d5963af711b78feb2a7b529aee316e33844b68e796" };

// ---------- the feature and its DSL, as make-slice.mjs writes the slice's ----------
const feature = read(path.join(here, "features", `${CAP}.feature`));
const featureDigest = sha(feature);
if (/@status:not-built|unbound/.test(feature)) throw new Error("the feature has a not-built case or an unbound provider");
const caseCount = (feature.match(/^\s*@case:/gm) || []).length;
if ((feature.match(/^\s*@provider:sql-database-reader$/gm) || []).length !== caseCount || (feature.match(/^\s*@status:probed$/gm) || []).length !== caseCount)
  throw new Error("every case needs one @provider:sql-database-reader and @status:probed");
const shared = (keyword) => { const v = [...new Set([...feature.matchAll(new RegExp(`^\\s+${keyword} (.+)$`, "gm"))].map((m) => m[1]))]; if (v.length !== 1) throw new Error(`${keyword} differs across cases`); return v[0]; };
const ops = [...new Set([...feature.matchAll(/^\s+\| (nerdery-[a-z-]+\.[a-z]+) \|/gm)].map((m) => m[1]))];
if (ops.length !== 1) throw new Error(`operations ${ops}`);
const variants = feature.match(/terminal variants: ([A-Z_]+(?:, [A-Z_]+)*)\./)[1].split(", ");
const title = feature.match(/^Feature: (.+)$/m)[1];
const soThat = feature.match(/^\s*So that (.+)$/m)[1];
const input = { type: "object", additionalProperties: false, required: ["request"], properties: {
  caller: { type: "object", additionalProperties: false, properties: { principalId: { type: "string" }, sessionId: { type: "string" } } }, request: { type: "object" } } };
const output = { type: "object", additionalProperties: true, required: ["contractId", "status"], properties: { contractId: { const: `${CAP}-result.v1` }, status: { enum: variants } } };
const config = { dataSource: "sfx-identity-database", statement: `EXEC wildlife.serve @operation=N'${CAP}',@input=@input;`, resultColumn: "value" };
const dsl = [`capability ${CAP}`, `feature ${CAP} sha256:${featureDigest}`,
  `intent: ${title}, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)`,
  `outcome: ${CAP}-result.v1 ${variants.join(" or ")}, each refusal named by its reason code, so that ${soThat}`,
  `input contract ${CAP}-request.v1 ${JSON.stringify(input)}`, `output contract ${CAP}-result.v1 ${JSON.stringify(output)}`, "cli display outcome as json",
  `scenario ${CAP} root terminal`, `given: ${shared("Given")}`, `when: ${shared("When")}`, `then: ${shared("Then")}`,
  `operation ${ops[0]} uses provider sql-database-reader`, `config: ${JSON.stringify(config)}`, `input input from ${CAP} $`, `outcome from ${ops[0]} $.value`, ""].join("\n");
if (/[^\x09\x0a\x20-\x7e]/.test(dsl)) throw new Error("non-ASCII DSL");
const dslRel = `nerdery/dsl/${CAP}.dsl`;
fs.writeFileSync(path.join(here, "dsl", `${CAP}.dsl`), dsl);
const compileCase = { name: CAP, source: dslRel, retain: [`nerdery/features/${CAP}.feature`],
  ...(COMPILED ? { compiledRun: COMPILED.run } : {}),
  expect: [["$.status", "COMPILED"], ["$.document.feature.digest", `sha256:${featureDigest}`],
    ["$.document.scenarios[0].operations[4].operationId", ops[0]], ["$.document.scenarios[0].operations[4].providerCapabilityId", "sql-database-reader"],
    ["$.document.scenarios[0].portBindings[2].platformCapabilityId", CARRY], ["$.document.scenarios[0].portBindings[7].platformCapabilityId", CARRY],
    ["$.document.scenarios[0].portBindings[3].configuration.commandTimeout", "30"], ["$.document.scenarios[0].portBindings[8].configuration.commandTimeout", "30"],
    ...(COMPILED ? [["$.documentDigest", COMPILED.documentDigest]] : [])] };
fs.writeFileSync(path.join(here, "individual-compile-cases.json"), JSON.stringify([compileCase], null, 1) + "\n");
console.log(JSON.stringify({ feature: `sha256:${featureDigest}`, dsl: `sha256:${sha(dsl)}`, cases: caseCount, operation: ops[0], variants }));
if (!COMPILED) {
  console.log("compile it read-only: node conformance/run-compile.mjs nerdery/individual-compile-cases.json <outBase>, then set COMPILED");
  process.exit(0);
}

// ---------- the mechanics: the new procedure and the dispatcher that reaches it ----------
const blocks = read(path.join(here, "wildlife/wildlife.procedures.sql")).split(/\nGO\n/).map((b) => b.replace(/^(--[^\n]*\n)+/, "").replace(/\s+$/, ""));
const block = (name) => { const b = blocks.find((x) => x.startsWith(`CREATE OR ALTER PROCEDURE ${name}\n`)); if (!b) throw new Error(`${name}: no block`); return b; };
const view = block("wildlife.view_collected_animal"), invoke = block("wildlife.invoke_operation");
const verifyDigest = (b) => "sha256:" + sha(b.slice(b.indexOf("PROCEDURE ")).replace(/[\n\r \t]+$/, ""));
// The dispatcher's only change: the line that reaches the new procedure and its storage refusal.
const added = [`    ELSE IF @operation=N'${CAP}' EXEC wildlife.view_collected_animal @request=@request,@user_id=@user_id,@result=@result OUTPUT;\n`,
  `        WHEN N'${CAP}' THEN N'COLLECTION_STORAGE_UNAVAILABLE'\n`];
let invokeBase = invoke + "\n";
for (const line of added) { if (invokeBase.split(line).length !== 2) throw new Error("dispatcher: added line"); invokeBase = invokeBase.replace(line, () => ""); }
if (verifyDigest(invokeBase) !== BASE.invoke) throw new Error("the dispatcher differs from the installed one by more than the two added lines");
for (const b of [view, invoke]) if (/[^\x09\x0a\x20-\x7e]/.test(b) || /^\s*GO\s*$/im.test(b)) throw new Error("a procedure text is not plain ASCII without GO");
const normalizedDigest = (object, v) => [`DECLARE @${v} nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'${object}')),NCHAR(13)+NCHAR(10),NCHAR(10));`,
  `SET @${v}=SUBSTRING(@${v},CHARINDEX(N'PROCEDURE ${object}',@${v}),DATALENGTH(@${v})/2);`,
  `WHILE DATALENGTH(@${v})>0 AND RIGHT(@${v},1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @${v}=LEFT(@${v},DATALENGTH(@${v})/2-1);`,
  `DECLARE @${v}_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@${v} COLLATE Latin1_General_100_BIN2_UTF8)),2));`];
const digestExpr = (object) => `'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'${object}')) COLLATE Latin1_General_100_BIN2_UTF8)),2))`;
const stop = (tag, why) => ["BEGIN", ` RAISERROR(N'${tag}: ${why.split("'").join("''")}',16,1);`, " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END"];

// ---------- the pages ----------
const pageDoc = (slug) => { const p = JSON.parse(read(path.join(here, "ui/pages", `${slug}.json`))); return { ...p, text: JSON.stringify(p) }; };
const mine = pageDoc("wildlife-mine"), individual = pageDoc("wildlife-individual");
if (mine.revision !== 2 || individual.revision !== 1) throw new Error("run ui/make-pages.mjs: wildlife-mine revision 2, wildlife-individual revision 1");

// ---------- one promise, one plan ----------
const fast = JSON.parse(read(path.join(here, "flights/fast-path.steps.json")));
const template = fast.steps.find((s) => s.stepId === "declare-view-collected-animals");
if (!template) throw new Error("the fast path's declaration step");
const declareInput = { ...template.input, payload: { ...template.input.payload, source: dsl } };
const promise = { contractId: "flight-promise.v1", promiseId: PROMISE, workClass: "owner-objective",
  statement: "OV3 declares nerdery-view-collected-animal, the view of one collected individual with the photo its owner uploaded, feature first: the declaration binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT, and the stored document is exactly the reviewed one.",
  obligations: [{ obligationId: "O1",
    statement: `${CAP} is declared from ${dslRel}, pinned to its canonical feature sha256:${featureDigest}, and its stored document is ${COMPILED.documentDigest}.`,
    evidence: `apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest ${COMPILED.documentDigest}` }] };
const steps = [{ stepId: "plan-header", contractId: "estate-flight-plan.v1", promiseId: PROMISE, flightType: "execution", workClass: "owner-objective", unknowns: [] },
  { stepId: "declare-view-collected-animal", capabilityId: "apply-declared-change",
    historicalBasis: `the eight slice capabilities were declared this way by capability-from-dsl (flight 9810b9af, scaffold CREATE) and re-declared by the two runtime repair flights; this DSL compiles COMPILED to ${COMPILED.documentDigest} against the retained bytes of its feature with the installed compiler (read-only run ${COMPILED.run}, and again inside nerdery/sql/photo-1-estate), and its operation's mechanics met every case of that feature read-only (run ef3510aa)`,
    input: declareInput, obligationIds: ["O1"], expect: { path: "$.disposition", equals: "COMMITTED" } },
  { stepId: "prove-view-collected-animal", capabilityId: "read-declared-capability-document",
    historicalBasis: "read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler's documentDigest for the same source (the repair flights proved all eight slice capabilities this way)",
    input: { capabilityId: CAP }, obligationIds: ["O1"], expect: { path: "$.documentDigest", equals: COMPILED.documentDigest } }];
const objective = "Declare nerdery-view-collected-animal, the view of one collected individual with the photo its owner uploaded, feature first through OV3's own change: capability-from-dsl binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT; prove the stored document is exactly the reviewed one by its digest.";
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
const retained = [[`capability-feature:${CAP}`, feature], [`flight-promise:${PROMISE}`, promiseText]];
const publish = [[mine, 2, 1], [individual, 1, null]];
emitPair("photo-1-estate", [
  "-- WHAT THIS DOES, in one transaction on the estate database:",
  `--   1. retains, through model.mint_content_artifact, the bytes of the canonical feature of ${CAP}`,
  `--      (sha256:${featureDigest}) and the promise flight-promise:${PROMISE};`,
  `--   2. compiles the capability's DSL with the installed compiler against those bytes: COMPILED to ${COMPILED.documentDigest},`,
  "--      the document the flight declares;",
  "--   3. publishes two pages through sidefx_ui.stage_ui_page and sidefx_ui.promote_ui_page: wildlife-mine revision 2, whose",
  "--      cards each open their individual, and wildlife-individual revision 1, which shows the individual's photo. Both read",
  "--      back READ through analysis.read_ui_page_document.",
  "-- WHERE: the estate database. Run the whole file in one session (under a minute).",
  `-- BASES: compiler body ${BASE.compiler}, mint ${BASE.mint}, the no-drift check installed, wildlife-mine current at`,
  "-- revision 1 with its reviewed digest, no wildlife-individual page yet.",
  "-- RESULT SETS: base; minted (2 rows); readback (retained 1 each); compile (status COMPILED, document = expected); pages",
  "-- (2 rows, digest_matches 1, read_status READ).",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  ...normalizedDigest("analysis.compile_capability_dsl", "cd"),
  `DECLARE @m varchar(80)=${digestExpr("model.mint_content_artifact")};`,
  "DECLARE @check int=CASE WHEN OBJECT_ID(N'analysis.check_capability_feature_conformance') IS NOT NULL THEN 1 ELSE 0 END;",
  "DECLARE @mine_revision int=(SELECT revision FROM sidefx_ui.ui_current_page WHERE page_id=N'ui-page-wildlife-mine');",
  "DECLARE @mine_digest char(64)=(SELECT d.digest FROM sidefx_ui.ui_current_page c JOIN sidefx_ui.ui_page_definition d ON d.page_id=c.page_id AND d.revision=c.revision WHERE c.page_id=N'ui-page-wildlife-mine');",
  "DECLARE @individual int=(SELECT COUNT(*) FROM sidefx_ui.ui_page_definition WHERE page_id=N'ui-page-wildlife-individual' OR path=N'/circuit/wildlife-individual');",
  `DECLARE @layout int=(SELECT COUNT(*) FROM sidefx_ui.ui_layout_definition WHERE layout_id=N'${BASE.layout.layoutId}' AND digest='${BASE.layout.digest}');`,
  `SELECT N'base' AS result_set,@cd_digest AS compiler_body,'${BASE.compiler}' AS compiler_expected,@m AS mint_installed,@check AS check_installed,`,
  " @mine_revision AS mine_revision,@mine_digest AS mine_digest,@individual AS individual_pages,@layout AS layout_declared;",
  `IF @cd_digest IS NULL OR @cd_digest<>'${BASE.compiler}' OR @m IS NULL OR @m<>'${BASE.mint}' OR @check<>1 OR ISNULL(@mine_revision,0)<>1`,
  ` OR ISNULL(@mine_digest,'')<>'${BASE.mine}' OR @individual<>0 OR @layout<>1`,
  ...stop("PHOTO1_BASE", "the compiler, the mint, the check, wildlife-mine or the layout is not the reviewed base, or wildlife-individual exists already; nothing is changed."), "GO"], [
  "SET NOCOUNT ON;",
  "DECLARE @minted TABLE(ordinal int IDENTITY(1,1),value nvarchar(max));",
  ...retained.map(([kind, text]) => `INSERT @minted(value) EXEC model.mint_content_artifact @document=${lit(JSON.stringify({ artifactKind: kind, text }))};`),
  "SELECT N'minted' AS result_set,ordinal,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,JSON_VALUE(value,'$.content_digest') AS content_digest FROM @minted ORDER BY ordinal;",
  "DECLARE @want TABLE(ordinal int PRIMARY KEY,artifact_kind nvarchar(80),digest varchar(80));",
  `INSERT @want VALUES${retained.map(([kind, text], i) => `(${i + 1},N'${kind}','sha256:${sha(text)}')`).join(",")};`,
  "SELECT N'readback' AS result_set,w.ordinal,w.artifact_kind,w.digest,CASE WHEN EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=w.artifact_kind COLLATE Latin1_General_100_BIN2 AND a.content_digest=CONVERT(binary(32),SUBSTRING(w.digest,8,64),2)) THEN 1 ELSE 0 END AS retained FROM @want w ORDER BY w.ordinal;",
  "IF EXISTS(SELECT 1 FROM @want w WHERE NOT EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=w.artifact_kind COLLATE Latin1_General_100_BIN2 AND a.content_digest=CONVERT(binary(32),SUBSTRING(w.digest,8,64),2)))",
  ...stop("PHOTO1_VERIFY_FAILED", "a retained text is not under the digest of its reviewed bytes; nothing is kept."),
  "DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);",
  "DECLARE @in nvarchar(max),@r nvarchar(max);", "DECLARE @t TABLE(v nvarchar(max));",
  `SET @in=(SELECT ${lit(dsl)} AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);`,
  "INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;", "SELECT @r=v FROM @t;",
  `SELECT N'compile' AS result_set,JSON_VALUE(@r,N'$.status') AS status,JSON_VALUE(@r,N'$.documentDigest') AS document,'${COMPILED.documentDigest}' AS expected;`,
  `IF ISNULL(JSON_VALUE(@r,N'$.status'),N'')<>N'COMPILED' OR ISNULL(JSON_VALUE(@r,N'$.documentDigest'),N'')<>N'${COMPILED.documentDigest}'`,
  ...stop("PHOTO1_COMPILE_FAILED", "the DSL does not compile to the reviewed document against the retained feature; nothing is kept."),
  "DECLARE @pages TABLE(ordinal int PRIMARY KEY,page_id nvarchar(400) COLLATE Latin1_General_100_BIN2,path nvarchar(400) COLLATE Latin1_General_100_BIN2,",
  " revision int,expected_current int,document nvarchar(max),digest char(64) COLLATE Latin1_General_100_BIN2);",
  ...publish.map(([d, revision, current], i) => `INSERT @pages VALUES(${i + 1},${lit(d.pageId)},${lit(d.path)},${revision},${current ?? "NULL"},${lit(d.text)},'${sha(d.text)}');`),
  "DECLARE @i int=1,@n int=(SELECT COUNT(*) FROM @pages),@id nvarchar(400),@path nvarchar(400),@doc nvarchar(max),@rev int,@cur int;",
  "WHILE @i<=@n",
  "BEGIN",
  " SELECT @id=page_id,@path=path,@doc=document,@rev=revision,@cur=expected_current FROM @pages WHERE ordinal=@i;",
  ` EXEC sidefx_ui.stage_ui_page @page_id=@id,@path=@path,@revision=@rev,@document_json=@doc,@namespace_id=N'sidefx:ui',@published_by=N'${PUBLISHER}';`,
  ` EXEC sidefx_ui.promote_ui_page @candidate_revision=@rev,@expected_current_revision=@cur,@actor=N'${PUBLISHER}',@page_id=@id;`,
  " SET @i+=1;",
  "END",
  "DECLARE @verify TABLE(ordinal int,path nvarchar(400),digest_matches int,read_status nvarchar(40));",
  "SET @i=1;",
  "WHILE @i<=@n",
  "BEGIN",
  " DECLARE @read nvarchar(max),@pin nvarchar(max);",
  " SELECT @path=path,@rev=revision FROM @pages WHERE ordinal=@i;",
  " SET @pin=(SELECT @path AS [payload.path] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);",
  " EXEC analysis.read_ui_page_document @input=@pin,@estate_model_pk=NULL,@result=@read OUTPUT,@emit=0;",
  " INSERT @verify SELECT p.ordinal,p.path,CASE WHEN d.digest COLLATE Latin1_General_100_BIN2=p.digest THEN 1 ELSE 0 END,JSON_VALUE(@read,N'$.status')",
  "  FROM @pages p JOIN sidefx_ui.ui_current_page c ON c.page_id=p.page_id COLLATE Latin1_General_100_BIN2 AND c.revision=p.revision",
  "  JOIN sidefx_ui.ui_page_definition d ON d.page_id=c.page_id AND d.revision=c.revision WHERE p.ordinal=@i;",
  " SET @i+=1;",
  "END",
  "SELECT N'pages' AS result_set,ordinal,path,digest_matches,read_status FROM @verify ORDER BY ordinal;",
  "IF (SELECT COUNT(*) FROM @verify WHERE digest_matches=1 AND read_status=N'READ')<>@n",
  ...stop("PHOTO1_PAGES_FAILED", "a page is not current at its reviewed revision and digest or does not read back READ; nothing is kept.")]);
const smoke = [
  ["Blake views his individual", `{"encounterId":"enc-008"}`, "user-b", ["$.status", "VISIBLE"], ["$.animal.photo.photoRef", "photo-other"], ["$.animal.photo.byteLength", "73"],
    ["$.animal.photo.contentSha256", "sha256:bafa6c640062744ce1559dcdbb23cbddec6d7d1d6833661634feeef2553ecc68"]],
  ["Avery asks for Blake's individual", `{"encounterId":"enc-008"}`, "user-a", ["$.status", "REFUSED"], ["$.reason.code", "ENCOUNTER_NOT_FOUND"]],
  ["Avery names no encounter", "{}", "user-a", ["$.reason.code", "ENCOUNTER_SELECTION_REQUIRED"]]];
emitPair("photo-2-identity", [
  "-- WHAT THIS DOES, in one transaction on the sfx-identity database:",
  `--   1. installs wildlife.view_collected_animal, the mechanics of ${CAP}: one of the caller's own individuals with`,
  "--      the bytes of the photo it was recorded with (base64), its media type and digest; another user's individual is",
  "--      answered ENCOUNTER_NOT_FOUND. Its texts met all 6 cases of the feature read-only (run ef3510aa);",
  "--   2. alters wildlife.invoke_operation by two lines only: the dispatch to that procedure and its storage refusal;",
  "--   3. verifies both bodies by digest and calls the new operation: Blake's own individual is VISIBLE with photo bytes whose",
  "--      sha256 is the stored digest, Avery asking for it is refused, an anonymous call is refused, and home still answers;",
  `--   4. records the plan of flight ${PROMISE} under planner agent ${AGENT} through evidence.upsert_flight_plan:`,
  `--      declare the capability from its DSL and prove its stored document. The plan is nerdery/flights/individual.steps.json;`,
  `--      its digest is ${planDigest}.`,
  "-- RUN photo-1-estate FIRST. WHERE: sfx-identity. Run the whole file in one session (a few seconds).",
  `-- BASES: wildlife.invoke_operation ${BASE.invoke}, no wildlife.view_collected_animal yet, the owner principal active,`,
  `-- the plan writer's four parameters, the agent's current plan ${BASE.plan} (round 2 of the runtime repair, flown).`,
  "-- RESULT SETS: base; verify (digest_matches 1 each); smoke (every passed 1); plans (matches_reviewed_file 1).",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  `DECLARE @p uniqueidentifier='${OWNER}';`,
  ...normalizedDigest("wildlife.invoke_operation", "io"),
  "DECLARE @view int=CASE WHEN OBJECT_ID(N'wildlife.view_collected_animal') IS NULL THEN 0 ELSE 1 END;",
  "DECLARE @owner int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id=@p AND active=1),",
  " @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));",
  `DECLARE @current binary(32)=(SELECT plan_digest FROM evidence.flight_plan WHERE principal_id=@p AND agent_id=${lit(AGENT)});`,
  "SELECT N'base' AS result_set,@io_digest AS dispatcher_installed,@view AS view_procedure_exists,@owner AS owner_principal_active,@params AS plan_writer_parameters,",
  " N'sha256:'+LOWER(CONVERT(varchar(64),@current,2)) AS current_plan;",
  `IF @io_digest IS NULL OR @io_digest<>'${BASE.invoke}' OR @view<>0 OR @owner<>1 OR @params<>4 OR @current IS NULL OR @current<>CONVERT(binary(32),'${BASE.plan.slice(7)}',2)`,
  ...stop("PHOTO2_BASE", "the dispatcher, the view procedure, the owner principal, the plan writer or the agent's current plan is not the reviewed base; nothing is changed."),
  "GO", view, "GO", invoke, "GO"], [
  "SET NOCOUNT ON;",
  `DECLARE @p uniqueidentifier='${OWNER}';`,
  "DECLARE @digests TABLE(object_name nvarchar(200),digest varchar(80));",
  ...normalizedDigest("wildlife.view_collected_animal", "v1"), "INSERT @digests VALUES(N'wildlife.view_collected_animal',@v1_digest);",
  ...normalizedDigest("wildlife.invoke_operation", "v2"), "INSERT @digests VALUES(N'wildlife.invoke_operation',@v2_digest);",
  `DECLARE @want TABLE(object_name nvarchar(200),digest varchar(80)); INSERT @want VALUES(N'wildlife.view_collected_animal','${verifyDigest(view)}'),(N'wildlife.invoke_operation','${verifyDigest(invoke)}');`,
  "SELECT N'verify' AS result_set,w.object_name,w.digest AS reviewed,d.digest AS installed,CASE WHEN d.digest=w.digest THEN 1 ELSE 0 END AS digest_matches FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name ORDER BY w.object_name;",
  "DECLARE @smoke TABLE(o int IDENTITY(1,1),item nvarchar(200),actual nvarchar(400),expected nvarchar(400),passed bit);",
  "DECLARE @r nvarchar(max);", "DECLARE @t TABLE(v nvarchar(max));",
  ...smoke.flatMap(([item, req, user, ...expects]) => [`EXEC wildlife.invoke_operation @operation=N'${CAP}',@request=N'${req}',@user_id=N'${user}',@result=@r OUTPUT;`,
    ...expects.map(([p, eq]) => `INSERT @smoke(item,actual,expected,passed) VALUES(${lit(`${item}: ${p}`)},JSON_VALUE(@r,N'${p}'),N'${eq}',CASE WHEN JSON_VALUE(@r,N'${p}')=N'${eq}' THEN 1 ELSE 0 END);`)]),
  `EXEC wildlife.invoke_operation @operation=N'${CAP}',@request=N'{"encounterId":"enc-008"}',@user_id=N'user-b',@result=@r OUTPUT;`,
  "DECLARE @bytes varbinary(max)=(SELECT b FROM OPENJSON(@r) WITH (b varbinary(max) N'$.animal.photo.contentBase64'));",
  "DECLARE @bytes_sha nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',@bytes),2));",
  "INSERT @smoke(item,actual,expected,passed) VALUES(N'the returned bytes hash to the stored digest',@bytes_sha,JSON_VALUE(@r,N'$.animal.photo.contentSha256'),CASE WHEN @bytes_sha=JSON_VALUE(@r,N'$.animal.photo.contentSha256') THEN 1 ELSE 0 END);",
  `INSERT @t EXEC wildlife.serve @operation=N'${CAP}',@input=N'{"request":{"encounterId":"enc-008"}}';`,
  "SELECT @r=v FROM @t; DELETE @t;",
  "INSERT @smoke(item,actual,expected,passed) VALUES(N'anonymous call: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'AUTHENTICATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'AUTHENTICATION_REQUIRED' THEN 1 ELSE 0 END);",
  "EXEC wildlife.invoke_operation @operation=N'nerdery-view-wildlife-home',@request=N'{}',@user_id=N'user-b',@result=@r OUTPUT;",
  "INSERT @smoke(item,actual,expected,passed) VALUES(N'home as Blake still answers: $.status',JSON_VALUE(@r,N'$.status'),N'VISIBLE',CASE WHEN JSON_VALUE(@r,N'$.status')=N'VISIBLE' THEN 1 ELSE 0 END);",
  "SELECT N'smoke' AS result_set,item,actual,expected,passed FROM @smoke ORDER BY o;",
  "IF EXISTS(SELECT 1 FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name WHERE d.digest IS NULL OR d.digest<>w.digest) OR EXISTS(SELECT 1 FROM @smoke WHERE passed=0)",
  ...stop("PHOTO2_VERIFY_FAILED", "an installed body is not the reviewed text, or a call did not answer as tested; nothing is kept."),
  "DECLARE @plans TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));",
  `INSERT @plans EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=${lit(AGENT)},@objective=${lit(objective)},`, ` @steps_json=${lit(stepsJson)};`,
  `SELECT N'plans' AS result_set,${lit(AGENT)} AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'${planDigest.slice(7)}',2) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @plans;`,
  `IF NOT EXISTS(SELECT 1 FROM @plans WHERE plan_digest=CONVERT(binary(32),'${planDigest.slice(7)}',2))`,
  ...stop("PHOTO2_PLAN_MISMATCH", "the recorded plan is not the reviewed one; nothing is kept.")]);
files["flights/individual.steps.json"] = JSON.stringify({ agentId: AGENT, promise, objective, planDigest, steps }, null, 2) + "\n";

// ---------- write and verify ----------
for (const [rel, text] of Object.entries(files)) {
  if (/[^\x09\x0a\x20-\x7e]/.test(text)) throw new Error(`${rel}: non-ASCII`);
  fs.mkdirSync(path.dirname(path.join(here, rel)), { recursive: true });
  fs.writeFileSync(path.join(here, rel), text);
}
const unlit = (l) => l.slice(2, -1).split("''").join("'");
for (const suffix of ["", ".commit"]) {
  const t2 = files[`sql/photo-2-identity${suffix}.sql`], m = t2.match(/@steps_json=(N'(?:[^']|'')*');/), o = t2.match(/@objective=(N'(?:[^']|'')*'),/);
  if (!m || unlit(m[1]) !== stepsJson || !o || unlit(o[1]) !== objective) throw new Error("photo-2: plan literal round trip");
  const batches = t2.split("\nGO\n");
  if (batches[1] !== view || batches[2] !== invoke) throw new Error("photo-2: the install batches are not the reviewed texts");
  const t1 = files[`sql/photo-1-estate${suffix}.sql`];
  const docs = [...t1.matchAll(/@document=(N'(?:[^']|'')*');/g)].map((x) => JSON.parse(unlit(x[1])));
  if (docs.length !== 2 || docs.some((d, i) => d.artifactKind !== retained[i][0] || d.text !== retained[i][1])) throw new Error("photo-1: retained literal round trip");
  const src = t1.match(/SET @in=\(SELECT (N'(?:[^']|'')*') AS source/);
  if (!src || unlit(src[1]) !== dsl) throw new Error("photo-1: DSL literal round trip");
  const pages = [...t1.matchAll(/INSERT @pages VALUES\(\d+,N'[^']*',N'[^']*',\d+,(?:\d+|NULL),(N'(?:[^']|'')*'),'([0-9a-f]{64})'\);/g)];
  if (pages.length !== 2 || pages.some((x, i) => unlit(x[1]) !== publish[i][0].text || x[2] !== sha(publish[i][0].text))) throw new Error("photo-1: page literal round trip");
}
const out = { generated: "2026-11-03", capabilityId: CAP, feature: `sha256:${featureDigest}`, dsl: `sha256:${sha(dsl)}`, document: COMPILED.documentDigest, compiledRun: COMPILED.run,
  plannerAgentId: AGENT, promiseId: PROMISE, promiseDigest: `sha256:${sha(promiseText)}`, planDigest, steps: steps.length - 1,
  procedures: [{ name: "wildlife.view_collected_animal", verifyDigest: verifyDigest(view) }, { name: "wildlife.invoke_operation", verifyDigest: verifyDigest(invoke), base: BASE.invoke }],
  pages: publish.map(([d, revision]) => ({ path: d.path, revision, digest: `sha256:${sha(d.text)}` })), twinParity: pairs,
  files: Object.keys(files).map((f) => ({ file: `nerdery/${f}`, bytes: Buffer.byteLength(files[f]), sha256: `sha256:${sha(files[f])}` })) };
fs.writeFileSync(path.join(here, "manifest.individual.json"), JSON.stringify(out, null, 1) + "\n");
console.log(JSON.stringify({ planDigest, promiseDigest: out.promiseDigest, document: out.document, pages: out.pages, twinParity: pairs }, null, 1));
