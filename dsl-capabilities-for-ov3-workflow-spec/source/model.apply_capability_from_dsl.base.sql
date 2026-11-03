CREATE   PROCEDURE model.apply_capability_from_dsl
  @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  IF @@TRANCOUNT=0 OR XACT_STATE()<>1 THROW 51000,N'CAPABILITY_FROM_DSL_TRANSACTION_REQUIRED',1;
  IF @document IS NULL OR ISJSON(@document)<>1 OR LEFT(LTRIM(@document),1)<>N'{'
    THROW 51000,N'CAPABILITY_FROM_DSL_DOCUMENT_INVALID',1;
  IF JSON_VALUE(@document,N'$.contractId')<>N'capability-from-dsl-change.v1'
    THROW 51000,N'CAPABILITY_FROM_DSL_CONTRACT_REQUIRED',1;
  IF EXISTS(SELECT 1 FROM OPENJSON(@document) WHERE [key] NOT IN (N'contractId',N'source',N'isMcpTooling',N'verificationCapabilityId',N'preflight',N'route'))
    THROW 51000,N'CAPABILITY_FROM_DSL_MEMBER_INVALID',1;
  DECLARE @source nvarchar(max)=(SELECT [value] FROM OPENJSON(@document) WHERE [key]=N'source');
  IF @source IS NULL OR LEN(@source)=0 THROW 51000,N'CAPABILITY_FROM_DSL_SOURCE_REQUIRED',1;
  DECLARE @is_mcp bit=CASE WHEN JSON_VALUE(@document,N'$.isMcpTooling')=N'true' THEN 1 ELSE 0 END;
  DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
  IF @estate IS NULL THROW 51000,N'CAPABILITY_FROM_DSL_ESTATE_REQUIRED',1;
  DECLARE @cres TABLE(value nvarchar(max));
  DECLARE @cinput nvarchar(max)=(SELECT @source AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT @cres EXEC analysis.compile_capability_dsl @input=@cinput,@estate_model_pk=@estate;
  DECLARE @res nvarchar(max)=(SELECT value FROM @cres);
  IF ISJSON(@res)<>1 OR JSON_VALUE(@res,N'$.status')<>N'COMPILED'
  BEGIN
    DECLARE @code nvarchar(40)=COALESCE(JSON_VALUE(@res,N'$.diagnostics[0].code'),N'DSL_REFUSED');
    DECLARE @line int=TRY_CONVERT(int,JSON_VALUE(@res,N'$.diagnostics[0].line'));
    DECLARE @dmsg nvarchar(400)=JSON_VALUE(@res,N'$.diagnostics[0].message');
    SELECT N'capability_from_dsl_refused' AS result_set,N'REFUSED' AS status,@code AS code,@line AS line,
      @dmsg AS message,JSON_VALUE(@res,N'$.sourceDigest') AS source_digest;
    DECLARE @throw_msg nvarchar(2048)=N'CAPABILITY_FROM_DSL_REFUSED: '+@code+N' at line '+COALESCE(CONVERT(nvarchar(10),@line),N'?')+N': '+COALESCE(@dmsg,N'');
    THROW 51000,@throw_msg,1;
  END
  DECLARE @doc nvarchar(max)=JSON_QUERY(@res,N'$.document');
  DECLARE @cap nvarchar(200)=JSON_VALUE(@doc,N'$.capabilityId');
  DECLARE @sdigest nvarchar(71)=JSON_VALUE(@res,N'$.sourceDigest');
  DECLARE @ddigest nvarchar(71)=JSON_VALUE(@res,N'$.documentDigest');
  IF @doc IS NULL OR @cap IS NULL
    THROW 51000,N'CAPABILITY_FROM_DSL_COMPILE_INCOMPLETE',1;
  -- A capability that is not in the estate before this declaration is born by it (scaffold CREATE).
  DECLARE @existed bit=CASE WHEN EXISTS(SELECT 1 FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk=ec.capability_pk
    WHERE ec.estate_model_pk=@estate AND c.capability_id=@cap) THEN 1 ELSE 0 END;
  SELECT N'capability_from_dsl' AS result_set,N'COMPILED' AS status,@cap AS capability_id,
    @sdigest AS source_digest,@ddigest AS document_digest,CONVERT(bit,@is_mcp) AS is_mcp_tooling;
  EXEC model.declare_capability_document @document=@doc;
  EXEC model.repoint_capability_feature @capability_id=@cap;
  IF @is_mcp=1 EXEC model.set_capability_mcp_tooling N'sidefx:capabilities',@cap,1;
  DECLARE @topology_routing nvarchar(max)=JSON_QUERY(@doc,N'$.routing');
  DECLARE @topology_graph nvarchar(max)=JSON_QUERY(@doc,N'$.executionGraph');
  IF @topology_routing IS NOT NULL OR @topology_graph IS NOT NULL
    EXEC model.declare_capability_topology @capability_id=@cap,@routing=@topology_routing,@execution_graph=@topology_graph;
  EXEC model.carry_capability_transformations @capability_id=@cap,@document=@doc;
  -- The document's example inquiries are written in the same change.
  IF JSON_QUERY(@doc,N'$.inquiries') IS NOT NULL
  BEGIN
    DECLARE @inquiry_doc nvarchar(max)=(SELECT N'sidefx:capabilities' AS namespaceId,
      JSON_QUERY((SELECT @cap AS capabilityId,JSON_QUERY(@doc,N'$.inquiries') AS inquiries FOR JSON PATH)) AS entries FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    EXEC model.set_capability_inquiry_examples @document=@inquiry_doc;
  END
  DECLARE @retain_doc nvarchar(max)=(SELECT @cap AS capabilityId,@source AS source,N'capability-from-dsl' AS authoringRef FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC model.retain_capability_dsl_source @document=@retain_doc;
  -- The declaration is recorded in the engineering change ledger, with its source and document digests.
  INSERT model.engineering_change(change_id,change_kind,mode,disposition,source_digest,note,object_name,object_type,after_digest,capability_id,
    evidence_kind,evidence_ref,changed_at)
  VALUES(NEWID(),N'capability-from-dsl','commit','COMMITTED',TRY_CONVERT(binary(32),SUBSTRING(@sdigest,8,64),2),
    CASE WHEN @existed=1 THEN N'scaffold EXISTING' ELSE N'scaffold CREATE' END,@cap,'CAPABILITY',TRY_CONVERT(binary(32),SUBSTRING(@ddigest,8,64),2),
    @cap,'writer',@sdigest,SYSUTCDATETIME());
  -- Conformance by construction. An unlabelled capability is labelled with its id (the
  -- populate-default-definition-labels rule), and the scaffold's <capability>-transform.v1 is
  -- removed when the reachability law reports it disposed, so no authored capability carries it.
  IF analysis.fv_definition_label(N'sidefx:capabilities',@cap) IS NULL
    EXEC model.fix_capability_label @capability_id=@cap,@version_label=@cap,@validate_full=0;
  DECLARE @scaffold_tid nvarchar(400)=@cap+N'-transform.v1',@scaffold_ns nvarchar(400)=N'sidefx:capability:'+@cap;
  IF EXISTS(SELECT 1 FROM analysis.fv_declared_reachability_conformance(@estate,@cap) r
    WHERE r.dim_key=N'declared_object_disposed' AND r.subject=@scaffold_tid COLLATE Latin1_General_100_BIN2)
    EXEC model.remove_transformation @transformation_id=@scaffold_tid,@acknowledge_retained_references=1,@namespace=@scaffold_ns;
  -- Technical debt by construction: the flag of the declared capability is derived from what it binds.
  EXEC model.derive_capability_technical_debt @capability_id=@cap,@quiet=1;
  SELECT N'capability_from_dsl_applied' AS result_set,@cap AS capability_id,N'INSTALLED' AS disposition,
    @sdigest AS source_digest,@ddigest AS document_digest,CASE WHEN @existed=1 THEN N'EXISTING' ELSE N'CREATE' END AS scaffold;
END;