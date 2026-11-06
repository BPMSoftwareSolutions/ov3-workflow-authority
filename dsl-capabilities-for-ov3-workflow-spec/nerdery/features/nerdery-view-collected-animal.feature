# nerdery-view-collected-animal: canonical feature for the SideFX build, 2026-11-03.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples, as the citizen slice's features follow them; not a new
# platform format.
# Status: written for the owner's request to see the photo of a collected animal when looking back at their animals. The
# owner-review package nerdery-canonical-features has no feature that reads a stored photo back; this one is canonical for
# the build and lives beside the slice's finalized features. Its arrangements are nerdery/fixtures/cases/*.json over that
# package's pinned base state.
# @status:probed: the case ran read-only against the wildlife procedures through nerdery/conformance/run-cases.mjs
# (run ef3510aa).
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# Provider: the operation is one sql-database-reader statement on sfx-identity (EXEC wildlife.serve), so every case is
# tagged @provider:sql-database-reader.
# The JSON under Given is the request body. The declared API operation binds the caller from the session the frontdoor
# validated; the capability input is {caller, request}. Fixture preparation is separate.
# A read changes nothing: every case leaves the stored state as it was.
# All JSON shapes/identities are proposed under D01. Case design decisions remain proposals, not Nerdery requirements.
# Scope: mvp. Source requirements: NRD-E06, NRD-E07.
# Proposed outcome contract: nerdery-view-collected-animal-result.v1; terminal variants: VISIBLE, REFUSED.
# Proposed operation identity: nerdery-view-collected-animal.view.

