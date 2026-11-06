import { writeFileSync } from 'node:fs';
import { file, read, sha } from './portfolio.mjs';
import { specimen } from './benchmark.mjs';

const id='publish-python-reuse-result', feature=read(id+'.feature');
const corpus=sha(read('experiment.json'));
const props={specimen:{enum:['notice','ledger']},text:{type:'string',maxLength:512},byteCount:{type:'integer',minimum:0,maximum:2048},
  base64:{type:'string',maxLength:3072},crc32:{type:'string',pattern:'^[0-9a-f]{8}$'},sha256:{type:'string',pattern:'^[0-9a-f]{64}$'},
  claimedSha256:{type:'string',pattern:'^[0-9a-f]{64}$'},matches:{type:'boolean'}};
const input={type:'object',additionalProperties:false,required:['specimen','text','byteCount','base64','crc32','sha256'],properties:props};
const output={type:'object',additionalProperties:false,required:['contractId','status','specimen','sourceCorpusDigest','contentDigest'],
  properties:{contractId:{const:'python-reuse-publication.v1'},status:{const:'COMPLETE'},specimen:props.specimen,sourceCorpusDigest:{const:corpus},contentDigest:{type:'string',pattern:'^sha256:[a-f0-9]{64}$'}}};
const sql=s=>JSON.stringify({dataSource:'sfx-estate-database',resultColumn:'value',statement:s.replace(/^\s*--.*$/gm,'').split(/\r?\n/).map(l=>l.trim()).join(' ')});
const prepare=`DECLARE @name nvarchar(20)=JSON_VALUE(@input,'$.specimen');
 IF @name='ledger' AND ((SELECT COUNT(*) FROM OPENJSON(@input) WHERE [key]='matches' AND type=3)<>1 OR JSON_VALUE(@input,'$.claimedSha256') IS NULL)
 THROW 51000,'LEDGER_COMPARISON_REQUIRED',1;
 IF @name='notice' AND EXISTS(SELECT 1 FROM OPENJSON(@input) WHERE [key] IN ('matches','claimedSha256')) THROW 51000,'NOTICE_FIELDS_INVALID',1;
 SELECT (SELECT 'content-artifact-change.v1' AS contractId,'python-reuse-manifest' AS artifactKind,@input AS [text],
 'read-harness-authoring-state' AS verificationCapabilityId,JSON_QUERY(N'{"resolvedDisposition":"terminated"}') AS route,
 JSON_QUERY(N'{"input":{"changeKind":"content-artifact-change","includeDefinitions":true},"expected":{"disposition":"terminated"}}') AS preflight FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;`;
const lines=['capability '+id,'feature '+id+' '+sha(feature),
  'intent: Publish the notice or ledger from a Python reuse benchmark as a portable JSON manifest. Supply the exact text, UTF-8 byte count, padded Base64, CRC-32 and SHA-256 from the declared Python operations. Include claimedSha256 and matches for a ledger.',
  'outcome: COMPLETE with the read-back artifact digest. The objective verifier independently checks the artifact and the actual Python call receipts.',
  'inquiry: Publish the escaped notice or exact CRLF ledger integrity manifest from its Python tool results.',
  'input contract '+id+'-request.v1 '+JSON.stringify(input),'output contract python-reuse-publication.v1 '+JSON.stringify(output),
  'cli display outcome as json','scenario '+id+' root terminal','variants: COMPLETE:success',
  ...['Given','When','Then'].map(k=>k.toLowerCase()+': '+feature.match(new RegExp('^    '+k+' (.+)$','m'))[1].trim()),
  'operation '+id+'.prepare uses provider sql-database-reader','config: '+sql(prepare),'input input from '+id+' $',
  'operation '+id+'.publish uses provider apply-declared-change','config: {"contractId":"declared-change.v1","changeKind":"content-artifact-change"}','input payload from '+id+'.prepare $.value',
  'operation '+id+'.finish uses provider sql-database-reader','config: '+sql("DECLARE @corpus varchar(71)='"+corpus+"';\n"+read('publication-receipt.sql')),
  'input input from '+id+'.publish $','outcome from '+id+'.finish $.value',''];
writeFileSync(file(id+'.dsl'),lines.join('\n'));
const variants=Object.fromEntries(['notice','ledger'].map(id=>[id,specimen(id)]));
const profile={id:'python-reuse-manifest/v1',scopeLabel:'python-reuse-manifest',scopeDefinition:'Produce the identified frozen notice or ledger manifest using the required Python operations.',
  contract:'python-reuse-publication.v1',sourceDigestPath:'$.sourceCorpusDigest',sourceDigest:corpus,producers:[id],publishedKindPrefix:'python-reuse-manifest',
  variants,obligations:[{id:'source',kind:'fixture_digest',checks:['FIXTURE_SCOPE']},{id:'operations',kind:'execution_count',checks:['RECEIPT_INPUT_OUTPUT','EXECUTION_ORDER']},
    {id:'manifest',kind:'publication',checks:['PUBLISHED_BYTES','MANIFEST_EQUALS_ORACLE','PUBLICATION_COMPLETE','EXPECTED_ARTIFACT']}],
  reader:'python-reuse-proof.sql'};
writeFileSync(file('../objective-verification/profiles/python-reuse.json'),JSON.stringify(profile,null,2)+'\n');
