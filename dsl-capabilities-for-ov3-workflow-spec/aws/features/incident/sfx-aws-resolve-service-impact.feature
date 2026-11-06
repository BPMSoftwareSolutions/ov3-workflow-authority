# sfx-aws-resolve-service-impact: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: cloudwatch:GetMetricData, cloudwatch:DescribeAlarms.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): ASSESSED, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CW-01, AWS-CW-02, AWS-SLO-01, AWS-SLO-02.
# Priority: P0.

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

    # Fixture: fixtures/cases/aws-impact-degraded.json (sha256:c85dc7f6fe5333d76bd7d664fa37fec26268c910a64943573b95fc4ced48be49).
    # AWS: GetMetricData returns newest-first Timestamps with one value each and StatusCode Complete (AWS-CW-02).
    # Curated: The heartbeat window is a documented GetMetricData result against the service's declared metric.
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
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

    # Fixture: fixtures/cases/aws-impact-normal.json (sha256:8b94ebdc5441855840ad2ea83182dfd9c9aae709e69839ead5a1ed59c0ef6b71).
    # AWS: As above (AWS-CW-02).
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
          "signalId": "ce60e11f-332c-4d1f-b04d-0cc195a8085e"
        }
        """
      And the pinned acceptance arrangement for aws-impact-normal is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | ASSESSED |
        | sfx-aws-resolve-service-impact.assess | $.impact.serviceState | HEALTHY |
        | sfx-aws-resolve-service-impact.assess | $.impact.targetBreached | false |

    # Fixture: fixtures/cases/aws-impact-insufficient.json (sha256:e6ed4c1c3e2cebd4618fd64cab9378d4a5d601c086b61db8ebba00ff69fcbf46).
    # AWS: The alarm reads INSUFFICIENT_DATA and the metric has no datapoints in the window (AWS-CW-01, AWS-CW-02).
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
          "signalId": "b93734ec-9960-4745-a952-a120cf30221e"
        }
        """
      And the pinned acceptance arrangement for aws-impact-insufficient is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-resolve-service-impact.assess | $.reason | RELIABILITY_DATA_INSUFFICIENT |

    # Fixture: fixtures/cases/aws-impact-unknown-slo.json (sha256:7dcea7c8b4c6b106ae6d7f8be029bf71e8040138e50d1d82611b9d2091726cc3).
    # AWS: None: the objective is SideFX's declaration; Application Signals SLOs are optional enrichment (AWS-SLO-01).
    # Curated: Without a declared objective nothing is read.
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-impact-unknown-slo is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-resolve-service-impact.assess | $.reason | SERVICE_OBJECTIVE_UNDECLARED |

    # Fixture: fixtures/cases/aws-impact-service-mismatch.json (sha256:d52500a633877237812aaea8e36bcd06f4d3dc578b732027454885d964b8f48a).
    # AWS: The metric is selected by its dimensions; a binding to another service's dimension reads another service (AWS-CW-02).
    # Curated: The mismatch is in SideFX's service binding, refused before any read.
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-impact-service-mismatch is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | REFUSED |
        | sfx-aws-resolve-service-impact.assess | $.reason | SERVICE_METRIC_SCOPE_MISMATCH |

    # Fixture: fixtures/cases/aws-impact-lag.json (sha256:fe2387f766595b4b6777e8b5955f14de5a6b3e42681889b5ad77eb17dd0e9bd9).
    # AWS: Over the last hour the newest datapoint is 35 minutes old (AWS-CW-02).
    # Curated: A two-day-old datapoint could not come back from an hour's query; the stale datapoint now sits inside the queried hour.
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
          "signalId": "12a4289a-5bb1-4ebf-a556-63e18ae438e9"
        }
        """
      And the pinned acceptance arrangement for aws-impact-lag is established
      When the service impact is assessed against its declared operating objective
      Then the observed service impact or its unobservability is stated
        | operation | path | equals |
        | sfx-aws-resolve-service-impact.assess | $.status | NOT_OBSERVABLE |
        | sfx-aws-resolve-service-impact.assess | $.reason | METRIC_WINDOW_STALE |
