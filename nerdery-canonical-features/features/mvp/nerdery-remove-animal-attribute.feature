# nerdery-remove-animal-attribute: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U01, NRD-A01.
# Proposed outcome contract: nerdery-remove-animal-attribute-result.v1; terminal variants: REMOVED, REFUSED.
# Proposed operation identity: nerdery-remove-animal-attribute.remove.

@capability:nerdery-remove-animal-attribute
@root-scenario:nerdery-remove-animal-attribute
@scenario:nerdery-remove-animal-attribute
@input:nerdery-remove-animal-attribute-request
@input-contract:nerdery-remove-animal-attribute-request.v1
@event:nerdery-remove-animal-attribute-requested
@event-authority:nerdery-remove-animal-attribute.v1
@outcome:nerdery-remove-animal-attribute-outcome
@outcome-contract:nerdery-remove-animal-attribute-result.v1
@outcome-terminal
Feature: Remove an animal attribute from active use
  As a biologist
  I want to remove an animal attribute
  So that the active attribute catalog no longer offers it

  Rule: Attribute removal has an explicit effect on active selection and historical references

    # Source requirements: NRD-U01, NRD-A01.
    # Proposed decisions: D01, D03, D13.
    # Arrangement: fixtures/cases/nrd-attribute-remove-unreferenced.json (sha256:fef9d6e6fb9151faf039071f36418cbff541646953ea0b240dcf7252a9182588).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-attribute-remove-unreferenced
    @status:not-built
    Scenario: An unused attribute is removed
      Given an animal attribute identity requested for removal
        """json
        {
          "attributeId": "habitat",
          "expectedRevision": 1
        }
        """
      And Habitat exists and no definition references it
      When the animal attribute is removed by the authenticated user
      Then the attribute is absent from active selection or a named refusal leaves it unchanged
        | operation | path | equals |
        | nerdery-remove-animal-attribute.remove | $.status | REMOVED |
        | nerdery-remove-animal-attribute.remove | $.attributeId | habitat |
        | nerdery-remove-animal-attribute.remove | $.active | false |
        | nerdery-remove-animal-attribute.remove | $.mutation.applied | true |

    # Source requirements: NRD-U01, NRD-A01.
    # Proposed decisions: D01, D03, D13.
    # Arrangement: fixtures/cases/nrd-attribute-remove-shared.json (sha256:4cde0ae666708d6e26ef225dc3b4bb3f257cdec678c443d037724fa56499ce81).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-attribute-remove-shared
    @status:not-built
    Scenario: A removed shared attribute keeps existing references resolvable
      Given an animal attribute identity requested for removal
        """json
        {
          "attributeId": "habitat",
          "expectedRevision": 1
        }
        """
      And all three fixture animal definitions currently refer to Habitat
      When the animal attribute is removed by the authenticated user
      Then the attribute is absent from active selection or a named refusal leaves it unchanged
        | operation | path | equals |
        | nerdery-remove-animal-attribute.remove | $.status | REMOVED |
        | nerdery-remove-animal-attribute.remove | $.active | false |
        | nerdery-remove-animal-attribute.remove | $.history.definitionReferencesRetained | 3 |
        | nerdery-remove-animal-attribute.remove | $.mutation.applied | true |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-attribute-remove-citizen.json (sha256:b244caed0fa32839b0dc3e8c67ce37ee2c01b3f0f84508ffb5e75aa5dabf55c4).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-attribute-remove-citizen
    @status:not-built
    Scenario: A citizen cannot remove an attribute
      Given an animal attribute identity requested for removal
        """json
        {
          "attributeId": "habitat",
          "expectedRevision": 1
        }
        """
      And Avery is a citizen requesting removal of an active shared attribute
      When the animal attribute is removed by the authenticated user
      Then the attribute is absent from active selection or a named refusal leaves it unchanged
        | operation | path | equals |
        | nerdery-remove-animal-attribute.remove | $.status | REFUSED |
        | nerdery-remove-animal-attribute.remove | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-remove-animal-attribute.remove | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D03.
    # Arrangement: fixtures/cases/nrd-attribute-remove-missing.json (sha256:2cbaf268997aeaafb224bf33f7ea956e2d51860f9c9bfe75fff8b346eae600d0).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-attribute-remove-missing
    @status:not-built
    Scenario: A missing attribute has a named removal refusal
      Given an animal attribute identity requested for removal
        """json
        {
          "attributeId": "missing",
          "expectedRevision": 1
        }
        """
      And the attribute ID to remove does not exist
      When the animal attribute is removed by the authenticated user
      Then the attribute is absent from active selection or a named refusal leaves it unchanged
        | operation | path | equals |
        | nerdery-remove-animal-attribute.remove | $.status | REFUSED |
        | nerdery-remove-animal-attribute.remove | $.reason.code | ANIMAL_ATTRIBUTE_NOT_FOUND |
        | nerdery-remove-animal-attribute.remove | $.mutation.applied | false |