@capability:nerdery-view-collected-animal
@root-scenario:nerdery-view-collected-animal
@scenario:nerdery-view-collected-animal
@input:nerdery-view-collected-animal-request
@input-contract:nerdery-view-collected-animal-request.v1
@event:nerdery-view-collected-animal-requested
@event-authority:nerdery-view-collected-animal.v1
@outcome:nerdery-view-collected-animal-outcome
@outcome-contract:nerdery-view-collected-animal-result.v1
@outcome-terminal
Feature: View one collected individual with its photo
  As a citizen or biologist
  I want to open an animal in my collection and see the photo I uploaded for it
  So that I see my own photo of the animal together with what I recorded about it

  Rule: An individual is shown with the user's stored photo, nickname and recorded location

    # Source requirements: NRD-E06, NRD-E07.
    # Proposed decisions: D01, D05, D10.
    # Arrangement: nerdery/fixtures/cases/nrd-individual-visible.json (sha256:aa1802d1cc3578179f6be1220fff5c3cfdc0469a8fddfb29c9f482a3154e71ee).
    # The photo is returned as its stored bytes, base64 encoded, with the media type and digest recorded at upload.
    @case:nrd-individual-visible
    @status:probed
    @provider:sql-database-reader
    Scenario: The owner views a recorded individual with the photo they uploaded
      Given a request to view one collected individual
        """json
        {
          "encounterId": "enc-001"
        }
        """
      And Avery recorded enc-001, a Demo Heron nicknamed Reed, with the photo photo-a
      When the individual and its stored photo are read for the authenticated user
      Then the user can view the individual with its photo or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animal.view | $.status | VISIBLE |
        | nerdery-view-collected-animal.view | $.animal.encounterId | enc-001 |
        | nerdery-view-collected-animal.view | $.animal.ownerUserId | user-a |
        | nerdery-view-collected-animal.view | $.animal.definitionId | animal-001 |
        | nerdery-view-collected-animal.view | $.animal.commonName | Demo Heron |
        | nerdery-view-collected-animal.view | $.animal.nickname | Reed |
        | nerdery-view-collected-animal.view | $.animal.displayName | Reed |
        | nerdery-view-collected-animal.view | $.animal.location | {"source":"manual","description":"Synthetic park, north path"} |
        | nerdery-view-collected-animal.view | $.animal.photo.photoRef | photo-a |
        | nerdery-view-collected-animal.view | $.animal.photo.mediaType | image/png |
        | nerdery-view-collected-animal.view | $.animal.photo.byteLength | 73 |
        | nerdery-view-collected-animal.view | $.animal.photo.contentSha256 | sha256:8021bd6b739aa5464382e945cf4ab848c30f467b91ddb40d1c350354ec21cfa6 |
        | nerdery-view-collected-animal.view | $.animal.photo.contentBase64 | iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOInpwLRAwQCgAlugVtTkdgTAAAAABJRU5ErkJggg== |

    # Source requirements: NRD-E07.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery/fixtures/cases/nrd-individual-fallback-name.json (sha256:ebfe17577898d48674d88b026fb9a219ccf99315e07fa4e6eca029fc9f5cf0a1).
    @case:nrd-individual-fallback-name
    @status:probed
    @provider:sql-database-reader
    Scenario: Without a nickname the common name labels the user's photo
      Given a request to view one collected individual
        """json
        {
          "encounterId": "enc-003"
        }
        """
      And Avery recorded enc-003, a Demo Fox without a nickname, with the photo photo-a
      When the individual and its stored photo are read for the authenticated user
      Then the user can view the individual with its photo or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animal.view | $.status | VISIBLE |
        | nerdery-view-collected-animal.view | $.animal.encounterId | enc-003 |
        | nerdery-view-collected-animal.view | $.animal.commonName | Demo Fox |
        | nerdery-view-collected-animal.view | $.animal.nickname | null |
        | nerdery-view-collected-animal.view | $.animal.displayName | Demo Fox |
        | nerdery-view-collected-animal.view | $.animal.photo.photoRef | photo-a |
        | nerdery-view-collected-animal.view | $.animal.photo.contentSha256 | sha256:8021bd6b739aa5464382e945cf4ab848c30f467b91ddb40d1c350354ec21cfa6 |

  Rule: Only the authenticated owner can view an individual and its photo

    # Source requirements: NRD-E06.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery/fixtures/cases/nrd-individual-other-owner.json (sha256:a1cca5284f3916276b543959aed4c4ebc1fa6589ebf7a5c47c7fe6b88bc6617f).
    # Another user's individual is answered as not found, so its existence is not revealed.
    @case:nrd-individual-other-owner
    @status:probed
    @provider:sql-database-reader
    Scenario: Another user's individual cannot be viewed
      Given a request to view one collected individual
        """json
        {
          "encounterId": "enc-008"
        }
        """
      And enc-008 belongs to Blake and Avery is the authenticated user
      When the individual and its stored photo are read for the authenticated user
      Then the user can view the individual with its photo or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animal.view | $.status | REFUSED |
        | nerdery-view-collected-animal.view | $.reason.code | ENCOUNTER_NOT_FOUND |
        | nerdery-view-collected-animal.view | $.animal | (absent) |

    # Source requirements: NRD-E06.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery/fixtures/cases/nrd-individual-not-found.json (sha256:b69f7091c2350134267bac91695eaca4da3522a615b27cce0578adc34fda3ee3).
    @case:nrd-individual-not-found
    @status:probed
    @provider:sql-database-reader
    Scenario: An encounter that was never recorded cannot be viewed
      Given a request to view one collected individual
        """json
        {
          "encounterId": "enc-404"
        }
        """
      And no encounter enc-404 is recorded for any user
      When the individual and its stored photo are read for the authenticated user
      Then the user can view the individual with its photo or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animal.view | $.status | REFUSED |
        | nerdery-view-collected-animal.view | $.reason.code | ENCOUNTER_NOT_FOUND |
        | nerdery-view-collected-animal.view | $.animal | (absent) |

    # Source requirements: NRD-E06.
    # Proposed decisions: D01.
    # Arrangement: nerdery/fixtures/cases/nrd-individual-selection-required.json (sha256:a561cf5561ae2b1863384e5eb1ee3f4d6b148c4430bc7b30522d86c3e446042f).
    @case:nrd-individual-selection-required
    @status:probed
    @provider:sql-database-reader
    Scenario: Viewing an individual requires naming its encounter
      Given a request to view one collected individual
        """json
        {}
        """
      And Avery is signed in and the request names no encounter
      When the individual and its stored photo are read for the authenticated user
      Then the user can view the individual with its photo or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animal.view | $.status | REFUSED |
        | nerdery-view-collected-animal.view | $.reason.code | ENCOUNTER_SELECTION_REQUIRED |
        | nerdery-view-collected-animal.view | $.animal | (absent) |

    # Source requirements: NRD-E06.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery/fixtures/cases/nrd-individual-anonymous.json (sha256:fe986dd73412613829810adabc6fccf81152cb3778f706f501867d0d0e189028).
    # Refused inside the operation's one provider call; the stored state is unchanged.
    @case:nrd-individual-anonymous
    @status:probed
    @provider:sql-database-reader
    Scenario: An unauthenticated request cannot view an individual
      Given a request to view one collected individual
        """json
        {
          "encounterId": "enc-001"
        }
        """
      And no authenticated subject is available for the personal collection
      When the individual and its stored photo are read for the authenticated user
      Then the user can view the individual with its photo or a named refusal
        | operation | path | equals |
        | nerdery-view-collected-animal.view | $.status | REFUSED |
        | nerdery-view-collected-animal.view | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-view-collected-animal.view | $.animal | (absent) |
