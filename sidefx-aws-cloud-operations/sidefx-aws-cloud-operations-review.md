# SideFX Cloud Operations — canonical feature review

Status: authored candidates, NOT declared/bound/estate-conformant/runtime accepted. All cases synthetic and `@status:not-built`.

**14 capability features · 91 acceptance cases · 242 assertions**

## Index

- `sfx-aws-observe-operational-signal` (P0, 7 cases) — `features/incident/sfx-aws-observe-operational-signal.feature`
- `sfx-aws-resolve-resource-context` (P0, 7 cases) — `features/incident/sfx-aws-resolve-resource-context.feature`
- `sfx-aws-correlate-change-evidence` (P0, 7 cases) — `features/incident/sfx-aws-correlate-change-evidence.feature`
- `sfx-aws-resolve-service-impact` (P0, 6 cases) — `features/incident/sfx-aws-resolve-service-impact.feature`
- `sfx-aws-select-recovery-option` (P0, 6 cases) — `features/incident/sfx-aws-select-recovery-option.feature`
- `sfx-aws-authorize-remediation` (P0, 7 cases) — `features/incident/sfx-aws-authorize-remediation.feature`
- `sfx-aws-dispatch-approved-automation` (P0, 6 cases) — `features/incident/sfx-aws-dispatch-approved-automation.feature`
- `sfx-aws-verify-service-recovery` (P0, 7 cases) — `features/incident/sfx-aws-verify-service-recovery.feature`
- `sfx-aws-resolve-service-incident` (P0, 8 cases) — `features/incident/sfx-aws-resolve-service-incident.feature`
- `sfx-aws-assess-configuration-drift` (P1, 6 cases) — `features/assurance/sfx-aws-assess-configuration-drift.feature`
- `sfx-aws-triage-security-finding` (P1, 6 cases) — `features/assurance/sfx-aws-triage-security-finding.feature`
- `sfx-aws-assess-cost-variance` (P1, 6 cases) — `features/assurance/sfx-aws-assess-cost-variance.feature`
- `sfx-aws-evaluate-recovery-readiness` (P1, 6 cases) — `features/assurance/sfx-aws-evaluate-recovery-readiness.feature`
- `sfx-aws-report-operating-posture` (P1, 6 cases) — `features/assurance/sfx-aws-report-operating-posture.feature`

---

## sfx-aws-observe-operational-signal

```gherkin
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
```

---

## sfx-aws-resolve-resource-context

```gherkin
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
```

---

## sfx-aws-correlate-change-evidence

```gherkin
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
```

---

## sfx-aws-resolve-service-impact

```gherkin
# sfx-aws-resolve-service-impact: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): ASSESSED, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CW-01, AWS-SLO-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-resolve-service-impact
@root-scenario:sfx-aws-resolve-service-impact
@scenario:sfx-aws-resolve-service-impact
@input:sfx-aws-resolve-service-impact-request
@input-contract:sfx-aws-resolve-service-impact-request.v1
@event:sfx-aws-resolve-service-impact-requested
@event-authority:sfx-aws-resolve-service-impact.v1
@outcome:sfx-aws-resolve-service-impact-outcome
@outcome-contract:sfx-aws-resolve-service-impact-result.v1
@outcome-terminal
Feature: Assess operational service impact
  As a cloud operations manager
  I want an attributable view of service degradation and its coverage
  So that incident priority reflects service effect rather than alarm count

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-degraded.json (sha256:d009c0499a0aa122043dadff856f5b5160a998e0f10d8de7e92459a4ccc8d694).
    @case:aws-impact-degraded
    @status:not-built
    Scenario: A breached health target establishes degraded observed service state
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-impact-degraded is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | ASSESSED |
        | sfx-aws-resolve-service-impact.assess | $.impact.serviceState | DEGRADED |
        | sfx-aws-resolve-service-impact.assess | $.impact.serviceId | citizen-portal |
        | sfx-aws-resolve-service-impact.assess | $.impact.targetBreached | true |

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-normal.json (sha256:effc86614afa91743cee168730c25666cf7f964f0d5d7ad1399a59726a9f304d).
    @case:aws-impact-normal
    @status:not-built
    Scenario: A healthy metric does not fabricate an incident
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-002"
        }
        """
      And the pinned acceptance arrangement for aws-impact-normal is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | ASSESSED |
        | sfx-aws-resolve-service-impact.assess | $.impact.serviceState | HEALTHY |
        | sfx-aws-resolve-service-impact.assess | $.impact.targetBreached | false |

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-insufficient.json (sha256:47414152d3e85a3120803f6567a511f082552104fa06187c042652f60a51a450).
    @case:aws-impact-insufficient
    @status:not-built
    Scenario: INSUFFICIENT_DATA is not the same as HEALTHY
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-003"
        }
        """
      And the pinned acceptance arrangement for aws-impact-insufficient is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-resolve-service-impact.assess | $.reason | RELIABILITY_DATA_INSUFFICIENT |

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-unknown-slo.json (sha256:11b630bbf11ad0035ea6eec607016646eb5500421b01ff6001d93ae6e78af882).
    @case:aws-impact-unknown-slo
    @status:not-built
    Scenario: No configured service objective means no invented priority
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-impact-unknown-slo is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-resolve-service-impact.assess | $.reason | SERVICE_OBJECTIVE_UNDECLARED |

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-service-mismatch.json (sha256:6bdd6066f571271c823bc9a68772d5dc5802f396ab7a88ae938df9d5581f2e96).
    @case:aws-impact-service-mismatch
    @status:not-built
    Scenario: A foreign service metric is not joined to the incident
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-impact-service-mismatch is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | REFUSED |
        | sfx-aws-resolve-service-impact.assess | $.reason | SERVICE_METRIC_SCOPE_MISMATCH |

    # Sources: AWS-CW-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-impact-lag.json (sha256:e6036af507ad5eb43f870f40b68ae98e67d145e8cc8b9a7ed0893d18b40ffd66).
    @case:aws-impact-lag
    @status:not-built
    Scenario: Stale metrics are not presented as fresh operational state
      Given a qualified signal, service binding and reliability evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-impact-lag is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-resolve-service-impact.assess | $.reason | METRIC_WINDOW_STALE |
```

