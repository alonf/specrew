# Shared module packaging: staging, stamping and identity.
#
# Extracted from invoke-module-release.ps1 on 2026-08-21 so the LOCAL INSTALL path and the RELEASE
# path run the same code. Before this there was no installer at all: invoke-module-release.ps1
# deletes its stage in a finally - correct for a release tool - so a dry run proved packaging worked
# and left nothing installable. Every local install was hand-assembled by extracting these functions
# from that script via an AST parse and re-running the sequence without the cleanup.
#
# That unsupported path is not a theoretical risk. It produced an install whose build stamp read one
# commit while its files carried another, caught only because someone diffed 82 files by hand.
#
# Moved VERBATIM rather than rewritten. A reworded second copy is how a release path and an install
# path drift apart, and the point of this file is that they cannot.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-ReleaseInfo {
    param([string]$Message)
    Write-Host "[release] $Message" -ForegroundColor Cyan
}

function Get-SpecrewVersionFromConfig {
    param([Parameter(Mandatory = $true)][string]$ConfigPath)

    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        throw "Missing Specrew config '$ConfigPath'."
    }

    foreach ($line in Get-Content -LiteralPath $ConfigPath -Encoding UTF8) {
        if ($line -match '^\s*specrew_version:\s*"?(?<version>[^"#]+?)"?\s*$') {
            return $Matches.version.Trim()
        }
    }

    throw "Could not read 'specrew_version' from '$ConfigPath'."
}

function Set-SpecrewManifestReleaseMetadata {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [Parameter(Mandatory = $true)][string]$Version,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Prerelease
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Missing module manifest '$ManifestPath'."
    }

    $content = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8
    $moduleVersionPattern = "(?m)^(\s*ModuleVersion\s*=\s*)'[^']*'\s*$"
    $moduleVersionMatch = [regex]::Match($content, $moduleVersionPattern)
    if (-not $moduleVersionMatch.Success) {
        throw "Could not locate ModuleVersion in '$ManifestPath'."
    }

    $updated = [regex]::Replace($content, $moduleVersionPattern, ('$1''{0}''' -f $Version), 1)
    $prereleasePattern = "(?m)^(\s*Prerelease\s*=\s*)'[^']*'\s*$"
    $prereleaseMatch = [regex]::Match($updated, $prereleasePattern)
    if (-not $prereleaseMatch.Success) {
        throw "Could not locate PrivateData.PSData.Prerelease in '$ManifestPath'."
    }

    $withPrerelease = [regex]::Replace($updated, $prereleasePattern, ('$1''{0}''' -f $Prerelease), 1)
    if ($PSCmdlet.ShouldProcess($ManifestPath, ("Set ModuleVersion to {0} with Prerelease '{1}'" -f $Version, $Prerelease))) {
        [System.IO.File]::WriteAllText($ManifestPath, $withPrerelease, [System.Text.UTF8Encoding]::new($false))
    }
}

function Get-SpecrewManifestReleaseInfo {
    param([Parameter(Mandatory = $true)][string]$ManifestPath)

    $manifest = Import-PowerShellDataFile -Path $ManifestPath
    $prerelease = ''
    if (
        $manifest.ContainsKey('PrivateData') -and
        $manifest.PrivateData -and
        $manifest.PrivateData.ContainsKey('PSData') -and
        $manifest.PrivateData.PSData -and
        $manifest.PrivateData.PSData.ContainsKey('Prerelease') -and
        $null -ne $manifest.PrivateData.PSData['Prerelease']
    ) {
        $prerelease = [string]$manifest.PrivateData.PSData['Prerelease']
    }

    return [pscustomobject]@{
        ModuleVersion = [string]$manifest.ModuleVersion
        Prerelease    = $prerelease
    }
}

function ConvertTo-ManifestPrerelease {
    param([AllowEmptyString()][string]$TagPrerelease)

    if ([string]::IsNullOrWhiteSpace($TagPrerelease)) {
        return ''
    }

    return ($TagPrerelease -replace '[.+]', '')
}

