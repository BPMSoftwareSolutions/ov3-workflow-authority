DECLARE @planned int=(SELECT COUNT(*) FROM OPENJSON(@input));
DECLARE @retained int=(SELECT COUNT(*) FROM OPENJSON(@input) WHERE JSON_VALUE(value,'$.result.status')='RETAINED' AND JSON_VALUE(value,'$.result.contentDigest') LIKE 'sha256:%');
SELECT (SELECT 'python-library-research-pass.v1' AS contractId,CASE WHEN @planned=@retained THEN 'SETTLED' ELSE 'PARTIAL' END AS status,
    @planned AS batchesReturned,@retained AS batchesRetained,'assemble-python-library-report' AS coverageCheck,
    'Call assemble-python-library-report with the same conversationId to read coverage and publish the report.' AS nextAction FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
