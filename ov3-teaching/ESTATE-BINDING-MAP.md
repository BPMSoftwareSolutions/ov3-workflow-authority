# Estate binding map: ov3.estate-workflow-discovery.v1

**Status:** CANDIDATE. Prepared 2026-11-02 by the Frontier planner from declared reads and installed sources. It gives W0 a head start, not its result: W0 re-reads every row before relying on it.

**Evidence basis.** Declared reads through `sfx-api capability observe ... --auth user`, all retained API runs and none of them flight-recorded:

| Read | Run | Result |
| --- | --- | --- |
| `read-mcp-catalog` | `507e6156` | READ, 241 MCP capabilities |
| `read-agent-specializations` | `17cbec1f` | READ: 4 specializations, 19 skills, 26 candidates |
| `read-capability-dsl-specification` | `3c7d66c7` | READ: `capability-dsl.v1`, 19 constructs, digest `sha256:bd9a44ae…` |
| `read-declared-capability-document` | `b05b8584`, `0e8a48f7`, `15421e60`, `24685f78`, `278015c2`, `61f6f5d2`, `ea1be51a`, `23b11626`, `99821f68`, `2535621e`, `f5714231` | documents for `propose-capability-circuit`, `draft-capability-from-spec`, `read-topology-conformance`, `read-scenario-authority`, `read-live-scenario-circuit`, `list-capabilities`, `plan-capability-flight`, `record-flight-plan`, `compile-capability-dsl`, `read-scenario-terminal-coverage`, `read-declared-composition` |

**Later reads, after re-login:**

| Read | Run | Result |
| --- | --- | --- |
| `read-project-tracker {limit: 100}` | `d075c4c7` | 38 projects; no `ov3-estate-workflow-fidelity` and no `oewf-*` tasks. The precedent `spec-driven-circuit-proposal` (approved 2026-10-15) has 10 of 16 tasks DONE, including proposal → declaration for the dungeon specimen |
| `compile-capability-dsl` | `266ab2a8` | `discover-spec-estate-baseline` COMPILED, 0 diagnostics |
| `read-agent-specializations {skillId, skillRevision}` | `a5411039` | returns `content` and `contentDigest` (base64 SHA-256) |
| `analysis-read-selected-definition` | `7640b43a` | `capability-workflow.v1` shape: `contractId, workflowCapabilityId, objective, promiseId, workClass, stages` |
| `read-flight-recording` (plan 19) | `766a980a` | promise payload `flight-promise.v1` via `content-artifact-change`; `semantics_json` passed as an object |

The host has no machine-auth token, so `--auth machine` fails; `--auth user` works.

Installed sources read (repository copies; W0 confirms against `read-declared-object-source`):

- `sql/schema/assemble-execution-declarations.sql`
- `sql/migrations/declare-route-semantic-progress.sql`
- `sql/schema/analysis-compose-workflow-run.sql`
- `sql/migrations/declare-skill-tables.sql`
- the kernel schema `canonical-circuit-blueprint.v1`

## Term bindings

