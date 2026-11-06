// Compiles every batch of a generated SQL file read-only through sql-database-reader, without running any of it. A batch
// that creates a procedure is created as a session temp procedure (a permanent name becomes #parse_<n>, WITH EXECUTE AS
// OWNER dropped), which compiles its body against the live schema; every other batch runs as EXEC(N'SET NOEXEC ON; ...'),
// which parses it and compiles each statement whose objects exist, and executes nothing. A statement on a temp table the
// file creates is compiled only when it runs, so it is not checked here.
//
// usage: node parse-sql.mjs <dataSource> <outBase> <file.sql>
//   dataSource  sfx-estate-database or sfx-identity-database
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
const [dataSource, outBase, file] = process.argv.slice(2);
const text = fs.readFileSync(file, "utf8").replace(/\r\n/g, "\n");
const batches = text.split(/^GO\n/m).filter((b) => b.trim().length).map((b, i) => {
  const m = b.match(/^CREATE\s+(?:OR\s+ALTER\s+)?PROCEDURE\s+(\S+)\n/);
  if (!m) return { kind: "batch", text: b, head: b.split("\n").find((l) => l.trim() && !l.startsWith("--")) || "" };
  const name = m[1].startsWith("#") ? m[1] : `#parse_${i}`;
  const body = b.slice(m[0].length).replace(/^((?:(?!\nAS\n)[\s\S])*?)\nWITH EXECUTE AS OWNER\nAS\n/, "$1\nAS\n");
  return { kind: "proc", text: `CREATE PROCEDURE ${name}\n${body}`, head: `CREATE PROCEDURE ${m[1]} (as ${name})` };
});
const statement = `SET NOCOUNT ON;
DECLARE @b TABLE(k int PRIMARY KEY,kind nvarchar(10),txt nvarchar(max));
INSERT @b SELECT CONVERT(int,j.[key]),x.kind,x.txt FROM OPENJSON(@input,N'$.batches') j CROSS APPLY OPENJSON(j.[value]) WITH (kind nvarchar(10) N'$.kind',txt nvarchar(max) N'$.text') x;
DECLARE @out TABLE(k int PRIMARY KEY,status nvarchar(10),msg nvarchar(4000),line int);
DECLARE @i int=0,@n int=(SELECT COUNT(*) FROM @b),@kind nvarchar(10),@txt nvarchar(max),@sql nvarchar(max);
WHILE @i<@n
BEGIN
  SELECT @kind=kind,@txt=txt FROM @b WHERE k=@i;
  BEGIN TRY
    IF @kind=N'proc' EXEC(@txt);
    ELSE BEGIN SET @sql=N'SET NOEXEC ON; '+@txt; EXEC(@sql); END
    INSERT @out VALUES(@i,N'OK',NULL,NULL);
  END TRY
  BEGIN CATCH
    INSERT @out VALUES(@i,N'ERROR',ERROR_MESSAGE(),ERROR_LINE());
  END CATCH
  SET @i+=1;
END
SELECT (SELECT k,status,msg,line,@@TRANCOUNT AS trancount FROM @out ORDER BY k FOR JSON PATH) AS value;`;
const sfx = process.env.SFX_SH || path.join(path.dirname(outBase), "..", "sfx.sh");
fs.writeFileSync(outBase + ".request.json", JSON.stringify({ dataSource, statement, resultColumn: "value", input: { batches: batches.map(({ kind, text }) => ({ kind, text })) } }));
if (fs.existsSync(outBase + ".json")) fs.unlinkSync(outBase + ".json");
let log = "";
try { log = execFileSync("bash", [sfx, "sql-database-reader", outBase + ".request.json", outBase], { encoding: "utf8" }); } catch (e) { log = String(e.stdout || e.message); }
process.stdout.write(log);
const raw = fs.existsSync(outBase + ".json") ? fs.readFileSync(outBase + ".json", "utf8").trim() : "";
if (!raw) { console.log("no result; see", outBase + ".err"); process.exit(2); }
const out = JSON.parse(raw).value;
let bad = 0;
for (const r of out) {
  const b = batches[r.k];
  if (r.status !== "OK") bad++;
  console.log(`${r.status === "OK" ? "ok  " : "FAIL"} batch ${r.k} ${b.kind} ${b.head.slice(0, 90)}${r.status === "OK" ? "" : `\n       line ${r.line}: ${r.msg}`}`);
}
console.log(`${out.length - bad}/${batches.length} batches compiled (${path.basename(file)})`);
process.exit(bad || out.length !== batches.length ? 1 : 0);
