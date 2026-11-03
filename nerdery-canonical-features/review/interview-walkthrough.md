# Interview walkthrough — November 3, 2026

## Open with the client's application, not the platform

“The DNR wants citizens to collect wildlife encounters and learn what distinguishes the animals, while biologists maintain the catalog. I separated animal definitions from individual encounters and made the team a selection from those collected individuals. The catalog's information unlock is enforced at the read boundary, not just by hiding controls.”

Then show how SideFX declares those behaviors: Input → Event → Outcome, one stable capability identity, explicit acceptance cases and attributable execution. Avoid asserting a feature is built merely because its file exists.

## Present five small moments

**Before collection:** show the overview and direct-detail response for an uncollected animal. Only the four allowed animal properties are present.

**Record the encounter:** upload a photo, record the animal with a manual or available device location and optional nickname, then inspect the durable encounter. There is no photo-verification approval gate in this phase.

**After collection:** the definition information is unlocked for that user. A second encounter of the same definition appears as a different individual with its own photo/nickname. Another user does not inherit that unlock.

**Build the team:** save up to six collected individuals and show them on the logged-in home page. Attempt seven and inspect the named refusal with the existing selection unchanged.

**Change the catalog:** sign in as a biologist, update a definition or shared attribute, then repeat a citizen mutation request and show its refusal. Explain that role administration remains with the existing external identity process for MVP.

## Application structure and data flow

The proposed views are sign-up/sign-in, home, collection overview/search, definition detail, encounter capture, personal individuals, team selection, definition administration and attribute administration. These are interface bindings over declared capabilities, not independent sources of business rules.

DNR identity supplies validated subject/role context. SideFX resolves declared application behavior through the existing server execution path. Domain persistence holds definitions, reusable attributes, selectable values, associations, encounters and team membership. Image storage supplies durable references. The browser obtains permitted read models and submits bounded requests. Actual technology/provider names should come from your deployed demo and DNR constraints, not be invented in the feature layer.

The source asks about technology decisions. Explain the actual selected runtime, data provider, media provider, presentation provider and identity integration if demonstrated. Contrast alternatives only where you have a concrete trade-off: reuse of DNR identity, indexed catalog queries, transactional team/encounter writes, shared image storage, and isolated personal data. Do not claim this feature package already validates a production deployment or performance result.

## Discuss the unanswered questions directly

Referenced-definition removal, search semantics, team membership details, languages, identity protocol and offline commitment are product decisions. Show the proposed-decision register rather than pretending the brief supplied the answers. The source names about 1000 definitions and up to 2000 concurrent users, not a request rate or latency SLO. WCAG 2.1 AA, browser coverage and responsive/localized UX have their own acceptance evidence plan.

## Evidence language

Use “authored,” “declared,” “conformant” and “proven” only for the corresponding observed state. For this package, the feature text passed Cucumber parsing and the estate feature-only check. The application cases still await execution. In the live demonstration, show the actual selected declaration, request, result, graph and receipt. If a provider is a fixture, label it as a fixture.
