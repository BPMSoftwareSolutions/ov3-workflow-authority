# Review copy for the owner and the owner's team, 2026-11-02. Revised the same day after the owner's review of census-2
# and the owner's direction on provider bindings.
#
# What this file is: the behavior the ov3-agentic-harness pack puts in place (sql/ov3-harness-06 and -07, flight
# ov3-harness-census-2) and what it still leaves open, written as Gherkin. It is not a canonical feature. The estate holds
# one canonical feature per capability, and OV3 writes those itself (task oah-features).
#
# Status tags:
#   @status:proven         ran in the estate, and the flight closed with PROMISE_CLOSED
#   @status:installed      the estate does this today (read from the installed definition, not from a run)
#   @status:probed         each step ran on its own against the live estate and DeepSeek; the flight has not run
#   @status:ready-not-run  written and checked offline (63 of 63 checks); takes effect once the owner runs SQL 06 and 07
#   @status:planned        a tracker task; no flight is planned for it yet
#   @status:not-built      the owner's direction requires it; nothing implements it yet
#
# Terms:
#   flight            one run of a recorded plan; each step calls a declared capability and checks its result
#   review            OV3's deterministic check of one exact plan digest; the verdict is CONFORMANT or not
#   work class        the kind of work a plan does; it selects the clearance policy
#   clearance         what must hold before a plan flies, set by flight-clearance-policy:<work class>
#   census            the capability areas the complete harness needs; each area owns recorded obligations
#   obligation        one recorded thing the work must answer: a tracker project, a task of the project, or one quoted
#                     line of the owner's direction
#   id check          analysis.check_capability_census: every obligation id is claimed by some area
#   fulfillment check a separate model pass judges each claim, and analysis.check_census_fulfillment counts an obligation
#                     as owned only when an area that claims it does what it requires
#   provider binding  the declared provider capability a scenario needs, named by its estate identity, the result it must
#                     produce there, and the run evidence that proves it did
#   provider tag      @provider:<id> names one required provider capability in sidefx:capabilities, case for case.
#   capability tag    @capability:<id> identifies the entry capability under test. Provider dependencies have their own tags.
#   decision point    a flight step that waits for an owner act
#
# The population: the live tracker read 52 obligations (probe ce4cf538: 39 projects, 10 tasks and the 3 lines of direction
# revision 1). The flight reads them after SQL 06 adds revision 2 and after its own tracker step adds 3 tasks: 69 on the
# 2026-11-02 baseline (39 projects, 13 tasks, 17 direction lines). Every check uses the population the flight reads.

