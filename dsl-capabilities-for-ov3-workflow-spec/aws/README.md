# AWS cloud operations: curated features

These are the curated SideFX features for governed AWS cloud operations. They come from the candidate pack `../../sidefx-aws-cloud-operations/`, which is read only, and were corrected against the AWS documentation and the SideFX case format. [CURATION.md](CURATION.md) lists every change, the estate's current gap, and the next steps to live AWS.

## Status

The features are candidates. None is declared, bound or run, and every case is `@status:not-built`. The AWS recordings in the fixtures are synthetic: they follow the documented shapes but none was captured from an AWS account.

## Layout

| Path | What it holds |
| --- | --- |
| `features/incident/` | The P0 slice: signal, resource context, change evidence, service impact, recovery option, authorization, dispatch, verification, and the root incident circuit |
| `features/assurance/` | P1: configuration drift, cost variance, recovery readiness, security finding triage, operating posture |
| `fixtures/cases/` | One arrangement per case. `sidefx` holds what SideFX owns; `awsCalls` holds the AWS calls in order, with the documented request and response, error, or no response |
| `source/aws-documentation-manifest.json` | The 33 AWS pages the facts rest on, read on 2026-11-03 |
| `review/case-manifest.json` | Every case with its outcome, its AWS calls and its digests |
| `skeleton.json` | Each feature's declared tags, story, rule and Given/When/Then, kept word for word from the candidate pack |

## Regenerate and check

```
node make-aws-pack.mjs     # writes features/, fixtures/, source/, review/ from the curated cases
node check-aws-pack.mjs    # case format, fixture pins, documented AWS values, component references
```

Edit the cases in `make-aws-pack.mjs` and the AWS shapes in `aws-shapes.mjs`, never the generated files. The check must pass before anything is built on the pack.
