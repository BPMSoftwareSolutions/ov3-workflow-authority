capability nerdery-sign-in-wildlife-user
feature nerdery-sign-in-wildlife-user sha256:bf9ff42f4a1c96eec6cb938f3bf40e57b8c13aed9b94e4a64dc73f90b6250cd6
intent: Sign in to the wildlife application, for the caller whose session the declared API operation verified (Nerdery wildlife application)
outcome: nerdery-sign-in-wildlife-user-result.v1 SIGNED_IN or REFUSED, each refusal named by its reason code, so that I can use my own collection and team
input contract nerdery-sign-in-wildlife-user-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-sign-in-wildlife-user-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-sign-in-wildlife-user-result.v1"},"status":{"enum":["SIGNED_IN","REFUSED"]}}}
cli display outcome as json
scenario nerdery-sign-in-wildlife-user root terminal
given: a DNR sign-in response reference
when: the wildlife sign-in is completed
then: the user has an authenticated application session or a named sign-in refusal
operation nerdery-sign-in-wildlife-user.sign-in uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-sign-in-wildlife-user',@input=@input;","resultColumn":"value"}
input input from nerdery-sign-in-wildlife-user $
outcome from nerdery-sign-in-wildlife-user.sign-in $.value
