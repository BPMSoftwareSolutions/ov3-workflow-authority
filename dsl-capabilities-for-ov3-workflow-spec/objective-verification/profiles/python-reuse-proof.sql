DECLARE @manifestJson nvarchar(max)=CASE WHEN ISJSON(@report)=1 THEN @report END;
DECLARE @specimen nvarchar(12)=JSON_VALUE(@manifestJson,'$.specimen');
DECLARE @variant nvarchar(max)=(SELECT value FROM OPENJSON(@profile,'$.variants') WHERE [key] COLLATE Latin1_General_100_BIN2=@specimen);
DECLARE @fixtureRequest nvarchar(max)=JSON_VALUE(@variant,'$.request'),@need nvarchar(max)=JSON_QUERY(@variant,'$.required');
DECLARE @oracle nvarchar(max)=JSON_QUERY(@variant,'$.manifest');
-- Compare typed scalar fields, including CRLF and significant trailing space. Also reject extra and duplicate keys.
DECLARE @manifestOk bit=IIF(@oracle IS NOT NULL AND @manifestJson IS NOT NULL
    AND (SELECT COUNT(*) FROM OPENJSON(@oracle))=(SELECT COUNT(*) FROM OPENJSON(@manifestJson))
    AND NOT EXISTS(SELECT [key] COLLATE Latin1_General_100_BIN2,type,CONVERT(varbinary(max),value) FROM OPENJSON(@oracle)
        EXCEPT SELECT [key] COLLATE Latin1_General_100_BIN2,type,CONVERT(varbinary(max),value) FROM OPENJSON(@manifestJson)),1,0);
