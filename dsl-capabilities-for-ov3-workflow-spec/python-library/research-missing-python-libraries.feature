@capability:research-missing-python-libraries
@root-scenario:research-missing-python-libraries
@scenario:research-missing-python-libraries
@input:research-missing-python-libraries-request
@input-contract:research-missing-python-libraries-request.v1
@event:research-missing-python-libraries-requested
@event-authority:research-missing-python-libraries.v1
@outcome:research-missing-python-libraries-outcome
@outcome-contract:python-library-research-pass.v1
@outcome-terminal
Feature: OV3 researches outstanding Python modules from a reconciled inventory
  As the estate owner
  I want module research to survive an interruption
  So that OV3 can finish the requested scope without repeating completed work

  @case:research-missing-python-libraries-json
  @provider:sql-database-reader
  @provider:research-python-library-batch
  Scenario: OV3 researches outstanding Python modules from a reconciled inventory
    Given a named OV3 inventory conversation and its retained research coverage
      """json
      {"conversationId":"64d0c3cd-34f6-4937-89bc-b0ff6b93d3b2","module":"json"}
      """
    When OV3 partitions the uncovered current modules into bounded batches and invokes each batch exactly once in this pass
    Then OV3 returns the batch receipt counts and names the coverage check
      | operation | path | equals |
      | research-missing-python-libraries.finish | $.status | SETTLED |
