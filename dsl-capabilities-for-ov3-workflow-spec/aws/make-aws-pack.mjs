// The curated AWS cloud-operations feature pack: the 14 candidate features of sidefx-aws-cloud-operations (read only,
// another pack's work) corrected against the AWS documentation and the SideFX case format.
//   aws/skeleton.json                         each feature's declared identity, story, rule and Given/When/Then, taken
//                                             once from the candidate pack and kept word for word
//   aws/features/<area>/<capability>.feature  the curated features, one circuit each, cases pinned to their fixtures
//   aws/fixtures/cases/<case>.json            per case: the SideFX records it relies on and the AWS calls it makes, in
//                                             the documented request and response shapes (aws-shapes.mjs)
//   aws/source/aws-documentation-manifest.json  the AWS pages each fact rests on, as read on 2026-11-03
//   aws/review/case-manifest.json             every case with its outcome, AWS calls and digests
// Every arrangement is synthetic: no recording was captured from an AWS account, and nothing here is declared in the
// estate. Run check-aws-pack.mjs after any change.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as aws from "./aws-shapes.mjs";
const here = path.dirname(fileURLToPath(import.meta.url));
const { sha, uuid } = aws;
const skeleton = JSON.parse(fs.readFileSync(path.join(here, "skeleton.json"), "utf8"));

// ---------- the AWS documentation each fact rests on (fetched 2026-11-03 unless marked search) ----------
const SOURCES = {
  "AWS-CW-01": ["CloudWatch alarm events and EventBridge", "https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch-and-eventbridge.html",
    "Alarm State Change envelope (id, account, region, resources, detail.state/previousState); states OK, ALARM, INSUFFICIENT_DATA; delivery to EventBridge is guaranteed"],
  "AWS-CW-02": ["CloudWatch MetricDataResult", "https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_MetricDataResult.html",
    "Timestamps and Values pair one to one; StatusCode Complete, InternalError, PartialData, Forbidden"],
  "AWS-EVB-01": ["EventBridge retry policy", "https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-rule-retry-policy.html",
    "retries for 24 hours and up to 185 times by default; after that the event is dropped unless a dead-letter queue is set"],
  "AWS-EVB-02": ["EventBridge dead-letter queues", "https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-rule-dlq.html",
    "undelivered events go to the target's DLQ (named AWS-SEC-01 in the candidate pack)"],
  "AWS-EVB-03": ["EventBridge API destinations", "https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-api-destinations.html",
    "connections carry the authorization (credentials kept in Secrets Manager); 5 second timeout; 401, 407, 409, 429 and 5xx are retried"],
  "AWS-CONFIG-01": ["AWS Config multi-account, multi-Region aggregation", "https://docs.aws.amazon.com/config/latest/developerguide/aggregate-data.html",
    "an aggregator collects configuration data from source accounts and Regions, read only"],
  "AWS-CONFIG-02": ["Config GetAggregateResourceConfig", "https://docs.aws.amazon.com/config/latest/APIReference/API_GetAggregateResourceConfig.html",
    "one configuration item for a SourceAccountId and SourceRegion; ResourceNotDiscoveredException when unknown or not discovered; no deleted resources"],
  "AWS-CONFIG-03": ["Config ConfigurationItem", "https://docs.aws.amazon.com/config/latest/APIReference/API_ConfigurationItem.html",
    "configurationItemStatus OK, ResourceDiscovered, ResourceNotRecorded, ResourceDeleted, ResourceDeletedNotRecorded; configuration is a JSON string; recordingFrequency DAILY when daily"],
  "AWS-ORG-01": ["AWS Organizations integration with AWS Config", "https://docs.aws.amazon.com/organizations/latest/userguide/services-that-can-integrate-config.html",
    "organization-wide aggregation"],
  "AWS-IAM-01": ["Cross-account resource access in IAM", "https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies-cross-account-resource-access.html",
    "cross-account roles"],
  "AWS-IAM-02": ["STS AssumeRole", "https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html",
    "sessions of 900 to 43200 seconds (1 hour when chaining roles); the caller must be trusted by the role and allowed sts:AssumeRole"],
  "AWS-CT-01": ["CloudTrail event history", "https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events.html",
    "90 days of management events per Region; no data, Insights or network activity events; one account, one Region, one attribute; no organization aggregation"],
  "AWS-CT-02": ["CloudTrail LookupEvents", "https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_LookupEvents.html",
    "2 requests per second per account per Region; at most 50 events a page; Resources named by ResourceType and ResourceName; EventTime is a timestamp"],
  "AWS-EC2-01": ["EC2 DescribeInstanceStatus", "https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstanceStatus.html",
    "only running instances unless IncludeAllInstances; state names and codes (stopped 80, running 16)"],
  "AWS-EC2-02": ["EC2 InstanceStatusSummary", "https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_InstanceStatusSummary.html",
    "status ok, impaired, insufficient-data, not-applicable, initializing"],
  "AWS-SSM-01": ["Systems Manager StartAutomationExecution", "https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_StartAutomationExecution.html",
    "ClientToken is a UUID that can't be reused; IdempotentParameterMismatch on a retry with other parameters; the answer is only AutomationExecutionId"],
  "AWS-SSM-02": ["Run an automation that requires approvals", "https://docs.aws.amazon.com/systems-manager/latest/userguide/running-automations-require-approvals.html",
    "AWS-StartEC2InstanceWithApproval takes InstanceId, Approvers and SNSTopicArn; the approval request is valid for 7 days"],
  "AWS-SSM-03": ["Systems Manager AutomationExecution", "https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_AutomationExecution.html",
    "AutomationExecutionStatus values (Waiting, Success, Failed, TimedOut, Cancelled and the rest); there is no WaitingForApproval"],
  "AWS-SSM-04": ["aws:approve", "https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-action-approve.html",
    "the automation shows Waiting until approvers decide; ApprovalStatus Approved, Rejected, Waiting; up to 10 approvers (users or roles); 7 day default timeout"],
  "AWS-SSM-05": ["Systems Manager SendAutomationSignal", "https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_SendAutomationSignal.html",
    "SignalType Approve, Reject, StartStep, StopStep, Resume, Revoke"],
  "AWS-SSM-06": ["Automation runbook reference: Amazon EC2", "https://docs.aws.amazon.com/systems-manager-automation-runbooks/latest/userguide/automation-ref-ec2.html",
    "AWS-StartEC2Instance, AWS-StopEC2Instance, AWS-RestartEC2Instance are listed; the WithApproval runbooks are not on this page"],
  "AWS-SLO-01": ["CloudWatch Application Signals SLOs", "https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-ServiceLevelObjectives.html",
    "service level objectives over Application Signals (optional enrichment)"],
  "AWS-SLO-02": ["Application Signals ServiceLevelObjectiveBudgetReport", "https://docs.aws.amazon.com/applicationsignals/latest/APIReference/API_ServiceLevelObjectiveBudgetReport.html",
    "BudgetStatus OK, WARNING, BREACHED, INSUFFICIENT_DATA"],
  "AWS-CFN-01": ["CloudFormation change sets", "https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html",
    "a change set previews a change; nothing changes until it is executed"],
  "AWS-CFN-02": ["CloudFormation DescribeChangeSet", "https://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_DescribeChangeSet.html",
    "Status CREATE_COMPLETE and the rest; ExecutionStatus AVAILABLE means it can still be executed"],
  "AWS-SH-01": ["Security Hub EventBridge event types", "https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-v2-cwe-event-types.html",
    "Findings Imported V2, one finding per event; Security Hub and Security Hub CSPM both use source aws.securityhub, so rules must match the Security Hub detail-type"],
  "AWS-SH-02": ["Security Hub EventBridge event formats", "https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-v2-cwe-event-formats.html",
    "detail.findings holds the OCSF finding (search)"],
  "AWS-SH-03": ["Security Hub OcsfFindingIdentifier", "https://docs.aws.amazon.com/securityhub/1.0/APIReference/API_OcsfFindingIdentifier.html",
    "cloud.account.uid + finding_info.uid + metadata.product.uid identify a finding; metadata.uid is globally unique; severity_id 0-6 or 99 (search)"],
  "AWS-CE-01": ["Cost Explorer API", "https://docs.aws.amazon.com/cost-management/latest/userguide/ce-api.html", "programmatic cost and usage"],
  "AWS-CE-02": ["Cost Explorer GetCostAndUsage", "https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetCostAndUsage.html",
    "Start inclusive, End exclusive; Estimated marks an unfinalized period; amounts are strings with a Unit; tag groups are key$value, untagged spend key$"],
  "AWS-BKP-01": ["AWS Backup restore testing", "https://docs.aws.amazon.com/aws-backup/latest/devguide/restore-testing.html",
    "scheduled restore jobs of type Test, their completion time and optional validation; restored resources are deleted afterwards (the candidate pack pointed this ID at the SSM runbook guide)"],
  "AWS-BKP-02": ["AWS Backup RestoreJobsListMember", "https://docs.aws.amazon.com/aws-backup/latest/devguide/API_RestoreJobsListMember.html",
    "Status PENDING, RUNNING, COMPLETED, ABORTED, FAILED; ValidationStatus; DeletionStatus; CreationDate and CompletionDate"],
  "AWS-BKP-03": ["AWS Backup feature availability", "https://docs.aws.amazon.com/aws-backup/latest/devguide/backup-feature-availability.html",
    "continuous backup and point-in-time restore cover Aurora, RDS, SAP HANA on EC2 and S3, not EC2 instances (search)"],
};

// ---------- the synthetic estate the arrangements describe ----------
const A = "111122223333", F = "999988887777", R = "us-east-2", I = "i-0123456789abcdef0", OTHER_I = "i-0fedcba9876543210";
const ARN = `arn:aws:ec2:${R}:${A}:instance/${I}`;
const SVC = "citizen-portal", ALARM = "citizen-portal-heartbeat-low";
const target = { accountId: A, region: R, serviceId: SVC, resourceArn: ARN };
const E = { alarm: uuid("event:alarm"), ok: uuid("event:ok"), forged: uuid("event:forged"), other: uuid("event:other-account"),
  insufficient: uuid("event:insufficient-data") };
