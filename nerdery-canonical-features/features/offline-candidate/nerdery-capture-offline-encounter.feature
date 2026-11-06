# nerdery-capture-offline-encounter: canonical-feature candidate for owner review, 2026-11-02.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples; not a new platform format.
# Status: feature candidate. The proposed capability is absent from estate model 34 (inventory run 49ae8acb).
# @status:not-built means this delivery contains no implementation or run evidence for the case.
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# Business provider candidates are named on each affected case. Bind and verify them before adding @provider tags.
# See review/provider-bindings.md for provider scope, evidence and open bindings. Fixture preparation is separate.
# A successful write requires durable provider testimony and independent read-back; output echoes are not proof.
# All JSON shapes/identities are proposed under D01. Case design decisions remain proposals, not Nerdery requirements.
# Scope: offline-candidate. Source requirements: NRD-E01, NRD-E02, NRD-E04, NRD-Q06.
# Proposed outcome contract: nerdery-capture-offline-encounter-result.v1; terminal variants: PENDING_SYNC, REFUSED.
# Proposed operation identity: nerdery-capture-offline-encounter.capture.

@capability:nerdery-capture-offline-encounter
@root-scenario:nerdery-capture-offline-encounter
@scenario:nerdery-capture-offline-encounter
@input:nerdery-capture-offline-encounter-request
@input-contract:nerdery-capture-offline-encounter-request.v1
@event:nerdery-capture-offline-encounter-requested
@event-authority:nerdery-capture-offline-encounter.v1
@outcome:nerdery-capture-offline-encounter-outcome
@outcome-contract:nerdery-capture-offline-encounter-result.v1
@outcome-terminal
Feature: Capture an encounter while disconnected
  As a previously signed-in user with a cached animal catalog
  I want to retain an encounter locally when there is no internet connection
  So that I do not lose the animal selection, location and photo before I can synchronize

  Rule: Offline capture retains the required data locally without claiming a server-recorded collection

    # Source requirements: NRD-Q06, NRD-E01, NRD-E02, NRD-E04.
    # Proposed decisions: D01, D07, D09, D10.
    # Arrangement: fixtures/cases/nrd-offline-capture.json (sha256:1caa8c7e7e0f0df943316a65c9478e10c1b5af9cf35eb44ac07e9f74795b9cc7).
    # Proposed provider calls (unbound): retain-offline-wildlife-draft.
    @case:nrd-offline-capture
    @status:not-built
    Scenario: A disconnected user retains a complete local draft across reload
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic offline path"
          },
          "localPhotoRef": "local-photo-a",
          "nickname": "Offline Reed"
        }
        """
      And Avery previously signed in, the catalog and photo are on the device, and the device will reload while disconnected
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | PENDING_SYNC |
        | nerdery-capture-offline-encounter.capture | $.draft.encounterId | offline-001 |
        | nerdery-capture-offline-encounter.capture | $.draft.ownerUserId | user-a |
        | nerdery-capture-offline-encounter.capture | $.draft.photoRetained | true |
        | nerdery-capture-offline-encounter.capture | $.serverRecorded | false |
        | nerdery-capture-offline-encounter.capture | $.serverCollectionUnlocked | false |
        | nerdery-capture-offline-encounter.capture | $.draft.location | {"source":"manual","description":"Synthetic offline path"} |
        | nerdery-capture-offline-encounter.capture | $.draft.nickname | Offline Reed |
        | nerdery-capture-offline-encounter.capture | $.draft.definitionId | animal-001 |

    # Source requirements: NRD-Q06, NRD-E02.
    # Proposed decisions: D01, D09.
    # Arrangement: fixtures/cases/nrd-offline-device-location.json (sha256:e0358ca4c6cb38011604011f79054749333f1af4ffe5d73a9716dbbc889f8a5f).
    # Proposed provider calls (unbound): retain-offline-wildlife-draft.
    @case:nrd-offline-device-location
    @status:not-built
    Scenario: Available device coordinates can populate the disconnected draft
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "location": {
            "source": "device",
            "latitude": 42.0,
            "longitude": -83.0
          },
          "localPhotoRef": "local-photo-a",
          "nickname": "Offline Reed"
        }
        """
      And the device is offline with the selected animal cached and coordinates available
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | PENDING_SYNC |
        | nerdery-capture-offline-encounter.capture | $.draft.location | {"source":"device","latitude":42.0,"longitude":-83.0} |
        | nerdery-capture-offline-encounter.capture | $.draft.photoRetained | true |
        | nerdery-capture-offline-encounter.capture | $.serverRecorded | false |

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D09, D10.
    # Arrangement: fixtures/cases/nrd-offline-missing-localphotoref.json (sha256:b70f82cec1a37091867348c30a65c03ab666ec0eadfe25fcaceac30954656bc4).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-offline-missing-localphotoref
    @status:not-built
    Scenario: Capturing a draft offline requires local photo reference
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic offline path"
          },
          "nickname": "Offline Reed"
        }
        """
      And Avery is offline with a cached catalog and the request omits a required capture field
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | REFUSED |
        | nerdery-capture-offline-encounter.capture | $.reason.code | PHOTO_REQUIRED |
        | nerdery-capture-offline-encounter.capture | $.mutation.applied | false |

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D09, D10.
    # Arrangement: fixtures/cases/nrd-offline-missing-location.json (sha256:78b16e8b50a9f6093367ade7cbfa3c153960dbd71a1d81e86db1fc52a4123ba0).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-offline-missing-location
    @status:not-built
    Scenario: Capturing a draft offline requires location
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "localPhotoRef": "local-photo-a",
          "nickname": "Offline Reed"
        }
        """
      And Avery is offline with a cached catalog and the request omits a required capture field
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | REFUSED |
        | nerdery-capture-offline-encounter.capture | $.reason.code | LOCATION_REQUIRED |
        | nerdery-capture-offline-encounter.capture | $.mutation.applied | false |

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D09.
    # Arrangement: fixtures/cases/nrd-offline-no-catalog.json (sha256:98b35fedce208393220b20d177c259c987d1970f71cb2ca7136a4e34f0b8fef5).
    # Proposed provider calls (unbound): retain-offline-wildlife-draft.
    @case:nrd-offline-no-catalog
    @status:not-built
    Scenario: A cold offline visit does not invent an animal catalog
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic offline path"
          },
          "localPhotoRef": "local-photo-a",
          "nickname": "Offline Reed"
        }
        """
      And the device is offline with an empty local catalog
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | REFUSED |
        | nerdery-capture-offline-encounter.capture | $.reason.code | CACHED_ANIMAL_UNAVAILABLE |
        | nerdery-capture-offline-encounter.capture | $.mutation.applied | false |

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D09.
    # Arrangement: fixtures/cases/nrd-offline-local-storage-failure.json (sha256:d7ab06f2f652647f1e4e7bb0cf2b42502393a41528b2a240854861c33f02d2cc).
    # Proposed provider calls (unbound): retain-offline-wildlife-draft.
    @case:nrd-offline-local-storage-failure
    @status:not-built
    Scenario: A failed local write does not claim the encounter was retained
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic offline path"
          },
          "localPhotoRef": "local-photo-a",
          "nickname": "Offline Reed"
        }
        """
      And the device is offline and local draft storage fails before commit
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | REFUSED |
        | nerdery-capture-offline-encounter.capture | $.reason.code | LOCAL_STORAGE_UNAVAILABLE |
        | nerdery-capture-offline-encounter.capture | $.mutation.applied | false |
