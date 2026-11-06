IF JSON_VALUE(@opend,'$.action')=N'ANSWER' AND JSON_QUERY(@opend,'$.verificationExpected') IS NOT NULL
  BEGIN
    DECLARE @checked nvarchar(max)=JSON_QUERY(@input,'$.result');
    DECLARE @expectedObjective varchar(71)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),analysis.fv_session_text(@pk+N'obj'))),2));
    IF NOT EXISTS (SELECT 1 WHERE @otarget=N'verify-objective-fulfillment' AND JSON_VALUE(@input,'$.disposition')='terminated'
       AND JSON_VALUE(@checked,'$.contractId')='objective-verification.v1' AND JSON_VALUE(@checked,'$.status') IN ('FULFILLED','UNVERIFIED')
       AND JSON_VALUE(@checked,'$.conversationId')=@conv AND JSON_VALUE(@checked,'$.objectiveHash')=@expectedObjective
       AND JSON_VALUE(@checked,'$.publicationTurn')=JSON_VALUE(@opend,'$.verificationExpected.publicationTurn')
       AND JSON_VALUE(@checked,'$.artifactDigest')=JSON_VALUE(@opend,'$.verificationExpected.artifactDigest')
       AND JSON_VALUE(@checked,'$.publicationReceiptDigest')=JSON_VALUE(@opend,'$.verificationExpected.publicationReceiptDigest'))
       SET @checked=(SELECT 'objective-verification.v1' AS contractId,'UNVERIFIED' AS status,'VERIFIER_RETURN_UNAVAILABLE_OR_UNBOUND' AS reason,
           @conv AS conversationId,JSON_QUERY(@opend,'$.verificationExpected') AS expected FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    SET @checked=JSON_MODIFY(@checked,'$.recordKind',N'objective-pursuit:'+@conv+N'#'+JSON_VALUE(@opend,'$.turn'));
    SET @opend=JSON_MODIFY(@opend,'$.verification',JSON_QUERY(@checked));
    SET @nk=@pk+N'verification'; EXEC analysis.put_session_text @key=@nk,@value=@checked;
  END;
