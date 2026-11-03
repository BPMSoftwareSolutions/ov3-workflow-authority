# Nerdery wildlife application — canonical feature candidates

**Prepared:** November 2, 2026  
**Interview:** November 3, 2026, as stated by the builder  
**Delivery:** 19 `.feature` files; 150 individually identified acceptance cases; 17 MVP capabilities and 2 separate offline candidates.

## Review status

All 19 exact feature digests returned `WELL_FORMED` when the repository checker ran in feature-only mode through the estate SQL reader. Cucumber parsed 150 cases with 564 result assertions. The Nerdery cases are `@status:not-built`. Declaration conformance, application execution and browser, accessibility and capacity evidence are still open. [Validation and run receipts](review/local-validation.md)

## Read the collection journey

| Question | Feature and case |
|---|---|
| What can a citizen see before an encounter? | [Browse the catalog](features/mvp/nerdery-browse-animal-collection.feature) · `nrd-collection-uncollected` checks the four permitted animal properties. |
| What changes when the citizen records a sighting? | [Record an encounter](features/mvp/nerdery-record-animal-encounter.feature) · `nrd-encounter-manual` starts with an empty collection and an uploaded photo. |
| Who gets the unlocked detail? | [Read the definition](features/mvp/nerdery-view-animal-definition.feature) · `nrd-animal-detail-unlocked` and `nrd-animal-detail-biologist-locked` distinguish personal collection state from permission to edit the catalog. |
| Which individuals appear on the home page? | [Select a team](features/mvp/nerdery-set-animal-team.feature) · `nrd-team-two-individuals` selects two sightings of the same definition. [View home](features/mvp/nerdery-view-wildlife-home.feature) checks the saved team in a separate arrangement. |
| What survives a lost connection? | [Synchronize a pending encounter](features/offline-candidate/nerdery-synchronize-offline-encounter.feature) · `nrd-offline-sync-ack-lost` checks a retry following a server commit. Offline capture and sync are candidates beyond the MVP. |

Each case starts from its own pinned fixture. The [decision register](review/scope-and-decisions.md) separates challenge requirements from proposed policies, including team membership and retry identity. See the [implementation handoff](review/implementation-handoff.md) for the path to runtime evidence.

## Package contents

| Path | Purpose |
|---|---|
| `features/mvp/` | Seventeen bounded application capabilities, with one circuit scenario per file and independently identified acceptance cases |
| `features/offline-candidate/` | Offline capture and synchronization candidates; not silently included in MVP |
| `fixtures/base-state.json` | Synthetic state and test reference catalogs; not actual DNR fauna or a selected state |
| `fixtures/cases/` | One pinned, isolated arrangement per acceptance case; authentication and dependencies live here, not in the caller request |
| `fixtures/media/` | Two tiny synthetic PNG test files; not wildlife images and not verification evidence |
| `source/` | Exact uploaded challenge and canonical examples, with computed SHA-256 identities |
| `review/` | Scope/decisions, quality obligations, input/result notes, handoff and interview guidance |
| `derived/` | Regenerable indexes, source traceability and local structural validation; never a second authoring authority |
| `SHA256SUMS` | Exact-byte identity for every delivered file except this checksum list itself |

## Capability inventory

| Capability | Scope | Cases | Promised experience |
|---|---|---:|---|
| `nerdery-register-wildlife-user` | mvp | 7 | Register a wildlife user through the DNR identity service |
| `nerdery-sign-in-wildlife-user` | mvp | 5 | Sign in to the wildlife application |
| `nerdery-resolve-wildlife-access` | mvp | 14 | Resolve access to wildlife application sections |
| `nerdery-add-animal-definition` | mvp | 17 | Add an animal definition |
| `nerdery-update-animal-definition` | mvp | 6 | Update an animal definition |
| `nerdery-remove-animal-definition` | mvp | 5 | Remove an animal definition from the active catalog |
| `nerdery-add-animal-attribute` | mvp | 6 | Add a reusable animal attribute |
| `nerdery-update-animal-attribute` | mvp | 5 | Update a reusable animal attribute |
| `nerdery-remove-animal-attribute` | mvp | 4 | Remove an animal attribute from active use |
| `nerdery-browse-animal-collection` | mvp | 11 | Browse and search the animal-definition collection |
| `nerdery-view-animal-definition` | mvp | 6 | View the information unlocked for an animal definition |
| `nerdery-upload-encounter-photo` | mvp | 5 | Retain a photo for an animal encounter |
| `nerdery-record-animal-encounter` | mvp | 17 | Record an animal encounter |
| `nerdery-view-collected-animals` | mvp | 6 | View the individual animals in a personal collection |
| `nerdery-set-animal-team` | mvp | 11 | Select a personal team of up to six collected animals |
| `nerdery-view-wildlife-home` | mvp | 4 | View the selected team on the wildlife home page |
| `nerdery-present-wildlife-experience` | mvp | 9 | Present the wildlife application in the requested supported language |
| `nerdery-capture-offline-encounter` | offline-candidate | 6 | Capture an encounter while disconnected |
| `nerdery-synchronize-offline-encounter` | offline-candidate | 6 | Synchronize a retained offline encounter |

## Reading one feature

The Feature-level tags identify the capability, its one root circuit scenario, Input, input contract, Event, event authority, Outcome, outcome contract and terminal disposition. Each `Scenario` is an acceptance case of that same circuit, with its own `@case` identity. Every case has the same primary Given/When/Then text, one JSON request and an operation/path/equals assertion table. Rules state the semantic partitions; a fixture varies state, identity or dependency behavior without creating a new circuit scenario.

The [provider binding review](review/provider-bindings.md) maps every case to its expected calls. Four live, fixture-backed reads establish `sql-database-reader` as a reusable provider. Its exact tag appears on 24 catalog, detail, personal collection and home cases. Another 110 cases name candidate providers whose contracts need proof. The remaining 16 describe a refusal before any business-provider call. Each product operation still needs a declared binding and its own runtime evidence.

## Proof boundaries

Feature review establishes intended behavior. Static checking establishes properties of these files. Estate conformance establishes correspondence to the selected declaration. A case-specific, digest-bound execution establishes runtime acceptance. Browser interaction, accessibility assessment and load testing establish different obligations. None substitutes for another.
