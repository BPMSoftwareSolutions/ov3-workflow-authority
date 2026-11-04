@capability:generate-python-library-report
@root-scenario:generate-python-library-report
@scenario:generate-python-library-report
@input:generate-python-library-report-request
@input-contract:generate-python-library-report-request.v1
@event:generate-python-library-report-requested
@event-authority:generate-python-library-report.v1
@outcome:generate-python-library-report-outcome
@outcome-contract:python-library-report.v1
@outcome-terminal
Feature: OV3 fulfills a full Python library provider report from the reference URL
  As the estate owner
  I want every current library covered without a second scope decision
  So that I receive one report I can inspect and resume

  @case:python-url-to-report
  @provider:read-python-library-sources
  @provider:sql-database-reader
  @provider:research-python-library-batch
  @provider:apply-declared-change
  Scenario: Complete coverage at publication
    Given the official Python standard library reference URL and public research batches retained within the last twenty-four hours
      """json
      {"url":"https://docs.python.org/3/library/index.html"}
      """
    When OV3 inventories the modules, researches missing current modules in retained batches, rechecks the official inventory and publishes the Markdown
    And the Markdown and publication receipt carry the final module index URL, documentation version and SHA-256 of the response bytes
    Then OV3 returns a digest and reports complete only when every current module has a sourced proposal with contracts and five ranked uses
      | operation | path | equals |
      | generate-python-library-report.finish | $.status | COMPLETE |
      | generate-python-library-report.finish | $.missingCount | 0 |
