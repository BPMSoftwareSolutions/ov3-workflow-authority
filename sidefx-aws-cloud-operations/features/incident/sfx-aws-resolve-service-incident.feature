# sfx-aws-resolve-service-incident: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): RESTORED, ESCALATED, HELD, REFUSED.
# Source reference IDs: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-resolve-service-incident
@root-scenario:sfx-aws-resolve-service-incident
@scenario:sfx-aws-resolve-service-incident
@input:sfx-aws-resolve-service-incident-request
@input-contract:sfx-aws-resolve-service-incident-request.v1
@event:sfx-aws-resolve-service-incident-requested
@event-authority:sfx-aws-resolve-service-incident.v1
@outcome:sfx-aws-resolve-service-incident-outcome
@outcome-contract:sfx-aws-resolve-service-incident-result.v1
@outcome-terminal
Feature: Resolve a cloud service incident through governed AWS capabilities
  As a cloud operations manager
  I want a service incident either recovered with proof or safely escalated
  So that every action, constraint and unresolved condition is visible in one incident circuit

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-end-to-end.json (sha256:61d6f90dc9c38cec83e063cebd0e0ea83da6790d6f663dee4a0e8d1d40cf024f).
    @case:aws-incident-end-to-end
    @status:not-built
    Scenario: A stopped instance is restarted after approval and proven healthy
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-001",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-end-to-end is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | RESTORED |
        | sfx-aws-resolve-service-incident.resolve | $.incidentId | inc-001 |
        | sfx-aws-resolve-service-incident.resolve | $.serviceState | HEALTHY |
        | sfx-aws-resolve-service-incident.resolve | $.evidence.recoveryVerified | true |
        | sfx-aws-resolve-service-incident.resolve | $.evidence.automationExecutionId | ssm-execution-001 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-denied.json (sha256:ffccd78dc868fae3306c7a66cba5898f38f691a6523831048c2b40a32a5baf6b).
    @case:aws-incident-denied
    @status:not-built
    Scenario: An approval denial safely escalates without running recovery
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-002",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-denied is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | ESCALATED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | REMEDIATION_NOT_APPROVED |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-no-evidence.json (sha256:2279c76aa8827dc7e648621da16385419a95c651126ee2ecd1274eedad2b1e4d).
    @case:aws-incident-no-evidence
    @status:not-built
    Scenario: A missing current-state read holds recovery and the incident remains unresolved
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-003",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-no-evidence is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | HELD |
        | sfx-aws-resolve-service-incident.resolve | $.reason | RESOURCE_CONTEXT_INCOMPLETE |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-ssm-failed.json (sha256:55edfa6fc7c73f22a6b1707bbf1ca483175e0e4a24e3d92c5318699e9a8be5e2).
    @case:aws-incident-ssm-failed
    @status:not-built
    Scenario: A failed runbook does not close the incident as restored
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-004",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-ssm-failed is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | ESCALATED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | RECOVERY_NOT_VERIFIED |
        | sfx-aws-resolve-service-incident.resolve | $.evidence.recoveryVerified | false |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-metric-gap.json (sha256:6ef882c7d3fbdc9b4d0a8418431ff076544c547e826df272a22fd2c88e8dc602).
    @case:aws-incident-metric-gap
    @status:not-built
    Scenario: Successful runbook with unavailable metrics retains a held outcome
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-005",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-metric-gap is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | HELD |
        | sfx-aws-resolve-service-incident.resolve | $.reason | RECOVERY_NOT_OBSERVABLE |
        | sfx-aws-resolve-service-incident.resolve | $.evidence.recoveryVerified | false |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-replayed.json (sha256:1f10e35134d3f10135f3f8b1db8adb70e0a89ed3e473c388e9d6d0d3f35885ee).
    @case:aws-incident-replayed
    @status:not-built
    Scenario: A replayed event cannot duplicate remediation
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-001",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-replayed is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | RESTORED |
        | sfx-aws-resolve-service-incident.resolve | $.incidentId | inc-001 |
        | sfx-aws-resolve-service-incident.resolve | $.effects.newExecutions | 0 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-foreign.json (sha256:bc95124db6232185b3993de4f0062bd2d8f1c2e66549df718739951f2cb348fd).
    @case:aws-incident-foreign
    @status:not-built
    Scenario: A foreign-account signal is rejected at intake
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-006"
        }
        """
      And the pinned acceptance arrangement for aws-incident-foreign is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | REFUSED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | ACCOUNT_NOT_ADMITTED |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-no-option.json (sha256:d214ccae2bf7411916a1a0dae11812a0b15ded589f67284f497d1495c781d7cc).
    @case:aws-incident-no-option
    @status:not-built
    Scenario: An unknown failure escalates for manual diagnosis, not an invented command
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-007",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-no-option is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | ESCALATED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | NO_ADMITTED_RECOVERY_ACTION |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |

