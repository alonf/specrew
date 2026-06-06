[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Bidirectional FileList completeness guard.
#
# Motivation: v0.28.0-beta1 shipped a broken package — scripts/internal/user-profile.ps1
# existed in source but was omitted from the Specrew.psd1 FileList, so PSGallery never
# packaged it and `specrew start` crashed on first run. The pre-publish Docker harness
# missed it because its FileList check is DIRECTIONAL (every *declared* entry exists on
# disk) and never checked the inverse (every *deployable source file* is declared).
#
# This test closes that blind spot at PR time (fast, deterministic, no Docker): every
# deployable source file under a shipping root MUST be declared in FileList. An undeclared
# file is silently dropped from the published package -> runtime crash or missing feature.
#
# Scan roots are DERIVED from the FileList's own top-level directory prefixes, not a
# hand-picked list. This makes the guard self-correcting: every root that actually ships
# (has at least one FileList entry) is scanned automatically, so a new shipping subtree can
# never be silently un-guarded the way the original scripts/*.ps1-only scan let the
# Feature 141 design-workshop skill, the design-lens knowledge, and the F-049 intake engine
# slip through. Roots with zero FileList entries — notably the .specify/ self-host mirror,
# regenerated downstream by deploy and never packaged — are excluded by construction.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$manifestPath = Join-Path -Path $repoRoot -ChildPath 'Specrew.psd1'

# Roots that ship through a mechanism OTHER than the manifest FileList, so their files are
# NOT expected to be individually declared. The publish workflow copies docs/ recursively
# (publish-module.yml: "Include docs/ recursively"), independent of FileList; deriving it
# as a scan root would false-positive every doc that isn't separately pinned.
$nonManifestShipRoots = @('docs')

function Get-DeployableRoots {
    param([string[]]$FileList, [string[]]$ExcludeRoots = @())
    $roots = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $FileList) {
        $norm = ([string]$entry -replace '\\', '/')
        if ($norm -match '/') {
            $top = ($norm -split '/')[0]
            if ($ExcludeRoots -notcontains $top) { [void]$roots.Add($top) }
        }
    }
    return @($roots)
}

function Get-UndeclaredDeployableFiles {
    param(
        [string[]]$FileList,
        [string]$RootPath,
        [string[]]$ExcludeRoots = @()
    )
    $declared = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $FileList) { [void]$declared.Add(([string]$entry -replace '\\', '/')) }

    $undeclared = New-Object System.Collections.Generic.List[string]
    foreach ($root in (Get-DeployableRoots -FileList $FileList -ExcludeRoots $ExcludeRoots)) {
        $rootFull = Join-Path -Path $RootPath -ChildPath $root
        if (-not (Test-Path -LiteralPath $rootFull)) { continue }
        foreach ($file in (Get-ChildItem -LiteralPath $rootFull -Recurse -File -Force)) {
            $rel = ($file.FullName.Substring($RootPath.Length).TrimStart('\', '/') -replace '\\', '/')
            if (-not $declared.Contains($rel)) { $null = $undeclared.Add($rel) }
        }
    }
    return $undeclared
}

$manifest = Import-PowerShellDataFile -Path $manifestPath
$fileList = @($manifest.FileList | ForEach-Object { [string]$_ })

# --- Test 1: real repo — every deployable source file is declared in FileList. ---
$undeclared = @(Get-UndeclaredDeployableFiles -FileList $fileList -RootPath $repoRoot -ExcludeRoots $nonManifestShipRoots)
if ($undeclared.Count -gt 0) {
    Write-Fail "Specrew.psd1 FileList is missing $($undeclared.Count) deployable source file(s); they would be dropped from the PSGallery package (runtime crash / missing feature):"
    foreach ($u in ($undeclared | Sort-Object)) { Write-Host "  - $u" -ForegroundColor Red }
    Write-Host "Add each to the FileList array in Specrew.psd1 (alphabetical within its directory)." -ForegroundColor Yellow
    exit 1
}
$scannedRoots = (Get-DeployableRoots -FileList $fileList -ExcludeRoots $nonManifestShipRoots | Sort-Object) -join ', '
Write-Pass "Every deployable source file under FileList-derived roots [$scannedRoots] is declared ($($fileList.Count) FileList entries; non-manifest roots excluded: $($nonManifestShipRoots -join ', '))"

# --- Test 2: regression — the F-049 iter-003 / Feature 141 scenario (a new deployable file
#     under a shipping root, NOT added to FileList) MUST be detected by the guard. ---
$scratch = Join-Path -Path $repoRoot -ChildPath (".scratch\filelist-completeness-" + [guid]::NewGuid().ToString('N'))
try {
    $null = New-Item -ItemType Directory -Path (Join-Path -Path $scratch -ChildPath 'scripts/internal') -Force
    $declaredRel = 'scripts/internal/existing-helper.ps1'
    $newFileRel = 'scripts/internal/new-iter003-helper.ps1'
    Set-Content -LiteralPath (Join-Path -Path $scratch -ChildPath $declaredRel) -Value '# declared baseline helper' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path -Path $scratch -ChildPath $newFileRel) -Value '# simulated new helper, not in FileList' -Encoding UTF8

    # A FileList that declares the baseline (so scripts/ is a derived root) but NOT the new
    # helper — the new helper must surface, the declared baseline must not.
    $detected = @(Get-UndeclaredDeployableFiles -FileList @('Specrew.psm1', 'Specrew.psd1', $declaredRel) -RootPath $scratch)
    if ($detected -notcontains $newFileRel) {
        Write-Fail "Regression: a new undeclared scripts/internal helper was NOT flagged by the bidirectional check (the v0.28.0-beta1 blind spot would recur)."
        exit 1
    }
    if ($detected -contains $declaredRel) {
        Write-Fail "Regression: the declared baseline helper was wrongly flagged as undeclared (derived-root scan over-reports)."
        exit 1
    }
    Write-Pass "Regression (F-049 iter-003 / F-141 scenario): an undeclared shipping-root helper is correctly flagged; a declared one is not"
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Pass "FileList completeness: bidirectional (source -> declared) guard passes"
exit 0
