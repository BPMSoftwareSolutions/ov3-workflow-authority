# Records the supply plan in this experiment's own slot and requests deterministic review.
# It never records approval or triggers flight execution. Reuse an identical saved plan.
param([switch]$Continuation,[switch]$Recovery,[switch]$Closure,[switch]$MarkdownPage,[switch]$MarkdownPageCsharp,[string]$VerifierDigest,[string]$ReplaceRecoveryDigest,[string]$ReplaceMarkdownDigest)
$ErrorActionPreference = 'Stop'
function Invoke-Capability($Identity, $Body) {
    $json = ConvertTo-Json -InputObject $Body -Depth 95 -Compress
    $raw = $json | sfx-api capability observe $Identity --input - --input-type json --json --auth user | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Failed to observe $Identity. Inspect the retained run." }
    return ($raw | ConvertFrom-Json -AsHashtable -Depth 100 -DateKind String)
}
$planFile = [IO.Path]::GetTempFileName()
try {
    if (([int]$Recovery.IsPresent+[int]$Continuation.IsPresent+[int]$Closure.IsPresent+[int]$MarkdownPage.IsPresent+[int]$MarkdownPageCsharp.IsPresent) -gt 1) { throw 'Choose one flight' }
    if ($MarkdownPageCsharp) {
        node (Join-Path $PSScriptRoot '../markdown-page/build-flight-r4.mjs') $planFile
    } elseif ($MarkdownPage) {
        node (Join-Path $PSScriptRoot '../markdown-page/build-flight.mjs') $planFile $VerifierDigest
    } elseif ($Closure) {
        node (Join-Path $PSScriptRoot 'build-closure-flight.mjs') $planFile
    } elseif ($Recovery) {
        node (Join-Path $PSScriptRoot 'build-recovery-flight.mjs') $planFile
    } elseif ($Continuation) {
        node (Join-Path $PSScriptRoot 'build-flight.mjs') $planFile --continuation
    } else {
        node (Join-Path $PSScriptRoot 'build-flight.mjs') $planFile
    }
    if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
    $flight = [IO.File]::ReadAllText($planFile) | ConvertFrom-Json -AsHashtable -Depth 99 -DateKind String
    if ($Continuation -and 'textwrap-display-label' -notin $flight.steps.stepId) { throw 'Continuation guard failed' }
} finally { Remove-Item -LiteralPath $planFile }
$login = sfx-api whoami --json | ConvertFrom-Json
if (!$login.principalId) { throw 'A signed-in estate principal is required' }
$identity = @{ principalId = $login.principalId; agentId = $flight.agentId }
$steps = ConvertTo-Json -InputObject $flight.steps -Depth 95 -Compress
$existing = Invoke-Capability 'read-flight-plan' $identity
if ($existing.status -eq 'NOT_FOUND' -and !$Continuation -and !$Closure) {
    $promise = ConvertTo-Json -InputObject $flight.promise -Depth 95 -Compress
    $change = @{contractId='declared-change.v1';changeKind='content-artifact-change';payload=@{
        contractId='content-artifact-change.v1';artifactKind="flight-promise:$($flight.promise.promiseId)";text=$promise
        verificationCapabilityId='read-harness-authoring-state';route=@{resolvedDisposition='terminated'}
        preflight=@{input=@{changeKind='content-artifact-change';includeDefinitions=$true};expected=@{disposition='terminated'}}
    }}
    $retained = Invoke-Capability 'apply-declared-change' $change
    if ($retained.disposition -cne 'COMMITTED') { throw 'Promise retention failed' }
    $saved = Invoke-Capability 'record-flight-plan' ($identity + @{objective=$flight.objective;stepsJson=$steps})
    if ($saved.status -cne 'RECORDED') { throw ('Plan record failed: ' + ($saved | ConvertTo-Json -Compress -Depth 5)) }
    $saved | Select-Object -ExcludeProperty steps | Out-Host
} elseif (($Closure -and $existing.status -eq 'READ' -and $existing.planDigest -ceq 'ede07e38ee00b6071443236709d7e8492152894b8cf6ceada0bd4a6c582e667e') -or
          ($Continuation -and $existing.status -eq 'READ' -and $existing.planDigest -ceq '44a472b228ec4f5d302277f5d5e4d2c50d591e600f3d25010af2337a21bae731') -or
          ($Recovery -and $existing.status -eq 'READ' -and $ReplaceRecoveryDigest -cmatch '^[0-9a-f]{64}$' -and $existing.planDigest -ceq $ReplaceRecoveryDigest) -or
          ($MarkdownPage -and $existing.status -eq 'READ' -and $ReplaceMarkdownDigest -cmatch '^[0-9a-f]{64}$' -and $existing.planDigest -ceq $ReplaceMarkdownDigest)) {
    if ($Closure) {
        $previous = Invoke-Capability 'read-flight-closure' ($identity + @{promiseId=$flight.promise.promiseId})
        if ($previous.planDigest -cne $existing.planDigest -or $previous.executionStatus -cne 'DEVIATED' -or
            $previous.executionDigest -cne 'sha256:2918dff689788635e3afd39ddd75c47e7880ea43709cb11a68415d6f98f817d2') { throw 'Recovery recording differs from reviewed baseline' }
    } elseif ($Recovery -or $MarkdownPage) {
        $replacePin = if ($MarkdownPage) { $ReplaceMarkdownDigest } else { $ReplaceRecoveryDigest }
        $clearance = Invoke-Capability 'resolve-flight-clearance' ($identity + @{promiseId=$flight.promise.promiseId})
        if ($clearance.planDigest -cne $replacePin -or $clearance.status -cne 'NOT_CLEARED' -or
            ($clearance.requirements | Where-Object requirement -eq 'OWNER_APPROVAL').satisfied -ne $false) { throw 'Cannot replace a cleared or unrecognized plan' }
    }
    $saved = Invoke-Capability 'record-flight-plan' ($identity + @{objective=$flight.objective;stepsJson=$steps})
    if ($saved.status -cne 'RECORDED') { throw 'Continuation was not recorded' }
    $saved | Select-Object planRevision,planDigest | ConvertTo-Json
} elseif ($existing.status -ne 'READ') {
    throw "Plan lookup returned $($existing.status)"
} else {
    $stored = if ($existing.steps -is [array]) { ConvertTo-Json -InputObject $existing.steps -Compress -Depth 95 } else { $existing.stepsJson }
    if ($stored -cne $steps) { throw 'Existing plan differs. Inspect its revision before changing it.' }
}
$review = Invoke-Capability 'review-flight-plan' ($identity + @{promiseId=$flight.promise.promiseId})
$report = Invoke-Capability 'generate-flight-plan-report-md' $identity
$review | Select-Object -Property verdict,status,planDigest,findings | ConvertTo-Json -Depth 20
$report | Select-Object -Property status,planDigest,reportDigest,contentDigest | ConvertTo-Json
if ($report.markdown) {
    $name = if ($MarkdownPageCsharp) { '../markdown-page/flight-report-r4.md' } elseif ($MarkdownPage) { '../markdown-page/flight-report.md' } elseif ($Closure) { 'closure-report.md' } elseif ($Recovery) { 'recovery-report.md' } elseif ($Continuation) { 'continuation-report.md' } else { 'flight-report.md' }
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot $name),$report.markdown)
}
