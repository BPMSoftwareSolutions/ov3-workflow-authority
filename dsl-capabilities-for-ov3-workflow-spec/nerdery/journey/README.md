# The interview journey, in the browser

The journey runs the declared slice capabilities from the SideFX Explorer on the staging web host. Everything on screen comes from the estate:
- the capabilities and their contracts;
- the live circuit of each run;
- each run's result.

Nothing here is code. This page only lists the input for each step.

**Before you start:** `sql/repair-3-estate`, `sql/repair-4-identity` and their flight must have run. Until then every call fails at its composing statement.

## Set up once

1. Sign in at `https://sidefx-web-staging.azurewebsites.net/circuit/login`. Your principal is Avery in the wildlife store.
2. In the same browser, open `https://sidefx-web-staging.azurewebsites.net/workspace/session`. Copy `principalId` and `sessionId` into the `caller` of each input below. The capability checks that pair against `[identity].session`, so a run with another principal is refused.
3. For each step, open the Explorer at `https://sidefx-web-staging.azurewebsites.net/circuit/explorer?capability=<capability>&namespace=sidefx:capabilities`.
4. Paste the input into **Capability input · JSON** and choose **Observe**. The circuit plays the run live, and **API result** shows the outcome.

```json
"caller": { "principalId": "<principalId>", "sessionId": "<sessionId>" }
```

## 1. Before collection

The Demo Heron is locked: only its common name, collection number, range and avatar appear.

| Step | Capability | `request` | Expect |
| --- | --- | --- | --- |
| Browse | `nerdery-browse-animal-collection` | `{"search": ""}` | `LISTED`, 3 animals, each `UNCOLLECTED` with four properties |
| Detail | `nerdery-view-animal-definition` | `{"definitionId": "animal-001"}` | `VISIBLE`, `UNCOLLECTED`, no scientific name, types, stats or attributes |

## 2. Capture an encounter

| Step | Capability | `request` | Expect |
| --- | --- | --- | --- |
| Upload | `nerdery-upload-encounter-photo` | `{"fileName": "photo-a.png", "mediaType": "image/png", "contentBase64": "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOInpwLRAwQCgAlugVtTkdgTAAAAABJRU5ErkJggg=="}` | `UPLOADED`; copy `photo.photoRef` |
| Record | `nerdery-record-animal-encounter` | `{"encounterId": "enc-interview-1", "definitionId": "animal-001", "location": {"source": "manual", "description": "Synthetic park, north path"}, "photoRef": "<photoRef>", "nickname": "Reed"}` | `RECORDED`, `COLLECTED`, `verificationPerformed` false |

## 3. After collection

| Step | Capability | `request` | Expect |
| --- | --- | --- | --- |
| Browse | `nerdery-browse-animal-collection` | `{"search": "Heron"}` | `COLLECTED`, now with scientific name, types and stats |
| Detail | `nerdery-view-animal-definition` | `{"definitionId": "animal-001"}` | `COLLECTED`; Habitat: Wetland, Diet: Fish |
| Second photo | `nerdery-upload-encounter-photo` | the upload request again | a new `photoRef` |
| Second individual | `nerdery-record-animal-encounter` | `{"encounterId": "enc-interview-2", "definitionId": "animal-001", "location": {"source": "device", "latitude": 44.95, "longitude": -93.09}, "photoRef": "<second photoRef>", "nickname": "Sky"}` | `RECORDED`, a separate individual |
| My animals | `nerdery-view-collected-animals` | `{}` | `LISTED`, Reed and Sky |

## 4. Build the team

| Step | Capability | `request` | Expect |
| --- | --- | --- | --- |
| Home | `nerdery-view-wildlife-home` | `{}` | `VISIBLE`; note `team.revision` (0 when there is no team) |
| Save | `nerdery-set-animal-team` | `{"expectedRevision": <that revision>, "encounterIds": ["enc-interview-1", "enc-interview-2"]}` | `SAVED`, size 2 |
| Home | `nerdery-view-wildlife-home` | `{}` | Reed and Sky on the team |
| Seven | `nerdery-set-animal-team` | `{"expectedRevision": <the saved revision>, "encounterIds": ["enc-interview-1", "enc-interview-2", "e3", "e4", "e5", "e6", "e7"]}` | `REFUSED` `TEAM_LIMIT_EXCEEDED`, `applied` false; home is unchanged |

## 5. Refusals and replay

| Step | Capability | Input | Expect |
| --- | --- | --- | --- |
| Citizen catalog change | `nerdery-add-animal-definition` | `request`: `{"animal": {"commonName": "Demo Owl", "scientificName": "Synthetic scientific label 4", "avatarPhotoRef": "avatar-001", "collectionNumber": 4, "range": ["county-a"], "types": ["Flying"], "stats": {"Strength": 5, "Size": 6, "Speed": 7}, "attributes": []}}` | `REFUSED` `BIOLOGIST_ROLE_REQUIRED` |
| Retry | `nerdery-record-animal-encounter` | the first Record input again | `replayed` true, `applied` false |
| Another principal | `nerdery-browse-animal-collection` | `caller.principalId` changed to `00000000-0000-4000-8000-000000000001` | `REFUSED` `AUTHENTICATION_REQUIRED` |

Each run keeps its request, graph and result. Open any of them again from the Explorer to show the recorded evidence on the circuit.

## The full journey runs once

Recording the first encounter collects animal-001 for Avery. After that, moment 1 shows it unlocked. To rehearse without spending that state, use the reads and refusals only.

## Not yet: the wildlife screens as declared pages

The deployed page shell (`live-circuit/circuit/page-runtime.js` in sfx-platform, the same on staging) can launch a capability run from a declared page, but cannot yet run this slice:
- An `observe` action takes its capability input as one literal or one binding. A page therefore cannot pair the signed-in caller (from the `session` source, which returns `principalId` and `sessionId`) with form values.
- No page source reads a run's output, so a page cannot show the result.

Two small changes to the shell would allow declared pages for collection, detail, capture, individuals, team and home, published through `sidefx_ui.stage_ui_page` and `promote_ui_page`:
- resolve bindings nested inside an action's `input`;
- add a run-output source.
