capability python-textwrap
feature python-textwrap sha256:debfab4b22653da3451820ea1988fcd8f41fd46dda50085cd3a0f616a5f37e6a
intent: Wrap a UTF-8 paragraph to a bounded width using textwrap.TextWrapper.wrap
outcome: A typed computation receipt with the executing Python version, or INVALID.
inquiry: Wrap a UTF-8 paragraph to a bounded width using textwrap.TextWrapper.wrap using the admitted Python standard library provider.
input contract python-textwrap-request.v1 {"type":"object","additionalProperties":false,"required":["text"],"properties":{"text":{"type":"string","maxLength":6144},"width":{"type":"integer","minimum":1,"maximum":256}}}
output contract python-textwrap-result.v1 {"type":"object","required":["contractId","runtime","status"],"additionalProperties":false,"properties":{"contractId":{"const":"python-textwrap-result.v1"},"status":{"enum":["COMPUTED","INVALID"]},"runtime":{"type":"object","required":["implementation","version"],"additionalProperties":false,"properties":{"implementation":{"const":"cpython"},"version":{"type":"string","pattern":"^[0-9]+[.][0-9]+[.][0-9]+$"}}},"value":{"type":"object","properties":{"lines":{"type":"array","items":{"type":"string"},"description":"Wrapped output lines without final newlines; empty if no content"},"line_count":{"type":"integer","minimum":0}},"required":["lines","line_count"],"additionalProperties":false},"reason":{"const":"OUTSIDE_BOUNDED_CONTRACT"}},"oneOf":[{"required":["value"],"properties":{"status":{"const":"COMPUTED"}},"not":{"required":["reason"]}},{"required":["reason"],"properties":{"status":{"const":"INVALID"}},"not":{"required":["value"]}}]}
cli display outcome as json
scenario python-textwrap root terminal
variants: COMPUTED:success,INVALID:failure
given: a bounded textwrap request within the admitted Python library profile
when: OV3 invokes the fixed textwrap operation through its declared provider
then: OV3 returns the computed value and runtime identity or a named input finding
operation python-textwrap.compute kind invoke-port port python-textwrap-compute
platform bind python-textwrap-compute
platform: cpython-textwrap-bounded-v1-port.v1
config: {"providerId":"cpython-textwrap-bounded-v1","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"cpython-textwrap-bounded-v1"}}
