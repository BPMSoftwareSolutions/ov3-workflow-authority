DECLARE @row nvarchar(max)=COALESCE(JSON_VALUE(@input,'$.result[0][0].value'),JSON_QUERY(@input,'$.result[0][0]'));
DECLARE @digest nvarchar(100)=JSON_VALUE(@row,'$.content_digest');
IF ISNULL(JSON_VALUE(@input,'$.disposition'),'')<>'COMMITTED' OR @digest IS NULL THROW 51000,'PYTHON_BATCH_NOT_RETAINED',1;
SELECT (SELECT 'python-library-batch-receipt.v1' AS contractId,'RETAINED' AS status,@digest AS contentDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
