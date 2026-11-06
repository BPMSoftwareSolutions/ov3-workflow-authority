# Fixture for compile-capability-dsl cases compile-feature-pin and compile-feature-drift: the canonical feature of probe
# capability dsl02-probe-feature-first, retained by its digest before its DSL is compiled. Never declared.

@capability:dsl02-probe-feature-first
@root-scenario:dsl02-probe-feature-first
@scenario:dsl02-probe-feature-first
@input:dsl02-probe-feature-first-request
@input-contract:dsl02-probe-feature-first-request.v1
@event:dsl02-probe-feature-first-requested
@event-authority:dsl02-probe-feature-first.v1
@outcome:dsl02-probe-feature-first-outcome
@outcome-contract:dsl02-probe-feature-first-result.v1
@outcome-terminal
Feature: Read one value through the provider the feature names

  @case:probe-read
  @provider:sql-database-reader
  Scenario: The provider reads the value
    Given a request naming a value
      """json
      {"value":"x"}
      """
    When the provider reads it
    Then the result carries the value
      | operation                      | path     | equals |
      | dsl02-probe-feature-first.read | $.status | READ   |
