# sfx-aws-select-recovery-option: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: ssm:DescribeDocument.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): SELECTED, NO_ACTION, REFUSED.
# Source reference IDs: AWS-SSM-02, AWS-SSM-06, AWS-EC2-02, AWS-IAM-01.
# Priority: P0.

@capability:sfx-aws-select-recovery-option
@root-scenario:sfx-aws-select-recovery-option
@scenario:sfx-aws-select-recovery-option
@input:sfx-aws-select-recovery-option-request
@input-contract:sfx-aws-select-recovery-option-request.v1
@event:sfx-aws-select-recovery-option-requested
@event-authority:sfx-aws-select-recovery-option.v1
@outcome:sfx-aws-select-recovery-option-outcome
@outcome-contract:sfx-aws-select-recovery-option-result.v1
@outcome-terminal
Feature: Select a governed recovery option
  As a on-call cloud operator
  I want a permitted action matched to the observed cloud condition
  So that remediation options follow the resource state and approved runbook policy

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Fixture: fixtures/cases/aws-option-stopped-ec2.json (sha256:cdaadf8352e6143bd4786bc90994f3e40ec772f7fbfed6d9716286545256b9cb).
    # AWS: AWS-StartEC2InstanceWithApproval is an AWS-owned runbook taking InstanceId, Approvers and SNSTopicArn (AWS-SSM-02).
    # Curated: The admitted option pins the runbook version, and the runbook's existence is read back. Version 1 is synthetic: read it from DescribeDocument in the sandbox account.
    @case:aws-option-stopped-ec2
    @status:not-built
    Scenario: A stopped EC2 instance matches a start-with-approval option
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "stopped"
        }
        """
      And the pinned acceptance arrangement for aws-option-stopped-ec2 is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | SELECTED |
        | sfx-aws-select-recovery-option.select | $.option.documentName | AWS-StartEC2InstanceWithApproval |
        | sfx-aws-select-recovery-option.select | $.option.documentVersion | 1 |
        | sfx-aws-select-recovery-option.select | $.option.requiresApproval | true |
        | sfx-aws-select-recovery-option.select | $.option.parameters.InstanceId | i-0123456789abcdef0 |

    # Fixture: fixtures/cases/aws-option-running.json (sha256:cba7456aeed78a49183f9021d008111df9f5a11fd4fb36628602e4484adcc9f9).
    # AWS: running is a documented instance state (AWS-EC2-01).
    @case:aws-option-running
    @status:not-built
    Scenario: A running EC2 instance is not started again
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "running"
        }
        """
      And the pinned acceptance arrangement for aws-option-running is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | NO_ACTION |
        | sfx-aws-select-recovery-option.select | $.reason | NO_ELIGIBLE_ACTION |

    # Fixture: fixtures/cases/aws-option-no-runbook.json (sha256:4087e9a0999250936901b6bc7378ee1d711926f9df9c32df2d4a4cae4f175f8b).
    # AWS: impaired is a documented status-check value (AWS-EC2-02); AWS-RestartEC2Instance exists (AWS-SSM-06) but is not admitted here.
    # Curated: 'degraded-unknown' is not an EC2 state; the instance is running with an impaired status check, which no admitted runbook addresses.
    @case:aws-option-no-runbook
    @status:not-built
    Scenario: An impaired instance with no admitted runbook gets no speculative command
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "running",
          "statusChecks": "impaired"
        }
        """
      And the pinned acceptance arrangement for aws-option-no-runbook is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | NO_ACTION |
        | sfx-aws-select-recovery-option.select | $.reason | NO_ELIGIBLE_ACTION |
        | sfx-aws-select-recovery-option.select | $.option | (absent) |

    # Fixture: fixtures/cases/aws-option-unapproved.json (sha256:779fc7ea96a39ca85ba5dc413282acd80369513e22c557c3d3dc79e6e63bcfd8).
    # AWS: Any account can own a custom Automation document (AWS-SSM-01 DocumentName); owning one is not admission.
    @case:aws-option-unapproved
    @status:not-built
    Scenario: An unapproved custom runbook is ineligible
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "stopped"
        }
        """
      And the pinned acceptance arrangement for aws-option-unapproved is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | NO_ACTION |
        | sfx-aws-select-recovery-option.select | $.reason | RUNBOOK_NOT_ADMITTED |

    # Fixture: fixtures/cases/aws-option-other-account.json (sha256:c6c96bd98f3bee4a6f92e2aacdeb2eb1ae8e7f82894c446b44db7e4c659d29e1).
    # AWS: None: account admission is SideFX's.
    # Curated: The request's account and resource ARN now agree (both 999988887777).
    @case:aws-option-other-account
    @status:not-built
    Scenario: An action is not selected for an unapproved account
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:999988887777:instance/i-0123456789abcdef0",
          "resourceState": "stopped"
        }
        """
      And the pinned acceptance arrangement for aws-option-other-account is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | REFUSED |
        | sfx-aws-select-recovery-option.select | $.reason | TARGET_NOT_IN_ALLOWED_SCOPE |

    # Fixture: fixtures/cases/aws-option-no-context.json (sha256:16730469ca6236d8a735915570c7dc535aa71ca17f8e9ffe5ca4ba13251a31fc).
    # AWS: None: there is no state to match against the catalog.
    @case:aws-option-no-context
    @status:not-built
    Scenario: A missing current state cannot be interpreted as stopped
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": null
        }
        """
      And the pinned acceptance arrangement for aws-option-no-context is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | NO_ACTION |
        | sfx-aws-select-recovery-option.select | $.reason | CURRENT_STATE_NOT_OBSERVABLE |
