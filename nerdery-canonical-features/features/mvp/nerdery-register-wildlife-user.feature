# nerdery-register-wildlife-user: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U05, NRD-U06.
# Proposed outcome contract: nerdery-register-wildlife-user-result.v1; terminal variants: REGISTERED, REFUSED.
# Proposed operation identity: nerdery-register-wildlife-user.register.

@capability:nerdery-register-wildlife-user
@root-scenario:nerdery-register-wildlife-user
@scenario:nerdery-register-wildlife-user
@input:nerdery-register-wildlife-user-request
@input-contract:nerdery-register-wildlife-user-request.v1
@event:nerdery-register-wildlife-user-requested
@event-authority:nerdery-register-wildlife-user.v1
@outcome:nerdery-register-wildlife-user-outcome
@outcome-contract:nerdery-register-wildlife-user-result.v1
@outcome-terminal
Feature: Register a wildlife user through the DNR identity service
  As a state citizen
  I want to complete account registration using the DNR identity service
  So that I can keep my own wildlife collection

  Rule: A validated DNR identity establishes a user with the required profile and a unique email

    # Source requirements: NRD-U05, NRD-U06.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-registration-created.json (sha256:240613f1d9122206687161c5fbe6c3cf3c5f30dc2d5695885f5100eab704083e).
    # Proposed provider calls (unbound): resolve-dnr-identity-response, create-unique-wildlife-profile.
    @case:nrd-registration-created
    @status:not-built
    Scenario: A new DNR identity establishes an account
      Given a DNR registration response reference
        """json
        {
          "identityResponseRef": "identity-new"
        }
        """
      And DNR has validated Drew's identity and no wildlife account uses Drew's email
      When the wildlife account registration is completed
      Then the user has one wildlife account or a named registration refusal
        | operation | path | equals |
        | nerdery-register-wildlife-user.register | $.status | REGISTERED |
        | nerdery-register-wildlife-user.register | $.user.firstName | Drew |
        | nerdery-register-wildlife-user.register | $.user.lastName | Citizen |
        | nerdery-register-wildlife-user.register | $.user.email | drew@example.test |
        | nerdery-register-wildlife-user.register | $.mutation.applied | true |

    # Source requirements: NRD-U05, NRD-U06.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-registration-duplicate-email.json (sha256:b26854afedfb8be4a14f559f2310404b266475744b9aa63168054226932646f9).
    # Proposed provider calls (unbound): resolve-dnr-identity-response, create-unique-wildlife-profile.
    @case:nrd-registration-duplicate-email
    @status:not-built
    Scenario: A different DNR subject cannot claim an existing email
      Given a DNR registration response reference
        """json
        {
          "identityResponseRef": "identity-duplicate-email"
        }
        """
      And DNR validated a different subject with the email already registered to Avery
      When the wildlife account registration is completed
      Then the user has one wildlife account or a named registration refusal
        | operation | path | equals |
        | nerdery-register-wildlife-user.register | $.status | REFUSED |
        | nerdery-register-wildlife-user.register | $.reason.code | EMAIL_NOT_UNIQUE |
        | nerdery-register-wildlife-user.register | $.mutation.applied | false |
        | nerdery-register-wildlife-user.register | $.user | (absent) |

    # Source requirements: NRD-U05, NRD-U06.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-registration-missing-firstname.json (sha256:a9eed05965d82cf1e2046dbc1ba879224d1dab0bd545b7a06a32b3b1a950bab9).
    # Proposed provider calls (unbound): resolve-dnr-identity-response.
    @case:nrd-registration-missing-firstname
    @status:not-built
    Scenario: Registering a user requires first name
      Given a DNR registration response reference
        """json
        {
          "identityResponseRef": "identity-missing"
        }
        """
      And DNR validated the new subject but its profile lacks the field named in this case
      When the wildlife account registration is completed
      Then the user has one wildlife account or a named registration refusal
        | operation | path | equals |
        | nerdery-register-wildlife-user.register | $.status | REFUSED |
        | nerdery-register-wildlife-user.register | $.reason.code | USER_PROFILE_INCOMPLETE |
        | nerdery-register-wildlife-user.register | $.mutation.applied | false |
        | nerdery-register-wildlife-user.register | $.user | (absent) |

    # Source requirements: NRD-U05, NRD-U06.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-registration-missing-lastname.json (sha256:01d2b1da5bacff0f7e633869231030c49726a0ff3c1470f566ea4fd7b4c455ac).
    # Proposed provider calls (unbound): resolve-dnr-identity-response.
    @case:nrd-registration-missing-lastname
    @status:not-built
    Scenario: Registering a user requires last name
      Given a DNR registration response reference
        """json
        {
          "identityResponseRef": "identity-missing"
        }
        """
      And DNR validated the new subject but its profile lacks the field named in this case
      When the wildlife account registration is completed
      Then the user has one wildlife account or a named registration refusal
        | operation | path | equals |
        | nerdery-register-wildlife-user.register | $.status | REFUSED |
        | nerdery-register-wildlife-user.register | $.reason.code | USER_PROFILE_INCOMPLETE |
        | nerdery-register-wildlife-user.register | $.mutation.applied | false |
        | nerdery-register-wildlife-user.register | $.user | (absent) |

    # Source requirements: NRD-U05, NRD-U06.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-registration-missing-email.json (sha256:5e2e9c0dfa65f7008a764e7975ed53d92d7a6431a57b568b6fcf4436ec696d94).
    # Proposed provider calls (unbound): resolve-dnr-identity-response.
    @case:nrd-registration-missing-email
    @status:not-built
    Scenario: Registering a user requires email address
      Given a DNR registration response reference
        """json
        {
          "identityResponseRef": "identity-missing"
        }
        """
      And DNR validated the new subject but its profile lacks the field named in this case
      When the wildlife account registration is completed
      Then the user has one wildlife account or a named registration refusal
        | operation | path | equals |
        | nerdery-register-wildlife-user.register | $.status | REFUSED |
        | nerdery-register-wildlife-user.register | $.reason.code | USER_PROFILE_INCOMPLETE |
        | nerdery-register-wildlife-user.register | $.mutation.applied | false |
        | nerdery-register-wildlife-user.register | $.user | (absent) |

    # Source requirements: NRD-U05.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-registration-untrusted-identity.json (sha256:6b8645561ce36b0b3bb7120d526c9d505e95c6d8c07bb45c68782f1f33d4ade0).
    # Proposed provider calls (unbound): resolve-dnr-identity-response.
    @case:nrd-registration-untrusted-identity
    @status:not-built
    Scenario: An unvalidated identity response cannot create an account
      Given a DNR registration response reference
        """json
        {
          "identityResponseRef": "identity-invalid"
        }
        """
      And the referenced DNR response has failed identity validation
      When the wildlife account registration is completed
      Then the user has one wildlife account or a named registration refusal
        | operation | path | equals |
        | nerdery-register-wildlife-user.register | $.status | REFUSED |
        | nerdery-register-wildlife-user.register | $.reason.code | IDENTITY_NOT_VALIDATED |
        | nerdery-register-wildlife-user.register | $.mutation.applied | false |
        | nerdery-register-wildlife-user.register | $.user | (absent) |

    # Source requirements: NRD-U05.
    # Proposed decisions: D01, D02.
    # Arrangement: fixtures/cases/nrd-registration-provider-unavailable.json (sha256:0a263f02e4a10790c71ac3a94bf0846393eaf7433f82f6317c211abbf1013bba).
    # Proposed provider calls (unbound): resolve-dnr-identity-response.
    @case:nrd-registration-provider-unavailable
    @status:not-built
    Scenario: An unavailable identity service does not yield a fabricated account
      Given a DNR registration response reference
        """json
        {
          "identityResponseRef": "identity-new"
        }
        """
      And the DNR identity service is unavailable before it can validate the registration
      When the wildlife account registration is completed
      Then the user has one wildlife account or a named registration refusal
        | operation | path | equals |
        | nerdery-register-wildlife-user.register | $.status | REFUSED |
        | nerdery-register-wildlife-user.register | $.reason.code | IDENTITY_SERVICE_UNAVAILABLE |
        | nerdery-register-wildlife-user.register | $.mutation.applied | false |
        | nerdery-register-wildlife-user.register | $.user | (absent) |
