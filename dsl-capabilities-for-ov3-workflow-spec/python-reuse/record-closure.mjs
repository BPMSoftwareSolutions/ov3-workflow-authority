import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { file, sha } from './portfolio.mjs';
import { specimen, verify } from './benchmark.mjs';

const [work,outputs]=process.argv.slice(2),dir=join(work,'closure-benchmark');
const read=path=>readFileSync(path,'utf8'),json=path=>JSON.parse(read(path));
const runId=log=>read(log).match(/Run ([a-f0-9-]{36})/i)[1];
const flight=json(join(work,'closure-flight-output.json')),closure=json(join(work,'closure-final-verdict.json'));
const approval=json(join(work,'closure-approval.json')),clearance=json(join(work,'closure-clearance.json'));
const retainedPlan=json(join(work,'flown-closure-plan.json'));
const evidencePath=join(outputs,'python-reuse-flight-evidence.json'),history=json(evidencePath);
for(const value of [flight,closure,clearance,approval,retainedPlan]){
  assert.equal(value.planDigest,history.closureReview.planDigest);
  assert.equal(Number(value.planRevision),3);
}
assert.equal(clearance.status,'CLEARED');
assert.equal(closure.executionStatus,flight.status);
const flightRun=runId(join(work,'closure-flight-output.log'));
const reviewChecks=flight.steps.filter(s=>s.result?.contractId==='objective-verification.v1')
  .map(s=>({step:s.stepId,status:s.result.status,artifactDigest:s.result.artifactDigest,reason:s.result.reason,inference:s.result.inference}));
const objectives=[];
for(const id of ['notice','ledger']){
  const step=flight.steps.find(s=>s.stepId==='fulfill-default-'+id);
  const steps=Array.isArray(retainedPlan.steps)?retainedPlan.steps:JSON.parse(retainedPlan.stepsJson);
  const plan=steps.find(s=>s.stepId===step.stepId);
  assert.equal(plan.input.objective,specimen(id).request);
  assert.ok(!Object.hasOwn(plan.input,'visibleCapabilities'));
  const cid=plan.input.conversationId,prefix=join(dir,id+'-'+cid),evidence=json(prefix+'-evidence.json');
  const standalone=step.status==='NOT_RUN';
  const root=standalone?json(prefix+'-objective.json'):step.result;
  if(standalone){
    const submitted=json(prefix+'-request.json');
    assert.equal(submitted.objective,plan.input.objective);
    assert.equal(submitted.conversationId,cid);
    assert.ok(!Object.hasOwn(submitted,'visibleCapabilities'));
  }
  assert.equal(root.objective,plan.input.objective);
  assert.equal(evidence.objective,root.objective);
  assert.equal(evidence.conversationId,cid);
  assert.equal(root.objectiveFulfillment,evidence.objectiveFulfillment);
  const published=readFileSync(prefix+'-artifact.json-bytes');
  const independent=verify(id,evidence,published),verification=evidence.verification;
  assert.equal(independent.artifactDigest,sha(published));
  assert.deepEqual(independent.proof.map(p=>p.receiptDigest),verification.proofReceipts.map(p=>p.digest));
  assert.equal(sha(readFileSync(join(outputs,'python-reuse-'+id+'.json'))),independent.artifactDigest);
  const metricsPath=join(dir,id+'-metrics.json');
  execFileSync(process.execPath,[fileURLToPath(file('measure-run.mjs')),join(work,standalone?'closure-'+id+'-trace.json':'closure-flight-trace.json'),
    prefix+'-evidence.json',metricsPath,...(standalone?[]:['request-capability-from-objective-v3'])]);
  const metrics=json(metricsPath);
  assert.equal(metrics.plannerCalls,evidence.receipts.length);
  const prepared=json(join(work,'candidate-'+id+'.json'));
  assert.deepEqual(prepared.state,{contractId:verification.obligationsContract,request:root.objective,obligations:verification.obligations});
  objectives.push({id,conversationId:cid,runId:standalone?runId(prefix+'-objective.log'):flightRun,
    submission:standalone?'standalone-after-flight-stop':'flight-step',stepStatus:step.status,outerStatus:root.objectiveFulfillment,
    wallMs:metrics.wallMs,metrics,sameTypedStateAsRehearsal:true,verification,independent,
    readbackRun:runId(prefix+'-readback.log'),artifactReadRun:runId(prefix+'-artifact.log')});
}
history.closureExecution={planDigest:flight.planDigest,flightRun,flightRecordingId:flight.flightRecordingId,
  approvalRun:runId(join(work,'closure-approval.log')),approvalDigest:clearance.requirements.find(r=>r.requirement==='OWNER_APPROVAL').evidenceDigest,
  status:flight.status,verdict:closure.verdict,executionDigest:closure.executionDigest,closedCount:closure.closedCount,obligationCount:closure.obligationCount,
  passedCount:closure.passedCount,plannedCount:closure.plannedCount,obligations:closure.obligations,steps:flight.steps.map(s=>({id:s.stepId,status:s.status,actual:s.actual})),
  reportDigest:sha(readFileSync(file('closure-report.md'))),reviewChecks,objectives};
writeFileSync(evidencePath,JSON.stringify(history,null,2)+'\n');
