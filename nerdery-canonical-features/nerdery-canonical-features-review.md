# Nerdery canonical features — complete review copy

Generated from the individual `.feature` files. The per-file copies are the editable candidates; regenerate this view after edits. All cases are not-built in this delivery.

## Capability inventory

| Capability | Scope | Cases | Promised experience |
|---|---|---:|---|
| `nerdery-register-wildlife-user` | mvp | 7 | Register a wildlife user through the DNR identity service |
| `nerdery-sign-in-wildlife-user` | mvp | 5 | Sign in to the wildlife application |
| `nerdery-resolve-wildlife-access` | mvp | 14 | Resolve access to wildlife application sections |
| `nerdery-add-animal-definition` | mvp | 17 | Add an animal definition |
| `nerdery-update-animal-definition` | mvp | 6 | Update an animal definition |
| `nerdery-remove-animal-definition` | mvp | 5 | Remove an animal definition from the active catalog |
| `nerdery-add-animal-attribute` | mvp | 6 | Add a reusable animal attribute |
| `nerdery-update-animal-attribute` | mvp | 5 | Update a reusable animal attribute |
| `nerdery-remove-animal-attribute` | mvp | 4 | Remove an animal attribute from active use |
| `nerdery-browse-animal-collection` | mvp | 11 | Browse and search the animal-definition collection |
| `nerdery-view-animal-definition` | mvp | 6 | View the information unlocked for an animal definition |
| `nerdery-upload-encounter-photo` | mvp | 5 | Retain a photo for an animal encounter |
| `nerdery-record-animal-encounter` | mvp | 17 | Record an animal encounter |
| `nerdery-view-collected-animals` | mvp | 6 | View the individual animals in a personal collection |
| `nerdery-set-animal-team` | mvp | 11 | Select a personal team of up to six collected animals |
| `nerdery-view-wildlife-home` | mvp | 4 | View the selected team on the wildlife home page |
| `nerdery-present-wildlife-experience` | mvp | 9 | Present the wildlife application in the requested supported language |
| `nerdery-capture-offline-encounter` | offline-candidate | 6 | Capture an encounter while disconnected |
| `nerdery-synchronize-offline-encounter` | offline-candidate | 6 | Synchronize a retained offline encounter |


## nerdery-register-wildlife-user

Source: `features/mvp/nerdery-register-wildlife-user.feature`  
SHA-256: `sha256:cb3a603d253356500369870cc1ca44bda98f8c2100aa229fb5134e371adff146`

```gherkin
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
```


## nerdery-sign-in-wildlife-user

Source: `features/mvp/nerdery-sign-in-wildlife-user.feature`  
SHA-256: `sha256:9ab0770a4aef7c2ee68dcdc276a913b64ee5161911f5b843e6b0aa35b6ae2e51`

```gherkin
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
```


## nerdery-resolve-wildlife-access

Source: `features/mvp/nerdery-resolve-wildlife-access.feature`  
SHA-256: `sha256:b670db64cd001d92910f5036b6465d4b405bb33866a335dbc7c7b7952d978fac`

```gherkin
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
```


## nerdery-add-animal-definition

Source: `features/mvp/nerdery-add-animal-definition.feature`  
SHA-256: `sha256:feee15f08dbad7a802741b1006ba16cba7e77dee4605b529bf40c1fa729fd89e`

```gherkin
# nerdery-add-animal-definition: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U01, NRD-D01, NRD-D02, NRD-D03, NRD-D04, NRD-D05, NRD-A01, NRD-A02.
# Proposed outcome contract: nerdery-add-animal-definition-result.v1; terminal variants: ADDED, REFUSED.
# Proposed operation identity: nerdery-add-animal-definition.add.

@capability:nerdery-add-animal-definition
@root-scenario:nerdery-add-animal-definition
@scenario:nerdery-add-animal-definition
@input:nerdery-add-animal-definition-request
@input-contract:nerdery-add-animal-definition-request.v1
@event:nerdery-add-animal-definition-requested
@event-authority:nerdery-add-animal-definition.v1
@outcome:nerdery-add-animal-definition-outcome
@outcome-contract:nerdery-add-animal-definition-result.v1
@outcome-terminal
Feature: Add an animal definition
  As a biologist
  I want to add a supported animal definition with its properties
  So that users can discover and collect that animal

  Rule: A biologist can add a complete definition that respects the stated type limit and reference catalog

    # Source requirements: NRD-U01, NRD-D01, NRD-D02, NRD-D03, NRD-D04, NRD-D05, NRD-A01, NRD-A02.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-add.json (sha256:c6c2589f2c30b14d623dd8129d4fb31223fdbd33bd9cb5d89e42e84bc94d3ffd).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-add
    @status:not-built
    Scenario: A biologist adds the complete definition
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Casey is a biologist, avatar-004 is retained and public collection number 4 is available
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | ADDED |
        | nerdery-add-animal-definition.add | $.animal.commonName | Demo Owl |
        | nerdery-add-animal-definition.add | $.animal.scientificName | Synthetic scientific label 4 |
        | nerdery-add-animal-definition.add | $.animal.avatarPhotoRef | avatar-004 |
        | nerdery-add-animal-definition.add | $.animal.collectionNumber | 4 |
        | nerdery-add-animal-definition.add | $.animal.range | ["county-a"] |
        | nerdery-add-animal-definition.add | $.animal.types | ["Flying"] |
        | nerdery-add-animal-definition.add | $.animal.stats | {"Strength":5,"Size":6,"Speed":7} |
        | nerdery-add-animal-definition.add | $.animal.attributes | [{"attributeId":"habitat","valueIds":["woodland"]},{"attributeId":"diet","valueIds":["fish"]}] |
        | nerdery-add-animal-definition.add | $.mutation.applied | true |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-zero-types.json (sha256:2c1399bc90b6255371c22eadedba30790b8c29bf92c4bb7edc2f9bf931d27caf).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-zero-types
    @status:not-built
    Scenario: Up to two types permits zero types
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and the type catalog has fifteen entries
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | ADDED |
        | nerdery-add-animal-definition.add | $.animal.types | [] |
        | nerdery-add-animal-definition.add | $.mutation.applied | true |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-two-types.json (sha256:d7d3bb0c0badf8e3d2d66e3c9a2b2192877d4fe7af9fa8bef56e8d8435069528).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-two-types
    @status:not-built
    Scenario: Up to two types permits two types
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and the type catalog has fifteen entries
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | ADDED |
        | nerdery-add-animal-definition.add | $.animal.types | ["Flying","Aquatic"] |
        | nerdery-add-animal-definition.add | $.mutation.applied | true |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-three-types.json (sha256:2fb53e062828aa007544a42018ae85fad6e6f8b50a8a3ef60f0566e0bad9442d).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-three-types
    @status:not-built
    Scenario: The new definition refuses three types
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying",
              "Aquatic",
              "Rural"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and the type catalog has fifteen entries
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_TYPE_LIMIT_EXCEEDED |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-unknown-type.json (sha256:4268b86a683120bc7fe38d9830c717a114c8bfb2a68a8cbd955a17d94a65fcc8).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-unknown-type
    @status:not-built
    Scenario: The new definition refuses unknown type
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "UnknownType"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And UnknownType is absent from the type catalog
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_TYPE_UNKNOWN |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D03.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-unknown-county.json (sha256:fe9f7f0944e198ef9630cbe4b1e64c978f4a2cb3142a77ac3ae072409e1cccd8).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-unknown-county
    @status:not-built
    Scenario: The new definition refuses unknown county
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-unknown"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And county-unknown is absent from the fixture state's county catalog
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | COUNTY_UNKNOWN |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D02.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-duplicate-number.json (sha256:995165dd5d5ba8911311b260d26bbdad38bb2db65ccb6df1f16a82a59d9c791b).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-duplicate-number
    @status:not-built
    Scenario: The new definition refuses duplicate number
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 1,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Demo Heron already holds public collection number 1
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | COLLECTION_NUMBER_NOT_UNIQUE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-A01, NRD-A02.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-unknown-attribute-value.json (sha256:099cb26e820df12357eddaba1747f1c08d45c1bedf667b2ef7f80985095682da).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-unknown-attribute-value
    @status:not-built
    Scenario: The new definition refuses unknown attribute value
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "desert"
                ]
              }
            ]
          }
        }
        """
      And the requested association uses a value outside the attribute's selectable values
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ATTRIBUTE_VALUE_NOT_SELECTABLE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

  Rule: A definition includes the intrinsic properties in the challenge

    # Source requirements: NRD-D01.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-commonname.json (sha256:4787ec6703247947c4acef971e917483f6e2dfee2276427d746ca7efd53e6562).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-commonname
    @status:not-built
    Scenario: Adding an animal definition requires common name
      Given a proposed animal definition
        """json
        {
          "animal": {
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits the definition with the indicated intrinsic property omitted
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D01.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-scientificname.json (sha256:bcf60509ef8fdedde19e946e1563ead8015e44ca15402162a3db45d5bf7ec36d).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-scientificname
    @status:not-built
    Scenario: Adding an animal definition requires scientific name
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits the definition with the indicated intrinsic property omitted
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D01.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-avatarphotoref.json (sha256:c5c614a0ad8b3b9ebaa2181672c3ca6386cfe05f1ca5649bb9443adc7da85279).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-avatarphotoref
    @status:not-built
    Scenario: Adding an animal definition requires on-file photo reference
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits the definition with the indicated intrinsic property omitted
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D02.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-collectionnumber.json (sha256:5315f7904538484fd1e335bbc91cbd57a6db63b7f3ce0533d478c746e96bad44).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-collectionnumber
    @status:not-built
    Scenario: Adding an animal definition requires public collection number
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits the definition without a public collection number
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D03.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-range.json (sha256:aa8aa27c0831cec361615295a7440390068a319b0a261bd4030b54748a25b1f9).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-range
    @status:not-built
    Scenario: Adding an animal definition requires county range
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits the definition without its county range
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-types.json (sha256:c2147d7b7a8328412d114774b26612cb8b92cb6b9247d891683fc0365be2d415).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-types
    @status:not-built
    Scenario: Adding an animal definition requires types field
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist omits the types field entirely
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-D05.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-definition-missing-stats.json (sha256:aa277eb9f598cbc5b8b64e8b57982c1ccabac53dc004da03cfd8cee86599a025).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-missing-stats
    @status:not-built
    Scenario: Adding an animal definition requires stats field
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist omits the stats field entirely
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | ANIMAL_DEFINITION_INCOMPLETE |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

  Rule: Only a biologist can add a catalog definition

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-definition-citizen-add.json (sha256:eb1eb354375391e888fc9756c375c424a02a99bdf2d5ec143651603d5a93bff3).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-citizen-add
    @status:not-built
    Scenario: A citizen cannot add an animal definition
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Avery has only the citizen role
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-definition-anonymous-add.json (sha256:2f960b56a3bad0e45477852f1e379505a249aeb8d5cfe60e6119cafe993902dd).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-definition-anonymous-add
    @status:not-built
    Scenario: An unauthenticated caller cannot add an animal definition
      Given a proposed animal definition
        """json
        {
          "animal": {
            "commonName": "Demo Owl",
            "scientificName": "Synthetic scientific label 4",
            "avatarPhotoRef": "avatar-004",
            "collectionNumber": 4,
            "range": [
              "county-a"
            ],
            "types": [
              "Flying"
            ],
            "stats": {
              "Strength": 5,
              "Size": 6,
              "Speed": 7
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And no subject is signed in
      When the animal definition is added by the authenticated user
      Then the new animal definition is available or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-definition.add | $.status | REFUSED |
        | nerdery-add-animal-definition.add | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-add-animal-definition.add | $.mutation.applied | false |
```


