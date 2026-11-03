# sfx-aws-report-operating-posture: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): REPORTED, INCOMPLETE, REFUSED.
# Source reference IDs: AWS-SLO-01, AWS-CE-01, AWS-BKP-01, AWS-SH-01.
# Pinned review decision: D01. Priority: P1.

@capability:sfx-aws-report-operating-posture
@root-scenario:sfx-aws-report-operating-posture
@scenario:sfx-aws-report-operating-posture
@input:sfx-aws-report-operating-posture-request
@input-contract:sfx-aws-report-operating-posture-request.v1
@event:sfx-aws-report-operating-posture-requested
@event-authority:sfx-aws-report-operating-posture.v1
@outcome:sfx-aws-report-operating-posture-outcome
@outcome-contract:sfx-aws-report-operating-posture-result.v1
@outcome-terminal
Feature: Report AWS cloud operations posture
  As a cloud operations manager
  I want a credible operating picture across reliability, security, cost and recovery
  So that leadership can see which obligations are met and which are not yet observable

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-SLO-01, AWS-CE-01, AWS-BKP-01, AWS-SH-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-posture-complete.json (sha256:8b0dba7a753028cbce8bd2e1c6f8f612e447cc4d3420dbf110523aa15012567e).
    @case:aws-posture-complete
    @status:not-built
    Scenario: A complete review covers reliability, security, cost and recovery
      Given a scoped estate window with admitted operational evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "reportPeriod": "2026-10"
        }
        """
      And the pinned acceptance arrangement for aws-posture-complete is established
      When the collected operational findings are assembled without hiding gaps
      Then a reviewable operating posture report or explicit incomplete disposition is available
        | operation | path | equals |
        | sfx-aws-report-operating-posture.report | $.status | REPORTED |
        | sfx-aws-report-operating-posture.report | $.coverage.reliability | OBSERVED |
        | sfx-aws-report-operating-posture.report | $.coverage.security | OBSERVED |
        | sfx-aws-report-operating-posture.report | $.coverage.cost | OBSERVED |
        | sfx-aws-report-operating-posture.report | $.coverage.recovery | OBSERVED |

    # Sources: AWS-SLO-01, AWS-CE-01, AWS-BKP-01, AWS-SH-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-posture-no-cost.json (sha256:c76b097caae4de7b8c6bab255382805f6cabac99ddc4870b398b9d468d1cf823).
    @case:aws-posture-no-cost
    @status:not-built
    Scenario: Missing cost data leaves the report incomplete but still reviewable
      Given a scoped estate window with admitted operational evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "reportPeriod": "2026-10"
        }
        """
      And the pinned acceptance arrangement for aws-posture-no-cost is established
      When the collected operational findings are assembled without hiding gaps
      Then a reviewable operating posture report or explicit incomplete disposition is available
        | operation | path | equals |
        | sfx-aws-report-operating-posture.report | $.status | INCOMPLETE |
        | sfx-aws-report-operating-posture.report | $.coverage.cost | NOT_OBSERVABLE |
        | sfx-aws-report-operating-posture.report | $.missingDomains | ["cost"] |

    # Sources: AWS-SLO-01, AWS-CE-01, AWS-BKP-01, AWS-SH-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-posture-no-health.json (sha256:11cfdab14deea04d69abbd8e620e8c25e240b831171d22c408f80c670721d8bf).
    @case:aws-posture-no-health
    @status:not-built
    Scenario: Missing health data cannot be reported as zero incidents
      Given a scoped estate window with admitted operational evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "reportPeriod": "2026-10"
        }
        """
      And the pinned acceptance arrangement for aws-posture-no-health is established
      When the collected operational findings are assembled without hiding gaps
      Then a reviewable operating posture report or explicit incomplete disposition is available
        | operation | path | equals |
        | sfx-aws-report-operating-posture.report | $.status | INCOMPLETE |
        | sfx-aws-report-operating-posture.report | $.coverage.reliability | NOT_OBSERVABLE |

    # Sources: AWS-SLO-01, AWS-CE-01, AWS-BKP-01, AWS-SH-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-posture-account.json (sha256:d4d2a57d9b1f3cd90d3d1293caaacc91f021c1fc931cf68310906fec2a8203b7).
    @case:aws-posture-account
    @status:not-built
    Scenario: An unauthorized account is refused
      Given a scoped estate window with admitted operational evidence
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "reportPeriod": "2026-10"
        }
        """
      And the pinned acceptance arrangement for aws-posture-account is established
      When the collected operational findings are assembled without hiding gaps
      Then a reviewable operating posture report or explicit incomplete disposition is available
        | operation | path | equals |
        | sfx-aws-report-operating-posture.report | $.status | REFUSED |
        | sfx-aws-report-operating-posture.report | $.reason | ACCOUNT_NOT_ADMITTED |

    # Sources: AWS-SLO-01, AWS-CE-01, AWS-BKP-01, AWS-SH-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-posture-stale.json (sha256:44190b81724d2ebc2ab63dab07b6f421edd72a09219a474bbae8912dcdafcfdc).
    @case:aws-posture-stale
    @status:not-built
    Scenario: A stale security snapshot is not treated as current
      Given a scoped estate window with admitted operational evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "reportPeriod": "2026-10"
        }
        """
      And the pinned acceptance arrangement for aws-posture-stale is established
      When the collected operational findings are assembled without hiding gaps
      Then a reviewable operating posture report or explicit incomplete disposition is available
        | operation | path | equals |
        | sfx-aws-report-operating-posture.report | $.status | INCOMPLETE |
        | sfx-aws-report-operating-posture.report | $.coverage.security | STALE |

    # Sources: AWS-SLO-01, AWS-CE-01, AWS-BKP-01, AWS-SH-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-posture-no-rto.json (sha256:729cd462f0df327b33826eda44c0c3a02ca0314adb0a1b9f3c61de1d312cc88c).
    @case:aws-posture-no-rto
    @status:not-built
    Scenario: No declared recovery objective is visible as an operational gap
      Given a scoped estate window with admitted operational evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "reportPeriod": "2026-10"
        }
        """
      And the pinned acceptance arrangement for aws-posture-no-rto is established
      When the collected operational findings are assembled without hiding gaps
      Then a reviewable operating posture report or explicit incomplete disposition is available
        | operation | path | equals |
        | sfx-aws-report-operating-posture.report | $.status | INCOMPLETE |
        | sfx-aws-report-operating-posture.report | $.coverage.recovery | NOT_OBSERVABLE |

