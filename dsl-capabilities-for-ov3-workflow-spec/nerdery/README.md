# Nerdery wildlife application: the citizen slice through SideFX

**Status, 2026-11-03, 01:15 EST:**
- **Declared in the estate, but not working yet: the first live call failed. The repair is two SQL files and one OV3 flight ([below](#the-repair-two-files-and-one-flight)).**
- **What happened on 2026-11-02:**
  - You ran `fast-1` at 22:10 EST and `fast-2` at 22:11.
  - Flight `9810b9af` flew all 20 steps from 22:15 to 22:30. It installed and declared the check, then declared the eight capabilities and read each one's feature pin back.
  - The wildlife store is installed (14 tables, 10 procedures). Avery has collected nothing yet.
- **What failed:**
  - The first live call, as Avery (run `53ad6ca6`), failed at the capability's composing statement with `DECLARED_PROVIDER_CONFIGURATION_VALUE_MISSING:commandTimeout`.
  - The compiler's `uses provider` expansion wrote its composing and outcome statements without the `commandTimeout` that `sfx-estate-run-statement-port.v1` requires.
  - The estate has 39 declared documents on that port. Only nine lack the timeout: the eight and the check.
  - This is a defect in my Part 3 compiler. The cases compiled the documents and ran the mechanics, but never ran a compiled document end to end.
- **What the repair changes:** the repaired compiler compiles each of the eight unchanged sources to its declared document plus the two timeouts, and nothing else (read-only, runs `a170c9ba` to `9e276d31`).
- **Still true from the read-only build:**
  - All 77 cases pass against the wildlife mechanics, run as session copies on sfx-identity.
  - All eight sources conform to their retained canonical features.
  - Your live session verifies as Avery, and the same session presented under another principal is refused.

The canonical features are the owner-review candidates in [nerdery-canonical-features](../../nerdery-canonical-features/README.md), which belong to the other agent. That folder is read only, and the finalized copies are in [features/](features/).

## What the slice is

The handoff's first executable interview slice:

1. Browse, then read a detail, while the animal is uncollected (restricted).
2. Upload a photo and record an encounter.
3. Browse and read the detail again (unlocked).
4. Record a second individual of the same animal.
5. View my individuals, save a team, and view home.
6. The refusals: a seven-member team, a citizen catalog addition, and a retry that replays.

| Capability | Cases | Operation | Variants |
| --- | ---: | --- | --- |
| `nerdery-browse-animal-collection` | 11 | `.browse` | LISTED, REFUSED |
| `nerdery-view-animal-definition` | 6 | `.view` | VISIBLE, REFUSED |
| `nerdery-upload-encounter-photo` | 5 | `.upload` | UPLOADED, REFUSED |
| `nerdery-record-animal-encounter` | 17 | `.record` | RECORDED, REFUSED |
| `nerdery-view-collected-animals` | 6 | `.view` | LISTED, REFUSED |
| `nerdery-set-animal-team` | 11 | `.set` | SAVED, REFUSED |
| `nerdery-view-wildlife-home` | 4 | `.view` | VISIBLE, REFUSED |
| `nerdery-add-animal-definition` | 17 | `.add` | ADDED, REFUSED |

## How it works

1. **The request.** The browser or CLI sends the case JSON. A declared API operation binds the caller from the session the frontdoor validated (`$caller.principalId`, `$caller.sessionId`). The capability input is `{caller, request}`.
2. **The capability.** It is declared feature first. Its DSL pins the retained bytes of its canonical feature, and its one operation `uses provider sql-database-reader` with `EXEC wildlife.serve @operation=N'<capability>',@input=@input` on sfx-identity.
3. **The caller check.** `wildlife.serve` verifies the session against `[identity].session` and `[identity].principal`, and maps the principal to its wildlife user. An unknown session, a revoked or expired one, or one presented with another principal makes the caller anonymous. So a run admitted through `POST /sfx/v1/runs` with someone else's `principalId` is refused `AUTHENTICATION_REQUIRED`.
4. **The operation.** `wildlife.invoke_operation` runs the operation's procedure in one transaction. A store that can't be read or written answers the operation's own storage refusal, and nothing is kept.
5. **The data.** It lives in schema `wildlife` (14 tables). Identities are case-sensitive and email is unique without regard to case. A photo's bytes are kept under their sha256.

These are the existing mechanics, with no new kernel, admission store or identity registry. The same pattern carries the estate's flight recordings and agent memories: `sql-database-reader` statements on sfx-identity that take the principal the caller proves.

**The proposed decisions are implemented as written.** All of them (D04 search, D05 private resources, D06 team membership, D07 retry identity, D10 media, D13 expected revision, D14 ordering) are still marked PROPOSED in [scope-and-decisions.md](../../nerdery-canonical-features/review/scope-and-decisions.md). Changing one changes the case's feature, so its digest and declaration change too.

## The repair, round 2: two files and one flight

Round 1 (`repair-1`, `repair-2`, flight `c0cd676c`) gave the composing and outcome statements their timeout, and has run. The next live call (run `d37c4351`) then failed with `DECLARED_PROVIDER_TARGET_MISSING:vault`:
- The kernel runs the estate's PORT definitions.
- The compiled open steps used `sfx-vault-reference-open-port.v1`, which replaces the vault and credential reference with the secret.
- Every other statement chain in the estate uses `sfx-vault-reference-carry-port.v1` and passes them on.

The repaired compiler binds the carrying port. Its chain now equals `ask-system-one`'s runtime ports one for one (runs `fa3d0621`, `b50b9384`).

Run each file whole, in one session. The preflight `.sql` is optional.

| Order | File | Database | What to expect |
| --- | --- | --- | --- |
| 1 | `sql/repair-3-estate.commit.sql` (under a minute) | estate | `base`: `compiler_body` = `compiler_expected` (`sha256:7197986a…`). `verify`: `compiler_body` = `compiler_expected` (`sha256:a437984d…`), `smoke_document` = `smoke_expected` (`sha256:85386b4e…`), `compose_open_platform` and `outcome_open_platform` `sfx-vault-reference-carry-port.v1`, both timeouts 30. `minted`: 1 row. `readback`: `retained` 1 |
| 2 | `sql/repair-4-identity.commit.sql` (a few seconds) | `sfx-identity` | `base`: `current_plan` `sha256:31a62748…`. `plans`: `plan_revision` 3, `matches_reviewed_file` 1 |

Then tell OV3, one sentence at a time:

1. "Review the current flight plan of agent claude-code-opus-5-5-nerdery-slice and generate its plan report."
2. "I approve flight plan digest sha256:d718a828997c60c867ae0b34c7202fc20c0f51b325dd4077e4ea351cb8605d56 of agent claude-code-opus-5-5-nerdery-slice."
3. "Fly the current flight plan of agent claude-code-opus-5-5-nerdery-slice."

The flight ([flights/repair-2.steps.json](flights/repair-2.steps.json)) re-declares the eight and the check from their unchanged sources. It proves each by the digest of its stored document (`repair-2-compile-cases.json`).

**Already run, don't run again:**
- `fast-1` and `fast-2`. Their guards would stop them anyway: the compiler has moved, and the schema exists.
- `nrd-01` to `nrd-03`, and `dsl-06` to `dsl-11`, are superseded. `nrd-03` would replace the plan under the same agent.

## The presentation

There are eight declared pages: Overview, Collection, Animal, Capture, My animals, Team, Home and Refusals. They are `ui-page-definition.v1` documents in [ui/pages/](ui/pages/), served by the SideFX shell at `https://sidefx-web-staging.azurewebsites.net/circuit/wildlife`.
- Each page opens on its capability's circuit, read from the estate.
- A capability runs only when you submit a form or press a button. The caller comes from your signed-in session, and the capability verifies it against `[identity].session`.
- The results are the capabilities' own outputs. Withheld fields show as dashes, refusals are named, and every run links to its circuit.
- No business rule lives in a page.

Three things make them live:
1. The repair, round 2, above.
2. `sql/pages-1-estate.commit.sql` on the estate, a few seconds. It stages and promotes the eight pages through `sidefx_ui.stage_ui_page` and `promote_ui_page`, then reads each one back. Expect `verify`: 8 rows, `digest_matches` 1, `read_status` READ.
3. The shell change in sfx-platform: PR #85, merged as `7c3ea2f`. The frontend release deployed it to sidefx-web-staging on 2026-11-03 at 07:13 EST, and staging serves the merged `page-runtime.js` byte for byte.

That shell change adds:
- bindings nested in an observe input;
- a page-local `run` source with a run's output;
- `map` projections on reads;
- `when.result` gating;
- form value kinds, including a file read as base64;
- declared-component styles.

Opening a page never admits a run, and nothing polls.

### The photo of a collected animal

Each My animals card has a **See the photo** link. It opens `/circuit/wildlife-individual?encounter=<id>`, where **Show the photo** runs `nerdery-view-collected-animal`. The page then shows your stored photo, checked against its digest, next to what you recorded.

| Step | What | Where |
| --- | --- | --- |
| Feature | [features/nerdery-view-collected-animal.feature](features/nerdery-view-collected-animal.feature), 6 cases over [fixtures/cases/](fixtures/cases/) | all met read-only, run ef3510aa |
| DSL | [dsl/nerdery-view-collected-animal.dsl](dsl/nerdery-view-collected-animal.dsl) | COMPILED read-only, run 2e4b4b4c, document `sha256:e6f62d7e…` |
| Mechanics | `wildlife.view_collected_animal`, plus one dispatch line in `wildlife.invoke_operation` | [wildlife/wildlife.procedures.sql](wildlife/wildlife.procedures.sql) |
| Estate | [sql/photo-1-estate.commit.sql](sql/photo-1-estate.commit.sql) retains the feature and the promise, compiles the DSL, and publishes wildlife-mine revision 2 and wildlife-individual revision 1 | owner SQL |
| Identity | [sql/photo-2-identity.commit.sql](sql/photo-2-identity.commit.sql) installs the mechanics, smoke-calls them, and records plan `sha256:aa443b90…` | owner SQL, after photo-1 |
| Flight | [flights/individual.steps.json](flights/individual.steps.json) declares the capability and proves its stored document | OV3 |
| Shell | sfx-platform PR #86 lets a figure's `src` be a digest-checked image data URL, and adds the map's `concat` and `encode` | merge deploys staging |

[make-individual.mjs](make-individual.mjs) generates all of it.

[ui/make-pages.mjs](ui/make-pages.mjs) writes the pages and validates each one with the shell's own `validatePage`. Since pages-1 has run, it no longer writes SQL. [ui/preview-pages.mjs](ui/preview-pages.mjs) renders them in the shell's own files in Chromium and walks the journey. Only the transport is stubbed: it serves the mechanics' real outputs from the 77-case run. [ui/screens/](ui/screens/) holds the screens it captured. There, the hero circuits show their pending state, because only the gateway serves the database scene.

## The interview journey in the Explorer

The journey also runs in the SideFX Explorer on the staging web host. [journey/README.md](journey/README.md) gives each step's capability, input and expected result. Every run plays live on the circuit, with its result.

`node nerdery/demo/run-journey.mjs --check` checks the capability path from the CLI: reads, two refusals and a forged caller, changing nothing. CLI evidence proves the path, but it is not the demo.

## Evidence

| What | Result | Runs |
| --- | --- | --- |
| The fast path, live | compiler and author path bodies are the reviewed ones; 14 tables and 10 procedures; plan revision 1 `sha256:8ffc4ac2…`; flight `9810b9af` COMPLETE, 20 of 20 steps passed on their first attempt; 9 capabilities declared, 11 texts retained | `371426cf`, `bfb09aa2`, `56124b1f`, `1e495921`, `cb3628a6` (flight run `4c5b1567`) |
| The first live call | FAILED at `nerdery-browse-animal-collection.browse-compose`: `DECLARED_PROVIDER_CONFIGURATION_VALUE_MISSING:commandTimeout` | `53ad6ca6` |
| The cause, across the estate | 39 declared documents use `sfx-estate-run-statement-port.v1`; only these nine lack `commandTimeout`. `ask-system-one` has the same compose, invoke and outcome shape with `commandTimeout` 30 on both statements. 90 working bindings use the same nested invocation | `e2eb731c`, `3e991ec1`, `779c19b8` |
| The repaired compiler, read-only | the eight and the check COMPILED with `commandTimeout` 30 on both statements; each document equals its declared one apart from those two values; the compile feature's three provider cases met | `a170c9ba`, `5a4126dd`, `e9610d68`, `8dc9fddc`, `db3ee8d9`, `862af3e0`, `fa52a79b`, `9e276d31`, `bca6d319`; declared documents `8c7503ae`; `13878374`, `80ada4cd`, `786baf10` |
| Every batch of `repair-1` and `repair-2` compiles; nothing runs | all | `4e649cbd`, `da376a51` |
| All 77 slice cases, as the fixture's subject, with state digests and read-back ([conformance/run-cases.mjs](conformance/run-cases.mjs)) | 77 of 77 | `84ff8efb`, `c901e190`, `8e66151b`, `7837a8f1`, `b28d02da`, `25e64090` |
| Each DSL against its retained feature ([compile-cases.json](compile-cases.json)) | 8 of 8 COMPILED | `e850ff59`, `996453fc`, `8f6cef9a`, `ad02949f`, `9afb0f75`, `a29350c3`, `a01f53b3`, `4a175b03` |
| Every batch of `nrd-01` to `nrd-03` compiles; nothing runs | all; the first `nrd-01` pass caught one DECLARE error, fixed and recompiled | `4314f467` (`nrd-01`), `6ea275cf` (`nrd-02`), `f0ca2aae` (`nrd-03`) |
| `nrd-01`'s seed and smoke calls against session copies | seed counts as expected; 9 of 9 smoke | `cac0545a` |
| Your live session through `wildlife.serve` | Avery LISTED; the same session with another principal REFUSED `AUTHENTICATION_REQUIRED` | `38c7990d` |
| The estate facts the design rests on | the reader connects to sfx-identity as `dbo`; sessions last 24 h; the frontdoor binds `$caller` only into declared operations' inputs; `POST /sfx/v1/runs` passes any input; no module reads a caller from session context | live reads of 2026-11-02 |

The bridge runs storage faults as real failures of the store: a refused write (a constraint that rejects every row) for `FAIL_BEFORE_COMMIT`, and an absent table for `UNAVAILABLE`. It never sets a flag in the procedures.

## Still open

- **The browser path.** [api/wildlife-operations.json](api/wildlife-operations.json) drafts the eight operations to add to `sidefx-api-interface.v1`, for example `POST /sfx/v1/wildlife/encounters`. Each binds `caller` from `$caller` and `request` from `$body`, `$path` or `$query`. The writer of that shared authority is still to be identified, so it isn't installed. Until then the slice runs through `sfx-api` runs with the caller in the input, which the capability verifies. No presentation pages exist yet.
- **The other nine MVP capabilities.** These are registration and sign-in through DNR identity, access resolution, the remaining catalog and attribute changes, and the language presentation.
- **The offline candidates.**
- **Measured quality.** WCAG 2.1 AA, browsers, responsive layout, and load up to 2,000 concurrent users each need their own evidence.

## Files

| Path | What it is |
| --- | --- |
| `features/` | The eight finalized canonical features |
| `dsl/` | Their feature-first DSL sources |
| `wildlife/wildlife.tables.sql`, `wildlife/wildlife.procedures.sql` | The store and its mechanics, the reviewed texts |
| `conformance/run-cases.mjs` | The test bridge: cases read-only on session copies, with state digests and read-back |
| `make-slice.mjs`, `make-sql.mjs`, `make-fast-path.mjs`, `make-repair.mjs` | Generators: finalized features and DSL; owner SQL and the declaration plan; the two-file fast path built from their validated batches; the runtime repair |
| `repair-compile-cases.json` | Each declared source compiled read-only by the repaired compiler, with the document digest its re-declaration must store |
| `sql/` | `repair-1-estate` and `repair-2-identity` (run these); `fast-1-estate` and `fast-2-identity` (run on 2026-11-02); `nrd-01` to `nrd-03` (superseded). Each is a preflight and a byte-identical commit twin |
| `flights/repair.steps.json` | The repair flight's promise, objective, steps and digest (`fast-path.steps.json` has flown; `slice-declare.steps.json` is superseded) |
| `demo/run-journey.mjs` | The live interview slice |
| `api/wildlife-operations.json` | Draft API operations for the browser path |
| `manifest.json`, `slice.manifest.json`, `manifest.fast.json`, `manifest.repair.json` | Every digest and the twins' parity |
