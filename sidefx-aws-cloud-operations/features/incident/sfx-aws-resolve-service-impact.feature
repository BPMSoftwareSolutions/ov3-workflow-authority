# sfx-aws-resolve-service-impact: SideFX canonical feature candidate for cloud operations, 2026-11-03.
# Source: AWS official documentation references in source/aws-documentation-manifest.json.
# Product intent: interview architecture prototype. AWS cloud operations scenario identity is proposed, not admitted.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# And a pinned test arrangement is fixture setup, not application authority or proof of a completed AWS call.
# No @provider tag: exact SideFX provider capability IDs and port bindings must be discovered in the live estate.
# Provider candidates listed in this file are AWS supplier context only, never a binding proof.
# Synthetic account IDs/ARNs/observations cannot be presented as real AWS results.
# No @status:proven tags exist: none of the cases was run against the actual AWS or SideFX server.
# A result field like $.verified may be asserted only after attributable provider testimony and independent readback.
# Outcome variants (proposed): ASSESSED, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CW-01, AWS-SLO-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-resolve-service-impact
@root-scenario:sfx-aws-resolve-service-impact
@scenario:sfx-aws-resolve-service-impact
@input:sfx-aws-resolve-service-impact-request
@input-contract:sfx-aws-resolve-service-impact-request.v1
@event:sfx-aws-resolve-service-impact-requested
@event-authority:sfx-aws-resolve-service-impact.v1
@outcome:sfx-aws-resolve-service-impact-outcome
@outcome-contract:sfx-aws-resolve-service-impact-result.v1
@outcome-terminal
Feature: Assess operational service impact
  As a cloud operations manager
  I want an attributable view of service degradation and its coverage
  So that incident priority reflects service effect rather than alarm count

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-degraded.json (sha256:d009c0499a0aa122043dadff856f5b5160a998e0f10d8de7e92459a4ccc8d694).
    @case:aws-impact-degraded
    @status:not-built
    Scenario: A breached health target establishes degraded observed service state
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-impact-degraded is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | ASSESSED |
        | sfx-aws-resolve-service-impact.assess | $.impact.serviceState | DEGRADED |
        | sfx-aws-resolve-service-impact.assess | $.impact.serviceId | citizen-portal |
        | sfx-aws-resolve-service-impact.assess | $.impact.targetBreached | true |

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-normal.json (sha256:effc86614afa91743cee168730c25666cf7f964f0d5d7ad1399a59726a9f304d).
    @case:aws-impact-normal
    @status:not-built
    Scenario: A healthy metric does not fabricate an incident
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-002"
        }
        """
      And the pinned acceptance arrangement for aws-impact-normal is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | ASSESSED |
        | sfx-aws-resolve-service-impact.assess | $.impact.serviceState | HEALTHY |
        | sfx-aws-resolve-service-impact.assess | $.impact.targetBreached | false |

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-insufficient.json (sha256:47414152d3e85a3120803f6567a511f082552104fa06187c042652f60a51a450).
    @case:aws-impact-insufficient
    @status:not-built
    Scenario: INSUFFICIENT_DATA is not the same as HEALTHY
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-003"
        }
        """
      And the pinned acceptance arrangement for aws-impact-insufficient is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-resolve-service-impact.assess | $.reason | RELIABILITY_DATA_INSUFFICIENT |

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-unknown-slo.json (sha256:11b630bbf11ad0035ea6eec607016646eb5500421b01ff6001d93ae6e78af882).
    @case:aws-impact-unknown-slo
    @status:not-built
    Scenario: No configured service objective means no invented priority
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-impact-unknown-slo is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-resolve-service-impact.assess | $.reason | SERVICE_OBJECTIVE_UNDECLARED |

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-service-mismatch.json (sha256:6bdd6066f571271c823bc9a68772d5dc5802f396ab7a88ae938df9d5581f2e96).
    @case:aws-impact-service-mismatch
    @status:not-built
    Scenario: A foreign service metric is not joined to the incident
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-impact-service-mismatch is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | REFUSED |
        | sfx-aws-resolve-service-impact.assess | $.reason | SERVICE_METRIC_SCOPE_MISMATCH |

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-lag.json (sha256:e6036af507ad5eb43f870f40b68ae98e67d145e8cc8b9a7ed0893d18b40ffd66).
    @case:aws-impact-lag
    @status:not-built
    Scenario: Stale metrics are not presented as fresh operational state
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-impact-lag is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-resolve-service-impact.assess | $.reason | METRIC_WINDOW_STALE |

