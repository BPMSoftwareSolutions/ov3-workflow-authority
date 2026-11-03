# Cloud Operations Manager interview demonstration — discussion guide

**Anchor:** The role owns reliability, operational risk, security cooperation, cost accountability and incident response—not memorizing every AWS service.

## 90-second opening

> I built this as a SideFX cloud-operations capability estate. Instead of connecting to every AWS console independently, I declared the outcomes an operations team must produce: detect an incident, understand the affected service, authorize a bounded response, execute an approved runbook and verify recovery. AWS services supply each physical responsibility. SideFX separates those providers from the canonical operational contract and records the actual evidence.

## Five-minute live circuit

1. Show one synthetic CloudWatch alarm-state change and identify the EventBridge delivery context (`evt-001`). Say **simulated** if using supplied fixtures.
2. Open the `sfx-aws-observe-operational-signal` feature: original alert → one operational signal; replay the same event and show `DUPLICATE`, not a second incident.
3. Inspect AWS Config ownership/environment, then fresh EC2 state (`stopped`) and a CloudTrail `StopInstances` record. Explain **temporal correlation is not causation**.
4. Show the eligible approved option `AWS-StartEC2InstanceWithApproval`. Compare `PENDING_APPROVAL` and `AUTHORIZED` requests. Explain the native AWS `aws:approve` check is separately observed.
5. Show SSM dispatch identity, then independently verify post-action EC2 state and CloudWatch application health. A successful AWS response alone must not turn into `RESTORED`.
6. Replay `aws-incident-metric-gap`: AWS runbook succeeds, service metrics unavailable → `HELD`, not recovered.

## Two-minute managerial extension

Open the separate drift, security, cost and recovery-readiness features. They consume the same account/Region/service identity but do not share authority to rewrite one another. Distinguish security finding from permission to delete, cost anomaly from savings achieved, and completed backup from completed restore exercise.

## Deep-dive questions to welcome

**Multi-account?** Organizations/Config aggregates for read-side visibility where enabled; cross-account IAM roles for scoped service-specific reads and effect dispatch. No blanket administrative principal.

**What if EventBridge retries?** Idempotency + actual execution read-back, event target DLQ for failed delivery, no blind repeated writes.

**What if an action is approved but AWS denies it?** It remains `NOT_DISPATCHED` or `REFUSED`; two independent authority boundaries must agree. The incident is not closed by the denial.

**What if metrics don't recover?** `NOT_RESTORED` or `NOT_OBSERVABLE`; escalate and retain the evidence.

**Why SideFX rather than a Step Functions state machine?** Step Functions is a valid AWS orchestration provider. SideFX's proposition is portable *capability meaning* across AWS and other ecosystems, separately admitted execution authority and attributable evidence. Neither replaces the other's job. If the organization is AWS-only and doesn't need that semantic portability, AWS-native automation may be the simpler choice.

**What about cost and staffing?** Start with one response path and the minimum required services; compare ongoing managed-service, on-call, authorization, provider-call and evidence costs with reliability value. No unsourced ROI claims.

## Presentation honesty

The package is **authored candidate features with synthetic provider arrangements**. It is not an AWS deployment, AWS credential integration, SideFX declaration, or execution proof. Live `sfx` commands must be confirmed from the real server and only reported as completed if their own receipts are observed. An AWS bill cannot be fabricated or treated as current from fixture values.
