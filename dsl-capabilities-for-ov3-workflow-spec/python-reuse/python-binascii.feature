@capability:python-binascii
@root-scenario:python-binascii
@scenario:python-binascii
@input:python-binascii-request
@input-contract:python-binascii-request.v1
@event:python-binascii-requested
@event-authority:python-binascii.v1
@outcome:python-binascii-outcome
@outcome-contract:python-binascii-result.v1
@outcome-terminal
Feature: Compute the unsigned CRC-32 of canonical Base64 bytes

  @case:python-binascii-reference-vector
  Scenario: Compute the reference vector on the bound Python runtime
    Given a bounded binascii request within the admitted Python library profile
      """json
      {"data":"MTIzNDU2Nzg5"}
      """
    When OV3 invokes the fixed binascii operation through its declared provider
    Then OV3 returns the computed value and runtime identity or a named input finding
      | operation | path | equals |
      | python-binascii.compute | $.status | COMPUTED |
      | python-binascii.compute | $.value.hex | cbf43926 |
      | python-binascii.compute | $.runtime.implementation | cpython |
