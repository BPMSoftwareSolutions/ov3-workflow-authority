import { writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { read, sha } from './portfolio.mjs';
import { specimen } from './benchmark.mjs';
import { obligationSql } from '../objective-verification/obligations.mjs';

const profile=JSON.parse(read('../objective-verification/profiles/python-reuse.json'));
const src=read('../objective-verification/profiles/python-reuse-proof.sql');
const pattern=/DECLARE @previousFinish datetime2=[\s\S]*?AND c.content_digest=HASHBYTES\('SHA2_256',c.content_bytes\);/;
if(!pattern.test(src)) throw Error('Readback select changed; inspect test substitution');
const testReader=src.replace(pattern,`INSERT @pilotBytes SELECT @rootKind+'#'+JSON_VALUE(j.value,'$.turn'),HASHBYTES('SHA2_256',b.raw),b.raw
 FROM OPENJSON(@input,'$.turns') j CROSS APPLY(SELECT CONVERT(varbinary(max),CONVERT(varchar(max),j.value COLLATE Latin1_General_100_BIN2_UTF8)) raw)b;`);
const base=`DECLARE @profile nvarchar(max)=JSON_QUERY(@input,'$.profile'),@report nvarchar(max)=JSON_QUERY(@input,'$.manifest'),@receipt nvarchar(max)=JSON_QUERY(@input,'$.receipt'),@original nvarchar(max)=JSON_VALUE(@input,'$.original'),@source nvarchar(max),@metrics nvarchar(max),@proofSet nvarchar(max);
 DECLARE @conversation varchar(36)='11111111-1111-1111-1111-111111111111';
 DECLARE @rootKind nvarchar(120)='objective-pursuit:'+@conversation,@turn int=20,
 @objectiveHash varchar(71)=JSON_VALUE(@input,'$.objectiveHash');
 DECLARE @evidence TABLE(kind nvarchar(200),stamp datetime2);
 DECLARE @root nvarchar(max)=NULL,@publishedAt datetime2=SYSUTCDATETIME(),@record nvarchar(max)=JSON_QUERY(@input,'$.publicationTurn');
 DECLARE @checks TABLE (code varchar(70) PRIMARY KEY, passed bit NOT NULL);
 INSERT @checks VALUES ('PUBLISHED_BYTES',1),('PUBLICATION_COMPLETE',1),('EXPECTED_ARTIFACT',1);
 DECLARE @observations TABLE(id varchar(60) PRIMARY KEY,expectedJson nvarchar(max),observedJson nvarchar(max));`;
const statement=base+'\n'+testReader+'\n'+obligationSql()+`
 SELECT (SELECT CONVERT(bit,IIF(EXISTS(SELECT 1 FROM @checks WHERE passed=0),0,1)) proved,
 JSON_QUERY((SELECT code FROM @checks WHERE passed=0 FOR JSON PATH)) failed FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;`;
const dir=process.argv[2];mkdirSync(dir,{recursive:true});
for(const [name,id,mutate,proved] of [
  ['valid-notice','notice',()=>{},true],['valid-ledger','ledger',()=>{},true],
  ['missing-escape','notice',p=>{p.calls=p.calls.filter(c=>c.cap!=='python-html');},false],
  ['wrong-bytes','ledger',p=>{p.manifest.text=p.manifest.text.replaceAll('\r','');},false],
  ['forged-comparison','ledger',p=>{p.manifest.matches=true;},false],
  ['swapped-source','notice',p=>{p.calls[0].req.text='another notice';},false],
  ['out-of-order','ledger',p=>{p.calls[2].n=0;},false],['extra-scope','notice',p=>{p.original+=' Also email it.';},false]
  ,['foreign-leaf-binding','ledger',p=>{p.calls[0].foreign=true;},false],
  ['wrong-publication-binding','ledger',p=>{p.foreignPublication=true;},false]
]){
  const s=specimen(id);
  const calls=Object.entries(s.required).map(([cap,v],i)=>({n:i+1,cap,digest:'sha256:'+String(i).repeat(64),req:v.input,
    res:{contractId:cap+'-result.v1',runtime:{implementation:'cpython',version:'3.12.16'},status:'COMPUTED',value:v.value}}));
  const payload={profile,manifest:s.manifest,receipt:{specimen:id},original:s.request,calls};
  mutate(payload);
  payload.objectiveHash=sha(Buffer.from(payload.original,'utf16le'));
  payload.publicationTurn={objectiveBinding:{conversationId:'11111111-1111-1111-1111-111111111111',objectiveHash:payload.foreignPublication?'sha256:'+('0'.repeat(64)):payload.objectiveHash}};
  payload.turns=payload.calls.map(c=>({turn:c.n,action:'CALL',disposition:'terminated',capability:c.cap,inputText:JSON.stringify(c.req),
    result:c.res,...(c.foreign&&{objectiveBinding:{conversationId:'22222222-2222-2222-2222-222222222222',objectiveHash:payload.objectiveHash}})}));
  delete payload.calls;
  writeFileSync(join(dir,name+'.json'),JSON.stringify({dataSource:'sfx-estate-database',resultColumn:'value',statement,input:payload}));
  console.log(name,proved);
}
