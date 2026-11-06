# sfx-aws-select-recovery-option: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): SELECTED, NO_ACTION, REFUSED.
# Source reference IDs: AWS-SSM-01, AWS-IAM-01.
# Pinned review decision: D01. Priority: P0.

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

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-stopped-ec2.json (sha256:ebe8ca7d914fa5032d4250723b7a2becf73051668e68464969366fe495b970dc).
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
        | sfx-aws-select-recovery-option.select | $.option.requiresApproval | true |

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-running.json (sha256:2d88c9bf8d334cca032770d6ee92d5e72b4286b38e679c4f93a91f752a8c5a54).
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

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-no-runbook.json (sha256:e7372bfbc4972d8b1dfcf58fbc28ce06b441fb21af383d3768b41b45d7b67467).
    @case:aws-option-no-runbook
    @status:not-built
    Scenario: Unknown failures do not create speculative shell commands
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "degraded-unknown"
        }
        """
      And the pinned acceptance arrangement for aws-option-no-runbook is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | NO_ACTION |
        | sfx-aws-select-recovery-option.select | $.option | (absent) |

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-unapproved.json (sha256:c805116e82207a71bd97df98b79fec4a9fd45fd51342370c7f894a8d92a73e1c).
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

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-other-account.json (sha256:b95fb92bf127d04736bcfa426616c5cda9e395367e2f36c0ccc7eb6dd1f5618e).
    @case:aws-option-other-account
    @status:not-built
    Scenario: An action is not selected for an unapproved account
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "stopped"
        }
        """
      And the pinned acceptance arrangement for aws-option-other-account is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | REFUSED |
        | sfx-aws-select-recovery-option.select | $.reason | TARGET_NOT_IN_ALLOWED_SCOPE |

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-no-context.json (sha256:c1d85efd0b97dbf33ec8e87922c9cb96e71fc8d032175710a148af2212321f28).
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

