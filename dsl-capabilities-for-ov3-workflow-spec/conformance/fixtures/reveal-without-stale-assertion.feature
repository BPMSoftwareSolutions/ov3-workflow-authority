# reveal-estate-workflows: canonical feature, review copy for the owner and the owner's team, 2026-11-02, tightened the
# same day after the owner's review.
#
# What this file is: the canonical reference for capability reveal-estate-workflows (specification
# ov3.estate-workflow-discovery.v1, section 5, work package W3). It comes first. The DSL, the estate declaration, the
# runs and the acceptance each trace to it by identity. Nothing is declared yet, and the flight that would declare it
# is on hold.
#
# How to read it:
#   - The Feature tags state the one circuit scenario and its identities, named as the compiler names them: input,
#     input contract, event, event authority, outcome, outcome contract and terminal. The DSL must declare exactly
#     these. The draft DSL does (compile run 91a0e162).
#   - Each Scenario is one acceptance case, and @case:<id> is its identity. A case id is unique in this file.
#   - Every case uses the circuit's own Given, When and Then: the DSL scenario's given, when and then lines,
#     word for word.
#     The json docstring under Given is the case's request, exactly. The table under Then lists the assertions. Each row
#     names the operation whose result it reads, a JSON path in that result (workflow-lens.v1) and the value it must
#     equal. "[]" means an empty array.
#   - @provider:<capability-id> names the provider capability that operation reveal-estate-workflows.reveal uses. The
#     DSL is re-expressed before the build as "operation reveal-estate-workflows.reveal uses provider
#     sql-database-reader". The draft still binds the four platform ports, which is drift.
#   - A run proves a case only when its request is this case's request and its own result meets this case's rows.
#     The no-drift check (features/check-capability-feature-conformance.feature) applies both rules.
#
# Status tags:
#   @status:probed  the procedure body ran read-only through sql-database-reader with exactly this request (run id
#                   in a comment); the capability is not declared yet
#
# Not covered by a case: ROUTE_VARIANT_UNDECLARED. The procedure holds a selection whose variant its from scenario
# does not declare, but no live capability has one, so there is no request to pin.