---

## sfx-aws-select-recovery-option

```gherkin
# sfx-aws-select-recovery-option: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): SELECTED, NO_ACTION, REFUSED.
# Source reference IDs: AWS-SSM-01, AWS-IAM-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-select-recovery-option
@root-scenario:sfx-aws-select-recovery-option
@scenario:sfx-aws-select-recovery-option
@input:sfx-aws-select-recovery-option-request
@input-contract:sfx-aws-select-recovery-option-request.v1
@event:sfx-aws-select-recovery-option-requested
@event-authority:sfx-aws-select-recovery-option.v1
@outcome:sfx-aws-select-recovery-option-outcome
@outcome-contract:sfx-aws-select-recovery-option-result.v1
@outcome-terminal
Feature: Select a governed recovery option
  As a on-call cloud operator
  I want a permitted action matched to the observed cloud condition
  So that remediation options follow the resource state and approved runbook policy

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-stopped-ec2.json (sha256:ebe8ca7d914fa5032d4250723b7a2becf73051668e68464969366fe495b970dc).
    @case:aws-option-stopped-ec2
    @status:not-built
    Scenario: A stopped EC2 instance matches a start-with-approval option
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "stopped"
        }
        """
      And the pinned acceptance arrangement for aws-option-stopped-ec2 is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | SELECTED |
        | sfx-aws-select-recovery-option.select | $.option.documentName | AWS-StartEC2InstanceWithApproval |
        | sfx-aws-select-recovery-option.select | $.option.requiresApproval | true |

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-running.json (sha256:2d88c9bf8d334cca032770d6ee92d5e72b4286b38e679c4f93a91f752a8c5a54).
    @case:aws-option-running
    @status:not-built
    Scenario: A running EC2 instance is not started again
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "running"
        }
        """
      And the pinned acceptance arrangement for aws-option-running is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | NO_ACTION |
        | sfx-aws-select-recovery-option.select | $.reason | NO_ELIGIBLE_ACTION |

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-no-runbook.json (sha256:e7372bfbc4972d8b1dfcf58fbc28ce06b441fb21af383d3768b41b45d7b67467).
    @case:aws-option-no-runbook
    @status:not-built
    Scenario: Unknown failures do not create speculative shell commands
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "degraded-unknown"
        }
        """
      And the pinned acceptance arrangement for aws-option-no-runbook is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | NO_ACTION |
        | sfx-aws-select-recovery-option.select | $.option | (absent) |

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-unapproved.json (sha256:c805116e82207a71bd97df98b79fec4a9fd45fd51342370c7f894a8d92a73e1c).
    @case:aws-option-unapproved
    @status:not-built
    Scenario: An unapproved custom runbook is ineligible
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "stopped"
        }
        """
      And the pinned acceptance arrangement for aws-option-unapproved is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | NO_ACTION |
        | sfx-aws-select-recovery-option.select | $.reason | RUNBOOK_NOT_ADMITTED |

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-other-account.json (sha256:b95fb92bf127d04736bcfa426616c5cda9e395367e2f36c0ccc7eb6dd1f5618e).
    @case:aws-option-other-account
    @status:not-built
    Scenario: An action is not selected for an unapproved account
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": "stopped"
        }
        """
      And the pinned acceptance arrangement for aws-option-other-account is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | REFUSED |
        | sfx-aws-select-recovery-option.select | $.reason | TARGET_NOT_IN_ALLOWED_SCOPE |

    # Sources: AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-option-no-context.json (sha256:c1d85efd0b97dbf33ec8e87922c9cb96e71fc8d032175710a148af2212321f28).
    @case:aws-option-no-context
    @status:not-built
    Scenario: A missing current state cannot be interpreted as stopped
      Given an incident assessment and admitted runbook catalog
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "resourceState": null
        }
        """
      And the pinned acceptance arrangement for aws-option-no-context is established
      When one eligible bounded recovery option is selected
      Then an eligible action is available, or the incident is left for manual escalation
        | operation | path | equals |
        | sfx-aws-select-recovery-option.select | $.status | NO_ACTION |
        | sfx-aws-select-recovery-option.select | $.reason | CURRENT_STATE_NOT_OBSERVABLE |
```

---

## sfx-aws-authorize-remediation

