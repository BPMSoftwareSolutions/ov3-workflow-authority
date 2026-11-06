import assert from 'node:assert/strict';
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { cases,proposals,criteria,catalogDigest,ontologyDigest,ontology,validate,sha } from './classify.mjs';
const [useDir,opDir,output,controlDir]=process.argv.slice(2);
if(!controlDir)throw Error('Pass use-case work directory, operation work directory, output directory and control work directory');
const read=(path)=>JSON.parse(readFileSync(path,'utf8'));
const labels=Object.keys(criteria);
const tally=()=>Object.fromEntries(labels.map(x=>[x,0]));
function collect(dir,source){
  const sourceMap=new Map(source.map(c=>[c.id,c]));
  const rows=[],runs=[],seen=new Set(),counts=tally();
  for(const name of readdirSync(join(dir,'requests')).filter(n=>n.endsWith('.json')).sort()){
    const q=read(join(dir,'requests',name));
    assert.equal(q.context.inputDigest,sha(JSON.stringify(q.state)));
    assert.equal(q.state.ontologyDigest,ontologyDigest);assert.equal(q.state.catalogDigest,catalogDigest);
    const r=read(join(dir,'answers',name));
    assert.match(r.runId,/^[a-f0-9-]{36}$/);assert.ok(r.answer.usage.input_tokens>0 && r.answer.usage.output_tokens>0);
    const decisions=validate(q,r.answer);
    for(const decision of decisions){
      const c=sourceMap.get(decision.id);
      assert.ok(c&&!seen.has(c.id));seen.add(c.id);counts[decision.classification]++;
      const refs=decision.candidates.map(k=>{const e=ontology[Number(k.slice(1))];assert.equal(q.state.declarations[k].id,e.id);return e.ns+'/'+e.id});
      rows.push({...decision,candidates:refs,module:c.module,statement:c.use,sourcePageDigest:c.pageDigest,runId:r.runId,model:r.answer.model});
    }
    runs.push({id:r.runId,model:r.answer.model,batch:name,decisions:decisions.length,inputDigest:q.context.inputDigest,
      wallMs:r.wallMs,inputTokens:r.answer.usage.input_tokens,outputTokens:r.answer.usage.output_tokens});
  }
  assert.equal(seen.size,source.length);
  const totals={calls:runs.length,inputTokens:runs.reduce((n,r)=>n+r.inputTokens,0),outputTokens:runs.reduce((n,r)=>n+r.outputTokens,0)};
  return {rows,runs,counts,totals};
}
const uses=collect(useDir,cases),ops=collect(opDir,proposals);
const controlRequest=read(join(controlDir,'requests','batch-0000.json'));
const controlResponse=read(join(controlDir,'answers','batch-0000.json'));
const controls=validate(controlRequest,controlResponse.answer).map((d,i)=>({identity:controlRequest.state.cases['u'+(i+1)].module,
  expected:'REUSE',actual:d.classification,confidence:d.confidence,probability:d.probabilities.REUSE}));
const probes=read(join(output,'python-cultivation-probes.json'));
assert.deepEqual(probes.seeded[0].result.rows,probes.seeded[1].result.rows);
assert.deepEqual(probes.seeded[0].result.rows.map(x=>x.value),[74,59,46,62]);
assert.equal(probes.head.result.httpStatus,200);
assert.equal(probes.head.result.contentType,'text/html');
assert.equal(probes.head.result.responseBodyText,'');
const reviewRows=file=>readFileSync(new URL(file,import.meta.url),'utf8').trim().split(/\r?\n/).slice(1)
  .map(line=>{const [index,id,label,evidence]=line.split('\t');return {index:+index,id,label,evidence}});
const review=reviewRows('blind-review.tsv');
const sample=read(join(useDir,'blind-sample.json'));
assert.deepEqual(review.map(r=>r.id),sample.sample.map(r=>r.id));
const matrix=Object.fromEntries(labels.map(x=>[x,tally()]));
const lookup=new Map(uses.rows.map(r=>[r.id,r]));
const comparisons=review.map(r=>{
  const actual=lookup.get(r.id);matrix[r.label][actual.classification]++;
  return {...r,jev:actual.classification,confidence:actual.confidence,probability:actual.probabilities[actual.classification],
    correct:r.label===actual.classification,runId:actual.runId};
});
const correct=comparisons.filter(r=>r.correct).length;
const alwaysNew=comparisons.filter(r=>r.label==='NEW_MECHANIC_CANDIDATE').length;
const expectedWitnesses={
  'io#2':['sidefx:mechanics/array','sidefx:mechanics/join'],
  'contextlib#3':['sidefx:mechanics/array','sidefx:capabilities/sql-database-reader'],
  'random#5':['sidefx:capabilities/analysis-draw-seeded-range']
};
const retrievalAudit=Object.entries(expectedWitnesses).map(([id,witnesses])=>({id,witnesses,
  missing:witnesses.filter(w=>!lookup.get(id).candidates.includes(w)),modelLabel:lookup.get(id).classification}));
