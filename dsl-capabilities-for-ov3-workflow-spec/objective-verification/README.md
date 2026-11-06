# Verifying published objectives

`verify-objective-fulfillment` is a declared MCP capability. Its input identifies a conversation and a retained publication turn. The verifier reads the original objective, the producer's actual return, the published content bytes and the proof artifacts. The objective loop invokes it automatically on the answer turn when the last business call returned a content-addressed artifact. The business call remains visible in `invocationResult`. The independent verdict appears in `verification` and controls `objectiveFulfillment`.

## TypeSafe boundary

[The JSON Schema](objective-obligations.schema.json) declares the exact `objective-obligations.v1` state sent to System One. Each obligation carries a stable identity, a discriminated kind, its quantifier and operator, expected and observed values, and a deterministic proof result. Both the schema and the SQL type checks are built from [the same type definitions](obligation-types.json). A typed snapshot is an object with the source URI, documentation version and SHA-256. A ranked count is an integer.

```json
{"id":"use_cases","kind":"ranked_count","operator":"exactly","quantifier":"each_current_module","expected":5,"observed":5,"proof":"PROVED"}
```

The source-specific reader supplies typed observations. The generic verifier compares them and requires the associated independent checks. It resolves an explicit requested use-case count before testing the supported count. It sends the original request and validated obligation vector to `ask-system-one` only on the `INFER` route. A single typed choice selects a complete work contract, an extra or different requirement, or an uncertain scope. Fulfillment requires both the expected choice and numerical confidence and probability of at least 0.90. Model identity and actual usage are in the receipt. Model inference can vary; the acceptance rules are fixed. The `HOLD` route returns the failed proof checks and skips inference.

## Source and evidence

[The first proof profile](profiles/python-library.json) pins the official Module Index identified by its title as Python 3.15.2. Its raw bytes have SHA-256 `87c31423f0ffe824d2dd2dd8369ad352413e61e77f4dd30cd6867c5e1d85044f`. The profile also pins the full inventory snapshot. It compares the source population, each report section, both JSON contracts and five distinct ranked uses against retained, hash-checked research batches. The receipt identifies the matched batches, the original scraper receipt, the source title and both evidence digests. Earlier reports that recorded only the index hash can be verified against those archived bytes. New publications include the explicit version and URL in their Markdown and publication receipt.

The profile allowlist binds producer identities, returned contract and source digest. A new source release or a new artifact family requires a reviewed profile and evidence reader. The generic scope decision and outer objective hook stay independent of those families.

## Rebuild and replay

Run `node build.mjs` in this directory to reproduce the feature-pinned DSL and JSON Schema. [The canonical feature](verify-objective-fulfillment.feature) describes the evidence, inference and hold scenarios. [The read-only regression script](check-state.ps1) exercises the evidence statement on valid, wrong-typed, unknown and altered evidence. It uses the staging estate's declared SQL reader.

For a historical check use `{"conversationId":"4ca89bb0-c7ed-4e95-bd19-603abb357b19","publicationTurn":3,"expectedSourceVersion":"3.15.2"}`. A retrospective verification produces a fresh receipt. Historical API outputs retain the result observed when they ran.

`build-wrapper.mjs <installed-source> <candidate>` applies the answer-turn changes only to the expected native procedure digest. The governed deployment drafts and retains that candidate, preflights it, preflights the digest-guarded installer, checks the live base again and commits the installer. In-flight publication turns retain a hash of the actual objective. The answer observer checks the verdict's conversation, objective, turn, publication receipt and artifact identities before accepting it. The returned outer fulfillment also requires successful conversation-record retention.

## Retained verification

| Test | Live run | Outcome |
| --- | --- | --- |
| Replay the original request through `request-capability-from-objective-v3` | `5364d981-3ef2-3a5b-dc5d-43bb94591efb` | Outer `FULFILLED`, 297 proved current modules, 24 removed modules identified |
| Replay with the fully declared TypeSafe input carrier on the final verifier revision | `f6235d12-bdba-c872-d9d0-896e337579f5` | Outer `FULFILLED`, same published bytes and six validated obligations |
| Read the conversation and its answer turn after completion | `6b5d4b51-75e5-acbe-9315-ac3fdf9bfaf4` | Both records hold the same verdict and publication digest |
| Request ten uses against the report that contains five | `abc206b0-048e-6824-4261-c1b7a67bc0d3` | Outer `UNVERIFIED`, expected integer 10, observed integer 5, inference skipped |
| Request Python 3.15.1 against the published 3.15.2 report | `644d87c7-5d3c-347b-eea7-6e19374b99de` | `UNVERIFIED`, inference skipped |
| Inspect the partial publication turn | `e83978d8-38d0-1604-a13e-ae3eef3ab89a` | `UNVERIFIED`, missing module coverage and incomplete publication |
| Test scope inference with an added deployment obligation | `3467ac6f-c043-10ab-c7d9-d54a362c833c` | System One selected `other` |

The verified report has SHA-256 `94a77a826d7822419a8fe8c2d00275048a541c1a1d6aff4f753835abcad0c966` and was retrieved in run `c1e84dc2-92b3-57c2-96d4-e54c16fdb161`. The final conversation receipt has SHA-256 `daccbea4f40d87dd41cf8c2e2ea6aff9c2863613847128293956736536e71d9e` and was retrieved in run `2b6328dc-61f4-aa87-c024-bb85a46fb48b`.
