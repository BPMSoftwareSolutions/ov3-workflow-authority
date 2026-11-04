DECLARE @pageInputHash varchar(71)=JSON_VALUE(@receipt,'$.inputDigest'),@pageSourceHash varchar(71)=JSON_VALUE(@receipt,'$.sourceDigest');
DECLARE @pageDocs TABLE(bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
INSERT @pageDocs SELECT TOP(1) c.content_bytes FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
 WHERE a.artifact_kind='markdown-page-input' AND a.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@pageInputHash,8,64),2)
 AND a.content_digest=HASHBYTES('SHA2_256',c.content_bytes) AND a.registered_date<=@publishedAt;
DECLARE @pageInput nvarchar(max)=(SELECT CONVERT(nvarchar(max),bytes) FROM @pageDocs);
DECLARE @pageMd nvarchar(max)=(SELECT value FROM OPENJSON(@pageInput) WHERE [key]='markdown' AND type=1);
DECLARE @pageName nvarchar(110)=JSON_VALUE(@pageInput,'$.filename'),@pageTitle nvarchar(200)=JSON_VALUE(@pageInput,'$.title');
DECLARE @pageActualSource varchar(71)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@pageMd COLLATE Latin1_General_100_BIN2_UTF8)),2));
DECLARE @pageVerify nvarchar(max)=JSON_QUERY(@receipt,'$.verification'),@pageCall nvarchar(max)=(SELECT value FROM OPENJSON(@record) WHERE [key]='inputText' AND type=1 AND ISJSON(value)=1);
DECLARE @pageCallMd nvarchar(max)=(SELECT value FROM OPENJSON(@pageCall) WHERE [key]='markdown' AND type=1);
DECLARE @pageKnown nvarchar(max)=(SELECT TOP(1) value FROM OPENJSON(@profile,'$.fixtures') WHERE JSON_VALUE(value,'$.sourceDigest')=@pageSourceHash AND JSON_VALUE(value,'$.filename')=@pageName
 AND CONVERT(varbinary(max),JSON_VALUE(value,'$.title'))=CONVERT(varbinary(max),@pageTitle) AND JSON_VALUE(value,'$.lang')=JSON_VALUE(@pageInput,'$.lang'));
INSERT @checks VALUES
 ('PAGE_SOURCE',IIF(@pageMd IS NOT NULL AND @pageActualSource=@pageSourceHash AND
 (JSON_VALUE(@input,'$.expectedSourceDigest') IS NULL OR JSON_VALUE(@input,'$.expectedSourceDigest')=@pageSourceHash) AND JSON_VALUE(@input,'$.expectedSourceVersion') IS NULL AND
 (CHARINDEX(@pageSourceHash,@original)>0 OR (@pageCallMd IS NOT NULL AND DATALENGTH(@pageCallMd) BETWEEN 2 AND 8000 AND CHARINDEX(CONVERT(nvarchar(4000),@pageCallMd),@original)>0)),1,0)),
 ('PAGE_PUBLICATION_BINDING',IIF(JSON_VALUE(@record,'$.objectiveBinding.conversationId')=@conversation AND JSON_VALUE(@record,'$.objectiveBinding.objectiveHash')=@objectiveHash
 AND JSON_VALUE(@pageCall,'$.filename')=@pageName AND JSON_VALUE(@receipt,'$.filename')=@pageName AND CHARINDEX(@pageName,@original)>0
 AND JSON_VALUE(@pageCall,'$.profile')=JSON_VALUE(@pageInput,'$.profile') AND JSON_VALUE(@pageCall,'$.lang')=JSON_VALUE(@pageInput,'$.lang')
 AND CONVERT(varbinary(max),JSON_VALUE(@pageCall,'$.title'))=CONVERT(varbinary(max),@pageTitle)
 AND (JSON_VALUE(@pageCall,'$.sourceDigest')=@pageSourceHash OR CONVERT(varbinary(max),@pageCallMd)=CONVERT(varbinary(max),@pageMd))
 AND EXISTS(SELECT 1 FROM model.content_artifact WHERE artifact_kind='markdown-page:'+SUBSTRING(@pageInputHash,8,64)
 AND content_digest=TRY_CONVERT(binary(32),SUBSTRING(@artifact,8,64),2) AND registered_date<=@publishedAt),1,0)),
 ('PAGE_RENDERER',IIF(JSON_VALUE(@receipt,'$.renderer.Markdown')=JSON_VALUE(@profile,'$.parserVersion')
 AND JSON_VALUE(@receipt,'$.renderer.nh3')=JSON_VALUE(@profile,'$.sanitizerVersion') AND JSON_VALUE(@receipt,'$.renderer.python') IS NOT NULL
 AND JSON_VALUE(@receipt,'$.profileDigest')=JSON_VALUE(@profile,'$.presentationDigest'),1,0)),
 ('PAGE_READBACK',IIF(JSON_VALUE(@pageVerify,'$.status')='VERIFIED' AND JSON_VALUE(@pageVerify,'$.inputDigest')=@pageInputHash
 AND JSON_VALUE(@pageVerify,'$.sourceDigest')=@pageSourceHash AND JSON_VALUE(@pageVerify,'$.outputDigest')=@artifact
 AND JSON_VALUE(@pageVerify,'$.bundleDigest')=JSON_VALUE(@profile,'$.sourceDigest') AND JSON_VALUE(@pageVerify,'$.profileDigest')=JSON_VALUE(@profile,'$.presentationDigest')
 AND TRY_CONVERT(bigint,JSON_VALUE(@pageVerify,'$.utf8Bytes'))=DATALENGTH(CONVERT(varchar(max),@report COLLATE Latin1_General_100_BIN2_UTF8))
 AND LEFT(@report,15)='<!doctype html>' AND CHARINDEX(N'<article>',@report)>0 AND RIGHT(RTRIM(REPLACE(@report,CHAR(10),'')),7)='</html>'
 AND (@pageKnown IS NULL OR JSON_VALUE(@pageKnown,'$.outputDigest')=@artifact),1,0));
SET @source=(SELECT @pageSourceHash sourceDigest,@pageInputHash inputDigest,@pageName filename FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SET @metrics=JSON_QUERY(@pageVerify);
SET @proofSet=(SELECT @turn publicationTurn,@turnDigest publicationReceiptDigest,@pageInputHash inputDigest,@artifact contentDigest FOR JSON PATH);
INSERT @observations VALUES ('source',QUOTENAME(@pageSourceHash,'"'),QUOTENAME(@pageActualSource,'"')),
 ('renderer',QUOTENAME(JSON_VALUE(@profile,'$.sourceDigest'),'"'),QUOTENAME(JSON_VALUE(@receipt,'$.bundleDigest'),'"')),
 ('page','"standalone-html-page"',CASE WHEN JSON_VALUE(@pageVerify,'$.status')='VERIFIED' THEN '"standalone-html-page"' END);
SET @profile=JSON_MODIFY(@profile,'$.scopeDefinition',CONCAT('Render the Markdown with source digest ',@pageSourceHash,' as a sanitized, complete, standalone UTF-8 HTML page named ',@pageName,' with title ',@pageTitle,' using the approved technical-report-v1 Python rendering profile and verify its publication.'));
