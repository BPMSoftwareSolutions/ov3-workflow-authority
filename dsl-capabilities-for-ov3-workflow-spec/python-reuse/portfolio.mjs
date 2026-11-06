import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';

export const file = name => new URL(name, import.meta.url);
export const read = name => readFileSync(file(name), 'utf8');
export const sha = bytes => 'sha256:' + createHash('sha256').update(bytes).digest('hex');
export const experiment = JSON.parse(read('experiment.json'));
const report = readFileSync(file('../../outputs/python-library-provider-report.md'));
if (sha(report) !== experiment.catalogDigest) throw Error('Catalog has changed');
const sections = report.toString('utf8').split(/^## /m);
const schemas = {
  textwrap: {width:{type:'integer',minimum:1,maximum:256}},
  html: {quote:{type:'boolean'}},
  base64: {padded:{const:true},wrapcol:{const:0}},
  binascii: {initialCrc:{type:'integer',minimum:0,maximum:4294967295}},
  hashlib: {algorithm:{const:'sha256'},usedforsecurity:{const:true}}
};
export const entries = Object.entries(schemas).map(([name, options]) => {
  const section = sections.find(s => s.startsWith(name+'\r\n') || s.startsWith(name+'\n'));
  const [catalogInput, catalogOutput] = [...section.matchAll(/```json\s+(.+?)\s+```/gs)].map(m=>JSON.parse(m[1]));
  const id = 'python-'+name, dependency = 'cpython-'+name+'-bounded-v1';
  const feature = read(id+'.feature');
  const valueKey = Object.hasOwn(catalogInput.properties,'text') ? 'text' : 'data';
  const input = {type:'object',additionalProperties:false,required:catalogInput.required,properties:{
    [valueKey]:{type:'string',maxLength:['hashlib','binascii'].includes(name)?8192:6144},...options}};
  const runtime = {type:'object',required:['implementation','version'],additionalProperties:false,
    properties:{implementation:{const:'cpython'},version:{type:'string',pattern:'^[0-9]+[.][0-9]+[.][0-9]+$'}}};
  const contract = feature.match(/^@outcome-contract:(\S+)/m)[1];
  const output = {type:'object',required:['contractId','runtime','status'],additionalProperties:false,
    properties:{contractId:{const:contract},status:{enum:['COMPUTED','INVALID']},runtime,value:catalogOutput,reason:{const:'OUTSIDE_BOUNDED_CONTRACT'}},
    oneOf:[{required:['value'],properties:{status:{const:'COMPUTED'}},not:{required:['reason']}},
           {required:['reason'],properties:{status:{const:'INVALID'}},not:{required:['value']}}]};
  const mechanic = dependency+'-port.v1';
  const title = feature.match(/^Feature: (.+)$/m)[1].trim();
  const assertions = [...feature.matchAll(/^\s*\| [\w.-]+ \| (\$[^ ]+) \| (.+?) \|/gm)].map(m=>({path:m[1],equals:m[2]}));
  const source = {catalogDigest:experiment.catalogDigest,moduleIndexDigest:experiment.moduleIndexDigest,
    documentationVersion:experiment.documentationVersion,url:section.match(/\[Python documentation\]\(([^)]+)\)/)[1],
    pageDigest:section.match(/Source digest `(sha256:[a-f0-9]{64})`/)[1]};
  const dsl = ['capability '+id,'feature '+id+' '+sha(feature),'intent: '+title,
    'outcome: A typed computation receipt with the executing Python version, or INVALID.',
    'inquiry: '+title+' using the admitted Python standard library provider.',
    'input contract '+id+'-request.v1 '+JSON.stringify(input),'output contract '+contract+' '+JSON.stringify(output),
    'cli display outcome as json','scenario '+id+' root terminal','variants: COMPUTED:success,INVALID:failure',
    ...['Given','When','Then'].map(k=>k.toLowerCase()+': '+feature.match(new RegExp('^    '+k+' (.+)$','m'))[1].trim()),
    'operation '+id+'.compute kind invoke-port port '+id+'-compute','platform bind '+id+'-compute','platform: '+mechanic,
    'config: '+JSON.stringify({providerId:dependency,dependency:{objectKind:'DEPENDENCY',namespace:'sidefx:dependencies',id:dependency}}),''].join('\n');
  const code = read('operation.py').replace('OPERATION = "__OPERATION__"','OPERATION = '+JSON.stringify(name));
  return {name,id,dependency,mechanic,source,feature,dsl,input,output,title,code,assertions,
    vector:JSON.parse(feature.match(/"""json\s+(.+?)\s+"""/s)[1])};
});

export function operationProgram(entry) {
  const literal = value => ({op:'literal',value});
  const ref = path => ({op:'path',from:'scope',path});
  const invoke = (invocation, ...args) => ({invocation,...(args.length && {arguments:args})});
  return {operationId:'compute',parameters:[{name:'wire',source:'input',path:'',encoding:'json-text'}],
    result:{from:'value',encoding:'json-text'},program:[
      {bind:'start',invocation:'new System.Diagnostics.ProcessStartInfo, System.Diagnostics.Process'},
      invoke('start.FileName.$write',literal('/usr/local/bin/python3')),
      invoke('start.UseShellExecute.$write',literal(false)),invoke('start.Environment.Clear'),
      ...['-I','-S','-B','-c',entry.code].map(s=>invoke('start.ArgumentList.Add',literal(s))),
      invoke('start.RedirectStandardInput.$write',literal(true)),invoke('start.RedirectStandardOutput.$write',literal(true)),
      {bind:'process',invocation:'new System.Diagnostics.Process, System.Diagnostics.Process',release:{invocation:'process.Dispose'}},
      invoke('process.StartInfo.$write',ref('start')),invoke('process.Start'),
      invoke('process.StandardInput.Write',ref('wire')),invoke('process.StandardInput.Close'),
      {bind:'value',invocation:'process.StandardOutput.ReadToEnd'},invoke('process.WaitForExit')
    ]};
}
