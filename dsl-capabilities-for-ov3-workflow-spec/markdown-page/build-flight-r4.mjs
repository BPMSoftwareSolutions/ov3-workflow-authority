// Revision 4: give the admitted renderer's provider a C# entry that launches the same pinned CPython closure, so the
// whole run stays on the hosted C# worker, then prove it there: a tampered bundle refused, and both objectives fulfilled
// through default MCP discovery.
import { writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { artifact, change, continuation, sql } from '../python-reuse/build-flight.mjs';
import { identity,page,leaf,read } from './build.mjs';
import { objectives } from './build-flight.mjs';
import { providerId,mechanic,entry,operation,csharpEntry,csharpOperation,interpreter,processType } from './native-profile.mjs';

// Revision 3 was approved and flown, so this revision records its plan in a slot of its own.
export const agentId='ov3-markdown-page-csharp-v1',promiseId='markdown-page-csharp-launch-v1';
const workClass='capability-build',prefix='sidefx:dependencies/'+providerId;
export const promise={contractId:'flight-promise.v1',promiseId,workClass,
  statement:'Run the admitted Markdown page capability on the hosted C# worker by launching its pinned CPython closure from a declared C# provider entry, then fulfill two objectives through default MCP discovery.',
  obligations:[
    {obligationId:'provider',statement:'Declare and bind a C# entry for the page provider that launches the pinned CPython entry under a deadline.',evidence:'Dependency, provider and binding commits, their pins, and C# delivery eligibility for the private operation and the public page.'},
    {obligationId:'control',statement:'Refuse a tampered package on the hosted C# worker.',evidence:'A direct invocation of the private operation answering PACKAGE_CLOSURE_MISMATCH.'},
    {obligationId:'report',statement:'Publish and verify the original 297-module report through the default objective path.',evidence:'Native FULFILLED with a publication turn, source and HTML digests.'},
    {obligationId:'reuse',statement:'Render an unrelated document through the same admitted capability.',evidence:'Fresh default MCP completion using the same provider closure and presentation digest.'}]};
const basis='Revision 3 (flight-report.md) admitted the renderer and reached its binding, which returned PROVIDER_LANGUAGE_UNAVAILABLE on the hosted C# worker: the operation was declared only for Python. The five python-reuse capabilities run CPython from C# provider programs on that worker (flight 51a278c0-4f65-48f5-a153-b2defa5ffabf). The launcher was rehearsed with the C# program\'s exact arguments: a tampered bundle, a failing exit, output that is not JSON, a 6 MB answer and an 80 s deadline.';
const conversations=['3f6b2c1e-8a47-4d0f-9b2e-5c1d7a9e4f60','c8e1d5a2-6b3f-4e7a-8d9c-0a2b4c6e8f13'];

export function makeFlight(){
  const steps=[{stepId:'plan-header',contractId:'estate-flight-plan.v1',promiseId,flightType:'execution',workClass,unknowns:[]}];
  const add=(stepId,capabilityId,input,path,equals,obligation='provider',bind=[])=>steps.push({
    stepId,capabilityId,input,expect:{path,equals},obligationIds:[obligation],historicalBasis:basis,...(bind.length?{bind}:{})});
  const bound=(target,fromStep,path)=>({target,fromStep,path});
  const template=continuation().steps;
  const catalogs=template.find(s=>s.stepId==='html-profile');
  const readPin=template.find(s=>s.stepId==='html-pin-dependency').input;
  // Revision 3 created every identity; this revision changes them, so all five must already exist.
  const guard=structuredClone(template.find(s=>s.stepId==='guard-new-identities').input);
  guard.input.names=[[page,'sidefx:capabilities'],[leaf,'sidefx:capabilities'],[providerId,'sidefx:providers'],[providerId,'sidefx:dependencies'],[mechanic,'sidefx:platform-capabilities']].map(([id,ns])=>({id,ns}));
  add('guard-admitted-identities','sql-database-reader',guard,'$.value.collisions',5);
  const fixtures=JSON.parse(read('acceptance.json'));
  add('guard-package-and-sources','sql-database-reader',sql(`SELECT (SELECT COUNT(DISTINCT a.content_digest) AS matched FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
    JOIN OPENJSON(@input,'$.assets') WITH (digest varchar(71),kind nvarchar(60)) i ON TRY_CONVERT(binary(32),SUBSTRING(i.digest,8,64),2)=a.content_digest
    WHERE (a.artifact_kind=i.kind OR (i.kind='python-library-report' AND a.artifact_kind LIKE 'python-library-report:%')) AND c.content_digest=HASHBYTES('SHA2_256',c.content_bytes)
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;`,{assets:[{kind:'markdown-python-provider-package',digest:identity.assetDigest},...fixtures.map((f,i)=>({kind:i?'markdown-page-source':'python-library-report',digest:f.sourceDigest}))]}),'$.value.matched',3);
  const op=operation(identity),cs=csharpOperation(identity),native=entry(identity),hosted=csharpEntry(identity);
  const title='Pinned Python Markdown page rendering and independent verification';
  const profile={...catalogs.input.input.profile,profileId:providerId,providerId,mechanicIds:[mechanic],implementationRef:prefix,conformanceRefs:['sidefx:capabilities/'+leaf]};
  const dependency={dependencyId:providerId,meaning:title,objectGraphClosure:'object-graph.v1',source:identity,
    runtimes:{python:{package:'importlib',export:'import_module',modules:['sys','subprocess','markdown','nh3'],wheelClosure:identity.assetDigest},
      csharp:{package:'CPython with the pinned Markdown and nh3 closure',type:processType,executable:interpreter,deadline:'/usr/bin/timeout',wheelClosure:identity.assetDigest}},
    operations:[{operationId:op.operationId,meaning:title,parameters:op.parameters,result:op.result,programs:{python:op.program,csharp:cs.program}}]};
  add('dependency','model-declare-semantic-object',{object_kind:'DEPENDENCY',namespace_id:'sidefx:dependencies',declared_id:providerId,semantics_json:dependency},'$.status','COMMITTED');
  add('pin-dependency','sql-database-reader',{...readPin,input:{ns:'sidefx:dependencies',id:providerId}},'$.value.verified',true);
  add('prepare-profile','sql-database-reader',{...catalogs.input,input:{profile,digest:''}},'$.value.verified',true,'provider',[bound('input.digest','pin-dependency','$.value.digest')]);
  const catalog={providerId,name:title,declarationProfile:'sda-platform-capability-catalog.v1',effectClassification:'observation',
    profile,dependency:{objectKind:'DEPENDENCY',namespace:'sidefx:dependencies',id:providerId,definitionDigest:'',operationId:op.operationId},
    providerProfiles:[
      {providerProfileId:providerId,language:'python',providerModule:native.module,providerExport:native.export,effectClassification:'observation',operations:[op]},
      {providerProfileId:providerId,language:'csharp',providerModule:processType,providerAssembly:processType,providerExport:'.ctor',factory:true,effectClassification:'observation',operations:[cs]}],
    capabilities:['python','csharp'].map(language=>({capabilityId:mechanic,kind:'graph-profile',projectionTarget:language,status:'DECLARED',
      implementationRef:prefix+'#operations/transform/programs/'+language,conformanceRef:'sidefx:capabilities/'+leaf}))};
  add('provider','model-declare-provider-identity',{provider_id:providerId,catalog_json:catalog},'$.status','COMMITTED','provider',[
    bound('catalog_json.profile.sourceAuthorityDigest','pin-dependency','$.value.digest'),bound('catalog_json.profile.profileDigest','prepare-profile','$.value.digest'),bound('catalog_json.dependency.definitionDigest','pin-dependency','$.value.digest')]);
  add('pin-provider','sql-database-reader',{...readPin,input:{ns:'sidefx:providers',id:providerId}},'$.value.verified',true);
  for(const [language,providerEntry] of [['python',native],['csharp',hosted]])
    add('bind-'+language,'model-declare-port-provider-binding',{namespace_id:'sidefx:capability:run-declared-graph',port_id:'run-declared-graph-execute',
      provider_entry_json:{...providerEntry,sourceProviderDefinitionDigest:''},overlay_binding_json:{mechanicId:mechanic,providerProfileId:providerId,providerProfileDigest:'',implementationRef:prefix}},
      '$.status','COMMITTED','provider',[bound('provider_entry_json.sourceProviderDefinitionDigest','pin-provider','$.value.digest'),bound('overlay_binding_json.providerProfileDigest','prepare-profile','$.value.digest')]);
  add('feature-'+leaf,'apply-declared-change',artifact('capability-feature:'+leaf,read(leaf+'.feature')),'$.disposition','COMMITTED');
  add('declare-'+leaf,'apply-declared-change',change('capability-from-dsl',{source:read(leaf+'.dsl'),isMcpTooling:false}),'$.disposition','COMMITTED');
  add('topology-'+leaf,'read-topology-conformance',{capabilityId:leaf},'$.capabilities[0].conformanceStatus','CONFORMANT');
  add('check-verifier-conformance','read-topology-conformance',{capabilityId:'verify-objective-fulfillment'},'$.capabilities[0].conformanceStatus','CONFORMANT');
  // Languages are reported in name order, so csharp comes first when a capability is eligible for it.
  for(const id of [leaf,page])add('verify-csharp-delivery-'+id,'read-capability-delivery-languages',{capabilityId:id},'$.languages[0]','csharp');
  const vector=JSON.parse(read(leaf+'.feature').match(/"""json\s+(.+?)\s+"""/s)[1]);
  add('control-tampered-package',leaf,vector,'$.finding','PACKAGE_CLOSURE_MISMATCH','control');
  for(const [i,request] of objectives().entries()){
    const objective={...request,conversationId:conversations[i]};
    const obligation=i?'reuse':'report';
    add('fulfill-'+obligation,'request-capability-from-objective-v3',objective,'$.objectiveFulfillment','FULFILLED',obligation);
    add('check-live-pin-'+obligation,'sql-database-reader',sql(`DECLARE @body TABLE(payload varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
      INSERT @body SELECT TOP(1) c.content_bytes FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
      WHERE a.artifact_kind='objective-pursuit:'+JSON_VALUE(@input,'$.conversation') AND c.content_digest=HASHBYTES('SHA2_256',c.content_bytes)
      ORDER BY a.registered_date DESC,a.content_artifact_pk DESC;
      SELECT (SELECT COUNT(*) AS bound FROM @body CROSS APPLY(SELECT CONVERT(nvarchar(max),payload) body)b WHERE JSON_VALUE(b.body,'$.objectiveFulfillment')='FULFILLED'
      AND JSON_VALUE(b.body,'$.verification.producer')='render-markdown-html-page' AND JSON_VALUE(b.body,'$.verification.artifactDigest')=JSON_VALUE(@input,'$.output')
      AND JSON_VALUE(b.body,'$.verification.metrics.bundleDigest')=JSON_VALUE(@input,'$.bundle')
      AND JSON_VALUE(b.body,'$.verification.sourceIdentity.sourceDigest')=JSON_VALUE(@input,'$.source') FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;`,
      {conversation:conversations[i],bundle:identity.bundleDigest,source:fixtures[i].sourceDigest,output:fixtures[i].outputDigest}),'$.value.bound',1,obligation);
  }
  return {agentId,promise,objective:promise.statement,steps};
}
if(process.argv[1]&&pathToFileURL(process.argv[1]).href===import.meta.url)writeFileSync(process.argv[2],JSON.stringify(makeFlight()));
