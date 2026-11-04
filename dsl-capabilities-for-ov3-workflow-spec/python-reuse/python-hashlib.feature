@capability:python-hashlib
@root-scenario:python-hashlib
@scenario:python-hashlib
@input:python-hashlib-request
@input-contract:python-hashlib-request.v1
@event:python-hashlib-requested
@event-authority:python-hashlib.v1
@outcome:python-hashlib-outcome
@outcome-contract:python-hashlib-result.v1
@outcome-terminal
Feature: Compute SHA-256 of canonical Base64 bytes with hashlib.new

  @case:python-hashlib-reference-vector
  Scenario: Compute the reference vector on the bound Python runtime
    Given a bounded hashlib request within the admitted Python library profile
      """json
      {"data":"YWJj","algorithm":"sha256"}
      """
    When OV3 invokes the fixed hashlib operation through its declared provider
    Then OV3 returns the computed value and runtime identity or a named input finding
      | operation | path | equals |
      | python-hashlib.compute | $.status | COMPUTED |
      | python-hashlib.compute | $.value.hexdigest | ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad |
      | python-hashlib.compute | $.runtime.implementation | cpython |