const opSeed=sha(catalogDigest+'|'+ontologyDigest+'|blind-operation-sample-v1');
const opReview=reviewRows('operation-review.tsv');
assert.deepEqual(opReview.map(r=>r.id),[...proposals].sort((a,b)=>sha(opSeed+a.id).localeCompare(sha(opSeed+b.id))).slice(0,24).map(c=>c.id));
const opLookup=new Map(ops.rows.map(r=>[r.id,r]));
const gapsByPackage={};
for(const r of ops.rows.filter(r=>r.classification==='NEW_MECHANIC_CANDIDATE')){
  const family=r.module.split('.')[0];
  gapsByPackage[family]=(gapsByPackage[family]??0)+1;
}
const familyCounts=Object.entries(gapsByPackage).sort((a,b)=>b[1]-a[1]||a[0].localeCompare(b[0]));
const opComparisons=opReview.map(r=>({...r,jev:opLookup.get(r.id).classification,correct:r.label===opLookup.get(r.id).classification,runId:opLookup.get(r.id).runId}));
const opCorrect=opComparisons.filter(r=>r.correct).length;
const positiveAudit=[
  {id:'html#operation',finding:'The shortlist contains the subordinate escape-html mechanic. Its public candidates do not supply the optional quote behavior and length metadata as a complete callable contract.'},
  {id:'textwrap#operation',finding:'The snapshot includes the partially installed python-textwrap identity, marked NON_CONFORMANT, and three records for its same binding. The pilot accepts text and width. The full proposal has additional TextWrapper options. Multiple records for one binding do not establish a runnable composition.'}
].map(x=>({...x,modelLabel:opLookup.get(x.id).classification,runId:opLookup.get(x.id).runId,decision:'REQUIRES_REVIEW'}));
assert.deepEqual(ops.rows.filter(r=>r.classification==='REUSE'||r.classification==='COMPOSE').map(r=>r.id).sort(),
  positiveAudit.map(x=>x.id).sort(),'Review every positive operation before reporting');
function wilson(k,n){if(!n)return null;const z=1.96,p=k/n,d=1+z*z/n,h=z*Math.sqrt(p*(1-p)/n+z*z/(4*n*n));
  return [(p+z*z/(2*n)-h)/d,(p+z*z/(2*n)+h)/d].map(x=>Math.round(10000*x)/100);}
const byClass=labels.map(label=>{
  const p=comparisons.filter(r=>r.jev===label),g=comparisons.filter(r=>r.label===label),k=p.filter(r=>r.correct).length;
  return {label,predicted:p.length,reviewedAs:g.length,correct:k,precision:p.length?k/p.length:null,recall:g.length?k/g.length:null,precision95:wilson(k,p.length)};
});
const confidenceBins=[[0,.7],[.7,.9],[.9,1.01]].map(([lo,hi])=>{
  const b=comparisons.filter(r=>r.probability>=lo&&r.probability<hi);
  return {from:lo,to:Math.min(1,hi),count:b.length,correct:b.filter(r=>r.correct).length};
});
const measurement={catalogDigest,ontologyDigest,ontologySize:ontology.length,mode:'ADVISORY_ONLY',useCases:{counts:uses.counts,...uses.totals},
  operations:{counts:ops.counts,...ops.totals,candidateOperationsByTopLevelPythonPackage:Object.fromEntries(familyCounts)},independentReview:{size:review.length,correct,alwaysNewCorrect:alwaysNew,agreement95:wilson(correct,review.length),
    sampleMethod:sample.method,sampleSeed:sample.seed,byClass,confidenceBins,matrix,comparisons,retrievalAudit},
  independentOperationReview:{size:24,correct:opCorrect,agreement95:wilson(opCorrect,24),sampleSeed:opSeed,comparisons:opComparisons},
  positiveOperationAudit:positiveAudit,
  liveWitnesses:{seededFixture:probes.seeded.map(p=>p.runId),head:probes.head.runId},
  directIdentityControls:{runId:controlResponse.runId,model:controlResponse.answer.model,usage:controlResponse.answer.usage,rows:controls},
  batches:[...uses.runs.map(r=>({...r,population:'use_case'})),...ops.runs.map(r=>({...r,population:'operation'}))]};
