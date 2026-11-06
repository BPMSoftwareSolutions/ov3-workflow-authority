import { readFileSync, writeFileSync } from 'node:fs';
import { brotliDecompressSync } from 'node:zlib';

// Accept the CLI evidence envelope or the declared API's retained chunk response.
const [tracePath, evidencePath, outputPath, nestedCapability]=process.argv.slice(2);
const read=path=>JSON.parse(readFileSync(path,'utf8'));
const trace=read(tracePath), evidence=read(evidencePath);
let events=trace.events;
if(!events && Array.isArray(trace.chunks)){
  events=trace.chunks.flatMap(ch=>JSON.parse(brotliDecompressSync(Buffer.from(ch.content,'base64'))));
}
if(!Array.isArray(events)||!events.length)throw Error('No retained trace events');
let ordered=events.toSorted((a,b)=>a.cursor-b.cursor);
const complete=ordered.at(-1).kind==='run.exited' && !(trace.gaps?.length) &&
  ordered.every((e,i)=>!i||e.cursor===ordered[i-1].cursor+1);
if(nestedCapability){
  const starts=ordered.filter(e=>e.kind==='nested-capability-invocation.v1' && e.payload.capabilityId===nestedCapability);
  if(starts.length!==1)throw Error('Expected one nested pursuit in this flight');
  const start=starts[0],end=ordered.find(e=>e.cursor>start.cursor && e.kind==='execution-outcome-returned.v1' &&
    e.payload.rootExecutionId===start.payload.rootExecutionId);
  if(!end)throw Error('Missing nested pursuit return');
  ordered=ordered.filter(e=>e.cursor>=start.cursor && e.cursor<=end.cursor);
}
const cells=ordered.filter(e=>e.payload?.testimonyType==='cell-execution-testimony.v1').map(e=>e.payload);
const specific=(id)=>cells.filter(c=>c.cellId==='cell:mechanic:'+id);
const planners=specific('request-capability-from-objective-v3.model');
const jev=specific('ask-system-one.exchange');
const verification=evidence.verification;
const admission=ordered.find(e=>e.kind==='nested-capability-invocation.v1' && e.payload.capabilityId==='verify-objective-fulfillment')?.payload;
const parent=admission&&cells.find(c=>c.cellExecutionId===admission.invokingCellExecutionId);
const verifierUsage=verification?.inference?.usage;
function counts(raw){
  if(!raw||typeof raw!=='object')return null;
  const input=raw.input_tokens??raw.promptTokenCount??raw.inputTokens;
  const output=raw.output_tokens??raw.candidatesTokenCount??raw.outputTokens;
  const total=raw.totalTokenCount??raw.total_tokens??raw.totalTokens;
  if(![input,output,total].some(Number.isFinite))return null;
  return {input:Number.isFinite(input)?input:null,output:Number.isFinite(output)?output:null,
    total:Number.isFinite(total)?total:Number.isFinite(input)&&Number.isFinite(output)?input+output:null};
}
function modelResult(cell){const p=cell.outcomeShape?.payload;return p?.result??p;}
const plannerUsage=planners.map((c,i)=>{
  const result=modelResult(c);
  return {turn:i+1,model:result?.resolvedModel??null,durationMs:c.durationMilliseconds,
    usage:counts(result?.usage??result?.normalizedResponse?.usage??result?.response?.usageMetadata) ??
      counts(evidence.receipts.find(r=>r.turn===i+1)?.usage)};
});
const answers=specific('ask-system-one.answer');
const routingUsage=specific('request-capability-from-objective-v3.intent-decide')[0]?.outcomeShape?.payload?.intent?.usage;
const jevUsage=jev.map((c,index)=>{
  const answer=answers.find(a=>a.rootExecutionId===c.rootExecutionId);
  const verified=Boolean(admission&&c.rootExecutionId?.includes(admission.rootExecutionId));
  return {root:c.rootExecutionId,durationMs:c.durationMilliseconds,verification:verified,
    usage:counts(modelResult(answer??{})?.usage)??(verified?counts(verifierUsage):index===0?counts(routingUsage):null)};
});
const usage=[...plannerUsage,...jevUsage].map(r=>r.usage);
const known=usage.filter(Boolean);
const sum=(key,rows)=>rows.length&&rows.every(r=>Number.isFinite(r?.[key]))?rows.reduce((n,r)=>n+r[key],0):null;
const result={conversationId:evidence.conversationId,objectiveFulfillment:evidence.objectiveFulfillment??null,
  startedAt:evidence.startedAt,endedAt:evidence.endedAt,wallMs:Date.parse(evidence.endedAt)-Date.parse(evidence.startedAt),
  traceComplete:complete,plannerCalls:planners.length,systemOneCalls:jev.length,plannerUsage,systemOneUsage:jevUsage,
  tokenBearingCalls:known.length,knownInputTokens:sum('input',known),knownOutputTokens:sum('output',known),
  totalTokens:complete?sum('total',usage):null,
  verification:{status:verification?.status??null,wallMs:parent?.durationMilliseconds??null,usage:counts(verifierUsage)},
  successfulOperations:[...new Set(evidence.receipts.filter(r=>r.action==='CALL'&&r.disposition==='terminated'&&r.result?.status==='COMPUTED').map(r=>r.capability))]};
writeFileSync(outputPath,JSON.stringify(result,null,2)+'\n');
