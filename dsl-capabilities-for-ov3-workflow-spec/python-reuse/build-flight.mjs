import { writeFileSync } from 'node:fs';
import { entries, experiment, file, operationProgram, sha } from './portfolio.mjs';
import { pathToFileURL } from 'node:url';

export function change(changeKind, fields) {
  return {contractId:'declared-change.v1',changeKind,payload:{contractId:changeKind+'-change.v1',
    ...fields,verificationCapabilityId:'read-harness-authoring-state',route:{resolvedDisposition:'terminated'},
    preflight:{input:{changeKind,includeDefinitions:true},expected:{disposition:'terminated'}}}};
}
// content-artifact-change already includes the word "change" in its kind name.
export function artifact(kind, text) {
  const request=change('content-artifact-change',{artifactKind:kind,text});
  request.payload.contractId='content-artifact-change.v1';
  return request;
}
const dataSource='sfx-estate-database';
export const sql=(statement,input={})=>({dataSource,resultColumn:'value',statement,input});
const definitions = `FROM model.semantic_object so
  JOIN model.identity_namespace ns ON ns.namespace_pk=so.namespace_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_pk=so.semantic_object_pk
  JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk
  AND ed.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk`;
const promiseId='python-reuse-supply-v1';
const agentId='ov3-python-reuse-supply-v1';
const workClass='capability-build';
const promise={contractId:'flight-promise.v1',promiseId,workClass,
  statement:'Declare five source-pinned Python provider bindings as conformant MCP capabilities. Runtime vectors and objective outcomes are separate evidence.',
  obligations:entries.map(e=>({obligationId:e.name,statement:'Install '+e.id+' from its pinned feature and bind its fixed Python operation.',
    evidence:'Selected dependency and provider digests, committed binding and MCP authoring receipt, and conformant topology for '+e.id}))};
const steps=[{stepId:'plan-header',contractId:'estate-flight-plan.v1',promiseId,flightType:'execution',workClass,unknowns:[]}];
const prior='Model and binding writers committed in flight 363. The selected OpenTofu dependency and provider were inspected in run 878bcbc2-45bf-4e0b-e804-5e4ce013b5c5.';
const authorBasis='Plan 363 retained and installed a DSL through apply-declared-change. The published Python inventory uses canonical feature pins and MCP tooling.';
function step(e,action,cap,input,path,equals,basis=prior,bind=[]) {
  const stepId=e.name+'-'+action;
  steps.push({stepId,capabilityId:cap,input,expect:{path,equals},obligationIds:[e.name],historicalBasis:basis,...(bind.length && {bind})});
  return stepId;
}
const bound=(target,fromStep,path)=>({target,fromStep,path});
const pinQuery=`SELECT (SELECT TOP(1) 'sha256:'+LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS digest,
  CONVERT(bit,IIF(d.definition_digest=HASHBYTES('SHA2_256',co.content_bytes),1,0)) AS verified
  ${definitions} WHERE ns.namespace_id=JSON_VALUE(@input,'$.ns') AND so.declared_id=JSON_VALUE(@input,'$.id')
  ORDER BY d.semantic_object_definition_pk DESC FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;`;
const names=entries.flatMap(e=>[[e.id,'sidefx:capabilities'],[e.mechanic,'sidefx:platform-capabilities'],[e.dependency,'sidefx:providers'],[e.dependency,'sidefx:dependencies']].map(([id,ns])=>({id,ns})));
steps.push({stepId:'guard-new-identities',capabilityId:'sql-database-reader',input:sql(`SELECT (SELECT COUNT(*) AS collisions FROM model.semantic_object o JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
  JOIN OPENJSON(@input,'$.names') WITH (id nvarchar(400),ns nvarchar(400)) k ON k.id=o.declared_id AND k.ns=n.namespace_id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;`,{names}),
  historicalBasis:'Identity inspection on the connected estate, run 4c3b3b18-8fee-52d9-7a63-b5c8c07320ac. Stop before the first write if a target identity exists.',
  obligationIds:entries.map(e=>e.name),expect:{path:'$.value.collisions',equals:0}});
