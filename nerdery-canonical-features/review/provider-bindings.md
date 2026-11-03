# Nerdery business provider bindings

The feature tags specify the providers the proposed product operations must invoke. The case comments name candidate jobs that still need an estate declaration and proof. Each candidate name below is a design proposal. An authorization or shape refusal can finish at the entry before a business provider is called. The authenticated subject is supplied by the trusted boundary.

## Verified read provider

Selected capability `sql-database-reader`, document `sha256:4e4abbeb5d6a85e7aef098cc9a4184d7abe4eb23a90cd8b8fe4f231153fce142`, executed graph `sha256:dbb29dc8172312c3546bb706e32b30c32b59cb1ecad3b4dfff7e35826f6f0596`. Declaration read `92b79617`. The four runs below invoked the provider against synthetic fixture inputs on the estate. They establish the reusable read mechanism. Production wildlife tables, governed read statements, the trusted subject binding and the product operation’s call evidence remain to be supplied.

| Proposed Nerdery read | Result observed from the provider | Direct provider run |
|---|---|---|
| `nerdery-browse-animal-collection` | Public numbers 1, 2, 3 in order; only Demo Heron was collected for Blake. | `c2d5ec95-57a3-9088-ef86-684ef134376d` |
| `nerdery-view-animal-definition` | Blake’s uncollected Demo Fox returned only common name, public number, county range and file photo. | `b5b5a835-d3c9-ec80-469f-8d4aee0cee56` |
| `nerdery-view-collected-animals` | Only enc-008, owned by Blake, with Blake’s photo and nickname. | `e56f6b4a-9903-c3c4-0e27-c528e0ab784d` |
| `nerdery-view-wildlife-home` | Avery’s saved members enc-001 and enc-003, in order, with their own photos and nickname or fallback name. | `6b402f2b-ebe4-62a2-9d7f-41f3d2336807` |

For acceptance, pin the selected product operation and provider graph before the run. Match the operation’s own dispatch, attempt, graph and returned result under the same run. A bare registry hit, a fixture-loading call or a successful read on another step supplies none of that proof. An expected storage failure needs its own attempted call or an attributable transport refusal; a locally refused request must have no business-provider invocation.

## Proposed jobs that still need a verified binding

| Candidate identity | Result required | Evidence needed |
|---|---|---|
| `resolve-dnr-identity-response` | Resolve the DNR response by reference and return its verified subject, profile and validity, or its expiration, invalidity or outage. | DNR protocol, issuer and reference binding; signed response or refusal tied to this attempt. |
| `create-unique-wildlife-profile` | Create one wildlife profile per authenticated subject while enforcing unique email under concurrent registration. | Atomic uniqueness and an independent profile read after commit or conflict. |
| `establish-wildlife-session` | Issue an application session for the validated DNR subject, with the correct local account. | Session issuance and subject read-back; no session issued on validation failure. |
| `resolve-current-dnr-roles` | Resolve the current DNR roles for a trusted subject, including a revoked biologist grant. | Evidence of the external grant/version used for that access decision. |
| `commit-wildlife-catalog-change` | Atomically add, replace or remove definitions and shared attributes, enforcing current revision, valid references and history. | Revision and affected IDs plus an independent read of catalog, encounter and team references on the relevant path. |
| `retain-owned-encounter-photo` | Retain the submitted image bytes for the authenticated owner and return an owned durable reference and digest. | Reopen bytes by reference under the correct owner and verify the digest; a precommit failure creates no reference. |
| `commit-owned-wildlife-encounter` | Check the selected definition and photo ownership, persist the encounter, and update collection state under the owner-scoped retry key. | Independent read of the individual and collection state; identical retries keep one row and conflicting retries preserve the first result. |
| `replace-owned-wildlife-team` | Check revision and owner membership and replace the ordered team in one transaction. | Read the exact saved member IDs and revision; a refused or failed replacement preserves the prior team. |
| `project-wildlife-page` | Project the permitted page data and locale resources, including the distinct biologist sections. | Returned locale, labels and page contract; denied paths return no private page data. Browser rendering is separate evidence. |
| `retain-offline-wildlife-draft` | Validate the cached selection and retain an owner-scoped offline draft with its photo on the device. | Draft and original photo survive device reload under the same subject without unlocking a server collection. |
| `read-owned-offline-wildlife-draft` | Read only the signed-in owner’s pending draft and retained photo. | Owner, local ID and photo digest read from device storage; another user cannot retrieve the draft. |
| `acknowledge-wildlife-draft-sync` | Mark the local draft synchronized only after confirmation of the corresponding committed server encounter. | Read the draft state after reload and match the acknowledgment to the server encounter ID. |
| `reconcile-committed-wildlife-encounter` | Match the authenticated owner, request key, canonical content and photo digest to the committed encounter after a lost acknowledgment. | Read the original server encounter and verify a single commit before acknowledging the local draft. |
| `nerdery-upload-encounter-photo` | Supply the retained device photo to the Nerdery upload operation; consume its server reference before recording the encounter. | The upload feature must first be declared and verified; match the child return to the sync attempt. |
| `nerdery-record-animal-encounter` | Commit or reconcile the same owner-scoped encounter ID through the Nerdery record operation. | The record feature must first be declared and verified; read exactly one server encounter after replay. |

