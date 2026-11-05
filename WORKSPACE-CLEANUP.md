# Workspace authority correction — 2026-11-05

The owner required removal of local process drivers and misleading continuation
material before delivery resumes. The contract already assigns the lifecycle to
OV3; C12/FP03 were not fulfilled by the frontier agent's local implementation.

## External recovery record

The quarantine is **outside this checkout**, at:

`C:\lab\ov3-workspace-history\2026-11-05-authority-correction`

- `workspace-before-cleanup.zip`: all 2,432 physical working-tree files before
  cleanup, including tracked, untracked and modified files; every member was
  read back and SHA-256 checked.
- `inventory.json`: original paths, byte lengths, SHA-256 and tracked/untracked
  classification. `git-status-before.txt` and `tracked-changes-before.patch`
  preserve the pre-existing working-tree changes.
- Archive SHA-256: `56f3b99e8f6d2a229abc365c37991f16e1b30acf2ae1040244a69c154a15c4b3`.
- Inventory SHA-256: `baa14a7ead2665e694e9abe0c841d297308b793737c9103449d478dd7153d64a`.
- `verification.json`, `cleanup-plan.json` and `cleanup-result.json` record the
  preservation and cleanup checks. Housekeeping scripts also remain outside
  this workspace; they are not OV3 capabilities or continuation tools.

No archive, quarantine directory, restoration script or link back to quarantined
content belongs in this workspace. Do not index or extract the archive during
normal continuation. Recover a specific artifact only for an explicit recovery
request, initially outside the checkout, checking its recorded digest.

## Removed from the active working tree

The cleanup removed 2,414 original files: local FP00 implementations and runners,
approval generators, flight builders, repair/rehearsal scripts, captured request
and response data, generated builds, demo code, and historical mission packs.
The old wildlife handoff and local-command continuation instructions were replaced.
The archive preserves those historical bytes without treating them as current
authority or deleting the record of failed attempts.

A `node_modules` junction exposed another 8,531 external runtime files to workspace
traversal. The junction was removed; its installed runtime target was preserved.
The snapshot contains the workspace-owned files, not that external dependency
tree. This distinction accounts for the original 10,963 visible files.

The retired local preview's empty directory tree was moved outside the checkout.
An automatic approval review rejected the command to stop that process with
`blocked by policy`; the cleanup did not terminate it. No demo source remains in
the workspace. Git history and live OV3 state were not rewritten or rolled back.

## Preserved authority and truthful status

The exact revision-3 contract, schemas, canonical feature/DSL, verification profile,
finite model, owner intent, reference deck, canonical topology SVG and formal
strategy remain. The deck and SVG keep their original `outputs/` paths because
the unchanged contract pins those paths; they are reference inputs, not run output.

All 21 original manifest members remain byte-identical in the external snapshot.
Historical checker/authoring scripts and their local receipts are intentionally
absent from the active checkout. The unchanged manifest and verification profile
still record their historical identities; they do not instruct an agent to rebuild
a local toolchain. The retained OV3 bundle remains a separate readback source.

The new entry points state that OV3 owns the objective, TypeSafe/System One handles
bounded inference through declared roles, and native deterministic checks retain
acceptance authority. Existing OV3 capabilities must be discovered before new
supply is proposed. No delivery gate or autonomous-product completion is claimed.

The attached TypeSafe/Jev example supplied direction, not executable authority.
Its simulated choices, fixed confidence, invented model metadata and hard-coded
usage/cost are not copied into the implementation or treated as measured evidence.
