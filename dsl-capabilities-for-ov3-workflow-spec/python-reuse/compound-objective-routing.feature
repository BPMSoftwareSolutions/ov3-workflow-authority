Feature: OV3 discovers operations needed after the first action
  Scenario: A compound objective uses the public catalog
    Given a default objective and a ranked first-action shortlist
    When distinctive words in the objective also identify selectable public capabilities
    Then preserve the original ranked tools and append at most eight distinct public identities

  Scenario: The caller supplies a visible portfolio
    Given an explicit visibleCapabilities array on the objective or its payload
    When the router finds additional catalog matches
    Then preserve the caller's exact array, including an empty array

  Scenario: No first-action ranking is available
    Given an objective without a first-action ranking
    When the router returns the objective to the agent loop
    Then retain the existing full-catalog behavior
