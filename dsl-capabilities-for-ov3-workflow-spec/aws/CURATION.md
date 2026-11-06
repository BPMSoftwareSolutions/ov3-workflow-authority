# AWS cloud operations: curation of the feature pack

Curated on 2026-11-03 from `sidefx-aws-cloud-operations/`. That pack was left unchanged; every curated file is in this folder.

The pack had 14 features and 91 cases. Each one was checked against the AWS documentation and against the SideFX case format.

**The result:**
- 14 features and 92 cases. One case was removed and two were added.
- 40 cases changed.
- The arrangements now record 74 AWS calls in the request and response shapes AWS documents.
- `check-aws-pack.mjs` holds every recorded value to the documented value sets. Six deliberate breaks in a scratch copy were each caught with their own error.

Every case is still `@status:not-built`. The pack is declared nowhere, and no recording came from an AWS account.

## What was wrong, and what it is now

### Systems Manager (dispatch, verify, the root incident)
- **`WaitingForApproval` is not an AWS status.** An automation waiting at its `aws:approve` step reads `Waiting`, and the approve step's own status is `Approved`, `Rejected` or `Waiting` (AWS-SSM-03, AWS-SSM-04). This was fixed in `aws-dispatch-start` and `aws-verify-not-complete`.
- **The `ClientToken` value `remedy-001` would be rejected.** The token must be a UUID of 36 characters and can't be reused (AWS-SSM-01). Automation execution IDs are also UUIDs, so `ssm-execution-001` is gone everywhere.
- **The substituted runbook.** `AWS-StartEC2InstanceWithApproval` is real: the AWS approvals walkthrough uses it (AWS-SSM-02). The substitute in `aws-dispatch-wrong-runbook` was `AWS-StopEC2InstanceWithApproval`, which none of the AWS pages read for this curation lists; it is now the documented `AWS-StopEC2Instance` (AWS-SSM-06).
- **Approval is two separate checks.** SideFX authorizes the effect. Then the runbook's own `aws:approve` step waits until the approver role sends `SendAutomationSignal Approve` (AWS-SSM-05). The end-to-end case now records that second check explicitly.
- **Added `aws-auth-self-approval`.** Decision D05 requires an independent approval, but no candidate case tested independence.

### EC2 (context, verify)
- **Stopped instances need a different read.** `DescribeInstanceStatus` answers only for running instances unless `IncludeAllInstances` is set (AWS-EC2-01). The context read is therefore `DescribeInstances`.
- **Recovery needs the status checks, not only `running`.** The instance and system checks must both be `ok` (AWS-EC2-02).
- **Added `aws-verify-checks-initializing`.** Right after a start, the checks read `initializing`. That is not yet recovery.
- **`degraded-unknown` is not an EC2 state.** The no-runbook case is now a running instance with an `impaired` status check.

### CloudTrail (change evidence)
- **Resources are named, not ARN'd.** `LookupEvents` identifies a resource by `ResourceType` and `ResourceName`, such as `AWS::EC2::Instance` with `i-…`, not by its ARN (AWS-CT-02). The correlated result now also names the CloudTrail `EventId`.
- **Event history can't be "missing".** It is always on and is not a trail (AWS-CT-01). The documented failure is throttling, at 2 requests per second (AWS-CT-02). `aws-change-gap` now answers `CHANGE_SOURCE_UNAVAILABLE` on a `ThrottlingException`.
- **`aws-change-outofscope` is removed.** Event history covers one account and one Region (AWS-CT-01), so another account's change can never appear in it. Bring the case back when an organization event data store becomes an admitted source.
- **`aws-change-dataevent` asked for S3 data events about an EC2 instance.** It now names the S3 bucket.

### Config (context, drift)
- The undocumented `not_enabled` / `not_recorded` labels became the documented `ResourceNotDiscoveredException` (AWS-CONFIG-02).
- **Staleness has a documented source.** A stale item is one recorded daily (`recordingFrequency: DAILY`) whose `configurationItemCaptureTime` is a day old (AWS-CONFIG-03). The invented `observedAt` is gone.
- **One Region per read.** `GetAggregateResourceConfig` reads exactly one `SourceRegion`, so the candidate's us-west-2 item answering a us-east-2 lookup could not happen. The mismatch is now in the request, and the request is refused before any read.

