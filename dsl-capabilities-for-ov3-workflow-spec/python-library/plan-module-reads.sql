DECLARE @urls TABLE(ord int, url nvarchar(900));
INSERT @urls SELECT TRY_CONVERT(int,j.[key]),JSON_VALUE(j.value,'$.url') FROM OPENJSON(@input,'$.sources') j;
IF (SELECT COUNT(*) FROM @urls) NOT BETWEEN 1 AND 5 OR EXISTS (SELECT 1 FROM @urls WHERE url IS NULL OR url NOT LIKE 'https://docs.python.org/3/library/%.html%' OR SUBSTRING(url,35,900) COLLATE Latin1_General_100_BIN2 LIKE '%[^A-Za-z0-9_.#-]%')
    OR EXISTS (SELECT url FROM @urls GROUP BY url HAVING COUNT(*)>1) THROW 51000,'PYTHON_MODULE_BATCH_INVALID',1;
SELECT (SELECT JSON_QUERY((SELECT 'propose-python-library-binding' AS executionTarget,'sidefx:capabilities' AS executionNamespace,
    'propose-python-library-binding' AS executionScenario,'json' AS inputType,JSON_QUERY((SELECT url FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS dispatchRequest
    FROM @urls ORDER BY ord FOR JSON PATH)) AS modules FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
