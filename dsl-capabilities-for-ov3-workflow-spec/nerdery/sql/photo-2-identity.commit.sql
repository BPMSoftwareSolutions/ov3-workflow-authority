-- photo-2-identity.commit.sql
--
-- ============================== COMMIT - THIS WRITES ==============================
-- Byte-identical to the preflight twin except this banner and the terminal statement:
-- COMMIT TRANSACTION here, ROLLBACK TRANSACTION there. The preflight is optional: this file verifies everything inside
-- its transaction and keeps nothing when a check fails.
--
-- WHAT THIS DOES, in one transaction on the sfx-identity database:
--   1. installs wildlife.view_collected_animal, the mechanics of nerdery-view-collected-animal: one of the caller's own individuals with
--      the bytes of the photo it was recorded with (base64), its media type and digest; another user's individual is
--      answered ENCOUNTER_NOT_FOUND. Its texts met all 6 cases of the feature read-only (run ef3510aa);
--   2. alters wildlife.invoke_operation by two lines only: the dispatch to that procedure and its storage refusal;
--   3. verifies both bodies by digest and calls the new operation: Blake's own individual is VISIBLE with photo bytes whose
--      sha256 is the stored digest, Avery asking for it is refused, an anonymous call is refused, and home still answers;
--   4. records the plan of flight nerdery-collected-animal-photo-view under planner agent claude-code-opus-5-5-nerdery-slice through evidence.upsert_flight_plan:
--      declare the capability from its DSL and prove its stored document. The plan is nerdery/flights/individual.steps.json;
--      its digest is sha256:aa443b90cf0930cc05349f65195280f42b8ef644dbe910fdc286896e57f96b70.
-- RUN photo-1-estate FIRST. WHERE: sfx-identity. Run the whole file in one session (a few seconds).
-- BASES: wildlife.invoke_operation sha256:08ab8afd8e62318c55f718bbb953b80ecbb62359e8740ab74528acbf03c6ee62, no wildlife.view_collected_animal yet, the owner principal active,
-- the plan writer's four parameters, the agent's current plan sha256:d718a828997c60c867ae0b34c7202fc20c0f51b325dd4077e4ea351cb8605d56 (round 2 of the runtime repair, flown).
-- RESULT SETS: base; verify (digest_matches 1 each); smoke (every passed 1); plans (matches_reviewed_file 1).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @p uniqueidentifier='565de6d4-ebcd-408b-9359-04d21dc62183';
DECLARE @io nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.invoke_operation')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @io=SUBSTRING(@io,CHARINDEX(N'PROCEDURE wildlife.invoke_operation',@io),DATALENGTH(@io)/2);
WHILE DATALENGTH(@io)>0 AND RIGHT(@io,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @io=LEFT(@io,DATALENGTH(@io)/2-1);
DECLARE @io_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@io COLLATE Latin1_General_100_BIN2_UTF8)),2));
DECLARE @view int=CASE WHEN OBJECT_ID(N'wildlife.view_collected_animal') IS NULL THEN 0 ELSE 1 END;
DECLARE @owner int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id=@p AND active=1),
 @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));
DECLARE @current binary(32)=(SELECT plan_digest FROM evidence.flight_plan WHERE principal_id=@p AND agent_id=N'claude-code-opus-5-5-nerdery-slice');
SELECT N'base' AS result_set,@io_digest AS dispatcher_installed,@view AS view_procedure_exists,@owner AS owner_principal_active,@params AS plan_writer_parameters,
 N'sha256:'+LOWER(CONVERT(varchar(64),@current,2)) AS current_plan;
