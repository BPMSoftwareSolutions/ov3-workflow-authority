-- dsl-01-test.sql
--
-- ============================== TEST - INSTALLS NOTHING ==============================
-- Run this first, once. It runs the reviewed revisions of analysis.compile_capability_dsl and
-- model.apply_capability_from_dsl as temporary procedures (#dsl01_compile, #dsl01_apply) that exist only in this
-- session, against the live estate. The installed procedures are neither changed nor locked. The one write, the
-- author-path probe, runs inside a transaction that always rolls back.
--
-- WHAT IT CHECKS:
--   probes       topology: every compiled transition carries semanticProgress by the estate's law (11 transitions), and
--                :terminal stays allowed on outcome-variants. refusals: a second root, an undeclared invoke-scenario
--                target, :terminal on a scenario variant, a self route, a route cycle, a self invoke-scenario and a join
--                without broadcast each refuse with a DSL_* code. provider binding: content, digest and placeholder
--                resolution, and four binding refusals. V8: the live specification's vector V8 compiles and reproduces
--                the digest of the artifact minted on 2026-10-15. V1: a source without routing compiles to the same
--                document as the installed compiler.
--   regression   every in-estate capability whose latest retained DSL source has a route, broadcast, join, recur,
--                provider binding, invoke-scenario or scenario :terminal line, or more than one root, compiled by the
--                installed and the revised compiler: same status, the same document apart from semanticProgress
--                members, and every transition's semanticProgress by the law.
--   author_probe inside a rolled-back transaction the revised author path mints a provider binding's content (exact
--                bytes, by digest) and declares the capability; after the rollback neither remains. Its writers print
--                their own result sets.
-- One compile takes about 22 s and the test runs about 26, so expect about 10 minutes.
-- RESULT SETS: base; the author path's own result sets; checks (one row per check, passed 1 or 0); verdict.
-- NEXT: when the verdict reads PASSED, run dsl-02-install-compiler-and-author-path.sql, then its .commit twin.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT>0
BEGIN
 RAISERROR(N'DSL01_OPEN_TRANSACTION: run this file in a session with no open transaction.',16,1);
 SET NOEXEC ON;
END
DECLARE @c varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'analysis.compile_capability_dsl')) COLLATE Latin1_General_100_BIN2_UTF8)),2));
DECLARE @a varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'model.apply_capability_from_dsl')) COLLATE Latin1_General_100_BIN2_UTF8)),2));
SELECT N'base' AS result_set,@c AS compiler_installed,'sha256:6aee2a7baec23b7e0563488a06536f5dbf88a60be5a9c4fe546c2276417c0ea9' AS compiler_expected,@a AS author_path_installed,'sha256:24112507370d0b9c8920cad1fe44044586407795e9b38a50fa2664a469712701' AS author_path_expected;
IF @c IS NULL OR @c<>'sha256:6aee2a7baec23b7e0563488a06536f5dbf88a60be5a9c4fe546c2276417c0ea9' OR @a IS NULL OR @a<>'sha256:24112507370d0b9c8920cad1fe44044586407795e9b38a50fa2664a469712701'
BEGIN
 RAISERROR(N'DSL01_BASE_MOVED: an installed procedure is not the base the revisions were drafted against; read it before running this file.',16,1);
 SET NOEXEC ON;
