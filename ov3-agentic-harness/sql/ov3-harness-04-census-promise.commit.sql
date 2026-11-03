-- ov3-harness-04-census-promise.commit.sql
--
-- ============================== COMMIT - THIS INSTALLS ==============================
-- Byte-identical to the preflight twin except this banner and the terminal statement:
-- COMMIT TRANSACTION here, ROLLBACK TRANSACTION there. Run the preflight first.
--
-- WHAT THIS ADDS: the promise of flight ov3-harness-census (flight-promise:ov3-harness-census) through the installed writer model.mint_content_artifact.
-- Nothing else is written. Re-running is harmless. WHERE: the estate database; run the whole file in one session.
-- BASE: model.mint_content_artifact sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e. RESULT SETS: base; minted (1 row); readback (matches = 1).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @installed varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'model.mint_content_artifact')) COLLATE Latin1_General_100_BIN2_UTF8)),2));
SELECT N'base' AS result_set,@installed AS installed_digest,'sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e' AS expected_base;
IF @installed IS NULL OR @installed<>'sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e'
BEGIN
 RAISERROR(N'OV3_HARNESS_BASE_MOVED: model.mint_content_artifact is not the reviewed definition.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
GO
DECLARE @minted TABLE(ordinal int IDENTITY(1,1),value nvarchar(max));
INSERT @minted(value) EXEC model.mint_content_artifact @document=N'{"artifactKind":"flight-promise:ov3-harness-census","text":"{\"contractId\":\"flight-promise.v1\",\"promiseId\":\"ov3-harness-census\",\"workClass\":\"owner-authorized-build-and-invoke\",\"statement\":\"OV3 writes the capability-area census of its complete agentic harness as data from the retained specification; a deterministic check passes it before it is retained and delivered; the owner decides at a declared decision point; the tracker records the change of plan.\",\"obligations\":[{\"obligationId\":\"O1\",\"statement\":\"The tracker records oah-long-bind done, the scope task superseded, and the census and its promotion as tasks.\",\"evidence\":\"project-tracking COMMITTED\"},{\"obligationId\":\"O2\",\"statement\":\"The census decision point is declared and reads back.\",\"evidence\":\"model-declare-semantic-object COMMITTED; analysis-read-selected-definition rows[0].declared_id\"},{\"obligationId\":\"O3\",\"statement\":\"OV3 writes the census as JSON and the deterministic check passes it.\",\"evidence\":\"read-spec found 1; ask-model MODEL_RESPONSE_OBTAINED; check-census CENSUS_READY\"},{\"obligationId\":\"O4\",\"statement\":\"The checked census is retained and delivered.\",\"evidence\":\"content-artifact-change COMMITTED; author-workspace-file AUTHORED\"},{\"obligationId\":\"O5\",\"statement\":\"The owner decides at the decision point.\",\"evidence\":\"await-owner-decision DECIDED\"}]}"}';
SELECT N'minted' AS result_set,ordinal,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,JSON_VALUE(value,'$.content_digest') AS content_digest FROM @minted;
SELECT N'readback' AS result_set,N'sha256:'+LOWER(CONVERT(varchar(64),x.content_digest,2)) AS newest_digest,CASE WHEN x.content_digest=CONVERT(binary(32),'0x1bdac2d60f6ad66ac15ba59f979ea88be159c4a4f4a15b5abb2ff85f2d94f368',1) THEN 1 ELSE 0 END AS matches
FROM (SELECT TOP (1) a.content_digest FROM model.content_artifact a WHERE a.artifact_kind=N'flight-promise:ov3-harness-census' COLLATE Latin1_General_100_BIN2 ORDER BY a.registered_date DESC,a.content_artifact_pk DESC) x;
COMMIT TRANSACTION;
GO
SET NOEXEC OFF;
