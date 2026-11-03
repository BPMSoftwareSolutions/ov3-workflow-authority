# dsl-01 probe: a provider binding line, and a configuration that names it.
capability dsl01-probe-binding
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
provider binding dsl01-probe-binding.v1 { "bindingType": "sidefx-provider-input-binding.v1", "id": "dsl01-probe-binding.v1", "note": "spaces  inside a string stay" }
scenario dsl01-probe-binding root terminal
operation dsl01-probe-binding.pass kind invoke-port port dsl01-pass
platform bind dsl01-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"literal","value":"@provider-binding:dsl01-probe-binding.v1"}}
