# AWS ecosystem mapped to SideFX capability responsibilities

**Boundary:** AWS service names are supplier candidates, not SideFX capability identities or verified bindings. An AWS service can satisfy several requirements; multiple services can be suppliers of one responsibility. Do not turn service names into root product scenarios.

| Domain responsibility | AWS candidate service(s) | Proposed role | Important limitation |
|---|---|---|---|
| Observe cloud condition | CloudWatch, EventBridge | Signal publisher, event routing | Verify source identity, duplicates, target delivery and lag |
| Buffer failed event routing | SQS DLQ, EventBridge retry policies | Transport resilience | DLQ and redrive need configured IAM/resource policies |
| Resolve resource scope | Organizations, AWS Config aggregator, Resource Explorer | Multi-account inventory/context | Config aggregator is read-only and requires recorded sources |
| Resolve current physical state | EC2 DescribeInstances, ECS/EKS/RDS service-specific APIs | Fresh targeted state read | Config is not a substitute for every service's live state |
| Explain recent AWS actions | CloudTrail Event History, trails, CloudTrail Lake | Management audit and historical event evidence | Event History = last 90 days management events per account/Region; extended logging separately configured |
| Evaluate health of experience | CloudWatch metrics, Application Signals SLOs, X-Ray | Service SLI, metrics, tracing | Health of the AWS API or runbook is not app health |
| Check AWS-origin service events | AWS Health | Native AWS provider/region incidents | Health organizational APIs have support plan / endpoint prerequisites; optional enrichment |
| Select approved operational response | Systems Manager document catalog, AppConfig, SideFX policy | Runbook options and effect policy | AWS runbook availability is not automatic authorization |
| Execute response | Systems Manager Automation | Physical effect provider | `StartAutomationExecution` returns an ID; use GetAutomationExecution and resource read-back |
| Enforce effect permission | IAM/STS, SideFX admitted authority, Systems Manager `aws:approve` | Cross-account delegation and human approval | Avoid management-account admin role; AWS and SideFX approvals are distinct checks |
| Inspect infrastructure intentions | CloudFormation change sets, Config | Prospective change and observed configuration | Change set is not a deployed change or a success guarantee |
| Govern estate baseline | Organizations, Control Tower, Config, Service Catalog | Organizational/guardrail context | Don't conflate organization inventory with application authorization |
| Triage cloud security posture | Security Hub, GuardDuty, Inspector, Macie, Detective | Finding/evidence providers | New Security Hub V2 and CSPM events can overlap; dedupe by finding identity |
| Observe consumption and unit costs | Cost Explorer, Billing & Cost Management, Budgets, Compute Optimizer | Historical cost and optimization evidence | Cost data delayed; billing permissions, tags, cutoff and currency matter |
| Evaluate recovery readiness | AWS Backup, Resilience Hub, Elastic Disaster Recovery, Application Recovery Controller | Backup/resilience and exercise evidence | Recovery objective is proven only by restore/continuity exercise, not backup existence |
| Deliver operator communications | SNS, SES, Chat integrations, Incident systems | Notification providers | Sending is not acknowledgement or resolution |
| Persist evidence | S3, DynamoDB or approved durable store, CloudTrail/CloudWatch | Effect receipts and read models | Storage provider is subordinate to SideFX evidence/ledger authority |
| Transport API requests | API Gateway, Lambda, ECS/Fargate, EKS | Optional interface/runtime delivery | These are deployment alternatives, not new scenario meaning |
| Select runtimes and resources | EC2, Lambda, Batch, ECS, EKS, RDS, S3, networking | Managed workload estate | No need to integrate them all in the first operations demonstration |

## Architecture boundary

SideFX capability semantic authority → admitted event/contract → AWS provider profile → physical AWS result → independent verification → SideFX outcome/flight recorder. Do not introduce a special AWS codepath into the SDA kernel merely for this demonstration.

## Service portfolio strategy

**P0 / live-demo target:** CloudWatch, EventBridge, AWS Config, CloudTrail, IAM/STS, EC2, Systems Manager, optionally SQS; only one gated mutation path.

**P1 / manager value:** Organizations, Security Hub, Cost Explorer, CloudFormation, Backup/Resilience Hub, CloudWatch SLOs.

**P2 / selectively add by workload:** EKS/ECS, RDS/Aurora, Lambda, S3, Route 53, networking, KMS, Macie, GuardDuty, AWS Health, Step Functions and other services the enterprise actually operates. Do not spend the interview wiring dozens of products without a named operational responsibility.
