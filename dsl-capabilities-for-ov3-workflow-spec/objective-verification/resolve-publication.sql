DECLARE @conversation varchar(36)=LOWER(CONVERT(varchar(36),TRY_CONVERT(uniqueidentifier,JSON_VALUE(@input,'$.conversationId')))),
        @turn int=TRY_CONVERT(int,TRY_CONVERT(float,JSON_VALUE(@input,'$.publicationTurn')));
DECLARE @objective nvarchar(max),@supplied nvarchar(max)=(SELECT value FROM OPENJSON(@input) WHERE [key]='objective' AND type=1);
DECLARE @evidence TABLE (kind nvarchar(200), digest binary(32), bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8, stamp datetime2);
DECLARE @rootKind nvarchar(120)='objective-pursuit:'+@conversation;
DECLARE @turnKind nvarchar(140)=@rootKind+'#'+CONVERT(varchar(12),@turn);
INSERT @evidence
SELECT a.artifact_kind,a.content_digest,c.content_bytes,a.registered_date FROM model.content_artifact a
JOIN source.content_object c ON c.content_digest=a.content_digest
WHERE a.artifact_kind IN (@rootKind,@turnKind) AND a.content_digest=HASHBYTES('SHA2_256',c.content_bytes);
DECLARE @root nvarchar(max)=(SELECT TOP(1) CONVERT(nvarchar(max),bytes) FROM @evidence WHERE kind=@rootKind ORDER BY stamp DESC);
DECLARE @record nvarchar(max),@turnDigest varchar(71),@publishedAt datetime2;
SELECT TOP(1) @record=CONVERT(nvarchar(max),bytes),@turnDigest='sha256:'+LOWER(CONVERT(varchar(64),digest,2)),@publishedAt=stamp FROM @evidence WHERE kind=@turnKind ORDER BY stamp DESC;
SELECT @objective=value FROM OPENJSON(@root) WHERE [key]='objective' AND type=1;
DECLARE @original nvarchar(max)=COALESCE(@objective,@supplied);
DECLARE @objectiveHash varchar(71)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@original)),2));
DECLARE @receipt nvarchar(max)=JSON_QUERY(@record,'$.result'),@producer nvarchar(400)=JSON_VALUE(@record,'$.capability');
DECLARE @contract nvarchar(200)=JSON_VALUE(@receipt,'$.contractId'),@artifact varchar(71)=JSON_VALUE(@receipt,'$.contentDigest');
DECLARE @profile nvarchar(max),@profileId varchar(200),@source nvarchar(max),@proofSet nvarchar(max)=N'[]',@metrics nvarchar(max);
DECLARE @checks TABLE (code varchar(70) PRIMARY KEY,passed bit NOT NULL);
DECLARE @observations TABLE (id varchar(60) PRIMARY KEY, expectedJson nvarchar(max), observedJson nvarchar(max));
SELECT @profile=CASE WHEN COUNT(*)=1 THEN MAX(p.value) END FROM OPENJSON(@profiles) p WHERE JSON_VALUE(p.value,'$.contract')=@contract
    AND JSON_VALUE(@receipt,JSON_VALUE(p.value,'$.sourceDigestPath'))=JSON_VALUE(p.value,'$.sourceDigest')
    AND EXISTS(SELECT 1 FROM OPENJSON(p.value,'$.producers') q WHERE q.value COLLATE Latin1_General_100_BIN2=@producer);
SET @profileId=JSON_VALUE(@profile,'$.id');
INSERT @checks VALUES
 ('SUPPORTED_PROFILE',IIF(@profile IS NOT NULL,1,0)),
 ('ORIGINAL_OBJECTIVE',IIF(NULLIF(TRIM(@original),'') IS NOT NULL AND LEN(@original)<=16000 AND
    ((JSON_VALUE(@root,'$.contractId')='objective-pursuit-record.v1' AND JSON_VALUE(@root,'$.conversationId')=@conversation AND @objective IS NOT NULL
        AND (@supplied IS NULL OR CONVERT(varbinary(max),@objective)=CONVERT(varbinary(max),@supplied)))
     OR (@root IS NULL AND JSON_VALUE(@record,'$.objectiveBinding.conversationId')=@conversation AND JSON_VALUE(@record,'$.objectiveBinding.objectiveHash')=@objectiveHash)),1,0)),
 ('PUBLICATION_TURN',IIF(@turn>0 AND @turn=TRY_CONVERT(int,JSON_VALUE(@record,'$.turn')) AND JSON_VALUE(@record,'$.action')='CALL' AND JSON_VALUE(@record,'$.blocked') IS NULL AND JSON_VALUE(@record,'$.disposition')='terminated',1,0)),
 ('PUBLICATION_COMPLETE',IIF(JSON_VALUE(@receipt,'$.status')='COMPLETE',1,0)),
 ('EXPECTED_ARTIFACT',IIF(JSON_VALUE(@input,'$.expectedArtifactDigest') IS NULL OR JSON_VALUE(@input,'$.expectedArtifactDigest') COLLATE Latin1_General_100_BIN2=@artifact,1,0));
DECLARE @raw TABLE (bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
INSERT @raw SELECT TOP(1) c.content_bytes FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
    WHERE a.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@artifact,8,64),2) AND a.content_digest=HASHBYTES('SHA2_256',c.content_bytes)
      AND LEFT(a.artifact_kind,LEN(JSON_VALUE(@profile,'$.publishedKindPrefix')))=JSON_VALUE(@profile,'$.publishedKindPrefix')
      AND a.registered_date<=@publishedAt;
DECLARE @report nvarchar(max)=(SELECT CONVERT(nvarchar(max),bytes) FROM @raw);
INSERT @checks VALUES ('PUBLISHED_BYTES',IIF(@report IS NOT NULL AND LEN(JSON_VALUE(@receipt,'$.contentDigest'))=71 AND LEFT(@artifact,7)='sha256:',1,0));
