# nerdery-present-wildlife-experience: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U01, NRD-U05, NRD-A02, NRD-C01, NRD-E07, NRD-T02, NRD-Q03.
# Proposed outcome contract: nerdery-present-wildlife-experience-result.v1; terminal variants: PRESENTED, REFUSED.
# Proposed operation identity: nerdery-present-wildlife-experience.present.
# These result assertions check the delivered presentation model. Browser rendering, device behavior and WCAG 2.1 AA require the separate quality acceptance plan; returning a flag is not proof.
# The illustrative route names are declared interface bindings, not capability identity.

@capability:nerdery-present-wildlife-experience
@root-scenario:nerdery-present-wildlife-experience
@scenario:nerdery-present-wildlife-experience
@input:nerdery-present-wildlife-experience-request
@input-contract:nerdery-present-wildlife-experience-request.v1
@event:nerdery-present-wildlife-experience-requested
@event-authority:nerdery-present-wildlife-experience.v1
@outcome:nerdery-present-wildlife-experience-outcome
@outcome-contract:nerdery-present-wildlife-experience-result.v1
@outcome-terminal
Feature: Present the wildlife application in the requested supported language
  As a wildlife application user
  I want to use the same wildlife experiences in a supported language and browser
  So that I can participate on mobile or desktop without changing the application's meaning

  Rule: The selected locale changes presentation rather than animal identities or permissions

    # Source requirements: NRD-Q03, NRD-C01.
    # Proposed decisions: D01, D11.
    # Arrangement: fixtures/cases/nrd-presentation-en.json (sha256:d5a92e9f0d1e17c4aa0b717baf9db764fba1a6182bd868c782a1e845363dc248).
    # Proposed provider calls (unbound): project-wildlife-page.
    @case:nrd-presentation-en
    @status:not-built
    Scenario: The collection page uses the en labels
      Given a wildlife page, supported locale and presentation context
        """json
        {
          "page": "collection",
          "locale": "en"
        }
        """
      And the collection contains the same definitions and the fixture supplies both English and Spanish labels
      When the wildlife page is presented
      Then the requested localized wildlife experience is available or a named presentation refusal
        | operation | path | equals |
        | nerdery-present-wildlife-experience.present | $.status | PRESENTED |
        | nerdery-present-wildlife-experience.present | $.presentation.locale | en |
        | nerdery-present-wildlife-experience.present | $.presentation.title | Animal collection |
        | nerdery-present-wildlife-experience.present | $.presentation.items[0].definitionId | animal-001 |

    # Source requirements: NRD-Q03, NRD-C01.
    # Proposed decisions: D01, D11.
    # Arrangement: fixtures/cases/nrd-presentation-es.json (sha256:daf5cddb5ce69d24d9a5ecf4b6c1b9dca6a99cb7b5c36852f7d0a148655867d4).
    # Proposed provider calls (unbound): project-wildlife-page.
    @case:nrd-presentation-es
    @status:not-built
    Scenario: The collection page uses the es labels
      Given a wildlife page, supported locale and presentation context
        """json
        {
          "page": "collection",
          "locale": "es"
        }
        """
      And the collection contains the same definitions and the fixture supplies both English and Spanish labels
      When the wildlife page is presented
      Then the requested localized wildlife experience is available or a named presentation refusal
        | operation | path | equals |
        | nerdery-present-wildlife-experience.present | $.status | PRESENTED |
        | nerdery-present-wildlife-experience.present | $.presentation.locale | es |
        | nerdery-present-wildlife-experience.present | $.presentation.title | Colección de animales |
        | nerdery-present-wildlife-experience.present | $.presentation.items[0].definitionId | animal-001 |

    # Source requirements: NRD-T02, NRD-E07.
    # Proposed decisions: D01, D05, D11.
    # Arrangement: fixtures/cases/nrd-presentation-home.json (sha256:8b1de736716c75308b5477e7ffb8a07ecf1b19c22852ec84215fe1f0e5c3513b).
    # Proposed provider calls (unbound): project-wildlife-page.
    @case:nrd-presentation-home
    @status:not-built
    Scenario: The home presentation consumes the saved-team result
      Given a wildlife page, supported locale and presentation context
        """json
        {
          "page": "home",
          "locale": "en"
        }
        """
      And Avery is signed in on a mobile viewport with enc-001 and enc-003 saved on the team
      When the wildlife page is presented
      Then the requested localized wildlife experience is available or a named presentation refusal
        | operation | path | equals |
        | nerdery-present-wildlife-experience.present | $.status | PRESENTED |
        | nerdery-present-wildlife-experience.present | $.presentation.team.members[0].encounterId | enc-001 |
        | nerdery-present-wildlife-experience.present | $.presentation.team.members[0].displayName | Reed |

  Rule: Account pages use DNR identity

    # Source requirements: NRD-U05.
    # Proposed decisions: D01, D02, D11.
    # Arrangement: fixtures/cases/nrd-presentation-sign-up.json (sha256:b031ea38cbf22f207a1443e736900404fa5cb832c6659d369ca2db3db85af11b).
    # Proposed provider calls (unbound): project-wildlife-page.
    @case:nrd-presentation-sign-up
    @status:not-built
    Scenario: The sign-up experience uses the DNR identity integration
      Given a wildlife page, supported locale and presentation context
        """json
        {
          "page": "sign-up",
          "locale": "en"
        }
        """
      And a visitor opens the account page on a mobile viewport without an application session
      When the wildlife page is presented
      Then the requested localized wildlife experience is available or a named presentation refusal
        | operation | path | equals |
        | nerdery-present-wildlife-experience.present | $.status | PRESENTED |
        | nerdery-present-wildlife-experience.present | $.presentation.identityOwner | DNR |
        | nerdery-present-wildlife-experience.present | $.presentation.localPasswordStore | false |

    # Source requirements: NRD-U05.
    # Proposed decisions: D01, D02, D11.
    # Arrangement: fixtures/cases/nrd-presentation-sign-in.json (sha256:92ce9cac1ed3940dead6aff1ceb7ff6f9ebc2fc5dc97b7d268c400c6592a9496).
    # Proposed provider calls (unbound): project-wildlife-page.
    @case:nrd-presentation-sign-in
    @status:not-built
    Scenario: The sign-in experience uses the DNR identity integration
      Given a wildlife page, supported locale and presentation context
        """json
        {
          "page": "sign-in",
          "locale": "en"
        }
        """
      And a visitor opens the account page on a mobile viewport without an application session
      When the wildlife page is presented
      Then the requested localized wildlife experience is available or a named presentation refusal
        | operation | path | equals |
        | nerdery-present-wildlife-experience.present | $.status | PRESENTED |
        | nerdery-present-wildlife-experience.present | $.presentation.identityOwner | DNR |
        | nerdery-present-wildlife-experience.present | $.presentation.localPasswordStore | false |

  Rule: The catalog administration pages require the biologist role

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05, D11.
    # Arrangement: fixtures/cases/nrd-presentation-biologist-animal-definitions-admin.json (sha256:17eba5bd61742cd6383b15507bf72e6d681701064cc02f10d03c0244b6ec494d).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, project-wildlife-page.
    @case:nrd-presentation-biologist-animal-definitions-admin
    @status:not-built
    Scenario: The biologist has a distinct animal-definitions-admin section
      Given a wildlife page, supported locale and presentation context
        """json
        {
          "page": "animal-definitions-admin",
          "locale": "en"
        }
        """
      And Casey has the external biologist role and has collected none of the catalog animals
      When the wildlife page is presented
      Then the requested localized wildlife experience is available or a named presentation refusal
        | operation | path | equals |
        | nerdery-present-wildlife-experience.present | $.status | PRESENTED |
        | nerdery-present-wildlife-experience.present | $.presentation.page | animal-definitions-admin |
        | nerdery-present-wildlife-experience.present | $.presentation.definitions[0].scientificName | Synthetic scientific label 1 |
        | nerdery-present-wildlife-experience.present | $.presentation.definitions[0].stats | {"Strength":2,"Size":3,"Speed":4} |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05, D11.
    # Arrangement: fixtures/cases/nrd-presentation-citizen-animal-definitions-admin.json (sha256:a2a56d4aea6a72eea3b91cf933b1485b1132234d3c08ca3a28841cf1c46eceb9).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-presentation-citizen-animal-definitions-admin
    @status:not-built
    Scenario: The citizen cannot obtain the animal-definitions-admin presentation
      Given a wildlife page, supported locale and presentation context
        """json
        {
          "page": "animal-definitions-admin",
          "locale": "en"
        }
        """
      And Avery has the citizen role and requests the administration page directly
      When the wildlife page is presented
      Then the requested localized wildlife experience is available or a named presentation refusal
        | operation | path | equals |
        | nerdery-present-wildlife-experience.present | $.status | REFUSED |
        | nerdery-present-wildlife-experience.present | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-present-wildlife-experience.present | $.presentation | (absent) |

    # Source requirements: NRD-U01, NRD-A02.
    # Proposed decisions: D01, D05, D11.
    # Arrangement: fixtures/cases/nrd-presentation-biologist-animal-attributes-admin.json (sha256:1ad805bb85e68071c2523b8f7b6ed19b57d0bd20d1425a7770bf0e4f39975d98).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, project-wildlife-page.
    @case:nrd-presentation-biologist-animal-attributes-admin
    @status:not-built
    Scenario: The biologist has a distinct animal-attributes-admin section
      Given a wildlife page, supported locale and presentation context
        """json
        {
          "page": "animal-attributes-admin",
          "locale": "en"
        }
        """
      And Casey has the biologist role and Habitat is the one attribute in the fixture
      When the wildlife page is presented
      Then the requested localized wildlife experience is available or a named presentation refusal
        | operation | path | equals |
        | nerdery-present-wildlife-experience.present | $.status | PRESENTED |
        | nerdery-present-wildlife-experience.present | $.presentation.page | animal-attributes-admin |
        | nerdery-present-wildlife-experience.present | $.presentation.attributes[0].name | Habitat |
        | nerdery-present-wildlife-experience.present | $.presentation.attributes[0].description | Synthetic fixture habitat |
        | nerdery-present-wildlife-experience.present | $.presentation.attributes[0].selectableValues | [{"valueId":"wetland","label":"Wetland"},{"valueId":"woodland","label":"Woodland"}] |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05, D11.
    # Arrangement: fixtures/cases/nrd-presentation-citizen-animal-attributes-admin.json (sha256:80000596e49ed1f1f87647df5217523e006c2a8e216765ec2c233db8fdb69a37).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-presentation-citizen-animal-attributes-admin
    @status:not-built
    Scenario: The citizen cannot obtain the animal-attributes-admin presentation
      Given a wildlife page, supported locale and presentation context
        """json
        {
          "page": "animal-attributes-admin",
          "locale": "en"
        }
        """
      And Avery has the citizen role and requests the administration page directly
      When the wildlife page is presented
      Then the requested localized wildlife experience is available or a named presentation refusal
        | operation | path | equals |
        | nerdery-present-wildlife-experience.present | $.status | REFUSED |
        | nerdery-present-wildlife-experience.present | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-present-wildlife-experience.present | $.presentation | (absent) |
