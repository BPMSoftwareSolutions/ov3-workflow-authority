DECLARE @proposal nvarchar(max)=JSON_QUERY(@input,'$.response.structuredValue');
DECLARE @context nvarchar(max)=(SELECT TOP (1) SUBSTRING(value,19,LEN(value)) FROM OPENJSON(@input,'$.receipt.requestLineage')
    WHERE type=1 AND LEFT(value,18)='objective-context:' AND ISJSON(SUBSTRING(value,19,LEN(value)))=1);
DECLARE @in nvarchar(max)=(SELECT value FROM OPENJSON(@proposal) WHERE [key]='inputSchemaJson' AND type=1),
        @out nvarchar(max)=(SELECT value FROM OPENJSON(@proposal) WHERE [key]='outputSchemaJson' AND type=1);
IF ISNULL(ISJSON(@in),0)=0 SET @in=NULL;
IF ISNULL(ISJSON(@out),0)=0 SET @out=NULL;
DECLARE @status nvarchar(40)=CASE
    WHEN ISNULL(JSON_VALUE(@input,'$.disposition'),'')<>'MODEL_RESPONSE_OBTAINED' THEN 'MODEL_FAILED'
    WHEN @context IS NULL OR JSON_VALUE(@context,'$.responseBodyHash') IS NULL THEN 'INVALID_PROPOSAL'
    WHEN JSON_VALUE(@proposal,'$.status') IN ('REMOVED','INSUFFICIENT_SOURCE') THEN JSON_VALUE(@proposal,'$.status')
    WHEN ISNULL(JSON_VALUE(@proposal,'$.status'),'') <> 'PROPOSED'
      OR NULLIF(TRIM(JSON_VALUE(@proposal,'$.operation')),'') IS NULL
      OR NULLIF(TRIM(JSON_VALUE(@proposal,'$.effects')),'') IS NULL OR NULLIF(TRIM(JSON_VALUE(@proposal,'$.constraints')),'') IS NULL
      OR ISNULL(JSON_VALUE(@in,'$.type'),'') <> 'object' OR ISNULL(JSON_VALUE(@out,'$.type'),'') <> 'object'
      OR NOT EXISTS(SELECT 1 FROM OPENJSON(@in,'$.properties')) OR NOT EXISTS(SELECT 1 FROM OPENJSON(@out,'$.properties'))
      OR LEFT(ISNULL(JSON_QUERY(@in,'$.required'),''),1)<>'[' OR LEFT(ISNULL(JSON_QUERY(@out,'$.required'),''),1)<>'['
      OR NOT EXISTS(SELECT 1 FROM OPENJSON(@proposal,'$.apis') WHERE type=1 AND NULLIF(TRIM(value),'') IS NOT NULL)
      OR NOT EXISTS(SELECT 1 FROM OPENJSON(@proposal,'$.failureModes') WHERE type=1 AND NULLIF(TRIM(value),'') IS NOT NULL)
      OR LEFT(ISNULL(JSON_QUERY(@proposal,'$.useCases'),''),1)<>'['
      OR (SELECT COUNT(*) FROM OPENJSON(@proposal,'$.useCases'))<>5
      OR (SELECT COUNT(DISTINCT TRIM(value)) FROM OPENJSON(@proposal,'$.useCases') WHERE type=1 AND NULLIF(TRIM(value),'') IS NOT NULL)<>5 THEN 'INVALID_PROPOSAL'
    ELSE 'PROPOSED' END;
SELECT (SELECT 'python-library-binding-proposal.v1' AS contractId,@status AS status,JSON_QUERY(@context) AS source,
    CASE WHEN @status='PROPOSED' THEN JSON_VALUE(@proposal,'$.operation') END AS operation,
    JSON_QUERY(CASE WHEN @status='PROPOSED' THEN JSON_QUERY(@proposal,'$.apis') END) AS apis,
    JSON_QUERY(CASE WHEN @status='PROPOSED' THEN @in END) AS inputContract,
    JSON_QUERY(CASE WHEN @status='PROPOSED' THEN @out END) AS outputContract,
    JSON_QUERY(CASE WHEN @status='PROPOSED' THEN JSON_QUERY(@proposal,'$.failureModes') END) AS failureModes,
    CASE WHEN @status='PROPOSED' THEN JSON_VALUE(@proposal,'$.effects') END AS effects,
    CASE WHEN @status='PROPOSED' THEN JSON_VALUE(@proposal,'$.constraints') END AS constraints,
    JSON_QUERY(CASE WHEN @status='PROPOSED' THEN JSON_QUERY(@proposal,'$.useCases') END) AS useCases
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
