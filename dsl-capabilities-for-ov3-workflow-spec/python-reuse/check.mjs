import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { entries, experiment } from './portfolio.mjs';

const engine = process.env.PYTHON || 'python';
function call(name, req) {
  const entry = entries.find(e=>e.name===name);
  const probe = spawnSync(engine,['-I','-S','-B','-c',entry.code],
    {input:JSON.stringify(req),encoding:'utf8',timeout:10000});
  assert.equal(probe.status,0,probe.error?.message || probe.stderr);
  return JSON.parse(probe.stdout);
}
function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for(let bit=0;bit<8;bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}
export function reference(text) {
  const bytes=Buffer.from(text,'utf8');
  return {text,byteCount:bytes.length,base64:bytes.toString('base64'),crc32:crc32(bytes).toString(16).padStart(8,'0'),
    sha256:createHash('sha256').update(bytes).digest('hex')};
}

if (process.argv[1] && import.meta.url === (await import('node:url')).pathToFileURL(process.argv[1]).href) {
  for(const e of entries) {
    const result=call(e.name,e.vector);
    for(const check of e.assertions) {
      const keys=check.path.slice(2).replace(/\[(\d+)\]/g,'.$1').split('.');
      assert.equal(keys.reduce((v,k)=>v[k],result),check.equals);
    }
    assert.equal(call(e.name,{...e.vector,extra:true}).status,'INVALID');
    console.log(e.id,result.runtime.version,'reference passed');
  }
  for(const [op,req] of [['binascii',{data:'Zh=='}],['hashlib',{algorithm:'md5',data:''}],
    ['base64',{data:'x',padded:false}],['html',{text:'🍎'.repeat(1537)}],['textwrap',{text:'x',width:true}]])
    assert.equal(call(op,req).status,'INVALID');
  assert.equal(call('base64',{data:''}).value.encoded,'');
  assert.equal(call('html',{text:'\u0027',quote:false}).value.escaped,'\u0027');
  assert.equal(call('textwrap',{text:''}).value.line_count,0);
  assert.equal(call('binascii',{data:'',initialCrc:4294967295}).value.hex,'ffffffff');
  for(const f of experiment.objectives) {
    let text=f.text;
    if(f.id==='notice'){
      const lines=call('textwrap',{text,width:f.width}).value.lines;
      assert.deepEqual(lines,f.expectedLines);
      text=call('html',{text:lines.join('\n')}).value.escaped;
      assert.equal(text,f.expectedText);
    }
    const expected=reference(f.expectedText ?? f.text);
    const encoded=call('base64',{data:text}).value;
    assert.equal(encoded.inputBytes,expected.byteCount);
    assert.equal(encoded.encoded,expected.base64);
    assert.equal(call('binascii',{data:encoded.encoded}).value.hex,expected.crc32);
    const actual=call('hashlib',{algorithm:'sha256',data:encoded.encoded}).value.hexdigest;
    assert.equal(actual,expected.sha256);
    if(f.id==='ledger') assert.equal(actual===f.claimedSha256,f.expectedMatch);
    console.log(f.id,'independent fixture passed',expected.sha256);
  }
}
