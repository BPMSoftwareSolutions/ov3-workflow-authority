import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { obligationContract, obligationSql, validateProfiles } from './obligations.mjs';
const file = p => new URL(p, import.meta.url);
const read = p => readFileSync(file(p), 'utf8');
const id = 'verify-objective-fulfillment';
const feature = read(id+'.feature');
const digest = createHash('sha256').update(readFileSync(file(id+'.feature'))).digest('hex');
const profiles = readdirSync(file('profiles/')).filter(n=>n.endsWith('.json')).sort().map(n=>JSON.parse(read('profiles/'+n)));
validateProfiles(profiles);
writeFileSync(file('objective-obligations.schema.json'),JSON.stringify(obligationContract,null,2)+'\n');
const literal = s => "N'"+s.replaceAll("'","''")+"'";
const readers = profiles.map(p=>'IF @profileId='+literal(p.id)+' BEGIN\n'+read('profiles/'+p.reader)+'\nEND;');
// The port configuration is projected through more than one text encoding.
// JSON escapes preserve Unicode fixture values until OPENJSON decodes them.
const profileJson=JSON.stringify(profiles).replace(/[^\x00-\x7f]/g,c=>'\\u'+c.charCodeAt(0).toString(16).padStart(4,'0'));
const prepare = ['DECLARE @profiles nvarchar(max)='+literal(profileJson)+';',read('resolve-publication.sql'),...readers,obligationSql(),read('prepare-inference.sql')].join('\n');
const statement = s => s.split(/\r?\n/).map(l=>l.trim()).filter(l=>l && !l.startsWith('--')).join(' ');
const sqlConfig = s => JSON.stringify({dataSource:'sfx-estate-database',statement:statement(s),resultColumn:'value'});
const steps = scenario => {
  const block=feature.split('@scenario:'+scenario+'\n')[1].split('@scenario:')[0];
  return ['Given','When','Then'].map(s=>s.toLowerCase()+': '+block.match(new RegExp('^    '+s+' (.+)$','m'))[1].trimEnd());
};
const hash = {type:'string',pattern:'^sha256:[0-9a-f]{64}$'};
const input = {type:'object',additionalProperties:false,required:['conversationId','publicationTurn'],properties:{conversationId:{type:'string',format:'uuid'},publicationTurn:{type:'integer',minimum:1},objective:{type:'string',minLength:1,maxLength:16000},expectedSourceVersion:{type:'string',minLength:1,maxLength:32},expectedArtifactDigest:hash,expectedSourceDigest:hash}};
const output = {type:'object',additionalProperties:true,required:['contractId','status','reason'],properties:{contractId:{const:'objective-verification.v1'},status:{enum:['FULFILLED','UNVERIFIED']},reason:{type:'string'}}};
const choiceQuestion={type:'object',additionalProperties:false,required:['type','instructions','criteria'],properties:{
  type:{const:'choice'},instructions:{type:'string',minLength:1},criteria:{type:'object',minProperties:3,additionalProperties:{type:'string',minLength:1}}
}};
const review={type:'object',additionalProperties:false,required:['status','route','context'],properties:{
  route:{enum:['INFER','HOLD']},status:{type:'string'},context:{type:'object'},state:obligationContract,
  questions:{type:'object',additionalProperties:false,required:['scope'],properties:{scope:choiceQuestion}}
},oneOf:[
  {properties:{route:{const:'INFER'},status:{const:'INFER'}},required:['state','questions']},
  {properties:{route:{const:'HOLD'},status:{const:'HOLD'}},not:{anyOf:[{required:['state']},{required:['questions']}]}}
]};
const lines=['capability '+id,'feature '+id+' sha256:'+digest,
 'intent: Independently verify whether a published artifact fulfills the original objective. Resolve its declared evidence profile, pin the source version and exact bytes, inspect the artifact against retained proof receipts, and use TypeSafe System One for typed scope inference.',
 'outcome: objective-verification.v1 FULFILLED or UNVERIFIED, bound to the objective, conversation, publication turn, artifact, source snapshot and receipts.','inquiry: Does this published artifact satisfy the entire original objective?',
 'input contract '+id+'-request.v1 '+JSON.stringify(input),'output contract objective-verification.v1 '+JSON.stringify(output),'contract objective-obligations.v1 '+JSON.stringify(obligationContract),
 'contract objective-verification-review.v1 '+JSON.stringify(review),
 'cli display outcome as json','scenario '+id+' root output=objective-verification-review.v1','variants: INFER:success,HOLD:success',...steps(id),
 'operation '+id+'.evidence uses provider sql-database-reader','config: '+sqlConfig(prepare),'input input from '+id+' $','outcome from '+id+'.evidence $.value',
 'scenario '+id+'-infer terminal input=objective-verification-review.v1','variants: FULFILLED:success,UNVERIFIED:failure',...steps(id+'-infer'),
 'operation '+id+'.infer uses provider ask-system-one',...['state','questions','context'].map(k=>'input '+k+' from '+id+'-infer $.'+k),
 'operation '+id+'.decide uses provider sql-database-reader','config: '+sqlConfig(read('decide.sql')),'input input from '+id+'.infer $','outcome from '+id+'.decide $.value',
 'scenario '+id+'-hold terminal input=objective-verification-review.v1','variants: FULFILLED:success,UNVERIFIED:failure',...steps(id+'-hold'),
 'operation '+id+'.hold uses provider sql-database-reader','config: '+sqlConfig(read('decide.sql')),'input input from '+id+'-hold $','outcome from '+id+'.hold $.value',
 'route '+id+' INFER to '+id+'-infer','route '+id+' HOLD to '+id+'-hold',''];
writeFileSync(file(id+'.dsl'),lines.join('\n'));
