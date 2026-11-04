# Python capability cultivation

The study submits typed advisory decisions to the installed SideFX MCP capability `ask-system-one`. The host schedules bounded requests and resumes them by input digest. Jev chooses the labels. Estate writers do not consume them.

The [canonical vocabulary](classify-capability-cultivation.feature) supplies the actual choice criteria used by the batch generator. The [state schema](state.schema.json) and its validator check the case keys, source digests, declaration references, and question vocabulary. The result reader validates the returned model, input digest, question identities, label, confidence and all four probabilities.

The [ontology read](ontology.sql) captures the active capability versions and selected support declarations from one estate model. The retained snapshot freezes the comparison population. A declared identity may lack execution proof, and some ontology descriptions are empty. The retriever scores the use-case wording, the Python module, and its proposal against the identity, intent, outcome and available contracts. It gives Jev up to four public capability candidates and four subordinate declarations. Each decision retains the actual shortlist. A missed declaration can change the result.

## Replay

From this directory, use the pinned source report and ontology in the workspace's `outputs` directory. Use separate working directories for the two populations and the controls. PowerShell 7, Node and Python with `jsonschema` are needed for this replay.

```powershell
node classify.mjs "$useWork/requests" 10
node classify.mjs "$operationWork/requests" 10 operations
node controls.mjs "$controlWork/requests"
foreach ($dir in $useWork,$operationWork,$controlWork) {
    python validate-state.py "$dir/requests"
    if ($LASTEXITCODE) { throw 'Invalid input state' }
    ./run-batches.ps1 -Directory $dir
}
node sample.mjs "$useWork/blind-sample.json"
node summarize.mjs $useWork $operationWork ../../outputs $controlWork
./retain-study.ps1 -OutputDirectory (Resolve-Path ../../outputs).Path
```

Separate worker processes may claim disjoint ranges with `-Skip` and `-Limit`. An identical retained answer is skipped. A failed transport can be retried with the same idempotency key. The aggregation refuses to produce the report unless every source identity occurs exactly once and every answer passes the typed checks.

## Review and interpretation

The blind review used ten cases per rank, selected by SHA-256 order from the pinned population. A second blind sample reviewed 24 of the proposed operations. The [use-case adjudications](blind-review.tsv) and [operation adjudications](operation-review.tsv) record the independent judgments and reasons. A separate six-case control uses existing capabilities' own declared intents to test whether the decision profile recognizes direct matches when retrieval is favorable.

The output distinguishes the 1,485 business use cases from the 297 proposed bindings. A binding may need several pieces, or several bindings may share a primitive. Declaring a new mechanic, proving a composition, recording owner approval, and enabling an automated routing policy are separate estate actions.
