# nerdery-view-animal-definition: canonical-feature candidate for owner review, 2026-11-02.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples; not a new platform format.
# Status: feature candidate. The proposed capability is absent from estate model 34 (inventory run 49ae8acb).
# @status:not-built means this delivery contains no implementation or run evidence for the case.
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# Expected business read: @provider:sql-database-reader. Model 34 contract and synthetic read proof b5b5a835.
# See review/provider-bindings.md for provider scope, evidence and open bindings. Fixture preparation is separate.
# A successful write requires durable provider testimony and independent read-back; output echoes are not proof.
# All JSON shapes/identities are proposed under D01. Case design decisions remain proposals, not Nerdery requirements.
# Scope: mvp. Source requirements: NRD-U03, NRD-D01, NRD-D02, NRD-D03, NRD-D04, NRD-D05, NRD-A01, NRD-A02, NRD-C02.
# Proposed outcome contract: nerdery-view-animal-definition-result.v1; terminal variants: VISIBLE, REFUSED.
# Proposed operation identity: nerdery-view-animal-definition.view.

@capability:nerdery-view-animal-definition
@root-scenario:nerdery-view-animal-definition
@scenario:nerdery-view-animal-definition
@input:nerdery-view-animal-definition-request
@input-contract:nerdery-view-animal-definition-request.v1
@event:nerdery-view-animal-definition-requested
@event-authority:nerdery-view-animal-definition.v1
@outcome:nerdery-view-animal-definition-outcome
@outcome-contract:nerdery-view-animal-definition-result.v1
@outcome-terminal
Feature: View the information unlocked for an animal definition
  As a wildlife application user
  I want to inspect a selected animal definition
  So that I can learn from the animal information that my collection has unlocked

  Rule: The direct read enforces the same collection-based field restriction as the overview

    # Source requirements: NRD-C02, NRD-D01, NRD-D02, NRD-D03.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-animal-detail-locked.json (sha256:96076c9561058484532811546334d843328da181d872429a6decdbcc2b640f67).
    @case:nrd-animal-detail-locked
    @status:not-built
    @provider:sql-database-reader
    Scenario: A direct detail request cannot bypass the uncollected restriction
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-001"
        }
        """
      And Avery has no encounters and requests Demo Heron directly
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | VISIBLE |
        | nerdery-view-animal-definition.view | $.collectionState | UNCOLLECTED |
        | nerdery-view-animal-definition.view | $.animal | {"commonName":"Demo Heron","collectionNumber":1,"range":["county-a"],"avatarPhotoRef":"avatar-001"} |

    # Source requirements: NRD-C02, NRD-D01, NRD-D04, NRD-D05, NRD-A01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-animal-detail-unlocked.json (sha256:4f871ea8086b1f1b7b8a538737cd361ef7976c2b78279294cbe681ef4b3d72be).
    @case:nrd-animal-detail-unlocked
    @status:not-built
    @provider:sql-database-reader
    Scenario: An owned encounter unlocks all catalog properties
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-001"
        }
        """
      And Avery has recorded Demo Heron and requests its definition directly
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | VISIBLE |
        | nerdery-view-animal-definition.view | $.collectionState | COLLECTED |
        | nerdery-view-animal-definition.view | $.animal.scientificName | Synthetic scientific label 1 |
        | nerdery-view-animal-definition.view | $.animal.types | ["Flying","Aquatic"] |
        | nerdery-view-animal-definition.view | $.animal.stats | {"Strength":2,"Size":3,"Speed":4} |
        | nerdery-view-animal-definition.view | $.animal.attributes | [{"attributeId":"habitat","valueIds":["wetland"]},{"attributeId":"diet","valueIds":["fish"]}] |

    # Source requirements: NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-animal-detail-missing.json (sha256:e32ad618583b8c4bba2bfb563fc5fcf2ef2f7ffd885180e7091c364ec7ac8197).
    @case:nrd-animal-detail-missing
    @status:not-built
    @provider:sql-database-reader
    Scenario: An unknown definition produces a named refusal
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-missing"
        }
        """
      And there is no definition for the requested ID
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | REFUSED |
        | nerdery-view-animal-definition.view | $.reason.code | ANIMAL_DEFINITION_NOT_FOUND |
        | nerdery-view-animal-definition.view | $.animal | (absent) |

    # Source requirements: NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-animal-detail-cross-user-cache.json (sha256:54a018e29153a63714bcb15395f796c4fb79434c59776a20f566e64e52a0cca5).
    # The prewarm call is setup only and cannot serve as acceptance evidence for this case.
    @case:nrd-animal-detail-cross-user-cache
    @status:not-built
    @provider:sql-database-reader
    Scenario: A prior unlocked read does not leak through a shared cache
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-002"
        }
        """
      And Avery's unlocked Demo Fox read has warmed the cache and Blake has never collected Demo Fox
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | VISIBLE |
        | nerdery-view-animal-definition.view | $.collectionState | UNCOLLECTED |
        | nerdery-view-animal-definition.view | $.animal | {"commonName":"Demo Fox","collectionNumber":2,"range":["county-a"],"avatarPhotoRef":"avatar-002"} |

    # Source requirements: NRD-C02, NRD-A01, NRD-A02.
    # Proposed decisions: D01, D14.
    # Arrangement: fixtures/cases/nrd-animal-detail-attribute-information.json (sha256:94f12d0f6bed4df0665e3caf1b8b43ad4bcee155008c7437781d717bdfa0bdca).
    @case:nrd-animal-detail-attribute-information
    @status:not-built
    @provider:sql-database-reader
    Scenario: An unlocked animal exposes the shared attribute meaning and its selected values
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-001"
        }
        """
      And Avery has collected Demo Heron and its only assigned attribute in this fixture is Habitat with the wetland value
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | VISIBLE |
        | nerdery-view-animal-definition.view | $.animal.attributeDetails[0].attributeId | habitat |
        | nerdery-view-animal-definition.view | $.animal.attributeDetails[0].name | Habitat |
        | nerdery-view-animal-definition.view | $.animal.attributeDetails[0].description | Synthetic fixture habitat |
        | nerdery-view-animal-definition.view | $.animal.attributeDetails[0].selectedValues | [{"valueId":"wetland","label":"Wetland"}] |

  Rule: A biologist browsing a personal collection sees the same lock as a citizen

    # Source requirements: NRD-U03, NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-animal-detail-biologist-locked.json (sha256:2fb3a73dc8aaeb2b00916c84334c405b248ccda83928e8106a505448f837c61a).
    @case:nrd-animal-detail-biologist-locked
    @status:not-built
    @provider:sql-database-reader
    Scenario: A biologist cannot unlock an uncollected animal through the personal detail page
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-002"
        }
        """
      And Casey is a biologist with an encounter for Demo Heron and none for Demo Fox
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | VISIBLE |
        | nerdery-view-animal-definition.view | $.collectionState | UNCOLLECTED |
        | nerdery-view-animal-definition.view | $.animal | {"commonName":"Demo Fox","collectionNumber":2,"range":["county-a"],"avatarPhotoRef":"avatar-002"} |
