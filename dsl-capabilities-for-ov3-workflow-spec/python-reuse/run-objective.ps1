param(
    [Parameter(Mandatory)][ValidateSet('notice','ledger')][string]$Specimen,
    [Parameter(Mandatory)][guid]$ConversationId,
    [Parameter(Mandatory)][guid]$PrincipalId,
    [Parameter(Mandatory)][string]$EvidenceDirectory,
    [switch]$Portfolio,
    [switch]$ReadbackOnly
)
$ErrorActionPreference='Stop'
[void][IO.Directory]::CreateDirectory($EvidenceDirectory)
$prefix=Join-Path $EvidenceDirectory "$Specimen-$ConversationId"
$fixture=node (Join-Path $PSScriptRoot 'benchmark.mjs') specimen $Specimen | Out-String | ConvertFrom-Json -AsHashtable -DateKind String
if ($LASTEXITCODE -or !$fixture.request) { throw 'Missing frozen request' }
function Observe($Identity,$Request,$Label,$Key) {
    $log="$prefix-$Label.log"
    $argsList=@('capability','observe',$Identity,'--input','-','--input-type','json','--json','--auth','user')
    if($Key){$argsList+=@('--idempotency-key',$Key)}
    $raw=$Request | ConvertTo-Json -Compress -Depth 80 | sfx-api @argsList 2>$log | Out-String
    $code=$LASTEXITCODE
    $run=[regex]::Match([IO.File]::ReadAllText($log),'(?i)Run ([0-9a-f-]{36})').Groups[1].Value
    Write-Host "$Label $run"
    if ((!$raw.Trim() -or $code) -and $run) {
        $raw=sfx-api run $run --json --auth user | Out-String
        $code=$LASTEXITCODE
    }
    if (!$raw.Trim() -or $code) { throw "$Label returned no successful result. Inspect the retained run $run." }
    [IO.File]::WriteAllText("$prefix-$Label.json",$raw)
    return ($raw | ConvertFrom-Json -AsHashtable -Depth 100 -DateKind String)
}
$request=@{objective=$fixture.request;conversationId=$ConversationId.ToString();principalId=$PrincipalId.ToString()}
if ($Portfolio) {
    $request.visibleCapabilities=@('publish-python-reuse-result','python-base64','python-binascii','python-hashlib','python-html','python-textwrap')
}
if (!$ReadbackOnly) {
    [IO.File]::WriteAllText("$prefix-request.json",($request|ConvertTo-Json -Depth 5))
    $out=Observe 'request-capability-from-objective-v3' $request 'objective' "python-reuse-$ConversationId"
    Write-Host "Objective return: $($out.objectiveFulfillment) $($out.disposition)"
}
$query=@{dataSource='sfx-estate-database';resultColumn='value';statement=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'read-evidence.sql'));input=@{conversationId=$ConversationId.ToString()}}
$evidence=(Observe 'sql-database-reader' $query 'readback' $null).value
if ($evidence.conversationId -cne $ConversationId.ToString() -or $evidence.objective -cne $fixture.request) { throw 'Retained conversation does not match the frozen request' }
[IO.File]::WriteAllText("$prefix-evidence.json",($evidence|ConvertTo-Json -Compress -Depth 95))
Write-Host "Retained objective: $($evidence.objectiveFulfillment), $($evidence.receipts.Count) turns"
if($evidence.contentDigest -match '^sha256:[a-f0-9]{64}$'){
    $query.input=@{digest=$evidence.contentDigest}
    $query.statement="SELECT (SELECT c.content_bytes AS bytes FROM source.content_object c WHERE c.content_digest=TRY_CONVERT(binary(32),SUBSTRING(JSON_VALUE(@input,'$.digest'),8,64),2) AND c.content_digest=HASHBYTES('SHA2_256',c.content_bytes) FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;"
    $encoded=(Observe 'sql-database-reader' $query 'artifact' $null).value.bytes
    [IO.File]::WriteAllBytes("$prefix-artifact.json-bytes",[Convert]::FromBase64String($encoded))
    $proof=node (Join-Path $PSScriptRoot 'benchmark.mjs') verify $Specimen "$prefix-evidence.json" "$prefix-artifact.json-bytes"|Out-String
    if($LASTEXITCODE){throw 'Independent artifact and receipt check failed'}
    [IO.File]::WriteAllText("$prefix-independent.json",$proof)
}
