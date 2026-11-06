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
