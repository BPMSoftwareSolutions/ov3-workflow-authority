import { readFileSync, writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { artifact, change, continuation, sql } from '../python-reuse/build-flight.mjs';
import { identity,page,leaf,read } from './build.mjs';
import { providerId,mechanic,entry,operation } from './native-profile.mjs';

export const agentId='ov3-markdown-page-v1',promiseId='markdown-page-v1';
const workClass='capability-build',prefix='sidefx:dependencies/'+providerId;
export const promise={contractId:'flight-promise.v1',promiseId,workClass,
  statement:'Activate a reusable UTF-8 Markdown page capability with a declared Python profile and pinned dependencies, then fulfill two objectives through default MCP discovery.',
  obligations:[
    {obligationId:'provider',statement:'Declare and execute the bounded Python profile and its pinned parser and sanitizer.',evidence:'Package readback, source and profile pins, Python delivery declaration and a live native package-pin control.'},
    {obligationId:'creation',statement:'Admit the feature-pinned reusable renderer and independent proof profile.',evidence:'Feature and DSL commits, topology conformance and public MCP membership.'},
    {obligationId:'report',statement:'Publish and verify the original 297-module report through the default objective path.',evidence:'Native FULFILLED with a publication turn, source and HTML digests.'},
    {obligationId:'reuse',statement:'Render an unrelated document through the same admitted capability.',evidence:'Fresh default MCP completion using the same provider closure and presentation digest, without admission steps.'}]};
const basis='The prior CPython supply and proof flight 51a278c0-4f65-48f5-a153-b2defa5ffabf admitted feature-pinned DSL and reverified publications. The selected sfx-runtime-probe declares Python through an importlib provider entry. The new package was rehearsed with the pinned native Python resolver on the configured image.';
const fixtures=JSON.parse(read('acceptance.json'));
export function objectives(){
  return fixtures.map((f,i)=>({conversationId:['bb142e8c-8217-4444-8546-be4939d99800','a81ca28f-3ccd-4faf-9f0f-5a0cc57a1839'][i],
    objective:`Use the admitted Python Markdown page capability to publish the full retained Markdown source ${f.sourceDigest} as ${f.filename}. Use title "${f.title}", lang "${f.lang}" and the technical-report-v1 presentation profile. Verify the standalone UTF-8 HTML and its source, sanitizer and publication receipts. Return its digest.`}));
}
export function makeFlight(verifierPin){
  if(!/^sha256:[0-9a-f]{64}$/.test(verifierPin))throw Error('Missing selected verifier baseline');
  const steps=[{stepId:'plan-header',contractId:'estate-flight-plan.v1',promiseId,flightType:'execution',workClass,unknowns:[]}];
  const add=(stepId,capabilityId,input,path,equals,obligation='provider',bind=[])=>steps.push({
    stepId,capabilityId,input,expect:{path,equals},obligationIds:[obligation],historicalBasis:basis,...(bind.length?{bind}:{})});
  const template=continuation().steps;
  const catalogs=template.find(s=>s.stepId==='html-profile');
  const readPin=template.find(s=>s.stepId==='html-pin-dependency').input;
  const guard=structuredClone(template.find(s=>s.stepId==='guard-new-identities').input);
  guard.input.names=[[page,'sidefx:capabilities'],[leaf,'sidefx:capabilities'],[providerId,'sidefx:providers'],[providerId,'sidefx:dependencies'],[mechanic,'sidefx:platform-capabilities']].map(([id,ns])=>({id,ns}));
  add('guard-new-identities','sql-database-reader',guard,'$.value.collisions',0);
  add('guard-verifier','read-declared-capability-document',{capabilityId:'verify-objective-fulfillment'},'$.documentDigest',verifierPin,'creation');
  add('guard-package-and-sources','sql-database-reader',sql(`SELECT (SELECT COUNT(DISTINCT a.content_digest) AS matched FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
    JOIN OPENJSON(@input,'$.assets') WITH (digest varchar(71),kind nvarchar(60)) i ON TRY_CONVERT(binary(32),SUBSTRING(i.digest,8,64),2)=a.content_digest
    WHERE (a.artifact_kind=i.kind OR (i.kind='python-library-report' AND a.artifact_kind LIKE 'python-library-report:%')) AND c.content_digest=HASHBYTES('SHA2_256',c.content_bytes)
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;`,{assets:[{kind:'markdown-python-provider-package',digest:identity.assetDigest},...fixtures.map((f,i)=>({kind:i?'markdown-page-source':'python-library-report',digest:f.sourceDigest}))]}),'$.value.matched',3);
  const op=operation(identity),native=entry(identity),title='Pinned Python Markdown page rendering and independent verification';
  const profile={...catalogs.input.input.profile,profileId:providerId,providerId,mechanicIds:[mechanic],implementationRef:prefix,conformanceRefs:['sidefx:capabilities/'+leaf]};
  const dependency={dependencyId:providerId,meaning:title,objectGraphClosure:'object-graph.v1',source:identity,
    runtimes:{python:{package:'importlib',export:'import_module',modules:['sys','subprocess','markdown','nh3'],wheelClosure:identity.assetDigest}},
    operations:[{operationId:op.operationId,meaning:title,parameters:op.parameters,result:op.result,programs:{python:op.program}}]};
  add('dependency','model-declare-semantic-object',{object_kind:'DEPENDENCY',namespace_id:'sidefx:dependencies',declared_id:providerId,semantics_json:dependency},'$.status','COMMITTED');
  add('pin-dependency','sql-database-reader',{...readPin,input:{ns:'sidefx:dependencies',id:providerId}},'$.value.verified',true);
  const oldMech=structuredClone(template.find(s=>s.stepId==='html-mechanic').input);
  oldMech.capability_id=mechanic;
  const mech=oldMech.platform_json??oldMech.semantics_json??oldMech.capability_json;
  Object.assign(mech,{projectionTarget:'python',implementationRef:prefix});
  mech.authority={mode:'capability',name:mechanic,userStory:{actor:'an objective owner',intent:title,outcome:'Compute or independently verify a standalone UTF-8 HTML page.'}};
  add('mechanic','model-declare-platform-capability',oldMech,'$.status','COMMITTED');
  const bound=(target,fromStep,path)=>({target,fromStep,path});
  add('prepare-profile','sql-database-reader',{...catalogs.input,input:{profile,digest:''}},'$.value.verified',true,'provider',[bound('input.digest','pin-dependency','$.value.digest')]);
  const catalog={providerId,name:title,declarationProfile:'sda-platform-capability-catalog.v1',effectClassification:'observation',
    profile,dependency:{objectKind:'DEPENDENCY',namespace:'sidefx:dependencies',id:providerId,definitionDigest:'',operationId:op.operationId},
    providerProfiles:[{providerProfileId:providerId,language:'python',providerModule:native.module,providerExport:native.export,effectClassification:'observation',operations:[op]}],
    capabilities:[{capabilityId:mechanic,kind:'graph-profile',projectionTarget:'python',status:'DECLARED',implementationRef:prefix+'#operations/transform/programs/python',conformanceRef:'sidefx:capabilities/'+leaf}]};
  add('provider','model-declare-provider-identity',{provider_id:providerId,catalog_json:catalog},'$.status','COMMITTED','provider',[
    bound('catalog_json.profile.sourceAuthorityDigest','pin-dependency','$.value.digest'),bound('catalog_json.profile.profileDigest','prepare-profile','$.value.digest'),bound('catalog_json.dependency.definitionDigest','pin-dependency','$.value.digest')]);
  add('pin-provider','sql-database-reader',{...readPin,input:{ns:'sidefx:providers',id:providerId}},'$.value.verified',true);
  add('bind-python','model-declare-port-provider-binding',{namespace_id:'sidefx:capability:run-declared-graph',port_id:'run-declared-graph-execute',
    provider_entry_json:{...native,sourceProviderDefinitionDigest:''},overlay_binding_json:{mechanicId:mechanic,providerProfileId:providerId,providerProfileDigest:'',implementationRef:prefix}},
    '$.status','COMMITTED','provider',[bound('provider_entry_json.sourceProviderDefinitionDigest','pin-provider','$.value.digest'),bound('overlay_binding_json.providerProfileDigest','prepare-profile','$.value.digest')]);
  const label=structuredClone(template.find(s=>s.stepId==='html-display-label').input);
  label.declared_id=providerId;label.version_label=title;
  add('label-provider','model-set-definition-label',label,'$.status','COMMITTED');
  for(const [id,member] of [[leaf,false],[page,true]]){
    const obligation=id===leaf?'provider':'creation';
    add('feature-'+id,'apply-declared-change',artifact('capability-feature:'+id,read(id+'.feature')),'$.disposition','COMMITTED',obligation);
    add('declare-'+id,'apply-declared-change',change('capability-from-dsl',{source:read(id+'.dsl'),isMcpTooling:member}),'$.disposition','COMMITTED',obligation);
    add('topology-'+id,'read-topology-conformance',{capabilityId:id},'$.capabilities[0].conformanceStatus','CONFORMANT',obligation);
  }
  add('verify-public-discovery','sql-database-reader',{...template.find(s=>s.stepId==='verify-mcp-membership').input,input:{ids:[page]}},'$.value.exposed',1,'creation');
  add('verify-python-delivery','read-capability-delivery-languages',{capabilityId:leaf},'$.languages[0]','python');
  add('install-publication-proof','apply-declared-change',change('capability-from-dsl',{source:read('../objective-verification/verify-objective-fulfillment.dsl'),isMcpTooling:true}),'$.disposition','COMMITTED','creation');
  add('check-verifier-conformance','read-topology-conformance',{capabilityId:'verify-objective-fulfillment'},'$.capabilities[0].conformanceStatus','CONFORMANT','creation');
  for(const [i,request] of objectives().entries()){
    add(i?'fulfill-reuse':'fulfill-report','request-capability-from-objective-v3',request,'$.objectiveFulfillment','FULFILLED',i?'reuse':'report');
    add('check-live-pin-'+(i?'reuse':'report'),'sql-database-reader',sql(`DECLARE @body TABLE(payload varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
      INSERT @body SELECT TOP(1) c.content_bytes FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
      WHERE a.artifact_kind='objective-pursuit:'+JSON_VALUE(@input,'$.conversation') AND c.content_digest=HASHBYTES('SHA2_256',c.content_bytes)
      ORDER BY a.registered_date DESC,a.content_artifact_pk DESC;
      SELECT (SELECT COUNT(*) AS bound FROM @body CROSS APPLY(SELECT CONVERT(nvarchar(max),payload) body)b WHERE JSON_VALUE(b.body,'$.objectiveFulfillment')='FULFILLED'
      AND JSON_VALUE(b.body,'$.verification.producer')='render-markdown-html-page' AND JSON_VALUE(b.body,'$.verification.artifactDigest')=JSON_VALUE(@input,'$.output')
      AND JSON_VALUE(b.body,'$.verification.metrics.bundleDigest')=JSON_VALUE(@input,'$.bundle')
      AND JSON_VALUE(b.body,'$.verification.sourceIdentity.sourceDigest')=JSON_VALUE(@input,'$.source') FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;`,
      {conversation:request.conversationId,bundle:identity.bundleDigest,source:fixtures[i].sourceDigest,output:fixtures[i].outputDigest}),'$.value.bound',1,'provider');
  }
  return {agentId,promise,objective:promise.statement,steps};
}
if(process.argv[1]&&pathToFileURL(process.argv[1]).href===import.meta.url)writeFileSync(process.argv[2],JSON.stringify(makeFlight(process.argv[3])));
