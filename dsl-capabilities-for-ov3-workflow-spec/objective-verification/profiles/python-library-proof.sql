DECLARE @pin varchar(71)=JSON_VALUE(@profile,'$.sourceDigest'),@invPin varchar(71)=JSON_VALUE(@profile,'$.inventoryDigest'),
        @version varchar(32)=JSON_VALUE(@profile,'$.sourceVersion'),@uri nvarchar(600)=JSON_VALUE(@profile,'$.sourceUrl');
DECLARE @sources TABLE(digest binary(32), bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
INSERT @sources SELECT content_digest,content_bytes FROM source.content_object
WHERE content_digest IN (TRY_CONVERT(binary(32),SUBSTRING(@pin,8,64),2),TRY_CONVERT(binary(32),SUBSTRING(@invPin,8,64),2))
    AND content_digest=HASHBYTES('SHA2_256',content_bytes);
DECLARE @html nvarchar(max)=(SELECT CONVERT(nvarchar(max),bytes) FROM @sources WHERE digest=TRY_CONVERT(binary(32),SUBSTRING(@pin,8,64),2)),
        @inventory nvarchar(max)=(SELECT CONVERT(nvarchar(max),bytes) FROM @sources WHERE digest=TRY_CONVERT(binary(32),SUBSTRING(@invPin,8,64),2));
DECLARE @titleStart int=CHARINDEX('<title>',@html)+7,@titleEnd int=CHARINDEX('</title>',@html);
DECLARE @title nvarchar(300)=SUBSTRING(@html,@titleStart,CASE WHEN @titleEnd>@titleStart THEN @titleEnd-@titleStart ELSE 0 END);
SET @source=(SELECT @uri AS uri,@version AS version,@title AS title,@pin AS responseBodyHash,@invPin AS inventoryDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @headEnd int=CHARINDEX('-->',@report);
DECLARE @meta nvarchar(max)=CASE WHEN LEFT(@report,4)='<!--' AND @headEnd>4 THEN SUBSTRING(@report,5,@headEnd-5) END;
IF ISNULL(ISJSON(@meta),0)<>1 SET @meta=NULL;
INSERT @checks VALUES ('PUBLISHED_SOURCE_IDENTITY',IIF(
    (JSON_QUERY(@meta,'$.sourceIdentity') IS NULL AND JSON_QUERY(@receipt,'$.sourceIdentity') IS NULL)
    OR (JSON_VALUE(@meta,'$.sourceIdentity.version')=@version AND JSON_VALUE(@meta,'$.sourceIdentity.uri')=@uri
        AND JSON_VALUE(@meta,'$.sourceIdentity.responseBodyHash')=@pin AND JSON_VALUE(@receipt,'$.sourceIdentity.version')=@version
        AND JSON_VALUE(@receipt,'$.sourceIdentity.uri')=@uri AND JSON_VALUE(@receipt,'$.sourceIdentity.responseBodyHash')=@pin),1,0));
DECLARE @roster TABLE(name nvarchar(250) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,url nvarchar(900),section nvarchar(250),removed bit,summary nvarchar(1500));
INSERT @roster SELECT name,url,section,removed,summary FROM OPENJSON(@inventory,'$.modules') WITH
    (name nvarchar(250) '$.module',url nvarchar(900) '$.documentationUrl',section nvarchar(250),removed bit,summary nvarchar(1500));
DECLARE @total int=(SELECT COUNT(*) FROM @roster),@active int=(SELECT COUNT(*) FROM @roster WHERE removed=0);
DECLARE @srcStart int=CHARINDEX('<table class="indextable modindextable">',@html);
DECLARE @srcEnd int=CHARINDEX('</table>',@html,@srcStart);
DECLARE @tab xml=TRY_CONVERT(xml,SUBSTRING(@html,@srcStart,CASE WHEN @srcEnd>@srcStart THEN @srcEnd-@srcStart+8 ELSE 0 END));
DECLARE @official TABLE(name nvarchar(250) COLLATE Latin1_General_100_BIN2,removed bit);
INSERT @official SELECT n.value('(td[2]//code/text())[1]','nvarchar(250)'),
    IIF(n.value('string((td[3]/em)[1])','nvarchar(1500)') LIKE 'Removed in %',1,0) FROM @tab.nodes('/table/tr[td[2]//code]') o(n);
DECLARE @statedVersion nvarchar(32)=JSON_VALUE(@input,'$.expectedSourceVersion');
DECLARE @versions TABLE(v nvarchar(100));
INSERT @versions SELECT TRIM('.' FROM value) FROM STRING_SPLIT(TRANSLATE(ISNULL(@original,''),'/,:;()[]?!'+CHAR(10)+CHAR(13)+CHAR(9),REPLICATE(' ',13)),' ')
    WHERE value LIKE '3.[0-9]%' AND TRIM('.' FROM value) NOT LIKE '%[^.0-9]%';
DECLARE @mentionedVersion nvarchar(100)=(SELECT CASE WHEN COUNT(DISTINCT v)=1 THEN MIN(v) END FROM @versions);
-- Resolve an explicit quantity in the original scope before considering the profile default.
DECLARE @words TABLE(ord int PRIMARY KEY,word nvarchar(250));
INSERT @words SELECT ROW_NUMBER() OVER(ORDER BY ordinal),LEFT(value,250) FROM STRING_SPLIT(TRANSLATE(LOWER(ISNULL(@original,'')),
    N'-,:;().'+NCHAR(10)+NCHAR(13)+NCHAR(9),REPLICATE(N' ',10)),N' ',1) WHERE value<>'';
DECLARE @quantities TABLE(n int);
INSERT @quantities SELECT DISTINCT COALESCE(TRY_CONVERT(int,w.word),n.value)
    FROM @words w LEFT JOIN (VALUES('one',1),('two',2),('three',3),('four',4),('five',5),('six',6),('seven',7),('eight',8),('nine',9),('ten',10)) n(word,value) ON n.word=w.word
    JOIN @words nextWord ON nextWord.ord=w.ord+1
    JOIN @words u ON u.ord=w.ord+CASE WHEN nextWord.word IN ('ranked','best','top') THEN 2 ELSE 1 END AND u.word='use'
    JOIN @words c ON c.ord=u.ord+1 AND c.word IN ('case','cases')
    WHERE COALESCE(TRY_CONVERT(int,w.word),n.value) IS NOT NULL;
DECLARE @requestedCount int=COALESCE((SELECT MIN(n) FROM @quantities),5);
INSERT @checks VALUES ('REQUESTED_RANKED_COUNT',IIF(@requestedCount=5 AND (SELECT COUNT(*) FROM @quantities)<=1,1,0));
INSERT @checks VALUES
 ('SOURCE_BYTES_VERSION',IIF(@title=JSON_VALUE(@inventory,'$.sourceTitle') AND RIGHT(@title,LEN('Python '+@version+' documentation'))='Python '+@version+' documentation' AND @uri=JSON_VALUE(@inventory,'$.moduleIndexUrl') AND @pin=JSON_VALUE(@inventory,'$.moduleIndexHash') AND @pin=JSON_VALUE(@receipt,'$.moduleIndexHash') AND @pin=JSON_VALUE(@meta,'$.moduleIndexHash'),1,0)),
 ('REQUESTED_SOURCE_PIN',IIF((@statedVersion IS NULL OR @statedVersion=@version) AND (JSON_VALUE(@input,'$.expectedSourceDigest') IS NULL OR JSON_VALUE(@input,'$.expectedSourceDigest')=@pin) AND NOT EXISTS(SELECT 1 FROM @versions WHERE v<>@version AND @version NOT LIKE v+'.%'),1,0)),
 ('OFFICIAL_POPULATION',IIF(@total>0 AND @total=(SELECT COUNT(*) FROM @official) AND NOT EXISTS(SELECT name,removed FROM @official EXCEPT SELECT name,removed FROM @roster) AND NOT EXISTS(SELECT name,removed FROM @roster EXCEPT SELECT name,removed FROM @official),1,0)),
 ('REPORT_SCOPE',IIF(JSON_VALUE(@meta,'$.status')='COMPLETE' AND JSON_VALUE(@meta,'$.scope')='all' AND JSON_VALUE(@receipt,'$.scope')='all'
    AND NOT EXISTS(SELECT 1 FROM (VALUES (@meta),(@receipt)) h(j) WHERE ISNULL(TRY_CONVERT(int,JSON_VALUE(h.j,'$.indexedCount')),-1)<>@total OR ISNULL(TRY_CONVERT(int,JSON_VALUE(h.j,'$.currentInScope')),-1)<>@active OR ISNULL(TRY_CONVERT(int,JSON_VALUE(h.j,'$.proposals')),-1)<>@active OR ISNULL(TRY_CONVERT(int,JSON_VALUE(h.j,'$.removedInScope')),-1)<>@total-@active OR ISNULL(TRY_CONVERT(int,JSON_VALUE(h.j,'$.missingCount')),-1)<>0),1,0));
DECLARE @lf nchar(1)=NCHAR(10);
DECLARE @blocks TABLE(name nvarchar(250) COLLATE Latin1_General_100_BIN2, sectionHash binary(32));
INSERT @blocks SELECT LEFT(j.value,CHARINDEX(@lf,j.value+@lf)-1),HASHBYTES('SHA2_256',CONVERT(varbinary(max),TRIM(@lf FROM j.value)))
    FROM OPENJSON('["'+REPLACE(STRING_ESCAPE(ISNULL(@report,''),'json'),'\n## ','","')+'"]') j WHERE TRY_CONVERT(int,j.[key])>0;
INSERT @checks VALUES ('EXACT_MODULE_SET',IIF((SELECT COUNT(*) FROM @blocks)=@total AND NOT EXISTS(SELECT name FROM @blocks EXCEPT SELECT name FROM @roster)
    AND NOT EXISTS(SELECT name FROM @roster EXCEPT SELECT name FROM @blocks),1,0));
DECLARE @removedOk int=(SELECT COUNT(*) FROM @roster r JOIN @blocks b ON b.name=r.name WHERE r.removed=1 AND b.sectionHash=HASHBYTES('SHA2_256',CONVERT(varbinary(max),
    CONCAT(r.name,@lf,@lf,r.section,@lf,@lf,'[Python documentation](',r.url,')',@lf,@lf,'Removed. ',r.summary))));
INSERT @checks VALUES ('REMOVED_MODULES',IIF(@removedOk=@total-@active,1,0));
DECLARE @batches TABLE(digest binary(32) PRIMARY KEY, bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
INSERT @batches SELECT DISTINCT a.content_digest,c.content_bytes FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
    WHERE a.artifact_kind=N'public-python-library-research-batch.v1' AND a.registered_date<=@publishedAt AND c.content_digest=HASHBYTES('SHA2_256',c.content_bytes);
DECLARE @matched TABLE(name nvarchar(250) COLLATE Latin1_General_100_BIN2, digest binary(32));
INSERT @matched
SELECT DISTINCT r.name,ba.digest FROM @batches ba
CROSS APPLY (SELECT CONVERT(nvarchar(max),ba.bytes) AS j) raw
CROSS APPLY OPENJSON(CASE WHEN ISJSON(raw.j)=1 THEN raw.j END,'$.entries') x
JOIN @roster r ON r.name=JSON_VALUE(x.value,'$.source.module') COLLATE Latin1_General_100_BIN2 AND r.removed=0
JOIN @blocks b ON b.name=r.name
CROSS APPLY (SELECT JSON_QUERY(x.value,'$.inputContract') AS inp,JSON_QUERY(x.value,'$.outputContract') AS outp,JSON_VALUE(x.value,'$.source.responseBodyHash') AS sourceHash) c
OUTER APPLY (SELECT
 (SELECT STRING_AGG(CONVERT(nvarchar(max),'- '+value),@lf) WITHIN GROUP(ORDER BY CONVERT(int,[key])) FROM OPENJSON(x.value,'$.apis')) AS apis,
 (SELECT STRING_AGG(CONVERT(nvarchar(max),'- '+value),@lf) WITHIN GROUP(ORDER BY CONVERT(int,[key])) FROM OPENJSON(x.value,'$.failureModes')) AS failures,
 (SELECT STRING_AGG(CONVERT(nvarchar(max),CONCAT(CONVERT(int,[key])+1,'. ',value)),@lf) WITHIN GROUP(ORDER BY CONVERT(int,[key])) FROM OPENJSON(x.value,'$.useCases')) AS uses) f
WHERE JSON_VALUE(raw.j,'$.contractId')='python-library-proposals-batch.v1' AND JSON_VALUE(x.value,'$.status')='PROPOSED'
 AND JSON_VALUE(x.value,'$.source.documentationUrl') COLLATE Latin1_General_100_BIN2=r.url AND LEFT(c.sourceHash,7)='sha256:' AND LEN(c.sourceHash)=71 AND TRY_CONVERT(binary(32),SUBSTRING(c.sourceHash,8,64),2) IS NOT NULL
 AND NOT EXISTS(SELECT 1 FROM (VALUES(c.inp),(c.outp)) k(j) WHERE ISNULL(JSON_VALUE(j,'$.type'),'')<>'object' OR LEFT(ISNULL(JSON_QUERY(j,'$.properties'),''),1)<>'{' OR NOT EXISTS(SELECT 1 FROM OPENJSON(j,'$.properties')) OR LEFT(ISNULL(JSON_QUERY(j,'$.required'),''),1)<>'[' OR EXISTS(SELECT 1 FROM OPENJSON(j,'$.required') req WHERE req.type<>1 OR NOT EXISTS(SELECT 1 FROM OPENJSON(j,'$.properties') prop WHERE prop.[key]=req.value COLLATE Latin1_General_100_BIN2)))
 AND LEFT(JSON_QUERY(x.value,'$.useCases'),1)='[' AND (SELECT COUNT(*) FROM OPENJSON(x.value,'$.useCases'))=5
 AND (SELECT COUNT(DISTINCT TRIM(value)) FROM OPENJSON(x.value,'$.useCases') WHERE type=1 AND NULLIF(TRIM(value),'') IS NOT NULL)=5
 AND NULLIF(f.apis,'') IS NOT NULL AND NULLIF(f.failures,'') IS NOT NULL
 AND b.sectionHash=HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONCAT(r.name,@lf,@lf,r.section,@lf,@lf,'[Python documentation](',r.url,')',@lf,@lf,
 JSON_VALUE(x.value,'$.operation'),@lf,@lf,'**APIs**',@lf,f.apis,@lf,@lf,
 '**Input contract**',@lf,'```json',@lf,c.inp,@lf,'```',@lf,@lf,'**Output contract**',@lf,'```json',@lf,c.outp,@lf,'```',@lf,@lf,
 '**Effects** ',JSON_VALUE(x.value,'$.effects'),@lf,@lf,'**Constraints** ',JSON_VALUE(x.value,'$.constraints'),@lf,@lf,'**Failure modes**',@lf,f.failures,@lf,@lf,
 '**Ranked use cases**',@lf,f.uses,@lf,@lf,'Source digest `',c.sourceHash,'`')));
DECLARE @proved int=(SELECT COUNT(DISTINCT name) FROM @matched);
INSERT @checks VALUES ('MODULE_CONTENT_AND_PROOF',IIF(@active>0 AND @proved=@active,1,0));
SET @metrics=(SELECT @total AS indexed,@active AS currentModules,@removedOk AS removedMatched,@proved AS provedModules,2*@proved AS provedContracts,5*@proved AS provedUseCases FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SET @proofSet=(SELECT 'sha256:'+LOWER(CONVERT(varchar(64),d,2)) AS digest,COUNT(*) AS modules FROM (SELECT name,MIN(digest) AS d FROM @matched GROUP BY name) chosen GROUP BY d ORDER BY d FOR JSON PATH);
DECLARE @scrapePin varchar(71)=JSON_VALUE(@profile,'$.scrapeReceiptDigest'),@scrape nvarchar(max);
SELECT @scrape=CONVERT(nvarchar(max),CONVERT(varchar(max),c.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM source.content_object c WHERE c.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@scrapePin,8,64),2) AND c.content_digest=HASHBYTES('SHA2_256',c.content_bytes);
DECLARE @scraped bit=IIF(JSON_VALUE(@scrape,'$.capability')='scrape-web-page' AND JSON_VALUE(@scrape,'$.result.status')='SCRAPED'
    AND JSON_VALUE(@scrape,'$.result.url')=JSON_VALUE(@inventory,'$.libraryIndexUrl') AND JSON_VALUE(@scrape,'$.result.responseBodyHash')=JSON_VALUE(@inventory,'$.libraryIndexHash'),1,0);
INSERT @checks VALUES ('SCRAPER_RECEIPT',@scraped);
SET @source=JSON_MODIFY(@source,'$.scrapeReceiptDigest',@scrapePin);
DECLARE @expectedSnapshot nvarchar(max)=(SELECT @uri AS uri,COALESCE(@statedVersion,CASE WHEN @mentionedVersion IS NOT NULL AND @version NOT LIKE @mentionedVersion+'.%' THEN @mentionedVersion END,@version) AS version,COALESCE(JSON_VALUE(@input,'$.expectedSourceDigest'),@pin) AS digest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @observedSnapshot nvarchar(max)=(SELECT @uri AS uri,@version AS version,JSON_VALUE(@receipt,'$.moduleIndexHash') AS digest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @observations VALUES
    ('source',@expectedSnapshot,@observedSnapshot),
    ('scraper','"scrape-web-page"',CASE WHEN @scraped=1 THEN '"scrape-web-page"' END),
    ('libraries',(SELECT @active AS [current],@total-@active AS removed FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),(SELECT @proved AS [current],@removedOk AS removed FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)),
    ('binding_contracts','{"input":"json-object","output":"json-object"}',CASE WHEN @proved=@active AND @active>0 THEN '{"input":"json-object","output":"json-object"}' END),
    ('use_cases',CONVERT(varchar(12),@requestedCount),CASE WHEN @proved=@active AND @active>0 THEN '5' END),
    ('deliverable','"markdown-report"',CASE WHEN @report IS NOT NULL AND JSON_VALUE(@receipt,'$.status')='COMPLETE' THEN '"markdown-report"' END);
