// Runs Nerdery acceptance cases read-only through sql-database-reader on the sfx-identity database. The wildlife
// tables are created as session temp tables (#w_*) and the procedures as session temp procedures (#wp_*); each case
// loads the pinned base state with its fixture's top-level replacements, runs its operation as the fixture's subject
// (the trusted boundary the fixture names) and reads the stored state back. Nothing is written to the database.
//
// usage: node run-cases.mjs <nerdery-canonical-features dir> <outBase> <gherkin node_modules> <capability-id>... [--case <id>]...
//   Storage faults are real failures of the store: a refused write (a CHECK constraint that rejects every row) for
//   FAIL_BEFORE_COMMIT, an absent table for UNAVAILABLE. A case passes when every Then row holds and the stored state
//   agrees: a refusal or a read leaves it unchanged, an applied mutation is read back as returned.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
const here = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const only = [];
for (let i = args.indexOf("--case"); i >= 0; i = args.indexOf("--case")) { only.push(args[i + 1]); args.splice(i, 2); }
const [pkg, outBase, modules, ...caps] = args;
const require = createRequire(import.meta.url);
const gherkin = require(modules + "/@cucumber/gherkin");
const { IdGenerator } = require(modules + "/@cucumber/messages");
const read = (p) => fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n");

// ---------- the cases ----------
const cases = [];
for (const cap of caps) {
  const dir = fs.existsSync(path.join(pkg, "features/mvp", cap + ".feature")) ? "mvp" : "offline-candidate";
  const id = IdGenerator.incrementing();
  const doc = new gherkin.Parser(new gherkin.AstBuilder(id), new gherkin.GherkinClassicTokenMatcher()).parse(read(path.join(pkg, "features", dir, cap + ".feature")));
  for (const p of gherkin.compile(doc, "f", id)) {
    const caseId = p.tags.find((t) => t.name.startsWith("@case:")).name.slice(6);
    if (only.length && !only.includes(caseId)) continue;
    const ds = p.steps.map((s) => s.argument && s.argument.docString).find((d) => d);
    const tbl = p.steps.map((s) => s.argument && s.argument.dataTable).find((t) => t);
    const fx = JSON.parse(read(path.join(pkg, "fixtures/cases", caseId + ".json")));
    cases.push({ cap, caseId, request: JSON.parse(ds.content), fx, then: tbl.rows.slice(1).map((r) => r.cells.map((c) => c.value)) });
  }
}
const base = JSON.parse(read(path.join(pkg, "fixtures/base-state.json")));
const media = fs.readdirSync(path.join(pkg, "fixtures/media")).map((f) => {
  const bytes = fs.readFileSync(path.join(pkg, "fixtures/media", f));
  return { sha: crypto.createHash("sha256").update(bytes).digest("hex"), b64: bytes.toString("base64") };
});
const avatarBytesSha = base.avatarPhotos[0].sha256;
const stateOf = (fx) => {
  const s = { ...base, ...(fx.replaceTopLevel || {}) };
  const extra = ((fx.arrangement || {}).retainedAvatarReferences || []).map((photoRef) => ({ photoRef, path: base.avatarPhotos[0].path, sha256: avatarBytesSha }));
  return { ...s, avatarPhotos: [...(s.avatarPhotos || []), ...extra] };
};
const faultsOf = (fx) => {
  const f = { check: [], omit: [] };
  for (const [k, v] of Object.entries(fx.providerBehavior || {})) {
    const table = { catalogStorage: "animal_definition", photoStorage: "photo", encounterStorage: "encounter", teamStorage: "team" }[k];
    if (!table) throw new Error(`${fx.caseId}: no fault injection for ${k}`);
    if (v === "UNAVAILABLE") f.omit.push(table); else if (v === "FAIL_BEFORE_COMMIT") f.check.push(table); else throw new Error(`${fx.caseId}: fault ${k}=${v}`);
  }
  return f;
};

