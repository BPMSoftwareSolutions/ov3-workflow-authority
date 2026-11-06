# Fixture of check case conf-compile-greeting-pin: a source for compile-capability-dsl that pins the greeting scaffold the
# estate retains under sha256:9f2f5b4e... It must refuse, naming each drift.
capability compile-capability-dsl
feature compile-capability-dsl sha256:9f2f5b4ea73e97b4b3134f56b845fe698587dcd536b5899ba9a388e98376f7ab
intent: Compile capability DSL into the declared document, or refuse with named diagnostics
outcome: compile-capability-dsl-result.v1 COMPILED or REFUSED
input contract compile-capability-dsl-request.v1 {"type":"object","additionalProperties":false,"required":["source"],"properties":{"source":{"type":"string","minLength":1,"maxLength":65536}}}
output contract compile-capability-dsl-result.v1 {"type":"object","required":["contractId","status"],"properties":{"status":{"enum":["COMPILED","REFUSED"]}}}
scenario compile-capability-dsl root terminal
given: DSL source text on the declared grammar
when: the resolver parses every line and validates the whole document
then: the compiled capability document with its digests, or the named DSL_* refusals with line numbers
operation compile-capability-dsl.compile uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"EXEC analysis.compile_capability_dsl @input=@input,@estate_model_pk=NULL;","resultColumn":"value"}
input input from compile-capability-dsl $
outcome from compile-capability-dsl.compile $.value
