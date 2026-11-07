#requires -Version 7.0
# Feature 203 T002 follow-up (B5F-033; DRIFT-047). Since T002's implement ruling (DRIFT-007) this repository syncs its
# `.specify/extensions/specrew-speckit` mirror from `extensions/specrew-speckit` in every commit, and nothing refreshed
# the mirror's install record, `.specrew-extension-runtime.json`. From `040fb169` the deployed files no longer matched
# their record, and every fixture that copies this repository's `.specify` failed W43 ("does not match what was
# installed"); `validate-governance-changed-only` was red for that reason alone.
#
# This script writes the record with the installer's own writer, `Write-SpecrewDeployedExtensionMarker`, and ONLY after
# it has confirmed that every deployed file is byte-identical to its source in `extensions/`, with no file on one side
# only. It never blesses `.specify` as it stands: a hand edit there, with its source unchanged, makes this script refuse
# and leave the record as it was, so W43 keeps catching it (maintainer condition, 2026-11-07).
#
# Run it in the same commit as each mirror sync. `-CheckOnly` writes nothing and also requires the record to match the
# mirror, which is what the f203 lane checks on every committed tree.
[CmdletBinding()]
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$CheckOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$markerName = '.specrew-extension-runtime.json'
$sourceRoot = Join-Path $ProjectRoot 'extensions/specrew-speckit'
$deployedRoot = Join-Path $ProjectRoot '.specify/extensions/specrew-speckit'
foreach ($required in @($sourceRoot, $deployedRoot)) {
    if (-not (Test-Path -LiteralPath $required -PathType Container)) {
        [Console]::Error.WriteLine(("The mirror record was not written: {0} is not there." -f $required))
        exit 1
    }
}

function Get-MirrorFiles {
    param([Parameter(Mandatory)][string]$Root, [switch]$SkipMarker)
    $resolved = (Resolve-Path -LiteralPath $Root).Path
    $files = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $resolved -File -Recurse -Force)) {
        $relative = ([IO.Path]::GetRelativePath($resolved, $file.FullName)) -replace '\\', '/'
        if ($SkipMarker -and $relative -ceq $markerName) { continue }
        $files[$relative] = $file.FullName
    }
    return $files
}

$source = Get-MirrorFiles -Root $sourceRoot
$deployed = Get-MirrorFiles -Root $deployedRoot -SkipMarker
$problems = [System.Collections.Generic.List[string]]::new()
foreach ($relative in @($deployed.Keys | Sort-Object)) {
    if (-not $source.ContainsKey($relative)) { [void]$problems.Add(('only in .specify, with no source in extensions/: {0}' -f $relative)) }
}
foreach ($relative in @($source.Keys | Sort-Object)) {
    if (-not $deployed.ContainsKey($relative)) { [void]$problems.Add(('in extensions/ but not synced to .specify: {0}' -f $relative)); continue }
    # Byte for byte, deliberately: the record's own hash normalizes line endings, so comparing that way here would let
    # a line-ending-only edit through. Both copies come from the same checkout, so an honest sync is identical.
    $a = [IO.File]::ReadAllBytes($source[$relative])
    $b = [IO.File]::ReadAllBytes($deployed[$relative])
    if (-not [System.Linq.Enumerable]::SequenceEqual($a, $b)) { [void]$problems.Add(('differs from its source in extensions/: {0}' -f $relative)) }
}
if ($problems.Count -gt 0) {
    [Console]::Error.WriteLine('The .specify mirror is not an exact copy of extensions/specrew-speckit, so its install record was left as it was:')
    foreach ($p in $problems) { [Console]::Error.WriteLine('  ' + $p) }
    [Console]::Error.WriteLine('Sync those files from extensions/ (or revert the edit in .specify), then run this again.')
    exit 1
}

# The installer's writer, from this script's own engine tree: the target project may be a fixture with no engine.
. (Join-Path $PSScriptRoot '..\..\extensions\specrew-speckit\scripts\shared-governance.ps1')

if ($CheckOnly) {
    $state = Test-SpecrewDeployedExtensionIntegrity -ProjectRoot $ProjectRoot
    $unlisted = @()
    $markerPath = Get-SpecrewDeployedExtensionMarkerPath -ProjectRoot $ProjectRoot
    if ([bool]$state.checked) {
        $listed = @{}
        foreach ($entry in @((Get-Content -LiteralPath $markerPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).managed_files)) { $listed[[string]$entry.path] = $true }
        $unlisted = @($deployed.Keys | Where-Object { -not $listed.ContainsKey($_) } | Sort-Object)
    }
    if (-not [bool]$state.checked -or @($state.drifted).Count -or @($state.missing).Count -or $unlisted.Count) {
        [Console]::Error.WriteLine('The .specify mirror matches extensions/, but its install record does not match the mirror:')
        if (-not [bool]$state.checked) { [Console]::Error.WriteLine('  no readable record at ' + $markerPath) }
        foreach ($p in @($state.drifted)) { [Console]::Error.WriteLine('  recorded with another hash: ' + $p) }
        foreach ($p in @($state.missing)) { [Console]::Error.WriteLine('  recorded but not deployed: ' + $p) }
        foreach ($p in $unlisted) { [Console]::Error.WriteLine('  deployed but not recorded: ' + $p) }
        [Console]::Error.WriteLine('Run scripts/internal/refresh-specify-mirror-record.ps1 in the commit that syncs the mirror.')
        exit 1
    }
    'The .specify mirror is an exact copy of extensions/ ({0} files) and its install record matches it.' -f $deployed.Count
    exit 0
}

# Keep the version the record already carries; the mirror's content changed, not the release it was installed from.
$version = 'unknown'
$existing = Get-SpecrewDeployedExtensionMarkerPath -ProjectRoot $ProjectRoot
if (Test-Path -LiteralPath $existing -PathType Leaf) {
    try {
        $old = Get-Content -LiteralPath $existing -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
        if ($old.PSObject.Properties['specrew_version'] -and -not [string]::IsNullOrWhiteSpace([string]$old.specrew_version)) { $version = [string]$old.specrew_version }
    }
    catch { $version = 'unknown' }
}
$written = Write-SpecrewDeployedExtensionMarker -ProjectRoot $ProjectRoot -SpecrewVersion $version
'Install record written: {0} ({1} files, each byte-identical to its source in extensions/; version {2}).' -f $written, $deployed.Count, $version
exit 0
