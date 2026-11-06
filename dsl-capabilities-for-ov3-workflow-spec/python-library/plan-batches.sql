DECLARE @limit int=COALESCE(TRY_CONVERT(int,TRY_CONVERT(float,JSON_VALUE(@input,'$.maxModules'))),400);
IF @limit NOT BETWEEN 1 AND 400 THROW 51000,'PYTHON_REPORT_BATCH_BOUND_INVALID',1;
DECLARE @work TABLE(ord int, url nvarchar(900));
INSERT @work SELECT TOP (@limit) ROW_NUMBER() OVER (ORDER BY m.name),m.url FROM @inventory m
  LEFT JOIN @entries e ON m.name=e.name WHERE m.removed=0 AND e.name IS NULL ORDER BY m.name;
DECLARE @batches nvarchar(max)=(SELECT 'research-python-library-batch' AS executionTarget,'sidefx:capabilities' AS executionNamespace,
    'research-python-library-batch' AS executionScenario,'json' AS inputType,
    JSON_QUERY((SELECT JSON_QUERY((SELECT w.url FROM @work w WHERE (w.ord-1)/5=g.grp ORDER BY w.ord FOR JSON PATH)) AS sources
                FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS dispatchRequest
    FROM (SELECT DISTINCT (ord-1)/5 AS grp FROM @work) g ORDER BY g.grp FOR JSON PATH);
SELECT (SELECT JSON_QUERY(COALESCE(@batches,'[]')) AS batches FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
