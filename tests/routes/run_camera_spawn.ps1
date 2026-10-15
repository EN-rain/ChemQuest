[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$godot = 'C:\Users\LENOVO\Desktop\GodotGDScript\Godot_v4.6.1-stable_win64.exe'
$viewports = @(
    @{ id = 'minimum_landscape'; width = 854; height = 480 },
    @{ id = 'tablet_4_3'; width = 1024; height = 768 },
    @{ id = 'reference_16_9'; width = 1280; height = 720 },
    @{ id = 'tablet_16_10'; width = 1280; height = 800 },
    @{ id = 'desktop_full_hd'; width = 1920; height = 1080 },
    @{ id = 'phone_wide'; width = 2400; height = 1080 },
    @{ id = 'desktop_ultrawide'; width = 2560; height = 1080 },
    @{ id = 'portrait_guard'; width = 720; height = 1280 }
)
$spawns = @('default', 'from_building_one', 'from_building_two', 'from_hometown')
$results = [System.Collections.Generic.List[object]]::new()

foreach ($viewport in $viewports) {
    foreach ($spawn in $spawns) {
        $args = @('--headless', '--path', $projectRoot, '--scene', 'res://tests/routes/camera_spawn_runner.tscn', '--', '--route-test', "--width=$($viewport.width)", "--height=$($viewport.height)", "--spawn=$spawn")
        $output = @(& $godot @args 2>&1 | ForEach-Object { $_.ToString() })
        $code = $LASTEXITCODE
        $failure = ($output | Where-Object { $_ -match 'CAMERA_SPAWN_FAIL|SCRIPT ERROR:|Parse Error' } | Select-Object -First 1)
        $passed = @($output | Where-Object { $_ -match 'CAMERA_SPAWN PASS' }).Count -eq 1
        $results.Add([pscustomobject]@{ viewport = $viewport.id; spawn = $spawn; size = "$($viewport.width)x$($viewport.height)"; status = if ($code -eq 0 -and $passed -and -not $failure) { 'PASS' } else { 'FAIL' }; failure = $failure })
    }
}

$pass = @($results | Where-Object status -eq 'PASS').Count
$fail = @($results | Where-Object status -eq 'FAIL').Count
$results | Format-Table -AutoSize | Out-String | Write-Output
Write-Output "CAMERA_SPAWN_MATRIX pass=$pass fail=$fail"
if ($fail -gt 0) { exit 1 }
exit 0