END
DROP PROCEDURE IF EXISTS #dsl01_apply;
DROP PROCEDURE IF EXISTS #dsl01_compile;
DROP TABLE IF EXISTS #dsl01_check;
CREATE TABLE #dsl01_check(o int IDENTITY(1,1) PRIMARY KEY,area nvarchar(40) NOT NULL,item nvarchar(400) NOT NULL,expected nvarchar(max) NULL,actual nvarchar(max) NULL,passed bit NOT NULL);
GO
CREATE PROCEDURE #dsl01_compile
  @input nvarchar(max),@estate_model_pk bigint
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
  DECLARE @scenarios TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_id nvarchar(200) COLLATE Latin1_General_100_BIN2,root bit,terminal bit,given_txt nvarchar(max),when_txt nvarchar(max),then_txt nvarchar(max),line_no int,input_contract nvarchar(200),output_contract nvarchar(200));
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
        IF @which=N'given' UPDATE @scenarios SET given_txt=@tail WHERE ordinal=@cur_scenario;
        IF @which=N'when' UPDATE @scenarios SET when_txt=@tail WHERE ordinal=@cur_scenario;
        IF @which=N'then' UPDATE @scenarios SET then_txt=@tail WHERE ordinal=@cur_scenario;
      END
    END
    ELSE IF LEFT(@line,10)=N'operation '
    BEGIN
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
        ELSE IF @rest NOT LIKE N'kind % port %' AND @rest NOT LIKE N'kind invoke-scenario scenario %'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "kind invoke-port port <port-id>", "kind invoke-scenario scenario <scenario-id>" or "kind for-each port <port-id> over <collection-path>"');
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
      IF @cur_binding IS NULL
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
          +N'"'+COALESCE(N',"outcomeVariants":['+o.variants_json+N']',N'')+N'}' END),N',') WITHIN GROUP (ORDER BY o.ordinal)
        FROM @operations o
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
CREATE PROCEDURE #dsl01_apply
  @document nvarchar(max)
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
  INSERT @cres EXEC #dsl01_compile @input=@cinput,@estate_model_pk=@estate;
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
GO
SET NOCOUNT ON;
DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @in nvarchar(max),@r nvarchar(max),@rb nvarchar(max);
DECLARE @t TABLE(v nvarchar(max));
-- topology
SET @in=(SELECT N'# dsl-01 probe: every compiled transition carries its semanticProgress.
capability dsl01-probe-topology
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
scenario intake root
variants: accepted:success,rejected:failure
operation dsl01-probe-topology.intake kind invoke-port port dsl01-pass
outcome-variants: passed:success,stopped:failure:terminal
platform bind dsl01-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"path","from":"input","path":""}}
scenario review
variants: approved:success,again:success,declined:failure
scenario dispatch
scenario leg-a
scenario leg-b
scenario settled terminal
scenario closed terminal
route intake accepted to review
route intake rejected to closed
route review approved to dispatch
route review declined to closed
recur review while again until approved max 3
broadcast dispatch to leg-a,leg-b
join settled from leg-a,leg-b' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl01_compile @input=@in,@estate_model_pk=@e;
SELECT @r=v FROM @t; DELETE @t;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'topology: compiles',N'COMPILED',JSON_VALUE(@r,N'$.status'),CASE WHEN JSON_VALUE(@r,N'$.status')=N'COMPILED' THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed)
SELECT N'probes',N'topology: '+x.tid,x.want,ISNULL(JSON_VALUE(r.value,N'$.semanticProgress'),N'(none)'),
 CASE WHEN JSON_VALUE(r.value,N'$.semanticProgress')=x.want THEN 1 ELSE 0 END
