import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { identity,read } from './build.mjs';
import { objectives } from './build-flight.mjs';
const [directory,out]=process.argv.slice(2);
const q=s=>"N'"+s.replaceAll("'","''")+"'";
const json=value=>q(JSON.stringify(value).replace(/[^\x00-\x7f]/g,c=>'\\u'+c.charCodeAt(0).toString(16).padStart(4,'0')));
const expected=JSON.parse(read('acceptance.json'))[1],source=read('harbor-log.md');
const sample=JSON.parse(readFileSync(join(directory,'rehearsal-evidence.json'))).find(r=>r.filename===expected.filename);
const html=readFileSync(join(directory,expected.filename),'utf8');
const request={sourceDigest:expected.sourceDigest,title:expected.title,filename:expected.filename,lang:expected.lang,profile:'technical-report-v1'};
const verifier=JSON.parse(read('../objective-verification/verify-objective-fulfillment.dsl').split('\n').find(l=>l.startsWith('config: ')).slice(8)).statement;
const statements=["IF @@TRANCOUNT=0 THROW 51000,'REHEARSAL_TRANSACTION_REQUIRED',1; SAVE TRANSACTION markdown_page_proof;",
  "DECLARE @input nvarchar(max),@result nvarchar(max),@p nvarchar(max),@wire nvarchar(max),@sha varchar(71),@htmlHash varchar(71),@inputHash varchar(71),@kind nvarchar(200),@s nvarchar(max); DECLARE @rows TABLE(v nvarchar(max));"];
function query(s){
  statements.push('SET @s='+q(s)+";DELETE @rows;INSERT @rows EXEC sys.sp_executesql @s,N'@input nvarchar(max)',@input=@input;SET @result=(SELECT v FROM @rows);");
}
function retain(){
  statements.push("SET @kind=JSON_VALUE(@result,'$.artifactKind'); SELECT @sha='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),value COLLATE Latin1_General_100_BIN2_UTF8)),2)) FROM OPENJSON(@result) WHERE [key]='text';",
    "SET @p=JSON_MODIFY(N'{\"contractId\":\"declared-change.v1\",\"changeKind\":\"content-artifact-change\"}','$.payload',JSON_QUERY(@result)); EXEC model.apply_declared_change @input=@p;",
    "IF NOT EXISTS(SELECT 1 FROM model.content_artifact WHERE artifact_kind=@kind AND content_digest=TRY_CONVERT(binary(32),SUBSTRING(@sha,8,64),2)) BEGIN SET @p=CONCAT('READBACK_MISSING ',COALESCE(@kind,'(null)'),' wanted ',COALESCE(@sha,'(null)'),' newest ',COALESCE((SELECT TOP(1) LOWER(CONVERT(varchar(64),content_digest,2)) FROM model.content_artifact WHERE artifact_kind=@kind ORDER BY content_artifact_pk DESC),'none')); THROW 51000,@p,1; END;",
    "SET @input=(SELECT 'COMMITTED' disposition,JSON_QUERY(N'[[{}]]') result FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);SET @input=JSON_MODIFY(@input,'$.result[0][0].value',(SELECT @kind artifact_kind,@sha content_digest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER));");
}
const prep=phase=>"DECLARE @asset varchar(71)='"+identity.assetDigest+"',@phase varchar(10)='"+phase+"';\n"+read('prepare-provider.sql');
statements.push('SET @input='+json(request)+';');query(read('prepare-input.sql'));retain();
statements.push('SET @inputHash=@sha;');query(prep('render'));
statements.push("IF JSON_VALUE(@result,'$.request.filename')<>"+q(expected.filename)+" OR DATALENGTH((SELECT value FROM OPENJSON(@result) WHERE [key]='bundle'))<2000000 THROW 51000,'PROVIDER_WIRE_MISMATCH',1;",
  'SET @input=JSON_MODIFY('+json({...sample.renderer,html})+",'$.inputDigest',@inputHash);");
query(read('publish-page.sql'));retain();statements.push('SET @htmlHash=@sha;');query(prep('verify'));
statements.push("IF CONVERT(varbinary(max),(SELECT value FROM OPENJSON(@result) WHERE [key]='html'))<>CONVERT(varbinary(max),"+q(html)+") OR JSON_VALUE(@result,'$.receipt.outputDigest')<>@htmlHash THROW 51000,'PUBLICATION_WIRE_MISMATCH',1;",
  'SET @input=JSON_MODIFY('+json({...sample.verification,renderer:sample.renderer.renderer,filename:expected.filename,bundleDigest:identity.bundleDigest,profileDigest:identity.profileDigest})+",'$.inputDigest',@inputHash);");
const finish=JSON.parse(read('render-markdown-html-page.dsl').split('\n').filter(l=>l.startsWith('config: ')).at(-1).slice(8)).statement;
query(finish);
// Seed only a rollback-scoped synthetic publication turn. Production requires a real OV3 turn.
const cid='74ee1646-0c10-493d-818a-ead17dad78f3', objective=objectives()[1].objective;
statements.push('DECLARE @objective nvarchar(max)='+q(objective)+",@record nvarchar(max),@scopeHash varchar(71); SET @scopeHash='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@objective)),2));",
  "SET @record=(SELECT 1 turn,'CALL' action,'terminated' disposition,'render-markdown-html-page' capability,"+json(request)+" inputText,JSON_QUERY(@result) result,JSON_QUERY((SELECT "+q(cid)+" conversationId,@scopeHash objectiveHash FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) objectiveBinding FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);",
  "SET @result=(SELECT 'content-artifact-change.v1' contractId,"+q('objective-pursuit:'+cid+'#1')+" artifactKind,@record [text],'read-harness-authoring-state' verificationCapabilityId,JSON_QUERY(N'{\"resolvedDisposition\":\"terminated\"}') route,JSON_QUERY(N'{\"input\":{\"changeKind\":\"content-artifact-change\",\"includeDefinitions\":true},\"expected\":{\"disposition\":\"terminated\"}}') preflight FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);");
retain();
for(const [label,expectedArtifactDigest,expectedRoute] of [['bound',expected.outputDigest,'INFER'],['swapped','sha256:'+'0'.repeat(64),'HOLD']]){
  statements.push('SET @input='+json({conversationId:cid,publicationTurn:1,objective,expectedArtifactDigest})+';');
  query(verifier);
  statements.push("IF ISNULL(JSON_VALUE(@result,'$.route'),'')<>"+q(expectedRoute)+" BEGIN SELECT @result unexpected; THROW 51000,'PAGE_PROOF_"+label+"_FAILED',1; END;",
    'SELECT '+q(label)+" specimen,JSON_VALUE(@result,'$.route') route,JSON_QUERY(@result,'$.context.checks') checks;");
}
statements.push("ROLLBACK TRANSACTION markdown_page_proof; SELECT 'markdown_page_proof' result_set,'PASSED_AND_ROLLED_BACK' disposition;");
// Share the verifier statement between both examples to stay under the engineering source limit.
const phrase='SET @s='+q(verifier)+';';
const text=statements.join('\n').replace(phrase,'DECLARE @verifier nvarchar(max)='+q(verifier)+'; SET @s=@verifier;').replace(phrase,'SET @s=@verifier;')+'\n';
if(text.length>131072)throw Error('Rehearsal too large');
writeFileSync(out,text);
