@capability:assemble-python-library-report
@root-scenario:assemble-python-library-report
@scenario:assemble-python-library-report
@input:assemble-python-library-report-request
@input-contract:assemble-python-library-report-request.v1
@event:assemble-python-library-report-requested
@event-authority:assemble-python-library-report.v1
@outcome:assemble-python-library-report-outcome
@outcome-contract:python-library-report.v1
@outcome-terminal
Feature: OV3 publishes a report from the module proposals it actually obtained
  As the estate owner
  I want one report with a source and an explicit disposition for each module
  So that incomplete research is visible and subsequent conversations can supply missing entries

  @case:py-report-json
  @provider:sql-database-reader
  @provider:apply-declared-change
  Scenario: The retained JSON module proposal covers the requested module
    Given a named OV3 conversation with a Python module inventory and retained proposal turns
      """json
      {"conversationId":"64d0c3cd-34f6-4937-89bc-b0ff6b93d3b2","module":"json"}
      """
    And a reusable public research batch must have been retained since the inventory snapshot and match its module name and documentation URL
    When OV3 reconciles the inventory with the cited proposals and retains the Markdown by digest
    And the published source identity includes the documentation version read from that inventory's title and its module index hash
    Then OV3 returns the verified report digest and coverage for the requested scope
      | operation | path | equals |
      | assemble-python-library-report.finish | $.status | COMPLETE |
      | assemble-python-library-report.finish | $.proposals | 1 |
      | assemble-python-library-report.finish | $.missingCount | 0 |
