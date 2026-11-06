---
name: ov3-teaching-channels
description: "How knowledge actually reaches the OV3 network (it does not read skills at run time), and the status of the ov3-teaching pack for the workflow-authority spec"
metadata:
  node_type: memory
  type: project
  originSessionId: 943f8284-49a5-427b-8011-8b6850817b0f
  modified: 2026-11-02T16:08:21.096Z
---

OV3 (`request-capability-from-objective-v3`, engine `analysis.objective_agent_step`) reads only the objective, `agent-memory:<principal>`, earlier turns and the MCP catalog. It never reads skills. Skill content reaches a model only via `read-specialist-context`, which only `coordinate-project-task` (RESOLVE) calls. What OV3 executes deterministically is flight plans and `CAPABILITY_WORKFLOW` declarations (`sidefx:workflows`, run through `start-workflow-run`). Source: sfx-embody/docs/research/skills-in-the-estate/README.md §5.

So "teaching OV3" means three things: tracker tasks that name capabilities and pin skills; skills (filed via the `agent-specialization-change` skill member); and workflow capabilities for repeatable sequences. "Workflow" collides: the estate's CAPABILITY_WORKFLOW is not a spec's scenario progression.

As of 2026-11-02, the teaching pack is at `c:\lab\ov3-workflow-authority-spec\ov3-teaching\` and is NOT FILED: 4 skills, project `ov3-estate-workflow-fidelity` with 16 tasks, a W0 workflow `discover-spec-estate-baseline`, and 4 flight candidates under planner id `claude-code-opus-5-5-ov3-teaching`. The DSL compiled and the expectation paths were checked against real rows. Skill read-back must use `{skillId, skillRevision}` and compare `contentDigest` (base64 SHA-256); `missing:false` is a constant. The five `flight-pattern-*` skills proposed 2026-10-27 are a soft dependency (references are prose only).

Trap: `read-capability-dsl-specification` lags `analysis.compile_capability_dsl`. The compiler also accepts `inquiry:`, `route`, `broadcast`/`join` and `recur ... max n`; read the compiler source before claiming the DSL can't do something. Only `recur` emits `semanticProgress`. As of 2026-11-02, revision 1 of `graph-topology-emission` is empty while it reads `RETAINED`. SQL batch 1 (01/02) ran on 2026-11-02 and is frozen; batch 2 (03/04) re-records skills-1, skills-2 and project at revision 2 and adds the gte repair flight.

**Why:** The spec pack assumed OV3 could be "taught" by documents. The estate only acts on rows it reads.
**How to apply:** Put new know-how into task pins plus workflow capabilities, not just skills. Check `read-agent-specializations` before assuming any pack skill is filed. Related: [[sfx-api-invocation-from-bash]]
