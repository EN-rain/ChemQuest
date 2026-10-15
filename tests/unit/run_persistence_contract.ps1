[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$godot = 'C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe'
$args = @('--headless', '--path', $projectRoot, '--scene', 'res://tests/unit/persistence_contract_runner.tscn')
$output = @(& $godot @args 2>&1 | ForEach-Object { $_.ToString() })
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }

$unexpected = @($output | Where-Object { $_ -match 'CONTRACT_UNEXPECTED_FAIL|CONTRACT_RESULT FAIL' })
$passed = @($output | Where-Object { $_ -match 'CONTRACT_RESULT PASS' })
$scriptErrors = @($output | Where-Object { $_ -match '(SCRIPT ERROR:|Parse Error)' })
if ($unexpected.Count -gt 0 -or $scriptErrors.Count -gt 0 -or $passed.Count -ne 1 -or $code -ne 0) {
    Write-Error "Persistence contract suite failed (exit=$code pass=$($passed.Count) unexpected=$($unexpected.Count) script_errors=$($scriptErrors.Count))."
    exit 1
}
Write-Output "PERSISTENCE_PASS"
exit 0
