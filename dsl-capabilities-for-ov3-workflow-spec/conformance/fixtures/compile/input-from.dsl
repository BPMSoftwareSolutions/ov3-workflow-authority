# Fixture of case compile-input-from: an operation's input member names the earlier result it consumes (proposed lines).
capability dsl02-probe-input-from
intent: Fixture of compile-capability-dsl; compiled only, never declared.
outcome: dsl02-probe-input-from-result.v1
input contract dsl02-probe-input-from-request.v1 {"type":"object"}
output contract dsl02-probe-input-from-result.v1 {"type":"object"}
scenario dsl02-probe-input-from root terminal
given: a request naming a value
when: the value is read and then put to the model
then: the model's answer about the value
operation dsl02-probe-input-from.read uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"SELECT @input AS value;","resultColumn":"value"}
operation dsl02-probe-input-from.ask uses provider ask-model
input prompt from dsl02-probe-input-from.read $.value
