@capability:python-textwrap
@root-scenario:python-textwrap
@scenario:python-textwrap
@input:python-textwrap-request
@input-contract:python-textwrap-request.v1
@event:python-textwrap-requested
@event-authority:python-textwrap.v1
@outcome:python-textwrap-outcome
@outcome-contract:python-textwrap-result.v1
@outcome-terminal
Feature: Wrap a UTF-8 paragraph to a bounded width using textwrap.TextWrapper.wrap

  @case:python-textwrap-reference-vector
  Scenario: Compute the reference vector on the bound Python runtime
    Given a bounded textwrap request within the admitted Python library profile
      """json
      {"text":"alpha beta","width":5}
      """
    When OV3 invokes the fixed textwrap operation through its declared provider
    Then OV3 returns the computed value and runtime identity or a named input finding
      | operation | path | equals |
      | python-textwrap.compute | $.status | COMPUTED |
      | python-textwrap.compute | $.value.lines[1] | beta |
      | python-textwrap.compute | $.runtime.implementation | cpython |
