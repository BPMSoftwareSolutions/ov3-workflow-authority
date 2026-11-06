// Writes source/analysis.compile_capability_dsl.v3.sql from the installed revision (source/analysis.compile_capability_dsl.new.sql)
// by anchored edits. Each anchor must occur exactly once. The edits add four lines to the grammar:
//   feature <capability-id> sha256:<hex>            the source pins the retained bytes of its canonical feature
//   operation <id> uses provider <capability-id>    the operation hands its job to that provider capability
//   input <member> from <scenario|operation> <path> a member of the provider's request, from the request or the result before
//   outcome from <operation> <path>                 the scenario's outcome, from the result of the operation before it
// and check a pinned source against its feature with analysis.check_capability_feature_conformance.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
let t = fs.readFileSync(path.join(root, "source", "analysis.compile_capability_dsl.new.sql"), "utf8").replace(/\r\n/g, "\n");
const edit = (anchor, replacement) => {
  const n = t.split(anchor).length - 1;
  if (n !== 1) throw new Error(`anchor found ${n} times: ${anchor.slice(0, 120)}`);
  t = t.replace(anchor, () => replacement);
};

// The vault, credential and open ports every statement port needs, as the estate's PORT definitions bind them: the kernel
// runs those, not a document's portBindings. The open port carries its input on (sfx-vault-reference-carry-port.v1),
// because the run-statement provider opens the credential itself from vault, credentialReference, keyReference and
// keyService; the opening port (sfx-vault-reference-open-port.v1) replaces them with the secret, and the statement then
// fails DECLARED_PROVIDER_TARGET_MISSING:vault (run d37c4351). Only read-vault-credential still opens.
const VAULT = String.raw`{"providerId":"sfx-vault-file-host","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-file"}}`;
const CREDENTIAL = String.raw`{"providerId":"sfx-estate-database-credential","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}`;
const OPEN_PLATFORM = "sfx-vault-reference-carry-port.v1";
const OPEN = String.raw`{"providerId":"sfx-vault-secret-service-reference-carry","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-secret-service"}}`;
const STATEMENT = String.raw`{"providerId":"sfx-estate-database-run-statement","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}`;
const INVOKE = String.raw`{"providerId":"ScenarioKernel.NodePlatform","authoritySource":"DATABASE","capabilityIdPath":"executionTarget","namespacePath":"executionNamespace","scenarioPath":"executionScenario","requestPath":"dispatchRequest","resultPath":"result","lineageMode":"retain-nested-execution"}`;

// Validation of the bind under construction, run before a provider operation or an outcome ends it.
const CLOSE_BIND = String.raw`
            IF @cur_binding IS NOT NULL
            BEGIN
              IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'statement'
                AND (b.platform_id IS NULL OR b.provider_id IS NULL OR b.statement IS NULL OR b.result_column IS NULL))
                INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'bind: missing one of its four keys');
              IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'platform'
                AND (b.platform_id IS NULL OR (b.provider_id IS NULL AND b.config_json IS NULL)))
                INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'platform bind: missing platform, config or provider');
              SET @cur_binding=NULL;
            END`;
const PATH_OK = (v) => String.raw`(${v}=N'$' OR (LEFT(${v},2)=N'$.' AND SUBSTRING(${v},3,400) NOT LIKE N'%[^a-zA-Z0-9_.]%' AND ${v} NOT LIKE N'%..%' AND RIGHT(${v},1)<>N'.'))`;

// 1. Scenario step lines keep their line numbers, for drift diagnostics.
edit(String.raw`given_txt nvarchar(max),when_txt nvarchar(max),then_txt nvarchar(max),line_no int,input_contract nvarchar(200),output_contract nvarchar(200));`,
  String.raw`given_txt nvarchar(max),when_txt nvarchar(max),then_txt nvarchar(max),line_no int,input_contract nvarchar(200),output_contract nvarchar(200),given_line int,when_line int,then_line int);`);
