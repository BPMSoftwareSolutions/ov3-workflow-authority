# sfx-aws-correlate-change-evidence: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): CORRELATED, UNCORRELATED, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CT-01.
# Pinned review decision: D01. Priority: P0.

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

    # Sources: AWS-CT-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-change-stop.json (sha256:56704fb1bd4645a31bf74416134909803b02b204e277e484b5b8b9ae0e273b1c).
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
        | sfx-aws-correlate-change-evidence.correlate | $.changes[0].resourceArn | arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0 |
        | sfx-aws-correlate-change-evidence.correlate | $.causationProven | false |

    # Sources: AWS-CT-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-change-none.json (sha256:8bf8f648492407279fec0e285a5dd370eed4539437c8fd4d07d73677980eb35f).
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

    # Sources: AWS-CT-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-change-gap.json (sha256:c21705b2b196f49aec78408fa5295c567eaaebc429fc648633c99d522b62154e).
    @case:aws-change-gap
    @status:not-built
    Scenario: A missing CloudTrail source is a visibility gap
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
        | sfx-aws-correlate-change-evidence.correlate | $.reason | TRAIL_QUERY_UNAVAILABLE |

    # Sources: AWS-CT-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-change-90d.json (sha256:5876afbc9be25d7c6eb71ca4c8d3d5246500c0b23a201008ac8a7b71cff7262f).
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

    # Sources: AWS-CT-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-change-dataevent.json (sha256:f8b9339093bfdf90c665470b16b27d547834b79d3a66bcb4c7967155f2a4278e).
    @case:aws-change-dataevent
    @status:not-built
    Scenario: Management event history is not a substitute for unenabled S3 data-event logging
      Given a scoped resource and incident observation window
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "eventClass": "s3-object-data-event"
        }
        """
      And the pinned acceptance arrangement for aws-change-dataevent is established
      When AWS change evidence is correlated without assuming causation
      Then a bounded change-evidence finding or an explicit evidence gap is available
        | operation | path | equals |
        | sfx-aws-correlate-change-evidence.correlate | $.status | NOT_OBSERVABLE |
        | sfx-aws-correlate-change-evidence.correlate | $.reason | DATA_EVENT_COVERAGE_UNAVAILABLE |

    # Sources: AWS-CT-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-change-outofscope.json (sha256:963ace786ac60c20e1b2653cabdb837a6f2e7dc4f64330ac960e486d435f8906).
    @case:aws-change-outofscope
    @status:not-built
    Scenario: A change from another account is not attributed to this resource
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
      And the pinned acceptance arrangement for aws-change-outofscope is established
      When AWS change evidence is correlated without assuming causation
      Then a bounded change-evidence finding or an explicit evidence gap is available
        | operation | path | equals |
        | sfx-aws-correlate-change-evidence.correlate | $.status | UNCORRELATED |
        | sfx-aws-correlate-change-evidence.correlate | $.changes | [] |

    # Sources: AWS-CT-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-change-no-access.json (sha256:45afa2c35e614ba83df665d3dc1de661c239f2a071242b3da84ee6fdb8f2fa3f).
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

