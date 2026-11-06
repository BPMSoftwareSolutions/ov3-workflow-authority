# nerdery-set-animal-team: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U02, NRD-U03, NRD-E05, NRD-E06, NRD-T01.
# Proposed outcome contract: nerdery-set-animal-team-result.v1; terminal variants: SAVED, REFUSED.
# Proposed operation identity: nerdery-set-animal-team.set.

@capability:nerdery-set-animal-team
@root-scenario:nerdery-set-animal-team
@scenario:nerdery-set-animal-team
@input:nerdery-set-animal-team-request
@input-contract:nerdery-set-animal-team-request.v1
@event:nerdery-set-animal-team-requested
@event-authority:nerdery-set-animal-team.v1
@outcome:nerdery-set-animal-team-outcome
@outcome-contract:nerdery-set-animal-team-result.v1
@outcome-terminal
Feature: Select a personal team of up to six collected animals
  As a citizen or biologist
  I want to select my team from my collected individuals
  So that my chosen animals can appear together on my home page

  Rule: A team has at most six distinct owned collected individuals and is replaced atomically

    # Source requirements: NRD-U02, NRD-T01, NRD-E05, NRD-E06.
    # Proposed decisions: D01, D05, D06, D13.
    # Arrangement: fixtures/cases/nrd-team-two-individuals.json (sha256:1c94f883fdf3ded4cdc2f52ac6a913efcba2312acbe0baed11d4cd72bfa23182).
    # Proposed provider calls (unbound): replace-owned-wildlife-team.
    @case:nrd-team-two-individuals
    @status:not-built
    Scenario: Two individuals of the same definition may both be selected
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 1,
          "encounterIds": [
            "enc-001",
            "enc-002"
          ]
        }
        """
      And enc-001 and enc-002 are two of Avery's recorded individuals of the same animal definition
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | SAVED |
        | nerdery-set-animal-team.set | $.team.encounterIds | ["enc-001","enc-002"] |
        | nerdery-set-animal-team.set | $.team.size | 2 |
        | nerdery-set-animal-team.set | $.team.revision | 2 |
        | nerdery-set-animal-team.set | $.mutation.applied | true |

    # Source requirements: NRD-T01.
    # Proposed decisions: D01, D05, D06, D13.
    # Arrangement: fixtures/cases/nrd-team-six.json (sha256:61f3cb8960c8de8f9e1cadcf764ba8321a3716e85003e3dde65c3480a8fa5479).
    # Proposed provider calls (unbound): replace-owned-wildlife-team.
    @case:nrd-team-six
    @status:not-built
    Scenario: Exactly six collected individuals is permitted
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 1,
          "encounterIds": [
            "enc-001",
            "enc-002",
            "enc-003",
            "enc-004",
            "enc-005",
            "enc-006"
          ]
        }
        """
      And Avery owns all seven candidate individuals and the current team is at revision 1
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | SAVED |
        | nerdery-set-animal-team.set | $.team.encounterIds | ["enc-001","enc-002","enc-003","enc-004","enc-005","enc-006"] |
        | nerdery-set-animal-team.set | $.team.size | 6 |
        | nerdery-set-animal-team.set | $.mutation.applied | true |

    # Source requirements: NRD-T01.
    # Proposed decisions: D01, D06, D13.
    # Arrangement: fixtures/cases/nrd-team-clear.json (sha256:167fd0005b67993dfc59bdbc5666a33f0de93ff32eeb63fdfbc0fc49fc94baa5).
    # Proposed provider calls (unbound): replace-owned-wildlife-team.
    @case:nrd-team-clear
    @status:not-built
    Scenario: An empty selection clears the team
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 1,
          "encounterIds": []
        }
        """
      And Avery has two saved team members and submits an empty selection
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | SAVED |
        | nerdery-set-animal-team.set | $.team.encounterIds | [] |
        | nerdery-set-animal-team.set | $.team.size | 0 |
        | nerdery-set-animal-team.set | $.mutation.applied | true |

    # Source requirements: NRD-T01.
    # Proposed decisions: D01, D05, D06, D13.
    # Arrangement: fixtures/cases/nrd-team-seven.json (sha256:c4f475785995550e8ed45cdfda5064c5e066244e664751c247db46e49feba3c4).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-team-seven
    @status:not-built
    Scenario: A seventh individual cannot be added
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 1,
          "encounterIds": [
            "enc-001",
            "enc-002",
            "enc-003",
            "enc-004",
            "enc-005",
            "enc-006",
            "enc-007"
          ]
        }
        """
      And Avery owns all seven candidate individuals and the current team is at revision 1
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | REFUSED |
        | nerdery-set-animal-team.set | $.reason.code | TEAM_LIMIT_EXCEEDED |
        | nerdery-set-animal-team.set | $.mutation.applied | false |

  Rule: A team can contain only distinct individuals the user has recorded

    # Source requirements: NRD-T01, NRD-E06.
    # Proposed decisions: D01, D05, D06.
    # Arrangement: fixtures/cases/nrd-team-uncollected.json (sha256:b5ea629e1d288f50277c08f7bcbb59c097f0c9a2bfaec1df33c4b490969489c0).
    # Proposed provider calls (unbound): replace-owned-wildlife-team.
    @case:nrd-team-uncollected
    @status:not-built
    Scenario: An unrecorded animal cannot occupy a team slot
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 1,
          "encounterIds": [
            "enc-missing"
          ]
        }
        """
      And no encounter exists at enc-missing
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | REFUSED |
        | nerdery-set-animal-team.set | $.reason.code | TEAM_MEMBER_NOT_AVAILABLE |
        | nerdery-set-animal-team.set | $.mutation.applied | false |

    # Source requirements: NRD-T01, NRD-E06.
    # Proposed decisions: D01, D05, D06.
    # Arrangement: fixtures/cases/nrd-team-foreign.json (sha256:6aab996c644f81cbead4ed0bd39073fd25815195e254fbc2c45fb927ea4c8f3e).
    # Proposed provider calls (unbound): replace-owned-wildlife-team.
    @case:nrd-team-foreign
    @status:not-built
    Scenario: Another user's individual cannot occupy a team slot
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 1,
          "encounterIds": [
            "enc-008"
          ]
        }
        """
      And enc-008 belongs to Blake and Avery is selecting the team
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | REFUSED |
        | nerdery-set-animal-team.set | $.reason.code | TEAM_MEMBER_NOT_AVAILABLE |
        | nerdery-set-animal-team.set | $.mutation.applied | false |

    # Source requirements: NRD-T01.
    # Proposed decisions: D01, D06.
    # Arrangement: fixtures/cases/nrd-team-duplicate.json (sha256:90015ddfe740358c9c8d5ca15a7305a35e541830ed0b66fb96fc6e0afde94716).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-team-duplicate
    @status:not-built
    Scenario: The same encounter cannot occupy two team slots
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 1,
          "encounterIds": [
            "enc-001",
            "enc-001"
          ]
        }
        """
      And the same encounter ID occurs twice in Avery's request
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | REFUSED |
        | nerdery-set-animal-team.set | $.reason.code | TEAM_MEMBER_DUPLICATE |
        | nerdery-set-animal-team.set | $.mutation.applied | false |

  Rule: A refused replacement preserves the saved team

    # Source requirements: NRD-T01.
    # Proposed decisions: D01, D06, D13.
    # Arrangement: fixtures/cases/nrd-team-stale.json (sha256:0c4af54fa69bbf5044ff1feaeea63512eab78c43911333347f848c4b572b2450).
    # Proposed provider calls (unbound): replace-owned-wildlife-team.
    @case:nrd-team-stale
    @status:not-built
    Scenario: A stale team edit preserves the newer selection
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 0,
          "encounterIds": [
            "enc-001",
            "enc-002"
          ]
        }
        """
      And Avery's saved team has revision 1 and the submitted revision is stale
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | REFUSED |
        | nerdery-set-animal-team.set | $.reason.code | REVISION_CONFLICT |
        | nerdery-set-animal-team.set | $.mutation.applied | false |

    # Source requirements: NRD-U03, NRD-T01.
    # Proposed decisions: D01, D05, D06.
    # Arrangement: fixtures/cases/nrd-team-biologist.json (sha256:6a0d848c7254da6229e44e3163629817f0fe2a2bfc1c502d592856e98d9cdd93).
    # Proposed provider calls (unbound): replace-owned-wildlife-team.
    @case:nrd-team-biologist
    @status:not-built
    Scenario: A biologist can select a personal team
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 1,
          "encounterIds": [
            "enc-009"
          ]
        }
        """
      And Casey is signed in as a biologist and owns enc-009
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | SAVED |
        | nerdery-set-animal-team.set | $.team.ownerUserId | user-bio |
        | nerdery-set-animal-team.set | $.team.encounterIds | ["enc-009"] |
        | nerdery-set-animal-team.set | $.mutation.applied | true |

    # Source requirements: NRD-T01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-team-anonymous.json (sha256:5279976c6a1e937f2ddd3b63e24eb3a5b6e3f5453442a28752fd0c9953071b98).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-team-anonymous
    @status:not-built
    Scenario: An unauthenticated caller cannot save a team
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 1,
          "encounterIds": [
            "enc-001",
            "enc-002"
          ]
        }
        """
      And there is no authenticated team owner
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | REFUSED |
        | nerdery-set-animal-team.set | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-set-animal-team.set | $.mutation.applied | false |

    # Source requirements: NRD-T01.
    # Proposed decisions: D01, D06, D13.
    # Arrangement: fixtures/cases/nrd-team-storage-failure.json (sha256:d675e76d2f0ed135c4ba0de88e68ae9ac1af5413d104a0c578c7d802226fe1ce).
    # Proposed provider calls (unbound): replace-owned-wildlife-team.
    @case:nrd-team-storage-failure
    @status:not-built
    Scenario: A failed team write preserves the previous team
      Given a proposed team of collected encounter identities
        """json
        {
          "expectedRevision": 1,
          "encounterIds": [
            "enc-001",
            "enc-002"
          ]
        }
        """
      And Avery already has a saved team and storage fails before the replacement commits
      When the team selection is saved for the authenticated user
      Then the selected team of at most six animals is saved or a named refusal preserves the previous team
        | operation | path | equals |
        | nerdery-set-animal-team.set | $.status | REFUSED |
        | nerdery-set-animal-team.set | $.reason.code | TEAM_STORAGE_UNAVAILABLE |
        | nerdery-set-animal-team.set | $.mutation.applied | false |
