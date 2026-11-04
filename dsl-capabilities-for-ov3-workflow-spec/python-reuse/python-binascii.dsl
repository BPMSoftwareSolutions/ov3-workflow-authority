capability python-binascii
feature python-binascii sha256:1a44e18793cd4e4710638a8d4e1e910ec1037ebaccc1932d6739d5439ab221a3
intent: Compute the unsigned CRC-32 of canonical Base64 bytes
outcome: A typed computation receipt with the executing Python version, or INVALID.
inquiry: Compute the unsigned CRC-32 of canonical Base64 bytes using the admitted Python standard library provider.
input contract python-binascii-request.v1 {"type":"object","additionalProperties":false,"required":["data"],"properties":{"data":{"type":"string","maxLength":8192},"initialCrc":{"type":"integer","minimum":0,"maximum":4294967295}}}
output contract python-binascii-result.v1 {"type":"object","required":["contractId","runtime","status"],"additionalProperties":false,"properties":{"contractId":{"const":"python-binascii-result.v1"},"status":{"enum":["COMPUTED","INVALID"]},"runtime":{"type":"object","required":["implementation","version"],"additionalProperties":false,"properties":{"implementation":{"const":"cpython"},"version":{"type":"string","pattern":"^[0-9]+[.][0-9]+[.][0-9]+$"}}},"value":{"type":"object","properties":{"crc":{"type":"integer","minimum":0,"maximum":4294967295,"description":"Unsigned 32-bit CRC-32 result."},"hex":{"type":"string","pattern":"^[0-9a-f]{8}$","description":"Zero-padded lowercase 8-character hex representation of crc."},"byteLength":{"type":"integer","minimum":0,"description":"Number of payload bytes checksummed."}},"required":["crc","hex","byteLength"],"additionalProperties":false},"reason":{"const":"OUTSIDE_BOUNDED_CONTRACT"}},"oneOf":[{"required":["value"],"properties":{"status":{"const":"COMPUTED"}},"not":{"required":["reason"]}},{"required":["reason"],"properties":{"status":{"const":"INVALID"}},"not":{"required":["value"]}}]}
cli display outcome as json
scenario python-binascii root terminal
variants: COMPUTED:success,INVALID:failure
given: a bounded binascii request within the admitted Python library profile
when: OV3 invokes the fixed binascii operation through its declared provider
then: OV3 returns the computed value and runtime identity or a named input finding
operation python-binascii.compute kind invoke-port port python-binascii-compute
platform bind python-binascii-compute
platform: cpython-binascii-bounded-v1-port.v1
config: {"providerId":"cpython-binascii-bounded-v1","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"cpython-binascii-bounded-v1"}}
