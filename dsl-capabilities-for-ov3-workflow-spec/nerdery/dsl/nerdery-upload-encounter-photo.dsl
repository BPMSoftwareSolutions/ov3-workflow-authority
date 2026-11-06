capability nerdery-upload-encounter-photo
feature nerdery-upload-encounter-photo sha256:38e58430acc3a39e88078f4a71000dacb3d585124a7a0cef2f906bcb35716de5
intent: Retain a photo for an animal encounter, for the caller whose session the declared API operation verified (Nerdery wildlife application, citizen slice)
outcome: nerdery-upload-encounter-photo-result.v1 UPLOADED or REFUSED, each refusal named by its reason code, so that the photo can be attached to my recorded animal
input contract nerdery-upload-encounter-photo-request.v1 {"type":"object","additionalProperties":false,"required":["request"],"properties":{"caller":{"type":"object","additionalProperties":false,"properties":{"principalId":{"type":"string"},"sessionId":{"type":"string"}}},"request":{"type":"object"}}}
output contract nerdery-upload-encounter-photo-result.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"nerdery-upload-encounter-photo-result.v1"},"status":{"enum":["UPLOADED","REFUSED"]}}}
cli display outcome as json
scenario nerdery-upload-encounter-photo root terminal
given: selected encounter photo bytes
when: the encounter photo is uploaded for the authenticated user
then: an owned retained photo reference is available or a named refusal explains why it is not available
operation nerdery-upload-encounter-photo.upload uses provider sql-database-reader
config: {"dataSource":"sfx-identity-database","statement":"EXEC wildlife.serve @operation=N'nerdery-upload-encounter-photo',@input=@input;","resultColumn":"value"}
input input from nerdery-upload-encounter-photo $
outcome from nerdery-upload-encounter-photo.upload $.value
