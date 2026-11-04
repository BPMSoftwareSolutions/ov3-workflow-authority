import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { providerId,mechanic } from './native-profile.mjs';
export const dir=new URL('./',import.meta.url);
export const read=name=>readFileSync(new URL(name,dir),'utf8');
export const hash=text=>'sha256:'+createHash('sha256').update(text).digest('hex');
export const identity=JSON.parse(read('provider-identity.json'));
export const page='render-markdown-html-page',leaf='python-markdown-page-operation';
const digest={type:'string',pattern:'^sha256:[0-9a-f]{64}$'};
const object=(properties,required=Object.keys(properties))=>({type:'object',properties,required,additionalProperties:false});
const request=object({markdown:{type:'string',minLength:1,maxLength:2097152},sourceDigest:digest,title:{type:'string',minLength:1,maxLength:200},
  lang:{type:'string',pattern:'^[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*$'},profile:{const:'technical-report-v1'},
  filename:{type:'string',pattern:'^[A-Za-z0-9][A-Za-z0-9_-]{0,95}\\.html$'}},['title','lang','profile','filename']);
request.oneOf=[{required:['markdown']},{required:['sourceDigest']}];
const wire=object({phase:{enum:['render','verify']},bundle:{type:'string',maxLength:2000000},inputDigest:digest,
  request:{type:'object'},html:{type:'string',maxLength:6291456},receipt:{type:'object'}});
const result={type:'object',required:['status'],oneOf:[
  {properties:{status:{const:'RENDERED'},html:{type:'string'},sourceDigest:digest,outputDigest:digest},required:['html','sourceDigest','outputDigest','renderer']},
  {properties:{status:{const:'VERIFIED'},sourceDigest:digest,outputDigest:digest,utf8Bytes:{type:'integer',minimum:1}},required:['sourceDigest','outputDigest','utf8Bytes','renderer']},
  {properties:{status:{const:'FAILED'},finding:{type:'string',minLength:1}},required:['finding']}
],additionalProperties:true};
const publication={type:'object',required:['status','contractId','contentDigest','sourceDigest','inputDigest','bundleDigest','profileDigest','filename','renderer','verification'],
  properties:{contractId:{const:'markdown-page-publication.v1'},status:{const:'COMPLETE'},contentDigest:digest,sourceDigest:digest,inputDigest:digest,
    bundleDigest:digest,profileDigest:digest,filename:{type:'string'},renderer:{type:'object'},verification:{type:'object'}},additionalProperties:true};
function intro(id,input,output,outcome,variants,intent,promise){
  const feature=read(id+'.feature');
  return ['capability '+id,'feature '+id+' '+hash(feature),'intent: '+intent,'outcome: '+promise,'inquiry: '+intent,
    'input contract '+id+'-request.v1 '+JSON.stringify(input),'output contract '+outcome+' '+JSON.stringify(output),
    'cli display outcome as json','scenario '+id+' root terminal','variants: '+variants,
    ...['Given','When','Then'].map(k=>k.toLowerCase()+': '+feature.match(new RegExp('^    '+k+' (.+)$','m'))[1].trim())];
}
function config(s){return JSON.stringify({dataSource:'sfx-estate-database',resultColumn:'value',statement:s.split(/\r?\n/).map(l=>l.trim()).filter(l=>l&&!l.startsWith('--')).join(' ')});}
export function build(){
  const privateDsl=intro(leaf,wire,result,'markdown-page-operation.v1','RENDERED:success,VERIFIED:success,FAILED:failure',
    'Execute one declared Markdown rendering or independent readback operation in the pinned CPython, from a C# or Python kernel.',
    'A digest-bound render, verification, or named package finding.');
  privateDsl.push('operation '+leaf+'.compute kind invoke-port port '+leaf+'-compute','platform bind '+leaf+'-compute','platform: '+mechanic,
    'config: '+JSON.stringify({providerId,dependency:{objectKind:'DEPENDENCY',namespace:'sidefx:dependencies',id:providerId}}));
  const lines=intro(page,request,publication,'markdown-page-publication.v1','COMPLETE:success',
    'Render Markdown text or a retained Markdown digest to a complete styled standalone HTML page using the approved Python-Markdown and nh3 presentation profile. Publish the HTML and verify the source and output digests.',
    'A verified published UTF-8 HTML document and compact content, source, renderer and publication receipt.');
  let previous=page;
  function op(name,cap,conf,bindings){
    lines.push('operation '+page+'.'+name+' uses provider '+cap);
    if(conf)lines.push('config: '+conf);
    for(const [member,path] of Object.entries(bindings))lines.push('input '+member+' from '+previous+' '+path);
    previous=page+'.'+name;
  }
  const sql=(name,s,path)=>op(name,'sql-database-reader',config(s),{input:path});
  const retain=name=>op(name,'apply-declared-change','{"contractId":"declared-change.v1","changeKind":"content-artifact-change"}',{payload:'$.value'});
  const prepare=(name,phase)=>sql(name,"DECLARE @asset varchar(71)='"+identity.assetDigest+"',@phase varchar(10)='"+phase+"';\n"+read('prepare-provider.sql'),'$');
  const compute=name=>op(name,leaf,null,Object.fromEntries(Object.keys(wire.properties).map(k=>[k,'$.value.'+k])));
  sql('source',read('prepare-input.sql'),'$');retain('retain-source');
  prepare('load-render','render');compute('render');
  sql('publication',read('publish-page.sql'),'$');retain('publish');
  prepare('read-publication','verify');compute('verify');
  sql('finish',`IF ISNULL(JSON_VALUE(@input,'$.status'),'')<>'VERIFIED' OR ISNULL(JSON_VALUE(@input,'$.bundleDigest'),'')<>'${identity.bundleDigest}'
    OR ISNULL(JSON_VALUE(@input,'$.profileDigest'),'')<>'${identity.profileDigest}' THROW 51000,'INDEPENDENT_HTML_CHECK_FAILED',1;
    SELECT (SELECT 'markdown-page-publication.v1' contractId,'COMPLETE' status,JSON_VALUE(@input,'$.outputDigest') contentDigest,
    JSON_VALUE(@input,'$.sourceDigest') sourceDigest,JSON_VALUE(@input,'$.inputDigest') inputDigest,JSON_VALUE(@input,'$.bundleDigest') bundleDigest,
    JSON_VALUE(@input,'$.profileDigest') profileDigest,JSON_VALUE(@input,'$.filename') filename,JSON_QUERY(@input,'$.renderer') renderer,
    JSON_QUERY(@input) verification FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;`,'$');
  lines.push('outcome from '+previous+' $.value');
  for(const [id,source] of [[leaf,privateDsl],[page,lines]])writeFileSync(new URL(id+'.dsl',dir),source.join('\n')+'\n');
}
if(fileURLToPath(import.meta.url)===process.argv[1])build();
