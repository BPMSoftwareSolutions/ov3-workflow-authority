# nerdery-view-collected-animals: canonical-feature candidate for owner review, 2026-11-02.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples; not a new platform format.
# Status: finalized for the SideFX build of the citizen slice from the owner-review candidate
# nerdery-canonical-features/features/mvp/nerdery-view-collected-animals.feature (sha256:7367cc04657b8ecdfa401520b649ab79117ab88b9035ec232c2fcabe00072ee4).
# @status:probed: the case ran read-only against the wildlife procedures through nerdery/conformance/run-cases.mjs
# (runs 84ff8efb, c901e190, 8e66151b, 7837a8f1, b28d02da, 25e64090).
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# Provider: the operation is one sql-database-reader statement on sfx-identity (EXEC wildlife.serve), so every case is
# tagged @provider:sql-database-reader.
# The JSON under Given is the request body. The declared API operation binds the caller from the session the frontdoor
# validated; the capability input is {caller, request}. Fixture preparation is separate.
# A successful write requires durable provider testimony and independent read-back; output echoes are not proof.
# All JSON shapes/identities are proposed under D01. Case design decisions remain proposals, not Nerdery requirements.
# Scope: mvp. Source requirements: NRD-U03, NRD-E05, NRD-E06, NRD-E07.
# Proposed outcome contract: nerdery-view-collected-animals-result.v1; terminal variants: LISTED, REFUSED.
# Proposed operation identity: nerdery-view-collected-animals.view.

