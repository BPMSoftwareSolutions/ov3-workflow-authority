import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

export const sha=b=>'sha256:'+createHash('sha256').update(b).digest('hex');
const files=new URL('../../outputs/',import.meta.url);
const pinned=(name,digest)=>{
  const b=readFileSync(new URL(name,files));
  assert.equal(sha(b),digest,'Unrecognized '+name);
  return b.toString('utf8');
};
export const catalogDigest='sha256:94a77a826d7822419a8fe8c2d00275048a541c1a1d6aff4f753835abcad0c966';
export const ontologyDigest='sha256:a98cbad964200f7728867077ea99f4e009cd3da38c8d071a0a0da1fdfecdd050';
export const ontology=JSON.parse(pinned('python-cultivation-ontology.json',ontologyDigest)).entries;
export const cases=pinned('python-library-provider-report.md',catalogDigest).split(/^## /m).flatMap(section=>{
  if(!section.includes('**Ranked use cases**')) return [];
  const module=section.split(/\r?\n/)[0];
  const sectionInfo=section.match(/\[Python documentation\]\([^)]+\)\s+([\s\S]*?)\s+\*\*APIs\*\*/);
  const pageDigest=section.match(/Source digest `(sha256:[a-f0-9]{64})`/)[1];
  const use=section.split('**Ranked use cases**')[1].split(/\n\s*\n/)[0];
  const ranked=[...use.matchAll(/^(\d+)\. (.+)$/gm)];
  assert.equal(ranked.length,5,module);
  return ranked.map(([,rank,s])=>({id:module+'#'+rank,module,rank:+rank,use:s.trim(),operation:sectionInfo[1].trim(),pageDigest}));
});
assert.equal(cases.length,1485);
assert.equal(new Set(cases.map(c=>c.id)).size,1485);
assert.equal(new Set(cases.map(c=>c.module)).size,297);
export const proposals=cases.filter(c=>c.rank===1).map(c=>({...c,id:c.module+'#operation',use:c.operation}));
const feature=readFileSync(new URL('classify-capability-cultivation.feature',import.meta.url),'utf8');
export const criteria=Object.fromEntries([...feature.matchAll(/^\s*\| ([A-Z_]+) \| ([^|]+?) \|$/gm)].map(m=>m.slice(1,3)));
assert.deepEqual(Object.keys(criteria),['REUSE','COMPOSE','NEW_MECHANIC_CANDIDATE','UNRESOLVED']);
const stop=new Set(('a an the of for in to on by through from or and as with into each using use used this that can capability capabilities estate returned declared returns result when their is are be its it apply which request input output data model system').split(' '));
function words(text) {
  return (text.toLowerCase().match(/[a-z0-9]+/g)??[]).map(w=>w.length>5?w.replace(/(?:ing|ed|s)$/,''):w).filter(w=>w.length>1&&!stop.has(w));
}
const docs=ontology.map(e=>words([e.id,e.id,e.id,e.intent,e.outcome??'',e.inputContract??'',e.outputContract??''].join(' ')));
const df=new Map(), counts=docs.map(tokens=>{
  const c=new Map(); for(const t of tokens)c.set(t,(c.get(t)??0)+1);
  for(const t of c.keys())df.set(t,(df.get(t)??0)+1);
  return c;
});
const mean=docs.reduce((n,t)=>n+t.length,0)/docs.length;
export function candidates(c) {
  const q=[...new Set(words(c.use+' '+c.module))], op=[...new Set(words(c.operation))];
  const hits=ontology.map((e,i)=>{
    function score(tokens) {return tokens.reduce((n,t)=>{
      const tf=counts[i].get(t)??0;
      return !tf?n:n+Math.log(1+(ontology.length-df.get(t)+0.5)/(df.get(t)+0.5))*tf*2.2/(tf+1.2*(0.25+0.75*docs[i].length/mean));
    },0);}
    return {i,score:score(q)+0.35*score(op)};
  }).filter(h=>h.score>0).sort((a,b)=>b.score-a.score||a.i-b.i);
  const publicHits=hits.filter(h=>ontology[h.i].ns==='sidefx:capabilities').slice(0,4);
  const otherHits=hits.filter(h=>ontology[h.i].ns!=='sidefx:capabilities').slice(0,4);
  return [...publicHits,...otherHits].map(h=>h.i);
}
const directions='Assess this specific ranked use case against only its retrieved declarations. A research proposal, general-purpose SQL, language runtime, code writer or model does not itself implement an arbitrary operation. Do not infer authority, implementation, compatibility or availability from a name. Choose UNRESOLVED when the evidence is inadequate.';
export function batch(rows) {
  const records={},work={},questions={};
  for(const [i,row] of rows.entries()){
    const ids=candidates(row);
    const key='u'+(i+1);
    work[key]={useCaseId:row.id,module:row.module,useCase:row.use,proposedOperation:row.operation.slice(0,420),candidates:ids.map(i=>'d'+i)};
    for(const i of ids){
      const e=ontology[i]; records['d'+i]={namespace:e.ns,id:e.id,meaning:e.intent.slice(0,220),...(e.outcome&&{outcome:e.outcome.slice(0,150)}),...(e.inputContract&&{input:e.inputContract}),...(e.outputContract&&{output:e.outputContract}),
        ...(e.id==='python-textwrap'&&{availability:'NON_CONFORMANT at snapshot: missing provider display label'})};
    }
    questions[key]={type:'choice',instructions:'Select the disposition for state.cases.'+key+' under the shared decision rule.',criteria};
  }
  const state={contractId:'capability-cultivation-state.v1',ontologyDigest,catalogDigest,
    ...(rows[0].id.endsWith('#operation')&&{decisionSubject:'proposed_operation'}),
    decisionRule:directions,cases:work,declarations:records};
  return {state,questions,context:{inputDigest:sha(JSON.stringify(state))}};
}
export function validate(q,r) {
  assert.equal(r.status,'ANSWERED');
  assert.match(r.model,/^jev-/);
  assert.equal(r.context?.inputDigest,q.context.inputDigest);
  assert.deepEqual(Object.keys(r.answers).sort(),Object.keys(q.questions).sort());
  return Object.entries(r.answers).map(([key,a])=>{
    const allowed=Object.keys(q.questions[key].criteria).sort();
    assert.equal(a.type,'choice');assert.ok(allowed.includes(a.choice));
    assert.deepEqual(Object.keys(a.probabilities).sort(),allowed);
    for(const p of [a.confidence,...Object.values(a.probabilities)])assert.ok(Number.isFinite(p)&&p>=0&&p<=1);
    return {id:q.state.cases[key].useCaseId,classification:a.choice,confidence:a.confidence,probabilities:a.probabilities,
      candidates:q.state.cases[key].candidates,decisionInput:q.context.inputDigest};
  });
}
if(process.argv[1] && pathToFileURL(process.argv[1]).href===import.meta.url){
  const dest=process.argv[2],size=Number(process.argv[3]??5);
  assert.ok(dest && Number.isInteger(size) && size>=1 && size<=20);
  mkdirSync(dest,{recursive:true});
  const population=process.argv[4]==='operations'?proposals:cases;
  for(let i=0;i<population.length;i+=size){
    const req=batch(population.slice(i,i+size));
    writeFileSync(join(dest,'batch-'+String(i).padStart(4,'0')+'.json'),JSON.stringify(req));
  }
  console.log(population.length,'decisions;',Math.ceil(population.length/size),'batches');
}