| Specification term | Disposition | Estate surface | Basis |
| --- | --- | --- | --- |
| Server authority / `sfx-api` | BOUND | `sfx-api` → SDA Run API → installed `KernelEntry`. Runs are retained online | runs above |
| Scenario: Input → Event → Outcome | BOUND | capability document `scenarios[]`: `inputId`, `inputContract`, `eventId`, `eventAuthority`, `outcomeId`, `outcomeContract`, `root`, `terminal` | DSL `documentSemantics` (run `3c7d66c7`) |
| Canonical blueprint, ADR-001 node kinds and edge dimensions | EQUIVALENT, partial | The kernel validator schema `canonical-circuit-blueprint.v1` defines them. Estate routes carry `topologyKind` and `semanticProgress`; the vocabulary map is in skill `spec-scenario-topology` | `declare-route-semantic-progress.sql` |
| Workflow entry | EQUIVALENT, candidate | Capability CLI interface `<cap>-cli` with `rootScenarioId` and the root scenario flag. OV3 sees it only when `model.capability.is_mcp_tooling` is set. **W1 must confirm that no other entry-admission carrier exists** | `interfaces.authority.json` assembly |
| Workflow (route closure from one entry) | AUTHORITY_GAP | Inside a capability: `$.semantics.routing` expanded by `analysis.capability_declared_transitions` into `semantic-graph.authority.json`. Across capabilities: only composition edges (`read-declared-composition`). No installed read returns per-entry closure | sources above |
| `TRANSITION`, `BRANCH_ROUTE`, `FAN_OUT_MEMBER`, `CONVERGENCE_REQUIREMENT`, `BOUNDED_RETURN` | EQUIVALENT | DSL lines `route`, `broadcast` + `join`, `recur … max n` compile to `selection`, `broadcast`, `join`/`failure`, `recurrence`. Hand-minted routes may also use `sequence`/`return` | compiler `sha256:6aee2a7b…` (run `916ade66`); `declare-route-semantic-progress.sql` |
| `semanticProgress` on DSL-authored routes | AUTHORITY_GAP | Only `recur` emits it (`recurring`). `route`/`broadcast`/`join` compile without it, and neither `model.declare_capability_topology` nor `model.declare_capability_envelope` adds it. Fail-closed: such routes are held. Task `oewf-w1-dsl-route-progress` | runs `916ade66`, `ecaeec9b`, `e3a83d09` |
| Bounded-return bound | BOUND | `recur … max <n>`; without `max` the compiler writes 2147483647 (treat as unbounded) | run `916ade66` |
| `ALTITUDE_DESCENT` | EQUIVALENT | not a route: operations → ports → port bindings → provider slots → providers | DSL `operation` / `bind` |
| Semantic progress `ESTABLISHES`, `DESCENDS` | AUTHORITY_GAP | no estate value; recorded as documented gaps | same migration |
| Provider binding, provider slot | BOUND | `portBindings`; `model-declare-provider-slot`, `analysis-read-provider-slot-bindings`, `read-declared-port-bindings` | catalog |
| Provider testimony | BOUND | `read-run-cell-testimony` | plan 440 steps 12–15 |
| Product dependency | NOT_DECLARED (unverified) | No relation carrier found. An overlay can be derived from shared contract ids (`read-declared-contracts`) | W1 |
| UI navigation | NOT_DECLARED | UI lives in sfx-platform (`sidefx-ui-*`); it is not estate routing | — |
| Pinned snapshot and digest | BOUND | `estateModelPk`, document and definition digests, `expectedCatalogDigest` (refuses `STALE_CATALOG`) | `read-topology-conformance` and `read-declared-composition` contracts |
| `reveal-estate-workflows` | candidate; reuse check | The closest installed reads are `read-live-scenario-circuit` (deck circuits, drill-down) and `read-declared-composition`. Neither computes an entry-rooted closure | documents above |
| Mermaid / ASCII / JSON / UI parity | AUTHORITY_GAP | No installed parity read. A Mermaid projection profile exists only outside the estate (agentic-harness) | W4 |
| Execution observation and replay | BOUND | `read-flight-recording`, `read-flight-progress`, `read-run-cell-testimony`, `sfx-api run <id>` | catalog |
| OV3 flight-plan envelope (`OV3-FLIGHT-PLAN-CANDIDATE.json`) | EQUIVALENT | `estate-flight-plan.v1` header plus steps; the promise is retained as `flight-promise:<id>` with obligations | `first-loop-proof.md`, `analysis.compose_workflow_run` |
| Admission and promotion (W7) | BOUND | `capability-from-dsl` / `apply-engineering-change` commit, `promote-stored-procedure-capability`, `mcp-tooling-change`, `approve-flight-plan`, `read-flight-closure` | AGENTS.md, catalog |
| Gherkin acceptance | EQUIVALENT | scenario `given`/`when`/`then` in DSL; `design-feature-gherkin`; acceptance runs are flight steps | DSL spec |
| "Workflow" (the estate word) | COLLISION | `CAPABILITY_WORKFLOW` in `sidefx:workflows` plus `start-workflow-run` / `fly-workflow-run`: declared stage sequences flown as flights. Not scenario progression | `analysis.compose_workflow_run` |
| Reader authorization context | NOT_VERIFIABLE here | `sfx-api --auth user` principal and specialization grants. Capability-level read authorization is unknown | W1 |
| DSL specification vs compiler | specification drift | The compiler accepts `inquiry:`, `route`, `broadcast`, `join` and `recur`. The installed `capability-dsl-specification.v1` (19 constructs, `sha256:bd9a44ae…`) lists none of them, so an agent that trusts the specification under-uses the DSL. This pack's first draft did exactly that. The compiler is the authority until the specification catches up; that update belongs to project `capability-dsl` | runs `266ab2a8`, `916ade66`, `3c7d66c7` |
| OV3 compound objectives | finding | The System One fast path (`omc-typesafe-intent-routing`, `03-decide-intent`) routes any sentence it classifies as `fly-flight-plan` (confidence ≥ 0.9) that names an `agent …` straight to `fly-flight-plan {principalId, agentId}`, with no model turn. Other requests in the same sentence ("approve and fly") are silently dropped; the reply reports only the fly | run `f9b4ec49`, recording `521c95ea` |
| Skill content reported as retained | finding | `read-agent-specializations` reports `missing:false` and `RETAINED` for skills whose content is empty (`graph-topology-emission` r1), and it echoes unknown skill ids. Only `contentDigest` proves content | runs `72fa3884`, `59b2f4e1`, `b6697788` |
| Spec → proposal → declaration | BOUND (precedent) | project `spec-driven-circuit-proposal`: `propose-capability-circuit`, `sp-proposal-to-declaration` DONE (dungeon specimen) | run `d075c4c7` |

## Gaps that need an owner decision

1. **Cross-capability routes.** The spec's offline path (queue → synchronize → record) and shared downstream scenarios need routes between capabilities. The estate has no carrier for that. The two options:
   - **Composition:** synchronize's port is bound to `record-wildlife-encounter`. This is descent into the shared responsibility, which matches spec §4.5.
   - **One capability:** a single capability holds the shared scenarios. The `capability_scenario` link may allow a scenario to be shared, but this is unverified.

   The choice decides what the lens draws as a route and what it draws as composition.
2. **The entry admission carrier.** Is root scenario + CLI interface + MCP flag the entry authority (spec §3.1), or does a separate declaration need to be proposed?
3. **The product dependency carrier.** Should it be shown as an overlay derived from contract identities, or proposed as a declared relation? The other option is to report it as NOT_DECLARED.
4. **MCP flagging of `discover-spec-estate-baseline`.** Flagging it adds a tool to OV3's catalog, and OV3 reads that catalog on every turn.
5. **The planner identity for these flights.** The flight process names `opencode-deepseek-flash`; recent plans ran as `claude-code-opus-5-5`. The teaching flights use `claude-code-opus-5-5-ov3-teaching-<flight>`: one current plan per agent in `evidence.flight_plan`, and no existing agent's plan superseded.