FROM (VALUES
 (N'enter-leg-a',N'expanding'),
 (N'settle-leg-a',N'converging'),
 (N'fail-leg-a',N'converging'),
 (N'enter-leg-b',N'expanding'),
 (N'settle-leg-b',N'converging'),
 (N'fail-leg-b',N'converging'),
 (N'route-intake-accepted',N'narrowing'),
 (N'route-intake-rejected',N'terminating'),
 (N'route-review-approved',N'narrowing'),
 (N'route-review-declined',N'terminating'),
 (N'recur-review',N'recurring')
) x(tid,want)
LEFT JOIN OPENJSON(@r,N'$.document.routing') r ON JSON_VALUE(r.value,N'$.transitionId')=x.tid;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'topology: every transition carries semanticProgress',N'11 of 11',CONCAT((SELECT COUNT(*) FROM OPENJSON(@r,N'$.document.routing') WHERE JSON_VALUE(value,N'$.semanticProgress') IS NOT NULL),N' of ',(SELECT COUNT(*) FROM OPENJSON(@r,N'$.document.routing'))),CASE WHEN (SELECT COUNT(*) FROM OPENJSON(@r,N'$.document.routing'))=11 AND NOT EXISTS(SELECT 1 FROM OPENJSON(@r,N'$.document.routing') WHERE JSON_VALUE(value,N'$.semanticProgress') IS NULL) THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'topology: :terminal stays allowed on outcome-variants',N'stopped terminal true',(SELECT TOP (1) CONCAT(JSON_VALUE(v.value,N'$.variantId'),N' terminal ',ISNULL(JSON_VALUE(v.value,N'$.terminal'),N'(none)')) FROM OPENJSON(@r,N'$.document.scenarios[0].operations[0].outcomeVariants') v WHERE JSON_VALUE(v.value,N'$.variantId')=N'stopped'),CASE WHEN EXISTS(SELECT 1 FROM OPENJSON(@r,N'$.document.scenarios[0].operations[0].outcomeVariants') v WHERE JSON_VALUE(v.value,N'$.variantId')=N'stopped' AND JSON_VALUE(v.value,N'$.terminal')=N'true') THEN 1 ELSE 0 END;
-- refusals
SET @in=(SELECT N'# dsl-01 probe: lines the compiler accepted before and must now refuse.
capability dsl01-probe-refusals
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
scenario entry root
variants: again:success,next:success
scenario second-entry root
scenario ping
variants: pong:success
scenario pong
variants: ping:success
scenario caller
operation dsl01-probe-refusals.call kind invoke-scenario scenario no-such-scenario
operation dsl01-probe-refusals.self kind invoke-scenario scenario caller
scenario marked
variants: done:success:terminal
scenario settle terminal
route entry again to entry
route entry next to ping
route ping pong to pong
route pong ping to ping
join settle from ping,pong' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl01_compile @input=@in,@estate_model_pk=@e;
SELECT @r=v FROM @t; DELETE @t;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'refusals: refused',N'REFUSED',JSON_VALUE(@r,N'$.status'),CASE WHEN JSON_VALUE(@r,N'$.status')=N'REFUSED' THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed)
SELECT N'probes',N'refusals: '+x.label,x.code+N' '+x.pat,
 ISNULL((SELECT TOP (1) CONCAT(JSON_VALUE(d.value,N'$.code'),N' line ',JSON_VALUE(d.value,N'$.line'),N': ',JSON_VALUE(d.value,N'$.message'))
  FROM OPENJSON(@r,N'$.diagnostics') d WHERE JSON_VALUE(d.value,N'$.code')=x.code AND JSON_VALUE(d.value,N'$.message') LIKE x.pat),N'(missing)'),
 CASE WHEN EXISTS(SELECT 1 FROM OPENJSON(@r,N'$.diagnostics') d WHERE JSON_VALUE(d.value,N'$.code')=x.code AND JSON_VALUE(d.value,N'$.message') LIKE x.pat) THEN 1 ELSE 0 END
