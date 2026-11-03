# nerdery-sign-in-wildlife-user: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U05.
# Proposed outcome contract: nerdery-sign-in-wildlife-user-result.v1; terminal variants: SIGNED_IN, REFUSED.
# Proposed operation identity: nerdery-sign-in-wildlife-user.sign-in.

@capability:nerdery-sign-in-wildlife-user
@root-scenario:nerdery-sign-in-wildlife-user
@scenario:nerdery-sign-in-wildlife-user
@input:nerdery-sign-in-wildlife-user-request
@input-contract:nerdery-sign-in-wildlife-user-request.v1
@event:nerdery-sign-in-wildlife-user-requested
@event-authority:nerdery-sign-in-wildlife-user.v1
@outcome:nerdery-sign-in-wildlife-user-outcome
@outcome-contract:nerdery-sign-in-wildlife-user-result.v1
@outcome-terminal
Feature: Sign in to the wildlife application
  As a registered user
  I want to sign in through the DNR identity service
  So that I can use my own collection and team

  Rule: Only a validated DNR identity establishes an application session

    # Source requirements: NRD-U05.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-sign-in-citizen.json (sha256:705562dd0876edf3143d6df117011b2df3d4b98b6fac7094450bf141e4c19c68).
    # Proposed provider calls (unbound): resolve-dnr-identity-response, establish-wildlife-session.
    @case:nrd-sign-in-citizen
    @status:not-built
    Scenario: A citizen can sign in
      Given a DNR sign-in response reference
        """json
        {
          "identityResponseRef": "identity-a"
        }
        """
      And the validated DNR subject belongs to Avery's registered citizen account
      When the wildlife sign-in is completed
      Then the user has an authenticated application session or a named sign-in refusal
        | operation | path | equals |
        | nerdery-sign-in-wildlife-user.sign-in | $.status | SIGNED_IN |
        | nerdery-sign-in-wildlife-user.sign-in | $.user.userId | user-a |
        | nerdery-sign-in-wildlife-user.sign-in | $.session.established | true |

    # Source requirements: NRD-U05.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-sign-in-biologist.json (sha256:e61706eb3de0e70e4ffed025d95aa13d995f7090fd9ff2c408ac0fba23826837).
    # Proposed provider calls (unbound): resolve-dnr-identity-response, establish-wildlife-session.
    @case:nrd-sign-in-biologist
    @status:not-built
    Scenario: A biologist can sign in
      Given a DNR sign-in response reference
        """json
        {
          "identityResponseRef": "identity-bio"
        }
        """
      And the validated DNR subject belongs to Casey's registered biologist account
      When the wildlife sign-in is completed
      Then the user has an authenticated application session or a named sign-in refusal
        | operation | path | equals |
        | nerdery-sign-in-wildlife-user.sign-in | $.status | SIGNED_IN |
        | nerdery-sign-in-wildlife-user.sign-in | $.user.userId | user-bio |
        | nerdery-sign-in-wildlife-user.sign-in | $.session.established | true |

    # Source requirements: NRD-U05.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-sign-in-invalid.json (sha256:d2e434cfc9636518a7a5de45bf6f5d6e3ff9f344c5f85eb42a0d8de42c543c35).
    # Proposed provider calls (unbound): resolve-dnr-identity-response.
    @case:nrd-sign-in-invalid
    @status:not-built
    Scenario: An invalid identity response cannot establish a session
      Given a DNR sign-in response reference
        """json
        {
          "identityResponseRef": "identity-invalid"
        }
        """
      And the DNR identity response failed validation
      When the wildlife sign-in is completed
      Then the user has an authenticated application session or a named sign-in refusal
        | operation | path | equals |
        | nerdery-sign-in-wildlife-user.sign-in | $.status | REFUSED |
        | nerdery-sign-in-wildlife-user.sign-in | $.reason.code | IDENTITY_NOT_VALIDATED |
        | nerdery-sign-in-wildlife-user.sign-in | $.session.established | false |

    # Source requirements: NRD-U05.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-sign-in-expired.json (sha256:0ea34a3c6008827eb6d356e54850dfa6ac33a8c67330b2c1a7dadd403fdf721b).
    # Proposed provider calls (unbound): resolve-dnr-identity-response.
    @case:nrd-sign-in-expired
    @status:not-built
    Scenario: An expired identity response cannot establish a session
      Given a DNR sign-in response reference
        """json
        {
          "identityResponseRef": "identity-expired"
        }
        """
      And the referenced DNR identity response has expired
      When the wildlife sign-in is completed
      Then the user has an authenticated application session or a named sign-in refusal
        | operation | path | equals |
        | nerdery-sign-in-wildlife-user.sign-in | $.status | REFUSED |
        | nerdery-sign-in-wildlife-user.sign-in | $.reason.code | IDENTITY_RESPONSE_EXPIRED |
        | nerdery-sign-in-wildlife-user.sign-in | $.session.established | false |

    # Source requirements: NRD-U05.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-sign-in-unavailable.json (sha256:f5fd5ba3c2834900b85b010ea70ec7ccdfe760087b400e4f12925f9d95ca736a).
    # Proposed provider calls (unbound): resolve-dnr-identity-response.
    @case:nrd-sign-in-unavailable
    @status:not-built
    Scenario: Sign-in reports an identity dependency failure
      Given a DNR sign-in response reference
        """json
        {
          "identityResponseRef": "identity-a"
        }
        """
      And the identity service is unavailable and no application session has been established
      When the wildlife sign-in is completed
      Then the user has an authenticated application session or a named sign-in refusal
        | operation | path | equals |
        | nerdery-sign-in-wildlife-user.sign-in | $.status | REFUSED |
        | nerdery-sign-in-wildlife-user.sign-in | $.reason.code | IDENTITY_SERVICE_UNAVAILABLE |
        | nerdery-sign-in-wildlife-user.sign-in | $.session.established | false |
