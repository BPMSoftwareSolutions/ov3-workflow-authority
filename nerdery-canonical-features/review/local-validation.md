# Feature validation

Cucumber parsed 19 features and compiled 150 acceptance cases. The local checks verified 564 assertion rows, case-specific source and decision links, fixture digests and references, media bytes, and agreement with the derived indexes. All ten negative controls produced the expected findings.

## Estate feature-only check

The repository conformance procedure ran read-only through `sql-database-reader` as a session-local procedure. All 19 feature digests returned `WELL_FORMED`. The [validation record](../derived/static-validation.json) lists each checked digest and case count.

| Run | Files | Cases |
|---|---:|---:|
| `41b9dc32-2583-5cb0-202a-c6acbec95260` | 4 | 43 |
| `58503c34-3c40-091c-d6c3-5640f2fd4285` | 4 | 33 |
| `6068df07-ea74-9715-580e-b2031667925f` | 4 | 35 |
| `f4c19b1c-4eec-b2f1-f104-dddce4c2e026` | 4 | 23 |
| `04fd1837-2cf3-46c8-6432-129118888950` | 3 | 16 |

## Evidence still due

Estate model 34 had no selected capability under any of the 19 proposed Nerdery IDs (inventory run `49ae8acb`). The [provider review](provider-bindings.md) records four live calls to the selected read provider on synthetic fixtures. Product-operation bindings and proofs for the named candidates remain open. Runtime acceptance requires the case’s own call, matching operation and result, and independent read-back for mutations. Browser, accessibility, load and offline-device tests also remain open.

## Local negative controls

| Control | Finding |
|---|---|
| changed-event-identity | `IDENTITY_MISMATCH` |
| changed-when-step | `STEP_TEXT_MISMATCH` |
| changed-operation | `ASSERTION_OPERATION_MISMATCH` |
| missing-request | `REQUEST_DOCSTRING_MISSING` |
| missing-status-assertion | `CASE_STATUS_UNASSERTED` |
| unknown-outcome-variant | `OUTCOME_VARIANT_UNDECLARED` |
| duplicate-case-id | `CASE_IDENTITY_DUPLICATE` |
| claimed-proof | `CASE_STATUS_MISMATCH` |
| invalid-json | `REQUEST_INVALID` |
| tampered-fixture-bytes | `FIXTURE_DIGEST_MISMATCH` |