```gherkin
# sfx-aws-authorize-remediation: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): AUTHORIZED, PENDING_APPROVAL, REFUSED.
# Source reference IDs: AWS-IAM-01, AWS-SSM-02.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-authorize-remediation
@root-scenario:sfx-aws-authorize-remediation
@scenario:sfx-aws-authorize-remediation
@input:sfx-aws-authorize-remediation-request
@input-contract:sfx-aws-authorize-remediation-request.v1
@event:sfx-aws-authorize-remediation-requested
@event-authority:sfx-aws-authorize-remediation.v1
@outcome:sfx-aws-authorize-remediation-outcome
@outcome-contract:sfx-aws-authorize-remediation-result.v1
@outcome-terminal
Feature: Authorize an operational recovery effect
  As a cloud operations manager
  I want a reviewable permission decision for a particular cloud change
  So that a model suggestion or operator click cannot bypass the admitted effect boundary

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-approved.json (sha256:c71a6349a08954cca1ce885b633e0c0c33c778fddab37965e407de4a557e54c1).
    @case:aws-auth-approved
    @status:not-built
    Scenario: A scoped, independent approval authorizes the named action
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval"
        }
        """
      And the pinned acceptance arrangement for aws-auth-approved is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | AUTHORIZED |
        | sfx-aws-authorize-remediation.authorize | $.authorizedAction | start-ec2 |
        | sfx-aws-authorize-remediation.authorize | $.target.resourceArn | arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0 |
        | sfx-aws-authorize-remediation.authorize | $.approval.id | apr-001 |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-pending.json (sha256:3aa51792125764da1a99f9f3de1fec359406952c9bec27a3706acb3e30c836f8).
    @case:aws-auth-pending
    @status:not-built
    Scenario: Approval not yet recorded leaves the effect pending
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "documentName": "AWS-StartEC2InstanceWithApproval"
        }
        """
      And the pinned acceptance arrangement for aws-auth-pending is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | PENDING_APPROVAL |
        | sfx-aws-authorize-remediation.authorize | $.writeAllowed | false |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_REQUIRED |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-denied.json (sha256:c3d08aab4dd4589c3bb6304bca8f34217cadb5a3d6bfd25f97d5a2bae985b81d).
    @case:aws-auth-denied
    @status:not-built
    Scenario: A denied approval cannot become an authorized effect
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "approvalId": "apr-002"
        }
        """
      And the pinned acceptance arrangement for aws-auth-denied is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_DENIED |
        | sfx-aws-authorize-remediation.authorize | $.writeAllowed | false |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-wrong-target.json (sha256:d7282fc2e0e7a0fa59780357534b89d4e7673f09514adcef84f978a511101280).
    @case:aws-auth-wrong-target
    @status:not-built
    Scenario: An approval for another resource does not transfer
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "approvalId": "apr-003"
        }
        """
      And the pinned acceptance arrangement for aws-auth-wrong-target is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_SCOPE_MISMATCH |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-least-privilege.json (sha256:942bddb690e48d49be2d0f9fe40b5cbb82558119c08e8bf75db315e1474981d2).
    @case:aws-auth-least-privilege
    @status:not-built
    Scenario: A read-only operator cannot authorize the write
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "approvalId": "apr-004"
        }
        """
      And the pinned acceptance arrangement for aws-auth-least-privilege is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | OPERATOR_NOT_AUTHORIZED |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-stale.json (sha256:48e06dd34f658b57dc1299fac77c33367bdd8460aab27d133cd7e20436960880).
    @case:aws-auth-stale
    @status:not-built
    Scenario: An expired approval is not silently refreshed
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "approvalId": "apr-005"
        }
        """
      And the pinned acceptance arrangement for aws-auth-stale is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | REFUSED |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_EXPIRED |

    # Sources: AWS-IAM-01, AWS-SSM-02. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-auth-proposal-only.json (sha256:99078bb0dd4db66c59752ef041eb0a39f824a54f239fa9233f80ae6be9d84e57).
    @case:aws-auth-proposal-only
    @status:not-built
    Scenario: An AI-generated plan has no inherent cloud permission
      Given a proposed recovery effect, target and trusted operator context
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "action": "start-ec2",
          "proposalId": "model-plan-001"
        }
        """
      And the pinned acceptance arrangement for aws-auth-proposal-only is established
      When the effect-specific authority and approval requirements are evaluated
      Then an authorized effect or an explicit pending or refused disposition is available
        | operation | path | equals |
        | sfx-aws-authorize-remediation.authorize | $.status | PENDING_APPROVAL |
        | sfx-aws-authorize-remediation.authorize | $.writeAllowed | false |
        | sfx-aws-authorize-remediation.authorize | $.reason | APPROVAL_REQUIRED |
```

---

## sfx-aws-dispatch-approved-automation

