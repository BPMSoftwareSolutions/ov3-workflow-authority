# sfx-aws-verify-service-recovery: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: ssm:GetAutomationExecution, ec2:DescribeInstanceStatus, cloudwatch:GetMetricData.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): RESTORED, NOT_RESTORED, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-SSM-03, AWS-SSM-04, AWS-EC2-01, AWS-EC2-02, AWS-CW-02, AWS-SLO-01.
# Priority: P0.

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

    # Fixture: fixtures/cases/aws-verify-restored.json (sha256:e33ca6cf6d85aa86eb8f4da50abc4c0acc8b8d6a24adb26558bf2034eaa64a6a).
    # AWS: Success is terminal; both status checks ok is the EC2 health proof; the heartbeat meets the objective (AWS-SSM-03, AWS-EC2-02, AWS-CW-02).
    # Curated: Recovery also needs both EC2 status checks ok, not only the running state.
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
          "automationExecutionId": "9ec30224-cda9-476e-8a45-506226b0a1d1"
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
        | sfx-aws-verify-service-recovery.verify | $.evidence.statusChecks | ok |
        | sfx-aws-verify-service-recovery.verify | $.verified | true |

    # Fixture: fixtures/cases/aws-verify-ssm-only.json (sha256:3a6a9f1f2eef6b461c660bc758bf103ea80b667bb97bad740635626da864e9bf).
    # AWS: GetMetricData can complete with no datapoints in the window (AWS-CW-02).
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
          "automationExecutionId": "9ec30224-cda9-476e-8a45-506226b0a1d1"
        }
        """
      And the pinned acceptance arrangement for aws-verify-ssm-only is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_OBSERVABLE |
        | sfx-aws-verify-service-recovery.verify | $.reason | POST_ACTION_HEALTH_EVIDENCE_MISSING |
        | sfx-aws-verify-service-recovery.verify | $.verified | false |

    # Fixture: fixtures/cases/aws-verify-still-bad.json (sha256:cd85f2d16d36fa2e02e0711bbb2b18ad6eb419eab9fde5c75253d6cdb5108179).
    # AWS: As in the restored case, with the heartbeat below the objective (AWS-CW-02).
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
          "automationExecutionId": "9ec30224-cda9-476e-8a45-506226b0a1d1"
        }
        """
      And the pinned acceptance arrangement for aws-verify-still-bad is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_RESTORED |
        | sfx-aws-verify-service-recovery.verify | $.serviceState | DEGRADED |
        | sfx-aws-verify-service-recovery.verify | $.verified | false |

    # Fixture: fixtures/cases/aws-verify-not-complete.json (sha256:09dc9940255bc0b1bea81348992b4cbab99a00f81e083a0adc8dea4ed0915cad).
    # AWS: While its aws:approve step waits, the execution reads Waiting (AWS-SSM-03, AWS-SSM-04).
    # Curated: WaitingForApproval is not an AutomationExecutionStatus value; the documented value is Waiting.
    @case:aws-verify-not-complete
    @status:not-built
    Scenario: A runbook waiting for approval is not completed
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "9ec30224-cda9-476e-8a45-506226b0a1d1"
        }
        """
      And the pinned acceptance arrangement for aws-verify-not-complete is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_OBSERVABLE |
        | sfx-aws-verify-service-recovery.verify | $.reason | AUTOMATION_NOT_TERMINAL |

    # Fixture: fixtures/cases/aws-verify-wrong-service.json (sha256:3750cfc5f835259a2622181a772e542f34abbe0420db822d38737d2e986bdf87).
    # AWS: The metric is selected by its dimensions (AWS-CW-02).
    # Curated: The mismatch is in the post-action binding, refused before the metric is read.
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
          "automationExecutionId": "9ec30224-cda9-476e-8a45-506226b0a1d1"
        }
        """
      And the pinned acceptance arrangement for aws-verify-wrong-service is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | REFUSED |
        | sfx-aws-verify-service-recovery.verify | $.reason | POST_ACTION_EVIDENCE_SCOPE_MISMATCH |

    # Fixture: fixtures/cases/aws-verify-failed-runbook.json (sha256:d575f35c239d1493e24e5db4ed79158de02882a8d0cdd9fd4cb5029596e4e6be).
    # AWS: Failed carries a FailureMessage; a stopped instance reports its status checks as not-applicable (AWS-SSM-03, AWS-EC2-02).
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
          "automationExecutionId": "9ec30224-cda9-476e-8a45-506226b0a1d1"
        }
        """
      And the pinned acceptance arrangement for aws-verify-failed-runbook is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_RESTORED |
        | sfx-aws-verify-service-recovery.verify | $.evidence.automationStatus | Failed |
        | sfx-aws-verify-service-recovery.verify | $.verified | false |

    # Fixture: fixtures/cases/aws-verify-stale.json (sha256:7d03c0135d20b19067195fcf2aa83dbd54f850255697166b969d3f779f321e7c).
    # AWS: Over the last hour the newest datapoint is 25 minutes old (AWS-CW-02).
    # Curated: A 120-minute-old datapoint could not come back from an hour's query; the stale datapoint now sits inside the queried hour.
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
          "automationExecutionId": "9ec30224-cda9-476e-8a45-506226b0a1d1"
        }
        """
      And the pinned acceptance arrangement for aws-verify-stale is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_OBSERVABLE |
        | sfx-aws-verify-service-recovery.verify | $.reason | POST_ACTION_METRICS_STALE |

    # Fixture: fixtures/cases/aws-verify-checks-initializing.json (sha256:f41fed3803fdadea6d3720019a5f37ee12070090b743f8eff556ec77aacc7606).
    # AWS: Right after a start the instance and system checks read initializing (AWS-EC2-02).
    # Curated: Added: a running state with checks still initializing is the commonest moment right after a start.
    @case:aws-verify-checks-initializing
    @status:not-built
    Scenario: A started instance whose status checks are still initializing is not yet recovered
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "9ec30224-cda9-476e-8a45-506226b0a1d1"
        }
        """
      And the pinned acceptance arrangement for aws-verify-checks-initializing is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_OBSERVABLE |
        | sfx-aws-verify-service-recovery.verify | $.reason | RECOVERY_CHECKS_INITIALIZING |
        | sfx-aws-verify-service-recovery.verify | $.verified | false |
