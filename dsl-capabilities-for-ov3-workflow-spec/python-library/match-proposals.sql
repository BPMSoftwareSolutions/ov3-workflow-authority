INSERT @turns
SELECT @job,a.content_artifact_pk,p.value,'propose-python-library-binding'
FROM model.content_artifact a JOIN source.content_object co ON co.content_digest=a.content_digest
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS body) b
CROSS APPLY OPENJSON(CASE WHEN ISJSON(b.body)=1 THEN b.body END,'$.entries') p
WHERE a.artifact_kind=N'public-python-library-research-batch.v1' AND a.registered_date>=@since
    AND JSON_VALUE(CASE WHEN ISJSON(b.body)=1 THEN b.body END,'$.contractId')='python-library-proposals-batch.v1';
INSERT @entries SELECT m.name,p.result FROM @inventory m CROSS APPLY (
    SELECT TOP (1) result FROM @turns t WHERE t.cap='propose-python-library-binding'
      AND JSON_VALUE(result,'$.contractId')='python-library-binding-proposal.v1' AND JSON_VALUE(result,'$.status')='PROPOSED'
      AND JSON_VALUE(result,'$.source.module') COLLATE Latin1_General_100_BIN2=m.name AND JSON_VALUE(result,'$.source.documentationUrl')=m.url
      AND JSON_VALUE(result,'$.source.responseBodyHash') LIKE 'sha256:%'
      AND JSON_QUERY(result,'$.inputContract') IS NOT NULL AND JSON_QUERY(result,'$.outputContract') IS NOT NULL
      AND (SELECT COUNT(DISTINCT TRIM(value)) FROM OPENJSON(result,'$.useCases') WHERE type=1 AND NULLIF(TRIM(value),'') IS NOT NULL)=5
    ORDER BY t.seq DESC) p WHERE m.removed=0;
