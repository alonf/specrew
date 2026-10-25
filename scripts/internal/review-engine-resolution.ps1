Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# HARD dependency on the ONE path-identity primitive. Guarded on the exact function needed rather than
# on a sibling name - DRIFT-198-I009-027's shadow survived a guard that probed a DIFFERENT name, and a
# stale copy of path-identity.ps1 satisfies the older names while lacking anything added since.
if (-not (Get-Command -Name 'Get-ContinuousCoReviewPathComparison' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'continuous-co-review/path-identity.ps1')
}
# HARD dependency (T006/FR-011), guarded on the EXACT function called here for the same reason as
# above. This file is where DRIFT-199-I001-005 actually bit: the managed-file hash below refused
# `_load.ps1` on a OneDrive-backed install, so `specrew review --remediate override-block` - the
# sanctioned door for recording a governance decision - could not be opened at all.
if (-not (Get-Command -Name 'Get-SpecrewReparseDispositionForItem' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'continuous-co-review/reparse-tag-policy.ps1')
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
    # T006/FR-011: the redirecting families still refuse - that is the whole point of this walk - but a
    # cloud placeholder is not a redirect and must not be treated as one.
    $rootItem = Get-Item -LiteralPath $rootFull -Force -ErrorAction Stop
    $rootDisposition = Get-SpecrewReparseDispositionForItem -Item $rootItem
    if (Test-SpecrewReparseRefusesRead -Disposition $rootDisposition.disposition) {
        throw (Get-SpecrewReparseRefusalMessage -Code 'review-runtime-managed-root-link-unsupported' -Path $Root `
                -Disposition $rootDisposition.disposition -LinkType $rootDisposition.link_type)
    }

    $relative = $pathFull.Substring($rootFull.Length).Trim([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $current = $rootFull
    foreach ($segment in @($relative -split '[\\/]' | Where-Object { -not [string]::IsNullOrEmpty($_) })) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) { continue }
        $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        $disposition = Get-SpecrewReparseDispositionForItem -Item $item
        if (Test-SpecrewReparseRefusesRead -Disposition $disposition.disposition) {
            throw (Get-SpecrewReparseRefusalMessage -Code 'review-runtime-managed-path-link-unsupported' -Path $Path `
                    -Disposition $disposition.disposition -LinkType $disposition.link_type)
        }
    }
    # The walk above proves each existing component is non-redirecting. Re-check lexical
    # containment after the walk as promised by this function's contract; this also makes a future
    # path-normalization change fail at the authorization seam instead of relying on the comment.
    if (-not (Test-SpecrewReviewRuntimePathUnderRoot -Path $pathFull -Root $rootFull)) {
        throw "review-runtime-managed-path-escapes-root:$Path"
    }
    return $pathFull
}

function Read-SpecrewReviewRuntimeManagedText {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    # T006/FR-011 and DRIFT-199-I001-005's exact line. This is the check that refused
    # `...\OneDrive - <Org>\Documents\PowerShell\Modules\Specrew\0.40.0\...\_load.ps1` and took the
    # whole remediation door down with it. A link here is still refused; a placeholder is read.
    $disposition = Get-SpecrewReparseDispositionForItem -Item $item
    if (Test-SpecrewReparseRefusesRead -Disposition $disposition.disposition) {
        throw (Get-SpecrewReparseRefusalMessage -Code 'review-runtime-managed-file-link-unsupported' -Path $Path `
                -Disposition $disposition.disposition -LinkType $disposition.link_type)
    }
    # HYDRATION IS THE READ. Opening a cloud placeholder is what asks the sync client to fetch it, so
    # there is no separate hydrate step to call - but the fetch can fail (no network, sync client not
    # running, the file evicted from the service). Left bare, the consumer gets a raw IO error about a
    # path inside a module directory they never chose and no idea that syncing is what is wrong. The
    # wrap applies ONLY to the cloud family, so an ordinary IO failure keeps its own diagnosis.
    $content = if ($disposition.disposition -ceq 'hydrate-cloud') {
        try { [IO.File]::ReadAllText($item.FullName, [Text.Encoding]::UTF8) }
        catch {
            throw ("review-runtime-managed-file-hydration-unavailable:{0} - This file is stored in the cloud and its contents could not be downloaded, so Specrew cannot verify it. Check that you are online and your sync app (OneDrive or similar) is running, then run the command again. You can also open the folder and choose 'Always keep on this device' to keep it available offline. The underlying error was: {1}" -f $Path, $_.Exception.Message)
        }
    }
    else { [IO.File]::ReadAllText($item.FullName, [Text.Encoding]::UTF8) }
    return $content
}

function Get-SpecrewReviewRuntimeManagedTextSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $content = Read-SpecrewReviewRuntimeManagedText -Path $Path
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
            $full = Assert-SpecrewReviewRuntimePathContained -Path ([IO.Path]::GetFullPath((Join-Path $root $relative))) -Root $root
            if (-not [IO.File]::Exists($full)) { throw "review-runtime-managed-file-missing:$relative" }
            $hash.AppendData([Text.Encoding]::UTF8.GetBytes($relative))
            $hash.AppendData([byte[]]@(0))
            # Managed deployment reads and rewrites runtime files as UTF-8 text.
            # Normalize line endings so an otherwise identical deployed engine does
            # not fail the handshake solely because of host checkout conventions or
            # a stripped UTF-8 BOM.
            # Marker-provided manifests take this same reparse/hydration path as discovered
            # manifests. The editable marker may name files; it cannot bypass the read policy.
            $content = Read-SpecrewReviewRuntimeManagedText -Path $full
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
        $schemaProperty = $marker.PSObject.Properties['schema_version']
        $bundleProperty = $marker.PSObject.Properties['runtime_bundle_sha256']
        if (-not $schemaProperty -or -not $bundleProperty -or [string]$schemaProperty.Value -cne '1.0' -or
            [string]::IsNullOrWhiteSpace([string]$bundleProperty.Value)) {
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
        if ([string]$bundleProperty.Value -cne $projectHash) {
            throw "review-engine-project-runtime-drifted: marker=$($bundleProperty.Value); actual=$projectHash; run 'specrew update --project-path `"$project`"'"
        }
    }

    if ($projectHash -cne $installedHash) {
        $versionProperty = if ($null -ne $marker) { $marker.PSObject.Properties['specrew_version'] } else { $null }
        $markerVersion = if ($versionProperty -and -not [string]::IsNullOrWhiteSpace([string]$versionProperty.Value)) { [string]$versionProperty.Value } else { 'unversioned' }
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
