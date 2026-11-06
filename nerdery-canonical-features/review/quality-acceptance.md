# Quality acceptance — separate proof obligations

The source requirements remain intact. These are release obligations over the application, not six new business capabilities or a fabricated compliance service. No quality profile has been executed.

## Q-BROWSER

Source: NRD-Q01. **NOT_RUN**.

**browsers:** ["Chrome","Firefox","Safari","Edge"]

**versions:** Record the tested modern versions at execution; none is prescribed by the source.

**journeys:** ["DNR sign-up and sign-in","catalog browse and search","locked and unlocked detail","photo upload","manual and device location","record encounter","collected individuals","team selection and home page","biologist definition and attribute editing"]

**requiredEvidence:** Rendered interaction observations for the same cases; a presentation model alone is insufficient.

## Q-RESPONSIVE

Source: NRD-Q02. **NOT_RUN**.

**requiredViewClasses:** ["mobile","desktop"]

**illustrativeViewportsCssPixels:** [{"width":390,"height":844},{"width":1440,"height":900}]

**viewportsAreProposals:** True

**requiredEvidence:** Review rendered layouts and complete the same user journeys in both view classes. Confirm chosen breakpoints, orientations and device scope.

## Q-LANGUAGE

Source: NRD-Q03. **NOT_RUN**.

**requiredDistinctLanguagesAtLeast:** 2

**fixtureLocales:** ["en","es"]

**fixtureLocalesAreNotCustomerSelection:** True

**requiredEvidence:** Observe localized navigation, forms, outcomes and errors while preserving animal identity and role restrictions. Agree translation ownership for animal/attribute descriptions, fallback behavior and additional languages.

## Q-ACCESSIBILITY

Source: NRD-Q04. **NOT_RUN**.

**standard:** WCAG 2.1

**level:** AA

**scope:** Entire delivered web experience, including authentication handoffs, public-facing personal experiences, biologist sections and applicable offline states.

**requiredEvidence:** An assessment against every applicable WCAG 2.1 Level A and Level AA success criterion, with the tested scope, versions, method and findings retained. Automated results alone or a returned compliant=true flag are not a conformance claim.

**assessmentMethod:** TO_BE_AGREED

## Q-CAPACITY

Source: NRD-D06, NRD-Q05. **NOT_RUN**.

**animalDefinitionCountApproximate:** 1000

**registeredUserPopulation:** tens of thousands; choose and record an exact test population

**maxConcurrentUsers:** 2000

**requestRate:** NOT_SPECIFIED

**latencyTarget:** NOT_SPECIFIED

**errorRateTarget:** NOT_SPECIFIED

**availabilityTarget:** NOT_SPECIFIED

**loadMix:** TO_BE_AGREED

**requiredEvidence:** A measured run with a declared workload mix, dataset, ramp, duration, think time and infrastructure profile. Measure read/write latency, failures, queues and resource use; prove collection isolation, field restrictions, team maximum and encounter integrity still hold. Do not reinterpret 2000 concurrent users as 2000 requests per second.

## Q-OFFLINE

Source: NRD-Q06. **NOT_RUN**.

**scopeStatus:** CANDIDATE_NOT_COMMITTED_TO_MVP

**featurePaths:** ["features/offline-candidate/nerdery-capture-offline-encounter.feature","features/offline-candidate/nerdery-synchronize-offline-encounter.feature"]

**requiredEvidence:** After owner approval, demonstrate disconnected capture, photo retention across reload, reconnect synchronization, interrupted upload, lost acknowledgment and wrong-account refusal on each supported target.

