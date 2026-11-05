capability govern-product-delivery
intent: Govern the pinned product delivery definition and attributed acceptance through canonical gate semantics.
outcome: Refuse unsupported claims; admit only the declared complete attributed outcome under the installed verification profile.
feature govern-product-delivery sha256:09245991d225150a4e6b9e69579ab62a0d09908326744a5bd79d3f7ebc806f47
cli display outcome as json
cli input json
input contract product-delivery-gate-request.v1 {"type":"object","additionalProperties":false,"required":["phase","definitionComplete","sameContract","flightReady","modelSaysProceed"],"properties":{"phase":{"type":"string","minLength":1},"definitionComplete":{"type":"boolean"},"sameContract":{"type":"boolean"},"flightReady":{"type":"boolean"},"modelSaysProceed":{"type":"boolean"}}}
output contract product-delivery-gate-result.v1 {"type":"object","additionalProperties":false,"required":["status"],"properties":{"status":{"type":"string","minLength":1}}}
contract formal-acceptance-fixture.v1 {"anyOf":[{"type":"object","additionalProperties":false,"required":["allOtherPredicates","invocationIdentity"],"properties":{"allOtherPredicates":{"type":"boolean"},"invocationIdentity":{"type":"boolean"}}},{"type":"object","additionalProperties":false,"required":["exactRequiredSet","allRequiredPredicates","blockingFindings"],"properties":{"exactRequiredSet":{"type":"boolean"},"allRequiredPredicates":{"type":"boolean"},"blockingFindings":{"type":"integer","minimum":0}}}]}
contract formal-acceptance-result.v1 {"type":"object","additionalProperties":false,"required":["status"],"properties":{"status":{"type":"string","minLength":1}}}
contract formal-replay-fixture.v1 {"type":"object","additionalProperties":false,"required":["cursor","eventFirstObservedAt","providerCallsBefore"],"properties":{"cursor":{"type":"integer","minimum":0},"eventFirstObservedAt":{"type":"array","items":{"type":"integer","minimum":0}},"providerCallsBefore":{"type":"integer","minimum":0}}}
contract formal-replay-result.v1 {"type":"object","additionalProperties":false,"required":["status","providerCallsAfter"],"properties":{"status":{"type":"string","minLength":1},"providerCallsAfter":{"type":"integer","minimum":0}}}
contract formal-maintenance-fixture.v1 {"type":"object","additionalProperties":false,"required":["priorRelease","candidateRelease","checksPassed","readbackMatches"],"properties":{"priorRelease":{"type":"integer","minimum":0},"candidateRelease":{"type":"integer","minimum":0},"checksPassed":{"type":"boolean"},"readbackMatches":{"type":"boolean"}}}
contract formal-maintenance-result.v1 {"type":"object","additionalProperties":false,"required":["status","activeRelease"],"properties":{"status":{"type":"string","minLength":1},"activeRelease":{"type":"integer","minimum":0}}}
scenario govern-product-delivery root terminal input=product-delivery-gate-request.v1 output=product-delivery-gate-result.v1
given: a product step with an absent authoritative definition receipt
when: the declared gate evaluates the pinned contract and execution authority
then: execution is refused independently of the model suggestion
variants: evaluated:success
operation govern-product-delivery.evaluate uses provider govern-product-delivery.govern-product-delivery
input phase from govern-product-delivery $.phase
input definitionComplete from govern-product-delivery $.definitionComplete
input sameContract from govern-product-delivery $.sameContract
input flightReady from govern-product-delivery $.flightReady
input modelSaysProceed from govern-product-delivery $.modelSaysProceed
outcome from govern-product-delivery.evaluate $.result
scenario accept-attributed-evidence terminal input=formal-acceptance-fixture.v1 output=formal-acceptance-result.v1
given: a fixture satisfying every acceptance predicate except invocation identity
when: the checker evaluates source, request, run, provider, graph, integrity and canonical assertions
then: the attributed acceptance claim is refused
variants: evaluated:success
operation accept-attributed-evidence.evaluate uses provider govern-product-delivery.accept-attributed-evidence
input allOtherPredicates from accept-attributed-evidence $.allOtherPredicates
input invocationIdentity from accept-attributed-evidence $.invocationIdentity
outcome from accept-attributed-evidence.evaluate $.result
scenario accept-complete-product terminal input=formal-acceptance-fixture.v1 output=formal-acceptance-result.v1
given: all exact required criteria and ecosystem instances have verified matching proof
when: the declared obligation verifier reads the retained contract, deployment and proof receipts
then: the obligation-complete result permits submission for review
variants: evaluated:success
operation accept-complete-product.evaluate uses provider govern-product-delivery.accept-complete-product
input exactRequiredSet from accept-complete-product $.exactRequiredSet
input allRequiredPredicates from accept-complete-product $.allRequiredPredicates
input blockingFindings from accept-complete-product $.blockingFindings
outcome from accept-complete-product.evaluate $.result
scenario preserve-replay-boundary terminal input=formal-replay-fixture.v1 output=formal-replay-result.v1
given: a replay cursor before a terminal event
when: the projection selects the observed prefix without execution authority
then: future outcomes remain hidden and no invocation is started
variants: evaluated:success
operation preserve-replay-boundary.evaluate uses provider govern-product-delivery.preserve-replay-boundary
input cursor from preserve-replay-boundary $.cursor
input eventFirstObservedAt from preserve-replay-boundary $.eventFirstObservedAt
input providerCallsBefore from preserve-replay-boundary $.providerCallsBefore
outcome from preserve-replay-boundary.evaluate $.result
scenario preserve-maintenance-release terminal input=formal-maintenance-fixture.v1 output=formal-maintenance-result.v1
given: a new revision with failed publication readback
when: publication evaluates the candidate against the pinned requirements
then: the active verified release remains the previous release
variants: evaluated:success
operation preserve-maintenance-release.evaluate uses provider govern-product-delivery.preserve-maintenance-release
input priorRelease from preserve-maintenance-release $.priorRelease
input candidateRelease from preserve-maintenance-release $.candidateRelease
input checksPassed from preserve-maintenance-release $.checksPassed
input readbackMatches from preserve-maintenance-release $.readbackMatches
outcome from preserve-maintenance-release.evaluate $.result