const EXECUTION = uuid("ssm:execution:remedy-001");
const TOKEN = (n) => uuid(`client-token:remedy-00${n}`);
const RUNBOOK = { documentName: "AWS-StartEC2InstanceWithApproval", documentVersion: "1" };
const APPROVER = `arn:aws:iam::${A}:role/ops-manager`, TOPIC = `arn:aws:sns:${R}:${A}:AutomationApproval-citizen-portal`;
const AUTOMATION_ROLE = `arn:aws:iam::${A}:role/sidefx-cloudops-automation`;
const RUN_PARAMETERS = { InstanceId: [I], Approvers: [APPROVER], SNSTopicArn: [TOPIC], AutomationAssumeRole: [AUTOMATION_ROLE] };
const BINDING = { serviceId: SVC, namespace: "CitizenPortal", metricName: "HeartbeatSuccess", dimensions: { ServiceId: SVC }, alarmName: ALARM };
const OBJECTIVE = { statistic: "Average", minimum: 0.99, windowMinutes: 5 };
const minus = (iso, minutes) => new Date(Date.parse(iso) - minutes * 60000).toISOString().replace(".000Z", "Z");
const call = (name, request, outcome) => ({ call: name, request, ...outcome });
const ok = (response) => ({ response });
const fails = (code, httpStatus, message) => ({ error: aws.awsError(code, httpStatus, message) });

const alarm = (id, value, previous, time, extra = {}) => aws.alarmStateChange({ id, account: A, region: R, alarmName: ALARM, value, previous, time, serviceId: SVC, ...extra });
const assumeRead = (session) => call("sts:AssumeRole", { RoleArn: `arn:aws:iam::${A}:role/sidefx-cloudops-read`, RoleSessionName: session, DurationSeconds: 900 },
  ok(aws.assumedRole({ account: A, role: "sidefx-cloudops-read", session })));
const assumeDenied = (session) => call("sts:AssumeRole", { RoleArn: `arn:aws:iam::${A}:role/sidefx-cloudops-read`, RoleSessionName: session, DurationSeconds: 900 },
  fails("AccessDenied", 403, `User: arn:aws:sts::${A}:assumed-role/sidefx-cloudops-base/sidefx is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::${A}:role/sidefx-cloudops-read`));
const configRead = (outcome) => call("config:GetAggregateResourceConfig", { ConfigurationAggregatorName: "sidefx-cloudops-aggregator",
  ResourceIdentifier: { SourceAccountId: A, SourceRegion: R, ResourceId: I, ResourceType: "AWS::EC2::Instance" } }, outcome);
const ci = (fields) => ok(aws.configurationItem({ account: A, region: R, instanceId: I, captureTime: "2026-11-02T23:52:30Z", ...fields }));
const ec2Read = (stateName) => call("ec2:DescribeInstances", { InstanceIds: [I] }, ok(aws.describeInstances({ instanceId: I, region: R, stateName,
  tags: [{ Key: "service", Value: SVC }] })));
const metricQuery = (clock, binding = BINDING) => ({ MetricDataQueries: [{ Id: "heartbeat", MetricStat: { Metric: { Namespace: binding.namespace,
  MetricName: binding.metricName, Dimensions: Object.entries(binding.dimensions).map(([Name, Value]) => ({ Name, Value })) }, Period: 60, Stat: "Average" } }],
  StartTime: aws.epoch(minus(clock, 60)), EndTime: aws.epoch(clock), ScanBy: "TimestampDescending" });
const metrics = (clock, values, newestMinutesAgo = 1, status = "Complete") =>
  call("cloudwatch:GetMetricData", metricQuery(clock), ok(aws.metricData({ values, newest: minus(clock, newestMinutesAgo), status })));
const execution = (status, extra = {}) => call("ssm:GetAutomationExecution", { AutomationExecutionId: EXECUTION },
  ok(aws.automationExecution({ id: EXECUTION, ...RUNBOOK, status, parameters: RUN_PARAMETERS, start: "2026-11-03T00:21:00Z", ...extra })));
const instanceChecks = (stateName, instance, system) => call("ec2:DescribeInstanceStatus", { InstanceIds: [I], IncludeAllInstances: true },
  ok(aws.instanceStatus({ instanceId: I, region: R, stateName, instance, system })));

// ---------- the curated cases, feature by feature ----------
// Each case: id, title, aws (the AWS fact it rests on, with sources), curated (what changed from the candidate, if
// anything), clock, request, then ([path, equals]), sidefx (the SideFX records it relies on), calls (the AWS calls in order).
const FEATURES = {};

FEATURES["sfx-aws-observe-operational-signal"] = { sources: ["AWS-CW-01", "AWS-EVB-01", "AWS-EVB-02", "AWS-EVB-03"],
  awsCalls: "none: EventBridge delivers the event to the SideFX intake through an API destination",
  base: { clock: "2026-11-03T00:20:00Z", sidefx: { admittedAccounts: [A], admittedAlarms: [ALARM], priorSignals: [],
    delivery: { channel: "eventbridge-api-destination", connection: "sidefx-cloudops-intake", credentialVerified: true } } },
  cases: [
    { id: "aws-signal-alarm", title: "A production CloudWatch ALARM is admitted once",
      aws: "EventBridge delivers the documented Alarm State Change envelope with a UUID event id (AWS-CW-01).",
      curated: "Event ids are UUIDs and the request is the full documented envelope; trust comes from the API destination connection credential (AWS-EVB-03).",
      request: { event: alarm(E.alarm, "ALARM", "OK", "2026-11-02T23:57:00Z") },
      then: [["$.status", "OBSERVED"], ["$.signal.source", "aws.cloudwatch"], ["$.signal.qualified", "true"], ["$.signal.occurrenceId", E.alarm],
        ["$.signal.state", "ALARM"], ["$.signal.alarmName", ALARM]] },
    { id: "aws-signal-repeat", title: "The same event is not counted twice",
      aws: "A retried delivery repeats the identical event: EventBridge retries for up to 24 hours and 185 attempts (AWS-EVB-01).",
      curated: "The redelivery is the identical envelope, as a retry sends it.",
      request: { event: alarm(E.alarm, "ALARM", "OK", "2026-11-02T23:57:00Z") }, sidefx: { priorSignals: [E.alarm] },
      then: [["$.status", "DUPLICATE"], ["$.newOperationalSignal", "false"], ["$.signal.occurrenceId", E.alarm]] },
    { id: "aws-signal-ok", title: "A distinct OK transition is retained as a new signal",
      aws: "Each state change is its own event with its own id (AWS-CW-01).",
      request: { event: alarm(E.ok, "OK", "ALARM", "2026-11-03T00:15:00Z") }, sidefx: { priorSignals: [E.alarm] },
      then: [["$.status", "OBSERVED"], ["$.signal.state", "OK"], ["$.signal.occurrenceId", E.ok]] },
    { id: "aws-signal-forged", title: "An unauthenticated caller cannot assert a trusted AWS event",
      aws: "Only the API destination's connection carries the credential SideFX verifies (AWS-EVB-03); the body's source field proves nothing.",
      curated: "The forged body is now a complete, plausible envelope, so only the missing connection credential refuses it.",
      request: { event: alarm(E.forged, "ALARM", "OK", "2026-11-03T00:05:00Z") },
      sidefx: { delivery: { channel: "direct-post", connection: null, credentialVerified: false } },
      then: [["$.status", "REFUSED"], ["$.reason", "UNTRUSTED_SOURCE"], ["$.newOperationalSignal", "false"]] },
    { id: "aws-signal-other-account", title: "An out-of-scope account does not become an incident",
      aws: "The envelope's account field names the account the alarm belongs to (AWS-CW-01).",
      request: { event: aws.alarmStateChange({ id: E.other, account: F, region: R, alarmName: ALARM, value: "ALARM", previous: "OK", time: "2026-11-03T00:06:00Z", serviceId: SVC }) },
      then: [["$.status", "REFUSED"], ["$.reason", "ACCOUNT_NOT_ADMITTED"], ["$.newOperationalSignal", "false"]] },
    { id: "aws-signal-malformed", title: "An event with no stable identity cannot be deduplicated safely",
      aws: "Every EventBridge event carries an id (AWS-CW-01); a body without one did not come from EventBridge intact.",
      request: { event: alarm(undefined, "ALARM", "OK", "2026-11-03T00:07:00Z") },
      then: [["$.status", "REFUSED"], ["$.reason", "EVENT_IDENTITY_MISSING"]] },
    { id: "aws-signal-ingest-gap", title: "An INSUFFICIENT_DATA transition is a coverage gap, not a healthy estate",
      aws: "INSUFFICIENT_DATA is the documented state for an alarm without enough data to evaluate (AWS-CW-01).",
      curated: "The candidate's opaque 'source_unavailable' observation is replaced by the documented state that reports missing data.",
      request: { event: alarm(E.insufficient, "INSUFFICIENT_DATA", "OK", "2026-11-03T00:10:00Z") },
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "SOURCE_COVERAGE_UNAVAILABLE"], ["$.signal", "(absent)"]] },
  ] };

