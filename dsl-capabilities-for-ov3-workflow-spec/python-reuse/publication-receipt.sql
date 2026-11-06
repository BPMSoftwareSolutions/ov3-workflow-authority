DECLARE @returned nvarchar(max)=COALESCE(JSON_VALUE(@input,'$.result[0][0].value'),JSON_QUERY(@input,'$.result[0][0]'));
DECLARE @digest varchar(71)=JSON_VALUE(@returned,'$.content_digest');
IF ISNULL(JSON_VALUE(@input,'$.disposition'),'')<>'COMMITTED' OR @digest IS NULL THROW 51000,'MANIFEST_PUBLICATION_FAILED',1;
DECLARE @stored TABLE(body varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
INSERT @stored SELECT TOP(1) c.content_bytes
    FROM model.content_artifact a JOIN source.content_object c ON a.content_digest=c.content_digest
    WHERE a.artifact_kind=N'python-reuse-manifest' AND a.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@digest,8,64),2)
      AND c.content_digest=HASHBYTES('SHA2_256',c.content_bytes);
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),body) FROM @stored);
IF @body IS NULL OR ISJSON(@body)<>1 THROW 51000,'MANIFEST_READBACK_FAILED',1;
SELECT (SELECT 'python-reuse-publication.v1' AS contractId,'COMPLETE' AS status,JSON_VALUE(@body,'$.specimen') AS specimen,
    @corpus AS sourceCorpusDigest,@digest AS contentDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
