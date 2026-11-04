# Python library research through OV3

For the complete report, invoke `generate-python-library-report` with `{"url":"https://docs.python.org/3/library/index.html"}`. It reads the full inventory, fills gaps using the estate scraper and proposal provider, reads the inventory again at publication, and retains the Markdown. The receipt includes the current, removed, proposed and missing counts, the module-index digest, and a retrievable report digest. The URL-only path can reuse matching public proposals retained in the preceding 24 hours. A partial result identifies the next missing modules. Reinvoking the same entry point reconciles saved batches before doing new work.

The inventory uses the library table of contents for sections and the Module Index for identities, including documented submodules, unlinked parent packages and removed modules. The proposal tool follows the documentation URL with the estate scraper and submits the retrieved text to the governed model provider.

## Source inventory

Call `read-python-library-sources` with `{"module":"json"}` for an exact lookup or `{"offset":0,"limit":10}` for a page. A limit of 400 requests the entire current population in one call. Follow any `nextOffset` with the returned `moduleIndexHash` as `expectedIndexHash`. A changed digest returns `SOURCE_CHANGED`. Removed entries remain in the inventory and carry `removed: true`. Each row includes its official documentation URL.

## Binding research

Pass a current row's documentation URL to `propose-python-library-binding`, for example `{"url":"https://docs.python.org/3/library/json.html#module-json"}`. A `PROPOSED` result contains the source URL and response hash, named APIs, JSON input and output contracts, constraints, failure modes, effects and five distinct ranked uses. The ranking is the model's assessment. A report proposal carries no claim that the proposed provider has been installed or executed.

## Assemble and resume

Pass the inventory conversation's UUID to `assemble-python-library-report` as `conversationId`. The tool reads the inventory snapshot and retained proposal turns, reconciles exact module names and documentation URLs, and publishes Markdown by content digest. A full report requires a full inventory. A single-module report accepts an exact inventory lookup when `module` is supplied. Every current module needs a proposal for its scope to return `COMPLETE`; retired modules appear separately. A `PARTIAL` receipt includes a count and up to ten missing modules for subsequent research.

For the full population, call `research-missing-python-libraries` with the same `conversationId`. Its declared loop partitions outstanding modules into groups of five. The internal `research-python-library-batch` capability retains each group as public documentation research. A subsequent pass starts from the remaining modules, and `maxModules` bounds a pass when needed. The report uses matching public batch results saved since the source inventory. When additional objective conversations contribute research, supply their UUIDs in `continuations`. Call the assembler again for the coverage receipt. Read the published Markdown with `read-retained-artifact` using the receipt's `contentDigest`.

## Rebuild and verify

Each `.feature` file owns the scenario wording, provider tags, case inputs and assertions. Run `node build.mjs` from this folder to regenerate the DSL files from the features and SQL read statements. The builder pins the SHA-256 of the feature bytes. The live `capability-from-dsl` authoring path checks the pin and binds the canonical feature in the same change. A local rebuild alone does not update the estate.

| Live verification | Run |
| --- | --- |
| Inventory installed with canonical feature conformance | `ac78e460-fcf7-0213-72fe-288419c5f0d3` |
| Proposal installed with canonical feature conformance | `a9de2b2f-cf71-c1f3-8f94-593e04135447` |
| Both entries returned by the MCP catalog | `ff7f7e65-38a7-5189-d969-f37cfdcd6508` |
| Complete source inventory, 321 names including 24 removed, compared by name to the official index | `28973a81-1c10-b9e7-ca2f-cd6ad89f8617` |
| OV3 selected both tools from a plain-language objective and produced the JSON module report entry | `5a44c9c7-affe-5a8f-d575-e35e744925cd` |
| Deliberately altered feature step returned DRIFT in a read-only check | `b67737e5-bfac-27eb-3c0f-3dde2ae035dd` |
| Report assembler installed | `2f23f897-1b98-3e3e-afbd-5951e9944b52` |
| Internal batch worker and public continuation workflow installed with canonical feature conformance | `54c22c50-ef8f-11c9-934a-757f2d0db55b`, `fdd89ff1-3e77-d579-dd6f-c0e705432f2a` |
| Assembler revision accepting public research batches installed with canonical feature conformance | `ebf51ffd-9649-669a-2c92-5fdec54163c1` |
| URL-only report entry installed with canonical feature conformance | `75663d2d-9c9d-6d4a-8c89-dd6af2c923e1` |
| Original natural-language objective selected the report generator, retried a partial return, and obtained a retained COMPLETE report covering 297 current and 24 removed modules | `5c2cb87c-fabb-13de-1b9b-9e13b483af99` |
| Final Markdown bytes retrieved and verified by digest; 321 unique indexed sections, 594 JSON contracts and 1,485 distinct-within-module ranked uses | `972a24bf-c9c2-7c24-564b-b89fd86ba476`, `sha256:f829e4240d5028337eee40276df101c935dc57573b35a11be826fc091ef57e03` |
| Continuation skipped the already-covered JSON module, with zero batches returned | `6a498d71-bece-fbb6-3e25-f2e34993513e` |
| Scoped JSON report published and its retained digest read back with one of one current modules covered | `3ce04e1a-15ec-8e21-0e3b-d40427091636` |

Run evidence can be retrieved with `sfx-api run <run-id> --json --auth user`.
