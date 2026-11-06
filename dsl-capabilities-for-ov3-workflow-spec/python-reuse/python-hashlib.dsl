capability python-hashlib
feature python-hashlib sha256:c29bb29ca3435b241348b2707e0d83755ec6c9215ecd6690aa830d5184d0c6eb
intent: Compute SHA-256 of canonical Base64 bytes with hashlib.new
outcome: A typed computation receipt with the executing Python version, or INVALID.
inquiry: Compute SHA-256 of canonical Base64 bytes with hashlib.new using the admitted Python standard library provider.
input contract python-hashlib-request.v1 {"type":"object","additionalProperties":false,"required":["algorithm","data"],"properties":{"data":{"type":"string","maxLength":8192},"algorithm":{"const":"sha256"},"usedforsecurity":{"const":true}}}
output contract python-hashlib-result.v1 {"type":"object","required":["contractId","runtime","status"],"additionalProperties":false,"properties":{"contractId":{"const":"python-hashlib-result.v1"},"status":{"enum":["COMPUTED","INVALID"]},"runtime":{"type":"object","required":["implementation","version"],"additionalProperties":false,"properties":{"implementation":{"const":"cpython"},"version":{"type":"string","pattern":"^[0-9]+[.][0-9]+[.][0-9]+$"}}},"value":{"type":"object","properties":{"algorithm":{"type":"string","description":"Canonical lowercase hash.name of the constructed object."},"hexdigest":{"type":"string","description":"Lowercase hex-encoded digest."},"digestSize":{"type":"integer","description":"hash.digest_size in bytes."},"blockSize":{"type":"integer","description":"hash.block_size in bytes."}},"required":["algorithm","hexdigest","digestSize","blockSize"],"additionalProperties":false},"reason":{"const":"OUTSIDE_BOUNDED_CONTRACT"}},"oneOf":[{"required":["value"],"properties":{"status":{"const":"COMPUTED"}},"not":{"required":["reason"]}},{"required":["reason"],"properties":{"status":{"const":"INVALID"}},"not":{"required":["value"]}}]}
cli display outcome as json
scenario python-hashlib root terminal
variants: COMPUTED:success,INVALID:failure
given: a bounded hashlib request within the admitted Python library profile
when: OV3 invokes the fixed hashlib operation through its declared provider
then: OV3 returns the computed value and runtime identity or a named input finding
operation python-hashlib.compute kind invoke-port port python-hashlib-compute
platform bind python-hashlib-compute
platform: cpython-hashlib-bounded-v1-port.v1
config: {"providerId":"cpython-hashlib-bounded-v1","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"cpython-hashlib-bounded-v1"}}