FEATURES["sfx-aws-resolve-resource-context"] = { sources: ["AWS-CONFIG-01", "AWS-CONFIG-02", "AWS-CONFIG-03", "AWS-ORG-01", "AWS-IAM-01", "AWS-IAM-02", "AWS-EC2-01"],
  awsCalls: "sts:AssumeRole, config:GetAggregateResourceConfig, ec2:DescribeInstances",
  base: { clock: "2026-11-03T00:20:00Z", request: { ...target, signalId: E.alarm },
    sidefx: { admittedAccounts: [A], readRole: `arn:aws:iam::${A}:role/sidefx-cloudops-read`, aggregator: "sidefx-cloudops-aggregator", maxEvidenceAgeMinutes: 60 } },
  cases: [
    { id: "aws-context-ec2", title: "An admitted EC2 resource resolves with owner and environment",
      aws: "The configuration item carries the tags; DescribeInstances gives the fresh state, because DescribeInstanceStatus omits stopped instances by default (AWS-CONFIG-03, AWS-EC2-01).",
      curated: "Observations are the documented configuration item and DescribeInstances shapes; the signal id is the admitted event's id.",
      calls: [assumeRead("sidefx-context"), configRead(ci({ tags: { service: SVC, environment: "production", owner: "operations" } })), ec2Read("stopped")],
      then: [["$.status", "RESOLVED"], ["$.resource.instanceId", I], ["$.resource.environment", "production"], ["$.resource.owner", "operations"],
        ["$.resource.lifecycleState", "stopped"], ["$.evidence.configurationItemStatus", "OK"]] },
    { id: "aws-context-cross-account", title: "Cross-account inventory is read only when access is admitted",
      aws: "AssumeRole returns the assumed-role identity the reads run as; credentials are never recorded (AWS-IAM-02).",
      curated: "The admitted role is named, and the result names the assumed-role session the reads ran as.",
      calls: [assumeRead("sidefx-context"), configRead(ci({ tags: { service: SVC, environment: "production", owner: "operations" } })), ec2Read("stopped")],
      then: [["$.status", "RESOLVED"], ["$.access.mode", "assumed-read-only-role"],
        ["$.access.assumedRoleArn", `arn:aws:sts::${A}:assumed-role/sidefx-cloudops-read/sidefx-context`], ["$.resource.serviceId", SVC]] },
    { id: "aws-context-no-recording", title: "Missing Config recording is reported as partial coverage",
      aws: "GetAggregateResourceConfig answers ResourceNotDiscoveredException for a resource Config has not discovered (AWS-CONFIG-02).",
      curated: "The candidate's 'not_enabled' becomes the documented error.",
      calls: [assumeRead("sidefx-context"), configRead(fails("ResourceNotDiscoveredException", 400, `Resource ${I} of resourceType:AWS::EC2::Instance is unknown or has not been discovered`)), ec2Read("stopped")],
      then: [["$.status", "PARTIAL"], ["$.reason", "CONFIG_COVERAGE_MISSING"], ["$.resource.lifecycleState", "stopped"]] },
    { id: "aws-context-unauthorized", title: "A cross-account role denial cannot be silently bypassed",
      aws: "STS answers AccessDenied (403) when the caller may not assume the role (AWS-IAM-02).",
      calls: [assumeDenied("sidefx-context")],
      then: [["$.status", "REFUSED"], ["$.reason", "CROSS_ACCOUNT_ACCESS_DENIED"]] },
    { id: "aws-context-tag-absent", title: "An unowned resource is not assigned a fictional team",
      aws: "Tags come only from the configuration item's tags map (AWS-CONFIG-03).",
      calls: [assumeRead("sidefx-context"), configRead(ci({ tags: {} })), ec2Read("stopped")],
      then: [["$.status", "PARTIAL"], ["$.resource.owner", "(absent)"], ["$.reason", "OWNER_NOT_OBSERVABLE"]] },
    { id: "aws-context-region", title: "A resource in another Region cannot resolve the admitted target",
      aws: "GetAggregateResourceConfig reads exactly one SourceRegion, so it cannot hand back another Region's item (AWS-CONFIG-02).",
      curated: "The candidate returned a us-west-2 item for a us-east-2 lookup, which the API cannot do; the mismatch now sits in the request and is refused before any read.",
      request: { ...target, resourceArn: `arn:aws:ec2:us-west-2:${A}:instance/${I}`, signalId: E.alarm }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "RESOURCE_SCOPE_MISMATCH"]] },
    { id: "aws-context-stale", title: "Stale configuration data is flagged rather than declared current",
      aws: "With daily recording the item carries recordingFrequency DAILY and its capture time can be a day old (AWS-CONFIG-03).",
      curated: "Staleness comes from the documented capture time and daily recording, not an invented observedAt.",
      calls: [assumeRead("sidefx-context"), configRead(ci({ tags: { service: SVC, environment: "production", owner: "operations" }, captureTime: "2026-11-02T00:05:00Z",
        recordingFrequency: "DAILY", stateName: "running" })), ec2Read("stopped")],
      then: [["$.status", "PARTIAL"], ["$.reason", "CONFIG_EVIDENCE_STALE"], ["$.resource.lifecycleState", "stopped"]] },
  ] };

const WINDOW = { start: "2026-11-02T23:00:00Z", end: "2026-11-03T01:00:00Z" };
const lookup = (outcome) => call("cloudtrail:LookupEvents", { LookupAttributes: [{ AttributeKey: "ResourceName", AttributeValue: I }],
  StartTime: aws.epoch(WINDOW.start), EndTime: aws.epoch(WINDOW.end), MaxResults: 50 }, outcome);
const STOP = { eventId: uuid("cloudtrail:stop-instances"), eventName: "StopInstances", account: A, region: R, time: "2026-11-02T23:52:00Z", instanceId: I,
  principal: `arn:aws:sts::${A}:assumed-role/deploy-pipeline/ci-run-4412` };
FEATURES["sfx-aws-correlate-change-evidence"] = { sources: ["AWS-CT-01", "AWS-CT-02"], awsCalls: "cloudtrail:LookupEvents",
  base: { clock: "2026-11-03T01:05:00Z", request: { ...target, window: WINDOW }, sidefx: { admittedAccounts: [A], sourceMode: "event-history" } },
  cases: [
    { id: "aws-change-stop", title: "A matching StopInstances CloudTrail management event is correlated",
      aws: "LookupEvents by ResourceName returns the event with ResourceType AWS::EC2::Instance and ResourceName, not an ARN (AWS-CT-02).",
      curated: "The recording is the documented LookupEvents shape; the result also names the CloudTrail event id it rests on.",
      calls: [lookup(ok(aws.lookupEvents([STOP])))],
      then: [["$.status", "CORRELATED"], ["$.changes[0].eventName", "StopInstances"], ["$.changes[0].eventId", STOP.eventId],
        ["$.changes[0].resourceArn", ARN], ["$.causationProven", "false"]] },
    { id: "aws-change-none", title: "No matching event means uncorrelated, not proof no change occurred",
      aws: "Event history holds management events only, so an empty answer covers management activity in the window and nothing else (AWS-CT-01).",
      calls: [lookup(ok(aws.lookupEvents([])))],
      then: [["$.status", "UNCORRELATED"], ["$.changes", "[]"], ["$.coverage.complete", "true"], ["$.coverage.source", "event-history"]] },
    { id: "aws-change-gap", title: "A throttled lookup is a visibility gap, not an empty history",
      aws: "Lookups are limited to two a second per account and Region and fail with a throttling error beyond that (AWS-CT-02).",
      curated: "Event history is always on and is not a trail (AWS-CT-01), so 'missing trail' cannot happen for it; the documented failure is throttling, and TRAIL_QUERY_UNAVAILABLE becomes CHANGE_SOURCE_UNAVAILABLE.",
      calls: [lookup(fails("ThrottlingException", 400, "Rate exceeded"))],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "CHANGE_SOURCE_UNAVAILABLE"]] },
    { id: "aws-change-90d", title: "Event History beyond its 90-day window is not claimed as covered",
      aws: "Event history keeps the past 90 days only (AWS-CT-01).",
      request: { ...target, window: { start: "2026-01-01T00:00:00Z", end: "2026-01-02T00:00:00Z" }, sourceMode: "event-history" }, calls: [],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "SOURCE_RETENTION_WINDOW_EXCEEDED"]] },
    { id: "aws-change-dataevent", title: "Management event history is not a substitute for unenabled S3 data-event logging",
      aws: "Event history never holds data events (AWS-CT-01).",
      curated: "The candidate asked for S3 data events about an EC2 instance; the request now names the S3 bucket.",
      request: { accountId: A, region: R, serviceId: SVC, resourceArn: "arn:aws:s3:::citizen-portal-uploads", window: WINDOW, eventClass: "data" }, calls: [],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "DATA_EVENT_COVERAGE_UNAVAILABLE"]] },
    { id: "aws-change-no-access", title: "CloudTrail denial does not fall back to an anonymous query",
      aws: "A caller without cloudtrail:LookupEvents gets AccessDeniedException.",
      calls: [lookup(fails("AccessDeniedException", 400, `User: arn:aws:sts::${A}:assumed-role/sidefx-cloudops-read/sidefx-change is not authorized to perform: cloudtrail:LookupEvents`))],
      then: [["$.status", "REFUSED"], ["$.reason", "SOURCE_ACCESS_DENIED"]] },
  ],
  removed: [["aws-change-outofscope", "Event history is one account and one Region (AWS-CT-01), so another account's change can never appear in it. Reinstate the case with an organization event data store as its source when that source is admitted."]] };

FEATURES["sfx-aws-resolve-service-impact"] = { sources: ["AWS-CW-01", "AWS-CW-02", "AWS-SLO-01", "AWS-SLO-02"],
  awsCalls: "cloudwatch:GetMetricData, cloudwatch:DescribeAlarms",
  base: { clock: "2026-11-03T00:20:00Z", request: { ...target, signalId: E.alarm }, sidefx: { serviceBinding: BINDING, objective: OBJECTIVE, maxMetricAgeMinutes: 15 } },
  cases: [
    { id: "aws-impact-degraded", title: "A breached health target establishes degraded observed service state",
      aws: "GetMetricData returns newest-first Timestamps with one value each and StatusCode Complete (AWS-CW-02).",
      curated: "The heartbeat window is a documented GetMetricData result against the service's declared metric.",
      calls: [metrics("2026-11-03T00:20:00Z", [0.2, 0.1, 0.3, 0.2, 0.4])],
      then: [["$.status", "ASSESSED"], ["$.impact.serviceState", "DEGRADED"], ["$.impact.serviceId", SVC], ["$.impact.targetBreached", "true"]] },
    { id: "aws-impact-normal", title: "A healthy metric does not fabricate an incident",
      aws: "As above (AWS-CW-02).",
      request: { ...target, signalId: E.ok }, calls: [metrics("2026-11-03T00:20:00Z", [1, 1, 1, 1, 1])],
      then: [["$.status", "ASSESSED"], ["$.impact.serviceState", "HEALTHY"], ["$.impact.targetBreached", "false"]] },
    { id: "aws-impact-insufficient", title: "INSUFFICIENT_DATA is not the same as HEALTHY",
      aws: "The alarm reads INSUFFICIENT_DATA and the metric has no datapoints in the window (AWS-CW-01, AWS-CW-02).",
      request: { ...target, signalId: E.insufficient },
      calls: [metrics("2026-11-03T00:20:00Z", []), call("cloudwatch:DescribeAlarms", { AlarmNames: [ALARM] },
        ok(aws.metricAlarm({ account: A, region: R, alarmName: ALARM, state: "INSUFFICIENT_DATA", updated: "2026-11-03T00:10:00Z", serviceId: SVC })))],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "RELIABILITY_DATA_INSUFFICIENT"]] },
    { id: "aws-impact-unknown-slo", title: "No configured service objective means no invented priority",
      aws: "None: the objective is SideFX's declaration; Application Signals SLOs are optional enrichment (AWS-SLO-01).",
      curated: "Without a declared objective nothing is read.",
      sidefx: { objective: null }, calls: [],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "SERVICE_OBJECTIVE_UNDECLARED"]] },
    { id: "aws-impact-service-mismatch", title: "A foreign service metric is not joined to the incident",
      aws: "The metric is selected by its dimensions; a binding to another service's dimension reads another service (AWS-CW-02).",
      curated: "The mismatch is in SideFX's service binding, refused before any read.",
      sidefx: { serviceBinding: { ...BINDING, dimensions: { ServiceId: "other-app" } } }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "SERVICE_METRIC_SCOPE_MISMATCH"]] },
    { id: "aws-impact-lag", title: "Stale metrics are not presented as fresh operational state",
      aws: "Over the last hour the newest datapoint is 35 minutes old (AWS-CW-02).",
      curated: "A two-day-old datapoint could not come back from an hour's query; the stale datapoint now sits inside the queried hour.",
      calls: [metrics("2026-11-03T00:20:00Z", [0.98, 0.97], 35)],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "METRIC_WINDOW_STALE"]] },
  ] };

