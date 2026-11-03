# nerdery-update-animal-attribute: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U01, NRD-A01, NRD-A02.
# Proposed outcome contract: nerdery-update-animal-attribute-result.v1; terminal variants: UPDATED, REFUSED.
# Proposed operation identity: nerdery-update-animal-attribute.update.

@capability:nerdery-update-animal-attribute
@root-scenario:nerdery-update-animal-attribute
@scenario:nerdery-update-animal-attribute
@input:nerdery-update-animal-attribute-request
@input-contract:nerdery-update-animal-attribute-request.v1
@event:nerdery-update-animal-attribute-requested
@event-authority:nerdery-update-animal-attribute.v1
@outcome:nerdery-update-animal-attribute-outcome
@outcome-contract:nerdery-update-animal-attribute-result.v1
@outcome-terminal
Feature: Update a reusable animal attribute
  As a biologist
  I want to maintain the name, description and selectable values of an attribute
  So that animals continue to reference a coherent shared property

  Rule: An attribute retains one identity across all animals that reference it

    # Source requirements: NRD-U01, NRD-A01, NRD-A02.
    # Proposed decisions: D01, D13.
    # Arrangement: fixtures/cases/nrd-attribute-update.json (sha256:b32bfcaf146ac3730637d6a87cc1e12ade3476f810671d5ee05b2bbf2b994aca).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-attribute-update
    @status:not-built
    Scenario: A shared attribute is updated without copying it per animal
      Given an animal attribute identity and proposed replacement properties
        """json
        {
          "attributeId": "habitat",
          "expectedRevision": 1,
          "attribute": {
            "name": "Habitat updated",
            "description": "Updated synthetic habitat description",
            "selectableValues": [
              {
                "valueId": "wetland",
                "label": "Wetland"
              },
              {
                "valueId": "woodland",
                "label": "Woodland"
              },
              {
                "valueId": "grassland",
                "label": "Grassland"
              }
            ]
          }
        }
        """
      And Casey can maintain Habitat, which has revision 1 and is shared by several definitions
      When the animal attribute is updated by the authenticated user
      Then the updated attribute is available or a named refusal preserves the existing attribute
        | operation | path | equals |
        | nerdery-update-animal-attribute.update | $.status | UPDATED |
        | nerdery-update-animal-attribute.update | $.attribute.attributeId | habitat |
        | nerdery-update-animal-attribute.update | $.attribute.name | Habitat updated |
        | nerdery-update-animal-attribute.update | $.attribute.selectableValues | [{"valueId":"wetland","label":"Wetland"},{"valueId":"woodland","label":"Woodland"},{"valueId":"grassland","label":"Grassland"}] |
        | nerdery-update-animal-attribute.update | $.attribute.revision | 2 |
        | nerdery-update-animal-attribute.update | $.mutation.applied | true |
        | nerdery-update-animal-attribute.update | $.attribute.description | Updated synthetic habitat description |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-attribute-update-citizen.json (sha256:2670b5beb74dc0401dd42c429f4338ac2d6d38ef91229fb74c614d24d9587050).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-attribute-update-citizen
    @status:not-built
    Scenario: A citizen cannot update a shared attribute
      Given an animal attribute identity and proposed replacement properties
        """json
        {
          "attributeId": "habitat",
          "expectedRevision": 1,
          "attribute": {
            "name": "Habitat updated",
            "description": "Updated synthetic habitat description",
            "selectableValues": [
              {
                "valueId": "wetland",
                "label": "Wetland"
              },
              {
                "valueId": "woodland",
                "label": "Woodland"
              },
              {
                "valueId": "grassland",
                "label": "Grassland"
              }
            ]
          }
        }
        """
      And Avery is a citizen submitting a change to Habitat
      When the animal attribute is updated by the authenticated user
      Then the updated attribute is available or a named refusal preserves the existing attribute
        | operation | path | equals |
        | nerdery-update-animal-attribute.update | $.status | REFUSED |
        | nerdery-update-animal-attribute.update | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-update-animal-attribute.update | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D13.
    # Arrangement: fixtures/cases/nrd-attribute-update-stale.json (sha256:3f8aba58832efb617e04b1787fe34399e3f84c88dea9cd9ec0882ebeba37c495).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-attribute-update-stale
    @status:not-built
    Scenario: A stale attribute edit is refused
      Given an animal attribute identity and proposed replacement properties
        """json
        {
          "attributeId": "habitat",
          "expectedRevision": 0,
          "attribute": {
            "name": "Habitat updated",
            "description": "Updated synthetic habitat description",
            "selectableValues": [
              {
                "valueId": "wetland",
                "label": "Wetland"
              },
              {
                "valueId": "woodland",
                "label": "Woodland"
              },
              {
                "valueId": "grassland",
                "label": "Grassland"
              }
            ]
          }
        }
        """
      And the shared attribute has been revised since the submitted revision
      When the animal attribute is updated by the authenticated user
      Then the updated attribute is available or a named refusal preserves the existing attribute
        | operation | path | equals |
        | nerdery-update-animal-attribute.update | $.status | REFUSED |
        | nerdery-update-animal-attribute.update | $.reason.code | REVISION_CONFLICT |
        | nerdery-update-animal-attribute.update | $.mutation.applied | false |

    # Source requirements: NRD-U01, NRD-A01, NRD-A02.
    # Proposed decisions: D01, D03, D13.
    # Arrangement: fixtures/cases/nrd-attribute-remove-used-value.json (sha256:342d8b3df6f66e3804e34e7b3cce72b20eea50ff3cc12fc2f4fdbf02540b19dd).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-attribute-remove-used-value
    @status:not-built
    Scenario: Removing an in-use selectable value requires a separate migration decision
      Given an animal attribute identity and proposed replacement properties
        """json
        {
          "attributeId": "habitat",
          "expectedRevision": 1,
          "attribute": {
            "name": "Habitat updated",
            "description": "Updated synthetic habitat description",
            "selectableValues": [
              {
                "valueId": "woodland",
                "label": "Woodland"
              }
            ]
          }
        }
        """
      And Demo Heron still references the wetland value that the proposed replacement omits
      When the animal attribute is updated by the authenticated user
      Then the updated attribute is available or a named refusal preserves the existing attribute
        | operation | path | equals |
        | nerdery-update-animal-attribute.update | $.status | REFUSED |
        | nerdery-update-animal-attribute.update | $.reason.code | ATTRIBUTE_VALUE_IN_USE |
        | nerdery-update-animal-attribute.update | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D13.
    # Arrangement: fixtures/cases/nrd-attribute-update-missing.json (sha256:5724d73fe0e0d1bd3fd62f6ec013fa50ef1cc6ef1785a982964ac2d13324ca3f).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-attribute-update-missing
    @status:not-built
    Scenario: An update cannot create an unknown attribute
      Given an animal attribute identity and proposed replacement properties
        """json
        {
          "attributeId": "missing",
          "expectedRevision": 1,
          "attribute": {
            "name": "Habitat updated",
            "description": "Updated synthetic habitat description",
            "selectableValues": [
              {
                "valueId": "wetland",
                "label": "Wetland"
              },
              {
                "valueId": "woodland",
                "label": "Woodland"
              },
              {
                "valueId": "grassland",
                "label": "Grassland"
              }
            ]
          }
        }
        """
      And the requested attribute ID has no catalog record
      When the animal attribute is updated by the authenticated user
      Then the updated attribute is available or a named refusal preserves the existing attribute
        | operation | path | equals |
        | nerdery-update-animal-attribute.update | $.status | REFUSED |
        | nerdery-update-animal-attribute.update | $.reason.code | ANIMAL_ATTRIBUTE_NOT_FOUND |
        | nerdery-update-animal-attribute.update | $.mutation.applied | false |
