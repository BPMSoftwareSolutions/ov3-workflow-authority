# sfx-aws-triage-security-finding: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): TRIAGED, DUPLICATE, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-SH-01, AWS-IAM-01.
# Pinned review decision: D01. Priority: P1.

@capability:sfx-aws-triage-security-finding
@root-scenario:sfx-aws-triage-security-finding
@scenario:sfx-aws-triage-security-finding
@input:sfx-aws-triage-security-finding-request
@input-contract:sfx-aws-triage-security-finding-request.v1
@event:sfx-aws-triage-security-finding-requested
@event-authority:sfx-aws-triage-security-finding.v1
@outcome:sfx-aws-triage-security-finding-outcome
@outcome-contract:sfx-aws-triage-security-finding-result.v1
@outcome-terminal
Feature: Triage an AWS security finding with attributable evidence
  As a security operations manager
  I want a prioritized cloud-security observation with safe next action
  So that findings are not mistaken for automatically authorized remediations

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-high.json (sha256:766dbdbfb7c2a6538066b1980dfe374c85b090992fac73d4f7ed42a20c3896dc).
    @case:aws-sec-high
    @status:not-built
    Scenario: A high severity finding becomes a classified security work item
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-001",
          "source": "aws.securityhub"
        }
        """
      And the pinned acceptance arrangement for aws-sec-high is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | TRIAGED |
        | sfx-aws-triage-security-finding.triage | $.workItem.findingId | finding-001 |
        | sfx-aws-triage-security-finding.triage | $.workItem.severity | HIGH |
        | sfx-aws-triage-security-finding.triage | $.automaticRemediation | false |

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-duplicate.json (sha256:3dc0386adab9a40a2a4f12152367770b273b5e14c2201f81394a8f9000ae6c46).
    @case:aws-sec-duplicate
    @status:not-built
    Scenario: A repeated finding update is not a new issue by default
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-001",
          "source": "aws.securityhub"
        }
        """
      And the pinned acceptance arrangement for aws-sec-duplicate is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | DUPLICATE |
        | sfx-aws-triage-security-finding.triage | $.newWorkItem | false |

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-cross-account.json (sha256:a49c1530ce9332edd82400cae0accfc3774866b23e39a9c1c1360e4f532368da).
    @case:aws-sec-cross-account
    @status:not-built
    Scenario: A foreign account finding cannot enter the estate
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-002",
          "source": "aws.securityhub"
        }
        """
      And the pinned acceptance arrangement for aws-sec-cross-account is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | REFUSED |
        | sfx-aws-triage-security-finding.triage | $.reason | FINDING_ACCOUNT_NOT_ADMITTED |

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-v1v2.json (sha256:6d7f9141f47aeeaeb34d9a038d23c4462d14b0e7546549e2e92ab71879bf1b61).
    @case:aws-sec-v1v2
    @status:not-built
    Scenario: Legacy and V2 event formats are not double-counted
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-003",
          "source": "aws.securityhub"
        }
        """
      And the pinned acceptance arrangement for aws-sec-v1v2 is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | DUPLICATE |
        | sfx-aws-triage-security-finding.triage | $.newWorkItem | false |

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-missing-resource.json (sha256:f9687f0239a27a9684c7a63eb6d3b6c2e6391f1f758cd7243a0005afc59f587f).
    @case:aws-sec-missing-resource
    @status:not-built
    Scenario: A finding with no attributable resource is left unobserved
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-004",
          "source": "aws.securityhub"
        }
        """
      And the pinned acceptance arrangement for aws-sec-missing-resource is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | NOT_OBSERVABLE |
        | sfx-aws-triage-security-finding.triage | $.reason | RESOURCE_BINDING_MISSING |

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-no-auto-write.json (sha256:81e8ef87d58724dbd48ec45c7a04cb694895a9c19353f14b83de92fb73d0d0c0).
    @case:aws-sec-no-auto-write
    @status:not-built
    Scenario: Even a critical finding cannot create a deletion without authority
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-005",
          "source": "aws.securityhub",
          "proposedAction": "delete-resource"
        }
        """
      And the pinned acceptance arrangement for aws-sec-no-auto-write is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | TRIAGED |
        | sfx-aws-triage-security-finding.triage | $.automaticRemediation | false |
        | sfx-aws-triage-security-finding.triage | $.workItem.requiresReview | true |