@capability:nerdery-view-collected-animals
@root-scenario:nerdery-view-collected-animals
@scenario:nerdery-view-collected-animals
@input:nerdery-view-collected-animals-request
@input-contract:nerdery-view-collected-animals-request.v1
@event:nerdery-view-collected-animals-requested
@event-authority:nerdery-view-collected-animals.v1
@outcome:nerdery-view-collected-animals-outcome
@outcome-contract:nerdery-view-collected-animals-result.v1
@outcome-terminal
Feature: View the individual animals in a personal collection
  As a citizen or biologist
  I want to view the individual animals I recorded
  So that I recognize my animals by my photos and optional nicknames

  Rule: Repeated encounters remain separate individuals and use the user's photo and nickname

    # Source requirements: NRD-E05, NRD-E06, NRD-E07.
    # Proposed decisions: D01, D05, D14.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-collected-individuals.json (sha256:858370102cf37aeb9eea7abb646f188c66a8cfa9e0789f3aa75ea2c0cfb51075).
    # Fixture encounter order is explicit; the product's general collected-list sorting policy is not prescribed by the brief.
    @case:nrd-collected-individuals
    @status:probed
    @provider:sql-database-reader
    Scenario: Two encounters of one definition remain two individual collection entries
      Given a personal collected-animals request
        """json
        {}
        """
      And Avery has two distinct encounters with Demo Heron, with different photos and nicknames
      When the recorded individuals are read for the authenticated user
      Then the user can view their individual collected animals or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animals.view | $.status | LISTED |
        | nerdery-view-collected-animals.view | $.total | 2 |
        | nerdery-view-collected-animals.view | $.items[0].encounterId | enc-001 |
        | nerdery-view-collected-animals.view | $.items[1].encounterId | enc-002 |
        | nerdery-view-collected-animals.view | $.items[0].definitionId | animal-001 |
        | nerdery-view-collected-animals.view | $.items[1].definitionId | animal-001 |
        | nerdery-view-collected-animals.view | $.items[0].photoRef | photo-a |
        | nerdery-view-collected-animals.view | $.items[1].photoRef | photo-b |
        | nerdery-view-collected-animals.view | $.items[0].displayName | Reed |
        | nerdery-view-collected-animals.view | $.items[1].displayName | Sky |
        | nerdery-view-collected-animals.view | $.items[2] | (absent) |

    # Source requirements: NRD-E06, NRD-E07.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-collected-fallback-name.json (sha256:6175e14f973f8a7c83838dc2732efb528c73fd6c8c64c86478a1c203253a7e80).
    @case:nrd-collected-fallback-name
    @status:probed
    @provider:sql-database-reader
    Scenario: Without a nickname the common name labels the user's photo
      Given a personal collected-animals request
        """json
        {}
        """
      And Avery's only encounter is a Demo Fox with a personal photo and no nickname
      When the recorded individuals are read for the authenticated user
      Then the user can view their individual collected animals or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animals.view | $.status | LISTED |
        | nerdery-view-collected-animals.view | $.total | 1 |
        | nerdery-view-collected-animals.view | $.items[0].displayName | Demo Fox |
        | nerdery-view-collected-animals.view | $.items[0].photoRef | photo-a |
        | nerdery-view-collected-animals.view | $.items[0].nickname | null |

    # Source requirements: NRD-E06.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-collected-empty.json (sha256:51867b50c235cf1ec4648f7c50723336f16c2284ddd39852c525a9946ad7f53e).
    @case:nrd-collected-empty
    @status:probed
    @provider:sql-database-reader
    Scenario: A user without encounters has an empty personal collection
      Given a personal collected-animals request
        """json
        {}
        """
      And Avery is signed in and the collection has no encounters
      When the recorded individuals are read for the authenticated user
      Then the user can view their individual collected animals or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animals.view | $.status | LISTED |
        | nerdery-view-collected-animals.view | $.total | 0 |
        | nerdery-view-collected-animals.view | $.items | [] |

    # Source requirements: NRD-E06.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-collected-ownership.json (sha256:7385b038f7c2db9b4d8196095023e372d580fced382430bb5d3e5afdcf1770cc).
    @case:nrd-collected-ownership
    @status:probed
    @provider:sql-database-reader
    Scenario: The personal collection contains only the authenticated user's individuals
      Given a personal collected-animals request
        """json
        {}
        """
      And Blake owns enc-008 and all other fixture encounters belong to other users
      When the recorded individuals are read for the authenticated user
      Then the user can view their individual collected animals or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animals.view | $.status | LISTED |
        | nerdery-view-collected-animals.view | $.total | 1 |
        | nerdery-view-collected-animals.view | $.items[0].encounterId | enc-008 |
        | nerdery-view-collected-animals.view | $.items[0].ownerUserId | user-b |
        | nerdery-view-collected-animals.view | $.items[1] | (absent) |

    # Source requirements: NRD-U03, NRD-E06.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-collected-biologist.json (sha256:59a3c2750da418ac22f7a7b3cdc91cb03a019b0d33be5f611716fa501997d1be).
    @case:nrd-collected-biologist
    @status:probed
    @provider:sql-database-reader
    Scenario: A biologist can view their own collected individual
      Given a personal collected-animals request
        """json
        {}
        """
      And Casey is signed in as a biologist and owns the individual enc-009
      When the recorded individuals are read for the authenticated user
      Then the user can view their individual collected animals or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animals.view | $.status | LISTED |
        | nerdery-view-collected-animals.view | $.total | 1 |
        | nerdery-view-collected-animals.view | $.items[0].encounterId | enc-009 |

    # Source requirements: NRD-E06.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-collected-anonymous.json (sha256:4fe17fb5508d2af78bacc24472df7a6d174778770bde6e113ef3e85e83343725).
    # Refused inside the operation's one provider call; the stored state is unchanged.
    @case:nrd-collected-anonymous
    @status:probed
    @provider:sql-database-reader
    Scenario: An unauthenticated request cannot read a personal collection
      Given a personal collected-animals request
        """json
        {}
        """
      And no authenticated subject is available for the personal collection
      When the recorded individuals are read for the authenticated user
      Then the user can view their individual collected animals or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animals.view | $.status | REFUSED |
        | nerdery-view-collected-animals.view | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-view-collected-animals.view | $.items | (absent) |
