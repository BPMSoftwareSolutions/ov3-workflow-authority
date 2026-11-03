# Teaching OV3 to build out a specification pack

**Status:** CANDIDATE, NOT FILED. Nothing in this folder has been written to the estate. Every file is ready to go through the mandatory flight process: plan, review, report, owner approval, and OV3 flies.

## How teaching reaches OV3

OV3 (`request-capability-from-objective-v3`) does not read skills at run time. On every turn its engine (`analysis.objective_agent_step`) reads four things: the objective, the person's `agent-memory:<principal>` artifact, the MCP catalog, and earlier turns. See `sfx-embody/docs/research/skills-in-the-estate/README.md` §5. So the teaching is delivered in the three forms the estate actually executes or assembles:

| Form | What it teaches | How it reaches a model or OV3 |
| --- | --- | --- |
| **Tracker project + tasks** | *What* to build, in what order, behind which gates | `coordinate-project-task` finds the next ready task and calls the capability that task names. Its RESOLVE phase assembles the task's pinned skills through `read-specialist-context` |
| **Skills** (`skills/`) | *How* to turn a spec into estate work: bind, declare, route, accept | Pinned on every task (`skillRefs`), so they arrive as specialist context. They can also be pinned on a planner specialization (decision below) |
| **Workflow capability** (`workflows/`) | A repeatable, executable sequence OV3 can be told to run | `"Start a run of discover-spec-estate-baseline for task oewf-w0-discover"` → composed into a flight → reviewed → approved → flown |

## The four skills

All four are ASCII and 4.7K–7.6K characters. Digests are in `manifest.json`.

| Skill | Responsibility | Spec phases |
| --- | --- | --- |
| `spec-pack-intake` | Retain the pack by digest. Bind every term to an installed surface or an exact gap. Preflight the project | W0, W1, B0 |
| `spec-capability-declaration` | Providers first (EXISTS / COMPOSE / LEAF). One capability per entry. DSL (including its `route` / `broadcast` / `join` / `recur` lines) → compile → draft → build and first-call flights. Make repeatable builds workflow capabilities | W3, B1–B5 |
| `spec-scenario-topology` | The spec's "workflows": blueprint term → DSL line → estate route vocabulary; relations that are never routes; fail-closed rules, including the held state of DSL routes that lack `semanticProgress`; the read-only lens | W1, W3, W4, B2, B3, B5 |
| `spec-acceptance-and-closure` | Gherkin → flight steps with expectations and historical basis. Negatives RED first. Real runs only. `PROMISE_CLOSED`. Final report | W2, W5, W6, W7, B6, B7 |

They build on the five `flight-pattern-*` skills proposed on 2026-10-27 in `sfx-embody/docs/research/skills-in-the-estate/proposed-skill-records.md`, which cover how to fly, and reference them by id. Those five are not filed yet. The references are prose, and the writer doesn't check them, so the order isn't enforced; until those five are filed, the references lead only to the proposal file.

Fix that proposal before filing it. Its read-back expects `$.skills[0].missing = false`, but that check reads false even for a skill whose content is empty. Use the content-digest check these flights use instead.

## Who does what

The split follows the transfer of agency. The owner's SQL makes only the two planner writes: each flight's promise, and its recorded plan. **OV3 does everything else:** review, report, approval on your words, the flight itself (registering the skills, opening the project, declaring the workflow), and closure.

