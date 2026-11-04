DECLARE @ctx nvarchar(max)=JSON_QUERY(@input,'$.context');
DECLARE @answered bit=IIF(JSON_VALUE(@input,'$.status')='ANSWERED',1,0);
DECLARE @choice nvarchar(100)=JSON_VALUE(@input,'$.answers.scope.choice'),@confidence float=TRY_CONVERT(float,JSON_VALUE(@input,'$.answers.scope.confidence')),
    @label nvarchar(100)=JSON_VALUE(@ctx,'$.scopeLabel');
DECLARE @probability float=(SELECT TRY_CONVERT(float,value) FROM OPENJSON(@input,'$.answers.scope.probabilities') WHERE [key]=@label COLLATE Latin1_General_100_BIN2);
DECLARE @typedAnswer bit=IIF(JSON_VALUE(@input,'$.answers.scope.type')='choice'
    AND (SELECT COUNT(*) FROM OPENJSON(@input,'$.answers'))=1
    AND EXISTS(SELECT 1 FROM OPENJSON(@input,'$.answers.scope') WHERE [key]='choice' AND type=1 AND value IN (@label,'other','unspecified'))
    AND EXISTS(SELECT 1 FROM OPENJSON(@input,'$.answers.scope') WHERE [key]='confidence' AND type=2)
    AND (SELECT COUNT(DISTINCT [key]) FROM OPENJSON(@input,'$.answers.scope.probabilities'))=3
    AND NOT EXISTS(SELECT 1 FROM OPENJSON(@input,'$.answers.scope.probabilities') WHERE [key] NOT IN (@label,'other','unspecified') OR type<>2 OR TRY_CONVERT(float,value) NOT BETWEEN 0 AND 1),1,0);
DECLARE @ok bit=IIF(JSON_VALUE(@ctx,'$.evidenceStatus')='PROVED' AND EXISTS(SELECT 1 FROM OPENJSON(@ctx,'$.checks')) AND NOT EXISTS(SELECT 1 FROM OPENJSON(@ctx,'$.checks') WHERE ISNULL(JSON_VALUE(value,'$.passed'),'false')<>'true'),1,0);
DECLARE @status varchar(25)=CASE WHEN @ok=1 AND @answered=1 AND @typedAnswer=1 AND @choice=@label AND @confidence BETWEEN 0.90 AND 1 AND @probability BETWEEN 0.90 AND 1 THEN 'FULFILLED' ELSE 'UNVERIFIED' END;
DECLARE @reason varchar(50)=CASE WHEN @ctx IS NULL THEN 'VERIFICATION_CONTEXT_MISSING' WHEN @ok=0 THEN 'PROOF_CHECK_FAILED' WHEN @answered=0 THEN 'INFERENCE_UNAVAILABLE'
    WHEN @typedAnswer=0 THEN 'INVALID_TYPED_ANSWER' WHEN @choice<>@label THEN 'SCOPE_NOT_COVERED' WHEN @status<>'FULFILLED' THEN 'INFERENCE_UNCERTAIN' ELSE 'ALL_REQUIREMENTS_VERIFIED' END;
DECLARE @inference nvarchar(max)=(SELECT JSON_VALUE(@input,'$.model') AS model,CASE WHEN JSON_VALUE(@input,'$.route')='HOLD' THEN 'SKIPPED' ELSE JSON_VALUE(@input,'$.status') END AS status,@choice AS scopeChoice,@confidence AS confidence,@probability AS scopeProbability,
    0.90 AS minimumConfidence,JSON_QUERY(@input,'$.usage') AS usage FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SELECT JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(ISNULL(@ctx,N'{}'),'$.contractId','objective-verification.v1'),'$.status',@status),'$.reason',@reason),'$.inference',JSON_QUERY(@inference)) AS value;
