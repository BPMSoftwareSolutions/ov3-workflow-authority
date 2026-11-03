-- repair-1-estate.sql
--
-- ============================== PREFLIGHT - NOT A WRITE ==============================
-- Byte-identical to the .commit twin except this banner and the terminal statement:
-- ROLLBACK TRANSACTION here, COMMIT TRANSACTION there. Nothing is written.
--
--
-- WHAT THIS DOES, in one transaction on the estate database:
--   1. installs the repaired analysis.compile_capability_dsl. The only change from the installed revision: a provider
--      operation's composing and outcome statements carry "commandTimeout":30, which sfx-estate-run-statement-port.v1
--      requires. Without it the slice's first live call failed (run 53ad6ca6, DECLARED_PROVIDER_CONFIGURATION_VALUE_MISSING);
--   2. verifies the installed body by digest, and compiles nerdery-view-wildlife-home's declared source to the exact
--      document the read-only compile produced, both timeouts included;
--   3. retains the flight's promise flight-promise:nerdery-citizen-slice-runtime-repair.
-- WHERE: the estate database. Run the whole file in one session; the transaction spans the batches (under a minute).
-- BASES: compiler body sha256:45e34c80e995f1fef0a3f148b567681f3b9a80d1c3ab0121f9a0996f68bf5594, mint sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e.
-- RESULT SETS: base; verify (compiler_body = compiler_expected, smoke_document = smoke_expected, compose_timeout and
-- outcome_timeout 30); minted (1 row); readback (retained 1).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @cd nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'analysis.compile_capability_dsl')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @cd=SUBSTRING(@cd,CHARINDEX(N'PROCEDURE analysis.compile_capability_dsl',@cd),DATALENGTH(@cd)/2);
WHILE DATALENGTH(@cd)>0 AND RIGHT(@cd,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @cd=LEFT(@cd,DATALENGTH(@cd)/2-1);
DECLARE @cd_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@cd COLLATE Latin1_General_100_BIN2_UTF8)),2));
DECLARE @m varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'model.mint_content_artifact')) COLLATE Latin1_General_100_BIN2_UTF8)),2));
SELECT N'base' AS result_set,@cd_digest AS compiler_body,'sha256:45e34c80e995f1fef0a3f148b567681f3b9a80d1c3ab0121f9a0996f68bf5594' AS compiler_expected,@m AS mint_installed,'sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e' AS mint_expected;
IF @cd_digest IS NULL OR @cd_digest<>'sha256:45e34c80e995f1fef0a3f148b567681f3b9a80d1c3ab0121f9a0996f68bf5594' OR @m IS NULL OR @m<>'sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e'
BEGIN
 RAISERROR(N'REPAIR1_BASE_MOVED: the installed compiler or mint is not the reviewed base; nothing is changed.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
GO
CREATE OR ALTER PROCEDURE analysis.compile_capability_dsl
  @input nvarchar(max),@estate_model_pk bigint
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  IF @input IS NULL OR ISJSON(@input)<>1 OR LEFT(LTRIM(@input),1)<>N'{'
    THROW 51000,N'COMPILE_DSL_REQUEST_INVALID',1;
  IF EXISTS(SELECT 1 FROM OPENJSON(@input) WHERE [key] NOT IN (N'source'))
    THROW 51000,N'COMPILE_DSL_REQUEST_SHAPE_INVALID',1;
  DECLARE @source nvarchar(max)=(SELECT [value] FROM OPENJSON(@input) WHERE [key]=N'source');
  IF @source IS NULL OR LEN(@source)=0 THROW 51000,N'COMPILE_DSL_SOURCE_REQUIRED',1;
  DECLARE @estate bigint=@estate_model_pk;
  IF @estate IS NULL SELECT @estate=estate_model_pk FROM source.current_model WHERE singleton_id=1;
  IF @estate IS NULL THROW 51000,N'COMPILE_DSL_ESTATE_REQUIRED',1;
  DECLARE @source_digest varchar(71)=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@source COLLATE Latin1_General_100_BIN2_UTF8))),2));
  DECLARE @lines TABLE(line_no int PRIMARY KEY,line nvarchar(max));
  DECLARE @rest nvarchar(max)=@source,@line nvarchar(max),@ln int=0,@nl int;
  WHILE LEN(@rest)>0
  BEGIN
    SET @ln+=1;
    SET @nl=CHARINDEX(CHAR(10),@rest);
    SET @line=CASE WHEN @nl=0 THEN @rest ELSE LEFT(@rest,@nl-1) END;
    SET @rest=CASE WHEN @nl=0 THEN N'' ELSE SUBSTRING(@rest,@nl+1,LEN(@rest)) END;
    SET @line=LTRIM(RTRIM(REPLACE(REPLACE(@line,CHAR(13),N''),CHAR(9),N' ')));
    INSERT @lines VALUES(@ln,@line);
  END
  DECLARE @errors TABLE(seq int IDENTITY,line_no int,code nvarchar(40),message nvarchar(400));
  DECLARE @capability_id nvarchar(200)=NULL,@intent nvarchar(max)=NULL,@outcome nvarchar(max)=NULL;
  DECLARE @input_id nvarchar(200)=NULL,@input_schema nvarchar(max)=NULL;
  DECLARE @output_id nvarchar(200)=NULL,@output_schema nvarchar(max)=NULL;
  DECLARE @display_select nvarchar(100)=NULL,@display_format nvarchar(20)=NULL;
  DECLARE @scenarios TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_id nvarchar(200) COLLATE Latin1_General_100_BIN2,root bit,terminal bit,given_txt nvarchar(max),when_txt nvarchar(max),then_txt nvarchar(max),line_no int,input_contract nvarchar(200),output_contract nvarchar(200),given_line int,when_line int,then_line int);
  DECLARE @operations TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_ordinal int,operation_id nvarchar(200) COLLATE Latin1_General_100_BIN2,kind nvarchar(40),port_id nvarchar(200) COLLATE Latin1_General_100_BIN2,line_no int,target_scenario nvarchar(200),variants_json nvarchar(max),collection_path nvarchar(400),max_iterations int);
  -- Example inquiries, further contracts, scenario and operation outcome variants,
  -- selection routes and CLI input/readings.
  DECLARE @inquiries TABLE(ordinal int IDENTITY PRIMARY KEY,txt nvarchar(max),line_no int);
  DECLARE @extra_contracts TABLE(ordinal int IDENTITY PRIMARY KEY,contract_id nvarchar(200) COLLATE Latin1_General_100_BIN2,schema_json nvarchar(max),line_no int);
  DECLARE @scenario_variants TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_ordinal int,variant_id nvarchar(200) COLLATE Latin1_General_100_BIN2,classification nvarchar(20),line_no int);
  DECLARE @op_variants TABLE(ordinal int IDENTITY PRIMARY KEY,operation_ordinal int,variant_id nvarchar(200) COLLATE Latin1_General_100_BIN2,classification nvarchar(20),is_terminal bit,line_no int);
  DECLARE @routes TABLE(ordinal int IDENTITY PRIMARY KEY,from_scenario nvarchar(200) COLLATE Latin1_General_100_BIN2,variant nvarchar(200) COLLATE Latin1_General_100_BIN2,to_scenario nvarchar(200) COLLATE Latin1_General_100_BIN2,line_no int);
  DECLARE @recurrences TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_id nvarchar(200) COLLATE Latin1_General_100_BIN2,continue_variant nvarchar(200) COLLATE Latin1_General_100_BIN2,stop_variant nvarchar(200) COLLATE Latin1_General_100_BIN2,max_iterations int,line_no int);
  DECLARE @readings TABLE(ordinal int IDENTITY PRIMARY KEY,reading nvarchar(100),altitudes nvarchar(400));
  DECLARE @cli_input_type nvarchar(10)=N'json',@cli_input_path nvarchar(400)=NULL,@last_operation int=NULL,@items nvarchar(max);
  DECLARE @bindings TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_ordinal int,port_id nvarchar(200) COLLATE Latin1_General_100_BIN2,form nvarchar(20),platform_id nvarchar(200),provider_id nvarchar(200),statement nvarchar(max),result_column nvarchar(200),config_json nvarchar(max),platform_line int,provider_line int,statement_line int,result_line int,config_line int,bind_line int);
  DECLARE @topology TABLE(ordinal int IDENTITY PRIMARY KEY,form nvarchar(20) COLLATE Latin1_General_100_BIN2,root_id nvarchar(200),join_id nvarchar(200),legs nvarchar(max),line_no int);
  DECLARE @provider_bindings TABLE(ordinal int IDENTITY PRIMARY KEY,id nvarchar(200) COLLATE Latin1_General_100_BIN2,content nvarchar(max),digest varchar(71),line_no int);
  DECLARE @cur_scenario int=NULL,@cur_binding int=NULL;
  -- Provider operations ("operation <id> uses provider <capability-id>"), their static request members (config:) and their
  -- dynamic ones ("input <member> from <scenario-or-operation> <json-path>"), each scenario's outcome ("outcome from
  -- <operation> <json-path>"), and the feature the source pins ("feature <capability-id> sha256:<hex>").
  DECLARE @provider_ops TABLE(op_ordinal int PRIMARY KEY,provider_id nvarchar(400) COLLATE Latin1_General_100_BIN2,config_json nvarchar(max),config_line int,
    prefix_ordinal int,compose_binding int,provider_scenario nvarchar(400),line_no int);
  DECLARE @provider_inputs TABLE(ordinal int IDENTITY PRIMARY KEY,op_ordinal int,member nvarchar(200) COLLATE Latin1_General_100_BIN2,
    source_ref nvarchar(400) COLLATE Latin1_General_100_BIN2,json_path nvarchar(400),carrier_path nvarchar(400),line_no int);
  DECLARE @scenario_outcomes TABLE(scenario_ordinal int PRIMARY KEY,source_ref nvarchar(400) COLLATE Latin1_General_100_BIN2,json_path nvarchar(400),
    carrier_path nvarchar(400),first_ordinal int,op_ordinal int,stmt_binding int,line_no int);
  DECLARE @cur_provider_op int=NULL,@feature_cap nvarchar(400)=NULL,@feature_hex varchar(64)=NULL,@feature_line int=NULL,@feature_text nvarchar(max)=NULL;
  DECLARE @check_procedure nvarchar(400)=N'analysis.check_capability_feature_conformance';
  DECLARE @i int=0,@n int=(SELECT MAX(line_no) FROM @lines),@sp int,@tok nvarchar(200),@tail nvarchar(max);
  WHILE @i<@n
  BEGIN
    SET @i+=1;
    SET @line=(SELECT line FROM @lines WHERE line_no=@i);
    IF @line=N'' OR LEFT(@line,1)=N'#' CONTINUE;
    IF LEFT(@line,11)=N'capability '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,12,LEN(@line)));
      IF @tail=N'' OR CHARINDEX(N' ',@tail)>0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'capability: missing trailing value or unexpected tokens');
      ELSE IF @capability_id IS NOT NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'capability: repeated capability id');
      ELSE IF @tail NOT LIKE N'[a-z0-9]%' OR @tail LIKE N'%[^a-z0-9.-]%'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'capability: id violates the id rule');
      ELSE SET @capability_id=@tail;
    END
    ELSE IF LEFT(@line,7)=N'intent:'
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,8,LEN(@line)));
      IF @tail=N'' INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'intent: missing trailing value');
      ELSE SET @intent=@tail;
    END
    ELSE IF LEFT(@line,8)=N'outcome:'
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,9,LEN(@line)));
      IF @tail=N'' INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'outcome: missing trailing value');
      ELSE SET @outcome=@tail;
    END
    ELSE IF LEFT(@line,15)=N'input contract ' OR LEFT(@line,16)=N'output contract '
    BEGIN
      DECLARE @is_input bit=CASE WHEN LEFT(@line,15)=N'input contract ' THEN 1 ELSE 0 END;
      SET @tail=LTRIM(SUBSTRING(@line,CASE WHEN @is_input=1 THEN 16 ELSE 17 END,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'contract: missing inline-json value');
      ELSE
      BEGIN
        SET @tok=LEFT(@tail,@sp-1);
        SET @rest=LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail)));
        IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'contract: id violates the id rule');
        ELSE IF (@is_input=1 AND @input_id IS NOT NULL) OR (@is_input=0 AND @output_id IS NOT NULL)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'contract: repeated contract id');
        ELSE IF ISJSON(@rest)<>1 OR LEFT(@rest,1)<>N'{'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_CONTRACT_INVALID',N'contract: inline-json is not a JSON object');
        ELSE IF @is_input=1 BEGIN SET @input_id=@tok; SET @input_schema=@rest; END
        ELSE BEGIN SET @output_id=@tok; SET @output_schema=@rest; END
      END
    END
    ELSE IF LEFT(@line,12)=N'cli display '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,13,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0 OR LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail))) NOT LIKE N'as %'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'cli display: expected "<select> as <format>"');
      ELSE
      BEGIN
        SET @tok=LEFT(@tail,@sp-1);
        SET @rest=LTRIM(SUBSTRING(SUBSTRING(@tail,@sp+1,LEN(@tail)),3,LEN(@tail)));
        IF @display_select IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'cli display: repeated declaration');
        ELSE IF @rest<>N'json'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'cli display: unknown format');
        ELSE BEGIN SET @display_select=@tok; SET @display_format=@rest; END
      END
    END
    ELSE IF LEFT(@line,9)=N'scenario '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,10,LEN(@line)));
      IF @tail=N'' INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'scenario: missing id');
      ELSE
      BEGIN
        SET @sp=CHARINDEX(N' ',@tail);
        SET @tok=CASE WHEN @sp=0 THEN @tail ELSE LEFT(@tail,@sp-1) END;
        SET @rest=CASE WHEN @sp=0 THEN N'' ELSE LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail))) END;
        IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'scenario: id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM @scenarios s WHERE s.scenario_id=@tok COLLATE Latin1_General_100_BIN2)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'scenario: repeated scenario id');
        ELSE
        BEGIN
          DECLARE @sid nvarchar(200)=@tok;
          DECLARE @has_root bit=0,@has_terminal bit=0,@bad_flag nvarchar(100)=NULL,@sc_in nvarchar(200)=NULL,@sc_out nvarchar(200)=NULL;
          WHILE @rest<>N''
          BEGIN
            SET @sp=CHARINDEX(N' ',@rest);
            SET @tok=CASE WHEN @sp=0 THEN @rest ELSE LEFT(@rest,@sp-1) END;
            SET @rest=CASE WHEN @sp=0 THEN N'' ELSE LTRIM(SUBSTRING(@rest,@sp+1,LEN(@rest))) END;
            IF @tok=N'root' AND @has_root=0 SET @has_root=1
            ELSE IF @tok=N'terminal' AND @has_terminal=0 SET @has_terminal=1
            ELSE IF LEFT(@tok,6)=N'input=' AND @sc_in IS NULL AND LEN(@tok)>6 SET @sc_in=SUBSTRING(@tok,7,200)
            ELSE IF LEFT(@tok,7)=N'output=' AND @sc_out IS NULL AND LEN(@tok)>7 SET @sc_out=SUBSTRING(@tok,8,200)
            ELSE IF @bad_flag IS NULL SET @bad_flag=@tok;
          END
          IF @bad_flag IS NOT NULL
            INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'scenario: unknown flag '+@bad_flag);
          ELSE
          BEGIN
            INSERT @scenarios(scenario_id,root,terminal,line_no,input_contract,output_contract) VALUES(@sid,@has_root,@has_terminal,@i,@sc_in,@sc_out);
            SET @cur_scenario=SCOPE_IDENTITY();
            SET @last_operation=NULL;
            SET @cur_provider_op=NULL;
          END
        END
      END
    END
    ELSE IF LEFT(@line,6)=N'given:' OR LEFT(@line,5)=N'when:' OR LEFT(@line,5)=N'then:'
    BEGIN
      DECLARE @which nvarchar(10)=CASE WHEN LEFT(@line,6)=N'given:' THEN N'given' WHEN LEFT(@line,5)=N'when:' THEN N'when' ELSE N'then' END;
      SET @tail=LTRIM(SUBSTRING(@line,CASE WHEN @which=N'given' THEN 7 ELSE 6 END,LEN(@line)));
      IF @tail=N''
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',@which+N': missing trailing value');
      ELSE IF @cur_scenario IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',@which+N': no scenario to attach to');
      ELSE
      BEGIN
        IF @which=N'given' UPDATE @scenarios SET given_txt=@tail,given_line=@i WHERE ordinal=@cur_scenario;
        IF @which=N'when' UPDATE @scenarios SET when_txt=@tail,when_line=@i WHERE ordinal=@cur_scenario;
        IF @which=N'then' UPDATE @scenarios SET then_txt=@tail,then_line=@i WHERE ordinal=@cur_scenario;
      END
    END
    ELSE IF LEFT(@line,10)=N'operation '
    BEGIN
      SET @cur_provider_op=NULL;
      SET @tail=LTRIM(SUBSTRING(@line,11,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0 INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "<id> kind <kind> port <port-id>"');
      ELSE
      BEGIN
        SET @tok=LEFT(@tail,@sp-1);
        SET @rest=LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail)));
        IF @cur_scenario IS NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'operation: no scenario to attach to');
        ELSE IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'operation: id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM @operations o WHERE o.operation_id=@tok COLLATE Latin1_General_100_BIN2)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'operation: repeated operation id');
        ELSE IF LEFT(@rest,14)=N'uses provider '
        BEGIN
          -- operation <id> uses provider <capability-id>: the operation hands its job to that provider capability, named by
          -- identity. It compiles to the estate's dispatch that binds no technical debt: vault, credential and open, a
          -- statement that composes the provider's request from the config: and input lines, and the generic capability
          -- invocation of the provider, whose result lands at result. The operation keeps its id and states the provider.
          DECLARE @pop_id nvarchar(200)=@tok,@pop_provider nvarchar(400)=LTRIM(SUBSTRING(@rest,15,LEN(@rest)));
          DECLARE @pop_base nvarchar(200)=REPLACE(@pop_id,N'.',N'-');
          IF @pop_provider=N'' OR CHARINDEX(N' ',@pop_provider)>0
            INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "<id> uses provider <capability-id>"');
          ELSE IF EXISTS(SELECT 1 FROM @operations o WHERE o.operation_id IN (@pop_id+N'-vault',@pop_id+N'-credential',@pop_id+N'-open',@pop_id+N'-compose'))
            OR EXISTS(SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=@cur_scenario
              AND b.port_id IN (@pop_base,@pop_base+N'-vault',@pop_base+N'-credential',@pop_base+N'-open',@pop_base+N'-compose'))
            INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'operation: an operation or port it compiles to is already declared');
          ELSE
          BEGIN
            IF @cur_binding IS NOT NULL
            BEGIN
              IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'statement'
                AND (b.platform_id IS NULL OR b.provider_id IS NULL OR b.statement IS NULL OR b.result_column IS NULL))
                INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'bind: missing one of its four keys');
              IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'platform'
                AND (b.platform_id IS NULL OR (b.provider_id IS NULL AND b.config_json IS NULL)))
                INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'platform bind: missing platform, config or provider');
              SET @cur_binding=NULL;
            END
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-vault',N'invoke-port',@pop_base+N'-vault',@i);
            DECLARE @pop_first int=SCOPE_IDENTITY();
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-credential',N'invoke-port',@pop_base+N'-credential',@i);
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-open',N'invoke-port',@pop_base+N'-open',@i);
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-compose',N'invoke-port',@pop_base+N'-compose',@i);
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id,N'invoke-port',@pop_base,@i);
            SET @last_operation=SCOPE_IDENTITY();
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-vault',N'platform',N'sfx-vault-host-read-port.v1',N'{"providerId":"sfx-vault-file-host","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-file"}}',@i,@i);
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-credential',N'platform',N'sfx-estate-credential-port.v1',N'{"providerId":"sfx-estate-database-credential","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}',@i,@i);
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-open',N'platform',N'sfx-vault-reference-open-port.v1',N'{"providerId":"sfx-vault-secret-service-reference","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-secret-service"}}',@i,@i);
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-compose',N'platform',N'sfx-estate-run-statement-port.v1',NULL,@i,@i);
            DECLARE @pop_compose int=SCOPE_IDENTITY();
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base,N'platform',N'generic-capability-invocation.v1',N'{"providerId":"ScenarioKernel.NodePlatform","authoritySource":"DATABASE","capabilityIdPath":"executionTarget","namespacePath":"executionNamespace","scenarioPath":"executionScenario","requestPath":"dispatchRequest","resultPath":"result","lineageMode":"retain-nested-execution"}',@i,@i);
            INSERT @provider_ops(op_ordinal,provider_id,prefix_ordinal,compose_binding,line_no) VALUES(@last_operation,@pop_provider,@pop_first,@pop_compose,@i);
            SET @cur_provider_op=@last_operation;
          END
        END
        ELSE IF @rest NOT LIKE N'kind % port %' AND @rest NOT LIKE N'kind invoke-scenario scenario %'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "kind invoke-port port <port-id>", "kind invoke-scenario scenario <scenario-id>", "kind for-each port <port-id> over <collection-path>" or "uses provider <capability-id>"');
        ELSE
        BEGIN
          DECLARE @op_id nvarchar(200)=@tok;
          SET @rest=LTRIM(SUBSTRING(@rest,6,LEN(@rest)));
          SET @sp=CHARINDEX(N' ',@rest);
          DECLARE @kind_value nvarchar(100)=CASE WHEN @sp=0 THEN @rest ELSE LEFT(@rest,@sp-1) END;
          SET @rest=CASE WHEN @sp=0 THEN N'' ELSE LTRIM(SUBSTRING(@rest,@sp+1,LEN(@rest))) END;
          IF @kind_value=N'invoke-scenario'
          BEGIN
            SET @tok=CASE WHEN LEFT(@rest,9)=N'scenario ' THEN LTRIM(SUBSTRING(@rest,10,LEN(@rest))) ELSE N'' END;
            IF @tok=N'' OR CHARINDEX(N' ',@tok)>0 OR @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
              INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "kind invoke-scenario scenario <scenario-id>"');
            ELSE
            BEGIN
              INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no,target_scenario) VALUES(@cur_scenario,@op_id,N'invoke-scenario',NULL,@i,@tok);
              SET @last_operation=SCOPE_IDENTITY();
            END
          END
          ELSE IF @kind_value=N'for-each'
          BEGIN
            -- kind for-each port <port-id> over <collection-path> [max <n>]: a graph-level fold whose body is
            -- the bound port, invoked once per element of the collection at the path, in order.
            DECLARE @fe_items nvarchar(max)=N'["'+REPLACE(STRING_ESCAPE(@rest,'json'),N' ',N'","')+N'"]',
              @fe_port nvarchar(200)=NULL,@fe_path nvarchar(400)=NULL,@fe_max nvarchar(20)=NULL;
            IF (SELECT COUNT(*) FROM OPENJSON(@fe_items)) NOT IN (4,6)
              OR (SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'0')<>N'port'
              OR (SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'2')<>N'over'
              OR ((SELECT COUNT(*) FROM OPENJSON(@fe_items))=6 AND (SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'4')<>N'max')
              OR EXISTS(SELECT 1 FROM OPENJSON(@fe_items) WHERE value=N'')
              INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "kind for-each port <port-id> over <collection-path> [max <n>]"');
            ELSE
            BEGIN
              SELECT @fe_port=(SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'1'),
                @fe_path=(SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'3'),
                @fe_max=(SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'5');
              IF @fe_port NOT LIKE N'[a-z0-9]%' OR @fe_port LIKE N'%[^a-z0-9.-]%'
                INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'operation: port id violates the id rule');
              ELSE IF @fe_max IS NOT NULL AND (TRY_CONVERT(int,@fe_max) IS NULL OR TRY_CONVERT(int,@fe_max)<1)
                INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'operation: for-each max must be a positive integer');
              ELSE
              BEGIN
                -- The kernel requires a finite maximumIterations; without max it is the largest it admits.
                INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no,collection_path,max_iterations)
                VALUES(@cur_scenario,@op_id,N'for-each',@fe_port,@i,@fe_path,ISNULL(TRY_CONVERT(int,@fe_max),2147483647));
                SET @last_operation=SCOPE_IDENTITY();
              END
            END
          END
          ELSE IF @kind_value<>N'invoke-port'
            INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'operation: unknown kind');
          ELSE IF LEFT(@rest,5)<>N'port '
            INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: missing port');
          ELSE
          BEGIN
            SET @tok=LTRIM(SUBSTRING(@rest,6,LEN(@rest)));
            IF @tok=N'' OR CHARINDEX(N' ',@tok)>0
              INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: missing port id');
            ELSE IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
              INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'operation: port id violates the id rule');
            ELSE
            BEGIN
              INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@op_id,N'invoke-port',@tok,@i);
              SET @last_operation=SCOPE_IDENTITY();
            END
          END
        END
      END
    END
    ELSE IF LEFT(@line,14)=N'platform bind ' OR LEFT(@line,5)=N'bind '
    BEGIN
      SET @cur_provider_op=NULL;
      DECLARE @form nvarchar(20)=CASE WHEN LEFT(@line,14)=N'platform bind ' THEN N'platform' ELSE N'statement' END;
      SET @tail=LTRIM(SUBSTRING(@line,CASE WHEN @form=N'platform' THEN 15 ELSE 6 END,LEN(@line)));
      IF @cur_scenario IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'bind: no scenario to attach to');
      ELSE IF @tail=N'' OR CHARINDEX(N' ',@tail)>0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'bind: missing or invalid port id');
      ELSE
      BEGIN
        IF @cur_binding IS NOT NULL
        BEGIN
          IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'statement'
            AND (b.platform_id IS NULL OR b.provider_id IS NULL OR b.statement IS NULL OR b.result_column IS NULL))
            INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'bind: missing one of its four keys');
          IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'platform'
            AND (b.platform_id IS NULL OR (b.provider_id IS NULL AND b.config_json IS NULL)))
            INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'platform bind: missing platform, config or provider');
        END
        IF @tail NOT LIKE N'[a-z0-9]%' OR @tail LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'bind: port id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=@cur_scenario AND b.port_id=@tail COLLATE Latin1_General_100_BIN2)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'bind: repeated port id in the scenario');
        ELSE
        BEGIN
          INSERT @bindings(scenario_ordinal,port_id,form,bind_line) VALUES(@cur_scenario,@tail,@form,@i);
          SET @cur_binding=SCOPE_IDENTITY();
        END
      END
    END
    ELSE IF LEFT(@line,9)=N'platform:' OR LEFT(@line,9)=N'provider:'
    BEGIN
      DECLARE @is_platform bit=CASE WHEN LEFT(@line,9)=N'platform:' THEN 1 ELSE 0 END;
      SET @tail=LTRIM(SUBSTRING(@line,10,LEN(@line)));
      IF @cur_binding IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'platform/provider: no bind to attach to');
      ELSE IF @tail=N'' OR CHARINDEX(N' ',@tail)>0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'platform/provider: missing or invalid id');
      ELSE IF @tail NOT LIKE N'[a-z0-9A-Z]%' OR @tail LIKE N'%[^a-zA-Z0-9.-]%'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'platform/provider: id violates the id rule');
      ELSE
      BEGIN
        IF @is_platform=1 AND (SELECT b.platform_id FROM @bindings b WHERE b.ordinal=@cur_binding) IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'platform: repeated key in bind');
        IF @is_platform=0 AND (SELECT b.provider_id FROM @bindings b WHERE b.ordinal=@cur_binding) IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'provider: repeated key in bind');
        IF @is_platform=1 UPDATE @bindings SET platform_id=@tail,platform_line=@i WHERE ordinal=@cur_binding;
        IF @is_platform=0 UPDATE @bindings SET provider_id=@tail,provider_line=@i WHERE ordinal=@cur_binding;
      END
    END
    ELSE IF LEFT(@line,7)=N'config:'
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,8,LEN(@line)));
      IF @cur_provider_op IS NOT NULL
      BEGIN
        -- After a provider operation, config: holds the static members of the provider's request.
        IF @tail=N'' OR LEFT(@tail,1)<>N'{' OR ISJSON(@tail)<>1
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'config: expected a single-line JSON object');
        ELSE IF (SELECT p.config_json FROM @provider_ops p WHERE p.op_ordinal=@cur_provider_op) IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'config: repeated key in operation');
        ELSE
          UPDATE @provider_ops SET config_json=@tail,config_line=@i WHERE op_ordinal=@cur_provider_op;
      END
      ELSE IF @cur_binding IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'config: no bind to attach to');
      ELSE IF (SELECT b.form FROM @bindings b WHERE b.ordinal=@cur_binding)=N'statement'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'config: not admitted for a statement bind');
      ELSE IF @tail=N'' OR LEFT(@tail,1)<>N'{' OR ISJSON(@tail)<>1
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'config: expected a single-line JSON object');
      ELSE IF (SELECT b.config_json FROM @bindings b WHERE b.ordinal=@cur_binding) IS NOT NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'config: repeated key in bind');
      ELSE
        UPDATE @bindings SET config_json=@tail,config_line=@i WHERE ordinal=@cur_binding;
    END
    ELSE IF LEFT(@line,10)=N'statement:' OR LEFT(@line,7)=N'result:'
    BEGIN
      DECLARE @is_statement bit=CASE WHEN LEFT(@line,10)=N'statement:' THEN 1 ELSE 0 END;
      SET @tail=LTRIM(SUBSTRING(@line,CASE WHEN @is_statement=1 THEN 11 ELSE 8 END,LEN(@line)));
      IF @cur_binding IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'statement/result: no bind to attach to');
      ELSE IF @tail=N'' OR (@is_statement=0 AND CHARINDEX(N' ',@tail)>0)
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'statement/result: missing or invalid value');
      ELSE IF (SELECT b.form FROM @bindings b WHERE b.ordinal=@cur_binding)=N'platform'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'statement/result: not admitted for a platform bind');
      ELSE
      BEGIN
        IF @is_statement=1 AND (SELECT b.statement FROM @bindings b WHERE b.ordinal=@cur_binding) IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'statement: repeated key in bind');
        IF @is_statement=0 AND (SELECT b.result_column FROM @bindings b WHERE b.ordinal=@cur_binding) IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'result: repeated key in bind');
        IF @is_statement=1 UPDATE @bindings SET statement=@tail,statement_line=@i WHERE ordinal=@cur_binding;
        IF @is_statement=0 UPDATE @bindings SET result_column=@tail,result_line=@i WHERE ordinal=@cur_binding;
      END
    END
    ELSE IF LEFT(@line,10)=N'broadcast '
    BEGIN
      DECLARE @btail nvarchar(max)=LTRIM(SUBSTRING(@line,11,LEN(@line)));
      DECLARE @btok int=CHARINDEX(N' to ',@btail);
      IF @btok=0 OR CHARINDEX(N',',@btail)=0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'broadcast: expected "<root> to <leg>,<leg>[,<leg>...]"');
      ELSE IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'broadcast: repeated construct');
      ELSE
      BEGIN
        DECLARE @broot nvarchar(200)=LTRIM(RTRIM(LEFT(@btail,@btok-1)));
        DECLARE @blegs nvarchar(max)=LTRIM(RTRIM(SUBSTRING(@btail,@btok+4,LEN(@btail))));
        IF @broot NOT LIKE N'[a-z0-9]%' OR @broot LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'broadcast: root id violates the id rule');
        ELSE IF @blegs=N'' OR EXISTS(SELECT 1 FROM STRING_SPLIT(@blegs,N',') l WHERE LTRIM(RTRIM(l.value))=N'' OR LTRIM(RTRIM(l.value)) NOT LIKE N'[a-z0-9]%' OR LTRIM(RTRIM(l.value)) LIKE N'%[^a-z0-9.-]%')
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'broadcast: leg id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM STRING_SPLIT(@blegs,N',') l GROUP BY LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 HAVING COUNT(*)>1)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'broadcast: repeated leg id');
        ELSE
          INSERT @topology(form,root_id,legs,line_no) VALUES(N'broadcast',@broot,@blegs,@i);
      END
    END
    ELSE IF LEFT(@line,5)=N'join '
    BEGIN
      DECLARE @jtail nvarchar(max)=LTRIM(SUBSTRING(@line,6,LEN(@line)));
      DECLARE @jidx int=CHARINDEX(N' from ',@jtail);
      IF @jidx=0 OR CHARINDEX(N',',@jtail)=0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'join: expected "<join-scenario> from <leg>,<leg>[,<leg>...]"');
      ELSE IF EXISTS(SELECT 1 FROM @topology WHERE form=N'join')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'join: repeated construct');
      ELSE
      BEGIN
        DECLARE @jroot nvarchar(200)=LTRIM(RTRIM(LEFT(@jtail,@jidx-1)));
        DECLARE @jlegs nvarchar(max)=LTRIM(RTRIM(SUBSTRING(@jtail,@jidx+6,LEN(@jtail))));
        IF @jroot NOT LIKE N'[a-z0-9]%' OR @jroot LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'join: scenario id violates the id rule');
        ELSE IF @jlegs=N'' OR EXISTS(SELECT 1 FROM STRING_SPLIT(@jlegs,N',') l WHERE LTRIM(RTRIM(l.value))=N'' OR LTRIM(RTRIM(l.value)) NOT LIKE N'[a-z0-9]%' OR LTRIM(RTRIM(l.value)) LIKE N'%[^a-z0-9.-]%')
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'join: leg id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM STRING_SPLIT(@jlegs,N',') l GROUP BY LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 HAVING COUNT(*)>1)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'join: repeated leg id');
        ELSE
          INSERT @topology(form,join_id,legs,line_no) VALUES(N'join',@jroot,@jlegs,@i);
      END
    END
    ELSE IF LEFT(@line,8)=N'inquiry:'
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,9,LEN(@line)));
      IF @tail=N'' INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'inquiry: missing trailing value');
      ELSE IF (SELECT COUNT(*) FROM @inquiries)>=3
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'inquiry: a capability holds three example inquiries (relevant_inquery_1..3)');
      ELSE INSERT @inquiries(txt,line_no) VALUES(@tail,@i);
    END
    ELSE IF LEFT(@line,9)=N'contract '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,10,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'contract: missing inline-json value');
      ELSE
      BEGIN
        SET @tok=LEFT(@tail,@sp-1);
        SET @rest=LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail)));
        IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'contract: id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM @extra_contracts e WHERE e.contract_id=@tok COLLATE Latin1_General_100_BIN2)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'contract: repeated contract id');
        ELSE IF ISJSON(@rest)<>1 OR LEFT(@rest,1)<>N'{'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_CONTRACT_INVALID',N'contract: inline-json is not a JSON object');
        ELSE INSERT @extra_contracts(contract_id,schema_json,line_no) VALUES(@tok,@rest,@i);
      END
    END
    ELSE IF LEFT(@line,17)=N'provider binding '
    BEGIN
      -- provider binding <id> <inline-json>: a document-level provider-input-binding artifact. Its content is the JSON
      -- without the whitespace outside strings, addressed by sha256 over its UTF-8 bytes. A configuration names it as
      -- "@provider-binding:<id>" and receives the digest; the author path mints the content.
      SET @tail=LTRIM(SUBSTRING(@line,18,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'provider binding: expected "provider binding <id> <inline-json>"');
      ELSE
      BEGIN
        SET @tok=LEFT(@tail,@sp-1);
        SET @rest=LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail)));
        IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'provider binding: id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM @provider_bindings pb WHERE pb.id=@tok COLLATE Latin1_General_100_BIN2)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'provider binding: repeated id');
        ELSE IF ISJSON(@rest)<>1 OR LEFT(@rest,1)<>N'{'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_CONTRACT_INVALID',N'provider binding: inline-json is not a JSON object');
        ELSE
        BEGIN
          DECLARE @pbc nvarchar(max)=N'',@pbpos int=1,@pbin bit=0,@pbch nchar(1);
          WHILE @pbpos<=LEN(@rest)
          BEGIN
            SET @pbch=SUBSTRING(@rest,@pbpos,1);
            IF @pbin=1
            BEGIN
              SET @pbc+=@pbch;
              IF @pbch=N'\' BEGIN SET @pbpos+=1; SET @pbc+=SUBSTRING(@rest,@pbpos,1); END
              ELSE IF @pbch=N'"' SET @pbin=0;
            END
            ELSE IF @pbch=N'"' BEGIN SET @pbin=1; SET @pbc+=@pbch; END
            ELSE IF @pbch NOT IN (N' ',CHAR(9),CHAR(10),CHAR(13)) SET @pbc+=@pbch;
            SET @pbpos+=1;
          END
          INSERT @provider_bindings(id,content,digest,line_no) VALUES(@tok,@pbc,
            N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@pbc COLLATE Latin1_General_100_BIN2_UTF8))),2)),@i);
        END
      END
    END
    ELSE IF LEFT(@line,9)=N'variants:' OR LEFT(@line,17)=N'outcome-variants:'
    BEGIN
      DECLARE @is_op_var bit=CASE WHEN LEFT(@line,17)=N'outcome-variants:' THEN 1 ELSE 0 END;
      SET @tail=LTRIM(SUBSTRING(@line,CASE WHEN @is_op_var=1 THEN 18 ELSE 10 END,LEN(@line)));
      SET @items=N'["'+REPLACE(REPLACE(STRING_ESCAPE(@tail,'json'),N' ',N''),N',',N'","')+N'"]';
      IF @tail=N''
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'variants: missing trailing value');
      ELSE IF @is_op_var=0 AND @cur_scenario IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'variants: no scenario to attach to');
      ELSE IF @is_op_var=1 AND @last_operation IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'outcome-variants: no operation to attach to');
      ELSE IF EXISTS(SELECT 1 FROM OPENJSON(@items) v
        WHERE v.value NOT LIKE N'[A-Za-z0-9]%:success' AND v.value NOT LIKE N'[A-Za-z0-9]%:failure'
          AND v.value NOT LIKE N'[A-Za-z0-9]%:success:terminal' AND v.value NOT LIKE N'[A-Za-z0-9]%:failure:terminal'
          OR CASE WHEN CHARINDEX(N':',v.value)>1 THEN LEFT(v.value,CHARINDEX(N':',v.value)-1) ELSE N'#' END LIKE N'%[^A-Za-z0-9_-]%')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'variants: expected <variant>:success|failure[:terminal], comma separated');
      ELSE IF @is_op_var=0 AND EXISTS(SELECT 1 FROM OPENJSON(@items) v WHERE v.value LIKE N'%:terminal')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'variants: a scenario variant takes no :terminal; it belongs on outcome-variants, and a scenario that ends the capability takes the terminal flag');
      ELSE IF @is_op_var=0
        INSERT @scenario_variants(scenario_ordinal,variant_id,classification,line_no)
        SELECT @cur_scenario,LEFT(v.value,CHARINDEX(N':',v.value)-1),
          CASE WHEN SUBSTRING(v.value,CHARINDEX(N':',v.value)+1,400) LIKE N'success%' THEN N'success' ELSE N'failure' END,@i
        FROM OPENJSON(@items) v ORDER BY CONVERT(int,v.[key]);
      ELSE
        INSERT @op_variants(operation_ordinal,variant_id,classification,is_terminal,line_no)
        SELECT @last_operation,LEFT(v.value,CHARINDEX(N':',v.value)-1),
          CASE WHEN SUBSTRING(v.value,CHARINDEX(N':',v.value)+1,400) LIKE N'success%' THEN N'success' ELSE N'failure' END,
          CASE WHEN v.value LIKE N'%:terminal' THEN 1 ELSE 0 END,@i
        FROM OPENJSON(@items) v ORDER BY CONVERT(int,v.[key]);
    END
    ELSE IF LEFT(@line,6)=N'recur '
    BEGIN
      -- recur <scenario> while <continue-variant> until <stop-variant> [max <n>]: a bounded recurrence. The
      -- scenario loops on itself while its outcome selects the continue variant and stops on the stop variant.
      SET @tail=LTRIM(SUBSTRING(@line,7,LEN(@line)));
      SET @items=N'["'+REPLACE(STRING_ESCAPE(@tail,'json'),N' ',N'","')+N'"]';
      IF (SELECT COUNT(*) FROM OPENJSON(@items)) NOT IN (5,7)
        OR (SELECT value FROM OPENJSON(@items) WHERE [key]=N'1')<>N'while'
        OR (SELECT value FROM OPENJSON(@items) WHERE [key]=N'3')<>N'until'
        OR ((SELECT COUNT(*) FROM OPENJSON(@items))=7 AND (SELECT value FROM OPENJSON(@items) WHERE [key]=N'5')<>N'max')
        OR EXISTS(SELECT 1 FROM OPENJSON(@items) WHERE value=N'')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'recur: expected "recur <scenario> while <continue-variant> until <stop-variant> [max <n>]"');
      ELSE IF (SELECT COUNT(*) FROM OPENJSON(@items))=7
        AND ISNULL(TRY_CONVERT(int,(SELECT value FROM OPENJSON(@items) WHERE [key]=N'6')),0)<1
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'recur: max must be a positive integer');
      ELSE IF EXISTS(SELECT 1 FROM @recurrences x WHERE x.scenario_id=(SELECT value FROM OPENJSON(@items) WHERE [key]=N'0') COLLATE Latin1_General_100_BIN2)
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'recur: repeated recurrence for one scenario');
      ELSE
        -- The kernel requires a finite maximumIterations; without max it is the largest it admits.
        INSERT @recurrences(scenario_id,continue_variant,stop_variant,max_iterations,line_no)
        SELECT (SELECT value FROM OPENJSON(@items) WHERE [key]=N'0'),(SELECT value FROM OPENJSON(@items) WHERE [key]=N'2'),
          (SELECT value FROM OPENJSON(@items) WHERE [key]=N'4'),
          ISNULL(TRY_CONVERT(int,(SELECT value FROM OPENJSON(@items) WHERE [key]=N'6')),2147483647),@i;
    END
    ELSE IF LEFT(@line,6)=N'route '
    BEGIN
      -- route <from-scenario> <variant> to <to-scenario>: one selection transition.
      SET @tail=LTRIM(SUBSTRING(@line,7,LEN(@line)));
      SET @items=N'["'+REPLACE(STRING_ESCAPE(@tail,'json'),N' ',N'","')+N'"]';
      IF (SELECT COUNT(*) FROM OPENJSON(@items))<>4 OR (SELECT value FROM OPENJSON(@items) WHERE [key]=N'2')<>N'to'
        OR EXISTS(SELECT 1 FROM OPENJSON(@items) WHERE value=N'')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'route: expected "route <from-scenario> <variant> to <to-scenario>"');
      ELSE
        INSERT @routes(from_scenario,variant,to_scenario,line_no)
        SELECT (SELECT value FROM OPENJSON(@items) WHERE [key]=N'0'),(SELECT value FROM OPENJSON(@items) WHERE [key]=N'1'),
          (SELECT value FROM OPENJSON(@items) WHERE [key]=N'3'),@i;
    END
    ELSE IF LEFT(@line,10)=N'cli input '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,11,LEN(@line)));
      IF @tail=N'json' BEGIN SET @cli_input_type=N'json'; SET @cli_input_path=NULL; END
      ELSE IF LEFT(@tail,5)=N'text ' AND LTRIM(SUBSTRING(@tail,6,LEN(@tail)))<>N'' AND CHARINDEX(N' ',LTRIM(SUBSTRING(@tail,6,LEN(@tail))))=0
      BEGIN SET @cli_input_type=N'text'; SET @cli_input_path=LTRIM(SUBSTRING(@tail,6,LEN(@tail))); END
      ELSE INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'cli input: expected "json" or "text <payload-path>"');
    END
    ELSE IF LEFT(@line,12)=N'cli reading '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,13,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0 OR CHARINDEX(N' ',LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail))))>0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'cli reading: expected "<reading> <altitude>[,<altitude>...]"');
      ELSE INSERT @readings(reading,altitudes) VALUES(LEFT(@tail,@sp-1),LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail))));
    END
    ELSE IF LEFT(@line,6)=N'input ' AND @line LIKE N'input % from %'
    BEGIN
      -- input <member> from <scenario-or-operation> <json-path>: a member of the provider's request, taken from the
      -- scenario's request (for the scenario's first operation) or from the result of the operation just before.
      DECLARE @in_items nvarchar(max)=N'["'+REPLACE(STRING_ESCAPE(LTRIM(SUBSTRING(@line,7,LEN(@line))),'json'),N' ',N'","')+N'"]';
      DECLARE @in_member nvarchar(200)=(SELECT value FROM OPENJSON(@in_items) WHERE [key]=N'0'),
        @in_ref nvarchar(400)=(SELECT value FROM OPENJSON(@in_items) WHERE [key]=N'2'),
        @in_path nvarchar(400)=(SELECT value FROM OPENJSON(@in_items) WHERE [key]=N'3');
      IF (SELECT COUNT(*) FROM OPENJSON(@in_items))<>4 OR (SELECT value FROM OPENJSON(@in_items) WHERE [key]=N'1')<>N'from'
        OR EXISTS(SELECT 1 FROM OPENJSON(@in_items) WHERE value=N'')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'input: expected "input <member> from <scenario-or-operation> <json-path>"');
      ELSE IF @cur_provider_op IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'input: no provider operation to attach to');
      ELSE IF @in_member NOT LIKE N'[a-zA-Z_]%' OR @in_member LIKE N'%[^a-zA-Z0-9_]%'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'input: member violates the member rule');
      ELSE IF NOT (@in_path=N'$' OR (LEFT(@in_path,2)=N'$.' AND SUBSTRING(@in_path,3,400) NOT LIKE N'%[^a-zA-Z0-9_.]%' AND @in_path NOT LIKE N'%..%' AND RIGHT(@in_path,1)<>N'.'))
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'input: json path must be $ or $.<member>[.<member>...]');
      ELSE IF EXISTS(SELECT 1 FROM @provider_inputs p WHERE p.op_ordinal=@cur_provider_op AND p.member=@in_member)
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'input: repeated member');
      ELSE
        INSERT @provider_inputs(op_ordinal,member,source_ref,json_path,line_no) VALUES(@cur_provider_op,@in_member,@in_ref,@in_path,@i);
    END
    ELSE IF LEFT(@line,13)=N'outcome from '
    BEGIN
      -- outcome from <operation> <json-path>: the scenario's outcome is that path of the result of the operation just
      -- before it. It compiles to vault, credential and open and a statement that selects the path.
      DECLARE @oc_items nvarchar(max)=N'["'+REPLACE(STRING_ESCAPE(LTRIM(SUBSTRING(@line,14,LEN(@line))),'json'),N' ',N'","')+N'"]';
      DECLARE @oc_ref nvarchar(400)=(SELECT value FROM OPENJSON(@oc_items) WHERE [key]=N'0'),
        @oc_path nvarchar(400)=(SELECT value FROM OPENJSON(@oc_items) WHERE [key]=N'1');
      DECLARE @oc_scenario nvarchar(200)=(SELECT scenario_id FROM @scenarios WHERE ordinal=@cur_scenario);
      DECLARE @oc_base nvarchar(200)=@oc_scenario+N'-outcome';
      IF (SELECT COUNT(*) FROM OPENJSON(@oc_items))<>2 OR EXISTS(SELECT 1 FROM OPENJSON(@oc_items) WHERE value=N'')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'outcome from: expected "outcome from <operation> <json-path>"');
      ELSE IF @cur_scenario IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'outcome from: no scenario to attach to');
      ELSE IF EXISTS(SELECT 1 FROM @scenario_outcomes WHERE scenario_ordinal=@cur_scenario)
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'outcome from: repeated in the scenario');
      ELSE IF NOT (@oc_path=N'$' OR (LEFT(@oc_path,2)=N'$.' AND SUBSTRING(@oc_path,3,400) NOT LIKE N'%[^a-zA-Z0-9_.]%' AND @oc_path NOT LIKE N'%..%' AND RIGHT(@oc_path,1)<>N'.'))
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'outcome from: json path must be $ or $.<member>[.<member>...]');
      ELSE IF EXISTS(SELECT 1 FROM @operations o WHERE o.operation_id IN (@oc_scenario+N'.outcome-vault',@oc_scenario+N'.outcome-credential',@oc_scenario+N'.outcome-open',@oc_scenario+N'.outcome'))
        OR EXISTS(SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=@cur_scenario
          AND b.port_id IN (@oc_base,@oc_base+N'-vault',@oc_base+N'-credential',@oc_base+N'-open'))
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'outcome from: an operation or port it compiles to is already declared');
      ELSE
      BEGIN
            IF @cur_binding IS NOT NULL
            BEGIN
              IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'statement'
                AND (b.platform_id IS NULL OR b.provider_id IS NULL OR b.statement IS NULL OR b.result_column IS NULL))
                INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'bind: missing one of its four keys');
              IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'platform'
                AND (b.platform_id IS NULL OR (b.provider_id IS NULL AND b.config_json IS NULL)))
                INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'platform bind: missing platform, config or provider');
              SET @cur_binding=NULL;
            END
        SET @cur_provider_op=NULL;
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome-vault',N'invoke-port',@oc_base+N'-vault',@i);
        DECLARE @oc_first int=SCOPE_IDENTITY();
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome-credential',N'invoke-port',@oc_base+N'-credential',@i);
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome-open',N'invoke-port',@oc_base+N'-open',@i);
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome',N'invoke-port',@oc_base,@i);
        SET @last_operation=SCOPE_IDENTITY();
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base+N'-vault',N'platform',N'sfx-vault-host-read-port.v1',N'{"providerId":"sfx-vault-file-host","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-file"}}',@i,@i);
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base+N'-credential',N'platform',N'sfx-estate-credential-port.v1',N'{"providerId":"sfx-estate-database-credential","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}',@i,@i);
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base+N'-open',N'platform',N'sfx-vault-reference-open-port.v1',N'{"providerId":"sfx-vault-secret-service-reference","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-secret-service"}}',@i,@i);
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base,N'platform',N'sfx-estate-run-statement-port.v1',NULL,@i,@i);
        INSERT @scenario_outcomes(scenario_ordinal,source_ref,json_path,first_ordinal,op_ordinal,stmt_binding,line_no)
          VALUES(@cur_scenario,@oc_ref,@oc_path,@oc_first,@last_operation,SCOPE_IDENTITY(),@i);
      END
    END
    ELSE IF LEFT(@line,8)=N'feature '
    BEGIN
      -- feature <capability-id> sha256:<hex>: the source implements the feature whose bytes are retained under that
      -- digest. The compiler reads exactly those bytes, never a binding, and refuses a source that drifts from them.
      DECLARE @ft_items nvarchar(max)=N'["'+REPLACE(STRING_ESCAPE(LTRIM(SUBSTRING(@line,9,LEN(@line))),'json'),N' ',N'","')+N'"]';
      DECLARE @ft_cap nvarchar(400)=(SELECT value FROM OPENJSON(@ft_items) WHERE [key]=N'0'),
        @ft_digest nvarchar(400)=(SELECT value FROM OPENJSON(@ft_items) WHERE [key]=N'1');
      IF (SELECT COUNT(*) FROM OPENJSON(@ft_items))<>2 OR LEFT(ISNULL(@ft_digest,N''),7)<>N'sha256:'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'feature: expected "feature <capability-id> sha256:<hex>"');
      ELSE IF @feature_line IS NOT NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'feature: repeated feature line');
      ELSE IF LEN(@ft_digest)<>71 OR SUBSTRING(@ft_digest,8,64) COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9a-f]%'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'feature: the digest is sha256: and 64 lowercase hex digits');
      ELSE
        SELECT @feature_cap=@ft_cap,@feature_hex=SUBSTRING(@ft_digest,8,64),@feature_line=@i;
    END
    ELSE
      INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'line does not match any construct form');
  END
  IF @cur_binding IS NOT NULL
  BEGIN
    IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'statement'
      AND (b.platform_id IS NULL OR b.provider_id IS NULL OR b.statement IS NULL OR b.result_column IS NULL))
      INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'bind: missing one of its four keys');
    IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'platform'
      AND (b.platform_id IS NULL OR (b.provider_id IS NULL AND b.config_json IS NULL)))
      INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'platform bind: missing platform, config or provider');
  END
  -- A configuration names a provider binding as "@provider-binding:<id>" and receives its digest. A name that no provider
  -- binding line declares refuses.
  DECLARE @pbi int=(SELECT MIN(ordinal) FROM @provider_bindings);
  WHILE @pbi IS NOT NULL
  BEGIN
    UPDATE b SET config_json=REPLACE(b.config_json,N'"@provider-binding:'+pb.id COLLATE DATABASE_DEFAULT+N'"',N'"'+pb.digest COLLATE DATABASE_DEFAULT+N'"')
    FROM @bindings b CROSS JOIN @provider_bindings pb WHERE pb.ordinal=@pbi AND b.config_json IS NOT NULL;
    SET @pbi=(SELECT MIN(ordinal) FROM @provider_bindings WHERE ordinal>@pbi);
  END
  INSERT @errors(line_no,code,message)
  SELECT b.config_line,N'DSL_VALUE_INVALID',N'config: names a provider binding that no provider binding line declares'
  FROM @bindings b WHERE b.config_json LIKE N'%"@provider-binding:%';
  -- The feature the source pins: its retained bytes are what the source is checked against.
  IF @feature_line IS NOT NULL
  BEGIN
    IF @capability_id IS NOT NULL AND @feature_cap<>@capability_id COLLATE Latin1_General_100_BIN2
      INSERT @errors(line_no,code,message) VALUES(@feature_line,N'DSL_VALUE_INVALID',N'feature: names another capability than the capability line');
    SELECT @feature_text=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
    FROM source.content_object co
    WHERE co.content_digest=CONVERT(binary(32),@feature_hex,2) AND HASHBYTES('SHA2_256',co.content_bytes)=co.content_digest;
    IF @feature_text IS NULL
      INSERT @errors(line_no,code,message) VALUES(@feature_line,N'DSL_FEATURE_NOT_RETAINED',N'feature: no bytes are retained under sha256:'+@feature_hex);
  END
  -- A provider operation names a capability of the selected estate exactly, and dispatches to its root scenario.
  UPDATE p SET provider_scenario=(SELECT TOP (1) s.scenario_id FROM model.estate_capability ec
      JOIN model.capability c ON c.capability_pk=ec.capability_pk
      JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
      JOIN model.capability_root_scenario r ON r.capability_version_pk=ec.capability_version_pk
      JOIN model.scenario s ON s.scenario_pk=r.scenario_pk
      WHERE ec.estate_model_pk=@estate AND c.capability_id COLLATE Latin1_General_100_BIN2=p.provider_id)
  FROM @provider_ops p;
  INSERT @errors(line_no,code,message)
  SELECT p.line_no,N'DSL_PROVIDER_UNKNOWN',N'operation: provider capability not declared in the selected estate: '+p.provider_id
  FROM @provider_ops p WHERE p.provider_scenario IS NULL;
  -- Lineage follows the declared operation order: a request member comes from the scenario's request when its operation is
  -- the scenario's first, or from the operation just before it. A provider operation's result lands at result.
  UPDATE i SET carrier_path=CASE
      WHEN prev.ordinal IS NULL AND i.source_ref=sc.scenario_id THEN i.json_path
      WHEN prev.operation_id=i.source_ref AND pp.op_ordinal IS NOT NULL THEN N'$.result'+SUBSTRING(i.json_path,2,400)
      WHEN prev.operation_id=i.source_ref AND so.scenario_ordinal IS NULL THEN i.json_path END
  FROM @provider_inputs i JOIN @provider_ops po ON po.op_ordinal=i.op_ordinal
  JOIN @operations o ON o.ordinal=po.op_ordinal JOIN @scenarios sc ON sc.ordinal=o.scenario_ordinal
  OUTER APPLY (SELECT TOP (1) o2.ordinal,o2.operation_id FROM @operations o2
    WHERE o2.scenario_ordinal=o.scenario_ordinal AND o2.ordinal<po.prefix_ordinal ORDER BY o2.ordinal DESC) prev
  LEFT JOIN @provider_ops pp ON pp.op_ordinal=prev.ordinal
  LEFT JOIN @scenario_outcomes so ON so.op_ordinal=prev.ordinal;
  INSERT @errors(line_no,code,message)
  SELECT i.line_no,N'DSL_VALUE_INVALID',N'input: '+i.source_ref+N' does not lead to this operation; name the scenario for its first operation, or the operation just before it'
  FROM @provider_inputs i WHERE i.carrier_path IS NULL;
  INSERT @errors(line_no,code,message)
  SELECT i.line_no,N'DSL_DUPLICATE_ID',N'input: member '+i.member+N' is also a config member'
  FROM @provider_inputs i JOIN @provider_ops p ON p.op_ordinal=i.op_ordinal
  WHERE p.config_json IS NOT NULL AND EXISTS(SELECT 1 FROM OPENJSON(p.config_json) j WHERE j.[key]=i.member COLLATE Latin1_General_100_BIN2);
  UPDATE so SET carrier_path=CASE
      WHEN prev.operation_id=so.source_ref AND pp.op_ordinal IS NOT NULL THEN N'$.result'+SUBSTRING(so.json_path,2,400)
      WHEN prev.operation_id=so.source_ref THEN so.json_path END
  FROM @scenario_outcomes so
  OUTER APPLY (SELECT TOP (1) o2.ordinal,o2.operation_id FROM @operations o2
    WHERE o2.scenario_ordinal=so.scenario_ordinal AND o2.ordinal<so.first_ordinal ORDER BY o2.ordinal DESC) prev
  LEFT JOIN @provider_ops pp ON pp.op_ordinal=prev.ordinal;
  INSERT @errors(line_no,code,message)
  SELECT so.line_no,N'DSL_VALUE_INVALID',N'outcome from: '+so.source_ref+N' is not the operation just before it'
  FROM @scenario_outcomes so WHERE so.carrier_path IS NULL;
  INSERT @errors(line_no,code,message)
  SELECT so.line_no,N'DSL_VALUE_INVALID',N'outcome from: operations follow it in the scenario'
  FROM @scenario_outcomes so WHERE EXISTS(SELECT 1 FROM @operations o WHERE o.scenario_ordinal=so.scenario_ordinal AND o.ordinal>so.op_ordinal);
  IF @capability_id IS NULL
    INSERT @errors(line_no,code,message) VALUES(0,N'DSL_REQUIRED_MISSING',N'no capability line');
  IF NOT EXISTS(SELECT 1 FROM @scenarios)
    INSERT @errors(line_no,code,message) VALUES(0,N'DSL_REQUIRED_MISSING',N'no scenario declared');
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast') AND NOT EXISTS(SELECT 1 FROM @topology WHERE form=N'join')
    INSERT @errors(line_no,code,message) VALUES((SELECT MIN(line_no) FROM @topology WHERE form=N'broadcast'),N'DSL_REQUIRED_MISSING',N'broadcast without join: the fan-out has no convergence scenario');
  -- A join converges the legs of the capability's broadcast; with no broadcast it would declare nothing, so it refuses.
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'join') AND NOT EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast')
    INSERT @errors(line_no,code,message) VALUES((SELECT MIN(line_no) FROM @topology WHERE form=N'join'),N'DSL_REQUIRED_MISSING',N'join without broadcast: a join converges the legs of a broadcast, and none is declared');
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast')
  BEGIN
    INSERT @errors(line_no,code,message)
    SELECT t.line_no,N'DSL_VALUE_INVALID',N'broadcast: scenario is not declared: '+LTRIM(RTRIM(s.value))
    FROM @topology t CROSS APPLY STRING_SPLIT(t.root_id+N','+t.legs,N',') s
    WHERE t.form=N'broadcast' AND NOT EXISTS(SELECT 1 FROM @scenarios sc WHERE sc.scenario_id=LTRIM(RTRIM(s.value)) COLLATE Latin1_General_100_BIN2);
  END
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'join')
  BEGIN
    INSERT @errors(line_no,code,message)
    SELECT t.line_no,N'DSL_VALUE_INVALID',N'join: scenario is not declared: '+LTRIM(RTRIM(s.value))
    FROM @topology t CROSS APPLY STRING_SPLIT(t.join_id+N','+t.legs,N',') s
    WHERE t.form=N'join' AND NOT EXISTS(SELECT 1 FROM @scenarios sc WHERE sc.scenario_id=LTRIM(RTRIM(s.value)) COLLATE Latin1_General_100_BIN2);
  END
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast') AND EXISTS(SELECT 1 FROM @topology WHERE form=N'join')
  BEGIN
    IF EXISTS(
      SELECT LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 AS leg FROM @topology t CROSS APPLY STRING_SPLIT(t.legs,N',') l WHERE t.form=N'broadcast'
      EXCEPT
      SELECT LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 FROM @topology t CROSS APPLY STRING_SPLIT(t.legs,N',') l WHERE t.form=N'join')
    OR EXISTS(
      SELECT LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 AS leg FROM @topology t CROSS APPLY STRING_SPLIT(t.legs,N',') l WHERE t.form=N'join'
      EXCEPT
      SELECT LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 FROM @topology t CROSS APPLY STRING_SPLIT(t.legs,N',') l WHERE t.form=N'broadcast')
      INSERT @errors(line_no,code,message) VALUES((SELECT MIN(line_no) FROM @topology),N'DSL_VALUE_INVALID',N'broadcast and join disagree on the leg set');
  END
  -- Edge contract preflight: the kernel refuses an edge whose adjacent endpoint
  -- contracts differ when kind <> return and no binding authority is declared
  -- (SemanticExecutionGraphCompiler.cs:929 and its five sibling implementations).
  -- The DSL construct emits no binding authority, so a fan-out document whose
  -- input and output contract ids differ refuses HERE with the kernel's code,
  -- naming every declared edge and both contract ids.
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast') AND @input_id IS NOT NULL AND @output_id IS NOT NULL
    AND @output_id COLLATE Latin1_General_100_BIN2 <> @input_id COLLATE Latin1_General_100_BIN2
  BEGIN
    INSERT @errors(line_no,code,message)
    SELECT t.line_no,N'EDGE_CONTRACT_MISMATCH',
      N'Edge edge:'+f.edge+N': outcome contract '+@output_id+N' != input contract '+@input_id+N'. Different endpoint contracts require binding authority; the DSL construct declares none, so both contract lines must share one contract id.'
    FROM @topology t
    CROSS APPLY (SELECT LTRIM(RTRIM(l.value)) AS leg FROM STRING_SPLIT(t.legs,N',') l) x
    CROSS APPLY (VALUES
      (N'enter-'+(CASE WHEN x.leg LIKE @capability_id+N'-%' THEN SUBSTRING(x.leg,LEN(@capability_id)+2,400) ELSE x.leg END)),
      (N'settle-'+(CASE WHEN x.leg LIKE @capability_id+N'-%' THEN SUBSTRING(x.leg,LEN(@capability_id)+2,400) ELSE x.leg END)),
      (N'fail-'+(CASE WHEN x.leg LIKE @capability_id+N'-%' THEN SUBSTRING(x.leg,LEN(@capability_id)+2,400) ELSE x.leg END))) f(edge)
    WHERE t.form=N'broadcast';
  END
  IF @input_id IS NULL OR @output_id IS NULL
    INSERT @errors(line_no,code,message) VALUES(0,N'DSL_REQUIRED_MISSING',N'a scenario without input or output contract declared');
  IF EXISTS(SELECT 1 FROM @operations o WHERE o.kind IN (N'invoke-port',N'for-each') AND NOT EXISTS(
      SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=o.scenario_ordinal AND b.port_id=o.port_id COLLATE Latin1_General_100_BIN2))
    INSERT @errors(line_no,code,message)
    SELECT MIN(o.line_no),N'DSL_REQUIRED_MISSING',N'operation without a matching bind port' FROM @operations o
    WHERE o.kind IN (N'invoke-port',N'for-each') AND NOT EXISTS(SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=o.scenario_ordinal AND b.port_id=o.port_id COLLATE Latin1_General_100_BIN2);
  -- Scenario contracts, routes and route variants resolve inside the document; a
  -- selection edge whose endpoint contracts differ is the kernel's EDGE_CONTRACT_MISMATCH.
  INSERT @errors(line_no,code,message)
  SELECT e.line_no,N'DSL_DUPLICATE_ID',N'contract: repeated contract id' FROM @extra_contracts e
  WHERE e.contract_id=@input_id COLLATE Latin1_General_100_BIN2 OR e.contract_id=@output_id COLLATE Latin1_General_100_BIN2;
  INSERT @errors(line_no,code,message)
  SELECT s.line_no,N'DSL_VALUE_INVALID',N'scenario: contract not declared in the document: '+x.c
  FROM @scenarios s CROSS APPLY (VALUES(s.input_contract),(s.output_contract)) x(c)
  WHERE x.c IS NOT NULL AND x.c<>ISNULL(@input_id,N'') AND x.c<>ISNULL(@output_id,N'')
    AND NOT EXISTS(SELECT 1 FROM @extra_contracts e WHERE e.contract_id=x.c COLLATE Latin1_General_100_BIN2);
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'DSL_VALUE_INVALID',N'route: scenario is not declared: '+x.sid
  FROM @routes r CROSS APPLY (VALUES(r.from_scenario),(r.to_scenario)) x(sid)
  WHERE NOT EXISTS(SELECT 1 FROM @scenarios s WHERE s.scenario_id=x.sid COLLATE Latin1_General_100_BIN2);
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'UNDECLARED_BRANCH_VARIANT',N'route: variant '+r.variant+N' is not declared on scenario '+r.from_scenario
  FROM @routes r JOIN @scenarios f ON f.scenario_id=r.from_scenario
  WHERE NOT EXISTS(SELECT 1 FROM @scenario_variants v WHERE v.scenario_ordinal=f.ordinal AND v.variant_id=r.variant);
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'EDGE_CONTRACT_MISMATCH',N'route '+r.from_scenario+N' '+r.variant+N': outcome contract '+c.fo+N' != input contract '+c.ti
  FROM @routes r JOIN @scenarios f ON f.scenario_id=r.from_scenario JOIN @scenarios t ON t.scenario_id=r.to_scenario
  CROSS APPLY (SELECT COALESCE(f.output_contract,@output_id) fo,COALESCE(t.input_contract,@input_id) ti) c
  WHERE c.fo<>c.ti COLLATE Latin1_General_100_BIN2;
  -- One capability is one entry: its CLI interface addresses its one root scenario, so a second root refuses.
  INSERT @errors(line_no,code,message)
  SELECT s.line_no,N'DSL_DUPLICATE_ID',N'scenario: a second root scenario; each independently invocable entry is its own capability'
  FROM @scenarios s WHERE s.root=1 AND s.ordinal>(SELECT MIN(x.ordinal) FROM @scenarios x WHERE x.root=1);
  -- An invoke-scenario operation names a scenario of this document.
  INSERT @errors(line_no,code,message)
  SELECT o.line_no,N'DSL_VALUE_INVALID',N'operation: scenario is not declared: '+o.target_scenario
  FROM @operations o WHERE o.kind=N'invoke-scenario'
    AND NOT EXISTS(SELECT 1 FROM @scenarios s WHERE s.scenario_id=o.target_scenario COLLATE Latin1_General_100_BIN2);
  -- Routes and invoke-scenario operations may not form a cycle, a route back to its own scenario included: the declared
  -- loop is a recur line, which carries its bound.
  DECLARE @edges TABLE(from_s nvarchar(200) COLLATE Latin1_General_100_BIN2,to_s nvarchar(200) COLLATE Latin1_General_100_BIN2,line_no int);
  INSERT @edges(from_s,to_s,line_no) SELECT r.from_scenario,r.to_scenario,r.line_no FROM @routes r;
  INSERT @edges(from_s,to_s,line_no) SELECT s.scenario_id,o.target_scenario,o.line_no
  FROM @operations o JOIN @scenarios s ON s.ordinal=o.scenario_ordinal WHERE o.kind=N'invoke-scenario';
  DECLARE @reach TABLE(origin nvarchar(200) COLLATE Latin1_General_100_BIN2,node nvarchar(200) COLLATE Latin1_General_100_BIN2,PRIMARY KEY(origin,node));
  DECLARE @reach_added int;
  INSERT @reach(origin,node) SELECT DISTINCT from_s,to_s FROM @edges;
  SET @reach_added=@@ROWCOUNT;
  WHILE @reach_added>0
  BEGIN
    INSERT @reach(origin,node) SELECT DISTINCT x.origin,e.to_s FROM @reach x JOIN @edges e ON e.from_s=x.node
    WHERE NOT EXISTS(SELECT 1 FROM @reach y WHERE y.origin=x.origin AND y.node=e.to_s);
    SET @reach_added=@@ROWCOUNT;
  END
  INSERT @errors(line_no,code,message)
  SELECT MIN(e.line_no),N'DSL_VALUE_INVALID',N'routes or invoke-scenario operations form a cycle through '+e.from_s+N': a loop is declared with recur, which carries its bound'
  FROM @edges e
  WHERE e.to_s=e.from_s OR EXISTS(SELECT 1 FROM @reach x WHERE x.origin=e.to_s AND x.node=e.from_s)
  GROUP BY e.from_s;
  -- A recurrence loops a declared scenario on itself: both variants are declared on it, and its outcome
  -- contract equals its input contract, because the recurrence edge joins the two.
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'DSL_VALUE_INVALID',N'recur: scenario is not declared: '+r.scenario_id FROM @recurrences r
  WHERE NOT EXISTS(SELECT 1 FROM @scenarios s WHERE s.scenario_id=r.scenario_id);
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'UNDECLARED_BRANCH_VARIANT',N'recur: variant '+v.variant+N' is not declared on scenario '+r.scenario_id
  FROM @recurrences r CROSS APPLY (VALUES(r.continue_variant),(r.stop_variant)) v(variant)
  JOIN @scenarios s ON s.scenario_id=r.scenario_id
  WHERE NOT EXISTS(SELECT 1 FROM @scenario_variants sv WHERE sv.scenario_ordinal=s.ordinal AND sv.variant_id=v.variant COLLATE Latin1_General_100_BIN2);
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'EDGE_CONTRACT_MISMATCH',N'recur '+r.scenario_id+N': outcome contract '+c.fo+N' != input contract '+c.ti
  FROM @recurrences r JOIN @scenarios s ON s.scenario_id=r.scenario_id
  CROSS APPLY (SELECT COALESCE(s.output_contract,@output_id) fo,COALESCE(s.input_contract,@input_id) ti) c
  WHERE c.fo<>c.ti COLLATE Latin1_General_100_BIN2;
  DECLARE @known_platform TABLE(id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
  DECLARE @known_provider TABLE(id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
  INSERT @known_platform(id)
  SELECT MIN(x.id) FROM (
    SELECT so.declared_id AS id FROM model.estate_definition ed
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
    JOIN model.semantic_object so ON so.semantic_object_pk=d.semantic_object_pk
    JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
    WHERE ed.estate_model_pk=@estate AND n.namespace_id=N'sidefx:platform-capabilities' AND so.object_kind=N'CAPABILITY'
    UNION ALL
    SELECT JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),N'$.semantics.platformCapabilityId')
    FROM model.estate_definition ed
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
    JOIN model.semantic_object so ON so.semantic_object_pk=d.semantic_object_pk
    JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
    JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    WHERE ed.estate_model_pk=@estate AND n.namespace_id LIKE N'sidefx:capability:%' AND so.object_kind=N'PORT'
  ) x WHERE x.id IS NOT NULL GROUP BY x.id COLLATE Latin1_General_100_BIN2;
  INSERT @known_provider(id)
  SELECT MIN(x.id) FROM (
    SELECT so.declared_id AS id FROM model.estate_definition ed
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
    JOIN model.semantic_object so ON so.semantic_object_pk=d.semantic_object_pk
    JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
    WHERE ed.estate_model_pk=@estate AND n.namespace_id=N'sidefx:providers' AND so.object_kind=N'PROVIDER'
    UNION ALL
    SELECT JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),N'$.semantics.configuration.providerId')
    FROM model.estate_definition ed
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
    JOIN model.semantic_object so ON so.semantic_object_pk=d.semantic_object_pk
    JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
    JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    WHERE ed.estate_model_pk=@estate AND n.namespace_id LIKE N'sidefx:capability:%' AND so.object_kind=N'PORT'
  ) x WHERE x.id IS NOT NULL GROUP BY x.id COLLATE Latin1_General_100_BIN2;
  INSERT @errors(line_no,code,message)
  SELECT b.platform_line,N'DSL_PROVIDER_UNKNOWN',N'platform not declared in the estate: '+b.platform_id
  FROM @bindings b WHERE b.platform_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM @known_platform k WHERE k.id=b.platform_id COLLATE Latin1_General_100_BIN2);
  INSERT @errors(line_no,code,message)
  SELECT b.provider_line,N'DSL_PROVIDER_UNKNOWN',N'provider not declared in the estate: '+b.provider_id
  FROM @bindings b WHERE b.provider_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM @known_provider k WHERE k.id=b.provider_id COLLATE Latin1_General_100_BIN2);
  DECLARE @status nvarchar(20),@document nvarchar(max)=NULL,@document_digest varchar(71)=NULL,@diagnostics nvarchar(max)=NULL;
  IF EXISTS(SELECT 1 FROM @errors)
  BEGIN
    SET @status=N'REFUSED';
    SET @diagnostics=(SELECT e.code,e.line_no AS line,e.message FROM @errors e ORDER BY CASE WHEN e.line_no=0 THEN 1 ELSE 0 END,e.line_no,e.seq FOR JSON PATH);
  END
  ELSE
  BEGIN
    SET @status=N'COMPILED';
    -- Each provider operation's composing statement builds the dispatch the generic invocation reads: the provider, its
    -- root scenario and its request, the config: members as written and each input member from its path. Both statements
    -- carry the command timeout the run-statement port requires (DECLARED_PROVIDER_CONFIGURATION_VALUE_MISSING without it),
    -- 30 seconds as the estate's own composing statements declare it.
    UPDATE b SET config_json=JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(N'{"providerId":"sfx-estate-database-run-statement","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}',N'$.statement',
        N'DECLARE @r nvarchar(max)=N'''+REPLACE(ISNULL(p.config_json,N'{}'),N'''',N'''''')+N''';'
        +ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max),N' SET @r=CASE WHEN JSON_QUERY(@input,N'''+i.carrier_path+N''') IS NOT NULL THEN JSON_MODIFY(@r,N''$."'
          +i.member COLLATE DATABASE_DEFAULT+N'"'',JSON_QUERY(@input,N'''+i.carrier_path+N''')) ELSE JSON_MODIFY(@r,N''$."'+i.member COLLATE DATABASE_DEFAULT
          +N'"'',JSON_VALUE(@input,N'''+i.carrier_path+N''')) END;'),N'') WITHIN GROUP (ORDER BY i.ordinal) FROM @provider_inputs i WHERE i.op_ordinal=p.op_ordinal),N'')
        +N' SELECT (SELECT N'''+p.provider_id COLLATE DATABASE_DEFAULT+N''' AS executionTarget,N''sidefx:capabilities'' AS executionNamespace,N'''
        +p.provider_scenario+N''' AS executionScenario,N''json'' AS inputType,JSON_QUERY(@r) AS dispatchRequest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;'),
      N'$.resultColumn',N'value'),N'$.commandTimeout',30)
    FROM @bindings b JOIN @provider_ops p ON p.compose_binding=b.ordinal;
    UPDATE b SET config_json=JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(N'{"providerId":"sfx-estate-database-run-statement","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}',N'$.statement',
        N'SELECT JSON_QUERY(@input,N'''+so.carrier_path+N''') AS value;'),N'$.resultColumn',N'value'),N'$.commandTimeout',30)
    FROM @bindings b JOIN @scenario_outcomes so ON so.stmt_binding=b.ordinal;
    UPDATE o SET variants_json=(SELECT STRING_AGG(CONVERT(nvarchar(max),N'{"variantId":"'+ov.variant_id COLLATE DATABASE_DEFAULT+N'","classification":"'+ov.classification+N'"'
        +CASE WHEN ov.is_terminal=1 THEN N',"terminal":true' ELSE N'' END+N'}'),N',') WITHIN GROUP (ORDER BY ov.ordinal)
      FROM @op_variants ov WHERE ov.operation_ordinal=o.ordinal)
    FROM @operations o;
    DECLARE @in_schema nvarchar(max)=N'',@out_schema nvarchar(max)=N'';
    DECLARE @cpos int=1,@cin bit=0,@cc nchar(1);
    WHILE @cpos<=LEN(@input_schema)
    BEGIN
      SET @cc=SUBSTRING(@input_schema,@cpos,1);
      IF @cin=1
      BEGIN
        SET @in_schema+=@cc;
        IF @cc=N'\' BEGIN SET @cpos+=1; SET @in_schema+=SUBSTRING(@input_schema,@cpos,1); END
        ELSE IF @cc=N'"' SET @cin=0;
      END
      ELSE IF @cc=N'"' BEGIN SET @cin=1; SET @in_schema+=@cc; END
      ELSE IF @cc NOT IN (N' ',CHAR(9),CHAR(10),CHAR(13)) SET @in_schema+=@cc;
      SET @cpos+=1;
    END
    SET @cpos=1; SET @cin=0;
    WHILE @cpos<=LEN(@output_schema)
    BEGIN
      SET @cc=SUBSTRING(@output_schema,@cpos,1);
      IF @cin=1
      BEGIN
        SET @out_schema+=@cc;
        IF @cc=N'\' BEGIN SET @cpos+=1; SET @out_schema+=SUBSTRING(@output_schema,@cpos,1); END
        ELSE IF @cc=N'"' SET @cin=0;
      END
      ELSE IF @cc=N'"' BEGIN SET @cin=1; SET @out_schema+=@cc; END
      ELSE IF @cc NOT IN (N' ',CHAR(9),CHAR(10),CHAR(13)) SET @out_schema+=@cc;
      SET @cpos+=1;
    END
    SET @document=N'{"document":"sidefx-capability-authority.v1","capabilityId":"'+@capability_id+N'"';
    IF @feature_line IS NOT NULL
      SET @document+=N',"feature":{"capabilityId":"'+@feature_cap+N'","digest":"sha256:'+@feature_hex+N'"}';
    IF @intent IS NOT NULL OR @outcome IS NOT NULL
      SET @document+=N',"meaning":{'+CASE WHEN @intent IS NOT NULL THEN N'"intent":"'+REPLACE(REPLACE(@intent,N'\',N'\\'),N'"',N'\"')+N'"' ELSE N'' END
        +CASE WHEN @intent IS NOT NULL AND @outcome IS NOT NULL THEN N',' ELSE N'' END
        +CASE WHEN @outcome IS NOT NULL THEN N'"outcome":"'+REPLACE(REPLACE(@outcome,N'\',N'\\'),N'"',N'\"')+N'"' ELSE N'' END+N'}';
    SET @document+=N',"cli":{"input":{"type":"'+@cli_input_type+N'","contract":"'+@input_id+N'"'
      +CASE WHEN @cli_input_path IS NOT NULL THEN N',"path":"'+@cli_input_path+N'"' ELSE N'' END+N'}'
      +CASE WHEN @display_select IS NOT NULL THEN N',"display":{"select":"'+@display_select+N'","as":"'+@display_format+N'"}' ELSE N'' END
      +COALESCE(N',"readings":['+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'{"reading":"'+r.reading+N'","altitudes":["'+REPLACE(r.altitudes,N',',N'","')+N'"]}'),N',') WITHIN GROUP (ORDER BY r.ordinal) FROM @readings r)+N']',N'')+N'}';
    SET @document+=N',"contracts":[{"id":"'+@input_id+N'","schema":'+@in_schema+N'}'+CASE WHEN @output_id<>@input_id THEN N',{"id":"'+@output_id+N'","schema":'+@out_schema+N'}' ELSE N'' END
      +COALESCE((SELECT STRING_AGG(CONVERT(nvarchar(max),N',{"id":"'+e.contract_id COLLATE DATABASE_DEFAULT+N'","schema":'+e.schema_json+N'}'),N'') WITHIN GROUP (ORDER BY e.ordinal) FROM @extra_contracts e),N'')+N']';
    SET @document+=N',"scenarios":[';
    DECLARE @si int=0,@sc int=(SELECT COUNT(*) FROM @scenarios);
    WHILE @si<@sc
    BEGIN
      SET @si+=1;
      DECLARE @s nvarchar(max)=N'';
      SET @rest=(SELECT scenario_id FROM @scenarios WHERE ordinal=@si);
      SET @s+=N'{"scenarioId":"'+@rest+N'","name":"'+UPPER(LEFT(REPLACE(@rest,N'-',N' '),1))+SUBSTRING(REPLACE(@rest,N'-',N' '),2,LEN(@rest))+N'"'
        +N',"inputId":"'+@rest+N'-request","inputContract":"'+COALESCE((SELECT input_contract FROM @scenarios WHERE ordinal=@si),@input_id)+N'"'
        -- The root scenario's execution authority is the capability's; every other scenario has its own.
        +N',"eventId":"'+@rest+N'-requested","eventAuthority":"'+CASE WHEN (SELECT root FROM @scenarios WHERE ordinal=@si)=1 THEN @capability_id ELSE @rest END+N'.v1"'
        -- The outcome identity is distinct from its scenario, and so from the capability the root scenario is named after.
        +N',"outcomeId":"'+@rest+N'-outcome","outcomeContract":"'+COALESCE((SELECT output_contract FROM @scenarios WHERE ordinal=@si),@output_id)+N'"'
        +N',"root":'+CASE WHEN (SELECT root FROM @scenarios WHERE ordinal=@si)=1 THEN N'true' ELSE N'false' END
        +N',"terminal":'+CASE WHEN (SELECT terminal FROM @scenarios WHERE ordinal=@si)=1 THEN N'true' ELSE N'false' END;
      IF EXISTS(SELECT 1 FROM @scenario_variants WHERE scenario_ordinal=@si)
        SET @s+=N',"variants":['+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'{"variantId":"'+v.variant_id COLLATE DATABASE_DEFAULT+N'","classification":"'+v.classification+N'"}'),N',') WITHIN GROUP (ORDER BY v.ordinal)
          FROM @scenario_variants v WHERE v.scenario_ordinal=@si)+N']';
      IF (SELECT given_txt FROM @scenarios WHERE ordinal=@si) IS NOT NULL
        SET @s+=N',"given":"'+REPLACE(REPLACE((SELECT given_txt FROM @scenarios WHERE ordinal=@si),N'\',N'\\'),N'"',N'\"')+N'"';
      IF (SELECT when_txt FROM @scenarios WHERE ordinal=@si) IS NOT NULL
        SET @s+=N',"when":"'+REPLACE(REPLACE((SELECT when_txt FROM @scenarios WHERE ordinal=@si),N'\',N'\\'),N'"',N'\"')+N'"';
      IF (SELECT then_txt FROM @scenarios WHERE ordinal=@si) IS NOT NULL
        SET @s+=N',"then":"'+REPLACE(REPLACE((SELECT then_txt FROM @scenarios WHERE ordinal=@si),N'\',N'\\'),N'"',N'\"')+N'"';
      SET @s+=N',"operations":['+COALESCE((SELECT STRING_AGG(CONVERT(nvarchar(max),CASE WHEN o.kind=N'for-each'
            -- A for-each operation hands its body provider the operation itself as configuration, so the
            -- body port's configuration members are carried on the operation beside the fold members.
            THEN JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(
                CASE WHEN o.variants_json IS NULL THEN ISNULL(fb.cfg,N'{}')
                  ELSE JSON_MODIFY(ISNULL(fb.cfg,N'{}'),N'$.outcomeVariants',JSON_QUERY(N'['+o.variants_json+N']')) END,
                N'$.operationId',o.operation_id COLLATE DATABASE_DEFAULT),N'$.kind',N'for-each'),N'$.portId',o.port_id COLLATE DATABASE_DEFAULT),
                N'$.bodyCapabilityId',fb.platform_id),N'$.collectionValuePath',o.collection_path),N'$.maximumIterations',o.max_iterations) COLLATE DATABASE_DEFAULT
            ELSE N'{"operationId":"'+o.operation_id COLLATE DATABASE_DEFAULT
          +CASE WHEN o.kind=N'invoke-scenario' THEN N'","kind":"invoke-scenario","scenarioId":"'+o.target_scenario ELSE N'","kind":"invoke-port","portId":"'+o.port_id COLLATE DATABASE_DEFAULT END
          +N'"'+COALESCE(N',"outcomeVariants":['+o.variants_json+N']',N'')+ISNULL(px.extra,N'')+N'}' END),N',') WITHIN GROUP (ORDER BY o.ordinal)
        FROM @operations o
        OUTER APPLY (SELECT N',"providerCapabilityId":"'+p.provider_id COLLATE DATABASE_DEFAULT+N'"'
            +COALESCE(N',"inputs":['+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'{"member":"'+i.member COLLATE DATABASE_DEFAULT+N'","from":"'
              +i.source_ref COLLATE DATABASE_DEFAULT+N'","path":"'+i.json_path+N'"}'),N',') WITHIN GROUP (ORDER BY i.ordinal)
              FROM @provider_inputs i WHERE i.op_ordinal=p.op_ordinal)+N']',N'') AS extra
          FROM @provider_ops p WHERE p.op_ordinal=o.ordinal) px
        OUTER APPLY (SELECT TOP (1) b.platform_id,CASE WHEN b.form=N'statement'
            THEN (SELECT b.statement AS [statement],b.result_column AS resultColumn,b.provider_id AS providerId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
            ELSE b.config_json END AS cfg
          FROM @bindings b WHERE b.scenario_ordinal=o.scenario_ordinal AND b.port_id=o.port_id COLLATE Latin1_General_100_BIN2 ORDER BY b.ordinal) fb
        WHERE o.scenario_ordinal=@si),N'')+N']';
      SET @s+=N',"portBindings":['+COALESCE((SELECT STRING_AGG(
          CASE WHEN b.form=N'statement'
            THEN N'{"portId":"'+b.port_id COLLATE DATABASE_DEFAULT+N'","platformCapabilityId":"'+b.platform_id+N'","configuration":{"statement":"'+REPLACE(REPLACE(b.statement,N'\',N'\\'),N'"',N'\"')+N'","resultColumn":"'+b.result_column+N'","providerId":"'+b.provider_id+N'"}}'
            ELSE N'{"portId":"'+b.port_id COLLATE DATABASE_DEFAULT+N'","platformCapabilityId":"'+b.platform_id+N'","configuration":'+CASE WHEN b.config_json IS NOT NULL THEN CASE WHEN b.provider_id IS NOT NULL THEN JSON_MODIFY(b.config_json,N'$.providerId',b.provider_id) ELSE b.config_json END ELSE N'{"providerId":"'+b.provider_id+N'"}' END+N'}' END,N',') WITHIN GROUP (ORDER BY b.ordinal)
        FROM @bindings b WHERE b.scenario_ordinal=@si),N'')+N']}';
      SET @document+=CASE WHEN @si=1 THEN N'' ELSE N',' END+@s;
    END

    SET @document+=N']';
    -- Routing: the broadcast/join fan-out, selection routes and declared recurrences, in that order; the
    -- executionGraph when the capability declares a fan-out or a recurrence.
    -- Every transition carries its semanticProgress, by the law the estate's declared routes follow: a selection that ends
    -- at a terminal scenario is terminating and any other selection narrowing; broadcast expanding; join converging; a
    -- failure collected at its join slot converging; recurrence recurring.
    DECLARE @sel_items nvarchar(max)=(SELECT STRING_AGG(CONVERT(nvarchar(max),
        N'{"transitionId":"route-'+r.from_scenario COLLATE DATABASE_DEFAULT+N'-'+r.variant COLLATE DATABASE_DEFAULT+N'","fromScenario":"'+r.from_scenario COLLATE DATABASE_DEFAULT
        +N'","variant":"'+r.variant COLLATE DATABASE_DEFAULT+N'","toScenario":"'+r.to_scenario COLLATE DATABASE_DEFAULT+N'","topologyKind":"selection","semanticProgress":"'
        +CASE WHEN t.terminal=1 THEN N'terminating' ELSE N'narrowing' END+N'"}'),N',') WITHIN GROUP (ORDER BY r.ordinal)
      FROM @routes r LEFT JOIN @scenarios t ON t.scenario_id=r.to_scenario);
    DECLARE @bc_items nvarchar(max)=NULL,@exec nvarchar(max)=NULL;
    IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast')
    BEGIN
      DECLARE @troot nvarchar(200),@tlegs nvarchar(max),@tjoin nvarchar(200);
      SELECT @troot=root_id,@tlegs=legs FROM @topology WHERE form=N'broadcast';
      SET @tjoin=(SELECT join_id FROM @topology WHERE form=N'join');
      DECLARE @fan nvarchar(500)=@capability_id+N'.fan',@conv nvarchar(500)=@capability_id+N'.converge',@auth nvarchar(500)=@capability_id+N'.dispatch';
      DECLARE @legcnt int=(SELECT COUNT(*) FROM STRING_SPLIT(@tlegs,N','));
      DECLARE @legnames TABLE(ord int IDENTITY PRIMARY KEY,name nvarchar(400),leg nvarchar(400));
      INSERT @legnames(name,leg)
      SELECT CASE WHEN LTRIM(RTRIM(l.value)) LIKE @capability_id+N'-%' THEN SUBSTRING(LTRIM(RTRIM(l.value)),LEN(@capability_id)+2,400) ELSE LTRIM(RTRIM(l.value)) END,
             LTRIM(RTRIM(l.value))
      FROM STRING_SPLIT(@tlegs,N',') l ORDER BY (SELECT NULL);
      SET @bc_items=(SELECT STRING_AGG(CONVERT(nvarchar(max),seg.seg),N',') WITHIN GROUP (ORDER BY seg.ord) FROM (
          SELECT c.ord,
            N'{"transitionId":"enter-'+c.name+N'","fromScenario":"'+@troot+N'","variant":"SUCCESS","toScenario":"'+c.leg+N'","topologyKind":"broadcast","groupId":"'+@fan+N'","semanticProgress":"expanding"},'
           +N'{"transitionId":"settle-'+c.name+N'","fromScenario":"'+c.leg+N'","variant":"SUCCESS","toScenario":"'+@tjoin+N'","topologyKind":"join","groupId":"'+@conv+N'","joinSlotId":"'+c.name+N'","semanticProgress":"converging"},'
           +N'{"transitionId":"fail-'+c.name+N'","fromScenario":"'+c.leg+N'","variant":"SUCCESS","toScenario":"'+@tjoin+N'","topologyKind":"failure","groupId":"'+@conv+N'","joinSlotId":"'+c.name+N'","semanticProgress":"converging"}'
           AS seg
          FROM @legnames c) seg);
      SET @exec=N'{"graphType":"sda-semantic-execution-graph.v2","requiredExecutionFeatures":["declared-concurrent-dispatch.v1"],"readyArbitration":"causal-activation-order.v1","executionBudget":{"maximumInFlightEffects":'+CONVERT(nvarchar(10),@legcnt)+N',"deadlineMs":60000},"dispatchAuthorities":[{"dispatchAuthorityId":"'+@auth+N'","mode":"concurrent","legCount":'+CONVERT(nvarchar(10),@legcnt)+N',"maximumActiveBranches":'+CONVERT(nvarchar(10),@legcnt)+N',"maximumInFlightEffects":'+CONVERT(nvarchar(10),@legcnt)+N',"readyOrder":"declared-edge-order","branchFailure":"collect","ownership":"join-before-return"}],"edgeGroups":['
        +N'{"groupId":"'+@fan+N'","kind":"broadcast","policy":"all","edgeIds":['+COALESCE((SELECT STRING_AGG(CONVERT(nvarchar(max),N'"edge:enter-'+c.name+N'"'),N',') WITHIN GROUP (ORDER BY c.ord) FROM @legnames c),N'')+N'],"dispatchAuthorityId":"'+@auth+N'","completionJoinGroupId":"'+@conv+N'"},'
        +N'{"groupId":"'+@conv+N'","kind":"join","policy":"all-required","edgeIds":['+COALESCE((SELECT STRING_AGG(CONVERT(nvarchar(max),N'"edge:settle-'+c.name+N'"'),N',') WITHIN GROUP (ORDER BY c.ord) FROM @legnames c),N'')+N'],"joinCellId":"cell:scenario:'+@tjoin+N'","requiredSlotIds":['+COALESCE((SELECT STRING_AGG(N'"'+c.name+N'"',N',') WITHIN GROUP (ORDER BY c.ord) FROM @legnames c),N'')+N']}]}';
    END
    DECLARE @rec_items nvarchar(max)=NULL,@rec_groups nvarchar(max)=NULL,@rec_auths nvarchar(max)=NULL;
    IF EXISTS(SELECT 1 FROM @recurrences)
    BEGIN
      -- One recurrence edge per recur line, in its own bounded group, with its authority and the authority's digest.
      SELECT @rec_items=STRING_AGG(CONVERT(nvarchar(max),N'{"transitionId":"recur-'+r.scenario_id COLLATE DATABASE_DEFAULT+N'","fromScenario":"'+r.scenario_id COLLATE DATABASE_DEFAULT
          +N'","variant":"'+r.continue_variant COLLATE DATABASE_DEFAULT+N'","toScenario":"'+r.scenario_id COLLATE DATABASE_DEFAULT
          +N'","topologyKind":"recurrence","groupId":"'+@capability_id+N'.recur-'+r.scenario_id COLLATE DATABASE_DEFAULT
          +N'","recurrenceAuthorityId":"'+@capability_id+N'.recurrence.'+r.scenario_id COLLATE DATABASE_DEFAULT+N'","semanticProgress":"recurring"}'),N',')
          WITHIN GROUP (ORDER BY r.ordinal),
        @rec_groups=STRING_AGG(CONVERT(nvarchar(max),N'{"groupId":"'+@capability_id+N'.recur-'+r.scenario_id COLLATE DATABASE_DEFAULT
          +N'","kind":"recurrence","policy":"bounded","edgeIds":["edge:recur-'+r.scenario_id COLLATE DATABASE_DEFAULT+N'"]}'),N',') WITHIN GROUP (ORDER BY r.ordinal),
        @rec_auths=STRING_AGG(CONVERT(nvarchar(max),JSON_MODIFY(a.body,N'$.authorityDigest',N'sha256:'+LOWER(CONVERT(varchar(64),
          HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),a.body COLLATE Latin1_General_100_BIN2_UTF8))),2)))),N',') WITHIN GROUP (ORDER BY r.ordinal)
      FROM @recurrences r
      CROSS APPLY (SELECT N'{"recurrenceAuthorityId":"'+@capability_id+N'.recurrence.'+r.scenario_id COLLATE DATABASE_DEFAULT
          +N'","continuationVariant":"'+r.continue_variant COLLATE DATABASE_DEFAULT+N'","stopVariant":"'+r.stop_variant COLLATE DATABASE_DEFAULT
          +N'","maximumIterations":'+CONVERT(nvarchar(20),r.max_iterations)+N',"cancellationPolicy":"complete-current"}' AS body) a;
      -- A capability without a fan-out carries a recurrence-only graph: sequential, one effect at a time, and a
      -- deadline the kernel requires to be finite, so it is the largest it admits.
      IF @exec IS NULL
        SET @exec=N'{"graphType":"sda-semantic-execution-graph.v2","requiredExecutionFeatures":["declared-concurrent-dispatch.v1"],"readyArbitration":"causal-activation-order.v1","executionBudget":{"maximumInFlightEffects":1,"deadlineMs":2147483647},"dispatchAuthorities":[],"edgeGroups":[]}';
      DECLARE @rgs TABLE(i int PRIMARY KEY,g nvarchar(max));
      INSERT @rgs(i,g) SELECT CONVERT(int,[key]),value FROM OPENJSON(N'['+@rec_groups+N']');
      DECLARE @rgi int=(SELECT MIN(i) FROM @rgs);
      WHILE @rgi IS NOT NULL
      BEGIN
        SET @exec=JSON_MODIFY(@exec,N'append $.edgeGroups',JSON_QUERY((SELECT g FROM @rgs WHERE i=@rgi)));
        SET @rgi=(SELECT MIN(i) FROM @rgs WHERE i>@rgi);
      END
      SET @exec=JSON_MODIFY(@exec,N'$.recurrenceAuthorities',JSON_QUERY(N'['+@rec_auths+N']'));
    END
    DECLARE @all_items nvarchar(max)=(SELECT STRING_AGG(x.items,N',') WITHIN GROUP (ORDER BY x.o)
      FROM (VALUES(1,@bc_items),(2,@sel_items),(3,@rec_items)) x(o,items) WHERE x.items IS NOT NULL);
    IF @all_items IS NOT NULL SET @document+=N',"routing":['+@all_items+N']';
    IF @exec IS NOT NULL SET @document+=N',"executionGraph":'+@exec;
    IF EXISTS(SELECT 1 FROM @inquiries)
      SET @document+=N',"inquiries":['+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(q.txt,'json')+N'"'),N',') WITHIN GROUP (ORDER BY q.ordinal) FROM @inquiries q)+N']';
    SET @document+=N'}';
    SET @document_digest=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@document COLLATE Latin1_General_100_BIN2_UTF8))),2));
    -- A pinned source is checked against its feature's bytes, as the no-drift check checks a declaration. Each finding
    -- refuses as DSL_FEATURE_DRIFT at the source line it concerns, its code first in the message.
    IF @feature_text IS NOT NULL
    BEGIN
      DECLARE @check_request nvarchar(max)=(SELECT @feature_text AS featureText,JSON_QUERY(@document) AS [document] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      DECLARE @check_result nvarchar(max)=NULL;
      IF OBJECT_ID(CASE WHEN LEFT(@check_procedure,1)=N'#' THEN N'tempdb..'+@check_procedure ELSE @check_procedure END) IS NULL
        INSERT @errors(line_no,code,message) VALUES(@feature_line,N'DSL_FEATURE_DRIFT',N'CHECK_NOT_INSTALLED: '+@check_procedure+N' is not installed, so the source cannot be checked against its feature');
      ELSE
      BEGIN
        EXEC @check_procedure @input=@check_request,@estate_model_pk=@estate,@result=@check_result OUTPUT,@emit=0;
        IF ISNULL(JSON_VALUE(@check_result,N'$.status'),N'')<>N'CONFORMANT'
        BEGIN
          INSERT @errors(line_no,code,message)
          SELECT COALESCE(
              CASE WHEN f.code=N'SCENARIO_STEP_NOT_IN_FEATURE' THEN (SELECT TOP (1) CASE WHEN s.given_txt=f.declaredValue THEN s.given_line
                WHEN s.when_txt=f.declaredValue THEN s.when_line WHEN s.then_txt=f.declaredValue THEN s.then_line END FROM @scenarios s WHERE s.scenario_id=f.scenarioId) END,
              CASE WHEN f.code=N'PROVIDER_BINDING_UNTAGGED' THEN (SELECT TOP (1) o.line_no FROM @operations o WHERE o.operation_id=f.featureValue) END,
              (SELECT TOP (1) s.line_no FROM @scenarios s WHERE s.scenario_id=f.scenarioId),
              @feature_line),
            N'DSL_FEATURE_DRIFT',
            LEFT(f.code+N': '+CASE
              WHEN f.code=N'PROVIDER_BINDING_UNTAGGED' THEN N'operation '+ISNULL(f.featureValue,N'?')+N' uses '+ISNULL(f.declaredValue,N'?')+N', and no case of its scenario tags @provider:'+ISNULL(f.declaredValue,N'?')
              WHEN f.code=N'PROVIDER_TAG_UNBOUND' THEN N'@provider:'+ISNULL(f.featureValue,N'?')+N' is tagged, and no operation of '+ISNULL(f.scenarioId,N'the scenario')+N' uses it'
              WHEN f.code LIKE N'CASE[_]%' THEN CASE WHEN f.caseId IS NULL THEN N'the case' ELSE N'case '+f.caseId END+N' at feature line '+ISNULL(CONVERT(nvarchar(10),f.line),N'?')
              WHEN f.featureValue IS NOT NULL AND f.declaredValue IS NOT NULL THEN N'feature '+f.featureValue+N', source '+f.declaredValue
              ELSE COALESCE(f.declaredValue,f.featureValue,f.caseId,f.scenarioId,N'') END,400)
          FROM OPENJSON(@check_result,N'$.findings') WITH (code nvarchar(60) N'$.code',scenarioId nvarchar(400) N'$.scenarioId',caseId nvarchar(400) N'$.caseId',
            line int N'$.line',featureValue nvarchar(max) N'$.featureValue',declaredValue nvarchar(max) N'$.declaredValue') f;
          IF NOT EXISTS(SELECT 1 FROM OPENJSON(ISNULL(@check_result,N'{}'),N'$.findings'))
            INSERT @errors(line_no,code,message) VALUES(@feature_line,N'DSL_FEATURE_DRIFT',N'STATUS: '+ISNULL(JSON_VALUE(@check_result,N'$.status'),N'(no result)'));
        END
      END
      IF EXISTS(SELECT 1 FROM @errors)
      BEGIN
        SET @status=N'REFUSED';
        SET @document=NULL;
        SET @document_digest=NULL;
        SET @diagnostics=(SELECT e.code,e.line_no AS line,e.message FROM @errors e ORDER BY CASE WHEN e.line_no=0 THEN 1 ELSE 0 END,e.line_no,e.seq FOR JSON PATH);
      END
    END
  END
  -- The result carries the provider binding artifacts the author path mints, as compile-capability-dsl-result.v1 requires.
  DECLARE @pb_json nvarchar(max)=COALESCE((SELECT pb.id AS providerBindingId,pb.digest AS digest,JSON_QUERY(pb.content) AS content
    FROM @provider_bindings pb ORDER BY pb.ordinal FOR JSON PATH),N'[]');
  SELECT (SELECT N'compile-capability-dsl-result.v1' AS contractId,@status AS status,@source_digest AS sourceDigest,
    JSON_QUERY(@document) AS [document],@document_digest AS documentDigest,
    JSON_QUERY(@pb_json) AS providerBindings,
    JSON_QUERY(COALESCE(@diagnostics,N'[]')) AS diagnostics
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;
END;
GO
SET NOCOUNT ON;
DECLARE @cd nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'analysis.compile_capability_dsl')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @cd=SUBSTRING(@cd,CHARINDEX(N'PROCEDURE analysis.compile_capability_dsl',@cd),DATALENGTH(@cd)/2);
WHILE DATALENGTH(@cd)>0 AND RIGHT(@cd,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @cd=LEFT(@cd,DATALENGTH(@cd)/2-1);
DECLARE @cd_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@cd COLLATE Latin1_General_100_BIN2_UTF8)),2));
DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @in nvarchar(max),@r nvarchar(max);
DECLARE @t TABLE(v nvarchar(max));
SET @in=(SELECT N'capability nerdery-view-wildlife-home
feature nerdery-view-wildlife-home sha256:d91ded8a312cb3eca7c69a6004026db720227bfb8582623674705d6dfe7e4bc4
intent: View the selected team on the wildlife home page, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)
outcome: nerdery-view-wildlife-home-result.v1 VISIBLE or REFUSED, each refusal named by its reason code, so that my personal wildlife team is immediately recognizable
input contract nerdery-view-wildlife-home-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-view-wildlife-home-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-view-wildlife-home-result.v1"},"status":{"enum":["VISIBLE","REFUSED"]}}}
cli display outcome as json
scenario nerdery-view-wildlife-home root terminal
given: a wildlife home-page request
when: the home-page experience is read for the authenticated user
then: the user sees their saved team or a named refusal
operation nerdery-view-wildlife-home.view uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N''nerdery-view-wildlife-home'',@input=@input;","resultColumn":"value"}
input input from nerdery-view-wildlife-home $
outcome from nerdery-view-wildlife-home.view $.value
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;
SELECT @r=v FROM @t;
SELECT N'verify' AS result_set,@cd_digest AS compiler_body,'sha256:7197986a4ed494670a66ac89fad4d46d52421976a23b0a2aeba3173785a3be7d' AS compiler_expected,JSON_VALUE(@r,N'$.status') AS smoke_status,
 JSON_VALUE(@r,N'$.documentDigest') AS smoke_document,'sha256:19c2755268fd1c3f664f304e907a0859c7484e4a03cc78b043ded5e22cb288eb' AS smoke_expected,
 JSON_VALUE(@r,N'$.document.scenarios[0].portBindings[3].configuration.commandTimeout') AS compose_timeout,
 JSON_VALUE(@r,N'$.document.scenarios[0].portBindings[8].configuration.commandTimeout') AS outcome_timeout;
IF @cd_digest<>'sha256:7197986a4ed494670a66ac89fad4d46d52421976a23b0a2aeba3173785a3be7d' OR ISNULL(JSON_VALUE(@r,N'$.documentDigest'),N'')<>N'sha256:19c2755268fd1c3f664f304e907a0859c7484e4a03cc78b043ded5e22cb288eb'
BEGIN
 RAISERROR(N'REPAIR1_VERIFY_FAILED: the installed body is not the reviewed revision, or the smoke compile did not produce the reviewed document; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
DECLARE @minted TABLE(value nvarchar(max));
INSERT @minted(value) EXEC model.mint_content_artifact @document=N'{"artifactKind":"flight-promise:nerdery-citizen-slice-runtime-repair","text":"{\"contractId\":\"flight-promise.v1\",\"promiseId\":\"nerdery-citizen-slice-runtime-repair\",\"workClass\":\"owner-objective\",\"statement\":\"OV3 re-declares the eight capabilities of the Nerdery citizen slice from their unchanged sources with the repaired compiler, which gives each provider operation''s composing and outcome statements the command timeout the run-statement port requires. Each stored document is exactly the reviewed one: the declared document plus that timeout, feature pin kept, found CONFORMANT in the same change.\",\"obligations\":[{\"obligationId\":\"O1\",\"statement\":\"nerdery-browse-animal-collection is re-declared from nerdery/dsl/nerdery-browse-animal-collection.dsl, unchanged and pinned to its canonical feature sha256:dc19f2defcd1b0dcc5beead0fe42a0976336238216422d87397ccbcfcb7588c5, and its stored document is sha256:15585def540151adc1c10eca07ade3d3f4836bbf7c18578fde5a2bde4ea526ef: the document declared before (sha256:9e75d43fb1677d8be2ba1ee7b7496ef1d46b0266848542583c35c20d03f77aea) with commandTimeout 30 on its composing and outcome statements and no other difference.\",\"evidence\":\"apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest sha256:15585def540151adc1c10eca07ade3d3f4836bbf7c18578fde5a2bde4ea526ef\"},{\"obligationId\":\"O2\",\"statement\":\"nerdery-view-animal-definition is re-declared from nerdery/dsl/nerdery-view-animal-definition.dsl, unchanged and pinned to its canonical feature sha256:2b4c55fd4f28e46b17394b620ba9b9d78f854557b4c85a909989023a036472c5, and its stored document is sha256:b77c7293642c1482c6a65e1e109189d7d23c113c0a95c50c24ee3f1ff367e85b: the document declared before (sha256:82247dea4f373aa002a0467c1a9851a34fac98e26ae0103f5d52e4335be8b06d) with commandTimeout 30 on its composing and outcome statements and no other difference.\",\"evidence\":\"apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest sha256:b77c7293642c1482c6a65e1e109189d7d23c113c0a95c50c24ee3f1ff367e85b\"},{\"obligationId\":\"O3\",\"statement\":\"nerdery-upload-encounter-photo is re-declared from nerdery/dsl/nerdery-upload-encounter-photo.dsl, unchanged and pinned to its canonical feature sha256:38e58430acc3a39e88078f4a71000dacb3d585124a7a0cef2f906bcb35716de5, and its stored document is sha256:406a7eed9edead17f4739ec55d348eef88193a32b1d9f2e3e0214132782ef267: the document declared before (sha256:9ada077b47703f1fcc018960fb642df54b5f6c25c1c5364c46fe031b53ea6f75) with commandTimeout 30 on its composing and outcome statements and no other difference.\",\"evidence\":\"apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest sha256:406a7eed9edead17f4739ec55d348eef88193a32b1d9f2e3e0214132782ef267\"},{\"obligationId\":\"O4\",\"statement\":\"nerdery-record-animal-encounter is re-declared from nerdery/dsl/nerdery-record-animal-encounter.dsl, unchanged and pinned to its canonical feature sha256:df6cea9ceb5ce4d6a63755f8c42e80bc285191fecc18598e695ab6bd73e03a23, and its stored document is sha256:0cd6d46e2ac04e13bd9e8174b0d949b2a23692ad1ecb471c6dd1338b41237e23: the document declared before (sha256:f573243de9858b983225f43be402c897a603af6d275b95650ff6fccf9bcc2158) with commandTimeout 30 on its composing and outcome statements and no other difference.\",\"evidence\":\"apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest sha256:0cd6d46e2ac04e13bd9e8174b0d949b2a23692ad1ecb471c6dd1338b41237e23\"},{\"obligationId\":\"O5\",\"statement\":\"nerdery-view-collected-animals is re-declared from nerdery/dsl/nerdery-view-collected-animals.dsl, unchanged and pinned to its canonical feature sha256:a8f1920e6569b46ab5924fe841bebd5cc63a0993accb26f5a2e78cd20bcd835c, and its stored document is sha256:c408418707ec644ac93e52ac649b1a057db8c6b3a479a730fd992f10ce47b60a: the document declared before (sha256:8b3e21317eb7595f5600015804dcbec2e10d0ef4ae2e770552187c92264ab039) with commandTimeout 30 on its composing and outcome statements and no other difference.\",\"evidence\":\"apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest sha256:c408418707ec644ac93e52ac649b1a057db8c6b3a479a730fd992f10ce47b60a\"},{\"obligationId\":\"O6\",\"statement\":\"nerdery-set-animal-team is re-declared from nerdery/dsl/nerdery-set-animal-team.dsl, unchanged and pinned to its canonical feature sha256:6dd6c439568c45a7b63b8ad2745ac200f73c3d6d45e043d06b858cf0926048d2, and its stored document is sha256:e2e19f12aefb4ba796c96d3499ae1dd6bde539dc9210669c9686e21758e6b2eb: the document declared before (sha256:39f49bf066dae2b7076cf6ced2bc1f127ea448b530a6bf6d73d8a003945f0a50) with commandTimeout 30 on its composing and outcome statements and no other difference.\",\"evidence\":\"apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest sha256:e2e19f12aefb4ba796c96d3499ae1dd6bde539dc9210669c9686e21758e6b2eb\"},{\"obligationId\":\"O7\",\"statement\":\"nerdery-view-wildlife-home is re-declared from nerdery/dsl/nerdery-view-wildlife-home.dsl, unchanged and pinned to its canonical feature sha256:d91ded8a312cb3eca7c69a6004026db720227bfb8582623674705d6dfe7e4bc4, and its stored document is sha256:19c2755268fd1c3f664f304e907a0859c7484e4a03cc78b043ded5e22cb288eb: the document declared before (sha256:b4251058bdb9df40d1aab11615e70fafe24a798256d88adc537e7ac512bddfd1) with commandTimeout 30 on its composing and outcome statements and no other difference.\",\"evidence\":\"apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest sha256:19c2755268fd1c3f664f304e907a0859c7484e4a03cc78b043ded5e22cb288eb\"},{\"obligationId\":\"O8\",\"statement\":\"nerdery-add-animal-definition is re-declared from nerdery/dsl/nerdery-add-animal-definition.dsl, unchanged and pinned to its canonical feature sha256:cecfea79150494650b84f119ec59e26c742c7bc3822601f831aaf17ee1b2c4f2, and its stored document is sha256:eb55fd8339c6aca19606bc2953c03340d4a734c203b968db6837388bfd151ac7: the document declared before (sha256:6eca3d7aaeef7e50525518d42c5ae32dc3b6d866881929c133bf1af8d0e39189) with commandTimeout 30 on its composing and outcome statements and no other difference.\",\"evidence\":\"apply-declared-change COMMITTED; read-declared-capability-document $.documentDigest sha256:eb55fd8339c6aca19606bc2953c03340d4a734c203b968db6837388bfd151ac7\"}]}"}';
SELECT N'minted' AS result_set,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,JSON_VALUE(value,'$.content_digest') AS content_digest FROM @minted;
DECLARE @retained int=CASE WHEN EXISTS(SELECT 1 FROM model.content_artifact a WHERE a.artifact_kind=N'flight-promise:nerdery-citizen-slice-runtime-repair' AND a.content_digest=CONVERT(binary(32),'57a712ddb9ecdd1098870e1fc4b14e3e77a4df1329cf56184ddc184c96fae44d',2)) THEN 1 ELSE 0 END;
SELECT N'readback' AS result_set,N'flight-promise:nerdery-citizen-slice-runtime-repair' AS artifact_kind,'sha256:57a712ddb9ecdd1098870e1fc4b14e3e77a4df1329cf56184ddc184c96fae44d' AS digest,@retained AS retained;
IF @retained<>1
BEGIN
 RAISERROR(N'REPAIR1_VERIFY_FAILED: the promise is not retained under the digest of its reviewed bytes; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
ROLLBACK TRANSACTION;
GO
SET NOEXEC OFF;
