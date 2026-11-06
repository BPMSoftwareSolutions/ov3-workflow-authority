@capability:classify-capability-cultivation
@provider:ask-system-one
Feature: Classify bounded use cases against pinned estate declarations

  Scenario: Interpret each candidate against the same catalog and ontology
    Given typed use cases with source identities and a shortlist drawn from a pinned estate snapshot
    When the declared System One provider answers one bounded choice per use case
    Then the decision belongs to this vocabulary
      | choice | criterion |
      | REUSE | One retrieved public capability covers the whole requested use with its declared semantics. |
      | COMPOSE | Two or more named retrieved declarations can cover the whole use with compatible data and effects and no missing primitive. |
      | NEW_MECHANIC_CANDIDATE | A concrete essential primitive is absent from retrieved public and subordinate mechanics. Propose investigation of that gap. |
      | UNRESOLVED | Meaning, retrieval, compatibility, permissions or coverage is too uncertain to distinguish the other classes. |

  Scenario: Retain the basis of each advisory decision
    Given a complete answer set for a typed batch
    When the four probabilities and the confidence are valid numbers in the unit interval
    Then retain each case identity, retrieved declarations, model, probabilities, input digest and run receipt

  Scenario: Validate the decision profile before any routing policy can consume it
    Given a representative sample chosen independently of model answers
    When an independent reviewer has classified the sample against the estate
    Then report class-specific agreement, errors and calibration with the sample design
    And leave automatic triage disabled until a separate policy is accepted
