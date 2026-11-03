# check-capability-feature-conformance: canonical feature, review copy for the owner and the owner's team, 2026-11-02,
# tightened the same day after the owner's review.
#
# What this file is: the canonical reference for the read-only check that keeps every capability circuit from
# drifting from its canonical .feature. It comes first: the capability is not declared yet. Its procedure body,
# conformance/check_capability_feature_conformance.body.sql (analysis.check_capability_feature_conformance once
# installed), ran read-only as a session procedure through sql-database-reader. Each probed case below ran with exactly
# its request, and conformance/run-check.mjs re-runs them from this file. With the final body, all 54 probed cases
# met their rows in runs c2d6f5b5, 0c9bcf2f, e08afb93 and 6afa6b38. The check finds this file WELL_FORMED, with the same
# pickles as @cucumber/gherkin (run 230e6700).
#
# What the estate has today (live reads, 2026-11-02):
#   - 669 capabilities are selected in sidefx:capabilities. 451 have a CANONICAL feature row for some version, and 406
#     have one for their selected version. model.estate_capability_feature holds 489 rows (runs 7e2a8058, e23af81e).
#   - Read exactly, by role and selected version, the estate-wide baseline (runs f222a984, 037a132a, 9d96f6fe; again
#     with the final body in a864cec2, fca3a2f7, 4c0b5e30, no capability changed) finds:
#     . 263 NOT_BOUND: 218 have no feature row at all, and 45 are bound only at another version, compose-implementation-design
#       among them.
#     . 406 DRIFT, 0 CONFORMANT. 375 of the 406 bound features are the scaffold greeting (run 54ab1386); none
#       uses @case or @provider.
#     . Identity drift: OUTCOME_IDENTITY_MISMATCH in 390, EVENT_IDENTITY_MISMATCH 389, OUTCOME_CONTRACT_MISMATCH 380,
#       INPUT_CONTRACT_MISMATCH 177, INPUT_IDENTITY_MISMATCH 66.
#     . Declared steps missing from the feature: SCENARIO_STEP_NOT_IN_FEATURE in 396 capabilities (1,183 steps).
#     . FEATURE_PIN_STALE 27. The case codes in 405 capabilities only show that no feature has cases yet.
#   - The estate's own reader, analysis.read_capability_gherkin_rows, gives an untagged scenario the @scenario tag of
#     the scenario before it, and it does not read Scenario Outline. This check does not use it. It parses Gherkin
#     itself, and its pickles equal those of @cucumber/gherkin (case conf-parse-tag-scope and the two after it).
#   - The declared Gherkin steps and identity tags of each scenario version are kept in its definition
#     (semantics.scenario.steps, run 7749b714). The check reads identities from the declared rows, and steps from that
#     definition.
#
# How to read it:
#   - The Feature tags state the check's one circuit scenario and the identities its DSL must declare, named as the
#     compiler names them.
#   - Each Scenario, and each Examples row of an Outline, is one acceptance case with its own @case:<id> or case
#     column. Every case uses the circuit's Given, When and Then word for word. The json docstring is the request. A
#     member written as {"$textOf": <path>} or {"$jsonOf": <path>} is the text, or the parsed JSON, of that file in this
#     folder. Its "$sha256" must match the file. An evidence file is pinned instead by the evidenceDigest of the
#     acceptance record that names it, and the check verifies those bytes itself. The table under Then lists the
#     assertions: operation, JSON path in the result (capability-feature-conformance.v1), and the value it must equal.
#     "(absent)" means the path selects nothing.
#   - A run proves a case only through its own call: a flight step through the k-th dispatch, which is its k-th
#     attempt; a direct call through its request, attested in the run by its canonical digest. Each step reports only
#     its first failing layer: tag, provider identity, step binding, attempt, call, graph, outcome, result.
#
# Feature first, without a circle: the feature's bytes are retained by digest; the compiler compiles the DSL against
# exactly those bytes; the author path (declared change capability-from-dsl) declares the document and binds the
# feature to the new capability version in one transaction, committing only when this check returns CONFORMANT; the
# first call's evidence then accepts each case. This check's part is built and probed (conf-compile-feature-conforms,
# conf-retained-bytes-by-digest); the compiler's and the author path's parts are not built.
#
# Status tags:
#   @status:probed     the body ran read-only through sql-database-reader with exactly this request (run id in a comment)
#   @status:not-built  the owner's direction requires it; nothing implements it yet

