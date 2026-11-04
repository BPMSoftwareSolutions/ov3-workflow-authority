# sfx-aws-evaluate-recovery-readiness: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: backup:ListRecoveryPointsByResource, backup:ListRestoreJobsByProtectedResource, backup:DescribeRestoreJob.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): READY, NOT_READY, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-BKP-01, AWS-BKP-02, AWS-BKP-03.
# Priority: P1.

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

    # Fixture: fixtures/cases/aws-dr-proven.json (sha256:8fe31f4eda95e2cd240280f10d6920e892acf6fb5e2a59d7c06facd9cdaac296).
    # AWS: A restore-testing job reports its CreationDate, CompletionDate and ValidationStatus (AWS-BKP-01, AWS-BKP-02).
    # Curated: The drill is an AWS Backup restore-testing job. The RPO objective is 60 minutes, not 15: EC2 has no continuous backup (AWS-BKP-03), so hourly snapshots bound it.
    @case:aws-dr-proven
    @status:not-built
    Scenario: A fresh successful restore test satisfies the declared RTO and RPO
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
            "rpoMinutes": 60
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
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.readiness.measuredRtoMinutes | 42 |

    # Fixture: fixtures/cases/aws-dr-backup-only.json (sha256:409745168ecc2a5fb1dc291697ff7e907856d12c6c1cae026109c6649346db93).
    # AWS: Recovery points exist and no restore job ran (AWS-BKP-02).
    @case:aws-dr-backup-only
    @status:not-built
    Scenario: Successful backups without a restore test do not prove ready
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
            "rpoMinutes": 60
          }
        }
        """
      And the pinned acceptance arrangement for aws-dr-backup-only is established
      When the observed recovery controls are checked against the declared recovery objective
      Then a supported readiness disposition with exact gaps is available
        | operation | path | equals |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.status | NOT_READY |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.reason | RESTORE_EXERCISE_NOT_PROVEN |

    # Fixture: fixtures/cases/aws-dr-rto.json (sha256:4bb87711470449dc2acc255c3c1d19846b4c84db32bb84bf8d470a387f64dc44).
    # AWS: The restore job took 90 minutes from CreationDate to CompletionDate (AWS-BKP-02).
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
            "rpoMinutes": 60
          }
        }
        """
      And the pinned acceptance arrangement for aws-dr-rto is established
      When the observed recovery controls are checked against the declared recovery objective
      Then a supported readiness disposition with exact gaps is available
        | operation | path | equals |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.status | NOT_READY |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.readiness.withinRto | false |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.readiness.measuredRtoMinutes | 90 |

    # Fixture: fixtures/cases/aws-dr-no-objective.json (sha256:e33272c11d6cf2f39feb42d32dbcc9958fcb1285d43904b20d1a9e8c59752f5c).
    # AWS: None: the objective is SideFX's.
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

    # Fixture: fixtures/cases/aws-dr-stale-proof.json (sha256:beadfcb81d8034aaa67db1b1c492e5edd930da81ac93d8db2db5de61ef7d0978).
    # AWS: The newest restore job completed in January 2025 (AWS-BKP-02).
    @case:aws-dr-stale-proof
    @status:not-built
    Scenario: An out-of-date restore test is not current proof
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
            "rpoMinutes": 60
          }
        }
        """
      And the pinned acceptance arrangement for aws-dr-stale-proof is established
      When the observed recovery controls are checked against the declared recovery objective
      Then a supported readiness disposition with exact gaps is available
        | operation | path | equals |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.status | NOT_READY |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.reason | EXERCISE_EVIDENCE_STALE |

    # Fixture: fixtures/cases/aws-dr-foreign.json (sha256:381040d582ab3d4a922f753097473c677de83a83da198fedbdf46aad1d1850a3).
    # AWS: A restore job names its SourceResourceArn (AWS-BKP-02).
    # Curated: Listing by resource can only return this resource's jobs, so the foreign proof is now a cited job read back with DescribeRestoreJob.
    @case:aws-dr-foreign
    @status:not-built
    Scenario: Another workload's proof does not transfer
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
            "rpoMinutes": 60
          },
          "proofRestoreJobId": "005a0a61-af7a-4d3d-9e2b-eac8d9a55168"
        }
        """
      And the pinned acceptance arrangement for aws-dr-foreign is established
      When the observed recovery controls are checked against the declared recovery objective
      Then a supported readiness disposition with exact gaps is available
        | operation | path | equals |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.status | REFUSED |
        | sfx-aws-evaluate-recovery-readiness.evaluate | $.reason | RECOVERY_EVIDENCE_SCOPE_MISMATCH |
