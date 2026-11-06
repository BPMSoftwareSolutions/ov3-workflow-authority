capability reveal-estate-workflows
feature reveal-estate-workflows sha256:2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48
intent: Reveal the admitted workflows of one capability as a read-only lens: its declared entries, the closure of each admitted entry over admitted transitions only, every routing transition with its topology, semanticProgress and status, and the findings that hold a transition or an entry, from one pinned definition
outcome: workflow-lens.v1 RESOLVED, PARTIAL_WITH_HELD_GAPS, NOT_DECLARED, NOT_FOUND or STALE, with entries, workflows, execution edges, findings, a summary signature and a projection digest
inquiry: Reveal the admitted workflows of this capability.
inquiry: Which routes can run from this capability's entry, and which are held?
inquiry: Why is this route shown or held?
input contract reveal-estate-workflows-request.v1 {"type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1,"maxLength":400},"entryScenarioId":{"type":"string","minLength":1,"maxLength":400},"expectedDefinitionDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}}}
output contract workflow-lens.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"workflow-lens.v1"},"status":{"enum":["RESOLVED","PARTIAL_WITH_HELD_GAPS","NOT_DECLARED","NOT_FOUND","STALE"]}}}
cli display outcome as json
scenario reveal-estate-workflows root terminal
given: an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
when: the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
then: a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
operation reveal-estate-workflows.reveal uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"SET ARITHABORT ON; DECLARE @estate_model_pk bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1); EXEC analysis.reveal_estate_workflows @input=@input,@estate_model_pk=@estate_model_pk;","resultColumn":"value"}
input input from reveal-estate-workflows $
outcome from reveal-estate-workflows.reveal $.value
