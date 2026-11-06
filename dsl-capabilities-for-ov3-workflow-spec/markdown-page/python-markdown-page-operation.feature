@capability:python-markdown-page-operation
@root-scenario:python-markdown-page-operation
@scenario:python-markdown-page-operation
@input:python-markdown-page-operation-request
@input-contract:python-markdown-page-operation-request.v1
@event:python-markdown-page-operation-requested
@event-authority:python-markdown-page-operation.v1
@outcome:python-markdown-page-operation-outcome
@outcome-contract:markdown-page-operation.v1
@outcome-terminal
Feature: Run a bounded page operation in the pinned CPython from a C# or Python kernel
  @case:reject-unpinned-package
  Scenario: Resolve a sealed parser and sanitizer package
    Given a phase, page input and the package bytes selected by the page capability
      """json
      {"phase":"render","bundle":"YQ==","request":{},"html":"","receipt":{},"inputDigest":"sha256:0000000000000000000000000000000000000000000000000000000000000000"}
      """
    When the declared provider launches the fixed package operation in CPython, bounded to 80 seconds
    Then the provider returns the phase result or a specific package or input finding
      | operation | path | equals |
      | python-markdown-page-operation.compute | $.status | FAILED |
      | python-markdown-page-operation.compute | $.finding | PACKAGE_CLOSURE_MISMATCH |
