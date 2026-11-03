# nerdery-record-animal-encounter: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U02, NRD-U03, NRD-C01, NRD-E01, NRD-E02, NRD-E03, NRD-E04, NRD-E05, NRD-E06.
# Proposed outcome contract: nerdery-record-animal-encounter-result.v1; terminal variants: RECORDED, REFUSED.
# Proposed operation identity: nerdery-record-animal-encounter.record.

@capability:nerdery-record-animal-encounter
@root-scenario:nerdery-record-animal-encounter
@scenario:nerdery-record-animal-encounter
@input:nerdery-record-animal-encounter-request
@input-contract:nerdery-record-animal-encounter-request.v1
@event:nerdery-record-animal-encounter-requested
@event-authority:nerdery-record-animal-encounter.v1
@outcome:nerdery-record-animal-encounter-outcome
@outcome-contract:nerdery-record-animal-encounter-result.v1
@outcome-terminal
Feature: Record an animal encounter
  As a citizen or biologist
  I want to record an animal I encountered with its location and my photo
  So that the individual animal is in my collection

  Rule: A recorded encounter has its own identity and does not require in-application photo verification

    # Source requirements: NRD-U02, NRD-C01, NRD-E01, NRD-E02, NRD-E03, NRD-E04.
    # Proposed decisions: D01, D05, D07, D10.
    # Arrangement: fixtures/cases/nrd-encounter-manual.json (sha256:1f4d866b3ba07523a4b2ff09dedcc974e0706ef48f6a36ab08439e5c85abaa93).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-manual
    @status:not-built
    Scenario: A citizen collects Demo Heron for the first time using a manual location
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery has uploaded photo-a and has never collected Demo Heron
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.encounterId | enc-new |
        | nerdery-record-animal-encounter.record | $.encounter.ownerUserId | user-a |
        | nerdery-record-animal-encounter.record | $.encounter.definitionId | animal-001 |
        | nerdery-record-animal-encounter.record | $.encounter.location | {"source":"manual","description":"Synthetic park, north path"} |
        | nerdery-record-animal-encounter.record | $.encounter.photoRef | photo-a |
        | nerdery-record-animal-encounter.record | $.encounter.nickname | Reed |
        | nerdery-record-animal-encounter.record | $.collectionState | COLLECTED |
        | nerdery-record-animal-encounter.record | $.verificationPerformed | false |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |

    # Source requirements: NRD-E01, NRD-E02.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-device.json (sha256:c7b36921965e9670fa0f6d17eeb8f1a10153d39a0d1af2eb56d627d369be39a4).
    # Coordinates are arbitrary fixture values, not a selected state or actual sighting.
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-device
    @status:not-built
    Scenario: A user records an encounter with device-supplied coordinates
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "device",
            "latitude": 42.0,
            "longitude": -83.0
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery owns the retained photo and the request carries device coordinates
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.location | {"source":"device","latitude":42.0,"longitude":-83.0} |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |

    # Source requirements: NRD-E04.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-encounter-no-nickname.json (sha256:0da03fda95b7ddc2ce5b560cb42c185d14168d28089626e2a37b626d68d9c1b6).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-no-nickname
    @status:not-built
    Scenario: A nickname is optional
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a"
        }
        """
      And Avery owns the photo and omits the optional nickname
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.nickname | null |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |

    # Source requirements: NRD-U03, NRD-E01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-encounter-biologist.json (sha256:e02ab312029b8f7c3a6c8338c93d7686c00ba3209b81e33a9f094a24287b4b0d).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-biologist
    @status:not-built
    Scenario: A biologist can record a personal encounter
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-bio",
          "nickname": "Reed"
        }
        """
      And Casey is a biologist recording a personal encounter with Casey's own photo
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.ownerUserId | user-bio |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |

    # Source requirements: NRD-U02, NRD-E05, NRD-E06.
    # Proposed decisions: D01, D05, D07.
    # Arrangement: fixtures/cases/nrd-encounter-another-individual.json (sha256:246455254f1b440b17736a3c4a2be85192fb141e9d009ede160e065ceb955a0a).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-another-individual
    @status:not-built
    Scenario: A new request records another individual of an already collected definition
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-another",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery already has two encounters with Demo Heron and submits a new encounter ID
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.encounterId | enc-another |
        | nerdery-record-animal-encounter.record | $.encounter.definitionId | animal-001 |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |

  Rule: An encounter requires an available animal, a location and an owned photo

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-missing-definitionid.json (sha256:963db515860029fca4ca70bbe8ac999ec1450480922c45c553965ab21c886ac2).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-encounter-missing-definitionid
    @status:not-built
    Scenario: Recording an encounter requires animal selection
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery is signed in and the request omits the required field identified in this case
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | ANIMAL_SELECTION_REQUIRED |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-missing-location.json (sha256:ea5b7a8eeb054803dcdaad6d9892fd26c84f13fb279f5c102815da2aee4bffc8).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-encounter-missing-location
    @status:not-built
    Scenario: Recording an encounter requires location
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery is signed in and the request omits the required field identified in this case
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | LOCATION_REQUIRED |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-missing-photoref.json (sha256:e83697f19332a2fa62656868f59ec2384adf46a12c842d36ecb598635a7c5089).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-encounter-missing-photoref
    @status:not-built
    Scenario: Recording an encounter requires uploaded photo reference
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "nickname": "Reed"
        }
        """
      And Avery is signed in and the request omits the required field identified in this case
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | PHOTO_REQUIRED |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-encounter-unknown-definition.json (sha256:ddc9acf804bf8d08fe0ac4b5ed10addf247e3c344eb05bd31135cac39cfcbbd3).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-unknown-definition
    @status:not-built
    Scenario: The selected animal must be in the catalog
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-missing",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And the selected animal ID does not exist
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | ANIMAL_DEFINITION_NOT_FOUND |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D03, D08.
    # Arrangement: fixtures/cases/nrd-encounter-removed-definition.json (sha256:ca74d94f2052b9e56296b47089d40bf4dc96010fd66e4750d9d6f898179879e2).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-removed-definition
    @status:not-built
    Scenario: A newly recorded encounter cannot select a removed definition
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Demo Heron is retained for history but is inactive in the catalog
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | ANIMAL_DEFINITION_UNAVAILABLE |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-foreign-photo.json (sha256:e3e96058ef0f4309d61e8778e2c7325ded9f4ef8b9a4b1daec66b9877e684509).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-foreign-photo
    @status:not-built
    Scenario: Another user's photo cannot be attached to this encounter
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-other",
          "nickname": "Reed"
        }
        """
      And the referenced photo belongs to Blake and Avery is recording the encounter
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | PHOTO_NOT_AVAILABLE_TO_USER |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-unretained-photo.json (sha256:998e71a2be7cdeb3383fd03b7296dd5b9dbf6ef46625d13cef2a73bb9a497b5b).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-unretained-photo
    @status:not-built
    Scenario: A nonexistent photo reference is not an uploaded photo
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-missing",
          "nickname": "Reed"
        }
        """
      And there is no retained photo at the requested reference
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | PHOTO_NOT_AVAILABLE_TO_USER |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-U02, NRD-E01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-encounter-anonymous.json (sha256:e7f17463bfecf5fe4b7a0d30bcc963bf9bb3cc5a19778a30230340c3662f7c1c).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-encounter-anonymous
    @status:not-built
    Scenario: A recorded encounter requires an authenticated owner
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And there is no authenticated owner for the encounter
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01, NRD-C01.
    # Proposed decisions: D01, D05, D07.
    # Arrangement: fixtures/cases/nrd-encounter-write-failure.json (sha256:29bff45c03b612b42b9d28f1fa30e3304a6e19f9640e0d8b08c168f178e25080).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-write-failure
    @status:not-built
    Scenario: A failed encounter write does not unlock the animal
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery has no encounters and collection storage fails before the write commits
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | COLLECTION_STORAGE_UNAVAILABLE |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

  Rule: Retries of one request do not collapse distinct encounters or duplicate the same encounter

    # Source requirements: NRD-E05, NRD-E06.
    # Proposed decisions: D01, D05, D07.
    # Arrangement: fixtures/cases/nrd-encounter-retry.json (sha256:23a0e4362e64bcd63c81eaaa5d7b2f12128f1f2e442544a8790d07f093124d75).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-retry
    @status:not-built
    Scenario: Retrying the same request returns its one existing encounter
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery's identical request for enc-new was already committed
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.encounterId | enc-new |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.replayed | true |
        | nerdery-record-animal-encounter.record | $.encounter.photoRef | photo-a |
        | nerdery-record-animal-encounter.record | $.encounter.nickname | Reed |
        | nerdery-record-animal-encounter.record | $.encounter.ownerUserId | user-a |

    # Source requirements: NRD-E05, NRD-E06.
    # Proposed decisions: D01, D05, D07.
    # Arrangement: fixtures/cases/nrd-encounter-id-conflict.json (sha256:f9e13f1bf0179048d019ebca724e03130bd16458092a1b8d2aa0733f9f260577).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-id-conflict
    @status:not-built
    Scenario: Reusing the request identity with changed content is refused
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Changed"
        }
        """
      And Avery's enc-new was already committed with the nickname Reed
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | ENCOUNTER_ID_CONFLICT |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-U02, NRD-E05, NRD-E06.
    # Proposed decisions: D01, D05, D07.
    # Arrangement: fixtures/cases/nrd-encounter-same-id-other-owner.json (sha256:65d827682b3d15ce1a6cc8a92ef584bfb19e238a4a83676d83d591ccba573d5b).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-same-id-other-owner
    @status:not-built
    Scenario: A second user can record a personal encounter with the same request ID
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-other",
          "nickname": "Brook"
        }
        """
      And Avery has already committed enc-new and Blake is signed in with Blake's own photo
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.encounterId | enc-new |
        | nerdery-record-animal-encounter.record | $.encounter.ownerUserId | user-b |
        | nerdery-record-animal-encounter.record | $.encounter.photoRef | photo-other |
        | nerdery-record-animal-encounter.record | $.encounter.nickname | Brook |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |
