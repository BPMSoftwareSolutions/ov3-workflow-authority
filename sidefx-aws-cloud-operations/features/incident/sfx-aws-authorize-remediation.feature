# sfx-aws-authorize-remediation: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): AUTHORIZED, PENDING_APPROVAL, REFUSED.
# Source reference IDs: AWS-IAM-01, AWS-SSM-02.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-authorize-remediation
@root-scenario:sfx-aws-authorize-remediation
@scenario:sfx-aws-authorize-remediation
@input:sfx-aws-authorize-remediation-request
@input-contract:sfx-aws-authorize-remediation-request.v1
@event:sfx-aws-authorize-remediation-requested
@event-authority:sfx-aws-authorize-remediation.v1
@outcome:sfx-aws-authorize-remediation-outcome
@outcome-contract:sfx-aws-authorize-remediation-result.v1
@outcome-terminal
Feature: Authorize an operational recovery effect
  As a cloud operations manager
  I want a reviewable permission decision for a particular cloud change
  So that a model suggestion or operator click cannot bypass the admitted effect boundary

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-approved.json (sha256:c71a6349a08954cca1ce885b633e0c0c33c778fddab37965e407de4a557e54c1).
    @case:aws-auth-approved
    @status:not-built
    Scenario: A scoped, independent approval authorizes the named action
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval"
        }
        """
      And the pinned acceptance arrangement for aws-auth-approved is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | AUTHORIZED |
        | sfx-aws-authorize-remediation.authorize | $.authorizedAction | start-ec2 |
        | sfx-aws-authorize-remediation.authorize | $.target.resourceArn | arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0 |
        | sfx-aws-authorize-remediation.authorize | $.approval.id | apr-001 |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-pending.json (sha256:3aa51792125764da1a99f9f3de1fec359406952c9bec27a3706acb3e30c836f8).
    @case:aws-auth-pending
    @status:not-built
    Scenario: Approval not yet recorded leaves the effect pending
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "documentName": "AWS-StartEC2InstanceWithApproval"
        }
        """
      And the pinned acceptance arrangement for aws-auth-pending is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | PENDING_APPROVAL |
        | sfx-aws-authorize-remediation.authorize | $.writeAllowed | false |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_REQUIRED |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-denied.json (sha256:c3d08aab4dd4589c3bb6304bca8f34217cadb5a3d6bfd25f97d5a2bae985b81d).
    @case:aws-auth-denied
    @status:not-built
    Scenario: A denied approval cannot become an authorized effect
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "approvalId": "apr-002"
        }
        """
      And the pinned acceptance arrangement for aws-auth-denied is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_DENIED |
        | sfx-aws-authorize-remediation.authorize | $.writeAllowed | false |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-wrong-target.json (sha256:d7282fc2e0e7a0fa59780357534b89d4e7673f09514adcef84f978a511101280).
    @case:aws-auth-wrong-target
    @status:not-built
    Scenario: An approval for another resource does not transfer
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "approvalId": "apr-003"
        }
        """
      And the pinned acceptance arrangement for aws-auth-wrong-target is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_SCOPE_MISMATCH |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-least-privilege.json (sha256:942bddb690e48d49be2d0f9fe40b5cbb82558119c08e8bf75db315e1474981d2).
    @case:aws-auth-least-privilege
    @status:not-built
    Scenario: A read-only operator cannot authorize the write
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "approvalId": "apr-004"
        }
        """
      And the pinned acceptance arrangement for aws-auth-least-privilege is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | OPERATOR_NOT_AUTHORIZED |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-stale.json (sha256:48e06dd34f658b57dc1299fac77c33367bdd8460aab27d133cd7e20436960880).
    @case:aws-auth-stale
    @status:not-built
    Scenario: An expired approval is not silently refreshed
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "approvalId": "apr-005"
        }
        """
      And the pinned acceptance arrangement for aws-auth-stale is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_EXPIRED |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-proposal-only.json (sha256:99078bb0dd4db66c59752ef041eb0a39f824a54f239fa9233f80ae6be9d84e57).
    @case:aws-auth-proposal-only
    @status:not-built
    Scenario: An AI-generated plan has no inherent cloud permission
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "proposalId": "model-plan-001"
        }
        """
      And the pinned acceptance arrangement for aws-auth-proposal-only is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | PENDING_APPROVAL |
        | sfx-aws-authorize-remediation.authorize | $.writeAllowed | false |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_REQUIRED |

