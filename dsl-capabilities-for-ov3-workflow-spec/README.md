# DSL capabilities for the OV3 workflow-authority specification

**Status, 2026-11-02:**
- **Part 1 (`dsl-01` to `dsl-03`, the DSL fixes): RUN and verified live.**
  - Compiler: the reviewed revision (run `686c128f`).
  - Author path: the reviewed revision (run `4fa07291`).
  - Specification: 29 constructs and 25 semantics rows (run `549c4381`).
- **The no-drift check: BUILT and PROBED, read-only. Nothing is installed or declared yet.**
  - The check is [check_capability_feature_conformance.body.sql](conformance/check_capability_feature_conformance.body.sql), with its canonical feature [features/check-capability-feature-conformance.feature](features/check-capability-feature-conformance.feature).
  - It rejects the greeting scaffold for specific mismatches and accepts the recorded census provider calls from pinned evidence. Every probed case re-runs from the feature text: 54 of 54.
  - The estate-wide baseline covers all 669 selected capabilities. See [The no-drift check](#the-no-drift-check).
- **Part 2 (OV3 declares `reveal-estate-workflows`): ON HOLD. Do not fly agent `claude-code-opus-5-5-dsl-reveal-draft`.**
  - `dsl-04` minted the promise (run `64121915`), and `dsl-05` recorded plan revision 1 (`sha256:ca193e39…`). Its closure is `NOT_FLOWN`.
  - That revision drafts a DSL that binds four platform ports instead of the `@provider:sql-database-reader` its feature names, and it would keep a scaffold feature.
  - It is superseded. Re-plan it as revision 2 once the compiler's `feature` and `uses provider` lines exist. See [Part 2](#part-2-ov3-declares-reveal-estate-workflows-on-hold).

## Feature first: the canonical features

The owner's rule, 2026-11-02:

> The `.feature` file is the canonical reference that ties to every capability/scenario circuit declaration. The key is establishing no drift and effective validation to prevent drift.

Each capability's canonical feature comes before its DSL, and every declaration, run and acceptance traces to it by identity:

- **The circuit.** The Feature tags carry the circuit's identity: `@capability`, `@root-scenario`, `@scenario`, `@input`, `@input-contract`, `@event`, `@event-authority`, `@outcome`, `@outcome-contract` and `@outcome-terminal`. These are the names the declaration uses.
- **The steps.** Every case uses the circuit's declared Given, When and Then word for word.
- **The cases.** Each Scenario, and each Examples row, is one acceptance case:
  - `@case:<id>` (or an Examples `case` column) is its identity;
  - its json docstring is its exact request;
  - its `operation | path | equals` table holds the assertions, and each row names the operation whose result it reads;
  - `@provider:<capability-id>` names the provider capability that the operation uses.

All four features parse with `@cucumber/gherkin`. The check finds each of them well formed, with pickles equal to `@cucumber/gherkin`'s (run `230e6700`).

| Feature | What it is the reference for | Status |
| --- | --- | --- |
| [features/compile-capability-dsl.feature](features/compile-capability-dsl.feature) | The compiler, with 9 cases. It replaces the greeting scaffold bound today. The check finds it `CONFORMANT` against the declared circuit (run `2c503ff8`), so it can be bound in place of the greeting. | 4 proven (`91a0e162`, `564885e8`, `5de6ee3d`, `42d00088`); 5 not built: the `feature` pin by retained digest, refusal of drift from it, and `uses provider` and `input … from`, with fixture sources in `conformance/fixtures/compile/` |
| [features/check-capability-feature-conformance.feature](features/check-capability-feature-conformance.feature) | The no-drift check, with 57 cases. | 54 probed; 3 not built: provider-binding comparison, the DSL feature pin, and the check inside the author path |
| [reveal-estate-workflows/reveal-estate-workflows.feature](reveal-estate-workflows/reveal-estate-workflows.feature) | The Phase A lens, with 8 cases; `@provider:sql-database-reader` is its provider job. | 8 probed (runs in each case) |

**Feature first, without a circle.**
1. The feature's bytes are retained under their sha256.
2. The DSL pins that digest with a `feature` line, and the compiler reads exactly those bytes, never a binding, which a new capability does not have yet. It refuses drift from them.
3. The author path (declared change `capability-from-dsl`, `model.apply_capability_from_dsl`) declares the document and binds the feature to the new capability version in one transaction. It commits only when the check returns `CONFORMANT`.
4. The first call's evidence then accepts each case.

The check's part of this sequence is built: it reads retained bytes by digest (`conf-retained-bytes-by-digest`) and checks a text before it is bound (`conf-compile-feature-conforms`). The compiler's part and the author path's part are not built.

## The no-drift check

A read-only procedure body (it reads `model.*` and `source.*`, and writes only temporary tables). It was tested as a session procedure through `sql-database-reader`, one call at a time. It has four modes:

| Request | What it checks | Statuses |
| --- | --- | --- |
| `{"capabilityId"}` | The `CANONICAL` feature bound to the **selected** capability version, exactly, with no fallback; bytes verified against their digest | `CONFORMANT`, `DRIFT`, `NOT_BOUND`, `NOT_FOUND` |
| `{"featureText" or "featureDigest", "capabilityId"?}` | That text, or the bytes retained under that digest; with `capabilityId`, against that declaration | `WELL_FORMED`/`MALFORMED`, or as above |
| `{"acceptance", "evidenceText", "featureText"?}` | A flight's steps, or one case, accepted from pinned evidence | `ACCEPTED`, `REJECTED` |
| `{"baseline": {"after", "size"}}` | A page of every selected capability, in bound mode | `BASELINE` |

**The parser is its own.** A tag set belongs only to the next Feature, Rule, Scenario or Examples line. A pickle inherits the Feature, Rule, Scenario and Examples tags, and each Examples row is one pickle with its placeholders filled. Docstring lines are content. The estate's `analysis.read_capability_gherkin_rows` gives an untagged scenario the tag of the scenario before it and does not read `Scenario Outline`, so the check does not use it.

**Comparisons with the declaration.** Each finding names its code and both values:

- The feature's `@capability` and `@root-scenario`.
- Scenario tags in both directions.
- Each identity tag against the declared rows: input, input contract, event, event authority, outcome, outcome contract and terminal.
- Each declared Gherkin step, which the estate keeps in the scenario version's definition.
- The feature version's scenario pins.
- Exact provider ids.
- Case rules: identity, request, assertions, a `$.status` assertion, declared operations and declared outcome variants.

**Acceptance.** A case is proven only by its own call:

- **A flight step.** Its k-th attempt is the flight's k-th dispatch. This join holds only while both counts agree. Each dispatch shares one execution id and carries no step id, so where they don't agree the check refuses with `EVIDENCE_ATTRIBUTION_GAP`.
- **A direct call.** Its request is the case's request, member for member. The run attests that request: the first cell's input digest is the sha256 of the canonical, key-sorted request.
- **Each step** must also show the accepted provider graph digest, the outcome its provider returned, and the step's own expectation.
- **One failure per step.** Each step reports only its first failing layer: tag, provider identity, step binding, attempt, call, graph, outcome, then result.
- **Pinned evidence.** Run retention is bounded, so evidence is pinned by sha256 in `conformance/controls/`.

### Results

| What | Result | Runs |
| --- | --- | --- |
| Negative control: the greeting bound to `compile-capability-dsl` | `DRIFT`: `@event` `compile-capability-dsl` where `compile-capability-dsl-requested` is declared; `@outcome` `compile-capability-dsl-greeting` (declared `compile-capability-dsl`); `@outcome-contract` `…-greeting.v1` (declared `compile-capability-dsl-result.v1`); the 3 declared steps; no cases | `e5dbe9ac` |
| Positive control: the census provider calls of run `bee2eee7` (plan revision 1, `698d488c…`) | `ACCEPTED` from 27 pinned dispatch events. `write-census` is dispatch 778: `ask-model`, `f6563ca4…`, `MODEL_RESPONSE_OBTAINED`. `check-census` is dispatch 934: `sql-database-reader`, `dbb29dc8…`, `READ` with `CENSUS_READY` | `a49f244e` |
| The census contract's 10 negative controls, plus another step, another attempt and tampered bytes | Each `REJECTED` with exactly its own code | `a49f244e` |
| Reveal: the STALE run as proof of `reveal-stale-pin` | `ACCEPTED` | `2c503ff8` |
| Reveal: the RESOLVED run offered as that proof; the STALE assertion removed | `REJECTED` (`EVIDENCE_REQUEST_MISMATCH`; `CASE_STATUS_UNASSERTED`), and the text without the assertion is `MALFORMED` | `2c503ff8` |
| 25 one-line drift fixtures against the declared circuit of `compile-capability-dsl` | The base `CONFORMANT`; each other fixture `DRIFT` with exactly its own code | `f8aa9214` |
| All 54 probed cases, run from the feature text with the final body | 54 of 54 | `c2d6f5b5`, `0c9bcf2f`, `e08afb93`, `6afa6b38` |

**Estate-wide baseline** (runs `a864cec2`, `fca3a2f7`, `4c0b5e30`, same as the first pass):

- **669 selected capabilities.** 451 have a `CANONICAL` row for some version, 406 for their selected version, and `model.estate_capability_feature` has 489 rows. (The earlier claim that "489 capabilities carry a CANONICAL feature" was wrong.)
- **263 `NOT_BOUND`.** 218 have no feature row, and 45 are bound only at another version; `compose-implementation-design` and `argv-provider` are among them.
- **406 `DRIFT`, 0 `CONFORMANT`.**
  - 375 of the 406 bound features are the greeting scaffold (run `54ab1386`).
  - None uses `@case` or `@provider`.
  - Identity drift: `OUTCOME_IDENTITY_MISMATCH` 390, `EVENT_IDENTITY_MISMATCH` 389, `OUTCOME_CONTRACT_MISMATCH` 380, `INPUT_CONTRACT_MISMATCH` 177, `INPUT_IDENTITY_MISMATCH` 66.
  - `SCENARIO_STEP_NOT_IN_FEATURE` in 396 capabilities (1,183 steps).
  - `FEATURE_PIN_STALE` 27, `SCENARIO_NOT_IN_FEATURE` 10.
  - Six capabilities lack only cases, `execute-declared-capability` among them.

What this says for the compiler work: the scaffold binds a greeting feature when a capability is established, and nothing replaces it when the DSL authors the real circuit. The `feature` line and the check inside the author path close that.

### How to re-run it

`node conformance/run-check.mjs features/check-capability-feature-conformance.feature <outBase> <@cucumber/gherkin node_modules>` re-runs every probed case from the feature, in sequential batches. It needs `SFX_SH`, a script that runs `sfx-api capability observe sql-database-reader --input - --json --auth user` with the request file as stdin. `node conformance/make-controls.mjs <dir>` rewrites the controls and fixtures and their digests (`conformance/controls/manifest.json`).

## Part 1: the DSL fixes

This folder first closed the four DSL gaps found on 2026-11-02 when we checked whether the capability DSL can declare what `ov3.estate-workflow-discovery.v1` needs. The other packs in this repository (`ov3-teaching`, `ov3-agentic-harness`) are not touched.

### What changes

| # | Gap | Fix | Where |
| --- | --- | --- | --- |
| 1 | `route`, `broadcast` and `join` compiled without `semanticProgress`, so a faithful lens would hold every DSL route except `recur` | Every compiled transition carries it, following the law the estate's declared routes already use: selection into a terminal scenario is `terminating`, any other selection is `narrowing`; broadcast `expanding`; join `converging`; failure collected at its join slot `converging`; recurrence `recurring` (unchanged) | `analysis.compile_capability_dsl` |
| 2 | Five unsafe lines compiled with no error | Each now refuses with a declared `DSL_*` code: `join` without `broadcast` (`DSL_REQUIRED_MISSING`); routes or `invoke-scenario` operations that form a cycle, a self route included (`DSL_VALUE_INVALID`); an `invoke-scenario` target the document doesn't declare (`DSL_VALUE_INVALID`); a second root scenario (`DSL_DUPLICATE_ID`); `:terminal` on a scenario's `variants:` (`DSL_VALUE_INVALID`) | `analysis.compile_capability_dsl` |
| 3 | `provider binding <id> <json>` was delivered on 2026-10-15 and later lost from both the compiler and the author path | Restored as the specification states it. The content is the JSON without the whitespace outside strings, addressed by sha256 over its UTF-8 bytes. `"@provider-binding:<id>"` in a config becomes that digest, and an unknown name refuses. The compile result always carries `providerBindings[]`, which its own contract requires. The author path mints each binding as raw content before declaring the document | `analysis.compile_capability_dsl`, `model.apply_capability_from_dsl` |
| 4 | The specification listed 19 constructs and none of the 13 lines added since 2026-10-20; the teaching skill misstated the grammar | The specification lists all 29 constructs and 25 document-semantics rows. Corrected texts of the two affected teaching skills are in `skills/` | `capability-dsl-specification.v1`; `skills/` |

The procedure changes are additive. The compiler diff (`changes/`) adds 101 lines and replaces 5, the routing emission lines that gain `semanticProgress`.

### Step 1: your SQL

Run each file whole, in one session, against the estate database (`sfx-estate-database`).

| Order | File | What to expect |
| --- | --- | --- |
| 1 | `sql/dsl-01-test.sql` (about 10 minutes, runs once, installs nothing) | `base`: both installed digests equal the expected ones. Then the author path's own result sets, including one `provider_binding_minted` row. `checks`: every row `passed = 1`. `verdict`: `PASSED`, with 40 probe checks, 10 regression checks (1 summary + 9 capabilities) and 4 author checks |
| 2 | `sql/dsl-02-install-compiler-and-author-path.sql`, then `.commit.sql` | `base`: installed = expected. `verify`: `compiler_body` = `compiler_expected`, `author_path_body` = `author_path_expected`, `smoke_status` `COMPILED`, `smoke_transitions` 11, `smoke_with_semantic_progress` 11, `smoke_has_provider_bindings` 1 |
| 3 | `sql/dsl-03-specification.sql`, then `.commit.sql` | `base`: constructs 19, semantics 15, both `differing` 0, vectors 8, compiler = the dsl-02 revision. `capability_dsl_specification`: `REPLACED`, constructs 19 → 29, semantics 15 → 25. `readback`: 29 and 25, both `differing` 0, vectors 8, `vectors_unchanged` 1 |

How the files protect the estate:

- **The test locks nothing.** `dsl-01` runs the reviewed bodies as session-only temporary procedures. A single compile takes about 22 s, so testing inside the install transaction would hold the procedures' schema lock for minutes and block every DSL compile in the estate. The test's only write, the author-path probe, runs inside a transaction that always rolls back, and the test checks that nothing remains.
- **The installs are short, guarded and verified.** `dsl-02` and `dsl-03` stop before any change if a base has moved. Inside the transaction they verify that the installed bodies and the specification are exactly the reviewed ones; otherwise nothing is kept. `dsl-02` holds the lock for seconds plus one 22 s smoke compile.
- **Each install has a twin.** The preflight (`.sql`) and its commit twin are byte-identical except the banner and the last statement (`manifest.json`, `twinParity`).

No OV3 step is needed to complete these changes.

### What the evidence is

Every rule rests on live estate reads made on 2026-11-02 through `sfx-api capability observe ... --auth user`. Repository files were read only as hints, and nothing in them was taken as authority. That includes the `sfx-embody` migrations dated 2026-10-17. Where a repository file and the live estate could disagree, the live read decides.

| Fact | Live source |
| --- | --- |
| Compiler base `sha256:6aee2a7b…`; its full grammar and the five lines it accepts | `read-declared-object-source` runs `916ade66`, `8629111b`; compile probes `b8dbe268`, `bd30bcf3`, `bf8002b7`, `27ba6a8d`, `9c7731d1` |
| `provider binding` refused (`DSL_SYNTAX`) though the specification lists it | compile run `924c7bad`; `read-capability-dsl-specification` run `67588f36` (19 constructs, `sha256:bd9a44ae…`) |
| Author path base `sha256:24112507…` mints nothing | run `95b858a8` |
| Raw content is stored by digest inside a writer, as `model.retain_capability_dsl_source` does | run `d4417fb6` |
| `source.content_object` columns; the V8 binding object minted on 2026-10-15 is a live row; 582 retained sources for 291 capabilities | run `87cdb622` |
| The restored content rule reproduces that object's digest `sha256:bde28572…` from the live V8 vector | checked offline against run `67588f36`; `dsl-01` checks it live |
| Declared routes: 105 in 15 capabilities, 76 without `semanticProgress`. The ones that carry it use `terminating`, `expanding`, `converging`, `recurring` | run `4cbc0711` |
| No installed module derives or validates the values | run `b077995f` |
| No declared CONTRACT, AUTHORITY or SCHEMA mentions `narrowing` | run `e85e98d5` (empty result) |
| Only 9 in-estate capabilities have topology lines; none uses `provider binding`, `invoke-scenario`, a scenario `:terminal`, a second root or `join` without `broadcast`; no `route` cycle | runs `b9019be8`, `5d455738` |
| The specification writer replaces only constructs, document semantics and vectors, and vector refusals must be `DSL_*` codes, so the new refusals reuse the declared codes | run `ea14c8a0` |
| `spec-capability-declaration` and `spec-scenario-topology` are not filed (`missing: true`) | runs `36268ad6`, `57669394` |

**`narrowing` is the one value no live row carries yet.** The kernel's transition schema isn't readable through any declared surface. The value comes from the SDA kernel source (`scenario-driven-architecture` HEAD `cd4fcf5`, `kernel/schemas/scenario-transition.v2.schema.json`, whose `semanticProgress` enum has been unchanged since 2026-08-16). I could not tie that commit to the deployed kernel digest `1f070fac…`. The first DSL capability with a selection into a non-terminal scenario that runs will be the live proof.

### After the install

- **Existing capabilities keep routes without `semanticProgress` until they are re-authored.** That covers the 9 DSL-authored capabilities with topology lines (`admit-api-run`, `compose-implementation-design`, `concurrent-fanout-demo`, `propose-capability-circuit-chunked`, `fly-flight-step`, `probe-recurrence`, `pursue-objective`, `request-capability-from-objective-v3`, `request-capability-from-objective-v5`) and any hand-minted envelopes. Until then, `assess-capability-dsl-parity` reports `DRIFT` on their `semanticProgress` paths. Re-authoring `fly-flight-step` and the OV3 capabilities is a deliberate later step, not part of this change.
- **The skills:** `skills/` holds corrected texts of `spec-capability-declaration.md` and `spec-scenario-topology.md`. They replace the files of the same names in `ov3-teaching/skills/`. Neither skill is filed yet, but the recorded plans of `ov3-teach-spec-skills-1` and `-2` embed the old text, so those plans need re-recording before they fly. That pack is the other agent's, so I left it alone.

### Not changed here

- **The specification's vectors V1–V8 are stale.** They still expect `outcomeId = <scenarioId>`, while the compiler has emitted `<scenarioId>-outcome` since 2026-10-19 (V8 `expectedDocument`, run `67588f36`; compiler source line 704). The drift predates this change, and `dsl-03` leaves the vectors as they are. Refreshing them is a follow-up.
- **`fail-<leg>` transitions carry variant `SUCCESS`.** This is known defect 1 of task `ena-authoring-conformance-by-construction`.
- **`recur` without `max` is bounded at 2147483647.** Five live capabilities use it, OV3's v3 and v5 among them; a faithful lens treats them as unbounded.
- **Some needs have no DSL line:** provider slots, product dependencies, routes across capabilities, authorization, and webhook or poll entries. Separate writers exist for slots, providers, contracts and data sources. The other four have no carrier.
- **The specification's `validation` section can't change.** The installed writer can't update it, so its six code descriptions don't mention the new refusals.

### Files

| Path | What it is |
| --- | --- |
| `sql/` | The SQL files of Part 1 (`dsl-01` to `dsl-03`) and Part 2 (`dsl-04`, `dsl-05`) |
| `source/` | Base bodies as read live, and the revised bodies |
| `changes/` | Unified diffs, base to revised |
| `probes/` | The DSL sources the test and the smoke check compile |
| `specification/grammar.json` | The 29 constructs and 25 semantics rows `dsl-03` submits |
| `skills/` | Corrected skill texts for the `ov3-teaching` pack |
| `manifest.json` | Digests of every SQL file, the revised bodies and the grammar, plus twin parity |
| `features/` | The canonical features of `compile-capability-dsl` and `check-capability-feature-conformance` |
| `conformance/check_capability_feature_conformance.body.sql` | The no-drift check's procedure body |
| `conformance/run-check.mjs` | Runs cases from a feature or a list, read-only, one call at a time |
| `conformance/make-controls.mjs` | Writes the acceptance records, negative controls and drift fixtures, pinned by sha256 |
| `conformance/controls/` | Pinned evidence (census run `bee2eee7`, reveal runs `f6b88ab2` and `d1175d72`), acceptance records, negative controls, `manifest.json` |
| `conformance/fixtures/` | Parser fixtures, drift fixtures, the reveal feature without its STALE assertion, and the compile fixtures of the not-built lines |
| `reveal-estate-workflows/` | The Phase A capability: canonical feature, specification, draft DSL, procedure |

## Part 2: OV3 declares `reveal-estate-workflows` (on hold)

The capability is to be declared through the OV3 network. OV3's own pipeline writes the draft, plans the build, installs the procedure, declares the capability and proves its first call. Your SQL only records the promise and the plan, the two planner writes OV3 can't make itself.

`reveal-estate-workflows` is the specification's Phase A capability (section 5, work package W3). It is a read-only workflow lens over one capability:

- **Entries** come from declared entry authority only.
- **Transitions** are admitted fail-closed: known topology, both endpoints resolved, a declared selecting variant, `semanticProgress` by the estate law, and a finite recurrence bound. Anything else is held with a finding and never traversed.
- **Each workflow** is the closure of one admitted entry over admitted transitions only.

The wildlife capabilities are Phase B. The specification starts them only after Phase A is admitted.

### Where it stands

- **The recorded flight.**
  - `dsl-04` minted promise `dsl-reveal-estate-workflows-draft` (run `64121915`).
  - `dsl-05` recorded plan revision 1 of agent `claude-code-opus-5-5-dsl-reveal-draft` (`sha256:ca193e39…`). The flight's closure is `NOT_FLOWN`.
- **Do not fly or approve revision 1.** Its draft step would bind the four platform ports instead of `@provider:sql-database-reader`, and it would leave a scaffold feature bound.
- **Revision 2.** Re-plan it under the same planner agent once these three things exist:
  1. The compiler's `feature` line (the pin by retained digest) and its `uses provider` line.
  2. The check inside the author path.
  3. The bytes of `reveal-estate-workflows.feature`, retained under their digest.
- **First call.** It must then accept every case of the feature from its own call.

### What OV3 will be given

[reveal-estate-workflows/specification.md](reveal-estate-workflows/specification.md) is the specification OV3's `draft-capability-from-spec` reads. It carries:

- **The DSL**, in the four-port form the drafting step requires today. It compiles with no diagnostics (run `91a0e162`), and it drifts from the canonical feature until it is re-expressed with `uses provider`.
- **The procedure** `analysis.reveal_estate_workflows`. It reads only `model.*` and `source.*`, and never writes.
- **The proof** the first call must meet: case `reveal-resolved` of the feature, `{"capabilityId":"dispatch-pair-demo"}` with `$.summary.signature = entries=1/1;edges=6/6;reached=4;terminals=1`.

The procedure body ran read-only against the live estate, through `sql-database-reader` with each case's request bound as `@input`. Each row is a case of the feature:

| Case | Status | `summary.signature` | Run |
| --- | --- | --- | --- |
| `reveal-resolved` | `RESOLVED` | `entries=1/1;edges=6/6;reached=4;terminals=1` | `f6b88ab2` |
| `reveal-held-selections` | `PARTIAL_WITH_HELD_GAPS`: 3 selections without `semanticProgress`, 1 unbounded recurrence | `entries=1/1;edges=0/4;reached=1;terminals=0` | `3f81051e` |
| `reveal-held-fan-out` | `PARTIAL_WITH_HELD_GAPS`: declared before the compiler fix | `entries=1/1;edges=0/6;reached=1;terminals=0` | `e8c7ed61` |
| `reveal-no-transitions` | `RESOLVED`: no routing | `entries=1/1;edges=0/0;reached=1;terminals=1` | `7554ea8c` |
| `reveal-entry-without-cli-input` | `NOT_DECLARED`: no CLI input, so no entry, though all 16 transitions are admitted | `entries=0/1;edges=16/16;reached=0;terminals=0` | `04e36e84` |
| `reveal-leg-is-not-an-entry` | `NOT_DECLARED`: a leg is not an entry | `entries=1/1;edges=6/6;reached=0;terminals=0` | `09b0b2f1` |
| `reveal-stale-pin` | `STALE` | | `d1175d72` |
| `reveal-not-found` | `NOT_FOUND` | | `bec5e723` |

### Your SQL

| Order | File | Database | State |
| --- | --- | --- | --- |
| 4 | `sql/dsl-04-reveal-promise.sql`, then `.commit.sql` | estate | RUN: the promise is minted |
| 5 | `sql/dsl-05-reveal-plan.sql`, then `.commit.sql` | `sfx-identity` | RUN: revision 1 is recorded and superseded. Revision 2 needs a new plan file. |
