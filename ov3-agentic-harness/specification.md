# Specification: OV3 as a complete agentic harness

Retained as specification:ov3-complete-agentic-harness. Assembled 2026-11-02 by the Frontier planner claude-code-opus-5-5 as a bootstrap: every section is the owner's words verbatim, a projection of estate rows, or an observation with its run id. Nothing here is a design. The design is what OV3 writes from this specification.

## 1. The request (the owner, 2026-11-02)

> Whatever needs to be done in SQL, you'll need to generate a .sql file and I'll run it. Ultimately, we're transferring agency to OV3.
> - the owner, 2026-11-02

> Is this something that typesafe-model-one can address as it relates to this fuzziness? We want deterministic multi-step task execution through OV3. We don't want fuzziness or bespokeness for one specific line of work. OV3 needs to become a real agentic harness. Therefore, the way we address this issue needs to be durable.
> - the owner, 2026-11-02

> Yes, this is the ultimate problem: "The objective-loop design rules out elaborate planning, self-improvement, multi-agent consensus, and extra control-plane pieces". This totally goes against what I've asked for. You can see the project tracker history and flights that we've flown to transfer agency. Here's the problem: - The canonical features (gherkin) were never written up and stored durabily in the estate and therefore the wrong design above was implemented. We need to get the OV3 network to write up it's own features to be a complete agentic harness, which includes (but not limited to): elaborate planning, self-improvement, multi-agent consensus, and extra control-plane pieces. Then we will have OV3 build it's own future state. That's the way to go.
> - the owner, 2026-11-02

What OV3 writes from this specification:

- The scope of OV3 as a complete agentic harness. It includes, and is not limited to, elaborate planning, self-improvement, multi-agent consensus and extra control-plane pieces, with deterministic multi-step task execution and no fuzziness or bespokeness for one line of work. The scope names each capability area with a proposed capability id, because the estate holds exactly one canonical feature per capability (model.declare_capability_feature; namespace sidefx:features).
- Then one canonical @-annotated Gherkin feature per accepted capability area: the authority OV3 then builds its own future state from.

## 2. The owner's directions already on record

> Capabilities are created in the database. And the first thing we need to establish when creating capabilities is what providers are needed for that capability. And then those providers also become capabilities that are bound as providers to the root scenario capabilities.
> - the owner, 2026-10-25 (docs/projects/OV3 Software Engineering Harness.md)

> We don't want any bespoke implementation in OV3. That should be purely driven by investigation of what providers are needed in order for that capability to achieve its effects and outcomes.
> - the owner, 2026-10-25 (docs/projects/OV3 Software Engineering Harness.md)

> The workers are going to be necessary for delivering the Markdown to the local machine of the user ... but also delivering any test harnesses that they need, such as HTML.
> - the owner, 2026-10-25 (docs/projects/OV3 Software Engineering Harness.md)

> The OV3 network needs to be able to also look up open source providers on the internet to propose/suggest leverage (e.g, https://landscape.cncf.io/, github, hugging-face, etc.).
> - the owner, 2026-10-25 (docs/projects/OV3 Software Engineering Harness.md)

> The cncf and github is powerful because direct integration is discoverable!
> - the owner, 2026-10-25 (docs/projects/OV3 Software Engineering Harness.md)

> All of these decisions will be decided in intentional workflows.
> - the owner, 2026-10-25 (docs/projects/Provider Capability Registry.md)

> when I tell you to do something I am giving you authority. I am the owner of this product and the purchaser and owner of this subscription. Do not ever "give" me friction. Friction is not what we're building in the process here.
> - the owner, 2026-10-23 (docs/projects/Transfer of Agency/flight-process.md)

The recorded north star (AGENTS.md of sfx-embody): Governed Recursive Capability Improvement - the system uses evidence from its own execution to propose, prove and admit improvements, while independent authority still decides what becomes durable.

## 3. Superseded stance

docs/projects/objective-agent-loop.md, section 2, says: "There's no need for elaborate planning algorithms, self-improvement policies, multi-agent consensus, or additional control-plane primitives." The owner's direction of 2026-11-02 supersedes it. It was never written as canonical features, so it became the implemented design by default.

## 4. OV3 as declared today (rows read 2026-11-02)

- request-capability-from-objective-v5, intent: Act on a person's natural-language objective the way an agent does: recall what the estate remembers for them, then turn by turn let the model look up, verify and act through one declared MCP capability at a time, read each actual result before the next action, and correct its input when a call is refused or finds nothing, until it answers the person with what it did and found; then remember what it learned and retain the conversation, every turn with its result
- outcome: objective-pursuit.v1 with the reply to the person, the last call in the objective-capability-result fields (capabilityId, childStatus, childDisposition, invocationResult, summary), every turn with its actual result status, what was remembered and the retained conversation
- scenario request-capability-from-objective-v5: given a person's objective, or the carrier of the previous turn; when the model is asked for the next action with every earlier turn's actual result, the action it chooses is taken, and the turn is retained with its result; then the carrier with route CONTINUE for the next turn, or STOP once the person is answered
- scenario request-capability-from-objective-v5-finish: given the last turn of the conversation; when what the model learned is remembered for the person and the conversation is retained; then the reply to the person with the last call and every turn
- Canonical features (sidefx:features), each with exactly one scenario:
  - request-capability-from-objective-v3: definition 9179b40f2e753d50..., scenarios request-capability-from-objective-v3
  - request-capability-from-objective-v5: definition ec5b0b169908a222..., scenarios request-capability-from-objective-v5
  - objective-agent-loop: definition 8e2baa8532dd64c3..., scenarios objective-agent-loop
- Routing before the turn loop (omc-typesafe-intent-routing, statement 03-decide-intent): TypeSafe System One answers typed questions (noul, choice, score; one label or number each, no extraction). When it chooses fly-flight-plan with confidence >= 0.9 and the objective names an agent, OV3 calls fly-flight-plan with no model turn.

Observed 2026-11-02 (run ids are retained online):

- "Approve and fly the current flight plan of agent ..." was routed to fly-flight-plan alone (run f9b4ec49, routedBy system-one, 0 turns; recording 521c95ea NOT_CLEARED). The approval was dropped silently.
- A flight step binds an earlier step's result with JSON_VALUE (analysis.fly_flight_step_cell), so a value longer than 4,000 characters cannot be bound (BINDING_UNRESOLVED); OV3 cannot carry a document it wrote to the next step. A repair is part of this project (oah-long-bind).
- The DSL specification (capability-dsl-specification.v1, 19 constructs) lags the compiler, which also accepts inquiry, route, broadcast, join and recur (run 916ade66); route, broadcast and join compile without semanticProgress.
- Skills are versioned rows, but no run-time path of OV3, the planner, the reviewer or the flight engine reads a skill; skill content reaches a model only through read-specialist-context, called by coordinate-project-task.
- read-agent-specializations reports a skill RETAINED with missing false when its content is empty (graph-topology-emission revision 1; runs 72fa3884, 59b2f4e1).

## 5. Laws the estate already holds (AGENTS.md and the flight process)

- Meaning is authored in the database through declared writers; no capability meaning lives in local executable code.
- A capability is authored through the declared pipeline (DSL, compile, declared change, readback, first call); providers first.
- Every flight: a planner records a plan with a historical basis per step; a deterministic review; a report; the owner approves the exact plan digest; OV3 flies; closure only on PROMISE_CLOSED with a recording.
- Owner acts (approval, decisions, plan and completion approval of projects) are recorded with the owner's own words; they are never inferred.
- The live database is the source of truth; a claim not visible in rows is not evidence; fixtures are never observations.

## 6. The recorded work: every project in the tracker (read-project-tracker, run d075c4c7, 38 projects, 502 tasks)

### agent-capability-network (ACTIVE; 23 of 23 tasks done; actor SFX Objective Agent)

- Goal: Make the capability network the objective agent navigates explicit, complete and self-extending: every MCP tool reachable from plain language, required edges receipt-backed, continuation between nodes declared, and growth exercised through the declared pipeline.
- Agent user story: As the SFX Objective Agent, I need a declared network view of every capability I can reach - its routing questions, inquiry examples, contracts, failure reports and edges - so that I can verify my own coverage, navigate from any goal to the right capability (and onward when an outcome requires a next step), and extend the network through the governed pipeline without owner intervention. As a deployed specialist I need my responsibility, skills, context, eligible capabilities, model role and evidence declared and inspectable; my delegations must carry lineage and contract-specific evidence; and my results must resolve project task dispositions through the Workbench - never merging proposals, effects, evaluation, acceptance and status into one claim.
- Acceptance: The census read reports every MCP tool with its edges and counts; required routing questions are receipt-backed and assess VERIFIED; at least one continuation edge is demonstrated with retained runs; a new capability joins the network through the declared pipeline and appears in the census; and one complete live specialist workflow is proven (an objective selects one specialist, invokes existing capabilities, returns evidence, and resolves task disposition) with an evaluated skill revision admitted separately - each with the refusal states named in the plan (no eligible specialist, denied authority, stale revision, missing child return, unavailable evidence, failed evaluation).
- Benefit: Coverage of what the estate can do becomes censusable, verifiable and repairable through declared reads and writers, retiring operator-held knowledge of the network.

### api-only-cutover (ACTIVE; 1 of 9 tasks done; actor SFX Platform Team)

- Goal: Transfer engineering execution and work coordination from external frontier coding agents and local development tools to the SideFX native agent harness; at cutover the external agent's sole engineering doorway is the SideFX API, and the human interacts directly with the Objective Agent through the Workbench
- Agent user story: As the SFX Objective Agent, I route human work descriptions to the appropriate project, task or specialist destination without performing domain engineering. As an SFX Engineering Specialist, I inspect, author, transform, probe, install and verify through native estate capabilities. As the SFX Execution Observer/Evaluator, I relate delegated operations, nested runs, observed effects and verification results to the originating objective and project task so completion is established from actual evidence.
- Acceptance: 1) An external agent under actual API-only restrictions completes a representative new engineering task using native capabilities; 2) direct engineering-tool bypass is unavailable to it; 3) the Objective Agent routes rather than engineers; 4) specialized agents perform and coordinate the work with relevant skill revisions and eligible capabilities; 5) source changes, probes, results and dispositions are reproducible from retained estate artifacts; 6) the owner demonstrates direct objective submission and live inspection through the Workbench; 7) any remaining unsupported workflows are identified explicitly. Owner approval and completion remain separate from automated success.
- Benefit: Engineering sovereignty, reduced frontier-agent dependency, durable engineering knowledge, lower repeated engineering cost, agent-network scalability and observable improvement - frontier models remain available for inference while the capability estate owns execution and retained knowledge

### capability-dsl (ACTIVE; 22 of 26 tasks done; actor SFX Objective Agent)

- Goal: Creating a governed SFX capability is inexpensive: concise DSL text compiles through the existing authoring pipeline into contracts, execution operations and provider bindings, deployed as a governed circuit that is formally verifiable in the Workbench and in a generated slide deck from the same retained evidence.
- Agent user story: As the SFX Objective Agent, I need to author capabilities from concise DSL text through declared writers, so that new capability circuits enter the estate governed, verified and reviewable without hand-written document JSON.
- Acceptance: One new capability is authored entirely from DSL text end to end - pipeline receipt, live invocation, circuit rendered in the Workbench with verified verdicts, and a generated slide deck - with zero hand-written document JSON anywhere in the path; five or more existing capabilities round-trip with zero unexplained drift.
- Benefit: Capability creation stops being a document-assembly exercise; the cheap path is the governed path, and verification surfaces are projections of one evidence set instead of parallel claims.

### capability-readiness-report (ACTIVE; 0 of 8 tasks done; actor SFX Capability Maintenance Agent)

- Goal: Make capability readiness executable: prove that a capability can achieve its declared outcomes using the declared input, provider, intermediate and output shapes before authoring, admission or publication, and make unknown or unsupported effects red rather than silent.
- Agent user story: As an SFX Capability Readiness Evaluator, I can execute declared capability scenarios against provider fixtures, observe typed evidence and virtual post-state, and receive READY/NOT_READY/UNKNOWN findings, so no capability is admitted or published without demonstrating its declared outcome.
- Acceptance: A declared readiness report covers input, provider input/output, intermediate shapes, effect behavior, outcome evidence shape and outcome fulfillment; unknown and unsupported are red; a write procedure expected virtual post-state is demonstrated; the promotion/authoring generator stops before authoring on unsupported nested effects and creates no partial capability; a partial candidate is distinguishable from an admitted capability; one READY and one NOT_READY case are retained with evidence; fixture proof and live integration proof remain distinct; no new testing architecture is introduced.
- Benefit: The Frontier can know before execution what a capability is ready to achieve, which scenarios prove it, and which outcomes remain unverified. Failed authoring attempts stop before partial capabilities are published.