## nerdery-update-animal-definition

Source: `features/mvp/nerdery-update-animal-definition.feature`  
SHA-256: `sha256:d46f78ebe19b2020c9ebeb8ee2d80da12a897b3ab81cb5b1bc78b37c133d9aca`

```gherkin
# nerdery-update-animal-definition: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U01, NRD-D01, NRD-D03, NRD-D04, NRD-A01, NRD-A02.
# Proposed outcome contract: nerdery-update-animal-definition-result.v1; terminal variants: UPDATED, REFUSED.
# Proposed operation identity: nerdery-update-animal-definition.update.

@capability:nerdery-update-animal-definition
@root-scenario:nerdery-update-animal-definition
@scenario:nerdery-update-animal-definition
@input:nerdery-update-animal-definition-request
@input-contract:nerdery-update-animal-definition-request.v1
@event:nerdery-update-animal-definition-requested
@event-authority:nerdery-update-animal-definition.v1
@outcome:nerdery-update-animal-definition-outcome
@outcome-contract:nerdery-update-animal-definition-result.v1
@outcome-terminal
Feature: Update an animal definition
  As a biologist
  I want to update an existing animal definition
  So that the catalog reflects the maintained wildlife information

  Rule: Definition changes preserve identity and apply only to the expected current revision

    # Source requirements: NRD-U01, NRD-D01, NRD-D03.
    # Proposed decisions: D01, D13.
    # Arrangement: fixtures/cases/nrd-definition-update.json (sha256:08f76c355c38351e84a6e8113e7daba0dc259a6a826a328d879b6e3d4e00b5e8).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-update
    @status:not-built
    Scenario: A biologist updates a definition without replacing its identity
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "wetland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Demo Heron is at revision 1 and Casey is signed in as a biologist
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | UPDATED |
        | nerdery-update-animal-definition.update | $.animal.definitionId | animal-001 |
        | nerdery-update-animal-definition.update | $.animal.commonName | Demo Heron Updated |
        | nerdery-update-animal-definition.update | $.animal.range | ["county-a","county-b"] |
        | nerdery-update-animal-definition.update | $.animal.revision | 2 |
        | nerdery-update-animal-definition.update | $.mutation.applied | true |

    # Source requirements: NRD-U01, NRD-A01, NRD-A02.
    # Proposed decisions: D01, D08, D13.
    # Arrangement: fixtures/cases/nrd-definition-update-attribute-association.json (sha256:3cef40f8e01e2d0e5832d17401f9fa26b4e8dc9cf6096ff65d4aec0e360a3524).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-update-attribute-association
    @status:not-built
    Scenario: A biologist changes the selectable attribute values associated with an animal
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "woodland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "plants"
                ]
              }
            ]
          }
        }
        """
      And Demo Heron currently references the wetland habitat value and Casey can maintain its definition
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | UPDATED |
        | nerdery-update-animal-definition.update | $.animal.attributes | [{"attributeId":"habitat","valueIds":["woodland"]},{"attributeId":"diet","valueIds":["plants"]}] |
        | nerdery-update-animal-definition.update | $.mutation.applied | true |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-definition-update-citizen.json (sha256:96d3797757947f546256bb0a701b0a1b3aabfa1c2289295979e46f0c08fe702e).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-update-citizen
    @status:not-built
    Scenario: A citizen cannot update a definition
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "wetland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Avery is a citizen submitting a change to an existing definition
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | REFUSED |
        | nerdery-update-animal-definition.update | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-update-animal-definition.update | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D13.
    # Arrangement: fixtures/cases/nrd-definition-update-stale.json (sha256:b4ce8f646512504127052f78f392d0f7cd76f74b525f5962b64efece6493273c).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-update-stale
    @status:not-built
    Scenario: A stale edit does not overwrite a newer definition
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 0,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "wetland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And Casey proposes a replacement from revision 0 while the catalog holds revision 1
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | REFUSED |
        | nerdery-update-animal-definition.update | $.reason.code | REVISION_CONFLICT |
        | nerdery-update-animal-definition.update | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D13.
    # Arrangement: fixtures/cases/nrd-definition-update-missing.json (sha256:583fe7453f07602a93b51f655aadcfc150562597c46b0a596169570629cb49f0).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-definition-update-missing
    @status:not-built
    Scenario: An update cannot create a missing definition
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-missing",
          "expectedRevision": 1,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "wetland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And the requested definition ID has no catalog record
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | REFUSED |
        | nerdery-update-animal-definition.update | $.reason.code | ANIMAL_DEFINITION_NOT_FOUND |
        | nerdery-update-animal-definition.update | $.mutation.applied | false |

    # Source requirements: NRD-D04.
    # Proposed decisions: D01, D08, D13.
    # Arrangement: fixtures/cases/nrd-definition-update-three-types.json (sha256:1edf1b7bc9cd397f596039647250db7c887f6d64c25359b19c34d5ff13c8338c).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-definition-update-three-types
    @status:not-built
    Scenario: An update cannot bypass the two-type limit
      Given an animal definition identity and its proposed replacement properties
        """json
        {
          "definitionId": "animal-001",
          "expectedRevision": 1,
          "animal": {
            "commonName": "Demo Heron Updated",
            "scientificName": "Synthetic scientific label 1",
            "avatarPhotoRef": "avatar-001",
            "collectionNumber": 1,
            "range": [
              "county-a",
              "county-b"
            ],
            "types": [
              "Flying",
              "Aquatic",
              "Metro"
            ],
            "stats": {
              "Strength": 2,
              "Size": 3,
              "Speed": 4
            },
            "attributes": [
              {
                "attributeId": "habitat",
                "valueIds": [
                  "wetland"
                ]
              },
              {
                "attributeId": "diet",
                "valueIds": [
                  "fish"
                ]
              }
            ]
          }
        }
        """
      And a biologist submits three types for a definition at the requested revision
      When the animal definition is updated by the authenticated user
      Then the updated animal definition is available or a named refusal preserves the existing definition
        | operation | path | equals |
        | nerdery-update-animal-definition.update | $.status | REFUSED |
        | nerdery-update-animal-definition.update | $.reason.code | ANIMAL_TYPE_LIMIT_EXCEEDED |
        | nerdery-update-animal-definition.update | $.mutation.applied | false |
```


## nerdery-remove-animal-definition

Source: `features/mvp/nerdery-remove-animal-definition.feature`  
SHA-256: `sha256:4a16b7ce730fef5d9057e2be86e5866117188b1e4b203a58b131a017a26a0294`

```gherkin
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
```


## nerdery-add-animal-attribute

Source: `features/mvp/nerdery-add-animal-attribute.feature`  
SHA-256: `sha256:512084b5b4381dc391116e28bef95b8edb914e4dd0c61e2f9093d69facbd1826`

