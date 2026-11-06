# OV3 writes its own features, then builds its own future state

**Status:** NOT RUN. Owner direction of 2026-11-02, in [owner-direction.md](owner-direction.md). Project `ov3-complete-agentic-harness`.

**For review:** [features/ov3-owns-the-objective.feature](features/ov3-owns-the-objective.feature) sets out what this pack does, and what it leaves open, as Gherkin, with each scenario's status and the team's open questions.

## Why OV3 needs this

OV3's canonical features (`sidefx:features`) each hold exactly one scenario: `request-capability-from-objective-v3`, `-v5` and `objective-agent-loop` (runs `8e0d50cf`, `e7a18b84`, `948a0ea5`). Nothing durable said what the harness must do. So the stance in `docs/projects/objective-agent-loop.md` §2 ("no need for elaborate planning algorithms, self-improvement policies, multi-agent consensus, or additional control-plane primitives") became the implemented design by default. This pack has OV3 write its own scope and canonical features, has you accept them at declared decision points, and then has OV3 build from them.

## What OV3 writes from

[specification.md](specification.md) (61K characters, `sha256:a3441048…`) contains no design. It holds:

- your directions verbatim (today's three, plus those already on record);
- the superseded stance;
- OV3's declared state, with the observed defects and their run ids;
- the estate's laws;
- the recorded goal, agent story, acceptance and benefit of all 38 projects in the tracker (run `d075c4c7`).

The Frontier planner projected it as a bootstrap. Task `oah-spec-assembly` makes assembling specifications OV3's own job afterwards.

## The blocker fixed first

A flight step binds an earlier step's result with `JSON_VALUE`. That reads any string over 4,000 characters as NULL, so the step fails `BINDING_UNRESOLVED`. OV3 couldn't carry the scope or a feature it wrote to the next step.

`ov3-harness-01` adds one 14-line block to `analysis.fly_flight_step_cell`, the step cell every flight runs: when the bind reads NULL, the same member is read through `OPENJSON`. Every bind that resolves today resolves the same way, and paths it can't safely read keep today's result. The script refuses a moved base. Inside the transaction it proves the installed definition is the base plus that block and nothing else, and otherwise rolls back.

## Step 1: your SQL

Run each preflight (`.sql`, ends in ROLLBACK), check the result sets, then run its `.commit.sql` twin. Run each whole file in one session.

| # | File | Database | Expect |
| --- | --- | --- | --- |
| 1 | `sql/ov3-harness-01-bind-long-values.sql` | estate | `base`: installed = `sha256:29ff4f83…`. `verify`: `block_present = 1`, `rest_unchanged = 1` |
| 2 | `sql/ov3-harness-02-sources-and-promises.sql` | estate | `minted`: 4 rows (owner direction, specification, two promises). `readback`: `matches = 1` |
| 3 | `sql/ov3-harness-03-flight-plans.sql` | sfx-identity | `plans`: 2 rows, `plan_revision = 1`, `matches_reviewed_file = 1` |

## Step 2: OV3 proves long binds

Use separate sentences. Never put approve and fly in one; see `ov3-teaching/README.md`.

1. "Review the current flight plan of agent claude-code-opus-5-5-ov3-harness-bind and generate its plan report."
2. "I approve flight plan digest cfc1fcf02a6911d598899054f5098c54ebb8bf85ee5634df28dcd2d4fb7993c4 of agent claude-code-opus-5-5-ov3-harness-bind."
3. "Fly the current flight plan of agent claude-code-opus-5-5-ov3-harness-bind."
4. "Read the flight closure of promise ov3-harness-long-bind." It should read `PROMISE_CLOSED`: a 6,000-character value bound whole, and a short bind unchanged.

## Step 3 (flown): the scope, and why it is replaced

The scope flight passed 6 of 7 steps (recording `b1b16e76`) and delivered `scope.md` (8,304 bytes, `sha256:39ea1983…`). But `design-intent-and-scope` writes one capability's intent as prose. It named no capability areas, and nothing could check it.

Close it with your decision, then fly it once more so the recording closes:

1. "Record my decision revise at decision point ov3-complete-agentic-harness/scope: …" Your words, for example: "replaced by the census flight; the scope must be the capability-area census as checked data."
2. "Fly the current flight plan of agent claude-code-opus-5-5-ov3-harness-scope."

## Step 5 (current): OV3 owns the work, checks it for intent, and proves its provider bindings

Revised 2026-11-02 after your review of census-2 and your direction on provider bindings. The Gherkin version is [features/ov3-owns-the-objective.feature](features/ov3-owns-the-objective.feature).

- **No approval.** `flight-clearance-policy:owner-objective` clears plans of work class `owner-objective` on the deterministic review alone.
- **Nothing recorded in your name.** Census-2 no longer answers the waiting census decision point. Its tracker step records, under OV3's own authority, that flight `ov3-harness-census` is superseded. The decision point stays unanswered.
- **Checked for intent, not just form.** The id check (`analysis.check_capability_census`) confirms that every obligation id is claimed. A separate fulfillment check then has DeepSeek judge each claim. `analysis.check_census_fulfillment` counts an obligation as owned only when an area that claims it does what it requires. Your review's case, one area `format-labels` ("Alphabetize display labels") claiming everything, passes the id check and fails this one with 0 of 69 fulfilled (probes `f11d0688`, `6d20bf47`).
- **OV3 corrects what the checks find.** The correction returns a patch, which `analysis.apply_census_patch` applies. There are up to two rounds, and `analysis.select_census_result` keeps the first round that passed. Probed on the flight's own population: the flight path passed in round one (`2f19a147`, 69 of 69), and format-labels passed in round two (`92d35a18`).
- **Provider bindings proved.** All six model calls resolve `MODEL_SELECTION` (their role, else `default`) from `sidefx:model-providers`. Before anything is retained, `analysis.verify_model_binding` compares each receipt with the binding. The probe returned `BINDING_HONORED`, six of six on `deepseek/deepseek-flash` (`901e22cb`). A call answered by any other provider stops the flight. A deliberate model change is one row.
- **Acceptance uses the population the flight reads.** That's 69 on today's baseline:
  - 39 projects;
  - 13 tasks (its tracker step adds `oah-owner-objective-clearance`, `oah-provider-bindings` and `oah-agency-acceptance`);
  - 17 direction lines (revision 2, with your provider-binding direction).

  The live tracker reads 52 today.
- **Safe to rerun.** SQL 06 compares each procedure by definition digest before writing anything, and the content writer adds nothing it already holds.

Every step was probed with the exact request or statement the plan carries, and `verify-census2.mjs` replays each bind against those probes (63 of 63 checks pass).

**Your steps:**

1. SQL, preflight then commit each:
   - `sql/ov3-harness-06-owner-objective.sql` (estate). Expect:
     - `base`: each procedure `absent`.
     - `installed`: `matches = 1`.
     - `self_test`: `CENSUS_READY`; `CENSUS_INVALID` naming `owner:2`; `format_labels_gate` `CENSUS_INVALID` with 0 fulfilled; `round_selected` `CENSUS_READY 2`; `unselected_receipt` `BINDING_VIOLATED`; `selected_receipt` `BINDING_HONORED`.
     - `readback`: 3 rows, `matches = 1`.
   - `sql/ov3-harness-07-census-2-plan.sql` (sfx-identity): `plan_revision = 1`, `matches_reviewed_file = 1` (plan `sha256:8b342fbd…`).
2. "Review the current flight plan of agent claude-code-opus-5-5-ov3-harness-census-2."
3. "Fly the current flight plan of agent claude-code-opus-5-5-ov3-harness-census-2." It clears on the review alone and runs its 20 steps to `PROMISE_CLOSED`, with `census.md` delivered.

Still open, by the same review: the acceptance test for transfer of agency is one objective, sent once, that OV3 plans, flies, corrects and closes with no further command. Claude Code still plans census-2, so that test isn't met yet.

## Step 4 (superseded by step 5): the first census flight

**What runs.** The census flight (`flights/census.steps.candidate.json`, plan `sha256:698d488c…`) composes installed capabilities only:

1. It records the tracker change: `oah-long-bind` DONE (the reviewed draft), `oah-scope` superseded, and new tasks `oah-census` and `oah-census-capability`.
2. It declares decision point `ov3-complete-agentic-harness/census`.
3. It reads the specification by digest, with the installed capability ids and the tracker's project ids.
4. `ask-model` writes the census as JSON against a schema. It runs on the selected provider, `deepseek/deepseek-flash` (`MODEL_SELECTION default`).
5. A deterministic SQL check passes or fails the census inside the flight (`CENSUS_READY`). It requires 1 to 30 areas, valid unique ids, and a name, a responsibility and a real source for every area. Each of elaborate planning, self-improvement, multi-agent consensus, control plane and deterministic multi-step execution must be covered. Citations the estate doesn't hold are removed and reported.
6. It retains the **checked** census as `capability-census:ov3-complete-agentic-harness`.
7. It delivers `docs/projects/ov3-complete-agentic-harness/census.md`, a table rendered from the data.
8. It waits for your decision.

**Probed before planning**, each step with the exact statement or request the plan carries:

| Step | Probe runs | Result |
| --- | --- | --- |
| Specification read | `c22895d9`, `85875bd3` | 61,272 bytes, 39 project ids, 669 capability ids |
| `ask-model` | `d69020ed`, `066e0fc0` | `MODEL_RESPONSE_OBTAINED` in 22 s and 24 s (about 3.5K output tokens) |
| Check | `12b42cd6`, `6e1bc08d` | `CENSUS_READY`, 30 areas each |
| Check on a bad answer | `470bb3c1` | `CENSUS_INVALID` (44 areas), with four invented capability citations removed |

A replay of the flight's binds against the real specification read reproduces the probed request byte for byte.

**Your steps:**

1. SQL, preflight then commit each:
   - `sql/ov3-harness-04-census-promise.sql`, on the estate database: `minted` 1 row, `readback` `matches = 1`;
   - `sql/ov3-harness-05-census-plan.sql`, on sfx-identity: `plan_revision = 1`, `matches_reviewed_file = 1`.
2. "Review the current flight plan of agent claude-code-opus-5-5-ov3-harness-census and generate its plan report."
3. "I approve revision 1, plan digest 698d488c222fd96af1d710c870e8145696b3a79f423eaace1731e9732ef72006, of agent claude-code-opus-5-5-ov3-harness-census."
4. "Fly the current flight plan of agent claude-code-opus-5-5-ov3-harness-census." It should pass 9 of 10 steps and wait at the decision.
5. Read `census.md`, then: "Record my decision accept at decision point ov3-complete-agentic-harness/census: …", or `revise` with what to change.
6. "Fly the current flight plan of agent claude-code-opus-5-5-ov3-harness-census." It resumes and closes.

If the check rejects the flight's own census, the flight stops at `check-census` with the reasons in the step result. That's the check working. The fix is a new plan revision that asks again, one SQL file.

## After the census

The features flight is planned from the checked census, in work class `owner-objective`: `design-feature-gherkin` writes one canonical feature per area, each checked, retained and delivered, with no approval or decision. Every provider-dependent scenario names its provider binding by estate identity, the result it must produce and the run evidence that proves it (task `oah-provider-bindings`). Then OV3 builds from them (`oah-build`), and each built capability declares its feature as canonical (`oah-canonical-binding`). Once the census flight closes, its steps become a reusable capability for any specification (`oah-census-capability`).

The Frontier planner plans the first features flight as a bootstrap. Planning is one of the capabilities OV3 is writing features for.

## Not verified yet

- **The census inside the flight.** Every step passed as a probe on the flight's population, but the model's answers vary between runs, so the flight's own checks decide. If neither correction round passes, the flight stops at `select-census` with the feedback, and nothing is retained.
- **Delivering `census.md`.** That needs a running worker router; the scope delivery worked. Without one, the census is still in the estate as `capability-census:ov3-complete-agentic-harness`.
- **The `ov3-teaching` flights are independent.** They can keep flying in parallel.
