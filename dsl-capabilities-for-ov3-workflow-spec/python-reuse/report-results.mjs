import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
import { experiment, file, sha } from './portfolio.mjs';
import { specimen, verify } from './benchmark.mjs';

const [work,outputs]=process.argv.slice(2);
const dir=join(work,'live-benchmark'),files=readdirSync(dir);
const json=p=>JSON.parse(readFileSync(p,'utf8'));
const cases=[];
for(const objectiveFile of files.filter(n=>n.endsWith('-objective.json')).sort()){
  const prefix=objectiveFile.replace(/-objective\.json$/,''),id=prefix.split('-')[0];
  const root=json(join(dir,objectiveFile)), evidencePath=join(dir,prefix+'-evidence.json'), evidence=json(evidencePath);
  assert.equal(root.objective,specimen(id).request);
  const published=Boolean(evidence.contentDigest), cohort=files.includes(prefix+'-request.json')&&json(join(dir,prefix+'-request.json')).visibleCapabilities?'portfolio':'default';
  const metricsPath=join(dir,cohort+'-'+id+'-metrics.json');
  execFileSync(process.execPath,[fileURLToPath(file('measure-run.mjs')),join(dir,cohort+'-'+id+'-trace.json'),evidencePath,metricsPath]);
  const metrics=json(metricsPath);
  const runId=readFileSync(join(dir,prefix+'-objective.log'),'utf8').match(/Run ([0-9a-f-]{36})/i)[1];
  let independent=null,rehearsal=null;
  if(published){
    const bytes=readFileSync(join(dir,prefix+'-artifact.json-bytes'));
    independent=verify(id,evidence,bytes);
    assert.equal(independent.artifactDigest,sha(bytes));
    writeFileSync(join(outputs,'python-reuse-'+id+'.json'),bytes);
    const proof=json(join(work,'typed-proof-'+id+'.json'));
    assert.equal(proof.artifactDigest,independent.artifactDigest);
    assert.equal(proof.conversationId,root.conversationId);
    assert.deepEqual(proof.proofReceipts.map(r=>r.digest),independent.proof.map(r=>r.receiptDigest));
    const timing=json(join(work,'jev-cost.json'))[id];
    rehearsal={status:proof.status,reason:proof.reason,metrics:proof.metrics,inference:proof.inference,
      inferenceExchangeMs:timing.exchangeMs,inferenceRunId:timing.runId,checks:proof.checks};
  }
  cases.push({id,cohort,runId,conversationId:root.conversationId,objectiveFulfillment:root.objectiveFulfillment,
    published,independent,rehearsal,metrics,objectiveTextCorrections:0});
}
const controls=json(join(work,'negative-tests-complete.json'));
assert.equal(controls.length,10);
assert.ok(controls.every(c=>c.outcome.proved===c.name.startsWith('valid-')));
const routingTests={};
for(const [name,runId] of Object.entries({
  'notice-default':'43b53017-322e-672e-6305-d6bfc7d0653b','ledger-default':'235e73fc-091b-603b-89fa-58eae945e961',
  'ledger-explicit':'416cbacc-5a14-70be-ceb0-42cfafb89528','ledger-payload':'f9bfbce5-d38b-f5e7-fae6-ada8a5f4bd34',
  'notice-unranked':'156eeea0-91c3-930c-a8d2-03141b5b7176'})){
  const result=json(join(work,'route-result-'+name+'.json'));
  assert.ok(!Object.hasOwn(result,'leaked'));
  if(name.endsWith('-default')){
    const input=json(join(work,'route-'+name+'.json')).input;
    const first=Object.keys(input.decision.result.answers.tools.probabilities);
    assert.deepEqual(result.visible.slice(0,first.length),first);
    assert.equal(new Set(result.visible).size,result.visible.length);
    assert.ok(result.visible.length<=20);
    for(const id of [...Object.keys(specimen(name.split('-')[0]).required),'publish-python-reuse-result'])assert.ok(result.visible.includes(id));
  }else if(name.endsWith('-explicit'))assert.deepEqual(result.visible,['python-binascii']);
  else if(name.endsWith('-payload'))assert.deepEqual(result.payloadVisible,[]);
  else assert.ok(!Object.hasOwn(result,'visible'));
  routingTests[name]={runId,...result};
}
const preflights={};
for(const [name,runId,filename] of [['routing','9c417110-74a9-6f6f-4ab2-6f9905753c25','routing-rehearsal.json'],
  ['proof','88c98853-bc6e-3817-90b2-f42e5734e784','proof-closure-rehearsal.json']]){
  const results=json(join(work,filename)).result.flat();
  const receipt=results.filter(r=>r.value).map(r=>JSON.parse(r.value)).find(r=>r.contractId==='engineering-change-receipt.v1');
  assert.equal(receipt.disposition,'APPLIED_AND_ROLLED_BACK');
  preflights[name]={runId,sourceDigest:receipt.sourceDigest,disposition:receipt.disposition,observations:results.filter(r=>r.specimen||r.outcome==='VERIFIED')};
}
const report={contractId:'python-reuse-benchmark.v1',source:{catalogDigest:experiment.catalogDigest,
  indexDigest:experiment.moduleIndexDigest,documentationVersion:experiment.documentationVersion},
  cases,controls,routingTests,preflights,proofRuns:{notice:{evidence:'cc0d0664-d06d-a8ef-f145-e138bfbc7a2e',inference:'30093aad-08d4-81d0-b410-c7a8f4f60c8f',decision:'f7dd738c-747b-5a87-56eb-c4d082a9f4b8'},
    ledger:{evidence:'79f0788f-c7bc-9b4b-f7dc-b785a0751f6f',inference:'03581cf0-5bbc-dcc4-01a9-90d1f58a1252',decision:'8dc49eef-9ad2-8c94-b485-a4d4ee97a527'},controls:'2eada794-1633-f5cf-e432-8e2de50f0f2e'}};