```gherkin
# sfx-aws-dispatch-approved-automation: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): DISPATCHED, NOT_DISPATCHED, REFUSED.
# Source reference IDs: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-dispatch-approved-automation
@root-scenario:sfx-aws-dispatch-approved-automation
@scenario:sfx-aws-dispatch-approved-automation
@input:sfx-aws-dispatch-approved-automation-request
@input-contract:sfx-aws-dispatch-approved-automation-request.v1
@event:sfx-aws-dispatch-approved-automation-requested
@event-authority:sfx-aws-dispatch-approved-automation.v1
@outcome:sfx-aws-dispatch-approved-automation-outcome
@outcome-contract:sfx-aws-dispatch-approved-automation-result.v1
@outcome-terminal
Feature: Dispatch an approved AWS Automation runbook
  As a incident responder
  I want one attributable execution of an explicitly admitted runbook
  So that recovery is delegated to an AWS native operator under precise permission and idempotency

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-start.json (sha256:ee34b260570a5aef1b7330f8f3a7951e0e5b37415d43170d3163389c72bf1c56).
    @case:aws-dispatch-start
    @status:not-built
    Scenario: An authorized runbook is started once and returns an execution ID
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "clientToken": "remedy-001"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-start is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.documentName | AWS-StartEC2InstanceWithApproval |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.executionId | ssm-execution-001 |
        | sfx-aws-dispatch-approved-automation.dispatch | $.effect.completed | false |

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-retry.json (sha256:9ef16d3db317a865b599a2a1b3f893ce81aa506c07b20293f9fedb27f84b3c0d).
    @case:aws-dispatch-retry
    @status:not-built
    Scenario: A repeated token does not create a second automation execution
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "clientToken": "remedy-001"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-retry is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.executionId | ssm-execution-001 |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.newDispatch | false |

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-no-approval.json (sha256:696bbf67436cb370af0f76b3b76a60c7173b1b2bd9c2388e3ffeb57b60860c61).
    @case:aws-dispatch-no-approval
    @status:not-built
    Scenario: Without an approved effect identity no write is dispatched
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "clientToken": "remedy-002"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-no-approval is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | NOT_DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | EFFECT_NOT_AUTHORIZED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.writeAttempted | false |

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-wrong-runbook.json (sha256:59bb6b5db76b5f75f6f868a3f40e42f2265de13599890652d11a4894854d5fc3).
    @case:aws-dispatch-wrong-runbook
    @status:not-built
    Scenario: The runbook cannot be substituted between approval and use
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StopEC2InstanceWithApproval",
          "clientToken": "remedy-003"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-wrong-runbook is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | REFUSED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | RUNBOOK_BINDING_MISMATCH |
        | sfx-aws-dispatch-approved-automation.dispatch | $.writeAttempted | false |

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-failure.json (sha256:a5a9b9b4db1e189d8b129ce182533646258b2569cdf83e4b436469fe787af283).
    @case:aws-dispatch-failure
    @status:not-built
    Scenario: An AWS API failure is reported as not dispatched
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "clientToken": "remedy-004"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-failure is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | NOT_DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | AWS_DISPATCH_FAILED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation | (absent) |

    # Sources: AWS-SSM-01, AWS-SSM-02, AWS-SEC-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dispatch-unknown.json (sha256:783b42475f29cffba96914bb014d9d777cbb4580dcfac62daae111890e258928).
    @case:aws-dispatch-unknown
    @status:not-built
    Scenario: An ambiguous timeout is reconciled before any retry write
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "clientToken": "remedy-005"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-unknown is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | NOT_DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | DISPATCH_CONFIRMATION_UNKNOWN |
        | sfx-aws-dispatch-approved-automation.dispatch | $.writeRetried | false |
```

---

## sfx-aws-verify-service-recovery

```gherkin
# sfx-aws-verify-service-recovery: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): RESTORED, NOT_RESTORED, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CW-01, AWS-SSM-01, AWS-SLO-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-verify-service-recovery
@root-scenario:sfx-aws-verify-service-recovery
@scenario:sfx-aws-verify-service-recovery
@input:sfx-aws-verify-service-recovery-request
@input-contract:sfx-aws-verify-service-recovery-request.v1
@event:sfx-aws-verify-service-recovery-requested
@event-authority:sfx-aws-verify-service-recovery.v1
@outcome:sfx-aws-verify-service-recovery-outcome
@outcome-contract:sfx-aws-verify-service-recovery-result.v1
@outcome-terminal
Feature: Verify a cloud service recovery from independent observations
  As a cloud operations manager
  I want proof that the operational experience has recovered
  So that a successful automation invocation never substitutes for a healthy service

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-restored.json (sha256:40f010808521faffefe80595a892eb4ab07eb31bf54723a1d61d805ce090388e).
    @case:aws-verify-restored
    @status:not-built
    Scenario: Successful automation plus healthy post-state confirms recovery
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-restored is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | RESTORED |
        | sfx-aws-verify-service-recovery.verify | $.serviceState | HEALTHY |
        | sfx-aws-verify-service-recovery.verify | $.evidence.automationStatus | Success |
        | sfx-aws-verify-service-recovery.verify | $.evidence.ec2State | running |
        | sfx-aws-verify-service-recovery.verify | $.verified | true |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-ssm-only.json (sha256:20884c16a8296fa0e046bc851db12a3f7921ed7fcd5a7cd0dd814cae15a5ed5c).
    @case:aws-verify-ssm-only
    @status:not-built
    Scenario: A successful runbook with no healthy service evidence is not recovery
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-ssm-only is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_OBSERVABLE |
        | sfx-aws-verify-service-recovery.verify | $.reason | POST_ACTION_HEALTH_EVIDENCE_MISSING |
        | sfx-aws-verify-service-recovery.verify | $.verified | false |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-still-bad.json (sha256:551ee0f35a19d56545d553ff440bb9bed75b4f06bd7b90d8799088a3bf74c127).
    @case:aws-verify-still-bad
    @status:not-built
    Scenario: Persistent alarm proves not restored
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-still-bad is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_RESTORED |
        | sfx-aws-verify-service-recovery.verify | $.serviceState | DEGRADED |
        | sfx-aws-verify-service-recovery.verify | $.verified | false |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-not-complete.json (sha256:831f23f8ce41ecfeb4f7aaa2c9c4bfff0e0984a8c90433afc5e7b005bfcf15a3).
    @case:aws-verify-not-complete
    @status:not-built
    Scenario: A waiting-for-approval runbook is not completed
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-not-complete is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_OBSERVABLE |
        | sfx-aws-verify-service-recovery.verify | $.reason | AUTOMATION_NOT_TERMINAL |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-wrong-service.json (sha256:28179c5c83525e43430869785df60d44241cb055515f58ef7901789e507643d9).
    @case:aws-verify-wrong-service
    @status:not-built
    Scenario: A healthy metric for another service is not success
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-wrong-service is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | REFUSED |
        | sfx-aws-verify-service-recovery.verify | $.reason | POST_ACTION_EVIDENCE_SCOPE_MISMATCH |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-failed-runbook.json (sha256:24251a4e25dde08997bbdea620cacd0b48ef842abee3002d5e1250eed66a7e1a).
    @case:aws-verify-failed-runbook
    @status:not-built
    Scenario: A failed runbook is not recovery even if some metric recovers
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-failed-runbook is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_RESTORED |
        | sfx-aws-verify-service-recovery.verify | $.evidence.automationStatus | Failed |
        | sfx-aws-verify-service-recovery.verify | $.verified | false |

    # Sources: AWS-CW-01, AWS-SSM-01, AWS-SLO-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-verify-stale.json (sha256:d7002de7b103473d1915be2e825663e341aaa242c7da6ff66cd1157f463a82dc).
    @case:aws-verify-stale
    @status:not-built
    Scenario: Old metric data is insufficient for a fresh recovery claim
      Given an automation result and a declared post-action service objective
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "automationExecutionId": "ssm-execution-001"
        }
        """
      And the pinned acceptance arrangement for aws-verify-stale is established
      When the current service state is independently checked against the objective
      Then recovery is confirmed, rejected, or left unobservable with evidence
        | operation | path | equals |
        | sfx-aws-verify-service-recovery.verify | $.status | NOT_OBSERVABLE |
        | sfx-aws-verify-service-recovery.verify | $.reason | POST_ACTION_METRICS_STALE |
```

