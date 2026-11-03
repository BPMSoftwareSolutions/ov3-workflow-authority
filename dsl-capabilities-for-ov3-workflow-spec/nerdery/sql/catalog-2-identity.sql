-- catalog-2-identity.sql
--
-- ============================== PREFLIGHT - NOT A WRITE ==============================
-- Byte-identical to the .commit twin except this banner and the terminal statement:
-- ROLLBACK TRANSACTION here, COMMIT TRANSACTION there. Nothing is written.
--
--
-- WHAT THIS DOES, in one transaction on the sfx-identity database:
--   1. installs the mechanics of the seven capabilities: wildlife.update_animal_definition, remove_animal_definition,
--      add_animal_attribute, update_animal_attribute, remove_animal_attribute, view_catalog_for_maintenance and
--      resolve_wildlife_access. Their texts met all 44 cases of their features read-only (runs 869e7203, 669ba146,
--      dce56efb);
--   2. alters wildlife.invoke_operation to dispatch them and to answer a catalog change that cannot be stored as not applied;
--   3. verifies every body by digest and calls the new operations as Casey (biologist) and Blake (citizen), changing nothing;
--   4. gives Avery, the owner's principal, the biologist role beside the citizen one, so one SideFX session can show
--      both the citizen journey and the catalog maintenance;
--   5. records the plan of flight nerdery-catalog-maintenance-and-access under planner agent claude-code-opus-5-5-nerdery-slice through evidence.upsert_flight_plan:
--      declare each capability from its DSL and prove its stored document. The plan is nerdery/flights/catalog.steps.json;
--      its digest is sha256:0442d1cbd50c5944662d30d85027fdd9fef4cf928ad558a8a8693b996c99b50f.
-- RUN catalog-1-estate FIRST. WHERE: sfx-identity. Run the whole file in one session (a few seconds).
-- BASES: wildlife.invoke_operation sha256:ba3aa04ed0e8eecbce3e0165db43365513f97e522853838ba174f78b9d90350a, none of the seven procedures yet, the owner principal active and
-- mapped to user-a, the plan writer's four parameters, the agent's current plan sha256:aa443b90cf0930cc05349f65195280f42b8ef644dbe910fdc286896e57f96b70 (the photo flight, flown).
-- RESULT SETS: base; verify (digest_matches 1 each); smoke (every passed 1); roles; plans (matches_reviewed_file 1).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @p uniqueidentifier='565de6d4-ebcd-408b-9359-04d21dc62183';
DECLARE @io nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.invoke_operation')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @io=SUBSTRING(@io,CHARINDEX(N'PROCEDURE wildlife.invoke_operation',@io),DATALENGTH(@io)/2);
WHILE DATALENGTH(@io)>0 AND RIGHT(@io,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @io=LEFT(@io,DATALENGTH(@io)/2-1);
DECLARE @io_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@io COLLATE Latin1_General_100_BIN2_UTF8)),2));
DECLARE @present int=(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'wildlife') AND name IN (N'update_animal_definition',N'remove_animal_definition',N'add_animal_attribute',N'update_animal_attribute',N'remove_animal_attribute',N'view_catalog_for_maintenance',N'resolve_wildlife_access'));
DECLARE @owner int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id=@p AND active=1),
 @mapped int=(SELECT COUNT(*) FROM wildlife.app_user WHERE principal_id=@p AND user_id=N'user-a'),
 @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));
DECLARE @current binary(32)=(SELECT plan_digest FROM evidence.flight_plan WHERE principal_id=@p AND agent_id=N'claude-code-opus-5-5-nerdery-slice');
SELECT N'base' AS result_set,@io_digest AS dispatcher_installed,@present AS new_procedures_present,@owner AS owner_principal_active,@mapped AS owner_is_user_a,
 @params AS plan_writer_parameters,N'sha256:'+LOWER(CONVERT(varchar(64),@current,2)) AS current_plan;