const execution=json(join(outputs,'python-reuse-flight-evidence.json')).closureExecution;
if(execution)report.closureExecution=execution;
writeFileSync(join(outputs,'python-reuse-benchmark.json'),JSON.stringify(report,null,2)+'\n');
const lines=['# Python capability reuse benchmark','',
  'OV3 executed five public CPython 3.12.16 bindings on the release notice. A second objective reused three of them on a Unicode ledger with CRLF line endings. Each used the same explicitly supplied six-tool portfolio. An independent byte and receipt check passed on both artifacts. All four original objective records ended `UNVERIFIED`.','',
  '| Objective | Tool selection | Artifact | Frontier / Jev calls | Pursuit time | Known tokens¹ | Verifier dispatch |',
  '| --- | --- | --- | ---: | ---: | ---: | ---: |'];
for(const c of [...cases].sort((a,b)=>a.cohort.localeCompare(b.cohort)||b.id.localeCompare(a.id))){
  const m=c.metrics;
  lines.push('| '+[c.id,c.cohort==='portfolio'?'Same six tools':'Default',c.published?c.independent.proof.length+' operation receipts':'None',
    m.plannerCalls+' / '+m.systemOneCalls,(m.wallMs/1000).toFixed(2)+' s',
    (m.knownInputTokens+m.knownOutputTokens).toLocaleString('en-US')+' ('+m.tokenBearingCalls+'/'+(m.plannerCalls+m.systemOneCalls)+' calls)',
    m.verification.wallMs===null?'—':(m.verification.wallMs/1000).toFixed(2)+' s'].join(' | ')+' |');
}
lines.push('','¹ Known tokens include observed input and output. Each trace covers the whole pursuit, but some model cells omit usage. Total tokens and dollar cost are unknown. Pursuit time is the interval on the estate record. Verifier dispatch measures the enclosing invocation.','',
  '## What changed between runs','',
  'With default discovery, the router used Jev’s first-action ranking to restrict every subsequent turn. The notice could wrap and escape its text. The ledger could encode and hash it. Neither could call the required CRC-32 capability from its selected tools. Neither published.','',
  'For the second pair, the only intervention was supplying the same six admitted MCP identities. Both requests retained their original wording. No tool sequence or expected values were supplied. The ledger reused Base64, CRC-32 and SHA-256, or 3 of its 3 required operations. No new provider was admitted between the two objectives. The different tasks and incomplete token telemetry do not establish cost savings.','',
  '## Byte checks and objective closure','',
  'The notice produced 49 UTF-8 bytes after wrapping and escaping, with CRC-32 `89264376`. The ledger preserved 13 UTF-8 bytes and CRLF, with CRC-32 `ff2987a7`. Its calculated SHA-256 differed from the supplied value. Both retained JSON artifacts and all eight ordered operation receipts passed independent verification. [Notice](python-reuse-notice.json) · [Ledger](python-reuse-ledger.json)','',
  'The installed verifier expected objective bindings on individual calculation receipts. OV3 binds its publication turn. The projected Unicode oracle was also misdecoded. The staged verifier checked the bound publication, immutable preceding turns, exact objective, input bytes, outputs and declared obligations. It accepted both real artifacts and rejected eight altered-evidence cases.','');