---

## sfx-aws-resolve-service-incident

```gherkin
# sfx-aws-resolve-service-incident: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): RESTORED, ESCALATED, HELD, REFUSED.
# Source reference IDs: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01.
# Pinned review decision: D01. Priority: P0.

@capability:sfx-aws-resolve-service-incident
@root-scenario:sfx-aws-resolve-service-incident
@scenario:sfx-aws-resolve-service-incident
@input:sfx-aws-resolve-service-incident-request
@input-contract:sfx-aws-resolve-service-incident-request.v1
@event:sfx-aws-resolve-service-incident-requested
@event-authority:sfx-aws-resolve-service-incident.v1
@outcome:sfx-aws-resolve-service-incident-outcome
@outcome-contract:sfx-aws-resolve-service-incident-result.v1
@outcome-terminal
Feature: Resolve a cloud service incident through governed AWS capabilities
  As a cloud operations manager
  I want a service incident either recovered with proof or safely escalated
  So that every action, constraint and unresolved condition is visible in one incident circuit

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-end-to-end.json (sha256:61d6f90dc9c38cec83e063cebd0e0ea83da6790d6f663dee4a0e8d1d40cf024f).
    @case:aws-incident-end-to-end
    @status:not-built
    Scenario: A stopped instance is restarted after approval and proven healthy
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-001",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-end-to-end is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | RESTORED |
        | sfx-aws-resolve-service-incident.resolve | $.incidentId | inc-001 |
        | sfx-aws-resolve-service-incident.resolve | $.serviceState | HEALTHY |
        | sfx-aws-resolve-service-incident.resolve | $.evidence.recoveryVerified | true |
        | sfx-aws-resolve-service-incident.resolve | $.evidence.automationExecutionId | ssm-execution-001 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-denied.json (sha256:ffccd78dc868fae3306c7a66cba5898f38f691a6523831048c2b40a32a5baf6b).
    @case:aws-incident-denied
    @status:not-built
    Scenario: An approval denial safely escalates without running recovery
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-002",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-denied is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | ESCALATED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | REMEDIATION_NOT_APPROVED |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-no-evidence.json (sha256:2279c76aa8827dc7e648621da16385419a95c651126ee2ecd1274eedad2b1e4d).
    @case:aws-incident-no-evidence
    @status:not-built
    Scenario: A missing current-state read holds recovery and the incident remains unresolved
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-003",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-no-evidence is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | HELD |
        | sfx-aws-resolve-service-incident.resolve | $.reason | RESOURCE_CONTEXT_INCOMPLETE |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-ssm-failed.json (sha256:55edfa6fc7c73f22a6b1707bbf1ca483175e0e4a24e3d92c5318699e9a8be5e2).
    @case:aws-incident-ssm-failed
    @status:not-built
    Scenario: A failed runbook does not close the incident as restored
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-004",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-ssm-failed is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | ESCALATED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | RECOVERY_NOT_VERIFIED |
        | sfx-aws-resolve-service-incident.resolve | $.evidence.recoveryVerified | false |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-metric-gap.json (sha256:6ef882c7d3fbdc9b4d0a8418431ff076544c547e826df272a22fd2c88e8dc602).
    @case:aws-incident-metric-gap
    @status:not-built
    Scenario: Successful runbook with unavailable metrics retains a held outcome
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-005",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-metric-gap is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | HELD |
        | sfx-aws-resolve-service-incident.resolve | $.reason | RECOVERY_NOT_OBSERVABLE |
        | sfx-aws-resolve-service-incident.resolve | $.evidence.recoveryVerified | false |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-replayed.json (sha256:1f10e35134d3f10135f3f8b1db8adb70e0a89ed3e473c388e9d6d0d3f35885ee).
    @case:aws-incident-replayed
    @status:not-built
    Scenario: A replayed event cannot duplicate remediation
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-001",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-replayed is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | RESTORED |
        | sfx-aws-resolve-service-incident.resolve | $.incidentId | inc-001 |
        | sfx-aws-resolve-service-incident.resolve | $.effects.newExecutions | 0 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-foreign.json (sha256:bc95124db6232185b3993de4f0062bd2d8f1c2e66549df718739951f2cb348fd).
    @case:aws-incident-foreign
    @status:not-built
    Scenario: A foreign-account signal is rejected at intake
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-006"
        }
        """
      And the pinned acceptance arrangement for aws-incident-foreign is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | REFUSED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | ACCOUNT_NOT_ADMITTED |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |

    # Sources: AWS-CW-01, AWS-EVB-01, AWS-CONFIG-01, AWS-CT-01, AWS-SSM-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-incident-no-option.json (sha256:d214ccae2bf7411916a1a0dae11812a0b15ded589f67284f497d1495c781d7cc).
    @case:aws-incident-no-option
    @status:not-built
    Scenario: An unknown failure escalates for manual diagnosis, not an invented command
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-007",
          "signalId": "sig-001"
        }
        """
      And the pinned acceptance arrangement for aws-incident-no-option is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | ESCALATED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | NO_ADMITTED_RECOVERY_ACTION |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |
```

