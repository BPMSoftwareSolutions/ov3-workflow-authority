# Python capability reuse benchmark

## Revision 3 on the live estate

Flight recording `51a278c0-4f65-48f5-a153-b2defa5ffabf` ended `DEVIATED`. OV3 recorded `PROMISE_NOT_CLOSED` with 3 of 4 obligations closed and 13 of 15 steps passed.

- **notice** returned `UNVERIFIED` in 29.73 s within the flight. The independent checker matched the publication bytes and 5 operation receipts. Jev chose the manifest scope with confidence 0.89 (minimum 0.9) and probability 0.93, using 879 input and 50 output tokens. Conversation `19c8c396-5444-4399-b863-149913f469ee`.
- **ledger** returned `FULFILLED` in 24.92 s in a separate default pursuit after the flight skipped this step. The independent checker matched the publication bytes and 3 operation receipts. Jev chose the manifest scope with confidence 0.92 (minimum 0.9) and probability 0.95, using 1039 input and 50 output tokens. Conversation `b3881f09-eeed-41c0-8384-77d0c36d7dc9`.

All twelve deterministic checks passed for each publication, including exact equality between the original request and the pinned fixture. The notice had the same typed obligations as the earlier verified notice. Its fresh confidence score was below the declared threshold. The installed verifier therefore held it. The ledger cleared the same threshold.

[Executed flight report](../dsl-capabilities-for-ov3-workflow-spec/python-reuse/closure-report.md) · [Execution and objective receipts](python-reuse-flight-evidence.json)

OV3 executed five public CPython 3.12.16 bindings on the release notice. A second objective reused three of them on a Unicode ledger with CRLF line endings. Each used the same explicitly supplied six-tool portfolio. An independent byte and receipt check passed on both artifacts. All four original objective records ended `UNVERIFIED`.

| Objective | Tool selection | Artifact | Frontier / Jev calls | Pursuit time | Known tokens¹ | Verifier dispatch |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| notice | Default | None | 5 / 1 | 20.33 s | 12,556 (3/6 calls) | — |
| ledger | Default | None | 7 / 1 | 23.73 s | 13,654 (3/8 calls) | — |
| notice | Same six tools | 5 operation receipts | 7 / 1 | 31.69 s | 8,892 (3/8 calls) | 7.27 s |
| ledger | Same six tools | 3 operation receipts | 5 / 1 | 31.59 s | 9,093 (3/6 calls) | 11.02 s |

¹ Known tokens include observed input and output. Each trace covers the whole pursuit, but some model cells omit usage. Total tokens and dollar cost are unknown. Pursuit time is the interval on the estate record. Verifier dispatch measures the enclosing invocation.

## What changed between runs

With default discovery, the router used Jev’s first-action ranking to restrict every subsequent turn. The notice could wrap and escape its text. The ledger could encode and hash it. Neither could call the required CRC-32 capability from its selected tools. Neither published.

For the second pair, the only intervention was supplying the same six admitted MCP identities. Both requests retained their original wording. No tool sequence or expected values were supplied. The ledger reused Base64, CRC-32 and SHA-256, or 3 of its 3 required operations. No new provider was admitted between the two objectives. The different tasks and incomplete token telemetry do not establish cost savings.

## Byte checks and objective closure

The notice produced 49 UTF-8 bytes after wrapping and escaping, with CRC-32 `89264376`. The ledger preserved 13 UTF-8 bytes and CRLF, with CRC-32 `ff2987a7`. Its calculated SHA-256 differed from the supplied value. Both retained JSON artifacts and all eight ordered operation receipts passed independent verification. [Notice](python-reuse-notice.json) · [Ledger](python-reuse-ledger.json)

The installed verifier expected objective bindings on individual calculation receipts. OV3 binds its publication turn. The projected Unicode oracle was also misdecoded. The staged verifier checked the bound publication, immutable preceding turns, exact objective, input bytes, outputs and declared obligations. It accepted both real artifacts and rejected eight altered-evidence cases.

- ledger returned `FULFILLED` in the staged proof. Jev confidence was 0.92 and scope probability was 0.95. The model exchange took 1.25 s and used 1039 input and 50 output tokens.
- notice returned `FULFILLED` in the staged proof. Jev confidence was 0.94 and scope probability was 0.96. The model exchange took 0.81 s and used 879 input and 50 output tokens.

These are read-only retrospective decisions. The four historical outer outcomes retain their original dispositions. The source catalog is pinned to Python 3.15.2. [Receipts and measurements](python-reuse-benchmark.json) · [Supply flight evidence](python-reuse-flight-evidence.json)