```gherkin
# nerdery-add-animal-attribute: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U01, NRD-D05, NRD-A02, NRD-A03.
# Proposed outcome contract: nerdery-add-animal-attribute-result.v1; terminal variants: ADDED, REFUSED.
# Proposed operation identity: nerdery-add-animal-attribute.add.

@capability:nerdery-add-animal-attribute
@root-scenario:nerdery-add-animal-attribute
@scenario:nerdery-add-animal-attribute
@input:nerdery-add-animal-attribute-request
@input-contract:nerdery-add-animal-attribute-request.v1
@event:nerdery-add-animal-attribute-requested
@event-authority:nerdery-add-animal-attribute.v1
@outcome:nerdery-add-animal-attribute-outcome
@outcome-contract:nerdery-add-animal-attribute-result.v1
@outcome-terminal
Feature: Add a reusable animal attribute
  As a biologist
  I want to define a distinctive animal attribute and its selectable values
  So that the same property can describe one or many animals

  Rule: A reusable attribute contains its name, description and selectable values

    # Source requirements: NRD-U01, NRD-A02.
    # Proposed decisions: D01.
    # Arrangement: fixtures/cases/nrd-attribute-add.json (sha256:6db2ea3d98a610ae8d9d4b043929f09e00c5d58ec24a2fde2e98f54d4f9e1b14).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-attribute-add
    @status:not-built
    Scenario: A biologist adds an attribute with selectable values
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "name": "Activity period",
            "description": "Synthetic activity-period attribute",
            "selectableValues": [
              {
                "valueId": "day",
                "label": "Day"
              },
              {
                "valueId": "night",
                "label": "Night"
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and Activity period is a new attribute
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | ADDED |
        | nerdery-add-animal-attribute.add | $.attribute.name | Activity period |
        | nerdery-add-animal-attribute.add | $.attribute.description | Synthetic activity-period attribute |
        | nerdery-add-animal-attribute.add | $.attribute.selectableValues | [{"valueId":"day","label":"Day"},{"valueId":"night","label":"Night"}] |
        | nerdery-add-animal-attribute.add | $.mutation.applied | true |

    # Source requirements: NRD-A02.
    # Proposed decisions: D01.
    # Arrangement: fixtures/cases/nrd-attribute-missing-name.json (sha256:04b9de2881d2eeeb10d1aa24d128602a42a73c83d9962a4216ceb56088a29eb4).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-attribute-missing-name
    @status:not-built
    Scenario: Adding an attribute requires name
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "description": "Synthetic activity-period attribute",
            "selectableValues": [
              {
                "valueId": "day",
                "label": "Day"
              },
              {
                "valueId": "night",
                "label": "Night"
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and the request omits one required attribute field
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | REFUSED |
        | nerdery-add-animal-attribute.add | $.reason.code | ANIMAL_ATTRIBUTE_INCOMPLETE |
        | nerdery-add-animal-attribute.add | $.mutation.applied | false |

    # Source requirements: NRD-A02.
    # Proposed decisions: D01.
    # Arrangement: fixtures/cases/nrd-attribute-missing-description.json (sha256:838d999917ae0ddb0ada3ad458fee031c39b0bbf206380256db6cd4da0567690).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-attribute-missing-description
    @status:not-built
    Scenario: Adding an attribute requires description
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "name": "Activity period",
            "selectableValues": [
              {
                "valueId": "day",
                "label": "Day"
              },
              {
                "valueId": "night",
                "label": "Night"
              }
            ]
          }
        }
        """
      And Casey is signed in as a biologist and the request omits one required attribute field
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | REFUSED |
        | nerdery-add-animal-attribute.add | $.reason.code | ANIMAL_ATTRIBUTE_INCOMPLETE |
        | nerdery-add-animal-attribute.add | $.mutation.applied | false |

    # Source requirements: NRD-A02.
    # Proposed decisions: D01.
    # Arrangement: fixtures/cases/nrd-attribute-missing-selectablevalues.json (sha256:8e45649cbfc6c733dfea4cdd608865999a6e010f5464be7ba465ae32ad1e0028).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-attribute-missing-selectablevalues
    @status:not-built
    Scenario: Adding an attribute requires list of selectable values
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "name": "Activity period",
            "description": "Synthetic activity-period attribute"
          }
        }
        """
      And Casey is signed in as a biologist and the request omits one required attribute field
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | REFUSED |
        | nerdery-add-animal-attribute.add | $.reason.code | ANIMAL_ATTRIBUTE_INCOMPLETE |
        | nerdery-add-animal-attribute.add | $.mutation.applied | false |

    # Source requirements: NRD-U01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-attribute-citizen-add.json (sha256:502f573ce2e3b817eb0acdce74c97e56a31b62b8715828ca248c86d797497848).
    # Proposed provider calls (unbound): resolve-current-dnr-roles.
    @case:nrd-attribute-citizen-add
    @status:not-built
    Scenario: A citizen cannot add an attribute
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "name": "Activity period",
            "description": "Synthetic activity-period attribute",
            "selectableValues": [
              {
                "valueId": "day",
                "label": "Day"
              },
              {
                "valueId": "night",
                "label": "Night"
              }
            ]
          }
        }
        """
      And Avery is signed in as a citizen and submits a complete attribute
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | REFUSED |
        | nerdery-add-animal-attribute.add | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-add-animal-attribute.add | $.mutation.applied | false |

    # Source requirements: NRD-A03, NRD-D05.
    # Proposed decisions: D01.
    # Arrangement: fixtures/cases/nrd-attribute-does-not-change-stats.json (sha256:8828947d420cc1cb9bfd7eb3c7fd45c3fceb0d18e99f537771342148c5005873).
    # Proposed provider calls (unbound): resolve-current-dnr-roles, commit-wildlife-catalog-change.
    @case:nrd-attribute-does-not-change-stats
    @status:not-built
    Scenario: Adding a nighttime value does not create a bonus-stat rule
      Given a proposed animal attribute
        """json
        {
          "attribute": {
            "name": "Activity period",
            "description": "Synthetic activity-period attribute",
            "selectableValues": [
              {
                "valueId": "day",
                "label": "Day"
              },
              {
                "valueId": "night",
                "label": "Night"
              }
            ]
          }
        }
        """
      And the new attribute offers Night as a selectable value and the catalog already contains animal stats
      When the animal attribute is added by the authenticated user
      Then the attribute is available for animal definitions or a named refusal explains why it was not added
        | operation | path | equals |
        | nerdery-add-animal-attribute.add | $.status | ADDED |
        | nerdery-add-animal-attribute.add | $.attribute.bonusStats | (absent) |
        | nerdery-add-animal-attribute.add | $.mutation.animalStatChanges | 0 |
```


## nerdery-update-animal-attribute

Source: `features/mvp/nerdery-update-animal-attribute.feature`  
SHA-256: `sha256:7a2c34d22bbc24bf687d77c59d30d60692b7fb7dd8555125a264d778abe2ca71`

```gherkin
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
```


## nerdery-remove-animal-attribute

Source: `features/mvp/nerdery-remove-animal-attribute.feature`  
SHA-256: `sha256:5424ed379b1c5e1d693c7798f6cd008b49869732f9b0d7dedbfc85f986f36317`

```gherkin
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
```


## nerdery-browse-animal-collection

Source: `features/mvp/nerdery-browse-animal-collection.feature`  
SHA-256: `sha256:1bfb48b620fa8f88853ddfed53b53355a828969544ea0bb80d83a3ab3ab11456`

```gherkin
# nerdery-browse-animal-collection: canonical-feature candidate for owner review, 2026-11-02.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples; not a new platform format.
# Status: feature candidate. The proposed capability is absent from estate model 34 (inventory run 49ae8acb).
# @status:not-built means this delivery contains no implementation or run evidence for the case.
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# Expected business read: @provider:sql-database-reader. Model 34 contract and synthetic read proof c2d5ec95.
# See review/provider-bindings.md for provider scope, evidence and open bindings. Fixture preparation is separate.
# A successful write requires durable provider testimony and independent read-back; output echoes are not proof.
# All JSON shapes/identities are proposed under D01. Case design decisions remain proposals, not Nerdery requirements.
# Scope: mvp. Source requirements: NRD-D02, NRD-C01, NRD-C02, NRD-C03, NRD-C04.
# Proposed outcome contract: nerdery-browse-animal-collection-result.v1; terminal variants: LISTED, REFUSED.
# Proposed operation identity: nerdery-browse-animal-collection.browse.

@capability:nerdery-browse-animal-collection
@root-scenario:nerdery-browse-animal-collection
@scenario:nerdery-browse-animal-collection
@input:nerdery-browse-animal-collection-request
@input-contract:nerdery-browse-animal-collection-request.v1
@event:nerdery-browse-animal-collection-requested
@event-authority:nerdery-browse-animal-collection.v1
@outcome:nerdery-browse-animal-collection-outcome
@outcome-contract:nerdery-browse-animal-collection-result.v1
@outcome-terminal
Feature: Browse and search the animal-definition collection
  As a wildlife application user
  I want to browse a numbered catalog and find an animal
  So that I can see what I have collected and discover what remains

  Rule: The catalog is ordered by collection number and uncollected entries expose only the four permitted animal properties

    # Source requirements: NRD-C01, NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-collection-uncollected.json (sha256:1b782d54dbf28a8217fe1c1b7bd85e02f952ab514cccec9c665162f0c59734f7).
    @case:nrd-collection-uncollected
    @status:not-built
    @provider:sql-database-reader
    Scenario: Uncollected entries contain exactly the permitted animal properties
      Given a collection browse request
        """json
        {
          "search": ""
        }
        """
      And Avery is signed in and has no recorded encounters
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.items[0].definitionId | animal-001 |
        | nerdery-browse-animal-collection.browse | $.items[0].collectionState | UNCOLLECTED |
        | nerdery-browse-animal-collection.browse | $.items[0].animal | {"commonName":"Demo Heron","collectionNumber":1,"range":["county-a"],"avatarPhotoRef":"avatar-001"} |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.scientificName | (absent) |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.stats | (absent) |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.attributes | (absent) |

    # Source requirements: NRD-C01, NRD-C03, NRD-D02.
    # Proposed decisions: D01.
    # Arrangement: fixtures/cases/nrd-collection-ordered.json (sha256:5d38e0f8d1364c4da2736483330aea419b13a53199244818c4155cd01cfb5fbb).
    @case:nrd-collection-ordered
    @status:not-built
    @provider:sql-database-reader
    Scenario: Catalog order is the public number rather than the storage order
      Given a collection browse request
        """json
        {
          "search": ""
        }
        """
      And the active definitions are stored in public-number order 3, 1, 2
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.collectionNumber | 1 |
        | nerdery-browse-animal-collection.browse | $.items[1].animal.collectionNumber | 2 |
        | nerdery-browse-animal-collection.browse | $.items[2].animal.collectionNumber | 3 |
        | nerdery-browse-animal-collection.browse | $.total | 3 |
        | nerdery-browse-animal-collection.browse | $.items[3] | (absent) |

    # Source requirements: NRD-C01, NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-collection-collected.json (sha256:e49470466bb17ac1b223c96e53bdafc46a7f47e4500a2765b696e9bdc7bf2420).
    @case:nrd-collection-collected
    @status:not-built
    @provider:sql-database-reader
    Scenario: A recorded encounter unlocks the definition for its owner
      Given a collection browse request
        """json
        {
          "search": "Heron"
        }
        """
      And Avery has recorded Demo Heron and searches the catalog for it
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.items[0].collectionState | COLLECTED |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.scientificName | Synthetic scientific label 1 |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.types | ["Flying","Aquatic"] |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.stats | {"Strength":2,"Size":3,"Speed":4} |
        | nerdery-browse-animal-collection.browse | $.items[0].animal.attributes | [{"attributeId":"habitat","valueIds":["wetland"]},{"attributeId":"diet","valueIds":["fish"]}] |

    # Source requirements: NRD-C01, NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-collection-owner-specific.json (sha256:d57113ea3e58bf35844fa19186fea5f5e5a5a94ca571ad98385eabe85d3972a6).
    @case:nrd-collection-owner-specific
    @status:not-built
    @provider:sql-database-reader
    Scenario: Another user collecting an animal does not unlock it for this user
      Given a collection browse request
        """json
        {
          "search": "Heron"
        }
        """
      And only Blake has recorded Demo Heron and Avery is browsing
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.items[0].collectionState | UNCOLLECTED |
        | nerdery-browse-animal-collection.browse | $.items[0].animal | {"commonName":"Demo Heron","collectionNumber":1,"range":["county-a"],"avatarPhotoRef":"avatar-001"} |
        | nerdery-browse-animal-collection.browse | $.items[0].definitionId | animal-001 |

  Rule: Search uses public catalog information

    # Source requirements: NRD-C04.
    # Proposed decisions: D01, D04.
    # Arrangement: fixtures/cases/nrd-collection-name-search.json (sha256:aeb41ec4dfb61c3971bb697f3de572cfd19ce92e4b11ccd256b4fc228e5627f3).
    @case:nrd-collection-name-search
    @status:not-built
    @provider:sql-database-reader
    Scenario: A common-name substring finds the matching animal
      Given a collection browse request
        """json
        {
          "search": "hErOn"
        }
        """
      And Demo Heron is the only active common name matching the mixed-case search
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.total | 1 |
        | nerdery-browse-animal-collection.browse | $.items[0].definitionId | animal-001 |
        | nerdery-browse-animal-collection.browse | $.items[1] | (absent) |

    # Source requirements: NRD-C04, NRD-D02.
    # Proposed decisions: D01, D04.
    # Arrangement: fixtures/cases/nrd-collection-number-search.json (sha256:4f4d52fa4edf17c2f7383bc0ed184114176c734713e8e00e6a8ffec1280e40a8).
    @case:nrd-collection-number-search
    @status:not-built
    @provider:sql-database-reader
    Scenario: A collection number finds the numbered definition
      Given a collection browse request
        """json
        {
          "search": "2"
        }
        """
      And Demo Fox holds public collection number 2
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.total | 1 |
        | nerdery-browse-animal-collection.browse | $.items[0].definitionId | animal-002 |
        | nerdery-browse-animal-collection.browse | $.items[1] | (absent) |

    # Source requirements: NRD-C04.
    # Proposed decisions: D01, D04.
    # Arrangement: fixtures/cases/nrd-collection-no-matches.json (sha256:83c720e1db4aa67981c553969bd3c635be45706ac57189af7f8425ddc15663a8).
    @case:nrd-collection-no-matches
    @status:not-built
    @provider:sql-database-reader
    Scenario: No match is an empty result rather than a failed browse
      Given a collection browse request
        """json
        {
          "search": "NoSuchAnimal"
        }
        """
      And no active common name or public number matches the search
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.total | 0 |
        | nerdery-browse-animal-collection.browse | $.items | [] |

    # Source requirements: NRD-C02, NRD-C04.
    # Proposed decisions: D01, D04, D05.
    # Arrangement: fixtures/cases/nrd-collection-no-locked-search-leak.json (sha256:a83633380da2e468555db3d15f9f55c6dc6f15a560f84547b370dfc06ff079f7).
    @case:nrd-collection-no-locked-search-leak
    @status:not-built
    @provider:sql-database-reader
    Scenario: A locked scientific label is not a hidden search channel
      Given a collection browse request
        """json
        {
          "search": "Synthetic scientific label 1"
        }
        """
      And Avery has no encounters and searches for a scientific name hidden from the public projection
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.total | 0 |
        | nerdery-browse-animal-collection.browse | $.items | [] |

    # Source requirements: NRD-C01, NRD-C04.
    # Proposed decisions: D01, D03, D04.
    # Arrangement: fixtures/cases/nrd-collection-removed-definition.json (sha256:503d131d5f9a875e6f327895e9871df2e1d2a231dda6a7751d8520bdd3814eb4).
    @case:nrd-collection-removed-definition
    @status:not-built
    @provider:sql-database-reader
    Scenario: A removed definition is absent from active catalog results
      Given a collection browse request
        """json
        {
          "search": "Heron"
        }
        """
      And Demo Heron has been removed from the active catalog
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | LISTED |
        | nerdery-browse-animal-collection.browse | $.total | 0 |
        | nerdery-browse-animal-collection.browse | $.items | [] |

  Rule: A personalized catalog requires a signed-in user and a successful catalog read

    # Source requirements: NRD-C01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-collection-anonymous.json (sha256:091b2c97d4ed9a432e65a97d0229adc6b6fd088b62209dc0079854d347b4256b).
    # This is the personalized collection capability. Anonymous/public browsing remains an undecided separate surface under D05.
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-collection-anonymous
    @status:not-built
    Scenario: A personalized collection read requires authenticated context
      Given a collection browse request
        """json
        {
          "search": ""
        }
        """
      And no authenticated subject is available for a personalized collection
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | REFUSED |
        | nerdery-browse-animal-collection.browse | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-browse-animal-collection.browse | $.items | (absent) |

    # Source requirements: NRD-C01, NRD-C04.
    # Proposed decisions: D01, D04.
    # Arrangement: fixtures/cases/nrd-collection-storage-failure.json (sha256:da9e98931b45c032ffb1c46628a6fe688b460480fd5d87f04f25b2f1f29b7c92).
    @case:nrd-collection-storage-failure
    @status:not-built
    @provider:sql-database-reader
    Scenario: Unavailable catalog storage is not an empty successful search
      Given a collection browse request
        """json
        {
          "search": "Heron"
        }
        """
      And the catalog read is unavailable for a search that would otherwise find Demo Heron
      When the animal-definition collection is read for the authenticated user
      Then the ordered matching collection is visible with only the information unlocked for that user or a named refusal
        | operation | path | equals |
        | nerdery-browse-animal-collection.browse | $.status | REFUSED |
        | nerdery-browse-animal-collection.browse | $.reason.code | CATALOG_STORAGE_UNAVAILABLE |
        | nerdery-browse-animal-collection.browse | $.items | (absent) |
```


