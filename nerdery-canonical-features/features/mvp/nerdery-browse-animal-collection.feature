# nerdery-browse-animal-collection: canonical-feature candidate for owner review, 2026-11-02.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples; not a new platform format.
# Status: feature candidate. The proposed capability is absent from estate model 34 (inventory run 49ae8acb).
# @status:not-built means this delivery contains no implementation or run evidence for the case.
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# Expected business read: @provider:sql-database-reader. Model 34 contract and synthetic read proof c2d5ec95.
# See review/provider-bindings.md for provider scope, evidence and open bindings. Fixture preparation is separate.
# A successful write requires durable provider testimony and independent read-back; output echoes are not proof.
# All JSON shapes/identities are proposed under D01. Case design decisions remain proposals, not Nerdery requirements.
# Scope: mvp. Source requirements: NRD-D02, NRD-C01, NRD-C02, NRD-C03, NRD-C04.
# Proposed outcome contract: nerdery-browse-animal-collection-result.v1; terminal variants: LISTED, REFUSED.
# Proposed operation identity: nerdery-browse-animal-collection.browse.

@capability:nerdery-browse-animal-collection
@root-scenario:nerdery-browse-animal-collection
@scenario:nerdery-browse-animal-collection
@input:nerdery-browse-animal-collection-request
@input-contract:nerdery-browse-animal-collection-request.v1
@event:nerdery-browse-animal-collection-requested
@event-authority:nerdery-browse-animal-collection.v1
@outcome:nerdery-browse-animal-collection-outcome
@outcome-contract:nerdery-browse-animal-collection-result.v1
@outcome-terminal
Feature: Browse and search the animal-definition collection
  As a wildlife application user
  I want to browse a numbered catalog and find an animal
  So that I can see what I have collected and discover what remains

  Rule: The catalog is ordered by collection number and uncollected entries expose only the four permitted animal properties

    # Source requirements: NRD-C01, NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-collection-uncollected.json (sha256:1b782d54dbf28a8217fe1c1b7bd85e02f952ab514cccec9c665162f0c59734f7).
    @case:nrd-collection-uncollected
    @status:not-built
    @provider:sql-database-reader
    Scenario: Uncollected entries contain exactly the permitted animal properties
      Given a collection browse request
        """json
        {
          "search": ""
        }
        """
      And Avery is signed in and has no recorded encounters
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.items[0].definitionId | animal-001 |
        | nerdery-browse-animal-collection.browse | $.items[0].collectionState | UNCOLLECTED |
        | nerdery-browse-animal-collection.browse | $.items[0].animal | {"commonName":"Demo Heron","collectionNumber":1,"range":["county-a"],"avatarPhotoRef":"avatar-001"} |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.scientificName | (absent) |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.stats | (absent) |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.attributes | (absent) |

    # Source requirements: NRD-C01, NRD-C03, NRD-D02.
    # Proposed decisions: D01.
    # Arrangement: fixtures/cases/nrd-collection-ordered.json (sha256:5d38e0f8d1364c4da2736483330aea419b13a53199244818c4155cd01cfb5fbb).
    @case:nrd-collection-ordered
    @status:not-built
    @provider:sql-database-reader
    Scenario: Catalog order is the public number rather than the storage order
      Given a collection browse request
        """json
        {
          "search": ""
        }
        """
      And the active definitions are stored in public-number order 3, 1, 2
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.collectionNumber | 1 |
        | nerdery-browse-animal-collection.browse | $.items[1].animal.collectionNumber | 2 |
        | nerdery-browse-animal-collection.browse | $.items[2].animal.collectionNumber | 3 |
        | nerdery-browse-animal-collection.browse | $.total | 3 |
        | nerdery-browse-animal-collection.browse | $.items[3] | (absent) |

    # Source requirements: NRD-C01, NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-collection-collected.json (sha256:e49470466bb17ac1b223c96e53bdafc46a7f47e4500a2765b696e9bdc7bf2420).
    @case:nrd-collection-collected
    @status:not-built
    @provider:sql-database-reader
    Scenario: A recorded encounter unlocks the definition for its owner
      Given a collection browse request
        """json
        {
          "search": "Heron"
        }
        """
      And Avery has recorded Demo Heron and searches the catalog for it
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.items[0].collectionState | COLLECTED |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.scientificName | Synthetic scientific label 1 |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.types | ["Flying","Aquatic"] |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.stats | {"Strength":2,"Size":3,"Speed":4} |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.attributes | [{"attributeId":"habitat","valueIds":["wetland"]},{"attributeId":"diet","valueIds":["fish"]}] |

    # Source requirements: NRD-C01, NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-collection-owner-specific.json (sha256:d57113ea3e58bf35844fa19186fea5f5e5a5a94ca571ad98385eabe85d3972a6).
    @case:nrd-collection-owner-specific
    @status:not-built
    @provider:sql-database-reader
    Scenario: Another user collecting an animal does not unlock it for this user
      Given a collection browse request
        """json
        {
          "search": "Heron"
        }
        """
      And only Blake has recorded Demo Heron and Avery is browsing
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.items[0].collectionState | UNCOLLECTED |
        | nerdery-browse-animal-collection.browse | $.items[0].animal | {"commonName":"Demo Heron","collectionNumber":1,"range":["county-a"],"avatarPhotoRef":"avatar-001"} |
        | nerdery-browse-animal-collection.browse | $.items[0].definitionId | animal-001 |

  Rule: Search uses public catalog information

    # Source requirements: NRD-C04.
    # Proposed decisions: D01, D04.
    # Arrangement: fixtures/cases/nrd-collection-name-search.json (sha256:aeb41ec4dfb61c3971bb697f3de572cfd19ce92e4b11ccd256b4fc228e5627f3).
    @case:nrd-collection-name-search
    @status:not-built
    @provider:sql-database-reader
    Scenario: A common-name substring finds the matching animal
      Given a collection browse request
        """json
        {
          "search": "hErOn"
        }
        """
      And Demo Heron is the only active common name matching the mixed-case search
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.total | 1 |
        | nerdery-browse-animal-collection.browse | $.items[0].definitionId | animal-001 |
        | nerdery-browse-animal-collection.browse | $.items[1] | (absent) |

    # Source requirements: NRD-C04, NRD-D02.
    # Proposed decisions: D01, D04.
    # Arrangement: fixtures/cases/nrd-collection-number-search.json (sha256:4f4d52fa4edf17c2f7383bc0ed184114176c734713e8e00e6a8ffec1280e40a8).
    @case:nrd-collection-number-search
    @status:not-built
    @provider:sql-database-reader
    Scenario: A collection number finds the numbered definition
      Given a collection browse request
        """json
        {
          "search": "2"
        }
        """
      And Demo Fox holds public collection number 2
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.total | 1 |
        | nerdery-browse-animal-collection.browse | $.items[0].definitionId | animal-002 |
        | nerdery-browse-animal-collection.browse | $.items[1] | (absent) |

    # Source requirements: NRD-C04.
    # Proposed decisions: D01, D04.
    # Arrangement: fixtures/cases/nrd-collection-no-matches.json (sha256:83c720e1db4aa67981c553969bd3c635be45706ac57189af7f8425ddc15663a8).
    @case:nrd-collection-no-matches
    @status:not-built
    @provider:sql-database-reader
    Scenario: No match is an empty result rather than a failed browse
      Given a collection browse request
        """json
        {
          "search": "NoSuchAnimal"
        }
        """
      And no active common name or public number matches the search
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.total | 0 |
        | nerdery-browse-animal-collection.browse | $.items | [] |

    # Source requirements: NRD-C02, NRD-C04.
    # Proposed decisions: D01, D04, D05.
    # Arrangement: fixtures/cases/nrd-collection-no-locked-search-leak.json (sha256:a83633380da2e468555db3d15f9f55c6dc6f15a560f84547b370dfc06ff079f7).
    @case:nrd-collection-no-locked-search-leak
    @status:not-built
    @provider:sql-database-reader
    Scenario: A locked scientific label is not a hidden search channel
      Given a collection browse request
        """json
        {
          "search": "Synthetic scientific label 1"
        }
        """
      And Avery has no encounters and searches for a scientific name hidden from the public projection
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.total | 0 |
        | nerdery-browse-animal-collection.browse | $.items | [] |

    # Source requirements: NRD-C01, NRD-C04.
    # Proposed decisions: D01, D03, D04.
    # Arrangement: fixtures/cases/nrd-collection-removed-definition.json (sha256:503d131d5f9a875e6f327895e9871df2e1d2a231dda6a7751d8520bdd3814eb4).
    @case:nrd-collection-removed-definition
    @status:not-built
    @provider:sql-database-reader
    Scenario: A removed definition is absent from active catalog results
      Given a collection browse request
        """json
        {
          "search": "Heron"
        }
        """
      And Demo Heron has been removed from the active catalog
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.total | 0 |
        | nerdery-browse-animal-collection.browse | $.items | [] |

  Rule: A personalized catalog requires a signed-in user and a successful catalog read

    # Source requirements: NRD-C01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-collection-anonymous.json (sha256:091b2c97d4ed9a432e65a97d0229adc6b6fd088b62209dc0079854d347b4256b).
    # This is the personalized collection capability. Anonymous/public browsing remains an undecided separate surface under D05.
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-collection-anonymous
    @status:not-built
    Scenario: A personalized collection read requires authenticated context
      Given a collection browse request
        """json
        {
          "search": ""
        }
        """
      And no authenticated subject is available for a personalized collection
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | REFUSED |
        | nerdery-browse-animal-collection.browse | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-browse-animal-collection.browse | $.items | (absent) |

    # Source requirements: NRD-C01, NRD-C04.
    # Proposed decisions: D01, D04.
    # Arrangement: fixtures/cases/nrd-collection-storage-failure.json (sha256:da9e98931b45c032ffb1c46628a6fe688b460480fd5d87f04f25b2f1f29b7c92).
    @case:nrd-collection-storage-failure
    @status:not-built
    @provider:sql-database-reader
    Scenario: Unavailable catalog storage is not an empty successful search
      Given a collection browse request
        """json
        {
          "search": "Heron"
        }
        """
      And the catalog read is unavailable for a search that would otherwise find Demo Heron
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | REFUSED |
        | nerdery-browse-animal-collection.browse | $.reason.code | CATALOG_STORAGE_UNAVAILABLE |
        | nerdery-browse-animal-collection.browse | $.items | (absent) |