edit(String.raw`        IF @which=N'given' UPDATE @scenarios SET given_txt=@tail WHERE ordinal=@cur_scenario;
        IF @which=N'when' UPDATE @scenarios SET when_txt=@tail WHERE ordinal=@cur_scenario;
        IF @which=N'then' UPDATE @scenarios SET then_txt=@tail WHERE ordinal=@cur_scenario;`,
  String.raw`        IF @which=N'given' UPDATE @scenarios SET given_txt=@tail,given_line=@i WHERE ordinal=@cur_scenario;
        IF @which=N'when' UPDATE @scenarios SET when_txt=@tail,when_line=@i WHERE ordinal=@cur_scenario;
        IF @which=N'then' UPDATE @scenarios SET then_txt=@tail,then_line=@i WHERE ordinal=@cur_scenario;`);

// 2. State of the four new lines.
edit(String.raw`  DECLARE @cur_scenario int=NULL,@cur_binding int=NULL;`,
  String.raw`  DECLARE @cur_scenario int=NULL,@cur_binding int=NULL;
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
  DECLARE @check_procedure nvarchar(400)=N'analysis.check_capability_feature_conformance';`);

// 3. A new scenario, operation or bind ends a provider operation's request lines.
edit(String.raw`            SET @cur_scenario=SCOPE_IDENTITY();
            SET @last_operation=NULL;`,
  String.raw`            SET @cur_scenario=SCOPE_IDENTITY();
            SET @last_operation=NULL;
            SET @cur_provider_op=NULL;`);
edit(String.raw`    ELSE IF LEFT(@line,10)=N'operation '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,11,LEN(@line)));`,
  String.raw`    ELSE IF LEFT(@line,10)=N'operation '
    BEGIN
      SET @cur_provider_op=NULL;
      SET @tail=LTRIM(SUBSTRING(@line,11,LEN(@line)));`);
edit(String.raw`      DECLARE @form nvarchar(20)=CASE WHEN LEFT(@line,14)=N'platform bind ' THEN N'platform' ELSE N'statement' END;`,
  String.raw`      SET @cur_provider_op=NULL;
      DECLARE @form nvarchar(20)=CASE WHEN LEFT(@line,14)=N'platform bind ' THEN N'platform' ELSE N'statement' END;`);

// 4. operation <id> uses provider <capability-id>.
edit(String.raw`        ELSE IF @rest NOT LIKE N'kind % port %' AND @rest NOT LIKE N'kind invoke-scenario scenario %'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "kind invoke-port port <port-id>", "kind invoke-scenario scenario <scenario-id>" or "kind for-each port <port-id> over <collection-path>"');`,
  String.raw`        ELSE IF LEFT(@rest,14)=N'uses provider '
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
          BEGIN${CLOSE_BIND}
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-vault',N'invoke-port',@pop_base+N'-vault',@i);
            DECLARE @pop_first int=SCOPE_IDENTITY();
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-credential',N'invoke-port',@pop_base+N'-credential',@i);
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-open',N'invoke-port',@pop_base+N'-open',@i);
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-compose',N'invoke-port',@pop_base+N'-compose',@i);
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id,N'invoke-port',@pop_base,@i);
            SET @last_operation=SCOPE_IDENTITY();
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-vault',N'platform',N'sfx-vault-host-read-port.v1',N'${VAULT}',@i,@i);
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-credential',N'platform',N'sfx-estate-credential-port.v1',N'${CREDENTIAL}',@i,@i);
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-open',N'platform',N'${OPEN_PLATFORM}',N'${OPEN}',@i,@i);
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-compose',N'platform',N'sfx-estate-run-statement-port.v1',NULL,@i,@i);
            DECLARE @pop_compose int=SCOPE_IDENTITY();
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base,N'platform',N'generic-capability-invocation.v1',N'${INVOKE}',@i,@i);
            INSERT @provider_ops(op_ordinal,provider_id,prefix_ordinal,compose_binding,line_no) VALUES(@last_operation,@pop_provider,@pop_first,@pop_compose,@i);
            SET @cur_provider_op=@last_operation;
          END
        END
        ELSE IF @rest NOT LIKE N'kind % port %' AND @rest NOT LIKE N'kind invoke-scenario scenario %'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "kind invoke-port port <port-id>", "kind invoke-scenario scenario <scenario-id>", "kind for-each port <port-id> over <collection-path>" or "uses provider <capability-id>"');`);

