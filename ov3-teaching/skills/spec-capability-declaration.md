# Declare capabilities from a bound specification

Use this skill for a tracker task that builds a capability a specification calls for. Build it through the declared pipeline, providers first, and prove it with a real first call. Meaning is authored in rows; no capability meaning, wiring, contract or transformation lives in local executable code. The binding map from spec-pack-intake comes first.

## Required inputs

- The task, its binding-map entries and its acceptance.
- The capability's identity: an installed equivalent when the binding map found one, otherwise the accepted candidate id (ids match ^[a-z0-9][a-z0-9.-]*$).
- Its input and outcome contracts and its effects.

## Providers first

1. Decompose the capability into effects: what it reads and from where, what it writes, which external service it calls, what it decides or transforms, where it needs a model, and what it delivers.
2. Resolve each effect against the estate with read-declared-port-bindings, analysis-read-provider-slot-bindings, analysis-read-slot-provider-candidates, search-provider-registry and read-provider-registry. Classify each:
   - EXISTS: a provider capability serves the effect. Bind it and cite a prior successful binding.
   - COMPOSE: no provider serves it, but existing leaves can. Build a new provider capability the same way, first.
   - LEAF: no leaf family serves it. Write it first as the code it would be, then declare it as dependency programs the resolvers run. Only a gap in the generic resolver goes to SDA.
3. Build leaves first. A provider passes its first call before the root binds it.
4. Prefer our providers over SDA platform debt bindings when both serve an effect. Never design a new tree onto debt.

## Entries

Each independently invocable entry the specification names is its own capability. Its root scenario is reached through its CLI interface (<capabilityId>-cli, rootScenarioId). An external system is never an entry. It is a provider beneath an event (identity, data supply), or the input source of an estate-owned ingress capability that admits its signal. Never turn a provider id into a capability id to preserve a diagram.

## Authoring path

- Text is capability-dsl.v1, compiled by analysis.compile_capability_dsl. The installed compiler is ahead of read-capability-dsl-specification. It accepts capability, intent, outcome, inquiry (up to three), input contract, output contract, cli display, scenario [root] [terminal], given, when, then, operation kind invoke-port, bind or platform bind with platform, provider, statement, result or config, and provider binding. It also accepts the routing lines route, broadcast, join and recur (spec-scenario-topology). When the specification and the compiler disagree, read the compiler source (read-declared-object-source); the compiler decides.
- compile-capability-dsl compiles the text or refuses with DSL_* diagnostics and line numbers. Fix the source, never the compiled document.
- From a Markdown description: draft-capability-from-spec writes the DSL and the procedure it executes, compiles, preflights and stores the draft. Correct a draft by passing previousDraftArtifactId. plan-capability-flight then plans the build flight (install the procedure, read it back, declare from the draft DSL, read the declaration back) and, once declared, the first-call flight.
- From finished DSL: follow flight-pattern-declare-capability-from-dsl (apply-declared-change capability-from-dsl, then read-declared-capability-document expecting the first operation id).
- For a whole circuit at once, propose-capability-circuit returns a proposal (scenarios, providers, ports, Gherkin) for review. A proposal is not a declaration.
- Engineering revisions follow the proven pattern only: read-declared-object-source for the base, draft-object-revision and retain it, apply-engineering-change mode preflight, then mode commit, then read back and invoke. A one-step author-plus-install is not an execution pattern.
- Routes between the capability's scenarios are DSL lines too: route, broadcast with join, and recur. What each means, and when a compiled route is admissible, is in spec-scenario-topology.

## Making a build repeatable

When the same staged sequence will run more than once (a baseline, a verification, an install by digest), declare it as a workflow capability: a CAPABILITY_WORKFLOW declaration in sidefx:workflows (objective, promiseId, workClass workflow-run, stages in the flight-step shape with {{principalId}}, {{runKey}}, {{agentId}}, {{parameters.<name>}}) plus a three-port capability document that dispatches start-workflow-run. Follow flight-pattern-declare-capability-from-dsl and flight-pattern-workflow-run. Limits: parameters and binds are scalars, a stage cannot fly another run, and the host stops a run at 300 s.

## Do not

- Hand-write INSERT, UPDATE or DELETE where an installed writer expresses the change.
- Create scratch SQL, probe files or local scripts. A missing read or writer is the next task.
- Name a specific capability, scenario, contract or provider in runtime code.
- Reference legacy v_* views or functions not named fv_* in new declarations.
- Label a fixture provider as a live external integration.

## Evidence

For each capability, retain: the draft artifact id; compile status and document digest; procedure digests before and after; preflight and commit receipts; the read-declared-capability-document readback; read-declared-port-bindings for every port; the first-call run id and outcome; read-topology-conformance for the capability.

## Stop conditions

Stop when a provider claim cannot be confirmed by a declared read (refuse it by name), when a contract can only be completed by guessing, or when a needed writer is missing (declare the writer first, as its own task).

## Completion

The capability is declared, its providers are bound and pass their first calls, and its own first call returns the declared outcome on a real run. The readbacks show exactly what the draft declared.
