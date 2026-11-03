capability nerdery-remove-animal-definition
feature nerdery-remove-animal-definition sha256:7592d131f3d89a452c1d3292973478a7ab979188f9e453e6a0551d3a458065b2
intent: Remove an animal definition from the active catalog, for the caller whose session the declared API operation verified (Nerdery wildlife application)
outcome: nerdery-remove-animal-definition-result.v1 REMOVED or REFUSED, each refusal named by its reason code, so that the active catalog no longer offers that definition
input contract nerdery-remove-animal-definition-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-remove-animal-definition-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-remove-animal-definition-result.v1"},"status":{"enum":["REMOVED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-remove-animal-definition root terminal
given: an animal definition identity requested for removal
when: the animal definition is removed by the authenticated user
then: the definition is absent from the active catalog or a named refusal leaves it unchanged
operation nerdery-remove-animal-definition.remove uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-remove-animal-definition',@input=@input;","resultColumn":"value"}
input input from nerdery-remove-animal-definition $
outcome from nerdery-remove-animal-definition.remove $.value