FROM (VALUES
 (N'second root',N'DSL_DUPLICATE_ID',N'scenario: a second root scenario%'),
 (N'invoke-scenario target',N'DSL_VALUE_INVALID',N'operation: scenario is not declared: no-such-scenario'),
 (N'scenario variant :terminal',N'DSL_VALUE_INVALID',N'variants: a scenario variant takes no :terminal%'),
 (N'self route',N'DSL_VALUE_INVALID',N'routes or invoke-scenario operations form a cycle through entry:%'),
 (N'route cycle ping',N'DSL_VALUE_INVALID',N'routes or invoke-scenario operations form a cycle through ping:%'),
 (N'route cycle pong',N'DSL_VALUE_INVALID',N'routes or invoke-scenario operations form a cycle through pong:%'),
 (N'self invoke-scenario',N'DSL_VALUE_INVALID',N'routes or invoke-scenario operations form a cycle through caller:%'),
 (N'join without broadcast',N'DSL_REQUIRED_MISSING',N'join without broadcast:%')
) x(label,code,pat);
-- provider binding
SET @in=(SELECT N'# dsl-01 probe: a provider binding line, and a configuration that names it.
capability dsl01-probe-binding
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
provider binding dsl01-probe-binding.v1 { "bindingType": "sidefx-provider-input-binding.v1", "id": "dsl01-probe-binding.v1", "note": "spaces  inside a string stay" }
scenario dsl01-probe-binding root terminal
operation dsl01-probe-binding.pass kind invoke-port port dsl01-pass
platform bind dsl01-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"literal","value":"@provider-binding:dsl01-probe-binding.v1"}}' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl01_compile @input=@in,@estate_model_pk=@e;
SELECT @r=v FROM @t; DELETE @t;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'provider binding: compiles',N'COMPILED',JSON_VALUE(@r,N'$.status'),CASE WHEN JSON_VALUE(@r,N'$.status')=N'COMPILED' THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'provider binding: one artifact with its id',N'1 dsl01-probe-binding.v1',CONCAT((SELECT COUNT(*) FROM OPENJSON(@r,N'$.providerBindings')),N' ',JSON_VALUE(@r,N'$.providerBindings[0].providerBindingId')),CASE WHEN (SELECT COUNT(*) FROM OPENJSON(@r,N'$.providerBindings'))=1 AND JSON_VALUE(@r,N'$.providerBindings[0].providerBindingId')=N'dsl01-probe-binding.v1' THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'provider binding: digest over the UTF-8 content',N'sha256:5e1fe1ec3926ee0aa0ac39d244aa7d9682ed5d06ae99d96ea722d4911e0a53fd',JSON_VALUE(@r,N'$.providerBindings[0].digest'),CASE WHEN JSON_VALUE(@r,N'$.providerBindings[0].digest')=N'sha256:5e1fe1ec3926ee0aa0ac39d244aa7d9682ed5d06ae99d96ea722d4911e0a53fd' THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'provider binding: content without the whitespace outside strings',N'{"bindingType":"sidefx-provider-input-binding.v1","id":"dsl01-probe-binding.v1","note":"spaces  inside a string stay"}',JSON_QUERY(@r,N'$.providerBindings[0].content'),CASE WHEN JSON_QUERY(@r,N'$.providerBindings[0].content')=N'{"bindingType":"sidefx-provider-input-binding.v1","id":"dsl01-probe-binding.v1","note":"spaces  inside a string stay"}' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'provider binding: the configuration carries the digest',N'"value":"sha256:5e1fe1ec3926ee0aa0ac39d244aa7d9682ed5d06ae99d96ea722d4911e0a53fd" and no placeholder left',CONCAT(CASE WHEN JSON_QUERY(@r,N'$.document') LIKE N'%"value":"sha256:5e1fe1ec3926ee0aa0ac39d244aa7d9682ed5d06ae99d96ea722d4911e0a53fd"%' THEN N'digest present' ELSE N'digest missing' END,N', ',CASE WHEN JSON_QUERY(@r,N'$.document') LIKE N'%@provider-binding:%' THEN N'placeholder left' ELSE N'no placeholder left' END),CASE WHEN JSON_QUERY(@r,N'$.document') LIKE N'%"value":"sha256:5e1fe1ec3926ee0aa0ac39d244aa7d9682ed5d06ae99d96ea722d4911e0a53fd"%' AND JSON_QUERY(@r,N'$.document') NOT LIKE N'%@provider-binding:%' THEN 1 ELSE 0 END;
-- provider binding refusals
SET @in=(SELECT N'# dsl-01 probe: provider binding lines and placeholders the compiler refuses.
capability dsl01-probe-binding-refusals
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
provider binding dsl01-dup.v1 {"a":1}
provider binding dsl01-dup.v1 {"a":2}
provider binding dsl01-bad.v1 {"a":
provider binding Bad_Id {"a":1}
scenario dsl01-probe-binding-refusals root terminal
operation dsl01-probe-binding-refusals.pass kind invoke-port port dsl01-pass
platform bind dsl01-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"literal","value":"@provider-binding:no-such-binding.v1"}}' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl01_compile @input=@in,@estate_model_pk=@e;
SELECT @r=v FROM @t; DELETE @t;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'provider binding refusals: refused',N'REFUSED',JSON_VALUE(@r,N'$.status'),CASE WHEN JSON_VALUE(@r,N'$.status')=N'REFUSED' THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed)
SELECT N'probes',N'provider binding refusals: '+x.label,x.code+N' '+x.pat,
 ISNULL((SELECT TOP (1) CONCAT(JSON_VALUE(d.value,N'$.code'),N' line ',JSON_VALUE(d.value,N'$.line'),N': ',JSON_VALUE(d.value,N'$.message'))
  FROM OPENJSON(@r,N'$.diagnostics') d WHERE JSON_VALUE(d.value,N'$.code')=x.code AND JSON_VALUE(d.value,N'$.message') LIKE x.pat),N'(missing)'),
 CASE WHEN EXISTS(SELECT 1 FROM OPENJSON(@r,N'$.diagnostics') d WHERE JSON_VALUE(d.value,N'$.code')=x.code AND JSON_VALUE(d.value,N'$.message') LIKE x.pat) THEN 1 ELSE 0 END
