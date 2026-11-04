-- Canonical behavior sha256:390f0ef712fcb2c141a99efe7752e14bf3cf4237407ac1cfeae7030d60cfa3e0
IF @@TRANCOUNT=0 THROW 51000,'ROUTER_TRANSACTION_REQUIRED',1;
DECLARE @namespace nvarchar(400)=N'sidefx:capability:request-capability-from-objective-v3',@port nvarchar(400),@cfg nvarchar(max),@sem nvarchar(max),@actual nvarchar(max),@expected nvarchar(max),@platform nvarchar(400);
DECLARE @selected TABLE(digest binary(32), bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
SET @port=N'request-capability-from-objective-v3-intent-compose';
DELETE @selected;
INSERT @selected SELECT TOP(1) d.definition_digest,co.content_bytes
 FROM model.port p JOIN model.identity_namespace ns ON ns.namespace_pk=p.namespace_pk
 JOIN model.semantic_object_definition d ON d.semantic_object_pk=p.semantic_object_pk
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk
 AND ed.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE ns.namespace_id=@namespace AND p.port_id=@port AND co.content_digest=d.definition_digest
 ORDER BY d.semantic_object_definition_pk DESC;
SET @sem=(SELECT JSON_QUERY(CONVERT(nvarchar(max),bytes),'$.semantics') FROM @selected WHERE HASHBYTES('SHA2_256',CONVERT(varbinary(max),bytes))=digest);
IF @sem IS NULL THROW 51000,'ROUTER_NO_HASHED_AUTHORITY',1;
IF NOT EXISTS(SELECT 1 FROM @selected WHERE digest=0x41ab61d8dae1f0f45e388f06a84aa964ca263403b871129b340527e1b2de1a5f) THROW 51000,'ROUTER_AUTHORITY_CHANGED',1;
SET @cfg=JSON_QUERY(@sem,'$.configuration'); SET @platform=JSON_VALUE(@sem,'$.platformCapabilityId');
SET @actual=(SELECT value FROM OPENJSON(@cfg) WHERE [key]='statement');
IF @actual IS NULL OR HASHBYTES('SHA2_256',@actual)<>0x02bcf0f1509074d9be101e14d590c25eaa9651568d8fbbf7c9e8ef552d8b0a2a THROW 51000,'ROUTER_SOURCE_CHANGED',1;
SET @actual=REPLACE(@actual COLLATE Latin1_General_100_BIN2,N'DECLARE @context nvarchar(max)=@input;',N'DECLARE @context nvarchar(max)=@input;
-- Preserve candidates for rare, explicit terms in a multi-operation objective.
-- The existing catalog has already been limited to public, selectable MCP tools.
DECLARE @coverage nvarchar(max);
IF JSON_QUERY(@input,''$.visibleCapabilities'') IS NULL AND JSON_QUERY(@input,''$.payload.visibleCapabilities'') IS NULL
BEGIN
 ;WITH hits AS (
    SELECT w.w,k.id,COUNT(*) OVER(PARTITION BY w.w) AS frequency
    FROM @words w JOIN @catalog k ON CHARINDEX(N'' ''+w.w+N'' '',N'' ''+TRANSLATE(k.haystack,N''.,;:()[]/?!'',N''           '')+N'' '')>0
    WHERE LEN(w.w)>=4 AND w.w COLLATE Latin1_General_100_BIN2 NOT LIKE N''%[^a-z0-9-]%''
 ), chosen AS (
    SELECT TOP(8) id,MAX(IIF(w LIKE ''%[0-9]%'',1,0)) AS technical,MIN(frequency) rarity,COUNT(*) matches
    FROM hits WHERE frequency<=5 GROUP BY id ORDER BY technical DESC,rarity,matches DESC,id
 )
 SELECT @coverage=N''[''+STRING_AGG(CONVERT(nvarchar(max),N''"''+STRING_ESCAPE(id,''json'')+N''"''),N'','')
    WITHIN GROUP(ORDER BY technical DESC,rarity,matches DESC,id)+N'']'' FROM chosen;
END;
SET @context=JSON_MODIFY(@context,N''$.routingCoverageCandidates'',JSON_QUERY(ISNULL(@coverage,N''[]'')));
');
IF HASHBYTES('SHA2_256',@actual)<>0x02b6ef82a466f25966ae5c5c79c7a36c750291d89fe64d59aa19cc56e440ec4d THROW 51000,'ROUTER_PATCH_MISMATCH',1;
SET @expected=JSON_MODIFY(@cfg,'$.statement',@actual);
EXEC model.replace_port_configuration @namespace=@namespace,@port=@port,@configuration_json=@expected;
DELETE @selected;
INSERT @selected SELECT TOP(1) d.definition_digest,co.content_bytes
 FROM model.port p JOIN model.identity_namespace ns ON ns.namespace_pk=p.namespace_pk
 JOIN model.semantic_object_definition d ON d.semantic_object_pk=p.semantic_object_pk
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk
 AND ed.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE ns.namespace_id=@namespace AND p.port_id=@port AND co.content_digest=d.definition_digest
 ORDER BY d.semantic_object_definition_pk DESC;
SET @sem=(SELECT JSON_QUERY(CONVERT(nvarchar(max),bytes),'$.semantics') FROM @selected WHERE HASHBYTES('SHA2_256',CONVERT(varbinary(max),bytes))=digest);
IF @sem IS NULL THROW 51000,'ROUTER_NO_HASHED_AUTHORITY',1;
SET @cfg=JSON_QUERY(@sem,'$.configuration');
IF @cfg IS NULL OR @platform IS NULL OR ISNULL(JSON_VALUE(@sem,'$.platformCapabilityId'),'')<>@platform OR CONVERT(varbinary(max),@cfg)<>CONVERT(varbinary(max),@expected) THROW 51000,'ROUTER_READBACK_MISMATCH',1;
SET @port=N'request-capability-from-objective-v3-intent-decide';
DELETE @selected;
INSERT @selected SELECT TOP(1) d.definition_digest,co.content_bytes
 FROM model.port p JOIN model.identity_namespace ns ON ns.namespace_pk=p.namespace_pk
 JOIN model.semantic_object_definition d ON d.semantic_object_pk=p.semantic_object_pk
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk
 AND ed.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE ns.namespace_id=@namespace AND p.port_id=@port AND co.content_digest=d.definition_digest
 ORDER BY d.semantic_object_definition_pk DESC;
SET @sem=(SELECT JSON_QUERY(CONVERT(nvarchar(max),bytes),'$.semantics') FROM @selected WHERE HASHBYTES('SHA2_256',CONVERT(varbinary(max),bytes))=digest);
IF @sem IS NULL THROW 51000,'ROUTER_NO_HASHED_AUTHORITY',1;
IF NOT EXISTS(SELECT 1 FROM @selected WHERE digest=0x3edddafbfe80d137f0beb260b14f1c60c20570ec38fb8548ff0ab0dc5a6f960c) THROW 51000,'ROUTER_AUTHORITY_CHANGED',1;
SET @cfg=JSON_QUERY(@sem,'$.configuration'); SET @platform=JSON_VALUE(@sem,'$.platformCapabilityId');
SET @actual=(SELECT value FROM OPENJSON(@cfg) WHERE [key]='statement');
IF @actual IS NULL OR HASHBYTES('SHA2_256',@actual)<>0x21b14affec611a8bd8f4545b0e662ff63c70db683d4af79a76b1f2d4316d2c14 THROW 51000,'ROUTER_SOURCE_CHANGED',1;
SET @actual=REPLACE(@actual COLLATE Latin1_General_100_BIN2,N'IF @routed=0 AND @short IS NOT NULL AND JSON_QUERY(@out,N''$.visibleCapabilities'') IS NULL AND JSON_QUERY(@out,N''$.payload.visibleCapabilities'') IS NULL
 SET @out=JSON_MODIFY(@out,N''$.visibleCapabilities'',JSON_QUERY(@short));
',N'IF @routed=0 AND @short IS NOT NULL AND JSON_QUERY(@out,N''$.visibleCapabilities'') IS NULL AND JSON_QUERY(@out,N''$.payload.visibleCapabilities'') IS NULL
BEGIN
 -- Keep the ranked shortlist in its original order. Append public coverage
 -- candidates once, without turning the model''s first action into an exclusion.
 ;WITH combined AS (
   SELECT j.value COLLATE DATABASE_DEFAULT AS id,CONVERT(int,j.[key]) AS ord FROM OPENJSON(@short) j
   UNION ALL
   SELECT j.value COLLATE DATABASE_DEFAULT,12+CONVERT(int,j.[key])
   FROM OPENJSON(@ctx,''$.routingCoverageCandidates'') j
   JOIN model.capability ca ON ca.capability_id=j.value COLLATE Latin1_General_100_BIN2 AND ca.is_mcp_tooling=1
   JOIN model.identity_namespace n ON n.namespace_pk=ca.namespace_pk AND n.namespace_id=N''sidefx:capabilities''
   JOIN model.estate_capability ec ON ec.capability_pk=ca.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
   WHERE j.type=1 AND CONVERT(int,j.[key]) BETWEEN 0 AND 7
 ), ids AS (SELECT id,MIN(ord) ord FROM combined GROUP BY id)
 SELECT @short=N''[''+STRING_AGG(CONVERT(nvarchar(max),N''"''+STRING_ESCAPE(id,''json'')+N''"''),N'','') WITHIN GROUP(ORDER BY ord,id)+N'']'' FROM ids;
 SET @out=JSON_MODIFY(@out,N''$.visibleCapabilities'',JSON_QUERY(@short));
END;
SET @out=JSON_MODIFY(@out,N''$.routingCoverageCandidates'',NULL);

');
IF HASHBYTES('SHA2_256',@actual)<>0xdbf7863bccf9575b5f03a6110f59e1985a143ec7ccc3fe14cd94b86a0fdaff44 THROW 51000,'ROUTER_PATCH_MISMATCH',1;
SET @expected=JSON_MODIFY(@cfg,'$.statement',@actual);
EXEC model.replace_port_configuration @namespace=@namespace,@port=@port,@configuration_json=@expected;
DELETE @selected;
INSERT @selected SELECT TOP(1) d.definition_digest,co.content_bytes
 FROM model.port p JOIN model.identity_namespace ns ON ns.namespace_pk=p.namespace_pk
 JOIN model.semantic_object_definition d ON d.semantic_object_pk=p.semantic_object_pk
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk
 AND ed.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE ns.namespace_id=@namespace AND p.port_id=@port AND co.content_digest=d.definition_digest
 ORDER BY d.semantic_object_definition_pk DESC;
SET @sem=(SELECT JSON_QUERY(CONVERT(nvarchar(max),bytes),'$.semantics') FROM @selected WHERE HASHBYTES('SHA2_256',CONVERT(varbinary(max),bytes))=digest);
IF @sem IS NULL THROW 51000,'ROUTER_NO_HASHED_AUTHORITY',1;
SET @cfg=JSON_QUERY(@sem,'$.configuration');
IF @cfg IS NULL OR @platform IS NULL OR ISNULL(JSON_VALUE(@sem,'$.platformCapabilityId'),'')<>@platform OR CONVERT(varbinary(max),@cfg)<>CONVERT(varbinary(max),@expected) THROW 51000,'ROUTER_READBACK_MISMATCH',1;
SELECT 'compound_objective_routing' result_set,'VERIFIED' outcome;
