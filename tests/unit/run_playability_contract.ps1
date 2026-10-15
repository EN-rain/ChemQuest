$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$godot = 'C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe'
if (-not (Test-Path -LiteralPath $godot)) {
    throw "Godot executable not found: $godot"
}
$output = @(& $godot '--headless' '--path' $projectRoot '--scene' 'res://tests/unit/playability_contract_runner.tscn' 2>&1 | ForEach-Object { $_.ToString() })
$code = $LASTEXITCODE
$output | Write-Output
if ($code -ne 0 -or -not ($output -match 'PLAYABILITY_CONTRACT PASS')) {
    throw "Playability contract failed (exit=$code)."
}
