capability python-markdown-page-operation
feature python-markdown-page-operation sha256:93c761fee701ac8ce7fb89bc98408d760443a831d42956b8ce009c9c2bbc3854
intent: Execute one declared Markdown rendering or independent readback operation in the pinned CPython, from a C# or Python kernel.
outcome: A digest-bound render, verification, or named package finding.
inquiry: Execute one declared Markdown rendering or independent readback operation in the pinned CPython, from a C# or Python kernel.
input contract python-markdown-page-operation-request.v1 {"type":"object","properties":{"phase":{"enum":["render","verify"]},"bundle":{"type":"string","maxLength":2000000},"inputDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"request":{"type":"object"},"html":{"type":"string","maxLength":6291456},"receipt":{"type":"object"}},"required":["phase","bundle","inputDigest","request","html","receipt"],"additionalProperties":false}
output contract markdown-page-operation.v1 {"type":"object","required":["status"],"oneOf":[{"properties":{"status":{"const":"RENDERED"},"html":{"type":"string"},"sourceDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"outputDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}},"required":["html","sourceDigest","outputDigest","renderer"]},{"properties":{"status":{"const":"VERIFIED"},"sourceDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"outputDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"utf8Bytes":{"type":"integer","minimum":1}},"required":["sourceDigest","outputDigest","utf8Bytes","renderer"]},{"properties":{"status":{"const":"FAILED"},"finding":{"type":"string","minLength":1}},"required":["finding"]}],"additionalProperties":true}
cli display outcome as json
scenario python-markdown-page-operation root terminal
variants: RENDERED:success,VERIFIED:success,FAILED:failure
given: a phase, page input and the package bytes selected by the page capability
when: the declared provider launches the fixed package operation in CPython, bounded to 80 seconds
then: the provider returns the phase result or a specific package or input finding
operation python-markdown-page-operation.compute kind invoke-port port python-markdown-page-operation-compute
platform bind python-markdown-page-operation-compute
platform: python-markdown-page-libraries-v1-port.v1
config: {"providerId":"python-markdown-page-libraries-v1","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"python-markdown-page-libraries-v1"}}
