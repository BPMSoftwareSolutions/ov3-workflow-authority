// Runs check-capability-feature-conformance cases read-only through sql-database-reader. The body is created as a
// session temp procedure (#check) and called once per request; batches run one after another, never in parallel.
//
// usage: node run-check.mjs <cases.json | file.feature> <outBase> <gherkin node_modules dir>
//   cases.json    [{name, request, expect: [[path, equals], ...], oracle?}]
//   file.feature  every case not tagged @status:not-built: @case or the Examples case column, the json docstring as
//                 the request, and the operation | path | equals rows as the expectations
// Request members written {"$textOf": path} or {"$jsonOf": path} are read from this folder; with "$sha256" the file
// must hash to it.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const [input, outBase, modules] = process.argv.slice(2);
const require = createRequire(import.meta.url);
const gherkin = require(modules + "/@cucumber/gherkin");
const { IdGenerator } = require(modules + "/@cucumber/messages");
const compile = (text) => {
  const id = IdGenerator.incrementing();
  const doc = new gherkin.Parser(new gherkin.AstBuilder(id), new gherkin.GherkinClassicTokenMatcher()).parse(text);
  return { doc, pickles: gherkin.compile(doc, "feature", id) };
};
const sha = (b) => crypto.createHash("sha256").update(b).digest("hex");
const resolve = (v) => {
  if (Array.isArray(v)) return v.map(resolve);
  if (v && typeof v === "object") {
    const ref = v.$textOf || v.$jsonOf;
    if (ref) {
      const bytes = fs.readFileSync(path.join(root, ref));
      if (v.$sha256 && sha(bytes) !== v.$sha256) throw new Error(`${ref}: sha256 ${sha(bytes)} is not the pinned ${v.$sha256}`);
      return v.$textOf ? bytes.toString("utf8") : resolve(JSON.parse(bytes.toString("utf8")));
    }
    return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, resolve(x)]));
  }
  return v;
};

const casesFromFeature = (file) => {
  const { doc, pickles } = compile(fs.readFileSync(file, "utf8"));
  const rows = new Map();
  const walk = (children) => {
    for (const c of children) {
      if (c.rule) walk(c.rule.children);
      for (const ex of (c.scenario && c.scenario.examples) || []) {
        const header = ex.tableHeader.cells.map((x) => x.value);
        for (const r of ex.tableBody) rows.set(r.id, Object.fromEntries(header.map((h, k) => [h, r.cells[k].value])));
      }
    }
  };
  walk(doc.feature.children);
  return pickles.filter((p) => !p.tags.some((t) => t.name === "@status:not-built")).map((p) => {
    const tag = p.tags.find((t) => t.name.startsWith("@case:"));
    const row = p.astNodeIds.length > 1 ? rows.get(p.astNodeIds[1]) : null;
    const name = tag ? tag.name.slice(6) : row && row.case;
    const doc = p.steps.map((s) => s.argument && s.argument.docString).find((d) => d && d.mediaType === "json");
    const table = p.steps.map((s) => s.argument && s.argument.dataTable).find((t) => t && t.rows[0].cells.map((c) => c.value).join("|") === "operation|path|equals");
    return { name, request: JSON.parse(doc.content), expect: table.rows.slice(1).map((r) => [r.cells[1].value, r.cells[2].value]) };
  });
};

const body = fs.readFileSync(path.join(here, "check_capability_feature_conformance.body.sql"), "utf8");
const proc = "CREATE PROCEDURE #check @input nvarchar(max), @estate_model_pk bigint = NULL, @result nvarchar(max) = NULL OUTPUT, @emit bit = 1 AS\n" + body;
const statement = `SET NOCOUNT ON;
IF OBJECT_ID(N'tempdb..#check') IS NOT NULL DROP PROCEDURE #check;
EXEC(N'${proc.replace(/'/g, "''")}');
DECLARE @reqs TABLE(k int PRIMARY KEY, req nvarchar(max));
INSERT @reqs SELECT CONVERT(int, [key]), [value] FROM OPENJSON(@input, N'$.requests');
DECLARE @out TABLE(k int PRIMARY KEY, value nvarchar(max));
DECLARE @one TABLE(value nvarchar(max));
DECLARE @i int = 0, @n int = (SELECT COUNT(*) FROM @reqs), @r nvarchar(max);
WHILE @i < @n
BEGIN
  SELECT @r = req FROM @reqs WHERE k = @i;
  DELETE @one;
  INSERT @one(value) EXEC #check @input = @r;
  INSERT @out(k, value) SELECT @i, value FROM @one;
  SET @i += 1;
END
SELECT N'{"results":[' + ISNULL(STRING_AGG(CONVERT(nvarchar(max), value), N',') WITHIN GROUP (ORDER BY k), N'') + N']}' AS value FROM @out;`;

