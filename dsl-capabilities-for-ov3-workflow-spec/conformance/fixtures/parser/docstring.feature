# Parser fixture: a docstring's lines are content, never tags or steps, and a delimiter closes only the kind that
# opened it.

@capability:fixture-docstring
@scenario:fixture-docstring
Feature: A docstring's lines are content, never tags or steps

  @case:doc-case
  Scenario: The docstring holds tag-like and step-like lines
    Given a request
      """json
      {"note":"@scenario:not-a-tag"}
      """
    And a text block
      ```
      @scenario:still-not-a-tag
      Then not a step
      """
      ```
    Then a result
      | operation | path     | equals |
      | op        | $.status | OK     |