## nerdery-view-animal-definition

Source: `features/mvp/nerdery-view-animal-definition.feature`  
SHA-256: `sha256:067bd1593daaeecb4705e0c23b458f54c23323aba0560b475db662289116db75`

```gherkin
# nerdery-view-animal-definition: canonical-feature candidate for owner review, 2026-11-02.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples; not a new platform format.
# Status: feature candidate. The proposed capability is absent from estate model 34 (inventory run 49ae8acb).
# @status:not-built means this delivery contains no implementation or run evidence for the case.
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# Expected business read: @provider:sql-database-reader. Model 34 contract and synthetic read proof b5b5a835.
# See review/provider-bindings.md for provider scope, evidence and open bindings. Fixture preparation is separate.
# A successful write requires durable provider testimony and independent read-back; output echoes are not proof.
# All JSON shapes/identities are proposed under D01. Case design decisions remain proposals, not Nerdery requirements.
# Scope: mvp. Source requirements: NRD-U03, NRD-D01, NRD-D02, NRD-D03, NRD-D04, NRD-D05, NRD-A01, NRD-A02, NRD-C02.
# Proposed outcome contract: nerdery-view-animal-definition-result.v1; terminal variants: VISIBLE, REFUSED.
# Proposed operation identity: nerdery-view-animal-definition.view.

@capability:nerdery-view-animal-definition
@root-scenario:nerdery-view-animal-definition
@scenario:nerdery-view-animal-definition
@input:nerdery-view-animal-definition-request
@input-contract:nerdery-view-animal-definition-request.v1
@event:nerdery-view-animal-definition-requested
@event-authority:nerdery-view-animal-definition.v1
@outcome:nerdery-view-animal-definition-outcome
@outcome-contract:nerdery-view-animal-definition-result.v1
@outcome-terminal
Feature: View the information unlocked for an animal definition
  As a wildlife application user
  I want to inspect a selected animal definition
  So that I can learn from the animal information that my collection has unlocked

  Rule: The direct read enforces the same collection-based field restriction as the overview

    # Source requirements: NRD-C02, NRD-D01, NRD-D02, NRD-D03.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-animal-detail-locked.json (sha256:96076c9561058484532811546334d843328da181d872429a6decdbcc2b640f67).
    @case:nrd-animal-detail-locked
    @status:not-built
    @provider:sql-database-reader
    Scenario: A direct detail request cannot bypass the uncollected restriction
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-001"
        }
        """
      And Avery has no encounters and requests Demo Heron directly
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | VISIBLE |
        | nerdery-view-animal-definition.view | $.collectionState | UNCOLLECTED |
        | nerdery-view-animal-definition.view | $.animal | {"commonName":"Demo Heron","collectionNumber":1,"range":["county-a"],"avatarPhotoRef":"avatar-001"} |

    # Source requirements: NRD-C02, NRD-D01, NRD-D04, NRD-D05, NRD-A01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-animal-detail-unlocked.json (sha256:4f871ea8086b1f1b7b8a538737cd361ef7976c2b78279294cbe681ef4b3d72be).
    @case:nrd-animal-detail-unlocked
    @status:not-built
    @provider:sql-database-reader
    Scenario: An owned encounter unlocks all catalog properties
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-001"
        }
        """
      And Avery has recorded Demo Heron and requests its definition directly
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | VISIBLE |
        | nerdery-view-animal-definition.view | $.collectionState | COLLECTED |
        | nerdery-view-animal-definition.view | $.animal.scientificName | Synthetic scientific label 1 |
        | nerdery-view-animal-definition.view | $.animal.types | ["Flying","Aquatic"] |
        | nerdery-view-animal-definition.view | $.animal.stats | {"Strength":2,"Size":3,"Speed":4} |
        | nerdery-view-animal-definition.view | $.animal.attributes | [{"attributeId":"habitat","valueIds":["wetland"]},{"attributeId":"diet","valueIds":["fish"]}] |

    # Source requirements: NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-animal-detail-missing.json (sha256:e32ad618583b8c4bba2bfb563fc5fcf2ef2f7ffd885180e7091c364ec7ac8197).
    @case:nrd-animal-detail-missing
    @status:not-built
    @provider:sql-database-reader
    Scenario: An unknown definition produces a named refusal
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-missing"
        }
        """
      And there is no definition for the requested ID
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | REFUSED |
        | nerdery-view-animal-definition.view | $.reason.code | ANIMAL_DEFINITION_NOT_FOUND |
        | nerdery-view-animal-definition.view | $.animal | (absent) |

    # Source requirements: NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-animal-detail-cross-user-cache.json (sha256:54a018e29153a63714bcb15395f796c4fb79434c59776a20f566e64e52a0cca5).
    # The prewarm call is setup only and cannot serve as acceptance evidence for this case.
    @case:nrd-animal-detail-cross-user-cache
    @status:not-built
    @provider:sql-database-reader
    Scenario: A prior unlocked read does not leak through a shared cache
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-002"
        }
        """
      And Avery's unlocked Demo Fox read has warmed the cache and Blake has never collected Demo Fox
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | VISIBLE |
        | nerdery-view-animal-definition.view | $.collectionState | UNCOLLECTED |
        | nerdery-view-animal-definition.view | $.animal | {"commonName":"Demo Fox","collectionNumber":2,"range":["county-a"],"avatarPhotoRef":"avatar-002"} |

    # Source requirements: NRD-C02, NRD-A01, NRD-A02.
    # Proposed decisions: D01, D14.
    # Arrangement: fixtures/cases/nrd-animal-detail-attribute-information.json (sha256:94f12d0f6bed4df0665e3caf1b8b43ad4bcee155008c7437781d717bdfa0bdca).
    @case:nrd-animal-detail-attribute-information
    @status:not-built
    @provider:sql-database-reader
    Scenario: An unlocked animal exposes the shared attribute meaning and its selected values
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-001"
        }
        """
      And Avery has collected Demo Heron and its only assigned attribute in this fixture is Habitat with the wetland value
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | VISIBLE |
        | nerdery-view-animal-definition.view | $.animal.attributeDetails[0].attributeId | habitat |
        | nerdery-view-animal-definition.view | $.animal.attributeDetails[0].name | Habitat |
        | nerdery-view-animal-definition.view | $.animal.attributeDetails[0].description | Synthetic fixture habitat |
        | nerdery-view-animal-definition.view | $.animal.attributeDetails[0].selectedValues | [{"valueId":"wetland","label":"Wetland"}] |

  Rule: A biologist browsing a personal collection sees the same lock as a citizen

    # Source requirements: NRD-U03, NRD-C02.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-animal-detail-biologist-locked.json (sha256:2fb3a73dc8aaeb2b00916c84334c405b248ccda83928e8106a505448f837c61a).
    @case:nrd-animal-detail-biologist-locked
    @status:not-built
    @provider:sql-database-reader
    Scenario: A biologist cannot unlock an uncollected animal through the personal detail page
      Given an animal definition identity
        """json
        {
          "definitionId": "animal-002"
        }
        """
      And Casey is a biologist with an encounter for Demo Heron and none for Demo Fox
      When the animal definition is read for the authenticated user
      Then the permitted animal information is available or a named refusal explains why it cannot be viewed
        | operation | path | equals |
        | nerdery-view-animal-definition.view | $.status | VISIBLE |
        | nerdery-view-animal-definition.view | $.collectionState | UNCOLLECTED |
        | nerdery-view-animal-definition.view | $.animal | {"commonName":"Demo Fox","collectionNumber":2,"range":["county-a"],"avatarPhotoRef":"avatar-002"} |
```


