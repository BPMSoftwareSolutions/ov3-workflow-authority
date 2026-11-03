capability nerdery-update-animal-attribute
feature nerdery-update-animal-attribute sha256:ddf61a8f55fda90100bbc1412d9837a2b96e0b5203f4f0d36c533dc7f8d01576
intent: Update a reusable animal attribute, for the caller whose session the declared API operation verified (Nerdery wildlife application)
outcome: nerdery-update-animal-attribute-result.v1 UPDATED or REFUSED, each refusal named by its reason code, so that animals continue to reference a coherent shared property
input contract nerdery-update-animal-attribute-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-update-animal-attribute-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-update-animal-attribute-result.v1"},"status":{"enum":["UPDATED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-update-animal-attribute root terminal
given: an animal attribute identity and proposed replacement properties
when: the animal attribute is updated by the authenticated user
then: the updated attribute is available or a named refusal preserves the existing attribute
operation nerdery-update-animal-attribute.update uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-update-animal-attribute',@input=@input;","resultColumn":"value"}
input input from nerdery-update-animal-attribute $
outcome from nerdery-update-animal-attribute.update $.value