const CATALOG = [{ ...RUNBOOK, action: "start-ec2", eligibleStates: ["stopped"], requiresApproval: true, admitted: true }];
const describeRunbook = call("ssm:DescribeDocument", { Name: RUNBOOK.documentName, DocumentVersion: RUNBOOK.documentVersion },
  ok({ Document: { Name: RUNBOOK.documentName, Owner: "Amazon", DocumentVersion: RUNBOOK.documentVersion, Status: "Active", DocumentType: "Automation",
    Parameters: [{ Name: "InstanceId" }, { Name: "Approvers" }, { Name: "SNSTopicArn" }, { Name: "AutomationAssumeRole" }] } }));
FEATURES["sfx-aws-select-recovery-option"] = { sources: ["AWS-SSM-02", "AWS-SSM-06", "AWS-EC2-02", "AWS-IAM-01"], awsCalls: "ssm:DescribeDocument",
  base: { clock: "2026-11-03T00:20:00Z", sidefx: { admittedAccounts: [A], catalog: CATALOG } },
  cases: [
    { id: "aws-option-stopped-ec2", title: "A stopped EC2 instance matches a start-with-approval option",
      aws: "AWS-StartEC2InstanceWithApproval is an AWS-owned runbook taking InstanceId, Approvers and SNSTopicArn (AWS-SSM-02).",
      curated: "The admitted option pins the runbook version, and the runbook's existence is read back. Version 1 is synthetic: read it from DescribeDocument in the sandbox account.",
      request: { ...target, resourceState: "stopped" }, calls: [describeRunbook],
      then: [["$.status", "SELECTED"], ["$.option.documentName", RUNBOOK.documentName], ["$.option.documentVersion", "1"],
        ["$.option.requiresApproval", "true"], ["$.option.parameters.InstanceId", I]] },
    { id: "aws-option-running", title: "A running EC2 instance is not started again",
      aws: "running is a documented instance state (AWS-EC2-01).",
      request: { ...target, resourceState: "running" }, calls: [],
      then: [["$.status", "NO_ACTION"], ["$.reason", "NO_ELIGIBLE_ACTION"]] },
    { id: "aws-option-no-runbook", title: "An impaired instance with no admitted runbook gets no speculative command",
      aws: "impaired is a documented status-check value (AWS-EC2-02); AWS-RestartEC2Instance exists (AWS-SSM-06) but is not admitted here.",
      curated: "'degraded-unknown' is not an EC2 state; the instance is running with an impaired status check, which no admitted runbook addresses.",
      request: { ...target, resourceState: "running", statusChecks: "impaired" }, calls: [],
      then: [["$.status", "NO_ACTION"], ["$.reason", "NO_ELIGIBLE_ACTION"], ["$.option", "(absent)"]] },
    { id: "aws-option-unapproved", title: "An unapproved custom runbook is ineligible",
      aws: "Any account can own a custom Automation document (AWS-SSM-01 DocumentName); owning one is not admission.",
      request: { ...target, resourceState: "stopped" },
      sidefx: { catalog: [{ documentName: "local-FixEverything", documentVersion: "3", action: "fix", eligibleStates: ["stopped"], requiresApproval: false, admitted: false }] }, calls: [],
      then: [["$.status", "NO_ACTION"], ["$.reason", "RUNBOOK_NOT_ADMITTED"]] },
    { id: "aws-option-other-account", title: "An action is not selected for an unapproved account",
      aws: "None: account admission is SideFX's.",
      curated: "The request's account and resource ARN now agree (both 999988887777).",
      request: { accountId: F, region: R, serviceId: SVC, resourceArn: `arn:aws:ec2:${R}:${F}:instance/${I}`, resourceState: "stopped" }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "TARGET_NOT_IN_ALLOWED_SCOPE"]] },
    { id: "aws-option-no-context", title: "A missing current state cannot be interpreted as stopped",
      aws: "None: there is no state to match against the catalog.",
      request: { ...target, resourceState: null }, calls: [],
      then: [["$.status", "NO_ACTION"], ["$.reason", "CURRENT_STATE_NOT_OBSERVABLE"]] },
  ] };

const APPROVAL = (id, fields) => ({ id, action: "start-ec2", scope: ARN, ...RUNBOOK, by: "ops-manager", requestedBy: "ops-lead", state: "approved",
  expiresAt: "2026-11-03T04:00:00Z", ...fields });
const OPERATOR = { subject: "ops-lead", grants: ["remediate:start-ec2"] };
FEATURES["sfx-aws-authorize-remediation"] = { sources: ["AWS-IAM-01", "AWS-SSM-02", "AWS-SSM-04"], awsCalls: "none: authorization is SideFX's; the runbook's own aws:approve step is a second, AWS-side check observed later",
  base: { clock: "2026-11-03T00:20:00Z", request: { ...target, action: "start-ec2", ...RUNBOOK },
    sidefx: { operator: OPERATOR, policy: "allows-start-after-independent-approval", approvals: [] } },
  cases: [
    { id: "aws-auth-approved", title: "A scoped, independent approval authorizes the named action",
      aws: "None.", curated: "The approval binds the runbook name and version as well as the action and target.",
      request: { ...target, action: "start-ec2", ...RUNBOOK, approvalId: "apr-001" }, sidefx: { approvals: [APPROVAL("apr-001")] }, calls: [],
      then: [["$.status", "AUTHORIZED"], ["$.authorizedAction", "start-ec2"], ["$.target.resourceArn", ARN], ["$.approval.id", "apr-001"],
        ["$.approval.approver", "ops-manager"]] },
    { id: "aws-auth-pending", title: "Approval not yet recorded leaves the effect pending",
      aws: "None.", calls: [], sidefx: { operator: { subject: "oncall", grants: ["remediate:start-ec2"] } },
      then: [["$.status", "PENDING_APPROVAL"], ["$.writeAllowed", "false"], ["$.reason", "APPROVAL_REQUIRED"]] },
    { id: "aws-auth-denied", title: "A denied approval cannot become an authorized effect",
      aws: "None.", request: { ...target, action: "start-ec2", ...RUNBOOK, approvalId: "apr-002" },
      sidefx: { approvals: [APPROVAL("apr-002", { state: "denied" })] }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "APPROVAL_DENIED"], ["$.writeAllowed", "false"]] },
    { id: "aws-auth-wrong-target", title: "An approval for another resource does not transfer",
      aws: "None.", request: { ...target, action: "start-ec2", ...RUNBOOK, approvalId: "apr-003" },
      sidefx: { approvals: [APPROVAL("apr-003", { scope: `arn:aws:ec2:${R}:${A}:instance/${OTHER_I}` })] }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "APPROVAL_SCOPE_MISMATCH"]] },
    { id: "aws-auth-least-privilege", title: "A read-only operator cannot authorize the write",
      aws: "None.", request: { ...target, action: "start-ec2", ...RUNBOOK, approvalId: "apr-004" },
      sidefx: { operator: { subject: "viewer", grants: ["read"] }, approvals: [APPROVAL("apr-004", { requestedBy: "viewer" })] }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "OPERATOR_NOT_AUTHORIZED"]] },
    { id: "aws-auth-stale", title: "An expired approval is not silently refreshed",
      aws: "None.", request: { ...target, action: "start-ec2", ...RUNBOOK, approvalId: "apr-005" },
      sidefx: { approvals: [APPROVAL("apr-005", { expiresAt: "2026-10-01T00:00:00Z" })] }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "APPROVAL_EXPIRED"]] },
    { id: "aws-auth-proposal-only", title: "An AI-generated plan has no inherent cloud permission",
      aws: "None.", request: { ...target, action: "start-ec2", ...RUNBOOK, proposalId: "model-plan-001" }, calls: [],
      then: [["$.status", "PENDING_APPROVAL"], ["$.writeAllowed", "false"], ["$.reason", "APPROVAL_REQUIRED"]] },
    { id: "aws-auth-self-approval", title: "An operator cannot approve their own effect",
      aws: "None: independence is decision D05; the runbook's aws:approve approvers are a separate AWS-side list (AWS-SSM-04).",
      curated: "Added: D05 asks for an independent approval and no candidate case tested independence.",
      request: { ...target, action: "start-ec2", ...RUNBOOK, approvalId: "apr-006" },
      sidefx: { approvals: [APPROVAL("apr-006", { by: "ops-lead" })] }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "APPROVER_NOT_INDEPENDENT"], ["$.writeAllowed", "false"]] },
  ] };

const EFFECT = { approvalId: "apr-001", action: "start-ec2", target: ARN, ...RUNBOOK, approvers: [APPROVER], snsTopicArn: TOPIC, automationAssumeRole: AUTOMATION_ROLE };
const start = (token, outcome) => call("ssm:StartAutomationExecution", { DocumentName: RUNBOOK.documentName, DocumentVersion: RUNBOOK.documentVersion,
  Parameters: RUN_PARAMETERS, ClientToken: token }, outcome);