for(const e of entries){
  const ref='sidefx:dependencies/'+e.dependency;
  const conform='sidefx:capabilities/'+e.id;
  const op=operationProgram(e);
  const pdb='System.Diagnostics.Process';
  const dep={dependencyId:e.dependency,meaning:e.title,objectGraphClosure:'object-graph.v1',source:e.source,
    runtimes:{csharp:{package:'CPython standard library',type:pdb,executable:'/usr/local/bin/python3'}},
    operations:[{operationId:op.operationId,meaning:e.title,parameters:op.parameters,result:op.result,programs:{csharp:op.program}}]};
  step(e,'dependency','model-declare-semantic-object',{object_kind:'DEPENDENCY',namespace_id:'sidefx:dependencies',declared_id:e.dependency,semantics_json:dep},'$.status','COMMITTED');
  const dependencyPin=step(e,'pin-dependency','sql-database-reader',sql(pinQuery,{ns:'sidefx:dependencies',id:e.dependency}),'$.value.verified',true);
  step(e,'mechanic','model-declare-platform-capability',{capability_id:e.mechanic,semantics_json:{projectionTarget:'csharp',status:'DECLARED',implementationRef:ref,authority:{mode:'capability',name:e.mechanic,userStory:{actor:'a capability author',intent:e.title,outcome:'Compute a bounded value and identify the runtime.'}}}},'$.status','COMMITTED');
  const profile={profileType:'sda-provider-profile.v2',profileId:e.dependency,providerId:e.dependency,mechanicIds:[e.mechanic],
    implementationRef:ref,effectClassification:'observation',determinism:'testimony-governed',conformanceRefs:[conform],physicalPrimitiveProfiles:[]};
  // Compute the profile pin from its concrete source digest on the server before declaring the provider.
  const prepared=step(e,'profile','sql-database-reader',sql(`DECLARE @p nvarchar(max)=JSON_MODIFY(JSON_QUERY(@input,'$.profile'),'$.sourceAuthorityDigest',JSON_VALUE(@input,'$.digest'));
    DECLARE @hash varchar(71)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p COLLATE Latin1_General_100_BIN2_UTF8)),2));
    SELECT (SELECT JSON_QUERY(JSON_MODIFY(@p,'$.profileDigest',@hash)) profile,@hash digest,CONVERT(bit,IIF(LEN(JSON_VALUE(@p,'$.sourceAuthorityDigest'))=71,1,0)) verified FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;`,{profile,digest:''}),
    '$.value.verified',true,prior,[bound('input.digest',dependencyPin,'$.value.digest')]);
  const catalog={providerId:e.dependency,name:e.title,declarationProfile:'sda-platform-capability-catalog.v1',effectClassification:'observation',
    profile,dependency:{objectKind:'DEPENDENCY',namespace:'sidefx:dependencies',id:e.dependency,definitionDigest:'',operationId:'compute'},
    providerProfiles:[{providerProfileId:e.dependency,language:'csharp',providerModule:pdb,providerAssembly:pdb,providerExport:'.ctor',
      factory:true,effectClassification:'observation',operations:[op]}],
    capabilities:[{capabilityId:e.mechanic,kind:'graph-profile',projectionTarget:'csharp',status:'DECLARED',implementationRef:ref+'#operations/compute/programs/csharp',conformanceRef:conform}]};
  step(e,'provider','model-declare-provider-identity',{provider_id:e.dependency,catalog_json:catalog},'$.status','COMMITTED',prior,
    [bound('catalog_json.profile.sourceAuthorityDigest',dependencyPin,'$.value.digest'),
     bound('catalog_json.profile.profileDigest',prepared,'$.value.digest'),
     bound('catalog_json.dependency.definitionDigest',dependencyPin,'$.value.digest')]);
  const providerPin=step(e,'pin-provider','sql-database-reader',sql(pinQuery,{ns:'sidefx:providers',id:e.dependency}),'$.value.verified',true);
  step(e,'bind','model-declare-port-provider-binding',{namespace_id:'sidefx:capability:run-declared-graph',port_id:'run-declared-graph-execute',
    provider_entry_json:{providerProfileId:e.dependency,language:'csharp',type:pdb,assembly:pdb,method:'.ctor',factory:true,
      effectClassification:'observation',operations:[op],sourceProviderDefinitionDigest:''},
    overlay_binding_json:{mechanicId:e.mechanic,providerProfileId:e.dependency,providerProfileDigest:'',implementationRef:ref}},
    '$.status','COMMITTED',prior,[bound('provider_entry_json.sourceProviderDefinitionDigest',providerPin,'$.value.digest'),bound('overlay_binding_json.providerProfileDigest',prepared,'$.value.digest')]);
  step(e,'feature','apply-declared-change',artifact('capability-feature:'+e.id,e.feature),'$.disposition','COMMITTED',authorBasis);
  step(e,'install','apply-declared-change',change('capability-from-dsl',{source:e.dsl,isMcpTooling:true}),'$.disposition','COMMITTED',authorBasis);
  step(e,'conformance','read-topology-conformance',{capabilityId:e.id},'$.capabilities[0].conformanceStatus','CONFORMANT',authorBasis);
}
steps.push({stepId:'verify-mcp-membership',capabilityId:'sql-database-reader',
  input:sql(`SELECT (SELECT COUNT(DISTINCT c.capability_id) AS exposed FROM model.capability c
    JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id='sidefx:capabilities'
    JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
    JOIN OPENJSON(@input,'$.ids') ids ON ids.value=c.capability_id WHERE c.is_mcp_tooling=1 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;`,{ids:entries.map(e=>e.id)}),
  expect:{path:'$.value.exposed',equals:entries.length},historicalBasis:'The installed MCP catalog selects model.capability.is_mcp_tooling. Discovery run 61afa2ce-298d-c5cf-f46d-bdf7fa51b423.',
  obligationIds:entries.map(e=>e.name)});
