// Writes the owner SQL of the Nerdery citizen slice and OV3's declaration flight:
//   nerdery/sql/nrd-01-wildlife-store(.commit).sql     sfx-identity: schema wildlife, its tables and procedures, and the
//                                                      synthetic seed; Avery (user-a) is the owner's principal
//   nerdery/sql/nrd-02-slice-features-and-promise(.commit).sql   estate: the eight finalized features retained by digest,
//                                                      and the promise of the declaration flight
//   nerdery/sql/nrd-03-slice-declare-plan(.commit).sql sfx-identity: the plan OV3 flies to declare the eight capabilities
//   nerdery/flights/slice-declare.steps.json           that plan's promise, objective, steps and digest
// and nerdery/manifest.json. Run make-slice.mjs first.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const SRC = path.resolve(root, "..", "nerdery-canonical-features");
const read = (p) => fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n");
const sha = (s) => crypto.createHash("sha256").update(typeof s === "string" ? Buffer.from(s, "utf8") : s).digest("hex");
const lit = (s) => {
  if (/^\s*GO\s*$/im.test(s)) throw new Error("a GO line inside a literal");
  if (/[^\x09\x0a\x20-\x7e]/.test(s)) throw new Error("non-ASCII inside a literal");
  return "N'" + s.split("'").join("''") + "'";
};
const OWNER = "565de6d4-ebcd-408b-9359-04d21dc62183";
const MINT_BASE = "sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e";
const AGENT = "claude-code-opus-5-5-nerdery-slice";
const PROMISE = "nerdery-citizen-slice-declare";
const WORK_CLASS = "owner-objective";
const slice = JSON.parse(read(path.join(here, "slice.manifest.json")));

// ---------- the reviewed texts ----------
const tablesSql = read(path.join(here, "wildlife/wildlife.tables.sql")).replace(/^(--[^\n]*\n)+/, "");
const procedures = read(path.join(here, "wildlife/wildlife.procedures.sql")).split(/\nGO\n/).map((b) => b.replace(/^(--[^\n]*\n)+/, "").replace(/\s+$/, ""))
  .filter((b) => b.startsWith("CREATE OR ALTER PROCEDURE"));