---

## sfx-aws-assess-configuration-drift

```gherkin
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
```

---

## sfx-aws-triage-security-finding

```gherkin
# sfx-aws-triage-security-finding: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): TRIAGED, DUPLICATE, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-SH-01, AWS-IAM-01.
# Pinned review decision: D01. Priority: P1.

@capability:sfx-aws-triage-security-finding
@root-scenario:sfx-aws-triage-security-finding
@scenario:sfx-aws-triage-security-finding
@input:sfx-aws-triage-security-finding-request
@input-contract:sfx-aws-triage-security-finding-request.v1
@event:sfx-aws-triage-security-finding-requested
@event-authority:sfx-aws-triage-security-finding.v1
@outcome:sfx-aws-triage-security-finding-outcome
@outcome-contract:sfx-aws-triage-security-finding-result.v1
@outcome-terminal
Feature: Triage an AWS security finding with attributable evidence
  As a security operations manager
  I want a prioritized cloud-security observation with safe next action
  So that findings are not mistaken for automatically authorized remediations

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-high.json (sha256:766dbdbfb7c2a6538066b1980dfe374c85b090992fac73d4f7ed42a20c3896dc).
    @case:aws-sec-high
    @status:not-built
    Scenario: A high severity finding becomes a classified security work item
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-001",
          "source": "aws.securityhub"
        }
        """
      And the pinned acceptance arrangement for aws-sec-high is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | TRIAGED |
        | sfx-aws-triage-security-finding.triage | $.workItem.findingId | finding-001 |
        | sfx-aws-triage-security-finding.triage | $.workItem.severity | HIGH |
        | sfx-aws-triage-security-finding.triage | $.automaticRemediation | false |

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-duplicate.json (sha256:3dc0386adab9a40a2a4f12152367770b273b5e14c2201f81394a8f9000ae6c46).
    @case:aws-sec-duplicate
    @status:not-built
    Scenario: A repeated finding update is not a new issue by default
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-001",
          "source": "aws.securityhub"
        }
        """
      And the pinned acceptance arrangement for aws-sec-duplicate is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | DUPLICATE |
        | sfx-aws-triage-security-finding.triage | $.newWorkItem | false |

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-cross-account.json (sha256:a49c1530ce9332edd82400cae0accfc3774866b23e39a9c1c1360e4f532368da).
    @case:aws-sec-cross-account
    @status:not-built
    Scenario: A foreign account finding cannot enter the estate
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-002",
          "source": "aws.securityhub"
        }
        """
      And the pinned acceptance arrangement for aws-sec-cross-account is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | REFUSED |
        | sfx-aws-triage-security-finding.triage | $.reason | FINDING_ACCOUNT_NOT_ADMITTED |

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-v1v2.json (sha256:6d7f9141f47aeeaeb34d9a038d23c4462d14b0e7546549e2e92ab71879bf1b61).
    @case:aws-sec-v1v2
    @status:not-built
    Scenario: Legacy and V2 event formats are not double-counted
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-003",
          "source": "aws.securityhub"
        }
        """
      And the pinned acceptance arrangement for aws-sec-v1v2 is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | DUPLICATE |
        | sfx-aws-triage-security-finding.triage | $.newWorkItem | false |

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-missing-resource.json (sha256:f9687f0239a27a9684c7a63eb6d3b6c2e6391f1f758cd7243a0005afc59f587f).
    @case:aws-sec-missing-resource
    @status:not-built
    Scenario: A finding with no attributable resource is left unobserved
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-004",
          "source": "aws.securityhub"
        }
        """
      And the pinned acceptance arrangement for aws-sec-missing-resource is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | NOT_OBSERVABLE |
        | sfx-aws-triage-security-finding.triage | $.reason | RESOURCE_BINDING_MISSING |

    # Sources: AWS-SH-01, AWS-IAM-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-sec-no-auto-write.json (sha256:81e8ef87d58724dbd48ec45c7a04cb694895a9c19353f14b83de92fb73d0d0c0).
    @case:aws-sec-no-auto-write
    @status:not-built
    Scenario: Even a critical finding cannot create a deletion without authority
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "findingId": "finding-005",
          "source": "aws.securityhub",
          "proposedAction": "delete-resource"
        }
        """
      And the pinned acceptance arrangement for aws-sec-no-auto-write is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | TRIAGED |
        | sfx-aws-triage-security-finding.triage | $.automaticRemediation | false |
        | sfx-aws-triage-security-finding.triage | $.workItem.requiresReview | true |
```

---

## sfx-aws-assess-cost-variance