IF @io_digest IS NULL OR @io_digest<>'sha256:ba3aa04ed0e8eecbce3e0165db43365513f97e522853838ba174f78b9d90350a' OR @present<>0 OR @owner<>1 OR @mapped<>1 OR @params<>4 OR @current IS NULL OR @current<>CONVERT(binary(32),'aa443b90cf0930cc05349f65195280f42b8ef644dbe910fdc286896e57f96b70',2)
BEGIN
 RAISERROR(N'CATALOG2_BASE: the dispatcher, the procedures, the owner principal or its user, the plan writer or the agent''s current plan is not the reviewed base; nothing is changed.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
GO
CREATE OR ALTER PROCEDURE wildlife.update_animal_definition
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-update-animal-definition-result.v1',@code nvarchar(60)=NULL,@current int=NULL;
  DECLARE @id nvarchar(100)=JSON_VALUE(@request,N'$.definitionId'),@expected int=TRY_CONVERT(int,JSON_VALUE(@request,N'$.expectedRevision'));
  DECLARE @revision int=NULL,@active bit=NULL;
  DECLARE @a nvarchar(max)=JSON_QUERY(@request,N'$.animal');
  DECLARE @common nvarchar(200)=JSON_VALUE(@a,N'$.commonName'),@scientific nvarchar(200)=JSON_VALUE(@a,N'$.scientificName'),
    @avatar nvarchar(100)=JSON_VALUE(@a,N'$.avatarPhotoRef'),@number int=TRY_CONVERT(int,JSON_VALUE(@a,N'$.collectionNumber')),
    @range nvarchar(max)=JSON_QUERY(@a,N'$.range'),@types nvarchar(max)=JSON_QUERY(@a,N'$.types'),@stats nvarchar(max)=JSON_QUERY(@a,N'$.stats'),
    @attributes nvarchar(max)=ISNULL(JSON_QUERY(@a,N'$.attributes'),N'[]');
  DECLARE @range_rows TABLE(ordinal int PRIMARY KEY,county_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,value_type int NOT NULL);
  DECLARE @type_rows TABLE(ordinal int PRIMARY KEY,type_name nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,value_type int NOT NULL);
  DECLARE @attr_rows TABLE(ordinal int PRIMARY KEY,attribute_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,value_ids nvarchar(max) NULL);
  DECLARE @value_rows TABLE(attribute_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,ordinal int NOT NULL,value_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,value_type int NOT NULL);
  IF @range IS NOT NULL AND LEFT(LTRIM(@range),1)=N'['
    INSERT @range_rows SELECT CONVERT(int,[key]),CASE WHEN [type]=1 THEN [value] END,[type] FROM OPENJSON(@range);
  IF @types IS NOT NULL AND LEFT(LTRIM(@types),1)=N'['
    INSERT @type_rows SELECT CONVERT(int,[key]),CASE WHEN [type]=1 THEN [value] END,[type] FROM OPENJSON(@types);
  IF LEFT(LTRIM(@attributes),1)=N'['
  BEGIN
    INSERT @attr_rows SELECT CONVERT(int,j.[key]),JSON_VALUE(j.[value],N'$.attributeId'),JSON_QUERY(j.[value],N'$.valueIds') FROM OPENJSON(@attributes) j;
    INSERT @value_rows SELECT r.attribute_id,CONVERT(int,v.[key]),CASE WHEN v.[type]=1 THEN v.[value] END,v.[type]
    FROM @attr_rows r CROSS APPLY OPENJSON(ISNULL(r.value_ids,N'[]')) v WHERE r.attribute_id IS NOT NULL;
  END
  -- D13: a change names the revision its author saw; a stale change is refused and changes nothing.
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.user_role r WHERE r.user_id=@user_id AND r.role=N'biologist') SET @code=N'BIOLOGIST_ROLE_REQUIRED';
  ELSE IF @id IS NULL OR LEN(LTRIM(RTRIM(@id)))=0 SET @code=N'ANIMAL_SELECTION_REQUIRED';
  ELSE IF @expected IS NULL SET @code=N'REVISION_REQUIRED';
  ELSE
  BEGIN
    SELECT @revision=d.revision,@active=d.active FROM wildlife.animal_definition d WHERE d.definition_id=@id;
    IF @revision IS NULL SET @code=N'ANIMAL_DEFINITION_NOT_FOUND';
    ELSE IF @revision<>@expected SELECT @code=N'REVISION_CONFLICT',@current=@revision;
  END
  -- The proposed properties are checked as an addition checks them; the definition's own collection number is no conflict.
  IF @code IS NULL
  BEGIN
    IF @a IS NULL OR LEN(LTRIM(RTRIM(ISNULL(@common,N''))))=0 OR LEN(LTRIM(RTRIM(ISNULL(@scientific,N''))))=0 OR LEN(LTRIM(RTRIM(ISNULL(@avatar,N''))))=0
      OR @number IS NULL OR @number<1 OR @range IS NULL OR LEFT(LTRIM(@range),1)<>N'[' OR @types IS NULL OR LEFT(LTRIM(@types),1)<>N'['
      OR @stats IS NULL OR LEFT(LTRIM(@stats),1)<>N'{' OR LEFT(LTRIM(@attributes),1)<>N'['
      OR EXISTS(SELECT 1 FROM @range_rows WHERE value_type<>1) OR EXISTS(SELECT 1 FROM @type_rows WHERE value_type<>1)
      OR EXISTS(SELECT 1 FROM @attr_rows WHERE attribute_id IS NULL OR value_ids IS NULL OR LEFT(LTRIM(value_ids),1)<>N'[') OR EXISTS(SELECT 1 FROM @value_rows WHERE value_type<>1)
      SET @code=N'ANIMAL_DEFINITION_INCOMPLETE';
    ELSE IF (SELECT COUNT(*) FROM @type_rows)>2 SET @code=N'ANIMAL_TYPE_LIMIT_EXCEEDED';
    ELSE IF EXISTS(SELECT 1 FROM @type_rows t WHERE NOT EXISTS(SELECT 1 FROM wildlife.animal_type x WHERE x.type_name=t.type_name)) SET @code=N'ANIMAL_TYPE_UNKNOWN';
    ELSE IF EXISTS(SELECT type_name FROM @type_rows GROUP BY type_name HAVING COUNT(*)>1) SET @code=N'ANIMAL_TYPE_DUPLICATE';
    ELSE IF EXISTS(SELECT 1 FROM @range_rows r WHERE NOT EXISTS(SELECT 1 FROM wildlife.county c WHERE c.county_id=r.county_id)) SET @code=N'COUNTY_UNKNOWN';
    ELSE IF EXISTS(SELECT county_id FROM @range_rows GROUP BY county_id HAVING COUNT(*)>1) SET @code=N'COUNTY_DUPLICATE';
    ELSE IF EXISTS(SELECT 1 FROM wildlife.animal_definition d WHERE d.collection_number=@number AND d.definition_id<>@id) SET @code=N'COLLECTION_NUMBER_NOT_UNIQUE';
    ELSE IF EXISTS(SELECT 1 FROM @attr_rows r WHERE NOT EXISTS(SELECT 1 FROM wildlife.attribute x WHERE x.attribute_id=r.attribute_id AND x.active=1)) SET @code=N'ATTRIBUTE_UNKNOWN';
    ELSE IF EXISTS(SELECT attribute_id FROM @attr_rows GROUP BY attribute_id HAVING COUNT(*)>1) SET @code=N'ATTRIBUTE_DUPLICATE';
    ELSE IF EXISTS(SELECT 1 FROM @value_rows v WHERE NOT EXISTS(SELECT 1 FROM wildlife.attribute_value x WHERE x.attribute_id=v.attribute_id AND x.value_id=v.value_id))
      SET @code=N'ATTRIBUTE_VALUE_NOT_SELECTABLE';
    ELSE IF EXISTS(SELECT attribute_id,value_id FROM @value_rows GROUP BY attribute_id,value_id HAVING COUNT(*)>1) SET @code=N'ATTRIBUTE_VALUE_DUPLICATE';
    ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.photo p WHERE p.photo_ref=@avatar AND p.purpose=N'avatar' AND p.durable=1) SET @code=N'AVATAR_PHOTO_NOT_RETAINED';
  END
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      @current AS currentRevision,JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  DECLARE @range_json nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(county_id,'json')+N'"'),N',') WITHIN GROUP (ORDER BY ordinal)+N']' FROM @range_rows),N'[]');
  DECLARE @types_json nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(type_name,'json')+N'"'),N',') WITHIN GROUP (ORDER BY ordinal)+N']' FROM @type_rows),N'[]');
  DECLARE @attr_json nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),x.j),N',') WITHIN GROUP (ORDER BY x.ordinal)+N']' FROM (
      SELECT r.ordinal,N'{"attributeId":"'+STRING_ESCAPE(r.attribute_id,'json')+N'","valueIds":'
        +ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(v.value_id,'json')+N'"'),N',') WITHIN GROUP (ORDER BY v.ordinal)+N']' FROM @value_rows v WHERE v.attribute_id=r.attribute_id),N'[]')+N'}' AS j
      FROM @attr_rows r) x),N'[]');
  -- The definition keeps its identity: encounters, teams and unlocks that name it keep naming it.
  DECLARE @tc int=@@TRANCOUNT;
  BEGIN TRY
    IF @tc=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION wildlife_definition_update;
    UPDATE wildlife.animal_definition SET revision=@revision+1,common_name=@common,scientific_name=@scientific,avatar_photo_ref=@avatar,collection_number=@number,
      range_json=@range_json,types_json=@types_json,stats_json=@stats,attributes_json=@attr_json WHERE definition_id=@id;
    DELETE wildlife.definition_county WHERE definition_id=@id;
    INSERT wildlife.definition_county(definition_id,county_id) SELECT @id,county_id FROM @range_rows;
    DELETE wildlife.definition_type WHERE definition_id=@id;
    INSERT wildlife.definition_type(definition_id,type_name) SELECT @id,type_name FROM @type_rows;
    DELETE wildlife.definition_attribute_value WHERE definition_id=@id;
    INSERT wildlife.definition_attribute_value(definition_id,attribute_id,value_id) SELECT @id,attribute_id,value_id FROM @value_rows;
    IF @tc=0 COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE()=-1 OR (@tc=0 AND @@TRANCOUNT>0) ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION wildlife_definition_update;
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"CATALOG_STORAGE_UNAVAILABLE"}') AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END CATCH
  SET @result=(SELECT @contract AS contractId,N'UPDATED' AS status,
    JSON_QUERY((SELECT @id AS definitionId,@revision+1 AS revision,@active AS active,@common AS commonName,@scientific AS scientificName,@avatar AS avatarPhotoRef,
      @number AS collectionNumber,JSON_QUERY(@range_json) AS [range],JSON_QUERY(@types_json) AS types,JSON_QUERY(@stats) AS stats,JSON_QUERY(@attr_json) AS attributes
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS animal,
    JSON_QUERY(N'{"applied":true}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.remove_animal_definition
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-remove-animal-definition-result.v1',@code nvarchar(60)=NULL,@current int=NULL;
  DECLARE @id nvarchar(100)=JSON_VALUE(@request,N'$.definitionId'),@expected int=TRY_CONVERT(int,JSON_VALUE(@request,N'$.expectedRevision'));
  DECLARE @revision int=NULL,@active bit=NULL;
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.user_role r WHERE r.user_id=@user_id AND r.role=N'biologist') SET @code=N'BIOLOGIST_ROLE_REQUIRED';
  ELSE IF @id IS NULL OR LEN(LTRIM(RTRIM(@id)))=0 SET @code=N'ANIMAL_SELECTION_REQUIRED';
  ELSE IF @expected IS NULL SET @code=N'REVISION_REQUIRED';
  ELSE
  BEGIN
    SELECT @revision=d.revision,@active=d.active FROM wildlife.animal_definition d WHERE d.definition_id=@id;
    IF @revision IS NULL SET @code=N'ANIMAL_DEFINITION_NOT_FOUND';
    ELSE IF @revision<>@expected SELECT @code=N'REVISION_CONFLICT',@current=@revision;
    ELSE IF @active=0 SET @code=N'ANIMAL_DEFINITION_UNAVAILABLE';
  END
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      @current AS currentRevision,JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  -- Removal takes the definition out of the active catalog; recorded individuals and team memberships stay as they are.
  DECLARE @encounters int=(SELECT COUNT(*) FROM wildlife.encounter e WHERE e.definition_id=@id);
  DECLARE @places int=(SELECT COUNT(*) FROM wildlife.team_member m JOIN wildlife.encounter e ON e.owner_user_id=m.owner_user_id AND e.encounter_id=m.encounter_id
    WHERE e.definition_id=@id);
  DECLARE @tc int=@@TRANCOUNT;
  BEGIN TRY
    IF @tc=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION wildlife_definition_remove;
    UPDATE wildlife.animal_definition SET active=0,revision=@revision+1 WHERE definition_id=@id;
    IF @tc=0 COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE()=-1 OR (@tc=0 AND @@TRANCOUNT>0) ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION wildlife_definition_remove;
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"CATALOG_STORAGE_UNAVAILABLE"}') AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END CATCH
  SET @result=(SELECT @contract AS contractId,N'REMOVED' AS status,@id AS definitionId,CONVERT(bit,0) AS active,@revision+1 AS revision,
    JSON_QUERY((SELECT @encounters AS encountersRetained,@places AS teamReferencesRetained FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS history,
    JSON_QUERY(N'{"applied":true}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.add_animal_attribute
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-add-animal-attribute-result.v1',@code nvarchar(60)=NULL;
  DECLARE @a nvarchar(max)=JSON_QUERY(@request,N'$.attribute');
  DECLARE @name nvarchar(200)=JSON_VALUE(@a,N'$.name'),@description nvarchar(2000)=JSON_VALUE(@a,N'$.description'),@values nvarchar(max)=JSON_QUERY(@a,N'$.selectableValues');
  DECLARE @rows TABLE(ordinal int PRIMARY KEY,value_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,label nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,value_type int NOT NULL);
  IF @values IS NOT NULL AND LEFT(LTRIM(@values),1)=N'['
    INSERT @rows SELECT CONVERT(int,[key]),CASE WHEN [type]=5 THEN JSON_VALUE([value],N'$.valueId') END,CASE WHEN [type]=5 THEN JSON_VALUE([value],N'$.label') END,[type] FROM OPENJSON(@values);
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.user_role r WHERE r.user_id=@user_id AND r.role=N'biologist') SET @code=N'BIOLOGIST_ROLE_REQUIRED';
  ELSE IF LEN(LTRIM(RTRIM(ISNULL(@name,N''))))=0 OR LEN(LTRIM(RTRIM(ISNULL(@description,N''))))=0 OR @values IS NULL OR LEFT(LTRIM(@values),1)<>N'['
    OR NOT EXISTS(SELECT 1 FROM @rows) OR EXISTS(SELECT 1 FROM @rows WHERE value_type<>5 OR LEN(LTRIM(RTRIM(ISNULL(value_id,N''))))=0 OR LEN(LTRIM(RTRIM(ISNULL(label,N''))))=0)
    SET @code=N'ANIMAL_ATTRIBUTE_INCOMPLETE';
  ELSE IF EXISTS(SELECT value_id FROM @rows GROUP BY value_id HAVING COUNT(*)>1) SET @code=N'ATTRIBUTE_VALUE_DUPLICATE';
  ELSE IF EXISTS(SELECT 1 FROM wildlife.attribute x WHERE x.active=1 AND LOWER(LTRIM(RTRIM(x.name))) COLLATE Latin1_General_100_CI_AS=LOWER(LTRIM(RTRIM(@name))) COLLATE Latin1_General_100_CI_AS)
    SET @code=N'ATTRIBUTE_NAME_NOT_UNIQUE';
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  -- The attribute's identity is its name in lower case with every other character run made a hyphen, numbered when taken.
  DECLARE @lower nvarchar(200)=LOWER(LTRIM(RTRIM(@name))),@slug nvarchar(200)=N'',@i int=1,@ch nchar(1);
  WHILE @i<=LEN(@lower)
  BEGIN
    SET @ch=SUBSTRING(@lower,@i,1);
    IF @ch COLLATE Latin1_General_100_BIN2 LIKE N'[a-z0-9]' SET @slug+=@ch;
    ELSE IF RIGHT(@slug,1)<>N'-' AND LEN(@slug)>0 SET @slug+=N'-';
    SET @i+=1;
  END
  WHILE RIGHT(@slug,1)=N'-' SET @slug=LEFT(@slug,LEN(@slug)-1);
  IF @slug=N'' SET @slug=N'attribute';
  DECLARE @id nvarchar(100)=@slug,@n int=2;
  WHILE EXISTS(SELECT 1 FROM wildlife.attribute x WHERE x.attribute_id=@id) BEGIN SET @id=@slug+N'-'+CONVERT(nvarchar(10),@n); SET @n+=1; END
  DECLARE @tc int=@@TRANCOUNT;
  BEGIN TRY
    IF @tc=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION wildlife_attribute_add;
    INSERT wildlife.attribute(attribute_id,revision,active,name,description) VALUES(@id,1,1,@name,@description);
    INSERT wildlife.attribute_value(attribute_id,value_id,label,ordinal) SELECT @id,value_id,label,ordinal FROM @rows;
    IF @tc=0 COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE()=-1 OR (@tc=0 AND @@TRANCOUNT>0) ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION wildlife_attribute_add;
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"CATALOG_STORAGE_UNAVAILABLE"}') AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END CATCH
  -- An attribute describes animals; adding one changes no animal's stats.
  SET @result=(SELECT @contract AS contractId,N'ADDED' AS status,
    JSON_QUERY((SELECT @id AS attributeId,1 AS revision,CONVERT(bit,1) AS active,@name AS name,@description AS description,
      JSON_QUERY(ISNULL((SELECT r.value_id AS valueId,r.label AS label FROM @rows r ORDER BY r.ordinal FOR JSON PATH),N'[]')) AS selectableValues
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS attribute,
    JSON_QUERY(N'{"applied":true,"animalStatChanges":0}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.update_animal_attribute
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-update-animal-attribute-result.v1',@code nvarchar(60)=NULL,@current int=NULL;
  DECLARE @id nvarchar(100)=JSON_VALUE(@request,N'$.attributeId'),@expected int=TRY_CONVERT(int,JSON_VALUE(@request,N'$.expectedRevision'));
  DECLARE @revision int=NULL,@active bit=NULL;
  DECLARE @a nvarchar(max)=JSON_QUERY(@request,N'$.attribute');
  DECLARE @name nvarchar(200)=JSON_VALUE(@a,N'$.name'),@description nvarchar(2000)=JSON_VALUE(@a,N'$.description'),@values nvarchar(max)=JSON_QUERY(@a,N'$.selectableValues');
  DECLARE @rows TABLE(ordinal int PRIMARY KEY,value_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,label nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,value_type int NOT NULL);
  IF @values IS NOT NULL AND LEFT(LTRIM(@values),1)=N'['
    INSERT @rows SELECT CONVERT(int,[key]),CASE WHEN [type]=5 THEN JSON_VALUE([value],N'$.valueId') END,CASE WHEN [type]=5 THEN JSON_VALUE([value],N'$.label') END,[type] FROM OPENJSON(@values);
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.user_role r WHERE r.user_id=@user_id AND r.role=N'biologist') SET @code=N'BIOLOGIST_ROLE_REQUIRED';
  ELSE IF @id IS NULL OR LEN(LTRIM(RTRIM(@id)))=0 SET @code=N'ATTRIBUTE_SELECTION_REQUIRED';
  ELSE IF @expected IS NULL SET @code=N'REVISION_REQUIRED';
  ELSE
  BEGIN
    SELECT @revision=x.revision,@active=x.active FROM wildlife.attribute x WHERE x.attribute_id=@id;
    IF @revision IS NULL SET @code=N'ANIMAL_ATTRIBUTE_NOT_FOUND';
    ELSE IF @revision<>@expected SELECT @code=N'REVISION_CONFLICT',@current=@revision;
    ELSE IF LEN(LTRIM(RTRIM(ISNULL(@name,N''))))=0 OR LEN(LTRIM(RTRIM(ISNULL(@description,N''))))=0 OR @values IS NULL OR LEFT(LTRIM(@values),1)<>N'['
      OR NOT EXISTS(SELECT 1 FROM @rows) OR EXISTS(SELECT 1 FROM @rows WHERE value_type<>5 OR LEN(LTRIM(RTRIM(ISNULL(value_id,N''))))=0 OR LEN(LTRIM(RTRIM(ISNULL(label,N''))))=0)
      SET @code=N'ANIMAL_ATTRIBUTE_INCOMPLETE';
    ELSE IF EXISTS(SELECT value_id FROM @rows GROUP BY value_id HAVING COUNT(*)>1) SET @code=N'ATTRIBUTE_VALUE_DUPLICATE';
    -- A value a definition still selects cannot be dropped here; migrating those definitions is a separate decision.
    ELSE IF EXISTS(SELECT 1 FROM wildlife.definition_attribute_value dv WHERE dv.attribute_id=@id AND NOT EXISTS(SELECT 1 FROM @rows r WHERE r.value_id=dv.value_id))
      SET @code=N'ATTRIBUTE_VALUE_IN_USE';
  END
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      @current AS currentRevision,JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  DECLARE @tc int=@@TRANCOUNT;
  BEGIN TRY
    IF @tc=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION wildlife_attribute_update;
    UPDATE wildlife.attribute SET name=@name,description=@description,revision=@revision+1 WHERE attribute_id=@id;
    DELETE wildlife.attribute_value WHERE attribute_id=@id;
    INSERT wildlife.attribute_value(attribute_id,value_id,label,ordinal) SELECT @id,value_id,label,ordinal FROM @rows;
    IF @tc=0 COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE()=-1 OR (@tc=0 AND @@TRANCOUNT>0) ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION wildlife_attribute_update;
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"CATALOG_STORAGE_UNAVAILABLE"}') AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END CATCH
  SET @result=(SELECT @contract AS contractId,N'UPDATED' AS status,
    JSON_QUERY((SELECT @id AS attributeId,@revision+1 AS revision,@active AS active,@name AS name,@description AS description,
      JSON_QUERY(ISNULL((SELECT r.value_id AS valueId,r.label AS label FROM @rows r ORDER BY r.ordinal FOR JSON PATH),N'[]')) AS selectableValues
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS attribute,
    JSON_QUERY(N'{"applied":true}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.remove_animal_attribute
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-remove-animal-attribute-result.v1',@code nvarchar(60)=NULL,@current int=NULL;
  DECLARE @id nvarchar(100)=JSON_VALUE(@request,N'$.attributeId'),@expected int=TRY_CONVERT(int,JSON_VALUE(@request,N'$.expectedRevision'));
  DECLARE @revision int=NULL,@active bit=NULL;
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.user_role r WHERE r.user_id=@user_id AND r.role=N'biologist') SET @code=N'BIOLOGIST_ROLE_REQUIRED';
  ELSE IF @id IS NULL OR LEN(LTRIM(RTRIM(@id)))=0 SET @code=N'ATTRIBUTE_SELECTION_REQUIRED';
  ELSE IF @expected IS NULL SET @code=N'REVISION_REQUIRED';
  ELSE
  BEGIN
    SELECT @revision=x.revision,@active=x.active FROM wildlife.attribute x WHERE x.attribute_id=@id;
    IF @revision IS NULL SET @code=N'ANIMAL_ATTRIBUTE_NOT_FOUND';
    ELSE IF @revision<>@expected SELECT @code=N'REVISION_CONFLICT',@current=@revision;
    ELSE IF @active=0 SET @code=N'ANIMAL_ATTRIBUTE_UNAVAILABLE';
  END
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      @current AS currentRevision,JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  -- Removal ends new selections of the attribute; definitions that reference it keep resolving it.
  DECLARE @kept int=(SELECT COUNT(*) FROM wildlife.animal_definition d
    WHERE EXISTS(SELECT 1 FROM OPENJSON(d.attributes_json) j WHERE JSON_VALUE(j.[value],N'$.attributeId')=@id));
  DECLARE @tc int=@@TRANCOUNT;
  BEGIN TRY
    IF @tc=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION wildlife_attribute_remove;
    UPDATE wildlife.attribute SET active=0,revision=@revision+1 WHERE attribute_id=@id;
    IF @tc=0 COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE()=-1 OR (@tc=0 AND @@TRANCOUNT>0) ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION wildlife_attribute_remove;
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"CATALOG_STORAGE_UNAVAILABLE"}') AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END CATCH
  SET @result=(SELECT @contract AS contractId,N'REMOVED' AS status,@id AS attributeId,CONVERT(bit,0) AS active,@revision+1 AS revision,
    JSON_QUERY((SELECT @kept AS definitionReferencesRetained FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS history,
    JSON_QUERY(N'{"applied":true}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.view_catalog_for_maintenance
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-view-catalog-for-maintenance-result.v1',@code nvarchar(60)=NULL;
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.user_role r WHERE r.user_id=@user_id AND r.role=N'biologist') SET @code=N'BIOLOGIST_ROLE_REQUIRED';
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  -- Everything a biologist maintains, with the revisions a change must name: every definition in collection-number order,
  -- active or removed, and every attribute in attributeId order with its selectable values in their order.
  DECLARE @definitions nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),x.j),N',') WITHIN GROUP (ORDER BY x.n)+N']' FROM (
      SELECT d.collection_number AS n,(SELECT d.definition_id AS definitionId,d.revision,d.active,d.common_name AS commonName,d.scientific_name AS scientificName,
        d.avatar_photo_ref AS avatarPhotoRef,d.collection_number AS collectionNumber,JSON_QUERY(d.range_json) AS [range],JSON_QUERY(d.types_json) AS types,
        JSON_QUERY(d.stats_json) AS stats,JSON_QUERY(d.attributes_json) AS attributes FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS j
      FROM wildlife.animal_definition d) x),N'[]');
  DECLARE @attributes nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),x.j),N',') WITHIN GROUP (ORDER BY x.id)+N']' FROM (
      SELECT a.attribute_id AS id,(SELECT a.attribute_id AS attributeId,a.revision,a.active,a.name,a.description,
        JSON_QUERY(ISNULL((SELECT v.value_id AS valueId,v.label AS label FROM wildlife.attribute_value v WHERE v.attribute_id=a.attribute_id ORDER BY v.ordinal FOR JSON PATH),N'[]'))
          AS selectableValues FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS j
      FROM wildlife.attribute a) x),N'[]');
  DECLARE @types nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(t.type_name,'json')+N'"'),N',') WITHIN GROUP (ORDER BY t.ordinal)+N']' FROM wildlife.animal_type t),N'[]');
  DECLARE @counties nvarchar(max)=ISNULL((SELECT c.county_id AS countyId,c.name FROM wildlife.county c ORDER BY c.county_id FOR JSON PATH),N'[]');
  DECLARE @avatars nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(p.photo_ref,'json')+N'"'),N',') WITHIN GROUP (ORDER BY p.photo_ref)+N']'
    FROM wildlife.photo p WHERE p.purpose=N'avatar' AND p.durable=1),N'[]');
  SET @result=(SELECT @contract AS contractId,N'VISIBLE' AS status,JSON_QUERY(@definitions) AS definitions,JSON_QUERY(@attributes) AS attributes,
    JSON_QUERY(@types) AS types,JSON_QUERY(@counties) AS counties,JSON_QUERY(@avatars) AS avatarPhotoRefs FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.resolve_wildlife_access
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-resolve-wildlife-access-result.v1',@code nvarchar(60)=NULL;
  DECLARE @section nvarchar(100)=JSON_VALUE(@request,N'$.section');
  -- Section access from the user's current, externally assigned roles: the personal sections for citizens and
  -- biologists alike, the catalog administration for biologists only. It is resolved on every request.
  DECLARE @sections TABLE(section nvarchar(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,biologist_only bit NOT NULL,permissions nvarchar(400) NOT NULL);
  INSERT @sections VALUES
    (N'collection',0,N'["browse-collection","view-animal"]'),
    (N'collected-animals',0,N'["view-collected-animals","upload-photo","record-encounter"]'),
    (N'team',0,N'["view-team","set-team"]'),
    (N'home',0,N'["view-home"]'),
    (N'animal-definitions-admin',1,N'["add-definition","update-definition","remove-definition"]'),
    (N'animal-attributes-admin',1,N'["add-attribute","update-attribute","remove-attribute"]');
  DECLARE @biologist_only bit=NULL,@permissions nvarchar(400)=NULL;
  SELECT @biologist_only=s.biologist_only,@permissions=s.permissions FROM @sections s WHERE s.section=@section;
  IF @biologist_only IS NULL SET @code=N'SECTION_UNKNOWN';
  ELSE IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF @biologist_only=1 AND NOT EXISTS(SELECT 1 FROM wildlife.user_role r WHERE r.user_id=@user_id AND r.role=N'biologist') SET @code=N'BIOLOGIST_ROLE_REQUIRED';
  ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.user_role r WHERE r.user_id=@user_id AND r.role IN (N'citizen',N'biologist')) SET @code=N'WILDLIFE_ROLE_REQUIRED';
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  SET @result=(SELECT @contract AS contractId,N'ALLOWED' AS status,@section AS section,JSON_QUERY(@permissions) AS permissions FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.invoke_operation
  @operation nvarchar(100),@request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @tc int=@@TRANCOUNT;
  BEGIN TRY
    IF @operation=N'nerdery-browse-animal-collection' EXEC wildlife.browse_animal_collection @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-view-animal-definition' EXEC wildlife.view_animal_definition @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-view-collected-animals' EXEC wildlife.view_collected_animals @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-view-collected-animal' EXEC wildlife.view_collected_animal @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-view-wildlife-home' EXEC wildlife.view_wildlife_home @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-upload-encounter-photo' EXEC wildlife.upload_encounter_photo @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-record-animal-encounter' EXEC wildlife.record_animal_encounter @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-set-animal-team' EXEC wildlife.set_animal_team @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-add-animal-definition' EXEC wildlife.add_animal_definition @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-update-animal-definition' EXEC wildlife.update_animal_definition @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-remove-animal-definition' EXEC wildlife.remove_animal_definition @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-add-animal-attribute' EXEC wildlife.add_animal_attribute @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-update-animal-attribute' EXEC wildlife.update_animal_attribute @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-remove-animal-attribute' EXEC wildlife.remove_animal_attribute @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-view-catalog-for-maintenance' EXEC wildlife.view_catalog_for_maintenance @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-resolve-wildlife-access' EXEC wildlife.resolve_wildlife_access @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE SET @result=(SELECT N'REFUSED' AS status,JSON_QUERY(N'{"code":"OPERATION_NOT_DECLARED"}') AS reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END TRY
  BEGIN CATCH
    -- A store that cannot be read or written answers the operation's own storage refusal; nothing is kept.
    IF @@TRANCOUNT>@tc ROLLBACK TRANSACTION;
    DECLARE @write bit=CASE WHEN @operation IN (N'nerdery-upload-encounter-photo',N'nerdery-record-animal-encounter',N'nerdery-set-animal-team',N'nerdery-add-animal-definition',
      N'nerdery-update-animal-definition',N'nerdery-remove-animal-definition',N'nerdery-add-animal-attribute',N'nerdery-update-animal-attribute',N'nerdery-remove-animal-attribute') THEN 1 ELSE 0 END;
    SET @result=(SELECT @operation+N'-result.v1' AS contractId,N'REFUSED' AS status,
      JSON_QUERY((SELECT CASE @operation
        WHEN N'nerdery-upload-encounter-photo' THEN N'PHOTO_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-record-animal-encounter' THEN N'COLLECTION_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-view-collected-animals' THEN N'COLLECTION_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-view-collected-animal' THEN N'COLLECTION_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-set-animal-team' THEN N'TEAM_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-view-wildlife-home' THEN N'TEAM_STORAGE_UNAVAILABLE'
        ELSE N'CATALOG_STORAGE_UNAVAILABLE' END AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      JSON_QUERY(CASE WHEN @write=1 THEN N'{"applied":false}' END) AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END CATCH
END;
GO
SET NOCOUNT ON;
DECLARE @p uniqueidentifier='565de6d4-ebcd-408b-9359-04d21dc62183';
DECLARE @digests TABLE(object_name nvarchar(200),digest varchar(80));
DECLARE @v0 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.update_animal_definition')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v0=SUBSTRING(@v0,CHARINDEX(N'PROCEDURE wildlife.update_animal_definition',@v0),DATALENGTH(@v0)/2);
WHILE DATALENGTH(@v0)>0 AND RIGHT(@v0,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v0=LEFT(@v0,DATALENGTH(@v0)/2-1);
DECLARE @v0_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v0 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.update_animal_definition',@v0_digest);
DECLARE @v1 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.remove_animal_definition')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v1=SUBSTRING(@v1,CHARINDEX(N'PROCEDURE wildlife.remove_animal_definition',@v1),DATALENGTH(@v1)/2);
WHILE DATALENGTH(@v1)>0 AND RIGHT(@v1,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v1=LEFT(@v1,DATALENGTH(@v1)/2-1);
DECLARE @v1_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v1 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.remove_animal_definition',@v1_digest);
DECLARE @v2 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.add_animal_attribute')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v2=SUBSTRING(@v2,CHARINDEX(N'PROCEDURE wildlife.add_animal_attribute',@v2),DATALENGTH(@v2)/2);
WHILE DATALENGTH(@v2)>0 AND RIGHT(@v2,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v2=LEFT(@v2,DATALENGTH(@v2)/2-1);
DECLARE @v2_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v2 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.add_animal_attribute',@v2_digest);
DECLARE @v3 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.update_animal_attribute')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v3=SUBSTRING(@v3,CHARINDEX(N'PROCEDURE wildlife.update_animal_attribute',@v3),DATALENGTH(@v3)/2);
WHILE DATALENGTH(@v3)>0 AND RIGHT(@v3,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v3=LEFT(@v3,DATALENGTH(@v3)/2-1);
DECLARE @v3_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v3 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.update_animal_attribute',@v3_digest);
DECLARE @v4 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.remove_animal_attribute')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v4=SUBSTRING(@v4,CHARINDEX(N'PROCEDURE wildlife.remove_animal_attribute',@v4),DATALENGTH(@v4)/2);
WHILE DATALENGTH(@v4)>0 AND RIGHT(@v4,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v4=LEFT(@v4,DATALENGTH(@v4)/2-1);
DECLARE @v4_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v4 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.remove_animal_attribute',@v4_digest);
DECLARE @v5 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.view_catalog_for_maintenance')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v5=SUBSTRING(@v5,CHARINDEX(N'PROCEDURE wildlife.view_catalog_for_maintenance',@v5),DATALENGTH(@v5)/2);
WHILE DATALENGTH(@v5)>0 AND RIGHT(@v5,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v5=LEFT(@v5,DATALENGTH(@v5)/2-1);
DECLARE @v5_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v5 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.view_catalog_for_maintenance',@v5_digest);
DECLARE @v6 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.resolve_wildlife_access')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v6=SUBSTRING(@v6,CHARINDEX(N'PROCEDURE wildlife.resolve_wildlife_access',@v6),DATALENGTH(@v6)/2);
WHILE DATALENGTH(@v6)>0 AND RIGHT(@v6,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v6=LEFT(@v6,DATALENGTH(@v6)/2-1);
DECLARE @v6_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v6 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.resolve_wildlife_access',@v6_digest);
DECLARE @v7 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.invoke_operation')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v7=SUBSTRING(@v7,CHARINDEX(N'PROCEDURE wildlife.invoke_operation',@v7),DATALENGTH(@v7)/2);
WHILE DATALENGTH(@v7)>0 AND RIGHT(@v7,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v7=LEFT(@v7,DATALENGTH(@v7)/2-1);
DECLARE @v7_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v7 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.invoke_operation',@v7_digest);
DECLARE @want TABLE(object_name nvarchar(200),digest varchar(80)); INSERT @want VALUES(N'wildlife.update_animal_definition','sha256:bc0ab5e42dafa0b2950eeba76cdd98a79a8f82befc984639c5a8756a5bdc7c5d'),(N'wildlife.remove_animal_definition','sha256:dee2ca38c51e9d82c0e63ac0f65a129ca6347c643fd3d164bbe0e1c809b31a6b'),(N'wildlife.add_animal_attribute','sha256:cc4bace433b2cc66d13200ae590c503feeff76270767d6f6a9413e1b2e3f4d46'),(N'wildlife.update_animal_attribute','sha256:2ba8570a5f2f5868d533b077476987e5f9b2533056c1af63eac62b5f477f1ae7'),(N'wildlife.remove_animal_attribute','sha256:8c29326bd9900deda3d471adaf32ac5488feb5727a7663abe17551616914ecae'),(N'wildlife.view_catalog_for_maintenance','sha256:ac696a1e161d09a26e3e9ee93bb95c4e62b12cdf9f3a0ec78bc4a8c4cca2266c'),(N'wildlife.resolve_wildlife_access','sha256:677666483faf95b32a2a85d03f5bd987de5afe2e8607e4a69b4d320d5c404625'),(N'wildlife.invoke_operation','sha256:94124fa6bbda90585043ea20977906dabd620c2bec1649e0dae896b5ce362abc');
SELECT N'verify' AS result_set,w.object_name,w.digest AS reviewed,d.digest AS installed,CASE WHEN d.digest=w.digest THEN 1 ELSE 0 END AS digest_matches FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name ORDER BY w.object_name;
DECLARE @smoke TABLE(o int IDENTITY(1,1),item nvarchar(200),actual nvarchar(400),expected nvarchar(400),passed bit);
DECLARE @r nvarchar(max);
DECLARE @before varchar(64)=CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(SELECT (SELECT * FROM wildlife.attribute ORDER BY attribute_id FOR JSON PATH) AS a,(SELECT definition_id,revision,active FROM wildlife.animal_definition ORDER BY definition_id FOR JSON PATH) AS d FOR JSON PATH,WITHOUT_ARRAY_WRAPPER))),2);
EXEC wildlife.invoke_operation @operation=N'nerdery-view-catalog-for-maintenance',@request=N'{}',@user_id=N'user-bio',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Casey reads the catalog for maintenance: $.status',JSON_VALUE(@r,N'$.status'),N'VISIBLE',CASE WHEN JSON_VALUE(@r,N'$.status')=N'VISIBLE' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'Casey reads the catalog for maintenance: $.definitions[0].definitionId',JSON_VALUE(@r,N'$.definitions[0].definitionId'),N'animal-001',CASE WHEN JSON_VALUE(@r,N'$.definitions[0].definitionId')=N'animal-001' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-view-catalog-for-maintenance',@request=N'{}',@user_id=N'user-b',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Blake reads the catalog for maintenance: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'BIOLOGIST_ROLE_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'BIOLOGIST_ROLE_REQUIRED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-resolve-wildlife-access',@request=N'{"section":"animal-definitions-admin"}',@user_id=N'user-bio',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Casey opens the definitions administration: $.status',JSON_VALUE(@r,N'$.status'),N'ALLOWED',CASE WHEN JSON_VALUE(@r,N'$.status')=N'ALLOWED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-resolve-wildlife-access',@request=N'{"section":"animal-definitions-admin"}',@user_id=N'user-b',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Blake opens the definitions administration: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'BIOLOGIST_ROLE_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'BIOLOGIST_ROLE_REQUIRED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-resolve-wildlife-access',@request=N'{"section":"team"}',@user_id=N'user-b',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Blake opens his team: $.status',JSON_VALUE(@r,N'$.status'),N'ALLOWED',CASE WHEN JSON_VALUE(@r,N'$.status')=N'ALLOWED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-remove-animal-attribute',@request=N'{"attributeId":"habitat","expectedRevision":1}',@user_id=N'user-b',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Blake removes an attribute: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'BIOLOGIST_ROLE_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'BIOLOGIST_ROLE_REQUIRED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-update-animal-attribute',@request=N'{"attributeId":"habitat","expectedRevision":0,"attribute":{"name":"x","description":"x","selectableValues":[{"valueId":"x","label":"x"}]}}',@user_id=N'user-bio',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Casey edits from a stale revision: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'REVISION_CONFLICT',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'REVISION_CONFLICT' THEN 1 ELSE 0 END);
DECLARE @after varchar(64)=CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(SELECT (SELECT * FROM wildlife.attribute ORDER BY attribute_id FOR JSON PATH) AS a,(SELECT definition_id,revision,active FROM wildlife.animal_definition ORDER BY definition_id FOR JSON PATH) AS d FOR JSON PATH,WITHOUT_ARRAY_WRAPPER))),2);
INSERT @smoke(item,actual,expected,passed) VALUES(N'the refused and read calls changed no catalog row',@after,@before,CASE WHEN @after=@before THEN 1 ELSE 0 END);
SELECT N'smoke' AS result_set,item,actual,expected,passed FROM @smoke ORDER BY o;
IF EXISTS(SELECT 1 FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name WHERE d.digest IS NULL OR d.digest<>w.digest) OR EXISTS(SELECT 1 FROM @smoke WHERE passed=0)
BEGIN
 RAISERROR(N'CATALOG2_VERIFY_FAILED: an installed body is not the reviewed text, or a call did not answer as tested; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
IF NOT EXISTS(SELECT 1 FROM wildlife.user_role WHERE user_id=N'user-a' AND role=N'biologist') INSERT wildlife.user_role(user_id,role) VALUES(N'user-a',N'biologist');
SELECT N'roles' AS result_set,user_id,role FROM wildlife.user_role WHERE user_id=N'user-a' ORDER BY role;
IF (SELECT COUNT(*) FROM wildlife.user_role WHERE user_id=N'user-a' AND role IN (N'citizen',N'biologist'))<>2
BEGIN
 RAISERROR(N'CATALOG2_ROLES_FAILED: Avery does not hold both the citizen and the biologist role; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
DECLARE @plans TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));
INSERT @plans EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=N'claude-code-opus-5-5-nerdery-slice',@objective=N'Declare the catalog maintenance and section access of the Nerdery wildlife application, feature first through OV3''s own changes: nerdery-update-animal-definition, nerdery-remove-animal-definition, nerdery-add-animal-attribute, nerdery-update-animal-attribute, nerdery-remove-animal-attribute, nerdery-resolve-wildlife-access and nerdery-view-catalog-for-maintenance, each with capability-from-dsl, which binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT; prove each stored document is exactly the reviewed one by its digest.',
 @steps_json=N'[{"stepId":"plan-header","contractId":"estate-flight-plan.v1","promiseId":"nerdery-catalog-maintenance-and-access","flightType":"execution","workClass":"owner-objective","unknowns":[]},{"stepId":"declare-update-animal-definition","capabilityId":"apply-declared-change","historicalBasis":"the slice''s capabilities and nerdery-view-collected-animal were declared this way by capability-from-dsl (flight 9810b9af and the photo flight, plan sha256:aa443b90); this DSL compiles COMPILED to sha256:d233ad634537615b209520768f2e4be93e3dd525000c87a6f682075fba533d28 against the retained bytes of its feature with the installed compiler (read-only run 23fd22c6), and its operation''s mechanics met every case of that feature read-only (runs 869e7203, 669ba146, dce56efb)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-update-animal-definition\nfeature nerdery-update-animal-definition sha256:22c39f030ea82bbb8eb05729aef5e2fe4bc2de624c03dc6403f1426719bd3791\nintent: Update an animal definition, for the caller whose session the declared API operation verified (Nerdery wildlife application)\noutcome: nerdery-update-animal-definition-result.v1 UPDATED or REFUSED, each refusal named by its reason code, so that the catalog reflects the maintained wildlife information\ninput contract nerdery-update-animal-definition-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-update-animal-definition-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-update-animal-definition-result.v1\"},\"status\":{\"enum\":[\"UPDATED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-update-animal-definition root terminal\ngiven: an animal definition identity and its proposed replacement properties\nwhen: the animal definition is updated by the authenticated user\nthen: the updated animal definition is available or a named refusal preserves the existing definition\noperation nerdery-update-animal-definition.update uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-update-animal-definition'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-update-animal-definition $\noutcome from nerdery-update-animal-definition.update $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O1"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-update-animal-definition","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler''s documentDigest for the same source (the repair flights and the photo flight proved theirs this way)","input":{"capabilityId":"nerdery-update-animal-definition"},"obligationIds":["O1"],"expect":{"path":"$.documentDigest","equals":"sha256:d233ad634537615b209520768f2e4be93e3dd525000c87a6f682075fba533d28"}},{"stepId":"declare-remove-animal-definition","capabilityId":"apply-declared-change","historicalBasis":"the slice''s capabilities and nerdery-view-collected-animal were declared this way by capability-from-dsl (flight 9810b9af and the photo flight, plan sha256:aa443b90); this DSL compiles COMPILED to sha256:d9a56175a0ceadc83e954266c801270f602c02eab30e49b0eebfc300a3527d5a against the retained bytes of its feature with the installed compiler (read-only run 54926d90), and its operation''s mechanics met every case of that feature read-only (runs 869e7203, 669ba146, dce56efb)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-remove-animal-definition\nfeature nerdery-remove-animal-definition sha256:7592d131f3d89a452c1d3292973478a7ab979188f9e453e6a0551d3a458065b2\nintent: Remove an animal definition from the active catalog, for the caller whose session the declared API operation verified (Nerdery wildlife application)\noutcome: nerdery-remove-animal-definition-result.v1 REMOVED or REFUSED, each refusal named by its reason code, so that the active catalog no longer offers that definition\ninput contract nerdery-remove-animal-definition-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-remove-animal-definition-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-remove-animal-definition-result.v1\"},\"status\":{\"enum\":[\"REMOVED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-remove-animal-definition root terminal\ngiven: an animal definition identity requested for removal\nwhen: the animal definition is removed by the authenticated user\nthen: the definition is absent from the active catalog or a named refusal leaves it unchanged\noperation nerdery-remove-animal-definition.remove uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-remove-animal-definition'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-remove-animal-definition $\noutcome from nerdery-remove-animal-definition.remove $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O2"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-remove-animal-definition","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler''s documentDigest for the same source (the repair flights and the photo flight proved theirs this way)","input":{"capabilityId":"nerdery-remove-animal-definition"},"obligationIds":["O2"],"expect":{"path":"$.documentDigest","equals":"sha256:d9a56175a0ceadc83e954266c801270f602c02eab30e49b0eebfc300a3527d5a"}},{"stepId":"declare-add-animal-attribute","capabilityId":"apply-declared-change","historicalBasis":"the slice''s capabilities and nerdery-view-collected-animal were declared this way by capability-from-dsl (flight 9810b9af and the photo flight, plan sha256:aa443b90); this DSL compiles COMPILED to sha256:35d6f9c153b73c0404a7d2c7ce312116e1b65b57d0829d2632110939d10fbb01 against the retained bytes of its feature with the installed compiler (read-only run 2e2e96a2), and its operation''s mechanics met every case of that feature read-only (runs 869e7203, 669ba146, dce56efb)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-add-animal-attribute\nfeature nerdery-add-animal-attribute sha256:45eed6cbd0664d8e0e2a63bc8cd9e89ac9618ab23052034eb2d41e25bfb6624a\nintent: Add a reusable animal attribute, for the caller whose session the declared API operation verified (Nerdery wildlife application)\noutcome: nerdery-add-animal-attribute-result.v1 ADDED or REFUSED, each refusal named by its reason code, so that the same property can describe one or many animals\ninput contract nerdery-add-animal-attribute-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-add-animal-attribute-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-add-animal-attribute-result.v1\"},\"status\":{\"enum\":[\"ADDED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-add-animal-attribute root terminal\ngiven: a proposed animal attribute\nwhen: the animal attribute is added by the authenticated user\nthen: the attribute is available for animal definitions or a named refusal explains why it was not added\noperation nerdery-add-animal-attribute.add uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-add-animal-attribute'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-add-animal-attribute $\noutcome from nerdery-add-animal-attribute.add $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O3"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-add-animal-attribute","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler''s documentDigest for the same source (the repair flights and the photo flight proved theirs this way)","input":{"capabilityId":"nerdery-add-animal-attribute"},"obligationIds":["O3"],"expect":{"path":"$.documentDigest","equals":"sha256:35d6f9c153b73c0404a7d2c7ce312116e1b65b57d0829d2632110939d10fbb01"}},{"stepId":"declare-update-animal-attribute","capabilityId":"apply-declared-change","historicalBasis":"the slice''s capabilities and nerdery-view-collected-animal were declared this way by capability-from-dsl (flight 9810b9af and the photo flight, plan sha256:aa443b90); this DSL compiles COMPILED to sha256:eda0c93e20cc3494b87b6b988c3ad5290c07b2c3f437dc271badb34ad2f5d483 against the retained bytes of its feature with the installed compiler (read-only run 3c354cd6), and its operation''s mechanics met every case of that feature read-only (runs 869e7203, 669ba146, dce56efb)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-update-animal-attribute\nfeature nerdery-update-animal-attribute sha256:ddf61a8f55fda90100bbc1412d9837a2b96e0b5203f4f0d36c533dc7f8d01576\nintent: Update a reusable animal attribute, for the caller whose session the declared API operation verified (Nerdery wildlife application)\noutcome: nerdery-update-animal-attribute-result.v1 UPDATED or REFUSED, each refusal named by its reason code, so that animals continue to reference a coherent shared property\ninput contract nerdery-update-animal-attribute-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-update-animal-attribute-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-update-animal-attribute-result.v1\"},\"status\":{\"enum\":[\"UPDATED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-update-animal-attribute root terminal\ngiven: an animal attribute identity and proposed replacement properties\nwhen: the animal attribute is updated by the authenticated user\nthen: the updated attribute is available or a named refusal preserves the existing attribute\noperation nerdery-update-animal-attribute.update uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-update-animal-attribute'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-update-animal-attribute $\noutcome from nerdery-update-animal-attribute.update $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O4"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-update-animal-attribute","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler''s documentDigest for the same source (the repair flights and the photo flight proved theirs this way)","input":{"capabilityId":"nerdery-update-animal-attribute"},"obligationIds":["O4"],"expect":{"path":"$.documentDigest","equals":"sha256:eda0c93e20cc3494b87b6b988c3ad5290c07b2c3f437dc271badb34ad2f5d483"}},{"stepId":"declare-remove-animal-attribute","capabilityId":"apply-declared-change","historicalBasis":"the slice''s capabilities and nerdery-view-collected-animal were declared this way by capability-from-dsl (flight 9810b9af and the photo flight, plan sha256:aa443b90); this DSL compiles COMPILED to sha256:c0bddb3d44760553adef2fd47c5acd0b1cc83e3a6cdb7865f6a3f8199d7c4334 against the retained bytes of its feature with the installed compiler (read-only run 48ec1966), and its operation''s mechanics met every case of that feature read-only (runs 869e7203, 669ba146, dce56efb)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-remove-animal-attribute\nfeature nerdery-remove-animal-attribute sha256:f7c98d58559233a51b925663f3c6e37eb8cc0891c09789cfa845e69f011f24ed\nintent: Remove an animal attribute from active use, for the caller whose session the declared API operation verified (Nerdery wildlife application)\noutcome: nerdery-remove-animal-attribute-result.v1 REMOVED or REFUSED, each refusal named by its reason code, so that the active attribute catalog no longer offers it\ninput contract nerdery-remove-animal-attribute-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-remove-animal-attribute-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-remove-animal-attribute-result.v1\"},\"status\":{\"enum\":[\"REMOVED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-remove-animal-attribute root terminal\ngiven: an animal attribute identity requested for removal\nwhen: the animal attribute is removed by the authenticated user\nthen: the attribute is absent from active selection or a named refusal leaves it unchanged\noperation nerdery-remove-animal-attribute.remove uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-remove-animal-attribute'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-remove-animal-attribute $\noutcome from nerdery-remove-animal-attribute.remove $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O5"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-remove-animal-attribute","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler''s documentDigest for the same source (the repair flights and the photo flight proved theirs this way)","input":{"capabilityId":"nerdery-remove-animal-attribute"},"obligationIds":["O5"],"expect":{"path":"$.documentDigest","equals":"sha256:c0bddb3d44760553adef2fd47c5acd0b1cc83e3a6cdb7865f6a3f8199d7c4334"}},{"stepId":"declare-resolve-wildlife-access","capabilityId":"apply-declared-change","historicalBasis":"the slice''s capabilities and nerdery-view-collected-animal were declared this way by capability-from-dsl (flight 9810b9af and the photo flight, plan sha256:aa443b90); this DSL compiles COMPILED to sha256:335ef2af50f211bd846c403e9465299c989259114f34769bb4a3733014654c2e against the retained bytes of its feature with the installed compiler (read-only run 69ecbca8), and its operation''s mechanics met every case of that feature read-only (runs 869e7203, 669ba146, dce56efb)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-resolve-wildlife-access\nfeature nerdery-resolve-wildlife-access sha256:c5ced02e926c301edb4ef7bdfc1a928330377ac85d38e5986f31b1f8b3b51b77\nintent: Resolve access to wildlife application sections, for the caller whose session the declared API operation verified (Nerdery wildlife application)\noutcome: nerdery-resolve-wildlife-access-result.v1 ALLOWED or REFUSED, each refusal named by its reason code, so that I can use the appropriate experiences without gaining unintended privileges\ninput contract nerdery-resolve-wildlife-access-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-resolve-wildlife-access-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-resolve-wildlife-access-result.v1\"},\"status\":{\"enum\":[\"ALLOWED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-resolve-wildlife-access root terminal\ngiven: a requested wildlife application section\nwhen: access to the section is resolved for the authenticated user\nthen: the requested section is available or the access refusal is known\noperation nerdery-resolve-wildlife-access.resolve uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-resolve-wildlife-access'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-resolve-wildlife-access $\noutcome from nerdery-resolve-wildlife-access.resolve $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O6"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-resolve-wildlife-access","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler''s documentDigest for the same source (the repair flights and the photo flight proved theirs this way)","input":{"capabilityId":"nerdery-resolve-wildlife-access"},"obligationIds":["O6"],"expect":{"path":"$.documentDigest","equals":"sha256:335ef2af50f211bd846c403e9465299c989259114f34769bb4a3733014654c2e"}},{"stepId":"declare-view-catalog-for-maintenance","capabilityId":"apply-declared-change","historicalBasis":"the slice''s capabilities and nerdery-view-collected-animal were declared this way by capability-from-dsl (flight 9810b9af and the photo flight, plan sha256:aa443b90); this DSL compiles COMPILED to sha256:80a4daab4d372f2a4025313631beb63bb96309f0f200268da49b88ab46ac3756 against the retained bytes of its feature with the installed compiler (read-only run a6f0c470), and its operation''s mechanics met every case of that feature read-only (runs 869e7203, 669ba146, dce56efb)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-view-catalog-for-maintenance\nfeature nerdery-view-catalog-for-maintenance sha256:3e403f869f8ac663beee431b1cf999996c824a53e24af3f9d3e1b03d30710a1b\nintent: View the catalog for maintenance, for the caller whose session the declared API operation verified (Nerdery wildlife application)\noutcome: nerdery-view-catalog-for-maintenance-result.v1 VISIBLE or REFUSED, each refusal named by its reason code, so that I can change or remove one from the revision I saw\ninput contract nerdery-view-catalog-for-maintenance-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-view-catalog-for-maintenance-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-view-catalog-for-maintenance-result.v1\"},\"status\":{\"enum\":[\"VISIBLE\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-view-catalog-for-maintenance root terminal\ngiven: a request to view the catalog for maintenance\nwhen: the catalog is read for maintenance by the authenticated user\nthen: the user can view the catalog with its revisions or a named refusal\noperation nerdery-view-catalog-for-maintenance.view uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-view-catalog-for-maintenance'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-view-catalog-for-maintenance $\noutcome from nerdery-view-catalog-for-maintenance.view $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O7"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-view-catalog-for-maintenance","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler''s documentDigest for the same source (the repair flights and the photo flight proved theirs this way)","input":{"capabilityId":"nerdery-view-catalog-for-maintenance"},"obligationIds":["O7"],"expect":{"path":"$.documentDigest","equals":"sha256:80a4daab4d372f2a4025313631beb63bb96309f0f200268da49b88ab46ac3756"}}]';
SELECT N'plans' AS result_set,N'claude-code-opus-5-5-nerdery-slice' AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'0442d1cbd50c5944662d30d85027fdd9fef4cf928ad558a8a8693b996c99b50f',2) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @plans;
IF NOT EXISTS(SELECT 1 FROM @plans WHERE plan_digest=CONVERT(binary(32),'0442d1cbd50c5944662d30d85027fdd9fef4cf928ad558a8a8693b996c99b50f',2))
BEGIN
 RAISERROR(N'CATALOG2_PLAN_MISMATCH: the recorded plan is not the reviewed one; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
ROLLBACK TRANSACTION;
GO
SET NOEXEC OFF;
