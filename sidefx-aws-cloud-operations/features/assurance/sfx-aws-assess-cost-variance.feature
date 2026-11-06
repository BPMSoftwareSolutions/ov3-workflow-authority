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

