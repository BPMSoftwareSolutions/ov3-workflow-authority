capability python-base64
feature python-base64 sha256:a7a9291beef95541f794fca5a2ffcf9360bd638937203d8dd167def947e9d372
intent: Encode UTF-8 text as padded unwrapped RFC 4648 Base64
outcome: A typed computation receipt with the executing Python version, or INVALID.
inquiry: Encode UTF-8 text as padded unwrapped RFC 4648 Base64 using the admitted Python standard library provider.
input contract python-base64-request.v1 {"type":"object","additionalProperties":false,"required":["data"],"properties":{"data":{"type":"string","maxLength":6144},"padded":{"const":true},"wrapcol":{"const":0}}}
output contract python-base64-result.v1 {"type":"object","required":["contractId","runtime","status"],"additionalProperties":false,"properties":{"contractId":{"const":"python-base64-result.v1"},"status":{"enum":["COMPUTED","INVALID"]},"runtime":{"type":"object","required":["implementation","version"],"additionalProperties":false,"properties":{"implementation":{"const":"cpython"},"version":{"type":"string","pattern":"^[0-9]+[.][0-9]+[.][0-9]+$"}}},"value":{"type":"object","properties":{"encoded":{"type":"string","description":"Base64-encoded ASCII text."},"inputBytes":{"type":"integer","minimum":0,"description":"Length in bytes of the input payload."},"outputBytes":{"type":"integer","minimum":0,"description":"Length in bytes of the encoded output."},"padded":{"type":"boolean"},"wrapcol":{"type":"integer","minimum":0}},"required":["encoded","inputBytes","outputBytes","padded","wrapcol"],"additionalProperties":false},"reason":{"const":"OUTSIDE_BOUNDED_CONTRACT"}},"oneOf":[{"required":["value"],"properties":{"status":{"const":"COMPUTED"}},"not":{"required":["reason"]}},{"required":["reason"],"properties":{"status":{"const":"INVALID"}},"not":{"required":["value"]}}]}
cli display outcome as json
scenario python-base64 root terminal
variants: COMPUTED:success,INVALID:failure
given: a bounded base64 request within the admitted Python library profile
when: OV3 invokes the fixed base64 operation through its declared provider
then: OV3 returns the computed value and runtime identity or a named input finding
operation python-base64.compute kind invoke-port port python-base64-compute
platform bind python-base64-compute
platform: cpython-base64-bounded-v1-port.v1
config: {"providerId":"cpython-base64-bounded-v1","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"cpython-base64-bounded-v1"}}