FROM (VALUES
 (N'repeated binding id',N'DSL_DUPLICATE_ID',N'provider binding: repeated id'),
 (N'binding not a JSON object',N'DSL_CONTRACT_INVALID',N'provider binding: inline-json is not a JSON object'),
 (N'binding id rule',N'DSL_VALUE_INVALID',N'provider binding: id violates the id rule'),
 (N'unknown placeholder',N'DSL_VALUE_INVALID',N'config: names a provider binding that no provider binding line declares')
) x(label,code,pat);
-- V8 and V1, read from the live specification
DECLARE @spec nvarchar(max),@v8 nvarchar(max),@v1 nvarchar(max);
SELECT TOP (1) @spec=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.estate_definition ed
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
JOIN model.semantic_object so ON so.semantic_object_pk=d.semantic_object_pk
JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE ed.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1) AND so.object_kind=N'AUTHORITY'
 AND n.namespace_id=N'sidefx:authorities' COLLATE Latin1_General_100_BIN2 AND so.declared_id=N'capability-dsl-specification.v1' COLLATE Latin1_General_100_BIN2
ORDER BY d.semantic_object_definition_pk DESC;
SELECT @v8=x.src FROM OPENJSON(JSON_QUERY(@spec,N'$.semantics.conformanceVectors')) WITH (vectorId nvarchar(200) N'$.vectorId',src nvarchar(max) N'$.source') x WHERE x.vectorId=N'V8';
SELECT @v1=x.src FROM OPENJSON(JSON_QUERY(@spec,N'$.semantics.conformanceVectors')) WITH (vectorId nvarchar(200) N'$.vectorId',src nvarchar(max) N'$.source') x WHERE x.vectorId=N'V1';
SET @in=(SELECT @v8 AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl01_compile @input=@in,@estate_model_pk=@e;
SELECT @r=v FROM @t; DELETE @t;
-- V8 binds sda-governed-http-exchange-port.v1. If no port or platform declaration names it any more, V8 refuses
-- DSL_PROVIDER_UNKNOWN on that line only; the provider binding is parsed before that check, so its digest is still tested.
DECLARE @v8_platform_only bit=CASE WHEN JSON_VALUE(@r,N'$.status')=N'REFUSED' AND EXISTS(SELECT 1 FROM OPENJSON(@r,N'$.diagnostics'))
 AND NOT EXISTS(SELECT 1 FROM OPENJSON(@r,N'$.diagnostics') d WHERE JSON_VALUE(d.value,N'$.code')<>N'DSL_PROVIDER_UNKNOWN'
  OR JSON_VALUE(d.value,N'$.message') NOT LIKE N'platform not declared in the estate: sda-governed-http-exchange-port.v1') THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'V8: compiles, or refuses only because its exchange platform is no longer declared',N'COMPILED',CONCAT(JSON_VALUE(@r,N'$.status'),CASE WHEN @v8_platform_only=1 THEN N' (platform sda-governed-http-exchange-port.v1 no longer declared)' ELSE N'' END),CASE WHEN JSON_VALUE(@r,N'$.status')=N'COMPILED' OR @v8_platform_only=1 THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'V8: binding digest equals the artifact minted 2026-10-15',N'sha256:bde28572eff443e84610687bfcafab1b7d1e96c6a65a06836a0d33769415e4ba',JSON_VALUE(@r,N'$.providerBindings[0].digest'),CASE WHEN JSON_VALUE(@r,N'$.providerBindings[0].digest')=N'sha256:bde28572eff443e84610687bfcafab1b7d1e96c6a65a06836a0d33769415e4ba' THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'V8: the exchange configuration carries the digest',N'"endpointAuthorityDigest":"sha256:bde28572eff443e84610687bfcafab1b7d1e96c6a65a06836a0d33769415e4ba"',CASE WHEN JSON_QUERY(@r,N'$.document') LIKE N'%"endpointAuthorityDigest":"sha256:bde28572eff443e84610687bfcafab1b7d1e96c6a65a06836a0d33769415e4ba"%' THEN N'present' WHEN @v8_platform_only=1 THEN N'not compiled; substitution is tested by the provider binding probe' ELSE N'missing' END,CASE WHEN JSON_QUERY(@r,N'$.document') LIKE N'%"endpointAuthorityDigest":"sha256:bde28572eff443e84610687bfcafab1b7d1e96c6a65a06836a0d33769415e4ba"%' OR @v8_platform_only=1 THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'V8: the minted artifact is a live row',N'1',CONVERT(nvarchar(10),(SELECT COUNT(*) FROM source.content_object WHERE content_digest=CONVERT(binary(32),N'bde28572eff443e84610687bfcafab1b7d1e96c6a65a06836a0d33769415e4ba',2))),CASE WHEN EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=CONVERT(binary(32),N'bde28572eff443e84610687bfcafab1b7d1e96c6a65a06836a0d33769415e4ba',2)) THEN 1 ELSE 0 END;
