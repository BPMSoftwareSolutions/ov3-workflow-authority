# sfx-aws-resolve-resource-context: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: sts:AssumeRole, config:GetAggregateResourceConfig, ec2:DescribeInstances.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): RESOLVED, PARTIAL, REFUSED.
# Source reference IDs: AWS-CONFIG-01, AWS-CONFIG-02, AWS-CONFIG-03, AWS-ORG-01, AWS-IAM-01, AWS-IAM-02, AWS-EC2-01.
# Priority: P0.

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

    # Fixture: fixtures/cases/aws-context-ec2.json (sha256:c1f5c5181781754d093e9eb799628fc5053d59b605028cc781c8fd7dd9cb3c0c).
    # AWS: The configuration item carries the tags; DescribeInstances gives the fresh state, because DescribeInstanceStatus omits stopped instances by default (AWS-CONFIG-03, AWS-EC2-01).
    # Curated: Observations are the documented configuration item and DescribeInstances shapes; the signal id is the admitted event's id.
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-context-ec2 is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | RESOLVED |
        | sfx-aws-resolve-resource-context.resolve | $.resource.instanceId | i-0123456789abcdef0 |
        | sfx-aws-resolve-resource-context.resolve | $.resource.environment | production |
        | sfx-aws-resolve-resource-context.resolve | $.resource.owner | operations |
        | sfx-aws-resolve-resource-context.resolve | $.resource.lifecycleState | stopped |
        | sfx-aws-resolve-resource-context.resolve | $.evidence.configurationItemStatus | OK |

    # Fixture: fixtures/cases/aws-context-cross-account.json (sha256:e5215968dbbc7a1a8290aade1c51e9607e9a436807196a2a0bf34d110507d9af).
    # AWS: AssumeRole returns the assumed-role identity the reads run as; credentials are never recorded (AWS-IAM-02).
    # Curated: The admitted role is named, and the result names the assumed-role session the reads ran as.
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-context-cross-account is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | RESOLVED |
        | sfx-aws-resolve-resource-context.resolve | $.access.mode | assumed-read-only-role |
        | sfx-aws-resolve-resource-context.resolve | $.access.assumedRoleArn | arn:aws:sts::111122223333:assumed-role/sidefx-cloudops-read/sidefx-context |
        | sfx-aws-resolve-resource-context.resolve | $.resource.serviceId | citizen-portal |

    # Fixture: fixtures/cases/aws-context-no-recording.json (sha256:e32b186f1059b4e421212fbc9000e72a17e21f7d5ce17b3cf11cb3efd6cf1d6e).
    # AWS: GetAggregateResourceConfig answers ResourceNotDiscoveredException for a resource Config has not discovered (AWS-CONFIG-02).
    # Curated: The candidate's 'not_enabled' becomes the documented error.
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-context-no-recording is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | PARTIAL |
        | sfx-aws-resolve-resource-context.resolve | $.reason | CONFIG_COVERAGE_MISSING |
        | sfx-aws-resolve-resource-context.resolve | $.resource.lifecycleState | stopped |

    # Fixture: fixtures/cases/aws-context-unauthorized.json (sha256:dcca23f2fd9c24924bc506464143e9a2210ef22198b029b37ae0f1b64e14c6d1).
    # AWS: STS answers AccessDenied (403) when the caller may not assume the role (AWS-IAM-02).
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-context-unauthorized is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | REFUSED |
        | sfx-aws-resolve-resource-context.resolve | $.reason | CROSS_ACCOUNT_ACCESS_DENIED |

    # Fixture: fixtures/cases/aws-context-tag-absent.json (sha256:cc339dab90edfbba3990eedac52f80d5089f8fff49423ff55c7bd91b3f39e9f8).
    # AWS: Tags come only from the configuration item's tags map (AWS-CONFIG-03).
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-context-tag-absent is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | PARTIAL |
        | sfx-aws-resolve-resource-context.resolve | $.resource.owner | (absent) |
        | sfx-aws-resolve-resource-context.resolve | $.reason | OWNER_NOT_OBSERVABLE |

    # Fixture: fixtures/cases/aws-context-region.json (sha256:c183bebe031706e12849c2d29bfc52d852bb900f38a2401bcb076dea39a6ff32).
    # AWS: GetAggregateResourceConfig reads exactly one SourceRegion, so it cannot hand back another Region's item (AWS-CONFIG-02).
    # Curated: The candidate returned a us-west-2 item for a us-east-2 lookup, which the API cannot do; the mismatch now sits in the request and is refused before any read.
    @case:aws-context-region
    @status:not-built
    Scenario: A resource in another Region cannot resolve the admitted target
      Given an admitted operational signal and an AWS resource identity
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-west-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-context-region is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | REFUSED |
        | sfx-aws-resolve-resource-context.resolve | $.reason | RESOURCE_SCOPE_MISMATCH |

    # Fixture: fixtures/cases/aws-context-stale.json (sha256:9452569ec95e3c2288951a2bec9d1bed671105920a8e1f2b92867c1e375d6d49).
    # AWS: With daily recording the item carries recordingFrequency DAILY and its capture time can be a day old (AWS-CONFIG-03).
    # Curated: Staleness comes from the documented capture time and daily recording, not an invented observedAt.
    @case:aws-context-stale
    @status:not-built
    Scenario: Stale configuration data is flagged rather than declared current
      Given an admitted operational signal and an AWS resource identity
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-context-stale is established
      When the governed resource context is resolved
      Then one attributable resource context or a named coverage limitation is available
        | operation | path | equals |
        | sfx-aws-resolve-resource-context.resolve | $.status | PARTIAL |
        | sfx-aws-resolve-resource-context.resolve | $.reason | CONFIG_EVIDENCE_STALE |
        | sfx-aws-resolve-resource-context.resolve | $.resource.lifecycleState | stopped |
