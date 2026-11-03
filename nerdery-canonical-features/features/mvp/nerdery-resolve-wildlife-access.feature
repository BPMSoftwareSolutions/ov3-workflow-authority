# nerdery-resolve-wildlife-access: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U01, NRD-U02, NRD-U03, NRD-U04, NRD-T01.
# Proposed outcome contract: nerdery-resolve-wildlife-access-result.v1; terminal variants: ALLOWED, REFUSED.
# Proposed operation identity: nerdery-resolve-wildlife-access.resolve.
# Section identifiers are proposed interface vocabulary. Authorization must also be enforced at mutation/read boundaries; a navigation result is not sufficient.

@capability:nerdery-resolve-wildlife-access
@root-scenario:nerdery-resolve-wildlife-access
@scenario:nerdery-resolve-wildlife-access
@input:nerdery-resolve-wildlife-access-request
@input-contract:nerdery-resolve-wildlife-access-request.v1
@event:nerdery-resolve-wildlife-access-requested
@event-authority:nerdery-resolve-wildlife-access.v1
@outcome:nerdery-resolve-wildlife-access-outcome
@outcome-contract:nerdery-resolve-wildlife-access-result.v1
@outcome-terminal
Feature: Resolve access to wildlife application sections
  As an application user
  I want to receive the section access permitted by my externally managed role
  So that I can use the appropriate experiences without gaining unintended privileges

  Rule: External role assignments govern section access and biologists retain personal collection access

    # Source requirements: NRD-U02.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-citizen-collection.json (sha256:92bdc7d2995156f6d9343c84bce907835d6dc9d63046e9145c58cf2127aa66b4).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-citizen-collection
    @status:not-built
    Scenario: Citizen can access collection
      Given a requested wildlife application section
        """json
        {
          "section": "collection"
        }
        """
      And the authenticated subject is Avery, whose external role is citizen
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | ALLOWED |
        | nerdery-resolve-wildlife-access.resolve | $.section | collection |

    # Source requirements: NRD-U02.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-citizen-collected-animals.json (sha256:58fc6f42217319c678bf9d7c85c56304f6d672ea0475bbce8d819607e324fa59).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-citizen-collected-animals
    @status:not-built
    Scenario: Citizen can access collected-animals
      Given a requested wildlife application section
        """json
        {
          "section": "collected-animals"
        }
        """
      And the authenticated subject is Avery, whose external role is citizen
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | ALLOWED |
        | nerdery-resolve-wildlife-access.resolve | $.section | collected-animals |

    # Source requirements: NRD-U02.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-citizen-team.json (sha256:a5b7fbc3c6163c95be471e68998ef452556d30815bd3fb0e7e528ca2b8a0bf35).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-citizen-team
    @status:not-built
    Scenario: Citizen can access team
      Given a requested wildlife application section
        """json
        {
          "section": "team"
        }
        """
      And the authenticated subject is Avery, whose external role is citizen
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | ALLOWED |
        | nerdery-resolve-wildlife-access.resolve | $.section | team |

    # Source requirements: NRD-U02.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-citizen-home.json (sha256:f29b277a9a556348314824332acba04857d2590d366698e656ffe5c44d6efc30).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-citizen-home
    @status:not-built
    Scenario: Citizen can access home
      Given a requested wildlife application section
        """json
        {
          "section": "home"
        }
        """
      And the authenticated subject is Avery, whose external role is citizen
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | ALLOWED |
        | nerdery-resolve-wildlife-access.resolve | $.section | home |

    # Source requirements: NRD-U03.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-biologist-collection.json (sha256:d1ee53e61c0d52a22eef2cd7f1ce68de2dd9f221ef111c839ee2f535dfa0df87).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-biologist-collection
    @status:not-built
    Scenario: Biologist can access collection
      Given a requested wildlife application section
        """json
        {
          "section": "collection"
        }
        """
      And the authenticated subject is Casey, whose external role is biologist
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | ALLOWED |
        | nerdery-resolve-wildlife-access.resolve | $.section | collection |

    # Source requirements: NRD-U03.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-biologist-collected-animals.json (sha256:0336be1992b15dc92b79c7c041c96a644370ae282e69843442598f63ead07df0).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-biologist-collected-animals
    @status:not-built
    Scenario: Biologist can access collected-animals
      Given a requested wildlife application section
        """json
        {
          "section": "collected-animals"
        }
        """
      And the authenticated subject is Casey, whose external role is biologist
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | ALLOWED |
        | nerdery-resolve-wildlife-access.resolve | $.section | collected-animals |

    # Source requirements: NRD-U03.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-biologist-team.json (sha256:52a51d44112434df38b38863c93ac3214988fb5e106842aae58c03c6c5800c98).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-biologist-team
    @status:not-built
    Scenario: Biologist can access team
      Given a requested wildlife application section
        """json
        {
          "section": "team"
        }
        """
      And the authenticated subject is Casey, whose external role is biologist
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | ALLOWED |
        | nerdery-resolve-wildlife-access.resolve | $.section | team |

    # Source requirements: NRD-U03.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-biologist-home.json (sha256:43c20999ab74c953b90c530cea38b782d572be3281a4552eeaee8fabc15084c8).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-biologist-home
    @status:not-built
    Scenario: Biologist can access home
      Given a requested wildlife application section
        """json
        {
          "section": "home"
        }
        """
      And the authenticated subject is Casey, whose external role is biologist
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | ALLOWED |
        | nerdery-resolve-wildlife-access.resolve | $.section | home |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-biologist-animal-definitions-admin.json (sha256:43c79fb9d9b4d468db7e41416fe70f2ed98e8d640dd6112343846274ed3dc6aa).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-biologist-animal-definitions-admin
    @status:not-built
    Scenario: A biologist can access animal-definitions-admin
      Given a requested wildlife application section
        """json
        {
          "section": "animal-definitions-admin"
        }
        """
      And Casey's external role grants biologist access
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | ALLOWED |
        | nerdery-resolve-wildlife-access.resolve | $.section | animal-definitions-admin |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-citizen-animal-definitions-admin.json (sha256:e38a26b95a14bc1275d891916581ab9294268013549bd2d66cbd78274c2a8c5f).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-citizen-animal-definitions-admin
    @status:not-built
    Scenario: A citizen cannot access animal-definitions-admin
      Given a requested wildlife application section
        """json
        {
          "section": "animal-definitions-admin"
        }
        """
      And Avery is signed in as a citizen and has no biologist role
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | REFUSED |
        | nerdery-resolve-wildlife-access.resolve | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-resolve-wildlife-access.resolve | $.permissions | (absent) |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-biologist-animal-attributes-admin.json (sha256:49592f5af1df42894534e4d6f9639472293397e5e52700c27137d9bd5fa5c57c).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-biologist-animal-attributes-admin
    @status:not-built
    Scenario: A biologist can access animal-attributes-admin
      Given a requested wildlife application section
        """json
        {
          "section": "animal-attributes-admin"
        }
        """
      And Casey's external role grants biologist access
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | ALLOWED |
        | nerdery-resolve-wildlife-access.resolve | $.section | animal-attributes-admin |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-citizen-animal-attributes-admin.json (sha256:34e1aba5fd45eae8bbbe324a3a9a882677aeb842a4eedbeade3b5779002d3283).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-citizen-animal-attributes-admin
    @status:not-built
    Scenario: A citizen cannot access animal-attributes-admin
      Given a requested wildlife application section
        """json
        {
          "section": "animal-attributes-admin"
        }
        """
      And Avery is signed in as a citizen and has no biologist role
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | REFUSED |
        | nerdery-resolve-wildlife-access.resolve | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-resolve-wildlife-access.resolve | $.permissions | (absent) |

    # Source requirements: NRD-U02, NRD-T01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-access-unauthenticated.json (sha256:8a5aa65e6dbe38840ef603381402c27d2bb77876814fb9620df2b664e9d162a7).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-access-unauthenticated
    @status:not-built
    Scenario: A personal team section requires an authenticated user
      Given a requested wildlife application section
        """json
        {
          "section": "team"
        }
        """
      And no authenticated subject is available for this personal section
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | REFUSED |
        | nerdery-resolve-wildlife-access.resolve | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-resolve-wildlife-access.resolve | $.permissions | (absent) |

    # Source requirements: NRD-U01, NRD-U04.
    # Proposed decisions: D01, D02, D05.
    # Arrangement: fixtures/cases/nrd-access-role-revoked.json (sha256:9ffe8603ac44c3153f17a67a53fe0bd875d6e9f6a86219f178faef0bbd005e35).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-access-role-revoked
    @status:not-built
    Scenario: Externally removed biologist access is not inferred from an old screen
      Given a requested wildlife application section
        """json
        {
          "section": "animal-definitions-admin"
        }
        """
      And Casey's current external role no longer grants biologist access
      When access to the section is resolved for the authenticated user
      Then the requested section is available or the access refusal is known
        | operation | path | equals |
        | nerdery-resolve-wildlife-access.resolve | $.status | REFUSED |
        | nerdery-resolve-wildlife-access.resolve | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-resolve-wildlife-access.resolve | $.permissions | (absent) |
