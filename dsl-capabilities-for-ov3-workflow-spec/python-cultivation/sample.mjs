import { cases, catalogDigest, ontologyDigest, ontology, sha } from './classify.mjs';
import { writeFileSync } from 'node:fs';
const seed=sha(catalogDigest+'|'+ontologyDigest+'|blind-rank-sample-v1');
const rows=[1,2,3,4,5].flatMap(rank=>cases.filter(c=>c.rank===rank).map(c=>({c,order:sha(seed+c.id)}))
  .sort((a,b)=>a.order.localeCompare(b.order)).slice(0,10).map(x=>x.c));
const sample=rows.map((c,i)=>({index:i+1,id:c.id,use:c.use,operation:c.operation}));
const output=process.argv[2];
if(!output) throw Error('Pass a path for the blind review sample');
writeFileSync(output,JSON.stringify({seed,method:'10 of 297 per use-case rank by salted SHA-256 order; equal inclusion probability',sample},null,2)+'\n');
if(process.argv[3]==='--list') for(const s of sample)console.log(s.index,s.id,s.use);
if(process.argv[3]==='--find') {
  const query=new RegExp(process.argv[4],'i');
  for(const e of ontology.filter(e=>query.test(e.id)))console.log(e.ns,e.id,e.intent.slice(0,150));
}
