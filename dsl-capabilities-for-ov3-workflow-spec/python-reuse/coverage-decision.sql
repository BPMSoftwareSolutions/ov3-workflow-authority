IF @routed=0 AND @short IS NOT NULL AND JSON_QUERY(@out,N'$.visibleCapabilities') IS NULL AND JSON_QUERY(@out,N'$.payload.visibleCapabilities') IS NULL
BEGIN
 -- Keep the ranked shortlist in its original order. Append public coverage
 -- candidates once, without turning the model's first action into an exclusion.
 ;WITH combined AS (
   SELECT j.value COLLATE DATABASE_DEFAULT AS id,CONVERT(int,j.[key]) AS ord FROM OPENJSON(@short) j
   UNION ALL
   SELECT j.value COLLATE DATABASE_DEFAULT,12+CONVERT(int,j.[key])
   FROM OPENJSON(@ctx,'$.routingCoverageCandidates') j
   JOIN model.capability ca ON ca.capability_id=j.value COLLATE Latin1_General_100_BIN2 AND ca.is_mcp_tooling=1
   JOIN model.identity_namespace n ON n.namespace_pk=ca.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
   JOIN model.estate_capability ec ON ec.capability_pk=ca.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
   WHERE j.type=1 AND CONVERT(int,j.[key]) BETWEEN 0 AND 7
 ), ids AS (SELECT id,MIN(ord) ord FROM combined GROUP BY id)
 SELECT @short=N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(id,'json')+N'"'),N',') WITHIN GROUP(ORDER BY ord,id)+N']' FROM ids;
 SET @out=JSON_MODIFY(@out,N'$.visibleCapabilities',JSON_QUERY(@short));
END;
SET @out=JSON_MODIFY(@out,N'$.routingCoverageCandidates',NULL);
