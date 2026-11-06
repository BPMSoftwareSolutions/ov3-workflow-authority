-- Run with the declared sql-database-reader using a conversationId. Select only this conversation.
DECLARE @job varchar(36)=LOWER(CONVERT(varchar(36),TRY_CONVERT(uniqueidentifier,JSON_VALUE(@input,'$.conversationId'))));
IF @job IS NULL THROW 51000,'REUSE_CONVERSATION_REQUIRED',1;
DECLARE @kind nvarchar(100)=N'objective-pursuit:'+@job;
DECLARE @rows TABLE(kind nvarchar(200),digest varchar(71),body varchar(max) COLLATE Latin1_General_100_BIN2_UTF8,stamp datetime2,pk bigint);
INSERT @rows SELECT a.artifact_kind,'sha256:'+LOWER(CONVERT(varchar(64),a.content_digest,2)),
    c.content_bytes,a.registered_date,a.content_artifact_pk
FROM model.content_artifact a JOIN source.content_object c ON c.content_digest=a.content_digest
WHERE (a.artifact_kind=@kind OR a.artifact_kind LIKE @kind+'#%') AND HASHBYTES('SHA2_256',c.content_bytes)=a.content_digest;
DECLARE @root nvarchar(max)=(SELECT TOP(1) body FROM @rows WHERE kind=@kind ORDER BY stamp DESC,pk DESC);
IF @root IS NULL THROW 51000,'REUSE_NO_RETAINED_OBJECTIVE',1;
WITH latest AS (SELECT kind,digest,CONVERT(nvarchar(max),body) COLLATE DATABASE_DEFAULT AS body,stamp,
    ROW_NUMBER() OVER(PARTITION BY kind ORDER BY stamp DESC,pk DESC) AS recency FROM @rows WHERE kind<>@kind)
SELECT (SELECT @job AS conversationId,JSON_VALUE(@root,'$.objective') AS objective,JSON_VALUE(@root,'$.startedAt') AS startedAt,
    JSON_VALUE(@root,'$.endedAt') AS endedAt,JSON_VALUE(@root,'$.objectiveFulfillment') AS objectiveFulfillment,
    JSON_QUERY(@root,'$.verification') AS verification,JSON_VALUE(@root,'$.verification.artifactDigest') AS contentDigest,
    JSON_QUERY((SELECT @job AS conversationId,JSON_VALUE(body,'$.action') AS action,TRY_CONVERT(int,JSON_VALUE(body,'$.turn')) AS turn,
        JSON_VALUE(body,'$.capability') AS capability,JSON_VALUE(body,'$.disposition') AS disposition,
        JSON_QUERY(CASE WHEN ISJSON(JSON_VALUE(body,'$.inputText'))=1 THEN JSON_VALUE(body,'$.inputText') ELSE JSON_QUERY(history.value,'$.input') END) AS input,
        JSON_QUERY(body,'$.result') AS result,JSON_QUERY(body,'$.usage') AS usage,digest AS receiptDigest,stamp AS registeredAt
        FROM latest OUTER APPLY (SELECT TOP(1) h.value FROM OPENJSON(@root,'$.turns') h WHERE JSON_VALUE(h.value,'$.turn')=JSON_VALUE(body,'$.turn')
            AND JSON_VALUE(h.value,'$.capability')=JSON_VALUE(body,'$.capability')) history
        WHERE recency=1 AND ISJSON(body)=1 ORDER BY TRY_CONVERT(int,JSON_VALUE(body,'$.turn')) FOR JSON PATH)) AS receipts
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