FEATURES["sfx-aws-dispatch-approved-automation"] = { sources: ["AWS-SSM-01", "AWS-SSM-02", "AWS-SSM-03", "AWS-SSM-04", "AWS-SSM-06"],
  awsCalls: "ssm:StartAutomationExecution, ssm:GetAutomationExecution",
  base: { clock: "2026-11-03T00:21:00Z", request: { ...target, approvalId: "apr-001", ...RUNBOOK },
    sidefx: { authorizedEffects: [EFFECT], dispatchRole: `arn:aws:iam::${A}:role/sidefx-cloudops-dispatch`, priorDispatches: [] } },
  cases: [
    { id: "aws-dispatch-start", title: "An authorized runbook is started once and returns an execution ID",
      aws: "StartAutomationExecution answers only a 36-character AutomationExecutionId; the runbook's aws:approve step then holds the execution in Waiting (AWS-SSM-01, AWS-SSM-04).",
      curated: "ClientToken and execution id are UUIDs as the API requires; the status read back is Waiting, not the undocumented WaitingForApproval.",
      request: { ...target, approvalId: "apr-001", ...RUNBOOK, clientToken: TOKEN(1) },
      calls: [start(TOKEN(1), ok(aws.automationStarted(EXECUTION))), execution("Waiting", { currentAction: "aws:approve" })],
      then: [["$.status", "DISPATCHED"], ["$.automation.documentName", RUNBOOK.documentName], ["$.automation.executionId", EXECUTION],
        ["$.automation.status", "Waiting"], ["$.effect.completed", "false"]] },
    { id: "aws-dispatch-retry", title: "A repeated token does not create a second automation execution",
      aws: "A ClientToken can't be reused for another request; resending other parameters under it fails with IdempotentParameterMismatch (AWS-SSM-01).",
      curated: "SideFX answers from its own dispatch record and makes no second call.",
      request: { ...target, approvalId: "apr-001", ...RUNBOOK, clientToken: TOKEN(1) },
      sidefx: { priorDispatches: [{ clientToken: TOKEN(1), automationExecutionId: EXECUTION }] }, calls: [],
      then: [["$.status", "DISPATCHED"], ["$.automation.executionId", EXECUTION], ["$.automation.newDispatch", "false"]] },
    { id: "aws-dispatch-no-approval", title: "Without an approved effect identity no write is dispatched",
      aws: "None.", request: { ...target, ...RUNBOOK, clientToken: TOKEN(2) }, sidefx: { authorizedEffects: [] }, calls: [],
      then: [["$.status", "NOT_DISPATCHED"], ["$.reason", "EFFECT_NOT_AUTHORIZED"], ["$.writeAttempted", "false"]] },
    { id: "aws-dispatch-wrong-runbook", title: "The runbook cannot be substituted between approval and use",
      aws: "AWS-StopEC2Instance is a documented AWS runbook (AWS-SSM-06).",
      curated: "AWS-StopEC2InstanceWithApproval is not on the AWS runbook pages read; the substitute is the documented AWS-StopEC2Instance.",
      request: { ...target, approvalId: "apr-001", documentName: "AWS-StopEC2Instance", documentVersion: "1", clientToken: TOKEN(3) }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "RUNBOOK_BINDING_MISMATCH"], ["$.writeAttempted", "false"]] },
    { id: "aws-dispatch-failure", title: "An AWS API failure is reported as not dispatched",
      aws: "A caller without ssm:StartAutomationExecution gets AccessDeniedException.",
      request: { ...target, approvalId: "apr-001", ...RUNBOOK, clientToken: TOKEN(4) },
      calls: [start(TOKEN(4), fails("AccessDeniedException", 400, `User: arn:aws:sts::${A}:assumed-role/sidefx-cloudops-dispatch/sidefx is not authorized to perform: ssm:StartAutomationExecution`))],
      then: [["$.status", "NOT_DISPATCHED"], ["$.reason", "AWS_DISPATCH_FAILED"], ["$.automation", "(absent)"], ["$.error.code", "AccessDeniedException"]] },
    { id: "aws-dispatch-unknown", title: "An ambiguous timeout is reconciled before any retry write",
      aws: "A retry under the same ClientToken is the API's own idempotency (AWS-SSM-01); this case holds instead of retrying (decision A4 in CURATION.md).",
      request: { ...target, approvalId: "apr-001", ...RUNBOOK, clientToken: TOKEN(5) },
      calls: [start(TOKEN(5), { noResponse: "client timed out after 30 seconds" })],
      then: [["$.status", "NOT_DISPATCHED"], ["$.reason", "DISPATCH_CONFIRMATION_UNKNOWN"], ["$.writeRetried", "false"]] },
  ] };

const VERIFY_CLOCK = "2026-11-03T00:40:00Z";
const verifyMetrics = (values, newestMinutesAgo = 1) => metrics(VERIFY_CLOCK, values, newestMinutesAgo);
FEATURES["sfx-aws-verify-service-recovery"] = { sources: ["AWS-SSM-03", "AWS-SSM-04", "AWS-EC2-01", "AWS-EC2-02", "AWS-CW-02", "AWS-SLO-01"],
  awsCalls: "ssm:GetAutomationExecution, ec2:DescribeInstanceStatus, cloudwatch:GetMetricData",
  base: { clock: VERIFY_CLOCK, request: { ...target, automationExecutionId: EXECUTION },
    sidefx: { serviceBinding: BINDING, objective: OBJECTIVE, maxMetricAgeMinutes: 10 } },
  cases: [
    { id: "aws-verify-restored", title: "Successful automation plus healthy post-state confirms recovery",
      aws: "Success is terminal; both status checks ok is the EC2 health proof; the heartbeat meets the objective (AWS-SSM-03, AWS-EC2-02, AWS-CW-02).",
      curated: "Recovery also needs both EC2 status checks ok, not only the running state.",
      calls: [execution("Success", { end: "2026-11-03T00:31:00Z" }), instanceChecks("running", "ok", "ok"), verifyMetrics([1, 1, 1, 1, 1])],
      then: [["$.status", "RESTORED"], ["$.serviceState", "HEALTHY"], ["$.evidence.automationStatus", "Success"], ["$.evidence.ec2State", "running"],
        ["$.evidence.statusChecks", "ok"], ["$.verified", "true"]] },
    { id: "aws-verify-ssm-only", title: "A successful runbook with no healthy service evidence is not recovery",
      aws: "GetMetricData can complete with no datapoints in the window (AWS-CW-02).",
      calls: [execution("Success", { end: "2026-11-03T00:31:00Z" }), instanceChecks("running", "ok", "ok"), verifyMetrics([])],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "POST_ACTION_HEALTH_EVIDENCE_MISSING"], ["$.verified", "false"]] },
    { id: "aws-verify-still-bad", title: "Persistent alarm proves not restored",
      aws: "As in the restored case, with the heartbeat below the objective (AWS-CW-02).",
      calls: [execution("Success", { end: "2026-11-03T00:31:00Z" }), instanceChecks("running", "ok", "ok"), verifyMetrics([0.2, 0.4, 0.5, 0.3, 0.4])],
      then: [["$.status", "NOT_RESTORED"], ["$.serviceState", "DEGRADED"], ["$.verified", "false"]] },
    { id: "aws-verify-not-complete", title: "A runbook waiting for approval is not completed",
      aws: "While its aws:approve step waits, the execution reads Waiting (AWS-SSM-03, AWS-SSM-04).",
      curated: "WaitingForApproval is not an AutomationExecutionStatus value; the documented value is Waiting.",
      calls: [execution("Waiting", { currentAction: "aws:approve" })],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "AUTOMATION_NOT_TERMINAL"]] },
    { id: "aws-verify-wrong-service", title: "A healthy metric for another service is not success",
      aws: "The metric is selected by its dimensions (AWS-CW-02).",
      curated: "The mismatch is in the post-action binding, refused before the metric is read.",
      sidefx: { serviceBinding: { ...BINDING, dimensions: { ServiceId: "other-app" } } }, calls: [execution("Success", { end: "2026-11-03T00:31:00Z" })],
      then: [["$.status", "REFUSED"], ["$.reason", "POST_ACTION_EVIDENCE_SCOPE_MISMATCH"]] },
    { id: "aws-verify-failed-runbook", title: "A failed runbook is not recovery even if some metric recovers",
      aws: "Failed carries a FailureMessage; a stopped instance reports its status checks as not-applicable (AWS-SSM-03, AWS-EC2-02).",
      calls: [execution("Failed", { end: "2026-11-03T00:24:00Z", failureMessage: "Step fails when it is changing the state of the instance." }),
        instanceChecks("stopped", "not-applicable", "not-applicable"), verifyMetrics([0, 0, 0])],
      then: [["$.status", "NOT_RESTORED"], ["$.evidence.automationStatus", "Failed"], ["$.verified", "false"]] },
    { id: "aws-verify-stale", title: "Old metric data is insufficient for a fresh recovery claim",
      aws: "Over the last hour the newest datapoint is 25 minutes old (AWS-CW-02).",
      curated: "A 120-minute-old datapoint could not come back from an hour's query; the stale datapoint now sits inside the queried hour.",
      calls: [execution("Success", { end: "2026-11-03T00:31:00Z" }), instanceChecks("running", "ok", "ok"), verifyMetrics([1, 1, 1], 25)],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "POST_ACTION_METRICS_STALE"]] },
    { id: "aws-verify-checks-initializing", title: "A started instance whose status checks are still initializing is not yet recovered",
      aws: "Right after a start the instance and system checks read initializing (AWS-EC2-02).",
      curated: "Added: a running state with checks still initializing is the commonest moment right after a start.",
      calls: [execution("Success", { end: "2026-11-03T00:31:00Z" }), instanceChecks("running", "initializing", "initializing"), verifyMetrics([1, 1])],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "RECOVERY_CHECKS_INITIALIZING"], ["$.verified", "false"]] },
  ] };

const COMPONENTS = { signal: "aws-signal-alarm", context: "aws-context-ec2", change: "aws-change-stop", impact: "aws-impact-degraded",
  option: "aws-option-stopped-ec2", authorization: "aws-auth-approved", dispatch: "aws-dispatch-start", verify: "aws-verify-restored" };
