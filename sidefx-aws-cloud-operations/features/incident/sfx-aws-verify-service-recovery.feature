# sfx-aws-verify-service-recovery: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): RESTORED, NOT_RESTORED, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CW-01, AWS-SSM-01, AWS-SLO-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-verify-service-recovery
@root-scenario:sfx-aws-verify-service-recovery
@scenario:sfx-aws-verify-service-recovery
@input:sfx-aws-verify-service-recovery-request
@input-contract:sfx-aws-verify-service-recovery-request.v1
@event:sfx-aws-verify-service-recovery-requested
@event-authority:sfx-aws-verify-service-recovery.v1
@outcome:sfx-aws-verify-service-recovery-outcome
@outcome-contract:sfx-aws-verify-service-recovery-result.v1
@outcome-terminal
Feature: Verify a cloud service recovery from independent observations
  As a cloud operations manager
  I want proof that the operational experience has recovered
  So that a successful automation invocation never substitutes for a healthy service

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-restored.json (sha256:40f010808521faffefe80595a892eb4ab07eb31bf54723a1d61d805ce090388e).
    @case:aws-verify-restored
    @status:not-built
    Scenario: Successful automation plus healthy post-state confirms recovery
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-restored is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | RESTORED |
        | sfx-aws-verify-service-recovery.verify | $.serviceState | HEALTHY |
        | sfx-aws-verify-service-recovery.verify | $.evidence.automationStatus | Success |
        | sfx-aws-verify-service-recovery.verify | $.evidence.ec2State | running |
        | sfx-aws-verify-service-recovery.verify | $.verified | true |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-ssm-only.json (sha256:20884c16a8296fa0e046bc851db12a3f7921ed7fcd5a7cd0dd814cae15a5ed5c).
    @case:aws-verify-ssm-only
    @status:not-built
    Scenario: A successful runbook with no healthy service evidence is not recovery
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-ssm-only is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_OBSERVABLE |
        | sfx-aws-verify-service-recovery.verify | $.reason | POST_ACTION_HEALTH_EVIDENCE_MISSING |
        | sfx-aws-verify-service-recovery.verify | $.verified | false |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-still-bad.json (sha256:551ee0f35a19d56545d553ff440bb9bed75b4f06bd7b90d8799088a3bf74c127).
    @case:aws-verify-still-bad
    @status:not-built
    Scenario: Persistent alarm proves not restored
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-still-bad is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_RESTORED |
        | sfx-aws-verify-service-recovery.verify | $.serviceState | DEGRADED |
        | sfx-aws-verify-service-recovery.verify | $.verified | false |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-not-complete.json (sha256:831f23f8ce41ecfeb4f7aaa2c9c4bfff0e0984a8c90433afc5e7b005bfcf15a3).
    @case:aws-verify-not-complete
    @status:not-built
    Scenario: A waiting-for-approval runbook is not completed
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-not-complete is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_OBSERVABLE |
        | sfx-aws-verify-service-recovery.verify | $.reason | AUTOMATION_NOT_TERMINAL |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-wrong-service.json (sha256:28179c5c83525e43430869785df60d44241cb055515f58ef7901789e507643d9).
    @case:aws-verify-wrong-service
    @status:not-built
    Scenario: A healthy metric for another service is not success
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-wrong-service is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | REFUSED |
        | sfx-aws-verify-service-recovery.verify | $.reason | POST_ACTION_EVIDENCE_SCOPE_MISMATCH |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-failed-runbook.json (sha256:24251a4e25dde08997bbdea620cacd0b48ef842abee3002d5e1250eed66a7e1a).
    @case:aws-verify-failed-runbook
    @status:not-built
    Scenario: A failed runbook is not recovery even if some metric recovers
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-failed-runbook is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_RESTORED |
        | sfx-aws-verify-service-recovery.verify | $.evidence.automationStatus | Failed |
        | sfx-aws-verify-service-recovery.verify | $.verified | false |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-stale.json (sha256:d7002de7b103473d1915be2e825663e341aaa242c7da6ff66cd1157f463a82dc).
    @case:aws-verify-stale
    @status:not-built
    Scenario: Old metric data is insufficient for a fresh recovery claim
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-stale is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_OBSERVABLE |
        | sfx-aws-verify-service-recovery.verify | $.reason | POST_ACTION_METRICS_STALE |