### CloudWatch (signal, impact, verify)
- **Events are the documented envelope.** Every event is the Alarm State Change envelope with a UUID `id` (AWS-CW-01).
- **The ingest-gap case uses a documented state.** It is now an `INSUFFICIENT_DATA` transition, the state for an alarm without enough data. It used to be an opaque `source_unavailable`.
- **Metric readings are documented results.** They are `GetMetricData` results: newest timestamp first, one value per timestamp, and a `StatusCode` (AWS-CW-02).
- **Stale datapoints sit inside the queried window.** The two stale-metric cases used datapoints far older than the window they queried, which the API would not return.

### Security Hub (triage)
- **The request is the delivered event.** It is now a "Findings Imported V2" event carrying one OCSF finding in `detail.findings`, not a flattened summary (AWS-SH-01, AWS-SH-02). The work item is keyed by `metadata.uid`.
- **The "V1/V2" case rests on documented AWS guidance.** Security Hub and Security Hub CSPM both publish under `aws.securityhub`, and AWS says to match the Security Hub detail-type so the CSPM copy is not a duplicate (AWS-SH-01). `aws-sec-v1v2` now answers `DUPLICATE` with reason `SECURITY_HUB_CSPM_STREAM`.
- **Cross-account is realistic.** The event comes through the admitted administrator account, but the finding belongs to `999988887777`.

### Cost Explorer (cost variance)
- **Cost readings are documented results.** They are `GetCostAndUsage` results:
  - amounts are strings with a unit;
  - groups are `service$citizen-portal`;
  - untagged spend falls in `service$`;
  - the end date is exclusive (AWS-CE-02).
- **The incomplete month uses the documented flag.** It is `Estimated: true`, replacing the invented `complete: false`.
- **The request lost the instance ARN and Region.** Cost is attributed by the activated cost-allocation tag, and Cost Explorer is one global endpoint.

### AWS Backup (recovery readiness)
- **The restore drill is an AWS Backup restore-testing job.** The job has a `CreationDate`, a `CompletionDate` and a `ValidationStatus` (AWS-BKP-01, AWS-BKP-02). Measured RTO is the time from creation to completion.
- **The RPO objective is 60 minutes, not 15.** EC2 instances have no continuous backup or point-in-time restore in AWS Backup (AWS-BKP-03), so the snapshot interval sets the RPO. The arrangement uses hourly snapshots; AWS documents no particular interval for this.
- **The foreign-proof case reads the cited job.** Listing jobs by resource can only return that resource's jobs. The foreign proof is now a cited job, read back with `DescribeRestoreJob`.

### CloudFormation (drift)
- **"Not executed" uses the documented status.** It is `Status: CREATE_COMPLETE` with `ExecutionStatus: AVAILABLE`, meaning the change set exists but has not been applied (AWS-CFN-02).

### The source manifest
- **Two links used an `en_en` path.** These were AWS-CW-01 and AWS-SLO-01.
- **AWS-BKP-01 was mislabelled.** It pointed at the Systems Manager runbooks guide, not AWS Backup.
- **AWS-SEC-01 was the EventBridge DLQ page.** It is now AWS-EVB-02.
- **The manifest grew from 14 sources to 33.** Each entry states the facts used from that page. Three facts were confirmed through an AWS-docs search rather than a full page read, and are marked `"verifiedBy": "search"`.

## How the arrangements are now built

Each fixture (`fixtureType …arrangement.v2`) separates two kinds of record:

- **`sidefx`:** what SideFX holds. This covers admitted accounts, the verified delivery channel, runbook catalog admission, approvals, service bindings, objectives, policies and prior records. None of it is AWS evidence, which follows decision D12.
- **`awsCalls`:** the AWS calls the circuit makes, in order. Each call has the documented request and exactly one of `response`, `error` (code and HTTP status), or `noResponse`. Credentials are never recorded.

