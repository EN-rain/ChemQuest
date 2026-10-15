[CmdletBinding()]
param(
    [string]$OutputDirectory = '',
    [string]$ReportPath = ''
)

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$sceneManifestPath = Join-Path $PSScriptRoot 'responsive_scenes.json'
$sceneManifest = Get-Content -Raw -LiteralPath $sceneManifestPath | ConvertFrom-Json
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $projectRoot 'tasks/builds/responsive-screenshots' }
if (-not $ReportPath) { $ReportPath = Join-Path $projectRoot 'tasks/responsive-screenshot-baseline.md' }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$results = [System.Collections.Generic.List[object]]::new()
foreach ($scene in $sceneManifest.active) {
    $fileName = ($scene.id -replace '[^A-Za-z0-9_.-]', '_') + '.png'
    $outputPath = Join-Path $OutputDirectory $fileName
    $output = @(& (Join-Path $PSScriptRoot 'run_responsive_scene.ps1') `
        -ScenePath $scene.path -Width 1280 -Height 720 -ScreenshotPath $outputPath `
        -Render `
        2>&1 | ForEach-Object { $_.ToString() })
    $code = $LASTEXITCODE
    $output | ForEach-Object { Write-Output $_ }
    $item = Get-Item -LiteralPath $outputPath -ErrorAction SilentlyContinue
    $hash = if ($item) { (Get-FileHash -Algorithm SHA256 -LiteralPath $outputPath).Hash } else { '' }
    $results.Add([pscustomobject]@{
        scene = $scene.id
        path = $scene.path
        status = if ($code -eq 0 -and $item) { 'PASS' } else { 'FAIL' }
        bytes = if ($item) { $item.Length } else { 0 }
        sha256 = $hash
    })
}

$pass = @($results | Where-Object status -eq 'PASS').Count
$fail = @($results | Where-Object status -eq 'FAIL').Count
$report = @('# Responsive 1280x720 reference screenshots', '')
$report += "Generated: $(Get-Date -Format o)"
$report += "Scenes: $($results.Count); pass: $pass; fail: $fail"
$report += ''
$report += 'Screenshots are generated under ignored `tasks/builds/responsive-screenshots/`; hashes make a later visual-baseline refresh auditable.'
$report += ''
$report += '| Scene | Result | PNG bytes | SHA-256 |'
$report += '|---|---:|---:|---|'
foreach ($result in $results) {
    $report += "| $($result.scene) | $($result.status) | $($result.bytes) | $($result.sha256) |"
}
Set-Content -LiteralPath $ReportPath -Value ($report -join [Environment]::NewLine) -Encoding utf8
Get-Content -LiteralPath $ReportPath
if ($fail -gt 0) { exit 1 }
exit 0
