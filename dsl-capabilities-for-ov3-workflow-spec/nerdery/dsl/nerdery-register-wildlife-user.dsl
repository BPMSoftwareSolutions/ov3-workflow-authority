capability nerdery-register-wildlife-user
feature nerdery-register-wildlife-user sha256:24ce719da85308c66551cae6d5f38a8477765ebff52dd7308e68db2dd7e0c666
intent: Register a wildlife user through the DNR identity service, for the caller whose session the declared API operation verified (Nerdery wildlife application)
outcome: nerdery-register-wildlife-user-result.v1 REGISTERED or REFUSED, each refusal named by its reason code, so that I can keep my own wildlife collection
input contract nerdery-register-wildlife-user-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-register-wildlife-user-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-register-wildlife-user-result.v1"},"status":{"enum":["REGISTERED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-register-wildlife-user root terminal
given: a DNR registration response reference
when: the wildlife account registration is completed
then: the user has one wildlife account or a named registration refusal
operation nerdery-register-wildlife-user.register uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-register-wildlife-user',@input=@input;","resultColumn":"value"}
input input from nerdery-register-wildlife-user $
outcome from nerdery-register-wildlife-user.register $.value