SET @in=(SELECT @v1 AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;
SELECT @rb=v FROM @t; DELETE @t;
SET @in=(SELECT @v1 AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl01_compile @input=@in,@estate_model_pk=@e;
SELECT @r=v FROM @t; DELETE @t;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'V1: the installed compiler compiles it',N'COMPILED',JSON_VALUE(@rb,N'$.status'),CASE WHEN JSON_VALUE(@rb,N'$.status')=N'COMPILED' THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'V1: the same document from both compilers',N'same',CASE WHEN JSON_QUERY(@r,N'$.document')=JSON_QUERY(@rb,N'$.document') COLLATE Latin1_General_100_BIN2 THEN N'same' ELSE N'DIFFERENT' END,CASE WHEN JSON_QUERY(@r,N'$.document')=JSON_QUERY(@rb,N'$.document') COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'probes',N'V1: the result carries providerBindings',N'[]',JSON_QUERY(@r,N'$.providerBindings'),CASE WHEN JSON_QUERY(@r,N'$.providerBindings')=N'[]' THEN 1 ELSE 0 END;
GO
SET NOCOUNT ON;
DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DROP TABLE IF EXISTS #dsl01_regression;
CREATE TABLE #dsl01_regression(o int IDENTITY(1,1) PRIMARY KEY,capability_id nvarchar(400) NOT NULL,source_digest varchar(71) NOT NULL,src nvarchar(max) NOT NULL,base_result nvarchar(max) NULL,new_result nvarchar(max) NULL);
INSERT #dsl01_regression(capability_id,source_digest,src)
SELECT x.capability_id,x.digest,x.txt FROM (
 SELECT l.capability_id,'sha256:'+LOWER(CONVERT(varchar(64),l.content_digest,2)) AS digest,
  CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS txt
 FROM (SELECT s.capability_id,s.content_digest,ROW_NUMBER() OVER (PARTITION BY s.capability_id ORDER BY s.recorded_date DESC,s.capability_dsl_source_pk DESC) AS rn
  FROM model.capability_dsl_source s) l
 JOIN source.content_object co ON co.content_digest=l.content_digest
 WHERE l.rn=1 AND EXISTS(SELECT 1 FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk=ec.capability_pk
  WHERE ec.estate_model_pk=@e AND c.capability_id=l.capability_id COLLATE Latin1_General_100_BIN2)) x
WHERE EXISTS(SELECT 1 FROM STRING_SPLIT(x.txt,NCHAR(10)) v CROSS APPLY (SELECT LTRIM(RTRIM(REPLACE(REPLACE(v.value,NCHAR(13),N''),NCHAR(9),N' '))) AS line) q
  WHERE q.line LIKE N'route %' OR q.line LIKE N'broadcast %' OR q.line LIKE N'join %' OR q.line LIKE N'recur %'
   OR q.line LIKE N'provider binding %' OR q.line LIKE N'variants:%:terminal%' OR q.line LIKE N'operation % kind invoke-scenario %')
 OR (SELECT COUNT(*) FROM STRING_SPLIT(x.txt,NCHAR(10)) v CROSS APPLY (SELECT N' '+LTRIM(RTRIM(REPLACE(REPLACE(v.value,NCHAR(13),N''),NCHAR(9),N' ')))+N' ' AS line) q
  WHERE q.line LIKE N' scenario %' AND q.line LIKE N'% root %')>1
ORDER BY x.capability_id;
DECLARE @i int=(SELECT MIN(o) FROM #dsl01_regression),@in nvarchar(max);
DECLARE @t TABLE(v nvarchar(max));
WHILE @i IS NOT NULL
BEGIN
 SET @in=(SELECT src AS source FROM #dsl01_regression WHERE o=@i FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;
 UPDATE #dsl01_regression SET base_result=(SELECT v FROM @t) WHERE o=@i;
 DELETE @t;
 INSERT @t(v) EXEC #dsl01_compile @input=@in,@estate_model_pk=@e;
 UPDATE #dsl01_regression SET new_result=(SELECT v FROM @t) WHERE o=@i;
 DELETE @t;
 SET @i=(SELECT MIN(o) FROM #dsl01_regression WHERE o>@i);
END
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'regression',N'sources with routing, provider binding, invoke-scenario or root lines',N'at least 1',CONVERT(nvarchar(10),(SELECT COUNT(*) FROM #dsl01_regression)),CASE WHEN (SELECT COUNT(*) FROM #dsl01_regression)>0 THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed)
SELECT N'regression',g.capability_id+N' ('+g.source_digest+N')',
 N'same status; the same document apart from semanticProgress; every transition by the law',
 CONCAT(N'installed ',JSON_VALUE(g.base_result,N'$.status'),N', revised ',JSON_VALUE(g.new_result,N'$.status'),N', transitions ',k.routes,
  N', with semanticProgress ',k.with_progress,N', law violations ',k.violations,N', document apart from semanticProgress ',CASE WHEN k.same=1 THEN N'same' ELSE N'DIFFERENT' END),
 CASE WHEN JSON_VALUE(g.base_result,N'$.status')=JSON_VALUE(g.new_result,N'$.status') AND JSON_QUERY(g.new_result,N'$.providerBindings') IS NOT NULL
   AND (JSON_VALUE(g.new_result,N'$.status')<>N'COMPILED' OR (k.same=1 AND k.violations=0 AND k.with_progress=k.routes)) THEN 1 ELSE 0 END
FROM #dsl01_regression g
CROSS APPLY (SELECT JSON_QUERY(g.base_result,N'$.document') AS bd,JSON_QUERY(g.new_result,N'$.document') AS nd) d
CROSS APPLY (SELECT
  (SELECT COUNT(*) FROM OPENJSON(d.nd,N'$.routing')) AS routes,
  (SELECT COUNT(*) FROM OPENJSON(d.nd,N'$.routing') WHERE JSON_VALUE(value,N'$.semanticProgress') IS NOT NULL) AS with_progress,
  (SELECT COUNT(*) FROM OPENJSON(d.nd,N'$.routing') r WHERE ISNULL(JSON_VALUE(r.value,N'$.semanticProgress'),N'')<>CASE JSON_VALUE(r.value,N'$.topologyKind')
    WHEN N'selection' THEN CASE WHEN EXISTS(SELECT 1 FROM OPENJSON(d.nd,N'$.scenarios') s WHERE JSON_VALUE(s.value,N'$.scenarioId')=JSON_VALUE(r.value,N'$.toScenario') AND JSON_VALUE(s.value,N'$.terminal')=N'true') THEN N'terminating' ELSE N'narrowing' END
    WHEN N'broadcast' THEN N'expanding' WHEN N'join' THEN N'converging'
    WHEN N'failure' THEN CASE WHEN JSON_VALUE(r.value,N'$.joinSlotId') IS NULL THEN N'terminating' ELSE N'converging' END
    WHEN N'recurrence' THEN N'recurring' ELSE N'(unknown)' END) AS violations,
  CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(d.bd,N',"semanticProgress":"narrowing"',N''),N',"semanticProgress":"terminating"',N''),N',"semanticProgress":"expanding"',N''),N',"semanticProgress":"converging"',N''),N',"semanticProgress":"recurring"',N'')=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(d.nd,N',"semanticProgress":"narrowing"',N''),N',"semanticProgress":"terminating"',N''),N',"semanticProgress":"expanding"',N''),N',"semanticProgress":"converging"',N''),N',"semanticProgress":"recurring"',N'') COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END AS same) k
