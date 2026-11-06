capability research-python-library-batch
feature research-python-library-batch sha256:6fa6e0e407ea017346103c411c3cf214976f8b063de2639d4b140854a2339551
intent: Research up to five official Python library documentation URLs using the proposal capability and retain the structured public results as one reusable batch.
outcome: A retained public research batch digest.
inquiry: Research this batch of Python module URLs.
input contract research-python-library-batch-request.v1 {"type":"object","additionalProperties":false,"properties":{"sources":{"type":"array","minItems":1,"maxItems":5,"items":{"type":"object","required":["url"],"properties":{"url":{"type":"string","maxLength":900}}}}},"required":["sources"]}
output contract python-library-batch-receipt.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"python-library-batch-receipt.v1"},"status":{"enum":["RETAINED"]},"contentDigest":{"type":"string"}}}
cli display outcome as json
scenario research-python-library-batch root terminal
variants: RETAINED:success
given: up to five distinct official Python library documentation URLs
when: OV3 invokes the binding proposal provider for each URL and retains the returned entries together
then: OV3 returns the retained batch digest
operation research-python-library-batch.plan uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","resultColumn":"value","statement":"DECLARE @urls TABLE(ord int, url nvarchar(900)); INSERT @urls SELECT TRY_CONVERT(int,j.[key]),JSON_VALUE(j.value,'$.url') FROM OPENJSON(@input,'$.sources') j; IF (SELECT COUNT(*) FROM @urls) NOT BETWEEN 1 AND 5 OR EXISTS (SELECT 1 FROM @urls WHERE url IS NULL OR url NOT LIKE 'https://docs.python.org/3/library/%.html%' OR SUBSTRING(url,35,900) COLLATE Latin1_General_100_BIN2 LIKE '%[^A-Za-z0-9_.#-]%') OR EXISTS (SELECT url FROM @urls GROUP BY url HAVING COUNT(*)>1) THROW 51000,'PYTHON_MODULE_BATCH_INVALID',1; SELECT (SELECT JSON_QUERY((SELECT 'propose-python-library-binding' AS executionTarget,'sidefx:capabilities' AS executionNamespace, 'propose-python-library-binding' AS executionScenario,'json' AS inputType,JSON_QUERY((SELECT url FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS dispatchRequest FROM @urls ORDER BY ord FOR JSON PATH)) AS modules FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;"}
input input from research-python-library-batch $
operation research-python-library-batch.research kind for-each port research-python-library-batch-research over result.value.modules max 5
operation research-python-library-batch.prepare uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","resultColumn":"value","statement":"IF LEFT(LTRIM(@input),1)<>'[' OR NOT EXISTS(SELECT 1 FROM OPENJSON(@input)) THROW 51000,'PYTHON_BATCH_EMPTY',1; DECLARE @rows nvarchar(max)=(SELECT '['+STRING_AGG(CONVERT(nvarchar(max),JSON_QUERY(value,'$.result')),',') WITHIN GROUP (ORDER BY CONVERT(int,[key]))+']' FROM OPENJSON(@input) WHERE JSON_VALUE(value,'$.result.contractId')='python-library-binding-proposal.v1'); IF ISNULL(ISJSON(@rows),0)<>1 THROW 51000,'PYTHON_BATCH_NO_VALID_RESULTS',1; DECLARE @body nvarchar(max)=(SELECT 'python-library-proposals-batch.v1' AS contractId,JSON_QUERY(@rows) AS entries FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); SELECT (SELECT 'content-artifact-change.v1' AS contractId,'public-python-library-research-batch.v1' AS artifactKind,@body AS [text], 'read-harness-authoring-state' AS verificationCapabilityId,JSON_QUERY(N'{\"resolvedDisposition\":\"terminated\"}') AS route, JSON_QUERY(N'{\"input\":{\"changeKind\":\"content-artifact-change\",\"includeDefinitions\":true},\"expected\":{\"disposition\":\"terminated\"}}') AS preflight FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;"}
input input from research-python-library-batch.research $
operation research-python-library-batch.publish uses provider apply-declared-change
config: {"contractId":"declared-change.v1","changeKind":"content-artifact-change"}
input payload from research-python-library-batch.prepare $.value
operation research-python-library-batch.finish uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","resultColumn":"value","statement":"DECLARE @row nvarchar(max)=COALESCE(JSON_VALUE(@input,'$.result[0][0].value'),JSON_QUERY(@input,'$.result[0][0]')); DECLARE @digest nvarchar(100)=JSON_VALUE(@row,'$.content_digest'); IF ISNULL(JSON_VALUE(@input,'$.disposition'),'')<>'COMMITTED' OR @digest IS NULL THROW 51000,'PYTHON_BATCH_NOT_RETAINED',1; SELECT (SELECT 'python-library-batch-receipt.v1' AS contractId,'RETAINED' AS status,@digest AS contentDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;"}
input input from research-python-library-batch.publish $
outcome from research-python-library-batch.finish $.value
platform bind research-python-library-batch-research
platform: sda-node-consumer-runtime.v1
config: {"providerCapabilityId":"propose-python-library-binding","providerId":"propose-python-library-binding","authoritySource":"DATABASE","capabilityIdPath":"executionTarget","namespacePath":"executionNamespace","scenarioPath":"executionScenario","requestPath":"dispatchRequest","resultPath":"result","lineageMode":"retain-nested-execution"}
