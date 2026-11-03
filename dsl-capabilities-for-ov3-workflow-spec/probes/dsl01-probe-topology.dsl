# dsl-01 probe: every compiled transition carries its semanticProgress.
capability dsl01-probe-topology
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
scenario intake root
variants: accepted:success,rejected:failure
operation dsl01-probe-topology.intake kind invoke-port port dsl01-pass
outcome-variants: passed:success,stopped:failure:terminal
platform bind dsl01-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"path","from":"input","path":""}}
scenario review
variants: approved:success,again:success,declined:failure
scenario dispatch
scenario leg-a
scenario leg-b
scenario settled terminal
scenario closed terminal
route intake accepted to review
route intake rejected to closed
route review approved to dispatch
route review declined to closed
recur review while again until approved max 3
broadcast dispatch to leg-a,leg-b
join settled from leg-a,leg-b
