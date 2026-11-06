-- ov3-harness-01-bind-long-values.sql
--
-- ============================== PREFLIGHT - NOT AN INSTALL ==============================
-- Byte-identical to the .commit twin except this banner and the terminal statement:
-- ROLLBACK TRANSACTION here, COMMIT TRANSACTION there. Nothing is written.
--
-- WHAT THIS CHANGES: analysis.fly_flight_step_cell, the step cell every flight runs, binds an earlier step's result
-- member with JSON_VALUE, which reads any string over 4,000 characters as NULL, so the step fails BINDING_UNRESOLVED
-- and OV3 cannot carry a document it wrote (a scope, a feature) to the next step. The revision adds one block after the
-- bind read: when it is NULL, the same member is read through OPENJSON (nvarchar(max)). Every bind that resolves today
-- resolves exactly as before; nothing else in the procedure changes.
--
-- WHERE: the estate database (data source sfx-estate-database). Run the whole file in one session; the transaction
-- spans the batches. CREATE OR ALTER keeps the procedure's permissions.
--
-- BASE: analysis.fly_flight_step_cell sha256:29ff4f83ef0dac68068714201748b38b934b6d8793ca00c5bd7ce9098814b10b
-- (read-declared-object-source run ae0be3a9, 2026-11-02, 13,635 bytes). A moved base stops the script before any change.
--
-- VERIFY (in the transaction): the installed definition holds the block, and with the block removed it equals the base
-- from "PROCEDURE" onward (line endings compared as LF). Otherwise the change rolls back.
--
-- RESULT SETS: base; verify (after digest, block_present, rest_unchanged, crlf_introduced).
--
-- NEXT: ov3-harness-02 (estate), ov3-harness-03 (sfx-identity), then OV3 flies the proof (README.md).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @installed varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'analysis.fly_flight_step_cell')) COLLATE Latin1_General_100_BIN2_UTF8)),2));
SELECT N'base' AS result_set,@installed AS installed_digest,'sha256:29ff4f83ef0dac68068714201748b38b934b6d8793ca00c5bd7ce9098814b10b' AS expected_base;
IF @installed IS NULL OR @installed<>'sha256:29ff4f83ef0dac68068714201748b38b934b6d8793ca00c5bd7ce9098814b10b'
BEGIN
 RAISERROR(N'OV3_HARNESS_BASE_MOVED: analysis.fly_flight_step_cell is not the reviewed definition; read it before running this file.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
IF OBJECT_ID(N'tempdb..#ov3_cell_base') IS NOT NULL DROP TABLE #ov3_cell_base;
SELECT OBJECT_DEFINITION(OBJECT_ID(N'analysis.fly_flight_step_cell')) AS def INTO #ov3_cell_base;
GO
CREATE OR ALTER PROCEDURE analysis.fly_flight_step_cell
 @input nvarchar(max),@estate_model_pk bigint,@step nvarchar(20),@sv2 bit = 0
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 -- One step of a folded flight (fly-flight-step): the piece of analysis.fly_flight_plan_step that runs a step. step-prepare
 -- (a step runs only after the step before it passed; binds; unbound operators; dispatch the step capability), step-check
 -- (evaluate the result against the step's expectation, record the attempt when the step recovers (@sv2 = 1, as
 -- analysis.fly_flight_step_recovery calls it), dispatch the retention of flight-step:<flightId>#<ordinal>) and step-return
 -- (the entry; the step's state is released). A step that declares waitWhen {path, equals} and does not meet its expectation
 -- waits instead of failing when its result matches waitWhen: a stage not finished yet, such as a decision point the owner has not
 -- decided, is WAITING, and its flight waits with it. The source is ASCII.
 DECLARE @noop nvarchar(max)=(SELECT N'read-dsl-authoring-fingerprint' executionTarget,N'sidefx:capabilities' executionNamespace,
  N'read-dsl-authoring-fingerprint' executionScenario,N'json' inputType,JSON_QUERY(N'{"capabilityId":"fly-flight-plan"}') dispatchRequest
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @clear nvarchar(max)=NULL;
 DECLARE @u TABLE(v varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
  IF @step=N'step-prepare'
  BEGIN
   IF @input IS NULL OR ISJSON(@input)<>1 THROW 51000,N'FLIGHT_STEP_REQUEST_INVALID',1;
   DECLARE @fid nvarchar(64)=JSON_VALUE(@input,'$.flightId'),@ord int=TRY_CONVERT(int,JSON_VALUE(@input,'$.ordinal')),
    @sdef nvarchar(max)=JSON_QUERY(@input,'$.step');
   IF @fid IS NULL OR @ord IS NULL OR @sdef IS NULL THROW 51000,N'FLIGHT_STEP_REQUEST_INVALID',1;
   DECLARE @scap nvarchar(400)=JSON_VALUE(@sdef,'$.capabilityId'),@sid nvarchar(200)=JSON_VALUE(@sdef,'$.stepId'),
    @pre nvarchar(max)=NULL,@prev nvarchar(max)=NULL;
   -- A step runs only after the step before it passed.
   IF @ord>0
   BEGIN
    INSERT @u(v) SELECT TOP (1) co.content_bytes FROM model.content_artifact a JOIN source.content_object co ON co.content_digest=a.content_digest
     WHERE a.artifact_kind=N'flight-step:'+@fid+N'#'+CONVERT(nvarchar(10),@ord-1) ORDER BY a.registered_date DESC,a.content_artifact_pk DESC;
    SELECT @prev=CONVERT(nvarchar(max),v) FROM @u;
    DELETE @u;
    IF ISNULL(JSON_VALUE(@prev,'$.status'),N'')<>N'PASSED'
     SET @pre=(SELECT @sid stepId,@scap capabilityId,N'NOT_RUN' status,JSON_QUERY(@sdef,'$.obligationIds') obligationIds,
      JSON_QUERY(@sdef,'$.expect') expect,N'EARLIER_STEP_NOT_PASSED' reasonCode,CONVERT(nvarchar(40),SYSUTCDATETIME(),127) completedAt
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   -- Product flow: each bind {target, fromStep, path, jsonPath?} sets an input member from an earlier step's retained result.
   DECLARE @sin nvarchar(max)=JSON_QUERY(@sdef,'$.input'),@sunb nvarchar(400)=NULL;
   DECLARE @sb TABLE(ordinal int PRIMARY KEY,target nvarchar(400),from_step nvarchar(200),path nvarchar(4000),json_path nvarchar(4000));
   IF @pre IS NULL
   BEGIN
    INSERT @sb SELECT CONVERT(int,b.[key]),JSON_VALUE(b.value,'$.target'),JSON_VALUE(b.value,'$.fromStep'),JSON_VALUE(b.value,'$.path'),JSON_VALUE(b.value,'$.jsonPath')
    FROM OPENJSON(ISNULL(JSON_QUERY(@sdef,'$.bind'),N'[]')) b;
    DECLARE @sbi int=0,@sbn int=(SELECT COUNT(*) FROM @sb),@sbt nvarchar(400),@sbf nvarchar(200),@sbp nvarchar(4000),@sbj nvarchar(4000),
     @sbo int,@sbe nvarchar(max),@sbr nvarchar(max),@sbv nvarchar(max);
    WHILE @sbi<@sbn AND @sunb IS NULL
    BEGIN
     SELECT @sbt=target,@sbf=from_step,@sbp=path,@sbj=json_path FROM @sb WHERE ordinal=@sbi;
     SET @sbo=(SELECT TOP (1) CONVERT(int,s.[key]) FROM OPENJSON(ISNULL(JSON_QUERY(@input,'$.stepIds'),N'[]')) s
      WHERE s.value=@sbf COLLATE Latin1_General_100_BIN2);
     SET @sbe=NULL;
     IF @sbo IS NOT NULL
     BEGIN
      INSERT @u(v) SELECT TOP (1) co.content_bytes FROM model.content_artifact a JOIN source.content_object co ON co.content_digest=a.content_digest
       WHERE a.artifact_kind=N'flight-step:'+@fid+N'#'+CONVERT(nvarchar(10),@sbo) ORDER BY a.registered_date DESC,a.content_artifact_pk DESC;
      SELECT @sbe=CONVERT(nvarchar(max),v) FROM @u;
      DELETE @u;
     END
     SET @sbr=JSON_QUERY(@sbe,'$.result');
     SET @sbv=CASE WHEN @sbr IS NOT NULL AND LEFT(ISNULL(@sbp,N''),1)=N'$' THEN JSON_VALUE(@sbr,@sbp) END;
     -- A string longer than the 4,000 characters JSON_VALUE returns reads as NULL there (lax mode). Read it as the last
     -- member of its parent through OPENJSON, which returns nvarchar(max). Only a parent path with no quote or space and a
     -- last member .name or ."name" (letters, digits, _ and -) are read this way; any other path keeps the result above.
     IF @sbv IS NULL AND @sbr IS NOT NULL AND LEFT(ISNULL(@sbp,N''),2)=N'$.'
     BEGIN
      DECLARE @sbd int,@sbk nvarchar(4000),@sbq nvarchar(4000);
      SET @sbd=LEN(@sbp)-CHARINDEX(N'.',REVERSE(@sbp))+1;
      SET @sbq=LEFT(@sbp,@sbd-1);
      SET @sbk=SUBSTRING(@sbp,@sbd+1,4000);
      IF LEN(@sbk)>=2 AND LEFT(@sbk,1)=N'"' AND RIGHT(@sbk,1)=N'"' SET @sbk=SUBSTRING(@sbk,2,LEN(@sbk)-2);
      IF LEFT(@sbq,1)=N'$' AND CHARINDEX(N'"',@sbq)=0 AND CHARINDEX(N' ',@sbq)=0 AND @sbk<>N'' AND @sbk NOT LIKE N'%[^A-Za-z0-9_-]%'
       AND JSON_QUERY(@sbr,@sbq) IS NOT NULL
       SELECT @sbv=[value] FROM OPENJSON(@sbr,@sbq) WHERE [key]=@sbk COLLATE Latin1_General_100_BIN2 AND [type]=1;
     END
     IF @sbv IS NOT NULL AND LEFT(ISNULL(@sbj,N''),1)=N'$' SET @sbv=CASE WHEN ISJSON(@sbv)=1 THEN JSON_VALUE(@sbv,@sbj) END;
     IF @sbv IS NULL OR @sbt IS NULL SET @sunb=ISNULL(@sbt,N'(target)');
     ELSE SET @sin=JSON_MODIFY(@sin,N'$.'+@sbt,@sbv);
     SET @sbi+=1;
    END
    IF @sunb IS NOT NULL
     SET @pre=(SELECT @sid stepId,@scap capabilityId,N'FAILED' status,JSON_QUERY(@sdef,'$.obligationIds') obligationIds,
      JSON_QUERY(@sdef,'$.expect') expect,N'BINDING_UNRESOLVED' reasonCode,@sunb actual,CONVERT(nvarchar(40),SYSUTCDATETIME(),127) completedAt
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   -- An operator that the step capability uses and that no declared mechanic binds refuses when its graph
   -- compiles, before the step could return a result: record that instead of dispatching.
   DECLARE @sops TABLE(operator nvarchar(200),use_count int,bound bit,mechanic_id nvarchar(400),definitions nvarchar(max));
   IF @pre IS NULL AND @scap IS NOT NULL
   BEGIN
    INSERT @sops EXEC analysis.read_capability_operator_bindings @capability_id=@scap,@estate_model_pk=@estate_model_pk;
    IF EXISTS(SELECT 1 FROM @sops WHERE bound=0)
     SET @pre=(SELECT @sid stepId,@scap capabilityId,N'FAILED' status,JSON_QUERY(@sdef,'$.obligationIds') obligationIds,
      JSON_QUERY(@sdef,'$.expect') expect,N'STEP_OPERATOR_UNBOUND' reasonCode,
      (SELECT STRING_AGG(CONVERT(nvarchar(max),operator),N',') WITHIN GROUP (ORDER BY operator) FROM @sops WHERE bound=0) actual,
      CONVERT(nvarchar(40),SYSUTCDATETIME(),127) completedAt FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   DECLARE @sctx nvarchar(max)=(SELECT @fid flightId,@ord ordinal,JSON_VALUE(@input,'$.promiseId') promiseId,JSON_QUERY(@sdef) step,
    JSON_QUERY(@pre) entry FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   EXEC analysis.put_session_text @key=N'toa_step_ctx',@value=@sctx;
   IF @pre IS NOT NULL BEGIN SELECT @noop value; RETURN; END
   DECLARE @sscn nvarchar(400)=(SELECT TOP (1) s.scenario_id FROM model.capability c
    JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities' COLLATE Latin1_General_100_BIN2
    JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate_model_pk
    JOIN model.capability_root_scenario r ON r.capability_version_pk=ec.capability_version_pk
    JOIN model.scenario s ON s.scenario_pk=r.scenario_pk
    WHERE c.capability_id=@scap COLLATE Latin1_General_100_BIN2 ORDER BY s.scenario_id);
   SELECT (SELECT @scap executionTarget,N'sidefx:capabilities' executionNamespace,ISNULL(@sscn,@scap) executionScenario,N'json' inputType,
    JSON_QUERY(@sin) dispatchRequest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;
   RETURN;
  END
  IF @step=N'step-check'
  BEGIN
   DECLARE @cx nvarchar(max)=analysis.fv_session_text(N'toa_step_ctx');
   IF @cx IS NULL THROW 51000,N'FLIGHT_STEP_STATE_MISSING',1;
   DECLARE @cstep nvarchar(max)=JSON_QUERY(@cx,'$.step'),@centry nvarchar(max)=JSON_QUERY(@cx,'$.entry');
   IF @centry IS NULL
   BEGIN
    DECLARE @cdisp nvarchar(100)=JSON_VALUE(@input,'$.disposition'),@cres nvarchar(max),@crt int;
    SELECT @cres=value,@crt=type FROM OPENJSON(@input) WHERE [key]='result';
    DECLARE @cexp nvarchar(max)=JSON_QUERY(@cstep,'$.expect'),@cpath nvarchar(4000)=JSON_VALUE(@cstep,'$.expect.path'),
     @cwant nvarchar(max),@cact nvarchar(max),@cst nvarchar(20);
    SELECT @cwant=value FROM OPENJSON(ISNULL(@cexp,N'{}')) WHERE [key]='equals';
    IF @cexp IS NOT NULL AND @crt IN (4,5) AND LEFT(ISNULL(@cpath,N''),1)=N'$'
     SET @cact=COALESCE(JSON_VALUE(@cres,@cpath),JSON_QUERY(@cres,@cpath));
    -- expect.jsonPath reads inside a member that holds JSON text (a writer receipt).
    IF @cact IS NOT NULL AND LEFT(ISNULL(JSON_VALUE(@cstep,'$.expect.jsonPath'),N''),1)=N'$'
     SET @cact=CASE WHEN ISJSON(@cact)=1 THEN JSON_VALUE(@cact,JSON_VALUE(@cstep,'$.expect.jsonPath')) END;
    SET @cst=CASE WHEN @cexp IS NOT NULL THEN CASE WHEN @cact=@cwant COLLATE Latin1_General_100_BIN2 THEN N'PASSED' ELSE N'FAILED' END
     WHEN @cdisp=N'terminated' THEN N'PASSED' ELSE N'FAILED' END;
    IF @cst=N'FAILED' AND JSON_QUERY(@cstep,'$.waitWhen') IS NOT NULL AND @crt IN (4,5)
    BEGIN
     DECLARE @wwant nvarchar(max),@wact nvarchar(max),@wpath nvarchar(4000)=JSON_VALUE(@cstep,'$.waitWhen.path');
     SELECT @wwant=value FROM OPENJSON(JSON_QUERY(@cstep,'$.waitWhen')) WHERE [key]='equals';
     IF LEFT(ISNULL(@wpath,N''),1)=N'$' SET @wact=COALESCE(JSON_VALUE(@cres,@wpath),JSON_QUERY(@cres,@wpath));
     IF @wact=@wwant COLLATE Latin1_General_100_BIN2 SET @cst=N'WAITING';
    END
    SET @centry=(SELECT JSON_VALUE(@cstep,'$.stepId') stepId,JSON_VALUE(@cstep,'$.capabilityId') capabilityId,@cst status,@cdisp disposition,
     JSON_QUERY(@cstep,'$.obligationIds') obligationIds,JSON_QUERY(@cexp) expect,@cact actual,
     JSON_QUERY(CASE WHEN @crt IN (4,5) THEN @cres END) result,CASE WHEN @crt NOT IN (4,5) THEN @cres END resultValue,
     CASE WHEN @cst=N'FAILED' THEN CASE WHEN @crt=5 AND JSON_VALUE(@cres,'$.status') IS NULL AND COALESCE(JSON_VALUE(@cres,'$.code'),JSON_VALUE(@cres,'$.receipt.code')) IS NOT NULL THEN N'EXECUTION_FAILED' WHEN @cexp IS NOT NULL THEN N'EXPECTATION_NOT_MET' ELSE N'STEP_NOT_RETURNED' END WHEN @cst=N'WAITING' THEN N'WAITING' END reasonCode,
     CASE WHEN @cst=N'FAILED' AND @crt=5 THEN COALESCE(JSON_VALUE(@cres,'$.code'),JSON_VALUE(@cres,'$.receipt.code')) END failureCode,
     CONVERT(nvarchar(40),SYSUTCDATETIME(),127) completedAt FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   END
   SET @centry=JSON_MODIFY(JSON_MODIFY(@centry,'$.flightId',JSON_VALUE(@cx,'$.flightId')),'$.ordinal',TRY_CONVERT(int,JSON_VALUE(@cx,'$.ordinal')));
   EXEC analysis.put_session_text @key=N'toa_step_entry',@value=@centry;
   IF @sv2=1
   BEGIN
    -- Recovery: record this attempt, then continue (repair and retry) while the step fails recoverably and
    -- declares recover, or stop.
    DECLARE @akey nvarchar(120)=analysis.fv_session_text(N'toa_step_akey');
    DECLARE @atl nvarchar(max)=ISNULL(analysis.fv_session_text(@akey),N'[]');
    DECLARE @anum int=(SELECT COUNT(*) FROM OPENJSON(@atl))+1;
    DECLARE @att nvarchar(max)=(SELECT @anum attempt,JSON_VALUE(@centry,'$.status') status,JSON_VALUE(@centry,'$.reasonCode') reasonCode,
     JSON_VALUE(@centry,'$.actual') actual,JSON_QUERY(@centry,'$.result') result,JSON_QUERY(analysis.fv_session_text(N'toa_step_rinfo')) repair
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    SET @atl=JSON_MODIFY(@atl,'append $',JSON_QUERY(@att));
    EXEC analysis.put_session_text @key=@akey,@value=@atl;
    SET @centry=JSON_MODIFY(@centry,'$.attempts',JSON_QUERY(@atl));
    EXEC analysis.put_session_text @key=N'toa_step_entry',@value=@centry;
    DECLARE @route nvarchar(20)=CASE WHEN JSON_VALUE(@centry,'$.status')=N'FAILED' AND JSON_QUERY(@cx,'$.step.recover') IS NOT NULL
      AND JSON_VALUE(@centry,'$.reasonCode') IN (N'EXPECTATION_NOT_MET',N'EXECUTION_FAILED',N'STEP_NOT_RETURNED',N'STEP_OPERATOR_UNBOUND') THEN N'CONTINUE' ELSE N'STOP' END;
    SELECT JSON_MODIFY(JSON_MODIFY(N'{}','$.request',JSON_QUERY(analysis.fv_session_text(N'toa_step_req'))),'$.route',@route) value;
    RETURN;
   END
   DECLARE @ckind nvarchar(80)=N'flight-step:'+JSON_VALUE(@cx,'$.flightId')+N'#'+JSON_VALUE(@cx,'$.ordinal');
   SELECT (SELECT N'apply-declared-change' executionTarget,N'sidefx:capabilities' executionNamespace,N'apply-declared-change' executionScenario,N'json' inputType,
    JSON_QUERY((SELECT N'declared-change.v1' contractId,N'content-artifact-change' changeKind,
     JSON_QUERY((SELECT N'content-artifact-change.v1' contractId,@ckind artifactKind,@centry [text],N'read-harness-authoring-state' verificationCapabilityId,
      JSON_QUERY(N'{"input":{"changeKind":"content-artifact-change","includeDefinitions":true},"expected":{"disposition":"terminated"}}') preflight,
      JSON_QUERY(N'{"resolvedDisposition":"terminated"}') route FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) payload FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) dispatchRequest
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;
   RETURN;
  END
  DECLARE @rentry nvarchar(max)=analysis.fv_session_text(N'toa_step_entry');
  IF @rentry IS NULL THROW 51000,N'FLIGHT_STEP_STATE_MISSING',1;
  DECLARE @rout nvarchar(max)=JSON_MODIFY(@rentry,'$.retention',JSON_QUERY((SELECT JSON_VALUE(@input,'$.result.disposition') disposition
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)));
  -- The finished step's state is released: its entry is retained as flight-step:<flightId>#<ordinal>.
  DECLARE @rakey nvarchar(120)=analysis.fv_session_text(N'toa_step_akey');
  IF @rakey IS NOT NULL EXEC analysis.put_session_text @key=@rakey,@value=@clear;
  EXEC analysis.put_session_text @key=N'toa_step_akey',@value=@clear;
  EXEC analysis.put_session_text @key=N'toa_step_entry',@value=@clear;
  EXEC analysis.put_session_text @key=N'toa_step_ctx',@value=@clear;
  EXEC analysis.put_session_text @key=N'toa_step_req',@value=@clear;
  EXEC analysis.put_session_text @key=N'toa_step_rinfo',@value=@clear;
  EXEC analysis.put_session_text @key=N'toa_step_carried',@value=@clear;
  SELECT @rout value;
  RETURN;
END
GO
DECLARE @after nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'analysis.fly_flight_step_cell')),NCHAR(13)+NCHAR(10),NCHAR(10));
DECLARE @base nvarchar(max)=(SELECT REPLACE(def,NCHAR(13)+NCHAR(10),NCHAR(10)) FROM #ov3_cell_base);
DECLARE @block nvarchar(max)=REPLACE(N'     -- A string longer than the 4,000 characters JSON_VALUE returns reads as NULL there (lax mode). Read it as the last
     -- member of its parent through OPENJSON, which returns nvarchar(max). Only a parent path with no quote or space and a
     -- last member .name or ."name" (letters, digits, _ and -) are read this way; any other path keeps the result above.
     IF @sbv IS NULL AND @sbr IS NOT NULL AND LEFT(ISNULL(@sbp,N''''),2)=N''$.''
     BEGIN
      DECLARE @sbd int,@sbk nvarchar(4000),@sbq nvarchar(4000);
      SET @sbd=LEN(@sbp)-CHARINDEX(N''.'',REVERSE(@sbp))+1;
      SET @sbq=LEFT(@sbp,@sbd-1);
      SET @sbk=SUBSTRING(@sbp,@sbd+1,4000);
      IF LEN(@sbk)>=2 AND LEFT(@sbk,1)=N''"'' AND RIGHT(@sbk,1)=N''"'' SET @sbk=SUBSTRING(@sbk,2,LEN(@sbk)-2);
      IF LEFT(@sbq,1)=N''$'' AND CHARINDEX(N''"'',@sbq)=0 AND CHARINDEX(N'' '',@sbq)=0 AND @sbk<>N'''' AND @sbk NOT LIKE N''%[^A-Za-z0-9_-]%''
       AND JSON_QUERY(@sbr,@sbq) IS NOT NULL
       SELECT @sbv=[value] FROM OPENJSON(@sbr,@sbq) WHERE [key]=@sbk COLLATE Latin1_General_100_BIN2 AND [type]=1;
     END
',NCHAR(13)+NCHAR(10),NCHAR(10));
DECLARE @a int=CHARINDEX(N'PROCEDURE analysis.fly_flight_step_cell',@after),@b int=CHARINDEX(N'PROCEDURE analysis.fly_flight_step_cell',@base);
DECLARE @present bit=CASE WHEN CHARINDEX(@block,@after)>0 THEN 1 ELSE 0 END;
DECLARE @same bit=CASE WHEN @a>0 AND @b>0 AND HASHBYTES('SHA2_256',REPLACE(SUBSTRING(@after,@a,DATALENGTH(@after)/2),@block,N''))=HASHBYTES('SHA2_256',SUBSTRING(@base,@b,DATALENGTH(@base)/2)) THEN 1 ELSE 0 END;
SELECT N'verify' AS result_set,'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'analysis.fly_flight_step_cell')) COLLATE Latin1_General_100_BIN2_UTF8)),2)) AS after_digest,
 @present AS block_present,@same AS rest_unchanged,CASE WHEN CHARINDEX(NCHAR(13),OBJECT_DEFINITION(OBJECT_ID(N'analysis.fly_flight_step_cell')))>0 THEN 1 ELSE 0 END AS crlf_introduced;
DROP TABLE #ov3_cell_base;
IF @present<>1 OR @same<>1
BEGIN
 RAISERROR(N'OV3_HARNESS_VERIFY_FAILED: the installed definition is not the base plus the one bind block; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
ROLLBACK TRANSACTION;
GO
SET NOEXEC OFF;