## nerdery-upload-encounter-photo

Source: `features/mvp/nerdery-upload-encounter-photo.feature`  
SHA-256: `sha256:c62116a60ec67a53a860738ac7ffcbfcf4f480170aa15d9c75ee04e7b1d8cf2c`

```gherkin
# nerdery-upload-encounter-photo: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U03, NRD-E01, NRD-E03.
# Proposed outcome contract: nerdery-upload-encounter-photo-result.v1; terminal variants: UPLOADED, REFUSED.
# Proposed operation identity: nerdery-upload-encounter-photo.upload.

@capability:nerdery-upload-encounter-photo
@root-scenario:nerdery-upload-encounter-photo
@scenario:nerdery-upload-encounter-photo
@input:nerdery-upload-encounter-photo-request
@input-contract:nerdery-upload-encounter-photo-request.v1
@event:nerdery-upload-encounter-photo-requested
@event-authority:nerdery-upload-encounter-photo.v1
@outcome:nerdery-upload-encounter-photo-outcome
@outcome-contract:nerdery-upload-encounter-photo-result.v1
@outcome-terminal
Feature: Retain a photo for an animal encounter
  As a user recording an encounter
  I want to upload the photo I selected
  So that the photo can be attached to my recorded animal

  Rule: A successful upload retains the submitted image without claiming animal verification

    # Source requirements: NRD-E01, NRD-E03.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-photo-upload.json (sha256:9f043a4d2709b9d742ad4d7a939f8c1e10135d032480a195111f85d4ed6e8f95).
    # Proposed provider calls (unbound): retain-owned-encounter-photo.
    @case:nrd-photo-upload
    @status:not-built
    Scenario: The uploaded image is retained and addressed for its owner
      Given selected encounter photo bytes
        """json
        {
          "fileName": "photo-a.png",
          "mediaType": "image/png",
          "contentBase64": "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOInpwLRAwQCgAlugVtTkdgTAAAAABJRU5ErkJggg=="
        }
        """
      And Avery is signed in and the fixture supplies the bytes of photo-a.png for independent read-back
      When the encounter photo is uploaded for the authenticated user
      Then an owned retained photo reference is available or a named refusal explains why it is not available
        | operation | path | equals |
        | nerdery-upload-encounter-photo.upload | $.status | UPLOADED |
        | nerdery-upload-encounter-photo.upload | $.photo.ownerUserId | user-a |
        | nerdery-upload-encounter-photo.upload | $.photo.contentSha256 | sha256:8021bd6b739aa5464382e945cf4ab848c30f467b91ddb40d1c350354ec21cfa6 |
        | nerdery-upload-encounter-photo.upload | $.photo.durable | true |
        | nerdery-upload-encounter-photo.upload | $.photo.verificationPerformed | false |

    # Source requirements: NRD-U03, NRD-E01, NRD-E03.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-photo-upload-biologist.json (sha256:3143e6c411e221c7ff8f3f4fc4f24eb810a5d545a815ae5238d5216ab040f31c).
    # Proposed provider calls (unbound): retain-owned-encounter-photo.
    @case:nrd-photo-upload-biologist
    @status:not-built
    Scenario: A biologist can upload a personal encounter photo
      Given selected encounter photo bytes
        """json
        {
          "fileName": "photo-a.png",
          "mediaType": "image/png",
          "contentBase64": "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOInpwLRAwQCgAlugVtTkdgTAAAAABJRU5ErkJggg=="
        }
        """
      And Casey is signed in as a biologist and supplies the same PNG bytes for read-back
      When the encounter photo is uploaded for the authenticated user
      Then an owned retained photo reference is available or a named refusal explains why it is not available
        | operation | path | equals |
        | nerdery-upload-encounter-photo.upload | $.status | UPLOADED |
        | nerdery-upload-encounter-photo.upload | $.photo.ownerUserId | user-bio |
        | nerdery-upload-encounter-photo.upload | $.photo.verificationPerformed | false |
        | nerdery-upload-encounter-photo.upload | $.photo.durable | true |
        | nerdery-upload-encounter-photo.upload | $.photo.contentSha256 | sha256:8021bd6b739aa5464382e945cf4ab848c30f467b91ddb40d1c350354ec21cfa6 |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-photo-upload-anonymous.json (sha256:dd3ad482e29fee4b101ab7f8ec8c54b07290ad8736f018c859016a7c00a06549).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-photo-upload-anonymous
    @status:not-built
    Scenario: An unauthenticated caller cannot obtain an owned photo
      Given selected encounter photo bytes
        """json
        {
          "fileName": "photo-a.png",
          "mediaType": "image/png",
          "contentBase64": "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOInpwLRAwQCgAlugVtTkdgTAAAAABJRU5ErkJggg=="
        }
        """
      And no authenticated subject owns the upload
      When the encounter photo is uploaded for the authenticated user
      Then an owned retained photo reference is available or a named refusal explains why it is not available
        | operation | path | equals |
        | nerdery-upload-encounter-photo.upload | $.status | REFUSED |
        | nerdery-upload-encounter-photo.upload | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-upload-encounter-photo.upload | $.mutation.applied | false |
        | nerdery-upload-encounter-photo.upload | $.photo | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D10.
    # Arrangement: fixtures/cases/nrd-photo-upload-missing.json (sha256:aee4b72152895e400140e1424a00f741f876a9cda2a0ce1c9002a7ca2567ac15).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-photo-upload-missing
    @status:not-built
    Scenario: Missing image content cannot satisfy the photo obligation
      Given selected encounter photo bytes
        """json
        {
          "fileName": "empty.png",
          "mediaType": "image/png",
          "contentBase64": ""
        }
        """
      And Avery supplies a file name and media type without image bytes
      When the encounter photo is uploaded for the authenticated user
      Then an owned retained photo reference is available or a named refusal explains why it is not available
        | operation | path | equals |
        | nerdery-upload-encounter-photo.upload | $.status | REFUSED |
        | nerdery-upload-encounter-photo.upload | $.reason.code | PHOTO_REQUIRED |
        | nerdery-upload-encounter-photo.upload | $.mutation.applied | false |
        | nerdery-upload-encounter-photo.upload | $.photo | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D10.
    # Arrangement: fixtures/cases/nrd-photo-upload-storage-failure.json (sha256:1f8f58e72f2cab59408971987b1bc7be32687f11ceed1ca83bdb5c46e559e4dc).
    # Proposed provider calls (unbound): retain-owned-encounter-photo.
    @case:nrd-photo-upload-storage-failure
    @status:not-built
    Scenario: A failed durable write is not reported as an uploaded photo
      Given selected encounter photo bytes
        """json
        {
          "fileName": "photo-a.png",
          "mediaType": "image/png",
          "contentBase64": "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOInpwLRAwQCgAlugVtTkdgTAAAAABJRU5ErkJggg=="
        }
        """
      And photo storage fails before commit for Avery's upload
      When the encounter photo is uploaded for the authenticated user
      Then an owned retained photo reference is available or a named refusal explains why it is not available
        | operation | path | equals |
        | nerdery-upload-encounter-photo.upload | $.status | REFUSED |
        | nerdery-upload-encounter-photo.upload | $.reason.code | PHOTO_STORAGE_UNAVAILABLE |
        | nerdery-upload-encounter-photo.upload | $.mutation.applied | false |
        | nerdery-upload-encounter-photo.upload | $.photo | (absent) |
```


## nerdery-record-animal-encounter

Source: `features/mvp/nerdery-record-animal-encounter.feature`  
SHA-256: `sha256:79a9dae5dd17251bc54b271a8c4f7199a6c4ef790cf8cff35dfa0a973066827f`