### capability-workflow-runway (ACTIVE; 7 of 7 tasks done; actor claude-code-opus-5-5)

- Goal: Workflows are capabilities: a long-running flight is a resumable run of a declared workflow capability, its units of work are assigned to generic workers by run, scenario and operation, and identity records reference estate capabilities canonically with their resolved digests.
- Agent user story: As the owner, I want a durable workflow capability with resumable runs and generic workers, so that long flights continue from retained state under current authority without the planner reconstructing them.
- Acceptance: An identity record naming a capability carries its resolved digest; a flight runs a workflow capability and records its position; an interrupted run resumes at the first unfinished stage without repeating a side effect and stops if its authority was revoked; a unit of work names its workflow, run, scenario, operation, worker and authority; provider-registry-intake runs as the first workflow.
- Benefit: Long flights resume from retained state instead of a frontier model reconstructing the plan; definition, run and assignment stay distinct; the Provider Capability Registry runs on it as its first workflow.

### contract-driven-provider-virtualization (ACTIVE; 1 of 8 tasks done; actor SFX Capability Maintenance Agent)

- Goal: Build one reusable, contract-driven provider virtualization mechanic: execute the same declared scenario circuits against governed fixture providers, validate contract references and effects, and independently evaluate whether the declared outcome was achieved.
- Agent user story: As an SFX Capability Readiness Evaluator, I can bind a governed fixture provider to a declared capability port, run the unchanged scenario circuit with a selected fixture case, and receive provider testimony plus an independent outcome evaluation, so capability readiness is proven without per-capability test code.
- Acceptance: One generic contract-aware fixture provider runs unchanged equity-v2 against valid and failing fixture cases; provider testimony is retained; fixture SUCCESS is not treated as capability outcome fulfillment; a write-effect capability demonstrates the expected virtualized post-state and refusal; no per-capability test runner or duplicate conformance engine is introduced; findings are specific rather than generic UNKNOWN.
- Benefit: Replace per-capability test runners with declared Gherkin, contracts and reusable fixtures. The estimator can derive required tests, execute them against interchangeable providers and retain evidence in the estate.

### declared-api-estate-execution (ACTIVE; 4 of 8 tasks done; actor sfx-api agent)

- Goal: Estate opens on the declared API: the signed-in principal's estate scopes, a bounded retained snapshot and a live cross-run feed, served through serve-api-request without the client creating runs.
- Agent user story: As the sfx-api agent, I declare the estate scope read, the snapshot and the live feed in sfx-api, add only connection-holding and fan-in transport to host/serve.py, deploy sfx-api-test and hand platform the paths, contracts and resume rules to bind, so a signed-in Estate pane shows runs started from other clients without being given their IDs.
- Acceptance: On the staging web hostname, signed in: opening Estate, refreshing it or selecting a retained interval makes no POST /sfx/v1/runs, no reader-run polling and no new entry in the user's run history; a run started from another client appears on Live without its ID being entered; a feed resumed with since or Last-Event-ID continues without loss, or reports the gap or restart; the feed ends when the session ends; the feed's record shape, frames and visibility come from declared capabilities, not serve.py; the owner verifies the result.
- Benefit: The Estate pane works on staging through sfx-api-test, and the platform can drop the legacy estate host (estate-host.mjs, estate-reader-service.mjs) and the observer feed (/events in observe-server.mjs). What the feed carries and who may see it become rows instead of host code.

### declared-api-frontdoor (ACTIVE; 2 of 15 tasks done; actor none)

