# compile-capability-dsl: canonical feature, review copy for the owner and the owner's team, 2026-11-02, tightened the
# same day after the owner's review.
#
# What this file is: the canonical reference for capability compile-capability-dsl (procedure
# analysis.compile_capability_dsl). It replaces the scaffold the estate binds today: feature version 182894, content
# digest 9f2f5b4e..., "Write the configured text to standard output", which promises a greeting (run 7e2a8058). The
# replacement is bound only after the no-drift check returns CONFORMANT for this text against the declared circuit
# (case conf-compile-feature-conforms in features/check-capability-feature-conformance.feature).
#
# How to read it:
#   - The Feature tags state the circuit's one scenario and the identities the estate declares for it (run 13e208b3):
#     input, input contract, event, event authority, outcome, outcome contract and terminal. Its declared outcome
#     variants are COMPILED and REFUSED, and its one operation is compile-capability-dsl.compile.
#   - Each Scenario is one acceptance case with its own @case:<id>. Every case uses the declared Given, When and Then
#     word for word. The json docstring under Given is the request. A member written as
#     {"$textOf": <path>, "$sha256": <digest>} is the UTF-8 text of that file in this folder, whose sha256 must
#     match. The table under Then lists the assertions: operation, JSON path in the result
#     (compile-capability-dsl-result.v1), and the value it must equal. "[]" means an empty array.
#   - No @provider tag: the operation binds platform port sda-embodiment-plan-port.v1, which is not a provider
#     capability.
#
# Feature first, without a circle. The cases of the last two rules are the compiler's part of this sequence:
#   1. The feature's bytes are retained under their sha256 before anything is compiled.
#   2. The DSL source pins that digest with a feature line, and the compiler reads exactly those bytes, never a
#      binding, which a new capability does not have yet. It checks the source against them with the no-drift check and
#      refuses each drift as DSL_FEATURE_DRIFT, at the source line it concerns and with its code first in the message.
#   3. The author path (declared change capability-from-dsl, model.apply_capability_from_dsl) declares the document and,
#      at the end of the same change, binds those bytes to the capability version it selected. It commits only when the
#      check returns CONFORMANT for that binding.
#   4. The first call's evidence then accepts each case at run time.
#
# The provider lines are the owner's grammar ("operation <id> uses provider <capability>" and "input <member> from
# <scenario>.<operation> <path>"), with "outcome from <operation> <path>" for the scenario's outcome. They compile to the
# estate's dispatch that binds no technical debt: vault, credential and open, a statement that composes the provider's
# request, and generic-capability-invocation.v1, the path request-capability-from-objective-v3 already runs for
# ask-system-one. The operation keeps its id and states providerCapabilityId, and the declaration keeps both in the
# scenario's execution authority, where the no-drift check reads them.
#
# The grammar is listed in capability-dsl-specification.v1: 29 constructs and 25 document-semantics rows (run 549c4381).
# dsl-08 adds feature, usesProvider, input and outcomeFrom and revises config: 33 and 29.
#
# Status tags:
#   @status:proven  ran with the installed compiler and exactly this request (run id in a comment)
#   @status:probed  ran with the revised compiler, source/analysis.compile_capability_dsl.v3.sql, created as a session
#                   procedure and called through sql-database-reader with exactly this request; feature bytes a step says
#                   are retained were placed in a session table read beside source.content_object (run id in a comment).
#                   dsl-07 installs the revision. Every proven case also compiles to the same result with it.

