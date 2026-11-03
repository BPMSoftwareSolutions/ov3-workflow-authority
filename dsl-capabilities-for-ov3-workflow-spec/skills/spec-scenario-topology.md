# Declare and reveal scenario workflows faithfully

Use this skill when a specification describes workflows as scenario progression: entries, routes, branches, fan-out, convergence, returns and terminals. Declare each route on an exact estate carrier or hold it as a finding. Keep provider bindings, capability composition, product dependencies and navigation out of execution routes. (A workflow capability in sidefx:workflows is a different object; see spec-capability-declaration.)

## Laws

- A scenario workflow is what is reachable from one declared entry by following only declared, admitted scenario routes. Reachability across any other relation is not execution.
- Zero inbound edges is neither necessary nor sufficient for entry status. Entries come from declared entry authority, never from indegree, top placement, naming, a UI link or an HTTP endpoint alone. A scenario with inbound routes can still be an independent entry.
- Fail closed. A route with missing topology, missing semanticProgress, an unknown selecting variant, an unresolved identity or unsupported cross-altitude meaning is not traversed. It is a finding with a source pointer, never a best-guess arrow.
- One semantic identity per scenario. A scenario reached from two entries is referenced, never cloned.
- Preserve every admitted terminal disposition. Do not invent a single success terminal.

## Vocabulary map

The specification's terms are the canonical-circuit-blueprint.v1 vocabulary (ADR-001). The estate declares routes at $.semantics.routing of a capability envelope (members fromScenario, variant, toScenario, topologyKind, groupId, joinSlotId, semanticProgress) and concurrency at $.semantics.executionGraph. Routes are authored as DSL lines, and the compiler writes semanticProgress on every transition it emits. Re-read the installed sources before relying on a row of this map.

| Blueprint term | DSL line | Estate topologyKind | Estate semanticProgress | Notes |
| --- | --- | --- | --- | --- |
| TRANSITION | route <from> <variant> to <to> | selection; sequence or return when hand-minted | narrowing, or terminating into a terminal scenario; preserving for sequence and return | progression inside one capability |
| BRANCH_ROUTE | one route line per variant | selection | narrowing; terminating into a terminal scenario | exclusive; the variant is declared on the from scenario; endpoint contracts must agree (EDGE_CONTRACT_MISMATCH) |
| FAN_OUT_MEMBER | broadcast <root> to <leg>,<leg> | broadcast (enter-<leg>) | expanding | a broadcast without a join refuses; edgeGroup policy all with a dispatchAuthority |
| CONVERGENCE_REQUIREMENT | join <scenario> from <leg>,<leg> | join (settle-<leg>) and failure (fail-<leg>) | converging | one joinSlotId per leg; the leg sets must agree; a join without a broadcast refuses |
| BOUNDED_RETURN | recur <scenario> while <continue> until <stop> max <n> | recurrence | recurring | always write max: without it the bound is 2147483647, so treat it as unbounded and hold it |
| ALTITUDE_DESCENT | none (not a route) | none | none | scenario operation, port, port binding, provider slot, provider |
| none (estate only) | from join | failure | converging with joinSlotId, otherwise terminating | branchFailure collect |
| none (estate only) | none | cancellation | terminating | |

Known gaps:
- Capabilities declared before the compiler wrote semanticProgress keep routes without it until they are re-authored. On 2026-11-02, 76 of the estate's 105 declared routes had none (run 4cbc0711). Such a route is held, with that finding.
- The failure transitions fail-<leg> carry variant SUCCESS, which no scenario declares (task ena-authoring-conformance-by-construction, defect 1). Show them as the join's failure collection, never as a selected branch.
- Blueprint progress ESTABLISHES and DESCENDS have no estate value.
- No live surface shows the kernel's semanticProgress enum. narrowing rests on the SDA kernel source; terminating, expanding, converging and recurring appear on live declared routes.

## Relations that are never routes

- Provider binding: a scenario port bound to a provider (DSL bind or platform bind, provider slots, read-declared-port-bindings). Show it only under descent.
- Capability composition: an operation that invokes another capability (nested invocation through ScenarioKernel.NodePlatform; read-declared-composition). This is descent into a shared responsibility. It can be how one workflow submits to another capability's responsibility, but it is labelled composition, not a route.
- Product dependency: one capability's outcome satisfying another's input. It makes a product available; it never invokes the consumer. No estate carrier for it is verified. Until one is, show it only as a labelled overlay derived from shared contract identities (read-declared-contracts), or report NOT_DECLARED.
- UI navigation, catalog lookup, actor relationships, provider testimony and any unknown edge.

## Declaring

1. Entries: one capability per independently invocable entry (spec-capability-declaration); the compiler refuses a second root scenario. An external signal enters through an estate-owned ingress capability that admits it.
2. Routes inside a capability are DSL lines in its source. capability-from-dsl compiles them into $.semantics.routing and $.semantics.executionGraph, and model.declare_capability_topology writes them through model.declare_capability_envelope, the only writer for routing. The compiler enforces these rules: every route endpoint and variant resolves inside the document; routes and invoke-scenario operations form no cycle, a route back to its own scenario included; a broadcast needs a join over the same legs, and a join needs its broadcast; a recurring scenario declares both variants, and its outcome contract equals its input contract; an invoke-scenario operation names a scenario of the document. Hand re-minting an envelope (graph-topology-emission) is only for topology the DSL cannot express. Re-mint; never patch.
3. Every route carries semanticProgress, derived by the law declare-route-semantic-progress recorded and the compiler now applies: selection narrowing, or terminating into a terminal scenario; broadcast expanding; join converging; failure converging with a join slot; recurrence recurring. A declared route without it predates the compiler change; report it as held until its capability is re-authored, and never draw it.
4. Routes across capabilities: there is no cross-capability route carrier. Present the owner with the two options and their consequences: composition (the caller's port bound to the callee capability; nested-capability-invocation), or one capability holding the shared scenarios. Record the decision in the binding map. Never decide silently.

## Verifying

- read-topology-conformance: violation pages, count-paired, with the catalog digest.
- read-scenario-terminal-coverage: covered and missing outcome variants and contracts.
- read-declared-composition: composition edges, kept apart from routes.
- read-declared-port-bindings: the descent beneath each event.
- read-live-scenario-circuit: the projected circuit and drill-down. Layout may vary between projections; membership and edge classes may not.
- For concurrency, the overlap witness on real runs.

## Revealing

A workflow lens is read-only and changes nothing it reads. From one pinned snapshot it returns: entries with status (admitted, candidate, held); per-entry route closure; routes, composition edges, provider bindings and product overlays as separate lists; and findings. Every rendered edge carries its semantic id, topologyKind, semanticProgress, variant, source capability and definition digest. A held route holds only itself and what depends on it; independent workflows still render.

## Stop conditions

Stop at a route whose carrier is missing. Record AUTHORITY_GAP with source pointers and continue with independent routes. Stop if a declaration would need an invented schema key; that is an extension proposal for owner review.

## Completion

Every edge in the lens maps one to one to a declared routing entry or a composition edge, with its identity and digest. No execution arrow comes from a provider, product or navigation relation. Held routes are listed with their findings.
