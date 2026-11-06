# sfx-aws-observe-operational-signal: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: none: EventBridge delivers the event to the SideFX intake through an API destination.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): OBSERVED, DUPLICATE, REFUSED, NOT_OBSERVABLE.
# Source reference IDs: AWS-CW-01, AWS-EVB-01, AWS-EVB-02, AWS-EVB-03.
# Priority: P0.

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

    # Fixture: fixtures/cases/aws-signal-alarm.json (sha256:d360aab6b0c52cc59c2b39a8f67c9fd37efc68545cbc034c28370047a7e2366b).
    # AWS: EventBridge delivers the documented Alarm State Change envelope with a UUID event id (AWS-CW-01).
    # Curated: Event ids are UUIDs and the request is the full documented envelope; trust comes from the API destination connection credential (AWS-EVB-03).
    @case:aws-signal-alarm
    @status:not-built
    Scenario: A production CloudWatch ALARM is admitted once
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "version": "0",
            "id": "12a4289a-5bb1-4ebf-a556-63e18ae438e9",
            "detail-type": "CloudWatch Alarm State Change",
            "source": "aws.cloudwatch",
            "account": "111122223333",
            "time": "2026-11-02T23:57:00Z",
            "region": "us-east-2",
            "resources": [
              "arn:aws:cloudwatch:us-east-2:111122223333:alarm:citizen-portal-heartbeat-low"
            ],
            "detail": {
              "alarmName": "citizen-portal-heartbeat-low",
              "configuration": {
                "description": "Heartbeat success below objective for citizen-portal",
                "metrics": [
                  {
                    "id": "m1",
                    "metricStat": {
                      "metric": {
                        "namespace": "CitizenPortal",
                        "name": "HeartbeatSuccess",
                        "dimensions": {
                          "ServiceId": "citizen-portal"
                        }
                      },
                      "period": 60,
                      "stat": "Average"
                    },
                    "returnData": true
                  }
                ]
              },
              "previousState": {
                "value": "OK",
                "reason": "Unchecked: state before 2026-11-02T23:57:00Z",
                "timestamp": "2026-11-02T23:52:00.000+0000"
              },
              "state": {
                "value": "ALARM",
                "reason": "Threshold Crossed: 5 out of the last 5 datapoints were less than the threshold (0.99).",
                "timestamp": "2026-11-02T23:57:00.000+0000"
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
        | sfx-aws-observe-operational-signal.observe | $.signal.occurrenceId | 12a4289a-5bb1-4ebf-a556-63e18ae438e9 |
        | sfx-aws-observe-operational-signal.observe | $.signal.state | ALARM |
        | sfx-aws-observe-operational-signal.observe | $.signal.alarmName | citizen-portal-heartbeat-low |

    # Fixture: fixtures/cases/aws-signal-repeat.json (sha256:0f6795e3899dc58c711886402266ce85d37099bc2f4719c99fef780cdcbd892a).
    # AWS: A retried delivery repeats the identical event: EventBridge retries for up to 24 hours and 185 attempts (AWS-EVB-01).
    # Curated: The redelivery is the identical envelope, as a retry sends it.
    @case:aws-signal-repeat
    @status:not-built
    Scenario: The same event is not counted twice
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "version": "0",
            "id": "12a4289a-5bb1-4ebf-a556-63e18ae438e9",
            "detail-type": "CloudWatch Alarm State Change",
            "source": "aws.cloudwatch",
            "account": "111122223333",
            "time": "2026-11-02T23:57:00Z",
            "region": "us-east-2",
            "resources": [
              "arn:aws:cloudwatch:us-east-2:111122223333:alarm:citizen-portal-heartbeat-low"
            ],
            "detail": {
              "alarmName": "citizen-portal-heartbeat-low",
              "configuration": {
                "description": "Heartbeat success below objective for citizen-portal",
                "metrics": [
                  {
                    "id": "m1",
                    "metricStat": {
                      "metric": {
                        "namespace": "CitizenPortal",
                        "name": "HeartbeatSuccess",
                        "dimensions": {
                          "ServiceId": "citizen-portal"
                        }
                      },
                      "period": 60,
                      "stat": "Average"
                    },
                    "returnData": true
                  }
                ]
              },
              "previousState": {
                "value": "OK",
                "reason": "Unchecked: state before 2026-11-02T23:57:00Z",
                "timestamp": "2026-11-02T23:52:00.000+0000"
              },
              "state": {
                "value": "ALARM",
                "reason": "Threshold Crossed: 5 out of the last 5 datapoints were less than the threshold (0.99).",
                "timestamp": "2026-11-02T23:57:00.000+0000"
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
        | sfx-aws-observe-operational-signal.observe | $.signal.occurrenceId | 12a4289a-5bb1-4ebf-a556-63e18ae438e9 |

    # Fixture: fixtures/cases/aws-signal-ok.json (sha256:9dd20b4c18fae095111f7522ba3ab1aa00d1a30f440efcdc5c1bea6ac6712eba).
    # AWS: Each state change is its own event with its own id (AWS-CW-01).
    @case:aws-signal-ok
    @status:not-built
    Scenario: A distinct OK transition is retained as a new signal
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "version": "0",
            "id": "ce60e11f-332c-4d1f-b04d-0cc195a8085e",
            "detail-type": "CloudWatch Alarm State Change",
            "source": "aws.cloudwatch",
            "account": "111122223333",
            "time": "2026-11-03T00:15:00Z",
            "region": "us-east-2",
            "resources": [
              "arn:aws:cloudwatch:us-east-2:111122223333:alarm:citizen-portal-heartbeat-low"
            ],
            "detail": {
              "alarmName": "citizen-portal-heartbeat-low",
              "configuration": {
                "description": "Heartbeat success below objective for citizen-portal",
                "metrics": [
                  {
                    "id": "m1",
                    "metricStat": {
                      "metric": {
                        "namespace": "CitizenPortal",
                        "name": "HeartbeatSuccess",
                        "dimensions": {
                          "ServiceId": "citizen-portal"
                        }
                      },
                      "period": 60,
                      "stat": "Average"
                    },
                    "returnData": true
                  }
                ]
              },
              "previousState": {
                "value": "ALARM",
                "reason": "Unchecked: state before 2026-11-03T00:15:00Z",
                "timestamp": "2026-11-03T00:10:00.000+0000"
              },
              "state": {
                "value": "OK",
                "reason": "Threshold Crossed: 5 out of the last 5 datapoints were not less than the threshold (0.99).",
                "timestamp": "2026-11-03T00:15:00.000+0000"
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
        | sfx-aws-observe-operational-signal.observe | $.signal.occurrenceId | ce60e11f-332c-4d1f-b04d-0cc195a8085e |

    # Fixture: fixtures/cases/aws-signal-forged.json (sha256:ca2909c76a4e10459a657651b1cb4afd688660184bacd701530fb164130858de).
    # AWS: Only the API destination's connection carries the credential SideFX verifies (AWS-EVB-03); the body's source field proves nothing.
    # Curated: The forged body is now a complete, plausible envelope, so only the missing connection credential refuses it.
    @case:aws-signal-forged
    @status:not-built
    Scenario: An unauthenticated caller cannot assert a trusted AWS event
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "version": "0",
            "id": "55d5403b-8786-498b-9524-6a8fbd47866a",
            "detail-type": "CloudWatch Alarm State Change",
            "source": "aws.cloudwatch",
            "account": "111122223333",
            "time": "2026-11-03T00:05:00Z",
            "region": "us-east-2",
            "resources": [
              "arn:aws:cloudwatch:us-east-2:111122223333:alarm:citizen-portal-heartbeat-low"
            ],
            "detail": {
              "alarmName": "citizen-portal-heartbeat-low",
              "configuration": {
                "description": "Heartbeat success below objective for citizen-portal",
                "metrics": [
                  {
                    "id": "m1",
                    "metricStat": {
                      "metric": {
                        "namespace": "CitizenPortal",
                        "name": "HeartbeatSuccess",
                        "dimensions": {
                          "ServiceId": "citizen-portal"
                        }
                      },
                      "period": 60,
                      "stat": "Average"
                    },
                    "returnData": true
                  }
                ]
              },
              "previousState": {
                "value": "OK",
                "reason": "Unchecked: state before 2026-11-03T00:05:00Z",
                "timestamp": "2026-11-03T00:00:00.000+0000"
              },
              "state": {
                "value": "ALARM",
                "reason": "Threshold Crossed: 5 out of the last 5 datapoints were less than the threshold (0.99).",
                "timestamp": "2026-11-03T00:05:00.000+0000"
              }
            }
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

    # Fixture: fixtures/cases/aws-signal-other-account.json (sha256:9edcf25d2d8e49db1f62fd232c60bf097224ce96b85a8858fd9828c4b990702e).
    # AWS: The envelope's account field names the account the alarm belongs to (AWS-CW-01).
    @case:aws-signal-other-account
    @status:not-built
    Scenario: An out-of-scope account does not become an incident
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "version": "0",
            "id": "5c155599-26f3-4871-97b1-3259d35cc93f",
            "detail-type": "CloudWatch Alarm State Change",
            "source": "aws.cloudwatch",
            "account": "999988887777",
            "time": "2026-11-03T00:06:00Z",
            "region": "us-east-2",
            "resources": [
              "arn:aws:cloudwatch:us-east-2:999988887777:alarm:citizen-portal-heartbeat-low"
            ],
            "detail": {
              "alarmName": "citizen-portal-heartbeat-low",
              "configuration": {
                "description": "Heartbeat success below objective for citizen-portal",
                "metrics": [
                  {
                    "id": "m1",
                    "metricStat": {
                      "metric": {
                        "namespace": "CitizenPortal",
                        "name": "HeartbeatSuccess",
                        "dimensions": {
                          "ServiceId": "citizen-portal"
                        }
                      },
                      "period": 60,
                      "stat": "Average"
                    },
                    "returnData": true
                  }
                ]
              },
              "previousState": {
                "value": "OK",
                "reason": "Unchecked: state before 2026-11-03T00:06:00Z",
                "timestamp": "2026-11-03T00:01:00.000+0000"
              },
              "state": {
                "value": "ALARM",
                "reason": "Threshold Crossed: 5 out of the last 5 datapoints were less than the threshold (0.99).",
                "timestamp": "2026-11-03T00:06:00.000+0000"
              }
            }
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

    # Fixture: fixtures/cases/aws-signal-malformed.json (sha256:b3741c3bae19611a9cfb06778d3bb4ef0f89e7f26856ee644eb1a0fc12bb9440).
    # AWS: Every EventBridge event carries an id (AWS-CW-01); a body without one did not come from EventBridge intact.
    @case:aws-signal-malformed
    @status:not-built
    Scenario: An event with no stable identity cannot be deduplicated safely
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "version": "0",
            "detail-type": "CloudWatch Alarm State Change",
            "source": "aws.cloudwatch",
            "account": "111122223333",
            "time": "2026-11-03T00:07:00Z",
            "region": "us-east-2",
            "resources": [
              "arn:aws:cloudwatch:us-east-2:111122223333:alarm:citizen-portal-heartbeat-low"
            ],
            "detail": {
              "alarmName": "citizen-portal-heartbeat-low",
              "configuration": {
                "description": "Heartbeat success below objective for citizen-portal",
                "metrics": [
                  {
                    "id": "m1",
                    "metricStat": {
                      "metric": {
                        "namespace": "CitizenPortal",
                        "name": "HeartbeatSuccess",
                        "dimensions": {
                          "ServiceId": "citizen-portal"
                        }
                      },
                      "period": 60,
                      "stat": "Average"
                    },
                    "returnData": true
                  }
                ]
              },
              "previousState": {
                "value": "OK",
                "reason": "Unchecked: state before 2026-11-03T00:07:00Z",
                "timestamp": "2026-11-03T00:02:00.000+0000"
              },
              "state": {
                "value": "ALARM",
                "reason": "Threshold Crossed: 5 out of the last 5 datapoints were less than the threshold (0.99).",
                "timestamp": "2026-11-03T00:07:00.000+0000"
              }
            }
          }
        }
        """
      And the pinned acceptance arrangement for aws-signal-malformed is established
      When the operational event is checked and admitted
      Then a distinct qualified signal is observable, or the event is safely classified
        | operation | path | equals |
        | sfx-aws-observe-operational-signal.observe | $.status | REFUSED |
        | sfx-aws-observe-operational-signal.observe | $.reason | EVENT_IDENTITY_MISSING |

    # Fixture: fixtures/cases/aws-signal-ingest-gap.json (sha256:8f13389f5395ac8766f0a3f1425ad1ceef7b82be7e10acc25b3d7a1de7683d62).
    # AWS: INSUFFICIENT_DATA is the documented state for an alarm without enough data to evaluate (AWS-CW-01).
    # Curated: The candidate's opaque 'source_unavailable' observation is replaced by the documented state that reports missing data.
    @case:aws-signal-ingest-gap
    @status:not-built
    Scenario: An INSUFFICIENT_DATA transition is a coverage gap, not a healthy estate
      Given an AWS operational event and its attributed delivery context
        """json
        {
          "event": {
            "version": "0",
            "id": "b93734ec-9960-4745-a952-a120cf30221e",
            "detail-type": "CloudWatch Alarm State Change",
            "source": "aws.cloudwatch",
            "account": "111122223333",
            "time": "2026-11-03T00:10:00Z",
            "region": "us-east-2",
            "resources": [
              "arn:aws:cloudwatch:us-east-2:111122223333:alarm:citizen-portal-heartbeat-low"
            ],
            "detail": {
              "alarmName": "citizen-portal-heartbeat-low",
              "configuration": {
                "description": "Heartbeat success below objective for citizen-portal",
                "metrics": [
                  {
                    "id": "m1",
                    "metricStat": {
                      "metric": {
                        "namespace": "CitizenPortal",
                        "name": "HeartbeatSuccess",
                        "dimensions": {
                          "ServiceId": "citizen-portal"
                        }
                      },
                      "period": 60,
                      "stat": "Average"
                    },
                    "returnData": true
                  }
                ]
              },
              "previousState": {
                "value": "OK",
                "reason": "Unchecked: state before 2026-11-03T00:10:00Z",
                "timestamp": "2026-11-03T00:05:00.000+0000"
              },
              "state": {
                "value": "INSUFFICIENT_DATA",
                "reason": "Insufficient Data: 5 datapoints were unknown.",
                "timestamp": "2026-11-03T00:10:00.000+0000"
              }
            }
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
