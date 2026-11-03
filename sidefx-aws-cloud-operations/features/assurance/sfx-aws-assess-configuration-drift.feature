# sfx-aws-assess-configuration-drift: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): DRIFT_DETECTED, NO_DRIFT, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CONFIG-01, AWS-CFN-01.
# Pinned review decision: D01. Priority: P1.

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

    # Sources: AWS-CONFIG-01, AWS-CFN-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-drift-tag.json (sha256:dd158f280295f5e46e13f1e82bf84ef8f4661d3f03bc735895b7ae86ccdab111).
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

    # Sources: AWS-CONFIG-01, AWS-CFN-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-drift-conforms.json (sha256:36cf8abebcdcf9c2851b092aefc105adc0ca76f001267a7f804938a81074a0d7).
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

    # Sources: AWS-CONFIG-01, AWS-CFN-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-drift-not-recorded.json (sha256:3bc01fcaafd77581f831a460ef65acea475b14f0f38f4eb59aa1664783e0f3ac).
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

    # Sources: AWS-CONFIG-01, AWS-CFN-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-drift-wrong-version.json (sha256:a66edfcdfb4cf719c856c6d660639416499b75ae06d2cb95895abdc3a856b791).
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

    # Sources: AWS-CONFIG-01, AWS-CFN-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-drift-unapproved-change.json (sha256:85aec0264864ce6da5c1506a6bba8b1f18d93c1b0d0a351ca78c74f6e186b195).
    @case:aws-drift-unapproved-change
    @status:not-built
    Scenario: A CloudFormation change set is a proposed change, not observed drift
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

    # Sources: AWS-CONFIG-01, AWS-CFN-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-drift-cross-account.json (sha256:bd820e07963347e3d2b59031373f30221d32ee02e6e3c91331d19b71a9a3f436).
    @case:aws-drift-cross-account
    @status:not-built
    Scenario: No read access to account is not a green posture
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

