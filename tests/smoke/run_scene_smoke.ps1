[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ScenePath,
    [int]$Frames = 3,
    [int]$TimeoutMs = 5000
)

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$godot = $null
$runningGodot = Get-Process -Name 'Godot*' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($runningGodot) {
    try { $godot = (Get-CimInstance Win32_Process -Filter "ProcessId=$($runningGodot.Id)").ExecutablePath } catch { }
}
if (-not $godot) {
    $godot = 'C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe'
}
if (-not (Test-Path -LiteralPath $godot)) {
    Write-Error "Godot executable not found: $godot"
    exit 1
}

$arguments = @(
    '--headless', '--path', $projectRoot, '--scene',
    'res://tests/smoke/scene_smoke_runner.tscn', '--',
    "--scene=$ScenePath", "--frames=$Frames", "--timeout_ms=$TimeoutMs"
)
$output = @(& $godot @arguments 2>&1 | ForEach-Object { $_.ToString() })
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }

$hasEngineError = $output -match '(?i)(SCRIPT ERROR:|Parse Error|\bERROR:)'
$hasOnlyShutdownLeak = $hasEngineError -and (@($output | Where-Object { $_ -match '(?i)(ERROR: 1 resources still in use|ObjectDB instances leaked)' }).Count -gt 0) -and (@($output | Where-Object { $_ -match '(?i)ERROR:' -and $_ -notmatch '(?i)ERROR: 1 resources still in use' }).Count -eq 0)
$hasSmokePass = $output -match 'SMOKE_PASS scene='
$hasSmokeFail = $output -match 'SMOKE_FAIL '
if ($hasOnlyShutdownLeak) {
    Write-Output 'SMOKE_WARNING shutdown resource-leak signal (does not fail scene readiness)'
    $hasEngineError = $false
}
if ($exitCode -ne 0 -or -not $hasSmokePass -or $hasSmokeFail -or $hasEngineError) {
    Write-Error "Scene smoke test failed: $ScenePath (exit=$exitCode engine_error=$hasEngineError)"
    exit 1
}
exit 0