// ---------- session copies of the reviewed texts ----------
const tablesSql = read(path.join(here, "../wildlife/wildlife.tables.sql"));
const procsSql = read(path.join(here, "../wildlife/wildlife.procedures.sql"));
const tableNames = [...tablesSql.matchAll(/CREATE TABLE wildlife\.(\w+)\(/g)].map((m) => m[1]);
const procNames = [...procsSql.matchAll(/CREATE OR ALTER PROCEDURE wildlife\.(\w+)/g)].map((m) => m[1]);
const toSession = (sql) => sql.replace(/wildlife\.(\w+)/g, (m, n) => tableNames.includes(n) ? `#w_${n}` : procNames.includes(n) ? `#wp_${n}` : m);
const tableBlocks = tablesSql.split(/;\n(?=CREATE )/).map((b) => b.replace(/^(--[^\n]*\n)+/, "").replace(/;\s*$/, "")).filter((b) => b.startsWith("CREATE"));
const tableDdl = (omit) => tableBlocks.filter((b) => !omit.some((t) => b.includes(`wildlife.${t}(`) || b.includes(`ON wildlife.${t}(`))).map((b) => toSession(b) + ";").join("\n");
const procBlocks = procsSql.split(/\nGO\n/).map((b) => b.replace(/^(--[^\n]*\n)+/, "")).filter((b) => b.startsWith("CREATE OR ALTER PROCEDURE") && !b.includes("PROCEDURE wildlife.serve"));
const sessionProcs = procBlocks.map((b) => toSession(b).replace(/^CREATE OR ALTER PROCEDURE/, "CREATE PROCEDURE").replace(/\nWITH EXECUTE AS OWNER\nAS\n/, "\nAS\n"));
const canonicalLocation = (l) => `CASE
      WHEN JSON_VALUE(${l},N'$.source')=N'manual' AND LEN(LTRIM(RTRIM(ISNULL(JSON_VALUE(${l},N'$.description'),N''))))>0
        THEN (SELECT N'manual' AS source,JSON_VALUE(${l},N'$.description') AS description FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
      WHEN JSON_VALUE(${l},N'$.source')=N'device' AND TRY_CONVERT(decimal(9,6),JSON_VALUE(${l},N'$.latitude')) BETWEEN -90 AND 90
        AND TRY_CONVERT(decimal(9,6),JSON_VALUE(${l},N'$.longitude')) BETWEEN -180 AND 180
        THEN (SELECT N'device' AS source,TRY_CONVERT(decimal(9,6),JSON_VALUE(${l},N'$.latitude')) AS latitude,TRY_CONVERT(decimal(9,6),JSON_VALUE(${l},N'$.longitude')) AS longitude
              FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) END`;
if (!procsSql.includes(canonicalLocation("@l").replace(/\n {6}/g, "\n      "))) throw new Error("the loader's location canonicalization differs from record_animal_encounter's");
const guard = (t, sql) => `IF OBJECT_ID(N'tempdb..#w_${t}') IS NOT NULL BEGIN ${sql} END`;
const loader = `CREATE PROCEDURE #load_state @state nvarchar(max),@media nvarchar(max) AS
BEGIN
SET NOCOUNT ON;
${[...tableNames].reverse().map((t) => guard(t, `DELETE #w_${t};`)).join("\n")}
${guard("app_user", `INSERT #w_app_user(user_id,principal_id,identity_subject,first_name,last_name,email) SELECT userId,NULL,identitySubject,firstName,lastName,email FROM OPENJSON(@state,N'$.users') WITH (userId nvarchar(100),identitySubject nvarchar(200),firstName nvarchar(200),lastName nvarchar(200),email nvarchar(320));`)}
${guard("user_role", `INSERT #w_user_role(user_id,role) SELECT u.userId,r.[value] FROM OPENJSON(@state,N'$.users') WITH (userId nvarchar(100),roles nvarchar(max) AS JSON) u CROSS APPLY OPENJSON(u.roles) r;`)}
${guard("county", `INSERT #w_county(county_id,name) SELECT countyId,name FROM OPENJSON(@state,N'$.counties') WITH (countyId nvarchar(100),name nvarchar(200));`)}
${guard("animal_type", `INSERT #w_animal_type(type_name,ordinal) SELECT [value],CONVERT(int,[key]) FROM OPENJSON(@state,N'$.types');`)}
${guard("attribute", `INSERT #w_attribute(attribute_id,revision,active,name,description) SELECT attributeId,revision,active,name,description FROM OPENJSON(@state,N'$.attributes') WITH (attributeId nvarchar(100),revision int,active bit,name nvarchar(200),description nvarchar(2000));`)}
${guard("attribute_value", `INSERT #w_attribute_value(attribute_id,value_id,label,ordinal) SELECT a.attributeId,JSON_VALUE(v.[value],N'$.valueId'),JSON_VALUE(v.[value],N'$.label'),CONVERT(int,v.[key]) FROM OPENJSON(@state,N'$.attributes') WITH (attributeId nvarchar(100),sv nvarchar(max) N'$.selectableValues' AS JSON) a CROSS APPLY OPENJSON(a.sv) v;`)}
DECLARE @defs TABLE(definitionId nvarchar(100),revision int,active bit,commonName nvarchar(200),scientificName nvarchar(200),avatarPhotoRef nvarchar(100),collectionNumber int,[range] nvarchar(max),types nvarchar(max),stats nvarchar(max),attributes nvarchar(max));
INSERT @defs SELECT * FROM OPENJSON(@state,N'$.animalDefinitions') WITH (definitionId nvarchar(100),revision int,active bit,commonName nvarchar(200),scientificName nvarchar(200),avatarPhotoRef nvarchar(100),collectionNumber int,[range] nvarchar(max) AS JSON,types nvarchar(max) AS JSON,stats nvarchar(max) AS JSON,attributes nvarchar(max) AS JSON);
${guard("animal_definition", `INSERT #w_animal_definition(definition_id,revision,active,common_name,scientific_name,avatar_photo_ref,collection_number,range_json,types_json,stats_json,attributes_json) SELECT definitionId,revision,active,commonName,scientificName,avatarPhotoRef,collectionNumber,[range],types,stats,attributes FROM @defs;`)}
${guard("definition_county", `INSERT #w_definition_county(definition_id,county_id) SELECT d.definitionId,r.[value] FROM @defs d CROSS APPLY OPENJSON(d.[range]) r;`)}
${guard("definition_type", `INSERT #w_definition_type(definition_id,type_name) SELECT d.definitionId,t.[value] FROM @defs d CROSS APPLY OPENJSON(d.types) t;`)}
${guard("definition_attribute_value", `INSERT #w_definition_attribute_value(definition_id,attribute_id,value_id) SELECT d.definitionId,JSON_VALUE(a.[value],N'$.attributeId'),v.[value] FROM @defs d CROSS APPLY OPENJSON(d.attributes) a CROSS APPLY OPENJSON(a.[value],N'$.valueIds') v;`)}
DECLARE @m TABLE(sha nvarchar(64) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,b varbinary(max));
INSERT @m SELECT sha,bytes FROM OPENJSON(@media) WITH (sha nvarchar(64),bytes varbinary(max) N'$.b64');
${guard("photo", `INSERT #w_photo(photo_ref,owner_user_id,purpose,media_type,content_sha256,content_bytes,byte_length,durable)
  SELECT p.photoRef,p.ownerUserId,N'encounter',p.mediaType,CONVERT(binary(32),SUBSTRING(p.contentSha256,8,64),2),m.b,DATALENGTH(m.b),p.durable
  FROM OPENJSON(@state,N'$.photos') WITH (photoRef nvarchar(100),ownerUserId nvarchar(100),mediaType nvarchar(100),contentSha256 nvarchar(80),durable bit) p
  LEFT JOIN @m m ON m.sha=SUBSTRING(p.contentSha256,8,64);
INSERT #w_photo(photo_ref,owner_user_id,purpose,media_type,content_sha256,content_bytes,byte_length,durable)
  SELECT a.photoRef,NULL,N'avatar',N'image/png',CONVERT(binary(32),SUBSTRING(a.sha256,8,64),2),m.b,DATALENGTH(m.b),1
  FROM OPENJSON(@state,N'$.avatarPhotos') WITH (photoRef nvarchar(100),sha256 nvarchar(80)) a
  LEFT JOIN @m m ON m.sha=SUBSTRING(a.sha256,8,64);`)}
${guard("encounter", `INSERT #w_encounter(owner_user_id,encounter_id,definition_id,location_json,photo_ref,nickname)
  SELECT e.ownerUserId,e.encounterId,e.definitionId,${canonicalLocation("e.location")},e.photoRef,e.nickname
  FROM OPENJSON(@state,N'$.encounters') WITH (encounterId nvarchar(100),ownerUserId nvarchar(100),definitionId nvarchar(100),location nvarchar(max) AS JSON,photoRef nvarchar(100),nickname nvarchar(200)) e;`)}
${guard("team", `INSERT #w_team(owner_user_id,revision) SELECT ownerUserId,revision FROM OPENJSON(@state,N'$.teams') WITH (ownerUserId nvarchar(100),revision int);`)}
${guard("team_member", `INSERT #w_team_member(owner_user_id,ordinal,encounter_id) SELECT t.ownerUserId,CONVERT(int,m.[key]),m.[value] FROM OPENJSON(@state,N'$.teams') WITH (ownerUserId nvarchar(100),ids nvarchar(max) N'$.encounterIds' AS JSON) t CROSS APPLY OPENJSON(t.ids) m;`)}
END`;
const digestOf = (omit) => {
  const parts = [["encounter", "owner_user_id,encounter_id,definition_id,location_json,photo_ref,nickname", "owner_user_id,encounter_id"], ["team", "owner_user_id,revision", "owner_user_id"],
    ["team_member", "owner_user_id,ordinal,encounter_id", "owner_user_id,ordinal"], ["photo", "photo_ref,owner_user_id,purpose,media_type,content_sha256,byte_length,durable", "photo_ref"],
    ["animal_definition", "definition_id,revision,active,common_name,scientific_name,avatar_photo_ref,collection_number,range_json,types_json,stats_json,attributes_json", "definition_id"],
    ["definition_county", "definition_id,county_id", "definition_id,county_id"], ["definition_type", "definition_id,type_name", "definition_id,type_name"],
    ["definition_attribute_value", "definition_id,attribute_id,value_id", "definition_id,attribute_id,value_id"], ["attribute", "attribute_id,revision,active,name,description", "attribute_id"],
    ["attribute_value", "attribute_id,value_id,label,ordinal", "attribute_id,value_id"]].filter(([t]) => !omit.includes(t));
  return `CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),(SELECT ${parts.map(([t, cols, ord]) => `(SELECT ${cols} FROM #w_${t} ORDER BY ${ord} FOR JSON PATH,INCLUDE_NULL_VALUES) AS [${t}]`).join(",")} FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) COLLATE Latin1_General_100_BIN2_UTF8))),2)`;
};
const readBack = (omit) => `(SELECT
  JSON_QUERY((SELECT p.photo_ref AS photoRef,p.owner_user_id AS ownerUserId,p.purpose,p.media_type AS mediaType,N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',p.content_bytes),2)) AS storedBytesSha256,p.byte_length AS byteLength,p.durable
     FROM #w_photo p WHERE p.photo_ref=JSON_VALUE(@result,N'$.photo.photoRef') FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS photo,
  JSON_QUERY((SELECT e.encounter_id AS encounterId,e.owner_user_id AS ownerUserId,e.definition_id AS definitionId,JSON_QUERY(e.location_json) AS location,e.photo_ref AS photoRef,e.nickname
     FROM #w_encounter e WHERE e.owner_user_id=@subject AND e.encounter_id=JSON_VALUE(@request,N'$.encounterId') FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS encounter,
  (SELECT COUNT(*) FROM #w_encounter e WHERE e.owner_user_id=@subject) AS ownerEncounters,
  ${omit.includes("team") ? "NULL" : `JSON_QUERY((SELECT t.revision,JSON_QUERY(ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+m.encounter_id+N'"'),N',') WITHIN GROUP (ORDER BY m.ordinal)+N']' FROM #w_team_member m WHERE m.owner_user_id=@subject),N'[]')) AS encounterIds
     FROM #w_team t WHERE t.owner_user_id=@subject FOR JSON PATH,WITHOUT_ARRAY_WRAPPER))`} AS team,
  ${omit.includes("animal_definition") ? "NULL" : `JSON_QUERY((SELECT d.definition_id AS definitionId,d.common_name AS commonName,d.scientific_name AS scientificName,d.avatar_photo_ref AS avatarPhotoRef,d.collection_number AS collectionNumber,
     JSON_QUERY(d.range_json) AS [range],JSON_QUERY(d.types_json) AS types,JSON_QUERY(d.stats_json) AS stats,JSON_QUERY(d.attributes_json) AS attributes,
     (SELECT COUNT(*) FROM #w_definition_type x WHERE x.definition_id=d.definition_id) AS typeRows,(SELECT COUNT(*) FROM #w_definition_county x WHERE x.definition_id=d.definition_id) AS countyRows,
     (SELECT COUNT(*) FROM #w_definition_attribute_value x WHERE x.definition_id=d.definition_id) AS attributeValueRows
     FROM #w_animal_definition d WHERE d.definition_id=JSON_VALUE(@result,N'$.definitionId') FOR JSON PATH,WITHOUT_ARRAY_WRAPPER))`} AS definition
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)`;
const statementFor = (omit, checks) => `SET NOCOUNT ON;
${tableDdl(omit)}
${[...sessionProcs, loader].map((p) => `EXEC(N'${p.replace(/'/g, "''")}');`).join("\n")}
DECLARE @cases TABLE(k int PRIMARY KEY,c nvarchar(max));
INSERT @cases SELECT CONVERT(int,[key]),[value] FROM OPENJSON(@input,N'$.cases');
DECLARE @out TABLE(k int PRIMARY KEY,v nvarchar(max));
DECLARE @i int=0,@n int=(SELECT COUNT(*) FROM @cases),@c nvarchar(max),@state nvarchar(max),@request nvarchar(max),@subject nvarchar(100),@operation nvarchar(100),
  @result nvarchar(max),@before varchar(64),@after varchar(64),@rb nvarchar(max),@err nvarchar(2048),@media nvarchar(max)=JSON_QUERY(@input,N'$.media'),@spid nvarchar(10)=CONVERT(nvarchar(10),@@SPID),
  @pre nvarchar(max),@pre_result nvarchar(max),@pre_subject nvarchar(100),@pre_request nvarchar(max);
WHILE @i<@n
BEGIN
  SELECT @c=c FROM @cases WHERE k=@i;
  SELECT @state=JSON_QUERY(@c,N'$.state'),@request=JSON_QUERY(@c,N'$.request'),@subject=JSON_VALUE(@c,N'$.subject'),@operation=JSON_VALUE(@c,N'$.operation'),
    @pre=JSON_QUERY(@c,N'$.prewarm'),@result=NULL,@err=NULL,@rb=NULL,@before=NULL,@after=NULL,@pre_result=NULL;
  BEGIN TRY
    EXEC #load_state @state=@state,@media=@media;
    SET @before=${digestOf(omit)};
    IF @pre IS NOT NULL
    BEGIN
      SELECT @pre_subject=JSON_VALUE(@pre,N'$.subject'),@pre_request=JSON_QUERY(@pre,N'$.request');
      EXEC #wp_invoke_operation @operation=@operation,@request=@pre_request,@user_id=@pre_subject,@result=@pre_result OUTPUT;
    END
${checks.map((t) => `    IF EXISTS(SELECT 1 FROM OPENJSON(@c,N'$.check') WHERE [value]=N'${t}') EXEC(N'ALTER TABLE #w_${t} WITH NOCHECK ADD CONSTRAINT nrd_fault_${t}_'+@spid+N' CHECK (1=0)');`).join("\n")}
    EXEC #wp_invoke_operation @operation=@operation,@request=@request,@user_id=@subject,@result=@result OUTPUT;
${checks.map((t) => `    IF EXISTS(SELECT 1 FROM OPENJSON(@c,N'$.check') WHERE [value]=N'${t}') EXEC(N'ALTER TABLE #w_${t} DROP CONSTRAINT nrd_fault_${t}_'+@spid);`).join("\n")}
    SET @after=${digestOf(omit)};
    SET @rb=${readBack(omit)};
  END TRY
  BEGIN CATCH
    SET @err=ERROR_MESSAGE()+N' (line '+CONVERT(nvarchar(10),ERROR_LINE())+N')';
    WHILE @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  END CATCH
  INSERT @out(k,v) SELECT @i,(SELECT JSON_VALUE(@c,N'$.caseId') AS caseId,JSON_QUERY(@result) AS result,@before AS stateBefore,@after AS stateAfter,JSON_QUERY(@rb) AS readBack,
    JSON_QUERY(@pre_result) AS prewarmResult,@err AS bridgeError FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @i+=1;
END
SELECT (SELECT N'['+ISNULL(STRING_AGG(CONVERT(nvarchar(max),v),N',') WITHIN GROUP (ORDER BY k),N'')+N']') AS value FROM @out;`;

// ---------- run, batch by batch (one call at a time) ----------
const sfx = process.env.SFX_SH || path.join(path.dirname(outBase), "..", "sfx.sh");
const runBatch = (batch, b) => {
  const omit = faultsOf(batch[0].fx).omit;
  const checks = [...new Set(batch.flatMap((c) => faultsOf(c.fx).check))];
  const input = { media, cases: batch.map((c) => {
    const pre = (c.fx.arrangement || {}).prewarmAuthenticatedRead;
    return { caseId: c.caseId, operation: c.cap, subject: c.fx.authenticatedSubject, request: c.request, state: stateOf(c.fx), check: faultsOf(c.fx).check,
      ...(pre ? { prewarm: { subject: pre.subject, request: pre.request } } : {}) };
  }) };
  const base = `${outBase}-${b}`;
  fs.writeFileSync(base + ".request.json", JSON.stringify({ dataSource: "sfx-identity-database", statement: statementFor(omit, checks), resultColumn: "value", input }));
  if (fs.existsSync(base + ".json")) fs.unlinkSync(base + ".json");
  let log = "";
  try { log = execFileSync("bash", [sfx, "sql-database-reader", base + ".request.json", base], { encoding: "utf8" }); } catch (e) { log = String(e.stdout || e.message); }
  process.stdout.write(log);
  const raw = fs.existsSync(base + ".json") ? fs.readFileSync(base + ".json", "utf8").trim() : "";
  if (!raw) { console.log("no result; see", base + ".err"); process.exit(2); }
  const out = JSON.parse(raw);
  const v = typeof out.value === "string" ? JSON.parse(out.value) : out.value;
  return v;
};
// Cases whose store is absent run alone; the others run in batches of at most 20.
const groups = [];
for (const c of cases) {
  const omit = faultsOf(c.fx).omit;
  const last = groups[groups.length - 1];
  if (!omit.length && last && !faultsOf(last[0].fx).omit.length && last.length < 20) last.push(c); else groups.push([c]);
}
const results = [];
groups.forEach((g, b) => results.push(...runBatch(g, b)));

// ---------- judge ----------
const at = (o, p) => p.replace(/^\$\.?/, "").split(/\.|\[(\d+)\]/).filter((x) => x !== undefined && x !== "").reduce((a, k) => (a === undefined || a === null || typeof a !== "object" ? undefined : a[k]), o);
const equal = (a, b) => {
  if (typeof a === "number" && typeof b === "number") return a === b;
  if (a === null || b === null || typeof a !== "object" || typeof b !== "object") return a === b;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  if (Array.isArray(a)) return a.length === b.length && a.every((x, i) => equal(x, b[i]));
  const ka = Object.keys(a).sort(), kb = Object.keys(b).sort();
  return ka.length === kb.length && ka.every((k, i) => k === kb[i] && equal(a[k], b[k]));
};
const expected = (cell) => { if (cell === "(absent)") return { absent: true }; try { return { value: JSON.parse(cell) }; } catch { return { value: cell }; } };
const show = (x) => (x === undefined ? "(absent)" : JSON.stringify(x));
let failed = 0;
const report = [];
cases.forEach((c, i) => {
  const r = results[i] || {};
  const bad = [];
  if (r.bridgeError) bad.push(`bridge: ${r.bridgeError}`);
  const res = r.result;
  for (const [op, p, cell] of c.then) {
    if (op !== `${c.cap}.${op.split(".").pop()}`) bad.push(`operation ${op} is not of ${c.cap}`);
    const e = expected(cell), a = at(res, p);
    if (e.absent ? a !== undefined : !equal(a, e.value)) bad.push(`${p}: ${show(a)} != ${cell}`);
  }
  const applied = res && res.mutation ? res.mutation.applied : undefined;
  if (res && applied === true) {
    if (r.stateBefore === r.stateAfter) bad.push("state: an applied mutation left the stored state unchanged");
    const rb = r.readBack || {};
    if (res.encounter && !(rb.encounter && equal(rb.encounter, res.encounter))) bad.push(`read-back: stored encounter ${show(rb.encounter)} is not the returned one`);
    if (res.photo && !(rb.photo && rb.photo.storedBytesSha256 === res.photo.contentSha256 && rb.photo.ownerUserId === res.photo.ownerUserId)) bad.push(`read-back: stored photo ${show(rb.photo)}`);
    if (res.team && !(rb.team && rb.team.revision === res.team.revision && equal(rb.team.encounterIds, res.team.encounterIds))) bad.push(`read-back: stored team ${show(rb.team)}`);
    if (res.definitionId && !(rb.definition && rb.definition.collectionNumber === res.animal.collectionNumber && equal(rb.definition.attributes, res.animal.attributes))) bad.push(`read-back: stored definition ${show(rb.definition)}`);
  } else if (res && r.stateBefore !== r.stateAfter) bad.push(`state: ${res.status} changed the stored state`);
  if (res && res.replayed === true && r.readBack && r.readBack.encounter === undefined) bad.push("read-back: replayed encounter not stored");
  failed += bad.length ? 1 : 0;
  report.push({ caseId: c.caseId, status: res ? res.status : null, ok: !bad.length, findings: bad, result: res, readBack: r.readBack });
  console.log(`${bad.length ? "FAIL" : "ok  "} ${c.caseId}: ${res ? res.status + (res.reason ? " " + res.reason.code : "") : "(no result)"}`);
  for (const x of bad) console.log("       " + x);
});
fs.writeFileSync(outBase + ".report.json", JSON.stringify(report, null, 1));
console.log(`${cases.length - failed}/${cases.length} cases met their expectations`);
process.exit(failed ? 1 : 0);