function Resolve-ReleaseStamp {
    param(
        [Parameter(Mandatory = $true)][string]$ReleaseMode,
        [AllowEmptyString()][string]$GitRefType,
        [AllowEmptyString()][string]$GitRefName,
        [Parameter(Mandatory = $true)][string]$ExpectedVersion
    )

    if ([string]::IsNullOrWhiteSpace($GitRefType) -or [string]::IsNullOrWhiteSpace($GitRefName)) {
        if ($ReleaseMode -ne 'dry-run') {
            throw ("Release mode '{0}' requires a v*.* tag ref or workflow_dispatch release_tag input." -f $ReleaseMode)
        }

        return [pscustomobject]@{
            ModuleVersion       = $ExpectedVersion
            ManifestPrerelease  = ''
            SourcePrereleaseTag = ''
            EffectiveVersion    = $ExpectedVersion
        }
    }

    if ($GitRefType -ne 'tag') {
        if ($ReleaseMode -ne 'dry-run') {
            throw ("Release mode '{0}' requires a tag ref, but the workflow is running against ref type '{1}'." -f $ReleaseMode, $GitRefType)
        }

        return [pscustomobject]@{
            ModuleVersion       = $ExpectedVersion
            ManifestPrerelease  = ''
            SourcePrereleaseTag = ''
            EffectiveVersion    = $ExpectedVersion
        }
    }

    if ($GitRefName -notmatch '^v(?<version>\d+\.\d+\.\d+)(?:-(?<prerelease>[0-9A-Za-z][0-9A-Za-z.-]*))?$') {
        throw ("Tag '{0}' does not follow the required v*.* format." -f $GitRefName)
    }

    $tagVersion = $Matches.version
    $tagPrerelease = if ($Matches.ContainsKey('prerelease') -and -not [string]::IsNullOrWhiteSpace($Matches.prerelease)) { $Matches.prerelease } else { '' }
    if ($tagVersion -ne $ExpectedVersion) {
        throw ("Tag version '{0}' does not match .specrew/config.yml specrew_version '{1}'." -f $tagVersion, $ExpectedVersion)
    }

    $normalizedTagPrerelease = ConvertTo-ManifestPrerelease -TagPrerelease $tagPrerelease

    $manifestPrerelease = switch ($ReleaseMode) {
        'dry-run' { $normalizedTagPrerelease }
        'publish-prerelease' {
            if ([string]::IsNullOrWhiteSpace($tagPrerelease)) {
                throw ("Release mode '{0}' requires a prerelease tag like v{1}-beta.1." -f $ReleaseMode, $ExpectedVersion)
            }

            $normalizedTagPrerelease
        }
        'publish-stable' {
            if (-not [string]::IsNullOrWhiteSpace($tagPrerelease)) {
                throw ("Release mode '{0}' requires a stable tag with no prerelease suffix." -f $ReleaseMode)
            }

            ''
        }
        'promote-prerelease' {
            if ([string]::IsNullOrWhiteSpace($tagPrerelease)) {
                throw ("Release mode '{0}' requires a prerelease tag to promote from." -f $ReleaseMode)
            }

            ''
        }
        default {
            throw ("Unsupported release mode '{0}'." -f $ReleaseMode)
        }
    }

    $effectiveVersion = if ([string]::IsNullOrWhiteSpace($manifestPrerelease)) {
        $ExpectedVersion
    }
    else {
        '{0}-{1}' -f $ExpectedVersion, $manifestPrerelease
    }

    return [pscustomobject]@{
        ModuleVersion       = $ExpectedVersion
        ManifestPrerelease  = $manifestPrerelease
        SourcePrereleaseTag = $tagPrerelease
        EffectiveVersion    = $effectiveVersion
    }
}

function New-ReleaseScratchRoot {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    param([Parameter(Mandatory = $true)][string]$RepositoryRoot)

    $scratchRoot = Join-Path -Path $RepositoryRoot -ChildPath '.scratch\module-release'
    if (Test-Path -LiteralPath $scratchRoot) {
        if ($PSCmdlet.ShouldProcess($scratchRoot, 'Reset release scratch root')) {
            Remove-Item -LiteralPath $scratchRoot -Recurse -Force
        }
    }

    if ($PSCmdlet.ShouldProcess($scratchRoot, 'Create release scratch root')) {
        $null = New-Item -Path $scratchRoot -ItemType Directory -Force
    }
    return $scratchRoot
}

function Copy-ReleaseFile {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)][string]$StageRoot,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $sourcePath = Join-Path -Path $RepositoryRoot -ChildPath $RelativePath
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Missing release file '$RelativePath'."
    }

    $destinationPath = Join-Path -Path $StageRoot -ChildPath $RelativePath
    $destinationDirectory = Split-Path -Path $destinationPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($destinationDirectory) -and -not (Test-Path -LiteralPath $destinationDirectory)) {
        $null = New-Item -Path $destinationDirectory -ItemType Directory -Force
    }

    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
}

function New-ReleaseStageRoot {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)][string]$ScratchRoot,
        [Parameter(Mandatory = $true)][string]$ManifestPath
    )

    $stageRoot = Join-Path -Path $ScratchRoot -ChildPath 'Specrew'
    if ($PSCmdlet.ShouldProcess($stageRoot, 'Create staged module release root')) {
        $null = New-Item -Path $stageRoot -ItemType Directory -Force
    }

    $manifest = Import-PowerShellDataFile -Path $ManifestPath
    $filesToStage = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($relativePath in @($manifest.FileList)) {
        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            continue
        }

        if ($filesToStage.Add($relativePath)) {
            Copy-ReleaseFile -RepositoryRoot $RepositoryRoot -StageRoot $stageRoot -RelativePath $relativePath
        }
    }

    foreach ($optionalPath in @('README.md', 'CHANGELOG.md', 'LICENSE', 'NOTICE.md')) {
        $sourcePath = Join-Path -Path $RepositoryRoot -ChildPath $optionalPath
        if ((Test-Path -LiteralPath $sourcePath -PathType Leaf) -and $filesToStage.Add($optionalPath)) {
            Copy-ReleaseFile -RepositoryRoot $RepositoryRoot -StageRoot $stageRoot -RelativePath $optionalPath
        }
    }

    return $stageRoot
}

