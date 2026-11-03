# nerdery-add-animal-definition: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U01, NRD-D01, NRD-D02, NRD-D03, NRD-D04, NRD-D05, NRD-A01, NRD-A02.
# Proposed outcome contract: nerdery-add-animal-definition-result.v1; terminal variants: ADDED, REFUSED.
# Proposed operation identity: nerdery-add-animal-definition.add.

@capability:nerdery-add-animal-definition
@root-scenario:nerdery-add-animal-definition
@scenario:nerdery-add-animal-definition
@input:nerdery-add-animal-definition-request
@input-contract:nerdery-add-animal-definition-request.v1
@event:nerdery-add-animal-definition-requested
@event-authority:nerdery-add-animal-definition.v1
@outcome:nerdery-add-animal-definition-outcome
@outcome-contract:nerdery-add-animal-definition-result.v1
@outcome-terminal
Feature: Add an animal definition
  As a biologist
  I want to add a supported animal definition with its properties
  So that users can discover and collect that animal

  Rule: A biologist can add a complete definition that respects the stated type limit and reference catalog

    # Source requirements: NRD-U01, NRD-D01, NRD-D02, NRD-D03, NRD-D04, NRD-D05, NRD-A01, NRD-A02.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-add.json (sha256:c6c2589f2c30b14d623dd8129d4fb31223fdbd33bd9cb5d89e42e84bc94d3ffd).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-add
    @status:not-built
    Scenario: A biologist adds the complete definition
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Casey is a biologist, avatar-004 is retained and public collection number 4 is available
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | ADDED |
        | nerdery-add-animal-definition.add | $.animal.commonName | Demo Owl |
        | nerdery-add-animal-definition.add | $.animal.scientificName | Synthetic scientific label 4 |
        | nerdery-add-animal-definition.add | $.animal.avatarPhotoRef | avatar-004 |
        | nerdery-add-animal-definition.add | $.animal.collectionNumber | 4 |
        | nerdery-add-animal-definition.add | $.animal.range | ["county-a"] |
        | nerdery-add-animal-definition.add | $.animal.types | ["Flying"] |
        | nerdery-add-animal-definition.add | $.animal.stats | {"Strength":5,"Size":6,"Speed":7} |
        | nerdery-add-animal-definition.add | $.animal.attributes | [{"attributeId":"habitat","valueIds":["woodland"]},{"attributeId":"diet","valueIds":["fish"]}] |
        | nerdery-add-animal-definition.add | $.mutation.applied | true |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-zero-types.json (sha256:2c1399bc90b6255371c22eadedba30790b8c29bf92c4bb7edc2f9bf931d27caf).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-zero-types
    @status:not-built
    Scenario: Up to two types permits zero types
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and the type catalog has fifteen entries
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | ADDED |
        | nerdery-add-animal-definition.add | $.animal.types | [] |
        | nerdery-add-animal-definition.add | $.mutation.applied | true |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-two-types.json (sha256:d7d3bb0c0badf8e3d2d66e3c9a2b2192877d4fe7af9fa8bef56e8d8435069528).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-two-types
    @status:not-built
    Scenario: Up to two types permits two types
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and the type catalog has fifteen entries
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | ADDED |
        | nerdery-add-animal-definition.add | $.animal.types | ["Flying","Aquatic"] |
        | nerdery-add-animal-definition.add | $.mutation.applied | true |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-three-types.json (sha256:2fb53e062828aa007544a42018ae85fad6e6f8b50a8a3ef60f0566e0bad9442d).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-three-types
    @status:not-built
    Scenario: The new definition refuses three types
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying",
              "Aquatic",
              "Rural"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and the type catalog has fifteen entries
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_TYPE_LIMIT_EXCEEDED |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-unknown-type.json (sha256:4268b86a683120bc7fe38d9830c717a114c8bfb2a68a8cbd955a17d94a65fcc8).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-unknown-type
    @status:not-built
    Scenario: The new definition refuses unknown type
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "UnknownType"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And UnknownType is absent from the type catalog
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_TYPE_UNKNOWN |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D03.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-unknown-county.json (sha256:fe9f7f0944e198ef9630cbe4b1e64c978f4a2cb3142a77ac3ae072409e1cccd8).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-unknown-county
    @status:not-built
    Scenario: The new definition refuses unknown county
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-unknown"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And county-unknown is absent from the fixture state's county catalog
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | COUNTY_UNKNOWN |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D02.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-duplicate-number.json (sha256:995165dd5d5ba8911311b260d26bbdad38bb2db65ccb6df1f16a82a59d9c791b).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-duplicate-number
    @status:not-built
    Scenario: The new definition refuses duplicate number
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 1,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Demo Heron already holds public collection number 1
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | COLLECTION_NUMBER_NOT_UNIQUE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-A01, NRD-A02.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-unknown-attribute-value.json (sha256:099cb26e820df12357eddaba1747f1c08d45c1bedf667b2ef7f80985095682da).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-unknown-attribute-value
    @status:not-built
    Scenario: The new definition refuses unknown attribute value
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "desert"
                ]
              }
            ]
          }
        }
        """
      And the requested association uses a value outside the attribute's selectable values
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ATTRIBUTE_VALUE_NOT_SELECTABLE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

  Rule: A definition includes the intrinsic properties in the challenge

    # Source requirements: NRD-D01.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-commonname.json (sha256:4787ec6703247947c4acef971e917483f6e2dfee2276427d746ca7efd53e6562).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-commonname
    @status:not-built
    Scenario: Adding an animal definition requires common name
      Given a proposed animal definition
        """json
        {
          "animal": {
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits the definition with the indicated intrinsic property omitted
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D01.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-scientificname.json (sha256:bcf60509ef8fdedde19e946e1563ead8015e44ca15402162a3db45d5bf7ec36d).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-scientificname
    @status:not-built
    Scenario: Adding an animal definition requires scientific name
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits the definition with the indicated intrinsic property omitted
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D01.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-avatarphotoref.json (sha256:c5c614a0ad8b3b9ebaa2181672c3ca6386cfe05f1ca5649bb9443adc7da85279).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-avatarphotoref
    @status:not-built
    Scenario: Adding an animal definition requires on-file photo reference
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits the definition with the indicated intrinsic property omitted
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D02.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-collectionnumber.json (sha256:5315f7904538484fd1e335bbc91cbd57a6db63b7f3ce0533d478c746e96bad44).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-collectionnumber
    @status:not-built
    Scenario: Adding an animal definition requires public collection number
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits the definition without a public collection number
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D03.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-range.json (sha256:aa8aa27c0831cec361615295a7440390068a319b0a261bd4030b54748a25b1f9).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-range
    @status:not-built
    Scenario: Adding an animal definition requires county range
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits the definition without its county range
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-types.json (sha256:c2147d7b7a8328412d114774b26612cb8b92cb6b9247d891683fc0365be2d415).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-types
    @status:not-built
    Scenario: Adding an animal definition requires types field
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist omits the types field entirely
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D05.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-stats.json (sha256:aa277eb9f598cbc5b8b64e8b57982c1ccabac53dc004da03cfd8cee86599a025).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-stats
    @status:not-built
    Scenario: Adding an animal definition requires stats field
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist omits the stats field entirely
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

  Rule: Only a biologist can add a catalog definition

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-definition-citizen-add.json (sha256:eb1eb354375391e888fc9756c375c424a02a99bdf2d5ec143651603d5a93bff3).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-citizen-add
    @status:not-built
    Scenario: A citizen cannot add an animal definition
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Avery has only the citizen role
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-definition-anonymous-add.json (sha256:2f960b56a3bad0e45477852f1e379505a249aeb8d5cfe60e6119cafe993902dd).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-definition-anonymous-add
    @status:not-built
    Scenario: An unauthenticated caller cannot add an animal definition
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
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
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And no subject is signed in
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |
