DECLARE @source nvarchar(max)=(SELECT value FROM OPENJSON(@input) WHERE [key]='markdown' AND type=1);
DECLARE @digest varchar(71)=JSON_VALUE(@input,'$.sourceDigest');
IF (SELECT COUNT(*) FROM OPENJSON(@input) WHERE [key] IN ('markdown','sourceDigest'))<>1 THROW 51000,'EXACTLY_ONE_MARKDOWN_SOURCE_REQUIRED',1;
IF @source IS NULL
BEGIN
 DECLARE @raw TABLE(bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
 INSERT @raw SELECT TOP(1) c.content_bytes FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
 WHERE a.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@digest,8,64),2) AND a.content_digest=HASHBYTES('SHA2_256',c.content_bytes)
 AND (a.artifact_kind LIKE N'python-library-report:%' OR a.artifact_kind=N'markdown-page-source') AND DATALENGTH(c.content_bytes) BETWEEN 1 AND 2097152;
 SELECT @source=CONVERT(nvarchar(max),bytes) FROM @raw;
END;
IF @source IS NULL OR DATALENGTH(CONVERT(varchar(max),@source COLLATE Latin1_General_100_BIN2_UTF8)) NOT BETWEEN 1 AND 2097152 THROW 51000,'MARKDOWN_SOURCE_NOT_RESOLVED',1;
IF ISNULL(JSON_VALUE(@input,'$.profile'),'')<>'technical-report-v1' THROW 51000,'UNKNOWN_PRESENTATION_PROFILE',1;
DECLARE @request nvarchar(max)=JSON_MODIFY(JSON_MODIFY(@input,'$.sourceDigest',NULL),'$.markdown',@source);
SELECT (SELECT 'content-artifact-change.v1' contractId,'markdown-page-input' artifactKind,@request [text],
 'read-harness-authoring-state' verificationCapabilityId,JSON_QUERY(N'{"resolvedDisposition":"terminated"}') route,
 JSON_QUERY(N'{"input":{"changeKind":"content-artifact-change","includeDefinitions":true},"expected":{"disposition":"terminated"}}') preflight FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;
