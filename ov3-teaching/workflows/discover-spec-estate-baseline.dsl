capability discover-spec-estate-baseline
intent: The workflow that captures the read-only estate baseline a specification pack is bound against. It is a workflow capability: its CAPABILITY_WORKFLOW declaration (sidefx:workflows/discover-spec-estate-baseline) declares seven stages over the run's parameter projectTaskId: read-mcp-catalog, read-agent-specializations, read-capability-dsl-specification, three read-declared-capability-document proofs that the specification-to-capability pipeline (propose-capability-circuit, draft-capability-from-spec, plan-capability-flight) is installed, then publish-workflow-verification for the task. Invoking it starts one run through start-workflow-run, recorded for agent workflow:discover-spec-estate-baseline/<run key>; the run is reviewed, approved and flown like every flight
outcome: workflow-run.v1 RECORDED with the run's agent, plan revision and digest and the digests it resolved, or NOT_FOUND
inquiry: Capture the estate baseline for this specification pack task.
inquiry: Start a run of the specification estate baseline workflow for this task.
inquiry: Which workflow records what the estate has installed before a specification is built?
input contract discover-spec-estate-baseline-request.v1 {"type":"object","additionalProperties":false,"required":["principalId","parameters"],"properties":{"principalId":{"type":"string","format":"uuid"},"runKey":{"type":"string","pattern":"^[a-z0-9][a-z0-9-]{0,39}$"},"parameters":{"type":"object","additionalProperties":false,"required":["projectTaskId"],"properties":{"projectTaskId":{"type":"string","minLength":1,"maxLength":400}}}}}
output contract workflow-run.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"workflow-run.v1"},"status":{"enum":["RECORDED","NOT_FOUND"]},"code":{"type":["string","null"]},"workflowCapabilityId":{"type":["string","null"]},"workflowCapabilityDigest":{"type":["string","null"]},"workflowDeclarationDigest":{"type":["string","null"]},"workflowRunKey":{"type":["string","null"]},"principalId":{"type":["string","null"]},"agentId":{"type":["string","null"]},"promiseId":{"type":["string","null"]},"workClass":{"type":["string","null"]},"objective":{"type":["string","null"]},"stageCount":{"type":["integer","null"]},"planRevision":{"type":["integer","null"]},"planDigest":{"type":["string","null"]},"next":{"type":["string","null"]}}}
cli display outcome as json
scenario discover-spec-estate-baseline root terminal
given: start-workflow-run composes and records runs of a declared workflow capability from the caller's parameters
when: a run of this workflow is started for the principal with the task the baseline is for
then: the run returns RECORDED with its agent, plan revision and digest
operation discover-spec-estate-baseline.start-request kind invoke-port port discover-spec-estate-baseline-start-request
operation discover-spec-estate-baseline.start kind invoke-port port discover-spec-estate-baseline-start
operation discover-spec-estate-baseline.return kind invoke-port port discover-spec-estate-baseline-return
platform bind discover-spec-estate-baseline-start-request
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"object","fields":{"executionTarget":{"op":"literal","value":"start-workflow-run"},"executionNamespace":{"op":"literal","value":"sidefx:capabilities"},"executionScenario":{"op":"literal","value":"start-workflow-run"},"inputType":{"op":"literal","value":"json"},"dispatchRequest":{"op":"merge","values":[{"op":"path","from":"input","path":""},{"op":"object","fields":{"workflowCapabilityId":{"op":"literal","value":"discover-spec-estate-baseline"}}}]}}}}
platform bind discover-spec-estate-baseline-start
platform: sda-node-consumer-runtime.v1
config: {"authoritySource":"DATABASE","capabilityIdPath":"executionTarget","requestPath":"dispatchRequest","namespacePath":"executionNamespace","scenarioPath":"executionScenario","resultPath":"result","lineageMode":"retain-nested-execution","providerId":"ScenarioKernel.NodePlatform"}
platform bind discover-spec-estate-baseline-return
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"path","from":"input","path":"result"}}
