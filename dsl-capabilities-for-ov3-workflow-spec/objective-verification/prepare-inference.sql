DECLARE @quality nvarchar(30)=CASE WHEN EXISTS(SELECT 1 FROM @checks WHERE passed=0) THEN 'INSUFFICIENT' ELSE 'PROVED' END;
DECLARE @context nvarchar(max)=(SELECT @conversation AS conversationId,@turn AS publicationTurn,@turnDigest AS publicationReceiptDigest,@producer AS producer,@contract AS publicationContract,
    @artifact AS artifactDigest,@objectiveHash AS objectiveHash,@profileId AS profileId,JSON_VALUE(@profile,'$.scopeLabel') AS scopeLabel,@quality AS evidenceStatus,JSON_QUERY(@source) AS sourceIdentity,JSON_QUERY(@metrics) AS metrics,
    'objective-obligations.v1' AS obligationsContract,JSON_QUERY(ISNULL(@obligations,'[]')) AS obligations,
    JSON_QUERY((SELECT code,passed FROM @checks ORDER BY code FOR JSON PATH)) AS checks,JSON_QUERY(ISNULL(@proofSet,'[]')) AS proofReceipts FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @state nvarchar(max)=(SELECT 'objective-obligations.v1' AS contractId,@original AS request,JSON_QUERY(ISNULL(@obligations,'[]')) AS obligations FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @label nvarchar(80)=COALESCE(JSON_VALUE(@profile,'$.scopeLabel'),'unsupported');
DECLARE @criteria nvarchar(max)=JSON_MODIFY(N'{}','$."'+@label+'"',COALESCE(JSON_VALUE(@profile,'$.scopeDefinition'),'No supported work contract.'));
SET @criteria=JSON_MODIFY(JSON_MODIFY(@criteria,'$.other','The request requires any other content, different source or version, extra delivery, deployment, or operational work.'),'$.unspecified','The intended work cannot be determined.');
DECLARE @questions nvarchar(max)=JSON_MODIFY(N'{"scope":{"type":"choice","instructions":"Choose the one work contract that fulfills the complete user request. If any required task is outside the named contract, choose other."}}','$.scope.criteria',JSON_QUERY(@criteria));
SELECT (SELECT IIF(@quality='PROVED','INFER','HOLD') AS route,IIF(@quality='PROVED','INFER','HOLD') AS status,
    JSON_QUERY(CASE WHEN @quality='PROVED' THEN @state END) AS state,JSON_QUERY(CASE WHEN @quality='PROVED' THEN @questions END) AS questions,
    JSON_QUERY(@context) AS context FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
