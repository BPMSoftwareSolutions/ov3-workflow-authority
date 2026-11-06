DECLARE @page nvarchar(max)=(SELECT value FROM OPENJSON(@input) WHERE [key]='html' AND type=1),@inputDigest varchar(71)=JSON_VALUE(@input,'$.inputDigest');
IF ISNULL(JSON_VALUE(@input,'$.status'),'')<>'RENDERED' OR LEN(ISNULL(@inputDigest,''))<>71 OR @page IS NULL OR
 ISNULL(JSON_VALUE(@input,'$.outputDigest'),'')<>'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@page COLLATE Latin1_General_100_BIN2_UTF8)),2)) THROW 51000,'PYTHON_RENDER_FAILED',1;
SELECT (SELECT 'content-artifact-change.v1' contractId,'markdown-page:'+SUBSTRING(@inputDigest,8,64) artifactKind,@page [text],
 'read-harness-authoring-state' verificationCapabilityId,JSON_QUERY(N'{"resolvedDisposition":"terminated"}') route,
 JSON_QUERY(N'{"input":{"changeKind":"content-artifact-change","includeDefinitions":true},"expected":{"disposition":"terminated"}}') preflight FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;
