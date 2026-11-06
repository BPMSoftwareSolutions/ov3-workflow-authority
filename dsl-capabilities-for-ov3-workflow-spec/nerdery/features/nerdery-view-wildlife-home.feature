# nerdery-view-wildlife-home: canonical-feature candidate for owner review, 2026-11-02.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples; not a new platform format.
# Status: finalized for the SideFX build of the citizen slice from the owner-review candidate
# nerdery-canonical-features/features/mvp/nerdery-view-wildlife-home.feature (sha256:2ef10443b9b117d2987e0050439e610796ef08743ef4dc327337ae5d9c082339).
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
# Scope: mvp. Source requirements: NRD-E07, NRD-T02.
# Proposed outcome contract: nerdery-view-wildlife-home-result.v1; terminal variants: VISIBLE, REFUSED.
# Proposed operation identity: nerdery-view-wildlife-home.view.

@capability:nerdery-view-wildlife-home
@root-scenario:nerdery-view-wildlife-home
@scenario:nerdery-view-wildlife-home
@input:nerdery-view-wildlife-home-request
@input-contract:nerdery-view-wildlife-home-request.v1
@event:nerdery-view-wildlife-home-requested
@event-authority:nerdery-view-wildlife-home.v1
@outcome:nerdery-view-wildlife-home-outcome
@outcome-contract:nerdery-view-wildlife-home-result.v1
@outcome-terminal
Feature: View the selected team on the wildlife home page
  As a signed-in user
  I want to see my selected team on the home page
  So that my personal wildlife team is immediately recognizable

  Rule: The logged-in home page shows the saved team with individual photos and display names

    # Source requirements: NRD-T02, NRD-E07.
    # Proposed decisions: D01, D05, D06, D14.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-home-saved-team.json (sha256:30de662e05f166a048291370171bf114fd40c90c88bef1eb97ee118244c1b00c).
    @case:nrd-home-saved-team
    @status:probed
    @provider:sql-database-reader
    Scenario: The home page presents the saved individuals rather than all collected animals
      Given a wildlife home-page request
        """json
        {}
        """
      And Avery has selected enc-001 and enc-003 in that order from a larger collection
      When the home-page experience is read for the authenticated user
      Then the user sees their saved team or a named refusal
        | operation | path | equals |
        | nerdery-view-wildlife-home.view | $.status | VISIBLE |
        | nerdery-view-wildlife-home.view | $.team.size | 2 |
        | nerdery-view-wildlife-home.view | $.team.members[0].encounterId | enc-001 |
        | nerdery-view-wildlife-home.view | $.team.members[0].displayName | Reed |
        | nerdery-view-wildlife-home.view | $.team.members[0].photoRef | photo-a |
        | nerdery-view-wildlife-home.view | $.team.members[1].encounterId | enc-003 |
        | nerdery-view-wildlife-home.view | $.team.members[1].displayName | Demo Fox |
        | nerdery-view-wildlife-home.view | $.team.members[1].photoRef | photo-a |
        | nerdery-view-wildlife-home.view | $.team.members[2] | (absent) |

    # Source requirements: NRD-T02.
    # Proposed decisions: D01, D05, D06.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-home-no-team.json (sha256:0dd56c24c195ed20dd7102adcb0c12a8044011150ba173dda5a91e89958e59e3).
    @case:nrd-home-no-team
    @status:probed
    @provider:sql-database-reader
    Scenario: A logged-in user without a selection sees an empty team
      Given a wildlife home-page request
        """json
        {}
        """
      And Casey has a collected individual but an empty saved team
      When the home-page experience is read for the authenticated user
      Then the user sees their saved team or a named refusal
        | operation | path | equals |
        | nerdery-view-wildlife-home.view | $.status | VISIBLE |
        | nerdery-view-wildlife-home.view | $.team.size | 0 |
        | nerdery-view-wildlife-home.view | $.team.members | [] |

    # Source requirements: NRD-T02.
    # Proposed decisions: D01, D05, D06.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-home-user-specific.json (sha256:e4ddae04797d7ff228252af36866314e8dbb66a7e212bc08c8dda9e2fa2d21b5).
    @case:nrd-home-user-specific
    @status:probed
    @provider:sql-database-reader
    Scenario: The home page does not reuse another user's saved team
      Given a wildlife home-page request
        """json
        {}
        """
      And Blake's team contains enc-008 and Avery's saved team contains different individuals
      When the home-page experience is read for the authenticated user
      Then the user sees their saved team or a named refusal
        | operation | path | equals |
        | nerdery-view-wildlife-home.view | $.status | VISIBLE |
        | nerdery-view-wildlife-home.view | $.team.size | 1 |
        | nerdery-view-wildlife-home.view | $.team.members[0].encounterId | enc-008 |
        | nerdery-view-wildlife-home.view | $.team.members[1] | (absent) |

    # Source requirements: NRD-T02.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery-canonical-features/fixtures/cases/nrd-home-team-anonymous.json (sha256:6aaceba8d35fa8f9c209c2a9dbadbb0055ccd4bfc986f1a380ebb93ede5763f0).
    # Refused inside the operation's one provider call; the stored state is unchanged.
    @case:nrd-home-team-anonymous
    @status:probed
    @provider:sql-database-reader
    Scenario: An anonymous request cannot receive a private saved team
      Given a wildlife home-page request
        """json
        {}
        """
      And no user is logged in
      When the home-page experience is read for the authenticated user
      Then the user sees their saved team or a named refusal
        | operation | path | equals |
        | nerdery-view-wildlife-home.view | $.status | REFUSED |
        | nerdery-view-wildlife-home.view | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-view-wildlife-home.view | $.team | (absent) |
