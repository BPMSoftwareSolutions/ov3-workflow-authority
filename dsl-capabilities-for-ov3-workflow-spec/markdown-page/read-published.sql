-- Return HTML bytes only for the named conversation's own successful renderer call.
DECLARE @id varchar(36)=LOWER(CONVERT(varchar(36),TRY_CONVERT(uniqueidentifier,JSON_VALUE(@input,'$.conversationId'))));
DECLARE @kind nvarchar(100)='objective-pursuit:'+@id;
DECLARE @rows TABLE(kind nvarchar(200),digest binary(32),bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8,stamp datetime2,pk bigint);
INSERT @rows SELECT a.artifact_kind,a.content_digest,c.content_bytes,a.registered_date,a.content_artifact_pk FROM model.content_artifact a
 JOIN source.content_object c ON c.content_digest=a.content_digest WHERE (a.artifact_kind=@kind OR a.artifact_kind LIKE @kind+'#%')
 AND c.content_digest=HASHBYTES('SHA2_256',c.content_bytes);
DECLARE @root nvarchar(max)=(SELECT TOP(1) CONVERT(nvarchar(max),bytes) FROM @rows WHERE kind=@kind ORDER BY stamp DESC,pk DESC);
IF @root IS NULL THROW 51000,'NO_RETAINED_OBJECTIVE',1;
DECLARE @objective nvarchar(max)=(SELECT value FROM OPENJSON(@root) WHERE [key]='objective');
DECLARE @hash varchar(71)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@objective)),2));
DECLARE @receipt nvarchar(max),@turn int,@turnDigest varchar(71);
SELECT TOP(1) @receipt=JSON_QUERY(body,'$.result'),@turn=TRY_CONVERT(int,JSON_VALUE(body,'$.turn')),@turnDigest='sha256:'+LOWER(CONVERT(varchar(64),r.digest,2))
 FROM @rows r CROSS APPLY(SELECT CONVERT(nvarchar(max),r.bytes) body)b WHERE r.kind<>@kind
 AND JSON_VALUE(body,'$.action')='CALL' AND JSON_VALUE(body,'$.disposition')='terminated'
 AND JSON_VALUE(body,'$.capability')='render-markdown-html-page' AND JSON_VALUE(body,'$.result.status')='COMPLETE'
 AND JSON_VALUE(body,'$.objectiveBinding.conversationId')=@id AND JSON_VALUE(body,'$.objectiveBinding.objectiveHash')=@hash
 ORDER BY r.stamp DESC,r.pk DESC;
SELECT (SELECT @id conversationId,@objective objective,JSON_VALUE(@root,'$.objectiveFulfillment') outerStatus,JSON_QUERY(@root,'$.verification') verification,
 @turn publicationTurn,@turnDigest publicationReceiptDigest,JSON_QUERY(@receipt) publication,
 (SELECT TOP(1) c.content_bytes FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
 WHERE a.artifact_kind='markdown-page:'+SUBSTRING(JSON_VALUE(@receipt,'$.inputDigest'),8,64) AND a.content_digest=TRY_CONVERT(binary(32),SUBSTRING(JSON_VALUE(@receipt,'$.contentDigest'),8,64),2)
 AND a.content_digest=HASHBYTES('SHA2_256',c.content_bytes)) bytes FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;
