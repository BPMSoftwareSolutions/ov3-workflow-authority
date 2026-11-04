# Retain evidence through the declared content writer. Does not declare a classifier,
# set a routing policy or change any capability/provider identity.
param([Parameter(Mandatory)][string]$OutputDirectory,[switch]$SnapshotOnly)
$ErrorActionPreference='Stop'
$kinds=[ordered]@{'python-cultivation-ontology.json'='ontology'}
if (!$SnapshotOnly) {
    $kinds['python-cultivation-decisions.jsonl']='decisions'
    $kinds['python-cultivation-measurements.json']='measurements'
    $kinds['python-cultivation-report.md']='report'
    $kinds['python-cultivation-probes.json']='probes'
}
$receipts=[ordered]@{}
foreach($name in $kinds.Keys) {
    $file=Join-Path $OutputDirectory $name
    $bytes=[IO.File]::ReadAllBytes($file)
    $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    $kind='python-cultivation-study:'+ $kinds[$name]
    $req=@{contractId='declared-change.v1';changeKind='content-artifact-change';payload=@{
        contractId='content-artifact-change.v1';artifactKind=$kind;text=[Text.Encoding]::UTF8.GetString($bytes)
        verificationCapabilityId='read-harness-authoring-state';route=@{resolvedDisposition='terminated'}
        preflight=@{input=@{changeKind='content-artifact-change';includeDefinitions=$true};expected=@{disposition='terminated'}}
    }}
    $tmp=[IO.Path]::GetTempFileName()
    $log=[IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllText($tmp,($req|ConvertTo-Json -Depth 12 -Compress))
        $raw=sfx-api capability observe apply-declared-change --input ('@'+$tmp) --json --auth user --idempotency-key ('cultivation-retain-'+$hash) 2>$log | Out-String
        $run=[regex]::Match([IO.File]::ReadAllText($log),'(?i)Run ([a-f0-9-]{36})').Groups[1].Value
        if($LASTEXITCODE -or !$raw.Trim()) { throw "Retention failed for $name (run $run)" }
        $receipt=$raw|ConvertFrom-Json -AsHashtable -Depth 95 -DateKind String
        if($receipt.disposition -cne 'COMMITTED' -or !$raw.Contains('sha256:'+$hash)) { throw "Digest mismatch for $name (run $run)" }
        $receipts[$name]=[ordered]@{kind=$kind;digest='sha256:'+$hash;bytes=$bytes.Length;runId=$run}
        Write-Output "$name $run sha256:$hash"
    } finally { Remove-Item -LiteralPath $tmp; Remove-Item -LiteralPath $log }
}
if(!$SnapshotOnly){ [IO.File]::WriteAllText((Join-Path $OutputDirectory 'python-cultivation-receipts.json'),($receipts|ConvertTo-Json -Depth 8)) }