// 5. config: after a provider operation holds the static members of its request.
edit(String.raw`      SET @tail=LTRIM(SUBSTRING(@line,8,LEN(@line)));
      IF @cur_binding IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'config: no bind to attach to');`,
  String.raw`      SET @tail=LTRIM(SUBSTRING(@line,8,LEN(@line)));
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
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'config: no bind to attach to');`);

// 6. input, outcome from and feature lines.
edit(String.raw`      ELSE INSERT @readings(reading,altitudes) VALUES(LEFT(@tail,@sp-1),LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail))));
    END
    ELSE
      INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'line does not match any construct form');`,
  String.raw`      ELSE INSERT @readings(reading,altitudes) VALUES(LEFT(@tail,@sp-1),LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail))));
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
      ELSE IF NOT ${PATH_OK("@in_path")}
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
      ELSE IF NOT ${PATH_OK("@oc_path")}
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'outcome from: json path must be $ or $.<member>[.<member>...]');
      ELSE IF EXISTS(SELECT 1 FROM @operations o WHERE o.operation_id IN (@oc_scenario+N'.outcome-vault',@oc_scenario+N'.outcome-credential',@oc_scenario+N'.outcome-open',@oc_scenario+N'.outcome'))
        OR EXISTS(SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=@cur_scenario
          AND b.port_id IN (@oc_base,@oc_base+N'-vault',@oc_base+N'-credential',@oc_base+N'-open'))
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'outcome from: an operation or port it compiles to is already declared');
      ELSE
      BEGIN${CLOSE_BIND}
        SET @cur_provider_op=NULL;
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome-vault',N'invoke-port',@oc_base+N'-vault',@i);
        DECLARE @oc_first int=SCOPE_IDENTITY();
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome-credential',N'invoke-port',@oc_base+N'-credential',@i);
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome-open',N'invoke-port',@oc_base+N'-open',@i);
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome',N'invoke-port',@oc_base,@i);
        SET @last_operation=SCOPE_IDENTITY();
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base+N'-vault',N'platform',N'sfx-vault-host-read-port.v1',N'${VAULT}',@i,@i);
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base+N'-credential',N'platform',N'sfx-estate-credential-port.v1',N'${CREDENTIAL}',@i,@i);
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base+N'-open',N'platform',N'${OPEN_PLATFORM}',N'${OPEN}',@i,@i);
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
      INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'line does not match any construct form');`);

// 7. After parsing: the pinned feature's bytes, the provider capabilities and the lineage of request members and outcomes.
edit(String.raw`  IF @capability_id IS NULL
    INSERT @errors(line_no,code,message) VALUES(0,N'DSL_REQUIRED_MISSING',N'no capability line');`,
  String.raw`  -- The feature the source pins: its retained bytes are what the source is checked against.
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
    INSERT @errors(line_no,code,message) VALUES(0,N'DSL_REQUIRED_MISSING',N'no capability line');`);

