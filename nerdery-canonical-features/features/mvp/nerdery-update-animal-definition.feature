# nerdery-update-animal-definition: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U01, NRD-D01, NRD-D03, NRD-D04, NRD-A01, NRD-A02.
# Proposed outcome contract: nerdery-update-animal-definition-result.v1; terminal variants: UPDATED, REFUSED.
# Proposed operation identity: nerdery-update-animal-definition.update.

@capability:nerdery-update-animal-definition
@root-scenario:nerdery-update-animal-definition
@scenario:nerdery-update-animal-definition
@input:nerdery-update-animal-definition-request
@input-contract:nerdery-update-animal-definition-request.v1
@event:nerdery-update-animal-definition-requested
@event-authority:nerdery-update-animal-definition.v1
@outcome:nerdery-update-animal-definition-outcome
@outcome-contract:nerdery-update-animal-definition-result.v1
@outcome-terminal
Feature: Update an animal definition
  As a biologist
  I want to update an existing animal definition
  So that the catalog reflects the maintained wildlife information

  Rule: Definition changes preserve identity and apply only to the expected current revision

    # Source requirements: NRD-U01, NRD-D01, NRD-D03.
    # Proposed decisions: D01, D13.
    # Arrangement: fixtures/cases/nrd-definition-update.json (sha256:08f76c355c38351e84a6e8113e7daba0dc259a6a826a328d879b6e3d4e00b5e8).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-update
    @status:not-built
    Scenario: A biologist updates a definition without replacing its identity
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "wetland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Demo Heron is at revision 1 and Casey is signed in as a biologist
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | UPDATED |
        | nerdery-update-animal-definition.update | $.animal.definitionId | animal-001 |
        | nerdery-update-animal-definition.update | $.animal.commonName | Demo Heron Updated |
        | nerdery-update-animal-definition.update | $.animal.range | ["county-a","county-b"] |
        | nerdery-update-animal-definition.update | $.animal.revision | 2 |
        | nerdery-update-animal-definition.update | $.mutation.applied | true |

    # Source requirements: NRD-U01, NRD-A01, NRD-A02.
    # Proposed decisions: D01, D08, D13.
    # Arrangement: fixtures/cases/nrd-definition-update-attribute-association.json (sha256:3cef40f8e01e2d0e5832d17401f9fa26b4e8dc9cf6096ff65d4aec0e360a3524).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-update-attribute-association
    @status:not-built
    Scenario: A biologist changes the selectable attribute values associated with an animal
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "plants"
                ]
              }
            ]
          }
        }
        """
      And Demo Heron currently references the wetland habitat value and Casey can maintain its definition
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | UPDATED |
        | nerdery-update-animal-definition.update | $.animal.attributes | [{"attributeId":"habitat","valueIds":["woodland"]},{"attributeId":"diet","valueIds":["plants"]}] |
        | nerdery-update-animal-definition.update | $.mutation.applied | true |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-definition-update-citizen.json (sha256:96d3797757947f546256bb0a701b0a1b3aabfa1c2289295979e46f0c08fe702e).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-update-citizen
    @status:not-built
    Scenario: A citizen cannot update a definition
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "wetland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Avery is a citizen submitting a change to an existing definition
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | REFUSED |
        | nerdery-update-animal-definition.update | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-update-animal-definition.update | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D13.
    # Arrangement: fixtures/cases/nrd-definition-update-stale.json (sha256:b4ce8f646512504127052f78f392d0f7cd76f74b525f5962b64efece6493273c).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-update-stale
    @status:not-built
    Scenario: A stale edit does not overwrite a newer definition
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 0,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "wetland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Casey proposes a replacement from revision 0 while the catalog holds revision 1
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | REFUSED |
        | nerdery-update-animal-definition.update | $.reason.code | REVISION_CONFLICT |
        | nerdery-update-animal-definition.update | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D13.
    # Arrangement: fixtures/cases/nrd-definition-update-missing.json (sha256:583fe7453f07602a93b51f655aadcfc150562597c46b0a596169570629cb49f0).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-update-missing
    @status:not-built
    Scenario: An update cannot create a missing definition
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-missing",
          "expectedRevision": 1,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "wetland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And the requested definition ID has no catalog record
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | REFUSED |
        | nerdery-update-animal-definition.update | $.reason.code | ANIMAL_DEFINITION_NOT_FOUND |
        | nerdery-update-animal-definition.update | $.mutation.applied | false |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08, D13.
    # Arrangement: fixtures/cases/nrd-definition-update-three-types.json (sha256:1edf1b7bc9cd397f596039647250db7c887f6d64c25359b19c34d5ff13c8338c).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-update-three-types
    @status:not-built
    Scenario: An update cannot bypass the two-type limit
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic",
              "Metro"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "wetland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits three types for a definition at the requested revision
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | REFUSED |
        | nerdery-update-animal-definition.update | $.reason.code | ANIMAL_TYPE_LIMIT_EXCEEDED |
        | nerdery-update-animal-definition.update | $.mutation.applied | false |
