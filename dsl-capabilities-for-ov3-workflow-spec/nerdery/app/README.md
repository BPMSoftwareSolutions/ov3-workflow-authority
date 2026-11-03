# Wildlife Collection: the local frontend

This is the web frontend for the Nerdery wildlife demo. It runs locally, and every screen is a run of a capability declared in the SideFX estate, made through the SideFX API as your signed-in session. The runs work on the estate's wildlife store. The local server stores nothing.

## Run it

```
sfx-api login      # once; the runs go out as this SideFX session
cd dsl-capabilities-for-ov3-workflow-spec/nerdery/app
npm start          # http://localhost:4310
```

You need Node 20 or later and the installed SideFX API client (`sfx-api.mjs`), and nothing else.

A run costs the SideFX API about 3–4 seconds, whatever the capability. The server calls the API directly in-process: the client's session is read once, and each run is two requests, admit and read the output. To keep the app responsive, the server:
- runs every answer a screen can show once at start, in about a minute;
- answers screens from those runs, in about 100 ms;
- refreshes an answer older than a minute in the background while still serving it;
- after a write, re-runs only the reads that write can change.

Runs still go one at a time, and a run someone is waiting for goes ahead of background ones. A write waits for its own run, about 3–4 seconds.

## What runs where

| Screen | Capability in the estate |
| --- | --- |
| Home | `nerdery-view-wildlife-home`, `nerdery-view-collected-animals` |
| Collection | `nerdery-browse-animal-collection` |
| Animal | `nerdery-view-animal-definition` |
| Capture | `nerdery-upload-encounter-photo`, `nerdery-record-animal-encounter` |
| My animals | `nerdery-view-collected-animals`, plus `nerdery-view-collected-animal` for each photo |
| Individual | `nerdery-view-collected-animal`, which returns the stored photo bytes, checked in the browser against their digest |
| Team | `nerdery-set-animal-team` |

Each screen shows the capability's own answer at its foot, with its SideFX run id and a link to that run on the circuit.

The page applies no rules of its own. The capabilities verify your session against `[identity].session` and refuse with named reasons.

A capability the estate does not declare yet is refused as `CAPABILITY_NOT_DECLARED` and never answered locally. That currently covers content management, section access, presentation and the maintenance read.

The **EN | ES** switch changes the interface labels, which live in [lib/labels.mjs](lib/labels.mjs). The estate's data reads the same in both languages.

## The reference model, not served

[lib/operations.mjs](lib/operations.mjs) and [lib/store.mjs](lib/store.mjs) model every MVP feature in JavaScript. `npm test` runs all 148 canonical cases against them.

They are the model the remaining estate mechanics are ported from (T-SQL in `../wildlife/wildlife.procedures.sql`). The server does not use them.
