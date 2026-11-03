-- dsl-11-check-first-call-plan.sql
--
-- ============================== PREFLIGHT - NOT A WRITE ==============================
-- Byte-identical to the .commit twin except this banner and the terminal statement:
-- ROLLBACK TRANSACTION here, COMMIT TRANSACTION there. Nothing is written.
--
-- WHAT THIS ADDS: the first-call plan of flight dsl-check-capability-feature-conformance-first-call (work class owner-objective), the next revision under
-- planner agent claude-code-opus-5-5-dsl-check-build, through the installed writer evidence.upsert_flight_plan. It approves nothing and flies
-- nothing. The plan is flights/check-first-call.steps.json; its digest is
-- sha256:9fa79faa22669f5ea5ff560c7c8dd11d5c280e11a594a53cf3d3fd7061913194.
-- RUN IT ONLY AFTER the build flight (dsl-10) closed: OV3 then calls check-capability-feature-conformance twice, for itself and for
-- compile-capability-dsl.
-- WHERE: the sfx-identity database. GUARD: the writer has its four parameters, the owner principal is active, and the
-- agent's current plan is the build plan of dsl-10 (or this plan, when re-run).
-- RESULT SETS: guard; plans (plan_revision, matches_reviewed_file 1).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @params int=(SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'evidence.upsert_flight_plan') AND name IN (N'@principal_id',N'@agent_id',N'@objective',N'@steps_json'));
DECLARE @active int=(SELECT COUNT(*) FROM [identity].principal WHERE principal_id='565de6d4-ebcd-408b-9359-04d21dc62183' AND active=1);
DECLARE @current_plan varchar(80)=(SELECT N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) FROM evidence.flight_plan WHERE principal_id='565de6d4-ebcd-408b-9359-04d21dc62183' AND agent_id=N'claude-code-opus-5-5-dsl-check-build' COLLATE Latin1_General_100_BIN2);
SELECT N'guard' AS result_set,@params AS writer_parameters,4 AS expected_parameters,@active AS owner_principal_active,@current_plan AS current_plan_of_agent;
IF @params<>4 OR @active<>1 OR ISNULL(@current_plan,'') NOT IN ('sha256:7144d15fe432b8cb32624a007dc440a4aee1798498ce9c8c2c7cc3539255e3a4','sha256:9fa79faa22669f5ea5ff560c7c8dd11d5c280e11a594a53cf3d3fd7061913194')
BEGIN
 RAISERROR(N'DSL11_PLAN_GUARD: the plan writer, the owner principal or the agent''s current plan (the build plan of dsl-10) is not as reviewed; nothing was recorded.',16,1);
 ROLLBACK TRANSACTION;
 SET NOEXEC ON;
END
GO
DECLARE @p uniqueidentifier='565de6d4-ebcd-408b-9359-04d21dc62183';
DECLARE @r TABLE(plan_revision bigint,plan_digest binary(32),updated_at datetime2(7));
INSERT @r EXEC evidence.upsert_flight_plan @principal_id=@p,@agent_id=N'claude-code-opus-5-5-dsl-check-build',@objective=N'Call check-capability-feature-conformance for the first time: it finds itself CONFORMANT to its canonical feature, and names each drift of the greeting scaffold bound to compile-capability-dsl.',
 @steps_json=N'[{"stepId":"plan-header","contractId":"estate-flight-plan.v1","promiseId":"dsl-check-capability-feature-conformance-first-call","flightType":"execution","workClass":"owner-objective","unknowns":[]},{"stepId":"first-call-self","capabilityId":"check-capability-feature-conformance","historicalBasis":"the build flight''s declaration committed only after this same request returned CONFORMANT inside it (model.apply_capability_from_dsl); case conf-self-conforms of the canonical feature","input":{"capabilityId":"check-capability-feature-conformance"},"obligationIds":["O1"],"expect":{"path":"$.status","equals":"CONFORMANT"}},{"stepId":"first-call-greeting","capabilityId":"check-capability-feature-conformance","historicalBasis":"the installed source returned exactly this signature for this request read-only (run 5fae01e0); case conf-greeting-drift of the canonical feature","input":{"capabilityId":"compile-capability-dsl"},"obligationIds":["O2"],"expect":{"path":"$.summary.signature","equals":"status=DRIFT;CASE_ASSERTION_MISSING=1;CASE_IDENTITY_MISSING=1;CASE_REQUEST_MISSING=1;EVENT_IDENTITY_MISMATCH=1;OUTCOME_CONTRACT_MISMATCH=1;OUTCOME_IDENTITY_MISMATCH=1;SCENARIO_STEP_NOT_IN_FEATURE=3"}}]';
SELECT N'plans' AS result_set,N'claude-code-opus-5-5-dsl-check-build' AS agent_id,plan_revision,N'sha256:'+LOWER(CONVERT(varchar(64),plan_digest,2)) AS plan_digest,CASE WHEN plan_digest=CONVERT(binary(32),'0x9fa79faa22669f5ea5ff560c7c8dd11d5c280e11a594a53cf3d3fd7061913194',1) THEN 1 ELSE 0 END AS matches_reviewed_file,updated_at FROM @r;
ROLLBACK TRANSACTION;
GO
SET NOEXEC OFF;