@project:ov3-complete-agentic-harness
@status:proposed-for-review
Feature: OV3 owns the owner's objective
  As the owner
  I want to give OV3 an objective and have OV3 own the work from there
  So that I decide only what I reserve, and am never OV3's planner, relay or approver

  The owner's directions of 2026-11-02, retained as owner-direction:ov3-complete-agentic-harness revision 2 (the quotes are
  an assessment and a recommendation the owner endorsed):
  "You give OV3 an objective. OV3 owns the work from there - assembling the evidence, planning, coordinating specialists,
  executing, checking the result against your intent, and correcting gaps. That includes building and improving the harness
  itself. You retain authority over the decisions you reserve."
  "OV3 network should not asking for my approval to fulfill my request. I need efficiency."
  "I'd make the expected provider binding part of each canonical feature wherever the scenario depends on a provider."

  Provider acceptance applies to every scenario that invokes a provider. Each required provider has one @provider:<id>
  tag on that scenario. For each expected call, acceptance compares the tag with the accepted estate binding for that
  scenario and step, then reads the invocation and its returned outcome from the scenario run. Repeated calls to one
  tagged provider each need their own evidence. A probe establishes only the path it actually exercised.

  Rule: Transfer of agency is one objective, sent once, closed with no further command

    @status:not-built
    @task:oah-agency-acceptance
    @capability:request-capability-from-objective-v3
    @provider:record-flight-plan
    @provider:review-flight-plan
    @provider:fly-flight-plan
    Scenario: One objective, sent once, closes with no further command
      Given the owner sends one objective, once
      When OV3 plans the work and flies it
      And a result misses the owner's intent, as one area "format-labels" claiming every obligation does
      Then OV3 catches the miss, corrects it and delivers evidence of closure
      And neither the owner nor another agent issues the next command
      # The acceptance test from the owner's review. Census-2 already catches and corrects format-labels (rules below), but
      # Claude Code still plans it and the owner still runs its SQL, so this is not met yet.

  Rule: A plan for the owner's objective clears on OV3's own review, with no owner approval

    @status:ready-not-run
    @provider:resolve-flight-clearance
    @task:oah-owner-objective-clearance
    @flight:ov3-harness-census-2
    Scenario: A conforming review alone clears the plan
      Given a flight plan of work class "owner-objective"
      And the newest review of that plan's exact digest is CONFORMANT
      And no owner approval is recorded for the plan
      When OV3 resolves the flight's clearance
      Then the flight is CLEARED under flight-clearance-policy:owner-objective, which requires OV3_CONFORMANT only
      # SQL 06 adds the policy row (sha256:07f9005b...). The task is verified when flight ov3-harness-census-2 clears this way.

    @status:installed
    @provider:resolve-flight-clearance
    Scenario: No approval does not mean no check
      Given a flight plan of work class "owner-objective"
      And its only CONFORMANT review names an earlier plan digest
      When OV3 resolves the flight's clearance
      Then the flight is NOT_CLEARED

    @status:installed
    @provider:resolve-flight-clearance
    Scenario: A work class without its own policy still waits for the owner's approval
      Given a flight plan whose work class has no clearance policy of its own
      When OV3 resolves the flight's clearance
      Then flight-clearance-policy:default applies, which requires OV3_CONFORMANT and OWNER_APPROVAL
      # The five ov3-teaching plans were recorded before this direction, in work classes skill-registration,
      # project-tracking and capability-build, so they still need the owner's approval (skills-1: recording 521c95ea).

    @status:not-built
    @provider:review-flight-plan
    Scenario: The review refuses an approval step the owner did not reserve
      Given a plan of work class "owner-objective" with an approve-flight-plan, await-owner-decision or record-owner-decision step
      And that step is not for a decision the owner reserves
      When OV3 reviews the plan
      Then the review is not CONFORMANT and names the step
      # Nothing enforces this today. The census-2 plan has no such step (checked offline).

  Rule: OV3 checks its work against every recorded obligation, for ownership and for fulfillment

    @status:probed
    @task:oah-census
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: The obligations are read from rows
      Given the tracker's projects, the tasks of project ov3-complete-agentic-harness and the newest owner-direction row
      When OV3 reads the census sources
      Then there is one obligation for each project, each task and each quoted line of the owner's direction
      And every later check uses exactly those obligations
      # Probe ce4cf538 read 52 live. The probes below used the 69 the flight will read.

    @status:probed
    @task:oah-census
    @provider:ask-model
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: A census is ready only when every obligation is owned by an area that fulfills it
      Given the census sources the flight read
      When OV3 checks a census
      Then the status is CENSUS_READY only if all of these hold:
        | every obligation id is answered by at least one area                                                     |
        | there are 1 to 60 areas (the writer aims for 30)                                                         |
        | every area id is unique and uses only lowercase ASCII letters, digits, dots and hyphens                  |
        | every area has a name, a responsibility and at least one real obligation id                              |
        | each of the five concerns the owner named is covered by an area                                          |
        | every obligation is claimed by an area the fulfillment check judged to do what the obligation requires   |
      # The five concerns: elaborate planning, self-improvement, multi-agent consensus, control plane and deterministic
      # multi-step execution. Probe 2f19a147: CENSUS_READY, 30 areas, 69 of 69 fulfilled.

    @status:probed
    @task:oah-census
    @provider:ask-model
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: An area that does not do what an obligation requires fulfills nothing it claims
      Given a census whose one area, "format-labels", has the responsibility "Alphabetize display labels"
      And it claims all 69 obligations and all five concerns
      When OV3 checks the census
      Then the id check alone says CENSUS_READY
      But the fulfillment check judges 0 of the 69 claims fulfilled
      And the status is CENSUS_INVALID, with feedback that names every obligation for correction
      # The owner's review found the id check passing it (run 15e76f2e, 52 live obligations); reproduced on 69 (f11d0688).
      # Judge edd7f58e: 0 of 69. Gate 6d20bf47: CENSUS_INVALID, 69 claims rejected.

    @status:probed
    @task:oah-census
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: The fulfillment check cannot give an obligation to an area that does not claim it
      Given a judgment that names an area that does not claim the obligation as fulfilling it
      When OV3 checks the census
      Then the obligation stays unfulfilled
      # Gate self-test 72be20ba: 0 fulfilled, 2 rejected. SQL 06 runs the same case in its self-test.

    @status:probed
    @task:oah-census
    @provider:ask-model
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: A project's domain work is not a harness area
      Given a tracker project whose own domain is, for example, resume documents or financial analysis
      When OV3 checks a census
      Then an area that does that domain work itself fulfills nothing
      And an area that declares, builds and runs the project's domain capabilities from its specification fulfills it
      # The writer, the judge and the correction now state this one rule. Before it was aligned, the same kind of area was
      # accepted in one run (2188d526) and rejected in another (8dabe1dc).

    @status:probed
    @task:oah-census
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: Citations the estate does not hold are removed and reported
      Given a census area that says it reuses a capability the estate does not hold
      When OV3 checks the census
      Then the citation is removed from the checked census
      And the feedback and census.md say it was removed
      # Probe bc00f99c removed generate-resume-document and read-run-model-attempts from the first write.

    @status:ready-not-run
    @task:oah-spec-assembly
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: The gap the owner found cannot pass again
      Given task oah-spec-assembly is recorded in project ov3-complete-agentic-harness
      And a census in which no area answers task:oah-spec-assembly
      When OV3 checks the census
      Then the status is CENSUS_INVALID
      And the feedback names task:oah-spec-assembly
      # The first census check tested the five concerns only, so a census in which no area owned specification assembly passed.

  Rule: OV3 corrects what its checks find, in up to two rounds, before anything is kept or delivered

    @status:probed
    @task:oah-census
    @provider:ask-model
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: OV3 fixes the defects its checks name
      Given OV3 wrote a census in which 68 of the 69 obligations are fulfilled
      And the checks named the defects
      When OV3 corrects the census from the same sources, its census and the checks' feedback
      Then the corrected census fulfills all 69 obligations
      And both checks pass
      # Write bc12cf9e (deepseek-flash, 26 s); id check bc00f99c; judge 8ab74de3; gate 8fde4890 (68 of 69);
      # correct 1f7cee92; apply 02d25ab9; id check ed885dda; judge 496ec1d1; gate 2f19a147 (CENSUS_READY, 69 of 69).

    @status:probed
    @task:oah-census
    @provider:ask-model
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: The correction changes exactly what it lists
      Given the correction pass returns a patch: areas to add or replace, and areas to remove
      When OV3 applies the patch
      Then the census changes by exactly those areas and keeps every other area as it was
      # A correction asked to return the whole census returned it unchanged (741e3b44), so it returns a patch and a SQL step
      # applies it. Self-test e7694567: remove, replace and add.

    @status:probed
    @task:oah-census
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: The first round that passes is kept
      Given two correction rounds have run
      When OV3 selects the census to keep
      Then it keeps the first round whose census passed both checks
      And a census that passed is never lost to the second judgment
      # Flight path: round one passed and was kept (636b186c). Format-labels: round one reached 67 of 69 (61408844), round two
      # 69 of 69 (92d35a18) and was kept (23d8c2d7). Selector self-test 13ad6f23.

    @status:ready-not-run
    @task:oah-census
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: A census that still fails is neither kept nor delivered
      Given neither correction round passed both checks
      When the flight reaches step select-census
      Then the flight stops there, with the last round's feedback in the step result
      And nothing is retained as capability-census:ov3-complete-agentic-harness
      And no census.md is delivered

    @status:ready-not-run
    @task:oah-census
    @provider:apply-declared-change
    @provider:author-workspace-file
    @flight:ov3-harness-census-2
    Scenario: A passing census is kept and delivered with no step for the owner
      Given a correction round passed both checks
      And every model call honored its provider binding
      When the flight finishes
      Then the census it kept is retained as capability-census:ov3-complete-agentic-harness
      And docs/projects/ov3-complete-agentic-harness/census.md is delivered, with each obligation's fulfilling areas and the check's reason
      And the flight closes with PROMISE_CLOSED
      # census.md reaches the owner's machine once a worker router is running.

  Rule: Every provider-dependent step names its provider binding and proves it

    @status:probed
    @provider:ask-model
    @task:oah-provider-bindings
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: Each census model call honors the declared model selection, proved by its receipt
      Given the census model calls depend on these provider bindings:
        | calls                                       | provider capability OV3 needs                                         | result it must produce here                 | run evidence that proves it         |
        | write-census                                | ask-model, with MODEL_SELECTION ov3-harness-census-write, else default   | one census that satisfies the census schema | the receipt's modelProviderId, model |
        | judge-written, judge-corrected, judge-again | ask-model, with MODEL_SELECTION ov3-harness-census-judge, else default   | one verdict per obligation                  | the receipt's modelProviderId, model |
        | correct-census, correct-again               | ask-model, with MODEL_SELECTION ov3-harness-census-correct, else default | one patch that satisfies the patch schema   | the receipt's modelProviderId, model |
      When census-2 makes its six model calls
      Then each call produces the result its binding requires
      And verify-model-binding finds that each receipt names the bound provider and that provider's model
      And the status is BINDING_HONORED before anything is retained
      # The selections are rows of sidefx:model-providers, resolved as ask-model resolves them. No role has its own selection,
      # so each call uses MODEL_SELECTION default. Probe 901e22cb: six of six on deepseek/deepseek-flash, model deepseek-flash.

    @status:probed
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: A receipt from a provider that is not bound stops the flight
      Given the binding for a model call is deepseek/deepseek-flash
      And the call's receipt names another provider, such as google/gemini-flash
      When OV3 verifies the binding
      Then the status is BINDING_VIOLATED, and the evidence names the call
      And nothing is retained or delivered
      # Self-test 128fabdc: a receipt naming a provider nobody selected is BINDING_VIOLATED; one naming the selection is
      # BINDING_HONORED (ce9920d3). SQL 06 runs both.

    @status:ready-not-run
    @provider:ask-model
    @flight:ov3-harness-census-2
    @provider:sql-database-reader
    Scenario: A deliberate model change goes through the binding, not the plan
      Given the owner changes MODEL_SELECTION default to another declared provider
      When census-2 runs
      Then every model call resolves the new provider
      And verify-model-binding expects the new provider, with no change to the plan

    @status:planned
    @task:oah-provider-bindings
    @provider:design-feature-gherkin
    Scenario: OV3's own features carry their provider bindings
      Given a canonical feature whose scenario depends on a provider
      When OV3 writes the feature
      Then each required provider appears once on the scenario as @provider:<exact estate capability id>
      And the scenario specifies the expected call, the result it must produce and how to locate that call in run evidence
      And acceptance fails if the set of provider tags omits a required binding or adds an unbound provider
      And a provider OV3 only expects stays a candidate until OV3 verifies it

  Rule: Each provider tag must agree with the accepted estate binding and the actual invocation

    @status:probed
    @provider:sql-database-reader
    Scenario: Provider identities resolve exactly in the current estate
      Given the provider IDs extracted from the scenario tags
      When sql-database-reader looks them up in sidefx:capabilities of the current estate model
      Then each ID resolves case for case to exactly one declared capability
      And neither Ask-Model nor ask_model resolves as ask-model
      # Estate read 6dfeb935, with both negative controls.

    @status:probed
    @provider:ask-model
    @provider:sql-database-reader
    @flight:ov3-harness-census
    Scenario: The first census ran the providers bound to its write and check steps
      Given the estate plan for claude-code-opus-5-5-ov3-harness-census at revision 1
      And its digest is 698d488c222fd96af1d710c870e8145696b3a79f423eaace1731e9732ef72006
      And these provider graph digests were captured in the probes before the flight
        | step         | provider tag                  | canonical graph digest                                                  |
        | write-census | @provider:ask-model           | sha256:f6563ca4e5e09732a861f0743c092e8023df1cf31c57cc6144deb226d60e8751 |
        | check-census | @provider:sql-database-reader | sha256:dbb29dc8172312c3546bb706e32b30c32b59cb1ecad3b4dfff7e35826f6f0596 |
      When acceptance reads run bee2eee7-755d-c85f-2a1c-9b5506272cf7 of that exact plan
      Then both step bindings in the estate plan match their provider tags
      And each first attempt has its own dispatch, matching captured graph digest and returned outcome
      And write-census returned MODEL_RESPONSE_OBTAINED with the census text
      And check-census checked that text and returned CENSUS_READY
      # Baseline runs d69020ed and 12b42cd6. read-spec used the same SQL reader earlier in this flight;
      # its READ outcome cannot satisfy check-census.

    @status:not-built
    @provider:ask-model
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: The census write and its check prove their own provider calls
      Given the accepted revision and digest of the estate plan for this scenario
      And the accepted canonical graph digest for each bound provider was recorded before the run
      When acceptance reads the retained run of that plan and the evidence for these steps
        | step          | provider tag                  | required result                                      |
        | write-census  | @provider:ask-model           | MODEL_RESPONSE_OBTAINED with the census in the reply |
        | check-written | @provider:sql-database-reader | the ID check ran on that census and returned feedback |
      Then each step's declared provider ID in the estate plan equals its tag's exact ID
      And each actual call is attributed to that step and attempt within the same run
      And its captured provider graph has the accepted digest
      And its invocation returned the required result for that step
      # Use the nested invocation, graph capture and returned outcome from the same execution, or the corresponding
      # admission, graph capture and returned outcome for a direct call. A graph capture alone proves no result.
      # The model-selection receipt is an additional check wherever the scenario requires a particular model.

    @status:not-built
    Scenario Outline: Provider acceptance fails when the evidence cannot prove a required call
      Given an accepted scenario binding for @provider:ask-model on step write-census
      When acceptance checks a run with <defect>
      Then provider acceptance fails for write-census and identifies the missing or conflicting evidence

      Examples:
        | defect                                                           |
        | a required provider named only by a capability tag                |
        | a provider tag differing only in case                             |
        | a tag for a capability absent from the accepted step binding      |
        | a different plan revision or digest                              |
        | a different provider graph digest from the accepted pin           |
        | a substituted provider returning a plausible census               |
        | only a captured graph and no invocation outcome                   |
        | the right provider invoked only in another run, step or attempt   |
        | a returned outcome that does not satisfy the step                 |
        | an evidence gap that prevents attribution of the required call    |

    @status:probed
    @provider:ask-model
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: A required model is checked on the invocation receipt
      Given a scenario tagged @provider:ask-model that requires the DeepSeek binding
      When OV3 checks acceptance
      Then the receipt's provider and model must equal the MODEL_SELECTION the call resolves
      And this check stands apart from the graph digest, because the selection is a row the call reads when it runs
      # verify_model_binding, probe 901e22cb.

  Rule: The owner's directions are rows OV3 reads, and OV3 records nothing in the owner's name

    @status:ready-not-run
    @task:oah-census
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: Each quoted line of the owner's direction is one obligation
      Given owner-direction:ov3-complete-agentic-harness revision 2 holds 17 quoted lines
      When OV3 reads the census sources
      Then they hold owner:1 to owner:17, each with the owner's words verbatim
      # SQL 06 adds revision 2 (sha256:f700c5c7...), with the provider-binding direction as lines 15 to 17; its self-test
      # reads the 17 lines back.

    @status:ready-not-run
    @task:oah-supersede-minimal-loop
    @provider:sql-database-reader
    @flight:ov3-harness-census-2
    Scenario: The minimal-loop stance no longer governs OV3's design
      Given docs/projects/objective-agent-loop.md section 2 says there is "no need for elaborate planning algorithms, self-improvement policies, multi-agent consensus, or additional control-plane primitives"
      And owner-direction revision 2 supersedes that stance
      When OV3 checks a census
      Then a census with no area for elaborate planning, self-improvement, multi-agent consensus or control plane is CENSUS_INVALID

    @status:ready-not-run
    @task:oah-census
    @provider:apply-declared-change
    @flight:ov3-harness-census-2
    Scenario: The earlier census flight is superseded under OV3's own authority
      Given flight ov3-harness-census waits at decision point ov3-complete-agentic-harness/census
      When flight ov3-harness-census-2 runs
      Then its tracker step records flight ov3-harness-census as superseded by it, under OV3's own authority
      And the decision point stays unanswered, with no owner decision recorded
      And no step of census-2 waits for the owner
      # The owner's review: the first census-2 plan recorded "revise" in the owner's name, a decision the owner did not make.
      # That step and its promise obligation are gone.

  Rule: The owner's SQL is safe to run again

    @status:ready-not-run
    Scenario: Running SQL 06 again changes nothing
      Given SQL 06 has run once
      When the owner runs it again
      Then each census procedure's definition digest matches, and it is applied again unchanged
      And the content writer adds no row for a digest and kind it already holds

    @status:ready-not-run
    Scenario: SQL 06 stops before writing when a procedure holds another definition
      Given a census procedure already exists with a different definition digest
      When the owner runs SQL 06
      Then it reports that procedure as DIFFERENT and stops with OV3_HARNESS_06_BASE_DIFFERS
      And nothing is written
      # The owner's review found the old guard failing on rerun: CHARINDEX was given an 8,407-character body and SQL Server
      # returned "String or binary data would be truncated" (run 82dcbff1). The guard now compares SHA-256 digests; SQL Server
      # computes the same digest as the generator for all six definitions (probe 3d747335).

  Rule: A step's result reaches the next step whole

    @status:proven
    @task:oah-long-bind
    @capability:fly-flight-plan
    @provider:sql-database-reader
    @flight:ov3-harness-long-bind
    Scenario: A value over 4,000 characters binds whole
      Given a flight step whose result holds a 6,000-character string
      When a later step binds that string
      Then the later step receives all 6,000 characters
      # Before the fix, JSON_VALUE read any string over 4,000 characters as NULL and the step failed BINDING_UNRESOLVED.
      # Proven by flight ov3-harness-long-bind (plan cfc1fcf0...): PROMISE_CLOSED, closure read b628d159.

    @status:proven
    @task:oah-long-bind
    @capability:fly-flight-plan
    @provider:sql-database-reader
    @flight:ov3-harness-long-bind
    Scenario: A short value binds as it did before
      Given a flight step whose result holds a short string
      When a later step binds that string
      Then the later step receives it unchanged

  Rule: A message with more than one request never loses one

    @status:not-built
    @capability:request-capability-from-objective-v3
    @task:oah-finding-compound-objectives
    @provider:approve-flight-plan
    @provider:fly-flight-plan
    Scenario: "Approve and fly" in one message is not cut down to "fly"
      Given the owner sends one message asking OV3 to approve a plan digest and fly that plan
      And the named digest is current and eligible for approval and flight
      When OV3 routes the message
      Then the run records approve-flight-plan for that digest followed by fly-flight-plan for the approved plan
      And an omitted call fails this scenario even if the reply names it
      # Finding: run f9b4ec49 sent the message straight to fly-flight-plan. The approval was dropped, and the flight came back
      # NOT_CLEARED, 0 of 4 steps (recording 521c95ea). Until this is built, send each request as its own sentence.

    @status:not-built
    @capability:request-capability-from-objective-v3
    @provider:approve-flight-plan
    @task:oah-finding-compound-objectives
    Scenario: A refused approval accounts for the unflown plan
      Given the owner asks OV3 to approve a digest and fly its plan in one message
      When the approval call refuses the stale digest and the current plan has no clearance
      Then the reply identifies the refused approval and explains why the flight did not run
      And the retained run contains the refusal and no flight invocation

  Rule: OV3 writes its own features, then plans and builds from them

    @status:planned
    @task:oah-features
    @provider:design-feature-gherkin
    @provider:apply-declared-change
    @provider:author-workspace-file
    Scenario: OV3 writes one canonical feature per census area
      Given the checked census capability-census:ov3-complete-agentic-harness
      When OV3 writes its harness features
      Then each census area has one feature, checked, retained as harness-feature:<capabilityId> and delivered
      And no step asks the owner to approve or decide

    @status:planned
    @task:oah-build
    @task:oah-canonical-binding
    @provider:analysis-read-selected-definition
    @provider:read-flight-closure
    Scenario: Every build names the feature it implements
      # The build writer is unresolved in the tracker. Bind and tag its exact provider before executing this planned case.
      Given a build task in project ov3-complete-agentic-harness
      When OV3 builds the capability
      Then the task names the harness feature the capability implements
      And analysis-read-selected-definition reads that feature back from sidefx:features for the built capability
      And read-flight-closure returns PROMISE_CLOSED for the build flight that implemented it

    @status:planned
    @task:oah-census-capability
    @provider:ask-model
    @provider:sql-database-reader
    Scenario: The census becomes a capability any specification can use
      Given flight ov3-harness-census-2 has closed with PROMISE_CLOSED
      When its steps are declared as a capability
      Then any retained specification can be turned into a census checked against every recorded obligation
      And one run of that capability closes with PROMISE_CLOSED

# Open questions for the team. Each is a place where the record is unclear or pulls two ways.
#
# Q1. Which decisions does the owner reserve? The tracker's law makes two owner acts that are never inferred: approving a
#     project's plan and approving its completion. Is there anything else?
# Q2. Does giving OV3 an objective count as approving the project's plan? The same law says a project executes only after
#     its plan is approved. Census-2 neither sets nor checks that approval.
# Q3. Every tracker project counts as an obligation (39 of the 69), whatever its status. Should completed or superseded
#     projects count?
# Q4. Census-2 corrects in up to two rounds. The flight path passed in round one in each final probe; the format-labels case
#     needed round two. Is two enough, or should OV3 keep correcting until it passes or reaches a limit?
# Q5. The writer aims for 30 areas, and the id check now allows up to 60. Earlier probes needed 37 to 45 areas to fulfill
#     every obligation; the final probes landed on 30. Keep 60 as the ceiling?
# Q6. Once the team agrees this file, should it be retained in the estate so that OV3's own features (task oah-features)
#     must satisfy it?
