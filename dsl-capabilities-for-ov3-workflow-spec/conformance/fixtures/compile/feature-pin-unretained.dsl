# Fixture of case compile-feature-pin-unretained: pins a digest under which no bytes are retained.
capability dsl02-probe-feature-first
feature dsl02-probe-feature-first sha256:0000000000000000000000000000000000000000000000000000000000000000
intent: Fixture of compile-capability-dsl; compiled only, never declared.
outcome: dsl02-probe-feature-first-result.v1
input contract dsl02-probe-feature-first-request.v1 {"type":"object"}
output contract dsl02-probe-feature-first-result.v1 {"type":"object","properties":{"status":{"enum":["READ"]}}}
scenario dsl02-probe-feature-first root terminal
given: a request naming a value
when: the provider reads it
then: the result carries the value
operation dsl02-probe-feature-first.read uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"SELECT @input AS value;","resultColumn":"value"}
outcome from dsl02-probe-feature-first.read $
