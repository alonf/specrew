Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SpecrewReviewRuntimeBundleSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RuntimeRoot)

    $root = (Resolve-Path -LiteralPath $RuntimeRoot -ErrorAction Stop).Path
    $files = @(Get-ChildItem -LiteralPath $root -File -Recurse | Where-Object {
        $_.Name -cne '.specrew-runtime.json'
    } | Sort-Object {
        ([IO.Path]::GetRelativePath($root, $_.FullName) -replace '\\', '/')
    })
    $hash = [Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
    try {
        foreach ($file in $files) {
            $relative = ([IO.Path]::GetRelativePath($root, $file.FullName) -replace '\\', '/')
            $hash.AppendData([Text.Encoding]::UTF8.GetBytes($relative))
            $hash.AppendData([byte[]]@(0))
            # Managed deployment reads and rewrites runtime files as UTF-8 text.
            # Normalize line endings so an otherwise identical deployed engine does
            # not fail the handshake solely because of host checkout conventions or
            # a stripped UTF-8 BOM.
            $content = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
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
    $projectHash = Get-SpecrewReviewRuntimeBundleSha256 -RuntimeRoot $projectRuntime
    $markerPath = Join-Path $projectRuntime '.specrew-runtime.json'
    $marker = $null
    if ([IO.File]::Exists($markerPath)) {
        try { $marker = [IO.File]::ReadAllText($markerPath, [Text.Encoding]::UTF8) | ConvertFrom-Json -Depth 8 }
        catch { throw "review-engine-marker-invalid:${markerPath}:$($_.Exception.Message)" }
        if ([string]$marker.schema_version -cne '1.0' -or [string]::IsNullOrWhiteSpace([string]$marker.runtime_bundle_sha256)) {
            throw "review-engine-marker-invalid:$markerPath"
        }
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
