[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path,
    [string]$OutputDirectory = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'manifests')
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

function Convert-ToAbsolutePath([string]$ResourcePath) {
    if (-not $ResourcePath.StartsWith('res://')) { return $null }
    return Join-Path $RepoRoot ($ResourcePath.Substring(6).Replace('/', '\'))
}

function Get-ResourceKind([string]$ResourcePath) {
    $extension = [IO.Path]::GetExtension($ResourcePath).ToLowerInvariant()
    switch ($extension) {
        '.tscn' { return 'scene' }
        '.gd' { return 'script' }
        '.tres' { return 'resource' }
        '.json' { return 'data' }
        '.png' { return 'texture' }
        '.jpg' { return 'texture' }
        '.jpeg' { return 'texture' }
        '.svg' { return 'texture' }
        '.mp3' { return 'audio' }
        '.wav' { return 'audio' }
        '.ogg' { return 'audio' }
        '.ttf' { return 'font' }
        '.otf' { return 'font' }
        default { return 'other' }
    }
}

function Get-DependencyClosure([string[]]$EntryPaths) {
    $seen = [ordered]@{}
    $parents = @{}
    $edges = @{}
    $queue = [Collections.Generic.Queue[string]]::new()
    foreach ($entry in $EntryPaths) { $queue.Enqueue($entry) }

    while ($queue.Count -gt 0) {
        $path = $queue.Dequeue().Replace('\', '/')
        if ($seen.Contains($path)) { continue }
        $seen[$path] = $true
        $absolute = Convert-ToAbsolutePath $path
        if (-not $absolute -or -not (Test-Path -LiteralPath $absolute -PathType Leaf)) { continue }

        $text = [IO.File]::ReadAllText($absolute)
        $children = [Collections.Generic.List[string]]::new()
        foreach ($match in [regex]::Matches($text, 'res://[^"\r\n]+')) {
            $child = $match.Value.TrimEnd(',)]};').Replace('\', '/')
            if (-not $child.StartsWith('res://') -or $child -eq $path -or $children.Contains($child)) { continue }
            $children.Add($child)
            if (-not $edges.ContainsKey($path)) { $edges[$path] = [Collections.Generic.List[string]]::new() }
            $edges[$path].Add($child)
            if (-not $parents.ContainsKey($child)) { $parents[$child] = [Collections.Generic.List[string]]::new() }
            $parents[$child].Add($path)
            if (-not $seen.Contains($child)) { $queue.Enqueue($child) }
        }
    }
    return [pscustomobject]@{ Paths = @($seen.Keys); Parents = $parents; Edges = $edges }
}

function Get-Hash([string]$ResourcePath) {
    $absolute = Convert-ToAbsolutePath $ResourcePath
    if (-not $absolute -or -not (Test-Path -LiteralPath $absolute -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $absolute -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-Classification([string]$Feature, [string]$Path, [bool]$Exists, [int]$HashCount) {
    if (-not $Exists) {
        if ($Path.EndsWith('/') -or $Path.Contains('*') -or $Path.Contains('%')) { return 'dynamic_path_pattern' }
        return 'missing'
    }
    $base = 'unique'
    if ($HashCount -gt 1) { $base = 'duplicate_identical' }

    if ($Feature -eq 'density') {
        if ($Path.StartsWith('res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/')) { return "nested_copy_$base" }
        if ($Path.StartsWith('res://games/chapter_one/hometown/building_two/Level2-1/')) { return "canonical_density_$base" }
        if ($Path.StartsWith('res://games/chapter_one/hometown/building_two/level2-2/')) { return "cross_feature_states_$base" }
    } elseif ($Feature -eq 'states') {
        if ($Path.StartsWith('res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/level2-2/')) { return "nested_copy_$base" }
        if ($Path.StartsWith('res://games/chapter_one/hometown/building_two/level2-2/mattermaze/')) { return "canonical_states_$base" }
        if ($Path.StartsWith('res://games/chapter_one/hometown/building_two/Level2-1/')) { return "cross_feature_density_$base" }
    } elseif ($Feature -eq 'glossary') {
        if ($Path.StartsWith('res://games/glossary/')) { return "canonical_glossary_$base" }
        if ($Path.StartsWith('res://glossary/')) { return "legacy_glossary_$base" }
    }
    if ($Path.StartsWith('res://games/global/')) { return "shared_global_$base" }
    return "shared_or_external_$base"
}

function Write-Manifest([string]$Feature, [string[]]$Entries, [string]$FileName, [string]$DecisionFile) {
    $closure = Get-DependencyClosure $Entries
    $rows = [Collections.Generic.List[object]]::new()
    $hashes = @{}
    foreach ($path in $closure.Paths) {
        $hash = Get-Hash $path
        if ($hash) {
            if (-not $hashes.ContainsKey($hash)) { $hashes[$hash] = 0 }
            $hashes[$hash]++
        }
    }
    foreach ($path in ($closure.Paths | Sort-Object)) {
        $absolute = Convert-ToAbsolutePath $path
        $exists = [bool]($absolute -and (Test-Path -LiteralPath $absolute -PathType Leaf))
        $hash = Get-Hash $path
        $parentList = ''
        if ($closure.Parents.ContainsKey($path)) { $parentList = ($closure.Parents[$path] | Sort-Object -Unique) -join ';' }
        $rows.Add([pscustomobject]@{
            feature = $Feature
            path = $path
            kind = Get-ResourceKind $path
            exists = $exists
            sha256 = $hash
            classification = Get-Classification $Feature $path $exists $(if ($hash -and $hashes.ContainsKey($hash)) { $hashes[$hash] } else { 0 })
            referenced_from = $parentList
        })
    }
    $rows | Export-Csv -LiteralPath (Join-Path $OutputDirectory $FileName) -NoTypeInformation -Encoding utf8

    $missing = @($rows | Where-Object { $_.classification -eq 'missing' })
    $dynamic = @($rows | Where-Object { $_.classification -eq 'dynamic_path_pattern' })
    $nested = @($rows | Where-Object { $_.classification -like 'nested_copy*' })
    $duplicates = @($rows | Where-Object { $_.classification -like '*duplicate_identical*' })
    $cross = @($rows | Where-Object { $_.classification -like 'cross_feature*' })
    $decision = [Collections.Generic.List[string]]::new()
    $decision.Add("# $Feature dependency decisions")
    $decision.Add('')
    $decision.Add("Generated: $(Get-Date -Format o)")
    $decision.Add("Closure resources: $($rows.Count); missing: $($missing.Count); dynamic path patterns: $($dynamic.Count); nested-copy candidates: $($nested.Count); exact duplicate members: $($duplicates.Count); cross-feature members: $($cross.Count)")
    $decision.Add('')
    $decision.Add('## Provisional ownership')
    if ($Feature -eq 'density') { $decision.Add('- Canonical entry/dependency boundary: `games/chapter_one/hometown/building_two/Level2-1/` (excluding its nested `Level2-1/Level2-1/` copy).') }
    if ($Feature -eq 'states') { $decision.Add('- Canonical entry/dependency boundary: `games/chapter_one/hometown/building_two/level2-2/mattermaze/`; nested matter-maze resources are migration candidates.') }
    if ($Feature -eq 'glossary') { $decision.Add('- Canonical feature boundary: `games/glossary/`; root `glossary/` is retained as a legacy candidate until all consumers are migrated.') }
    $decision.Add('- Shared `games/global/` resources remain shared and are not moved by this manifest.')
    $decision.Add('')
    $decision.Add('## Review signals')
    foreach ($row in $missing) { $decision.Add("- Missing active reference: " + $row.path + " (from " + $row.referenced_from + ").") }
    foreach ($row in $dynamic) { $decision.Add("- Dynamic path pattern (not a missing file): " + $row.path + " (from " + $row.referenced_from + ").") }
    $decision.Add('- Exact duplicate groups are hash-backed in the CSV; no deletion is authorized by this generated report alone.')
    $decision.Add('- Divergent same-purpose files require visual/runtime review before migration.')
    Set-Content -LiteralPath (Join-Path $OutputDirectory $DecisionFile) -Value $decision -Encoding utf8
    return $rows.Count
}

$densityEntries = @(
    'res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level 1/level_1.tscn',
    'res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_2.tscn',
    'res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_3.tscn'
)
$statesEntries = @(
    'res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_1.tscn',
    'res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_2.tscn',
    'res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_3.tscn'
)
$glossaryEntries = @(
    'res://games/glossary/main.tscn',
    'res://games/glossary/element_info.tscn',
    'res://games/glossary/about.tscn'
)

$densityCount = Write-Manifest 'density' $densityEntries 'density-resources.csv' 'density-decisions.md'
$statesCount = Write-Manifest 'states' $statesEntries 'states-resources.csv' 'states-decisions.md'
$glossaryCount = Write-Manifest 'glossary' $glossaryEntries 'glossary-resources.csv' 'glossary-decisions.md'
Write-Output "Generated manifests: density=$densityCount states=$statesCount glossary=$glossaryCount output=$OutputDirectory"
