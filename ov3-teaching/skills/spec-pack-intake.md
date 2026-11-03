# Spec pack intake and estate binding

Use this skill when the owner hands the network a specification pack (a specification, build profiles, Gherkin acceptance, fixtures, a candidate flight-plan envelope) and asks for it to be built. It turns the pack into estate work without building anything: the pack retained by digest, every term the pack uses bound to an installed surface or recorded as a gap, and a tracker project whose tasks name capabilities and pin skills. A pack is a candidate. It never establishes admission, installation or runtime behavior.

## Required inputs

- The pack files and their UTF-8 SHA-256 digests.
- The owner principal id and the planner agent id.
- The selected estate model (estateModelPk) and a catalog digest from the first declared read that returns one. Pin both. Pass expectedCatalogDigest where a read accepts it; STALE_CATALOG means re-pin and re-read, not retry.

## Allowed actions

- Declared reads: read-mcp-catalog, list-capabilities, read-declared-identities, read-declared-capability-document, read-declared-contracts, read-declared-port-bindings, read-declared-composition, read-scenario-authority, read-topology-conformance, read-live-scenario-circuit, read-capability-dsl-specification, read-agent-specializations, read-specialist-selection, read-project-tracker.
- Retain the pack as the owner's artifact through apply-declared-change with changeKind content-artifact-change, so later calls can take it by digest.
- Preflight a project-tracking change (apply-declared-change, changeKind project-tracking). Plan approval (planApprovalDate) and completion approval are owner acts; never set them.

## Binding procedure

1. Read the live inventory before claiming anything is missing. A named surface that is not installed is a work item, never a blocker, and never a reason to invent one.
2. Give every capability, command, table, procedure, schema field, mechanic, role and vocabulary term the pack names exactly one disposition:
   - BOUND: an installed surface carries the same meaning. Cite its id, document or definition digest and the read run id.
   - EQUIVALENT: an installed surface carries the meaning under another name. Cite it, state the correspondence, and use the installed name from then on.
   - AUTHORITY_GAP: no installed surface carries the meaning. Record source pointers and a bounded extension proposal naming its owner: sfx-embody for meaning, sfx-dal for identity, sfx-platform for delivery, SDA only by an evidenced request that names no provider.
   - NOT_DECLARED or NOT_VERIFIABLE: the estate holds no declaration, or no read can verify one. This is a valid answer. Never fill it from layout, naming, indegree, Gherkin prose, a product dependency or a model explanation.
3. Record name collisions. A pack word can name a different installed concept. In this estate "workflow" also means a CAPABILITY_WORKFLOW declaration (sidefx:workflows) flown by start-workflow-run; a specification's "workflow" usually means scenario progression. Qualify every use: "scenario workflow" or "workflow capability".
4. Separate illustrative identifiers (example field names, mission envelopes, candidate capability ids) from installed ones. Adopt an illustrative name only after the owner accepts it in the binding map; reuse an installed equivalent first.
5. Map the pack's mission envelope onto the estate flight format: the estate-flight-plan.v1 header (stepId plan-header, promiseId, flightType, workClass, unknowns), the promise retained as flight-promise:<promiseId> with obligations, and steps with expectations. The pack's own envelope is never submitted as is.

## Project and task shape

- One project per pack, assigned to the actor that will execute it, carrying the agent user story and acceptance criteria from the pack.
- One task per work package or gate. Keep the pack's sequencing as dependencyRefs, not prose. A later phase stays OPEN behind its gate task.
- Every task carries requiredOutcome, capabilityRef as "<performing capability> (performs); <verifying read> (verifies)" or "UNRESOLVED: <what is missing> (performs); <read> (verifies)", dependencyRefs, assignedActor and skillRefs as <skillId>@<revision>.
- Read every pinned skill revision back first; the project writer refuses unknown refs with PROJECT_TASK_SKILL_UNKNOWN.

## Output

- The retained pack digests.
- The binding map: term, disposition, installed surface, digest, run id, source pointer.
- The gap list with owner and proposed path, and any owner decisions the pack leaves open.
- The project-tracking change, preflighted, ready for owner review.

## Stop conditions

Stop and report if the estate model or catalog digest cannot be pinned, if a read the procedure needs fails, or if a binding can only be made by assumption. Inventory may continue with the failing area labelled NOT_VERIFIABLE. Do not create scratch SQL, probe files or local scripts; a missing declared read is the next task.

## Completion

The owner can read the binding map and see, for every pack term, the installed surface it maps to or the exact gap. The project and its tasks are preflighted. Nothing has been installed, admitted or flown.