## Coverage by feature

| Feature | Required, verified provider identity | Other candidate identities used on applicable paths |
|---|---|---|
| [nerdery-register-wildlife-user](../features/mvp/nerdery-register-wildlife-user.feature) | — | `create-unique-wildlife-profile`, `resolve-dnr-identity-response` |
| [nerdery-sign-in-wildlife-user](../features/mvp/nerdery-sign-in-wildlife-user.feature) | — | `establish-wildlife-session`, `resolve-dnr-identity-response` |
| [nerdery-resolve-wildlife-access](../features/mvp/nerdery-resolve-wildlife-access.feature) | — | `resolve-current-dnr-roles` |
| [nerdery-add-animal-definition](../features/mvp/nerdery-add-animal-definition.feature) | — | `commit-wildlife-catalog-change`, `resolve-current-dnr-roles` |
| [nerdery-update-animal-definition](../features/mvp/nerdery-update-animal-definition.feature) | — | `commit-wildlife-catalog-change`, `resolve-current-dnr-roles` |
| [nerdery-remove-animal-definition](../features/mvp/nerdery-remove-animal-definition.feature) | — | `commit-wildlife-catalog-change`, `resolve-current-dnr-roles` |
| [nerdery-add-animal-attribute](../features/mvp/nerdery-add-animal-attribute.feature) | — | `commit-wildlife-catalog-change`, `resolve-current-dnr-roles` |
| [nerdery-update-animal-attribute](../features/mvp/nerdery-update-animal-attribute.feature) | — | `commit-wildlife-catalog-change`, `resolve-current-dnr-roles` |
| [nerdery-remove-animal-attribute](../features/mvp/nerdery-remove-animal-attribute.feature) | — | `commit-wildlife-catalog-change`, `resolve-current-dnr-roles` |
| [nerdery-browse-animal-collection](../features/mvp/nerdery-browse-animal-collection.feature) | `sql-database-reader` | — |
| [nerdery-view-animal-definition](../features/mvp/nerdery-view-animal-definition.feature) | `sql-database-reader` | — |
| [nerdery-upload-encounter-photo](../features/mvp/nerdery-upload-encounter-photo.feature) | — | `retain-owned-encounter-photo` |
| [nerdery-record-animal-encounter](../features/mvp/nerdery-record-animal-encounter.feature) | — | `commit-owned-wildlife-encounter` |
| [nerdery-view-collected-animals](../features/mvp/nerdery-view-collected-animals.feature) | `sql-database-reader` | — |
| [nerdery-set-animal-team](../features/mvp/nerdery-set-animal-team.feature) | — | `replace-owned-wildlife-team` |
| [nerdery-view-wildlife-home](../features/mvp/nerdery-view-wildlife-home.feature) | `sql-database-reader` | — |
| [nerdery-present-wildlife-experience](../features/mvp/nerdery-present-wildlife-experience.feature) | — | `project-wildlife-page`, `resolve-current-dnr-roles` |
| [nerdery-capture-offline-encounter](../features/offline-candidate/nerdery-capture-offline-encounter.feature) | — | `retain-offline-wildlife-draft` |
| [nerdery-synchronize-offline-encounter](../features/offline-candidate/nerdery-synchronize-offline-encounter.feature) | — | `acknowledge-wildlife-draft-sync`, `nerdery-record-animal-encounter`, `nerdery-upload-encounter-photo`, `read-owned-offline-wildlife-draft`, `reconcile-committed-wildlife-encounter` |

## Discovery evidence

OV3 discovery run `29a7ce4a` examined the selectable tools and a partial port inventory. The selected capability inventory (`90fd8c2e`) covered all 669 IDs in model 34. A separate read (`e78907ed`) enumerated all 3,052 selected port identities. Platform port names and registry listings do not by themselves identify a suitable provider capability.

- `authenticate-ide-user` and `enroll-ide-user` describe IDE identity. `check-api-session` checks an existing SideFX API session. None establishes the DNR issuer or wildlife role mapping.
- `write-binary-artifact` describes verified artifact bytes. `read-retained-artifact` accepts a digest. Neither contract establishes a private, owner-scoped media reference and its retention policy.
- `http-exchange` can make credentialed HTTP requests. Using it for DNR requires a selected DNR endpoint, protocol and credential reference.
- `database-query-provider` and `invoke-database-capability` carry a configured-message user story in their selected envelopes. They do not prove the transactional writes required by the Nerdery proposals.
- The selected envelopes for these near matches were read in `3df4621e`. The negative finding concerns missing evidence for a compatible binding; it is not a claim that no reusable port exists.
