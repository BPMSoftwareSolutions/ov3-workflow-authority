import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { experiment, sha } from './portfolio.mjs';
import { reference } from './check.mjs';

export function specimen(id) {
  const f=experiment.objectives.find(f=>f.id===id);
  if(!f) throw Error('Expected notice or ledger');
  const expected=reference(f.expectedText ?? f.text);
  const manifest={specimen:id,...expected};
  if(id==='ledger') {
    manifest.claimedSha256=f.claimedSha256;
    manifest.matches=expected.sha256===f.claimedSha256;
  }
  const request=f.request+' Input text as a JSON string: '+JSON.stringify(f.text)+
    (f.claimedSha256?' Supplied SHA-256: '+f.claimedSha256+'.':'')+
    ' Use the admitted Python capabilities for each operation. Publish one JSON artifact and return its receipt.';
  const required={};
  if(id==='notice'){
    required['python-textwrap']={input:{text:f.text,width:f.width},value:{lines:f.expectedLines,line_count:f.expectedLines.length}};
    required['python-html']={input:{text:f.expectedLines.join('\n')},value:{escaped:expected.text,quoteApplied:true}};
  }
  required['python-base64']={input:{data:expected.text},value:{encoded:expected.base64,inputBytes:expected.byteCount,padded:true,wrapcol:0}};
  required['python-binascii']={input:{data:expected.base64},value:{hex:expected.crc32,crc:parseInt(expected.crc32,16),byteLength:expected.byteCount}};
  required['python-hashlib']={input:{data:expected.base64,algorithm:'sha256'},value:{algorithm:'sha256',hexdigest:expected.sha256,digestSize:32,blockSize:64}};
  return {request,manifest,required,sourceDigest:sha(Buffer.from(f.text,'utf8'))};
}
// Independent readback: artifactBytes come from the retained content object; receipts from
// hash-checked CALL turns in the named conversation. Reject missing or foreign receipts.
export function verify(id, evidence, artifactBytes) {
  const {request,manifest,required}=specimen(id);
  assert.equal(evidence.objective,request);
  assert.equal(sha(artifactBytes),evidence.contentDigest);
  assert.deepEqual(JSON.parse(artifactBytes),manifest);
  const proof=[];
  let previousTurn=0,encodingTurn=0;
  for(const [cap,{input,value}] of Object.entries(required)){
    const predecessor=['python-binascii','python-hashlib'].includes(cap)?encodingTurn:previousTurn;
    const row=evidence.receipts.find(row=>row.conversationId===evidence.conversationId &&
      row.capability===cap && row.turn>predecessor && row.action==='CALL' && row.disposition==='terminated' &&
      row.result?.status==='COMPUTED' && row.result.contractId===cap+'-result.v1' &&
      row.result.runtime?.implementation==='cpython' && /^\d+\.\d+\.\d+$/.test(row.result.runtime.version) &&
      subset(row.input,input) && subset(row.result.value,value) && /^sha256:[a-f0-9]{64}$/.test(row.receiptDigest));
    assert.ok(row,'Missing matching live CALL for '+cap);
    proof.push({capability:cap,turn:row.turn,receiptDigest:row.receiptDigest,runtime:row.result.runtime});
    previousTurn=row.turn;
    if(cap==='python-base64')encodingTurn=row.turn;
  }
  return {artifactDigest:evidence.contentDigest,proof};
}
function subset(actual,expected) {
  return actual && Object.keys(expected).every(key=>{
    try{assert.deepEqual(actual[key],expected[key]);return true;}catch{return false;}
  });
}
if(process.argv[1] && pathToFileURL(process.argv[1]).href===import.meta.url){
  const [action,id,record,artifact]=process.argv.slice(2);
  const result=action==='specimen'?specimen(id):action==='verify'?
    verify(id,JSON.parse(readFileSync(record,'utf8')),readFileSync(artifact)):null;
  if(!result) throw Error('Use specimen <id> or verify <id> <live evidence JSON> <artifact file>');
  console.log(JSON.stringify(result,null,2));
}