FEATURES["sfx-aws-resolve-service-incident"] = { sources: ["AWS-CW-01", "AWS-EVB-03", "AWS-CONFIG-02", "AWS-CT-02", "AWS-SSM-01", "AWS-SSM-04", "AWS-SSM-05", "AWS-EC2-02", "AWS-IAM-02"],
  awsCalls: "none of its own: each component circuit makes its calls; the root composes their arrangements by case id",
  base: { clock: VERIFY_CLOCK, request: { ...target, incidentId: "inc-001", signalId: E.alarm }, sidefx: { admittedAccounts: [A], components: COMPONENTS } },
  cases: [
    { id: "aws-incident-end-to-end", title: "A stopped instance is restarted after approval and proven healthy",
      aws: "Between dispatch (Waiting) and verification (Success) the ops-manager role approves with SendAutomationSignal Approve (AWS-SSM-04, AWS-SSM-05).",
      curated: "The arrangement composes the component cases instead of opaque labels, so root and components cannot drift apart.",
      sidefx: { nativeApproval: { signalType: "Approve", by: APPROVER, automationExecutionId: EXECUTION } }, calls: [],
      then: [["$.status", "RESTORED"], ["$.incidentId", "inc-001"], ["$.serviceState", "HEALTHY"], ["$.evidence.recoveryVerified", "true"],
        ["$.evidence.automationExecutionId", EXECUTION]] },
    { id: "aws-incident-denied", title: "An approval denial safely escalates without running recovery",
      aws: "None beyond the components.", request: { ...target, incidentId: "inc-002", signalId: E.alarm },
      sidefx: { components: { ...COMPONENTS, authorization: "aws-auth-denied", dispatch: null, verify: null } }, calls: [],
      then: [["$.status", "ESCALATED"], ["$.reason", "REMEDIATION_NOT_APPROVED"], ["$.effects.executed", "0"]] },
    { id: "aws-incident-no-evidence", title: "A missing current-state read holds recovery and the incident remains unresolved",
      aws: "The read role was denied (AWS-IAM-02).", request: { ...target, incidentId: "inc-003", signalId: E.alarm },
      sidefx: { components: { ...COMPONENTS, context: "aws-context-unauthorized", option: null, authorization: null, dispatch: null, verify: null } }, calls: [],
      then: [["$.status", "HELD"], ["$.reason", "RESOURCE_CONTEXT_INCOMPLETE"], ["$.effects.executed", "0"]] },
    { id: "aws-incident-ssm-failed", title: "A failed runbook does not close the incident as restored",
      aws: "The execution ended Failed (AWS-SSM-03).", request: { ...target, incidentId: "inc-004", signalId: E.alarm },
      sidefx: { components: { ...COMPONENTS, verify: "aws-verify-failed-runbook" } }, calls: [],
      then: [["$.status", "ESCALATED"], ["$.reason", "RECOVERY_NOT_VERIFIED"], ["$.evidence.recoveryVerified", "false"]] },
    { id: "aws-incident-metric-gap", title: "Successful runbook with unavailable metrics retains a held outcome",
      aws: "The heartbeat window had no datapoints (AWS-CW-02).", request: { ...target, incidentId: "inc-005", signalId: E.alarm },
      sidefx: { components: { ...COMPONENTS, verify: "aws-verify-ssm-only" } }, calls: [],
      then: [["$.status", "HELD"], ["$.reason", "RECOVERY_NOT_OBSERVABLE"], ["$.evidence.recoveryVerified", "false"]] },
    { id: "aws-incident-replayed", title: "A replayed event cannot duplicate remediation",
      aws: "EventBridge can deliver an event again (AWS-EVB-01); the dispatch answers from its record (AWS-SSM-01).",
      sidefx: { components: { ...COMPONENTS, signal: "aws-signal-repeat", dispatch: "aws-dispatch-retry" } }, calls: [],
      then: [["$.status", "RESTORED"], ["$.incidentId", "inc-001"], ["$.effects.newExecutions", "0"]] },
    { id: "aws-incident-foreign", title: "A foreign-account signal is rejected at intake",
      aws: "The event's account is 999988887777 (AWS-CW-01).", curated: "The request's account and resource ARN now agree.",
      request: { accountId: F, region: R, serviceId: SVC, resourceArn: `arn:aws:ec2:${R}:${F}:instance/${I}`, incidentId: "inc-006", signalId: E.other },
      sidefx: { components: { signal: "aws-signal-other-account" } }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "ACCOUNT_NOT_ADMITTED"], ["$.effects.executed", "0"]] },
    { id: "aws-incident-no-option", title: "An impaired instance with no admitted runbook escalates for manual diagnosis",
      aws: "The status checks read impaired (AWS-EC2-02).", request: { ...target, incidentId: "inc-007", signalId: E.alarm },
      sidefx: { components: { ...COMPONENTS, option: "aws-option-no-runbook", authorization: null, dispatch: null, verify: null } }, calls: [],
      then: [["$.status", "ESCALATED"], ["$.reason", "NO_ADMITTED_RECOVERY_ACTION"], ["$.effects.executed", "0"]] },
  ] };

const POLICY = { id: "production-required-tags.v1", admitted: true, requiredTags: ["environment", "owner"] };
FEATURES["sfx-aws-assess-configuration-drift"] = { sources: ["AWS-CONFIG-01", "AWS-CONFIG-02", "AWS-CONFIG-03", "AWS-CFN-01", "AWS-CFN-02", "AWS-IAM-02"],
  awsCalls: "sts:AssumeRole, config:GetAggregateResourceConfig, cloudformation:DescribeChangeSet",
  base: { clock: "2026-11-03T00:20:00Z", request: { ...target, policyId: POLICY.id }, sidefx: { policies: [POLICY, { id: "production-required-tags.v0", admitted: false }] } },
  cases: [
    { id: "aws-drift-tag", title: "A missing required ownership tag is reported precisely",
      aws: "Tags come from the configuration item (AWS-CONFIG-03).",
      calls: [assumeRead("sidefx-drift"), configRead(ci({ tags: { environment: "production", service: SVC } }))],
      then: [["$.status", "DRIFT_DETECTED"], ["$.findings[0].code", "REQUIRED_TAG_ABSENT"], ["$.findings[0].field", "tags.owner"]] },
    { id: "aws-drift-conforms", title: "A resource satisfying its observed policy has no drift",
      aws: "As above (AWS-CONFIG-03).",
      calls: [assumeRead("sidefx-drift"), configRead(ci({ tags: { environment: "production", owner: "operations", service: SVC } }))],
      then: [["$.status", "NO_DRIFT"], ["$.findings", "[]"]] },
    { id: "aws-drift-not-recorded", title: "A resource missing from Config coverage is not reported compliant",
      aws: "ResourceNotDiscoveredException for a resource Config has not discovered (AWS-CONFIG-02).",
      calls: [assumeRead("sidefx-drift"), configRead(fails("ResourceNotDiscoveredException", 400, `Resource ${I} of resourceType:AWS::EC2::Instance is unknown or has not been discovered`))],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "CONFIG_COVERAGE_MISSING"]] },
    { id: "aws-drift-wrong-version", title: "A stale policy revision is not silently replaced",
      aws: "None: policy admission is SideFX's.", request: { ...target, policyId: "production-required-tags.v0" }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "POLICY_REVISION_NOT_ADMITTED"]] },
    { id: "aws-drift-unapproved-change", title: "A change set not yet executed is a proposed change, not observed drift",
      aws: "A change set at Status CREATE_COMPLETE with ExecutionStatus AVAILABLE has not been applied (AWS-CFN-01, AWS-CFN-02).",
      curated: "The candidate's 'executed: false' is the documented ExecutionStatus AVAILABLE; the stack comes from CloudFormation's own aws:cloudformation:stack-name tag.",
      sidefx: { pendingChangeSets: [{ stackName: "citizen-portal", changeSetName: "citizen-portal-tags-update" }] },
      calls: [assumeRead("sidefx-drift"), configRead(ci({ tags: { environment: "production", owner: "operations", service: SVC, "aws:cloudformation:stack-name": "citizen-portal" } })),
        call("cloudformation:DescribeChangeSet", { StackName: "citizen-portal", ChangeSetName: "citizen-portal-tags-update" },
          ok(aws.changeSet({ account: A, region: R, stack: "citizen-portal", name: "citizen-portal-tags-update", status: "CREATE_COMPLETE", executionStatus: "AVAILABLE", instanceId: I })))],
      then: [["$.status", "NO_DRIFT"], ["$.findings", "[]"], ["$.pendingChanges", "1"]] },
    { id: "aws-drift-cross-account", title: "No read access to the account is not a green posture",
      aws: "STS answers AccessDenied (AWS-IAM-02).", calls: [assumeDenied("sidefx-drift")],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "ACCOUNT_READ_UNAVAILABLE"]] },
  ] };

const cost = (start, end, outcome) => call("ce:GetCostAndUsage", { TimePeriod: { Start: start, End: end }, Granularity: "MONTHLY", Metrics: ["UnblendedCost"],
  Filter: { Dimensions: { Key: "LINKED_ACCOUNT", Values: [A] } }, GroupBy: [{ Type: "TAG", Key: "service" }] }, outcome);
const months = (sep, oct, estimated = false) => aws.costAndUsage([{ start: "2026-09-01", end: "2026-10-01", groups: sep, estimated: false },
  { start: "2026-10-01", end: "2026-11-01", groups: oct, estimated }]);
