@capability:propose-python-library-binding
@root-scenario:propose-python-library-binding
@scenario:propose-python-library-binding
@input:propose-python-library-binding-request
@input-contract:propose-python-library-binding-request.v1
@event:propose-python-library-binding-requested
@event-authority:propose-python-library-binding.v1
@outcome:propose-python-library-binding-outcome
@outcome-contract:python-library-binding-proposal.v1
@outcome-terminal
Feature: OV3 can design a provider binding from one Python module's documentation
  As the estate owner
  I want OV3 to research one candidate dependency at a time
  So that every report entry can be traced to Python's documentation

  @case:py-proposal-json
  @provider:scrape-web-page
  @provider:sql-database-reader
  @provider:ask-model
  Scenario: Design a proposed JSON binding from its source
    Given a documentation URL for one indexed Python module
      """json
      {"url":"https://docs.python.org/3/library/json.html#module-json"}
      """
    When OV3 scrapes its documentation and validates a structured binding proposal against the requested report shape
    Then OV3 returns a cited proposal with typed contracts and five ranked uses or a named finding
      | operation | path | equals |
      | propose-python-library-binding.finish | $.status | PROPOSED |
      | propose-python-library-binding.finish | $.source.module | json |
