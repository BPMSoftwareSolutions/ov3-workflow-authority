param(
    [Parameter(Mandatory)][string]$Directory,
    [int]$Limit=0, [int]$Skip=0
)
$ErrorActionPreference='Stop'
$resultDir=Join-Path $Directory 'answers'
[void][IO.Directory]::CreateDirectory($resultDir)
$files=@(Get-ChildItem -LiteralPath (Join-Path $Directory 'requests') -Filter 'batch-*.json' | Sort-Object Name | Select-Object -Skip $Skip)
if($Limit -gt 0) { $files=@($files | Select-Object -First $Limit) }
foreach ($file in $files) {
    $ErrorActionPreference='Stop'
    $out=Join-Path $resultDir $file.Name
    $req=[IO.File]::ReadAllText($file.FullName)|ConvertFrom-Json -AsHashtable -Depth 64
    $key=$req.context.inputDigest
    if(Test-Path -LiteralPath $out){
        $previous=[IO.File]::ReadAllText($out)|ConvertFrom-Json -AsHashtable -Depth 64
        if($previous.answer.status -eq 'ANSWERED' -and $previous.answer.context.inputDigest -eq $key){continue}
        throw "Conflicting retained response for $($file.Name)"
    }
    $log=Join-Path $resultDir ($file.BaseName+'.log')
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $wire=sfx-api capability observe ask-system-one --input ('@'+$file.FullName) --input-type json --auth user --json --idempotency-key ('jev-cultivation-'+$key.Substring(7)) 2>$log | Out-String
    $rc=$LASTEXITCODE
    $run=[regex]::Match([IO.File]::ReadAllText($log),'(?i)Run ([a-f0-9-]{36})').Groups[1].Value
    if(!$wire.Trim() -or $rc -ne 0) { Write-Warning "$($file.Name) transport $rc run $run";continue }
    $answer=$wire|ConvertFrom-Json -AsHashtable -Depth 64 -DateKind String
    if(!$run -or $answer.status -cne 'ANSWERED' -or $answer.context.inputDigest -cne $key){
        [IO.File]::WriteAllText((Join-Path $resultDir ($file.BaseName+'.finding')),$wire)
        Write-Warning "$($file.Name) returned $($answer.status) run $run";continue
    }
    $rec=[ordered]@{runId=$run;wallMs=$watch.ElapsedMilliseconds;answer=$answer}
    [IO.File]::WriteAllText($out,($rec|ConvertTo-Json -Compress -Depth 64))
    Write-Output "$($file.BaseName) $run $($answer.answers.Count) choices"
}