const procName = (b) => b.match(/^CREATE OR ALTER PROCEDURE (wildlife\.\w+)/)[1];
const tableNames = [...tablesSql.matchAll(/CREATE TABLE (wildlife\.\w+)\(/g)].map((m) => m[1]);
for (const t of [tablesSql, ...procedures]) if (/[^\x09\x0a\x20-\x7e]/.test(t)) throw new Error("non-ASCII in a reviewed text");
const verifyDigest = (b) => "sha256:" + sha(b.slice(b.indexOf("PROCEDURE ")).replace(/[\n\r \t]+$/, ""));
const normalizedDigest = (object, v) => `DECLARE @${v} nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'${object}')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @${v}=SUBSTRING(@${v},CHARINDEX(N'PROCEDURE ${object}',@${v}),DATALENGTH(@${v})/2);
WHILE DATALENGTH(@${v})>0 AND RIGHT(@${v},1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @${v}=LEFT(@${v},DATALENGTH(@${v})/2-1);
INSERT @digests VALUES(N'${object}','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@${v} COLLATE Latin1_General_100_BIN2_UTF8)),2)));`;

// ---------- the seed: the synthetic base catalog and the other users' collections; Avery starts empty ----------
const base = JSON.parse(read(path.join(SRC, "fixtures/base-state.json")));
const media = Object.fromEntries(fs.readdirSync(path.join(SRC, "fixtures/media")).map((f) => {
  const b = fs.readFileSync(path.join(SRC, "fixtures/media", f)); return [sha(b), b];
}));
const q = (s) => (s === null || s === undefined ? "NULL" : lit(String(s)));
const hex = (b) => "0x" + b.toString("hex").toUpperCase();
const seedUsers = base.users.map((u) => ({ ...u, principalId: u.userId === "user-a" ? OWNER : null }));
const seedEncounters = base.encounters.filter((e) => e.ownerUserId !== "user-a");
const seedPhotos = base.photos.filter((p) => p.ownerUserId !== "user-a");
const seedTeams = base.teams.filter((t) => t.ownerUserId !== "user-a");
// A stored location is canonicalized by record_animal_encounter's own expression, so a retry compares equal texts.
const canonicalLocation = read(path.join(here, "wildlife/wildlife.procedures.sql")).match(/SET @location=(CASE\n[\s\S]*?END);/)[1].replace(/@l\b/g, "x.l");
const seed = [
  ...base.counties.map((c) => `INSERT wildlife.county(county_id,name) VALUES(${q(c.countyId)},${q(c.name)});`),
  ...base.types.map((t, i) => `INSERT wildlife.animal_type(type_name,ordinal) VALUES(${q(t)},${i});`),
  ...base.attributes.map((a) => `INSERT wildlife.attribute(attribute_id,revision,active,name,description) VALUES(${q(a.attributeId)},${a.revision},${a.active ? 1 : 0},${q(a.name)},${q(a.description)});`),
  ...base.attributes.flatMap((a) => a.selectableValues.map((v, i) => `INSERT wildlife.attribute_value(attribute_id,value_id,label,ordinal) VALUES(${q(a.attributeId)},${q(v.valueId)},${q(v.label)},${i});`)),
  ...base.animalDefinitions.map((d) => `INSERT wildlife.animal_definition(definition_id,revision,active,common_name,scientific_name,avatar_photo_ref,collection_number,range_json,types_json,stats_json,attributes_json) VALUES(${q(d.definitionId)},${d.revision},${d.active ? 1 : 0},${q(d.commonName)},${q(d.scientificName)},${q(d.avatarPhotoRef)},${d.collectionNumber},${q(JSON.stringify(d.range))},${q(JSON.stringify(d.types))},${q(JSON.stringify(d.stats))},${q(JSON.stringify(d.attributes))});`),
  ...base.animalDefinitions.flatMap((d) => d.range.map((c) => `INSERT wildlife.definition_county(definition_id,county_id) VALUES(${q(d.definitionId)},${q(c)});`)),
  ...base.animalDefinitions.flatMap((d) => d.types.map((t) => `INSERT wildlife.definition_type(definition_id,type_name) VALUES(${q(d.definitionId)},${q(t)});`)),
  ...base.animalDefinitions.flatMap((d) => d.attributes.flatMap((a) => a.valueIds.map((v) => `INSERT wildlife.definition_attribute_value(definition_id,attribute_id,value_id) VALUES(${q(d.definitionId)},${q(a.attributeId)},${q(v)});`))),
  ...base.avatarPhotos.map((a) => { const b = media[a.sha256.slice(7)]; return `INSERT wildlife.photo(photo_ref,owner_user_id,purpose,media_type,content_sha256,content_bytes,byte_length,durable) VALUES(${q(a.photoRef)},NULL,N'avatar',N'image/png',0x${a.sha256.slice(7)},${hex(b)},${b.length},1);`; }),
  ...seedPhotos.map((p) => { const b = media[p.contentSha256.slice(7)]; return `INSERT wildlife.photo(photo_ref,owner_user_id,purpose,media_type,content_sha256,content_bytes,byte_length,durable) VALUES(${q(p.photoRef)},${q(p.ownerUserId)},N'encounter',${q(p.mediaType)},0x${p.contentSha256.slice(7)},${hex(b)},${b.length},${p.durable ? 1 : 0});`; }),
  ...seedUsers.map((u) => `INSERT wildlife.app_user(user_id,principal_id,identity_subject,first_name,last_name,email) VALUES(${q(u.userId)},${u.principalId ? `'${u.principalId}'` : "NULL"},${q(u.identitySubject)},${q(u.firstName)},${q(u.lastName)},${q(u.email)});`),
  ...seedUsers.flatMap((u) => u.roles.map((r) => `INSERT wildlife.user_role(user_id,role) VALUES(${q(u.userId)},${q(r)});`)),
  ...seedEncounters.map((e) => `INSERT wildlife.encounter(owner_user_id,encounter_id,definition_id,location_json,photo_ref,nickname) SELECT ${q(e.ownerUserId)},${q(e.encounterId)},${q(e.definitionId)},${canonicalLocation},${q(e.photoRef)},${q(e.nickname)} FROM (SELECT ${q(JSON.stringify(e.location))} AS l) x;`),
  ...seedTeams.map((t) => `INSERT wildlife.team(owner_user_id,revision) VALUES(${q(t.ownerUserId)},${t.revision});`),
  ...seedTeams.flatMap((t) => t.encounterIds.map((id, i) => `INSERT wildlife.team_member(owner_user_id,ordinal,encounter_id) VALUES(${q(t.ownerUserId)},${i},${q(id)});`)),
];
const counts = { county: base.counties.length, animal_type: base.types.length, attribute: base.attributes.length, animal_definition: base.animalDefinitions.length,
  photo: base.avatarPhotos.length + seedPhotos.length, app_user: seedUsers.length, encounter: seedEncounters.length, team: seedTeams.length };

const files = {};
const pairs = [];
const banner = (commit) => commit
  ? ["-- ============================== COMMIT - THIS WRITES ==============================", "-- Byte-identical to the preflight twin except this banner and the terminal statement:", "-- COMMIT TRANSACTION here, ROLLBACK TRANSACTION there. Run the preflight first."]
  : ["-- ============================== PREFLIGHT - NOT A WRITE ==============================", "-- Byte-identical to the .commit twin except this banner and the terminal statement:", "-- ROLLBACK TRANSACTION here, COMMIT TRANSACTION there. Nothing is written."];
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
const stop = (tag, why) => ["BEGIN", ` RAISERROR(N'${tag}: ${why}',16,1);`, " ROLLBACK TRANSACTION;", " SET NOEXEC ON;", "END"];

// ---------- nrd-01: the wildlife store in sfx-identity ----------
const smoke = [
  ["browse as Avery", "nerdery-browse-animal-collection", `{"search":""}`, "user-a", ["$.status", "LISTED"], ["$.total", "3"], ["$.items[0].collectionState", "UNCOLLECTED"]],
  ["home as Avery", "nerdery-view-wildlife-home", "{}", "user-a", ["$.status", "VISIBLE"], ["$.team.size", "0"]],
  ["home as Blake", "nerdery-view-wildlife-home", "{}", "user-b", ["$.status", "VISIBLE"], ["$.team.members[0].encounterId", "enc-008"]],
];
emitPair("nrd-01-wildlife-store", [
  "-- WHAT THIS ADDS: the wildlife domain store of the Nerdery citizen slice, schema wildlife in this database: 14 tables,",
  "-- 10 procedures (one per operation, the dispatcher wildlife.invoke_operation and the only entry, wildlife.serve, which",
  "-- verifies the caller's session against [identity].session) and the synthetic seed from",
  "-- nerdery-canonical-features/fixtures/base-state.json: 3 animal definitions, 2 attributes, 2 counties, 15 types, 3 avatars,",
  "-- and users Avery (citizen, mapped to the owner's principal " + OWNER + "), Blake (citizen) and Casey (biologist).",
  "-- Avery starts with no photos, encounters or team, as the handoff's first demo slice requires; Blake and Casey keep",
  "-- their base encounters (enc-008, enc-009) and teams. The data is synthetic, not DNR fauna or a selected state.",
  "-- The procedures are the texts that met all 77 cases of the slice read-only (nerdery/conformance/run-cases.mjs,",
  "-- runs 84ff8efb, c901e190, 8e66151b, 7837a8f1, b28d02da, 25e64090).",
  "-- WHERE: the sfx-identity database. Run the whole file in one session; the transaction spans the batches.",
  "-- GUARDS: no schema wildlife yet; [identity].session and [identity].principal exist; the owner principal is active.",
  "-- VERIFY (in the transaction): each procedure body, from \"PROCEDURE <name>\" on with LF line ends, hashes to its reviewed",
  "-- text; the seed counts; three calls (browse and home as Avery, home as Blake); an anonymous call and a call naming the",
  "-- owner's principal with a session that does not exist are both refused AUTHENTICATION_REQUIRED. Otherwise nothing is",
  "-- kept. RESULT SETS: base; verify (14 tables, 10 procedures, every digest_matches 1); smoke (every passed 1).",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  "DECLARE @schema int=SCHEMA_ID(N'wildlife'),@session int=CASE WHEN OBJECT_ID(N'[identity].session') IS NOT NULL AND OBJECT_ID(N'[identity].principal') IS NOT NULL THEN 1 ELSE 0 END,",
  ` @owner int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id='${OWNER}' AND active=1);`,
  "SELECT N'base' AS result_set,@schema AS wildlife_schema_id,@session AS identity_tables,@owner AS owner_principal_active;",
  "IF @schema IS NOT NULL OR @session<>1 OR @owner<>1", ...stop("NRD01_BASE", "the schema wildlife already exists, or the identity tables or the owner principal are not as reviewed; nothing is changed."),
  "EXEC(N'CREATE SCHEMA wildlife AUTHORIZATION dbo');", "GO", tablesSql.replace(/\s+$/, ""), "GO",
  ...procedures.flatMap((b) => [b, "GO"])], [
  "SET NOCOUNT ON;", ...seed, "GO",
  "SET NOCOUNT ON;", "DECLARE @digests TABLE(object_name nvarchar(200),digest varchar(80));",
  ...procedures.map((b, i) => normalizedDigest(procName(b), `p${i}`)),
  `DECLARE @want TABLE(object_name nvarchar(200),digest varchar(80)); INSERT @want VALUES${procedures.map((b) => `(N'${procName(b)}','${verifyDigest(b)}')`).join(",")};`,
  "DECLARE @tables int=(SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(N'wildlife')),@procs int=(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'wildlife')),",
  " @mismatch int=(SELECT COUNT(*) FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name WHERE d.digest IS NULL OR d.digest<>w.digest);",
  `DECLARE @counts nvarchar(400)=(SELECT ${Object.keys(counts).map((t) => `(SELECT COUNT(*) FROM wildlife.${t}) AS [${t}]`).join(",")} FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);`,
  `SELECT N'verify' AS result_set,@tables AS tables,@procs AS procedures,@mismatch AS digest_mismatches,@counts AS seed_counts,${lit(JSON.stringify(counts))} AS seed_expected;`,
  "SELECT N'verify' AS result_set,w.object_name,w.digest AS reviewed,d.digest AS installed,CASE WHEN d.digest=w.digest THEN 1 ELSE 0 END AS digest_matches FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name ORDER BY w.object_name;",
  "DECLARE @smoke TABLE(o int IDENTITY(1,1),item nvarchar(200),actual nvarchar(400),expected nvarchar(400),passed bit);",
  "DECLARE @r nvarchar(max);", "DECLARE @t TABLE(v nvarchar(max));",
  ...smoke.flatMap(([item, op, req, user, ...expects]) => [`EXEC wildlife.invoke_operation @operation=N'${op}',@request=N'${req}',@user_id=N'${user}',@result=@r OUTPUT;`,
    ...expects.map(([p, eq]) => `INSERT @smoke(item,actual,expected,passed) VALUES(N'${item}: ${p}',JSON_VALUE(@r,N'${p}'),N'${eq}',CASE WHEN JSON_VALUE(@r,N'${p}')=N'${eq}' THEN 1 ELSE 0 END);`)]),
  `INSERT @t EXEC wildlife.serve @operation=N'nerdery-browse-animal-collection',@input=N'{"request":{"search":""}}';`,
  "SELECT @r=v FROM @t; DELETE @t;",
  "INSERT @smoke(item,actual,expected,passed) VALUES(N'anonymous call: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'AUTHENTICATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'AUTHENTICATION_REQUIRED' THEN 1 ELSE 0 END);",
  `DECLARE @forged nvarchar(max)=N'{"caller":{"principalId":"${OWNER}","sessionId":"'+CONVERT(nvarchar(36),NEWID())+N'"},"request":{"search":""}}';`,
  "INSERT @t EXEC wildlife.serve @operation=N'nerdery-browse-animal-collection',@input=@forged;", "SELECT @r=v FROM @t; DELETE @t;",
  "INSERT @smoke(item,actual,expected,passed) VALUES(N'owner principal with an unknown session: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'AUTHENTICATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'AUTHENTICATION_REQUIRED' THEN 1 ELSE 0 END);",
  "SELECT N'smoke' AS result_set,item,actual,expected,passed FROM @smoke ORDER BY o;",
  `IF @tables<>${tableNames.length} OR @procs<>${procedures.length} OR @mismatch<>0 OR @counts<>${lit(JSON.stringify(counts))} OR EXISTS(SELECT 1 FROM @smoke WHERE passed=0)`,
  ...stop("NRD01_VERIFY_FAILED", "the store is not exactly the reviewed one, or a smoke call did not answer as tested; nothing is kept.")]);

// ---------- nrd-02: the finalized features retained by digest, and the promise ----------
const features = slice.capabilities.map((c) => ({ ...c, text: read(path.join(here, "features", `${c.capabilityId}.feature`)), dslText: read(path.join(here, "dsl", `${c.capabilityId}.dsl`)) }));
for (const f of features) { if (`sha256:${sha(f.text)}` !== f.feature || `sha256:${sha(f.dslText)}` !== f.dsl) throw new Error(`${f.capabilityId}: the files differ from slice.manifest.json; run make-slice.mjs`); }
const promise = { contractId: "flight-promise.v1", promiseId: PROMISE, workClass: WORK_CLASS,
  statement: "OV3 declares the eight capabilities of the Nerdery citizen slice feature first: each from its DSL, pinned to the retained bytes of its finalized canonical feature, bound to those bytes and found CONFORMANT in the same change. Each runs as one sql-database-reader statement on the wildlife store, which verifies the caller's session.",
  obligations: features.map((f, i) => ({ obligationId: `O${i + 1}`, statement: `${f.capabilityId} is declared from nerdery/dsl/${f.capabilityId}.dsl, pinned to its canonical feature ${f.feature}, bound to those bytes and found CONFORMANT.`,
    evidence: `apply-declared-change COMMITTED; read-declared-capability-document $.document.feature.digest ${f.feature}` })) };
const promiseText = JSON.stringify(promise);
const retained = [...features.map((f) => [`capability-feature:${f.capabilityId}`, f.text, f.capabilityId]), [`flight-promise:${PROMISE}`, promiseText, "the promise"]];
emitPair("nrd-02-slice-features-and-promise", [
  "-- WHAT THIS ADDS, through the installed writer model.mint_content_artifact (re-running is harmless): the bytes of the eight",
  "-- finalized canonical features of the Nerdery citizen slice (nerdery/features), which their DSL sources pin and the",
  `-- compiler reads by digest, and the promise flight-promise:${PROMISE}.`,
  "-- RUN Part 3 OF THE DSL WORK FIRST (dsl-07 and the check's build flight): the declarations need the feature pin and the check.",
  "-- WHERE: the estate database; run the whole file in one session.",
  `-- BASE: model.mint_content_artifact ${MINT_BASE}. RESULT SETS: base; minted (${retained.length} rows); readback (retained 1 each).`,
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  "DECLARE @installed varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'model.mint_content_artifact')) COLLATE Latin1_General_100_BIN2_UTF8)),2));",
  `SELECT N'base' AS result_set,@installed AS installed_digest,'${MINT_BASE}' AS expected_base;`,
  `IF @installed IS NULL OR @installed<>'${MINT_BASE}'`, ...stop("NRD02_BASE_MOVED", "model.mint_content_artifact is not the reviewed definition; nothing is written."), "GO"], [
  "DECLARE @minted TABLE(ordinal int IDENTITY(1,1),value nvarchar(max));",
  ...retained.map(([kind, text]) => `INSERT @minted(value) EXEC model.mint_content_artifact @document=${lit(JSON.stringify({ artifactKind: kind, text }))};`),
  "SELECT N'minted' AS result_set,ordinal,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,JSON_VALUE(value,'$.content_digest') AS content_digest FROM @minted ORDER BY ordinal;",
  "DECLARE @want TABLE(ordinal int PRIMARY KEY,artifact_kind nvarchar(80),digest varchar(80));",
  `INSERT @want VALUES${retained.map(([kind, text], i) => `(${i + 1},N'${kind}','sha256:${sha(text)}')`).join(",")};`,
  "SELECT N'readback' AS result_set,w.ordinal,w.artifact_kind,w.digest,CASE WHEN EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=w.artifact_kind COLLATE Latin1_General_100_BIN2 AND a.content_digest=CONVERT(binary(32),SUBSTRING(w.digest,8,64),2)) THEN 1 ELSE 0 END AS retained FROM @want w ORDER BY w.ordinal;",
  "IF EXISTS(SELECT 1 FROM @want w WHERE NOT EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=w.artifact_kind COLLATE Latin1_General_100_BIN2 AND a.content_digest=CONVERT(binary(32),SUBSTRING(w.digest,8,64),2)))",
  ...stop("NRD02_VERIFY_FAILED", "a retained text is not under the digest of its reviewed bytes; nothing is kept.")]);

// ---------- nrd-03: the declaration plan ----------
const route = { resolvedDisposition: "terminated" };
const pre = (kind) => ({ input: { changeKind: kind, includeDefinitions: true }, expected: { disposition: "terminated" } });
const steps = [{ stepId: "plan-header", contractId: "estate-flight-plan.v1", promiseId: PROMISE, flightType: "execution", workClass: WORK_CLASS, unknowns: [] }];
features.forEach((f, i) => {
  const short = f.capabilityId.replace(/^nerdery-/, "");
  steps.push({ stepId: `declare-${short}`, capabilityId: "apply-declared-change",
    historicalBasis: `ledger 8704fa02-098a-4109-9c6c-bdbabbdc1cdc (2026-11-02T05:22:29.712): capture-estate-live-observation declared by capability-from-dsl (scaffold CREATE); this DSL compiles COMPILED against the retained bytes of its feature with the revised compiler (nerdery/compile-cases.json), and its operation's mechanics met every case of that feature read-only`,
    input: { contractId: "declared-change.v1", changeKind: "capability-from-dsl", payload: { contractId: "capability-from-dsl-change.v1", source: f.dslText, isMcpTooling: false,
      verificationCapabilityId: "read-harness-authoring-state", preflight: pre("capability-from-dsl"), route } },
    obligationIds: [`O${i + 1}`], expect: { path: "$.disposition", equals: "COMMITTED" } });
  steps.push({ stepId: `prove-${short}`, capabilityId: "read-declared-capability-document",
    historicalBasis: "read-declared-capability-document returns the stored compiled document (run 6d338754), and the declaration keeps its feature pin",
    input: { capabilityId: f.capabilityId }, obligationIds: [`O${i + 1}`], expect: { path: "$.document.feature.digest", equals: f.feature } });
});
const objective = "Declare the eight capabilities of the Nerdery citizen slice feature first, through OV3's own changes: for each, declare it from its DSL with capability-from-dsl, which binds the retained bytes of its finalized canonical feature and commits only when the check finds the binding CONFORMANT, and prove the declaration keeps that feature pin.";
const stepsJson = JSON.stringify(steps);
const planDigest = `sha256:${sha(`${objective}\u0000${stepsJson}`)}`;
files["flights/slice-declare.steps.json"] = JSON.stringify({ agentId: AGENT, promise, objective, planDigest, steps }, null, 2) + "\n";
emitPair("nrd-03-slice-declare-plan", [
  `-- WHAT THIS ADDS: the plan of flight ${PROMISE} (work class ${WORK_CLASS}) under planner agent ${AGENT}, through the`,
  "-- installed writer evidence.upsert_flight_plan. It approves nothing and flies nothing. Re-running is harmless.",
  `-- OV3 flies 16 steps: for each of the eight capabilities it declares the DSL (capability-from-dsl) and reads the declared`,
  `-- feature pin back. The plan is nerdery/flights/slice-declare.steps.json; its digest is ${planDigest}.`,
  "-- RUN nrd-02 FIRST, and Part 3 of the DSL work (the check must be installed).",
  "-- WHERE: the sfx-identity database. GUARD: the writer has its four parameters and the owner principal is active.",
  "-- RESULT SETS: guard; plans (plan_revision, matches_reviewed_file 1).",
  "SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;",
  "DECLARE @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));",
  `DECLARE @active int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id='${OWNER}' AND active=1);`,
  "SELECT N'guard' AS result_set,@params AS writer_parameters,4 AS expected_parameters,@active AS owner_principal_active;",
  "IF @params<>4 OR @active<>1", ...stop("NRD03_PLAN_GUARD", "the plan writer or the owner principal is not as reviewed; nothing was recorded."), "GO"], [
  `DECLARE @p uniqueidentifier='${OWNER}';`, "DECLARE @r TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));",
  `INSERT @r EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=${lit(AGENT)},@objective=${lit(objective)},`, ` @steps_json=${lit(stepsJson)};`,
  `SELECT N'plans' AS result_set,${lit(AGENT)} AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'0x${planDigest.slice(7)}',1) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @r;`]);

// ---------- write and verify ----------
for (const [rel, text] of Object.entries(files)) {
  if (/[^\x09\x0a\x20-\x7e]/.test(text)) throw new Error(`${rel}: non-ASCII`);
  fs.mkdirSync(path.dirname(path.join(here, rel)), { recursive: true });
  fs.writeFileSync(path.join(here, rel), text);
}
const unlit = (l) => l.slice(2, -1).split("''").join("'");
for (const suffix of ["", ".commit"]) {
  const t3 = files[`sql/nrd-03-slice-declare-plan${suffix}.sql`];
  const m = t3.match(/@steps_json=(N'(?:[^']|'')*');/);
  if (!m || unlit(m[1]) !== stepsJson) throw new Error("nrd-03: steps literal round trip");
  const t2 = files[`sql/nrd-02-slice-features-and-promise${suffix}.sql`];
  const docs = [...t2.matchAll(/@document=(N'(?:[^']|'')*');/g)].map((x) => JSON.parse(unlit(x[1])));
  if (docs.length !== retained.length || docs.some((d, i) => d.text !== retained[i][1])) throw new Error("nrd-02: literal round trip");
  const t1 = files[`sql/nrd-01-wildlife-store${suffix}.sql`];
  for (const b of procedures) if (!t1.includes(`\nGO\n${b}\nGO\n`)) throw new Error(`nrd-01: ${procName(b)} body`);
}
const manifest = { pack: "dsl-capabilities-for-ov3-workflow-spec/nerdery", part: "the Nerdery citizen slice through SideFX", generated: "2026-11-02",
  store: { database: "sfx-identity", schema: "wildlife", tables: tableNames, procedures: procedures.map((b) => ({ name: procName(b), verifyDigest: verifyDigest(b) })), seedCounts: counts, ownerPrincipalMappedTo: "user-a" },
  slice: slice.capabilities, flight: { plannerAgentId: AGENT, promiseId: PROMISE, workClass: WORK_CLASS, promiseDigest: `sha256:${sha(promiseText)}`, planDigest, steps: steps.length - 1, stepsJsonCharacters: stepsJson.length },
  twinParity: pairs, files: Object.keys(files).map((f) => ({ file: f, bytes: Buffer.byteLength(files[f]), sha256: `sha256:${sha(files[f])}` })) };
fs.writeFileSync(path.join(here, "manifest.json"), JSON.stringify(manifest, null, 1) + "\n");
console.log(JSON.stringify({ store: { tables: tableNames.length, procedures: procedures.length, seed: counts }, flight: manifest.flight, twinParity: pairs, files: manifest.files.map((f) => `${f.file} ${f.bytes}`) }, null, 1));