| # | Flight | Planner id (current plan) | Promise | Steps | Plan digest | After |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | teach-skills-1: spec-pack-intake, spec-capability-declaration | `claude-code-opus-5-5-ov3-teaching-skills-1` | `ov3-teach-spec-skills-1` | file + prove ×2 | rev 2 `4821b1e1…` | — |
| 2 | teach-skills-2: spec-scenario-topology, spec-acceptance-and-closure | `claude-code-opus-5-5-ov3-teaching-skills-2` | `ov3-teach-spec-skills-2` | file + prove ×2 | rev 2 `b1554a22…` | — |
| 3 | teach-project: `ov3-estate-workflow-fidelity`, 17 tasks | `claude-code-opus-5-5-ov3-teaching-project` | `ov3-teach-spec-project` | 1 | rev 2 `09dad5bf…` | 1 and 2 closed (the writer refuses unknown skill pins) |
| 4 | declare `discover-spec-estate-baseline` | `claude-code-opus-5-5-ov3-teaching-workflow` | `wf-declare-discover-spec-estate-baseline` | 6: retain the run promise, then the declare-once pattern of flight `30b9f6b4` | rev 1 `f1552e69…` | owner decision 4 |
| 5 | repair `graph-topology-emission` as revision 2 | `claude-code-opus-5-5-ov3-teaching-gte` | `ov3-teach-gte-r2` | file (`baseRevision: 1`) + prove | rev 1 `ee94396c…` | any time |

`evidence.flight_plan` keeps one current plan per agent, so each flight has its own planner id. The dedicated prefix means no other agent's plan is superseded. Full digests are in `manifest.json` under `flightPlans`. Each prove step reads the skill back by exact revision and expects `$.skills[0].contentDigest` to equal `contentDigestBase64` in the manifest, the base64 SHA-256 of the reviewed file. The writer's long-content and Unicode path is recorded as NOT_TESTED, so that match is the evidence that the content landed intact. The read echoes a requested id even when no such skill exists, but without `contentDigest`, so the check can't pass falsely.

**Why flights 1–3 are at revision 2.** After `ov3-teach-02` recorded them, the installed compiler turned out to declare routing from DSL text. The DSL specification doesn't list those lines, and two skills said it couldn't. The skills are corrected, and the project gained the gap task `oewf-w1-dsl-route-progress`. None of these plans had been approved, so nothing is superseded except reviews of the old digests.

**Graph-topology-emission repair (flight 5).** The estate's revision 1 of `graph-topology-emission` holds no content: it was registered before the writer stopped truncating long content, yet it reads `missing:false` and `RETAINED`. Revision 2 restores the original 4,149 characters, the `sfx-embody/.claude/skills/graph-topology-emission/SKILL.md` body. That body is byte-identical to the change that registered revision 1. Its §5 still describes `dsl-fanout-construct` as upcoming work, though that task closed on 2026-10-16. The repair restores the text as agreed; updating it would be a revision 3.

## Step 1: your SQL

Each script comes as a preflight (`.sql`, ends in `ROLLBACK`) and a byte-identical commit twin (`.commit.sql`). Run the preflight, check its result sets, then run the commit twin. Run each whole file in one session.

| Order | File | Database | What the result sets should show |
| --- | --- | --- | --- |
| 1 | `sql/ov3-teach-01-promises.sql`, then `.commit.sql` (**ran 2026-11-02**) | estate (`sfx-estate-database`) | `base`: installed = expected (`sha256:d6f8025a…`). `minted`: 4 rows, `MINTED`. `readback`: 4 rows, `matches = 1` |
| 2 | `sql/ov3-teach-02-flight-plans.sql`, then `.commit.sql` (**ran 2026-11-02**) | `sfx-identity` | `guard`: 4 writer parameters, owner principal active = 1. `plans`: 4 rows, `plan_revision = 1`, `matches_reviewed_file = 1` |
| 3 | `sql/ov3-teach-03-promises.sql`, then `.commit.sql` | estate (`sfx-estate-database`) | `base` as in 1. `minted`: 1 row (`flight-promise:ov3-teach-gte-r2`), `MINTED`. `readback`: `matches = 1` |
| 4 | `sql/ov3-teach-04-flight-plans.sql`, then `.commit.sql` | `sfx-identity` | `guard` as in 2. `plans`: skills-1, skills-2 and project at `plan_revision = 2`, gte at `1`; all `matches_reviewed_file = 1` |

Files 1 and 2 are kept byte-for-byte as run. They are the record and are never regenerated.

