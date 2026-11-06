-- fast-2-identity.commit.sql
--
-- ============================== COMMIT - THIS WRITES ==============================
-- Byte-identical to the preflight twin except this banner and the terminal statement:
-- COMMIT TRANSACTION here, ROLLBACK TRANSACTION there. The preflight is optional: this file verifies everything inside
-- its transaction and keeps nothing when a check fails.
--
-- WHAT THIS DOES, in one transaction on the sfx-identity database:
--   1. installs the wildlife store of the Nerdery citizen slice: schema wildlife, 14 tables, 10 procedures and the synthetic
--      seed (nrd-01's batches); Avery (citizen) is the owner's principal and starts with no encounters; verified by body
--      digest, seed counts and smoke calls, including an anonymous and a forged caller;
--   2. records the plan of flight nerdery-citizen-slice-build under planner agent claude-code-opus-5-5-nerdery-slice through evidence.upsert_flight_plan:
--      install and declare the check, then declare the eight slice capabilities, each with its pin read back.
--      The plan is nerdery/flights/fast-path.steps.json; its digest is sha256:8ffc4ac2cab7fec7524ebd222f6696070f94d6c6f11e6668715c24e1489bcd1f.
-- RUN fast-1-estate FIRST. WHERE: sfx-identity. Run the whole file in one session (a few seconds).
-- GUARDS: no schema wildlife yet; the identity tables exist; the owner principal is active; the plan writer has its four
-- parameters. RESULT SETS: base; verify; smoke (every passed 1); plans (matches_reviewed_file 1).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @schema int=SCHEMA_ID(N'wildlife'),@session int=CASE WHEN OBJECT_ID(N'[identity].session') IS NOT NULL AND OBJECT_ID(N'[identity].principal') IS NOT NULL THEN 1 ELSE 0 END,
 @owner int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id='565de6d4-ebcd-408b-9359-04d21dc62183' AND active=1),
 @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));