```gherkin
# nerdery-record-animal-encounter: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: mvp. Source requirements: NRD-U02, NRD-U03, NRD-C01, NRD-E01, NRD-E02, NRD-E03, NRD-E04, NRD-E05, NRD-E06.
# Proposed outcome contract: nerdery-record-animal-encounter-result.v1; terminal variants: RECORDED, REFUSED.
# Proposed operation identity: nerdery-record-animal-encounter.record.

@capability:nerdery-record-animal-encounter
@root-scenario:nerdery-record-animal-encounter
@scenario:nerdery-record-animal-encounter
@input:nerdery-record-animal-encounter-request
@input-contract:nerdery-record-animal-encounter-request.v1
@event:nerdery-record-animal-encounter-requested
@event-authority:nerdery-record-animal-encounter.v1
@outcome:nerdery-record-animal-encounter-outcome
@outcome-contract:nerdery-record-animal-encounter-result.v1
@outcome-terminal
Feature: Record an animal encounter
  As a citizen or biologist
  I want to record an animal I encountered with its location and my photo
  So that the individual animal is in my collection

  Rule: A recorded encounter has its own identity and does not require in-application photo verification

    # Source requirements: NRD-U02, NRD-C01, NRD-E01, NRD-E02, NRD-E03, NRD-E04.
    # Proposed decisions: D01, D05, D07, D10.
    # Arrangement: fixtures/cases/nrd-encounter-manual.json (sha256:1f4d866b3ba07523a4b2ff09dedcc974e0706ef48f6a36ab08439e5c85abaa93).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-manual
    @status:not-built
    Scenario: A citizen collects Demo Heron for the first time using a manual location
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery has uploaded photo-a and has never collected Demo Heron
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.encounterId | enc-new |
        | nerdery-record-animal-encounter.record | $.encounter.ownerUserId | user-a |
        | nerdery-record-animal-encounter.record | $.encounter.definitionId | animal-001 |
        | nerdery-record-animal-encounter.record | $.encounter.location | {"source":"manual","description":"Synthetic park, north path"} |
        | nerdery-record-animal-encounter.record | $.encounter.photoRef | photo-a |
        | nerdery-record-animal-encounter.record | $.encounter.nickname | Reed |
        | nerdery-record-animal-encounter.record | $.collectionState | COLLECTED |
        | nerdery-record-animal-encounter.record | $.verificationPerformed | false |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |

    # Source requirements: NRD-E01, NRD-E02.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-device.json (sha256:c7b36921965e9670fa0f6d17eeb8f1a10153d39a0d1af2eb56d627d369be39a4).
    # Coordinates are arbitrary fixture values, not a selected state or actual sighting.
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-device
    @status:not-built
    Scenario: A user records an encounter with device-supplied coordinates
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "device",
            "latitude": 42.0,
            "longitude": -83.0
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery owns the retained photo and the request carries device coordinates
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.location | {"source":"device","latitude":42.0,"longitude":-83.0} |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |

    # Source requirements: NRD-E04.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-encounter-no-nickname.json (sha256:0da03fda95b7ddc2ce5b560cb42c185d14168d28089626e2a37b626d68d9c1b6).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-no-nickname
    @status:not-built
    Scenario: A nickname is optional
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a"
        }
        """
      And Avery owns the photo and omits the optional nickname
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.nickname | null |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |

    # Source requirements: NRD-U03, NRD-E01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-encounter-biologist.json (sha256:e02ab312029b8f7c3a6c8338c93d7686c00ba3209b81e33a9f094a24287b4b0d).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-biologist
    @status:not-built
    Scenario: A biologist can record a personal encounter
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-bio",
          "nickname": "Reed"
        }
        """
      And Casey is a biologist recording a personal encounter with Casey's own photo
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.ownerUserId | user-bio |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |

    # Source requirements: NRD-U02, NRD-E05, NRD-E06.
    # Proposed decisions: D01, D05, D07.
    # Arrangement: fixtures/cases/nrd-encounter-another-individual.json (sha256:246455254f1b440b17736a3c4a2be85192fb141e9d009ede160e065ceb955a0a).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-another-individual
    @status:not-built
    Scenario: A new request records another individual of an already collected definition
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-another",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery already has two encounters with Demo Heron and submits a new encounter ID
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.encounterId | enc-another |
        | nerdery-record-animal-encounter.record | $.encounter.definitionId | animal-001 |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |

  Rule: An encounter requires an available animal, a location and an owned photo

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-missing-definitionid.json (sha256:963db515860029fca4ca70bbe8ac999ec1450480922c45c553965ab21c886ac2).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-encounter-missing-definitionid
    @status:not-built
    Scenario: Recording an encounter requires animal selection
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery is signed in and the request omits the required field identified in this case
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | ANIMAL_SELECTION_REQUIRED |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-missing-location.json (sha256:ea5b7a8eeb054803dcdaad6d9892fd26c84f13fb279f5c102815da2aee4bffc8).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-encounter-missing-location
    @status:not-built
    Scenario: Recording an encounter requires location
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery is signed in and the request omits the required field identified in this case
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | LOCATION_REQUIRED |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-missing-photoref.json (sha256:e83697f19332a2fa62656868f59ec2384adf46a12c842d36ecb598635a7c5089).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-encounter-missing-photoref
    @status:not-built
    Scenario: Recording an encounter requires uploaded photo reference
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "nickname": "Reed"
        }
        """
      And Avery is signed in and the request omits the required field identified in this case
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | PHOTO_REQUIRED |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D08.
    # Arrangement: fixtures/cases/nrd-encounter-unknown-definition.json (sha256:ddc9acf804bf8d08fe0ac4b5ed10addf247e3c344eb05bd31135cac39cfcbbd3).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-unknown-definition
    @status:not-built
    Scenario: The selected animal must be in the catalog
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-missing",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And the selected animal ID does not exist
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | ANIMAL_DEFINITION_NOT_FOUND |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D03, D08.
    # Arrangement: fixtures/cases/nrd-encounter-removed-definition.json (sha256:ca74d94f2052b9e56296b47089d40bf4dc96010fd66e4750d9d6f898179879e2).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-removed-definition
    @status:not-built
    Scenario: A newly recorded encounter cannot select a removed definition
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Demo Heron is retained for history but is inactive in the catalog
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | ANIMAL_DEFINITION_UNAVAILABLE |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-foreign-photo.json (sha256:e3e96058ef0f4309d61e8778e2c7325ded9f4ef8b9a4b1daec66b9877e684509).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-foreign-photo
    @status:not-built
    Scenario: Another user's photo cannot be attached to this encounter
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-other",
          "nickname": "Reed"
        }
        """
      And the referenced photo belongs to Blake and Avery is recording the encounter
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | PHOTO_NOT_AVAILABLE_TO_USER |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: fixtures/cases/nrd-encounter-unretained-photo.json (sha256:998e71a2be7cdeb3383fd03b7296dd5b9dbf6ef46625d13cef2a73bb9a497b5b).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-unretained-photo
    @status:not-built
    Scenario: A nonexistent photo reference is not an uploaded photo
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-missing",
          "nickname": "Reed"
        }
        """
      And there is no retained photo at the requested reference
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | PHOTO_NOT_AVAILABLE_TO_USER |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-U02, NRD-E01.
    # Proposed decisions: D01, D05.
    # Arrangement: fixtures/cases/nrd-encounter-anonymous.json (sha256:e7f17463bfecf5fe4b7a0d30bcc963bf9bb3cc5a19778a30230340c3662f7c1c).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-encounter-anonymous
    @status:not-built
    Scenario: A recorded encounter requires an authenticated owner
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And there is no authenticated owner for the encounter
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-E01, NRD-C01.
    # Proposed decisions: D01, D05, D07.
    # Arrangement: fixtures/cases/nrd-encounter-write-failure.json (sha256:29bff45c03b612b42b9d28f1fa30e3304a6e19f9640e0d8b08c168f178e25080).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-write-failure
    @status:not-built
    Scenario: A failed encounter write does not unlock the animal
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery has no encounters and collection storage fails before the write commits
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | COLLECTION_STORAGE_UNAVAILABLE |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

  Rule: Retries of one request do not collapse distinct encounters or duplicate the same encounter

    # Source requirements: NRD-E05, NRD-E06.
    # Proposed decisions: D01, D05, D07.
    # Arrangement: fixtures/cases/nrd-encounter-retry.json (sha256:23a0e4362e64bcd63c81eaaa5d7b2f12128f1f2e442544a8790d07f093124d75).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-retry
    @status:not-built
    Scenario: Retrying the same request returns its one existing encounter
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Reed"
        }
        """
      And Avery's identical request for enc-new was already committed
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.encounterId | enc-new |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.replayed | true |
        | nerdery-record-animal-encounter.record | $.encounter.photoRef | photo-a |
        | nerdery-record-animal-encounter.record | $.encounter.nickname | Reed |
        | nerdery-record-animal-encounter.record | $.encounter.ownerUserId | user-a |

    # Source requirements: NRD-E05, NRD-E06.
    # Proposed decisions: D01, D05, D07.
    # Arrangement: fixtures/cases/nrd-encounter-id-conflict.json (sha256:f9e13f1bf0179048d019ebca724e03130bd16458092a1b8d2aa0733f9f260577).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-id-conflict
    @status:not-built
    Scenario: Reusing the request identity with changed content is refused
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-a",
          "nickname": "Changed"
        }
        """
      And Avery's enc-new was already committed with the nickname Reed
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | REFUSED |
        | nerdery-record-animal-encounter.record | $.reason.code | ENCOUNTER_ID_CONFLICT |
        | nerdery-record-animal-encounter.record | $.mutation.applied | false |
        | nerdery-record-animal-encounter.record | $.encounter | (absent) |

    # Source requirements: NRD-U02, NRD-E05, NRD-E06.
    # Proposed decisions: D01, D05, D07.
    # Arrangement: fixtures/cases/nrd-encounter-same-id-other-owner.json (sha256:65d827682b3d15ce1a6cc8a92ef584bfb19e238a4a83676d83d591ccba573d5b).
    # Proposed provider calls (unbound): commit-owned-wildlife-encounter.
    @case:nrd-encounter-same-id-other-owner
    @status:not-built
    Scenario: A second user can record a personal encounter with the same request ID
      Given an encounter request with an animal selection, location, photo reference and optional nickname
        """json
        {
          "encounterId": "enc-new",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic park, north path"
          },
          "photoRef": "photo-other",
          "nickname": "Brook"
        }
        """
      And Avery has already committed enc-new and Blake is signed in with Blake's own photo
      When the animal encounter is recorded for the authenticated user
      Then the individual animal is recorded once for this request or a named refusal leaves the collection unchanged
        | operation | path | equals |
        | nerdery-record-animal-encounter.record | $.status | RECORDED |
        | nerdery-record-animal-encounter.record | $.encounter.encounterId | enc-new |
        | nerdery-record-animal-encounter.record | $.encounter.ownerUserId | user-b |
        | nerdery-record-animal-encounter.record | $.encounter.photoRef | photo-other |
        | nerdery-record-animal-encounter.record | $.encounter.nickname | Brook |
        | nerdery-record-animal-encounter.record | $.mutation.applied | true |
```


## nerdery-view-collected-animals

Source: `features/mvp/nerdery-view-collected-animals.feature`  
SHA-256: `sha256:7367cc04657b8ecdfa401520b649ab79117ab88b9035ec232c2fcabe00072ee4`

