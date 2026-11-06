import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const [basePath, candidatePath] = process.argv.slice(2);
const hash = b => createHash('sha256').update(b).digest('hex');
const base = readFileSync(basePath);
if (hash(base)!=='a310f57f6c85e5fc0a6b23fe4481d691ed971f46d32757a3defd006ad66b414b') throw Error('Objective loop base digest changed. Read and review the installed definition.');
const eol=base.includes(Buffer.from('\r\n'))?'\r\n':'\n';
let src=base.toString('utf8').replaceAll('\r\n','\n');
function replace(before,after) {
  if(src.split(before).length!==2) throw Error('Expected exactly one insertion point: '+before);
  src=src.replace(before,()=>after);
}
const fragment=p=>readFileSync(new URL(p,import.meta.url),'utf8').replaceAll('\r\n','\n').trimEnd();
replace('CREATE   PROCEDURE analysis.objective_agent_step','CREATE OR ALTER PROCEDURE analysis.objective_agent_step');
replace("(N'route'),(N'memsel');","(N'route'),(N'memsel'),(N'verification');");
const answer="SET @dpend=(SELECT @dturn turn,N'ANSWER' action,@dreason reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);";
replace(answer,answer+'\n'+fragment('wrapper-dispatch.sql'));
const observe="  IF JSON_VALUE(@opend,'$.action')=N'CALL' AND JSON_VALUE(@opend,'$.blocked') IS NULL";
replace(observe,fragment('wrapper-observe.sql')+'\n'+observe);
const actual="IF @ort IN (4,5) SET @opend=JSON_MODIFY(@opend,'$.result',JSON_QUERY(@ores));";
const held="IF @ort=5 AND LEFT(JSON_VALUE(@ores,'$.contentDigest'),7)='sha256:'\n    SET @opend=JSON_MODIFY(@opend,'$.objectiveBinding',JSON_QUERY((SELECT @conv AS conversationId,'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),analysis.fv_session_text(@pk+N'obj'))),2)) AS objectiveHash FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)));";
replace(actual,held+'\n   '+actual);
const original="analysis.fv_session_text(@pk+N'obj') objective,analysis.fv_session_text(@pk+N'disp') disposition,analysis.fv_session_text(@pk+N'reply') reply,";
replace(original,original+"\n   JSON_VALUE(analysis.fv_session_text(@pk+N'verification'),'$.status') AS objectiveFulfillment,JSON_QUERY(analysis.fv_session_text(@pk+N'verification')) AS verification,");
const clearance="WHEN @lcap=N'fly-flight-plan' AND @lstatus=N'COMPLETE' THEN N'FULFILLED' ELSE N'UNVERIFIED' END objectiveFulfillment,";
replace(clearance,"WHEN JSON_VALUE(analysis.fv_session_text(@pk+N'verification'),'$.status')=N'FULFILLED' AND COALESCE(JSON_VALUE(@input,'$.result.disposition'),JSON_VALUE(@input,'$.disposition'))=N'COMMITTED' THEN N'FULFILLED'\n   "+clearance+"\n  JSON_QUERY(analysis.fv_session_text(@pk+N'verification')) AS verification,");
writeFileSync(candidatePath,src.replaceAll('\n',eol));
