# Parser fixture: a tag set belongs to the next Scenario only. The second scenario has no @scenario tag, so it traces
# to no circuit scenario. The estate's reader (analysis.read_capability_gherkin_rows) gives it "first" instead.

@capability:fixture-tag-scope
Feature: Tags belong to the next element only

  @scenario:first
  @case:first-case
  Scenario: The first scenario carries its own scenario tag
    Given a step
      """json
      {"n":1}
      """
    Then a result
      | operation | path     | equals |
      | op        | $.status | OK     |

  @case:second-case
  Scenario: The second scenario carries none
    Given a step
      """json
      {"n":2}
      """
    Then a result
      | operation | path     | equals |
      | op        | $.status | OK     |
