import assert from 'node:assert/strict';
import { mkdirSync,writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { batch,ontology } from './classify.mjs';
const ids=['validate-email-address','http-exchange-public','read-python-library-sources','read-iac-tool-version','analysis-draw-seeded-range','parse-csharp-source'];
const rows=ids.map((id,i)=>{
  const e=ontology.find(e=>e.ns==='sidefx:capabilities'&&e.id===id);
  assert.ok(e);
  return {id:'control_'+i+'#1',module:id,rank:1,use:e.intent,operation:e.intent};
});
const q=batch(rows);
for (const [i,id] of ids.entries()){
  assert.ok(q.state.cases['u'+(i+1)].candidates.some(k=>q.state.declarations[k].id===id));
}
const dir=process.argv[2];mkdirSync(dir,{recursive:true});
writeFileSync(join(dir,'batch-0000.json'),JSON.stringify(q));
