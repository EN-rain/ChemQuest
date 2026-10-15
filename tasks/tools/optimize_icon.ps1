[CmdletBinding()]
param(
    [string]$IconPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path 'icon.svg'),
    [string]$ReportPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'manifests/icon-optimization.md')
)

$ErrorActionPreference = 'Stop'
$originalBytes = [IO.File]::ReadAllBytes($IconPath)
$originalHash = ([Security.Cryptography.SHA256]::Create()).ComputeHash($originalBytes) | ForEach-Object { $_.ToString('x2') }
$originalHash = -join $originalHash
$content = [Text.Encoding]::UTF8.GetString($originalBytes)
$matches = [regex]::Matches($content, '<rect\s+x="(?<x>\d+)"\s+y="(?<y>\d+)"\s+width="1"\s+height="1"\s+fill="(?<fill>#[0-9A-Fa-f]{6})"\s*/>')
if ($matches.Count -ne 40000) { throw "Expected 40,000 one-pixel rectangles; found $($matches.Count). Refusing to rewrite icon." }

$pixels = @{}
foreach ($match in $matches) {
    $x = [int]$match.Groups['x'].Value
    $y = [int]$match.Groups['y'].Value
    if ($x -lt 0 -or $x -ge 200 -or $y -lt 0 -or $y -ge 200) { throw "Pixel coordinate outside 200x200 canvas: $x,$y" }
    $key = "$x,$y"
    if ($pixels.ContainsKey($key)) { throw "Duplicate pixel coordinate: $key" }
    $pixels[$key] = $match.Groups['fill'].Value.ToUpperInvariant()
}
if ($pixels.Count -ne 40000) { throw "Pixel coverage is incomplete: $($pixels.Count) unique coordinates." }

$builder = [Text.StringBuilder]::new()
[void]$builder.AppendLine('<?xml version="1.0" encoding="UTF-8" ?>')
[void]$builder.AppendLine('<svg version="1.1" width="200" height="200" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">')
$runCount = 0
for ($y = 0; $y -lt 200; $y++) {
    $x = 0
    while ($x -lt 200) {
        $fill = $pixels["$x,$y"]
        $start = $x
        while (($x + 1) -lt 200 -and $pixels.ContainsKey("$($x + 1),$y") -and $pixels["$($x + 1),$y"] -eq $fill) { $x++ }
        $width = $x - $start + 1
        [void]$builder.AppendLine(('  <rect x="{0}" y="{1}" width="{2}" height="1" fill="{3}" />' -f $start, $y, $width, $fill))
        $runCount++
        $x++
    }
}
[void]$builder.AppendLine('</svg>')
[IO.File]::WriteAllText($IconPath, $builder.ToString(), [Text.UTF8Encoding]::new($false))
$optimizedBytes = [IO.File]::ReadAllBytes($IconPath)
$optimizedHash = ([Security.Cryptography.SHA256]::Create()).ComputeHash($optimizedBytes) | ForEach-Object { $_.ToString('x2') }
$optimizedHash = -join $optimizedHash
$optimizedSize = $optimizedBytes.Length

$report = @(
    '# Project icon optimization',
    '',
    "Generated: $(Get-Date -Format o)",
    '',
    'The icon was rewritten with horizontal run-length rectangles. Every original 1x1 pixel coordinate and color was validated before writing; the raster content is unchanged.',
    '',
    ('- Original bytes: ' + $originalBytes.Length + '; SHA-256: `' + $originalHash + '`'),
    ('- Optimized bytes: ' + $optimizedSize + '; SHA-256: `' + $optimizedHash + '`'),
    "- Original rectangles: $($matches.Count); optimized rectangles: $runCount",
    "- Size reduction: $([math]::Round((1 - ($optimizedSize / [double]$originalBytes.Length)) * 100, 2))%"
)
Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8
Write-Output "Icon optimized: $($originalBytes.Length) -> $optimizedSize bytes, rectangles=$runCount report=$ReportPath"
