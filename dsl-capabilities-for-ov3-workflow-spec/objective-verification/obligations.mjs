import { readFileSync } from 'node:fs';
const types=JSON.parse(readFileSync(new URL('obligation-types.json',import.meta.url),'utf8'));
const literal=s=>"N'"+s.replaceAll("'","''")+"'";
function record(properties) {
  return {type:'object',additionalProperties:false,required:Object.keys(properties),properties};
}
const base={id:{type:'string',pattern:'^[a-z][a-z0-9_]*$'}};
export const obligationContract=record({
  contractId:{const:'objective-obligations.v1'},request:{type:'string',minLength:1,maxLength:16000},
  obligations:{type:'array',minItems:1,items:{oneOf:Object.entries(types).map(([kind,t])=>record({
    ...base,kind:{const:kind},operator:{const:t.op},quantifier:{const:t.quantifier},
    expected:t.value,observed:{anyOf:[t.value,{type:'null'}]},proof:{enum:['PROVED','UNPROVED']}
  }))}}
});
export function validateProfiles(profiles) {
  const identities=new Set();
  for(const p of profiles) {
    const ids=new Set();
    for(const producer of p.producers) {
      const key=[p.contract,producer,p.sourceDigest].join('|');
      if(identities.has(key)) throw Error('Ambiguous proof profile '+key);
      identities.add(key);
    }
    for(const o of p.obligations) {
      if(!Object.hasOwn(types,o.kind)||!/^[a-z][a-z0-9_]*$/.test(o.id)||ids.has(o.id)||!o.checks.length) throw Error('Invalid obligation '+o.id);
      ids.add(o.id);
    }
  }
}
function valid(alias,schema) {
  const {type}=schema;
  if(type==='object') {
    const fields=Object.entries(schema.properties);
    return [alias+'.type=5',
      '(SELECT COUNT(*) FROM OPENJSON(CASE WHEN '+alias+'.type=5 THEN '+alias+'.value END))='+fields.length,
      ...fields.map(([name,sub])=>'EXISTS(SELECT 1 FROM OPENJSON(CASE WHEN '+alias+'.type=5 THEN '+alias+'.value END) member WHERE member.[key]='+literal(name)+' AND '+valid('member',sub)+')')
    ].join(' AND ');
  }
  if(type==='integer') return alias+'.type=2 AND TRY_CONVERT(bigint,'+alias+'.value)>=0 AND '+alias+'.value NOT LIKE '+literal('%[^0-9]%');
  const clauses=[alias+'.type=1'];
  if(schema.const) clauses.push(alias+'.value='+literal(schema.const));
  if(schema.enum) clauses.push(alias+'.value IN ('+schema.enum.map(literal).join(',')+')');
  if(schema.minLength) clauses.push('LEN(TRIM('+alias+'.value))>='+schema.minLength);
  if(schema.format==='uri') clauses.push(alias+".value LIKE 'https://%/%'");
  if(schema.pattern?.includes('sha256')) clauses.push("LEN("+alias+".value)=71 AND LEFT("+alias+".value,7)='sha256:' AND SUBSTRING("+alias+".value,8,64) COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^a-f0-9]%'");
  else if(schema.pattern) clauses.push(alias+".value NOT LIKE '%[^0-9.]%' AND PARSENAME("+alias+".value,1) IS NOT NULL AND PARSENAME("+alias+".value,2) IS NOT NULL");
  return clauses.join(' AND ');
}
// Every value is parsed by OPENJSON with its JSON type intact. A quoted number is not an integer.
export function obligationSql() {
  const typeRows=Object.entries(types).map(([k,t])=>'('+[k,t.op,t.quantifier].map(literal).join(',')+')').join(',');
  const rules=Object.entries(types).map(([k,t])=>"(d.kind="+literal(k)+' AND '+valid('v',t.value)+')').join(' OR ');
  return `
DECLARE @defs TABLE(id varchar(60) PRIMARY KEY,kind varchar(50),op varchar(40),quantifier varchar(40),gates nvarchar(max));
INSERT @defs SELECT p.id,p.kind,d.op,d.quantifier,p.gates FROM OPENJSON(@profile,'$.obligations') WITH(id varchar(60),kind varchar(50),gates nvarchar(max) '$.checks' AS JSON) p
JOIN (VALUES ${typeRows}) d(kind,op,quantifier) ON d.kind=p.kind;
DECLARE @encoded TABLE(id varchar(60) PRIMARY KEY,j nvarchar(max),typed bit,passed bit);
INSERT @encoded
SELECT d.id,N'{"id":"'+d.id+'","kind":"'+d.kind+'","operator":"'+d.op+'","quantifier":"'+d.quantifier+'","expected":'+COALESCE(o.expectedJson,'null')+',"observed":'+COALESCE(o.observedJson,'null')+',"proof":"'+IIF(ok.passed=1,'PROVED','UNPROVED')+'"}',
       shape.typed,ok.passed FROM @defs d LEFT JOIN @observations o ON o.id=d.id
CROSS APPLY (SELECT CASE WHEN EXISTS(SELECT 1 FROM OPENJSON('['+o.expectedJson+']') v WHERE ${rules})
 AND (o.observedJson IS NULL OR EXISTS(SELECT 1 FROM OPENJSON('['+o.observedJson+']') v WHERE ${rules})) THEN 1 ELSE 0 END AS typed) shape
CROSS APPLY (SELECT CASE WHEN shape.typed=1 AND o.observedJson IS NOT NULL
 AND o.expectedJson COLLATE Latin1_General_100_BIN2=o.observedJson COLLATE Latin1_General_100_BIN2
 AND EXISTS(SELECT 1 FROM OPENJSON(d.gates)) AND NOT EXISTS(SELECT 1 FROM OPENJSON(d.gates) g LEFT JOIN @checks c ON c.code=g.value WHERE ISNULL(c.passed,0)=0)
 THEN 1 ELSE 0 END AS passed) ok;
DECLARE @obligations nvarchar(max)=(SELECT '['+STRING_AGG(CONVERT(nvarchar(max),j),',') WITHIN GROUP(ORDER BY id)+']' FROM @encoded);
INSERT @checks VALUES ('TYPED_OBLIGATIONS',IIF(EXISTS(SELECT 1 FROM @encoded) AND NOT EXISTS(SELECT 1 FROM @encoded WHERE typed=0)
 AND NOT EXISTS(SELECT id FROM @observations EXCEPT SELECT id FROM @defs) AND (SELECT COUNT(*) FROM @encoded)=(SELECT COUNT(*) FROM OPENJSON(@profile,'$.obligations')),1,0)),
 ('ALL_OBLIGATIONS_PROVED',IIF(EXISTS(SELECT 1 FROM @encoded) AND NOT EXISTS(SELECT 1 FROM @encoded WHERE passed=0),1,0));
`;
}
