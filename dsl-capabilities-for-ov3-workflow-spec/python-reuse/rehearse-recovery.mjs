import { writeFileSync } from 'node:fs';
import { recovery } from './build-recovery-flight.mjs';
import { change } from './build-flight.mjs';
import { read } from './portfolio.mjs';

// Exercise the actual declared model writers in one rollback-only SQL session.
// Runtime inference and API-side recording are exercised separately on the live flight.
const n=text=>"N'"+text.replaceAll("'","''")+"'";
const doc=value=>n(JSON.stringify(value).replace(/[^\x00-\x7f]/g,c=>'\\u'+c.charCodeAt(0).toString(16).padStart(4,'0')));
const slice=process.argv[3];
if(!['supply','publication','base64','binascii','hashlib'].includes(slice))throw Error('Unknown rehearsal slice');
const lines=[
  "IF @@TRANCOUNT=0 THROW 51000,'REHEARSAL_TRANSACTION_REQUIRED',1;",
  'SAVE TRANSACTION python_reuse_rehearsal;',
  'DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);',
  'DECLARE @req nvarchar(max),@output nvarchar(max),@bound nvarchar(max),@payload nvarchar(max);',
  'DECLARE @rows TABLE(value nvarchar(max));',
  'DECLARE @results TABLE(id nvarchar(150) PRIMARY KEY,body nvarchar(max));'
];
for(const step of recovery.steps.slice(1)){
  const cap=step.capabilityId;
  if(cap!=='apply-engineering-change'){
    if(['base64','binascii','hashlib'].includes(slice)){
      if(!step.stepId.startsWith(slice+'-'))continue;
    }else if(step.obligationIds.includes('supply')!==(slice==='supply') &&
      !(slice==='supply'&&step.obligationIds.includes('encoding')))continue;
  }
  if(['read-declared-capability-document','verify-objective-fulfillment'].includes(cap))continue;
  if(cap==='apply-engineering-change'){
    // These leaf features are byte-for-byte ASCII under both decoders. Keep the
    // shared DSL procedure unlocked while rehearsing their placement changes.
    if(['binascii','hashlib'].includes(slice)){
      if(/[^\x00-\x7f]/.test(read('python-'+slice+'.feature')))throw Error('Unicode feature needs decoder rehearsal');
      continue;
    }
    lines.push('EXEC sys.sp_executesql '+n(read('repair-feature-decoding.sql'))+';');
    continue;
  }
  const isRead=cap==='sql-database-reader'||cap==='read-topology-conformance';
  const payload=isRead?(cap==='sql-database-reader'?step.input.input:step.input):
    (cap==='apply-declared-change'?step.input:change(cap,step.input));
  lines.push('SET @req='+doc(payload)+';');
  for(const b of step.bind??[]){
    const path=isRead?b.target.replace(/^input\./,''):'payload.'+b.target;
    lines.push('SET @bound=JSON_VALUE((SELECT body FROM @results WHERE id='+n(b.fromStep)+'),'+n(b.path)+');',
      "IF @bound IS NULL THROW 51000,'REHEARSAL_BINDING_MISSING',1;",
      'SET @req=JSON_MODIFY(@req,'+n('$.'+path)+',@bound);');
  }
  if(isRead){
    const statement=cap==='sql-database-reader'?step.input.statement:'EXEC analysis.read_topology_conformance @input=@input,@estate_model_pk=@estate;';
    lines.push('DELETE @rows;','INSERT @rows EXEC sys.sp_executesql '+n(statement)+",N'@input nvarchar(max),@estate bigint',@input=@req,@estate=@estate;",
      cap==='sql-database-reader'?"SET @output=(SELECT JSON_QUERY(value) AS value FROM @rows FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);":"SET @output=(SELECT value FROM @rows);",
      'IF ISNULL(JSON_VALUE(@output,'+n(step.expect.path)+"),N'(missing)')<>"+n(String(step.expect.equals))+
      ' BEGIN ROLLBACK TRANSACTION python_reuse_rehearsal; SELECT '+n(step.stepId)+" stepId,'EXPECTATION_FAILED' finding,@output observed; RETURN; END;",
      'INSERT @results VALUES('+n(step.stepId)+',@output);');
  }else if(cap.startsWith('model-')){
    // The governed engineering preflight already owns the transaction. Placement
    // installers require depth one. Use the same declared installer the live
    // change envelope dispatches, and leave its placement checks enabled.
    const installers={
      'model-declare-semantic-object':'model.install_model_declare_semantic_object_change',
      'model-declare-platform-capability':'model.install_model_declare_platform_capability_change',
      'model-declare-provider-identity':'model.install_model_declare_provider_identity_change',
      'model-declare-port-provider-binding':'model.install_model_declare_port_provider_binding_change',
      'model-set-definition-label':'model.install_model_set_definition_label_change'
    };
    if(!installers[cap])throw Error('Unrecognized placement installer '+cap);
    lines.push("SET @payload=JSON_QUERY(@req,'$.payload');",'EXEC '+installers[cap]+' @document=@payload;');
  }else{
    lines.push('EXEC model.apply_declared_change @input=@req;');
  }
  if(step.stepId===process.argv[4])break;
}
lines.push('ROLLBACK TRANSACTION python_reuse_rehearsal;',
  "SELECT 'python_reuse_rehearsal' result_set,'PASSED_AND_ROLLED_BACK' disposition;");
const source=lines.join('\n')+'\n';
if(source.length>131072)throw Error('Rehearsal exceeds the engineering source limit');
writeFileSync(process.argv[2],source);