@capability:check-capability-feature-conformance
@root-scenario:check-capability-feature-conformance
@scenario:check-capability-feature-conformance
@input:check-capability-feature-conformance-request
@input-contract:check-capability-feature-conformance-request.v1
@event:check-capability-feature-conformance-requested
@event-authority:check-capability-feature-conformance.v1
@outcome:check-capability-feature-conformance-outcome
@outcome-contract:capability-feature-conformance.v1
@outcome-terminal
Feature: A capability's circuit never drifts from its canonical feature
  As the owner of the estate
  I want every capability circuit checked against its canonical .feature by identity, and every case accepted only from its own call
  So that the feature, its DSL, its declaration, its runs and its acceptance always describe the same thing, and OV3 can tell which link broke

  Rule: The check reads exactly the canonical feature bound to the selected version, with no fallback

    @case:conf-greeting-drift
    @provider:sql-database-reader
    @status:probed
    Scenario: The greeting scaffold bound to compile-capability-dsl is drift on three named identities and three steps
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"capabilityId":"compile-capability-dsl"}
        """
      And the CANONICAL feature of its selected version is the scaffold "Write the configured text to standard output"
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                        | equals                                                                                                                                                                                                |
        | check-capability-feature-conformance.check | $.status                    | DRIFT                                                                                                                                                                                                 |
        | check-capability-feature-conformance.check | $.feature.featureVersionPk  | 182894                                                                                                                                                                                                |
        | check-capability-feature-conformance.check | $.feature.contentDigest     | sha256:9f2f5b4ea73e97b4b3134f56b845fe698587dcd536b5899ba9a388e98376f7ab                                                                                                                               |
        | check-capability-feature-conformance.check | $.feature.bytesVerified     | true                                                                                                                                                                                                  |
        | check-capability-feature-conformance.check | $.findings[3].code          | EVENT_IDENTITY_MISMATCH                                                                                                                                                                               |
        | check-capability-feature-conformance.check | $.findings[3].featureValue  | compile-capability-dsl                                                                                                                                                                                |
        | check-capability-feature-conformance.check | $.findings[3].declaredValue | compile-capability-dsl-requested                                                                                                                                                                      |
        | check-capability-feature-conformance.check | $.findings[4].code          | OUTCOME_CONTRACT_MISMATCH                                                                                                                                                                             |
        | check-capability-feature-conformance.check | $.findings[4].featureValue  | compile-capability-dsl-greeting.v1                                                                                                                                                                    |
        | check-capability-feature-conformance.check | $.findings[5].code          | OUTCOME_IDENTITY_MISMATCH                                                                                                                                                                             |
        | check-capability-feature-conformance.check | $.findings[5].featureValue  | compile-capability-dsl-greeting                                                                                                                                                                       |
        | check-capability-feature-conformance.check | $.summary.signature         | status=DRIFT;CASE_ASSERTION_MISSING=1;CASE_IDENTITY_MISSING=1;CASE_REQUEST_MISSING=1;EVENT_IDENTITY_MISMATCH=1;OUTCOME_CONTRACT_MISMATCH=1;OUTCOME_IDENTITY_MISMATCH=1;SCENARIO_STEP_NOT_IN_FEATURE=3 |
      # Run e5dbe9ac. This is the first negative control. The declared steps it lacks are those of
      # features/compile-capability-dsl.feature.

    @case:conf-retained-bytes-by-digest
    @provider:sql-database-reader
    @status:probed
    Scenario: Feature bytes retained under a digest are read and verified by that digest
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"capabilityId":"compile-capability-dsl","featureDigest":"sha256:9f2f5b4ea73e97b4b3134f56b845fe698587dcd536b5899ba9a388e98376f7ab"}
        """
      And source.content_object retains the greeting's bytes under that digest
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                    | equals   |
        | check-capability-feature-conformance.check | $.feature.source        | retained |
        | check-capability-feature-conformance.check | $.feature.bytesVerified | true     |
        | check-capability-feature-conformance.check | $.status                | DRIFT    |
      # Run c2d6f5b5. This is how the author path will check a feature before any binding exists.

    @case:conf-not-bound-other-version
    @provider:sql-database-reader
    @status:probed
    Scenario: A feature bound only to another version of the capability is not the canonical feature
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"capabilityId":"compose-implementation-design"}
        """
      And its CANONICAL row names capability version 4942363 while the selected version is 4942364
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                | equals           |
        | check-capability-feature-conformance.check | $.status            | NOT_BOUND        |
        | check-capability-feature-conformance.check | $.feature           | (absent)         |
        | check-capability-feature-conformance.check | $.summary.signature | status=NOT_BOUND |
      # Run c2d6f5b5. Run e23af81e found 45 capabilities in this state.

    @case:conf-not-found-case-differs
    @provider:sql-database-reader
    @status:probed
    Scenario: A capability id that differs only in case is not found
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"capabilityId":"Compile-Capability-DSL"}
        """
      And the selected estate declares compile-capability-dsl in lower case only
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path     | equals    |
        | check-capability-feature-conformance.check | $.status | NOT_FOUND |
      # Run c2d6f5b5.

  Rule: The check parses Gherkin itself, and a tag set belongs to the next element only

    @case:conf-parse-tag-scope
    @provider:sql-database-reader
    @status:probed
    Scenario: A scenario without a scenario tag traces to no scenario, not to the scenario before it
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"featureText":{"$textOf":"conformance/fixtures/parser/tag-scope.feature","$sha256":"139303fc406cf8ea697e5729b5205f1deb4fb6974a26b628abd4a496e8f6df02"}}
        """
      And its first scenario is tagged @scenario:first and its second has no @scenario tag
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                    | equals                                  |
        | check-capability-feature-conformance.check | $.status                | MALFORMED                               |
        | check-capability-feature-conformance.check | $.summary.signature     | status=MALFORMED;SCENARIO_TAG_MISSING=1 |
        | check-capability-feature-conformance.check | $.pickles[0].scenarioId | first                                   |
        | check-capability-feature-conformance.check | $.pickles[1].caseId     | second-case                             |
        | check-capability-feature-conformance.check | $.pickles[1].scenarioId | (absent)                                |
      # Run e5dbe9ac. Its pickles equal those of @cucumber/gherkin: tags, step types and text, docstrings, tables.

    @case:conf-parse-outline
    @provider:sql-database-reader
    @status:probed
    Scenario: Each Examples row is one case, with its own Examples tags and its placeholders filled
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"featureText":{"$textOf":"conformance/fixtures/parser/outline.feature","$sha256":"ed2fa832793e8d7241720bc54279f0e9f938f83b377b1ce784048c90540b28e1"}}
        """
      And a Scenario Outline has two Examples blocks, the first tagged @provider:sql-database-reader, with three rows in all
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                | equals                                                                                            |
        | check-capability-feature-conformance.check | $.status            | WELL_FORMED                                                                                       |
        | check-capability-feature-conformance.check | $.parse.pickles     | 3                                                                                                 |
        | check-capability-feature-conformance.check | $.pickles[0].caseId | row-one                                                                                           |
        | check-capability-feature-conformance.check | $.pickles[0].tags   | @capability:fixture-outline @provider:sql-database-reader @scenario:fixture-outline @status:probe |
        | check-capability-feature-conformance.check | $.pickles[2].caseId | row-three                                                                                         |
        | check-capability-feature-conformance.check | $.pickles[2].tags   | @capability:fixture-outline @scenario:fixture-outline @status:probe                               |
      # Run e5dbe9ac. The estate's reader does not recognize Scenario Outline at all.

    @case:conf-parse-docstring
    @provider:sql-database-reader
    @status:probed
    Scenario: A docstring's lines are content, never tags or steps
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"featureText":{"$textOf":"conformance/fixtures/parser/docstring.feature","$sha256":"cc114cb7d6bbb9cc979c3bcc3ac82b2189b97efbce2165667abb7503e0b9f8e2"}}
        """
      And a docstring holds an @scenario line, a Then line and the other kind of delimiter
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path               | equals                                                                   |
        | check-capability-feature-conformance.check | $.status           | WELL_FORMED                                                              |
        | check-capability-feature-conformance.check | $.pickles[0].tags  | @capability:fixture-docstring @case:doc-case @scenario:fixture-docstring |
        | check-capability-feature-conformance.check | $.pickles[0].steps | 3                                                                        |
      # Run e5dbe9ac.

  Rule: Identities, steps and cases agree with the declaration in both directions, and each drift is named alone

    @case:conf-compile-feature-conforms
    @provider:sql-database-reader
    @status:probed
    Scenario: The replacement feature of compile-capability-dsl conforms to its declared circuit before it is bound
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"capabilityId":"compile-capability-dsl","featureText":{"$textOf":"features/compile-capability-dsl.feature","$sha256":"3c40ef9a2256f1e5deef38c774590431d4cc2643221a9b0aea63461194f69875"}}
        """
      And the text states the declared identities, the three declared steps in every case, and $.status values COMPILED and REFUSED only
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                | equals            |
        | check-capability-feature-conformance.check | $.status            | CONFORMANT        |
        | check-capability-feature-conformance.check | $.parse.cases       | 9                 |
        | check-capability-feature-conformance.check | $.summary.signature | status=CONFORMANT |
      # Run 2c503ff8. Binding this text in place of the greeting is a write of the author path, not of this check.

    @provider:sql-database-reader
    @status:probed
    Scenario Outline: Each kind of drift is named by its own code
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"capabilityId":"compile-capability-dsl","featureText":{"$textOf":"conformance/fixtures/drift/<fixture>.feature","$sha256":"<sha256>"}}
        """
      And the fixture conforms to the declared circuit of compile-capability-dsl except for <drift>
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                | equals      |
        | check-capability-feature-conformance.check | $.status            | <status>    |
        | check-capability-feature-conformance.check | $.summary.signature | <signature> |

      Examples:
        | case                         | fixture                 | drift                                                      | sha256                                                           | status     | signature                                     |
        | conf-drift-none              | base-conforms           | nothing                                                    | 54d815256aba8b082f9a4f2f20a540a8a23468c2b0e75d9bdb7a9e16b44feb79 | CONFORMANT | status=CONFORMANT                             |
        | conf-drift-capability        | feature-capability      | a @capability tag naming another capability                | 5268f33d875fa4e07411661e0fb5513c2a2c1249491988c16ef0f3c50e72b27f | DRIFT      | status=DRIFT;FEATURE_CAPABILITY_MISMATCH=1    |
        | conf-drift-root              | root-scenario           | a @root-scenario that is not the declared entry            | 180b11be4d5cfd2ca1886279061f5f7b86daa4968d42d17f5395725b40d8aa76 | DRIFT      | status=DRIFT;ROOT_SCENARIO_MISMATCH=1         |
        | conf-drift-scenario-tag      | scenario-undeclared     | a scenario tag that names no declared scenario             | b40a7c9a3304d9f6a821207a6a4fe0d3cf023de92b0eba960bdad6040e285804 | DRIFT      | status=DRIFT;FEATURE_SCENARIO_UNDECLARED=1    |
        | conf-drift-scenario-untagged | scenario-not-in-feature | a declared scenario that no case tags                      | 63c1c62e1baa4acd946e6f0c7505771d269c6ca63407050f8a0ae82d17c4a535 | DRIFT      | status=DRIFT;SCENARIO_NOT_IN_FEATURE=1        |
        | conf-drift-case-untagged     | scenario-tag-missing    | a case that tags no scenario                               | 793fecc0df05344409c44b3bf57eb7259dcf483d91b15a45d0ddbdf89155423f | DRIFT      | status=DRIFT;SCENARIO_TAG_MISSING=1           |
        | conf-drift-input             | input-identity          | an @input the scenario does not declare                    | 70fb0fcbe8bcf6b21475e09fee07d24914dafef602435711e845ea7f45926705 | DRIFT      | status=DRIFT;INPUT_IDENTITY_MISMATCH=1        |
        | conf-drift-input-contract    | input-contract          | an @input-contract the scenario does not declare           | 763c45009a326cd7f359f71f8e8a099b905ffe776b1c58d463a3bfbdd6c863d2 | DRIFT      | status=DRIFT;INPUT_CONTRACT_MISMATCH=1        |
        | conf-drift-event             | event-identity          | the greeting's @event                                      | 4f9adc6afb38f8f5ad0c97ecfde32a1936402e898766202382f838e2c5753798 | DRIFT      | status=DRIFT;EVENT_IDENTITY_MISMATCH=1        |
        | conf-drift-event-authority   | event-authority         | an @event-authority the scenario does not declare          | a16fc47b47533965943a375853a15a1145ca02173778d450d31f390d945fd029 | DRIFT      | status=DRIFT;EVENT_AUTHORITY_MISMATCH=1       |
        | conf-drift-outcome           | outcome-identity        | the greeting's @outcome                                    | 76471d9863bb36795fe9cd6aca42b3440eb30a1a23430ddc654739658db7aa12 | DRIFT      | status=DRIFT;OUTCOME_IDENTITY_MISMATCH=1      |
        | conf-drift-outcome-contract  | outcome-contract        | the greeting's @outcome-contract                           | c84ecb367a885bb90e6687a38233a7eba2d81d7895ce82f1c33f2c7657c43894 | DRIFT      | status=DRIFT;OUTCOME_CONTRACT_MISMATCH=1      |
        | conf-drift-terminal          | outcome-terminal        | no @outcome-terminal on a terminal scenario                | 35ccec411a511a64927806883afbe36667daece880370bc38c2c9ac00920190b | DRIFT      | status=DRIFT;OUTCOME_TERMINAL_MISMATCH=1      |
        | conf-drift-step              | declared-step           | a declared step that no case holds                         | b506d1051bc84bb96372dc595475e14c58fa2d011aa12db599174c4cbc6f1be3 | DRIFT      | status=DRIFT;SCENARIO_STEP_NOT_IN_FEATURE=1   |
        | conf-drift-provider          | provider-unknown        | a provider tag that differs only in case                   | dbe6c5352e84273bcf7645bcb369777063f2eb12bf38b0bd860616873776f9ac | DRIFT      | status=DRIFT;PROVIDER_UNKNOWN=1               |
        | conf-drift-status            | outcome-undeclared      | a $.status the circuit cannot return                       | ab201ea851c92b72643d9bbeaa6460cc0877fdf72d29003be6c5619437312f7f | DRIFT      | status=DRIFT;OUTCOME_UNDECLARED=1             |
        | conf-drift-operation         | operation-undeclared    | an assertion on an operation the scenario does not declare | fad000704ba75ac2311c1a405e4c2145ec8dbc3690db20717635661bfb58d3f4 | DRIFT      | status=DRIFT;ASSERTION_OPERATION_UNDECLARED=1 |
        | conf-drift-case-missing      | case-identity-missing   | a case without @case                                       | c638d45b54be8a6dc3873b84b426b4acc254621ae1fcee76417d2b711e5af9a8 | DRIFT      | status=DRIFT;CASE_IDENTITY_MISSING=1          |
        | conf-drift-case-duplicate    | case-identity-duplicate | two cases with one @case                                   | ce61bd572e387178ee9d7ef188e128c08f809ec46669f395238f246c0fb5dfff | DRIFT      | status=DRIFT;CASE_IDENTITY_DUPLICATE=1        |
        | conf-drift-case-ambiguous    | case-identity-ambiguous | one case with two @case tags                               | f94915d20db851dc52150e09afaee21b70ba818ffd9865efd8d831f5ad86f381 | DRIFT      | status=DRIFT;CASE_IDENTITY_AMBIGUOUS=1        |
        | conf-drift-request-missing   | case-request-missing    | a case without a json request                              | afa7018d45a1def3e8bacd8d85489beffd35eaae7adfd6c726a770aa5f701d80 | DRIFT      | status=DRIFT;CASE_REQUEST_MISSING=1           |
        | conf-drift-request-invalid   | case-request-invalid    | a json request that does not parse                         | fd339cd9373fe553247d6e259e0d6640f68beb05a9b4de893ff0e8795eddadea | DRIFT      | status=DRIFT;CASE_REQUEST_INVALID=1           |
        | conf-drift-assertions        | case-assertion-missing  | a case without an operation, path and equals table         | 09458938b39ea6e27c16c013794af0aa3d5c7701935593d09ce660162d572d54 | DRIFT      | status=DRIFT;CASE_ASSERTION_MISSING=1         |
        | conf-drift-status-unasserted | case-status-unasserted  | assertions that never read $.status                        | 4066a9c8c4d86031979e6072032d52051f1b09f415d1d843242a84aad8ccb462 | DRIFT      | status=DRIFT;CASE_STATUS_UNASSERTED=1         |
        | conf-drift-parse             | parse-error             | a tag line that no keyword follows                         | 04aee29bfce507e2399faac1e89da4a9bd31c5be062c616f390cbe8e8c1b5c72 | DRIFT      | status=DRIFT;GHERKIN_PARSE_ERROR=1            |
      # Run f8aa9214: each fixture changes one line of base-conforms, and each finds exactly its own code.

    @case:conf-provider-binding
    @provider:sql-database-reader
    @status:not-built
    Scenario: Each provider tag is bound by an operation, and each bound provider capability is tagged
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"capabilityId":"reveal-estate-workflows"}
        """
      And reveal-estate-workflows is declared from a DSL whose operation says "uses provider sql-database-reader"
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                | equals            |
        | check-capability-feature-conformance.check | $.status            | CONFORMANT        |
        | check-capability-feature-conformance.check | $.summary.signature | status=CONFORMANT |
      # Needs the compiler's "uses provider" line, which states the provider capability on the operation. Then a tag that
      # no operation binds is PROVIDER_TAG_UNBOUND, and a bound provider capability that no case tags is
      # PROVIDER_BINDING_UNTAGGED. The draft DSL, which binds four platform ports, would be PROVIDER_TAG_UNBOUND.

    @case:conf-dsl-feature-pin
    @provider:sql-database-reader
    @status:not-built
    Scenario: The retained DSL source pins the digest of the feature bound to its capability version
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"capabilityId":"reveal-estate-workflows"}
        """
      And its newest retained DSL source pins the feature with a feature line
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path     | equals     |
        | check-capability-feature-conformance.check | $.status | CONFORMANT |
      # A source that pins no feature is DSL_FEATURE_UNPINNED, and one that pins another digest is DSL_FEATURE_STALE.
      # Needs the compiler's feature line.

  Rule: An acceptance case has an identity, a request and its own assertions

    @case:conf-reveal-well-formed
    @provider:sql-database-reader
    @status:probed
    Scenario: The reveal feature states eight cases, each with a request and a status assertion
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"featureText":{"$textOf":"reveal-estate-workflows/reveal-estate-workflows.feature","$sha256":"2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48"}}
        """
      And reveal-estate-workflows is not declared, so only the feature's own rules apply
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                | equals             |
        | check-capability-feature-conformance.check | $.status            | WELL_FORMED        |
        | check-capability-feature-conformance.check | $.parse.cases       | 8                  |
        | check-capability-feature-conformance.check | $.summary.signature | status=WELL_FORMED |
      # Run 2c503ff8.

    @case:conf-reveal-stale-assertion-removed
    @provider:sql-database-reader
    @status:probed
    Scenario: Removing the STALE assertion leaves the STALE case without a status assertion
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"featureText":{"$textOf":"conformance/fixtures/reveal-without-stale-assertion.feature","$sha256":"e3661c01493c528c68a707c6e1997104a377db31b1e976e672741d52e880e559"}}
        """
      And the fixture is the reveal feature without the row "$.status | STALE" of case reveal-stale-pin
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                 | equals                                    |
        | check-capability-feature-conformance.check | $.status             | MALFORMED                                 |
        | check-capability-feature-conformance.check | $.summary.signature  | status=MALFORMED;CASE_STATUS_UNASSERTED=1 |
        | check-capability-feature-conformance.check | $.findings[0].caseId | reveal-stale-pin                          |
      # Run 2c503ff8. A check keyed only by the circuit scenario would still pass: all eight cases tag the same scenario.

  Rule: A run proves a case only through its own call, from pinned evidence

    @case:conf-accept-census
    @provider:sql-database-reader
    @status:probed
    Scenario: The recorded census provider calls are accepted from pinned evidence
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"acceptance":{"$jsonOf":"conformance/controls/census-1.acceptance.json","$sha256":"91a7997c784833639dba357b07911bcfc3e5a34e8895bd64a23617f981ce7530"},"evidenceText":{"$textOf":"conformance/controls/census-1.bee2eee7.evidence.json"}}
        """
      And the record is the census acceptance contract: plan claude-code-opus-5-5-ov3-harness-census at revision 1, digest 698d488c..., and per step its provider tag, accepted graph digest, returned outcome and expectation
      And the evidence is 27 dispatch events and the step results of run bee2eee7, pinned as sha256:5ced6205...
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                                  | equals                                                                  |
        | check-capability-feature-conformance.check | $.status                              | ACCEPTED                                                                |
        | check-capability-feature-conformance.check | $.acceptance.evidenceVerified         | true                                                                    |
        | check-capability-feature-conformance.check | $.acceptance.steps[0].stepId          | write-census                                                            |
        | check-capability-feature-conformance.check | $.acceptance.steps[0].dispatchCursor  | 778                                                                     |
        | check-capability-feature-conformance.check | $.acceptance.steps[0].graphDigest     | sha256:f6563ca4e5e09732a861f0743c092e8023df1cf31c57cc6144deb226d60e8751 |
        | check-capability-feature-conformance.check | $.acceptance.steps[0].returnedOutcome | MODEL_RESPONSE_OBTAINED                                                 |
        | check-capability-feature-conformance.check | $.acceptance.steps[1].stepId          | check-census                                                            |
        | check-capability-feature-conformance.check | $.acceptance.steps[1].dispatchCursor  | 934                                                                     |
        | check-capability-feature-conformance.check | $.acceptance.steps[1].graphDigest     | sha256:dbb29dc8172312c3546bb706e32b30c32b59cb1ecad3b4dfff7e35826f6f0596 |
        | check-capability-feature-conformance.check | $.acceptance.steps[1].returnedOutcome | READ                                                                    |
        | check-capability-feature-conformance.check | $.acceptance.steps[1].actual          | CENSUS_READY                                                            |
      # Run a49f244e. This is the positive control. The provider returned READ, and CENSUS_READY is the step's own
      # expectation ($.value.status) met by its own call: the 6th dispatch is its attempt 1. read-spec's reader call
      # (dispatch 660) also returned READ, and cannot stand in for check-census.

    @provider:sql-database-reader
    @status:probed
    Scenario Outline: Census acceptance fails when the evidence cannot prove a required call
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"acceptance":{"$jsonOf":"conformance/controls/census-negative/<control>.acceptance.json","$sha256":"<sha256>"},"evidenceText":{"$textOf":"conformance/controls/<evidence>"}}
        """
      And the census positive control is changed in one place: <defect>
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                | equals      |
        | check-capability-feature-conformance.check | $.status            | REJECTED    |
        | check-capability-feature-conformance.check | $.summary.signature | <signature> |

      Examples:
        | case                        | control               | defect                                                         | sha256                                                           | evidence                                            | signature                                       |
        | conf-census-capability-tag  | capability-tag-only   | a required provider named only by a capability tag             | 80faf2e259327b96250f4aeb98b10259b59a803ba479664c01531b994c0e1dc9 | census-1.bee2eee7.evidence.json                     | status=REJECTED;PROVIDER_TAG_MISSING=1          |
        | conf-census-tag-case        | tag-case-differs      | a provider tag differing only in case                          | 3bf4a2542c899cea403801e1fed5e40285c94276cd9ebcccc23e80d3828d049a | census-1.bee2eee7.evidence.json                     | status=REJECTED;PROVIDER_UNKNOWN=1              |
        | conf-census-tag-not-bound   | tag-not-step-binding  | a tag for a capability absent from the accepted step binding   | 7e2896786e9d316ddf2f42f451e0b878dfd4cf5450a0a5e8871a42c67a5cb320 | census-1.bee2eee7.evidence.json                     | status=REJECTED;PROVIDER_TAG_NOT_STEP_BINDING=1 |
        | conf-census-plan            | other-plan-revision   | a different plan revision or digest                            | fabc3abfb8f15969433d2e2961ad7ec658b71a3d9f4941095590811a999506dc | census-1.bee2eee7.evidence.json                     | status=REJECTED;PLAN_MISMATCH=1                 |
        | conf-census-graph           | other-graph-digest    | a different provider graph digest from the accepted pin        | e544edd04e481bf410eec72e2a0500d9026675595a2de4aa7d151cb5e9c2c78d | census-1.bee2eee7.evidence.json                     | status=REJECTED;GRAPH_DIGEST_MISMATCH=1         |
        | conf-census-substituted     | substituted-provider  | a substituted provider returning a plausible census            | 96b4b8a2be94bce585b458c866a929c4e9071c45025ed82e53be1b7a95c86bd2 | census-negative/substituted-provider.evidence.json  | status=REJECTED;PROVIDER_SUBSTITUTED=1          |
        | conf-census-graph-only      | graph-without-outcome | only a captured graph and no invocation outcome                | 00dee85ced930415a26faf7154c243559c2de7013bf394df1b266d475058ad67 | census-negative/graph-without-outcome.evidence.json | status=REJECTED;OUTCOME_NOT_RETURNED=1          |
        | conf-census-another-run     | another-run           | the right provider invoked only in another run                 | 7d6e8ea31bd45c28952f102ea6f62def5e8f23cdcc1c8429930b88a203555c10 | census-negative/another-run.evidence.json           | status=REJECTED;RUN_MISMATCH=1                  |
        | conf-census-another-step    | another-step          | the right provider invoked only in another step                | a6b39e706edbb6bd2a2dea171dd620652af8687810fa9ee685409ed26789d654 | census-negative/another-step.evidence.json          | status=REJECTED;CALL_IN_ANOTHER_STEP=2          |
        | conf-census-another-attempt | another-attempt       | the right provider invoked only in another attempt             | 91ad3b745007bbc60f802659465c47b37501aecb50637c85ca677a3aa4378dea | census-negative/another-attempt.evidence.json       | status=REJECTED;OUTCOME_MISMATCH=1              |
        | conf-census-outcome         | unsatisfying-outcome  | a returned outcome that does not satisfy the step              | 7bc8ff2839371f94f2902f6c50e374dc09c4b70b1617fc31e6f8bbe2dbf38f2f | census-negative/unsatisfying-outcome.evidence.json  | status=REJECTED;OUTCOME_MISMATCH=1              |
        | conf-census-gap             | attribution-gap       | an evidence gap that prevents attribution of the required call | c63e6436d4bed77cb391dc32cda61eb2f0c2d897e56ad2d93ed0b92b1842a1a6 | census-negative/attribution-gap.evidence.json       | status=REJECTED;EVIDENCE_ATTRIBUTION_GAP=1      |
        | conf-census-tampered        | tampered-evidence     | evidence bytes that are not the pinned bytes                   | 91a7997c784833639dba357b07911bcfc3e5a34e8895bd64a23617f981ce7530 | census-negative/tampered-evidence.evidence.json     | status=REJECTED;EVIDENCE_DIGEST_MISMATCH=1      |
      # Run a49f244e. The first ten rows are the census contract's negative controls; another step, another attempt
      # and tampered bytes are added. A changed evidence file is pinned again in its own record, so each row can fail
      # only on its own defect.

    @case:conf-accept-reveal-stale
    @provider:sql-database-reader
    @status:probed
    Scenario: The STALE run proves the STALE case through its own request and result
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"acceptance":{"$jsonOf":"conformance/controls/reveal-stale-pin.acceptance.json","$sha256":"6f301c9b03f2795627ecd1a191759d46668fa53aea33b9609abeb0ce13001ae4"},"featureText":{"$textOf":"reveal-estate-workflows/reveal-estate-workflows.feature","$sha256":"2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48"},"evidenceText":{"$textOf":"conformance/controls/reveal-stale.d1175d72.evidence.json"}}
        """
      And the record names case reveal-stale-pin, operation reveal-estate-workflows.reveal and run d1175d72
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                              | equals                                                                  |
        | check-capability-feature-conformance.check | $.status                          | ACCEPTED                                                                |
        | check-capability-feature-conformance.check | $.acceptance.requestMatches       | true                                                                    |
        | check-capability-feature-conformance.check | $.acceptance.graphDigest          | sha256:dbb29dc8172312c3546bb706e32b30c32b59cb1ecad3b4dfff7e35826f6f0596 |
        | check-capability-feature-conformance.check | $.acceptance.assertions[0].actual | STALE                                                                   |
      # Run 2c503ff8. The case's request and assertions come from the feature text, not from the record.

    @provider:sql-database-reader
    @status:probed
    Scenario Outline: A STALE proof that is not the STALE case's own call is rejected
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"acceptance":{"$jsonOf":"conformance/controls/<record>","$sha256":"<sha256>"},"featureText":{"$textOf":"<feature>"},"evidenceText":{"$textOf":"conformance/controls/<evidence>"}}
        """
      And <defect>
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path                | equals      |
        | check-capability-feature-conformance.check | $.status            | REJECTED    |
        | check-capability-feature-conformance.check | $.summary.signature | <signature> |

      Examples:
        | case                          | record                                                      | sha256                                                           | feature                                                     | evidence                                                 | defect                                                           | signature                                   |
        | conf-reveal-resolved-as-stale | reveal-negative/resolved-run-as-stale-proof.acceptance.json | eaa9aefc2bbbe24883d2b7cc7e52200287dd1dce2e0ba2c9b8a90a467c8e8ff2 | reveal-estate-workflows/reveal-estate-workflows.feature     | reveal-resolved.f6b88ab2.evidence.json                   | the RESOLVED run is offered as the STALE case's proof            | status=REJECTED;EVIDENCE_REQUEST_MISMATCH=1 |
        | conf-reveal-unasserted        | reveal-stale-pin.acceptance.json                            | 6f301c9b03f2795627ecd1a191759d46668fa53aea33b9609abeb0ce13001ae4 | conformance/fixtures/reveal-without-stale-assertion.feature | reveal-stale.d1175d72.evidence.json                      | the STALE case has lost its status assertion                     | status=REJECTED;CASE_STATUS_UNASSERTED=1    |
        | conf-reveal-wrong-result      | reveal-negative/stale-request-wrong-result.acceptance.json  | d17f4d1f7d48827632be49011f2767d3d49c9fc0670d039fc174ff22bd26c953 | reveal-estate-workflows/reveal-estate-workflows.feature     | reveal-negative/stale-request-wrong-result.evidence.json | the STALE case's own request returned a result that is not STALE | status=REJECTED;ASSERTION_FAILED=1          |
      # Run 2c503ff8. The reviewer's two tests are the first two rows: both fail.

  Rule: The estate baseline reads every selected capability, bound or not

    @case:conf-baseline-first-page
    @provider:sql-database-reader
    @status:probed
    Scenario: The first page of the baseline lists the first hundred selected capabilities by identity
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"baseline":{"after":"","size":100}}
        """
      And the estate selects 669 capabilities in sidefx:capabilities
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path         | equals           |
        | check-capability-feature-conformance.check | $.status     | BASELINE         |
        | check-capability-feature-conformance.check | $.page.count | 100              |
        | check-capability-feature-conformance.check | $.page.last  | complete-api-run |
      # Run f222a984; pages two and three are runs 037a132a and 9d96f6fe. Over all 669: 406 DRIFT, 263 NOT_BOUND,
      # 0 CONFORMANT (totals in the header). New capabilities move the page boundaries.

    @case:conf-author-path-check
    @provider:sql-database-reader
    @status:not-built
    Scenario: The author path commits a declaration only when its feature conforms
      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
        """json
        {"capabilityId":"reveal-estate-workflows","featureDigest":"sha256:2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48"}
        """
      And the declared change capability-from-dsl has declared the document and bound the retained feature inside its transaction
      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
        | operation                                  | path     | equals     |
        | check-capability-feature-conformance.check | $.status | CONFORMANT |
      # Any other status rolls the transaction back and returns the findings. model.apply_capability_from_dsl does not
      # call the check yet.
