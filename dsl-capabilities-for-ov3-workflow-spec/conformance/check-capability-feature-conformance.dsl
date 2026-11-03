capability check-capability-feature-conformance
feature check-capability-feature-conformance sha256:49bf06230349e792eeba7041a7f7ecf2cd2c894aa5635ae2ec5c5b2130ab02b9
intent: Check a capability's circuit against its canonical feature by identity, and accept each case only from the pinned evidence of its own call
outcome: capability-feature-conformance.v1 CONFORMANT, DRIFT, WELL_FORMED, MALFORMED, NOT_BOUND, NOT_FOUND, ACCEPTED, REJECTED or BASELINE, with each finding named by its code and identity
inquiry: Does this capability's circuit drift from its canonical feature?
inquiry: Which identity, step or case drifted, and where?
inquiry: Does this run prove this case through its own call?
input contract check-capability-feature-conformance-request.v1 {"type":"object","additionalProperties":false,"properties":{"capabilityId":{"type":"string","minLength":1,"maxLength":400},"featureText":{"type":"string","minLength":1},"featureDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"document":{"type":"object"},"acceptance":{"type":"object"},"evidenceText":{"type":"string","minLength":1},"baseline":{"type":"object"},"explain":{"type":"boolean"}}}
output contract capability-feature-conformance.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"capability-feature-conformance.v1"},"status":{"type":"string"}}}
cli display outcome as json
scenario check-capability-feature-conformance root terminal
variants: CONFORMANT:success,DRIFT:success,WELL_FORMED:success,MALFORMED:success,NOT_BOUND:success,NOT_FOUND:success,ACCEPTED:success,REJECTED:success,BASELINE:success
given: a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
when: the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
then: CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
operation check-capability-feature-conformance.check uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"SET ARITHABORT ON; DECLARE @estate_model_pk bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1); EXEC analysis.check_capability_feature_conformance @input=@input,@estate_model_pk=@estate_model_pk;","resultColumn":"value"}
input input from check-capability-feature-conformance $
outcome from check-capability-feature-conformance.check $.value
