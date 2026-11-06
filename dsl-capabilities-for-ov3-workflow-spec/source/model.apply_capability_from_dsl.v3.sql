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
  -- Each provider binding the source declares is minted as raw content-addressed authority before the document that names
  -- its digest is declared. Its content must hash to the digest the compiler reported.
  DECLARE @pbi int=0,@pbn int=(SELECT COUNT(*) FROM OPENJSON(@res,N'$.providerBindings'));
  WHILE @pbi<@pbn
  BEGIN
    DECLARE @pb nvarchar(max)=JSON_QUERY(@res,N'$.providerBindings['+CONVERT(nvarchar(10),@pbi)+N']');
    DECLARE @pbid nvarchar(200)=JSON_VALUE(@pb,N'$.providerBindingId'),@pbdigest nvarchar(71)=JSON_VALUE(@pb,N'$.digest');
    DECLARE @pbbytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),JSON_QUERY(@pb,N'$.content') COLLATE Latin1_General_100_BIN2_UTF8));
    DECLARE @pbhash binary(32)=HASHBYTES('SHA2_256',@pbbytes);
    IF @pbid IS NULL OR @pbbytes IS NULL OR ISNULL(@pbdigest,N'')<>N'sha256:'+LOWER(CONVERT(varchar(64),@pbhash,2))
      THROW 51000,N'CAPABILITY_FROM_DSL_PROVIDER_BINDING_INTEGRITY',1;
    IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@pbhash)
      INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@pbhash,@pbbytes,DATALENGTH(@pbbytes));
    SELECT N'provider_binding_minted' AS result_set,@pbid AS provider_binding_id,@pbdigest AS digest;
    SET @pbi+=1;
  END
  EXEC model.declare_capability_document @document=@doc;
  -- A source that pins its feature is bound to that feature at the end of this change, not to the one bound before.
  DECLARE @feature_digest nvarchar(80)=JSON_VALUE(@doc,N'$.feature.digest');
  IF @feature_digest IS NULL
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
  -- The feature binding follows the version this change finally selected: the topology and the label above can select a
  -- later capability version than the document's declaration did.
  IF @feature_digest IS NULL
    EXEC model.repoint_capability_feature @capability_id=@cap;
  ELSE
  BEGIN
    -- Feature first: the source pins the feature whose retained bytes it was compiled against. Those exact bytes become the
    -- canonical feature of the selected version, and the change commits only when the no-drift check finds the binding
    -- CONFORMANT; any other answer rolls the whole declaration back.
    DECLARE @feature_text nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
      FROM source.content_object co WHERE co.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@feature_digest,8,64),2));
    IF @feature_text IS NULL THROW 51000,N'CAPABILITY_FROM_DSL_FEATURE_NOT_RETAINED',1;
    EXEC model.declare_capability_feature @capability_id=@cap,@feature_text=@feature_text;
    DECLARE @feature_version bigint=(SELECT TOP (1) fv.feature_version_pk FROM model.feature_version fv
      JOIN model.capability c ON c.capability_pk=fv.capability_pk
      JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
      JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=fv.semantic_object_definition_pk
      JOIN source.content_object env ON env.content_object_pk=d.canonical_content_pk
      WHERE c.capability_id=@cap COLLATE Latin1_General_100_BIN2
        AND JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),env.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),N'$.semantics.content_digest')=SUBSTRING(@feature_digest,8,64)
      ORDER BY fv.feature_version_pk DESC);
    IF @feature_version IS NULL THROW 51000,N'CAPABILITY_FROM_DSL_FEATURE_NOT_DECLARED',1;
    EXEC model.repoint_capability_feature @capability_id=@cap,@feature_version_pk=@feature_version;
    DECLARE @conformance nvarchar(max)=NULL,@conformance_request nvarchar(max)=(SELECT @cap AS capabilityId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    EXEC analysis.check_capability_feature_conformance @input=@conformance_request,@estate_model_pk=@estate,@result=@conformance OUTPUT,@emit=0;
    SELECT N'capability_feature_conformance' AS result_set,JSON_VALUE(@conformance,N'$.status') AS status,
      JSON_VALUE(@conformance,N'$.summary.signature') AS signature,@feature_digest AS feature_digest,@feature_version AS feature_version_pk;
    IF ISNULL(JSON_VALUE(@conformance,N'$.status'),N'')<>N'CONFORMANT'
    BEGIN
      DECLARE @drift nvarchar(2048)=N'CAPABILITY_FROM_DSL_FEATURE_DRIFT: '+ISNULL(JSON_VALUE(@conformance,N'$.summary.signature'),N'(the check returned nothing)');
      THROW 51000,@drift,1;
    END
  END
  SELECT N'capability_from_dsl_applied' AS result_set,@cap AS capability_id,N'INSTALLED' AS disposition,
    @sdigest AS source_digest,@ddigest AS document_digest,CASE WHEN @existed=1 THEN N'EXISTING' ELSE N'CREATE' END AS scaffold;
END;