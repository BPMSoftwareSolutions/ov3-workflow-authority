capability nerdery-view-animal-definition
feature nerdery-view-animal-definition sha256:2b4c55fd4f28e46b17394b620ba9b9d78f854557b4c85a909989023a036472c5
intent: View the information unlocked for an animal definition, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)
outcome: nerdery-view-animal-definition-result.v1 VISIBLE or REFUSED, each refusal named by its reason code, so that I can learn from the animal information that my collection has unlocked
input contract nerdery-view-animal-definition-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-view-animal-definition-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-view-animal-definition-result.v1"},"status":{"enum":["VISIBLE","REFUSED"]}}}
cli display outcome as json
scenario nerdery-view-animal-definition root terminal
given: an animal definition identity
when: the animal definition is read for the authenticated user
then: the permitted animal information is available or a named refusal explains why it cannot be viewed
operation nerdery-view-animal-definition.view uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-view-animal-definition',@input=@input;","resultColumn":"value"}
input input from nerdery-view-animal-definition $
outcome from nerdery-view-animal-definition.view $.value
