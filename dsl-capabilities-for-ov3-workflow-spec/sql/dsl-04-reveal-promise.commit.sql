-- dsl-04-reveal-promise.commit.sql
--
-- ============================== COMMIT - THIS INSTALLS ==============================
-- Byte-identical to the preflight twin except this banner and the terminal statement:
-- COMMIT TRANSACTION here, ROLLBACK TRANSACTION there. Run the preflight first.
--
-- WHAT THIS ADDS: the promise of flight dsl-reveal-estate-workflows-draft (flight-promise:dsl-reveal-estate-workflows-draft) through the installed writer
-- model.mint_content_artifact. OV3 flies the flight; this file only records what it promises. Re-running is harmless.
-- WHERE: the estate database; run the whole file in one session.
-- BASE: model.mint_content_artifact sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e (read 2026-11-02, run de256508). RESULT SETS: base; minted (1 row);
-- readback (matches = 1).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @installed varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'model.mint_content_artifact')) COLLATE Latin1_General_100_BIN2_UTF8)),2));
SELECT N'base' AS result_set,@installed AS installed_digest,'sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e' AS expected_base;
IF @installed IS NULL OR @installed<>'sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e'
BEGIN
 RAISERROR(N'DSL04_BASE_MOVED: model.mint_content_artifact is not the reviewed definition; nothing is written.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
GO
DECLARE @minted TABLE(ordinal int IDENTITY(1,1),value nvarchar(max));
INSERT @minted(value) EXEC model.mint_content_artifact @document=N'{"artifactKind":"flight-promise:dsl-reveal-estate-workflows-draft","text":"{\"contractId\":\"flight-promise.v1\",\"promiseId\":\"dsl-reveal-estate-workflows-draft\",\"workClass\":\"capability-build\",\"statement\":\"OV3 drafts reveal-estate-workflows from the owner''s specification through draft-capability-from-spec and plans its build flight through plan-capability-flight, under agent ov3-network-reveal-estate-workflows: the draft is ready (its DSL compiles, its procedure is the one the DSL executes and its preflight applies and rolls back), and the build plan is recorded and reviewed CONFORMANT, with its plan report stored.\",\"obligations\":[{\"obligationId\":\"O1\",\"statement\":\"reveal-estate-workflows is drafted from the specification and the draft is ready.\",\"evidence\":\"draft-capability-from-spec ready true\"},{\"obligationId\":\"O2\",\"statement\":\"The build flight of reveal-estate-workflows is planned from the ready draft, recorded under agent ov3-network-reveal-estate-workflows and reviewed.\",\"evidence\":\"plan-capability-flight reviewVerdict CONFORMANT\"}]}"}';
SELECT N'minted' AS result_set,ordinal,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,JSON_VALUE(value,'$.content_digest') AS content_digest FROM @minted;
SELECT N'readback' AS result_set,N'sha256:'+LOWER(CONVERT(varchar(64),x.content_digest,2)) AS newest_digest,CASE WHEN x.content_digest=CONVERT(binary(32),'0x65d61b44fd05c43d02651e41b4f12e266f3c43428dbc6d0902b7935f4df842d9',1) THEN 1 ELSE 0 END AS matches
FROM (SELECT TOP (1) a.content_digest FROM model.content_artifact a WHERE a.artifact_kind=N'flight-promise:dsl-reveal-estate-workflows-draft' COLLATE Latin1_General_100_BIN2 ORDER BY a.registered_date DESC,a.content_artifact_pk DESC) x;
COMMIT TRANSACTION;
GO
SET NOEXEC OFF;
