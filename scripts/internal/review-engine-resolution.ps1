Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# HARD dependency on the ONE path-identity primitive. Guarded on the exact function needed rather than
# on a sibling name - DRIFT-198-I009-027's shadow survived a guard that probed a DIFFERENT name, and a
# stale copy of path-identity.ps1 satisfies the older names while lacking anything added since.
if (-not (Get-Command -Name 'Get-ContinuousCoReviewPathComparison' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'continuous-co-review/path-identity.ps1')
}

function Test-SpecrewReviewRuntimePathUnderRoot {
    # This was the SEVENTH OS-family case shortcut, and the structural tests could not see it: they
    # scanned `scripts/internal/continuous-co-review` rather than `scripts/internal` whole
    # (DRIFT-198-I009-037). It is not a cosmetic instance - this predicate gates
    # Assert-SpecrewReviewRuntimePathContained, which authorizes DELETING a file named by an editable
    # managed-file marker in the target project. On a case-insensitive macOS volume the OS-family rule
    # chose Ordinal, so a case-aliased path compared as OUTSIDE the root: DRIFT-198-I009-015's exploit
    # shape on a delete path. Undetermined resolves to 'same' so containment answers "inside" more
    # readily, which is the REFUSING direction here.
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Root)
    $pathFull = [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $comparison = Get-ContinuousCoReviewPathComparison -Path $rootFull -WhenUndetermined 'same'
    return $pathFull.Equals($rootFull, $comparison) -or $pathFull.StartsWith($rootFull + [IO.Path]::DirectorySeparatorChar, $comparison)
}

function Assert-SpecrewReviewRuntimePathContained {
    # Lexical containment is NOT containment: GetFullPath only folds '..' and separators, so a path
    # whose ANCESTOR is a symlink/junction to an external directory still compares as under the root
    # while Get-Item, hashing, and Delete follow that ancestor outside the project. The managed-file
    # marker is an editable file in the target project supplying both the path AND its expected hash,
    # so a validly shaped marker could otherwise authorize deleting a matching external file. Reject
    # a reparse point at EVERY existing component from the root down, then re-verify containment.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Root)

    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $pathFull = [IO.Path]::GetFullPath($Path)
    if (-not (Test-SpecrewReviewRuntimePathUnderRoot -Path $pathFull -Root $rootFull)) {
        throw "review-runtime-managed-path-escapes-root:$Path"
    }
    $rootItem = Get-Item -LiteralPath $rootFull -Force -ErrorAction Stop
    if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "review-runtime-managed-root-link-unsupported:$Root"
    }

    $relative = $pathFull.Substring($rootFull.Length).Trim([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $current = $rootFull
    foreach ($segment in @($relative -split '[\\/]' | Where-Object { -not [string]::IsNullOrEmpty($_) })) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) { continue }
        $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "review-runtime-managed-path-link-unsupported:$Path"
        }
    }
    return $pathFull
}

function Get-SpecrewReviewRuntimeManagedTextSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "review-runtime-managed-file-link-unsupported:$Path"
    }
    $content = [IO.File]::ReadAllText($item.FullName, [Text.Encoding]::UTF8)
    $normalized = $content.Replace("`r`n", "`n").Replace("`r", "`n")
    return [Convert]::ToHexString(
        [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($normalized))
    ).ToLowerInvariant()
}

function ConvertTo-SpecrewReviewRuntimeManagedFileManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RuntimeRoot,
        [AllowNull()]$ManagedFiles
    )

    $root = [IO.Path]::GetFullPath($RuntimeRoot)
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $normalized = [Collections.Generic.List[object]]::new()
    foreach ($entry in @($ManagedFiles)) {
        if ($null -eq $entry -or -not $entry.PSObject.Properties['path'] -or -not $entry.PSObject.Properties['sha256']) {
            throw 'review-runtime-managed-manifest-entry-invalid'
        }
        $relative = ([string]$entry.path -replace '\\', '/').Trim()
        if ([string]::IsNullOrWhiteSpace($relative) -or $relative.StartsWith('/') -or
            $relative -match '^[A-Za-z]:' -or @($relative -split '/' | Where-Object { $_ -ceq '..' }).Count -gt 0) {
            throw "review-runtime-managed-path-unsafe:$relative"
        }
        $full = [IO.Path]::GetFullPath((Join-Path $root $relative))
        if (-not (Test-SpecrewReviewRuntimePathUnderRoot -Path $full -Root $root) -or $full -ceq $root) {
            throw "review-runtime-managed-path-unsafe:$relative"
        }
        if (-not $seen.Add($relative)) { throw "review-runtime-managed-path-duplicate:$relative" }
        $sha256 = [string]$entry.sha256
        if ($sha256 -cnotmatch '^[a-f0-9]{64}$') { throw "review-runtime-managed-hash-invalid:$relative" }
        $normalized.Add([pscustomobject][ordered]@{ path = $relative; sha256 = $sha256 }) | Out-Null
    }
    return @($normalized | Sort-Object path)
}

