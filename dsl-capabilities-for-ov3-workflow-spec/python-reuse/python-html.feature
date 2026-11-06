@capability:python-html
@root-scenario:python-html
@scenario:python-html
@input:python-html-request
@input-contract:python-html-request.v1
@event:python-html-requested
@event-authority:python-html.v1
@outcome:python-html-outcome
@outcome-contract:python-html-result.v1
@outcome-terminal
Feature: Escape UTF-8 text for display with html.escape

  @case:python-html-reference-vector
  Scenario: Compute the reference vector on the bound Python runtime
    Given a bounded html request within the admitted Python library profile
      """json
      {"text":"<A&B>"}
      """
    When OV3 invokes the fixed html operation through its declared provider
    Then OV3 returns the computed value and runtime identity or a named input finding
      | operation | path | equals |
      | python-html.compute | $.status | COMPUTED |
      | python-html.compute | $.value.escaped | &lt;A&amp;B&gt; |
      | python-html.compute | $.runtime.implementation | cpython |
