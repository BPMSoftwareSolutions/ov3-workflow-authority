# Wildlife Collection: the local demo

This is a local web app for the Nerdery wildlife challenge. Its behavior is defined by the challenge's canonical features: each operation returns exactly the result its feature specifies, and those features' cases run as the app's acceptance tests.

## Run it

```
cd dsl-capabilities-for-ov3-workflow-spec/nerdery/app
npm start          # http://localhost:4310
npm run reset      # start again from the seed: Avery owns nothing yet
npm test           # run every canonical case against the operations
```

You need Node 20 or later. There are no dependencies and nothing to install.

## Signing in

The app stands in for the DNR identity service with the identity responses from the challenge fixtures:
- **Avery** is a citizen.
- **Casey** is a biologist.
- **Drew** is validated by DNR but not registered.
- An **invalid** response and an **expired** response show the named refusals.

The app keeps no passwords. A session starts only from a response DNR validated, for a registered wildlife user.

If Drew tries to sign in, sign-in answers REGISTRATION_REQUIRED and the app offers registration. `nerdery-register-wildlife-user` creates the account with the roles DNR assigns, and the same response then signs Drew in.

Before every screen, the app asks `nerdery-resolve-wildlife-access` for that screen's section, using the user's current roles. The menu offers Catalog only when access to `animal-definitions-admin` is allowed, so the page never decides from roles itself.

## Screens

| Screen | Operations used |
| --- | --- |
| Home | `nerdery-view-wildlife-home`, `nerdery-view-collected-animals` |
| Collection | `nerdery-browse-animal-collection` |
| Animal | `nerdery-view-animal-definition` |
| Capture | `nerdery-upload-encounter-photo`, `nerdery-record-animal-encounter` |
| My animals | `nerdery-view-collected-animals`, plus `nerdery-view-collected-animal` for each photo |
| Individual | `nerdery-view-collected-animal`, which returns the stored photo bytes, checked in the browser against their digest |
| Team | `nerdery-set-animal-team` |
| Catalog (biologists only) | `nerdery-view-catalog-for-maintenance`, `nerdery-add-animal-definition`, `nerdery-update-animal-definition`, `nerdery-remove-animal-definition`, `nerdery-add-animal-attribute`, `nerdery-update-animal-attribute`, `nerdery-remove-animal-attribute` |

The menu offers Catalog only to biologists. Even so, every catalog operation refuses a citizen on its own, with BIOLOGIST_ROLE_REQUIRED.

`nerdery-view-catalog-for-maintenance` is a feature written for this app, in `../features`: the package's update and remove features need each definition's revision, and its reads never return one.

At the foot of each screen, the operation's own answer is shown under its capability name. The page applies no rules of its own: every refusal you see is named by an operation.

## Where things are

| Path | What it holds |
| --- | --- |
| [server.mjs](server.mjs) | The HTTP server. An operation runs as the user of the session this server started, never as a user named in the request. |
| [lib/operations.mjs](lib/operations.mjs) | One function per feature, ported from the slice's mechanics in `../wildlife/wildlife.procedures.sql`. |
| [lib/store.mjs](lib/store.mjs) | The store: seeded from the fixtures, transactional, with storage faults the cases can inject. Its data lives in `data/`, which git ignores. |
| [test/run-features.mjs](test/run-features.mjs) | The acceptance runner. It reads the cases from `nerdery-canonical-features/features` and `../features`, with their fixtures. |

The features are read where they live and are never copied. The review package is `nerdery-canonical-features`, read only. Features written for the build, such as the photo view, live in `../features`.
