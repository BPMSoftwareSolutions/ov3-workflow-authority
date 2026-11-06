capability nerdery-record-animal-encounter
feature nerdery-record-animal-encounter sha256:df6cea9ceb5ce4d6a63755f8c42e80bc285191fecc18598e695ab6bd73e03a23
intent: Record an animal encounter, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)
outcome: nerdery-record-animal-encounter-result.v1 RECORDED or REFUSED, each refusal named by its reason code, so that the individual animal is in my collection
input contract nerdery-record-animal-encounter-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-record-animal-encounter-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-record-animal-encounter-result.v1"},"status":{"enum":["RECORDED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-record-animal-encounter root terminal
given: an encounter request with an animal selection, location, photo reference and optional nickname
when: the animal encounter is recorded for the authenticated user
then: the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
operation nerdery-record-animal-encounter.record uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-record-animal-encounter',@input=@input;","resultColumn":"value"}
input input from nerdery-record-animal-encounter $
outcome from nerdery-record-animal-encounter.record $.value