ORDER BY g.o;
GO
SET NOCOUNT ON;
DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @cap nvarchar(200)=N'dsl01-author-probe';
DECLARE @dg binary(32)=CONVERT(binary(32),N'bccf9b9a3500e013bfe35d325572a466ae48cec777a6e216eb1d49419197acf2',2);
DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),N'{"bindingType":"sidefx-provider-input-binding.v1","id":"dsl01-author-probe-binding.v1","note":"dsl-01 author-path probe, rolled back"}' COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @pre_obj int=(SELECT COUNT(*) FROM source.content_object WHERE content_digest=@dg);
DECLARE @pre_cap int=(SELECT COUNT(*) FROM model.capability WHERE capability_id=@cap COLLATE Latin1_General_100_BIN2);
DECLARE @doc nvarchar(max)=(SELECT N'capability-from-dsl-change.v1' AS contractId,N'# dsl-01 probe: authored through the author path inside a transaction that always rolls back.
capability dsl01-author-probe
intent: Test source of dsl-01; declared only inside a transaction that rolls back.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
cli display outcome as json
provider binding dsl01-author-probe-binding.v1 {"bindingType":"sidefx-provider-input-binding.v1","id":"dsl01-author-probe-binding.v1","note":"dsl-01 author-path probe, rolled back"}
scenario dsl01-author-probe root terminal
given: a provider binding line and a configuration that names it
when: the source is authored through the author path
then: the binding content is minted before the document that names its digest is declared
operation dsl01-author-probe.pass kind invoke-port port dsl01-author-probe-pass
platform bind dsl01-author-probe-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"literal","value":"@provider-binding:dsl01-author-probe-binding.v1"}}' AS source,CONVERT(bit,0) AS isMcpTooling FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @in_obj int=NULL,@in_cap int=NULL;
IF @pre_obj=0 AND @pre_cap=0
BEGIN
 BEGIN TRANSACTION;
 EXEC #dsl01_apply @document=@doc;
 SET @in_obj=(SELECT COUNT(*) FROM source.content_object WHERE content_digest=@dg AND content_bytes=@bytes AND byte_length=DATALENGTH(@bytes));
 SET @in_cap=(SELECT COUNT(*) FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk=ec.capability_pk
  WHERE ec.estate_model_pk=@e AND c.capability_id=@cap COLLATE Latin1_General_100_BIN2);
 ROLLBACK TRANSACTION;
