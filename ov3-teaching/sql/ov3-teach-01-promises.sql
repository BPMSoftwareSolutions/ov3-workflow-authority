-- ov3-teach-01-promises.sql
--
-- ============================== PREFLIGHT - NOT AN INSTALL ==============================
-- Byte-identical to the .commit twin except this banner and the terminal statement:
-- ROLLBACK TRANSACTION here, COMMIT TRANSACTION there. Nothing is written.
--
-- WHAT THIS ADDS: the promise rows of the 4 OV3 teaching flights for specification
-- ov3.estate-workflow-discovery.v1: one model.content_artifact row of kind flight-promise:<promiseId> per flight,
-- its text a flight-promise.v1 document in source.content_object, so review-flight-plan finds each flight's
-- promise. It runs the installed writer model.mint_content_artifact (the writer behind content-artifact-change);
-- nothing else is written. Re-running is harmless: rows whose bytes already exist report EXISTING.
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
-- NEXT: ov3-teach-02-flight-plans on the sfx-identity database, then OV3 (ov3-teaching/README.md).
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
INSERT @minted(value) EXEC model.mint_content_artifact @document=N'{"artifactKind":"flight-promise:ov3-teach-spec-skills-1","text":"{\"contractId\":\"flight-promise.v1\",\"promiseId\":\"ov3-teach-spec-skills-1\",\"workClass\":\"skill-registration\",\"statement\":\"The specification-pack skills spec-pack-intake and spec-capability-declaration are registered at revision 1 in sidefx:agents and their retained content is byte-identical to the reviewed files.\",\"obligations\":[{\"obligationId\":\"O1\",\"statement\":\"Each skill change is committed through agent-specialization-change.\",\"evidence\":\"apply-declared-change disposition COMMITTED for each file step\"},{\"obligationId\":\"O2\",\"statement\":\"Each skill revision 1 reads back with the reviewed content.\",\"evidence\":\"read-agent-specializations {skillId, skillRevision: 1} contentDigest equals the base64 SHA-256 in manifest.json\"}]}"}';
INSERT @minted(value) EXEC model.mint_content_artifact @document=N'{"artifactKind":"flight-promise:ov3-teach-spec-skills-2","text":"{\"contractId\":\"flight-promise.v1\",\"promiseId\":\"ov3-teach-spec-skills-2\",\"workClass\":\"skill-registration\",\"statement\":\"The specification-pack skills spec-scenario-topology and spec-acceptance-and-closure are registered at revision 1 in sidefx:agents and their retained content is byte-identical to the reviewed files.\",\"obligations\":[{\"obligationId\":\"O1\",\"statement\":\"Each skill change is committed through agent-specialization-change.\",\"evidence\":\"apply-declared-change disposition COMMITTED for each file step\"},{\"obligationId\":\"O2\",\"statement\":\"Each skill revision 1 reads back with the reviewed content.\",\"evidence\":\"read-agent-specializations {skillId, skillRevision: 1} contentDigest equals the base64 SHA-256 in manifest.json\"}]}"}';
INSERT @minted(value) EXEC model.mint_content_artifact @document=N'{"artifactKind":"flight-promise:ov3-teach-spec-project","text":"{\"contractId\":\"flight-promise.v1\",\"promiseId\":\"ov3-teach-spec-project\",\"workClass\":\"project-tracking\",\"statement\":\"Project ov3-estate-workflow-fidelity exists with its 16 tasks, each pinning the specification-pack skills at revision 1, with plan approval left to the owner.\",\"obligations\":[{\"obligationId\":\"O1\",\"statement\":\"The project and its tasks are committed through project-tracking.\",\"evidence\":\"apply-declared-change disposition COMMITTED, verified by read-project-tracker\"}]}"}';
INSERT @minted(value) EXEC model.mint_content_artifact @document=N'{"artifactKind":"flight-promise:wf-declare-discover-spec-estate-baseline","text":"{\"contractId\":\"flight-promise.v1\",\"promiseId\":\"wf-declare-discover-spec-estate-baseline\",\"workClass\":\"capability-build\",\"statement\":\"The workflow capability discover-spec-estate-baseline is declared - its run promise retained, its CAPABILITY_WORKFLOW in sidefx:workflows and its three-port capability document (MCP-flagged) - and its DSL projection is in the repository.\",\"obligations\":[{\"obligationId\":\"O1\",\"statement\":\"The run promise and the CAPABILITY_WORKFLOW declaration are retained and read back.\",\"evidence\":\"promise COMMITTED; model-declare-semantic-object COMMITTED; analysis-read-selected-definition rows[0].declared_id\"},{\"obligationId\":\"O2\",\"statement\":\"The capability is declared from its DSL and reads back with its first operation.\",\"evidence\":\"capability-from-dsl COMMITTED; read-declared-capability-document operations[0] = discover-spec-estate-baseline.start-request\"},{\"obligationId\":\"O3\",\"statement\":\"The DSL projection is authored into the repository.\",\"evidence\":\"author-workspace-file status AUTHORED\"}]}"}';
SELECT N'minted' AS result_set,ordinal,JSON_VALUE(value,'$.artifact_kind') AS artifact_kind,JSON_VALUE(value,'$.action') AS action,
 JSON_VALUE(value,'$.content_digest') AS content_digest,JSON_VALUE(value,'$.byte_length') AS byte_length FROM @minted ORDER BY ordinal;
SELECT N'readback' AS result_set,e.artifact_kind,e.expected_digest,N'sha256:'+LOWER(CONVERT(varchar(64),x.content_digest,2)) AS newest_digest,
 CASE WHEN x.content_digest=CONVERT(binary(32),e.expected_hex,1) THEN 1 ELSE 0 END AS matches,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),x.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.statement') AS statement
FROM (VALUES
 (N'flight-promise:ov3-teach-spec-skills-1','sha256:91e82306e19314f6f9c25b1a26e68c66c563f2cc89310b42860b313ae3a15740','0x91e82306e19314f6f9c25b1a26e68c66c563f2cc89310b42860b313ae3a15740'),
 (N'flight-promise:ov3-teach-spec-skills-2','sha256:87e812f662dedd4b31f01f4e4a2456908cc2b9089dede2c38898a74bf2d435d6','0x87e812f662dedd4b31f01f4e4a2456908cc2b9089dede2c38898a74bf2d435d6'),
 (N'flight-promise:ov3-teach-spec-project','sha256:69a95a57c92a36a0b387ddaeaf7fc78d803f3c1d342f3dd1e8b5545ab7da5417','0x69a95a57c92a36a0b387ddaeaf7fc78d803f3c1d342f3dd1e8b5545ab7da5417'),
 (N'flight-promise:wf-declare-discover-spec-estate-baseline','sha256:cd875854f7de609c067690925834a3c9939fe9e74696111f9ecb7c4218ba3ee6','0xcd875854f7de609c067690925834a3c9939fe9e74696111f9ecb7c4218ba3ee6')
) e(artifact_kind,expected_digest,expected_hex)
OUTER APPLY (SELECT TOP (1) a.content_digest,co.content_bytes FROM model.content_artifact a
 JOIN source.content_object co ON co.content_digest=a.content_digest
 WHERE a.artifact_kind=e.artifact_kind COLLATE Latin1_General_100_BIN2 ORDER BY a.registered_date DESC,a.content_artifact_pk DESC) x;
ROLLBACK TRANSACTION;
GO
SET NOEXEC OFF;
