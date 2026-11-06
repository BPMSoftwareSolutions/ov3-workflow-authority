# dsl-01 probe: lines the compiler accepted before and must now refuse.
capability dsl01-probe-refusals
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
scenario entry root
variants: again:success,next:success
scenario second-entry root
scenario ping
variants: pong:success
scenario pong
variants: ping:success
scenario caller
operation dsl01-probe-refusals.call kind invoke-scenario scenario no-such-scenario
operation dsl01-probe-refusals.self kind invoke-scenario scenario caller
scenario marked
variants: done:success:terminal
scenario settle terminal
route entry again to entry
route entry next to ping
route ping pong to pong
route pong ping to ping
join settle from ping,pong