Each script only calls the installed writers: `model.mint_content_artifact` (the writer behind `content-artifact-change`) and `evidence.upsert_flight_plan` (what `record-flight-plan` runs). There are no hand-written INSERTs into model tables. The promises script stops before any write if its writer's definition has moved.

## Step 2: OV3, by voice or text

For each flight in order, starting with `claude-code-opus-5-5-ov3-teaching-skills-1`:

1. "Review the current flight plan of agent claude-code-opus-5-5-ov3-teaching-skills-1 and generate its plan report." OV3 runs `review-flight-plan` and `generate-flight-plan-report-md`. Read the report.
2. "I approve flight plan digest 4821b1e1c0a430f774535eef7e5e7471df2e1467aa800448e0acd78b39081bbc of agent claude-code-opus-5-5-ov3-teaching-skills-1." OV3 records your words with `approve-flight-plan {principalId, agentId, planDigest, ownerStatement}`. The digest is the one in the report; naming it means the approval can only land on the revision you reviewed.
3. "Fly the current flight plan of agent claude-code-opus-5-5-ov3-teaching-skills-1."
4. "Read the flight closure of promise ov3-teach-spec-skills-1." It should read `PROMISE_CLOSED`. A green step without closure is not acceptance.

**Never combine approve and fly in one sentence.** OV3 sends a sentence to its turn loop only when the System One router (`omc-typesafe-intent-routing`, statement `03-decide-intent`) declines it. Whenever the classifier picks `fly-flight-plan` with confidence ≥ 0.9 and the sentence names an `agent …`, the router dispatches `fly-flight-plan` alone, with no model turn. On 2026-11-02, "Approve and fly the current flight plan of agent …-skills-1" was routed that way: run `f9b4ec49`, `routedBy: system-one`, 0 turns, recording `521c95ea` `NOT_CLEARED`. Nothing was written, because the engine refuses an unapproved plan, but the approval was silently dropped.

| Flight | Promise | Plan digest to approve |
| --- | --- | --- |
| `…-skills-1` | `ov3-teach-spec-skills-1` | `4821b1e1c0a430f774535eef7e5e7471df2e1467aa800448e0acd78b39081bbc` |
| `…-skills-2` | `ov3-teach-spec-skills-2` | `b1554a22e24cf36044916cf9df4ee4c5267b40f2dcd3242c56d25f133e9cb729` |
| `…-project` | `ov3-teach-spec-project` | `09dad5bf404517a43c5f493961d8bc985614e2a40889e75d87431c5a71275756` |
| `…-workflow` | `wf-declare-discover-spec-estate-baseline` | `f1552e699abd20a7f5564aaf463749ec2d99d631ab468ed62fdf1a1329719f71` |
| `…-gte` | `ov3-teach-gte-r2` | `ee94396c52cfe29e21d2057582e4486e856197be3b3e36e31f61b69a683deef3` |

Approve only a digest that the plan report you read shows.

Then do the same for `-skills-2` and `-project`. Do `-workflow` after decision 4. Do `-gte` (promise `ov3-teach-gte-r2`) whenever you like. The report you already read for `-skills-1` was for revision 1 (`a5fa7559…`); after script 4, review again, and the new report names revision 2.

## Then OV3 builds the spec

Once the owner approves the project plan (`planApprovalDate`, an owner act recorded through the project-tracking kind; "Approve the plan of project ov3-estate-workflow-fidelity" to OV3 has no precedent yet), the sentences are:

1. "Start a run of discover-spec-estate-baseline for task oewf-w0-discover." Then review, approve and fly as usual. This produces the W0 baseline and its verification report.
2. "Advance project ov3-estate-workflow-fidelity." `coordinate-project-task` picks the next ready task, assembles its pinned skills, and calls the named capability. Tasks whose capabilityRef is `UNRESOLVED` (W2 specimen carrier, W4 parity read, B0, B5, B6) start by building the missing read or writer. That task is the work, not a blocker.

## Decisions for the owner

