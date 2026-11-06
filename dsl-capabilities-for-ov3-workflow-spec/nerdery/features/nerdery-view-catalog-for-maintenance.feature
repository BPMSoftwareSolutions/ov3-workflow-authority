# nerdery-view-catalog-for-maintenance: canonical feature for the wildlife application's local demo, 2026-11-03.
# Product authority: source/nerdery-architecture-design-challenge.pdf, identified in source/source-manifest.json.
# Authoring convention: the two supplied canonical feature examples, as the citizen slice's features follow them; not a new
# platform format.
# Status: written so a biologist can maintain the catalog. The update and remove features of the owner-review package
# nerdery-canonical-features name each definition's and attribute's expectedRevision, and the reads of that package never
# return a revision or, for an uncollected animal, its locked fields. This read returns both, to biologists only. Its
# arrangements are nerdery/fixtures/cases/*.json over that package's pinned base state.
# @status:probed: the case ran read-only against the wildlife procedures through nerdery/conformance/run-cases.mjs
# (runs 869e7203, 669ba146, dce56efb).
# Provider: the operation is one sql-database-reader statement on sfx-identity (EXEC wildlife.serve), so every case is
# tagged @provider:sql-database-reader.
# Every Scenario below is an acceptance case of the ONE circuit scenario tagged on this Feature.
# Given / When / Then are exact across cases. Given holds the request JSON. Then holds operation/path/equals.
# Values: true/false/null/numbers/arrays/objects are JSON values; other values are strings; (absent) selects nothing.
# Authentication, fixture state and dependency behavior come from the pinned test arrangement, never caller role claims.
# A read changes nothing: every case leaves the stored state as it was.
# All JSON shapes/identities are proposed under D01. Case design decisions remain proposals, not Nerdery requirements.
# Scope: mvp. Source requirements: NRD-U02, NRD-A01.
# Proposed outcome contract: nerdery-view-catalog-for-maintenance-result.v1; terminal variants: VISIBLE, REFUSED.
# Proposed operation identity: nerdery-view-catalog-for-maintenance.view.

@capability:nerdery-view-catalog-for-maintenance
@root-scenario:nerdery-view-catalog-for-maintenance
@scenario:nerdery-view-catalog-for-maintenance
@input:nerdery-view-catalog-for-maintenance-request
@input-contract:nerdery-view-catalog-for-maintenance-request.v1
@event:nerdery-view-catalog-for-maintenance-requested
@event-authority:nerdery-view-catalog-for-maintenance.v1
@outcome:nerdery-view-catalog-for-maintenance-outcome
@outcome-contract:nerdery-view-catalog-for-maintenance-result.v1
@outcome-terminal
Feature: View the catalog for maintenance
  As a biologist
  I want to see every animal definition and attribute with its current revision
  So that I can change or remove one from the revision I saw

  Rule: A biologist sees every definition and attribute in full, with its revision and whether it is active

    # Source requirements: NRD-U02, NRD-A01.
    # Proposed decisions: D01, D13.
    # Arrangement: nerdery/fixtures/cases/nrd-maintenance-biologist.json (sha256:fe0c0e29192cf893e36d2e4f7f6a7097ad12f74cbba4394ac11019719913f42c).
    # Casey has collected only Demo Heron; maintenance still shows Demo Fox's locked fields.
    @case:nrd-maintenance-biologist
    @status:probed
    @provider:sql-database-reader
    Scenario: A biologist sees the whole catalog with revisions
      Given a request to view the catalog for maintenance
        """json
        {}
        """
      And Casey is signed in as a biologist and has collected Demo Heron only
      When the catalog is read for maintenance by the authenticated user
      Then the user can view the catalog with its revisions or a named refusal
        | operation | path | equals |
        | nerdery-view-catalog-for-maintenance.view | $.status | VISIBLE |
        | nerdery-view-catalog-for-maintenance.view | $.definitions[0].definitionId | animal-001 |
        | nerdery-view-catalog-for-maintenance.view | $.definitions[0].revision | 1 |
        | nerdery-view-catalog-for-maintenance.view | $.definitions[1].scientificName | Synthetic scientific label 2 |
        | nerdery-view-catalog-for-maintenance.view | $.definitions[1].stats | {"Strength":3,"Size":4,"Speed":5} |
        | nerdery-view-catalog-for-maintenance.view | $.attributes[1].attributeId | habitat |
        | nerdery-view-catalog-for-maintenance.view | $.attributes[1].revision | 1 |
        | nerdery-view-catalog-for-maintenance.view | $.avatarPhotoRefs | ["avatar-001","avatar-002","avatar-003"] |

    # Source requirements: NRD-A01.
    # Proposed decisions: D01, D13.
    # Arrangement: nerdery/fixtures/cases/nrd-maintenance-inactive.json (sha256:375e20ab7e62975204e93404c755c049ded944dbc3f9ebb6a32b113f934e8498).
    @case:nrd-maintenance-inactive
    @status:probed
    @provider:sql-database-reader
    Scenario: A removed definition stays visible to maintenance as inactive
      Given a request to view the catalog for maintenance
        """json
        {}
        """
      And Demo Beetle was removed from the active catalog at revision 2
      When the catalog is read for maintenance by the authenticated user
      Then the user can view the catalog with its revisions or a named refusal
        | operation | path | equals |
        | nerdery-view-catalog-for-maintenance.view | $.status | VISIBLE |
        | nerdery-view-catalog-for-maintenance.view | $.definitions[2].definitionId | animal-003 |
        | nerdery-view-catalog-for-maintenance.view | $.definitions[2].active | false |
        | nerdery-view-catalog-for-maintenance.view | $.definitions[2].revision | 2 |

  Rule: Only biologists maintain the catalog

    # Source requirements: NRD-U02.
    # Proposed decisions: D01, D05.
    # Arrangement: nerdery/fixtures/cases/nrd-maintenance-citizen.json (sha256:be24516f717be7ca191d54bd26feab26146e9515134fc96631f52f91efd8fbca).
    @case:nrd-maintenance-citizen
    @status:probed
    @provider:sql-database-reader
    Scenario: A citizen cannot read the catalog for maintenance
      Given a request to view the catalog for maintenance
        """json
        {}
        """
      And Avery is signed in as a citizen
      When the catalog is read for maintenance by the authenticated user
      Then the user can view the catalog with its revisions or a named refusal
        | operation | path | equals |
        | nerdery-view-catalog-for-maintenance.view | $.status | REFUSED |
        | nerdery-view-catalog-for-maintenance.view | $.reason.code | BIOLOGIST_ROLE_REQUIRED |
        | nerdery-view-catalog-for-maintenance.view | $.definitions | (absent) |

    # Source requirements: NRD-U02.
    # Proposed decisions: D01.
    # Arrangement: nerdery/fixtures/cases/nrd-maintenance-anonymous.json (sha256:6d1275003ba3140df1b3c17ab2f5a088498b0f576196fe7066b62eb1967adf22).
    @case:nrd-maintenance-anonymous
    @status:probed
    @provider:sql-database-reader
    Scenario: An unauthenticated request cannot read the catalog for maintenance
      Given a request to view the catalog for maintenance
        """json
        {}
        """
      And no authenticated subject is available for catalog maintenance
      When the catalog is read for maintenance by the authenticated user
      Then the user can view the catalog with its revisions or a named refusal
        | operation | path | equals |
        | nerdery-view-catalog-for-maintenance.view | $.status | REFUSED |
        | nerdery-view-catalog-for-maintenance.view | $.reason.code | AUTHENTICATION_REQUIRED |
        | nerdery-view-catalog-for-maintenance.view | $.definitions | (absent) |
