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
