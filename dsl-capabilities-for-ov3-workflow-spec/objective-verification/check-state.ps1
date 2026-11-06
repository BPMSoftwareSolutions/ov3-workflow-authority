# Read-only regression checks against the SQL used by the declared evidence provider.
$ErrorActionPreference = 'Stop'
$source = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'verify-objective-fulfillment.dsl')
$line = $source | Where-Object { $_ -like 'config: *' } | Select-Object -First 1
$statement = ($line.Substring(8) | ConvertFrom-Json -AsHashtable).statement
$request = @{conversationId='4ca89bb0-c7ed-4e95-bd19-603abb357b19';publicationTurn=3}
$cases = @(
    @{Name='typed integer'; Replace=$null; With=$null; Expected='INFER'},
    @{Name='string masquerading as count'; Replace="('use_cases',CONVERT(varchar(12),@requestedCount),"; With="('use_cases','`"5`"',"; Expected='HOLD'},
    @{Name='unknown obligation'; Replace="('use_cases',CONVERT(varchar(12),@requestedCount),"; With="('invented_obligation','5',"; Expected='HOLD'},
    @{Name='different requested count'; Replace='DECLARE @words TABLE'; With="SET @original=REPLACE(@original,'top 5','top 10'); DECLARE @words TABLE"; Expected='HOLD'; Count=10},
    @{Name='invented artifact section'; Replace="DECLARE @roster TABLE"; With="SET @report=REPLACE(@report,N'## json'+NCHAR(10),N'## bogus'+NCHAR(10)); DECLARE @roster TABLE"; Expected='HOLD'}
)
foreach($case in $cases) {
    $test=$statement
    if($case.Replace) {
        if(! $test.Contains($case.Replace)){throw "Fixture anchor changed for $($case.Name)"}
        $test=$test.Replace($case.Replace,$case.With)
    }
    $query=@{dataSource='sfx-estate-database';resultColumn='value';statement=$test;input=$request}
    $raw=$query | ConvertTo-Json -Depth 6 -Compress | sfx-api capability observe sql-database-reader --input - --json --auth user
    if($LASTEXITCODE -ne 0){throw "Run failed for $($case.Name)"}
    $value=(($raw -join [Environment]::NewLine) | ConvertFrom-Json -AsHashtable).value
    if($value.route -ne $case.Expected){throw "Unexpected route for $($case.Name)"}
    if($value.route -eq 'HOLD' -and $null -ne $value.state){throw 'An invalid state could reach inference'}
    if($case.ContainsKey('Count')){
        $use=$value.context.obligations | Where-Object id -eq 'use_cases'
        if($use.expected -ne $case['Count'] -or $use.observed -ne 5 -or $use.proof -ne 'UNPROVED'){throw 'Requested count was not bound from the objective'}
    }
    if($value.route -eq 'INFER'){
        $use=$value.state.obligations | Where-Object id -eq 'use_cases'
        if($use.expected -is [string] -or $use.expected -ne 5){throw 'Lost JSON integer type'}
    }
    Write-Output "$($case.Name) -> $($value.route)"
}
