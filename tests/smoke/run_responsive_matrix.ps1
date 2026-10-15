[CmdletBinding()]
param(
    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$sceneManifestPath = Join-Path $PSScriptRoot 'responsive_scenes.json'
$viewportManifestPath = Join-Path $PSScriptRoot 'responsive_viewports.json'
$sceneManifest = Get-Content -Raw -LiteralPath $sceneManifestPath | ConvertFrom-Json
$viewportManifest = Get-Content -Raw -LiteralPath $viewportManifestPath | ConvertFrom-Json
$results = [System.Collections.Generic.List[object]]::new()

foreach ($viewport in $viewportManifest.viewports) {
    foreach ($scene in $sceneManifest.active) {
        $begin = Get-Date
        $runOutput = @(& (Join-Path $PSScriptRoot 'run_responsive_scene.ps1') -ScenePath $scene.path -Width $viewport.width -Height $viewport.height 2>&1 | ForEach-Object { $_.ToString() })
        $code = $LASTEXITCODE
        $failure = ($runOutput | Where-Object { $_ -match '(?i)(RESPONSIVE_FAIL|SCRIPT ERROR:|Parse Error|Responsive scene test failed)' } | Select-Object -First 1)
        if (-not $failure -and $code -ne 0) { $failure = 'responsive wrapper returned nonzero' }
        if ($failure) { $failure = $failure.Replace('|', '\u007c') }
        $results.Add([pscustomobject]@{
            viewport = $viewport.id
            width = $viewport.width
            height = $viewport.height
            scene = $scene.id
            path = $scene.path
            status = if ($code -eq 0) { 'PASS' } else { 'FAIL' }
            failure = $failure
            duration_ms = [int]((New-TimeSpan -Start $begin -End (Get-Date)).TotalMilliseconds)
        })
    }
}

$pass = @($results | Where-Object status -eq 'PASS').Count
$fail = @($results | Where-Object status -eq 'FAIL').Count
if (-not $OutputPath) { $OutputPath = Join-Path $projectRoot 'tasks/responsive-runtime-baseline.md' }
$report = @()
$report += '# Responsive runtime baseline'
$report += ''
$report += "Generated: $(Get-Date -Format o)"
$report += "Matrix entries: $($results.Count); pass: $pass; fail: $fail"
$report += ''
$report += '| Viewport | Size | Scene | Result | Duration (ms) | Failure signal |'
$report += '|---|---:|---|---:|---:|---|'
foreach ($result in $results) {
    $report += "| $($result.viewport) | $($result.width)x$($result.height) | $($result.scene) | $($result.status) | $($result.duration_ms) | $($result.failure) |"
}
$report += ''
$report += 'The responsive runner validates manifest-critical Controls and TouchScreenButtons after a five-frame readiness window. Portrait entries validate the global rotate-device guard.'
Set-Content -LiteralPath $OutputPath -Value ($report -join [Environment]::NewLine) -Encoding utf8
Get-Content -LiteralPath $OutputPath
if ($fail -gt 0) { exit 1 }
exit 0
