# Phase B — DNR Wildlife Reference Estate: OV3 Consumer Build Profile

**Status:** PROPOSED / NOT ADMITTED / NOT EXECUTED. Begins only after Phase A workflow topology fidelity is demonstrated and its admission gates close. Read the four-page Nerdery challenge as authoritative source requirements; the earlier wildlife candidate zip is a design specimen, not an installed estate.

## Purpose

Use the newly proved workflow inspection and typed-graph representation to author, connect, project and execute an actual wildlife reference capability assembly. **Do not assume the original “four roots” are four executable workflows.** Admit each independently invocable entry from declared scenario entry authority, and represent product consumption, UI navigation and provider binding with separate semantics.

## Domain product and identity laws

- `AnimalDefinition`: scientific/catalog animal type; ~1,000 MVP definitions; unique public collection number and ordering; common/scientific names, image, counties/range, up to two types selected from 15, and stats such as strength/size/speed.
- `AnimalAttributeDefinition`: name, description, selectable values; animal association can be shared or unique; future attribute types/bonus stats are outside MVP.
- `Encounter`: one user-reported observation with selected animal, manual/device location, required photo, optional nickname, durable identity, and explicitly `UNVERIFIED` photo verification status.
- `CollectedAnimal`: recorded user instance derived from encounter; repeated collection of the same animal type allowed. Biological identity deduplication is NOT implied; collection display uses the user's photo/nickname when supplied.
- `WildlifeTeam`: owner-selected list of zero to six recorded instances, shown on owner home page; cross-user team interaction and social share are future scope.
- `Identity`: state DNR identity provider is an existing external supplier; citizen and biologist are authorization roles. Biologist also has citizen collection rights; roles managed outside app for MVP. Name fields + globally unique email are source requirements.

## Proposed capabilities (reuse exact admitted identities if existing)

| Capability identity | Core scenario responsibilities | Outcome product / independent entry candidate |
|---|---|---|
| `access-wildlife-application` | Register profile/sign in/resolve permitted access | authorized account/session; provider beneath event |
| `curate-wildlife-catalog` | Create/update/retire animal definition | authoritative catalog state |
| `curate-wildlife-attributes` | Create/update/retire attribute definition and selectable values | authoritative attribute state |
| `browse-wildlife-catalog` | List/search/order catalog; apply collection-aware disclosure | authorized catalog projection |
| `reveal-animal-knowledge` | Resolve collected status and science-field visibility | authorized animal knowledge projection |
| `compare-wildlife-properties` | Compare supported attribute/stats data without leakage | authorized comparison product |
| `record-wildlife-encounter` | Admit submission, verify owner and required data, store idempotently | recorded unverified encounter + collected instance |
| `view-wildlife-collection` | Retrieve owner's recorded unique instances | owner collection view |
| `manage-wildlife-team` | Select/reorder/remove up to six owned instances with atomic constraints | owner team projection |
| `synchronize-offline-encounters` | Admit pending offline captures upon connectivity and reconcile idempotently | sync disposition + encounter references |

The list is a **candidate capability inventory**, not a workflow-root count. OV3 must resolve which scenarios actually have entry authority and which relationships are execution transitions.

## Phase B work packages

**B0 — Domain source mapping and decisions.** Pin current challenge document; trace every requirement to a scenario, contract, projection, policy or deferred feature. Ask for a decision only where missing meaning blocks the chosen execution slice. Record source-vs-proposal status. Keep ambiguities such as biological individual identity and offline MVP timing visible.

**B1 — Domain contracts and first user effect.** Use already-admitted JSON Schema and database-authoring mechanisms. Start with a fixture owner, one catalog animal, manual location, one stored photo reference, and idempotent register → persisted unverified encounter → inspectable receipt. External DNR provider can initially be a **clearly labeled fixture** rather than a claimed live enterprise integration; never label fixture identity as externally verified.

**B2 — Catalog and attributes.** Prove biologist-only create/update/retire, catalog ordering/IDs, two-type bound, counties/range, attribute selectable values, history and reference integrity. Changes update durable products; they do **not** automatically execute browsing or knowledge view scenarios.

**B3 — Citizen consumption.** Add independently invocable browse, reveal and compare scenarios. Prove uncollected animals only reveal common name, collection number, range and catalog image; unlocked fields require collection eligibility. Enforce disclosure at server read/projection, not just CSS.

**B4 — Personal collection and team.** Render every recorded instance with own image and optional nickname, permit repeat species with new encounter IDs, enforce zero-to-six owned team members under concurrent edits, and project team home-page view.

**B5 — Offline profile.** Implement only when scoped/admitted as an MVP requirement: browser pending capture and photo retention, eventual sync via admitted server entry, duplicate replay safety, conflict/expiry testimony, no false on-server collection while offline. No special alternate registration authority.

**B6 — Multi-surface and quality.** Project responsive desktop/mobile UI and API/CLI inspection from the same admitted estate where applicable. Prove the selected language set, WCAG 2.1 AA, modern-browser behavior and performance profile under representative load up to the brief's 2,000 concurrent users. These are measured exit gates, not automatic achievements of declarative design.

**B7 — Review and promotion.** Inspect roots and routes through the Phase A workflow lens. Confirm DNR identity provider appears only in the event's subordinate provider view, and that catalog-product relationships do not render as automatic workflow execution. Run negative authorization and privacy fixtures, capture true execution receipts, then admit and publish only through existing estate lifecycle.

## Minimum end-to-end proof

**Given** one admitted animal definition, an authenticated authorized subject, a durable photo reference and a manual location; **when** the encounter-registration scenario is invoked through the installed server kernel; **then** exactly one unverified encounter is persisted and addressable, idempotent replay does not create another, the owner's collection becomes queryable, and an actual receipt allows an operator to trace the scenario → provider/mechanic descent → outcome evidence without any invented execution arrow.

## Acceptance requirements to cross-apply

- Biologist can maintain definitions/attributes; citizen cannot.
- Biologist can also collect and manage a team.
- Email uniqueness and user-name data are enforced in the chosen identity/profile contract.
- Each catalog definition has proper public order, image, range, types and stats.
- Search is collection-number ordered and enforces locked-field policy.
- Verification of a user-submitted photo is deferred and recorded honestly.
- Multiple reports of the same animal definition remain independent records.
- Collection view honors owner identity and user's image/nickname.
- Team selection allows at most six owned instances, including under races.
- Offline capture and eventual synchronization are explicitly scoped, not silently assumed delivered.
- Multilingual, mobile/desktop, WCAG 2.1 AA, and concurrency claims require target-specific measured proof.
- No domain behavior enters hand-authored consumer executable bodies; any novel physical mechanic is an explicit provider/kernel extension with separate authority.

**Exit:** Only a real admitted DNR wildlife estate and measured experience/conformance evidence qualifies as Phase B success. Phase A's accurate workflow visualization is necessary but never sufficient for app delivery.
