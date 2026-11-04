# sfx-aws-resolve-service-incident: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: none of its own: each component circuit makes its calls; the root composes their arrangements by case id.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): RESTORED, ESCALATED, HELD, REFUSED.
# Source reference IDs: AWS-CW-01, AWS-EVB-03, AWS-CONFIG-02, AWS-CT-02, AWS-SSM-01, AWS-SSM-04, AWS-SSM-05, AWS-EC2-02, AWS-IAM-02.
# Priority: P0.

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

    # Fixture: fixtures/cases/aws-incident-end-to-end.json (sha256:9ce06e87c6bae00e02ecd15c264c5fff4c59e7597bf356482f05c5b88c719b73).
    # AWS: Between dispatch (Waiting) and verification (Success) the ops-manager role approves with SendAutomationSignal Approve (AWS-SSM-04, AWS-SSM-05).
    # Curated: The arrangement composes the component cases instead of opaque labels, so root and components cannot drift apart.
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
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
        | sfx-aws-resolve-service-incident.resolve | $.evidence.automationExecutionId | 9ec30224-cda9-476e-8a45-506226b0a1d1 |

    # Fixture: fixtures/cases/aws-incident-denied.json (sha256:c34304337ab0bc7510532f4cadef7e00a3f4b2ae4a07cede0aac62215b539538).
    # AWS: None beyond the components.
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-incident-denied is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | ESCALATED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | REMEDIATION_NOT_APPROVED |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |

    # Fixture: fixtures/cases/aws-incident-no-evidence.json (sha256:4eba14ab43463f990fffe15c1a7679df23ce4045f217b3ec54f0bc6b2fde59ef).
    # AWS: The read role was denied (AWS-IAM-02).
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-incident-no-evidence is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | HELD |
        | sfx-aws-resolve-service-incident.resolve | $.reason | RESOURCE_CONTEXT_INCOMPLETE |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |

    # Fixture: fixtures/cases/aws-incident-ssm-failed.json (sha256:81d66aed46dd7db1ca163191d2fc8e42e5e5408fb7d04e71dd8eca1fbf904076).
    # AWS: The execution ended Failed (AWS-SSM-03).
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-incident-ssm-failed is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | ESCALATED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | RECOVERY_NOT_VERIFIED |
        | sfx-aws-resolve-service-incident.resolve | $.evidence.recoveryVerified | false |

    # Fixture: fixtures/cases/aws-incident-metric-gap.json (sha256:713b2dea8dd3719d5ef0e4d031374d9ba918927346374e536549ddf6de8e28ce).
    # AWS: The heartbeat window had no datapoints (AWS-CW-02).
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-incident-metric-gap is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | HELD |
        | sfx-aws-resolve-service-incident.resolve | $.reason | RECOVERY_NOT_OBSERVABLE |
        | sfx-aws-resolve-service-incident.resolve | $.evidence.recoveryVerified | false |

    # Fixture: fixtures/cases/aws-incident-replayed.json (sha256:c6bdc82303ae668508c240b3029e24f0230d6d695c2b9a5c796cd9f36dfef194).
    # AWS: EventBridge can deliver an event again (AWS-EVB-01); the dispatch answers from its record (AWS-SSM-01).
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-incident-replayed is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | RESTORED |
        | sfx-aws-resolve-service-incident.resolve | $.incidentId | inc-001 |
        | sfx-aws-resolve-service-incident.resolve | $.effects.newExecutions | 0 |

    # Fixture: fixtures/cases/aws-incident-foreign.json (sha256:d0b3ebff564d251aa58a916b1a4e09ae9e1e98eabf19713246d214e837cb00e7).
    # AWS: The event's account is 999988887777 (AWS-CW-01).
    # Curated: The request's account and resource ARN now agree.
    @case:aws-incident-foreign
    @status:not-built
    Scenario: A foreign-account signal is rejected at intake
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "999988887777",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:999988887777:instance/i-0123456789abcdef0",
          "incidentId": "inc-006",
          "signalId": "5c155599-26f3-4871-97b1-3259d35cc93f"
        }
        """
      And the pinned acceptance arrangement for aws-incident-foreign is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | REFUSED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | ACCOUNT_NOT_ADMITTED |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |

    # Fixture: fixtures/cases/aws-incident-no-option.json (sha256:dafacea37dce4152d6ca10ee1522b24e5dbcacc9a2f32176684c517604d11cc5).
    # AWS: The status checks read impaired (AWS-EC2-02).
    @case:aws-incident-no-option
    @status:not-built
    Scenario: An impaired instance with no admitted runbook escalates for manual diagnosis
      Given one qualified cloud incident with its admitted service and effect boundary
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "incidentId": "inc-007",
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-incident-no-option is established
      When the admitted investigation, response and recovery circuits are composed
      Then the service is independently restored, or the incident retains an explicit non-restored disposition
        | operation | path | equals |
        | sfx-aws-resolve-service-incident.resolve | $.status | ESCALATED |
        | sfx-aws-resolve-service-incident.resolve | $.reason | NO_ADMITTED_RECOVERY_ACTION |
        | sfx-aws-resolve-service-incident.resolve | $.effects.executed | 0 |
