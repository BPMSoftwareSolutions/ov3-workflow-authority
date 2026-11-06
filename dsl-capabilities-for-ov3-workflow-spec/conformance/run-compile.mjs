// Compiles DSL sources read-only through sql-database-reader with the revised compiler, created as a session temp procedure
// (#compile) beside the revised no-drift check (#check). Feature bytes a case retains are placed in a session table that
// the compiler's retained-feature lookup reads with source.content_object; nothing is written to the estate.
// One compile per call: a compile takes about 22 s and the reader allows about 30.
//
// usage: node run-compile.mjs <cases.json | file.feature> <outBase> [gherkin node_modules dir, for a feature]
//   cases.json    [{name, source: <path>, retain: [<path>...], expect: [[path, equals], ...]}]   paths relative to this folder's parent
//   file.feature  every case not tagged @status:not-built: its request {"source": {"$textOf": <path>, "$sha256": <hex>}}, the
//                 files a step says "the bytes of <path> are retained under sha256:<hex>", and its operation | path | equals rows
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const [casesFile, outBase, modules] = process.argv.slice(2);
const read = (p) => fs.readFileSync(path.join(root, p), "utf8");
const pinned = (p, hex) => {
  const text = read(p);
  const got = crypto.createHash("sha256").update(Buffer.from(text, "utf8")).digest("hex");
  if (hex && got !== hex) throw new Error(`${p}: sha256 ${got} is not the pinned ${hex}`);
  return p;
};
const casesFromFeature = (file) => {
  const require = createRequire(import.meta.url);
  const g = require(modules + "/@cucumber/gherkin"), { IdGenerator } = require(modules + "/@cucumber/messages");
  const id = IdGenerator.incrementing();
  const doc = new g.Parser(new g.AstBuilder(id), new g.GherkinClassicTokenMatcher()).parse(fs.readFileSync(file, "utf8"));
  return g.compile(doc, "feature", id).filter((p) => !p.tags.some((t) => t.name === "@status:not-built")).map((p) => {
    const tag = p.tags.find((t) => t.name.startsWith("@case:"));
    const request = JSON.parse(p.steps.map((s) => s.argument && s.argument.docString).find((d) => d && d.mediaType === "json").content);
    const table = p.steps.map((s) => s.argument && s.argument.dataTable).find((t) => t && t.rows[0].cells.map((c) => c.value).join("|") === "operation|path|equals");
    const retain = p.steps.map((s) => s.text.match(/the bytes of (\S+) are retained under sha256:([0-9a-f]{64})/)).filter(Boolean).map((m) => pinned(m[1], m[2]));
    return { name: tag.name.slice(6), source: pinned(request.source.$textOf, request.source.$sha256), retain,
      expect: table.rows.slice(1).map((r) => [r.cells[1].value, r.cells[2].value]) };
  });
};
const swap = (text, a, b) => { const n = text.split(a).length - 1; if (n !== 1) throw new Error(`expected one ${a.slice(0, 60)}, found ${n}`); return text.replace(a, () => b); };

let compiler = read("source/analysis.compile_capability_dsl.v3.sql");
compiler = swap(compiler, "CREATE   PROCEDURE analysis.compile_capability_dsl\n  @input nvarchar(max),@estate_model_pk bigint\nWITH EXECUTE AS OWNER\nAS",
  "CREATE PROCEDURE #compile\n  @input nvarchar(max),@estate_model_pk bigint\nAS");
compiler = swap(compiler, "DECLARE @check_procedure nvarchar(400)=N'analysis.check_capability_feature_conformance';",
  "DECLARE @check_procedure nvarchar(400)=N'#check';");
compiler = swap(compiler, "    FROM source.content_object co\n    WHERE co.content_digest=CONVERT(binary(32),@feature_hex,2)",
  "    FROM (SELECT content_digest,content_bytes FROM source.content_object UNION ALL SELECT content_digest,content_bytes FROM #retained) co\n    WHERE co.content_digest=CONVERT(binary(32),@feature_hex,2)");