- Goal: The API is declared to the profile schema boundary and hosted only by the frontdoor, so the runtime is deterministic and governed by the transistor model.
- Acceptance: Staging serves every API operation through the frontdoor; each operation is a declared capability or declared read; delivery and language selection are read from rows; services/sda-api and the sfx-platform modules that carried API meaning are deleted; the frontdoor passes three-language conformance (C#, Node, Python).
- Benefit: Delivery, routing, admission, capture and run policy become rows that can be read, changed and verified as data. The host carries no meaning, so the failures seen on staging on 2026-10-29 have no code to live in.

### equity-v2-catalog (ACTIVE; 4 of 4 tasks done; actor SFX Capability Maintenance Agent)

- Goal: Bind the RapidAPI providers on resolve-equity-market-price-evidence-v2 and replace v1 in the MCP catalog.
- Agent user story: As the SFX Capability Maintenance Agent, I need to maintain the declared RapidAPI provider bindings for resolve-equity-market-price-evidence-v2, verify that its operation identities correspond to the admitted execution graph, and update the MCP tooling catalog to select v2 instead of v1, so that future equity-price objectives resolve to the maintained capability without requiring manual catalog intervention.
- Acceptance: The catalog resolves to v2, its provider bindings are valid, and the capability's invocation and resulting evidence can be verified through the scenario circuit.
- Benefit: The MCP market-price tool serves the v2 generation with provider authority and graph-aligned operation identities.

### error-classification-registry-and-reporting (SUPERSEDED; 0 of 8 tasks done; actor SFX Capability Maintenance Agent)

- Goal: Make every stored procedure participating in capability authoring, execution, conformance and readiness reveal failures through the classified occurrence and its actual evidence, with no synthetic resolution and no competing registry.
- Agent user story: As an SFX Capability Maintenance Agent, I can query one retained occurrence with its primary class, phase, cause, evidence and disposition, and see the conformance and readiness projections relate to that same occurrence, so a failure cannot be hidden, misclassified or cleared by synthetic evidence.
- Acceptance: The registry authority is queryable; one classified occurrence projection relates execution, conformance and readiness; unsupported result shape is refused as AUTHORING before partial promotion; the retained promotion runtime failure is EXECUTION with AUTHORING cause; dimension 36 and OPERATION_EXECUTION NOT_READY are exposed; synthetic evidence cannot resolve; equity-v2 missing evidence is EVIDENCE and outcome fulfillment remains NOT_TESTED; real corrected execution is required before resolution.
- Benefit: Operators and native agents can query what failed, why, where, which outcome was affected, and whether readiness was subsequently demonstrated, without reverse-engineering SQL errors or trusting a projection that disagrees with the occurrence.

### estate-error-to-capability-closure (ACTIVE; 0 of 8 tasks done; actor SFX Capability Maintenance Agent)

- Goal: Create one repeatable, human-supervised engineering circuit: actual defect -> classified occurrence -> installed SQL detection/report or committed SQL evidence query -> owner-reproduced failure -> generic governed repair -> owner-executed repair -> same detection re-run and actual outcome verified -> safely promoted MCP repair capability.
- Agent user story: As an SFX Capability Maintenance Agent, I can take one actual defect through the eight-stage circuit using existing SQL authorities and owner-run evidence, so the estate gains a durable reusable repair capability instead of a case-specific patch.
- Acceptance: All eight accountable task outcomes are evidenced by owner-run SQL and scope-appropriate execution; all 11 registry classes have traceable SQL reporting/detection routes without fabricated occurrences; every task has its approved exact skill revision registered, readable with content digest and evidence query, and pinned through model.project_task_skills; no task is operationally ready with a missing or inaccessible skill revision; one real pilot has pre-repair classified detection, owner acceptance, generic repair with safe refusal, owner-executed correction, same-detector and underlying-state verification, real fixture/live outcome proof, correctly authorized MCP invocation and explicit owner acceptance; further error families are ordinary cases, not task expansion.
- Benefit: Failures become queryable classified facts and generic fixes become verified reusable capabilities, with owner-controlled detection, repair and publication gates rather than model narrative or synthetic proof.

### estate-execution-topology (ACTIVE; 11 of 13 tasks done; actor SFX Objective Agent)

- Goal: The estate declares the meaning and readers behind the Estate Execution Topology experience: the topology, activity, provenance, detail, coverage and invocation contracts exist as declared reads with named states, distinct execution-instance counting, revision basis and temporal honesty; the seven design acceptance items run as estate conformance, and live user-observed acceptance is tracked as a separate platform-owned gate.
- Agent user story: As the SFX Objective Agent, I need the estate to expose topology, activity, provenance, evidence, coverage and invocation semantics as declared reads with honest named states, so the execution topology experience can be built and accepted on captured testimony alone.
- Acceptance: The six service contract requirements of the design are declared estate reads with their named states and invariants enforced; distinct-instance counting and temporal honesty are demonstrated; the seven acceptance items pass as estate conformance with retained runs; the platform-owned integration gate is observed live.
- Benefit: The topology UI stands on declared estate semantics instead of a bounded local contract: illumination follows captured testimony, counts are instances, parentage is evidence, correlation is not causation, and playback cannot show the future.

### estate-live-observation (ACTIVE; 3 of 11 tasks done; actor sfx-api agent)

- Goal: Every capability execution in the estate is observable live from any machine, as the legacy observer's publish/subscribe channel was, served through declared capabilities with the hosting facade as transport only.
- Agent user story: As the sfx-api agent, I build the approved features one slice at a time, in the owner's priority order, through publish-, select- and subscribe-estate-live-observation, capture-estate-live-observation-facts and check-api-session, adding only transport to host/serve.py.
- Acceptance: The scenarios of features/estate-live-observation.feature and features/estate-live-observation-declared.feature (sfx-api, approved by the owner 2026-11-01) pass on sfx-api-test, and the legacy subscribers' own code accepts the records.
- Benefit: Restores what the cutover lost: the machine watchers and routers (workspace files, agent memory, worker routing), the Explorer's live circuit and the Fractal Lab bridge subscribe again, and Retained shows the runs sfx-api executes. The meaning leaves host/serve.py.

### estate-native-agent-engineering (ACTIVE; 12 of 19 tasks done; actor SFX Capability Maintenance Agent)

- Goal: Enable SFX agents to inspect, author, transform, validate, install, verify, and improve the capability estate entirely through governed capabilities, without depending on scratch folders, temporary scripts, or manually reconstructed execution artifacts
- Agent user story: As an SFX Engineering Specialist, I need to perform implementation changes using installed-source reads, content-addressed artifacts, declared transformations, governed writers, and retained execution evidence, so that I can improve the estate without reconstructing a temporary engineering environment for each task.
- Acceptance: An SFX specialist completes a real engineering repair entirely through estate-managed operations, with source revisions, test vectors, installed-state readback, execution evidence, and project disposition independently inspectable. The entire sequence is reproducible from estate-managed artifacts and references; no scratch scripts or folders are required for continuity.
- Benefit: Reduce agent execution costs, repeated inference, engineering detours, and dependence on external coding-agent workspaces; make engineering operations reproducible, observable, and reusable by subsequent specialist agents

### estate-native-agent-network (ACTIVE; 0 of 7 tasks done; actor SFX Capability Maintenance Agent)

- Goal: Make the SideFX harness the primary environment for general-purpose engineering work by teaching its specialized agents to discover, inspect, author, probe, repair, verify, and improve the capability estate using its own admitted capabilities
- Agent user story: As an SFX Engineering Specialist, I need to discover applicable estate capabilities, acquire relevant skill context, inspect existing implementations, perform governed changes, execute probes, and evaluate outcomes so that I can accomplish assigned engineering tasks without reconstructing external development environments.
- Acceptance: An unfamiliar but supported engineering task is performed through the native harness, without a frontier coding agent manually operating the repository or relying on scratch artifacts to maintain work continuity. The result and its evidence remain available to the next specialist invocation.
- Benefit: Reduce dependence on external frontier coding agents as engineering operators; establish durable, reusable engineering skills and workflows that allow SideFX to perform increasingly complex work through its native capability estate

### estate-purity-workflow (ACTIVE; 2 of 12 tasks done; actor none)

- Goal: Every capability in the estate runs each step on our own providers, re-declared by a workflow OV3 runs by name.
- Benefit: No capability depends on SDA engines (expression engine, SQL reader, Node dispatcher), and the transformation needs no frontier agent per capability.

### estate-semantic-conformance (ACTIVE; 0 of 24 tasks done; actor SFX Objective Agent)

- Goal: Establish and operationally demonstrate conformance rules across the capability estate, with each rule connected to its architectural source, lifecycle stage, enforcement mechanism and observed result.
- Agent user story: As an estate authoring or maintenance specialist, I need required meanings and relationships enforced at the appropriate boundaries so a conforming change succeeds and a nonconforming change reveals its exact violated rule; as coordinator, I need segment coverage connected to exact outcomes so partial changes cannot substitute for estate acceptance.
- Acceptance: 1. Every supplied table has an analysis owner and every in-scope relationship/boundary has an owner and disposition. 2. Each segment has a retained source-grounded assessment. 3. Cross-altitude contradictions resolved or explicitly open. 4. Required corrections and data reconciliation executed through the estate and verified. 5. Valid authoring/execution still works; selected nonconforming cases expose the actual rule. 6. Definitions, projections, writers, consumers and reporting agree on scoped rules. 7. Analysis, implementation, verification and owner acceptance remain distinct. 8. Deferred findings name scope and decision owner. 9. Owner can inspect full coverage and effects in the reporting surface. Standing execution contract: every request asynchronous and observable, with explicit async dispatch, addressable correlation, live observation while processing (terminal telemetry retained for fast executions), nested traceability, and independent evaluation against durable outcomes. No synchronous blocking, timeout-based async simulation, or multiple Frontier-operated calls substituting for native continuation.
- Benefit: Capability meanings and relationships are enforced at the appropriate authoring/execution boundaries instead of depending on model memory or prose.

### estate-simple-data-model (ACTIVE; 9 of 9 tasks done; actor SFX Objective Agent)

- Goal: Every simple question about projects, tasks, actors, skills, specializations, capabilities, verification or evidence is answered with plain relational joins: one fact stored once, one collation, no CTE/UNION/string parsing in retrieval - meaning is never hidden behind query complexity.
- Agent user story: As the SFX Objective Agent, I need the estate's relational surface to store each fact once and expose it through plain joins, so that retrieval never requires CTEs, unions, string parsing or collation casts to answer simple questions.
- Acceptance: The mechanical law scan finds no WITH/UNION/STRING_SPLIT/CHARINDEX on simple-retrieval paths of the redeclared reads; the sample-question inspect set answers every question with plain joins; string-FK and semantic-mirror parity invariants read zero drift through the soak; the duplicate string columns are absent from sys.columns after retirement with the desktop read-back green.
- Benefit: The project-management, verification, inspection, skills and agent-network surfaces become queryable with the simplicity of the owner's intended design; duplicates, parsers and casts are removed by transformation with parity evidence.

### estate-violation-ledger (ACTIVE; 4 of 7 tasks done; actor claude-code-opus-5-5)

- Goal: A durable violation ledger in memory (sfx-identity rows) projected into the repo, holding every violation of the profile schema boundary with its law, footprint, disposition, exit criteria, tracker task, status and evidence.
- Agent user story: As the owner, I want a durable violation ledger in memory and projected in the repo, so that every violation of the boundary is tracked to closure and nothing presents debt as the pattern.
- Acceptance: read-violation-ledger returns the seeded entries with counts; docs/violation-ledger.md lands through the worker after a ledger write and matches the rows; a closing write (id, status, evidence) revises one entry and the projection follows; agent memory and OV3 point at the ledger.
- Benefit: Debt and false narratives are recorded once, read by agents and OV3, and visible in the repo, so they cannot be forgotten or mistaken for law.

### financial-analysis-capability (COMPLETED; 13 of 13 tasks done; actor SFX Objective Agent)

- Goal: Analyze Financial Position computes valuation metrics, liquidity ratios, leverage ratios and scenario outcomes from fundamentals fetched live through the same governed provider stack as resolve-equity-market-price-evidence-v2 - no seeded data - with the declared execution graph and validation envelope, formally verifiable from retained evidence.
- Agent user story: As the SFX Objective Agent, I need to declare fundamentals endpoints, bindings, builders and a normalizer through the governed pipeline, so that analyze-financial-position computes from fetched evidence end to end.
- Acceptance: One live invocation for a real symbol returns VALIDATED financial analysis whose stage inputs trace to a retained provider payload (binding id, endpoint digest, native shape, fetch run), with the refusal path demonstrated; no seeded position data participates in the live path.
- Benefit: The estate demonstrates a real financial-analysis capability whose data arrives through declared credible providers; the DSL makes the graph cheap and the providers make the data real.

### iac-opentofu-terraform (ACTIVE; 1 of 6 tasks done; actor none)

- Goal: Customers describe the infrastructure they want; SideFX plans it through a Terraform-compatible provider, shows the plan before it applies, applies the admitted plan and retains the evidence.
- Agent user story: As the assigned agent (claude-code-opus-5-5, flight planner), I need the Terraform and OpenTofu registries discoverable through declared profiles, a declared provider that runs the tool operations init, plan, show and apply on the host behind the API, and capabilities whose outcomes are the plan summary and the apply result, so that I can plan flights that provision a declared environment and prove each step with a retained run.
- Benefit: Students and customers get a provisioned environment without becoming cloud engineers, and infrastructure becomes a provider-independent capability family in the registry (OpenTofu or Terraform).

### intelligence-publishing (ACTIVE; 1 of 13 tasks done; actor SFX Objective Agent)

- Goal: The estate declares the capability semantics for the Intelligence articles and publishing design: every one of the 33 proposed transports maps to a declared read or write with typed contracts, the shared write envelope and nine refusal outcomes are authority, the lifecycle and publishing-authority semantics are rows, and the acceptance workflow plus six adversarial cases run with retained evidence.
- Agent user story: As the SFX Objective Agent, I need the publishing transports to exist as declared estate capabilities with refusal contracts and lifecycle authority, so that the acceptance workflow runs through governed writes with receipts and public reads stay published-only and honest.
- Acceptance: Every transport maps to a declared capability with an owning side in the readiness report; the shared write envelope and the nine refusal codes are declared and demonstrated; publish runs under an effective grant recording the acting publisher; the acceptance workflow and the six adversarial cases are demonstrated with retained runs and declared reads.
- Benefit: The platform and DAL build against declared names and contracts instead of a proposal; publishing authority, revision immutability and corrections are governed semantics, not UI behavior.

### kernel-no-code-platform-cleanup (ACTIVE; 0 of 13 tasks done; actor none)

- Goal: Make SDA a no-code kernel runtime with a complete, durable violation inventory.
- Benefit: Stops the kernel from accreting platform code and makes the remaining debt visible, owned and finite.

### no-silent-failure-law (ACTIVE; 6 of 11 tasks done; actor SFX Execution Observer / Evaluator)

- Goal: Make every live capability invocation error visible in the scenario circuit and formally verifiable before any fix is applied.
- Agent user story: As the SFX Execution Observer, I need every live capability invocation failure to produce an explicit, attributable outcome within its scenario circuit, so that I can identify the failed operation, preserve its evidence, classify the observed condition, and initiate an appropriate governed correction workflow.

As the SFX Conformance Evaluator, I need to evaluate declared failure-observation conditions and report whether they are satisfied, so that a correction cannot conceal an unresolved failure or replace observation with an unsupported success claim.
- Acceptance: Failures are observable, classifiable, and independently verifiable before corrective changes are applied.
- Benefit: No silent failures: failures render as declared outcomes, drive detect-then-correct, and the conformance reports carry the statically evaluable conditions.

### objective-agent-full-reliance (ACTIVE; 12 of 13 tasks done; actor SFX Objective Agent)

- Goal: Make request-capability-from-objective-v3 the primary operator: every MCP tooling capability is reachable, constructible, executable and reportable from one plain-language inquiry, so estate work - repairs, inspection, verification, authoring - runs through the agent.
- Agent user story: As the SFX Objective Agent, I need to discover, inspect, construct requests for, invoke, and interpret the outcomes of every capability made available to me through the governed MCP tooling catalog, so that I can perform estate inspection, verification, repair, and authoring from a plain-language objective without requiring the owner to operate each tool manually.
- Acceptance: I can carry an authorized objective through its required capability invocations and return attributable execution evidence that the owner can independently verify.
- Benefit: Retires local operator work; every unit lands as a retained, online-verifiable run; the estate manages its own backlog through the tracker.

### objective-agent-loop (ACTIVE; 14 of 24 tasks done; actor SFX Objective Agent)

- Goal: The objective lane routes to a specialist that owns a persistent work cycle - observe, decide, invoke, observe - across successive capability executions without the frontier agent or human driving each iteration, suspending only at explicit authorization gates.
- Agent user story: As a resident specialist, I can pursue an objective across successive capability executions by observing each result and choosing the next permitted action from my persisted estate state, until the required outcome is established, refused, suspended for approval, or a budget is exhausted.
- Acceptance: First proof: the Design Specialist takes the retained dungeon design revision (sha256:cb9b7836...) and the review findings, and completes multiple evidence-driven iterations (inspect, select corrections, revise elements, evaluate, continue) under one objective with no frontier-agent coordination; every iteration is observable as nested/correlated circuit executions; the loop ends in a corrected digest-bound revision suspended at the owner approval gate, or a named blocker. If the loop stops after one invocation, the exact stop point is recorded as the next missing continuation mechanic. Standing execution contract: every request asynchronous and observable, with explicit async dispatch, addressable correlation, live observation while processing (terminal telemetry retained for fast executions), nested traceability, and independent evaluation against durable outcomes. No synchronous blocking, timeout-based async simulation, or multiple Frontier-operated calls substituting for native continuation.
- Benefit: Agency transfers into the estate: sustained agentic work becomes observable and governable as ordinary scenario circuits instead of living in an external agent's conversation context.

### ov3-model-call-optimization (ACTIVE; 2 of 22 tasks done; actor claude-code-fable-5-1)

- Goal: Cut the cost and latency of every OV3 model call and make its token usage observable: bound what a turn sends to Gemini (tool list, memory, history), set the output limit, retain prompt size and token usage per turn, and expose them through declared reads, so a two-turn conversation finishes well under a minute and no conversation dies at the 300 s host limit.
- Agent user story: As claude-code-fable-5-1, the planner the owner assigned, I plan the flights in which the OV3 network authors, retains and installs the revisions by digest, measures before and after through declared reads, and publishes each flight's verification report for the owner; I author no SQL myself unless the owner takes the wheel.
- Acceptance: (1) A turn-1 model request is at most 110,000 characters (from ~237,500) and each earlier turn adds at most 2,500 characters. (2) Every retained turn carries promptChars, toolListChars, memoryChars, historyChars and, once captured, promptTokenCount and candidatesTokenCount. (3) read-run-model-attempts returns per-turn sizes, timing and usage for a retained conversation. (4) Ten consecutive two-turn conversations complete with median per-call model time at most 10 s and no RUN_TIMEOUT, selecting the same capability as before. (5) Every task is DONE with a task-execution-evidence.v1 reference or carries a recorded disposition, and the owner accepts each flight's verification report.
- Benefit: Today a turn-1 call is ~59K tokens (tool list 77%, memory 22%), each call 13-30 s, two calls per conversation, an 18-turn conversation ~1.4M tokens, and no token count is retained anywhere, so the OV3 benchmark cannot score model cost or per-call latency. After: calls at most half the size with bounded growth, faster answers, no RUN_TIMEOUT from payload growth, and token and cost rows for the benchmark.

### profile-schema-boundary-doctrine (ACTIVE; 2 of 4 tasks done; actor claude-code-opus-5-5)

- Goal: The profile schema boundary (declared 1 is ours, the per-language resolver 0 is SDA's, every provider beyond the schema is ours, SDA platform bindings are debt) is stated first and unmistakably in every estate document, agent memory and OV3 prompt.
- Agent user story: As the owner, I want the boundary stated so strongly that nothing in memory or durable documentation drowns it out, so that OV3 and every agent design providers as ours.
- Acceptance: docs/the-boundary.md exists and AGENTS.md, README.md and transistor-model.md state the boundary first; agent memory carries profile-schema-is-the-boundary and no memory presents SDA debt as the pattern; OV3 answers from the declared boundary statement; the document sweep leaves no estate document presenting SDA platform behavior as the way.
- Benefit: No agent or OV3 turn reproduces the false narrative that the estate depends on SDA for database reads or must ask SDA for a provider.

### project-plan-reports (ACTIVE; 3 of 3 tasks done; actor claude-code-opus-5-5)

- Goal: Every project plan can be generated from the tracker as a Markdown report for the owner's review and materialized into docs/reports/Projects by a worker.
- Agent user story: As the owner, I want project plans generated into docs/reports/Projects by a worker, so that I can review them before approving.
- Acceptance: generate-project-plan-report returns a report from the tracker for a project; the worker writes <projectId>-plan.md into docs/reports/Projects; the file matches the report.
- Benefit: The owner reviews plans as documents generated from the tracker rows, never hand-written summaries.

### provider-capability-registry (ACTIVE; 4 of 12 tasks done; actor claude-code-opus-5-5)

- Goal: The experience of the person looking up providers in the registry, mastered: searchable pages that show what each provider is, how to connect it, what can be done with it through the estate and what execution has been verified, published live by the intake workflow from a provider-to-capability graph with derived status per layer.
- Agent user story: As a person looking up providers, I want to find the providers for what I need and see what each one is, how to connect it, what I can do with it and what has been verified, so that I can choose one and use it. (The owner, 2026-10-26: "We want to master that experience. We want to make sure that's our only focus.")
- Acceptance: The ten acceptance tests of docs/projects/Provider Capability Registry.md: discover, profile (a model with no inference mapping reads Profiled with no connection), connect, admit before verify, verify per scenario, publish with every fact traced, educate first, compare, maintain by surface digest, and scale with no new table or renderer and no read on SDA's built-in SQL reader.
- Benefit: Every provider intake publishes becomes a page the user reads, with every fact traced to a row or a run; the intake workflow is a live value chain to that user, not a back-office process, and the registry grows by rows, not publishing code.

### resume-generator (ACTIVE; 3 of 23 tasks done; actor claude-code-fable-5-1)

- Goal: Declare the resume generator of C:\lab\repos\my-resumes into the estate: the resume sources retained as workspace files, generate-resume-document declared through the pipeline, the document rendered to .docx and .pdf on the host, and the export manifest as rows.
- Agent user story: As claude-code-fable-5-1, the planner the owner assigned, I plan each flight of this project from the declared pipeline (draft-capability-from-spec, plan-capability-flight, approve-flight-plan, OV3 flies) so that generate-resume-document and its host rendering and manifest are declared and demonstrated with retained evidence, and the owner approves every plan before it flies.
- Acceptance: Every task is DONE with a task-execution-evidence.v1 reference or carries a recorded disposition; generate-resume-document is declared and its first call for perspective cto on source sha256:c5bd2053cbb70604785e2c09b94447e6ee8a04112da66307d4aa94d4a787a167 returns GENERATED with the document created in the my-resumes workspace by its watcher; read-project-tracker reconciles the project.
- Benefit: A resume is generated from retained, digest-pinned sources through a declared capability with retained evidence, instead of local Python and Word scripts.

### sidefx-compounding-capability-improvement (ACTIVE; 16 of 34 tasks done; actor claude-code-opus-5-5)

- Goal: A SideFX operator can take an existing executable behavior, reconstruct its bounded meaning, compare original and declared execution with trustworthy testimony, preserve verified reusable knowledge, and demonstrate whether a subsequent equivalent case closes with less inference, time and cost, without weakening outcome or evidence integrity. Execution Intelligence (SEE: what executed, what became true, what was missing, what was consumed) and Semantic Reconstruction (SCR: what observable obligation a source embodies and whether the estate represents it faithfully) are joined by Shared Verification (SVC: whether a verified reusable rule reduces inference or work on a later comparable case).
- Agent user story: As claude-code-opus-5-5, the planner registered for this program, I read the tracker and the retained runs first, link existing tasks instead of cloning them, and plan deterministic flights (exact steps with fixed expectations, retained candidates installed by digest, drafting and preflight done as discovery with rollback before a plan is recorded) that the OV3 network flies once the owner approves. Each flight that demonstrates a task ends with publish-workflow-verification, and a task reads DONE only after the owner accepts that report. I need a run-addressable read of retained cell testimony, honest terminal, propagation and coverage states, a frozen challenge corpus and one shared comparison contract, observation providers for C# source declared up to the profile schema, the existing authoring and revision lifecycle for candidates, and differential execution of original and declared behavior under the isolation and authorization the owner decides. I never admit a reconstruction myself: inference proposes, the existing capability governance admits, and the owner approves. I author no SQL, DSL or content myself unless the owner takes the wheel.
- Acceptance: (1) P1: one completed, one failed or timed-out and one non-OV3 run each yield an attributable, honestly coverage-qualified assessment, first on 4aeefa71 and 87c35fcd, with observed model and HTTP timings and missing spans, no double counting of nested inclusive durations and no claimed token counts. (2) P2: one C# specimen closes on declared semantics with an attributable original-versus-declared comparison, and a targeted adversarial fixture catches at least one plausible but incomplete translation. (3) P3: a new, verified C# case applies one previously admitted mapping without redundant inference and with no decline in admitted behavior or evidence; if no case qualifies, the finding is reported, never fabricated. (4) Pilot thresholds: zero false claims of fulfilled objectives on deliberately deviated fixtures; zero falsely complete coverage on known missing nested populations; one measured C# semantics reapplication without inference; 100 percent provenance or explicit unavailability on the selected fixture-run testimony; no observed behavioral-parity regression; no percentage speedup or token-reduction target before matched baselines exist. (5) Completion law: for one novel bounded C# specimen and a second covered specimen, SideFX retains exact source identity, reconstructs and verifies canonical behavior with existing admitted profiles, records trustworthy timing, provider and outcome evidence, promotes one reusable verified mapping through its existing change process, invokes it on the second specimen without redundant inference, and produces a matched, attributable comparison; later languages expand that proof and never substitute for it. (6) Every task is DONE with a task-execution-evidence.v1 reference or carries a recorded disposition, and the owner accepts each run-published verification report.
- Benefit: Today (research of 2026-10-26 and 2026-10-27): every OV3 output reads RETURNED and ANSWERED, deviated flights included; read-estate-execution-activity reports coverage.complete true while missing the nested executions of 17 of 20 runs; 3 of 20 runs were killed at 300 s and 1 was lost with no terminal state; token usage, billed price and the resolved model are not readable; no source behavior has been reconstructed, verified and reused without inference. After: attributable, honestly coverage-qualified run assessments; one verified C# mapping reapplied to a new case without redundant inference; a matched, attributable measurement of what the reuse saved.

### spec-driven-circuit-proposal (ACTIVE; 10 of 16 tasks done; actor SFX Objective Agent)

- Goal: Specs in markdown become declared circuits: the objective agent reviews a specification and proposes topology, providers/bindings/ports, the @-annotated Gherkin feature and execution operations through the governed model lane - proposal first, declaration next.
- Agent user story: As the SFX Objective Agent, I need to receive a markdown specification and return a circuit proposal (topology, providers, bindings, ports, feature Gherkin, execution operations) through declared capabilities, so that new features are authored from specs without hand-assembly.
- Acceptance: The Procedural Dungeon Webpage handoff spec is proposed through the objective lane: a retained circuit-proposal.v1 names the topology, provider identities, port bindings, the full @-annotated Gherkin feature and the execution operations, tracing to the model testimony; the accepted proposal is declared into a working capability through the governed pipeline; and the game is played live through the estate: player commands dispatch through declared mechanics, visibility renders fog-of-war frames, and each move appears as a retained run in the live circuit. Owner direction 2026-10-17: the playable experience is the acceptance bar - the project was undelivered and not officially closed.
- Benefit: New features start from a spec: the proposal is generated, reviewable and retained, and the same pipeline turns an accepted proposal into a declared capability. The Procedural Dungeon Webpage handoff is the first subject.

### stored-procedure-capability-promotion (ACTIVE; 12 of 15 tasks done; actor SFX Objective Agent)

- Goal: Promote existing, optimized SQL stored procedures into governed, MCP-available capabilities without rewriting their logic: SQL scaffolds the interface mechanically, the specialist completes the semantic contracts and bindings, and SideFX installs and publishes.
- Agent user story: As the Stored Procedure Capability Specialist, I can take an existing well-shaped procedure, scaffold its candidate capability from SQL metadata, complete its input/outcome contracts and provider bindings, declare it through the governed estate, publish it to MCP, and demonstrate discovery and invocation - without rewriting the procedure's SQL logic.
- Acceptance: One stored procedure, one specialist, one successful promotion, one live MCP invocation: a natural-language promotion request through Objective V3 is routed to the specialist, the scaffold candidate is completed with semantic contracts and bindings, the capability is installed through the governed estate (no migration runners, no scratch scripts), published to the MCP catalog, and invoked live with the execution observed on the scenario circuit; the procedure's SQL logic is unchanged. Missing mechanics revealed by the first execution become the next tasks.
- Benefit: Existing database intelligence becomes reusable agent tooling without inference reconstructing computation; the reverse acquisition pathway complements intent-first engineering and feeds the specialist network.

### task-skill-verification (ACTIVE; 10 of 21 tasks done; actor SFX Objective Agent)

- Goal: Every task verifies both states: an assessed before-state baseline and an after-state checked against target requirements, joined by an accepted transition comparison, with task-linked skills pinned at exact revisions.
- Agent user story: As the SFX Objective Agent, I need each task to carry versioned before and after verification processes with their skill obligations, evidence sets, evaluations and transition comparison, so that I perform work under exact pinned skills and closure consumes the authoritative results instead of my assertions.
- Acceptance: Before and after are separate processes with separate state, level, evidence and evaluation; an expected-defect baseline can be baseline-accepted while its finding stays FAIL; after-state PASS alone cannot close a task missing baseline or transition evidence; a complete task opens both immutable evidence sets and the accepted comparison after restart; absent, malformed or historical-unavailable skill refs never render as verified; the four source-backed task-to-skill mappings render with capability refs as separate bindings; stale or concurrent closure writes refuse explicitly with refreshed semantic readback.
- Benefit: Acceptance is consumed from authoritative paired-state results; the Workbench renders two independent verification processes per task with their evidence, evaluations and reviewer requirements.

### transfer-of-agency (ACTIVE; 15 of 17 tasks done; actor SFX Capability Maintenance Agent)

- Goal: Make the estate as capable as the frontier model: no constraints beyond the architecture, no additional guardrails on agency transfer, and acceptance by operational proof.
- Agent user story: As an estate capability agent, I can perform migration and repair work with the same practical agency as the host tool, receive the work as input, execute it through an estate-native capability, and return a retained run and result, without being handed credentials or blocked by agent-added guardrails.
- Acceptance: The owner rules are durable in AGENTS.md, the project plan and the tracker. Migration work is an invocable estate capability with host-level agency and host-side credentials. A real supplied capability-repair list is executed through that capability and read back. Constraints outside the architecture are named and removed or accepted by the owner.
- Benefit: The estate can repair itself, migrate itself, and change its own capability surface through its agent network. Defensive drift is removed; owner authority and architecture remain the only constraints.

### watcher-worker-flight-orchestration (COMPLETED; 13 of 13 tasks done; actor claude-code-opus-5-5)

- Goal: One watcher per profile receives events, routes each to the worker flights its declared assignments name, and keeps listening; workers are durable responsibilities realized as long-running flights.
- Agent user story: As the owner, I want to spin up workers through the watcher for specific tasks in designated sub-folders, so that the outcomes of a capability are handled asynchronously while the watcher keeps listening.
- Acceptance: A declared profile with two scopes and two workers routes one live event to its worker flight asynchronously; the financial report worker lands a report through its flight; the existing watchers run as profiles; evidence.watcher is gone and identity.watcher holds the instances.
- Benefit: Workers for specific tasks in designated folders start from declared rows instead of new watcher processes; routing, bindings and handoffs are retained and replayable; the watcher never blocks on a worker.

### wsjf-priority-model (ACTIVE; 3 of 3 tasks done; actor SFX Objective Agent)

- Goal: The estate orders open work by WSJF: each task carries relative estimates (business value, time criticality, risk reduction/opportunity enablement, job size) recorded as rows; the score is derived in reads, never stored; the Workbench Priority Work Queue and the Objective Agent both rank from the same declared queue read.
- Agent user story: As the SFX Objective Agent, I need each open task to carry owner-visible WSJF estimates and a derived score available through a declared read, so that I work highest-value-first and can explain any ordering decision from rows.
- Acceptance: Estimates and derived WSJF are readable per task through declared reads (read-project-tracker and read-task-priority-queue); the score writer validates the domain and refuses out-of-range input; the baseline scoring act ranks the live open backlog with a retained queue read; the process documents name the scoring authority and the queue rule.
- Benefit: Scheduling stops being prose. Open work has a numeric, inspectable priority; unranked work is visible as debt instead of silently outranking scored work; lanes and next-task selection follow the same declared order.