1. **The cross-capability route form.** The choice is composition or shared scenarios; it decides how the offline path and shared downstream scenarios are declared. See `ESTATE-BINDING-MAP.md`, gap 1.
2. **Pin the four skills on a specialization as well.** The options are `capability-authoring` or the proposed `flight-planner`. Task pins alone reach a model only through `coordinate-project-task`.
3. **Approve the project plan.** Execution is gated on `planApprovalDate`.
4. **MCP-flag `discover-spec-estate-baseline`.** Flagging adds one tool to OV3's per-turn catalog. Leaving it unflagged means runs start through `start-workflow-run` directly.
5. **Confirm `createdBy` / `projectSponsor` = `sidney`.** That value follows earlier tracker rows.
6. **Repin `resume-generator/rg-specialist-lanes` to `graph-topology-emission@2`?** It is the one OPEN task pinned to the empty revision 1. Four DONE `capability-dsl` tasks also pin it, and they stay as history. Pins never move by themselves.

## Verified 2026-11-02 (declared reads, user session)

- **No id collision.** All 38 projects were read (runs `6a583415`, `d075c4c7`). `ov3-estate-workflow-fidelity` and the `oewf-*` task ids are free. Related project: `spec-driven-circuit-proposal` (approved 2026-10-15). Its tasks `sp-proposal-mechanics`, `sp-propose-capability` and `sp-proposal-to-declaration` are DONE, so the dungeon specimen already proved spec → proposal → declared capability. W3 and B1 can cite it as historical basis.
- **The workflow DSL compiles** (run `266ab2a8`): `COMPILED`, 0 diagnostics. Its source digest equals `manifest.json`, and its document digest is `sha256:3a154d62…`. The `inquiry:` lines compile into `document.inquiries`.
- **The installed compiler declares routing** (`analysis.compile_capability_dsl` `sha256:6aee2a7b…`, run `916ade66`): `route`, `broadcast`, `join` and `recur [max n]`. `capability-from-dsl` carries the result through `model.declare_capability_topology` (`sha256:e747d71f…`, run `ecaeec9b`) into `model.declare_capability_envelope` (`sha256:1542212d…`, run `e3a83d09`). Only `recur` emits `semanticProgress`, and neither writer adds it: that gap is task `oewf-w1-dsl-route-progress`. A `recur` without `max` is bounded at 2147483647.
- **The skill writer is the repaired revision** (`sha256:6e694646…`, run `f71bcd63`): content is read through OPENJSON and hashed as `varchar(max)`. `graph-topology-emission` r1 reads back without content (runs `72fa3884`, `59b2f4e1`); `nested-capability-invocation` r2 reads back with it (run `ab099b37`).
- **Flight 1 had not flown** when its content was corrected (`read-flight-closure` `NOT_FLOWN`, run `400a571e`). The scripts ran 2026-11-02 are unchanged and kept as the record.
- **Expectation paths, checked against real rows:**
  - `$.skills[0].contentDigest`, the base64 SHA-256 of the content. It equals the 2026-10-18 export for `eec-generic-governed-repair` r1 (run `a5411039`).
  - `$.rows[0].declared_id` and the `capability-workflow.v1` declaration shape (run `7640b43a`).
  - `$.document.scenarios[0].operations[0].operationId` (run `0768839d`).
- **Formats taken from plan 19's recording** (run `766a980a`): the promise payload and the object-typed `semantics_json`.

## Not verified

- **Nothing has been written to the estate.** The SQL has not been run. The skill, project and workflow writes are flight steps OV3 performs, and none has flown.
- **The scripts were checked mechanically, not run.** Every T-SQL literal un-doubles and parses back to the reviewed payloads, and the promise and plan digests match `manifest.json`. The writer bodies, the moved-base guard digest, and the `model.content_artifact` / `source.content_object` columns were read from the installed estate. The `sfx-identity` side (`evidence.upsert_flight_plan`, `[identity].principal`) was read from the sfx-dal migration `006-flight-recording`, not from the live database.
- **The review and report inputs OV3 will construct** (`{principalId, agentId}`) follow the proven lifecycle table in `docs/research/flight-patterns/deterministic-workflows.md`.
