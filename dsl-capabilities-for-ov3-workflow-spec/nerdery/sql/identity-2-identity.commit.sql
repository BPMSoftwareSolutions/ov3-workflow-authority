-- identity-2-identity.commit.sql
--
-- ============================== COMMIT - THIS WRITES ==============================
-- Byte-identical to the preflight twin except this banner and the terminal statement:
-- COMMIT TRANSACTION here, ROLLBACK TRANSACTION there. The preflight is optional: this file verifies everything inside
-- its transaction and keeps nothing when a check fails.
--
-- WHAT THIS DOES, in one transaction on the sfx-identity database:
--   1. creates the DNR identity service's stand-in, wildlife.identity_response, with the identity responses of the
--      challenge fixtures (Avery, Casey, Drew, an invalid and an expired response), and wildlife.signed_in_session, the
--      wildlife user each verified SideFX session signed in as;
--   2. installs wildlife.sign_in_wildlife_user and wildlife.register_wildlife_user, whose texts met all 12 cases of
--      their features read-only (runs 8a8f1f45, 59995dd3, e8a9ae1e, d6230231);
--   3. alters wildlife.invoke_operation to dispatch them, and wildlife.serve to answer a verified session as the user
--      it signed in as (otherwise as the user its principal maps to, as before); the sixteen declared capabilities'
--      127 cases met their expectations again with these texts;
--   4. takes the biologist role from Avery again, who is a citizen: roles are assigned outside the application, and
--      Casey is the biologist;
--   5. verifies every body by digest and calls the operations, then removes the one sign-in the calls made;
--   6. records the plan of flight nerdery-dnr-sign-up-and-sign-in under planner agent claude-code-opus-5-5-nerdery-slice through evidence.upsert_flight_plan:
--      declare each capability from its DSL and prove its stored document. The plan is nerdery/flights/identity.steps.json;
--      its digest is sha256:e9ca57d9c0ef8e965a6b03132a39eab59e7cca1ee3d098e72b3effc557e17ba5.
-- RUN identity-1-estate FIRST. WHERE: sfx-identity. Run the whole file in one session (a few seconds).
-- BASES: wildlife.invoke_operation sha256:94124fa6bbda90585043ea20977906dabd620c2bec1649e0dae896b5ce362abc, wildlife.serve sha256:7a15adba12661fb75a59a9a92914082b96fdc8b834c45d7e4fb9c3703a9b6a2e, neither new table nor
-- procedure yet, the owner principal active, the plan writer's four parameters, the agent's current plan sha256:0442d1cbd50c5944662d30d85027fdd9fef4cf928ad558a8a8693b996c99b50f
-- (the catalog flight, flown).
-- RESULT SETS: base; responses (5 rows); verify (digest_matches 1 each); smoke (every passed 1); roles; plans (matches_reviewed_file 1).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @p uniqueidentifier='565de6d4-ebcd-408b-9359-04d21dc62183';
DECLARE @io nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.invoke_operation')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @io=SUBSTRING(@io,CHARINDEX(N'PROCEDURE wildlife.invoke_operation',@io),DATALENGTH(@io)/2);
WHILE DATALENGTH(@io)>0 AND RIGHT(@io,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @io=LEFT(@io,DATALENGTH(@io)/2-1);
DECLARE @io_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@io COLLATE Latin1_General_100_BIN2_UTF8)),2));
DECLARE @sv nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.serve')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @sv=SUBSTRING(@sv,CHARINDEX(N'PROCEDURE wildlife.serve',@sv),DATALENGTH(@sv)/2);
WHILE DATALENGTH(@sv)>0 AND RIGHT(@sv,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @sv=LEFT(@sv,DATALENGTH(@sv)/2-1);
DECLARE @sv_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@sv COLLATE Latin1_General_100_BIN2_UTF8)),2));
DECLARE @present int=(SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'wildlife') AND name IN (N'identity_response',N'signed_in_session',N'sign_in_wildlife_user',N'register_wildlife_user'));
DECLARE @owner int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id=@p AND active=1),
 @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));
