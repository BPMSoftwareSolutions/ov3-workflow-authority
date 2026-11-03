capability nerdery-remove-animal-attribute
feature nerdery-remove-animal-attribute sha256:f7c98d58559233a51b925663f3c6e37eb8cc0891c09789cfa845e69f011f24ed
intent: Remove an animal attribute from active use, for the caller whose session the declared API operation verified (Nerdery wildlife application)
outcome: nerdery-remove-animal-attribute-result.v1 REMOVED or REFUSED, each refusal named by its reason code, so that the active attribute catalog no longer offers it
input contract nerdery-remove-animal-attribute-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-remove-animal-attribute-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-remove-animal-attribute-result.v1"},"status":{"enum":["REMOVED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-remove-animal-attribute root terminal
given: an animal attribute identity requested for removal
when: the animal attribute is removed by the authenticated user
then: the attribute is absent from active selection or a named refusal leaves it unchanged
operation nerdery-remove-animal-attribute.remove uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-remove-animal-attribute',@input=@input;","resultColumn":"value"}
input input from nerdery-remove-animal-attribute $
outcome from nerdery-remove-animal-attribute.remove $.value
