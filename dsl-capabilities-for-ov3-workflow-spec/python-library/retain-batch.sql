IF LEFT(LTRIM(@input),1)<>'[' OR NOT EXISTS(SELECT 1 FROM OPENJSON(@input)) THROW 51000,'PYTHON_BATCH_EMPTY',1;
DECLARE @rows nvarchar(max)=(SELECT '['+STRING_AGG(CONVERT(nvarchar(max),JSON_QUERY(value,'$.result')),',') WITHIN GROUP (ORDER BY CONVERT(int,[key]))+']'
    FROM OPENJSON(@input) WHERE JSON_VALUE(value,'$.result.contractId')='python-library-binding-proposal.v1');
IF ISNULL(ISJSON(@rows),0)<>1 THROW 51000,'PYTHON_BATCH_NO_VALID_RESULTS',1;
DECLARE @body nvarchar(max)=(SELECT 'python-library-proposals-batch.v1' AS contractId,JSON_QUERY(@rows) AS entries FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SELECT (SELECT 'content-artifact-change.v1' AS contractId,'public-python-library-research-batch.v1' AS artifactKind,@body AS [text],
    'read-harness-authoring-state' AS verificationCapabilityId,JSON_QUERY(N'{"resolvedDisposition":"terminated"}') AS route,
    JSON_QUERY(N'{"input":{"changeKind":"content-artifact-change","includeDefinitions":true},"expected":{"disposition":"terminated"}}') AS preflight FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