// 8. The composing and outcome statements, written once the source compiles.
edit(String.raw`    SET @status=N'COMPILED';`,
  String.raw`    SET @status=N'COMPILED';
    -- Each provider operation's composing statement builds the dispatch the generic invocation reads: the provider, its
    -- root scenario and its request, the config: members as written and each input member from its path. Both statements
    -- carry the command timeout the run-statement port requires (DECLARED_PROVIDER_CONFIGURATION_VALUE_MISSING without it),
    -- 30 seconds as the estate's own composing statements declare it.
    UPDATE b SET config_json=JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(N'${STATEMENT}',N'$.statement',
        N'DECLARE @r nvarchar(max)=N'''+REPLACE(ISNULL(p.config_json,N'{}'),N'''',N'''''')+N''';'
        +ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max),N' SET @r=CASE WHEN JSON_QUERY(@input,N'''+i.carrier_path+N''') IS NOT NULL THEN JSON_MODIFY(@r,N''$."'
          +i.member COLLATE DATABASE_DEFAULT+N'"'',JSON_QUERY(@input,N'''+i.carrier_path+N''')) ELSE JSON_MODIFY(@r,N''$."'+i.member COLLATE DATABASE_DEFAULT
          +N'"'',JSON_VALUE(@input,N'''+i.carrier_path+N''')) END;'),N'') WITHIN GROUP (ORDER BY i.ordinal) FROM @provider_inputs i WHERE i.op_ordinal=p.op_ordinal),N'')
        +N' SELECT (SELECT N'''+p.provider_id COLLATE DATABASE_DEFAULT+N''' AS executionTarget,N''sidefx:capabilities'' AS executionNamespace,N'''
        +p.provider_scenario+N''' AS executionScenario,N''json'' AS inputType,JSON_QUERY(@r) AS dispatchRequest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;'),
      N'$.resultColumn',N'value'),N'$.commandTimeout',30)
    FROM @bindings b JOIN @provider_ops p ON p.compose_binding=b.ordinal;
    UPDATE b SET config_json=JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(N'${STATEMENT}',N'$.statement',
        N'SELECT JSON_QUERY(@input,N'''+so.carrier_path+N''') AS value;'),N'$.resultColumn',N'value'),N'$.commandTimeout',30)
    FROM @bindings b JOIN @scenario_outcomes so ON so.stmt_binding=b.ordinal;`);

// 9. A provider operation states its provider and its request members in the document.
edit(String.raw`          +N'"'+COALESCE(N',"outcomeVariants":['+o.variants_json+N']',N'')+N'}' END),N',') WITHIN GROUP (ORDER BY o.ordinal)
        FROM @operations o`,
  String.raw`          +N'"'+COALESCE(N',"outcomeVariants":['+o.variants_json+N']',N'')+ISNULL(px.extra,N'')+N'}' END),N',') WITHIN GROUP (ORDER BY o.ordinal)
        FROM @operations o
        OUTER APPLY (SELECT N',"providerCapabilityId":"'+p.provider_id COLLATE DATABASE_DEFAULT+N'"'
            +COALESCE(N',"inputs":['+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'{"member":"'+i.member COLLATE DATABASE_DEFAULT+N'","from":"'
              +i.source_ref COLLATE DATABASE_DEFAULT+N'","path":"'+i.json_path+N'"}'),N',') WITHIN GROUP (ORDER BY i.ordinal)
              FROM @provider_inputs i WHERE i.op_ordinal=p.op_ordinal)+N']',N'') AS extra
          FROM @provider_ops p WHERE p.op_ordinal=o.ordinal) px`);

// 10. The document records the feature it was compiled against.
edit(String.raw`    SET @document=N'{"document":"sidefx-capability-authority.v1","capabilityId":"'+@capability_id+N'"';`,
  String.raw`    SET @document=N'{"document":"sidefx-capability-authority.v1","capabilityId":"'+@capability_id+N'"';
    IF @feature_line IS NOT NULL
      SET @document+=N',"feature":{"capabilityId":"'+@feature_cap+N'","digest":"sha256:'+@feature_hex+N'"}';`);

// 11. A pinned source is checked against its feature, as the no-drift check checks a declaration; any drift refuses.
edit(String.raw`    SET @document_digest=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@document COLLATE Latin1_General_100_BIN2_UTF8))),2));
  END`,
  String.raw`    SET @document_digest=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@document COLLATE Latin1_General_100_BIN2_UTF8))),2));
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
  END`);

const out = path.join(root, "source", "analysis.compile_capability_dsl.v3.sql");
fs.writeFileSync(out, t);
console.log("wrote", out, t.length, "chars,", t.split("\n").length, "lines");