@capability:reveal-estate-workflows
@root-scenario:reveal-estate-workflows
@scenario:reveal-estate-workflows
@input:reveal-estate-workflows-request
@input-contract:reveal-estate-workflows-request.v1
@event:reveal-estate-workflows-requested
@event-authority:reveal-estate-workflows.v1
@outcome:reveal-estate-workflows-outcome
@outcome-contract:workflow-lens.v1
@outcome-terminal
Feature: Reveal the admitted workflows of a capability
  As a SideFX estate reviewer
  I want each workflow a capability admits, from its declared entry over admitted transitions only
  So that providers, product dependencies and undeclared arrows cannot pass for workflow routes

  Rule: An entry comes from declared entry authority, never from the shape of the graph

    @case:reveal-resolved
    @provider:sql-database-reader
    @status:probed
    Scenario: A capability whose entry and transitions are all admitted resolves
      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
        """json
        {"capabilityId":"dispatch-pair-demo"}
        """
      And dispatch-pair-demo declares its root scenario, its CLI input contract and six transitions that each carry semanticProgress
      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
        | operation                      | path                | equals                                      |
        | reveal-estate-workflows.reveal | $.status            | RESOLVED                                    |
        | reveal-estate-workflows.reveal | $.summary.signature | entries=1/1;edges=6/6;reached=4;terminals=1 |
      # Run f6b88ab2. This is the first-call proof. Evidence: conformance/controls/reveal-resolved.f6b88ab2.evidence.json.

    @case:reveal-entry-without-cli-input
    @provider:sql-database-reader
    @status:probed
    Scenario: A root scenario without a CLI input contract is not an entry
      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
        """json
        {"capabilityId":"project-model-provider-protocol"}
        """
      And project-model-provider-protocol declares a root scenario but no CLI input contract
      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
        | operation                      | path                     | equals                                        |
        | reveal-estate-workflows.reveal | $.status                 | NOT_DECLARED                                  |
        | reveal-estate-workflows.reveal | $.entries[0].status      | held                                          |
        | reveal-estate-workflows.reveal | $.entries[0].findings[0] | ENTRY_CLI_INPUT_MISSING                       |
        | reveal-estate-workflows.reveal | $.summary.signature      | entries=0/1;edges=16/16;reached=0;terminals=0 |
      # Run 04e36e84. Its 16 transitions are still listed, each admitted.

    @case:reveal-leg-is-not-an-entry
    @provider:sql-database-reader
    @status:probed
    Scenario: A scenario that is not a declared entry is refused as an entry
      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
        """json
        {"capabilityId":"dispatch-pair-demo","entryScenarioId":"dispatch-pair-demo-leg-a"}
        """
      And dispatch-pair-demo-leg-a is a leg of dispatch-pair-demo and not its root
      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
        | operation                      | path                | equals                                      |
        | reveal-estate-workflows.reveal | $.status            | NOT_DECLARED                                |
        | reveal-estate-workflows.reveal | $.entryScenarioId   | dispatch-pair-demo-leg-a                    |
        | reveal-estate-workflows.reveal | $.workflows         | []                                          |
        | reveal-estate-workflows.reveal | $.summary.signature | entries=1/1;edges=6/6;reached=0;terminals=0 |
      # Run 09b0b2f1.

    @case:reveal-no-transitions
    @provider:sql-database-reader
    @status:probed
    Scenario: A capability with no transitions is its own workflow
      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
        """json
        {"capabilityId":"compile-capability-dsl"}
        """
      And compile-capability-dsl declares one root terminal scenario and no routing
      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
        | operation                      | path                | equals                                      |
        | reveal-estate-workflows.reveal | $.status            | RESOLVED                                    |
        | reveal-estate-workflows.reveal | $.summary.signature | entries=1/1;edges=0/0;reached=1;terminals=1 |
      # Run 7554ea8c.

  Rule: A transition is traversed only when it is admitted

    @case:reveal-held-selections
    @provider:sql-database-reader
    @status:probed
    Scenario: Selections without semanticProgress and an unbounded recurrence are held
      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
        """json
        {"capabilityId":"request-capability-from-objective-v3"}
        """
      And request-capability-from-objective-v3 declares three selections without semanticProgress and a recurrence without max
      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
        | operation                      | path                             | equals                                          |
        | reveal-estate-workflows.reveal | $.status                         | PARTIAL_WITH_HELD_GAPS                          |
        | reveal-estate-workflows.reveal | $.executionEdges[0].findings[0]  | ROUTE_SEMANTIC_PROGRESS_MISSING                 |
        | reveal-estate-workflows.reveal | $.executionEdges[3].transitionId | recur-request-capability-from-objective-v3-turn |
        | reveal-estate-workflows.reveal | $.executionEdges[3].findings[0]  | RECURRENCE_UNBOUNDED                            |
        | reveal-estate-workflows.reveal | $.summary.signature              | entries=1/1;edges=0/4;reached=1;terminals=0     |
      # Run 3f81051e. The workflow stops at its entry.

    @case:reveal-held-fan-out
    @provider:sql-database-reader
    @status:probed
    Scenario: A fan-out declared before the compiler wrote semanticProgress is held
      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
        """json
        {"capabilityId":"concurrent-fanout-demo"}
        """
      And concurrent-fanout-demo declares a broadcast and its join without semanticProgress
      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
        | operation                      | path                            | equals                                      |
        | reveal-estate-workflows.reveal | $.status                        | PARTIAL_WITH_HELD_GAPS                      |
        | reveal-estate-workflows.reveal | $.executionEdges[0].findings[0] | ROUTE_SEMANTIC_PROGRESS_MISSING             |
        | reveal-estate-workflows.reveal | $.summary.signature             | entries=1/1;edges=0/6;reached=1;terminals=0 |
      # Run e8c7ed61. All six transitions are held.

  Rule: The lens answers only for what it can pin

    @case:reveal-stale-pin
    @provider:sql-database-reader
    @status:probed
    Scenario: A pinned definition digest that differs refuses
      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
        """json
        {"capabilityId":"dispatch-pair-demo","expectedDefinitionDigest":"sha256:0000000000000000000000000000000000000000000000000000000000000000"}
        """
      And the pinned digest is not the selected definition digest of dispatch-pair-demo
      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
        | operation                      | path                       | equals                                                                  |
        | reveal-estate-workflows.reveal | $.expectedDefinitionDigest | sha256:0000000000000000000000000000000000000000000000000000000000000000 |
      # Run d1175d72. Evidence: conformance/controls/reveal-stale.d1175d72.evidence.json.

    @case:reveal-not-found
    @provider:sql-database-reader
    @status:probed
    Scenario: An unknown capability is not found
      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
        """json
        {"capabilityId":"no-such-capability-dsl01"}
        """
      And the selected estate has no capability no-such-capability-dsl01
      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
        | operation                      | path           | equals                   |
        | reveal-estate-workflows.reveal | $.status       | NOT_FOUND                |
        | reveal-estate-workflows.reveal | $.capabilityId | no-such-capability-dsl01 |
      # Run bec5e723.
