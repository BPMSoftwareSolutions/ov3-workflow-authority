# Nerdery wildlife application: the citizen slice through SideFX

**Status, 2026-11-02, 21:50 EST:**
- **Built and proven read-only; your SQL is ready. Nothing is installed yet.**
- All 77 cases of the eight slice capabilities pass against the wildlife mechanics, run as session copies on sfx-identity. Each refusal leaves the stored state unchanged, and each applied write is read back from storage as returned.
- All eight DSL sources compile against the retained bytes of their finalized canonical features. For a pinned source this means the no-drift check found no drift.
- Every batch of the SQL compiles. The seed and the smoke calls pass against session copies. Your live session verifies as Avery, and the same session presented under another principal is refused.

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

## Your SQL, then OV3

**First, Part 3 of the DSL work** ([../README.md](../README.md#part-3-feature-first-installed)): `dsl-06` to `dsl-10`, then the check's build flight. The declarations below need its `feature` pin, its `uses provider` line and the installed check. Without them each declaration refuses `CHECK_NOT_INSTALLED`.

Run each file whole, in one session: the preflight `.sql`, then its `.commit.sql`.

| Order | File | Database | What to expect |
| --- | --- | --- | --- |
| 1 | `sql/nrd-01-wildlife-store` | `sfx-identity` | `base`: `wildlife_schema_id` NULL, `identity_tables` 1, `owner_principal_active` 1. `verify`: tables 14, procedures 10, `digest_mismatches` 0, `seed_counts` = `seed_expected`, every `digest_matches` 1. `smoke`: every `passed` 1 |
| 2 | `sql/nrd-02-slice-features-and-promise` | estate | `base`: installed = expected. `minted`: 9 rows (the eight features and the promise). `readback`: `retained` 1, nine times |
| 3 | `sql/nrd-03-slice-declare-plan` | `sfx-identity` | `guard`: 4 parameters, owner active. `plans`: `plan_revision` 1, `matches_reviewed_file` 1, `plan_digest` `sha256:d651f4fbd376338b2ca2ef41f4d42de63c23c8ef0f0f21e05775d6100c4d8dcd` |

Then tell OV3, one sentence at a time:

1. "Review the current flight plan of agent claude-code-opus-5-5-nerdery-slice and generate its plan report."
2. "I approve flight plan digest sha256:d651f4fbd376338b2ca2ef41f4d42de63c23c8ef0f0f21e05775d6100c4d8dcd of agent claude-code-opus-5-5-nerdery-slice."
3. "Fly the current flight plan of agent claude-code-opus-5-5-nerdery-slice."
4. "Read the flight closure of promise nerdery-citizen-slice-declare."

The plan is in work class `owner-objective`. Sentence 2 is needed only while `flight-clearance-policy:owner-objective` is not declared, which is the case today. The flight ([flights/slice-declare.steps.json](flights/slice-declare.steps.json)) declares each capability through `capability-from-dsl`. The author path commits each one only when the check finds its binding `CONFORMANT`. The flight then reads each declared feature pin back.

## The live demo

```
sfx-api login
node nerdery/demo/run-journey.mjs
```

[demo/run-journey.mjs](demo/run-journey.mjs) reads your session (`sfx-api whoami`) and runs the slice as Avery through the declared capabilities, 13 calls in all. Each call prints its run id beside the result fields that matter: the restricted animal before collection, the unlocked one after, the two individuals, the saved team on home, and the three refusals. Read any run with `sfx-api run <id> --json --events`. Encounter ids carry a timestamp, so the script can run again.

Your session expires at 10:04 EST on 2026-11-03. Sign in again before the interview.

## Evidence

| What | Result | Runs |
| --- | --- | --- |
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
| `make-slice.mjs`, `make-sql.mjs` | Generators: finalized features and DSL; owner SQL and the declaration plan |
| `sql/` | `nrd-01` to `nrd-03`, each a preflight and a byte-identical commit twin |
| `flights/slice-declare.steps.json` | The declaration flight's promise, objective, steps and digest |
| `demo/run-journey.mjs` | The live interview slice |
| `api/wildlife-operations.json` | Draft API operations for the browser path |
| `manifest.json`, `slice.manifest.json` | Every digest and the twins' parity |
