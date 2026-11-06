import { readFileSync, writeFileSync } from 'node:fs';
import { read, sha } from './portfolio.mjs';

// The selected live definitions are input to the build. The change rechecks both
// pins, the exact old statements, and the entire configuration inside one transaction.
const [baselineFile,output]=process.argv.slice(2);
const rows=JSON.parse(readFileSync(baselineFile,'utf8'));
const specs=[
  ['compose','41ab61d8dae1f0f45e388f06a84aa964ca263403b871129b340527e1b2de1a5f'],
  ['decide','3edddafbfe80d137f0beb260b14f1c60c20570ec38fb8548ff0ab0dc5a6f960c']
];
const n=s=>"N'"+s.replaceAll("'","''")+"'";
const parts=['-- Canonical behavior '+sha(read('compound-objective-routing.feature')),
  "IF @@TRANCOUNT=0 THROW 51000,'ROUTER_TRANSACTION_REQUIRED',1;",
  "DECLARE @namespace nvarchar(400)=N'sidefx:capability:request-capability-from-objective-v3',@port nvarchar(400),@cfg nvarchar(max),@sem nvarchar(max),@actual nvarchar(max),@expected nvarchar(max),@platform nvarchar(400);",
  "DECLARE @selected TABLE(digest binary(32), bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);"];
const fetch=`DELETE @selected;
INSERT @selected SELECT TOP(1) d.definition_digest,co.content_bytes
 FROM model.port p JOIN model.identity_namespace ns ON ns.namespace_pk=p.namespace_pk
 JOIN model.semantic_object_definition d ON d.semantic_object_pk=p.semantic_object_pk
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk
 AND ed.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE ns.namespace_id=@namespace AND p.port_id=@port AND co.content_digest=d.definition_digest
 ORDER BY d.semantic_object_definition_pk DESC;
SET @sem=(SELECT JSON_QUERY(CONVERT(nvarchar(max),bytes),'$.semantics') FROM @selected WHERE HASHBYTES('SHA2_256',CONVERT(varbinary(max),bytes))=digest);
IF @sem IS NULL THROW 51000,'ROUTER_NO_HASHED_AUTHORITY',1;`;
for(const [role,digest] of specs){
  const id='request-capability-from-objective-v3-intent-'+role;
  const row=rows.find(r=>r.name===id);
  if(row?.digest!==digest)throw Error('Unrecognized selected port '+id);
  const old=row.config.statement;
  const anchor=role==='compose'?'DECLARE @context nvarchar(max)=@input;':
    old.slice(old.indexOf('IF @routed=0 AND @short IS NOT NULL'),old.indexOf('-- The memory gate'));
  if(!anchor||old.split(anchor).length!==2)throw Error('Nonunique anchor in '+id);
  const replacement=role==='compose'?anchor+'\n'+read('coverage-candidates.sql'):read('coverage-decision.sql')+'\n';
  const target=old.replace(anchor,()=>replacement);
  const textDigest=s=>sha(Buffer.from(s,'utf16le')).slice(7);
  parts.push('SET @port='+n(id)+';',fetch,
    "IF NOT EXISTS(SELECT 1 FROM @selected WHERE digest=0x"+digest+") THROW 51000,'ROUTER_AUTHORITY_CHANGED',1;",
    "SET @cfg=JSON_QUERY(@sem,'$.configuration'); SET @platform=JSON_VALUE(@sem,'$.platformCapabilityId');",
    "SET @actual=(SELECT value FROM OPENJSON(@cfg) WHERE [key]='statement');",
    "IF @actual IS NULL OR HASHBYTES('SHA2_256',@actual)<>0x"+textDigest(old)+" THROW 51000,'ROUTER_SOURCE_CHANGED',1;",
    'SET @actual=REPLACE(@actual COLLATE Latin1_General_100_BIN2,'+n(anchor)+','+n(replacement)+');',
    "IF HASHBYTES('SHA2_256',@actual)<>0x"+textDigest(target)+" THROW 51000,'ROUTER_PATCH_MISMATCH',1;",
    "SET @expected=JSON_MODIFY(@cfg,'$.statement',@actual);",
    'EXEC model.replace_port_configuration @namespace=@namespace,@port=@port,@configuration_json=@expected;',fetch,
    "SET @cfg=JSON_QUERY(@sem,'$.configuration');",
    "IF @cfg IS NULL OR @platform IS NULL OR ISNULL(JSON_VALUE(@sem,'$.platformCapabilityId'),'')<>@platform OR CONVERT(varbinary(max),@cfg)<>CONVERT(varbinary(max),@expected) THROW 51000,'ROUTER_READBACK_MISMATCH',1;");
}
parts.push("SELECT 'compound_objective_routing' result_set,'VERIFIED' outcome;");
writeFileSync(output,parts.join('\n')+'\n');
