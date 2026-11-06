capability nerdery-add-animal-definition
feature nerdery-add-animal-definition sha256:cecfea79150494650b84f119ec59e26c742c7bc3822601f831aaf17ee1b2c4f2
intent: Add an animal definition, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)
outcome: nerdery-add-animal-definition-result.v1 ADDED or REFUSED, each refusal named by its reason code, so that users can discover and collect that animal
input contract nerdery-add-animal-definition-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-add-animal-definition-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-add-animal-definition-result.v1"},"status":{"enum":["ADDED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-add-animal-definition root terminal
given: a proposed animal definition
when: the animal definition is added by the authenticated user
then: the new animal definition is available or a named refusal explains why it was not added
operation nerdery-add-animal-definition.add uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-add-animal-definition',@input=@input;","resultColumn":"value"}
input input from nerdery-add-animal-definition $
outcome from nerdery-add-animal-definition.add $.value
