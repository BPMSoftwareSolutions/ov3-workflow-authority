@capability:python-base64
@root-scenario:python-base64
@scenario:python-base64
@input:python-base64-request
@input-contract:python-base64-request.v1
@event:python-base64-requested
@event-authority:python-base64.v1
@outcome:python-base64-outcome
@outcome-contract:python-base64-result.v1
@outcome-terminal
Feature: Encode UTF-8 text as padded unwrapped RFC 4648 Base64

  @case:python-base64-reference-vector
  Scenario: Compute the reference vector on the bound Python runtime
    Given a bounded base64 request within the admitted Python library profile
      """json
      {"data":"café"}
      """
    When OV3 invokes the fixed base64 operation through its declared provider
    Then OV3 returns the computed value and runtime identity or a named input finding
      | operation | path | equals |
      | python-base64.compute | $.status | COMPUTED |
      | python-base64.compute | $.value.encoded | Y2Fmw6k= |
      | python-base64.compute | $.runtime.implementation | cpython |