```gherkin
# nerdery-view-collected-animals: canonical-feature candidate for owner review, 2026-11-02.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples; not a new platform format.
# Status: feature candidate. The proposed capability is absent from estate model 34 (inventory run 49ae8acb).
# @status:not-built means this delivery contains no implementation or run evidence for the case.
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# Expected business read: @provider:sql-database-reader. Model 34 contract and synthetic read proof e56f6b4a.
# See review/provider-bindings.md for provider scope, evidence and open bindings. Fixture preparation is separate.
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
    # Arrangement: fixtures/cases/nrd-collected-individuals.json (sha256:858370102cf37aeb9eea7abb646f188c66a8cfa9e0789f3aa75ea2c0cfb51075).
    # Fixture encounter order is explicit; the product's general collected-list sorting policy is not prescribed by the brief.
    @case:nrd-collected-individuals
    @status:not-built
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
    # Arrangement: fixtures/cases/nrd-collected-fallback-name.json (sha256:6175e14f973f8a7c83838dc2732efb528c73fd6c8c64c86478a1c203253a7e80).
    @case:nrd-collected-fallback-name
    @status:not-built
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
    # Arrangement: fixtures/cases/nrd-collected-empty.json (sha256:51867b50c235cf1ec4648f7c50723336f16c2284ddd39852c525a9946ad7f53e).
    @case:nrd-collected-empty
    @status:not-built
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
    # Arrangement: fixtures/cases/nrd-collected-ownership.json (sha256:7385b038f7c2db9b4d8196095023e372d580fced382430bb5d3e5afdcf1770cc).
    @case:nrd-collected-ownership
    @status:not-built
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
    # Arrangement: fixtures/cases/nrd-collected-biologist.json (sha256:59a3c2750da418ac22f7a7b3cdc91cb03a019b0d33be5f611716fa501997d1be).
    @case:nrd-collected-biologist
    @status:not-built
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
    # Arrangement: fixtures/cases/nrd-collected-anonymous.json (sha256:4fe17fb5508d2af78bacc24472df7a6d174778770bde6e113ef3e85e83343725).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-collected-anonymous
    @status:not-built
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
```


## nerdery-set-animal-team

Source: `features/mvp/nerdery-set-animal-team.feature`  
SHA-256: `sha256:f7dab2b2f441f1501f074730a2e6981ef8345e1ac181d3d6a77d4a770f7fa13a`

```gherkin
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
```


## nerdery-view-wildlife-home

Source: `features/mvp/nerdery-view-wildlife-home.feature`  
SHA-256: `sha256:2ef10443b9b117d2987e0050439e610796ef08743ef4dc327337ae5d9c082339`

```gherkin
# nerdery-view-wildlife-home: canonical-feature candidate for owner review, 2026-11-02.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples; not a new platform format.
# Status: feature candidate. The proposed capability is absent from estate model 34 (inventory run 49ae8acb).
# @status:not-built means this delivery contains no implementation or run evidence for the case.
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# Expected business read: @provider:sql-database-reader. Model 34 contract and synthetic read proof 6b402f2b.
# See review/provider-bindings.md for provider scope, evidence and open bindings. Fixture preparation is separate.
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
    # Arrangement: fixtures/cases/nrd-home-saved-team.json (sha256:30de662e05f166a048291370171bf114fd40c90c88bef1eb97ee118244c1b00c).
    @case:nrd-home-saved-team
    @status:not-built
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
    # Arrangement: fixtures/cases/nrd-home-no-team.json (sha256:0dd56c24c195ed20dd7102adcb0c12a8044011150ba173dda5a91e89958e59e3).
    @case:nrd-home-no-team
    @status:not-built
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
    # Arrangement: fixtures/cases/nrd-home-user-specific.json (sha256:e4ddae04797d7ff228252af36866314e8dbb66a7e212bc08c8dda9e2fa2d21b5).
    @case:nrd-home-user-specific
    @status:not-built
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
    # Arrangement: fixtures/cases/nrd-home-team-anonymous.json (sha256:6aaceba8d35fa8f9c209c2a9dbadbb0055ccd4bfc986f1a380ebb93ede5763f0).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-home-team-anonymous
    @status:not-built
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
```


## nerdery-present-wildlife-experience

Source: `features/mvp/nerdery-present-wildlife-experience.feature`  
SHA-256: `sha256:c6e4fa403b33ec66b1e47ad9d9d35538153724b92af00df6edd14bdc8c5e1044`

```gherkin
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
```


## nerdery-capture-offline-encounter

Source: `features/offline-candidate/nerdery-capture-offline-encounter.feature`  
SHA-256: `sha256:d869ce4bd1e9ea906b9778dad9e5e5ec4d521b870c20fac13d3dc45f7d42f3bc`

```gherkin
# nerdery-capture-offline-encounter: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: offline-candidate. Source requirements: NRD-E01, NRD-E02, NRD-E04, NRD-Q06.
# Proposed outcome contract: nerdery-capture-offline-encounter-result.v1; terminal variants: PENDING_SYNC, REFUSED.
# Proposed operation identity: nerdery-capture-offline-encounter.capture.

@capability:nerdery-capture-offline-encounter
@root-scenario:nerdery-capture-offline-encounter
@scenario:nerdery-capture-offline-encounter
@input:nerdery-capture-offline-encounter-request
@input-contract:nerdery-capture-offline-encounter-request.v1
@event:nerdery-capture-offline-encounter-requested
@event-authority:nerdery-capture-offline-encounter.v1
@outcome:nerdery-capture-offline-encounter-outcome
@outcome-contract:nerdery-capture-offline-encounter-result.v1
@outcome-terminal
Feature: Capture an encounter while disconnected
  As a previously signed-in user with a cached animal catalog
  I want to retain an encounter locally when there is no internet connection
  So that I do not lose the animal selection, location and photo before I can synchronize

  Rule: Offline capture retains the required data locally without claiming a server-recorded collection

    # Source requirements: NRD-Q06, NRD-E01, NRD-E02, NRD-E04.
    # Proposed decisions: D01, D07, D09, D10.
    # Arrangement: fixtures/cases/nrd-offline-capture.json (sha256:1caa8c7e7e0f0df943316a65c9478e10c1b5af9cf35eb44ac07e9f74795b9cc7).
    # Proposed provider calls (unbound): retain-offline-wildlife-draft.
    @case:nrd-offline-capture
    @status:not-built
    Scenario: A disconnected user retains a complete local draft across reload
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic offline path"
          },
          "localPhotoRef": "local-photo-a",
          "nickname": "Offline Reed"
        }
        """
      And Avery previously signed in, the catalog and photo are on the device, and the device will reload while disconnected
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | PENDING_SYNC |
        | nerdery-capture-offline-encounter.capture | $.draft.encounterId | offline-001 |
        | nerdery-capture-offline-encounter.capture | $.draft.ownerUserId | user-a |
        | nerdery-capture-offline-encounter.capture | $.draft.photoRetained | true |
        | nerdery-capture-offline-encounter.capture | $.serverRecorded | false |
        | nerdery-capture-offline-encounter.capture | $.serverCollectionUnlocked | false |
        | nerdery-capture-offline-encounter.capture | $.draft.location | {"source":"manual","description":"Synthetic offline path"} |
        | nerdery-capture-offline-encounter.capture | $.draft.nickname | Offline Reed |
        | nerdery-capture-offline-encounter.capture | $.draft.definitionId | animal-001 |

    # Source requirements: NRD-Q06, NRD-E02.
    # Proposed decisions: D01, D09.
    # Arrangement: fixtures/cases/nrd-offline-device-location.json (sha256:e0358ca4c6cb38011604011f79054749333f1af4ffe5d73a9716dbbc889f8a5f).
    # Proposed provider calls (unbound): retain-offline-wildlife-draft.
    @case:nrd-offline-device-location
    @status:not-built
    Scenario: Available device coordinates can populate the disconnected draft
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "location": {
            "source": "device",
            "latitude": 42.0,
            "longitude": -83.0
          },
          "localPhotoRef": "local-photo-a",
          "nickname": "Offline Reed"
        }
        """
      And the device is offline with the selected animal cached and coordinates available
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | PENDING_SYNC |
        | nerdery-capture-offline-encounter.capture | $.draft.location | {"source":"device","latitude":42.0,"longitude":-83.0} |
        | nerdery-capture-offline-encounter.capture | $.draft.photoRetained | true |
        | nerdery-capture-offline-encounter.capture | $.serverRecorded | false |

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D09, D10.
    # Arrangement: fixtures/cases/nrd-offline-missing-localphotoref.json (sha256:b70f82cec1a37091867348c30a65c03ab666ec0eadfe25fcaceac30954656bc4).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-offline-missing-localphotoref
    @status:not-built
    Scenario: Capturing a draft offline requires local photo reference
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic offline path"
          },
          "nickname": "Offline Reed"
        }
        """
      And Avery is offline with a cached catalog and the request omits a required capture field
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | REFUSED |
        | nerdery-capture-offline-encounter.capture | $.reason.code | PHOTO_REQUIRED |
        | nerdery-capture-offline-encounter.capture | $.mutation.applied | false |

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D09, D10.
    # Arrangement: fixtures/cases/nrd-offline-missing-location.json (sha256:78b16e8b50a9f6093367ade7cbfa3c153960dbd71a1d81e86db1fc52a4123ba0).
    # Local refusal before business-provider dispatch; acceptance requires no business call or mutation.
    @case:nrd-offline-missing-location
    @status:not-built
    Scenario: Capturing a draft offline requires location
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "localPhotoRef": "local-photo-a",
          "nickname": "Offline Reed"
        }
        """
      And Avery is offline with a cached catalog and the request omits a required capture field
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | REFUSED |
        | nerdery-capture-offline-encounter.capture | $.reason.code | LOCATION_REQUIRED |
        | nerdery-capture-offline-encounter.capture | $.mutation.applied | false |

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D09.
    # Arrangement: fixtures/cases/nrd-offline-no-catalog.json (sha256:98b35fedce208393220b20d177c259c987d1970f71cb2ca7136a4e34f0b8fef5).
    # Proposed provider calls (unbound): retain-offline-wildlife-draft.
    @case:nrd-offline-no-catalog
    @status:not-built
    Scenario: A cold offline visit does not invent an animal catalog
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic offline path"
          },
          "localPhotoRef": "local-photo-a",
          "nickname": "Offline Reed"
        }
        """
      And the device is offline with an empty local catalog
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | REFUSED |
        | nerdery-capture-offline-encounter.capture | $.reason.code | CACHED_ANIMAL_UNAVAILABLE |
        | nerdery-capture-offline-encounter.capture | $.mutation.applied | false |

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D09.
    # Arrangement: fixtures/cases/nrd-offline-local-storage-failure.json (sha256:d7ab06f2f652647f1e4e7bb0cf2b42502393a41528b2a240854861c33f02d2cc).
    # Proposed provider calls (unbound): retain-offline-wildlife-draft.
    @case:nrd-offline-local-storage-failure
    @status:not-built
    Scenario: A failed local write does not claim the encounter was retained
      Given an offline encounter draft with an animal selection, location and local photo
        """json
        {
          "encounterId": "offline-001",
          "definitionId": "animal-001",
          "location": {
            "source": "manual",
            "description": "Synthetic offline path"
          },
          "localPhotoRef": "local-photo-a",
          "nickname": "Offline Reed"
        }
        """
      And the device is offline and local draft storage fails before commit
      When the encounter draft is retained on the device for its owner
      Then the encounter is visibly pending synchronization or a named refusal explains why it was not retained
        | operation | path | equals |
        | nerdery-capture-offline-encounter.capture | $.status | REFUSED |
        | nerdery-capture-offline-encounter.capture | $.reason.code | LOCAL_STORAGE_UNAVAILABLE |
        | nerdery-capture-offline-encounter.capture | $.mutation.applied | false |
```