function Get-ReleaseBuildId {
    param([Parameter(Mandatory = $true)][string]$RepositoryRoot)

    foreach ($candidate in @($env:SPECREW_BUILD_COMMIT, $env:GITHUB_SHA)) {
        $value = ([string]$candidate).Trim()
        if ($value -match '^[0-9a-fA-F]{7,40}$') {
            return $value.Substring(0, [Math]::Min(8, $value.Length)).ToLowerInvariant()
        }
    }

    if (Test-Path -LiteralPath (Join-Path $RepositoryRoot '.git')) {
        $head = (& git -C $RepositoryRoot rev-parse --short=8 HEAD 2>$null)
        if ($LASTEXITCODE -eq 0 -and ([string]$head).Trim() -match '^[0-9a-fA-F]{7,8}$') {
            return ([string]$head).Trim().ToLowerInvariant()
        }
    }

    throw 'Could not resolve the release build commit. Set SPECREW_BUILD_COMMIT or package from a git checkout.'
}

function Get-SpecrewPackageContentSha256 {
    # A hash of WHAT IS IN THE PACKAGE, computed the same way runtime_bundle_sha256 is: sorted relative
    # paths plus per-file content, so the order files happen to be enumerated in cannot change it.
    # build-stamp.json is excluded because it is about to contain this value.
    #
    # -RelativePaths SCOPES THE HASH TO A KNOWN FILE SET, which an INSTALL needs and a stage does not.
    # An install legitimately carries files no package contains - the module's own version-check cache
    # and PowerShellGet's provenance file - so hashing the whole install root compares a package against
    # a package plus two extras and always disagrees. The first version did exactly that, and its own
    # post-install check caught it: byte verification passed for all 410 files and the identity assertion
    # still failed. The defect was in the question, not the copy.
    param(
        [Parameter(Mandatory = $true)][string]$StageRoot,
        [string[]]$RelativePaths
    )

    $root = (Resolve-Path -LiteralPath $StageRoot -ErrorAction Stop).Path
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $accumulator = [System.IO.MemoryStream]::new()
        $scoped = $null
        if ($null -ne $RelativePaths -and @($RelativePaths).Count -gt 0) {
            $scoped = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            foreach ($candidate in @($RelativePaths)) { [void]$scoped.Add(([string]$candidate -replace '\\', '/')) }
        }
        $files = @(Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction Stop |
                Where-Object { $_.Name -cne 'build-stamp.json' } |
                Where-Object { $null -eq $scoped -or $scoped.Contains((([IO.Path]::GetRelativePath($root, $_.FullName)) -replace '\\', '/')) } |
                Sort-Object { ([IO.Path]::GetRelativePath($root, $_.FullName) -replace '\\', '/') })
        foreach ($file in $files) {
            $relative = ([IO.Path]::GetRelativePath($root, $file.FullName) -replace '\\', '/')
            $nameBytes = [Text.Encoding]::UTF8.GetBytes($relative + "`n")
            $accumulator.Write($nameBytes, 0, $nameBytes.Length)
            $fileHash = $sha.ComputeHash([IO.File]::ReadAllBytes($file.FullName))
            $accumulator.Write($fileHash, 0, $fileHash.Length)
        }
        $accumulator.Position = 0
        return ([BitConverter]::ToString($sha.ComputeHash($accumulator)) -replace '-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Write-ReleaseBuildStamp {
    # THE STAMP DESCRIBES THE PACKAGE, NOT JUST THE INTENT.
    #
    # It used to record only a commit id supplied at package time, so an install could claim 248dd0d2
    # while carrying entirely different code - which is exactly what happened on 2026-08-20, and it was
    # caught only because someone diffed 82 files by hand. `commit` stays, because provenance is worth
    # recording; `content_sha256` is added so the claim is CHECKABLE against the files themselves.
    param(
        [Parameter(Mandatory = $true)][string]$StageRoot,
        [Parameter(Mandatory = $true)][string]$Commit
    )

    $stampPath = Join-Path $StageRoot 'build-stamp.json'
    # content_file_count RECORDS THE SCOPE, because a hash without its scope is not reproducible. The
    # first independent verification of this stamp disagreed with it, and the install was fine - the
    # verifier had scoped to FileList while the stamp covers every staged file except itself, which also
    # includes the optional README/CHANGELOG/LICENSE/NOTICE. A verifier who counts a different number of
    # files now knows that before comparing hashes, instead of suspecting the package.
    $stampedFiles = @(Get-ChildItem -LiteralPath $StageRoot -File -Recurse -Force -ErrorAction Stop |
            Where-Object { $_.Name -cne 'build-stamp.json' })
    $content = [ordered]@{
        schema = 'specrew-build-stamp/v1'
        commit = $Commit
        content_sha256 = Get-SpecrewPackageContentSha256 -StageRoot $StageRoot
        content_file_count = $stampedFiles.Count
    } | ConvertTo-Json
    [System.IO.File]::WriteAllText($stampPath, ($content + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    return $stampPath
}
