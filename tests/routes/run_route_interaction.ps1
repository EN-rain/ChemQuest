[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$godot = 'C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe'
$output = @(& $godot '--headless' '--path' $projectRoot '--scene' 'res://tests/routes/route_interaction_runner.tscn' '--' '--route-test' 2>&1 | ForEach-Object { $_.ToString() })
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
$passed = @($output | Where-Object { $_ -match 'ROUTE_INTERACTION PASS' })
$failures = @($output | Where-Object { $_ -match 'ROUTE_INTERACTION_FAIL|SCRIPT ERROR:|Parse Error' })
if ($code -ne 0 -or $passed.Count -ne 1 -or $failures.Count -gt 0) {
    Write-Error "Route interaction suite failed (exit=$code pass=$($passed.Count) failures=$($failures.Count))."
    exit 1
}
Write-Output 'ROUTE_INTERACTION_PASS'
exit 0
