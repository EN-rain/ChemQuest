[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$godot = 'C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe'
$output = @(& $godot '--headless' '--path' $projectRoot '--scene' 'res://tests/unit/responsive_layout_runner.tscn' 2>&1 | ForEach-Object { $_.ToString() })
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
if ($code -ne 0 -or @($output | Where-Object { $_ -match 'RESPONSIVE_LAYOUT_RESULT PASS' }).Count -ne 1 -or @($output | Where-Object { $_ -match 'SCRIPT ERROR:|Parse Error|RESPONSIVE_LAYOUT_FAIL' }).Count -gt 0) {
    Write-Error "Responsive layout contract failed (exit=$code)."
    exit 1
}
Write-Output 'RESPONSIVE_LAYOUT_PASS'
exit 0
