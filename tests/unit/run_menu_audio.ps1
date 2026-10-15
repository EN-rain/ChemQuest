[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$godot = 'C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe'
$output = @(& $godot '--headless' '--path' $projectRoot '--scene' 'res://tests/unit/menu_audio_runner.tscn' 2>&1 | ForEach-Object { $_.ToString() })
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
if ($code -ne 0 -or @($output | Where-Object { $_ -match 'AUDIO_RESULT PASS' }).Count -ne 1 -or @($output | Where-Object { $_ -match 'SCRIPT ERROR:|Parse Error|AUDIO_FAIL' }).Count -gt 0) {
    Write-Error "Menu audio contract failed (exit=$code)."
    exit 1
}
Write-Output 'MENU_AUDIO_PASS'
exit 0
