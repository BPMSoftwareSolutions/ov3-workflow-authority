// Checks the curated AWS pack (make-aws-pack.mjs) before anyone builds on it:
//   - each feature keeps its declared identity tags and Given/When/Then word for word, names no @provider it cannot
//     resolve, and every case has its own id, a JSON request, an operation | path | equals table with a $.status row
//     naming one of the feature's outcome variants, and a fixture whose bytes match the pinned sha256;
//   - every recorded AWS value is one the documentation allows (aws-shapes.mjs ENUMS and PATTERNS): automation statuses,
//     configuration item statuses, instance states and their codes, status checks, metric status codes, change set and
//     restore job statuses, OCSF severity ids, UUID tokens and execution ids, account ids, runbook names and versions;
//   - each component a composed case names exists.
// This is a local structural check, not SideFX feature conformance and not AWS evidence.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { ENUMS, PATTERNS, sha } from "./aws-shapes.mjs";
const here = path.dirname(fileURLToPath(import.meta.url));
const skeleton = JSON.parse(fs.readFileSync(path.join(here, "skeleton.json"), "utf8"));
const manifest = JSON.parse(fs.readFileSync(path.join(here, "review/case-manifest.json"), "utf8"));
const failures = [];
const fail = (where, what) => failures.push(`${where}: ${what}`);
const allCases = new Set(manifest.features.flatMap((f) => f.cases.map((c) => c.caseId)));

// Every documented value a recording carries, wherever it sits.
function checkValues(where, value, key = "", parent = {}) {
  if (Array.isArray(value)) { value.forEach((v, i) => checkValues(where, v, key, value)); return; }
  if (value && typeof value === "object") {
    if ("Code" in value && "Name" in value && ENUMS.instanceStateName.includes(value.Name) && ENUMS.instanceStateCode[value.Name] !== value.Code)
      fail(where, `instance state ${value.Name} carries code ${value.Code}`);
    if ("Timestamps" in value && "Values" in value && value.Timestamps.length !== value.Values.length) fail(where, "metric Timestamps and Values differ in length");
    for (const [k, v] of Object.entries(value)) checkValues(where, v, k, value);
    return;
  }
  const one = (set, label) => { if (!set.includes(value)) fail(where, `${key} ${JSON.stringify(value)} is not a documented ${label}`); };
  const like = (re, label) => { if (typeof value !== "string" || !re.test(value)) fail(where, `${key} ${JSON.stringify(value)} is not a valid ${label}`); };
  switch (key) {
    case "AutomationExecutionStatus": one(ENUMS.automationStatus, "AutomationExecutionStatus"); break;
    case "AutomationExecutionId": case "ClientToken": case "automationExecutionId": case "clientToken": like(PATTERNS.uuid, "UUID"); break;
    case "DocumentName": case "documentName": like(PATTERNS.documentName, "document name"); break;
    case "DocumentVersion": case "documentVersion": like(PATTERNS.documentVersion, "document version"); break;
    case "configurationItemStatus": one(ENUMS.configurationItemStatus, "configuration item status"); break;
    case "recordingFrequency": one(ENUMS.recordingFrequency, "recording frequency"); break;
    case "StatusCode": one(ENUMS.metricStatus, "metric status code"); break;
    case "StateValue": one(ENUMS.alarmState, "alarm state"); break;
    case "BudgetStatus": one(ENUMS.sloBudgetStatus, "SLO budget status"); break;
    case "ExecutionStatus": one(ENUMS.changeSetExecutionStatus, "change set execution status"); break;
    case "ValidationStatus": one(ENUMS.restoreValidationStatus, "restore validation status"); break;
    case "DeletionStatus": one(ENUMS.restoreDeletionStatus, "restore deletion status"); break;
    case "severity_id": one(ENUMS.ocsfSeverityId, "OCSF severity id"); break;
    case "SignalType": case "signalType": one(ENUMS.signalType, "automation signal type"); break;
    case "accountId": case "AccountId": case "account": case "AwsAccountId": case "SourceAccountId": like(PATTERNS.account, "12-digit account id"); break;
    case "InstanceId": case "instanceId": like(PATTERNS.instanceId, "instance id"); break;
    // Status means different things by the record it sits in; EC2 status checks are checked by checkInstanceStatuses.
    case "Status":
      if ("ChangeSetId" in parent) one(ENUMS.changeSetStatus, "change set status");
      else if ("RestoreJobId" in parent) one(ENUMS.restoreJobStatus, "restore job status");
      else if (parent.Name === "reachability") one(ENUMS.reachability, "reachability status");
      break;
    case "value": if (parent && "timestamp" in parent && "reason" in parent) one(ENUMS.alarmState, "alarm state"); break;
    default: break;
  }
}
// The EC2 status-check objects: their Status is a status-check value, their Details a reachability value.
function checkInstanceStatuses(where, response) {
  for (const s of response?.InstanceStatuses ?? []) for (const k of ["InstanceStatus", "SystemStatus"]) {
    if (!ENUMS.statusCheck.includes(s[k]?.Status)) fail(where, `${k}.Status ${s[k]?.Status} is not a documented status-check value`);
    for (const d of s[k]?.Details ?? []) if (!ENUMS.reachability.includes(d.Status)) fail(where, `${k} reachability ${d.Status} is not documented`);
  }
}
function checkEvent(where, event) {
  if (!event || typeof event !== "object") return;
  if (event.source === "aws.cloudwatch" && event["detail-type"] !== "CloudWatch Alarm State Change") fail(where, "unexpected CloudWatch detail-type");
  if (event.source === "aws.securityhub" && ![...ENUMS.securityHubDetailType, ...ENUMS.securityHubCspmDetailType].includes(event["detail-type"])) fail(where, "unexpected Security Hub detail-type");
  if ("id" in event && !PATTERNS.uuid.test(event.id)) fail(where, `event id ${event.id} is not a UUID`);
  if (event.source === "aws.securityhub" && event["detail-type"] === "Findings Imported V2" && event.detail?.findings?.length !== 1) fail(where, "a Findings Imported V2 event carries exactly one finding");
}