SELECT N'base' AS result_set,@schema AS wildlife_schema_id,@session AS identity_tables,@owner AS owner_principal_active,@params AS plan_writer_parameters;
IF @schema IS NOT NULL OR @session<>1 OR @owner<>1 OR @params<>4
BEGIN
 RAISERROR(N'FAST2_BASE: the schema wildlife already exists, or the identity tables, the owner principal or the plan writer are not as reviewed; nothing is changed.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
EXEC(N'CREATE SCHEMA wildlife AUTHORIZATION dbo');
GO
CREATE TABLE wildlife.app_user(
  user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  principal_id uniqueidentifier NULL,
  identity_subject nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL UNIQUE,
  first_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  last_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  email nvarchar(320) COLLATE Latin1_General_100_CI_AS NOT NULL UNIQUE);
CREATE UNIQUE INDEX UX_wildlife_app_user_principal ON wildlife.app_user(principal_id) WHERE principal_id IS NOT NULL;
CREATE TABLE wildlife.user_role(
  user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  role nvarchar(40) COLLATE Latin1_General_100_BIN2 NOT NULL,
  PRIMARY KEY(user_id,role));
CREATE TABLE wildlife.county(
  county_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL);
CREATE TABLE wildlife.animal_type(
  type_name nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  ordinal int NOT NULL);
CREATE TABLE wildlife.attribute(
  attribute_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  revision int NOT NULL,
  active bit NOT NULL,
  name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  description nvarchar(2000) COLLATE Latin1_General_100_BIN2 NOT NULL);
CREATE TABLE wildlife.attribute_value(
  attribute_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  value_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  label nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  ordinal int NOT NULL,
  PRIMARY KEY(attribute_id,value_id));
CREATE TABLE wildlife.animal_definition(
  definition_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  revision int NOT NULL,
  active bit NOT NULL,
  common_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  scientific_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NOT NULL,
  avatar_photo_ref nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  collection_number int NOT NULL UNIQUE,
  range_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
  types_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
  stats_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
  attributes_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
CREATE TABLE wildlife.definition_county(
  definition_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  county_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  PRIMARY KEY(definition_id,county_id));
CREATE TABLE wildlife.definition_type(
  definition_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  type_name nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  PRIMARY KEY(definition_id,type_name));
CREATE TABLE wildlife.definition_attribute_value(
  definition_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  attribute_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  value_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  PRIMARY KEY(definition_id,attribute_id,value_id));
CREATE TABLE wildlife.photo(
  photo_ref nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  owner_user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,
  purpose nvarchar(20) COLLATE Latin1_General_100_BIN2 NOT NULL,
  media_type nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  content_sha256 binary(32) NOT NULL,
  content_bytes varbinary(max) NULL,
  byte_length bigint NULL,
  durable bit NOT NULL);
CREATE TABLE wildlife.encounter(
  owner_user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  encounter_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  definition_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  location_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
  photo_ref nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  nickname nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,
  PRIMARY KEY(owner_user_id,encounter_id));
CREATE TABLE wildlife.team(
  owner_user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  revision int NOT NULL);
CREATE TABLE wildlife.team_member(
  owner_user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  ordinal int NOT NULL,
  encounter_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  PRIMARY KEY(owner_user_id,ordinal),
  UNIQUE(owner_user_id,encounter_id));
GO
CREATE OR ALTER PROCEDURE wildlife.browse_animal_collection
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-browse-animal-collection-result.v1';
  IF @user_id IS NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"AUTHENTICATION_REQUIRED"}') AS reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  -- D04: a case-insensitive common-name substring; an all-digit query also matches that collection number. Locked
  -- fields are never searched.
  DECLARE @search nvarchar(200)=LTRIM(RTRIM(ISNULL(JSON_VALUE(@request,N'$.search'),N'')));
  DECLARE @number int=CASE WHEN @search<>N'' AND @search NOT LIKE N'%[^0-9]%' AND LEN(@search)<=9 THEN CONVERT(int,@search) END;
  DECLARE @items TABLE(ordinal int NOT NULL PRIMARY KEY,item nvarchar(max) NOT NULL);
  INSERT @items(ordinal,item)
  SELECT d.collection_number,
    (SELECT d.definition_id AS definitionId,CASE WHEN c.collected=1 THEN N'COLLECTED' ELSE N'UNCOLLECTED' END AS collectionState,
       JSON_QUERY(CASE WHEN c.collected=1
         THEN (SELECT d.common_name AS commonName,d.collection_number AS collectionNumber,JSON_QUERY(d.range_json) AS [range],d.avatar_photo_ref AS avatarPhotoRef,
                 d.scientific_name AS scientificName,JSON_QUERY(d.types_json) AS types,JSON_QUERY(d.stats_json) AS stats,JSON_QUERY(d.attributes_json) AS attributes
               FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
         ELSE (SELECT d.common_name AS commonName,d.collection_number AS collectionNumber,JSON_QUERY(d.range_json) AS [range],d.avatar_photo_ref AS avatarPhotoRef
               FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) END) AS animal
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
  FROM wildlife.animal_definition d
  CROSS APPLY (SELECT CASE WHEN EXISTS(SELECT 1 FROM wildlife.encounter e WHERE e.owner_user_id=@user_id AND e.definition_id=d.definition_id) THEN 1 ELSE 0 END AS collected) c
  WHERE d.active=1 AND (@search=N'' OR CHARINDEX(LOWER(@search),LOWER(d.common_name))>0 OR d.collection_number=@number);
  SET @result=(SELECT @contract AS contractId,N'LISTED' AS status,@search AS search,(SELECT COUNT(*) FROM @items) AS total,
    JSON_QUERY(ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),item),N',') WITHIN GROUP (ORDER BY ordinal)+N']' FROM @items),N'[]')) AS items
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.view_animal_definition
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-view-animal-definition-result.v1',@code nvarchar(60)=NULL;
  DECLARE @id nvarchar(100)=JSON_VALUE(@request,N'$.definitionId');
  DECLARE @active bit=NULL,@collected bit=0;
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF @id IS NULL SET @code=N'ANIMAL_SELECTION_REQUIRED';
  ELSE
  BEGIN
    SELECT @active=d.active FROM wildlife.animal_definition d WHERE d.definition_id=@id;
    IF @active IS NULL SET @code=N'ANIMAL_DEFINITION_NOT_FOUND';
    ELSE IF @active=0 SET @code=N'ANIMAL_DEFINITION_UNAVAILABLE';
  END
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  IF EXISTS(SELECT 1 FROM wildlife.encounter e WHERE e.owner_user_id=@user_id AND e.definition_id=@id) SET @collected=1;
  -- D14: resolved attribute details are ordered by attributeId; selected values keep their selectable order.
  DECLARE @details TABLE(attribute_id nvarchar(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,j nvarchar(max) NOT NULL);
  IF @collected=1
    INSERT @details(attribute_id,j)
    SELECT a.attribute_id,(SELECT a.attribute_id AS attributeId,a.name AS name,a.description AS description,JSON_QUERY(sv.values_json) AS selectedValues FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
    FROM wildlife.attribute a
    CROSS APPLY (SELECT N'['+ISNULL(STRING_AGG(CONVERT(nvarchar(max),x.j),N',') WITHIN GROUP (ORDER BY x.o),N'')+N']' AS values_json
      FROM (SELECT v.ordinal AS o,(SELECT v.value_id AS valueId,v.label AS label FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS j
        FROM wildlife.definition_attribute_value dv JOIN wildlife.attribute_value v ON v.attribute_id=dv.attribute_id AND v.value_id=dv.value_id
        WHERE dv.definition_id=@id AND dv.attribute_id=a.attribute_id) x) sv
    WHERE EXISTS(SELECT 1 FROM wildlife.definition_attribute_value dv WHERE dv.definition_id=@id AND dv.attribute_id=a.attribute_id);
  DECLARE @details_json nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),j),N',') WITHIN GROUP (ORDER BY attribute_id)+N']' FROM @details),N'[]');
  SET @result=(SELECT @contract AS contractId,N'VISIBLE' AS status,d.definition_id AS definitionId,
      CASE WHEN @collected=1 THEN N'COLLECTED' ELSE N'UNCOLLECTED' END AS collectionState,
      JSON_QUERY(CASE WHEN @collected=1
        THEN (SELECT d.common_name AS commonName,d.collection_number AS collectionNumber,JSON_QUERY(d.range_json) AS [range],d.avatar_photo_ref AS avatarPhotoRef,
                d.scientific_name AS scientificName,JSON_QUERY(d.types_json) AS types,JSON_QUERY(d.stats_json) AS stats,JSON_QUERY(d.attributes_json) AS attributes,
                JSON_QUERY(@details_json) AS attributeDetails
              FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
        ELSE (SELECT d.common_name AS commonName,d.collection_number AS collectionNumber,JSON_QUERY(d.range_json) AS [range],d.avatar_photo_ref AS avatarPhotoRef
              FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) END) AS animal
    FROM wildlife.animal_definition d WHERE d.definition_id=@id
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.view_collected_animals
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-view-collected-animals-result.v1';
  IF @user_id IS NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"AUTHENTICATION_REQUIRED"}') AS reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  -- Each recorded encounter is one individual, in encounterId order (D14), shown with the user's photo and nickname,
  -- or the definition's common name when no nickname was given.
  DECLARE @items TABLE(ordinal int IDENTITY(1,1) PRIMARY KEY,item nvarchar(max) NOT NULL);
  INSERT @items(item)
  SELECT (SELECT e.encounter_id AS encounterId,e.owner_user_id AS ownerUserId,e.definition_id AS definitionId,e.photo_ref AS photoRef,e.nickname AS nickname,
      ISNULL(e.nickname,d.common_name) AS displayName FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)
  FROM wildlife.encounter e JOIN wildlife.animal_definition d ON d.definition_id=e.definition_id
  WHERE e.owner_user_id=@user_id ORDER BY e.encounter_id;
  SET @result=(SELECT @contract AS contractId,N'LISTED' AS status,(SELECT COUNT(*) FROM @items) AS total,
    JSON_QUERY(ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),item),N',') WITHIN GROUP (ORDER BY ordinal)+N']' FROM @items),N'[]')) AS items
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.view_wildlife_home
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-view-wildlife-home-result.v1';
  IF @user_id IS NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"AUTHENTICATION_REQUIRED"}') AS reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  DECLARE @revision int=ISNULL((SELECT t.revision FROM wildlife.team t WHERE t.owner_user_id=@user_id),0);
  DECLARE @members TABLE(ordinal int NOT NULL PRIMARY KEY,item nvarchar(max) NOT NULL);
  INSERT @members(ordinal,item)
  SELECT m.ordinal,(SELECT e.encounter_id AS encounterId,e.definition_id AS definitionId,e.photo_ref AS photoRef,e.nickname AS nickname,
      ISNULL(e.nickname,d.common_name) AS displayName FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)
  FROM wildlife.team_member m
  JOIN wildlife.encounter e ON e.owner_user_id=m.owner_user_id AND e.encounter_id=m.encounter_id
  JOIN wildlife.animal_definition d ON d.definition_id=e.definition_id
  WHERE m.owner_user_id=@user_id;
  SET @result=(SELECT @contract AS contractId,N'VISIBLE' AS status,
    JSON_QUERY((SELECT @revision AS revision,(SELECT COUNT(*) FROM @members) AS size,
      JSON_QUERY(ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),item),N',') WITHIN GROUP (ORDER BY ordinal)+N']' FROM @members),N'[]')) AS members
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS team
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.upload_encounter_photo
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-upload-encounter-photo-result.v1',@code nvarchar(60)=NULL;
  DECLARE @b64 nvarchar(max),@media_type nvarchar(100),@bytes varbinary(max)=NULL;
  SELECT @b64=contentBase64,@media_type=mediaType FROM OPENJSON(ISNULL(@request,N'{}')) WITH (contentBase64 nvarchar(max) N'$.contentBase64',mediaType nvarchar(100) N'$.mediaType');
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF @b64 IS NULL OR LEN(@b64)=0 SET @code=N'PHOTO_REQUIRED';
  ELSE IF @media_type IS NULL OR @media_type NOT LIKE N'image/_%' SET @code=N'PHOTO_MEDIA_TYPE_REQUIRED';
  ELSE
  BEGIN
    BEGIN TRY
      SET @bytes=CAST(N'' AS xml).value('xs:base64Binary(sql:variable("@b64"))','varbinary(max)');
    END TRY
    BEGIN CATCH
      SET @bytes=NULL;
    END CATCH
    IF @bytes IS NULL OR DATALENGTH(@bytes)=0 SET @code=N'PHOTO_REQUIRED';
  END
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  -- D10: the image bytes are retained for the owner under their sha256; retaining them is not species verification.
  DECLARE @ref nvarchar(100)=N'photo-'+LOWER(LEFT(REPLACE(CONVERT(nvarchar(36),NEWID()),N'-',N''),16));
  DECLARE @digest binary(32)=HASHBYTES('SHA2_256',@bytes),@tc int=@@TRANCOUNT;
  BEGIN TRY
    IF @tc=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION wildlife_photo;
    INSERT wildlife.photo(photo_ref,owner_user_id,purpose,media_type,content_sha256,content_bytes,byte_length,durable)
    VALUES(@ref,@user_id,N'encounter',@media_type,@digest,@bytes,DATALENGTH(@bytes),1);
    IF @tc=0 COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE()=-1 OR (@tc=0 AND @@TRANCOUNT>0) ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION wildlife_photo;
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"PHOTO_STORAGE_UNAVAILABLE"}') AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END CATCH
  SET @result=(SELECT @contract AS contractId,N'UPLOADED' AS status,
    JSON_QUERY((SELECT @ref AS photoRef,@user_id AS ownerUserId,@media_type AS mediaType,N'sha256:'+LOWER(CONVERT(varchar(64),@digest,2)) AS contentSha256,
      DATALENGTH(@bytes) AS byteLength,CONVERT(bit,1) AS durable,CONVERT(bit,0) AS verificationPerformed FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS photo,
    JSON_QUERY(N'{"applied":true}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.record_animal_encounter
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-record-animal-encounter-result.v1',@code nvarchar(60)=NULL;
  DECLARE @encounter_id nvarchar(100)=JSON_VALUE(@request,N'$.encounterId'),@definition_id nvarchar(100)=JSON_VALUE(@request,N'$.definitionId'),
    @photo_ref nvarchar(100)=JSON_VALUE(@request,N'$.photoRef'),@nickname nvarchar(200)=JSON_VALUE(@request,N'$.nickname'),
    @l nvarchar(max)=JSON_QUERY(@request,N'$.location'),@location nvarchar(max)=NULL,@active bit=NULL;
  IF @l IS NOT NULL
    SET @location=CASE
      WHEN JSON_VALUE(@l,N'$.source')=N'manual' AND LEN(LTRIM(RTRIM(ISNULL(JSON_VALUE(@l,N'$.description'),N''))))>0
        THEN (SELECT N'manual' AS source,JSON_VALUE(@l,N'$.description') AS description FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
      WHEN JSON_VALUE(@l,N'$.source')=N'device' AND TRY_CONVERT(decimal(9,6),JSON_VALUE(@l,N'$.latitude')) BETWEEN -90 AND 90
        AND TRY_CONVERT(decimal(9,6),JSON_VALUE(@l,N'$.longitude')) BETWEEN -180 AND 180
        THEN (SELECT N'device' AS source,TRY_CONVERT(decimal(9,6),JSON_VALUE(@l,N'$.latitude')) AS latitude,TRY_CONVERT(decimal(9,6),JSON_VALUE(@l,N'$.longitude')) AS longitude
              FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) END;
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF @definition_id IS NULL SET @code=N'ANIMAL_SELECTION_REQUIRED';
  ELSE IF @l IS NULL SET @code=N'LOCATION_REQUIRED';
  ELSE IF @photo_ref IS NULL SET @code=N'PHOTO_REQUIRED';
  ELSE IF @encounter_id IS NULL SET @code=N'ENCOUNTER_ID_REQUIRED';
  ELSE IF @location IS NULL SET @code=N'LOCATION_INVALID';
  IF @code IS NULL
  BEGIN
    -- D07: the encounterId is the owner's retry key. The same key with the same content returns the recorded
    -- encounter; the same key with other content is refused.
    DECLARE @old_definition nvarchar(100),@old_location nvarchar(max),@old_photo nvarchar(100),@old_nickname nvarchar(200),@exists bit=0;
    SELECT @exists=1,@old_definition=e.definition_id,@old_location=e.location_json,@old_photo=e.photo_ref,@old_nickname=e.nickname
    FROM wildlife.encounter e WHERE e.owner_user_id=@user_id AND e.encounter_id=@encounter_id;
    IF @exists=1
    BEGIN
      IF @old_definition=@definition_id AND @old_location=@location AND @old_photo=@photo_ref
        AND (@old_nickname=@nickname OR (@old_nickname IS NULL AND @nickname IS NULL))
      BEGIN
        SET @result=(SELECT @contract AS contractId,N'RECORDED' AS status,
          JSON_QUERY((SELECT @encounter_id AS encounterId,@user_id AS ownerUserId,@old_definition AS definitionId,JSON_QUERY(@old_location) AS location,
            @old_photo AS photoRef,@old_nickname AS nickname FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS encounter,
          N'COLLECTED' AS collectionState,CONVERT(bit,0) AS verificationPerformed,CONVERT(bit,1) AS replayed,JSON_QUERY(N'{"applied":false}') AS mutation
          FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
        RETURN;
      END
      SET @code=N'ENCOUNTER_ID_CONFLICT';
    END
  END
  IF @code IS NULL
  BEGIN
    SELECT @active=d.active FROM wildlife.animal_definition d WHERE d.definition_id=@definition_id;
    IF @active IS NULL SET @code=N'ANIMAL_DEFINITION_NOT_FOUND';
    ELSE IF @active=0 SET @code=N'ANIMAL_DEFINITION_UNAVAILABLE';
    ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.photo p WHERE p.photo_ref=@photo_ref AND p.owner_user_id=@user_id AND p.purpose=N'encounter' AND p.durable=1)
      SET @code=N'PHOTO_NOT_AVAILABLE_TO_USER';
  END
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  DECLARE @tc int=@@TRANCOUNT;
  BEGIN TRY
    IF @tc=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION wildlife_encounter;
    INSERT wildlife.encounter(owner_user_id,encounter_id,definition_id,location_json,photo_ref,nickname)
    VALUES(@user_id,@encounter_id,@definition_id,@location,@photo_ref,@nickname);
    IF @tc=0 COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE()=-1 OR (@tc=0 AND @@TRANCOUNT>0) ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION wildlife_encounter;
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"COLLECTION_STORAGE_UNAVAILABLE"}') AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END CATCH
  SET @result=(SELECT @contract AS contractId,N'RECORDED' AS status,
    JSON_QUERY((SELECT @encounter_id AS encounterId,@user_id AS ownerUserId,@definition_id AS definitionId,JSON_QUERY(@location) AS location,
      @photo_ref AS photoRef,@nickname AS nickname FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS encounter,
    N'COLLECTED' AS collectionState,CONVERT(bit,0) AS verificationPerformed,CONVERT(bit,0) AS replayed,JSON_QUERY(N'{"applied":true}') AS mutation
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.set_animal_team
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-set-animal-team-result.v1',@code nvarchar(60)=NULL;
  DECLARE @ids nvarchar(max)=JSON_QUERY(@request,N'$.encounterIds'),@expected int=TRY_CONVERT(int,JSON_VALUE(@request,N'$.expectedRevision'));
  DECLARE @members TABLE(ordinal int NOT NULL PRIMARY KEY,encounter_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,value_type int NOT NULL);
  IF @ids IS NOT NULL AND LEFT(LTRIM(@ids),1)=N'['
    INSERT @members(ordinal,encounter_id,value_type) SELECT CONVERT(int,[key]),CASE WHEN [type]=1 THEN [value] END,[type] FROM OPENJSON(@ids);
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF @ids IS NULL OR LEFT(LTRIM(@ids),1)<>N'[' OR EXISTS(SELECT 1 FROM @members WHERE value_type<>1) SET @code=N'TEAM_REQUEST_INVALID';
  ELSE IF @expected IS NULL SET @code=N'REVISION_REQUIRED';
  ELSE IF (SELECT COUNT(*) FROM @members)>6 SET @code=N'TEAM_LIMIT_EXCEEDED';
  ELSE IF EXISTS(SELECT encounter_id FROM @members GROUP BY encounter_id HAVING COUNT(*)>1) SET @code=N'TEAM_MEMBER_DUPLICATE';
  -- D06: members are the owner's own recorded individuals; distinct individuals of one definition may both be members.
  ELSE IF EXISTS(SELECT 1 FROM @members m WHERE NOT EXISTS(SELECT 1 FROM wildlife.encounter e WHERE e.owner_user_id=@user_id AND e.encounter_id=m.encounter_id))
    SET @code=N'TEAM_MEMBER_NOT_AVAILABLE';
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  -- D06/D13: the submitted list replaces the team atomically when the expected revision is current.
  DECLARE @tc int=@@TRANCOUNT,@current int,@stale bit=0;
  BEGIN TRY
    IF @tc=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION wildlife_team;
    SET @current=ISNULL((SELECT t.revision FROM wildlife.team t WITH (UPDLOCK,HOLDLOCK) WHERE t.owner_user_id=@user_id),0);
    IF @current<>@expected SET @stale=1;
    ELSE
    BEGIN
      DELETE wildlife.team_member WHERE owner_user_id=@user_id;
      INSERT wildlife.team_member(owner_user_id,ordinal,encounter_id) SELECT @user_id,ordinal,encounter_id FROM @members;
      IF EXISTS(SELECT 1 FROM wildlife.team WHERE owner_user_id=@user_id) UPDATE wildlife.team SET revision=@current+1 WHERE owner_user_id=@user_id;
      ELSE INSERT wildlife.team(owner_user_id,revision) VALUES(@user_id,@current+1);
    END
    IF @tc=0 COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE()=-1 OR (@tc=0 AND @@TRANCOUNT>0) ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION wildlife_team;
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"TEAM_STORAGE_UNAVAILABLE"}') AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END CATCH
  IF @stale=1
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"REVISION_CONFLICT"}') AS reason,@current AS currentRevision,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  SET @result=(SELECT @contract AS contractId,N'SAVED' AS status,
    JSON_QUERY((SELECT @user_id AS ownerUserId,@current+1 AS revision,(SELECT COUNT(*) FROM @members) AS size,
      JSON_QUERY(ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(encounter_id,'json')+N'"'),N',') WITHIN GROUP (ORDER BY ordinal)+N']' FROM @members),N'[]')) AS encounterIds
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS team,
    JSON_QUERY(N'{"applied":true}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.add_animal_definition
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-add-animal-definition-result.v1',@code nvarchar(60)=NULL;
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
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.user_role r WHERE r.user_id=@user_id AND r.role=N'biologist') SET @code=N'BIOLOGIST_ROLE_REQUIRED';
  ELSE IF @a IS NULL OR LEN(LTRIM(RTRIM(ISNULL(@common,N''))))=0 OR LEN(LTRIM(RTRIM(ISNULL(@scientific,N''))))=0 OR LEN(LTRIM(RTRIM(ISNULL(@avatar,N''))))=0
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
  ELSE IF EXISTS(SELECT 1 FROM wildlife.animal_definition d WHERE d.collection_number=@number) SET @code=N'COLLECTION_NUMBER_NOT_UNIQUE';
  ELSE IF EXISTS(SELECT 1 FROM @attr_rows r WHERE NOT EXISTS(SELECT 1 FROM wildlife.attribute x WHERE x.attribute_id=r.attribute_id AND x.active=1)) SET @code=N'ATTRIBUTE_UNKNOWN';
  ELSE IF EXISTS(SELECT attribute_id FROM @attr_rows GROUP BY attribute_id HAVING COUNT(*)>1) SET @code=N'ATTRIBUTE_DUPLICATE';
  ELSE IF EXISTS(SELECT 1 FROM @value_rows v WHERE NOT EXISTS(SELECT 1 FROM wildlife.attribute_value x WHERE x.attribute_id=v.attribute_id AND x.value_id=v.value_id))
    SET @code=N'ATTRIBUTE_VALUE_NOT_SELECTABLE';
  ELSE IF EXISTS(SELECT attribute_id,value_id FROM @value_rows GROUP BY attribute_id,value_id HAVING COUNT(*)>1) SET @code=N'ATTRIBUTE_VALUE_DUPLICATE';
  ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.photo p WHERE p.photo_ref=@avatar AND p.purpose=N'avatar' AND p.durable=1) SET @code=N'AVATAR_PHOTO_NOT_RETAINED';
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  DECLARE @range_json nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(county_id,'json')+N'"'),N',') WITHIN GROUP (ORDER BY ordinal)+N']' FROM @range_rows),N'[]');
  DECLARE @types_json nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(type_name,'json')+N'"'),N',') WITHIN GROUP (ORDER BY ordinal)+N']' FROM @type_rows),N'[]');
  DECLARE @attr_json nvarchar(max)=ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),x.j),N',') WITHIN GROUP (ORDER BY x.ordinal)+N']' FROM (
      SELECT r.ordinal,N'{"attributeId":"'+STRING_ESCAPE(r.attribute_id,'json')+N'","valueIds":'
        +ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(v.value_id,'json')+N'"'),N',') WITHIN GROUP (ORDER BY v.ordinal)+N']' FROM @value_rows v WHERE v.attribute_id=r.attribute_id),N'[]')+N'}' AS j
      FROM @attr_rows r) x),N'[]');
  DECLARE @id nvarchar(100)=N'animal-'+CASE WHEN @number<1000 THEN RIGHT(N'00'+CONVERT(nvarchar(10),@number),3) ELSE CONVERT(nvarchar(10),@number) END;
  IF EXISTS(SELECT 1 FROM wildlife.animal_definition d WHERE d.definition_id=@id) SET @id=N'animal-'+LOWER(LEFT(REPLACE(CONVERT(nvarchar(36),NEWID()),N'-',N''),12));
  DECLARE @tc int=@@TRANCOUNT;
  BEGIN TRY
    IF @tc=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION wildlife_definition;
    INSERT wildlife.animal_definition(definition_id,revision,active,common_name,scientific_name,avatar_photo_ref,collection_number,range_json,types_json,stats_json,attributes_json)
    VALUES(@id,1,1,@common,@scientific,@avatar,@number,@range_json,@types_json,@stats,@attr_json);
    INSERT wildlife.definition_county(definition_id,county_id) SELECT @id,county_id FROM @range_rows;
    INSERT wildlife.definition_type(definition_id,type_name) SELECT @id,type_name FROM @type_rows;
    INSERT wildlife.definition_attribute_value(definition_id,attribute_id,value_id) SELECT @id,attribute_id,value_id FROM @value_rows;
    IF @tc=0 COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE()=-1 OR (@tc=0 AND @@TRANCOUNT>0) ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION wildlife_definition;
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"CATALOG_STORAGE_UNAVAILABLE"}') AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END CATCH
  SET @result=(SELECT @contract AS contractId,N'ADDED' AS status,@id AS definitionId,1 AS revision,
    JSON_QUERY((SELECT @common AS commonName,@scientific AS scientificName,@avatar AS avatarPhotoRef,@number AS collectionNumber,JSON_QUERY(@range_json) AS [range],
      JSON_QUERY(@types_json) AS types,JSON_QUERY(@stats) AS stats,JSON_QUERY(@attr_json) AS attributes FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS animal,
    JSON_QUERY(N'{"applied":true}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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
    ELSE IF @operation=N'nerdery-view-wildlife-home' EXEC wildlife.view_wildlife_home @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-upload-encounter-photo' EXEC wildlife.upload_encounter_photo @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-record-animal-encounter' EXEC wildlife.record_animal_encounter @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-set-animal-team' EXEC wildlife.set_animal_team @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-add-animal-definition' EXEC wildlife.add_animal_definition @request=@request,@user_id=@user_id,@result=@result OUTPUT;
    ELSE SET @result=(SELECT N'REFUSED' AS status,JSON_QUERY(N'{"code":"OPERATION_NOT_DECLARED"}') AS reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END TRY
  BEGIN CATCH
    -- A store that cannot be read or written answers the operation's own storage refusal; nothing is kept.
    IF @@TRANCOUNT>@tc ROLLBACK TRANSACTION;
    DECLARE @write bit=CASE WHEN @operation IN (N'nerdery-upload-encounter-photo',N'nerdery-record-animal-encounter',N'nerdery-set-animal-team',N'nerdery-add-animal-definition') THEN 1 ELSE 0 END;
    SET @result=(SELECT @operation+N'-result.v1' AS contractId,N'REFUSED' AS status,
      JSON_QUERY((SELECT CASE @operation
        WHEN N'nerdery-upload-encounter-photo' THEN N'PHOTO_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-record-animal-encounter' THEN N'COLLECTION_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-view-collected-animals' THEN N'COLLECTION_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-set-animal-team' THEN N'TEAM_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-view-wildlife-home' THEN N'TEAM_STORAGE_UNAVAILABLE'
        ELSE N'CATALOG_STORAGE_UNAVAILABLE' END AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      JSON_QUERY(CASE WHEN @write=1 THEN N'{"applied":false}' END) AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END CATCH
END;
GO
CREATE OR ALTER PROCEDURE wildlife.serve
  @operation nvarchar(100),@input nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  -- The caller is bound by the declared API operation from the session the frontdoor validated ($caller); it is
  -- verified again here, so a run admitted with someone else's principalId is anonymous. A verified principal
  -- without a wildlife profile is anonymous too.
  DECLARE @principal uniqueidentifier=TRY_CONVERT(uniqueidentifier,JSON_VALUE(@input,N'$.caller.principalId')),
    @session uniqueidentifier=TRY_CONVERT(uniqueidentifier,JSON_VALUE(@input,N'$.caller.sessionId')),@user_id nvarchar(100)=NULL,@result nvarchar(max);
  IF @principal IS NOT NULL AND @session IS NOT NULL
    SELECT @user_id=u.user_id
    FROM wildlife.app_user u
    JOIN [identity].session s ON s.principal_id=u.principal_id AND s.session_id=@session AND s.revoked_at IS NULL AND s.expires_at>SYSUTCDATETIME()
    JOIN [identity].principal p ON p.principal_id=s.principal_id AND p.active=1
    WHERE u.principal_id=@principal;
  DECLARE @request nvarchar(max)=ISNULL(JSON_QUERY(@input,N'$.request'),N'{}');
  EXEC wildlife.invoke_operation @operation=@operation,@request=@request,@user_id=@user_id,@result=@result OUTPUT;
  SELECT @result AS value;
END;
GO
SET NOCOUNT ON;
INSERT wildlife.county(county_id,name) VALUES(N'county-a',N'Demo County A');
INSERT wildlife.county(county_id,name) VALUES(N'county-b',N'Demo County B');
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'Flying',0);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'Aquatic',1);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'Bug',2);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'Rural',3);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'Metro',4);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'SyntheticType06',5);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'SyntheticType07',6);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'SyntheticType08',7);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'SyntheticType09',8);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'SyntheticType10',9);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'SyntheticType11',10);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'SyntheticType12',11);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'SyntheticType13',12);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'SyntheticType14',13);
INSERT wildlife.animal_type(type_name,ordinal) VALUES(N'SyntheticType15',14);
INSERT wildlife.attribute(attribute_id,revision,active,name,description) VALUES(N'habitat',1,1,N'Habitat',N'Synthetic fixture habitat');
INSERT wildlife.attribute(attribute_id,revision,active,name,description) VALUES(N'diet',1,1,N'Diet',N'Synthetic fixture diet');
INSERT wildlife.attribute_value(attribute_id,value_id,label,ordinal) VALUES(N'habitat',N'wetland',N'Wetland',0);
INSERT wildlife.attribute_value(attribute_id,value_id,label,ordinal) VALUES(N'habitat',N'woodland',N'Woodland',1);
INSERT wildlife.attribute_value(attribute_id,value_id,label,ordinal) VALUES(N'diet',N'plants',N'Plants',0);
INSERT wildlife.attribute_value(attribute_id,value_id,label,ordinal) VALUES(N'diet',N'fish',N'Fish',1);
INSERT wildlife.animal_definition(definition_id,revision,active,common_name,scientific_name,avatar_photo_ref,collection_number,range_json,types_json,stats_json,attributes_json) VALUES(N'animal-001',1,1,N'Demo Heron',N'Synthetic scientific label 1',N'avatar-001',1,N'["county-a"]',N'["Flying","Aquatic"]',N'{"Strength":2,"Size":3,"Speed":4}',N'[{"attributeId":"habitat","valueIds":["wetland"]},{"attributeId":"diet","valueIds":["fish"]}]');
INSERT wildlife.animal_definition(definition_id,revision,active,common_name,scientific_name,avatar_photo_ref,collection_number,range_json,types_json,stats_json,attributes_json) VALUES(N'animal-002',1,1,N'Demo Fox',N'Synthetic scientific label 2',N'avatar-002',2,N'["county-a"]',N'["Rural"]',N'{"Strength":3,"Size":4,"Speed":5}',N'[{"attributeId":"habitat","valueIds":["woodland"]},{"attributeId":"diet","valueIds":["plants"]}]');
INSERT wildlife.animal_definition(definition_id,revision,active,common_name,scientific_name,avatar_photo_ref,collection_number,range_json,types_json,stats_json,attributes_json) VALUES(N'animal-003',1,1,N'Demo Beetle',N'Synthetic scientific label 3',N'avatar-003',3,N'["county-a"]',N'["Bug"]',N'{"Strength":4,"Size":5,"Speed":6}',N'[{"attributeId":"habitat","valueIds":["woodland"]},{"attributeId":"diet","valueIds":["plants"]}]');
INSERT wildlife.definition_county(definition_id,county_id) VALUES(N'animal-001',N'county-a');
INSERT wildlife.definition_county(definition_id,county_id) VALUES(N'animal-002',N'county-a');
INSERT wildlife.definition_county(definition_id,county_id) VALUES(N'animal-003',N'county-a');
INSERT wildlife.definition_type(definition_id,type_name) VALUES(N'animal-001',N'Flying');
INSERT wildlife.definition_type(definition_id,type_name) VALUES(N'animal-001',N'Aquatic');
INSERT wildlife.definition_type(definition_id,type_name) VALUES(N'animal-002',N'Rural');
INSERT wildlife.definition_type(definition_id,type_name) VALUES(N'animal-003',N'Bug');
INSERT wildlife.definition_attribute_value(definition_id,attribute_id,value_id) VALUES(N'animal-001',N'habitat',N'wetland');
INSERT wildlife.definition_attribute_value(definition_id,attribute_id,value_id) VALUES(N'animal-001',N'diet',N'fish');
INSERT wildlife.definition_attribute_value(definition_id,attribute_id,value_id) VALUES(N'animal-002',N'habitat',N'woodland');
INSERT wildlife.definition_attribute_value(definition_id,attribute_id,value_id) VALUES(N'animal-002',N'diet',N'plants');
INSERT wildlife.definition_attribute_value(definition_id,attribute_id,value_id) VALUES(N'animal-003',N'habitat',N'woodland');
INSERT wildlife.definition_attribute_value(definition_id,attribute_id,value_id) VALUES(N'animal-003',N'diet',N'plants');
INSERT wildlife.photo(photo_ref,owner_user_id,purpose,media_type,content_sha256,content_bytes,byte_length,durable) VALUES(N'avatar-001',NULL,N'avatar',N'image/png',0x8021bd6b739aa5464382e945cf4ab848c30f467b91ddb40d1c350354ec21cfa6,0x89504E470D0A1A0A0000000D4948445200000002000000020802000000FDD49A730000001049444154789C63889E9C0B440C100A0025BA056D4E47604C0000000049454E44AE426082,73,1);
INSERT wildlife.photo(photo_ref,owner_user_id,purpose,media_type,content_sha256,content_bytes,byte_length,durable) VALUES(N'avatar-002',NULL,N'avatar',N'image/png',0x8021bd6b739aa5464382e945cf4ab848c30f467b91ddb40d1c350354ec21cfa6,0x89504E470D0A1A0A0000000D4948445200000002000000020802000000FDD49A730000001049444154789C63889E9C0B440C100A0025BA056D4E47604C0000000049454E44AE426082,73,1);
INSERT wildlife.photo(photo_ref,owner_user_id,purpose,media_type,content_sha256,content_bytes,byte_length,durable) VALUES(N'avatar-003',NULL,N'avatar',N'image/png',0x8021bd6b739aa5464382e945cf4ab848c30f467b91ddb40d1c350354ec21cfa6,0x89504E470D0A1A0A0000000D4948445200000002000000020802000000FDD49A730000001049444154789C63889E9C0B440C100A0025BA056D4E47604C0000000049454E44AE426082,73,1);
INSERT wildlife.photo(photo_ref,owner_user_id,purpose,media_type,content_sha256,content_bytes,byte_length,durable) VALUES(N'photo-bio',N'user-bio',N'encounter',N'image/png',0x8021bd6b739aa5464382e945cf4ab848c30f467b91ddb40d1c350354ec21cfa6,0x89504E470D0A1A0A0000000D4948445200000002000000020802000000FDD49A730000001049444154789C63889E9C0B440C100A0025BA056D4E47604C0000000049454E44AE426082,73,1);
INSERT wildlife.photo(photo_ref,owner_user_id,purpose,media_type,content_sha256,content_bytes,byte_length,durable) VALUES(N'photo-other',N'user-b',N'encounter',N'image/png',0xbafa6c640062744ce1559dcdbb23cbddec6d7d1d6833661634feeef2553ecc68,0x89504E470D0A1A0A0000000D4948445200000002000000020802000000FDD49A730000001049444154789C6398591D08440C100A00283A0595231D1F260000000049454E44AE426082,73,1);
INSERT wildlife.app_user(user_id,principal_id,identity_subject,first_name,last_name,email) VALUES(N'user-a','565de6d4-ebcd-408b-9359-04d21dc62183',N'dnr:subject-a',N'Avery',N'Citizen',N'avery@example.test');
INSERT wildlife.app_user(user_id,principal_id,identity_subject,first_name,last_name,email) VALUES(N'user-b',NULL,N'dnr:subject-b',N'Blake',N'Citizen',N'blake@example.test');
INSERT wildlife.app_user(user_id,principal_id,identity_subject,first_name,last_name,email) VALUES(N'user-bio',NULL,N'dnr:subject-bio',N'Casey',N'Biologist',N'casey@example.test');
INSERT wildlife.user_role(user_id,role) VALUES(N'user-a',N'citizen');
INSERT wildlife.user_role(user_id,role) VALUES(N'user-b',N'citizen');
INSERT wildlife.user_role(user_id,role) VALUES(N'user-bio',N'biologist');
INSERT wildlife.encounter(owner_user_id,encounter_id,definition_id,location_json,photo_ref,nickname) SELECT N'user-b',N'enc-008',N'animal-001',CASE
      WHEN JSON_VALUE(x.l,N'$.source')=N'manual' AND LEN(LTRIM(RTRIM(ISNULL(JSON_VALUE(x.l,N'$.description'),N''))))>0
        THEN (SELECT N'manual' AS source,JSON_VALUE(x.l,N'$.description') AS description FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
      WHEN JSON_VALUE(x.l,N'$.source')=N'device' AND TRY_CONVERT(decimal(9,6),JSON_VALUE(x.l,N'$.latitude')) BETWEEN -90 AND 90
        AND TRY_CONVERT(decimal(9,6),JSON_VALUE(x.l,N'$.longitude')) BETWEEN -180 AND 180
        THEN (SELECT N'device' AS source,TRY_CONVERT(decimal(9,6),JSON_VALUE(x.l,N'$.latitude')) AS latitude,TRY_CONVERT(decimal(9,6),JSON_VALUE(x.l,N'$.longitude')) AS longitude
              FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) END,N'photo-other',NULL FROM (SELECT N'{"source":"manual","description":"Synthetic park, north path"}' AS l) x;
INSERT wildlife.encounter(owner_user_id,encounter_id,definition_id,location_json,photo_ref,nickname) SELECT N'user-bio',N'enc-009',N'animal-001',CASE
      WHEN JSON_VALUE(x.l,N'$.source')=N'manual' AND LEN(LTRIM(RTRIM(ISNULL(JSON_VALUE(x.l,N'$.description'),N''))))>0
        THEN (SELECT N'manual' AS source,JSON_VALUE(x.l,N'$.description') AS description FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
      WHEN JSON_VALUE(x.l,N'$.source')=N'device' AND TRY_CONVERT(decimal(9,6),JSON_VALUE(x.l,N'$.latitude')) BETWEEN -90 AND 90
        AND TRY_CONVERT(decimal(9,6),JSON_VALUE(x.l,N'$.longitude')) BETWEEN -180 AND 180
        THEN (SELECT N'device' AS source,TRY_CONVERT(decimal(9,6),JSON_VALUE(x.l,N'$.latitude')) AS latitude,TRY_CONVERT(decimal(9,6),JSON_VALUE(x.l,N'$.longitude')) AS longitude
              FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) END,N'photo-bio',NULL FROM (SELECT N'{"source":"manual","description":"Synthetic park, north path"}' AS l) x;
INSERT wildlife.team(owner_user_id,revision) VALUES(N'user-b',1);
INSERT wildlife.team(owner_user_id,revision) VALUES(N'user-bio',1);
INSERT wildlife.team_member(owner_user_id,ordinal,encounter_id) VALUES(N'user-b',0,N'enc-008');
GO
SET NOCOUNT ON;
DECLARE @digests TABLE(object_name nvarchar(200),digest varchar(80));
DECLARE @p0 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.browse_animal_collection')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @p0=SUBSTRING(@p0,CHARINDEX(N'PROCEDURE wildlife.browse_animal_collection',@p0),DATALENGTH(@p0)/2);
WHILE DATALENGTH(@p0)>0 AND RIGHT(@p0,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @p0=LEFT(@p0,DATALENGTH(@p0)/2-1);
INSERT @digests VALUES(N'wildlife.browse_animal_collection','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p0 COLLATE Latin1_General_100_BIN2_UTF8)),2)));
DECLARE @p1 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.view_animal_definition')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @p1=SUBSTRING(@p1,CHARINDEX(N'PROCEDURE wildlife.view_animal_definition',@p1),DATALENGTH(@p1)/2);
WHILE DATALENGTH(@p1)>0 AND RIGHT(@p1,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @p1=LEFT(@p1,DATALENGTH(@p1)/2-1);
INSERT @digests VALUES(N'wildlife.view_animal_definition','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p1 COLLATE Latin1_General_100_BIN2_UTF8)),2)));
DECLARE @p2 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.view_collected_animals')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @p2=SUBSTRING(@p2,CHARINDEX(N'PROCEDURE wildlife.view_collected_animals',@p2),DATALENGTH(@p2)/2);
WHILE DATALENGTH(@p2)>0 AND RIGHT(@p2,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @p2=LEFT(@p2,DATALENGTH(@p2)/2-1);
INSERT @digests VALUES(N'wildlife.view_collected_animals','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p2 COLLATE Latin1_General_100_BIN2_UTF8)),2)));
DECLARE @p3 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.view_wildlife_home')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @p3=SUBSTRING(@p3,CHARINDEX(N'PROCEDURE wildlife.view_wildlife_home',@p3),DATALENGTH(@p3)/2);
WHILE DATALENGTH(@p3)>0 AND RIGHT(@p3,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @p3=LEFT(@p3,DATALENGTH(@p3)/2-1);
INSERT @digests VALUES(N'wildlife.view_wildlife_home','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p3 COLLATE Latin1_General_100_BIN2_UTF8)),2)));
DECLARE @p4 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.upload_encounter_photo')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @p4=SUBSTRING(@p4,CHARINDEX(N'PROCEDURE wildlife.upload_encounter_photo',@p4),DATALENGTH(@p4)/2);
WHILE DATALENGTH(@p4)>0 AND RIGHT(@p4,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @p4=LEFT(@p4,DATALENGTH(@p4)/2-1);
INSERT @digests VALUES(N'wildlife.upload_encounter_photo','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p4 COLLATE Latin1_General_100_BIN2_UTF8)),2)));
DECLARE @p5 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.record_animal_encounter')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @p5=SUBSTRING(@p5,CHARINDEX(N'PROCEDURE wildlife.record_animal_encounter',@p5),DATALENGTH(@p5)/2);
WHILE DATALENGTH(@p5)>0 AND RIGHT(@p5,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @p5=LEFT(@p5,DATALENGTH(@p5)/2-1);
INSERT @digests VALUES(N'wildlife.record_animal_encounter','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p5 COLLATE Latin1_General_100_BIN2_UTF8)),2)));
DECLARE @p6 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.set_animal_team')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @p6=SUBSTRING(@p6,CHARINDEX(N'PROCEDURE wildlife.set_animal_team',@p6),DATALENGTH(@p6)/2);
WHILE DATALENGTH(@p6)>0 AND RIGHT(@p6,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @p6=LEFT(@p6,DATALENGTH(@p6)/2-1);
INSERT @digests VALUES(N'wildlife.set_animal_team','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p6 COLLATE Latin1_General_100_BIN2_UTF8)),2)));
DECLARE @p7 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.add_animal_definition')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @p7=SUBSTRING(@p7,CHARINDEX(N'PROCEDURE wildlife.add_animal_definition',@p7),DATALENGTH(@p7)/2);
WHILE DATALENGTH(@p7)>0 AND RIGHT(@p7,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @p7=LEFT(@p7,DATALENGTH(@p7)/2-1);
INSERT @digests VALUES(N'wildlife.add_animal_definition','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p7 COLLATE Latin1_General_100_BIN2_UTF8)),2)));
DECLARE @p8 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.invoke_operation')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @p8=SUBSTRING(@p8,CHARINDEX(N'PROCEDURE wildlife.invoke_operation',@p8),DATALENGTH(@p8)/2);
WHILE DATALENGTH(@p8)>0 AND RIGHT(@p8,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @p8=LEFT(@p8,DATALENGTH(@p8)/2-1);
INSERT @digests VALUES(N'wildlife.invoke_operation','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p8 COLLATE Latin1_General_100_BIN2_UTF8)),2)));
DECLARE @p9 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.serve')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @p9=SUBSTRING(@p9,CHARINDEX(N'PROCEDURE wildlife.serve',@p9),DATALENGTH(@p9)/2);
WHILE DATALENGTH(@p9)>0 AND RIGHT(@p9,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @p9=LEFT(@p9,DATALENGTH(@p9)/2-1);
INSERT @digests VALUES(N'wildlife.serve','sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@p9 COLLATE Latin1_General_100_BIN2_UTF8)),2)));
DECLARE @want TABLE(object_name nvarchar(200),digest varchar(80)); INSERT @want VALUES(N'wildlife.browse_animal_collection','sha256:2eab058ed14de6030bfc80680c7aaf38cb821a1012e7ff03af11bfb681207f54'),(N'wildlife.view_animal_definition','sha256:58fb596744c841d8793499c40bddfeff3a49aff8487b36ded32ddf1b2863aaa7'),(N'wildlife.view_collected_animals','sha256:a08acf58d52c84a3a3521ab2a70f4feceb2078a8669cee3f021fc8f141024bc9'),(N'wildlife.view_wildlife_home','sha256:d89b21b3c800502511537cd68b4531aeee4134e2a5f88135cf60f8fe9bb4e6b2'),(N'wildlife.upload_encounter_photo','sha256:ebd6faa24fcdad7c34638b200c4c795069290af4cc8251f5b892b45a262282c5'),(N'wildlife.record_animal_encounter','sha256:fcde23842f1119bb22868c61592ff4685aa9abc1d494b6d4d2f704c526af5dd1'),(N'wildlife.set_animal_team','sha256:32484e6b62bc07e658e1bd8a6165ae4f220b4c9b9454f3f7633c0bb2203bc9ed'),(N'wildlife.add_animal_definition','sha256:3129e82c759df3072f27260150fb77799dad3c6ee0fd7b8d89abea838fb1149d'),(N'wildlife.invoke_operation','sha256:08ab8afd8e62318c55f718bbb953b80ecbb62359e8740ab74528acbf03c6ee62'),(N'wildlife.serve','sha256:7a15adba12661fb75a59a9a92914082b96fdc8b834c45d7e4fb9c3703a9b6a2e');
DECLARE @tables int=(SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(N'wildlife')),@procs int=(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'wildlife')),
 @mismatch int=(SELECT COUNT(*) FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name WHERE d.digest IS NULL OR d.digest<>w.digest);
DECLARE @counts nvarchar(400)=(SELECT (SELECT COUNT(*) FROM wildlife.county) AS [county],(SELECT COUNT(*) FROM wildlife.animal_type) AS [animal_type],(SELECT COUNT(*) FROM wildlife.attribute) AS [attribute],(SELECT COUNT(*) FROM wildlife.animal_definition) AS [animal_definition],(SELECT COUNT(*) FROM wildlife.photo) AS [photo],(SELECT COUNT(*) FROM wildlife.app_user) AS [app_user],(SELECT COUNT(*) FROM wildlife.encounter) AS [encounter],(SELECT COUNT(*) FROM wildlife.team) AS [team] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SELECT N'verify' AS result_set,@tables AS tables,@procs AS procedures,@mismatch AS digest_mismatches,@counts AS seed_counts,N'{"county":2,"animal_type":15,"attribute":2,"animal_definition":3,"photo":5,"app_user":3,"encounter":2,"team":2}' AS seed_expected;
SELECT N'verify' AS result_set,w.object_name,w.digest AS reviewed,d.digest AS installed,CASE WHEN d.digest=w.digest THEN 1 ELSE 0 END AS digest_matches FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name ORDER BY w.object_name;
DECLARE @smoke TABLE(o int IDENTITY(1,1),item nvarchar(200),actual nvarchar(400),expected nvarchar(400),passed bit);
DECLARE @r nvarchar(max);
DECLARE @t TABLE(v nvarchar(max));
EXEC wildlife.invoke_operation @operation=N'nerdery-browse-animal-collection',@request=N'{"search":""}',@user_id=N'user-a',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'browse as Avery: $.status',JSON_VALUE(@r,N'$.status'),N'LISTED',CASE WHEN JSON_VALUE(@r,N'$.status')=N'LISTED' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'browse as Avery: $.total',JSON_VALUE(@r,N'$.total'),N'3',CASE WHEN JSON_VALUE(@r,N'$.total')=N'3' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'browse as Avery: $.items[0].collectionState',JSON_VALUE(@r,N'$.items[0].collectionState'),N'UNCOLLECTED',CASE WHEN JSON_VALUE(@r,N'$.items[0].collectionState')=N'UNCOLLECTED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-view-wildlife-home',@request=N'{}',@user_id=N'user-a',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'home as Avery: $.status',JSON_VALUE(@r,N'$.status'),N'VISIBLE',CASE WHEN JSON_VALUE(@r,N'$.status')=N'VISIBLE' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'home as Avery: $.team.size',JSON_VALUE(@r,N'$.team.size'),N'0',CASE WHEN JSON_VALUE(@r,N'$.team.size')=N'0' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-view-wildlife-home',@request=N'{}',@user_id=N'user-b',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'home as Blake: $.status',JSON_VALUE(@r,N'$.status'),N'VISIBLE',CASE WHEN JSON_VALUE(@r,N'$.status')=N'VISIBLE' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'home as Blake: $.team.members[0].encounterId',JSON_VALUE(@r,N'$.team.members[0].encounterId'),N'enc-008',CASE WHEN JSON_VALUE(@r,N'$.team.members[0].encounterId')=N'enc-008' THEN 1 ELSE 0 END);
INSERT @t EXEC wildlife.serve @operation=N'nerdery-browse-animal-collection',@input=N'{"request":{"search":""}}';
SELECT @r=v FROM @t; DELETE @t;
INSERT @smoke(item,actual,expected,passed) VALUES(N'anonymous call: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'AUTHENTICATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'AUTHENTICATION_REQUIRED' THEN 1 ELSE 0 END);
DECLARE @forged nvarchar(max)=N'{"caller":{"principalId":"565de6d4-ebcd-408b-9359-04d21dc62183","sessionId":"'+CONVERT(nvarchar(36),NEWID())+N'"},"request":{"search":""}}';
INSERT @t EXEC wildlife.serve @operation=N'nerdery-browse-animal-collection',@input=@forged;
SELECT @r=v FROM @t; DELETE @t;
INSERT @smoke(item,actual,expected,passed) VALUES(N'owner principal with an unknown session: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'AUTHENTICATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'AUTHENTICATION_REQUIRED' THEN 1 ELSE 0 END);
SELECT N'smoke' AS result_set,item,actual,expected,passed FROM @smoke ORDER BY o;
IF @tables<>14 OR @procs<>10 OR @mismatch<>0 OR @counts<>N'{"county":2,"animal_type":15,"attribute":2,"animal_definition":3,"photo":5,"app_user":3,"encounter":2,"team":2}' OR EXISTS(SELECT 1 FROM @smoke WHERE passed=0)
BEGIN
 RAISERROR(N'NRD01_VERIFY_FAILED: the store is not exactly the reviewed one, or a smoke call did not answer as tested; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
GO
DECLARE @p uniqueidentifier='565de6d4-ebcd-408b-9359-04d21dc62183';
DECLARE @r TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));
INSERT @r EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=N'claude-code-opus-5-5-nerdery-slice',@objective=N'Install the no-drift check and declare it, then declare the eight capabilities of the Nerdery citizen slice, all feature first through OV3''s own changes: install analysis.check_capability_feature_conformance from its retained source with apply-engineering-change and prove its definition; declare check-capability-feature-conformance and each slice capability from its DSL with capability-from-dsl, which binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT; and prove each declaration keeps its feature pin.',
 @steps_json=N'[{"stepId":"plan-header","contractId":"estate-flight-plan.v1","promiseId":"nerdery-citizen-slice-build","flightType":"execution","workClass":"owner-objective","unknowns":[]},{"stepId":"install-procedure","capabilityId":"apply-engineering-change","historicalBasis":"ledger 7df11b46-3dce-4fa2-9d65-6326c481650b (2026-11-02T02:50:11.355): analysis.objective_agent_step installed by apply-engineering-change, one of 238 applied engineering changes (run fc518bd3); this source, retained under its digest by nerdery/sql/fast-1-estate, met the probed cases of its canonical feature read-only through sql-database-reader (runs 5fae01e0, 31062d0e, 2df0fbf8, f31ee728) and holds none of the installer''s refused tokens","input":{"contractId":"engineering-change.v1","sourceDigest":"sha256:e1afc4f75e34b69e32b605a553235e5abcc78a22997b12ac8b545d995615adfe","mode":"commit","note":"Install analysis.check_capability_feature_conformance, the no-drift check of the canonical features (dsl-capabilities-for-ov3-workflow-spec).","grantExecuteOn":["analysis.check_capability_feature_conformance"],"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"engineering-change","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}},"obligationIds":["O1"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-procedure","capabilityId":"read-declared-object-source","historicalBasis":"read-declared-object-source reports analysis.fv_object_definition_digest; each of the six newest procedure installs kept its retained source with CREATE OR ALTER PROCEDURE stored as CREATE PROCEDURE and every other byte unchanged (run 9e384ab2), so this source installs as this digest","input":{"objectName":"analysis.check_capability_feature_conformance"},"obligationIds":["O1"],"expect":{"path":"$.definitionDigest","equals":"sha256:ffd7c3a98c237784fcf6dd3b0b4f5e8414d728965e8aaf4f048ad43fe066a924"}},{"stepId":"declare-capability","capabilityId":"apply-declared-change","historicalBasis":"ledger 8704fa02-098a-4109-9c6c-bdbabbdc1cdc (2026-11-02T05:22:29.712): capture-estate-live-observation declared by capability-from-dsl (scaffold CREATE), one of 412 committed declarations (run fc518bd3); this DSL compiles COMPILED against the retained bytes of its feature with the revised compiler (run 8b8b7e11)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability check-capability-feature-conformance\nfeature check-capability-feature-conformance sha256:49bf06230349e792eeba7041a7f7ecf2cd2c894aa5635ae2ec5c5b2130ab02b9\nintent: Check a capability''s circuit against its canonical feature by identity, and accept each case only from the pinned evidence of its own call\noutcome: capability-feature-conformance.v1 CONFORMANT, DRIFT, WELL_FORMED, MALFORMED, NOT_BOUND, NOT_FOUND, ACCEPTED, REJECTED or BASELINE, with each finding named by its code and identity\ninquiry: Does this capability''s circuit drift from its canonical feature?\ninquiry: Which identity, step or case drifted, and where?\ninquiry: Does this run prove this case through its own call?\ninput contract check-capability-feature-conformance-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"capabilityId\":{\"type\":\"string\",\"minLength\":1,\"maxLength\":400},\"featureText\":{\"type\":\"string\",\"minLength\":1},\"featureDigest\":{\"type\":\"string\",\"pattern\":\"^sha256:[0-9a-f]{64}$\"},\"document\":{\"type\":\"object\"},\"acceptance\":{\"type\":\"object\"},\"evidenceText\":{\"type\":\"string\",\"minLength\":1},\"baseline\":{\"type\":\"object\"},\"explain\":{\"type\":\"boolean\"}}}\noutput contract capability-feature-conformance.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"capability-feature-conformance.v1\"},\"status\":{\"type\":\"string\"}}}\ncli display outcome as json\nscenario check-capability-feature-conformance root terminal\nvariants: CONFORMANT:success,DRIFT:success,WELL_FORMED:success,MALFORMED:success,NOT_BOUND:success,NOT_FOUND:success,ACCEPTED:success,REJECTED:success,BASELINE:success\ngiven: a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\nwhen: the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\nthen: CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\noperation check-capability-feature-conformance.check uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-estate-database\",\"statement\":\"SET ARITHABORT ON; DECLARE @estate_model_pk bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1); EXEC analysis.check_capability_feature_conformance @input=@input,@estate_model_pk=@estate_model_pk;\",\"resultColumn\":\"value\"}\ninput input from check-capability-feature-conformance $\noutcome from check-capability-feature-conformance.check $.value\n","isMcpTooling":true,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O2"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-declared","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns the stored compiled document (run 6d338754, compile-capability-dsl, document sha256:55ccc6fe...); a declaration stores the whole document by digest, feature pin included","input":{"capabilityId":"check-capability-feature-conformance"},"obligationIds":["O2"],"expect":{"path":"$.document.feature.digest","equals":"sha256:49bf06230349e792eeba7041a7f7ecf2cd2c894aa5635ae2ec5c5b2130ab02b9"}},{"stepId":"declare-browse-animal-collection","capabilityId":"apply-declared-change","historicalBasis":"ledger 8704fa02-098a-4109-9c6c-bdbabbdc1cdc (2026-11-02T05:22:29.712): capture-estate-live-observation declared by capability-from-dsl (scaffold CREATE); this DSL compiles COMPILED against the retained bytes of its feature with the revised compiler (nerdery/compile-cases.json), and its operation''s mechanics met every case of that feature read-only","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-browse-animal-collection\nfeature nerdery-browse-animal-collection sha256:dc19f2defcd1b0dcc5beead0fe42a0976336238216422d87397ccbcfcb7588c5\nintent: Browse and search the animal-definition collection, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)\noutcome: nerdery-browse-animal-collection-result.v1 LISTED or REFUSED, each refusal named by its reason code, so that I can see what I have collected and discover what remains\ninput contract nerdery-browse-animal-collection-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-browse-animal-collection-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-browse-animal-collection-result.v1\"},\"status\":{\"enum\":[\"LISTED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-browse-animal-collection root terminal\ngiven: a collection browse request\nwhen: the animal-definition collection is read for the authenticated user\nthen: the ordered matching collection is visible with only the information unlocked for that user or a named refusal\noperation nerdery-browse-animal-collection.browse uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-browse-animal-collection'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-browse-animal-collection $\noutcome from nerdery-browse-animal-collection.browse $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O3"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-browse-animal-collection","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns the stored compiled document (run 6d338754), and the declaration keeps its feature pin","input":{"capabilityId":"nerdery-browse-animal-collection"},"obligationIds":["O3"],"expect":{"path":"$.document.feature.digest","equals":"sha256:dc19f2defcd1b0dcc5beead0fe42a0976336238216422d87397ccbcfcb7588c5"}},{"stepId":"declare-view-animal-definition","capabilityId":"apply-declared-change","historicalBasis":"ledger 8704fa02-098a-4109-9c6c-bdbabbdc1cdc (2026-11-02T05:22:29.712): capture-estate-live-observation declared by capability-from-dsl (scaffold CREATE); this DSL compiles COMPILED against the retained bytes of its feature with the revised compiler (nerdery/compile-cases.json), and its operation''s mechanics met every case of that feature read-only","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-view-animal-definition\nfeature nerdery-view-animal-definition sha256:2b4c55fd4f28e46b17394b620ba9b9d78f854557b4c85a909989023a036472c5\nintent: View the information unlocked for an animal definition, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)\noutcome: nerdery-view-animal-definition-result.v1 VISIBLE or REFUSED, each refusal named by its reason code, so that I can learn from the animal information that my collection has unlocked\ninput contract nerdery-view-animal-definition-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-view-animal-definition-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-view-animal-definition-result.v1\"},\"status\":{\"enum\":[\"VISIBLE\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-view-animal-definition root terminal\ngiven: an animal definition identity\nwhen: the animal definition is read for the authenticated user\nthen: the permitted animal information is available or a named refusal explains why it cannot be viewed\noperation nerdery-view-animal-definition.view uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-view-animal-definition'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-view-animal-definition $\noutcome from nerdery-view-animal-definition.view $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O4"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-view-animal-definition","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns the stored compiled document (run 6d338754), and the declaration keeps its feature pin","input":{"capabilityId":"nerdery-view-animal-definition"},"obligationIds":["O4"],"expect":{"path":"$.document.feature.digest","equals":"sha256:2b4c55fd4f28e46b17394b620ba9b9d78f854557b4c85a909989023a036472c5"}},{"stepId":"declare-upload-encounter-photo","capabilityId":"apply-declared-change","historicalBasis":"ledger 8704fa02-098a-4109-9c6c-bdbabbdc1cdc (2026-11-02T05:22:29.712): capture-estate-live-observation declared by capability-from-dsl (scaffold CREATE); this DSL compiles COMPILED against the retained bytes of its feature with the revised compiler (nerdery/compile-cases.json), and its operation''s mechanics met every case of that feature read-only","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-upload-encounter-photo\nfeature nerdery-upload-encounter-photo sha256:38e58430acc3a39e88078f4a71000dacb3d585124a7a0cef2f906bcb35716de5\nintent: Retain a photo for an animal encounter, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)\noutcome: nerdery-upload-encounter-photo-result.v1 UPLOADED or REFUSED, each refusal named by its reason code, so that the photo can be attached to my recorded animal\ninput contract nerdery-upload-encounter-photo-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-upload-encounter-photo-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-upload-encounter-photo-result.v1\"},\"status\":{\"enum\":[\"UPLOADED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-upload-encounter-photo root terminal\ngiven: selected encounter photo bytes\nwhen: the encounter photo is uploaded for the authenticated user\nthen: an owned retained photo reference is available or a named refusal explains why it is not available\noperation nerdery-upload-encounter-photo.upload uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-upload-encounter-photo'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-upload-encounter-photo $\noutcome from nerdery-upload-encounter-photo.upload $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O5"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-upload-encounter-photo","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns the stored compiled document (run 6d338754), and the declaration keeps its feature pin","input":{"capabilityId":"nerdery-upload-encounter-photo"},"obligationIds":["O5"],"expect":{"path":"$.document.feature.digest","equals":"sha256:38e58430acc3a39e88078f4a71000dacb3d585124a7a0cef2f906bcb35716de5"}},{"stepId":"declare-record-animal-encounter","capabilityId":"apply-declared-change","historicalBasis":"ledger 8704fa02-098a-4109-9c6c-bdbabbdc1cdc (2026-11-02T05:22:29.712): capture-estate-live-observation declared by capability-from-dsl (scaffold CREATE); this DSL compiles COMPILED against the retained bytes of its feature with the revised compiler (nerdery/compile-cases.json), and its operation''s mechanics met every case of that feature read-only","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-record-animal-encounter\nfeature nerdery-record-animal-encounter sha256:df6cea9ceb5ce4d6a63755f8c42e80bc285191fecc18598e695ab6bd73e03a23\nintent: Record an animal encounter, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)\noutcome: nerdery-record-animal-encounter-result.v1 RECORDED or REFUSED, each refusal named by its reason code, so that the individual animal is in my collection\ninput contract nerdery-record-animal-encounter-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-record-animal-encounter-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-record-animal-encounter-result.v1\"},\"status\":{\"enum\":[\"RECORDED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-record-animal-encounter root terminal\ngiven: an encounter request with an animal selection, location, photo reference and optional nickname\nwhen: the animal encounter is recorded for the authenticated user\nthen: the individual animal is recorded once for this request or a named refusal leaves the collection unchanged\noperation nerdery-record-animal-encounter.record uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-record-animal-encounter'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-record-animal-encounter $\noutcome from nerdery-record-animal-encounter.record $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O6"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-record-animal-encounter","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns the stored compiled document (run 6d338754), and the declaration keeps its feature pin","input":{"capabilityId":"nerdery-record-animal-encounter"},"obligationIds":["O6"],"expect":{"path":"$.document.feature.digest","equals":"sha256:df6cea9ceb5ce4d6a63755f8c42e80bc285191fecc18598e695ab6bd73e03a23"}},{"stepId":"declare-view-collected-animals","capabilityId":"apply-declared-change","historicalBasis":"ledger 8704fa02-098a-4109-9c6c-bdbabbdc1cdc (2026-11-02T05:22:29.712): capture-estate-live-observation declared by capability-from-dsl (scaffold CREATE); this DSL compiles COMPILED against the retained bytes of its feature with the revised compiler (nerdery/compile-cases.json), and its operation''s mechanics met every case of that feature read-only","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-view-collected-animals\nfeature nerdery-view-collected-animals sha256:a8f1920e6569b46ab5924fe841bebd5cc63a0993accb26f5a2e78cd20bcd835c\nintent: View the individual animals in a personal collection, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)\noutcome: nerdery-view-collected-animals-result.v1 LISTED or REFUSED, each refusal named by its reason code, so that I recognize my animals by my photos and optional nicknames\ninput contract nerdery-view-collected-animals-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-view-collected-animals-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-view-collected-animals-result.v1\"},\"status\":{\"enum\":[\"LISTED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-view-collected-animals root terminal\ngiven: a personal collected-animals request\nwhen: the recorded individuals are read for the authenticated user\nthen: the user can view their individual collected animals or a named refusal\noperation nerdery-view-collected-animals.view uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-view-collected-animals'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-view-collected-animals $\noutcome from nerdery-view-collected-animals.view $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O7"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-view-collected-animals","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns the stored compiled document (run 6d338754), and the declaration keeps its feature pin","input":{"capabilityId":"nerdery-view-collected-animals"},"obligationIds":["O7"],"expect":{"path":"$.document.feature.digest","equals":"sha256:a8f1920e6569b46ab5924fe841bebd5cc63a0993accb26f5a2e78cd20bcd835c"}},{"stepId":"declare-set-animal-team","capabilityId":"apply-declared-change","historicalBasis":"ledger 8704fa02-098a-4109-9c6c-bdbabbdc1cdc (2026-11-02T05:22:29.712): capture-estate-live-observation declared by capability-from-dsl (scaffold CREATE); this DSL compiles COMPILED against the retained bytes of its feature with the revised compiler (nerdery/compile-cases.json), and its operation''s mechanics met every case of that feature read-only","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-set-animal-team\nfeature nerdery-set-animal-team sha256:6dd6c439568c45a7b63b8ad2745ac200f73c3d6d45e043d06b858cf0926048d2\nintent: Select a personal team of up to six collected animals, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)\noutcome: nerdery-set-animal-team-result.v1 SAVED or REFUSED, each refusal named by its reason code, so that my chosen animals can appear together on my home page\ninput contract nerdery-set-animal-team-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-set-animal-team-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-set-animal-team-result.v1\"},\"status\":{\"enum\":[\"SAVED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-set-animal-team root terminal\ngiven: a proposed team of collected encounter identities\nwhen: the team selection is saved for the authenticated user\nthen: the selected team of at most six animals is saved or a named refusal preserves the previous team\noperation nerdery-set-animal-team.set uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-set-animal-team'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-set-animal-team $\noutcome from nerdery-set-animal-team.set $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O8"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-set-animal-team","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns the stored compiled document (run 6d338754), and the declaration keeps its feature pin","input":{"capabilityId":"nerdery-set-animal-team"},"obligationIds":["O8"],"expect":{"path":"$.document.feature.digest","equals":"sha256:6dd6c439568c45a7b63b8ad2745ac200f73c3d6d45e043d06b858cf0926048d2"}},{"stepId":"declare-view-wildlife-home","capabilityId":"apply-declared-change","historicalBasis":"ledger 8704fa02-098a-4109-9c6c-bdbabbdc1cdc (2026-11-02T05:22:29.712): capture-estate-live-observation declared by capability-from-dsl (scaffold CREATE); this DSL compiles COMPILED against the retained bytes of its feature with the revised compiler (nerdery/compile-cases.json), and its operation''s mechanics met every case of that feature read-only","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-view-wildlife-home\nfeature nerdery-view-wildlife-home sha256:d91ded8a312cb3eca7c69a6004026db720227bfb8582623674705d6dfe7e4bc4\nintent: View the selected team on the wildlife home page, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)\noutcome: nerdery-view-wildlife-home-result.v1 VISIBLE or REFUSED, each refusal named by its reason code, so that my personal wildlife team is immediately recognizable\ninput contract nerdery-view-wildlife-home-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-view-wildlife-home-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-view-wildlife-home-result.v1\"},\"status\":{\"enum\":[\"VISIBLE\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-view-wildlife-home root terminal\ngiven: a wildlife home-page request\nwhen: the home-page experience is read for the authenticated user\nthen: the user sees their saved team or a named refusal\noperation nerdery-view-wildlife-home.view uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-view-wildlife-home'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-view-wildlife-home $\noutcome from nerdery-view-wildlife-home.view $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O9"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-view-wildlife-home","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns the stored compiled document (run 6d338754), and the declaration keeps its feature pin","input":{"capabilityId":"nerdery-view-wildlife-home"},"obligationIds":["O9"],"expect":{"path":"$.document.feature.digest","equals":"sha256:d91ded8a312cb3eca7c69a6004026db720227bfb8582623674705d6dfe7e4bc4"}},{"stepId":"declare-add-animal-definition","capabilityId":"apply-declared-change","historicalBasis":"ledger 8704fa02-098a-4109-9c6c-bdbabbdc1cdc (2026-11-02T05:22:29.712): capture-estate-live-observation declared by capability-from-dsl (scaffold CREATE); this DSL compiles COMPILED against the retained bytes of its feature with the revised compiler (nerdery/compile-cases.json), and its operation''s mechanics met every case of that feature read-only","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-add-animal-definition\nfeature nerdery-add-animal-definition sha256:cecfea79150494650b84f119ec59e26c742c7bc3822601f831aaf17ee1b2c4f2\nintent: Add an animal definition, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)\noutcome: nerdery-add-animal-definition-result.v1 ADDED or REFUSED, each refusal named by its reason code, so that users can discover and collect that animal\ninput contract nerdery-add-animal-definition-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-add-animal-definition-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-add-animal-definition-result.v1\"},\"status\":{\"enum\":[\"ADDED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-add-animal-definition root terminal\ngiven: a proposed animal definition\nwhen: the animal definition is added by the authenticated user\nthen: the new animal definition is available or a named refusal explains why it was not added\noperation nerdery-add-animal-definition.add uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-add-animal-definition'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-add-animal-definition $\noutcome from nerdery-add-animal-definition.add $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O10"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-add-animal-definition","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns the stored compiled document (run 6d338754), and the declaration keeps its feature pin","input":{"capabilityId":"nerdery-add-animal-definition"},"obligationIds":["O10"],"expect":{"path":"$.document.feature.digest","equals":"sha256:cecfea79150494650b84f119ec59e26c742c7bc3822601f831aaf17ee1b2c4f2"}}]';
SELECT N'plans' AS result_set,N'claude-code-opus-5-5-nerdery-slice' AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'0x8ffc4ac2cab7fec7524ebd222f6696070f94d6c6f11e6668715c24e1489bcd1f',1) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @r;
IF NOT EXISTS(SELECT 1 FROM @r WHERE plan_digest=CONVERT(binary(32),'0x8ffc4ac2cab7fec7524ebd222f6696070f94d6c6f11e6668715c24e1489bcd1f',1))
BEGIN
 RAISERROR(N'FAST2_PLAN_MISMATCH: the recorded plan is not the reviewed one; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
COMMIT TRANSACTION;
GO
SET NOEXEC OFF;