writeFileSync(join(output,'python-cultivation-decisions.jsonl'),[...uses.rows,...ops.rows].map(r=>JSON.stringify(r)).join('\n')+'\n');
writeFileSync(join(output,'python-cultivation-measurements.json'),JSON.stringify(measurement,null,2)+'\n');
const table=labels.map(label=>'| `'+label+'` | '+uses.counts[label]+' | '+ops.counts[label]+' |').join('\n');
const interval=measurement.independentReview.agreement95;
const source=readFileSync(new URL('../../outputs/python-cultivation-ontology.json',import.meta.url),'utf8');
const report=['# Python capability cultivation','',
  'Jev classified 1,485 ranked uses and, separately, all 297 bounded provider proposals against '+ontology.length+' selected estate declarations captured at '+JSON.parse(source).capturedAt+'.','',
  '| Advisory classification | Use cases | Proposed operations |','| --- | ---: | ---: |',table,'',
  'The operation column answers the binding-level question directly. Each candidate label identifies a gap to investigate in the retrieved records. Several proposals can share one gap. The number of unique new mechanics required is unproved.','',
  'The '+ops.counts.NEW_MECHANIC_CANDIDATE+' candidate operations span '+familyCounts.length+' top-level Python package names. The largest groups are '+familyCounts.slice(0,5).map(([n,c])=>'`'+n+'` ('+c+')').join(', ')+'. Package membership identifies places to examine shared needs without assuming all members need the same mechanic.','',
  'Both positive operation labels were checked against their specific retrieved identities.','',...positiveAudit.map(x=>'- `'+x.id+'` ('+x.modelLabel+'). '+x.finding),'',
  '## Independent review','',
  'A blinded Codex review selected ten uses per rank by seeded hash, searched the full ontology, and inspected selected contracts. It agreed with Jev on '+correct+' of '+review.length+' uses ('+(correct*100/review.length).toFixed(1)+'%, approximate 95% Wilson interval '+interval[0]+'–'+interval[1]+'%). The interval describes this finite sample approximately and does not establish class-specific reliability.','',
  'For comparison, always choosing NEW_MECHANIC_CANDIDATE would agree on '+alwaysNew+' of the same '+review.length+' cases.','',
  '| Class | Jev choices in sample | Reviewer choices | Agreements |','| --- | ---: | ---: | ---: |',
  ...byClass.map(x=>'| '+x.label+' | '+x.predicted+' | '+x.reviewedAs+' | '+x.correct+' |'),'',
  ...comparisons.filter(r=>!r.correct).map(r=>'- `'+r.id+'` received '+r.jev+' from Jev and '+r.label+' on independent review. '+r.evidence),'',
  'For the three reviewed uses judged realizable from existing declarations, '+retrievalAudit.filter(x=>x.missing.length===0).length+' of three shortlists contained every witness identified by the reviewer. The stored shortlists allow retrieval misses to be distinguished from decisions made with the relevant declaration in view.','',
  'Two further read-only probes checked the disputed seeded-fixture judgment and an HTTP reuse case. Jev received analysis-draw-seeded-range for random#5 and selected NEW_MECHANIC_CANDIDATE. Two independent live calls with seed 42 both produced [74, 59, 46, 62], verifying reproducible integer fixtures. The separate random binding proposal requires sampling arbitrary items without replacement and returning Python generator state. A live http-exchange-public HEAD request returned HTTP 200, content type text/html and an empty body, supporting the reachability and content-type examples in http.client#1 and http.client#5. The probe receipts preserve the exact requests and provider returns.','',
  'A separate blind sample of 24 proposed operations agreed on '+opCorrect+' of 24. The measurement file records the evidence and label for every reviewed operation.','',
  'In a separate retrieval-friendly control, Jev called '+controls.filter(x=>x.actual==='REUSE').length+' of '+controls.length+' existing capabilities REUSE when their own declared intents were supplied verbatim. These controls are excluded from both populations and the blind-sample accuracy.','',
  '## Usage and evidence','',
  '| Population | Jev calls | Input tokens | Output tokens |','| --- | ---: | ---: | ---: |',
  '| Ranked uses | '+uses.totals.calls+' | '+uses.totals.inputTokens+' | '+uses.totals.outputTokens+' |',
  '| Proposed operations | '+ops.totals.calls+' | '+ops.totals.inputTokens+' | '+ops.totals.outputTokens+' |','',
  'The evidence ledger identifies every case, candidate shortlist, Jev version, probability vector, input digest and retained API run. The measurement file contains the full sample review, confusion matrix, calibration bins and batch usage. Billing and a frontier-model cost baseline were not observed.','',
  'All classifications remain advisory. The lexical shortlist included at most four public capabilities and four subordinate declarations. Missing vocabulary or missing contract detail can hide viable reuse. A matching label provides no executable composition or admission receipt.',''];
writeFileSync(join(output,'python-cultivation-report.md'),report.join('\n'));
console.log(JSON.stringify({uses:uses.counts,operations:ops.counts,correct,sampleSize:review.length}));