const check = "CREATE PROCEDURE #check @input nvarchar(max), @estate_model_pk bigint = NULL, @result nvarchar(max) = NULL OUTPUT, @emit bit = 1 AS\n"
  + read("conformance/check_capability_feature_conformance.body.sql");
const q = (s) => s.replace(/'/g, "''");
const statement = `SET NOCOUNT ON;
IF OBJECT_ID(N'tempdb..#compile') IS NOT NULL DROP PROCEDURE #compile;
IF OBJECT_ID(N'tempdb..#check') IS NOT NULL DROP PROCEDURE #check;
IF OBJECT_ID(N'tempdb..#retained') IS NOT NULL DROP TABLE #retained;
CREATE TABLE #retained(content_digest binary(32) NOT NULL, content_bytes varbinary(max) NOT NULL);
INSERT #retained(content_digest, content_bytes)
SELECT HASHBYTES('SHA2_256', x.b), x.b FROM OPENJSON(@input, N'$.retain') j
CROSS APPLY (SELECT CONVERT(varbinary(max), CONVERT(varchar(max), j.value COLLATE Latin1_General_100_BIN2_UTF8)) AS b) x;
EXEC(N'${q(check)}');
EXEC(N'${q(compiler)}');
DECLARE @req nvarchar(max) = JSON_QUERY(@input, N'$.compile');
DECLARE @out TABLE(value nvarchar(max));
INSERT @out(value) EXEC #compile @input = @req, @estate_model_pk = NULL;
SELECT TOP (1) value FROM @out;`;

const at = (o, p) => p.replace(/^\$\.?/, "").split(/\.|\[(\d+)\]/).filter((x) => x !== undefined && x !== "").reduce((a, k) => (a == null ? undefined : a[k]), o);
const show = (x) => x === undefined || x === null ? "(absent)" : typeof x === "object" ? JSON.stringify(x) : String(x);
const sfx = process.env.SFX_SH || path.join(path.dirname(outBase), "..", "sfx.sh");
const cases = casesFile.endsWith(".feature") ? casesFromFeature(casesFile) : JSON.parse(fs.readFileSync(casesFile, "utf8"));
let failed = 0;
cases.forEach((c, k) => {
  const base = `${outBase}-${k}`;
  const input = { compile: { source: read(c.source) }, retain: (c.retain || []).map(read) };
  fs.writeFileSync(base + ".request.json", JSON.stringify({ dataSource: "sfx-estate-database", statement, resultColumn: "value", input }));
  if (fs.existsSync(base + ".json")) fs.unlinkSync(base + ".json");
  const t0 = Date.now();
  let log = "";
  try { log = execFileSync("bash", [sfx, "sql-database-reader", base + ".request.json", base], { encoding: "utf8" }); } catch (e) { log = String(e.stdout || e.message); }
  const raw = fs.existsSync(base + ".json") ? fs.readFileSync(base + ".json", "utf8").trim() : "";
  const run = (log.match(/Run ([0-9a-f-]+)/) || [])[1] || "?";
  if (!raw) { failed++; console.log(`FAIL ${c.name}: no result (run ${run}, ${Math.round((Date.now() - t0) / 1000)} s)`); return; }
  const out = JSON.parse(raw);
  const r = typeof out.value === "string" ? JSON.parse(out.value) : out.value;
  fs.writeFileSync(base + ".result.json", JSON.stringify(r, null, 1));
  const bad = [];
  for (const [p, eq] of c.expect || []) { const a = at(r, p); if (show(a) !== String(eq)) bad.push(`${p}: ${show(a)} != ${eq}`); }
  failed += bad.length ? 1 : 0;
  console.log(`${bad.length ? "FAIL" : "ok  "} ${c.name}: ${r.status} (run ${run}, ${Math.round((Date.now() - t0) / 1000)} s) ${(r.diagnostics || []).slice(0, 3).map((d) => d.code + "@" + d.line + " " + d.message).join(" | ")}`);
  for (const b of bad) console.log("       " + b);
});
console.log(`${cases.length - failed}/${cases.length} compile cases met their expectations`);
process.exit(failed ? 1 : 0);
