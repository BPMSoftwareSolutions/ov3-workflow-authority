# Specification acceptance as flights, and honest closure

Use this skill to turn a specification's Gherkin acceptance and fixtures into reviewed flights, and to close its promise only on evidence. Fixture expectations are hypotheses; only retained runs are evidence. The flight mechanics are in flight-pattern-promise-plan-review-report-approve, flight-pattern-workflow-run and flight-pattern-verification-publish-and-acceptance. This skill adds the rules a specification brings.

## Required inputs

- The bound acceptance scenarios and fixtures, retained by digest.
- The capabilities under test, declared and read back.
- The promise and its obligations, the owner principal id and the planner agent id.

## From Gherkin to steps

- stepsJson is an array. Element 0 is the estate-flight-plan.v1 header: stepId plan-header, promiseId, flightType (execution or discovery), workClass, unknowns. Each later element is a step: stepId, capabilityId, input matching the capability's root input contract, obligationIds, expect {path, equals}, historicalBasis.
- Each Gherkin scenario becomes one or more steps with a checkable expectation. The Then clause becomes expect, never prose. A Then that no result member can express is a gap in the capability's outcome contract, not a reason to drop the check.
- Every execution step names its historical basis: the prior successful retained execution or pattern that makes it admissible. A step without one belongs in a discovery flight, never an execution flight.
- Negative fixtures run first and must be RED on the existing surface before any repair. An intentionally invalid specimen must be rejected by a real run; if no surface can consume the specimen at all, that absence is the finding. A green negative is a defect in the test, not a pass.
- An expected-defect baseline is accepted as a baseline while its conformance finding stays FAIL. After-state PASS alone does not close a task; it needs the accepted baseline and a transition comparison.

## The process

The planner retains the promise, records the plan (record-flight-plan, or start-workflow-run for a workflow capability), and has it reviewed (review-flight-plan; fix PLAN_*, STEP_* and PROMISE_* findings by re-planning). The report comes from generate-flight-plan-report-md. The owner approves, and the planner records the approval at once with approve-flight-plan, quoting the owner. resolve-flight-clearance clears it. The owner triggers it through OV3, and OV3 flies it. The planner never triggers on its own initiative. The reviewer and the reporter never approve or fly.

## Observation

- A flight begins its recording before the first executable step and completes it on every terminal disposition. A run with no flight recording informs the next plan but cannot establish acceptance.
- Execution testimony comes from real runs: read-run-cell-testimony, read-flight-recording, read-flight-progress, and sfx-api run <runId>. A fixture value never renders as EXECUTED; without a receipt it is NOT_OBSERVED.
- Provider swaps, concurrency, authorization refusals and held-route cases are proven by real signals, not screenshots or replays.
- Never resubmit an unknown outcome automatically. Reconcile it by run id.

## Closure and the final report

- read-flight-closure must return PROMISE_CLOSED. A green step is not a closed promise.
- Record task evidence through project-tracking (apply-declared-change, or coordinate-project-task RECORD) with task-execution-evidence.v1 references. A task is DONE only when its acceptance is demonstrated.
- The mission disposition is COMPLETE, PARTIAL_WITH_HELD_GAPS or NOT_ADMITTED. Keep six claims separate: specification written, fixture valid, graph projected, provider invoked, workflow executed, promised outcome evidenced.
- The final report gives: the snapshot identity and digests; admitted entries with their rationale and source pointers; routes, composition edges, provider bindings and product overlays as separate inventories from the same snapshot; expected versus observed fixture dispositions, negatives included; parity across the projection targets actually admitted; held gaps with owners; and receipts only where the lifecycle produced them. No invented digest appears anywhere.

## Stop conditions

Stop if a step's capability or input does not resolve (STEP_CAPABILITY_UNKNOWN, STEP_INPUT_CONTRACT_MISMATCH), if an obligation has no checkable expectation (PROMISE_OBLIGATION_UNCOVERED), or if closure is asked for without a recording.

## Completion

Every acceptance scenario is a reviewed step with a real-run result. Negatives were RED before repair. Closure reads PROMISE_CLOSED. The report keeps the six claims separate and names every held gap.
