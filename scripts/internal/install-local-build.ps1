<#
.SYNOPSIS
    Package the current checkout and install it as the local Specrew module.

.DESCRIPTION
    THE SUPPORTED LOCAL INSTALL PATH. Before this existed, every local install was hand-assembled by
    extracting the release script's functions via an AST parse and re-running the sequence without its
    cleanup - because invoke-module-release.ps1 deletes its stage in a `finally`, which is correct for a
    release tool and useless for installing. That unsupported path produced an install whose build stamp
    read one commit while its files carried another; it was caught only because someone diffed 82 files.

    This runs the SAME staging and stamping code as the release path (scripts/internal/module-packaging.ps1),
    then installs and byte-verifies the result.

    WHAT THIS IS NOT: a way to run a dirty working tree. It refuses uncommitted changes to packaged files
    unless -AllowDirty is given, because the value of a manual walk is that it exercises what SHIPS, and
    an install whose identity drifts from its contents is the defect this whole path exists to prevent.

    THE OTHER HALF OF THE HANDSHAKE. Installing the module is only one side. A governed project carries a
    deployed runtime bundle, and scripts/internal/review-engine-resolution.ps1 refuses every review when
    the two disagree (`review-engine-version-mismatch`). After installing, update each project you intend
    to use:  specrew update --project-path <project>

.EXAMPLE
    pwsh -File scripts/internal/install-local-build.ps1
    Packages HEAD and installs it over the current 0.40.0 module.

.EXAMPLE
    pwsh -File scripts/internal/install-local-build.ps1 -WhatIfOnly
    Packages and reports the identity it WOULD install, touching nothing.
#>
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path,

    # Where the module lives. Defaults to the highest-versioned installed Specrew, so a dev loop does not
    # have to know the path.
    [string]$InstallRoot,

    # Package and report, install nothing.
    [switch]$WhatIfOnly,

    # Package a working tree with uncommitted changes to packaged files. Off by default on purpose.
    [switch]$AllowDirty,

    # Keep the staged package after installing, for inspection.
    [switch]$KeepStage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'module-packaging.ps1')

function Write-InstallInfo {
    param([string]$Message)
    Write-Host "[install] $Message" -ForegroundColor Cyan
}

$resolvedRepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot -ErrorAction Stop).Path
$manifestPath = Join-Path $resolvedRepositoryRoot 'Specrew.psd1'
$configPath = Join-Path $resolvedRepositoryRoot '.specrew/config.yml'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "not a Specrew checkout: $manifestPath is missing" }

