@capability:research-python-library-batch
@root-scenario:research-python-library-batch
@scenario:research-python-library-batch
@input:research-python-library-batch-request
@input-contract:research-python-library-batch-request.v1
@event:research-python-library-batch-requested
@event-authority:research-python-library-batch.v1
@outcome:research-python-library-batch-outcome
@outcome-contract:python-library-batch-receipt.v1
@outcome-terminal
Feature: OV3 retains a bounded batch of public Python module research
  As the estate owner
  I want module research to survive an interruption
  So that OV3 can finish the requested scope without repeating completed work

  @case:research-python-library-batch-json
  @provider:sql-database-reader
  @provider:propose-python-library-binding
  @provider:apply-declared-change
  Scenario: OV3 retains a bounded batch of public Python module research
    Given up to five distinct official Python library documentation URLs
      """json
      {"sources":[{"url":"https://docs.python.org/3/library/json.html#module-json"}]}
      """
    When OV3 invokes the binding proposal provider for each URL and retains the returned entries together
    Then OV3 returns the retained batch digest
      | operation | path | equals |
      | research-python-library-batch.finish | $.status | RETAINED |
