[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ScenePath,
    [Parameter(Mandatory = $true)]
    [int]$Width,
    [Parameter(Mandatory = $true)]
    [int]$Height,
    [int]$Frames = 5,
    [int]$TimeoutMs = 10000,
    [string]$ScreenshotPath = '',
    [switch]$Render
)

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$godot = 'C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe'
if (-not (Test-Path -LiteralPath $godot)) {
    Write-Error "Godot executable not found: $godot"
    exit 1
}

$arguments = @(
    '--path', $projectRoot, '--scene',
    'res://tests/smoke/responsive_layout_runner.tscn', '--',
    "--scene=$ScenePath", "--width=$Width", "--height=$Height", "--frames=$Frames"
)
if (-not $Render) { $arguments = @('--headless') + $arguments }
if ($ScreenshotPath) { $arguments += "--screenshot=$ScreenshotPath" }
$output = @(& $godot @arguments 2>&1 | ForEach-Object { $_.ToString() })
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
$pass = @($output | Where-Object { $_ -match "RESPONSIVE_PASS scene=$([regex]::Escape($ScenePath)) size=$Width`x$Height" }).Count -gt 0
$fail = @($output | Where-Object { $_ -match 'SCRIPT ERROR:|Parse Error|RESPONSIVE_FAIL' }).Count -gt 0
if ($code -ne 0 -or -not $pass -or $fail) {
    Write-Error "Responsive scene test failed: $ScenePath at ${Width}x${Height} (exit=$code)."
    exit 1
}
Write-Output "RESPONSIVE_SCENE_PASS $ScenePath ${Width}x${Height}"
exit 0
