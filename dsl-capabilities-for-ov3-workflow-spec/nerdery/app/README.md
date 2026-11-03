# Wildlife Collection: the local frontend

This is the web frontend for the Nerdery wildlife demo. It runs locally, and every screen is a run of a capability declared in the SideFX estate, made through the SideFX API as your signed-in session. The runs work on the estate's wildlife store. The local server stores nothing.

## Run it

```
sfx-api login      # once; the runs go out as this SideFX session
cd dsl-capabilities-for-ov3-workflow-spec/nerdery/app
npm start          # http://localhost:4310
```

You need Node 20 or later and the installed SideFX API client (`sfx-api.mjs`), and nothing else.

A run costs the SideFX API 4–5 seconds, whatever the capability: admission takes 1–2 s, then the output read waits about 3 s for the estate's answer (`TIMING=1 npm start` logs each run). The server calls the API directly in-process: the client's session is read once, and each run is two requests, admit and read the output. To keep the app responsive, the server:
- at start, signs in as each registered user in turn (Avery, then Casey) and runs every answer their screens can show, in about three minutes, in the background; it stops the moment someone signs in themselves;
- after a sign-in, runs only the answers it does not hold yet, so the next sign-in or write does not wait behind a minute of refreshes;
- answers screens from those runs, in about 100 ms;
- refreshes an answer older than five minutes in the background while still serving it (every write goes through this server and re-runs what it changes);
- after a write, re-runs only the reads that write can change.

Runs still go one at a time, and a run someone is waiting for goes ahead of background ones. A sign-in or a write waits for its own run, 4–5 seconds. Meanwhile the chosen card or button says what it is doing, and a bar at the top of the page moves while any run is out.

## Sign in and sign out

The app opens on **Sign in with DNR**. Each card is one of the challenge's DNR identity responses, served from the estate's `wildlife.identity_response` stand-in:
- **Avery Citizen** is a citizen.
- **Casey Biologist** is a biologist, so the **Catalog** is offered.
- **Drew Citizen** is validated by DNR but has no wildlife profile. Sign-in answers `REGISTRATION_REQUIRED` and offers registration, which signs in once it is done.
- The `INVALID` and `EXPIRED` responses are refused by sign-in with their own reasons.

Signing in binds your SideFX session to that wildlife user, so every later run answers as them. Roles come from DNR, as the brief keeps role management outside the app.

**Sign out** is in the header, beside the name and roles. Once signed out, the server runs nothing until the next sign-in.

## What runs where

| Screen | Capability in the estate |
| --- | --- |
| Sign in | `nerdery-sign-in-wildlife-user`, `nerdery-register-wildlife-user` |
| Every screen | `nerdery-resolve-wildlife-access` for its section |
| Home | `nerdery-view-wildlife-home`, `nerdery-view-collected-animals` |
| Collection | `nerdery-browse-animal-collection` |
| Animal | `nerdery-view-animal-definition` |
| Capture | `nerdery-upload-encounter-photo`, `nerdery-record-animal-encounter` |
| My animals | `nerdery-view-collected-animals`, plus `nerdery-view-collected-animal` for each photo |
| Individual | `nerdery-view-collected-animal`, which returns the stored photo bytes, checked in the browser against their digest |
| Team | `nerdery-set-animal-team` |
| Catalog (biologists) | `nerdery-view-catalog-for-maintenance`; `nerdery-add-animal-definition`, `-update-`, `-remove-`; `nerdery-add-animal-attribute`, `-update-`, `-remove-` |

Each screen shows the capability's own answer at its foot, with its SideFX run id and a link to that run on the circuit.

The page applies no rules of its own. The capabilities verify your session against `[identity].session` and refuse with named reasons.

A capability the estate does not declare is refused as `CAPABILITY_NOT_DECLARED` and never answered locally. Presentation (`nerdery-present-wildlife-experience`) is not declared, so the labels come from the frontend.

The **EN | ES** switch changes the interface labels, which live in [lib/labels.mjs](lib/labels.mjs). The estate's data reads the same in both languages.

## The reference model, not served

[lib/operations.mjs](lib/operations.mjs) and [lib/store.mjs](lib/store.mjs) model every MVP feature in JavaScript. `npm test` runs all 148 canonical cases against them.

They are the model the remaining estate mechanics are ported from (T-SQL in `../wildlife/wildlife.procedures.sql`). The server does not use them.
