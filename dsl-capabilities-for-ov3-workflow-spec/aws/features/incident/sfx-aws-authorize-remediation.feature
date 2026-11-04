# sfx-aws-authorize-remediation: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: none: authorization is SideFX's; the runbook's own aws:approve step is a second, AWS-side check observed later.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): AUTHORIZED, PENDING_APPROVAL, REFUSED.
# Source reference IDs: AWS-IAM-01, AWS-SSM-02, AWS-SSM-04.
# Priority: P0.

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

    # Fixture: fixtures/cases/aws-auth-approved.json (sha256:4c89e418b8bf438915fc6185a50f21955dbf005570dd58337b12b673abe0c145).
    # AWS: None.
    # Curated: The approval binds the runbook name and version as well as the action and target.
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
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
          "approvalId": "apr-001"
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
        | sfx-aws-authorize-remediation.authorize | $.approval.approver | ops-manager |

    # Fixture: fixtures/cases/aws-auth-pending.json (sha256:2226ceb1ddfae5c320d577d99c421bed1de49a273b8c929b56030dad2f62d7fc).
    # AWS: None.
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
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1"
        }
        """
      And the pinned acceptance arrangement for aws-auth-pending is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | PENDING_APPROVAL |
        | sfx-aws-authorize-remediation.authorize | $.writeAllowed | false |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_REQUIRED |

    # Fixture: fixtures/cases/aws-auth-denied.json (sha256:412b815b9aeb703e8b2f50ee5de2db413a421d987084e7dee5a7552176abafbb).
    # AWS: None.
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
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
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

    # Fixture: fixtures/cases/aws-auth-wrong-target.json (sha256:f04c54e9b54ff2dd76b97d3e1c73cb8962b5e360fb27fd91360f8aedb123f355).
    # AWS: None.
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
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
          "approvalId": "apr-003"
        }
        """
      And the pinned acceptance arrangement for aws-auth-wrong-target is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_SCOPE_MISMATCH |

    # Fixture: fixtures/cases/aws-auth-least-privilege.json (sha256:35901b8a9ff877aa942939731508e7e12a436bd79d8956f06c9a39a3c292ee16).
    # AWS: None.
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
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
          "approvalId": "apr-004"
        }
        """
      And the pinned acceptance arrangement for aws-auth-least-privilege is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | OPERATOR_NOT_AUTHORIZED |

    # Fixture: fixtures/cases/aws-auth-stale.json (sha256:68251722eb9bbf5e8f5cb420c738ae26aee61010a54d555fb69a003ca8721123).
    # AWS: None.
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
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
          "approvalId": "apr-005"
        }
        """
      And the pinned acceptance arrangement for aws-auth-stale is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_EXPIRED |

    # Fixture: fixtures/cases/aws-auth-proposal-only.json (sha256:cbf2f52995dc36b1604c09a0f258c4c3d2c409644a66fa980ca41d7fc9229990).
    # AWS: None.
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
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
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

    # Fixture: fixtures/cases/aws-auth-self-approval.json (sha256:8b564634156b4f4a2bd445bef65621b70bc0bf9c899cead54da7a7b349b4644b).
    # AWS: None: independence is decision D05; the runbook's aws:approve approvers are a separate AWS-side list (AWS-SSM-04).
    # Curated: Added: D05 asks for an independent approval and no candidate case tested independence.
    @case:aws-auth-self-approval
    @status:not-built
    Scenario: An operator cannot approve their own effect
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
          "approvalId": "apr-006"
        }
        """
      And the pinned acceptance arrangement for aws-auth-self-approval is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVER_NOT_INDEPENDENT |
        | sfx-aws-authorize-remediation.authorize | $.writeAllowed | false |