// SFX_SH: a script that runs `sfx-api capability observe <capability> --input - --json --auth user` with the input file
// as stdin and writes <outBase>.json and <outBase>.err (the run id is on stderr).
const sfx = process.env.SFX_SH || path.join(path.dirname(outBase), "..", "sfx.sh");
const runBatch = (requests, base) => {
  fs.writeFileSync(base + ".request.json", JSON.stringify({ dataSource: "sfx-estate-database", statement, resultColumn: "value", input: { requests } }));
  if (fs.existsSync(base + ".json")) fs.unlinkSync(base + ".json");
  let log = "";
  try { log = execFileSync("bash", [sfx, "sql-database-reader", base + ".request.json", base], { encoding: "utf8" }); } catch (e) { log = String(e.stdout || e.message); }
  process.stdout.write(log);
  const raw = fs.existsSync(base + ".json") ? fs.readFileSync(base + ".json", "utf8").trim() : "";
  if (!raw) { console.log("no result; see", base + ".err"); process.exit(2); }
  const out = JSON.parse(raw);
  return (typeof out.value === "string" ? JSON.parse(out.value) : out.value).results;
};

const cases = input.endsWith(".feature") ? casesFromFeature(input) : JSON.parse(fs.readFileSync(input, "utf8"));
const requests = cases.map((c) => resolve(c.request));
const results = [];
for (let i = 0, b = 0; i < requests.length; b++) {
  let size = 0, j = i;
  while (j < requests.length && (j === i || size + JSON.stringify(requests[j]).length < 200000)) size += JSON.stringify(requests[j++]).length;
  results.push(...runBatch(requests.slice(i, j), `${outBase}-${b}`));
  i = j;
}
const at = (o, p) => p.replace(/^\$\.?/, "").split(/\.|\[(\d+)\]/).filter((x) => x !== undefined && x !== "").reduce((a, k) => (a == null ? undefined : a[k]), o);
const show = (x) => x === undefined || x === null ? "(absent)" : typeof x === "object" ? JSON.stringify(x) : String(x);
let failed = 0;
cases.forEach((c, i) => {
  const r = results[i];
  const bad = [];
  for (const [p, eq] of c.expect || []) { const a = at(r, p); if (show(a) !== String(eq)) bad.push(`${p}: ${show(a)} != ${eq}`); }
  if (c.oracle) {
    const mine = r.pickles || [];
    const { pickles } = compile(requests[i].featureText);
    if (pickles.length !== mine.length) bad.push(`oracle: ${pickles.length} pickles, check: ${mine.length}`);
    pickles.forEach((p, k) => {
      const m = mine[k] || {};
      const tags = p.tags.map((t) => t.name).sort((a, b) => (a < b ? -1 : a > b ? 1 : 0)).join(" ");
      if (tags !== m.tags) bad.push(`oracle pickle ${k} tags: ${tags} != ${m.tags}`);
      const steps = m.stepsDetail || [];
      p.steps.forEach((s, j) => {
        const ms = steps[j] || {};
        if (s.type !== ms.type || s.text !== ms.text) bad.push(`oracle pickle ${k} step ${j}: ${s.type} ${s.text} != ${ms.type} ${ms.text}`);
        const d = s.argument && s.argument.docString;
        if (d && (d.content !== ms.docString || (d.mediaType || null) !== (ms.mediaType || null))) bad.push(`oracle pickle ${k} step ${j} docString differs`);
        const t = s.argument && s.argument.dataTable;
        if (t && JSON.stringify(t.rows.map((x) => x.cells.map((y) => y.value))) !== JSON.stringify(ms.dataTable)) bad.push(`oracle pickle ${k} step ${j} dataTable differs`);
      });
    });
  }
  failed += bad.length ? 1 : 0;
  console.log(`${bad.length ? "FAIL" : "ok  "} ${c.name}: ${r.status} ${r.summary ? r.summary.signature : ""}`);
  for (const b of bad) console.log("       " + b);
});
console.log(`${cases.length - failed}/${cases.length} cases met their expectations`);
process.exit(failed ? 1 : 0);
