[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path,
    [string]$ReportPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'manifests/density-shared-asset-migration-20260908.md')
)

$ErrorActionPreference = 'Stop'

function Convert-ToAbsolutePath([string]$ResourcePath) {
    if (-not $ResourcePath.StartsWith('res://')) { return $null }
    return Join-Path $RepoRoot ($ResourcePath.Substring(6).Replace('/', '\'))
}

function Get-Hash([string]$ResourcePath) {
    $absolute = Convert-ToAbsolutePath $ResourcePath
    if (-not $absolute -or -not (Test-Path -LiteralPath $absolute -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $absolute -Algorithm SHA256).Hash.ToLowerInvariant()
}

$sourcePrefix = 'res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/level2-2/mattermaze/'
$targetPrefix = 'res://games/chapter_one/hometown/building_two/level2-2/mattermaze/'
$scanRoot = Join-Path $RepoRoot 'games/chapter_one/hometown/building_two/Level2-1/Scenes'
$files = @(Get-ChildItem -LiteralPath $scanRoot -Recurse -File | Where-Object {
    $_.Extension.ToLowerInvariant() -in @('.gd', '.tscn', '.tres', '.json') -and $_.FullName -notmatch '\\.godot\\'
})

$map = [ordered]@{}
$evidence = [ordered]@{}
foreach ($file in $files) {
    $text = [IO.File]::ReadAllText($file.FullName)
    foreach ($match in [regex]::Matches($text, 'res://[^"\r\n]+')) {
        $source = $match.Value.TrimEnd(',)]};').Replace('\', '/')
        if (-not $source.StartsWith($sourcePrefix) -or $map.Contains($source)) { continue }
        $target = $targetPrefix + $source.Substring($sourcePrefix.Length)
        $sourceHash = Get-Hash $source
        $targetHash = Get-Hash $target
        if (-not $sourceHash -or $sourceHash -ne $targetHash) { continue }
        $map[$source] = $target
        $evidence[$source] = $sourceHash
    }
}

$changed = [Collections.Generic.List[string]]::new()
foreach ($file in $files) {
    $text = [IO.File]::ReadAllText($file.FullName)
    $updated = $text
    foreach ($source in $map.Keys) { $updated = $updated.Replace($source, $map[$source]) }
    if ($updated -eq $text) { continue }
    [IO.File]::WriteAllText($file.FullName, $updated, [Text.UTF8Encoding]::new($false))
    $changed.Add($file.FullName.Substring($RepoRoot.Length + 1).Replace('\', '/'))
}

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Density shared-asset migration')
$lines.Add('')
$lines.Add("Generated: $(Get-Date -Format o)")
$lines.Add('')
$lines.Add('Only source/target pairs with identical SHA-256 content were redirected. No source assets were deleted and no UIDs were changed.')
$lines.Add('')
$lines.Add("- Exact texture mappings: $($map.Count)")
$lines.Add("- Canonical density scene files changed: $($changed.Count)")
$lines.Add('')
$lines.Add('## Mappings')
foreach ($source in $map.Keys) {
    $lines.Add(('- `' + $source + '` -> `' + $map[$source] + '` (SHA-256 `' + $evidence[$source] + '`)'))
}
$lines.Add('')
$lines.Add('## Changed files')
foreach ($path in $changed) { $lines.Add(('- `' + $path + '`')) }
$lines.Add('')
$lines.Add('Divergent scripts and non-identical assets remain in their original trees for semantic review; see `tasks/todo.md` owner decisions.')
Set-Content -LiteralPath $ReportPath -Value $lines -Encoding utf8
Write-Output "Density shared-asset migration complete: mappings=$($map.Count) files=$($changed.Count) report=$ReportPath"