DECLARE @current binary(32)=(SELECT plan_digest FROM evidence.flight_plan WHERE principal_id=@p AND agent_id=N'claude-code-opus-5-5-nerdery-slice');
SELECT N'base' AS result_set,@io_digest AS dispatcher_installed,@sv_digest AS serve_installed,@present AS new_objects_present,@owner AS owner_principal_active,
 @params AS plan_writer_parameters,N'sha256:'+LOWER(CONVERT(varchar(64),@current,2)) AS current_plan;
IF @io_digest IS NULL OR @io_digest<>'sha256:94124fa6bbda90585043ea20977906dabd620c2bec1649e0dae896b5ce362abc' OR @sv_digest IS NULL OR @sv_digest<>'sha256:7a15adba12661fb75a59a9a92914082b96fdc8b834c45d7e4fb9c3703a9b6a2e' OR @present<>0 OR @owner<>1 OR @params<>4
 OR @current IS NULL OR @current<>CONVERT(binary(32),'0442d1cbd50c5944662d30d85027fdd9fef4cf928ad558a8a8693b996c99b50f',2)
BEGIN
 RAISERROR(N'IDENTITY2_BASE: the dispatcher, serve, the new objects, the owner principal, the plan writer or the agent''s current plan is not the reviewed base; nothing is changed.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
EXEC(N'CREATE TABLE wildlife.identity_response(
  response_ref nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
  validation nvarchar(20) COLLATE Latin1_General_100_BIN2 NOT NULL,
  subject nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,
  first_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,
  last_name nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,
  email nvarchar(320) COLLATE Latin1_General_100_CI_AS NULL,
  roles_json nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL)');
EXEC(N'CREATE TABLE wildlife.signed_in_session(
  session_id uniqueidentifier NOT NULL PRIMARY KEY,
  user_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
  signed_in_at datetime2(3) NOT NULL)');
GO
SET NOCOUNT ON;
INSERT wildlife.identity_response(response_ref,validation,subject,first_name,last_name,email,roles_json) VALUES(N'identity-new',N'VALID',N'dnr:subject-new',N'Drew',N'Citizen',N'drew@example.test',N'["citizen"]');
INSERT wildlife.identity_response(response_ref,validation,subject,first_name,last_name,email,roles_json) VALUES(N'identity-a',N'VALID',N'dnr:subject-a',N'Avery',N'Citizen',N'avery@example.test',N'["citizen"]');
INSERT wildlife.identity_response(response_ref,validation,subject,first_name,last_name,email,roles_json) VALUES(N'identity-bio',N'VALID',N'dnr:subject-bio',N'Casey',N'Biologist',N'casey@example.test',N'["biologist"]');
INSERT wildlife.identity_response(response_ref,validation,subject,first_name,last_name,email,roles_json) VALUES(N'identity-invalid',N'INVALID',NULL,NULL,NULL,NULL,NULL);
INSERT wildlife.identity_response(response_ref,validation,subject,first_name,last_name,email,roles_json) VALUES(N'identity-expired',N'EXPIRED',NULL,NULL,NULL,NULL,NULL);
SELECT N'responses' AS result_set,response_ref,validation,subject,first_name,last_name,email,roles_json FROM wildlife.identity_response ORDER BY response_ref;
GO
CREATE OR ALTER PROCEDURE wildlife.sign_in_wildlife_user
  @request nvarchar(max),@session_id uniqueidentifier,@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-sign-in-wildlife-user-result.v1',@code nvarchar(60)=NULL;
  DECLARE @ref nvarchar(100)=JSON_VALUE(@request,N'$.identityResponseRef');
  DECLARE @validation nvarchar(20)=NULL,@subject nvarchar(200)=NULL,@user_id nvarchar(100)=NULL;
  -- D02: the DNR response is resolved and validated on the server; the application keeps no passwords. Only a
  -- validated response for a registered wildlife user starts a session, bound to the verified SideFX session.
  IF @ref IS NULL OR LEN(LTRIM(RTRIM(@ref)))=0 SET @code=N'IDENTITY_RESPONSE_REQUIRED';
  ELSE
  BEGIN
    SELECT @validation=r.validation,@subject=r.subject FROM wildlife.identity_response r WHERE r.response_ref=@ref;
    IF @validation=N'EXPIRED' SET @code=N'IDENTITY_RESPONSE_EXPIRED';
    ELSE IF @validation IS NULL OR @validation<>N'VALID' SET @code=N'IDENTITY_NOT_VALIDATED';
    ELSE
    BEGIN
      SELECT @user_id=u.user_id FROM wildlife.app_user u WHERE u.identity_subject=@subject;
      IF @user_id IS NULL SET @code=N'REGISTRATION_REQUIRED';
      ELSE IF @session_id IS NULL SET @code=N'SESSION_REQUIRED';
    END
  END
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      JSON_QUERY(N'{"established":false}') AS session FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  UPDATE wildlife.signed_in_session SET user_id=@user_id,signed_in_at=SYSUTCDATETIME() WHERE session_id=@session_id;
  IF @@ROWCOUNT=0 INSERT wildlife.signed_in_session(session_id,user_id,signed_in_at) VALUES(@session_id,@user_id,SYSUTCDATETIME());
  SET @result=(SELECT @contract AS contractId,N'SIGNED_IN' AS status,
    JSON_QUERY((SELECT u.user_id AS userId,u.first_name AS firstName,u.last_name AS lastName,u.email,
      JSON_QUERY(ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(r.role,'json')+N'"'),N',') WITHIN GROUP (ORDER BY r.role)+N']'
        FROM wildlife.user_role r WHERE r.user_id=u.user_id),N'[]')) AS roles
      FROM wildlife.app_user u WHERE u.user_id=@user_id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS [user],
    JSON_QUERY(N'{"established":true}') AS session FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.register_wildlife_user
  @request nvarchar(max),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-register-wildlife-user-result.v1',@code nvarchar(60)=NULL;
  DECLARE @ref nvarchar(100)=JSON_VALUE(@request,N'$.identityResponseRef');
  DECLARE @validation nvarchar(20)=NULL,@subject nvarchar(200)=NULL,@first nvarchar(200)=NULL,@last nvarchar(200)=NULL,@email nvarchar(320)=NULL,@roles nvarchar(max)=NULL;
  -- A validated DNR subject not yet registered becomes a wildlife user with the required profile and a unique email;
  -- its roles are the ones DNR assigns, managed outside the application.
  IF @ref IS NULL OR LEN(LTRIM(RTRIM(@ref)))=0 SET @code=N'IDENTITY_RESPONSE_REQUIRED';
  ELSE
  BEGIN
    SELECT @validation=r.validation,@subject=r.subject,@first=r.first_name,@last=r.last_name,@email=r.email,@roles=r.roles_json
    FROM wildlife.identity_response r WHERE r.response_ref=@ref;
    IF @validation=N'EXPIRED' SET @code=N'IDENTITY_RESPONSE_EXPIRED';
    ELSE IF @validation IS NULL OR @validation<>N'VALID' SET @code=N'IDENTITY_NOT_VALIDATED';
    ELSE IF EXISTS(SELECT 1 FROM wildlife.app_user u WHERE u.identity_subject=@subject) SET @code=N'ALREADY_REGISTERED';
    ELSE IF LEN(LTRIM(RTRIM(ISNULL(@first,N''))))=0 OR LEN(LTRIM(RTRIM(ISNULL(@last,N''))))=0 OR LEN(LTRIM(RTRIM(ISNULL(@email,N''))))=0
      SET @code=N'USER_PROFILE_INCOMPLETE';
    ELSE IF EXISTS(SELECT 1 FROM wildlife.app_user u WHERE LTRIM(RTRIM(u.email))=LTRIM(RTRIM(@email)) COLLATE Latin1_General_100_CI_AS) SET @code=N'EMAIL_NOT_UNIQUE';
  END
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  DECLARE @id nvarchar(100)=N'user-'+LOWER(LEFT(REPLACE(CONVERT(nvarchar(36),NEWID()),N'-',N''),8)),@tc int=@@TRANCOUNT;
  BEGIN TRY
    IF @tc=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION wildlife_register;
    INSERT wildlife.app_user(user_id,principal_id,identity_subject,first_name,last_name,email) VALUES(@id,NULL,@subject,@first,@last,@email);
    INSERT wildlife.user_role(user_id,role) SELECT DISTINCT @id,[value] FROM OPENJSON(ISNULL(@roles,N'[]')) WHERE [type]=1;
    IF @tc=0 COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE()=-1 OR (@tc=0 AND @@TRANCOUNT>0) ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION wildlife_register;
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY(N'{"code":"USER_STORAGE_UNAVAILABLE"}') AS reason,
      JSON_QUERY(N'{"applied":false}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END CATCH
  SET @result=(SELECT @contract AS contractId,N'REGISTERED' AS status,
    JSON_QUERY((SELECT u.user_id AS userId,u.first_name AS firstName,u.last_name AS lastName,u.email,
      JSON_QUERY(ISNULL((SELECT N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(r.role,'json')+N'"'),N',') WITHIN GROUP (ORDER BY r.role)+N']'
        FROM wildlife.user_role r WHERE r.user_id=u.user_id),N'[]')) AS roles
      FROM wildlife.app_user u WHERE u.user_id=@id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS [user],
    JSON_QUERY(N'{"applied":true}') AS mutation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE wildlife.invoke_operation
  @operation nvarchar(100),@request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT,@session_id uniqueidentifier=NULL
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
    ELSE IF @operation=N'nerdery-sign-in-wildlife-user' EXEC wildlife.sign_in_wildlife_user @request=@request,@session_id=@session_id,@result=@result OUTPUT;
    ELSE IF @operation=N'nerdery-register-wildlife-user' EXEC wildlife.register_wildlife_user @request=@request,@result=@result OUTPUT;
    ELSE SET @result=(SELECT N'REFUSED' AS status,JSON_QUERY(N'{"code":"OPERATION_NOT_DECLARED"}') AS reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END TRY
  BEGIN CATCH
    -- A store that cannot be read or written answers the operation's own storage refusal; nothing is kept.
    IF @@TRANCOUNT>@tc ROLLBACK TRANSACTION;
    DECLARE @write bit=CASE WHEN @operation IN (N'nerdery-upload-encounter-photo',N'nerdery-record-animal-encounter',N'nerdery-set-animal-team',N'nerdery-add-animal-definition',
      N'nerdery-update-animal-definition',N'nerdery-remove-animal-definition',N'nerdery-add-animal-attribute',N'nerdery-update-animal-attribute',N'nerdery-remove-animal-attribute',
      N'nerdery-register-wildlife-user') THEN 1 ELSE 0 END;
    SET @result=(SELECT @operation+N'-result.v1' AS contractId,N'REFUSED' AS status,
      JSON_QUERY((SELECT CASE @operation
        WHEN N'nerdery-upload-encounter-photo' THEN N'PHOTO_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-record-animal-encounter' THEN N'COLLECTION_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-view-collected-animals' THEN N'COLLECTION_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-view-collected-animal' THEN N'COLLECTION_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-set-animal-team' THEN N'TEAM_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-view-wildlife-home' THEN N'TEAM_STORAGE_UNAVAILABLE'
        WHEN N'nerdery-sign-in-wildlife-user' THEN N'IDENTITY_SERVICE_UNAVAILABLE'
        WHEN N'nerdery-register-wildlife-user' THEN N'IDENTITY_SERVICE_UNAVAILABLE'
        ELSE N'CATALOG_STORAGE_UNAVAILABLE' END AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason,
      JSON_QUERY(CASE WHEN @write=1 THEN N'{"applied":false}' END) AS mutation,
      JSON_QUERY(CASE WHEN @operation=N'nerdery-sign-in-wildlife-user' THEN N'{"established":false}' END) AS session FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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
  -- verified again here, so a run admitted with someone else's principalId is anonymous. A verified session answers
  -- as the wildlife user it signed in as through DNR, otherwise as the wildlife user its principal maps to; a
  -- verified principal with neither is anonymous too.
  DECLARE @principal uniqueidentifier=TRY_CONVERT(uniqueidentifier,JSON_VALUE(@input,N'$.caller.principalId')),
    @session uniqueidentifier=TRY_CONVERT(uniqueidentifier,JSON_VALUE(@input,N'$.caller.sessionId')),@user_id nvarchar(100)=NULL,@result nvarchar(max),
    @verified uniqueidentifier=NULL;
  IF @principal IS NOT NULL AND @session IS NOT NULL AND EXISTS(SELECT 1 FROM [identity].session s
      JOIN [identity].principal p ON p.principal_id=s.principal_id AND p.active=1
      WHERE s.session_id=@session AND s.principal_id=@principal AND s.revoked_at IS NULL AND s.expires_at>SYSUTCDATETIME())
    SET @verified=@session;
  IF @verified IS NOT NULL
  BEGIN
    SELECT @user_id=su.user_id FROM wildlife.signed_in_session su WHERE su.session_id=@verified;
    IF @user_id IS NULL SELECT @user_id=u.user_id FROM wildlife.app_user u WHERE u.principal_id=@principal;
  END
  DECLARE @request nvarchar(max)=ISNULL(JSON_QUERY(@input,N'$.request'),N'{}');
  EXEC wildlife.invoke_operation @operation=@operation,@request=@request,@user_id=@user_id,@result=@result OUTPUT,@session_id=@verified;
  SELECT @result AS value;
END;
GO
SET NOCOUNT ON;
DECLARE @p uniqueidentifier='565de6d4-ebcd-408b-9359-04d21dc62183';
DELETE wildlife.user_role WHERE user_id=N'user-a' AND role=N'biologist';
DECLARE @digests TABLE(object_name nvarchar(200),digest varchar(80));
DECLARE @v0 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.sign_in_wildlife_user')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v0=SUBSTRING(@v0,CHARINDEX(N'PROCEDURE wildlife.sign_in_wildlife_user',@v0),DATALENGTH(@v0)/2);
WHILE DATALENGTH(@v0)>0 AND RIGHT(@v0,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v0=LEFT(@v0,DATALENGTH(@v0)/2-1);
DECLARE @v0_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v0 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.sign_in_wildlife_user',@v0_digest);
DECLARE @v1 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.register_wildlife_user')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v1=SUBSTRING(@v1,CHARINDEX(N'PROCEDURE wildlife.register_wildlife_user',@v1),DATALENGTH(@v1)/2);
WHILE DATALENGTH(@v1)>0 AND RIGHT(@v1,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v1=LEFT(@v1,DATALENGTH(@v1)/2-1);
DECLARE @v1_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v1 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.register_wildlife_user',@v1_digest);
DECLARE @v2 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.invoke_operation')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v2=SUBSTRING(@v2,CHARINDEX(N'PROCEDURE wildlife.invoke_operation',@v2),DATALENGTH(@v2)/2);
WHILE DATALENGTH(@v2)>0 AND RIGHT(@v2,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v2=LEFT(@v2,DATALENGTH(@v2)/2-1);
DECLARE @v2_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v2 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.invoke_operation',@v2_digest);
DECLARE @v3 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.serve')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v3=SUBSTRING(@v3,CHARINDEX(N'PROCEDURE wildlife.serve',@v3),DATALENGTH(@v3)/2);
WHILE DATALENGTH(@v3)>0 AND RIGHT(@v3,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v3=LEFT(@v3,DATALENGTH(@v3)/2-1);
DECLARE @v3_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v3 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.serve',@v3_digest);
DECLARE @want TABLE(object_name nvarchar(200),digest varchar(80)); INSERT @want VALUES(N'wildlife.sign_in_wildlife_user','sha256:ea56712a04ba63500624e119d16fed3302fe9923362a83d7889d70037b1b38e1'),(N'wildlife.register_wildlife_user','sha256:d451fa2fa59507ef23918fb31fef002cf6dcbb5e18664654f58134ee424a5b58'),(N'wildlife.invoke_operation','sha256:ca0635e20192eaf0e83365e854e0dafc2c476b4d1e868aed0d03de7bc8f7a42f'),(N'wildlife.serve','sha256:11855a662ba65400021d2b850c0010079b517670788677e71585317cc57ee1e8');
SELECT N'verify' AS result_set,w.object_name,w.digest AS reviewed,d.digest AS installed,CASE WHEN d.digest=w.digest THEN 1 ELSE 0 END AS digest_matches FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name ORDER BY w.object_name;
DECLARE @smoke TABLE(o int IDENTITY(1,1),item nvarchar(200),actual nvarchar(400),expected nvarchar(400),passed bit);
DECLARE @r nvarchar(max),@sid uniqueidentifier=NEWID();
DECLARE @t TABLE(v nvarchar(max));
EXEC wildlife.invoke_operation @operation=N'nerdery-sign-in-wildlife-user',@request=N'{"identityResponseRef":"identity-bio"}',@user_id=NULL,@result=@r OUTPUT,@session_id=@sid;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Casey signs in through DNR: $.status',JSON_VALUE(@r,N'$.status'),N'SIGNED_IN',CASE WHEN JSON_VALUE(@r,N'$.status')=N'SIGNED_IN' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'Casey signs in through DNR: $.user.userId',JSON_VALUE(@r,N'$.user.userId'),N'user-bio',CASE WHEN JSON_VALUE(@r,N'$.user.userId')=N'user-bio' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-sign-in-wildlife-user',@request=N'{"identityResponseRef":"identity-expired"}',@user_id=NULL,@result=@r OUTPUT,@session_id=@sid;
INSERT @smoke(item,actual,expected,passed) VALUES(N'An expired DNR response: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'IDENTITY_RESPONSE_EXPIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'IDENTITY_RESPONSE_EXPIRED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-sign-in-wildlife-user',@request=N'{"identityResponseRef":"identity-invalid"}',@user_id=NULL,@result=@r OUTPUT,@session_id=@sid;
INSERT @smoke(item,actual,expected,passed) VALUES(N'A DNR response that did not validate: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'IDENTITY_NOT_VALIDATED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'IDENTITY_NOT_VALIDATED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-sign-in-wildlife-user',@request=N'{"identityResponseRef":"identity-new"}',@user_id=NULL,@result=@r OUTPUT,@session_id=@sid;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Drew signs in before registering: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'REGISTRATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'REGISTRATION_REQUIRED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-register-wildlife-user',@request=N'{"identityResponseRef":"identity-a"}',@user_id=NULL,@result=@r OUTPUT,@session_id=@sid;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Avery registers again: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'ALREADY_REGISTERED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'ALREADY_REGISTERED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-resolve-wildlife-access',@request=N'{"section":"animal-definitions-admin"}',@user_id=N'user-a',@result=@r OUTPUT,@session_id=@sid;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Avery opens the definitions administration: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'BIOLOGIST_ROLE_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'BIOLOGIST_ROLE_REQUIRED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-resolve-wildlife-access',@request=N'{"section":"animal-definitions-admin"}',@user_id=N'user-bio',@result=@r OUTPUT,@session_id=@sid;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Casey opens the definitions administration: $.status',JSON_VALUE(@r,N'$.status'),N'ALLOWED',CASE WHEN JSON_VALUE(@r,N'$.status')=N'ALLOWED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-resolve-wildlife-access',@request=N'{"section":"team"}',@user_id=N'user-a',@result=@r OUTPUT,@session_id=@sid;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Avery opens her team: $.status',JSON_VALUE(@r,N'$.status'),N'ALLOWED',CASE WHEN JSON_VALUE(@r,N'$.status')=N'ALLOWED' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'the sign-in bound its session to Casey',(SELECT user_id FROM wildlife.signed_in_session WHERE session_id=@sid),N'user-bio',CASE WHEN (SELECT user_id FROM wildlife.signed_in_session WHERE session_id=@sid)=N'user-bio' THEN 1 ELSE 0 END);
DELETE wildlife.signed_in_session WHERE session_id=@sid;
INSERT @t EXEC wildlife.serve @operation=N'nerdery-browse-animal-collection',@input=N'{"request":{"search":""}}';
SELECT @r=v FROM @t; DELETE @t;
INSERT @smoke(item,actual,expected,passed) VALUES(N'anonymous call: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'AUTHENTICATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'AUTHENTICATION_REQUIRED' THEN 1 ELSE 0 END);
DECLARE @forged nvarchar(max)=N'{"caller":{"principalId":"565de6d4-ebcd-408b-9359-04d21dc62183","sessionId":"'+CONVERT(nvarchar(36),NEWID())+N'"},"request":{"search":""}}';
INSERT @t EXEC wildlife.serve @operation=N'nerdery-browse-animal-collection',@input=@forged;
SELECT @r=v FROM @t; DELETE @t;
INSERT @smoke(item,actual,expected,passed) VALUES(N'owner principal with an unknown session: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'AUTHENTICATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'AUTHENTICATION_REQUIRED' THEN 1 ELSE 0 END);
SELECT N'smoke' AS result_set,item,actual,expected,passed FROM @smoke ORDER BY o;
SELECT N'roles' AS result_set,user_id,role FROM wildlife.user_role ORDER BY user_id,role;
IF EXISTS(SELECT 1 FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name WHERE d.digest IS NULL OR d.digest<>w.digest) OR EXISTS(SELECT 1 FROM @smoke WHERE passed=0)
 OR (SELECT COUNT(*) FROM wildlife.identity_response)<>5 OR EXISTS(SELECT 1 FROM wildlife.user_role WHERE user_id=N'user-a' AND role=N'biologist')
BEGIN
 RAISERROR(N'IDENTITY2_VERIFY_FAILED: an installed body, a call, the stand-in''s responses or Avery''s role is not as reviewed; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
DECLARE @plans TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));
INSERT @plans EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=N'claude-code-opus-5-5-nerdery-slice',@objective=N'Declare sign-up and sign-in for the Nerdery wildlife application through the DNR identity service, feature first through OV3''s own changes: nerdery-register-wildlife-user and nerdery-sign-in-wildlife-user, each with capability-from-dsl, which binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT; prove each stored document is exactly the reviewed one by its digest.',
 @steps_json=N'[{"stepId":"plan-header","contractId":"estate-flight-plan.v1","promiseId":"nerdery-dnr-sign-up-and-sign-in","flightType":"execution","workClass":"owner-objective","unknowns":[]},{"stepId":"declare-sign-in-wildlife-user","capabilityId":"apply-declared-change","historicalBasis":"the wildlife capabilities were declared this way by capability-from-dsl (flight 9810b9af, the photo flight and the catalog flight, plan sha256:0442d1cb); this DSL compiles COMPILED to sha256:8d80e177396ad14f72b937aab911022b68f12b34b25fcd03628a9b8c21f389d9 against the retained bytes of its feature with the installed compiler (read-only run 1dd86a71), and its operation''s mechanics met every case of that feature read-only (runs 8a8f1f45, 59995dd3, e8a9ae1e, d6230231)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-sign-in-wildlife-user\nfeature nerdery-sign-in-wildlife-user sha256:bf9ff42f4a1c96eec6cb938f3bf40e57b8c13aed9b94e4a64dc73f90b6250cd6\nintent: Sign in to the wildlife application, for the caller whose session the declared API operation verified (Nerdery wildlife application)\noutcome: nerdery-sign-in-wildlife-user-result.v1 SIGNED_IN or REFUSED, each refusal named by its reason code, so that I can use my own collection and team\ninput contract nerdery-sign-in-wildlife-user-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-sign-in-wildlife-user-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-sign-in-wildlife-user-result.v1\"},\"status\":{\"enum\":[\"SIGNED_IN\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-sign-in-wildlife-user root terminal\ngiven: a DNR sign-in response reference\nwhen: the wildlife sign-in is completed\nthen: the user has an authenticated application session or a named sign-in refusal\noperation nerdery-sign-in-wildlife-user.sign-in uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-sign-in-wildlife-user'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-sign-in-wildlife-user $\noutcome from nerdery-sign-in-wildlife-user.sign-in $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O1"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-sign-in-wildlife-user","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler''s documentDigest for the same source (the earlier wildlife flights proved theirs this way)","input":{"capabilityId":"nerdery-sign-in-wildlife-user"},"obligationIds":["O1"],"expect":{"path":"$.documentDigest","equals":"sha256:8d80e177396ad14f72b937aab911022b68f12b34b25fcd03628a9b8c21f389d9"}},{"stepId":"declare-register-wildlife-user","capabilityId":"apply-declared-change","historicalBasis":"the wildlife capabilities were declared this way by capability-from-dsl (flight 9810b9af, the photo flight and the catalog flight, plan sha256:0442d1cb); this DSL compiles COMPILED to sha256:a015138ada6c7327a6c802401f08a1e213d537d7c3b3dac8cee6be7ee555bb01 against the retained bytes of its feature with the installed compiler (read-only run 3a10274e), and its operation''s mechanics met every case of that feature read-only (runs 8a8f1f45, 59995dd3, e8a9ae1e, d6230231)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-register-wildlife-user\nfeature nerdery-register-wildlife-user sha256:24ce719da85308c66551cae6d5f38a8477765ebff52dd7308e68db2dd7e0c666\nintent: Register a wildlife user through the DNR identity service, for the caller whose session the declared API operation verified (Nerdery wildlife application)\noutcome: nerdery-register-wildlife-user-result.v1 REGISTERED or REFUSED, each refusal named by its reason code, so that I can keep my own wildlife collection\ninput contract nerdery-register-wildlife-user-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-register-wildlife-user-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-register-wildlife-user-result.v1\"},\"status\":{\"enum\":[\"REGISTERED\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-register-wildlife-user root terminal\ngiven: a DNR registration response reference\nwhen: the wildlife account registration is completed\nthen: the user has one wildlife account or a named registration refusal\noperation nerdery-register-wildlife-user.register uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-register-wildlife-user'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-register-wildlife-user $\noutcome from nerdery-register-wildlife-user.register $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O2"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-register-wildlife-user","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler''s documentDigest for the same source (the earlier wildlife flights proved theirs this way)","input":{"capabilityId":"nerdery-register-wildlife-user"},"obligationIds":["O2"],"expect":{"path":"$.documentDigest","equals":"sha256:a015138ada6c7327a6c802401f08a1e213d537d7c3b3dac8cee6be7ee555bb01"}}]';
SELECT N'plans' AS result_set,N'claude-code-opus-5-5-nerdery-slice' AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'e9ca57d9c0ef8e965a6b03132a39eab59e7cca1ee3d098e72b3effc557e17ba5',2) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @plans;
IF NOT EXISTS(SELECT 1 FROM @plans WHERE plan_digest=CONVERT(binary(32),'e9ca57d9c0ef8e965a6b03132a39eab59e7cca1ee3d098e72b3effc557e17ba5',2))
BEGIN
 RAISERROR(N'IDENTITY2_PLAN_MISMATCH: the recorded plan is not the reviewed one; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
COMMIT TRANSACTION;
GO
SET NOEXEC OFF;
