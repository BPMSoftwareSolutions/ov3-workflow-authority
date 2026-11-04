import { writeFileSync } from 'node:fs';
import { artifact, change, continuation, sql } from './build-flight.mjs';
import { read, sha } from './portfolio.mjs';
import { pathToFileURL } from 'node:url';

const verifier='verify-objective-fulfillment', publisher='publish-python-reuse-result';
const currentVerifier='sha256:cdbb33a6cee4020d697a086f9a50bf8095cabc8e8b02e9473f1a89d4bbb707f7';
const promiseId='python-reuse-recovery-v1',workClass='capability-build';
const statement='Preserve the two conformant Python bindings, repair UTF-8 decoding in the DSL feature installer, finish the remaining three bindings, and admit the publisher and typed verification profile for the notice and ledger objectives.';
const promise={contractId:'flight-promise.v1',promiseId,workClass,statement,obligations:[
  {obligationId:'encoding',statement:'The installer preserves the approved UTF-8 feature digest.',evidence:'Digest-guarded decoder repair and successful installation of the original Unicode Base64 feature.'},
  {obligationId:'supply',statement:'All five bounded providers are conformant and exposed through MCP.',evidence:'Selected authority pins, topology and public catalog readback.'},
  {obligationId:'publisher',statement:'Install the new feature-pinned manifest publisher.',evidence:'Committed canonical bytes and DSL, conformant public identity.'},
  {obligationId:'proof',statement:'Extend the existing verifier from its inspected revision.',evidence:'Matching starting document digest, committed DSL, conformant verifier and a retrospective fulfilled report.'}
]};
const basis='The supply flight retained a canonical feature and installed its DSL in recording 9389d42b-5bff-41c9-9012-8380c9043104. Historical objective f6235d12-bdba-c872-d9d0-896e337579f5 fulfilled the previous Python report.';
const steps=[{stepId:'plan-header',contractId:'estate-flight-plan.v1',promiseId,flightType:'execution',workClass,unknowns:[]}];
function step(stepId,capabilityId,input,path,equals,obligationId) {
  steps.push({stepId,capabilityId,input,expect:{path,equals},obligationIds:[obligationId],historicalBasis:basis});
}
const supply=continuation().steps;
const reuse=s=>({...s,obligationIds:['supply']});
const guard=structuredClone(supply.find(s=>s.stepId==='guard-new-identities'));
guard.input.input.names=guard.input.input.names.filter(item=>/binascii|hashlib/.test(item.id));
steps.push(reuse(guard));
for(const id of ['python-textwrap','python-html'])
  step('preserve-'+id,'read-topology-conformance',{capabilityId:id},'$.capabilities[0].conformanceStatus','CONFORMANT','supply');
const baseline=supply.find(s=>s.stepId==='existing-authority-0').input;
for(const [ns,id,digest] of [
  ['sidefx:dependencies','cpython-base64-bounded-v1','ff9ea9e7c9b0bc11d4621aa7087022617e382e37ceb4faf1c78aa1816fb2c7d8'],
  ['sidefx:providers','cpython-base64-bounded-v1','dee58657f846bf485b99816cbc74bf9a2e0ddca8ac5d176d397d37f871ebfa59'],
  ['sidefx:platform-capabilities','cpython-base64-bounded-v1-port.v1','1ec6a169765107c5550fa1ce6cc3dd8f097a7abc86d66c8565213c1e18c29d68']
]) step('preserve-base64-'+ns.split(':')[1],'sql-database-reader',{...baseline,input:{ns,id}},'$.value.digest','sha256:'+digest,'supply');
step('guard-current-verifier','read-declared-capability-document',{capabilityId:verifier},'$.documentDigest',currentVerifier,'proof');
step('guard-new-publisher','read-declared-capability-document',{capabilityId:publisher},'$.documentInstalled',false,'publisher');
const repair=sha(read('repair-feature-decoding.sql'));
step('repair-feature-decoder','apply-engineering-change',{contractId:'engineering-change.v1',sourceDigest:repair,mode:'commit',
  verificationCapabilityId:'read-harness-authoring-state',preflight:{input:{changeKind:'engineering-change',includeDefinitions:true},expected:{disposition:'terminated'}},
  route:{resolvedDisposition:'terminated'}},'$.disposition','COMMITTED','encoding');
step('prove-decoder-digest','sql-database-reader',sql(`SELECT (SELECT LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
  CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'model.apply_capability_from_dsl')) COLLATE Latin1_General_100_BIN2_UTF8)),2)) digest
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;`),'$.value.digest','bef69d7f885f2e5e43a6deb523fae28961e90fc824fcbcdacef1c58b917ac4b5','encoding');
for(const s of supply.filter(s=>/^(?:binascii-|hashlib-|base64-(?:install|display-label|conformance)$)/.test(s.stepId)))
  steps.push({...reuse(s),...(s.stepId==='base64-install'&&{obligationIds:['supply','encoding']})});
steps.push(reuse(supply.find(s=>s.stepId==='verify-mcp-membership')));
step('retain-publisher-feature','apply-declared-change',artifact('capability-feature:'+publisher,read(publisher+'.feature')),'$.disposition','COMMITTED','publisher');
for(const [id,src,obligation] of [[publisher,read(publisher+'.dsl'),'publisher'],[verifier,read('../objective-verification/'+verifier+'.dsl'),'proof']]){
  step('install-'+obligation,'apply-declared-change',change('capability-from-dsl',{source:src,isMcpTooling:true}),'$.disposition','COMMITTED',obligation);
  step('check-'+obligation,'read-topology-conformance',{capabilityId:id},'$.capabilities[0].conformanceStatus','CONFORMANT',obligation);
}
// Exercise the existing entry point and its previous evidence family after the additive revision.
step('verify-original-python-report',verifier,{conversationId:'4ca89bb0-c7ed-4e95-bd19-603abb357b19',publicationTurn:3,
  expectedSourceVersion:'3.15.2',expectedArtifactDigest:'sha256:94a77a826d7822419a8fe8c2d00275048a541c1a1d6aff4f753835abcad0c966'},'$.status','FULFILLED','proof');
export const recovery={agentId:'ov3-python-reuse-recovery-v1',promise,objective:statement,steps};
if(process.argv[1] && pathToFileURL(process.argv[1]).href===import.meta.url){
  writeFileSync(process.argv[2],JSON.stringify(recovery));
  console.log(steps.length-1,'steps, recovery plan source',sha(JSON.stringify(steps)));
}
