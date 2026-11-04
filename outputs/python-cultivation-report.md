# Python capability cultivation

Jev classified 1,485 ranked uses and, separately, all 297 bounded provider proposals against 1198 selected estate declarations captured at 2026-11-04T03:40:18.2534624Z.

| Advisory classification | Use cases | Proposed operations |
| --- | ---: | ---: |
| `REUSE` | 10 | 1 |
| `COMPOSE` | 5 | 1 |
| `NEW_MECHANIC_CANDIDATE` | 1315 | 264 |
| `UNRESOLVED` | 155 | 31 |

The operation column answers the binding-level question directly. Each candidate label identifies a gap to investigate in the retrieved records. Several proposals can share one gap. The number of unique new mechanics required is unproved.

The 264 candidate operations span 171 top-level Python package names. The largest groups are `email` (22), `xml` (13), `tkinter` (8), `multiprocessing` (7), `wsgiref` (7). Package membership identifies places to examine shared needs without assuming all members need the same mechanic.

Both positive operation labels were checked against their specific retrieved identities.

- `html#operation` (REUSE). The shortlist contains the subordinate escape-html mechanic. Its public candidates do not supply the optional quote behavior and length metadata as a complete callable contract.
- `textwrap#operation` (COMPOSE). The snapshot includes the partially installed python-textwrap identity, marked NON_CONFORMANT, and three records for its same binding. The pilot accepts text and width. The full proposal has additional TextWrapper options. Multiple records for one binding do not establish a runnable composition.

## Independent review

A blinded Codex review selected ten uses per rank by seeded hash, searched the full ontology, and inspected selected contracts. It agreed with Jev on 32 of 50 uses (64.0%, approximate 95% Wilson interval 50.14–75.86%). The interval describes this finite sample approximately and does not establish class-specific reliability.

For comparison, always choosing NEW_MECHANIC_CANDIDATE would agree on 37 of the same 50 cases.

| Class | Jev choices in sample | Reviewer choices | Agreements |
| --- | ---: | ---: | ---: |
| REUSE | 0 | 1 | 0 |
| COMPOSE | 0 | 2 | 0 |
| NEW_MECHANIC_CANDIDATE | 43 | 37 | 31 |
| UNRESOLVED | 7 | 10 | 1 |

