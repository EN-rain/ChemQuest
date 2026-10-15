[CmdletBinding()]
param(
    [int]$Width = 1280,
    [int]$Height = 720
)

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$godot = 'C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe'
if (-not (Test-Path -LiteralPath $godot)) {
    Write-Error "Godot executable not found: $godot"
    exit 1
}

$arguments = @(
    '--headless', '--path', $projectRoot, '--scene',
    'res://tests/unit/responsive_touch_runner.tscn', '--',
    "--width=$Width", "--height=$Height"
)
$output = @(& $godot @arguments 2>&1 | ForEach-Object { $_.ToString() })
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
$pass = @($output | Where-Object { $_ -match "RESPONSIVE_TOUCH_RESULT PASS size=$Width`x$Height" }).Count -eq 1
$fail = @($output | Where-Object { $_ -match 'SCRIPT ERROR:|Parse Error|RESPONSIVE_TOUCH_FAIL' }).Count -gt 0
if ($code -ne 0 -or -not $pass -or $fail) {
    Write-Error "Responsive touch contract failed at ${Width}x${Height} (exit=$code)."
    exit 1
}
Write-Output "RESPONSIVE_TOUCH_PASS ${Width}x${Height}"
exit 0