END
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'author_probe',N'before: no probe capability and no probe binding content',N'0 and 0',CONCAT(@pre_cap,N' and ',@pre_obj),CASE WHEN @pre_cap=0 AND @pre_obj=0 THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'author_probe',N'in the transaction: the binding content is minted with its exact bytes',N'1 (sha256:bccf9b9a3500e013bfe35d325572a466ae48cec777a6e216eb1d49419197acf2)',CONVERT(nvarchar(10),@in_obj),CASE WHEN ISNULL(@in_obj,0)=1 THEN 1 ELSE 0 END;
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'author_probe',N'in the transaction: the capability is declared',N'1',CONVERT(nvarchar(10),@in_cap),CASE WHEN ISNULL(@in_cap,0)=1 THEN 1 ELSE 0 END;
DECLARE @post_obj int=(SELECT COUNT(*) FROM source.content_object WHERE content_digest=@dg);
DECLARE @post_cap int=(SELECT COUNT(*) FROM model.capability WHERE capability_id=@cap COLLATE Latin1_General_100_BIN2);
INSERT #dsl01_check(area,item,expected,actual,passed) SELECT N'author_probe',N'after the rollback: nothing remains',N'0 and 0',CONCAT(@post_cap,N' and ',@post_obj),CASE WHEN @post_cap=0 AND @post_obj=0 AND @@TRANCOUNT=0 THEN 1 ELSE 0 END;
GO
SET NOCOUNT ON;
DECLARE @probes int=(SELECT COUNT(*) FROM #dsl01_check WHERE area=N'probes'),@reg int=(SELECT COUNT(*) FROM #dsl01_check WHERE area=N'regression'),
 @auth int=(SELECT COUNT(*) FROM #dsl01_check WHERE area=N'author_probe'),@failed int=(SELECT COUNT(*) FROM #dsl01_check WHERE passed=0);
SELECT N'checks' AS result_set,o,area,item,expected,actual,passed FROM #dsl01_check ORDER BY o;
SELECT N'verdict' AS result_set,CASE WHEN @failed=0 AND @probes=40 AND @reg>=2 AND @auth=4 THEN N'PASSED' ELSE N'FAILED' END AS verdict,
 @probes AS probe_checks,40 AS probe_checks_expected,@reg AS regression_checks,@auth AS author_checks,4 AS author_checks_expected,@failed AS failed_checks;
DROP PROCEDURE IF EXISTS #dsl01_apply;
DROP PROCEDURE IF EXISTS #dsl01_compile;
GO
SET NOEXEC OFF;