- `enum#1` received NEW_MECHANIC_CANDIDATE from Jev and UNRESOLVED on independent review. schema-admission and unique could cover member-name validation. The required alias and flag semantics are not established by these declarations.
- `contextvars#1` received UNRESOLVED from Jev and NEW_MECHANIC_CANDIDATE on independent review. Telemetry observation supplies no enumeration of the active Python context's variables.
- `getpass#2` received NEW_MECHANIC_CANDIDATE from Jev and UNRESOLVED on independent review. Current estate principal and operating-system login need not coincide. The use does not say which identity is acceptable for the headers.
- `asyncio#2` received NEW_MECHANIC_CANDIDATE from Jev and UNRESOLVED on independent review. execute-bounded-process and scenario-orchestration are relevant. Combined timeout, parallel fanout and individual error retention for supplied tasks need contract evidence.
- `io#2` received NEW_MECHANIC_CANDIDATE from Jev and COMPOSE on independent review. array collects ordered text fragments and join returns one string with an empty separator. This meets incremental assembly before the handoff. A seekable stream is a stricter proposed operation.
- `urllib.request#2` received NEW_MECHANIC_CANDIDATE from Jev and UNRESOLVED on independent review. http-exchange-public accepts GET and HEAD, but its declared input offers no response-byte or read bound. A hard memory ceiling on actual downloads needs additional evidence.
- `inspect#3` received UNRESOLVED from Jev and NEW_MECHANIC_CANDIDATE on independent review. JSON contract validation does not implement Python signature binding for positional, keyword and variadic parameters.
- `xml.dom#3` received UNRESOLVED from Jev and NEW_MECHANIC_CANDIDATE on independent review. probe-runtime-modules does not resolve a DOM implementation or report the requested DOM features.
- `tkinter.simpledialog#3` received NEW_MECHANIC_CANDIDATE from Jev and UNRESOLVED on independent review. Existing login and password providers are credential-scoped. Their declarations do not establish reusable masked prompt authority for this workflow.
- `contextlib#3` received NEW_MECHANIC_CANDIDATE from Jev and COMPOSE on independent review. The fixture stack can be represented as an array, then projected in reverse ordinal order with a declared ordered query. This covers predicting order, not invoking arbitrary cleanup code.
- `multiprocessing#4` received UNRESOLVED from Jev and NEW_MECHANIC_CANDIDATE on independent review. None of the selected runtime probes covers the supported and default multiprocessing start methods for the host.
- `multiprocessing.dummy#4` received NEW_MECHANIC_CANDIDATE from Jev and UNRESOLVED on independent review. Scenario fanout and bounded processes exist. Neither declaration proves a parameterized fixed-width worker-thread pool for external calls.
- `sys#4` received UNRESOLVED from Jev and NEW_MECHANIC_CANDIDATE on independent review. No selected runtime probe returns filesystem encoding and host byte order together for data interchange.
- `wsgiref.headers#5` received NEW_MECHANIC_CANDIDATE from Jev and UNRESOLVED on independent review. join and map can render a simple CGI field, but safe header validation and handling repeated names are not established by that composition.
- `tempfile#5` received NEW_MECHANIC_CANDIDATE from Jev and UNRESOLVED on independent review. generate-random-identity and create-directory exist. Atomic exclusive creation, safe permissions and cleanup authority are not demonstrated.
- `random#5` received NEW_MECHANIC_CANDIDATE from Jev and REUSE on independent review. analysis-draw-seeded-range takes seed, count, low and high for reproducible integer fixtures. A no-replacement sample of an arbitrary population would be a different requirement.
- `xml.sax.xmlreader#5` received NEW_MECHANIC_CANDIDATE from Jev and UNRESOLVED on independent review. Comparing a supplied mapping could use existing collection mechanics. The namespace bindings, trace format and replay invariants to validate are unclear.
- `cmath#5` received UNRESOLVED from Jev and NEW_MECHANIC_CANDIDATE on independent review. Selected arithmetic primitives do not supply complex NaN/infinity classification or the requested complex-function behavior.

For the three reviewed uses judged realizable from existing declarations, 1 of three shortlists contained every witness identified by the reviewer. The stored shortlists allow retrieval misses to be distinguished from decisions made with the relevant declaration in view.

Two further read-only probes checked the disputed seeded-fixture judgment and an HTTP reuse case. Jev received analysis-draw-seeded-range for random#5 and selected NEW_MECHANIC_CANDIDATE. Two independent live calls with seed 42 both produced [74, 59, 46, 62], verifying reproducible integer fixtures. The separate random binding proposal requires sampling arbitrary items without replacement and returning Python generator state. A live http-exchange-public HEAD request returned HTTP 200, content type text/html and an empty body, supporting the reachability and content-type examples in http.client#1 and http.client#5. The probe receipts preserve the exact requests and provider returns.

A separate blind sample of 24 proposed operations agreed on 17 of 24. The measurement file records the evidence and label for every reviewed operation.

In a separate retrieval-friendly control, Jev called 6 of 6 existing capabilities REUSE when their own declared intents were supplied verbatim. These controls are excluded from both populations and the blind-sample accuracy.

## Usage and evidence

| Population | Jev calls | Input tokens | Output tokens |
| --- | ---: | ---: | ---: |
| Ranked uses | 149 | 1376930 | 91955 |
| Proposed operations | 30 | 312863 | 18397 |

The evidence ledger identifies every case, candidate shortlist, Jev version, probability vector, input digest and retained API run. The measurement file contains the full sample review, confusion matrix, calibration bins and batch usage. Billing and a frontier-model cost baseline were not observed.

All classifications remain advisory. The lexical shortlist included at most four public capabilities and four subordinate declarations. Missing vocabulary or missing contract detail can hide viable reuse. A matching label provides no executable composition or admission receipt.