# --- what exactly are we packaging -------------------------------------------------------------------
$headCommit = Get-ReleaseBuildId -RepositoryRoot $resolvedRepositoryRoot
$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$packagedPaths = @(@($manifest.FileList) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

# Dirty-tree check scoped to PACKAGED files only. Uncommitted specs, drift logs and scratch do not reach
# the package and must not block an install; an edited script does.
$dirtyPackaged = @()
try {
    $status = @(& git -C $resolvedRepositoryRoot status --porcelain -- $packagedPaths 2>$null)
    $dirtyPackaged = @($status | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}
catch { $dirtyPackaged = @() }

if ($dirtyPackaged.Count -gt 0 -and -not $AllowDirty) {
    $sample = (@($dirtyPackaged) | Select-Object -First 5) -join [Environment]::NewLine
    throw ("refusing to package a dirty tree: {0} packaged file(s) have uncommitted changes, so the install would carry code that is in no commit and its stamp would name a commit that does not describe it.{1}{2}{1}Commit them, or pass -AllowDirty if you deliberately want an unreleasable dev build." -f $dirtyPackaged.Count, [Environment]::NewLine, $sample)
}
if ($dirtyPackaged.Count -gt 0) {
    Write-InstallInfo ("WARNING: packaging a DIRTY tree - {0} packaged file(s) differ from HEAD {1}. This build is not reproducible from any commit." -f $dirtyPackaged.Count, $headCommit)
}

# --- stage, using the release path's own code --------------------------------------------------------
$scratchRoot = $null
$stageRoot = $null
try {
    $scratchRoot = New-ReleaseScratchRoot -RepositoryRoot $resolvedRepositoryRoot
    $moduleVersion = Get-SpecrewVersionFromConfig -ConfigPath $configPath
    $stageRoot = New-ReleaseStageRoot -RepositoryRoot $resolvedRepositoryRoot -ScratchRoot $scratchRoot -ManifestPath $manifestPath
    $stagedManifest = Join-Path $stageRoot 'Specrew.psd1'

    $manifestInfo = Get-SpecrewManifestReleaseInfo -ManifestPath $stagedManifest
    $null = Write-ReleaseBuildStamp -StageRoot $stageRoot -Commit $headCommit
    $stamp = Get-Content -LiteralPath (Join-Path $stageRoot 'build-stamp.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $null = Test-ModuleManifest -Path $stagedManifest -ErrorAction Stop

    $stagedFiles = @(Get-ChildItem -LiteralPath $stageRoot -File -Recurse -Force)
    Write-InstallInfo ("packaged {0} files from {1}" -f $stagedFiles.Count, $headCommit)
    Write-InstallInfo ("version {0} prerelease '{1}'" -f $manifestInfo.ModuleVersion, $manifestInfo.Prerelease)
    Write-InstallInfo ("commit {0}  content {1}" -f $stamp.commit, $stamp.content_sha256)

    if (-not $InstallRoot) {
        $installed = @(Get-Module -ListAvailable -Name Specrew | Sort-Object Version -Descending | Select-Object -First 1)
        if ($installed.Count -eq 0) { throw 'no installed Specrew module found; pass -InstallRoot explicitly' }
        $InstallRoot = $installed[0].ModuleBase
    }
    Write-InstallInfo ("target {0}" -f $InstallRoot)

    if ($WhatIfOnly) {
        Write-InstallInfo 'WhatIfOnly: nothing was installed.'
        return [pscustomobject]@{ commit = $stamp.commit; content_sha256 = $stamp.content_sha256; installed = $false; install_root = $InstallRoot }
    }

    if (-not (Test-Path -LiteralPath $InstallRoot -PathType Container)) { throw "install root does not exist: $InstallRoot" }

    # Items that live in an install and are NOT part of a package: the module's own version-check cache
    # and PowerShellGet's provenance file. A clean replace removes both silently, so they are carried
    # across rather than lost.
    $preserved = @('.specrew', 'PSGetModuleInfo.xml')
    $holding = Join-Path $scratchRoot 'preserved'
    $null = New-Item -Path $holding -ItemType Directory -Force
    foreach ($item in $preserved) {
        $source = Join-Path $InstallRoot $item
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $holding $item) -Recurse -Force
            Write-InstallInfo ("preserving {0}" -f $item)
        }
    }

    Get-ChildItem -LiteralPath $InstallRoot -Force | Remove-Item -Recurse -Force
    Copy-Item -Path (Join-Path $stageRoot '*') -Destination $InstallRoot -Recurse -Force
    foreach ($item in $preserved) {
        $held = Join-Path $holding $item
        if (Test-Path -LiteralPath $held) { Copy-Item -LiteralPath $held -Destination (Join-Path $InstallRoot $item) -Recurse -Force }
    }

    # BYTE VERIFICATION, not "the copy did not error". A half-completed copy is exactly the shape this
    # project keeps finding, and a install that is 99% right is a build stamp that lies.
    $mismatch = [System.Collections.Generic.List[string]]::new()
    foreach ($file in $stagedFiles) {
        $relative = $file.FullName.Substring($stageRoot.Length).TrimStart([char]92)
        $target = Join-Path $InstallRoot $relative
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { [void]$mismatch.Add("missing: $relative"); continue }
        if ((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) {
            [void]$mismatch.Add("hash: $relative")
        }
    }
    if ($mismatch.Count -gt 0) {
        throw ("install verification FAILED for {0} file(s): {1}" -f $mismatch.Count, ((@($mismatch) | Select-Object -First 5) -join '; '))
    }
    Write-InstallInfo ("byte verification: all {0} packaged files match" -f $stagedFiles.Count)

    # The stamp must describe what actually landed, not what was staged.
    $packagedRelatives = @($stagedFiles | ForEach-Object { $_.FullName.Substring($stageRoot.Length).TrimStart([char]92) })
    $installedContent = Get-SpecrewPackageContentSha256 -StageRoot $InstallRoot -RelativePaths $packagedRelatives
    if ($installedContent -cne [string]$stamp.content_sha256) {
        throw ("installed content hash {0} does not match the stamp {1}; the install does not match its own identity" -f $installedContent, $stamp.content_sha256)
    }
    Write-InstallInfo 'stamp verified against installed contents'

    Write-InstallInfo ''
    Write-InstallInfo 'NEXT: the module is only one side of the runtime handshake. For each project you will use:'
    Write-InstallInfo ('  specrew update --project-path <project>      (from PowerShell; `specrew` is not on the bash PATH)')

    return [pscustomobject]@{ commit = $stamp.commit; content_sha256 = $stamp.content_sha256; installed = $true; install_root = $InstallRoot; files = $stagedFiles.Count }
}
finally {
    if (-not $KeepStage -and $scratchRoot -and (Test-Path -LiteralPath $scratchRoot)) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    elseif ($KeepStage -and $stageRoot) {
        Write-InstallInfo ("stage kept at {0}" -f $stageRoot)
    }
}
