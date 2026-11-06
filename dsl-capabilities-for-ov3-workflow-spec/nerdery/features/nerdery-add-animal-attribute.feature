# nerdery-add-animal-attribute: canonical-feature candidate for owner review, 2026-11-02.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples; not a new platform format.
# Status: finalized for the SideFX build from the owner-review candidate
# nerdery-canonical-features/features/mvp/nerdery-add-animal-attribute.feature (sha256:512084b5b4381dc391116e28bef95b8edb914e4dd0c61e2f9093d69facbd1826).
# @status:probed: the case ran read-only against the wildlife procedures through nerdery/conformance/run-cases.mjs
# (runs 869e7203, 669ba146, dce56efb).
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# Provider: the operation is one sql-database-reader statement on sfx-identity (EXEC wildlife.serve), so every case is
# tagged @provider:sql-database-reader.
# See review/provider-bindings.md for provider scope, evidence and open bindings. Fixture preparation is separate.
# A successful write requires durable provider testimony and independent read-back; output echoes are not proof.
# All JSON shapes/identities are proposed under D01. Case design decisions remain proposals, not Nerdery requirements.
# Scope: mvp. Source requirements: NRD-U01, NRD-D05, NRD-A02, NRD-A03.
# Proposed outcome contract: nerdery-add-animal-attribute-result.v1; terminal variants: ADDED, REFUSED.
# Proposed operation identity: nerdery-add-animal-attribute.add.

@capability:nerdery-add-animal-attribute
@root-scenario:nerdery-add-animal-attribute
@scenario:nerdery-add-animal-attribute
@input:nerdery-add-animal-attribute-request
@input-contract:nerdery-add-animal-attribute-request.v1
@event:nerdery-add-animal-attribute-requested
@event-authority:nerdery-add-animal-attribute.v1
@outcome:nerdery-add-animal-attribute-outcome
@outcome-contract:nerdery-add-animal-attribute-result.v1
@outcome-terminal
Feature: Add a reusable animal attribute
  As a biologist
  I want to define a distinctive animal attribute and its selectable values
  So that the same property can describe one or many animals

  Rule: A reusable attribute contains its name, description and selectable values

    # Source requirements: NRD-U01, NRD-A02.
    # Proposed decisions: D01.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-attribute-add.json (sha256:6db2ea3d98a610ae8d9d4b043929f09e00c5d58ec24a2fde2e98f54d4f9e1b14).
    @case:nrd-attribute-add
    @status:probed
    @provider:sql-database-reader
    Scenario: A biologist adds an attribute with selectable values
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "name": "Activity period",
            "description": "Synthetic activity-period attribute",
            "selectableValues": [
              {
                "valueId": "day",
                "label": "Day"
              },
              {
                "valueId": "night",
                "label": "Night"
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and Activity period is a new attribute
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | ADDED |
        | nerdery-add-animal-attribute.add | $.attribute.name | Activity period |
        | nerdery-add-animal-attribute.add | $.attribute.description | Synthetic activity-period attribute |
        | nerdery-add-animal-attribute.add | $.attribute.selectableValues | [{"valueId":"day","label":"Day"},{"valueId":"night","label":"Night"}] |
        | nerdery-add-animal-attribute.add | $.mutation.applied | true |

    # Source requirements: NRD-A02.
    # Proposed decisions: D01.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-attribute-missing-name.json (sha256:04b9de2881d2eeeb10d1aa24d128602a42a73c83d9962a4216ceb56088a29eb4).
    @case:nrd-attribute-missing-name
    @status:probed
    @provider:sql-database-reader
    Scenario: Adding an attribute requires name
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "description": "Synthetic activity-period attribute",
            "selectableValues": [
              {
                "valueId": "day",
                "label": "Day"
              },
              {
                "valueId": "night",
                "label": "Night"
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and the request omits one required attribute field
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | REFUSED |
        | nerdery-add-animal-attribute.add | $.reason.code | ANIMAL_ATTRIBUTE_INCOMPLETE |
        | nerdery-add-animal-attribute.add | $.mutation.applied | false |

    # Source requirements: NRD-A02.
    # Proposed decisions: D01.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-attribute-missing-description.json (sha256:838d999917ae0ddb0ada3ad458fee031c39b0bbf206380256db6cd4da0567690).
    @case:nrd-attribute-missing-description
    @status:probed
    @provider:sql-database-reader
    Scenario: Adding an attribute requires description
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "name": "Activity period",
            "selectableValues": [
              {
                "valueId": "day",
                "label": "Day"
              },
              {
                "valueId": "night",
                "label": "Night"
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and the request omits one required attribute field
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | REFUSED |
        | nerdery-add-animal-attribute.add | $.reason.code | ANIMAL_ATTRIBUTE_INCOMPLETE |
        | nerdery-add-animal-attribute.add | $.mutation.applied | false |

    # Source requirements: NRD-A02.
    # Proposed decisions: D01.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-attribute-missing-selectablevalues.json (sha256:8e45649cbfc6c733dfea4cdd608865999a6e010f5464be7ba465ae32ad1e0028).
    @case:nrd-attribute-missing-selectablevalues
    @status:probed
    @provider:sql-database-reader
    Scenario: Adding an attribute requires list of selectable values
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "name": "Activity period",
            "description": "Synthetic activity-period attribute"
          }
        }
        """
      And Casey is signed in as a biologist and the request omits one required attribute field
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | REFUSED |
        | nerdery-add-animal-attribute.add | $.reason.code | ANIMAL_ATTRIBUTE_INCOMPLETE |
        | nerdery-add-animal-attribute.add | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-attribute-citizen-add.json (sha256:502f573ce2e3b817eb0acdce74c97e56a31b62b8715828ca248c86d797497848).
    @case:nrd-attribute-citizen-add
    @status:probed
    @provider:sql-database-reader
    Scenario: A citizen cannot add an attribute
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "name": "Activity period",
            "description": "Synthetic activity-period attribute",
            "selectableValues": [
              {
                "valueId": "day",
                "label": "Day"
              },
              {
                "valueId": "night",
                "label": "Night"
              }
            ]
          }
        }
        """
      And Avery is signed in as a citizen and submits a complete attribute
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | REFUSED |
        | nerdery-add-animal-attribute.add | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-add-animal-attribute.add | $.mutation.applied | false |

    # Source requirements: NRD-A03, NRD-D05.
    # Proposed decisions: D01.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-attribute-does-not-change-stats.json (sha256:8828947d420cc1cb9bfd7eb3c7fd45c3fceb0d18e99f537771342148c5005873).
    @case:nrd-attribute-does-not-change-stats
    @status:probed
    @provider:sql-database-reader
    Scenario: Adding a nighttime value does not create a bonus-stat rule
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "name": "Activity period",
            "description": "Synthetic activity-period attribute",
            "selectableValues": [
              {
                "valueId": "day",
                "label": "Day"
              },
              {
                "valueId": "night",
                "label": "Night"
              }
            ]
          }
        }
        """
      And the new attribute offers Night as a selectable value and the catalog already contains animal stats
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | ADDED |
        | nerdery-add-animal-attribute.add | $.attribute.bonusStats | (absent) |
        | nerdery-add-animal-attribute.add | $.mutation.animalStatChanges | 0 |
