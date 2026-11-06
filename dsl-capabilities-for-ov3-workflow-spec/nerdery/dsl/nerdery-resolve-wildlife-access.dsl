capability nerdery-resolve-wildlife-access
feature nerdery-resolve-wildlife-access sha256:c5ced02e926c301edb4ef7bdfc1a928330377ac85d38e5986f31b1f8b3b51b77
intent: Resolve access to wildlife application sections, for the caller whose session the declared API operation verified (Nerdery wildlife application)
outcome: nerdery-resolve-wildlife-access-result.v1 ALLOWED or REFUSED, each refusal named by its reason code, so that I can use the appropriate experiences without gaining unintended privileges
input contract nerdery-resolve-wildlife-access-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-resolve-wildlife-access-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-resolve-wildlife-access-result.v1"},"status":{"enum":["ALLOWED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-resolve-wildlife-access root terminal
given: a requested wildlife application section
when: access to the section is resolved for the authenticated user
then: the requested section is available or the access refusal is known
operation nerdery-resolve-wildlife-access.resolve uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-resolve-wildlife-access',@input=@input;","resultColumn":"value"}
input input from nerdery-resolve-wildlife-access $
outcome from nerdery-resolve-wildlife-access.resolve $.value
