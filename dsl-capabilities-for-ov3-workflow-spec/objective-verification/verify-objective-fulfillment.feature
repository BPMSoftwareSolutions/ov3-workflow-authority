@capability:verify-objective-fulfillment
@root-scenario:verify-objective-fulfillment
Feature: OV3 verifies published work against the typed obligations of the full original objective
  As the estate owner
  I want verifiable proof and a scoped inference decision before an objective closes
  So that a successful tool return alone cannot fulfill an objective

  @scenario:verify-objective-fulfillment
  @input:verify-objective-fulfillment-request
  @input-contract:verify-objective-fulfillment-request.v1
  @event:verify-objective-fulfillment-requested
  @event-authority:verify-objective-fulfillment.v1
  @outcome:verify-objective-fulfillment-outcome
  @outcome-contract:objective-verification-review.v1
  @case:typed-obligations-ready
  @provider:sql-database-reader
  Scenario: All proof gates pass and a typed state is ready
    Given an original objective and an actual retained publication turn
      """json
      {"conversationId":"4ca89bb0-c7ed-4e95-bd19-603abb357b19","publicationTurn":3}
      """
    When OV3 resolves its proof profile and constructs the typed obligations from the pinned source, published bytes and supporting receipts
    Then only a complete well-typed proof is routed to inference
      | operation | path | equals |
      | verify-objective-fulfillment.evidence | $.status | INFER |

  @scenario:verify-objective-fulfillment-infer
  @input:verify-objective-fulfillment-infer-request
  @input-contract:objective-verification-review.v1
  @event:verify-objective-fulfillment-infer-requested
  @event-authority:verify-objective-fulfillment-infer.v1
  @outcome:verify-objective-fulfillment-infer-outcome
  @outcome-contract:objective-verification.v1
  @outcome-terminal
  @case:complete-pinned-report
  @provider:ask-system-one
  @provider:sql-database-reader
  Scenario: The original request is fully evidenced
    Given a complete mechanically proved objective-obligations.v1 state
      """json
      {"conversationId":"4ca89bb0-c7ed-4e95-bd19-603abb357b19","publicationTurn":3,"expectedSourceVersion":"3.15.2"}
      """
    When System One chooses a work contract for the entire original request from the typed obligations
    Then OV3 closes only a confident match and returns the bound source identity and proof receipts
      | operation | path | equals |
      | verify-objective-fulfillment.decide | $.status | FULFILLED |
      | verify-objective-fulfillment.decide | $.sourceIdentity.version | 3.15.2 |
      | verify-objective-fulfillment.decide | $.metrics.provedModules | 297 |
      | verify-objective-fulfillment.decide | $.obligationsContract | objective-obligations.v1 |

  @scenario:verify-objective-fulfillment-hold
  @input:verify-objective-fulfillment-hold-request
  @input-contract:objective-verification-review.v1
  @event:verify-objective-fulfillment-hold-requested
  @event-authority:verify-objective-fulfillment-hold.v1
  @outcome:verify-objective-fulfillment-hold-outcome
  @outcome-contract:objective-verification.v1
  @outcome-terminal
  @case:wrong-patch-level
  @provider:sql-database-reader
  Scenario: A different requested patch release holds closure
    Given a publication with missing, contradictory or malformed obligation evidence
      """json
      {"conversationId":"4ca89bb0-c7ed-4e95-bd19-603abb357b19","publicationTurn":3,"expectedSourceVersion":"3.15.1"}
      """
    When OV3 retains the deterministic findings without a System One call
    Then the objective remains unverified with the failed checks and the source it examined
      | operation | path | equals |
      | verify-objective-fulfillment.hold | $.status | UNVERIFIED |
      | verify-objective-fulfillment.hold | $.inference.status | SKIPPED |

  @scenario:verify-objective-fulfillment-hold
  @input:verify-objective-fulfillment-hold-request
  @input-contract:objective-verification-review.v1
  @event:verify-objective-fulfillment-hold-requested
  @event-authority:verify-objective-fulfillment-hold.v1
  @outcome:verify-objective-fulfillment-hold-outcome
  @outcome-contract:objective-verification.v1
  @outcome-terminal
  @case:partial-publication
  @provider:sql-database-reader
  Scenario: A partial publication cannot fulfill the full original request
    Given a publication with missing, contradictory or malformed obligation evidence
      """json
      {"conversationId":"4ca89bb0-c7ed-4e95-bd19-603abb357b19","publicationTurn":1}
      """
    When OV3 retains the deterministic findings without a System One call
    Then the objective remains unverified with the failed checks and the source it examined
      | operation | path | equals |
      | verify-objective-fulfillment.hold | $.status | UNVERIFIED |
      | verify-objective-fulfillment.hold | $.reason | PROOF_CHECK_FAILED |

  @scenario:verify-objective-fulfillment-hold
  @input:verify-objective-fulfillment-hold-request
  @input-contract:objective-verification-review.v1
  @event:verify-objective-fulfillment-hold-requested
  @event-authority:verify-objective-fulfillment-hold.v1
  @outcome:verify-objective-fulfillment-hold-outcome
  @outcome-contract:objective-verification.v1
  @outcome-terminal
  @case:wrong-artifact
  @provider:sql-database-reader
  Scenario: An unrelated artifact digest holds closure
    Given a publication with missing, contradictory or malformed obligation evidence
      """json
      {"conversationId":"4ca89bb0-c7ed-4e95-bd19-603abb357b19","publicationTurn":3,"expectedArtifactDigest":"sha256:0000000000000000000000000000000000000000000000000000000000000000"}
      """
    When OV3 retains the deterministic findings without a System One call
    Then the objective remains unverified with the failed checks and the source it examined
      | operation | path | equals |
      | verify-objective-fulfillment.hold | $.status | UNVERIFIED |

  @scenario:verify-objective-fulfillment
  @input:verify-objective-fulfillment-request
  @input-contract:verify-objective-fulfillment-request.v1
  @event:verify-objective-fulfillment-requested
  @event-authority:verify-objective-fulfillment.v1
  @outcome:verify-objective-fulfillment-outcome
  @outcome-contract:objective-verification-review.v1
  @case:published-notice
  @provider:sql-database-reader
  Scenario: The published notice has all operation receipts
    Given an original objective and an actual retained publication turn
      """json
      {"conversationId":"7c1f0f8c-952c-4d77-9fa4-6e05effbb6ac","publicationTurn":6,"expectedArtifactDigest":"sha256:f5261c8dddb6f98e420fa75fa1fa09700dafcc3aa6eb942bc83e86f6af7a59f5"}
      """
    When OV3 resolves its proof profile and constructs the typed obligations from the pinned source, published bytes and supporting receipts
    Then only a complete well-typed proof is routed to inference
      | operation | path | equals |
      | verify-objective-fulfillment.evidence | $.status | INFER |
      | verify-objective-fulfillment.evidence | $.context.metrics.observedOperations | 5 |

  @scenario:verify-objective-fulfillment
  @input:verify-objective-fulfillment-request
  @input-contract:verify-objective-fulfillment-request.v1
  @event:verify-objective-fulfillment-requested
  @event-authority:verify-objective-fulfillment.v1
  @outcome:verify-objective-fulfillment-outcome
  @outcome-contract:objective-verification-review.v1
  @case:published-ledger
  @provider:sql-database-reader
  Scenario: The published ledger has all operation receipts
    Given an original objective and an actual retained publication turn
      """json
      {"conversationId":"f8900169-3abc-4501-87f8-aad6a8e43b74","publicationTurn":4,"expectedArtifactDigest":"sha256:c557c34314513ff51f7501a17d47cc3bd04fb1a92bdaa63c0b6914570bcdfded"}
      """
    When OV3 resolves its proof profile and constructs the typed obligations from the pinned source, published bytes and supporting receipts
    Then only a complete well-typed proof is routed to inference
      | operation | path | equals |
      | verify-objective-fulfillment.evidence | $.status | INFER |
      | verify-objective-fulfillment.evidence | $.context.metrics.observedOperations | 3 |
