// The AWS responses the curated arrangements record, in the shapes the AWS documentation gives (source IDs in
// source/aws-documentation-manifest.json), and the documented value sets check-aws-pack.mjs holds them to.
// Every recording is synthetic: built from the documentation, never captured from an AWS account. EC2 and STS answer
// in XML on the wire; their recordings use the AWS SDK's JSON rendering of the same members.
import crypto from "node:crypto";

export const sha = (s) => crypto.createHash("sha256").update(Buffer.from(s, "utf8")).digest("hex");
// A stable UUID (version 4 layout) for a label, so every identifier in the pack is reproducible.
export function uuid(label) {
  const h = sha(label);
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-4${h.slice(13, 16)}-${"89ab"[parseInt(h[16], 16) % 4]}${h.slice(17, 20)}-${h.slice(20, 32)}`;
}
export const epoch = (iso) => Date.parse(iso) / 1000;
// CloudWatch writes state timestamps as 2019-10-02T17:04:40.989+0000 (AWS-CW-01).
const cwTime = (iso) => new Date(iso).toISOString().replace("Z", "+0000");

// The documented value sets.
export const ENUMS = {
  alarmState: ["OK", "ALARM", "INSUFFICIENT_DATA"], // AWS-CW-01
  metricStatus: ["Complete", "InternalError", "PartialData", "Forbidden"], // AWS-CW-02
  configurationItemStatus: ["OK", "ResourceDiscovered", "ResourceNotRecorded", "ResourceDeleted", "ResourceDeletedNotRecorded"], // AWS-CONFIG-03
  recordingFrequency: ["CONTINUOUS", "DAILY"], // AWS-CONFIG-03
  instanceStateName: ["pending", "running", "shutting-down", "terminated", "stopping", "stopped"], // AWS-EC2-01
  instanceStateCode: { pending: 0, running: 16, "shutting-down": 32, terminated: 48, stopping: 64, stopped: 80 }, // AWS-EC2-01
  statusCheck: ["ok", "impaired", "insufficient-data", "not-applicable", "initializing"], // AWS-EC2-02
  reachability: ["passed", "failed", "initializing", "insufficient-data"], // AWS-EC2-01
  automationStatus: ["Pending", "InProgress", "Waiting", "Success", "TimedOut", "Cancelling", "Cancelled", "Failed", "PendingApproval",
    "Approved", "Rejected", "Scheduled", "RunbookInProgress", "PendingChangeCalendarOverride", "ChangeCalendarOverrideApproved",
    "ChangeCalendarOverrideRejected", "CompletedWithSuccess", "CompletedWithFailure", "Exited"], // AWS-SSM-03
  approvalStatus: ["Approved", "Rejected", "Waiting"], // AWS-SSM-04
  signalType: ["Approve", "Reject", "StartStep", "StopStep", "Resume", "Revoke"], // AWS-SSM-05
  sloBudgetStatus: ["OK", "WARNING", "BREACHED", "INSUFFICIENT_DATA"], // AWS-SLO-02
  changeSetStatus: ["CREATE_PENDING", "CREATE_IN_PROGRESS", "CREATE_COMPLETE", "DELETE_PENDING", "DELETE_IN_PROGRESS", "DELETE_COMPLETE",
    "DELETE_FAILED", "FAILED"], // AWS-CFN-02
  changeSetExecutionStatus: ["UNAVAILABLE", "AVAILABLE", "EXECUTE_IN_PROGRESS", "EXECUTE_COMPLETE", "EXECUTE_FAILED", "OBSOLETE"], // AWS-CFN-02
  restoreJobStatus: ["PENDING", "RUNNING", "COMPLETED", "ABORTED", "FAILED"], // AWS-BKP-02
  restoreValidationStatus: ["FAILED", "SUCCESSFUL", "TIMED_OUT", "VALIDATING"], // AWS-BKP-02
  restoreDeletionStatus: ["DELETING", "FAILED", "SUCCESSFUL"], // AWS-BKP-02
  ocsfSeverityId: [0, 1, 2, 3, 4, 5, 6, 99], // AWS-SH-03
  securityHubDetailType: ["Findings Imported V2"], // AWS-SH-01
  securityHubCspmDetailType: ["Security Hub Findings - Imported"], // AWS-SH-01: the CSPM stream on the same source
};
export const PATTERNS = {
  uuid: /^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/, // ClientToken, AutomationExecutionId (AWS-SSM-01)
  account: /^\d{12}$/, // AWS-CONFIG-03
  documentName: /^[a-zA-Z0-9_\-.:/]{3,128}$/, // AWS-SSM-01
  documentVersion: /^([$]LATEST|[$]DEFAULT|[1-9][0-9]*)$/, // AWS-SSM-01
  instanceId: /^i-[0-9a-f]{8}([0-9a-f]{9})?$/,
};

// EventBridge delivers a CloudWatch alarm state change in this envelope (AWS-CW-01).
export function alarmStateChange({ id, account, region, alarmName, value, previous, time, serviceId }) {
  const event = { version: "0", "detail-type": "CloudWatch Alarm State Change", source: "aws.cloudwatch", account, time, region,
    resources: [`arn:aws:cloudwatch:${region}:${account}:alarm:${alarmName}`],
    detail: { alarmName,
      configuration: { description: `Heartbeat success below objective for ${serviceId}`,
        metrics: [{ id: "m1", metricStat: { metric: { namespace: "CitizenPortal", name: "HeartbeatSuccess", dimensions: { ServiceId: serviceId } },
          period: 60, stat: "Average" }, returnData: true }] },
      previousState: { value: previous, reason: `Unchecked: state before ${time}`, timestamp: cwTime(Date.parse(time) - 300000) },
      state: { value, reason: value === "INSUFFICIENT_DATA" ? "Insufficient Data: 5 datapoints were unknown."
        : `Threshold Crossed: 5 out of the last 5 datapoints were ${value === "ALARM" ? "less" : "not less"} than the threshold (0.99).`,
      timestamp: cwTime(time) } } };
  return id === undefined ? event : { version: "0", id, ...Object.fromEntries(Object.entries(event).slice(1)) };
}

// A full CloudTrail record, as LookupEvents returns it in CloudTrailEvent (a JSON string) (AWS-CT-02).
function cloudTrailRecord({ eventId, eventName, account, region, time, instanceId, principal }) {
  return JSON.stringify({ eventVersion: "1.10", userIdentity: { type: "AssumedRole", arn: principal, accountId: account },
    eventTime: time, eventSource: "ec2.amazonaws.com", eventName, awsRegion: region, sourceIPAddress: "198.51.100.24",
    userAgent: "aws-cli/2.17.0", requestParameters: { instancesSet: { items: [{ instanceId }] }, force: false },
    responseElements: { instancesSet: { items: [{ instanceId, currentState: { code: 64, name: "stopping" }, previousState: { code: 16, name: "running" } }] } },
    requestID: uuid(`request:${eventId}`), eventID: eventId, readOnly: false, eventType: "AwsApiCall", managementEvent: true,
    recipientAccountId: account, eventCategory: "Management" });
}
// LookupEvents: most recent first, EventTime in epoch seconds, resources named by type and name, not by ARN (AWS-CT-02).
export function lookupEvents(events) {
  return { Events: events.map((e) => ({ EventId: e.eventId, EventName: e.eventName, ReadOnly: "false", AccessKeyId: "ASIAIOSFODNN7EXAMPLE",
    EventTime: epoch(e.time), EventSource: "ec2.amazonaws.com", Username: e.principal.split("/").pop(),
    Resources: [{ ResourceType: "AWS::EC2::Instance", ResourceName: e.instanceId }], CloudTrailEvent: cloudTrailRecord(e) })) };
}

// GetAggregateResourceConfig: one configuration item; configuration is a JSON-encoded string (AWS-CONFIG-02, AWS-CONFIG-03).
export function configurationItem({ account, region, instanceId, status = "OK", captureTime, tags, recordingFrequency, stateName = "stopped" }) {
  return { ConfigurationItem: { version: "1.3", accountId: account, configurationItemCaptureTime: epoch(captureTime), configurationItemStatus: status,
    configurationStateId: String(epoch(captureTime) * 1000), arn: `arn:aws:ec2:${region}:${account}:instance/${instanceId}`,
    resourceType: "AWS::EC2::Instance", resourceId: instanceId, awsRegion: region, availabilityZone: `${region}a`, tags, relatedEvents: [],
    relationships: [], configuration: JSON.stringify({ instanceId, instanceType: "t3.micro",
      state: { code: ENUMS.instanceStateCode[stateName], name: stateName } }), supplementaryConfiguration: {},
    ...(recordingFrequency ? { recordingFrequency } : {}) } };
}

// DescribeInstances, the fresh state read; DescribeInstanceStatus answers only running instances by default (AWS-EC2-01).
export function describeInstances({ instanceId, region, stateName, tags = [] }) {
  return { Reservations: [{ Instances: [{ InstanceId: instanceId, InstanceType: "t3.micro", Placement: { AvailabilityZone: `${region}a` },
    State: { Code: ENUMS.instanceStateCode[stateName], Name: stateName }, Tags: tags }] }] };
}
// DescribeInstanceStatus with IncludeAllInstances: state plus the instance and system status checks (AWS-EC2-01, AWS-EC2-02).
export function instanceStatus({ instanceId, region, stateName, instance, system }) {
  // A not-applicable check (a stopped instance) carries no reachability detail.
  const details = (s) => (s === "not-applicable" ? [] : [{ Name: "reachability", Status: s === "ok" ? "passed" : s === "impaired" ? "failed" : s }]);
  return { InstanceStatuses: [{ InstanceId: instanceId, AvailabilityZone: `${region}a`,
    InstanceState: { Code: ENUMS.instanceStateCode[stateName], Name: stateName },
    InstanceStatus: { Status: instance, Details: details(instance) }, SystemStatus: { Status: system, Details: details(system) } }] };
}

// AssumeRole: credentials are never recorded, only the assumed-role identity (AWS-IAM-02).
export function assumedRole({ account, role, session }) {
  return { AssumedRoleUser: { Arn: `arn:aws:sts::${account}:assumed-role/${role}/${session}`, AssumedRoleId: `AROAEXAMPLEID${account.slice(-4)}:${session}` },
    Credentials: "(withheld: never recorded)" };
}

// StartAutomationExecution answers only the new execution's ID (AWS-SSM-01).
export const automationStarted = (id) => ({ AutomationExecutionId: id });
// GetAutomationExecution (AWS-SSM-03); an aws:approve step holds the execution in Waiting (AWS-SSM-04).
export function automationExecution({ id, documentName, documentVersion, status, parameters, start, end, failureMessage, currentAction }) {
  return { AutomationExecution: { AutomationExecutionId: id, DocumentName: documentName, DocumentVersion: documentVersion,
    AutomationExecutionStatus: status, Mode: "Auto", ExecutionStartTime: epoch(start), ...(end ? { ExecutionEndTime: epoch(end) } : {}),
    ...(currentAction ? { CurrentAction: currentAction } : {}), ...(failureMessage ? { FailureMessage: failureMessage } : {}),
    Parameters: parameters, ExecutedBy: "arn:aws:sts::111122223333:assumed-role/sidefx-cloudops-dispatch/sidefx" } };
}

// GetMetricData: timestamps newest first, one value per timestamp, a status per result (AWS-CW-02).
export function metricData({ values, newest, periodSeconds = 60, status = "Complete", label = "HeartbeatSuccess" }) {
  return { MetricDataResults: [{ Id: "heartbeat", Label: label,
    Timestamps: values.map((_, i) => epoch(newest) - i * periodSeconds), Values: values, StatusCode: status }], Messages: [] };
}
// DescribeAlarms for one metric alarm (AWS-CW-01 state values).
export function metricAlarm({ account, region, alarmName, state, updated, serviceId }) {
  return { MetricAlarms: [{ AlarmName: alarmName, AlarmArn: `arn:aws:cloudwatch:${region}:${account}:alarm:${alarmName}`, StateValue: state,
    StateUpdatedTimestamp: epoch(updated), Namespace: "CitizenPortal", MetricName: "HeartbeatSuccess",
    Dimensions: [{ Name: "ServiceId", Value: serviceId }] }], CompositeAlarms: [] };
}

// GetCostAndUsage grouped by one cost-allocation tag: Keys are tag$value, untagged spend is tag$, amounts are strings,
// the end date is exclusive and Estimated marks an unfinalized period (AWS-CE-02).
export function costAndUsage(periods) {
  return { GroupDefinitions: [{ Type: "TAG", Key: "service" }], ResultsByTime: periods.map((p) => ({ TimePeriod: { Start: p.start, End: p.end },
    Total: {}, Groups: Object.entries(p.groups).map(([value, amount]) => ({ Keys: [`service$${value}`],
      Metrics: { UnblendedCost: { Amount: amount, Unit: "USD" } } })), Estimated: p.estimated })) };
}

// ListRestoreJobsByProtectedResource: restore-testing jobs with their timing and validation (AWS-BKP-01, AWS-BKP-02).
export function restoreJobs(jobs) {
  return { RestoreJobs: jobs.map((j) => ({ AccountId: j.account, RestoreJobId: j.id, RecoveryPointArn: j.recoveryPoint,
    RecoveryPointCreationDate: epoch(j.recoveryPointCreated), SourceResourceArn: j.source, ResourceType: "EC2",
    CreatedResourceArn: j.created, CreationDate: epoch(j.started), ...(j.completed ? { CompletionDate: epoch(j.completed) } : {}),
    Status: j.status, ValidationStatus: j.validation, DeletionStatus: j.deletion, IamRoleArn: `arn:aws:iam::${j.account}:role/service-role/AWSBackupDefaultServiceRole`,
    CreatedBy: { RestoreTestingPlanArn: `arn:aws:backup:${j.region}:${j.account}:restore-testing-plan:citizen_portal_weekly-${j.planSuffix}` } })) };
}
// ListRecoveryPointsByResource: snapshot recovery points; EC2 has no continuous backup, so the interval bounds the RPO (AWS-BKP-03).
export function recoveryPoints({ account, region, created }) {
  return { RecoveryPoints: created.map((c) => ({ RecoveryPointArn: `arn:aws:ec2:${region}::image/ami-${sha(c).slice(0, 17)}`,
    CreationDate: epoch(c), Status: "COMPLETED", BackupVaultName: "citizen-portal-vault", IsParent: false })) };
}

// DescribeChangeSet: a created change set not yet executed (AWS-CFN-02).
export function changeSet({ account, region, stack, name, status, executionStatus, instanceId }) {
  const id = uuid(`changeset:${name}`);
  return { ChangeSetName: name, ChangeSetId: `arn:aws:cloudformation:${region}:${account}:changeSet/${name}/${id}`, StackName: stack,
    StackId: `arn:aws:cloudformation:${region}:${account}:stack/${stack}/${uuid(`stack:${stack}`)}`, Status: status, ExecutionStatus: executionStatus,
    Changes: [{ Type: "Resource", ResourceChange: { Action: "Modify", LogicalResourceId: "PortalInstance", PhysicalResourceId: instanceId,
      ResourceType: "AWS::EC2::Instance", Replacement: "False", Scope: ["Tags"] } }] };
}

// Security Hub sends one OCSF finding per Findings Imported V2 event in detail.findings (AWS-SH-01, AWS-SH-02); a finding
// is identified by cloud.account.uid + finding_info.uid + metadata.product.uid, and metadata.uid is globally unique (AWS-SH-03).
export function securityHubV2Event({ id, account, region, time, finding }) {
  return { version: "0", id, "detail-type": "Findings Imported V2", source: "aws.securityhub", account, time, region, resources: [],
    detail: { findings: [finding] } };
}
export function ocsfFinding({ uid, providerUid, account, region, title, severity, severityId, resource, time }) {
  return { metadata: { uid, product: { uid: "aws-security-hub", name: "Security Hub" } }, finding_info: { uid: providerUid, title,
    created_time_dt: time, modified_time_dt: time }, cloud: { provider: "AWS", region, account: { uid: account } }, severity,
    severity_id: severityId, status: "New", resources: resource ? [{ uid: resource, type: "AWS::EC2::Instance" }] : [] };
}
// The Security Hub CSPM stream: the same source, its own detail-type, ASFF findings (AWS-SH-01).
export function securityHubCspmEvent({ id, account, region, time, findingId, severity, resource }) {
  return { version: "0", id, "detail-type": "Security Hub Findings - Imported", source: "aws.securityhub", account, time, region,
    resources: [findingId], detail: { findings: [{ SchemaVersion: "2018-10-08", Id: findingId,
      ProductArn: `arn:aws:securityhub:${region}::product/aws/securityhub`, AwsAccountId: account, Severity: { Label: severity },
      Resources: [{ Type: "AwsEc2Instance", Id: resource }], Workflow: { Status: "NEW" }, RecordState: "ACTIVE" }] } };
}

// An AWS error as the provider surfaces it: the documented error code and HTTP status.
export const awsError = (code, httpStatus, message) => ({ code, httpStatus, message });
