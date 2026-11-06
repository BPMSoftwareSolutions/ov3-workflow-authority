import { readFileSync } from 'node:fs';
const source=readFileSync(new URL('provider-entry.py',import.meta.url),'utf8');
const launcher=readFileSync(new URL('provider-launcher.py',import.meta.url),'utf8');
const literal=value=>({op:'literal',value});
const ref=path=>({op:'path',from:'scope',path});
export const providerId='python-markdown-page-libraries-v1';
export const mechanic=providerId+'-port.v1';
export const interpreter='/usr/local/bin/python3',processType='System.Diagnostics.Process';
// Both languages run the fixed launcher around the fixed entry. The launcher ends the entry at 80 s and always answers
// one JSON object. From C#, coreutils timeout also ends the launcher if it outlives 100 s.
function child(identity){
  const hash=identity.bundleDigest.slice(7);
  if(!/^[a-f0-9]{64}$/.test(hash))throw Error('Missing provider package identity');
  return ['-I','-S','-B','-c',launcher,source.replace('__BUNDLE_SHA256__',hash)];
}
const parameters=[{name:'wire',source:'input',path:'',encoding:'json-text'}];
const result={from:'value',encoding:'json-text'};
export function operation(identity){
  const program=[
    {bind:'system',invocation:'import_module',arguments:[literal('sys')]},
    {bind:'subprocess',invocation:'import_module',arguments:[literal('subprocess')]},
    {bind:'process',invocation:'subprocess.Popen',arguments:[{op:'array',items:[ref('system.executable'),...child(identity).map(literal)]},
      literal(-1),literal(null),literal(-1),literal(-1),literal(-1)]},
    {bind:'bytes',invocation:'wire.encode',arguments:[literal('utf-8')]},
    {bind:'streams',invocation:'process.communicate',arguments:[ref('bytes'),literal(100)]},
    {bind:'stdout',invocation:'streams.$computed.$read',selector:literal(0)},
    {bind:'value',invocation:'stdout.decode',arguments:[literal('utf-8')]}];
  return {operationId:'transform',parameters,result,program};
}
export function csharpOperation(identity){
  const invoke=(invocation,...args)=>({invocation,...(args.length&&{arguments:args})});
  const program=[
    {bind:'start',invocation:'new System.Diagnostics.ProcessStartInfo, System.Diagnostics.Process'},
    invoke('start.FileName.$write',literal('/usr/bin/timeout')),
    invoke('start.UseShellExecute.$write',literal(false)),invoke('start.Environment.Clear'),
    ...['--kill-after=5','100',interpreter,...child(identity)].map(s=>invoke('start.ArgumentList.Add',literal(s))),
    invoke('start.RedirectStandardInput.$write',literal(true)),invoke('start.RedirectStandardOutput.$write',literal(true)),
    {bind:'process',invocation:'new System.Diagnostics.Process, System.Diagnostics.Process',release:{invocation:'process.Dispose'}},
    invoke('process.StartInfo.$write',ref('start')),invoke('process.Start'),
    invoke('process.StandardInput.Write',ref('wire')),invoke('process.StandardInput.Close'),
    {bind:'value',invocation:'process.StandardOutput.ReadToEnd'},invoke('process.WaitForExit')];
  return {operationId:'transform',parameters,result,program};
}
export const entry=identity=>({providerProfileId:providerId,language:'python',module:'importlib',export:'import_module',
  effectClassification:'observation',operations:[operation(identity)]});
export const csharpEntry=identity=>({providerProfileId:providerId,language:'csharp',type:processType,assembly:processType,
  method:'.ctor',factory:true,effectClassification:'observation',operations:[csharpOperation(identity)]});