for(const c of cases.filter(c=>c.rehearsal)){
  const r=c.rehearsal,inf=r.inference;
  lines.push('- '+c.id+' returned `'+r.status+'` in the staged proof. Jev confidence was '+inf.confidence+' and scope probability was '+inf.scopeProbability+'. The model exchange took '+(r.inferenceExchangeMs/1000).toFixed(2)+' s and used '+inf.usage.input_tokens+' input and '+inf.usage.output_tokens+' output tokens.');
}
lines.push('','These are read-only retrospective decisions. The four historical outer outcomes retain their original dispositions. The source catalog is pinned to Python '+experiment.documentationVersion+'. [Receipts and measurements](python-reuse-benchmark.json) · [Supply flight evidence](python-reuse-flight-evidence.json)','');
if(execution){
  const latest=['## Revision 3 on the live estate','',
    'Flight recording `'+execution.flightRecordingId+'` ended `'+execution.status+'`. OV3 recorded `'+execution.verdict+'` with '+execution.closedCount+' of '+execution.obligationCount+' obligations closed and '+execution.passedCount+' of '+execution.plannedCount+' steps passed.',''];
  for(const run of execution.objectives){
    const proof=run.independent, inf=run.verification?.inference;
    latest.push('- **'+run.id+'** returned `'+(run.outerStatus??run.stepStatus)+'`'+(run.wallMs?' in '+(run.wallMs/1000).toFixed(2)+' s':'')+
      (run.submission==='standalone-after-flight-stop'?' in a separate default pursuit after the flight skipped this step':' within the flight')+'. '+
      (proof?'The independent checker matched the publication bytes and '+proof.proof.length+' operation receipts. ':'')+
      (inf?.usage?'Jev chose the manifest scope with confidence '+inf.confidence+' (minimum '+inf.minimumConfidence+') and probability '+inf.scopeProbability+
        ', using '+inf.usage.input_tokens+' input and '+inf.usage.output_tokens+' output tokens. ':'')+
      (run.conversationId?'Conversation `'+run.conversationId+'`.':''));
  }
  if(execution.objectives.every(run=>run.verification?.checks.every(c=>c.passed))){
    latest.push('','All twelve deterministic checks passed for each publication, including exact equality between the original request and the pinned fixture. The notice had the same typed obligations as the earlier verified notice. Its fresh confidence score was below the declared threshold. The installed verifier therefore held it. The ledger cleared the same threshold.');
  }
  latest.push('','[Executed flight report](../dsl-capabilities-for-ov3-workflow-spec/python-reuse/closure-report.md) · [Execution and objective receipts](python-reuse-flight-evidence.json)','');
  lines.splice(2,0,...latest);
}
writeFileSync(join(outputs,'python-reuse-benchmark.md'),lines.join('\n'));