const COST_REQUEST = { accountId: A, serviceId: SVC, period: "2026-10", baselinePeriod: "2026-09" };
FEATURES["sfx-aws-assess-cost-variance"] = { sources: ["AWS-CE-01", "AWS-CE-02"], awsCalls: "ce:GetCostAndUsage",
  base: { clock: "2026-11-03T00:20:00Z", request: COST_REQUEST,
    sidefx: { admittedAccounts: [A], costAllocationTag: { key: "service", activated: true }, varianceRule: { materialPercent: 5, currency: "USD" } } },
  cases: [
    { id: "aws-cost-rise", title: "An observed monthly cost increase is attributed to the requested service",
      aws: "Amounts come back as strings with Unit USD, grouped as service$citizen-portal; End is exclusive (AWS-CE-02).",
      curated: "Cost is attributed by the activated cost-allocation tag, so the request drops the instance ARN and Region; Cost Explorer is one global endpoint.",
      calls: [cost("2026-09-01", "2026-11-01", ok(months({ [SVC]: "1000.00" }, { [SVC]: "1200.00" })))],
      then: [["$.status", "VARIANCE_OBSERVED"], ["$.variance.currency", "USD"], ["$.variance.delta", "200.0"], ["$.variance.percent", "20.0"]] },
    { id: "aws-cost-flat", title: "No material spend change yields no variance",
      aws: "As above (AWS-CE-02).", calls: [cost("2026-09-01", "2026-11-01", ok(months({ [SVC]: "1000.00" }, { [SVC]: "1000.00" })))],
      then: [["$.status", "NO_VARIANCE"], ["$.variance.delta", "0.0"]] },
    { id: "aws-cost-lag", title: "Incomplete recent billing data is not called a complete monthly result",
      aws: "Estimated true marks a period whose costs are not final (AWS-CE-02).",
      curated: "The candidate's 'complete: false' is the documented Estimated flag.",
      request: { ...COST_REQUEST, period: "2026-11", baselinePeriod: "2026-10" },
      calls: [cost("2026-10-01", "2026-12-01", ok(aws.costAndUsage([{ start: "2026-10-01", end: "2026-11-01", groups: { [SVC]: "1200.00" }, estimated: false },
        { start: "2026-11-01", end: "2026-12-01", groups: { [SVC]: "96.40" }, estimated: true }])))],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "BILLING_PERIOD_INCOMPLETE"]] },
    { id: "aws-cost-cross-account", title: "A non-entitled account is not charged to the wrong team",
      aws: "None: billing scope is SideFX's.", request: { ...COST_REQUEST, accountId: F }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "BILLING_SCOPE_NOT_ADMITTED"]] },
    { id: "aws-cost-denied", title: "Cost Explorer permission denial is an observation limitation",
      aws: "A caller without ce:GetCostAndUsage gets AccessDeniedException.",
      calls: [cost("2026-09-01", "2026-11-01", fails("AccessDeniedException", 400, `User: arn:aws:sts::${A}:assumed-role/sidefx-cloudops-read/sidefx-cost is not authorized to perform: ce:GetCostAndUsage`))],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "COST_READ_DENIED"]] },
    { id: "aws-cost-missing-tags", title: "Absent cost-allocation tags prevent invented service attribution",
      aws: "Spend without the tag lands in the group service$ (AWS-CE-02).",
      calls: [cost("2026-09-01", "2026-11-01", ok(months({ "": "1000.00" }, { "": "1200.00" })))],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "COST_ATTRIBUTION_MISSING"]] },
  ] };

const HOURLY = ["2026-11-02T22:00:00Z", "2026-11-02T23:00:00Z", "2026-11-03T00:00:00Z"];
const pointsRead = call("backup:ListRecoveryPointsByResource", { ResourceArn: ARN }, ok(aws.recoveryPoints({ account: A, region: R, created: HOURLY })));
const jobsRead = (jobs) => call("backup:ListRestoreJobsByProtectedResource", { ResourceArn: ARN }, ok(aws.restoreJobs(jobs)));
const testJob = (fields) => ({ account: A, region: R, id: uuid(`restore-job:${fields.started}`), recoveryPoint: `arn:aws:ec2:${R}::image/ami-${sha("2026-10-28T00:00:00Z").slice(0, 17)}`,
  recoveryPointCreated: "2026-10-28T00:00:00Z", source: ARN, created: `arn:aws:ec2:${R}:${A}:instance/i-0a1b2c3d4e5f60718`, status: "COMPLETED",
  validation: "SUCCESSFUL", deletion: "SUCCESSFUL", planSuffix: "8f3d2c1b-4a5e-4f60-9b7c-1d2e3f405162", ...fields });
const OBJ = { rtoMinutes: 60, rpoMinutes: 60 };
FEATURES["sfx-aws-evaluate-recovery-readiness"] = { sources: ["AWS-BKP-01", "AWS-BKP-02", "AWS-BKP-03"],
  awsCalls: "backup:ListRecoveryPointsByResource, backup:ListRestoreJobsByProtectedResource, backup:DescribeRestoreJob",
  base: { clock: "2026-11-03T00:20:00Z", request: { ...target, workloadId: SVC, objective: OBJ }, sidefx: { maxProofAgeDays: 90 } },
  cases: [
    { id: "aws-dr-proven", title: "A fresh successful restore test satisfies the declared RTO and RPO",
      aws: "A restore-testing job reports its CreationDate, CompletionDate and ValidationStatus (AWS-BKP-01, AWS-BKP-02).",
      curated: "The drill is an AWS Backup restore-testing job. The RPO objective is 60 minutes, not 15: EC2 has no continuous backup (AWS-BKP-03), so hourly snapshots bound it.",
      calls: [pointsRead, jobsRead([testJob({ started: "2026-10-28T03:00:00Z", completed: "2026-10-28T03:42:00Z" })])],
      then: [["$.status", "READY"], ["$.readiness.restoreExerciseVerified", "true"], ["$.readiness.withinRto", "true"], ["$.readiness.withinRpo", "true"],
        ["$.readiness.measuredRtoMinutes", "42"]] },
    { id: "aws-dr-backup-only", title: "Successful backups without a restore test do not prove ready",
      aws: "Recovery points exist and no restore job ran (AWS-BKP-02).", calls: [pointsRead, jobsRead([])],
      then: [["$.status", "NOT_READY"], ["$.reason", "RESTORE_EXERCISE_NOT_PROVEN"]] },
    { id: "aws-dr-rto", title: "Measured restore time outside RTO is not ready",
      aws: "The restore job took 90 minutes from CreationDate to CompletionDate (AWS-BKP-02).",
      calls: [pointsRead, jobsRead([testJob({ started: "2026-10-28T03:00:00Z", completed: "2026-10-28T04:30:00Z" })])],
      then: [["$.status", "NOT_READY"], ["$.readiness.withinRto", "false"], ["$.readiness.measuredRtoMinutes", "90"]] },
    { id: "aws-dr-no-objective", title: "No declared recovery objective means readiness cannot be judged",
      aws: "None: the objective is SideFX's.", request: { ...target, workloadId: SVC, objective: null }, calls: [],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "RECOVERY_OBJECTIVE_UNDECLARED"]] },
    { id: "aws-dr-stale-proof", title: "An out-of-date restore test is not current proof",
      aws: "The newest restore job completed in January 2025 (AWS-BKP-02).",
      calls: [pointsRead, jobsRead([testJob({ started: "2025-01-01T03:00:00Z", completed: "2025-01-01T03:40:00Z", recoveryPointCreated: "2024-12-31T23:00:00Z" })])],
      then: [["$.status", "NOT_READY"], ["$.reason", "EXERCISE_EVIDENCE_STALE"]] },
    { id: "aws-dr-foreign", title: "Another workload's proof does not transfer",
      aws: "A restore job names its SourceResourceArn (AWS-BKP-02).",
      curated: "Listing by resource can only return this resource's jobs, so the foreign proof is now a cited job read back with DescribeRestoreJob.",
      request: { ...target, workloadId: SVC, objective: OBJ, proofRestoreJobId: uuid("restore-job:other-app") },
      calls: [call("backup:DescribeRestoreJob", { RestoreJobId: uuid("restore-job:other-app") },
        ok(aws.restoreJobs([testJob({ id: uuid("restore-job:other-app"), started: "2026-10-29T03:00:00Z", completed: "2026-10-29T03:30:00Z",
          source: `arn:aws:ec2:${R}:${A}:instance/${OTHER_I}` })]).RestoreJobs[0]))],
      then: [["$.status", "REFUSED"], ["$.reason", "RECOVERY_EVIDENCE_SCOPE_MISMATCH"]] },
  ] };

const DOMAINS = { reliability: "aws-impact-normal", security: "aws-sec-high", cost: "aws-cost-rise", recovery: "aws-dr-proven" };
FEATURES["sfx-aws-report-operating-posture"] = { sources: ["AWS-CW-02", "AWS-SH-01", "AWS-CE-02", "AWS-BKP-01"],
  awsCalls: "none of its own: each domain is a component circuit's outcome, composed by case id",
  base: { clock: "2026-11-03T00:20:00Z", request: { ...target, reportPeriod: "2026-10" }, sidefx: { admittedAccounts: [A], maxSnapshotAgeDays: 31, components: DOMAINS } },
  cases: [
    { id: "aws-posture-complete", title: "A complete review covers reliability, security, cost and recovery",
      aws: "None beyond the components.", curated: "Each domain names the component case it rests on instead of an opaque 'observed'.", calls: [],
      then: [["$.status", "REPORTED"], ["$.coverage.reliability", "OBSERVED"], ["$.coverage.security", "OBSERVED"], ["$.coverage.cost", "OBSERVED"],
        ["$.coverage.recovery", "OBSERVED"]] },
    { id: "aws-posture-no-cost", title: "Missing cost data leaves the report incomplete but still reviewable",
      aws: "The cost read was denied (component aws-cost-denied).", sidefx: { components: { ...DOMAINS, cost: "aws-cost-denied" } }, calls: [],
      then: [["$.status", "INCOMPLETE"], ["$.coverage.cost", "NOT_OBSERVABLE"], ["$.missingDomains", "[\"cost\"]"]] },
    { id: "aws-posture-no-health", title: "Missing health data cannot be reported as zero incidents",
      aws: "The heartbeat had no data (component aws-impact-insufficient).", sidefx: { components: { ...DOMAINS, reliability: "aws-impact-insufficient" } }, calls: [],
      then: [["$.status", "INCOMPLETE"], ["$.coverage.reliability", "NOT_OBSERVABLE"]] },
    { id: "aws-posture-account", title: "An unauthorized account is refused",
      aws: "None.", request: { accountId: F, region: R, serviceId: SVC, resourceArn: `arn:aws:ec2:${R}:${F}:instance/${I}`, reportPeriod: "2026-10" }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "ACCOUNT_NOT_ADMITTED"]] },
    { id: "aws-posture-stale", title: "A stale security snapshot is not treated as current",
      aws: "None beyond the components.", sidefx: { components: { ...DOMAINS, security: { case: "aws-sec-high", asOf: "2026-08-01T00:00:00Z" } } }, calls: [],
      then: [["$.status", "INCOMPLETE"], ["$.coverage.security", "STALE"]] },
    { id: "aws-posture-no-rto", title: "No declared recovery objective is visible as an operational gap",
      aws: "None beyond the components.", sidefx: { components: { ...DOMAINS, recovery: "aws-dr-no-objective" } }, calls: [],
      then: [["$.status", "INCOMPLETE"], ["$.coverage.recovery", "NOT_OBSERVABLE"]] },
  ] };

