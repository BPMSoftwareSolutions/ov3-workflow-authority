import { writeFileSync } from 'node:fs';
import { artifact, change } from './build-flight.mjs';
import { read } from './portfolio.mjs';
const id='verify-objective-fulfillment';
const literal=s=>"N'"+s.replaceAll("'","''")+"'";
const document=v=>literal(JSON.stringify(v).replace(/[^\x00-\x7f]/g,c=>'\\u'+c.charCodeAt(0).toString(16).padStart(4,'0')));
const feature=read('../objective-verification/'+id+'.feature');
const requests=[artifact('capability-feature:'+id,feature),
  change('capability-from-dsl',{source:read('../objective-verification/'+id+'.dsl'),isMcpTooling:true})];
const lines=["IF @@TRANCOUNT=0 THROW 51000,'REHEARSAL_REQUIRES_TRANSACTION',1;",
  'SAVE TRANSACTION proof_closure; DECLARE @req nvarchar(max),@compose nvarchar(max),@sql nvarchar(max),@envelope nvarchar(max),@body nvarchar(max);',
  'DECLARE @rows TABLE(v nvarchar(max)); DECLARE @stored TABLE(raw varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);'];
for(const request of requests)lines.push('SET @req='+document(request)+'; EXEC model.apply_declared_change @input=@req;');
lines.push(`INSERT @stored SELECT TOP(1) co.content_bytes FROM model.port p
 JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
 JOIN model.semantic_object_definition d ON d.semantic_object_pk=p.semantic_object_pk
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk AND ed.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE n.namespace_id=N'sidefx:capability:verify-objective-fulfillment' AND p.port_id=N'verify-objective-fulfillment-evidence-compose'
 AND co.content_digest=HASHBYTES('SHA2_256',co.content_bytes) ORDER BY d.semantic_object_definition_pk DESC;
 SELECT @compose=j.value FROM @stored CROSS APPLY OPENJSON(CONVERT(nvarchar(max),raw),'$.semantics.configuration') j WHERE j.[key]='statement';
 IF @compose IS NULL THROW 51000,'PROJECTED_COMPOSER_MISSING',1;`);
const cases=[['notice','7c1f0f8c-952c-4d77-9fa4-6e05effbb6ac',6,5],['ledger','f8900169-3abc-4501-87f8-aad6a8e43b74',4,3],
  ['historical','be0a0a31-50fc-460c-ac66-fb24a999bbc2',1,297],['mismatched-artifact','4ca89bb0-c7ed-4e95-bd19-603abb357b19',3,0]];
for(const [name,conversationId,publicationTurn,expected] of cases){
  const input={conversationId,publicationTurn,...(name==='historical'||!expected?{expectedArtifactDigest:'sha256:94a77a826d7822419a8fe8c2d00275048a541c1a1d6aff4f753835abcad0c966',expectedSourceVersion:'3.15.2'}:{})};
  lines.push('SET @req='+document(input)+';',
    "DELETE @rows;INSERT @rows EXEC sys.sp_executesql @compose,N'@input nvarchar(max)',@input=@req; SET @envelope=(SELECT JSON_QUERY(v,'$.dispatchRequest') FROM @rows);",
    "SET @sql=(SELECT value FROM OPENJSON(@envelope) WHERE [key]='statement'); IF @sql IS NULL THROW 51000,'MISSING_PROJECTED_SQL',1;",
    "SET @req=JSON_QUERY(@envelope,'$.input');DELETE @rows;INSERT @rows EXEC sys.sp_executesql @sql,N'@input nvarchar(max)',@input=@req;SET @body=(SELECT v FROM @rows);",
    'IF ISNULL(JSON_VALUE(@body,\'$.route\'),\'\')<>'+literal(expected?'INFER':'HOLD')+
    (expected?" OR ISNULL(TRY_CONVERT(int,JSON_VALUE(@body,'$.context.metrics."+(name==='historical'?'provedModules':'observedOperations')+"')),-1)<>"+expected:
    " OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.context.checks') WHERE JSON_VALUE(value,'$.code')='EXPECTED_ARTIFACT' AND JSON_VALUE(value,'$.passed')='false')")+
    " THROW 51000,'PROJECTED_PROOF_FAILED_"+name+"',1;",
    'SELECT '+literal(name)+" specimen,JSON_VALUE(@body,'$.route') route,JSON_QUERY(@body,'$.context.metrics') metrics;");
}
lines.push("ROLLBACK TRANSACTION proof_closure;SELECT 'proof_closure' result_set,'PASSED_AND_ROLLED_BACK' disposition;");
const sql=lines.join('\n')+'\n';
if(sql.length>131072)throw Error('Engineering source too large');
writeFileSync(process.argv[2],sql);
