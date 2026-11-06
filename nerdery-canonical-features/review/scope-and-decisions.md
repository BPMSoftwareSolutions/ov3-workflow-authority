# Scope, vocabulary and decisions

## Source hierarchy

The uploaded Nerdery challenge owns product scope. The two supplied canonical SideFX examples own the feature-writing pattern. This package proposes the application-specific names, contracts and boundary decisions needed to author the features. It does not borrow historical project implementation claims to establish current Nerdery capability availability.

## Domain vocabulary to preserve

**Animal definition** is a catalog animal with a public collection number, intrinsic properties and special attribute associations. **Special attribute** is a reusable named/described definition with selectable values; it is not an animal-specific free-text field. **Encounter / collected individual** is a user's particular recorded instance, with their location, photo and optional nickname. Several individuals may refer to the same animal definition. The **team** is the selected collection membership shown on the logged-in home page; encounter-based membership is an explicit proposal under D06.

**Collected/uncollected** is relative to a user and an animal definition. It is not a global property of the definition. **Unlocked** information cannot be treated as merely hidden in the browser: both catalog and detail response obligations preserve the restriction. The source's unlock wording is interpreted as collection unlocking the remaining definition information, rather than requiring the out-of-scope photo-verification workflow.

**Photo uploaded** does not mean the animal is verified. The MVP stores the photo for later verification. It does not introduce species recognition, biologist review, moderation approval or a waiting-for-verification gate.

## Explicitly outside the source MVP

In-application user/role administration is fast-follow. Photo verification, richer attribute types, value-driven stat bonuses, team-to-team interactions and social sharing are future scope. No leaderboard, battles, trading, AI identification, maps, public user profiles, sightings-analysis dashboard or new comparison-screen workflow is added by these features. The brief's educational similarity/difference purpose is represented through shared attributes and unlocked animal information; a separate comparison product was not requested.

## Offline is a candidate scope, not an unspoken commitment

The source says DNR is interested in collecting without connectivity. Two complete candidate feature files are included separately so that the owner can discuss and decide this scope. They are not counted among the seventeen MVP capabilities. They depend on previous sign-in, a cached catalog and local photo retention as explicit proposals, not guarantees supplied by the challenge.

## Decisions proposed by this package

### D01 — Request/result shapes and identities

**PROPOSED — NOT APPROVED.** All capability, scenario, operation and contract IDs and all JSON member names in this pack are proposed authoring identities, not an observed estate binding. Requests exclude caller-supplied roles. Generated IDs in fixtures are controlled test values, not a mandated production allocation algorithm.

### D02 — DNR identity integration

**PROPOSED — NOT APPROVED.** Use a provider-neutral identityResponseRef resolved and validated server-side. The existing DNR identity technology, protocol, registration screens, session mechanism and claim mapping are unknown. Do not add a password database or assume a vendor.

### D03 — Removal with existing references

**PROPOSED — NOT APPROVED.** Proposed: remove a definition or attribute from active discovery/selection while retaining historical references. Definition removal does not delete prior encounters or teams. Referenced selectable values cannot be removed without an explicit migration decision. Confirm this retention policy; it is not in the brief.

### D04 — Search semantics

**PROPOSED — NOT APPROVED.** Proposed: case-insensitive common-name substring match, with an all-digit query also matching an exact collection number. Do not use locked scientific/attribute data as a search side channel. Fuzzy search, stemming and translated search behavior remain undecided.

### D05 — Private user resources and enforcement

**PROPOSED — NOT APPROVED.** Proposed: personal collections, encounter media and team mutations are scoped to the server-validated subject. A biologist can edit the catalog but cannot thereby read or change another user's private collection. Public/anonymous catalog access is not settled.

### D06 — Team membership and atomic replacement

**PROPOSED — NOT APPROVED.** Proposed: team membership refers to collected encounter instances, not species definitions; the same encounter cannot appear twice. Distinct instances of the same definition are allowed. One submitted list replaces the team atomically, and an empty list clears it. Confirm these semantics.

### D07 — Retry identity

**PROPOSED — NOT APPROVED.** Proposed: encounterId is a stable client-generated key scoped to the authenticated user. The same key and same canonical request returns the existing encounter; the same key with changed content is refused. Different keys remain distinct encounters even when every wildlife field matches.

### D08 — Reference data and validation

**PROPOSED — NOT APPROVED.** The state, counties, full 15-type catalog, stat names/value domains and animal dataset are not supplied. Fixture values are synthetic only. Proposed: public collection numbers are unique; referenced counties/types/attributes/values must exist in the selected reference catalog. No unrequested stat scale is imposed.

### D09 — Offline experience

**PROPOSED — NOT APPROVED.** Candidate only: a previously signed-in user with a cached catalog can retain a local draft with its photo and location, see that it is pending, and synchronize it later under the same subject. No cross-device, first-visit-offline or background-sync guarantee is made. Conflict and retention details require owner decisions.

### D10 — Media boundary

**PROPOSED — NOT APPROVED.** Proposed test contract accepts image bytes and returns an owned media reference; production upload transport, allowed formats, size limits, privacy, retention and malware controls remain undecided. Image acceptance is not species verification. No upload-size limit is invented.

### D11 — Language and presentation

**PROPOSED — NOT APPROVED.** en and es plus the fixture viewport sizes are test examples, not the state's chosen languages or mandated breakpoints. UI labels and domain descriptions need an explicit translation policy. Accessibility and responsive behavior require rendered-surface assessment, not just a returned declaration.

### D12 — Quality evidence

**PROPOSED — NOT APPROVED.** The brief supplies population/concurrency and a WCAG version/level, but no latency/error/availability targets, load mix, browser versions or accessibility audit method. Record these before certifying readiness. The quality plan does not invent service-level numbers.

### D13 — Optimistic update semantics

**PROPOSED — NOT APPROVED.** Proposed: definition, attribute and team replacement requests carry expectedRevision. A stale revision refuses without overwriting newer state. This concurrency policy is not specified in the brief.

### D14 — Read-model ordering

**PROPOSED — NOT APPROVED.** Proposed: collected individuals are returned in ascending encounterId order; team members preserve the submitted selection order; resolved attributeDetails are ordered by attributeId, except where an explicitly named fixture subset contains one attribute. Only definition collection-number ordering is supplied by Nerdery. Confirm or replace these proposed tie-breaks before admission.

## Facts the brief does not settle

The state and authoritative counties; the complete fifteen types; stat value domains; which animal fields are mandatory beyond the listed model; uniqueness/immutability/allocation of public numbers; referenced-data removal semantics; email normalization; identity vendor/protocol/claims; anonymous browsing; location precision/retention and out-of-range encounters; photo limits and privacy; search matching; selected language list and domain translation; the exact team semantics; offline commitment, device support, retention, conflicts and background synchronization; service-level targets and measured workload mix.

Do not convert this list into a reason to stop all work. Build independent, source-supported paths. Before admitting a decision-dependent case, accept or revise its proposed meaning and regenerate the affected feature digest and derived indexes.
