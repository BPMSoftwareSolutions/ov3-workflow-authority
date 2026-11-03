CREATE OR ALTER PROCEDURE analysis.reveal_estate_workflows
  @input nvarchar(max),@estate_model_pk bigint
WITH EXECUTE AS OWNER
AS
BEGIN
  -- reveal-estate-workflows: a read-only workflow lens over one capability of the selected estate. Entries come from
  -- declared entry authority (root scenario row, authority.rootScenarioId, CLI input contract), never from indegree.
  -- A routing transition is admitted only with a known topology, both endpoints in the capability, a declared selecting
  -- variant (selection, recurrence), semanticProgress by the estate law and a finite recurrence bound; otherwise it is
  -- held with findings and never traversed. A workflow is the closure of one admitted entry over admitted transitions.
  SET NOCOUNT ON;
  DECLARE @e bigint=COALESCE(@estate_model_pk,(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1));
  DECLARE @ok bit=CASE WHEN ISJSON(@input)=1 THEN 1 ELSE 0 END;
  DECLARE @cap nvarchar(400)=CASE WHEN @ok=1 THEN JSON_VALUE(@input,N'$.capabilityId') END,
    @entry nvarchar(400)=CASE WHEN @ok=1 THEN JSON_VALUE(@input,N'$.entryScenarioId') END,
    @pin nvarchar(80)=CASE WHEN @ok=1 THEN JSON_VALUE(@input,N'$.expectedDefinitionDigest') END;
  DECLARE @cvpk bigint,@mcp bit,@env nvarchar(max),@def varchar(71),@envd varchar(71);
  SELECT @cvpk=ec.capability_version_pk,@mcp=c.is_mcp_tooling,
    @env=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),
    @envd='sha256:'+LOWER(CONVERT(varchar(64),co.content_digest,2)),@def='sha256:'+LOWER(CONVERT(varchar(64),cv.definition_digest,2))
  FROM model.capability c
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@e
  JOIN model.capability_version cv ON cv.capability_version_pk=ec.capability_version_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE c.capability_id=@cap COLLATE Latin1_General_100_BIN2;
  IF @cvpk IS NULL OR (@pin IS NOT NULL AND @pin<>@def)
  BEGIN
    SELECT (SELECT N'workflow-lens.v1' AS contractId,CASE WHEN @cvpk IS NULL THEN N'NOT_FOUND' ELSE N'STALE' END AS status,@cap AS capabilityId,
      @e AS estateModelPk,@def AS definitionDigest,@pin AS expectedDefinitionDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) AS value;
    RETURN;
  END
  -- The capability's scenarios: terminal flag, contracts, execution authority, declared outcome variants.
  DECLARE @sc TABLE(sid nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,svpk bigint,terminal bit,inc nvarchar(400),outc nvarchar(400),auth bit);
  INSERT @sc(sid,svpk) SELECT x.scenario_id,x.svpk FROM (SELECT s.scenario_id,cs.scenario_version_pk AS svpk,
    ROW_NUMBER() OVER (PARTITION BY s.scenario_id ORDER BY cs.scenario_version_pk DESC) AS rn
    FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk WHERE cs.capability_version_pk=@cvpk) x WHERE x.rn=1;
  UPDATE s SET terminal=ISNULL((SELECT MAX(CONVERT(int,o.terminal)) FROM model.scenario_outcome o WHERE o.scenario_version_pk=s.svpk),0),
    inc=(SELECT TOP (1) k.contract_id FROM model.scenario_input i JOIN model.contract_version kv ON kv.contract_version_pk=i.input_contract_version_pk
      JOIN model.contract k ON k.contract_pk=kv.contract_pk WHERE i.scenario_version_pk=s.svpk),
    outc=(SELECT TOP (1) k.contract_id FROM model.scenario_outcome_contract oc JOIN model.contract_version kv ON kv.contract_version_pk=oc.contract_version_pk
      JOIN model.contract k ON k.contract_pk=kv.contract_pk WHERE oc.scenario_version_pk=s.svpk),
    auth=CASE WHEN EXISTS(SELECT 1 FROM model.scenario_event v WHERE v.scenario_version_pk=s.svpk AND v.execution_authority_version_pk IS NOT NULL) THEN 1 ELSE 0 END
  FROM @sc s;
  DECLARE @var TABLE(sid nvarchar(400) COLLATE Latin1_General_100_BIN2,vid nvarchar(400) COLLATE Latin1_General_100_BIN2);
  INSERT @var SELECT DISTINCT s.sid,ov.variant_id FROM @sc s JOIN model.outcome_variant ov ON ov.scenario_version_pk=s.svpk;
  -- Entries: each root scenario row, admitted only when the envelope declares it as rootScenarioId with a CLI input contract
  -- and its input contract, outcome contract and execution authority resolve.
  DECLARE @aroot nvarchar(400)=JSON_VALUE(@env,N'$.semantics.authority.rootScenarioId'),@clic nvarchar(400)=JSON_VALUE(@env,N'$.semantics.cli.input.contract');
  DECLARE @en TABLE(sid nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,codes nvarchar(max));
  INSERT @en(sid,codes) SELECT r.sid,NULLIF(CONCAT(
      CASE WHEN ISNULL(@aroot,N'')<>r.sid THEN N'"ENTRY_NOT_AUTHORITY_ROOT",' ELSE N'' END,
      CASE WHEN @clic IS NULL THEN N'"ENTRY_CLI_INPUT_MISSING",' ELSE N'' END,
      CASE WHEN s.sid IS NULL THEN N'"ENTRY_SCENARIO_NOT_IN_CAPABILITY",' ELSE N'' END,
      CASE WHEN s.sid IS NOT NULL AND s.inc IS NULL THEN N'"ENTRY_INPUT_CONTRACT_UNRESOLVED",' ELSE N'' END,
      CASE WHEN s.sid IS NOT NULL AND s.outc IS NULL THEN N'"ENTRY_OUTCOME_CONTRACT_UNRESOLVED",' ELSE N'' END,
      CASE WHEN s.sid IS NOT NULL AND s.auth=0 THEN N'"ENTRY_EXECUTION_AUTHORITY_UNRESOLVED",' ELSE N'' END),N'')
  FROM (SELECT DISTINCT sc.scenario_id AS sid FROM model.capability_root_scenario rs JOIN model.scenario sc ON sc.scenario_pk=rs.scenario_pk
    WHERE rs.capability_version_pk=@cvpk) r LEFT JOIN @sc s ON s.sid=r.sid;
  -- Transitions as declared at $.semantics.routing, each judged against the fail-closed law.
  DECLARE @rt TABLE(o int PRIMARY KEY,tid nvarchar(400),f nvarchar(400) COLLATE Latin1_General_100_BIN2,v nvarchar(400) COLLATE Latin1_General_100_BIN2,
    t nvarchar(400) COLLATE Latin1_General_100_BIN2,kind nvarchar(40),gid nvarchar(400),slot nvarchar(400),prog nvarchar(40),rauth nvarchar(400),codes nvarchar(max));
  INSERT @rt(o,tid,f,v,t,kind,gid,slot,prog,rauth)
  SELECT CONVERT(int,r.[key]),j.tid,j.f,j.v,j.t,j.kind,j.gid,j.slot,j.prog,j.rauth FROM OPENJSON(@env,N'$.semantics.routing') r
  CROSS APPLY OPENJSON(r.value) WITH (tid nvarchar(400) N'$.transitionId',f nvarchar(400) N'$.fromScenario',v nvarchar(400) N'$.variant',
    t nvarchar(400) N'$.toScenario',kind nvarchar(40) N'$.topologyKind',gid nvarchar(400) N'$.groupId',slot nvarchar(400) N'$.joinSlotId',
    prog nvarchar(40) N'$.semanticProgress',rauth nvarchar(400) N'$.recurrenceAuthorityId') j;
  UPDATE r SET codes=NULLIF(CONCAT(
      CASE WHEN law.p IS NULL THEN N'"ROUTE_TOPOLOGY_UNKNOWN",' ELSE N'' END,
      CASE WHEN NOT EXISTS(SELECT 1 FROM @sc s WHERE s.sid=r.f) OR NOT EXISTS(SELECT 1 FROM @sc s WHERE s.sid=r.t) THEN N'"ROUTE_ENDPOINT_UNRESOLVED",' ELSE N'' END,
      CASE WHEN r.kind IN (N'selection',N'recurrence') AND NOT EXISTS(SELECT 1 FROM @var x WHERE x.sid=r.f AND x.vid=r.v) THEN N'"ROUTE_VARIANT_UNDECLARED",' ELSE N'' END,
      CASE WHEN r.prog IS NULL THEN N'"ROUTE_SEMANTIC_PROGRESS_MISSING",' WHEN law.p IS NOT NULL AND r.prog<>law.p THEN N'"ROUTE_SEMANTIC_PROGRESS_CONTRADICTS_LAW",' ELSE N'' END,
      CASE WHEN r.kind=N'recurrence' AND ISNULL(b.maxi,2147483647)>=2147483647 THEN N'"RECURRENCE_UNBOUNDED",' ELSE N'' END),N'')
  FROM @rt r
  CROSS APPLY (SELECT CASE r.kind WHEN N'selection' THEN CASE WHEN EXISTS(SELECT 1 FROM @sc s WHERE s.sid=r.t AND s.terminal=1) THEN N'terminating' ELSE N'narrowing' END
    WHEN N'broadcast' THEN N'expanding' WHEN N'join' THEN N'converging' WHEN N'failure' THEN CASE WHEN r.slot IS NULL THEN N'terminating' ELSE N'converging' END
    WHEN N'recurrence' THEN N'recurring' WHEN N'sequence' THEN N'preserving' WHEN N'return' THEN N'preserving' WHEN N'cancellation' THEN N'terminating' END AS p) law
  OUTER APPLY (SELECT TOP (1) TRY_CONVERT(int,JSON_VALUE(a.value,N'$.maximumIterations')) AS maxi FROM OPENJSON(@env,N'$.semantics.executionGraph.recurrenceAuthorities') a
    WHERE JSON_VALUE(a.value,N'$.recurrenceAuthorityId')=r.rauth) b;
  -- Closure of each admitted entry over admitted transitions only.
  DECLARE @reach TABLE(entry nvarchar(400) COLLATE Latin1_General_100_BIN2,sid nvarchar(400) COLLATE Latin1_General_100_BIN2,PRIMARY KEY(entry,sid));
  DECLARE @added int;
  INSERT @reach(entry,sid) SELECT sid,sid FROM @en WHERE codes IS NULL AND (@entry IS NULL OR sid=@entry COLLATE Latin1_General_100_BIN2);
  SET @added=@@ROWCOUNT;
  WHILE @added>0
  BEGIN
    INSERT @reach(entry,sid) SELECT DISTINCT x.entry,r.t FROM @reach x JOIN @rt r ON r.f=x.sid AND r.codes IS NULL
    WHERE NOT EXISTS(SELECT 1 FROM @reach y WHERE y.entry=x.entry AND y.sid=r.t);
    SET @added=@@ROWCOUNT;
  END
  DECLARE @entries int=(SELECT COUNT(*) FROM @en),@admittedEntries int=(SELECT COUNT(*) FROM @en WHERE codes IS NULL),
    @edges int=(SELECT COUNT(*) FROM @rt),@admittedEdges int=(SELECT COUNT(*) FROM @rt WHERE codes IS NULL),
    @reached int=(SELECT COUNT(DISTINCT sid) FROM @reach),
    @terminals int=(SELECT COUNT(DISTINCT x.sid) FROM @reach x JOIN @sc s ON s.sid=x.sid AND s.terminal=1),
    @entryKnown bit=CASE WHEN @entry IS NULL OR EXISTS(SELECT 1 FROM @en WHERE sid=@entry COLLATE Latin1_General_100_BIN2) THEN 1 ELSE 0 END;
  DECLARE @status nvarchar(30)=CASE WHEN @entryKnown=0 OR NOT EXISTS(SELECT 1 FROM @reach) THEN N'NOT_DECLARED'
    WHEN @admittedEdges<@edges OR @admittedEntries<@entries THEN N'PARTIAL_WITH_HELD_GAPS' ELSE N'RESOLVED' END;
  DECLARE @lens nvarchar(max)=(SELECT
    JSON_QUERY(ISNULL((SELECT e.sid AS scenarioId,CASE WHEN e.codes IS NULL THEN N'admitted' ELSE N'held' END AS status,s.inc AS inputContract,
      s.outc AS outcomeContract,@clic AS cliInputContract,JSON_QUERY(N'['+ISNULL(LEFT(e.codes,LEN(e.codes)-1),N'')+N']') AS findings
      FROM @en e LEFT JOIN @sc s ON s.sid=e.sid ORDER BY e.sid FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]')) AS entries,
    JSON_QUERY(ISNULL((SELECT r.tid AS transitionId,r.f AS fromScenario,r.v AS variant,r.t AS toScenario,r.kind AS topologyKind,r.prog AS semanticProgress,
      r.gid AS groupId,r.slot AS joinSlotId,CASE WHEN r.codes IS NULL THEN N'admitted' ELSE N'held' END AS status,
      JSON_QUERY(N'['+ISNULL(LEFT(r.codes,LEN(r.codes)-1),N'')+N']') AS findings FROM @rt r ORDER BY r.o FOR JSON PATH),N'[]')) AS executionEdges,
    JSON_QUERY(ISNULL((SELECT e.sid AS entryScenarioId,
      CASE WHEN EXISTS(SELECT 1 FROM @rt r JOIN @reach x ON x.entry=e.sid AND x.sid=r.f WHERE r.codes IS NOT NULL) THEN N'partial' ELSE N'complete' END AS status,
      JSON_QUERY(N'['+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(x.sid,'json')+N'"'),N',') WITHIN GROUP (ORDER BY x.sid) FROM @reach x WHERE x.entry=e.sid)+N']') AS scenarios,
      JSON_QUERY(N'['+ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(r.tid,'json')+N'"'),N',') WITHIN GROUP (ORDER BY r.o)
        FROM @rt r JOIN @reach x ON x.entry=e.sid AND x.sid=r.f WHERE r.codes IS NULL),N'')+N']') AS transitions,
      JSON_QUERY(N'['+ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(r.tid,'json')+N'"'),N',') WITHIN GROUP (ORDER BY r.o)
        FROM @rt r JOIN @reach x ON x.entry=e.sid AND x.sid=r.f WHERE r.codes IS NOT NULL),N'')+N']') AS heldTransitions,
      JSON_QUERY(N'['+ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(x.sid,'json')+N'"'),N',') WITHIN GROUP (ORDER BY x.sid)
        FROM @reach x JOIN @sc s ON s.sid=x.sid AND s.terminal=1 WHERE x.entry=e.sid),N'')+N']') AS terminals
      FROM @en e WHERE e.codes IS NULL AND (@entry IS NULL OR e.sid=@entry COLLATE Latin1_General_100_BIN2) ORDER BY e.sid FOR JSON PATH),N'[]')) AS workflows
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT (SELECT N'workflow-lens.v1' AS contractId,@status AS status,@cap AS capabilityId,@e AS estateModelPk,@def AS definitionDigest,@envd AS envelopeDigest,
    @mcp AS mcpTooling,@entry AS entryScenarioId,JSON_QUERY(@lens,N'$.entries') AS entries,JSON_QUERY(@lens,N'$.workflows') AS workflows,
    JSON_QUERY(@lens,N'$.executionEdges') AS executionEdges,
    JSON_QUERY(N'[]') AS compositionEdges,JSON_QUERY(N'[]') AS productRelations,JSON_QUERY(N'[]') AS providerBindings,
    JSON_QUERY((SELECT @entries AS entries,@admittedEntries AS admittedEntries,@edges AS edges,@admittedEdges AS admittedEdges,@edges-@admittedEdges AS heldEdges,
      @reached AS reachedScenarios,@terminals AS reachedTerminals,
      CONCAT(N'entries=',@admittedEntries,N'/',@entries,N';edges=',@admittedEdges,N'/',@edges,N';reached=',@reached,N';terminals=',@terminals) AS signature
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS summary,
    'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@lens COLLATE Latin1_General_100_BIN2_UTF8)),2)) AS projectionDigest
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) AS value;
END;
