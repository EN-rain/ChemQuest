[CmdletBinding()]
param([string]$OutputPath = '')

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$matrixPath = Join-Path $PSScriptRoot 'scenes.json'
$matrix = Get-Content -Raw -LiteralPath $matrixPath | ConvertFrom-Json
$results = [System.Collections.Generic.List[object]]::new()
$started = Get-Date

foreach ($entry in $matrix.active) {
    $begin = Get-Date
    $runOutput = @(& (Join-Path $PSScriptRoot 'run_scene_smoke.ps1') -ScenePath $entry.path 2>&1 | ForEach-Object { $_.ToString() })
    $code = $LASTEXITCODE
    $reason = ''
    $warning = ''
    if ($code -ne 0) {
        $reason = ($runOutput | Where-Object { $_ -match '(?i)(SCRIPT ERROR:|Parse Error|ERROR:|SMOKE_FAIL)' } | Select-Object -First 1)
        if (-not $reason) { $reason = 'smoke wrapper returned nonzero' }
        $reason = $reason.Replace('|', '\u007c')
    }
    $warning = ($runOutput | Where-Object { $_ -match 'SMOKE_WARNING' } | Select-Object -First 1)
    if ($warning) { $warning = $warning.Replace('|', '\u007c') }
    $results.Add([pscustomobject]@{
        id = $entry.id; path = $entry.path; role = $entry.role
        status = if ($code -eq 0) { 'PASS' } else { 'FAIL' }
        reason = $reason
        warning = $warning
        duration_ms = [int]((New-TimeSpan -Start $begin -End (Get-Date)).TotalMilliseconds)
    })
}

$pass = @($results | Where-Object status -eq 'PASS').Count
$fail = @($results | Where-Object status -eq 'FAIL').Count
$report = @()
$report += '# Runtime regression snapshot'
$report += ''
$report += "Generated: $(Get-Date -Format o)"
$report += "Godot: $((Get-Process -Name 'Godot*' -ErrorAction SilentlyContinue | Select-Object -First 1).Path)"
$report += "Matrix entries: $($results.Count); pass: $pass; fail: $fail"
$report += ''
$report += '| ID | Role | Result | Duration (ms) | Path | Failure signal | Warning signal |'
$report += '|---|---|---:|---:|---|---|---|'
foreach ($result in $results) {
    $report += "| $($result.id) | $($result.role) | $($result.status) | $($result.duration_ms) | ``$($result.path)`` | $($result.reason) | $($result.warning) |"
}
$report += ''
$report += 'Orphan candidates are listed separately in `tests/smoke/scenes.json` and are not included in the active baseline.'
$report += ''
$report += 'The smoke wrapper requires `SMOKE_PASS` and rejects script/parse/startup errors. A known shutdown resource-leak signature is reported as a warning for the affected density scene and does not hide scene-readiness failures.'

if (-not $OutputPath) { $OutputPath = Join-Path $projectRoot 'tasks/runtime-baseline.md' }
Set-Content -LiteralPath $OutputPath -Value ($report -join [Environment]::NewLine) -Encoding utf8
Get-Content -LiteralPath $OutputPath
if ($fail -gt 0) { exit 1 }
exit 0
