# sfx-aws-resolve-resource-context: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): RESOLVED, PARTIAL, REFUSED.
# Source reference IDs: AWS-CONFIG-01, AWS-IAM-01, AWS-ORG-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-resolve-resource-context
@root-scenario:sfx-aws-resolve-resource-context
@scenario:sfx-aws-resolve-resource-context
@input:sfx-aws-resolve-resource-context-request
@input-contract:sfx-aws-resolve-resource-context-request.v1
@event:sfx-aws-resolve-resource-context-requested
@event-authority:sfx-aws-resolve-resource-context.v1
@outcome:sfx-aws-resolve-resource-context-outcome
@outcome-contract:sfx-aws-resolve-resource-context-result.v1
@outcome-terminal
Feature: Resolve affected AWS resource context
  As a cloud operations engineer
  I want the ownership and current condition of a cloud resource
  So that the team can target the correct account, environment and service without guessing

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-CONFIG-01, AWS-IAM-01, AWS-ORG-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-context-ec2.json (sha256:655a08d479314a8bfa552a83505b30550e6959ab62b4b3a322861a15d795274e).
    @case:aws-context-ec2
    @status:not-built
    Scenario: An admitted EC2 resource resolves with owner and environment
      Given an admitted operational signal and an AWS resource identity
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-context-ec2 is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | RESOLVED |
        | sfx-aws-resolve-resource-context.resolve | $.resource.instanceId | i-0123456789abcdef0 |
        | sfx-aws-resolve-resource-context.resolve | $.resource.environment | production |
        | sfx-aws-resolve-resource-context.resolve | $.resource.lifecycleState | stopped |

    # Sources: AWS-CONFIG-01, AWS-IAM-01, AWS-ORG-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-context-cross-account.json (sha256:89b0b320a960f8c1278cb6fe7048435fee958f280931e8e4817cdfe99fc7cca7).
    @case:aws-context-cross-account
    @status:not-built
    Scenario: Cross-account inventory is read only when access is admitted
      Given an admitted operational signal and an AWS resource identity
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-context-cross-account is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | RESOLVED |
        | sfx-aws-resolve-resource-context.resolve | $.access.mode | assumed-read-only-role |
        | sfx-aws-resolve-resource-context.resolve | $.resource.serviceId | citizen-portal |

    # Sources: AWS-CONFIG-01, AWS-IAM-01, AWS-ORG-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-context-no-recording.json (sha256:947837ffe6a712ef3b4b0f8ee3ee8ad98302e1e34fe04818f84e1dc3175f6cca).
    @case:aws-context-no-recording
    @status:not-built
    Scenario: Missing Config recording is reported as partial coverage
      Given an admitted operational signal and an AWS resource identity
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-context-no-recording is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | PARTIAL |
        | sfx-aws-resolve-resource-context.resolve | $.reason | CONFIG_COVERAGE_MISSING |
        | sfx-aws-resolve-resource-context.resolve | $.resource.lifecycleState | stopped |

    # Sources: AWS-CONFIG-01, AWS-IAM-01, AWS-ORG-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-context-unauthorized.json (sha256:e028bb32bc3e35f44abbe2f75b91aca0b6f4a45a2806398e21f0fb65685d7f2a).
    @case:aws-context-unauthorized
    @status:not-built
    Scenario: A cross-account role denial cannot be silently bypassed
      Given an admitted operational signal and an AWS resource identity
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-context-unauthorized is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | REFUSED |
        | sfx-aws-resolve-resource-context.resolve | $.reason | CROSS_ACCOUNT_ACCESS_DENIED |

    # Sources: AWS-CONFIG-01, AWS-IAM-01, AWS-ORG-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-context-tag-absent.json (sha256:d97c707454db1074599eccd7f4a21a7c015d10d3071f6e5446a2d7be2fb17f37).
    @case:aws-context-tag-absent
    @status:not-built
    Scenario: An unowned resource is not assigned a fictional team
      Given an admitted operational signal and an AWS resource identity
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-context-tag-absent is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | PARTIAL |
        | sfx-aws-resolve-resource-context.resolve | $.resource.owner | (absent) |
        | sfx-aws-resolve-resource-context.resolve | $.reason | OWNER_NOT_OBSERVABLE |

    # Sources: AWS-CONFIG-01, AWS-IAM-01, AWS-ORG-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-context-region.json (sha256:b787ad35f580b8623973d1860446d6f7f24891ca3fa8c5147cfe9d8cf37ab277).
    @case:aws-context-region
    @status:not-built
    Scenario: Evidence from another Region cannot resolve the target resource
      Given an admitted operational signal and an AWS resource identity
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-context-region is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | REFUSED |
        | sfx-aws-resolve-resource-context.resolve | $.reason | RESOURCE_SCOPE_MISMATCH |

    # Sources: AWS-CONFIG-01, AWS-IAM-01, AWS-ORG-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-context-stale.json (sha256:8d5684557a46d4aa587a3671f49a1c697dc138f9049e11951950ecfa7285e354).
    @case:aws-context-stale
    @status:not-built
    Scenario: Stale aggregate data is flagged rather than declared current
      Given an admitted operational signal and an AWS resource identity
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-context-stale is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | PARTIAL |
        | sfx-aws-resolve-resource-context.resolve | $.reason | CONFIG_EVIDENCE_STALE |

