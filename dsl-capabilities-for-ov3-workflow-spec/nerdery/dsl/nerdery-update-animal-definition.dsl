capability nerdery-update-animal-definition
feature nerdery-update-animal-definition sha256:22c39f030ea82bbb8eb05729aef5e2fe4bc2de624c03dc6403f1426719bd3791
intent: Update an animal definition, for the caller whose session the declared API operation verified (Nerdery wildlife application)
outcome: nerdery-update-animal-definition-result.v1 UPDATED or REFUSED, each refusal named by its reason code, so that the catalog reflects the maintained wildlife information
input contract nerdery-update-animal-definition-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-update-animal-definition-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-update-animal-definition-result.v1"},"status":{"enum":["UPDATED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-update-animal-definition root terminal
given: an animal definition identity and its proposed replacement properties
when: the animal definition is updated by the authenticated user
then: the updated animal definition is available or a named refusal preserves the existing definition
operation nerdery-update-animal-definition.update uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-update-animal-definition',@input=@input;","resultColumn":"value"}
input input from nerdery-update-animal-definition $
outcome from nerdery-update-animal-definition.update $.value