export const flight={agentId,promise,objective:promise.statement,steps};
export const firstDigest='44a472b228ec4f5d302277f5d5e4d2c50d591e600f3d25010af2337a21bae731';
export function continuation() {
  const recording='9389d42b-5bff-41c9-9012-8380c9043104';
  const result=structuredClone(flight);
  const [header,guard]=result.steps;
  guard.input.input.names=guard.input.input.names.filter(item=>!item.id.includes('textwrap'));
  const existing=entries[0];
  const pins=[
    ['sidefx:dependencies',existing.dependency,'173b34d964b718ec541f0c58658f24163db653eeb3c972a65b872cfb4b5d0a09'],
    ['sidefx:providers',existing.dependency,'5795ddcfc5a79885d89224c83de38f27ad2ffc1104ed41391e2610a9910f3b61'],
    ['sidefx:platform-capabilities',existing.mechanic,'67f068e1f0b62f02f6287ed0e5dea670135c0ac45fd9a638e6f555e5f5140fa2']
  ];
  const before=pins.map(([ns,id,digest],i)=>({stepId:'existing-authority-'+i,capabilityId:'sql-database-reader',
    input:sql(pinQuery,{ns,id}),expect:{path:'$.value.digest',equals:'sha256:'+digest},obligationIds:['textwrap'],
    historicalBasis:'Pin the successful authority from recorded flight '+recording+' before touching the provider label.'}));
  before.push({stepId:'existing-textwrap-vector',capabilityId:existing.id,input:existing.vector,expect:existing.assertions[1],
    obligationIds:['textwrap'],historicalBasis:'Live CPython 3.12.16 reference vector in run 7517acff-e6fa-bf78-0b46-ab5389cf0f1b.'});
  result.steps=[header,guard,...before];
  for(const item of flight.steps.slice(2)) {
    if(item.stepId.startsWith('textwrap-') && item.stepId!=='textwrap-conformance') continue;
    if(item.stepId.endsWith('-conformance')){
      const e=entries.find(e=>item.stepId===e.name+'-conformance');
      result.steps.push({stepId:e.name+'-display-label',capabilityId:'model-set-definition-label',
        input:{declared_id:e.dependency,namespace_id:'sidefx:providers',object_kind:'PROVIDER',version_label:e.title},
        expect:{path:'$.status',equals:'COMMITTED'},obligationIds:[e.name],
        historicalBasis:'Plan 363 step label-brotli-codec-provider. Recording '+recording+' stopped on TOPOLOGY_PROVIDER_LABEL_MISSING.'});
    }
    result.steps.push(item);
  }
  return result;
}
if(process.argv[1] && pathToFileURL(process.argv[1]).href===import.meta.url){
  for(const e of entries) writeFileSync(file(e.id+'.dsl'),e.dsl);
  const plan=process.argv.includes('--continuation')?continuation():flight;
  if(process.argv[2]) writeFileSync(process.argv[2],JSON.stringify(plan));
  console.log(plan.steps.length-1,'steps, catalog',experiment.catalogDigest,'plan source',sha(JSON.stringify(plan.steps)));
}
