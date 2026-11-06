capability nerdery-add-animal-attribute
feature nerdery-add-animal-attribute sha256:45eed6cbd0664d8e0e2a63bc8cd9e89ac9618ab23052034eb2d41e25bfb6624a
intent: Add a reusable animal attribute, for the caller whose session the declared API operation verified (Nerdery wildlife application)
outcome: nerdery-add-animal-attribute-result.v1 ADDED or REFUSED, each refusal named by its reason code, so that the same property can describe one or many animals
input contract nerdery-add-animal-attribute-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-add-animal-attribute-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-add-animal-attribute-result.v1"},"status":{"enum":["ADDED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-add-animal-attribute root terminal
given: a proposed animal attribute
when: the animal attribute is added by the authenticated user
then: the attribute is available for animal definitions or a named refusal explains why it was not added
operation nerdery-add-animal-attribute.add uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-add-animal-attribute',@input=@input;","resultColumn":"value"}
input input from nerdery-add-animal-attribute $
outcome from nerdery-add-animal-attribute.add $.value