IF @io_digest IS NULL OR @io_digest<>'sha256:08ab8afd8e62318c55f718bbb953b80ecbb62359e8740ab74528acbf03c6ee62' OR @view<>0 OR @owner<>1 OR @params<>4 OR @current IS NULL OR @current<>CONVERT(binary(32),'d718a828997c60c867ae0b34c7202fc20c0f51b325dd4077e4ea351cb8605d56',2)
BEGIN
 RAISERROR(N'PHOTO2_BASE: the dispatcher, the view procedure, the owner principal, the plan writer or the agent''s current plan is not the reviewed base; nothing is changed.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
GO
CREATE OR ALTER PROCEDURE wildlife.view_collected_animal
  @request nvarchar(max),@user_id nvarchar(100),@result nvarchar(max) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @contract nvarchar(100)=N'nerdery-view-collected-animal-result.v1',@code nvarchar(60)=NULL;
  DECLARE @id nvarchar(100)=JSON_VALUE(@request,N'$.encounterId');
  IF @user_id IS NULL SET @code=N'AUTHENTICATION_REQUIRED';
  ELSE IF @id IS NULL OR LEN(@id)=0 SET @code=N'ENCOUNTER_SELECTION_REQUIRED';
  -- D05: another user's individual is answered as not found, so its existence is not revealed.
  ELSE IF NOT EXISTS(SELECT 1 FROM wildlife.encounter e WHERE e.owner_user_id=@user_id AND e.encounter_id=@id) SET @code=N'ENCOUNTER_NOT_FOUND';
  IF @code IS NOT NULL
  BEGIN
    SET @result=(SELECT @contract AS contractId,N'REFUSED' AS status,JSON_QUERY((SELECT @code AS code FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    RETURN;
  END
  -- D10: the individual is shown with the bytes of the owner's photo it was recorded with, base64 encoded by FOR JSON,
  -- and the media type and digest kept at upload.
  SET @result=(SELECT @contract AS contractId,N'VISIBLE' AS status,
    JSON_QUERY((SELECT e.encounter_id AS encounterId,e.owner_user_id AS ownerUserId,e.definition_id AS definitionId,d.common_name AS commonName,
        e.nickname AS nickname,ISNULL(e.nickname,d.common_name) AS displayName,JSON_QUERY(e.location_json) AS location,
        JSON_QUERY((SELECT p.photo_ref AS photoRef,p.media_type AS mediaType,p.byte_length AS byteLength,
            N'sha256:'+LOWER(CONVERT(varchar(64),p.content_sha256,2)) AS contentSha256,p.content_bytes AS contentBase64
          FROM wildlife.photo p WHERE p.photo_ref=e.photo_ref AND p.owner_user_id=e.owner_user_id
          FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS photo
      FROM wildlife.encounter e JOIN wildlife.animal_definition d ON d.definition_id=e.definition_id
      WHERE e.owner_user_id=@user_id AND e.encounter_id=@id
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES)) AS animal
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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
DECLARE @v1 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.view_collected_animal')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v1=SUBSTRING(@v1,CHARINDEX(N'PROCEDURE wildlife.view_collected_animal',@v1),DATALENGTH(@v1)/2);
WHILE DATALENGTH(@v1)>0 AND RIGHT(@v1,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v1=LEFT(@v1,DATALENGTH(@v1)/2-1);
DECLARE @v1_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v1 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.view_collected_animal',@v1_digest);
DECLARE @v2 nvarchar(max)=REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'wildlife.invoke_operation')),NCHAR(13)+NCHAR(10),NCHAR(10));
SET @v2=SUBSTRING(@v2,CHARINDEX(N'PROCEDURE wildlife.invoke_operation',@v2),DATALENGTH(@v2)/2);
WHILE DATALENGTH(@v2)>0 AND RIGHT(@v2,1) IN (NCHAR(10),NCHAR(13),NCHAR(32),NCHAR(9)) SET @v2=LEFT(@v2,DATALENGTH(@v2)/2-1);
DECLARE @v2_digest varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@v2 COLLATE Latin1_General_100_BIN2_UTF8)),2));
INSERT @digests VALUES(N'wildlife.invoke_operation',@v2_digest);
DECLARE @want TABLE(object_name nvarchar(200),digest varchar(80)); INSERT @want VALUES(N'wildlife.view_collected_animal','sha256:94428741aa3c0de4ff5bb9e30a12cfb5e917a188d6fe0c3d88e074c40d5b864e'),(N'wildlife.invoke_operation','sha256:ba3aa04ed0e8eecbce3e0165db43365513f97e522853838ba174f78b9d90350a');
SELECT N'verify' AS result_set,w.object_name,w.digest AS reviewed,d.digest AS installed,CASE WHEN d.digest=w.digest THEN 1 ELSE 0 END AS digest_matches FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name ORDER BY w.object_name;
DECLARE @smoke TABLE(o int IDENTITY(1,1),item nvarchar(200),actual nvarchar(400),expected nvarchar(400),passed bit);
DECLARE @r nvarchar(max);
DECLARE @t TABLE(v nvarchar(max));
EXEC wildlife.invoke_operation @operation=N'nerdery-view-collected-animal',@request=N'{"encounterId":"enc-008"}',@user_id=N'user-b',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Blake views his individual: $.status',JSON_VALUE(@r,N'$.status'),N'VISIBLE',CASE WHEN JSON_VALUE(@r,N'$.status')=N'VISIBLE' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'Blake views his individual: $.animal.photo.photoRef',JSON_VALUE(@r,N'$.animal.photo.photoRef'),N'photo-other',CASE WHEN JSON_VALUE(@r,N'$.animal.photo.photoRef')=N'photo-other' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'Blake views his individual: $.animal.photo.byteLength',JSON_VALUE(@r,N'$.animal.photo.byteLength'),N'73',CASE WHEN JSON_VALUE(@r,N'$.animal.photo.byteLength')=N'73' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'Blake views his individual: $.animal.photo.contentSha256',JSON_VALUE(@r,N'$.animal.photo.contentSha256'),N'sha256:bafa6c640062744ce1559dcdbb23cbddec6d7d1d6833661634feeef2553ecc68',CASE WHEN JSON_VALUE(@r,N'$.animal.photo.contentSha256')=N'sha256:bafa6c640062744ce1559dcdbb23cbddec6d7d1d6833661634feeef2553ecc68' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-view-collected-animal',@request=N'{"encounterId":"enc-008"}',@user_id=N'user-a',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Avery asks for Blake''s individual: $.status',JSON_VALUE(@r,N'$.status'),N'REFUSED',CASE WHEN JSON_VALUE(@r,N'$.status')=N'REFUSED' THEN 1 ELSE 0 END);
INSERT @smoke(item,actual,expected,passed) VALUES(N'Avery asks for Blake''s individual: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'ENCOUNTER_NOT_FOUND',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'ENCOUNTER_NOT_FOUND' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-view-collected-animal',@request=N'{}',@user_id=N'user-a',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'Avery names no encounter: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'ENCOUNTER_SELECTION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'ENCOUNTER_SELECTION_REQUIRED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-view-collected-animal',@request=N'{"encounterId":"enc-008"}',@user_id=N'user-b',@result=@r OUTPUT;
DECLARE @bytes varbinary(max)=(SELECT b FROM OPENJSON(@r) WITH (b varbinary(max) N'$.animal.photo.contentBase64'));
DECLARE @bytes_sha nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',@bytes),2));
INSERT @smoke(item,actual,expected,passed) VALUES(N'the returned bytes hash to the stored digest',@bytes_sha,JSON_VALUE(@r,N'$.animal.photo.contentSha256'),CASE WHEN @bytes_sha=JSON_VALUE(@r,N'$.animal.photo.contentSha256') THEN 1 ELSE 0 END);
INSERT @t EXEC wildlife.serve @operation=N'nerdery-view-collected-animal',@input=N'{"request":{"encounterId":"enc-008"}}';
SELECT @r=v FROM @t; DELETE @t;
INSERT @smoke(item,actual,expected,passed) VALUES(N'anonymous call: $.reason.code',JSON_VALUE(@r,N'$.reason.code'),N'AUTHENTICATION_REQUIRED',CASE WHEN JSON_VALUE(@r,N'$.reason.code')=N'AUTHENTICATION_REQUIRED' THEN 1 ELSE 0 END);
EXEC wildlife.invoke_operation @operation=N'nerdery-view-wildlife-home',@request=N'{}',@user_id=N'user-b',@result=@r OUTPUT;
INSERT @smoke(item,actual,expected,passed) VALUES(N'home as Blake still answers: $.status',JSON_VALUE(@r,N'$.status'),N'VISIBLE',CASE WHEN JSON_VALUE(@r,N'$.status')=N'VISIBLE' THEN 1 ELSE 0 END);
SELECT N'smoke' AS result_set,item,actual,expected,passed FROM @smoke ORDER BY o;
IF EXISTS(SELECT 1 FROM @want w LEFT JOIN @digests d ON d.object_name=w.object_name WHERE d.digest IS NULL OR d.digest<>w.digest) OR EXISTS(SELECT 1 FROM @smoke WHERE passed=0)
BEGIN
 RAISERROR(N'PHOTO2_VERIFY_FAILED: an installed body is not the reviewed text, or a call did not answer as tested; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
DECLARE @plans TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));
INSERT @plans EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=N'claude-code-opus-5-5-nerdery-slice',@objective=N'Declare nerdery-view-collected-animal, the view of one collected individual with the photo its owner uploaded, feature first through OV3''s own change: capability-from-dsl binds the retained bytes of its canonical feature and commits only when the check finds the binding CONFORMANT; prove the stored document is exactly the reviewed one by its digest.',
 @steps_json=N'[{"stepId":"plan-header","contractId":"estate-flight-plan.v1","promiseId":"nerdery-collected-animal-photo-view","flightType":"execution","workClass":"owner-objective","unknowns":[]},{"stepId":"declare-view-collected-animal","capabilityId":"apply-declared-change","historicalBasis":"the eight slice capabilities were declared this way by capability-from-dsl (flight 9810b9af, scaffold CREATE) and re-declared by the two runtime repair flights; this DSL compiles COMPILED to sha256:e6f62d7eb71418ca3a2cd7d5963af711b78feb2a7b529aee316e33844b68e796 against the retained bytes of its feature with the installed compiler (read-only run 2e4b4b4c, and again inside nerdery/sql/photo-1-estate), and its operation''s mechanics met every case of that feature read-only (run ef3510aa)","input":{"contractId":"declared-change.v1","changeKind":"capability-from-dsl","payload":{"contractId":"capability-from-dsl-change.v1","source":"capability nerdery-view-collected-animal\nfeature nerdery-view-collected-animal sha256:d01b38d276d161ba76402d4f3fbd10cd88a98f4c40c9f07e00f7f068b5874e45\nintent: View one collected individual with its photo, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)\noutcome: nerdery-view-collected-animal-result.v1 VISIBLE or REFUSED, each refusal named by its reason code, so that I see my own photo of the animal together with what I recorded about it\ninput contract nerdery-view-collected-animal-request.v1 {\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"request\"],\"properties\":{\"caller\":{\"type\":\"object\",\"additionalProperties\":false,\"properties\":{\"principalId\":{\"type\":\"string\"},\"sessionId\":{\"type\":\"string\"}}},\"request\":{\"type\":\"object\"}}}\noutput contract nerdery-view-collected-animal-result.v1 {\"type\":\"object\",\"additionalProperties\":true,\"required\":[\"contractId\",\"status\"],\"properties\":{\"contractId\":{\"const\":\"nerdery-view-collected-animal-result.v1\"},\"status\":{\"enum\":[\"VISIBLE\",\"REFUSED\"]}}}\ncli display outcome as json\nscenario nerdery-view-collected-animal root terminal\ngiven: a request to view one collected individual\nwhen: the individual and its stored photo are read for the authenticated user\nthen: the user can view the individual with its photo or a named refusal\noperation nerdery-view-collected-animal.view uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-identity-database\",\"statement\":\"EXEC wildlife.serve @operation=N''nerdery-view-collected-animal'',@input=@input;\",\"resultColumn\":\"value\"}\ninput input from nerdery-view-collected-animal $\noutcome from nerdery-view-collected-animal.view $.value\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}},"obligationIds":["O1"],"expect":{"path":"$.disposition","equals":"COMMITTED"}},{"stepId":"prove-view-collected-animal","capabilityId":"read-declared-capability-document","historicalBasis":"read-declared-capability-document returns documentDigest, the digest of the stored document, which equals the compiler''s documentDigest for the same source (the repair flights proved all eight slice capabilities this way)","input":{"capabilityId":"nerdery-view-collected-animal"},"obligationIds":["O1"],"expect":{"path":"$.documentDigest","equals":"sha256:e6f62d7eb71418ca3a2cd7d5963af711b78feb2a7b529aee316e33844b68e796"}}]';
SELECT N'plans' AS result_set,N'claude-code-opus-5-5-nerdery-slice' AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'aa443b90cf0930cc05349f65195280f42b8ef644dbe910fdc286896e57f96b70',2) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @plans;
IF NOT EXISTS(SELECT 1 FROM @plans WHERE plan_digest=CONVERT(binary(32),'aa443b90cf0930cc05349f65195280f42b8ef644dbe910fdc286896e57f96b70',2))
BEGIN
 RAISERROR(N'PHOTO2_PLAN_MISMATCH: the recorded plan is not the reviewed one; nothing is kept.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
COMMIT TRANSACTION;
GO
SET NOEXEC OFF;
