# sfx-aws-assess-configuration-drift: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: sts:AssumeRole, config:GetAggregateResourceConfig, cloudformation:DescribeChangeSet.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): DRIFT_DETECTED, NO_DRIFT, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CONFIG-01, AWS-CONFIG-02, AWS-CONFIG-03, AWS-CFN-01, AWS-CFN-02, AWS-IAM-02.
# Priority: P1.

@capability:sfx-aws-assess-configuration-drift
@root-scenario:sfx-aws-assess-configuration-drift
@scenario:sfx-aws-assess-configuration-drift
@input:sfx-aws-assess-configuration-drift-request
@input-contract:sfx-aws-assess-configuration-drift-request.v1
@event:sfx-aws-assess-configuration-drift-requested
@event-authority:sfx-aws-assess-configuration-drift.v1
@outcome:sfx-aws-assess-configuration-drift-outcome
@outcome-contract:sfx-aws-assess-configuration-drift-result.v1
@outcome-terminal
Feature: Assess cloud configuration against governed expectations
  As a cloud governance owner
  I want a reviewable difference between intended and observed cloud resources
  So that configuration drift is interpreted from facts rather than a stale deployment diagram

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Fixture: fixtures/cases/aws-drift-tag.json (sha256:3a386f698118db43ad301d75f6e7b0305310238d3386ba3e69ae4d4186c4b0b8).
    # AWS: Tags come from the configuration item (AWS-CONFIG-03).
    @case:aws-drift-tag
    @status:not-built
    Scenario: A missing required ownership tag is reported precisely
      Given a declared resource policy and AWS configuration observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "policyId": "production-required-tags.v1"
        }
        """
      And the pinned acceptance arrangement for aws-drift-tag is established
      When the observed configuration is evaluated against its admitted target
      Then a specific drift finding, no drift, or a coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-configuration-drift.assess | $.status | DRIFT_DETECTED |
        | sfx-aws-assess-configuration-drift.assess | $.findings[0].code | REQUIRED_TAG_ABSENT |
        | sfx-aws-assess-configuration-drift.assess | $.findings[0].field | tags.owner |

    # Fixture: fixtures/cases/aws-drift-conforms.json (sha256:03273305e0ed841daa629452a249366d4a3b68a3cd9cca25ea2e83b71bb4a00a).
    # AWS: As above (AWS-CONFIG-03).
    @case:aws-drift-conforms
    @status:not-built
    Scenario: A resource satisfying its observed policy has no drift
      Given a declared resource policy and AWS configuration observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "policyId": "production-required-tags.v1"
        }
        """
      And the pinned acceptance arrangement for aws-drift-conforms is established
      When the observed configuration is evaluated against its admitted target
      Then a specific drift finding, no drift, or a coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-configuration-drift.assess | $.status | NO_DRIFT |
        | sfx-aws-assess-configuration-drift.assess | $.findings | [] |

    # Fixture: fixtures/cases/aws-drift-not-recorded.json (sha256:189925cf0476112ad25295387c480b72639590b17491e7f8a191a5e49ae5c56c).
    # AWS: ResourceNotDiscoveredException for a resource Config has not discovered (AWS-CONFIG-02).
    @case:aws-drift-not-recorded
    @status:not-built
    Scenario: A resource missing from Config coverage is not reported compliant
      Given a declared resource policy and AWS configuration observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "policyId": "production-required-tags.v1"
        }
        """
      And the pinned acceptance arrangement for aws-drift-not-recorded is established
      When the observed configuration is evaluated against its admitted target
      Then a specific drift finding, no drift, or a coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-configuration-drift.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-assess-configuration-drift.assess | $.reason | CONFIG_COVERAGE_MISSING |

    # Fixture: fixtures/cases/aws-drift-wrong-version.json (sha256:0d43dc02da57915ebf83a88ccca6e0297d3cd9d1f4c6239a49e867de0282afab).
    # AWS: None: policy admission is SideFX's.
    @case:aws-drift-wrong-version
    @status:not-built
    Scenario: A stale policy revision is not silently replaced
      Given a declared resource policy and AWS configuration observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "policyId": "production-required-tags.v0"
        }
        """
      And the pinned acceptance arrangement for aws-drift-wrong-version is established
      When the observed configuration is evaluated against its admitted target
      Then a specific drift finding, no drift, or a coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-configuration-drift.assess | $.status | REFUSED |
        | sfx-aws-assess-configuration-drift.assess | $.reason | POLICY_REVISION_NOT_ADMITTED |

    # Fixture: fixtures/cases/aws-drift-unapproved-change.json (sha256:4454e0dba2e5a5b71389bed9395ffa4f10fff56c2004a79f33517f50766a29ae).
    # AWS: A change set at Status CREATE_COMPLETE with ExecutionStatus AVAILABLE has not been applied (AWS-CFN-01, AWS-CFN-02).
    # Curated: The candidate's 'executed: false' is the documented ExecutionStatus AVAILABLE; the stack comes from CloudFormation's own aws:cloudformation:stack-name tag.
    @case:aws-drift-unapproved-change
    @status:not-built
    Scenario: A change set not yet executed is a proposed change, not observed drift
      Given a declared resource policy and AWS configuration observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "policyId": "production-required-tags.v1"
        }
        """
      And the pinned acceptance arrangement for aws-drift-unapproved-change is established
      When the observed configuration is evaluated against its admitted target
      Then a specific drift finding, no drift, or a coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-configuration-drift.assess | $.status | NO_DRIFT |
        | sfx-aws-assess-configuration-drift.assess | $.findings | [] |
        | sfx-aws-assess-configuration-drift.assess | $.pendingChanges | 1 |

    # Fixture: fixtures/cases/aws-drift-cross-account.json (sha256:0c023638c0187c08476d04c45b7f65c1ffffaeb6eaaa01dfdf6a31c832a00d03).
    # AWS: STS answers AccessDenied (AWS-IAM-02).
    @case:aws-drift-cross-account
    @status:not-built
    Scenario: No read access to the account is not a green posture
      Given a declared resource policy and AWS configuration observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "policyId": "production-required-tags.v1"
        }
        """
      And the pinned acceptance arrangement for aws-drift-cross-account is established
      When the observed configuration is evaluated against its admitted target
      Then a specific drift finding, no drift, or a coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-configuration-drift.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-assess-configuration-drift.assess | $.reason | ACCOUNT_READ_UNAVAILABLE |