for (const f of manifest.features) {
  const s = skeleton[f.capabilityId];
  const text = fs.readFileSync(path.join(here, f.feature), "utf8");
  if (`sha256:${sha(text)}` !== f.featureDigest) fail(f.feature, "feature bytes differ from the manifest digest");
  const lines = text.split("\n");
  const tags = lines.filter((l) => /^@/.test(l));
  if (JSON.stringify(tags) !== JSON.stringify(s.tags)) fail(f.feature, "declared identity tags differ from the skeleton");
  if (lines.some((l) => /@provider:/.test(l) && !/^#/.test(l.trim()))) fail(f.feature, "names an @provider tag no estate capability provides yet");
  const blocks = text.split(/\n(?=    # Fixture: )/).slice(1);
  if (blocks.length !== f.cases.length) fail(f.feature, `${blocks.length} case blocks for ${f.cases.length} manifest cases`);
  blocks.forEach((block, i) => {
    const c = f.cases[i];
    const where = `${f.capabilityId}/${c.caseId}`;
    const b = block.split("\n");
    const pin = /# Fixture: (\S+) \(sha256:([0-9a-f]{64})\)\./.exec(b[0]);
    if (!pin || pin[1] !== c.fixture) { fail(where, "fixture comment missing or pointing elsewhere"); return; }
    const fixtureText = fs.readFileSync(path.join(here, pin[1]), "utf8");
    if (sha(fixtureText) !== pin[2]) fail(where, "fixture bytes differ from the pinned sha256");
    const fixture = JSON.parse(fixtureText);
    if (fixture.caseId !== c.caseId || fixture.capabilityId !== f.capabilityId) fail(where, "fixture names another case or capability");
    if (!b.some((l) => l.trim() === `@case:${c.caseId}`)) fail(where, "no @case tag");
    if (!b.some((l) => l.trim() === "@status:not-built")) fail(where, "status tag must stay not-built until a live run proves it");
    const step = (prefix) => b.find((l) => l.trim().startsWith(prefix))?.trim();
    if (step("Given ") !== s.given) fail(where, "Given differs from the declared step");
    if (step("When ") !== s.when) fail(where, "When differs from the declared step");
    if (step("Then ") !== s.then) fail(where, "Then differs from the declared step");
    if (step("And ") !== `And the pinned acceptance arrangement for ${c.caseId} is established`) fail(where, "arrangement step missing");
    const open = b.findIndex((l) => l.trim() === '"""json'), close = b.findIndex((l, k) => k > open && l.trim() === '"""');
    let request;
    try { request = JSON.parse(b.slice(open + 1, close).join("\n")); } catch { fail(where, "request docstring is not JSON"); }
    const rows = b.filter((l) => /^\s+\| /.test(l)).slice(1).map((l) => l.split("|").slice(1, -1).map((x) => x.trim()));
    if (rows.some((r) => r[0] !== s.operations[0])) fail(where, "a row names another operation");
    const status = rows.find((r) => r[1] === "$.status");
    if (!status) fail(where, "no $.status row");
    else if (!s.variants.includes(status[2]) || status[2] !== c.status) fail(where, `$.status ${status[2]} is not this case's variant`);
    if (new Set(rows.map((r) => r[1])).size !== rows.length) fail(where, "a path is asserted twice");
    // The recorded AWS values and the event bodies.
    checkValues(`${where} request`, request);
    checkEvent(`${where} request`, request?.event);
    fixture.awsCalls.forEach((x, k) => {
      const at = `${where} call ${k + 1} ${x.call}`;
      if (!/^[a-z0-9]+:[A-Z][A-Za-z]+$/.test(x.call)) fail(at, "call is not service:Operation");
      const outcomes = ["response", "error", "noResponse"].filter((o) => o in x);
      if (outcomes.length !== 1) fail(at, "a call records exactly one of response, error, noResponse");
      if (x.error && !(x.error.code && Number.isInteger(x.error.httpStatus))) fail(at, "an error records its code and HTTP status");
      checkValues(at, x.request);
      checkValues(at, x.response);
      if (x.call === "ec2:DescribeInstanceStatus") checkInstanceStatuses(at, x.response);
      if (JSON.stringify(x).match(/"SecretAccessKey"|"SessionToken"|wJalrXUtnFEMI/)) fail(at, "a recording carries credentials");
    });
    for (const [k, v] of Object.entries(fixture.sidefx.components ?? {})) {
      const ref = typeof v === "object" && v ? v.case : v;
      if (ref !== null && !allCases.has(ref)) fail(where, `component ${k} names unknown case ${ref}`);
    }
  });
}
const cases = manifest.features.reduce((n, f) => n + f.cases.length, 0);
console.log(failures.length ? failures.join("\n") : `${manifest.features.length} features, ${cases} cases: every check holds`);
process.exit(failures.length ? 1 : 0);
