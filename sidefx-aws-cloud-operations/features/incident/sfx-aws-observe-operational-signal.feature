# sfx-aws-observe-operational-signal: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): OBSERVED, DUPLICATE, REFUSED, NOT_OBSERVABLE.
# Source reference IDs: AWS-CW-01, AWS-EVB-01, AWS-SEC-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-observe-operational-signal
@root-scenario:sfx-aws-observe-operational-signal
@scenario:sfx-aws-observe-operational-signal
@input:sfx-aws-observe-operational-signal-request
@input-contract:sfx-aws-observe-operational-signal-request.v1
@event:sfx-aws-observe-operational-signal-requested
@event-authority:sfx-aws-observe-operational-signal.v1
@outcome:sfx-aws-observe-operational-signal-outcome
@outcome-contract:sfx-aws-observe-operational-signal-result.v1
@outcome-terminal
Feature: Observe a cloud operational signal
  As a cloud operations team
  I want one bounded operational condition from an authenticated source
  So that investigation begins with a traceable observation rather than an unverified alert

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-signal-alarm.json (sha256:d05d192f54fde9076c4959001bd455218c99e9c2c503a46eeb853302a796dbbf).
    @case:aws-signal-alarm
    @status:not-built
    Scenario: A production CloudWatch ALARM is admitted once
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "id": "evt-001",
            "source": "aws.cloudwatch",
            "detail-type": "CloudWatch Alarm State Change",
            "account": "111122223333",
            "region": "us-east-2",
            "resources": [
              "arn:aws:cloudwatch:us-east-2:111122223333:alarm:citizen-portal-heartbeat-low"
            ],
            "detail": {
              "alarmName": "citizen-portal-heartbeat-low",
              "state": {
                "value": "ALARM"
              }
            }
          }
        }
        """
      And the pinned acceptance arrangement for aws-signal-alarm is established
      When the operational event is checked and admitted
      Then a distinct qualified signal is observable, or the event is safely classified
        | operation | path | equals |
        | sfx-aws-observe-operational-signal.observe | $.status | OBSERVED |
        | sfx-aws-observe-operational-signal.observe | $.signal.source | aws.cloudwatch |
        | sfx-aws-observe-operational-signal.observe | $.signal.qualified | true |
        | sfx-aws-observe-operational-signal.observe | $.signal.occurrenceId | evt-001 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-signal-repeat.json (sha256:f0d0d4a9c4bca5ed470bb6130f2797f80ef0f9a59d21edb42e29f9b552717cd3).
    @case:aws-signal-repeat
    @status:not-built
    Scenario: The same event is not counted twice
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "id": "evt-001",
            "source": "aws.cloudwatch",
            "detail-type": "CloudWatch Alarm State Change",
            "account": "111122223333",
            "region": "us-east-2",
            "resources": [
              "arn:aws:cloudwatch:us-east-2:111122223333:alarm:citizen-portal-heartbeat-low"
            ],
            "detail": {
              "state": {
                "value": "ALARM"
              }
            }
          }
        }
        """
      And the pinned acceptance arrangement for aws-signal-repeat is established
      When the operational event is checked and admitted
      Then a distinct qualified signal is observable, or the event is safely classified
        | operation | path | equals |
        | sfx-aws-observe-operational-signal.observe | $.status | DUPLICATE |
        | sfx-aws-observe-operational-signal.observe | $.newOperationalSignal | false |
        | sfx-aws-observe-operational-signal.observe | $.signal.occurrenceId | evt-001 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-signal-ok.json (sha256:b8e03994929d3e232f3f2df210c09d9a3235d0e1ded05a51214ec1ac1e5b3248).
    @case:aws-signal-ok
    @status:not-built
    Scenario: A distinct OK transition is retained as a new signal
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "id": "evt-002",
            "source": "aws.cloudwatch",
            "detail-type": "CloudWatch Alarm State Change",
            "account": "111122223333",
            "region": "us-east-2",
            "resources": [
              "arn:aws:cloudwatch:us-east-2:111122223333:alarm:citizen-portal-heartbeat-low"
            ],
            "detail": {
              "state": {
                "value": "OK"
              }
            }
          }
        }
        """
      And the pinned acceptance arrangement for aws-signal-ok is established
      When the operational event is checked and admitted
      Then a distinct qualified signal is observable, or the event is safely classified
        | operation | path | equals |
        | sfx-aws-observe-operational-signal.observe | $.status | OBSERVED |
        | sfx-aws-observe-operational-signal.observe | $.signal.state | OK |
        | sfx-aws-observe-operational-signal.observe | $.signal.occurrenceId | evt-002 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-signal-forged.json (sha256:e8649ee83d80c15a54fbbfa8c7a28546446e6531406e44afbfa194e244f4455e).
    @case:aws-signal-forged
    @status:not-built
    Scenario: An unauthenticated caller cannot assert a trusted AWS event
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "id": "evt-003",
            "source": "aws.cloudwatch",
            "detail-type": "CloudWatch Alarm State Change"
          }
        }
        """
      And the pinned acceptance arrangement for aws-signal-forged is established
      When the operational event is checked and admitted
      Then a distinct qualified signal is observable, or the event is safely classified
        | operation | path | equals |
        | sfx-aws-observe-operational-signal.observe | $.status | REFUSED |
        | sfx-aws-observe-operational-signal.observe | $.reason | UNTRUSTED_SOURCE |
        | sfx-aws-observe-operational-signal.observe | $.newOperationalSignal | false |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-signal-other-account.json (sha256:d9a2238c9ee9253967b4fab7ee84d249f5f4e9485f4ee2480880aa6ccdcb1da7).
    @case:aws-signal-other-account
    @status:not-built
    Scenario: An out-of-scope account does not become an incident
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "id": "evt-004",
            "source": "aws.cloudwatch",
            "detail-type": "CloudWatch Alarm State Change",
            "account": "999988887777",
            "region": "us-east-2"
          }
        }
        """
      And the pinned acceptance arrangement for aws-signal-other-account is established
      When the operational event is checked and admitted
      Then a distinct qualified signal is observable, or the event is safely classified
        | operation | path | equals |
        | sfx-aws-observe-operational-signal.observe | $.status | REFUSED |
        | sfx-aws-observe-operational-signal.observe | $.reason | ACCOUNT_NOT_ADMITTED |
        | sfx-aws-observe-operational-signal.observe | $.newOperationalSignal | false |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-signal-malformed.json (sha256:c63a710c77c02590f0db22b71b42643ad4c2cd72765e6b22dd9a15b1e7837db3).
    @case:aws-signal-malformed
    @status:not-built
    Scenario: An event with no stable identity cannot be deduplicated safely
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "source": "aws.cloudwatch",
            "detail-type": "CloudWatch Alarm State Change",
            "account": "111122223333"
          }
        }
        """
      And the pinned acceptance arrangement for aws-signal-malformed is established
      When the operational event is checked and admitted
      Then a distinct qualified signal is observable, or the event is safely classified
        | operation | path | equals |
        | sfx-aws-observe-operational-signal.observe | $.status | REFUSED |
        | sfx-aws-observe-operational-signal.observe | $.reason | EVENT_IDENTITY_MISSING |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-signal-ingest-gap.json (sha256:95faf7053ac45f439c584485b9c641933e8424825849deec1d2d4675570564b5).
    @case:aws-signal-ingest-gap
    @status:not-built
    Scenario: A source outage is not misrepresented as a healthy estate
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "id": "evt-005",
            "source": "aws.cloudwatch",
            "detail-type": "CloudWatch Alarm State Change"
          }
        }
        """
      And the pinned acceptance arrangement for aws-signal-ingest-gap is established
      When the operational event is checked and admitted
      Then a distinct qualified signal is observable, or the event is safely classified
        | operation | path | equals |
        | sfx-aws-observe-operational-signal.observe | $.status | NOT_OBSERVABLE |
        | sfx-aws-observe-operational-signal.observe | $.reason | SOURCE_COVERAGE_UNAVAILABLE |
        | sfx-aws-observe-operational-signal.observe | $.signal | (absent) |

