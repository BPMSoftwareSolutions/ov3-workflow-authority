# sfx-aws-assess-cost-variance: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: ce:GetCostAndUsage.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): VARIANCE_OBSERVED, NO_VARIANCE, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-CE-01, AWS-CE-02.
# Priority: P1.

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

    # Fixture: fixtures/cases/aws-cost-rise.json (sha256:fb1baa6eba89f6c060b40e7cc392551afd49a2a8c00923fdfb9801b28dd102d3).
    # AWS: Amounts come back as strings with Unit USD, grouped as service$citizen-portal; End is exclusive (AWS-CE-02).
    # Curated: Cost is attributed by the activated cost-allocation tag, so the request drops the instance ARN and Region; Cost Explorer is one global endpoint.
    @case:aws-cost-rise
    @status:not-built
    Scenario: An observed monthly cost increase is attributed to the requested service
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "111122223333",
          "serviceId": "citizen-portal",
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

    # Fixture: fixtures/cases/aws-cost-flat.json (sha256:258aff266f1b39c8026da84c9605b3800549ae7eacf29ba661ff29ec30198e8a).
    # AWS: As above (AWS-CE-02).
    @case:aws-cost-flat
    @status:not-built
    Scenario: No material spend change yields no variance
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "111122223333",
          "serviceId": "citizen-portal",
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

    # Fixture: fixtures/cases/aws-cost-lag.json (sha256:bcd3366b8ae15228eaaf001119b3161fff2efba447449389ac83a595ea734745).
    # AWS: Estimated true marks a period whose costs are not final (AWS-CE-02).
    # Curated: The candidate's 'complete: false' is the documented Estimated flag.
    @case:aws-cost-lag
    @status:not-built
    Scenario: Incomplete recent billing data is not called a complete monthly result
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "111122223333",
          "serviceId": "citizen-portal",
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

    # Fixture: fixtures/cases/aws-cost-cross-account.json (sha256:5ae8a4633710d5a5f5726e94b733805071a7fe64f1bbe97ec3fdb2efd4c5bec2).
    # AWS: None: billing scope is SideFX's.
    @case:aws-cost-cross-account
    @status:not-built
    Scenario: A non-entitled account is not charged to the wrong team
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "999988887777",
          "serviceId": "citizen-portal",
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

    # Fixture: fixtures/cases/aws-cost-denied.json (sha256:d489b560064c6941910e80728abe71de50342fd7e6802efd869884c8cef1d19a).
    # AWS: A caller without ce:GetCostAndUsage gets AccessDeniedException.
    @case:aws-cost-denied
    @status:not-built
    Scenario: Cost Explorer permission denial is an observation limitation
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "111122223333",
          "serviceId": "citizen-portal",
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

    # Fixture: fixtures/cases/aws-cost-missing-tags.json (sha256:f29dd624d6ae476b5cc296fd29851b016e450c66e143e3eb644006e5ac4368f0).
    # AWS: Spend without the tag lands in the group service$ (AWS-CE-02).
    @case:aws-cost-missing-tags
    @status:not-built
    Scenario: Absent cost-allocation tags prevent invented service attribution
      Given a billing scope, comparison period and AWS cost observation
        """json
        {
          "accountId": "111122223333",
          "serviceId": "citizen-portal",
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
