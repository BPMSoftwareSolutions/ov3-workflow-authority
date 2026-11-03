capability nerdery-browse-animal-collection
feature nerdery-browse-animal-collection sha256:dc19f2defcd1b0dcc5beead0fe42a0976336238216422d87397ccbcfcb7588c5
intent: Browse and search the animal-definition collection, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)
outcome: nerdery-browse-animal-collection-result.v1 LISTED or REFUSED, each refusal named by its reason code, so that I can see what I have collected and discover what remains
input contract nerdery-browse-animal-collection-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-browse-animal-collection-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-browse-animal-collection-result.v1"},"status":{"enum":["LISTED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-browse-animal-collection root terminal
given: a collection browse request
when: the animal-definition collection is read for the authenticated user
then: the ordered matching collection is visible with only the information unlocked for that user or a named refusal
operation nerdery-browse-animal-collection.browse uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-browse-animal-collection',@input=@input;","resultColumn":"value"}
input input from nerdery-browse-animal-collection $
outcome from nerdery-browse-animal-collection.browse $.value
