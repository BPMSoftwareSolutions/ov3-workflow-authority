capability nerdery-set-animal-team
feature nerdery-set-animal-team sha256:6dd6c439568c45a7b63b8ad2745ac200f73c3d6d45e043d06b858cf0926048d2
intent: Select a personal team of up to six collected animals, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)
outcome: nerdery-set-animal-team-result.v1 SAVED or REFUSED, each refusal named by its reason code, so that my chosen animals can appear together on my home page
input contract nerdery-set-animal-team-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-set-animal-team-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-set-animal-team-result.v1"},"status":{"enum":["SAVED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-set-animal-team root terminal
given: a proposed team of collected encounter identities
when: the team selection is saved for the authenticated user
then: the selected team of at most six animals is saved or a named refusal preserves the previous team
operation nerdery-set-animal-team.set uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-set-animal-team',@input=@input;","resultColumn":"value"}
input input from nerdery-set-animal-team $
outcome from nerdery-set-animal-team.set $.value