The two composed circuits, `sfx-aws-resolve-service-incident` and `sfx-aws-report-operating-posture`, refer to their component cases by id. They no longer use opaque labels such as `"ssm": "success"`, so the root and its components cannot drift apart.

Because the recordings have the real response shapes, a mechanic built against them reads live AWS the same way once a provider exists. It is the same move as `wildlife.identity_response` standing in for DNR.

## The estate today

I read the live estate on 2026-11-03 (run 10c94fc9). Of its 688 capabilities, none can call AWS.

- **`http-exchange`** reads a vault credential and sends it as a header (`credentialHeader` and `credentialPrefix`, for example a Bearer token). AWS APIs need every request signed with Signature Version 4, which a static header cannot provide.
- **The Azure capabilities** (`plan-azure-infrastructure` and `apply-azure-infrastructure-plan`) run OpenTofu through `opentofu-acquire-port.v1`, `opentofu-plan-digest-port.v1` and `opentofu-apply-port.v1`, with credentials from the vault. That suits infrastructure plans, not operational reads or one-off runbook dispatches.

So the features keep **no `@provider` tags**: under the no-drift rule, a tag must resolve to a capability that actually provides it.

## Decisions

**A1. How SideFX calls AWS. This one is yours.**
- **(a) Recommended: teach the HTTP exchange port to sign AWS Signature Version 4.** Credentials stay vault references and are exchanged for short sessions with `sts:AssumeRole` (AWS-IAM-02). One provider then covers every AWS operation in this pack.
  - Most of the services in this pack (Systems Manager, CloudTrail, Config, Cost Explorer, Security Hub, Application Signals) answer in JSON.
  - EC2, STS and CloudWatch's query API answer in XML, so the port must also return XML as data.
  - This is an sfx-platform change, which you merge.
- **(b) The OpenTofu path, as Azure uses it.** It needs no platform change, but it fits planned infrastructure changes, not `LookupEvents` or `StartAutomationExecution`.
- **(c) An AWS-side relay.** An API Gateway with an authorizer would accept the bearer credential `http-exchange` already sends. It needs no platform change, but it adds AWS-side code that SideFX doesn't declare, which the pack's handoff advises against.

**Defaults I took. Say if you want them otherwise.**
- **A2. Inbound events.** EventBridge delivers to SideFX through an API destination, and SideFX verifies the connection credential against a vault reference. The credential is kept on the AWS side in Secrets Manager (AWS-EVB-03). A body that merely claims `source: aws.cloudwatch` is refused (`aws-signal-forged`).
- **A3. Outcome names kept as the candidates had them.** An AWS access denial is `REFUSED` in context, change and dispatch, but `NOT_OBSERVABLE` in cost and drift. Harmonizing them would change outcome contracts, so I left them.
- **A4. An ambiguous dispatch holds.** If `StartAutomationExecution` gets no answer, the case holds (`DISPATCH_CONFIRMATION_UNKNOWN`). AWS's own idempotency would allow a retry with the same `ClientToken` and identical parameters (AWS-SSM-01). That is the alternative if you prefer fewer escalations.

## Next, to get to live AWS

1. **Settle A1.** With (a), the port change goes to sfx-platform as a PR for you to merge.
2. **Set up a sandbox account.** It needs:
   - the three roles named in the arrangements (`sidefx-cloudops-read`, `sidefx-cloudops-dispatch`, `sidefx-cloudops-automation`) and the `ops-manager` approver role;
   - a Config aggregator;
   - the SNS topic `AutomationApproval-citizen-portal`;
   - the EventBridge rule, API destination and connection.

   Credentials go into the vault as references, never into features, fixtures or Git.
3. **Capture real recordings** from the sandbox for the P0 slice and replace the synthetic ones. The shapes stay the same, and `check-aws-pack.mjs` must still pass.
4. **Build the first slice the Nerdery way:** mechanics over the recorded observations, read-only bridge cases, DSL, owner SQL, then one flight. Then bind the AWS provider in place of the recordings.