DECLARE @pilotTurns TABLE(turnNumber int, cap nvarchar(120), receiptDigest varchar(71), requestJson nvarchar(max), resultJson nvarchar(max));
DECLARE @pilotBytes TABLE(artifact_kind nvarchar(200) COLLATE Latin1_General_100_BIN2_UTF8,content_digest binary(32),payload varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
-- Use the latest receipt in each ordinal slot in the publication's own pursuit.
-- A previous completed pursuit with the same caller-supplied UUID is a boundary.
DECLARE @previousFinish datetime2=(SELECT MAX(stamp) FROM @evidence WHERE kind=@rootKind AND stamp<@publishedAt);
;WITH slot AS (
 SELECT a.artifact_kind,a.content_digest,ROW_NUMBER() OVER(PARTITION BY a.artifact_kind ORDER BY a.registered_date DESC,a.content_artifact_pk DESC) AS revision
 FROM model.content_artifact a WHERE a.artifact_kind LIKE @rootKind+'#%' AND a.registered_date<=@publishedAt
 AND (@previousFinish IS NULL OR a.registered_date>@previousFinish)
)
INSERT @pilotBytes SELECT s.artifact_kind,s.content_digest,c.content_bytes FROM slot s
JOIN source.content_object c ON c.content_digest=s.content_digest
WHERE s.revision=1 AND c.content_digest=HASHBYTES('SHA2_256',c.content_bytes);
INSERT @pilotTurns SELECT TRY_CONVERT(int,JSON_VALUE(t.body,'$.turn')),JSON_VALUE(t.body,'$.capability'),
    'sha256:'+LOWER(CONVERT(varchar(64),a.content_digest,2)),q.value,JSON_QUERY(t.body,'$.result')
FROM @pilotBytes a CROSS APPLY(SELECT CONVERT(nvarchar(max),a.payload) body)t
CROSS APPLY OPENJSON(t.body) q
WHERE q.[key]='inputText' AND q.type=1 AND ISJSON(q.value)=1 AND JSON_VALUE(t.body,'$.action')='CALL'
    AND JSON_VALUE(t.body,'$.disposition')='terminated' AND JSON_VALUE(t.body,'$.result.status')='COMPUTED'
    AND JSON_VALUE(t.body,'$.result.runtime.implementation')='cpython' AND JSON_VALUE(t.body,'$.result.runtime.version') IS NOT NULL
    AND TRY_CONVERT(int,JSON_VALUE(t.body,'$.turn')) BETWEEN 1 AND @turn-1
    AND (NOT EXISTS(SELECT 1 FROM OPENJSON(t.body) member WHERE member.[key]='objectiveBinding')
      OR (JSON_VALUE(t.body,'$.objectiveBinding.conversationId')=@conversation AND JSON_VALUE(t.body,'$.objectiveBinding.objectiveHash')=@objectiveHash))
    AND JSON_VALUE(@record,'$.objectiveBinding.conversationId')=@conversation AND JSON_VALUE(@record,'$.objectiveBinding.objectiveHash')=@objectiveHash
    AND (NOT EXISTS(SELECT 1 FROM @evidence WHERE kind=@rootKind AND stamp>=@publishedAt)
      OR EXISTS(SELECT 1 FROM OPENJSON(@root,'$.turns') h WHERE JSON_VALUE(h.value,'$.turn')=JSON_VALUE(t.body,'$.turn') COLLATE Latin1_General_100_BIN2
        AND JSON_VALUE(h.value,'$.capability')=JSON_VALUE(t.body,'$.capability') COLLATE Latin1_General_100_BIN2
        AND JSON_VALUE(h.value,'$.action')='CALL' AND JSON_VALUE(h.value,'$.disposition')='terminated' AND JSON_VALUE(h.value,'$.status')='COMPUTED'))
    AND a.artifact_kind=@rootKind+'#'+JSON_VALUE(t.body,'$.turn');
DECLARE @matchedPilot TABLE(cap nvarchar(120),turnNumber int,receiptDigest varchar(71),runtime nvarchar(60),requestJson nvarchar(max));
INSERT @matchedPilot SELECT p.cap,p.turnNumber,p.receiptDigest,JSON_VALUE(p.resultJson,'$.runtime.version'),p.requestJson FROM @pilotTurns p
JOIN OPENJSON(@need) req ON req.[key] COLLATE Latin1_General_100_BIN2=p.cap
WHERE JSON_VALUE(p.resultJson,'$.contractId')=p.cap+'-result.v1'
    AND NOT EXISTS(SELECT [key] COLLATE Latin1_General_100_BIN2,type,CONVERT(varbinary(max),value) FROM OPENJSON(req.value,'$.input')
        EXCEPT SELECT [key] COLLATE Latin1_General_100_BIN2,type,CONVERT(varbinary(max),value) FROM OPENJSON(p.requestJson))
    AND NOT EXISTS(SELECT [key] COLLATE Latin1_General_100_BIN2,type,CONVERT(varbinary(max),value) FROM OPENJSON(req.value,'$.value') WHERE type<>4
        EXCEPT SELECT [key] COLLATE Latin1_General_100_BIN2,type,CONVERT(varbinary(max),value) FROM OPENJSON(p.resultJson,'$.value') WHERE type<>4)
    AND (p.cap<>'python-textwrap' OR (JSON_QUERY(p.resultJson,'$.value.lines') IS NOT NULL
        AND (SELECT COUNT(*) FROM OPENJSON(req.value,'$.value.lines'))=(SELECT COUNT(*) FROM OPENJSON(p.resultJson,'$.value.lines'))
        AND NOT EXISTS(SELECT [key],type,CONVERT(varbinary(max),value) FROM OPENJSON(req.value,'$.value.lines')
            EXCEPT SELECT [key],type,CONVERT(varbinary(max),value) FROM OPENJSON(p.resultJson,'$.value.lines'))));
DECLARE @wrapped int=(SELECT MIN(turnNumber) FROM @matchedPilot WHERE cap='python-textwrap');
DECLARE @escaped int=(SELECT MIN(turnNumber) FROM @matchedPilot WHERE cap='python-html' AND turnNumber>@wrapped);
DECLARE @base64Turn int=(SELECT MIN(turnNumber) FROM @matchedPilot WHERE cap='python-base64' AND (@specimen='ledger' OR turnNumber>@escaped));
DECLARE @crcTurn int=(SELECT MIN(turnNumber) FROM @matchedPilot WHERE cap='python-binascii' AND turnNumber>@base64Turn);
DECLARE @hashTurn int=(SELECT MIN(turnNumber) FROM @matchedPilot WHERE cap='python-hashlib' AND turnNumber>@base64Turn);
DECLARE @planned int=(SELECT COUNT(*) FROM OPENJSON(@need)),@observed int=(SELECT COUNT(DISTINCT cap) FROM @matchedPilot);
DECLARE @firstInput nvarchar(max)=(SELECT TOP(1) CASE WHEN @specimen='notice' THEN JSON_VALUE(requestJson,'$.text') ELSE JSON_VALUE(requestJson,'$.data') END
    FROM @matchedPilot WHERE turnNumber=IIF(@specimen='notice',@wrapped,@base64Turn));
DECLARE @sourceHash varchar(71)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@firstInput COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @checks VALUES
    ('FIXTURE_SCOPE',IIF(@variant IS NOT NULL AND JSON_VALUE(@receipt,'$.specimen')=@specimen AND CONVERT(varbinary(max),@fixtureRequest)=CONVERT(varbinary(max),@original)
        AND @sourceHash=JSON_VALUE(@variant,'$.sourceDigest') AND (JSON_VALUE(@input,'$.expectedSourceDigest') IS NULL OR JSON_VALUE(@input,'$.expectedSourceDigest')=@sourceHash)
        AND JSON_VALUE(@input,'$.expectedSourceVersion') IS NULL,1,0)),
    ('RECEIPT_INPUT_OUTPUT',IIF(@planned>0 AND @planned=@observed,1,0)),
    ('EXECUTION_ORDER',IIF(@crcTurn IS NOT NULL AND @hashTurn IS NOT NULL,1,0)),
    ('MANIFEST_EQUALS_ORACLE',@manifestOk);
SET @source=(SELECT @specimen AS specimen,@sourceHash AS sourceDigest,JSON_VALUE(@profile,'$.sourceDigest') AS corpusDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SET @metrics=(SELECT @planned AS requiredOperations,@observed AS observedOperations FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SET @proofSet=(SELECT cap AS capability,turnNumber AS turn,receiptDigest AS digest,runtime FROM @matchedPilot WHERE turnNumber IN (@wrapped,@escaped,@base64Turn,@crcTurn,@hashTurn) ORDER BY turnNumber FOR JSON PATH);
INSERT @observations VALUES
    ('source',QUOTENAME(JSON_VALUE(@variant,'$.sourceDigest'),'"'),QUOTENAME(@sourceHash,'"')),
    ('operations',CONVERT(varchar(12),@planned),CONVERT(varchar(12),@observed)),
    ('manifest','"json-manifest"',CASE WHEN @manifestOk=1 THEN '"json-manifest"' END);
IF @fixtureRequest IS NOT NULL SET @profile=JSON_MODIFY(@profile,'$.scopeDefinition',@fixtureRequest);
