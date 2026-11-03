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