@capability:compile-capability-dsl
@root-scenario:compile-capability-dsl
@scenario:compile-capability-dsl
@input:compile-capability-dsl-request
@input-contract:compile-capability-dsl-request.v1
@event:compile-capability-dsl-requested
@event-authority:compile-capability-dsl.v1
@outcome:compile-capability-dsl
@outcome-contract:compile-capability-dsl-result.v1
@outcome-terminal
Feature: Compile capability DSL into the declared document, or refuse with named diagnostics
  As a capability author, human or OV3
  I want DSL source compiled deterministically into the sidefx-capability-authority.v1 document
  So that every capability declaration is authored from text and every refusal names its line and reason

  Rule: A source on the declared grammar compiles with no diagnostics

    @case:compile-drafting-form
    @status:proven
    Scenario: A source in the drafting form compiles with no diagnostics
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"reveal-estate-workflows/reveal-estate-workflows.dsl","$sha256":"8253c22216a0be2324c2d1ef4df994c83034a014f83179eb9fc66e5e3545b00f"}}
        """
      And the source declares three inquiries, two contracts, one root terminal scenario and four bound ports
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path               | equals                                                                  |
        | compile-capability-dsl.compile | $.status           | COMPILED                                                                |
        | compile-capability-dsl.compile | $.sourceDigest     | sha256:8253c22216a0be2324c2d1ef4df994c83034a014f83179eb9fc66e5e3545b00f |
        | compile-capability-dsl.compile | $.documentDigest   | sha256:822546c95da61cbab9f4e9b27f48ac2173447d28f29b9463edc6715a7b842d6c |
        | compile-capability-dsl.compile | $.diagnostics      | []                                                                      |
        | compile-capability-dsl.compile | $.providerBindings | []                                                                      |
      # Run 91a0e162.

  Rule: Every compiled transition carries its semanticProgress by the estate law

    @case:compile-semantic-progress-law
    @status:proven
    Scenario: Selection, broadcast, join, failure and recurrence each get their law value
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"probes/dsl01-probe-topology.dsl","$sha256":"bc391b678a05f7d4ec5cdb658171aef4934fecd2ea170121b14440fe92eebd74"}}
        """
      And the source routes into a terminal and a non-terminal scenario, broadcasts to two legs with their join, and recurs with max 3
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path                                    | equals                                                                  |
        | compile-capability-dsl.compile | $.status                                | COMPILED                                                                |
        | compile-capability-dsl.compile | $.sourceDigest                          | sha256:bc391b678a05f7d4ec5cdb658171aef4934fecd2ea170121b14440fe92eebd74 |
        | compile-capability-dsl.compile | $.documentDigest                        | sha256:202ebb9e45e33997e88a0ede6d9721cc6047608216b39a717591e55daa482c15 |
        | compile-capability-dsl.compile | $.document.routing[0].semanticProgress  | expanding                                                               |
        | compile-capability-dsl.compile | $.document.routing[1].semanticProgress  | converging                                                              |
        | compile-capability-dsl.compile | $.document.routing[2].semanticProgress  | converging                                                              |
        | compile-capability-dsl.compile | $.document.routing[6].transitionId      | route-intake-accepted                                                   |
        | compile-capability-dsl.compile | $.document.routing[6].semanticProgress  | narrowing                                                               |
        | compile-capability-dsl.compile | $.document.routing[7].transitionId      | route-intake-rejected                                                   |
        | compile-capability-dsl.compile | $.document.routing[7].semanticProgress  | terminating                                                             |
        | compile-capability-dsl.compile | $.document.routing[10].semanticProgress | recurring                                                               |
      # Run 564885e8: 11 of 11 transitions carry their value. The document digest pins all eleven.
      # [0] enter-leg-a broadcast, [1] settle-leg-a join, [2] fail-leg-a failure at its join slot.

  Rule: Lines the specification forbids refuse instead of compiling

    @case:compile-unsafe-lines-refuse
    @status:proven
    Scenario: Eight unsafe lines each refuse with a named diagnostic
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"probes/dsl01-probe-refusals.dsl","$sha256":"4b0c033e984aead023071b7b658b39d648100f792e09610e6fd024964ed2f468"}}
        """
      And the source has a second root scenario, an invoke-scenario of an undeclared scenario, a self invoke-scenario, a scenario variant marked :terminal, a self route, a two-route cycle and a join without a broadcast
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path                  | equals                                                                  |
        | compile-capability-dsl.compile | $.status              | REFUSED                                                                 |
        | compile-capability-dsl.compile | $.sourceDigest        | sha256:4b0c033e984aead023071b7b658b39d648100f792e09610e6fd024964ed2f468 |
        | compile-capability-dsl.compile | $.diagnostics[0].code | DSL_DUPLICATE_ID                                                        |
        | compile-capability-dsl.compile | $.diagnostics[0].line | 9                                                                       |
        | compile-capability-dsl.compile | $.diagnostics[1].code | DSL_VALUE_INVALID                                                       |
        | compile-capability-dsl.compile | $.diagnostics[1].line | 15                                                                      |
        | compile-capability-dsl.compile | $.diagnostics[2].code | DSL_VALUE_INVALID                                                       |
        | compile-capability-dsl.compile | $.diagnostics[2].line | 16                                                                      |
        | compile-capability-dsl.compile | $.diagnostics[3].code | DSL_VALUE_INVALID                                                       |
        | compile-capability-dsl.compile | $.diagnostics[3].line | 18                                                                      |
        | compile-capability-dsl.compile | $.diagnostics[4].code | DSL_VALUE_INVALID                                                       |
        | compile-capability-dsl.compile | $.diagnostics[4].line | 20                                                                      |
        | compile-capability-dsl.compile | $.diagnostics[5].code | DSL_VALUE_INVALID                                                       |
        | compile-capability-dsl.compile | $.diagnostics[5].line | 22                                                                      |
        | compile-capability-dsl.compile | $.diagnostics[6].code | DSL_VALUE_INVALID                                                       |
        | compile-capability-dsl.compile | $.diagnostics[6].line | 23                                                                      |
        | compile-capability-dsl.compile | $.diagnostics[7].code | DSL_REQUIRED_MISSING                                                    |
        | compile-capability-dsl.compile | $.diagnostics[7].line | 24                                                                      |
      # Run 5de6ee3d: one diagnostic per unsafe line.

  Rule: A provider binding is content-addressed and its placeholder resolves

    @case:compile-provider-binding-digest
    @status:proven
    Scenario: A configuration that names a provider binding receives its digest
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"probes/dsl01-probe-binding.dsl","$sha256":"716307578ed920887ef0764b885e5daab79d2924d58f60075c3891cc4576900b"}}
        """
      And the binding's JSON holds two spaces inside a string and spaces between members, and a platform config names it as @provider-binding:dsl01-probe-binding.v1
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path                                                                   | equals                                                                  |
        | compile-capability-dsl.compile | $.status                                                               | COMPILED                                                                |
        | compile-capability-dsl.compile | $.providerBindings[0].providerBindingId                                | dsl01-probe-binding.v1                                                  |
        | compile-capability-dsl.compile | $.providerBindings[0].digest                                           | sha256:5e1fe1ec3926ee0aa0ac39d244aa7d9682ed5d06ae99d96ea722d4911e0a53fd |
        | compile-capability-dsl.compile | $.providerBindings[0].content.note                                     | spaces  inside a string stay                                            |
        | compile-capability-dsl.compile | $.document.scenarios[0].portBindings[0].configuration.expression.value | sha256:5e1fe1ec3926ee0aa0ac39d244aa7d9682ed5d06ae99d96ea722d4911e0a53fd |
        | compile-capability-dsl.compile | $.documentDigest                                                       | sha256:9d2054e35bbc76b5ab78439dca749d137e790b35d83dc76a35d47b7ac49b8c41 |
      # Run 42d00088. The digest is the sha256 of the binding's JSON without the whitespace outside strings. The live
      # specification's vector V8 reproduces the digest of the binding minted on 2026-10-15, sha256:bde28572...

  Rule: The compiler reads the feature from its retained bytes, by digest, and refuses drift from it

    @case:compile-feature-pin
    @status:probed
    Scenario: A source pins the retained bytes of the feature it implements
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"conformance/fixtures/compile/feature-pin.dsl","$sha256":"ad6c6b3eb86cc70a3f78dbe82b1425d1565b4d197fd2a38d034249324fcf2598"}}
        """
      And the bytes of conformance/fixtures/compile/feature-first-probe.feature are retained under sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc
      And the source pins them with "feature dsl02-probe-feature-first sha256:a27afaf6...", names its provider with "uses provider sql-database-reader" and takes its outcome with "outcome from dsl02-probe-feature-first.read $"
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path                                                       | equals                                                                  |
        | compile-capability-dsl.compile | $.status                                                   | COMPILED                                                                |
        | compile-capability-dsl.compile | $.document.feature.capabilityId                            | dsl02-probe-feature-first                                               |
        | compile-capability-dsl.compile | $.document.feature.digest                                  | sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc |
        | compile-capability-dsl.compile | $.document.scenarios[0].operations[4].operationId          | dsl02-probe-feature-first.read                                          |
        | compile-capability-dsl.compile | $.document.scenarios[0].operations[4].providerCapabilityId | sql-database-reader                                                     |
        | compile-capability-dsl.compile | $.document.scenarios[0].operations[8].operationId          | dsl02-probe-feature-first.outcome                                       |
        | compile-capability-dsl.compile | $.documentDigest                                           | sha256:74acfefad613ef94ada2048aefa7bd47f076d5a20becf30fe413170a837e9aec |
      # Run 41a325bf. Operations 0 to 3 are the vault, credential, open and composing statement the provider operation
      # compiles to, and 5 to 8 the outcome's. The source conforms to the feature's bytes, so the check found no drift.

    @case:compile-feature-pin-unretained
    @status:probed
    Scenario: A pinned feature digest with no retained bytes refuses
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"conformance/fixtures/compile/feature-pin-unretained.dsl","$sha256":"f44d606ebf5be693b4f99cb27fb53ab60e77f061b271604a544de37c3b117805"}}
        """
      And no bytes are retained under the digest its feature line pins
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path                  | equals                   |
        | compile-capability-dsl.compile | $.status              | REFUSED                  |
        | compile-capability-dsl.compile | $.diagnostics[0].code | DSL_FEATURE_NOT_RETAINED |
        | compile-capability-dsl.compile | $.diagnostics[0].line | 3                        |
      # Run cf232301.

    @case:compile-feature-drift
    @status:probed
    Scenario: A source line that drifts from its pinned feature refuses, naming the drift
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"conformance/fixtures/compile/feature-drift.dsl","$sha256":"f754503b79a84af6ebfc79f104557fa8d51440d0be59a98a79cf2207e43c7f28"}}
        """
      And the bytes of conformance/fixtures/compile/feature-first-probe.feature are retained under sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc
      And its then line is "the result holds the value", while the pinned feature's step is "the result carries the value"
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path                     | equals                                                   |
        | compile-capability-dsl.compile | $.status                 | REFUSED                                                  |
        | compile-capability-dsl.compile | $.diagnostics[0].code    | DSL_FEATURE_DRIFT                                        |
        | compile-capability-dsl.compile | $.diagnostics[0].line    | 11                                                       |
        | compile-capability-dsl.compile | $.diagnostics[0].message | SCENARIO_STEP_NOT_IN_FEATURE: the result holds the value |
        | compile-capability-dsl.compile | $.diagnostics[1]         | (absent)                                                 |
      # Run c5fc7a4b. The result contract admits only code, line and message on a diagnostic, so the drift code leads the
      # message.

    @case:compile-greeting-pin
    @status:probed
    Scenario: A source pinned to the greeting scaffold refuses with each drift named
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"conformance/fixtures/compile/greeting-pinned.dsl","$sha256":"c8d4347c365a22dd2138d70a5749546834253b455689df61ade895863af75057"}}
        """
      And the estate itself retains the greeting scaffold bound to compile-capability-dsl today, under sha256:9f2f5b4e...
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path                     | equals                                                                                                                                                       |
        | compile-capability-dsl.compile | $.status                 | REFUSED                                                                                                                                                      |
        | compile-capability-dsl.compile | $.diagnostics[0].message | CASE_ASSERTION_MISSING: the case at feature line 13                                                                                                          |
        | compile-capability-dsl.compile | $.diagnostics[3].message | EVENT_IDENTITY_MISMATCH: feature compile-capability-dsl, source compile-capability-dsl-requested                                                             |
        | compile-capability-dsl.compile | $.diagnostics[4].message | OUTCOME_CONTRACT_MISMATCH: feature compile-capability-dsl-greeting.v1, source compile-capability-dsl-result.v1                                               |
        | compile-capability-dsl.compile | $.diagnostics[5].message | OUTCOME_IDENTITY_MISMATCH: feature compile-capability-dsl-greeting, source compile-capability-dsl-outcome                                                    |
        | compile-capability-dsl.compile | $.diagnostics[6].line    | 10                                                                                                                                                           |
        | compile-capability-dsl.compile | $.diagnostics[9].message | PROVIDER_BINDING_UNTAGGED: operation compile-capability-dsl.compile uses sql-database-reader, and no case of its scenario tags @provider:sql-database-reader |
      # Run c77e1863, with the bytes the estate retains: three case findings, three identities, the three declared steps
      # the greeting lacks, and the untagged provider.

  Rule: An operation names the provider capability that does its job, and the result it consumes

    @case:compile-uses-unknown-provider
    @status:probed
    Scenario: A provider id that sidefx:capabilities does not declare exactly refuses
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"conformance/fixtures/compile/uses-unknown-provider.dsl","$sha256":"77d3f1a88ecb3386297d9d29d59e01660829269849bb0e6463285618e5ab20f9"}}
        """
      And the bytes of conformance/fixtures/compile/feature-first-probe.feature are retained under sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc
      And its operation says "uses provider Sql-Database-Reader", which differs from sql-database-reader only in case
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path                  | equals               |
        | compile-capability-dsl.compile | $.status              | REFUSED              |
        | compile-capability-dsl.compile | $.diagnostics[0].code | DSL_PROVIDER_UNKNOWN |
        | compile-capability-dsl.compile | $.diagnostics[0].line | 12                   |
      # Run 5e3ec950.

    @case:compile-input-from
    @status:probed
    Scenario: An operation's input member names the earlier result it consumes
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"conformance/fixtures/compile/input-from.dsl","$sha256":"71f6aa39ba01180f580a893d6f9d35eb38e628fb6b4a931812b40d417702c02b"}}
        """
      And operation dsl02-probe-input-from.ask takes its prompt from the value operation dsl02-probe-input-from.read returns
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path                                                       | equals                      |
        | compile-capability-dsl.compile | $.status                                                   | COMPILED                    |
        | compile-capability-dsl.compile | $.document.scenarios[0].operations[9].providerCapabilityId | ask-model                   |
        | compile-capability-dsl.compile | $.document.scenarios[0].operations[9].inputs[0].member     | prompt                      |
        | compile-capability-dsl.compile | $.document.scenarios[0].operations[9].inputs[0].from       | dsl02-probe-input-from.read |
        | compile-capability-dsl.compile | $.document.scenarios[0].operations[9].inputs[0].path       | $.value                     |
      # Run 46648e5e. The composing statement of dsl02-probe-input-from.ask reads $.result.value: the result of the provider
      # just before. A source that names any other operation refuses, so lineage follows the declared order.

    @case:compile-reveal-revision-2
    @status:probed
    Scenario: The Phase A lens, re-expressed with its provider, compiles against its canonical feature
      Given DSL source text on the declared grammar
        """json
        {"source":{"$textOf":"reveal-estate-workflows/reveal-estate-workflows.feature-first.dsl","$sha256":"d78a4131ea10e08f59636a2d16ea0066d2f27471b7bf15342ee24ab5ddf1626e"}}
        """
      And the bytes of reveal-estate-workflows/reveal-estate-workflows.feature are retained under sha256:2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48
      And its operation reveal-estate-workflows.reveal uses provider sql-database-reader, with the request as its input and the lens as the outcome
      When the resolver parses every line and validates the whole document
      Then the compiled capability document with its digests, or the named DSL_* refusals with line numbers
        | operation                      | path                                                       | equals                                                                  |
        | compile-capability-dsl.compile | $.status                                                   | COMPILED                                                                |
        | compile-capability-dsl.compile | $.document.feature.digest                                  | sha256:2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48 |
        | compile-capability-dsl.compile | $.document.scenarios[0].operations[4].operationId          | reveal-estate-workflows.reveal                                          |
        | compile-capability-dsl.compile | $.document.scenarios[0].operations[4].providerCapabilityId | sql-database-reader                                                     |
      # Run 7626b28f. This is the source revision 2 of the Reveal flight will declare.
