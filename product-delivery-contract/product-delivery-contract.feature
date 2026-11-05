@capability:govern-product-delivery
@root-scenario:govern-product-delivery
Feature: Deliver the complete Capability Studio through the owner's five altitudes
  The pinned product-delivery-contract.json defines the complete product scope,
  obligation/criterion set, qualification matrix, flight plans and payload schemas.
  Its Markdown projection, owner intent, deck, canonical topology and formal strategy
  must agree. The definition gate validates that agreement before product work.
  A later obligation gate verifies actual fulfillment before review submission.
  Neither a local proof, advisory model answer, materialized plan nor partial flight
  is a complete product or authoritative gate receipt.
  Canonical feature establishes intended outcome and requirements; scenario establishes
  Input → Event → Outcome and admissibility; capability/profile schemas establish
  structural, semantic, dependency, provider and authority contracts; resolution and
  execution establish binding/runtime conformance; flight-recorded evidence compares
  observed behavior and effects against those obligations without expanding the claim.
  Formal models are derived finite interpretations. The required refinement argument
  and observation trust boundary must connect them to deployed implementations.
  Fixtures below are abstract test requests, not execution or approval receipts.

  @scenario:govern-product-delivery @input:govern-product-delivery-request
  @input-contract:product-delivery-gate-request.v1
  @event:govern-product-delivery-requested @event-authority:govern-product-delivery.v1
  @outcome:govern-product-delivery-outcome @outcome-contract:product-delivery-gate-result.v1 @outcome-terminal
  @case:definition-required-before-product-work
  Scenario: A definition-complete receipt is required before product execution
    Given a product step with an absent authoritative definition receipt
      """json
      {"phase":"PRODUCT","definitionComplete":false,"sameContract":true,"flightReady":true,"modelSaysProceed":true}
      """
    When the declared gate evaluates the pinned contract and execution authority
    Then execution is refused independently of the model suggestion
      | operation | path | equals |
      | govern-product-delivery.evaluate | $.status | REFUSED |

  @scenario:accept-attributed-evidence @input:accept-attributed-evidence-request
  @input-contract:formal-acceptance-fixture.v1
  @event:accept-attributed-evidence-requested @event-authority:accept-attributed-evidence.v1
  @outcome:accept-attributed-evidence-outcome @outcome-contract:formal-acceptance-result.v1 @outcome-terminal
  @case:wrong-invocation-cannot-pass
  Scenario: Acceptance belongs to the canonical case's own complete execution
    Given a fixture satisfying every acceptance predicate except invocation identity
      """json
      {"allOtherPredicates":true,"invocationIdentity":false}
      """
    When the checker evaluates source, request, run, provider, graph, integrity and canonical assertions
    Then the attributed acceptance claim is refused
      | operation | path | equals |
      | accept-attributed-evidence.evaluate | $.status | REFUSED |

  @scenario:accept-complete-product @input:accept-complete-product-request
  @input-contract:formal-acceptance-fixture.v1
  @event:accept-complete-product-requested @event-authority:accept-complete-product.v1
  @outcome:accept-complete-product-outcome @outcome-contract:formal-acceptance-result.v1 @outcome-terminal
  @case:non-vacuous-complete-acceptance
  Scenario: A complete correctly attributed delivery can be accepted
    Given all exact required criteria and ecosystem instances have verified matching proof
      """json
      {"exactRequiredSet":true,"allRequiredPredicates":true,"blockingFindings":0}
      """
    When the declared obligation verifier reads the retained contract, deployment and proof receipts
    Then the obligation-complete result permits submission for review
      | operation | path | equals |
      | accept-complete-product.evaluate | $.status | OBLIGATIONS_COMPLETE |

  @scenario:preserve-replay-boundary @input:preserve-replay-boundary-request
  @input-contract:formal-replay-fixture.v1
  @event:preserve-replay-boundary-requested @event-authority:preserve-replay-boundary.v1
  @outcome:preserve-replay-boundary-outcome @outcome-contract:formal-replay-result.v1 @outcome-terminal
  @case:replay-cannot-reveal-future-or-invoke
  Scenario: Replay contains only the selected invocation's observed prefix
    Given a replay cursor before a terminal event
      """json
      {"cursor":1,"eventFirstObservedAt":[0,1,2],"providerCallsBefore":1}
      """
    When the projection selects the observed prefix without execution authority
    Then future outcomes remain hidden and no invocation is started
      | operation | path | equals |
      | preserve-replay-boundary.evaluate | $.status | PREFIX_ONLY |
      | preserve-replay-boundary.evaluate | $.providerCallsAfter | 1 |

  @scenario:preserve-maintenance-release @input:preserve-maintenance-release-request
  @input-contract:formal-maintenance-fixture.v1
  @event:preserve-maintenance-release-requested @event-authority:preserve-maintenance-release.v1
  @outcome:preserve-maintenance-release-outcome @outcome-contract:formal-maintenance-result.v1 @outcome-terminal
  @case:failed-revision-preserves-verified-release
  Scenario: Failed maintenance cannot replace the last verified publication
    Given a new revision with failed publication readback
      """json
      {"priorRelease":0,"candidateRelease":1,"checksPassed":true,"readbackMatches":false}
      """
    When publication evaluates the candidate against the pinned requirements
    Then the active verified release remains the previous release
      | operation | path | equals |
      | preserve-maintenance-release.evaluate | $.status | FAILED_PRESERVED |
      | preserve-maintenance-release.evaluate | $.activeRelease | 0 |
