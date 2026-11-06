capability python-html
feature python-html sha256:979137c5cdda884192aea77cc6002b5e9ede3dfca693a78153bead7abdedc501
intent: Escape UTF-8 text for display with html.escape
outcome: A typed computation receipt with the executing Python version, or INVALID.
inquiry: Escape UTF-8 text for display with html.escape using the admitted Python standard library provider.
input contract python-html-request.v1 {"type":"object","additionalProperties":false,"required":["text"],"properties":{"text":{"type":"string","maxLength":6144},"quote":{"type":"boolean"}}}
output contract python-html-result.v1 {"type":"object","required":["contractId","runtime","status"],"additionalProperties":false,"properties":{"contractId":{"const":"python-html-result.v1"},"status":{"enum":["COMPUTED","INVALID"]},"runtime":{"type":"object","required":["implementation","version"],"additionalProperties":false,"properties":{"implementation":{"const":"cpython"},"version":{"type":"string","pattern":"^[0-9]+[.][0-9]+[.][0-9]+$"}}},"value":{"type":"object","properties":{"escaped":{"type":"string","description":"HTML-safe escaped text"},"quoteApplied":{"type":"boolean","description":"Whether quote translation was applied"},"inputLength":{"type":"integer","description":"Length of input text in code points"},"outputLength":{"type":"integer","description":"Length of escaped output in code points"}},"required":["escaped","quoteApplied","inputLength","outputLength"],"additionalProperties":false},"reason":{"const":"OUTSIDE_BOUNDED_CONTRACT"}},"oneOf":[{"required":["value"],"properties":{"status":{"const":"COMPUTED"}},"not":{"required":["reason"]}},{"required":["reason"],"properties":{"status":{"const":"INVALID"}},"not":{"required":["value"]}}]}
cli display outcome as json
scenario python-html root terminal
variants: COMPUTED:success,INVALID:failure
given: a bounded html request within the admitted Python library profile
when: OV3 invokes the fixed html operation through its declared provider
then: OV3 returns the computed value and runtime identity or a named input finding
operation python-html.compute kind invoke-port port python-html-compute
platform bind python-html-compute
platform: cpython-html-bounded-v1-port.v1
config: {"providerId":"cpython-html-bounded-v1","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"cpython-html-bounded-v1"}}