```gherkin
# sfx-aws-assess-cost-variance: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): VARIANCE_OBSERVED, NO_VARIANCE, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CE-01.
# Pinned review decision: D01. Priority: P1.

@capability:sfx-aws-assess-cost-variance
@root-scenario:sfx-aws-assess-cost-variance
@scenario:sfx-aws-assess-cost-variance
@input:sfx-aws-assess-cost-variance-request
@input-contract:sfx-aws-assess-cost-variance-request.v1
@event:sfx-aws-assess-cost-variance-requested
@event-authority:sfx-aws-assess-cost-variance.v1
@outcome:sfx-aws-assess-cost-variance-outcome
@outcome-contract:sfx-aws-assess-cost-variance-result.v1
@outcome-terminal
Feature: Assess AWS spend against an admitted budget or baseline
  As a cloud financial operations owner
  I want a cost change that is measurable and attributed to a defined scope
  So that cost optimization begins from spend evidence rather than speculative savings

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-CE-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-cost-rise.json (sha256:47e4a1dc83c1ccb8345ea0d11db25576778f174971cfbde77152630b55e7ff8c).
    @case:aws-cost-rise
    @status:not-built
    Scenario: An observed monthly cost increase is attributed to the requested service
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "period": "2026-10",
          "baselinePeriod": "2026-09"
        }
        """
      And the pinned acceptance arrangement for aws-cost-rise is established
      When the scoped cost evidence is compared under a declared variance rule
      Then an attributable variance or an explicit coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-cost-variance.assess | $.status | VARIANCE_OBSERVED |
        | sfx-aws-assess-cost-variance.assess | $.variance.currency | USD |
        | sfx-aws-assess-cost-variance.assess | $.variance.delta | 200.0 |
        | sfx-aws-assess-cost-variance.assess | $.variance.percent | 20.0 |

    # Sources: AWS-CE-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-cost-flat.json (sha256:1e2060ba8f5a89743056258085c8f948830df96107d2d8ac3aabfdf7f889806c).
    @case:aws-cost-flat
    @status:not-built
    Scenario: No material spend change yields no variance
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "period": "2026-10",
          "baselinePeriod": "2026-09"
        }
        """
      And the pinned acceptance arrangement for aws-cost-flat is established
      When the scoped cost evidence is compared under a declared variance rule
      Then an attributable variance or an explicit coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-cost-variance.assess | $.status | NO_VARIANCE |
        | sfx-aws-assess-cost-variance.assess | $.variance.delta | 0.0 |

    # Sources: AWS-CE-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-cost-lag.json (sha256:9263a9a517ec2dff1345d63f89f010603152e00d0b07e4c1678e3323db38a026).
    @case:aws-cost-lag
    @status:not-built
    Scenario: Incomplete recent billing data is not called a complete monthly result
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "period": "2026-11",
          "baselinePeriod": "2026-10"
        }
        """
      And the pinned acceptance arrangement for aws-cost-lag is established
      When the scoped cost evidence is compared under a declared variance rule
      Then an attributable variance or an explicit coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-cost-variance.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-assess-cost-variance.assess | $.reason | BILLING_PERIOD_INCOMPLETE |

    # Sources: AWS-CE-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-cost-cross-account.json (sha256:914855041861e10bc8cb1de5ac44739597e18cc16cfa135d380946cba6c32b38).
    @case:aws-cost-cross-account
    @status:not-built
    Scenario: A non-entitled account is not charged to the wrong team
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "period": "2026-10",
          "baselinePeriod": "2026-09"
        }
        """
      And the pinned acceptance arrangement for aws-cost-cross-account is established
      When the scoped cost evidence is compared under a declared variance rule
      Then an attributable variance or an explicit coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-cost-variance.assess | $.status | REFUSED |
        | sfx-aws-assess-cost-variance.assess | $.reason | BILLING_SCOPE_NOT_ADMITTED |

    # Sources: AWS-CE-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-cost-denied.json (sha256:a6c08a6865dc1e3e79a782073c0eeaeef98a15a2769da72ae74646c2f75bca04).
    @case:aws-cost-denied
    @status:not-built
    Scenario: Cost Explorer permission denial is an observation limitation
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "period": "2026-10",
          "baselinePeriod": "2026-09"
        }
        """
      And the pinned acceptance arrangement for aws-cost-denied is established
      When the scoped cost evidence is compared under a declared variance rule
      Then an attributable variance or an explicit coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-cost-variance.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-assess-cost-variance.assess | $.reason | COST_READ_DENIED |

    # Sources: AWS-CE-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-cost-missing-tags.json (sha256:4e99adf2f707c8bf7cd3080adf40e4f092f306d89379fc57d44f66beda1e1e33).
    @case:aws-cost-missing-tags
    @status:not-built
    Scenario: Absent cost-allocation tags prevent invented service attribution
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "period": "2026-10",
          "baselinePeriod": "2026-09"
        }
        """
      And the pinned acceptance arrangement for aws-cost-missing-tags is established
      When the scoped cost evidence is compared under a declared variance rule
      Then an attributable variance or an explicit coverage limitation is available
        | operation | path | equals |
        | sfx-aws-assess-cost-variance.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-assess-cost-variance.assess | $.reason | COST_ATTRIBUTION_MISSING |
```

---

## sfx-aws-evaluate-recovery-readiness

