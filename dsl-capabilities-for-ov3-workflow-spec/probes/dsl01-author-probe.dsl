# dsl-01 probe: authored through the author path inside a transaction that always rolls back.
capability dsl01-author-probe
intent: Test source of dsl-01; declared only inside a transaction that rolls back.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
cli display outcome as json
provider binding dsl01-author-probe-binding.v1 {"bindingType":"sidefx-provider-input-binding.v1","id":"dsl01-author-probe-binding.v1","note":"dsl-01 author-path probe, rolled back"}
scenario dsl01-author-probe root terminal
given: a provider binding line and a configuration that names it
when: the source is authored through the author path
then: the binding content is minted before the document that names its digest is declared
operation dsl01-author-probe.pass kind invoke-port port dsl01-author-probe-pass
platform bind dsl01-author-probe-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"literal","value":"@provider-binding:dsl01-author-probe-binding.v1"}}
