# sfx-aws-correlate-change-evidence: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: cloudtrail:LookupEvents.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): CORRELATED, UNCORRELATED, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CT-01, AWS-CT-02.
# Priority: P0.
# Removed case aws-change-outofscope: Event history is one account and one Region (AWS-CT-01), so another account's change can never appear in it. Reinstate the case with an organization event data store as its source when that source is admitted.

@capability:sfx-aws-correlate-change-evidence
@root-scenario:sfx-aws-correlate-change-evidence
@scenario:sfx-aws-correlate-change-evidence
@input:sfx-aws-correlate-change-evidence-request
@input-contract:sfx-aws-correlate-change-evidence-request.v1
@event:sfx-aws-correlate-change-evidence-requested
@event-authority:sfx-aws-correlate-change-evidence.v1
@outcome:sfx-aws-correlate-change-evidence-outcome
@outcome-contract:sfx-aws-correlate-change-evidence-result.v1
@outcome-terminal
Feature: Correlate infrastructure change evidence
  As a incident investigator
  I want historical change evidence relevant to an affected resource
  So that the team distinguishes observed change from a causal hypothesis

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Fixture: fixtures/cases/aws-change-stop.json (sha256:5dc8eabd73dc5e7a293c70e21435aacf1663bbcb3ce8a0e4f1bd0e755e18d7c1).
    # AWS: LookupEvents by ResourceName returns the event with ResourceType AWS::EC2::Instance and ResourceName, not an ARN (AWS-CT-02).
    # Curated: The recording is the documented LookupEvents shape; the result also names the CloudTrail event id it rests on.
    @case:aws-change-stop
    @status:not-built
    Scenario: A matching StopInstances CloudTrail management event is correlated
      Given a scoped resource and incident observation window
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "window": {
            "start": "2026-11-02T23:00:00Z",
            "end": "2026-11-03T01:00:00Z"
          }
        }
        """
      And the pinned acceptance arrangement for aws-change-stop is established
      When AWS change evidence is correlated without assuming causation
      Then a bounded change-evidence finding or an explicit evidence gap is available
        | operation | path | equals |
        | sfx-aws-correlate-change-evidence.correlate | $.status | CORRELATED |
        | sfx-aws-correlate-change-evidence.correlate | $.changes[0].eventName | StopInstances |
        | sfx-aws-correlate-change-evidence.correlate | $.changes[0].eventId | 31f872a1-6277-4d87-ac7c-f70711d37b36 |
        | sfx-aws-correlate-change-evidence.correlate | $.changes[0].resourceArn | arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0 |
        | sfx-aws-correlate-change-evidence.correlate | $.causationProven | false |

    # Fixture: fixtures/cases/aws-change-none.json (sha256:cc862ff73392f0b2487468682ba7e00b242a1d052f4ca2810c42b23830b08ecf).
    # AWS: Event history holds management events only, so an empty answer covers management activity in the window and nothing else (AWS-CT-01).
    @case:aws-change-none
    @status:not-built
    Scenario: No matching event means uncorrelated, not proof no change occurred
      Given a scoped resource and incident observation window
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "window": {
            "start": "2026-11-02T23:00:00Z",
            "end": "2026-11-03T01:00:00Z"
          }
        }
        """
      And the pinned acceptance arrangement for aws-change-none is established
      When AWS change evidence is correlated without assuming causation
      Then a bounded change-evidence finding or an explicit evidence gap is available
        | operation | path | equals |
        | sfx-aws-correlate-change-evidence.correlate | $.status | UNCORRELATED |
        | sfx-aws-correlate-change-evidence.correlate | $.changes | [] |
        | sfx-aws-correlate-change-evidence.correlate | $.coverage.complete | true |
        | sfx-aws-correlate-change-evidence.correlate | $.coverage.source | event-history |

    # Fixture: fixtures/cases/aws-change-gap.json (sha256:db5d5afb24b6fccf6bec6ce15efa10318b4b465133133f9e68513a19ad142cfc).
    # AWS: Lookups are limited to two a second per account and Region and fail with a throttling error beyond that (AWS-CT-02).
    # Curated: Event history is always on and is not a trail (AWS-CT-01), so 'missing trail' cannot happen for it; the documented failure is throttling, and TRAIL_QUERY_UNAVAILABLE becomes CHANGE_SOURCE_UNAVAILABLE.
    @case:aws-change-gap
    @status:not-built
    Scenario: A throttled lookup is a visibility gap, not an empty history
      Given a scoped resource and incident observation window
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "window": {
            "start": "2026-11-02T23:00:00Z",
            "end": "2026-11-03T01:00:00Z"
          }
        }
        """
      And the pinned acceptance arrangement for aws-change-gap is established
      When AWS change evidence is correlated without assuming causation
      Then a bounded change-evidence finding or an explicit evidence gap is available
        | operation | path | equals |
        | sfx-aws-correlate-change-evidence.correlate | $.status | NOT_OBSERVABLE |
        | sfx-aws-correlate-change-evidence.correlate | $.reason | CHANGE_SOURCE_UNAVAILABLE |

    # Fixture: fixtures/cases/aws-change-90d.json (sha256:8e22b0638a138806f1ed5b6d8b0029b86b090be75c1e940751d76d544e38ba6c).
    # AWS: Event history keeps the past 90 days only (AWS-CT-01).
    @case:aws-change-90d
    @status:not-built
    Scenario: Event History beyond its 90-day window is not claimed as covered
      Given a scoped resource and incident observation window
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "window": {
            "start": "2026-01-01T00:00:00Z",
            "end": "2026-01-02T00:00:00Z"
          },
          "sourceMode": "event-history"
        }
        """
      And the pinned acceptance arrangement for aws-change-90d is established
      When AWS change evidence is correlated without assuming causation
      Then a bounded change-evidence finding or an explicit evidence gap is available
        | operation | path | equals |
        | sfx-aws-correlate-change-evidence.correlate | $.status | NOT_OBSERVABLE |
        | sfx-aws-correlate-change-evidence.correlate | $.reason | SOURCE_RETENTION_WINDOW_EXCEEDED |

    # Fixture: fixtures/cases/aws-change-dataevent.json (sha256:f81e1c1ef6e30d35b4bbde72508eb845c69830041b0dd489c223b94eb25a852f).
    # AWS: Event history never holds data events (AWS-CT-01).
    # Curated: The candidate asked for S3 data events about an EC2 instance; the request now names the S3 bucket.
    @case:aws-change-dataevent
    @status:not-built
    Scenario: Management event history is not a substitute for unenabled S3 data-event logging
      Given a scoped resource and incident observation window
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:s3:::citizen-portal-uploads",
          "window": {
            "start": "2026-11-02T23:00:00Z",
            "end": "2026-11-03T01:00:00Z"
          },
          "eventClass": "data"
        }
        """
      And the pinned acceptance arrangement for aws-change-dataevent is established
      When AWS change evidence is correlated without assuming causation
      Then a bounded change-evidence finding or an explicit evidence gap is available
        | operation | path | equals |
        | sfx-aws-correlate-change-evidence.correlate | $.status | NOT_OBSERVABLE |
        | sfx-aws-correlate-change-evidence.correlate | $.reason | DATA_EVENT_COVERAGE_UNAVAILABLE |

    # Fixture: fixtures/cases/aws-change-no-access.json (sha256:b5a1f9c55e8bc07cb7c925b56095a458f5425368c8397088b0625ef986110a8a).
    # AWS: A caller without cloudtrail:LookupEvents gets AccessDeniedException.
    @case:aws-change-no-access
    @status:not-built
    Scenario: CloudTrail denial does not fall back to an anonymous query
      Given a scoped resource and incident observation window
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "window": {
            "start": "2026-11-02T23:00:00Z",
            "end": "2026-11-03T01:00:00Z"
          }
        }
        """
      And the pinned acceptance arrangement for aws-change-no-access is established
      When AWS change evidence is correlated without assuming causation
      Then a bounded change-evidence finding or an explicit evidence gap is available
        | operation | path | equals |
        | sfx-aws-correlate-change-evidence.correlate | $.status | REFUSED |
        | sfx-aws-correlate-change-evidence.correlate | $.reason | SOURCE_ACCESS_DENIED |
