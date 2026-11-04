-- The builder pins @asset and sets @phase. Both paths read verified bytes back from the content store.
DECLARE @returned nvarchar(max)=COALESCE(JSON_VALUE(@input,'$.result[0][0].value'),JSON_QUERY(@input,'$.result[0][0]'));
DECLARE @storedDigest varchar(71)=JSON_VALUE(@returned,'$.content_digest'),@kind nvarchar(200)=JSON_VALUE(@returned,'$.artifact_kind');
IF ISNULL(JSON_VALUE(@input,'$.disposition'),'')<>'COMMITTED' OR @storedDigest IS NULL THROW 51000,'PUBLICATION_WRITE_FAILED',1;
DECLARE @package TABLE(bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
INSERT @package SELECT TOP(1) c.content_bytes FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
 WHERE a.artifact_kind=N'markdown-python-provider-package' AND a.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@asset,8,64),2)
 AND a.content_digest=HASHBYTES('SHA2_256',c.content_bytes);
DECLARE @bundle varchar(max)=(SELECT bytes FROM @package);
IF @bundle IS NULL THROW 51000,'PINNED_PACKAGE_NOT_PRESENT',1;
DECLARE @inputHash varchar(71)=CASE WHEN @phase='render' AND @kind='markdown-page-input' THEN @storedDigest
 WHEN @phase='verify' AND LEN(@kind)=78 AND LEFT(@kind,14)='markdown-page:' THEN 'sha256:'+SUBSTRING(@kind,15,64) END;
DECLARE @documents TABLE(kind nvarchar(200),bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
INSERT @documents SELECT a.artifact_kind,c.content_bytes FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
 WHERE ((a.artifact_kind='markdown-page-input' AND a.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@inputHash,8,64),2))
 OR (@phase='verify' AND a.artifact_kind=@kind AND a.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@storedDigest,8,64),2))) AND a.content_digest=HASHBYTES('SHA2_256',c.content_bytes);
DECLARE @request nvarchar(max)=(SELECT TOP(1) CONVERT(nvarchar(max),bytes) FROM @documents WHERE kind='markdown-page-input');
DECLARE @html nvarchar(max)=(SELECT TOP(1) CONVERT(nvarchar(max),bytes) FROM @documents WHERE kind=@kind AND @phase='verify');
IF @request IS NULL OR (@phase='verify' AND @html IS NULL) THROW 51000,'PAGE_AND_SOURCE_BINDING_MISSING',1;
DECLARE @source nvarchar(max)=(SELECT value FROM OPENJSON(@request) WHERE [key]='markdown' AND type=1);
DECLARE @sourceDigest varchar(71)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@source COLLATE Latin1_General_100_BIN2_UTF8)),2));
SELECT (SELECT @phase phase,@bundle bundle,@inputHash inputDigest,JSON_QUERY(@request) request,COALESCE(@html,N'') html,
 JSON_QUERY((SELECT @sourceDigest sourceDigest,@storedDigest outputDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) receipt FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;
