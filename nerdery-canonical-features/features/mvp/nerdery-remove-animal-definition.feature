# nerdery-remove-animal-definition: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U01, NRD-E06, NRD-T02.
# Proposed outcome contract: nerdery-remove-animal-definition-result.v1; terminal variants: REMOVED, REFUSED.
# Proposed operation identity: nerdery-remove-animal-definition.remove.
# The historical-retention rule is proposed decision D03, not a rule supplied by Nerdery.

@capability:nerdery-remove-animal-definition
@root-scenario:nerdery-remove-animal-definition
@scenario:nerdery-remove-animal-definition
@input:nerdery-remove-animal-definition-request
@input-contract:nerdery-remove-animal-definition-request.v1
@event:nerdery-remove-animal-definition-requested
@event-authority:nerdery-remove-animal-definition.v1
@outcome:nerdery-remove-animal-definition-outcome
@outcome-contract:nerdery-remove-animal-definition-result.v1
@outcome-terminal
Feature: Remove an animal definition from the active catalog
  As a biologist
  I want to remove an animal definition from use
  So that the active catalog no longer offers that definition

  Rule: Removal changes active availability without silently deleting historical collection records

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D03, D13.
    # Arrangement: fixtures/cases/nrd-definition-remove-unreferenced.json (sha256:374fb1a9450e401ffa55a27d74e2add7af28d6e3447e4a0c5fe31fedd3179852).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-remove-unreferenced
    @status:not-built
    Scenario: An unreferenced definition is removed from the active catalog
      Given an animal definition identity requested for removal
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1
        }
        """
      And the definition exists and there are no encounter or team references to it
      When the animal definition is removed by the authenticated user
      Then the definition is absent from the active catalog or a named refusal leaves it unchanged
        | operation | path | equals |
        | nerdery-remove-animal-definition.remove | $.status | REMOVED |
        | nerdery-remove-animal-definition.remove | $.definitionId | animal-001 |
        | nerdery-remove-animal-definition.remove | $.active | false |
        | nerdery-remove-animal-definition.remove | $.mutation.applied | true |

    # Source requirements: NRD-U01, NRD-E06, NRD-T02.
    # Proposed decisions: D01, D03, D13.
    # Arrangement: fixtures/cases/nrd-definition-remove-referenced.json (sha256:c777cfdc57dcb56bfd6eb4df334ed75e8379826d2554f36c36dd86db0966ef07).
    # D03 candidate: counts are independently observed after the mutation, not copied from the request.
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-remove-referenced
    @status:not-built
    Scenario: Removing a referenced definition retains prior collected individuals
      Given an animal definition identity requested for removal
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1
        }
        """
      And four recorded encounters use Demo Heron and two saved team memberships refer to those encounters
      When the animal definition is removed by the authenticated user
      Then the definition is absent from the active catalog or a named refusal leaves it unchanged
        | operation | path | equals |
        | nerdery-remove-animal-definition.remove | $.status | REMOVED |
        | nerdery-remove-animal-definition.remove | $.active | false |
        | nerdery-remove-animal-definition.remove | $.history.encountersRetained | 4 |
        | nerdery-remove-animal-definition.remove | $.history.teamReferencesRetained | 2 |
        | nerdery-remove-animal-definition.remove | $.mutation.applied | true |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-definition-remove-citizen.json (sha256:5d66b74561e91542bf90708fe84fc5f5afca71ce2167490e5bee6df9b045771e).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-remove-citizen
    @status:not-built
    Scenario: A citizen cannot remove a definition
      Given an animal definition identity requested for removal
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1
        }
        """
      And a citizen requests removal of an active definition
      When the animal definition is removed by the authenticated user
      Then the definition is absent from the active catalog or a named refusal leaves it unchanged
        | operation | path | equals |
        | nerdery-remove-animal-definition.remove | $.status | REFUSED |
        | nerdery-remove-animal-definition.remove | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-remove-animal-definition.remove | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D13.
    # Arrangement: fixtures/cases/nrd-definition-remove-stale.json (sha256:f457fbe6e9afe241dbc404643c5a8a17a485ad09cc469cfe67a3198588187998).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-remove-stale
    @status:not-built
    Scenario: A stale removal does not remove a changed definition
      Given an animal definition identity requested for removal
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 0
        }
        """
      And the definition's current revision is newer than the one submitted for removal
      When the animal definition is removed by the authenticated user
      Then the definition is absent from the active catalog or a named refusal leaves it unchanged
        | operation | path | equals |
        | nerdery-remove-animal-definition.remove | $.status | REFUSED |
        | nerdery-remove-animal-definition.remove | $.reason.code | REVISION_CONFLICT |
        | nerdery-remove-animal-definition.remove | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D03.
    # Arrangement: fixtures/cases/nrd-definition-remove-missing.json (sha256:6750a84f0c7ffa48037117c72fade3c244c71876a5d38722680a8454490117a0).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-remove-missing
    @status:not-built
    Scenario: A missing definition produces a named removal refusal
      Given an animal definition identity requested for removal
        """json
        {
          "definitionId": "animal-missing",
          "expectedRevision": 1
        }
        """
      And the definition ID to remove is absent from the catalog
      When the animal definition is removed by the authenticated user
      Then the definition is absent from the active catalog or a named refusal leaves it unchanged
        | operation | path | equals |
        | nerdery-remove-animal-definition.remove | $.status | REFUSED |
        | nerdery-remove-animal-definition.remove | $.reason.code | ANIMAL_DEFINITION_NOT_FOUND |
        | nerdery-remove-animal-definition.remove | $.mutation.applied | false |