## nerdery-synchronize-offline-encounter

Source: `features/offline-candidate/nerdery-synchronize-offline-encounter.feature`  
SHA-256: `sha256:6503912583ce2ffc13e0b52ded6e839cf94de8183137b7e9be853144b54cc6b3`

```gherkin
# nerdery-synchronize-offline-encounter: canonical-feature candidate for owner review, 2026-11-02.
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
# Scope: offline-candidate. Source requirements: NRD-E01, NRD-E05, NRD-E06, NRD-Q06.
# Proposed outcome contract: nerdery-synchronize-offline-encounter-result.v1; terminal variants: SYNCHRONIZED, PENDING_SYNC, REFUSED.
# Proposed operation identity: nerdery-synchronize-offline-encounter.synchronize.

@capability:nerdery-synchronize-offline-encounter
@root-scenario:nerdery-synchronize-offline-encounter
@scenario:nerdery-synchronize-offline-encounter
@input:nerdery-synchronize-offline-encounter-request
@input-contract:nerdery-synchronize-offline-encounter-request.v1
@event:nerdery-synchronize-offline-encounter-requested
@event-authority:nerdery-synchronize-offline-encounter.v1
@outcome:nerdery-synchronize-offline-encounter-outcome
@outcome-contract:nerdery-synchronize-offline-encounter-result.v1
@outcome-terminal
Feature: Synchronize a retained offline encounter
  As the owner of a pending offline encounter
  I want to submit the retained encounter after reconnecting
  So that the pending individual becomes part of my server-recorded collection without duplication

  Rule: Synchronization preserves ownership and request identity through connection failures and retries

    # Source requirements: NRD-Q06, NRD-E01, NRD-E06.
    # Proposed decisions: D01, D05, D07, D09, D10.
    # Arrangement: fixtures/cases/nrd-offline-sync.json (sha256:b0328aa143e37209a44b1f3b2fde7976a8560e3017e9d3da6b9207bc29df824d).
    # Proposed provider calls (unbound): read-owned-offline-wildlife-draft, nerdery-upload-encounter-photo, nerdery-record-animal-encounter, acknowledge-wildlife-draft-sync.
    @case:nrd-offline-sync
    @status:not-built
    Scenario: Reconnection records the owned draft on the server
      Given an owned pending offline encounter identity
        """json
        {
          "encounterId": "offline-001"
        }
        """
      And Avery is back online with one pending draft and its retained device photo
      When the offline encounter is synchronized for the authenticated user
      Then the encounter is server-recorded once or remains visibly pending with a named synchronization reason
        | operation | path | equals |
        | nerdery-synchronize-offline-encounter.synchronize | $.status | SYNCHRONIZED |
        | nerdery-synchronize-offline-encounter.synchronize | $.encounter.encounterId | offline-001 |
        | nerdery-synchronize-offline-encounter.synchronize | $.encounter.ownerUserId | user-a |
        | nerdery-synchronize-offline-encounter.synchronize | $.draft.state | SYNCHRONIZED |
        | nerdery-synchronize-offline-encounter.synchronize | $.serverRecorded | true |
        | nerdery-synchronize-offline-encounter.synchronize | $.serverRecordCountForEncounter | 1 |

    # Source requirements: NRD-Q06, NRD-E05, NRD-E06.
    # Proposed decisions: D01, D07, D09.
    # Arrangement: fixtures/cases/nrd-offline-sync-ack-lost.json (sha256:04ca3ec8c48ecf84b2352b6740c4aaa3fc3d11efd0171bdaff73d584d92af136).
    # Proposed provider calls (unbound): read-owned-offline-wildlife-draft, reconcile-committed-wildlife-encounter, acknowledge-wildlife-draft-sync.
    @case:nrd-offline-sync-ack-lost
    @status:not-built
    Scenario: Retry after a lost acknowledgment does not create another individual
      Given an owned pending offline encounter identity
        """json
        {
          "encounterId": "offline-001"
        }
        """
      And the server already committed offline-001 but the device missed the acknowledgment
      When the offline encounter is synchronized for the authenticated user
      Then the encounter is server-recorded once or remains visibly pending with a named synchronization reason
        | operation | path | equals |
        | nerdery-synchronize-offline-encounter.synchronize | $.status | SYNCHRONIZED |
        | nerdery-synchronize-offline-encounter.synchronize | $.encounter.encounterId | offline-001 |
        | nerdery-synchronize-offline-encounter.synchronize | $.serverRecordCountForEncounter | 1 |
        | nerdery-synchronize-offline-encounter.synchronize | $.replayed | true |

  Rule: A draft remains recoverable when synchronization cannot complete

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D09.
    # Arrangement: fixtures/cases/nrd-offline-sync-network-loss.json (sha256:84a46962b10a3dac8279472d0d7ce5da42031060904427c680c2421fb7dabf30).
    # Proposed provider calls (unbound): read-owned-offline-wildlife-draft.
    @case:nrd-offline-sync-network-loss
    @status:not-built
    Scenario: A disconnected retry remains pending with its photo retained
      Given an owned pending offline encounter identity
        """json
        {
          "encounterId": "offline-001"
        }
        """
      And Avery's draft and photo remain on the device and the network is unavailable
      When the offline encounter is synchronized for the authenticated user
      Then the encounter is server-recorded once or remains visibly pending with a named synchronization reason
        | operation | path | equals |
        | nerdery-synchronize-offline-encounter.synchronize | $.status | PENDING_SYNC |
        | nerdery-synchronize-offline-encounter.synchronize | $.reason.code | NETWORK_UNAVAILABLE |
        | nerdery-synchronize-offline-encounter.synchronize | $.draft.state | PENDING_SYNC |
        | nerdery-synchronize-offline-encounter.synchronize | $.draft.photoRetained | true |

    # Source requirements: NRD-Q06, NRD-E06.
    # Proposed decisions: D01, D05, D09.
    # Arrangement: fixtures/cases/nrd-offline-sync-wrong-owner.json (sha256:6a4b21a3aa657c9b7ede611308aedfc0bd66fbc5ed96d16e55f3ec96141076d1).
    # Proposed provider calls (unbound): read-owned-offline-wildlife-draft.
    @case:nrd-offline-sync-wrong-owner
    @status:not-built
    Scenario: A different signed-in user cannot synchronize another person's draft
      Given an owned pending offline encounter identity
        """json
        {
          "encounterId": "offline-001"
        }
        """
      And Blake is signed in on a device that holds Avery's pending draft
      When the offline encounter is synchronized for the authenticated user
      Then the encounter is server-recorded once or remains visibly pending with a named synchronization reason
        | operation | path | equals |
        | nerdery-synchronize-offline-encounter.synchronize | $.status | REFUSED |
        | nerdery-synchronize-offline-encounter.synchronize | $.reason.code | DRAFT_NOT_AVAILABLE_TO_USER |
        | nerdery-synchronize-offline-encounter.synchronize | $.mutation.applied | false |

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D03, D09.
    # Arrangement: fixtures/cases/nrd-offline-sync-definition-removed.json (sha256:f41ce3044a28d83bb33f03886420f9762445530651bef872da6363ff33bb3a6d).
    # Proposed provider calls (unbound): read-owned-offline-wildlife-draft, nerdery-upload-encounter-photo, nerdery-record-animal-encounter.
    @case:nrd-offline-sync-definition-removed
    @status:not-built
    Scenario: A removed definition leaves a visible unresolved draft instead of discarding it
      Given an owned pending offline encounter identity
        """json
        {
          "encounterId": "offline-001"
        }
        """
      And Avery is back online but the cached animal has been removed from the active server catalog
      When the offline encounter is synchronized for the authenticated user
      Then the encounter is server-recorded once or remains visibly pending with a named synchronization reason
        | operation | path | equals |
        | nerdery-synchronize-offline-encounter.synchronize | $.status | PENDING_SYNC |
        | nerdery-synchronize-offline-encounter.synchronize | $.reason.code | ANIMAL_DEFINITION_UNAVAILABLE |
        | nerdery-synchronize-offline-encounter.synchronize | $.draft.photoRetained | true |
        | nerdery-synchronize-offline-encounter.synchronize | $.serverRecorded | false |
        | nerdery-synchronize-offline-encounter.synchronize | $.draft.state | PENDING_SYNC |

    # Source requirements: NRD-Q06, NRD-E01.
    # Proposed decisions: D01, D09, D10.
    # Arrangement: fixtures/cases/nrd-offline-sync-photo-failed.json (sha256:a870ecfed57e863afba1ac0d8383cd2b5137185a00004ca08cd91482c0df6ba4).
    # Proposed provider calls (unbound): read-owned-offline-wildlife-draft, nerdery-upload-encounter-photo.
    @case:nrd-offline-sync-photo-failed
    @status:not-built
    Scenario: A failed photo upload preserves the local draft for retry
      Given an owned pending offline encounter identity
        """json
        {
          "encounterId": "offline-001"
        }
        """
      And Avery is back online and server photo storage fails before commit
      When the offline encounter is synchronized for the authenticated user
      Then the encounter is server-recorded once or remains visibly pending with a named synchronization reason
        | operation | path | equals |
        | nerdery-synchronize-offline-encounter.synchronize | $.status | PENDING_SYNC |
        | nerdery-synchronize-offline-encounter.synchronize | $.reason.code | PHOTO_STORAGE_UNAVAILABLE |
        | nerdery-synchronize-offline-encounter.synchronize | $.draft.photoRetained | true |
        | nerdery-synchronize-offline-encounter.synchronize | $.serverRecorded | false |
        | nerdery-synchronize-offline-encounter.synchronize | $.draft.state | PENDING_SYNC |
```
