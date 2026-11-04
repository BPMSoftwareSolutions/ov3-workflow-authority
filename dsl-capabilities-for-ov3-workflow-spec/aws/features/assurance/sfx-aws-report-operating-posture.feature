# sfx-aws-report-operating-posture: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: none of its own: each domain is a component circuit's outcome, composed by case id.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): REPORTED, INCOMPLETE, REFUSED.
# Source reference IDs: AWS-CW-02, AWS-SH-01, AWS-CE-02, AWS-BKP-01.
# Priority: P1.

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

    # Fixture: fixtures/cases/aws-posture-complete.json (sha256:05ff536dea1c7100e848f9c59800aff32e167b2ed1f15bd7c1021aac48dcf5eb).
    # AWS: None beyond the components.
    # Curated: Each domain names the component case it rests on instead of an opaque 'observed'.
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

    # Fixture: fixtures/cases/aws-posture-no-cost.json (sha256:a1fcd0ad13e786da9b84662407003fc604220930563610d33603b275becf3cc6).
    # AWS: The cost read was denied (component aws-cost-denied).
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

    # Fixture: fixtures/cases/aws-posture-no-health.json (sha256:91c0197928b541a8853b03e99dd9511c7208901b8dee75fc2f4fba3c5adb3c47).
    # AWS: The heartbeat had no data (component aws-impact-insufficient).
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

    # Fixture: fixtures/cases/aws-posture-account.json (sha256:d1c607fbd991e9d2924c23c35c1d3e80c75b040ff4def8acc6bb7e6d85029836).
    # AWS: None.
    @case:aws-posture-account
    @status:not-built
    Scenario: An unauthorized account is refused
      Given a scoped estate window with admitted operational evidence
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:999988887777:instance/i-0123456789abcdef0",
          "reportPeriod": "2026-10"
        }
        """
      And the pinned acceptance arrangement for aws-posture-account is established
      When the collected operational findings are assembled without hiding gaps
      Then a reviewable operating posture report or explicit incomplete disposition is available
        | operation | path | equals |
        | sfx-aws-report-operating-posture.report | $.status | REFUSED |
        | sfx-aws-report-operating-posture.report | $.reason | ACCOUNT_NOT_ADMITTED |

    # Fixture: fixtures/cases/aws-posture-stale.json (sha256:8ae420eb13917439f83dff733051fcf5bc22ec14de2f1dd64a961e0a3a68c8ff).
    # AWS: None beyond the components.
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

    # Fixture: fixtures/cases/aws-posture-no-rto.json (sha256:aadec07a317e537121b14d58f33cb53b56885936788ee3816d1ed6c5201ad568).
    # AWS: None beyond the components.
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
