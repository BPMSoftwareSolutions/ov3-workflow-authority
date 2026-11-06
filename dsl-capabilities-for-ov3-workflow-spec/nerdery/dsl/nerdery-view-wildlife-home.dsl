capability nerdery-view-wildlife-home
feature nerdery-view-wildlife-home sha256:d91ded8a312cb3eca7c69a6004026db720227bfb8582623674705d6dfe7e4bc4
intent: View the selected team on the wildlife home page, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)
outcome: nerdery-view-wildlife-home-result.v1 VISIBLE or REFUSED, each refusal named by its reason code, so that my personal wildlife team is immediately recognizable
input contract nerdery-view-wildlife-home-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-view-wildlife-home-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-view-wildlife-home-result.v1"},"status":{"enum":["VISIBLE","REFUSED"]}}}
cli display outcome as json
scenario nerdery-view-wildlife-home root terminal
given: a wildlife home-page request
when: the home-page experience is read for the authenticated user
then: the user sees their saved team or a named refusal
operation nerdery-view-wildlife-home.view uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-view-wildlife-home',@input=@input;","resultColumn":"value"}
input input from nerdery-view-wildlife-home $
outcome from nerdery-view-wildlife-home.view $.value
