capability nerdery-view-catalog-for-maintenance
feature nerdery-view-catalog-for-maintenance sha256:3e403f869f8ac663beee431b1cf999996c824a53e24af3f9d3e1b03d30710a1b
intent: View the catalog for maintenance, for the caller whose session the declared API operation verified (Nerdery wildlife application)
outcome: nerdery-view-catalog-for-maintenance-result.v1 VISIBLE or REFUSED, each refusal named by its reason code, so that I can change or remove one from the revision I saw
input contract nerdery-view-catalog-for-maintenance-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-view-catalog-for-maintenance-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-view-catalog-for-maintenance-result.v1"},"status":{"enum":["VISIBLE","REFUSED"]}}}
cli display outcome as json
scenario nerdery-view-catalog-for-maintenance root terminal
given: a request to view the catalog for maintenance
when: the catalog is read for maintenance by the authenticated user
then: the user can view the catalog with its revisions or a named refusal
operation nerdery-view-catalog-for-maintenance.view uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-view-catalog-for-maintenance',@input=@input;","resultColumn":"value"}
input input from nerdery-view-catalog-for-maintenance $
outcome from nerdery-view-catalog-for-maintenance.view $.value
