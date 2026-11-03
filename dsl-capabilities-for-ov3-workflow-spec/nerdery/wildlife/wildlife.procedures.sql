-- The mechanics of the Nerdery citizen slice, schema wildlife in the sfx-identity database. One procedure per
-- capability operation takes the case request and the trusted wildlife user (NULL when no session was verified) and
-- returns the operation's result; wildlife.invoke_operation dispatches them and turns a storage failure into the
-- operation's named refusal; wildlife.serve is the only entry a capability statement calls: it verifies the caller's
-- session against [identity].session, maps the principal to its wildlife user and returns the result as value.
-- A refusal changes nothing; a write commits in one transaction or not at all.
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