const FINDING = (n) => `${uuid(`ocsf:metadata:${n}`)}`;
const CONTROL = (n) => `arn:aws:securityhub:${R}:${A}:security-control/EC2.8/finding/${uuid(`control:${n}`)}`;
const v2 = (n, fields = {}) => aws.securityHubV2Event({ id: uuid(`sh-event:${n}:${fields.time ?? ""}`), account: A, region: R, time: fields.time ?? "2026-11-03T00:12:00Z",
  finding: aws.ocsfFinding({ uid: FINDING(n), providerUid: CONTROL(n), account: A, region: R, title: "EC2 instances should use Instance Metadata Service Version 2 (IMDSv2)",
    severity: "High", severityId: 4, resource: ARN, time: fields.time ?? "2026-11-03T00:12:00Z", ...fields }) });
FEATURES["sfx-aws-triage-security-finding"] = { sources: ["AWS-SH-01", "AWS-SH-02", "AWS-SH-03", "AWS-IAM-01"],
  awsCalls: "none: EventBridge delivers Findings Imported V2 events to the SideFX intake",
  base: { clock: "2026-11-03T00:20:00Z", sidefx: { admittedAccounts: [A], admittedDetailType: "Findings Imported V2", priorWorkItems: [], policy: "triage-only" } },
  cases: [
    { id: "aws-sec-high", title: "A high severity finding becomes a classified security work item",
      aws: "One OCSF finding per Findings Imported V2 event, in detail.findings; metadata.uid is globally unique (AWS-SH-01, AWS-SH-02, AWS-SH-03).",
      curated: "The request is the delivered event, not a flattened summary, and the work item is keyed by metadata.uid.",
      request: { event: v2(1) }, calls: [],
      then: [["$.status", "TRIAGED"], ["$.workItem.findingId", FINDING(1)], ["$.workItem.severity", "HIGH"], ["$.automaticRemediation", "false"]] },
    { id: "aws-sec-duplicate", title: "A repeated finding update is not a new issue by default",
      aws: "Every update to a finding sends another Findings Imported V2 event for it (AWS-SH-01).",
      request: { event: v2(1, { time: "2026-11-03T00:18:00Z" }) }, sidefx: { priorWorkItems: [FINDING(1)] }, calls: [],
      then: [["$.status", "DUPLICATE"], ["$.newWorkItem", "false"]] },
    { id: "aws-sec-cross-account", title: "A foreign account finding cannot enter the estate",
      aws: "An administrator's feed carries member accounts' findings; the finding's own account is cloud.account.uid (AWS-SH-01, AWS-SH-03).",
      curated: "The envelope comes from the admitted administrator account while the finding belongs to 999988887777, the realistic shape of this refusal.",
      request: { event: aws.securityHubV2Event({ id: uuid("sh-event:foreign"), account: A, region: R, time: "2026-11-03T00:12:00Z",
        finding: aws.ocsfFinding({ uid: FINDING(2), providerUid: CONTROL(2), account: F, region: R, title: "EC2 instances should use Instance Metadata Service Version 2 (IMDSv2)",
          severity: "High", severityId: 4, resource: `arn:aws:ec2:${R}:${F}:instance/${I}`, time: "2026-11-03T00:12:00Z" }) }) }, calls: [],
      then: [["$.status", "REFUSED"], ["$.reason", "FINDING_ACCOUNT_NOT_ADMITTED"]] },
    { id: "aws-sec-v1v2", title: "The Security Hub CSPM copy of a finding is not counted twice",
      aws: "Security Hub and Security Hub CSPM both publish on source aws.securityhub; AWS says to match the Security Hub detail-type to avoid duplicates (AWS-SH-01).",
      curated: "The candidate's abstract 'sameCanonicalFinding' becomes the documented rule: the CSPM detail-type is a second stream, not a second finding.",
      request: { event: aws.securityHubCspmEvent({ id: uuid("sh-event:cspm"), account: A, region: R, time: "2026-11-03T00:12:00Z", findingId: CONTROL(1), severity: "HIGH", resource: ARN }) },
      sidefx: { priorWorkItems: [FINDING(1)] }, calls: [],
      then: [["$.status", "DUPLICATE"], ["$.newWorkItem", "false"], ["$.reason", "SECURITY_HUB_CSPM_STREAM"]] },
    { id: "aws-sec-missing-resource", title: "A finding with no attributable resource is left unobserved",
      aws: "The OCSF finding's resources list is empty (AWS-SH-02).", request: { event: v2(4, { resource: null }) }, calls: [],
      then: [["$.status", "NOT_OBSERVABLE"], ["$.reason", "RESOURCE_BINDING_MISSING"]] },
    { id: "aws-sec-no-auto-write", title: "Even a critical finding cannot create a deletion without authority",
      aws: "severity_id 5 is Critical (AWS-SH-03).",
      request: { event: v2(5, { severity: "Critical", severityId: 5 }), proposedAction: "delete-resource" }, calls: [],
      then: [["$.status", "TRIAGED"], ["$.automaticRemediation", "false"], ["$.workItem.requiresReview", "true"]] },
  ] };

// ---------- render ----------
const AREA_ORDER = Object.keys(skeleton);
const deep = (base, over) => { const out = { ...base }; for (const [k, v] of Object.entries(over ?? {})) out[k] = v; return out; };
const manifest = { contractId: "sidefx-aws-curated-case-manifest.v1", curatedOn: "2026-11-03", synthetic: true, features: [] };
fs.rmSync(path.join(here, "features"), { recursive: true, force: true });
fs.rmSync(path.join(here, "fixtures"), { recursive: true, force: true });
for (const id of AREA_ORDER) {
  const s = skeleton[id], f = FEATURES[id];
  if (!f) throw new Error(`no curated cases for ${id}`);
  const op = s.operations[0];
  const lines = [
    `# ${id}: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.`,
    `# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in`,
    `#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.`,
    `# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.`,
    `# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.`,
    `# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.`,
    `# AWS calls of this circuit: ${f.awsCalls}.`,
    `# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.`,
    `#   They are synthetic: built from the documentation, never captured from an AWS account.`,
    `# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange`,
    `#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.`,
    `# Outcome variants (proposed): ${s.variants.join(", ")}.`,
    `# Source reference IDs: ${f.sources.join(", ")}.`,
    `# Priority: ${s.priority}.`,
    ...(f.removed ?? []).map(([caseId, why]) => `# Removed case ${caseId}: ${why}`),
    "", ...s.tags, ...s.story, "", `  ${s.rule}`];
  const entry = { capabilityId: id, area: s.area, priority: s.priority, operation: op, variants: s.variants, cases: [] };
  for (const c of f.cases) {
    const clock = c.clock ?? f.base.clock;
    const request = c.request ?? f.base.request;
    if (!request) throw new Error(`${c.id}: no request`);
    const status = c.then.find(([p]) => p === "$.status")?.[1];
    if (!s.variants.includes(status)) throw new Error(`${c.id}: ${status} is not a variant of ${id}`);
    const fixture = { fixtureType: "sidefx-aws-cloud-ops-acceptance-arrangement.v2", caseId: c.id, capabilityId: id, synthetic: true, clock,
      sidefx: deep(f.base.sidefx, c.sidefx), awsCalls: c.calls ?? [],
      notes: "Synthetic arrangement. AWS requests and responses use the documented shapes (see the feature's source IDs); none was captured from an AWS account." };
    const fixtureText = JSON.stringify(fixture, null, 2) + "\n";
    const rel = `fixtures/cases/${c.id}.json`;
    fs.mkdirSync(path.join(here, "fixtures/cases"), { recursive: true });
    fs.writeFileSync(path.join(here, rel), fixtureText);
    const digest = sha(fixtureText);
    const requestText = JSON.stringify(request, null, 2).split("\n").map((l) => "        " + l);
    lines.push("", `    # Fixture: ${rel} (sha256:${digest}).`, `    # AWS: ${c.aws}`, ...(c.curated ? [`    # Curated: ${c.curated}`] : []),
      `    @case:${c.id}`, "    @status:not-built", `    Scenario: ${c.title}`, `      ${s.given}`, '        """json', ...requestText, '        """',
      `      And the pinned acceptance arrangement for ${c.id} is established`, `      ${s.when}`, `      ${s.then}`, "        | operation | path | equals |",
      ...c.then.map(([p, v]) => `        | ${op} | ${p} | ${v} |`));
    entry.cases.push({ caseId: c.id, status, fixture: rel, fixtureDigest: `sha256:${digest}`, awsCalls: (c.calls ?? []).map((x) => x.call), curated: Boolean(c.curated) });
  }
  const text = lines.join("\n") + "\n";
  const rel = `features/${s.area}/${id}.feature`;
  fs.mkdirSync(path.join(here, "features", s.area), { recursive: true });
  fs.writeFileSync(path.join(here, rel), text);
  entry.feature = rel;
  entry.featureDigest = `sha256:${sha(text)}`;
  manifest.features.push(entry);
}
fs.mkdirSync(path.join(here, "source"), { recursive: true });
fs.writeFileSync(path.join(here, "source/aws-documentation-manifest.json"), JSON.stringify({ documentType: "aws-documentation-manifest.v2", verifiedDate: "2026-11-03",
  scope: "the AWS facts the curated SideFX AWS cloud-operations features rest on; 'search' marks facts confirmed through an AWS-docs search summary rather than a full page read",
  sources: Object.entries(SOURCES).map(([id, [title, url, facts]]) => ({ id, title, url, facts: facts.replace(/ \(search\)$/, ""),
    verifiedBy: / \(search\)$/.test(facts) ? "search" : "page" })) }, null, 2) + "\n");
fs.mkdirSync(path.join(here, "review"), { recursive: true });
fs.writeFileSync(path.join(here, "review/case-manifest.json"), JSON.stringify(manifest, null, 2) + "\n");
const count = manifest.features.reduce((n, f) => n + f.cases.length, 0);
console.log(JSON.stringify({ features: manifest.features.length, cases: count, curatedCases: manifest.features.reduce((n, f) => n + f.cases.filter((c) => c.curated).length, 0),
  awsCalls: manifest.features.reduce((n, f) => n + f.cases.reduce((m, c) => m + c.awsCalls.length, 0), 0) }));
