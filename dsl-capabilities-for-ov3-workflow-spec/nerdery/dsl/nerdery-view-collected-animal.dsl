capability nerdery-view-collected-animal
feature nerdery-view-collected-animal sha256:d01b38d276d161ba76402d4f3fbd10cd88a98f4c40c9f07e00f7f068b5874e45
intent: View one collected individual with its photo, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)
outcome: nerdery-view-collected-animal-result.v1 VISIBLE or REFUSED, each refusal named by its reason code, so that I see my own photo of the animal together with what I recorded about it
input contract nerdery-view-collected-animal-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-view-collected-animal-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-view-collected-animal-result.v1"},"status":{"enum":["VISIBLE","REFUSED"]}}}
cli display outcome as json
scenario nerdery-view-collected-animal root terminal
given: a request to view one collected individual
when: the individual and its stored photo are read for the authenticated user
then: the user can view the individual with its photo or a named refusal
operation nerdery-view-collected-animal.view uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-view-collected-animal',@input=@input;","resultColumn":"value"}
input input from nerdery-view-collected-animal $
outcome from nerdery-view-collected-animal.view $.value
