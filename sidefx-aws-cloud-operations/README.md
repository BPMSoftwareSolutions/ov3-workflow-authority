# SideFX + AWS: Governed Cloud Operations — interview feature pack

**Date:** 2026-11-03. **State:** Candidate architecture only. **Not live, not declared, not estate-conformant.**

The product promise: **Cloud operations can detect a condition, identify the affected service, investigate its evidence, authorize a bounded response, invoke an AWS supplier, and prove whether the promised recovery outcome occurred.**

## Contents

- `14` independent canonical Gherkin feature candidates (one root circuit scenario per feature).
- `91` case-specific acceptance requests, each with an isolated synthetic fixture and named result assertions (`242` assertions total).
- `review/provider-capability-map.md` — AWS ecosystem → semantic operational responsibilities.
- `review/architecture-and-operations.md` — technical architecture and honest AWS limitations.
- `review/interview-walkthrough.md` — a short demonstration and cloud-operations deep dive.
- `review/decision-register.md` — decisions proposed, not silently treated as requirements.
- `review/sidefx-implementation-handoff.md` — feature-first, no-drift admission handoff.
- `source/aws-documentation-manifest.json` — AWS official documentation grounding supplier feasibility.
- `demo/sidefx-aws-operations-scenario-review.html` — **synthetic, explicitly labeled** offline visual discussion aid.
- `validation/local-review-report.json` — local structural results, **NOT** official estate acceptance.
- `sidefx-aws-cloud-operations-review.md` — combined complete Gherkin review text.

## Recommended first slice

`CloudWatch → EventBridge → signal → AWS Config + fresh EC2 read → CloudTrail change context → approved SSM Automation → independent EC2 + CloudWatch verification → RESTORED or HELD/ESCALATED receipt.`

Use `features/incident/sfx-aws-resolve-service-incident.feature` as the business root. It composes bounded scenario capabilities; it does NOT mean a new API, worker or microservice for every file. Use your actual SideFX server to prove any live claims.

## Deliberately absent

No AWS access keys, secret names, account-specific production configs, deployed IaC, executable AWS SDK integrations, new kernel implementation, IAM role installation, live CloudWatch alarm or SSM run, SideFX declarations, canonical feature bindings or accepted runtime receipts. Provider candidates are **not** equivalent to verified estate provider capabilities. The 2026-11-03 synthetic fixture IDs (account `111122223333`, `us-east-2`, and EC2 `i-0123456789abcdef0`) illustrate AWS identity formats only.

The user's broad AWS service catalog should be treated as supplier universe. This pack intentionally chooses operational capabilities and a small AWS provider surface to demonstrate responsible management, not a connection-per-service design.
