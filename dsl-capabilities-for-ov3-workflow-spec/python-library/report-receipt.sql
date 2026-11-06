DECLARE @row nvarchar(max)=COALESCE(JSON_VALUE(@input,'$.result[0][0].value'), JSON_QUERY(@input,'$.result[0][0]'));
DECLARE @hash nvarchar(100)=JSON_VALUE(@row,'$.content_digest');
IF ISNULL(JSON_VALUE(@input,'$.disposition'),'')<>'COMMITTED' OR @hash IS NULL THROW 51000,'PYTHON_REPORT_NOT_RETAINED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM source.content_object WHERE content_digest=TRY_CONVERT(binary(32),SUBSTRING(@hash,8,64),2));
DECLARE @end int=CHARINDEX('-->',@body);
DECLARE @meta nvarchar(max)=SUBSTRING(@body,5,CASE WHEN @end>4 THEN @end-5 ELSE 0 END);
IF ISNULL(ISJSON(@meta),0)<>1 THROW 51000,'PYTHON_REPORT_READBACK_FAILED',1;
SELECT JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(@meta,'$.contractId','python-library-report.v1'),'$.contentDigest',@hash),'$.filename','python-library-provider-report.md') AS value;
