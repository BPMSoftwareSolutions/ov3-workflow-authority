# dsl-01 probe: provider binding lines and placeholders the compiler refuses.
capability dsl01-probe-binding-refusals
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
provider binding dsl01-dup.v1 {"a":1}
provider binding dsl01-dup.v1 {"a":2}
provider binding dsl01-bad.v1 {"a":
provider binding Bad_Id {"a":1}
scenario dsl01-probe-binding-refusals root terminal
operation dsl01-probe-binding-refusals.pass kind invoke-port port dsl01-pass
platform bind dsl01-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"literal","value":"@provider-binding:no-such-binding.v1"}}
