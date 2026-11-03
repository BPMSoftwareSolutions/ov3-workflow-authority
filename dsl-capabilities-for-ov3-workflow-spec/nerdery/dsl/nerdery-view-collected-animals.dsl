capability nerdery-view-collected-animals
feature nerdery-view-collected-animals sha256:a8f1920e6569b46ab5924fe841bebd5cc63a0993accb26f5a2e78cd20bcd835c
intent: View the individual animals in a personal collection, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)
outcome: nerdery-view-collected-animals-result.v1 LISTED or REFUSED, each refusal named by its reason code, so that I recognize my animals by my photos and optional nicknames
input contract nerdery-view-collected-animals-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-view-collected-animals-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-view-collected-animals-result.v1"},"status":{"enum":["LISTED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-view-collected-animals root terminal
given: a personal collected-animals request
when: the recorded individuals are read for the authenticated user
then: the user can view their individual collected animals or a named refusal
operation nerdery-view-collected-animals.view uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-view-collected-animals',@input=@input;","resultColumn":"value"}
input input from nerdery-view-collected-animals $
outcome from nerdery-view-collected-animals.view $.value
