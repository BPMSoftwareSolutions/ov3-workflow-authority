-- The answer turn already has a declared nested dispatch. Attach independent review to the latest business result.
   DECLARE @pubTurn int=(SELECT TOP(1) TRY_CONVERT(int,JSON_VALUE(value,'$.turn'))
      FROM OPENJSON(analysis.fv_session_text(@pk+N'turnsum'))
      WHERE JSON_VALUE(value,'$.action')='CALL' AND JSON_VALUE(value,'$.blocked') IS NULL
        AND JSON_VALUE(value,'$.capability')<>N'verify-objective-fulfillment'
      ORDER BY TRY_CONVERT(int,[key]) DESC);
   DECLARE @pubRow nvarchar(max),@pubHash varchar(71),@pubTurnHash varchar(71);
   SELECT TOP(1) @pubRow=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),
       @pubTurnHash='sha256:'+LOWER(CONVERT(varchar(64),co.content_digest,2))
      FROM model.content_artifact a JOIN source.content_object co ON co.content_digest=a.content_digest
      WHERE a.artifact_kind=N'objective-pursuit:'+@conv+'#'+CONVERT(varchar(12),@pubTurn) ORDER BY a.content_artifact_pk DESC;
   SET @pubHash=JSON_VALUE(@pubRow,'$.result.contentDigest');
   IF JSON_VALUE(@pubRow,'$.disposition')='terminated' AND JSON_VALUE(@pubRow,'$.result.contractId') IS NOT NULL
      AND LEFT(@pubHash,7)='sha256:' AND LEN(@pubHash)=71 AND TRY_CONVERT(binary(32),SUBSTRING(@pubHash,8,64),2) IS NOT NULL
   BEGIN
      SET @dtarget=N'verify-objective-fulfillment';
      SET @dout=(SELECT @dtarget AS executionTarget,@ns AS executionNamespace,@dtarget AS executionScenario,'json' AS inputType,
          JSON_QUERY((SELECT @conv AS conversationId,@pubTurn AS publicationTurn,analysis.fv_session_text(@pk+N'obj') AS objective,
          @pubHash AS expectedArtifactDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS dispatchRequest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      SET @dpend=JSON_MODIFY(@dpend,'$.verificationExpected',JSON_QUERY((SELECT @pubTurn AS publicationTurn,
          @pubHash AS artifactDigest,@pubTurnHash AS publicationReceiptDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)));
   END;
