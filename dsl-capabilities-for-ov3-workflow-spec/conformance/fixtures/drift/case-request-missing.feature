# Drift fixture of check-capability-feature-conformance. The base conforms to the declared circuit of
# compile-capability-dsl; each fixture changes it in one place.

@capability:compile-capability-dsl
@root-scenario:compile-capability-dsl
Feature: Compile capability DSL

  @scenario:compile-capability-dsl
  @input:compile-capability-dsl-request
  @input-contract:compile-capability-dsl-request.v1
  @event:compile-capability-dsl-requested
  @event-authority:compile-capability-dsl.v1
  @outcome:compile-capability-dsl
  @outcome-contract:compile-capability-dsl-result.v1
  @outcome-terminal
  Rule: The declared circuit

    @case:drift-base
    Scenario: A source that is not on the grammar refuses
      Given DSL source text on the declared grammar
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path     | equals  |
        | compile-capability-dsl.compile | $.status | REFUSED |
