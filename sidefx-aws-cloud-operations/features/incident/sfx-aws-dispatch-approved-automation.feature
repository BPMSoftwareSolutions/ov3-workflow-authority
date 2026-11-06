# sfx-aws-dispatch-approved-automation: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): DISPATCHED, NOT_DISPATCHED, REFUSED.
# Source reference IDs: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-dispatch-approved-automation
@root-scenario:sfx-aws-dispatch-approved-automation
@scenario:sfx-aws-dispatch-approved-automation
@input:sfx-aws-dispatch-approved-automation-request
@input-contract:sfx-aws-dispatch-approved-automation-request.v1
@event:sfx-aws-dispatch-approved-automation-requested
@event-authority:sfx-aws-dispatch-approved-automation.v1
@outcome:sfx-aws-dispatch-approved-automation-outcome
@outcome-contract:sfx-aws-dispatch-approved-automation-result.v1
@outcome-terminal
Feature: Dispatch an approved AWS Automation runbook
  As a incident responder
  I want one attributable execution of an explicitly admitted runbook
  So that recovery is delegated to an AWS native operator under precise permission and idempotency

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-start.json (sha256:ee34b260570a5aef1b7330f8f3a7951e0e5b37415d43170d3163389c72bf1c56).
    @case:aws-dispatch-start
    @status:not-built
    Scenario: An authorized runbook is started once and returns an execution ID
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "clientToken": "remedy-001"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-start is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.documentName | AWS-StartEC2InstanceWithApproval |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.executionId | ssm-execution-001 |
        | sfx-aws-dispatch-approved-automation.dispatch | $.effect.completed | false |

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-retry.json (sha256:9ef16d3db317a865b599a2a1b3f893ce81aa506c07b20293f9fedb27f84b3c0d).
    @case:aws-dispatch-retry
    @status:not-built
    Scenario: A repeated token does not create a second automation execution
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "clientToken": "remedy-001"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-retry is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.executionId | ssm-execution-001 |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.newDispatch | false |

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-no-approval.json (sha256:696bbf67436cb370af0f76b3b76a60c7173b1b2bd9c2388e3ffeb57b60860c61).
    @case:aws-dispatch-no-approval
    @status:not-built
    Scenario: Without an approved effect identity no write is dispatched
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "clientToken": "remedy-002"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-no-approval is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | NOT_DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | EFFECT_NOT_AUTHORIZED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.writeAttempted | false |

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-wrong-runbook.json (sha256:59bb6b5db76b5f75f6f868a3f40e42f2265de13599890652d11a4894854d5fc3).
    @case:aws-dispatch-wrong-runbook
    @status:not-built
    Scenario: The runbook cannot be substituted between approval and use
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StopEC2InstanceWithApproval",
          "clientToken": "remedy-003"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-wrong-runbook is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | REFUSED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | RUNBOOK_BINDING_MISMATCH |
        | sfx-aws-dispatch-approved-automation.dispatch | $.writeAttempted | false |

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-failure.json (sha256:a5a9b9b4db1e189d8b129ce182533646258b2569cdf83e4b436469fe787af283).
    @case:aws-dispatch-failure
    @status:not-built
    Scenario: An AWS API failure is reported as not dispatched
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "clientToken": "remedy-004"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-failure is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | NOT_DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | AWS_DISPATCH_FAILED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation | (absent) |

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-unknown.json (sha256:783b42475f29cffba96914bb014d9d777cbb4580dcfac62daae111890e258928).
    @case:aws-dispatch-unknown
    @status:not-built
    Scenario: An ambiguous timeout is reconciled before any retry write
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "clientToken": "remedy-005"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-unknown is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | NOT_DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | DISPATCH_CONFIRMATION_UNKNOWN |
        | sfx-aws-dispatch-approved-automation.dispatch | $.writeRetried | false |

