# Five Python bindings and two reuse objectives

The supply flight for estate model 34 started with five proposals in the content-addressed Python 3.15.2 report. Each public capability has its own canonical feature, bounded input/output contract, dependency, mechanic, provider identity and graph binding. The wrapper starts isolated CPython at a fixed executable path, sends JSON over standard input, and returns the actual implementation and version. Its configuration accepts caller data only.

The pilot narrows Base64 to padded, unwrapped UTF-8 and hashlib to SHA-256. Text wrapping accepts a paragraph and width. CRC-32 supports a starting unsigned CRC. HTML escaping supports the quote flag. The documentation version identifies the catalog source. The first server execution identified CPython 3.12.16.

## Supply and proof

[Revision 1](flight-report.md) was approved and flown. Its recording is `9389d42b-5bff-41c9-9012-8380c9043104`. It committed the textwrap authority and stopped on `TOPOLOGY_PROVIDER_LABEL_MISSING`. A separate live MCP invocation returned the lines `alpha` and `beta` for width 5.

[Revision 2](continuation-report.md) flew under recording `378a4400-4dcd-488d-a2ab-d63f000ad5dd`. It passed 26 steps, including the textwrap vector, both provider display labels, both topology checks, and the Base64 provider binding. The Base64 DSL install stopped on `CAPABILITY_FROM_DSL_FEATURE_NOT_DECLARED`, and 25 steps were skipped.

The Base64 feature was retained intact. In read-only run `15b1d3c7-df4d-4ba0-70fc-020fa5b3f5ec`, the installed writer decoded its example as `cafÃ©`, changing the SHA-256. The [decoder repair](repair-feature-decoding.sql) reads the same bytes through a UTF-8 column and preserves `café` and its digest. The patch checks the installed procedure's baseline and the exact changed body. Engineering preflight `df63b8f4-12c0-8bb8-2a38-98e387925501` verified the new body and rolled back.

From this directory, run `node check.mjs` to test the isolated programs locally against independent Node byte, Base64, CRC-32 and SHA-256 references. Run `node build-flight.mjs <temporary-plan-file>` to reproduce the first flight or append `--continuation` for revision 2. The PowerShell review command records a plan in the dedicated experiment slot and obtains the estate-generated review and report.

## Objective protocol

The [two frozen fixtures](experiment.json) use different inputs and deliverables. The notice requires wrapping and HTML escaping, followed by encoding, checksum and digest. The ledger preserves CRLF and Unicode and checks an intentionally incorrect claimed SHA-256. Its three shared operations are Base64, CRC-32 and SHA-256.

`node benchmark.mjs specimen notice` and `node benchmark.mjs specimen ledger` emit their objective texts and independent reference values. Supply only the request to OV3's normal `request-capability-from-objective-v3` entry point and use a separate conversation for each. The publisher accepts the resulting manifest values. Its independent verifier profile checks the original scope, retained bytes, actual inputs and outputs of the ordered calls, and their attached conversation and objective identities before routing typed obligations to System One.

`node build-publication.mjs` reproduces the publication DSL and the verifier profile. Rebuild the adjacent objective-verification DSL with its own builder. `node check-proof.mjs <temporary-directory>` generates read-only SQL probes with synthetic turn records. A production proof reads hashed estate turns from the original conversation. For independent offline readback, use `read-evidence.sql` through the declared reader and compare the retrieved artifact with `node benchmark.mjs verify <specimen> <evidence-file> <published-bytes-file>`.

The [recovery flight](recovery-report.md) installed all five public capabilities, the publisher and the extended verifier. Its last step paired a report digest with the wrong historical publication turn. The installed verifier rejected that pair and returned `FULFILLED` for the correct report in run `0ea941c2-f6b7-969c-dc74-0a58cef43bf7`.

The [benchmark](../../outputs/python-reuse-benchmark.md) records both default objectives, both portfolio-assisted pursuits, their genuine artifact bytes and the operation receipts. The staged verifier corroborates calculation receipts from the publication's own pursuit, honors a supplied leaf binding, and preserves Unicode in projected profile configurations. It accepted both genuine manifests and rejected eight altered cases, including a foreign leaf identity and a mismatched publication binding.

Record objective wall time and model attempts from the retained conversation. Use the verifier's own inference usage and trace interval for verification cost. Missing usage stays unknown. Count unprompted successful shared operations by stable identity in each verified execution. Record human corrections to the objective separately from supply-plan corrections. The two benchmark workloads differ, so a cost difference alone cannot establish causal savings.
