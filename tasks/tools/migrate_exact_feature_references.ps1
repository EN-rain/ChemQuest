[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path,
    [string]$ReportPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'manifests/feature-migration-20260907.md')
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

function Get-CandidateMap([string[]]$Files, [string]$SourcePrefix, [string]$TargetPrefix) {
    $map = [ordered]@{}
    foreach ($file in $Files) {
        $text = [IO.File]::ReadAllText($file)
        foreach ($match in [regex]::Matches($text, 'res://[^"\r\n]+')) {
            $source = $match.Value.TrimEnd(',)]};').Replace('\', '/')
            if (-not $source.StartsWith($SourcePrefix) -or $map.Contains($source)) { continue }
            $target = $TargetPrefix + $source.Substring($SourcePrefix.Length)
            $sourceHash = Get-Hash $source
            $targetHash = Get-Hash $target
            if ($sourceHash -and $sourceHash -eq $targetHash) {
                $map[$source] = $target
            }
        }
    }
    return $map
}

function Rewrite-Files([string[]]$Files, [hashtable]$Map) {
    $changed = [Collections.Generic.List[object]]::new()
    foreach ($file in $Files) {
        $text = [IO.File]::ReadAllText($file)
        $updated = $text
        foreach ($source in $Map.Keys) { $updated = $updated.Replace($source, $Map[$source]) }
        if ($updated -eq $text) { continue }
        [IO.File]::WriteAllText($file, $updated, [Text.UTF8Encoding]::new($false))
        $changed.Add([pscustomobject]@{ path = $file.Substring($RepoRoot.Length + 1).Replace('\', '/'); replacements = @($Map.Keys | Where-Object { $text.Contains($_) }).Count })
    }
    return $changed
}

function Get-TextFiles([string]$Root) {
    return @(Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object {
        $_.Extension.ToLowerInvariant() -in @('.gd', '.tscn', '.tres', '.json') -and $_.FullName -notmatch '\\.godot\\'
    } | ForEach-Object { $_.FullName })
}

$densityRoot = Join-Path $RepoRoot 'games/chapter_one/hometown/building_two/Level2-1'
$statesRoot = Join-Path $RepoRoot 'games/chapter_one/hometown/building_two/level2-2/mattermaze'
$densityFiles = Get-TextFiles $densityRoot | Where-Object { $_ -notmatch '\\Level2-1\\Level2-1\\' }
$statesFiles = Get-TextFiles $statesRoot

$densitySourcePrefix = 'res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/'
$densityTargetPrefix = 'res://games/chapter_one/hometown/building_two/Level2-1/'
$statesSourcePrefix = 'res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/level2-2/mattermaze/'
$statesTargetPrefix = 'res://games/chapter_one/hometown/building_two/level2-2/mattermaze/'

$densityMap = Get-CandidateMap $densityFiles $densitySourcePrefix $densityTargetPrefix
$statesMap = Get-CandidateMap $statesFiles $statesSourcePrefix $statesTargetPrefix
$densityChanged = Rewrite-Files $densityFiles $densityMap
$statesChanged = Rewrite-Files $statesFiles $statesMap

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Exact feature-reference migration')
$lines.Add('')
$lines.Add("Generated: $(Get-Date -Format o)")
$lines.Add('')
$lines.Add('Only references whose source and target files existed and had identical SHA-256 hashes were rewritten. No source files were deleted.')
$lines.Add('')
$lines.Add("- Density mappings: $($densityMap.Count); files changed: $($densityChanged.Count)")
$lines.Add("- States mappings: $($statesMap.Count); files changed: $($statesChanged.Count)")
$lines.Add('')
$lines.Add('## Density mappings')
foreach ($source in $densityMap.Keys) { $lines.Add(('- `' + $source + '` -> `' + $densityMap[$source] + '`')) }
$lines.Add('')
$lines.Add('## States mappings')
foreach ($source in $statesMap.Keys) { $lines.Add(('- `' + $source + '` -> `' + $statesMap[$source] + '`')) }
$lines.Add('')
$lines.Add('## Changed files')
foreach ($entry in @($densityChanged + $statesChanged)) { $lines.Add(('- `' + $entry.path + '` (' + $entry.replacements + ' mapping(s))')) }
Set-Content -LiteralPath $ReportPath -Value $lines -Encoding utf8
Write-Output "Exact migration complete: density=$($densityMap.Count) states=$($statesMap.Count) files=$(@($densityChanged + $statesChanged).Count) report=$ReportPath"