```gherkin
# sfx-aws-evaluate-recovery-readiness: SideFX canonical feature candidate for cloud operations, 2026-11-03.
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
# Outcome variants (proposed): READY, NOT_READY, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-BKP-01.
# Pinned review decision: D01. Priority: P1.

@capability:sfx-aws-evaluate-recovery-readiness
@root-scenario:sfx-aws-evaluate-recovery-readiness
@scenario:sfx-aws-evaluate-recovery-readiness
@input:sfx-aws-evaluate-recovery-readiness-request
@input-contract:sfx-aws-evaluate-recovery-readiness-request.v1
@event:sfx-aws-evaluate-recovery-readiness-requested
@event-authority:sfx-aws-evaluate-recovery-readiness.v1
@outcome:sfx-aws-evaluate-recovery-readiness-outcome
@outcome-contract:sfx-aws-evaluate-recovery-readiness-result.v1
@outcome-terminal
Feature: Evaluate recovery readiness for a cloud workload
  As a service continuity owner
  I want an evidence-based view of recovery preparedness
  So that a backup configured does not by itself prove recoverability

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Sources: AWS-BKP-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dr-proven.json (sha256:8408af99433313c602b49d43407a7b57061f12fe02233ee3293e2fb7e5b32e70).
    @case:aws-dr-proven
    @status:not-built
    Scenario: A fresh successful restore exercise satisfies the declared RTO and RPO
      Given a recovery obligation and its actual backup or exercise evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "workloadId": "citizen-portal",
          "objective": {
            "rtoMinutes": 60,
            "rpoMinutes": 15
          }
        }
        """
      And the pinned acceptance arrangement for aws-dr-proven is established
      When the observed recovery controls are checked against the declared recovery objective
      Then a supported readiness disposition with exact gaps is available
        | operation | path | equals |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.status | READY |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.readiness.restoreExerciseVerified | true |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.readiness.withinRto | true |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.readiness.withinRpo | true |

    # Sources: AWS-BKP-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dr-backup-only.json (sha256:a0578bd16c794f522557443122e235f95dd53523f13a64cae7ca5157b5613ac6).
    @case:aws-dr-backup-only
    @status:not-built
    Scenario: Successful backups without a restore exercise do not prove ready
      Given a recovery obligation and its actual backup or exercise evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "workloadId": "citizen-portal",
          "objective": {
            "rtoMinutes": 60,
            "rpoMinutes": 15
          }
        }
        """
      And the pinned acceptance arrangement for aws-dr-backup-only is established
      When the observed recovery controls are checked against the declared recovery objective
      Then a supported readiness disposition with exact gaps is available
        | operation | path | equals |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.status | NOT_READY |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.reason | RESTORE_EXERCISE_NOT_PROVEN |

    # Sources: AWS-BKP-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dr-rto.json (sha256:29392b99668e0773aa53d63f4ef979e0e52ac819f0ada237ee323f3df55f38d1).
    @case:aws-dr-rto
    @status:not-built
    Scenario: Measured restore time outside RTO is not ready
      Given a recovery obligation and its actual backup or exercise evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "workloadId": "citizen-portal",
          "objective": {
            "rtoMinutes": 60,
            "rpoMinutes": 15
          }
        }
        """
      And the pinned acceptance arrangement for aws-dr-rto is established
      When the observed recovery controls are checked against the declared recovery objective
      Then a supported readiness disposition with exact gaps is available
        | operation | path | equals |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.status | NOT_READY |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.readiness.withinRto | false |

    # Sources: AWS-BKP-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dr-no-objective.json (sha256:e0c791f4555cf93fc848085efd9fefc9eb95f4de06bb4a8cdc6a825146833d5c).
    @case:aws-dr-no-objective
    @status:not-built
    Scenario: No declared recovery objective means readiness cannot be judged
      Given a recovery obligation and its actual backup or exercise evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "workloadId": "citizen-portal",
          "objective": null
        }
        """
      And the pinned acceptance arrangement for aws-dr-no-objective is established
      When the observed recovery controls are checked against the declared recovery objective
      Then a supported readiness disposition with exact gaps is available
        | operation | path | equals |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.status | NOT_OBSERVABLE |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.reason | RECOVERY_OBJECTIVE_UNDECLARED |

    # Sources: AWS-BKP-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dr-stale-proof.json (sha256:a427264a5a4d14c972e8285a63a790ad796363e02fb65024683d815330a46c2b).
    @case:aws-dr-stale-proof
    @status:not-built
    Scenario: An out-of-date exercise is not current proof
      Given a recovery obligation and its actual backup or exercise evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "workloadId": "citizen-portal",
          "objective": {
            "rtoMinutes": 60,
            "rpoMinutes": 15
          }
        }
        """
      And the pinned acceptance arrangement for aws-dr-stale-proof is established
      When the observed recovery controls are checked against the declared recovery objective
      Then a supported readiness disposition with exact gaps is available
        | operation | path | equals |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.status | NOT_READY |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.reason | EXERCISE_EVIDENCE_STALE |

    # Sources: AWS-BKP-01. Proposed decisions: D01, D12, D16.
    # Fixture: fixtures/cases/aws-dr-foreign.json (sha256:719cd10e10b69f1419bd2f7a58dbea53ddb1892c3132ec6e80adbbb2a626423d).
    @case:aws-dr-foreign
    @status:not-built
    Scenario: Another workload proof does not transfer
      Given a recovery obligation and its actual backup or exercise evidence
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "workloadId": "citizen-portal",
          "objective": {
            "rtoMinutes": 60,
            "rpoMinutes": 15
          }
        }
        """
      And the pinned acceptance arrangement for aws-dr-foreign is established
      When the observed recovery controls are checked against the declared recovery objective
      Then a supported readiness disposition with exact gaps is available
        | operation | path | equals |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.status | REFUSED |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.reason | RECOVERY_EVIDENCE_SCOPE_MISMATCH |
```

---

## sfx-aws-report-operating-posture

```gherkin
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
```

---

