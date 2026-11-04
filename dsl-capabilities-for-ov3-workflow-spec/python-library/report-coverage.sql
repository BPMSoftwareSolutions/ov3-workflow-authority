-- Read only the named conversations' inventory and proposal turns. Do not read conversation prompts, replies or memory.
DECLARE @job uniqueidentifier=TRY_CONVERT(uniqueidentifier,JSON_VALUE(@input,'$.conversationId'));
IF @job IS NULL THROW 51000,'PYTHON_REPORT_CONVERSATION_REQUIRED',1;
DECLARE @scope nvarchar(250)=JSON_VALUE(@input,'$.module');
DECLARE @ids TABLE(id uniqueidentifier PRIMARY KEY);
INSERT @ids VALUES(@job);
INSERT @ids SELECT DISTINCT TRY_CONVERT(uniqueidentifier,value) FROM OPENJSON(@input,'$.continuations')
    WHERE TRY_CONVERT(uniqueidentifier,value) IS NOT NULL AND TRY_CONVERT(uniqueidentifier,value)<>@job;
DECLARE @turns TABLE (id uniqueidentifier, seq bigint, result nvarchar(max), cap nvarchar(100));
INSERT @turns
SELECT i.id, a.content_artifact_pk, JSON_QUERY(t.body,'$.result'), JSON_VALUE(t.body,'$.capability')
FROM @ids i JOIN model.content_artifact a ON a.artifact_kind LIKE ('objective-pursuit:'+LOWER(CONVERT(varchar(36),i.id))+'#%') COLLATE Latin1_General_100_BIN2
JOIN source.content_object co ON co.content_digest=a.content_digest
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS body) t
WHERE ISJSON(t.body)=1 AND JSON_VALUE(t.body,'$.action')='CALL'
  AND JSON_VALUE(t.body,'$.capability') IN ('read-python-library-sources','propose-python-library-binding');
DECLARE @index nvarchar(max)=(SELECT TOP (1) result FROM @turns WHERE id=@job AND cap='read-python-library-sources'
    AND JSON_VALUE(result,'$.status')='LISTED' ORDER BY seq DESC);
DECLARE @hash nvarchar(100)=JSON_VALUE(@index,'$.moduleIndexHash'), @total int=TRY_CONVERT(int,JSON_VALUE(@index,'$.indexedCount'));
DECLARE @inventory TABLE (name nvarchar(250) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, url nvarchar(900), section nvarchar(250), removed bit, summary nvarchar(1500));
INSERT @inventory
SELECT m.name,MAX(m.url),MAX(m.section),CONVERT(bit,MAX(CONVERT(int,m.removed))),MAX(m.summary)
FROM @turns t CROSS APPLY OPENJSON(t.result,'$.modules') WITH
(name nvarchar(250) '$.module',url nvarchar(900) '$.documentationUrl',section nvarchar(250),removed bit,summary nvarchar(1500)) m
WHERE id=@job AND cap='read-python-library-sources' AND JSON_VALUE(t.result,'$.moduleIndexHash')=@hash AND JSON_VALUE(t.result,'$.status')='LISTED'
  AND (@scope IS NULL OR m.name COLLATE Latin1_General_100_BIN2=@scope)
GROUP BY m.name;
IF @hash IS NULL OR NOT EXISTS (SELECT 1 FROM @inventory) OR (@scope IS NULL AND @total<>(SELECT COUNT(*) FROM @inventory))
    THROW 51000,'PYTHON_REPORT_SOURCE_INVENTORY_INCOMPLETE',1;
DECLARE @entries TABLE(name nvarchar(250) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, proposal nvarchar(max));
-- Reuse public batch products built since this snapshot. Their only inputs are official module documentation URLs.
DECLARE @since datetime2=(SELECT MIN(a.registered_date) FROM model.content_artifact a
    JOIN @turns t ON t.seq=a.content_artifact_pk WHERE t.id=@job AND t.cap='read-python-library-sources'
    AND JSON_VALUE(t.result,'$.moduleIndexHash')=@hash);