function Get-SpecrewReviewRuntimeManagedFileManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RuntimeRoot)

    $root = (Resolve-Path -LiteralPath $RuntimeRoot -ErrorAction Stop).Path
    $manifest = foreach ($file in @(Get-ChildItem -LiteralPath $root -File -Recurse -Force | Where-Object {
                $_.Name -cne '.specrew-runtime.json'
            } | Sort-Object {
                ([IO.Path]::GetRelativePath($root, $_.FullName) -replace '\\', '/')
            })) {
        $relative = ([IO.Path]::GetRelativePath($root, $file.FullName) -replace '\\', '/')
        [pscustomobject][ordered]@{
            path = $relative
            sha256 = Get-SpecrewReviewRuntimeManagedTextSha256 -Path $file.FullName
        }
    }
    return @(ConvertTo-SpecrewReviewRuntimeManagedFileManifest -RuntimeRoot $root -ManagedFiles @($manifest))
}

function Get-SpecrewReviewRuntimeBundleSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RuntimeRoot,
        [AllowNull()]$ManagedFiles
    )

    $root = (Resolve-Path -LiteralPath $RuntimeRoot -ErrorAction Stop).Path
    $manifest = if ($PSBoundParameters.ContainsKey('ManagedFiles')) {
        @(ConvertTo-SpecrewReviewRuntimeManagedFileManifest -RuntimeRoot $root -ManagedFiles $ManagedFiles)
    }
    else {
        @(Get-SpecrewReviewRuntimeManagedFileManifest -RuntimeRoot $root)
    }
    $hash = [Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
    try {
        foreach ($entry in $manifest) {
            $relative = [string]$entry.path
            $full = [IO.Path]::GetFullPath((Join-Path $root $relative))
            if (-not [IO.File]::Exists($full)) { throw "review-runtime-managed-file-missing:$relative" }
            $hash.AppendData([Text.Encoding]::UTF8.GetBytes($relative))
            $hash.AppendData([byte[]]@(0))
            # Managed deployment reads and rewrites runtime files as UTF-8 text.
            # Normalize line endings so an otherwise identical deployed engine does
            # not fail the handshake solely because of host checkout conventions or
            # a stripped UTF-8 BOM.
            $content = [IO.File]::ReadAllText($full, [Text.Encoding]::UTF8)
            $normalized = $content.Replace("`r`n", "`n").Replace("`r", "`n")
            $hash.AppendData([Text.Encoding]::UTF8.GetBytes($normalized))
            $hash.AppendData([byte[]]@(0))
        }
        return [Convert]::ToHexString($hash.GetHashAndReset()).ToLowerInvariant()
    }
    finally { $hash.Dispose() }
}

function Resolve-SpecrewReviewEngineRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$InstalledRuntimeRoot
    )

    $installed = (Resolve-Path -LiteralPath $InstalledRuntimeRoot -ErrorAction Stop).Path
    $project = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    $projectRuntime = Join-Path $project 'scripts/internal/continuous-co-review'
    $projectLoad = Join-Path $projectRuntime '_load.ps1'
    if (-not [IO.File]::Exists($projectLoad)) {
        return [pscustomobject][ordered]@{
            runtime_root = $installed
            source = 'installed'
            bundle_sha256 = Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $installed
            project_bundle_sha256 = $null
            marker_present = $false
        }
    }

    $installedHash = Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $installed
    $markerPath = Join-Path $projectRuntime '.specrew-runtime.json'
    $marker = $null
    $projectManagedFiles = $null
    if ([IO.File]::Exists($markerPath)) {
        try { $marker = [IO.File]::ReadAllText($markerPath, [Text.Encoding]::UTF8) | ConvertFrom-Json -Depth 8 }
        catch { throw "review-engine-marker-invalid:${markerPath}:$($_.Exception.Message)" }
        if ([string]$marker.schema_version -cne '1.0' -or [string]::IsNullOrWhiteSpace([string]$marker.runtime_bundle_sha256)) {
            throw "review-engine-marker-invalid:$markerPath"
        }
        if ($marker.PSObject.Properties['managed_files']) {
            $projectManagedFiles = @(
                ConvertTo-SpecrewReviewRuntimeManagedFileManifest -RuntimeRoot $projectRuntime -ManagedFiles $marker.managed_files
            )
        }
    }
    $projectHash = if ($null -ne $projectManagedFiles) {
        Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $projectRuntime -ManagedFiles $projectManagedFiles
    }
    else {
        Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $projectRuntime
    }
    if ($null -ne $marker) {
        if ([string]$marker.runtime_bundle_sha256 -cne $projectHash) {
            throw "review-engine-project-runtime-drifted: marker=$($marker.runtime_bundle_sha256); actual=$projectHash; run 'specrew update --project-path `"$project`"'"
        }
    }

    if ($projectHash -cne $installedHash) {
        $markerVersion = if ($null -ne $marker -and -not [string]::IsNullOrWhiteSpace([string]$marker.specrew_version)) { [string]$marker.specrew_version } else { 'unversioned' }
        throw "review-engine-version-mismatch: installed=$installedHash; project=$projectHash; project_version=$markerVersion; run 'specrew update --project-path `"$project`"' before review"
    }

    return [pscustomobject][ordered]@{
        runtime_root = $projectRuntime
        source = 'project-deployed'
        bundle_sha256 = $installedHash
        project_bundle_sha256 = $projectHash
        marker_present = ($null -ne $marker)
    }
}
