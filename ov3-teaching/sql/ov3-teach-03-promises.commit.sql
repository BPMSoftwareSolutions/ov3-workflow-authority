-- ov3-teach-03-promises.commit.sql
--
-- ============================== COMMIT - THIS INSTALLS ==============================
-- Byte-identical to the preflight twin except this banner and the terminal statement:
-- COMMIT TRANSACTION here, ROLLBACK TRANSACTION there. Run the preflight first.
--
-- WHAT THIS ADDS: the promise of the graph-topology-emission repair flight (revision 2 restores the content that
-- revision 1 lost). The promises of the other teaching flights were retained by ov3-teach-01 and are unchanged.
-- Each promise is one model.content_artifact row of kind flight-promise:<promiseId>, its text a flight-promise.v1 document
-- in source.content_object, so review-flight-plan finds the flight's promise. It runs the installed writer
-- model.mint_content_artifact (the writer behind content-artifact-change); nothing else is written. Re-running is
-- harmless: rows whose bytes already exist report EXISTING.
--
-- WHERE: the estate database (data source sfx-estate-database). Run the whole file in one session (SSMS or
-- sqlcmd); the transaction spans the batches.
--
-- BASE: model.mint_content_artifact sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e
-- (read-declared-object-source run 033f33fd, 2026-11-02). A moved base stops the script before any write.
--
-- RESULT SETS: base (installed and expected digest); minted (one row per promise: kind, action, digest, bytes);
-- readback (the newest row of each kind, decoded from its bytes; matches = 1 when it is the promise this file carries).
--
-- NEXT: ov3-teach-04-flight-plans on the sfx-identity database, then OV3 (ov3-teaching/README.md).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @installed varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'model.mint_content_artifact')) COLLATE Latin1_General_100_BIN2_UTF8)),2));
SELECT N'base' AS result_set,@installed AS installed_digest,'sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e' AS expected_base;
IF @installed IS NULL OR @installed<>'sha256:d6f8025a8c5e0d891a50d11df06dc0f2a1785eb7bdd977d0cd45e89eaca2516e'
BEGIN
 RAISERROR(N'OV3_TEACH_BASE_MOVED: model.mint_content_artifact is not the reviewed definition; read it before running this file.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
GO
DECLARE @minted TABLE(ordinal int IDENTITY(1,1),value nvarchar(max));
INSERT @minted(value) EXEC model.mint_content_artifact @document=N'{"artifactKind":"flight-promise:ov3-teach-gte-r2","text":"{\"contractId\":\"flight-promise.v1\",\"promiseId\":\"ov3-teach-gte-r2\",\"workClass\":\"skill-registration\",\"statement\":\"Skill graph-topology-emission has a revision 2 that retains its original content in full; revision 1 holds none.\",\"obligations\":[{\"obligationId\":\"O1\",\"statement\":\"Revision 2 is committed on base revision 1 through agent-specialization-change.\",\"evidence\":\"apply-declared-change disposition COMMITTED\"},{\"obligationId\":\"O2\",\"statement\":\"Revision 2 reads back with the original content.\",\"evidence\":\"read-agent-specializations {skillId, skillRevision: 2} contentDigest equals the base64 SHA-256 in manifest.json repairs\"}]}"}';
SELECT N'minted' AS result_set,ordinal,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,
 JSON_VALUE(value,'$.content_digest') AS content_digest,JSON_VALUE(value,'$.byte_length') AS byte_length FROM @minted ORDER BY ordinal;
SELECT N'readback' AS result_set,e.artifact_kind,e.expected_digest,N'sha256:'+LOWER(CONVERT(varchar(64),x.content_digest,2)) AS newest_digest,
 CASE WHEN x.content_digest=CONVERT(binary(32),e.expected_hex,1) THEN 1 ELSE 0 END AS matches,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),x.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.statement') AS statement
FROM (VALUES
 (N'flight-promise:ov3-teach-gte-r2','sha256:80ac32e79117de76ba78d05197022c00ab43e936025232bd81e0d9782772e146','0x80ac32e79117de76ba78d05197022c00ab43e936025232bd81e0d9782772e146')
) e(artifact_kind,expected_digest,expected_hex)
OUTER APPLY (SELECT TOP (1) a.content_digest,co.content_bytes FROM model.content_artifact a
 JOIN source.content_object co ON co.content_digest=a.content_digest
 WHERE a.artifact_kind=e.artifact_kind COLLATE Latin1_General_100_BIN2 ORDER BY a.registered_date DESC,a.content_artifact_pk DESC) x;
COMMIT TRANSACTION;
GO
SET NOEXEC OFF;
