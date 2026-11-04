import { writeFileSync } from 'node:fs';
import { recovery } from './build-recovery-flight.mjs';
import { artifact, change } from './build-flight.mjs';
import { read, sha } from './portfolio.mjs';
import { specimen } from './benchmark.mjs';

const verifier='verify-objective-fulfillment';
const {agentId,promise}=recovery;
const basis='Recovery recording f7c6ad02-e767-4e70-a65b-bd161e98b730 installed all five public providers and the publication authority. The retained notice and ledger supply the matching original requests, publication turns and independent byte checks.';
const steps=[structuredClone(recovery.steps[0])];
function step(stepId,capabilityId,input,path,equals,obligationId='proof'){
  steps.push({stepId,capabilityId,input,expect:{path,equals},obligationIds:[obligationId],historicalBasis:basis});
}
for(const id of ['prove-decoder-digest','verify-mcp-membership','check-publisher']){
  const s=recovery.steps.find(s=>s.stepId===id);
  if(!s)throw Error('Missing recovery readback '+id);
  steps.push({...s,historicalBasis:basis});
}
step('guard-installed-proof','read-declared-capability-document',{capabilityId:verifier},'$.documentDigest','sha256:7a85e51187c7d19e4f9a84361d7abcc9eec4d519bc4e4f25ce1ebc18f08814ea');
step('retain-proof-feature','apply-declared-change',artifact('capability-feature:'+verifier,read('../objective-verification/'+verifier+'.feature')),'$.disposition','COMMITTED');
step('install-proof','apply-declared-change',change('capability-from-dsl',{source:read('../objective-verification/'+verifier+'.dsl'),isMcpTooling:true}),'$.disposition','COMMITTED');
step('check-proof','read-topology-conformance',{capabilityId:verifier},'$.capabilities[0].conformanceStatus','CONFORMANT');
const publications=[
  ['original-python-report','be0a0a31-50fc-460c-ac66-fb24a999bbc2',1,'94a77a826d7822419a8fe8c2d00275048a541c1a1d6aff4f753835abcad0c966'],
  ['notice','7c1f0f8c-952c-4d77-9fa4-6e05effbb6ac',6,'f5261c8dddb6f98e420fa75fa1fa09700dafcc3aa6eb942bc83e86f6af7a59f5'],
  ['ledger','f8900169-3abc-4501-87f8-aad6a8e43b74',4,'c557c34314513ff51f7501a17d47cc3bd04fb1a92bdaa63c0b6914570bcdfded']];
for(const [name,conversationId,publicationTurn,hash] of publications)
  step('verify-'+name,verifier,{conversationId,publicationTurn,expectedArtifactDigest:'sha256:'+hash,
    ...(name==='original-python-report'&&{expectedSourceVersion:'3.15.2'})},'$.status','FULFILLED');
step('reject-mismatched-publication',verifier,{conversationId:'4ca89bb0-c7ed-4e95-bd19-603abb357b19',publicationTurn:3,
  expectedArtifactDigest:'sha256:'+publications[0][3]},'$.status','UNVERIFIED');
step('retain-routing-feature','apply-declared-change',artifact('acceptance-feature:ov3-compound-objective-routing',read('compound-objective-routing.feature')),'$.disposition','COMMITTED');
step('install-compound-discovery','apply-engineering-change',{contractId:'engineering-change.v1',sourceDigest:sha(read('repair-compound-routing.sql')),
  mode:'commit',verificationCapabilityId:'read-harness-authoring-state',preflight:{input:{changeKind:'engineering-change',includeDefinitions:true},expected:{disposition:'terminated'}},
  route:{resolvedDisposition:'terminated'}},'$.disposition','COMMITTED');
for(const [id,conversationId] of [['notice','19c8c396-5444-4399-b863-149913f469ee'],['ledger','b3881f09-eeed-41c0-8384-77d0c36d7dc9']])
  step('fulfill-default-'+id,'request-capability-from-objective-v3',{conversationId,objective:specimen(id).request},'$.objectiveFulfillment','FULFILLED');
const objective='Close the recovery promise by proving the original Python report, the published notice and ledger, and two fresh unscoped objectives. Preserve the five public bindings, check the verifier against their retained evidence, and restore later-operation discovery on OV3’s default route.';
writeFileSync(process.argv[2],JSON.stringify({agentId,promise,objective,steps}));
