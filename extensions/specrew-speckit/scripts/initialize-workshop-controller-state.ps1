#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ProjectRoot,

    [Parameter(Mandatory)]
    [string] $FeatureRef,

    [switch] $PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-AtomicUtf8NoBom {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $Content
    )

    $tempPath = '{0}.{1}.tmp' -f $Path, ([Guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($tempPath, $Content, [Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tempPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
}

$resolvedProjectRoot = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
)
if (-not (Test-Path -LiteralPath $resolvedProjectRoot -PathType Container)) {
    throw "Project root does not exist: '$resolvedProjectRoot'."
}
if (-not (Test-Path -LiteralPath (Join-Path $resolvedProjectRoot '.specrew/config.yml') -PathType Leaf)) {
    throw "Workshop controller state can only be initialized in a Specrew-governed project."
}
if ($FeatureRef -cnotmatch '^[0-9]{3}-[a-z0-9][a-z0-9-]{0,63}$') {
    throw "FeatureRef must be an exact Specrew feature reference such as '001-article-amplifier'."
}

$featureRoot = Join-Path (Join-Path $resolvedProjectRoot 'specs') $FeatureRef
if (-not (Test-Path -LiteralPath $featureRoot -PathType Container)) {
    throw "Feature directory does not exist: '$featureRoot'."
}

$specPath = Join-Path $featureRoot 'spec.md'
if (-not (Test-Path -LiteralPath $specPath -PathType Leaf)) {
    throw "Feature scaffold is incomplete because spec.md is missing: '$specPath'."
}
$specItem = Get-Item -LiteralPath $specPath -ErrorAction Stop
if ($specItem.Length -le 0 -or $specItem.Length -gt 1048576) {
    throw "Feature scaffold spec.md must be nonempty and no larger than 1 MiB."
}

$statePath = Join-Path $featureRoot 'lens-applicability.json'
if (Test-Path -LiteralPath $statePath) {
    throw "Refusing to overwrite existing workshop controller state: '$statePath'."
}

$state = [ordered]@{
    schema_version        = '1.1'
    workshop_intake       = $true
    confirmation_required = $true
    agenda_contract       = 'complete-coverage-v1'
    agenda_status         = 'pending-confirmation'
    selected              = @()
    agenda                = [ordered]@{}
    skipped               = [ordered]@{}
    agenda_confirmation   = 'pending'
    agenda_confirmation_scope = 'lens-selection'
    workshop              = [ordered]@{}
}
$json = ($state | ConvertTo-Json -Depth 6) + [Environment]::NewLine
Write-AtomicUtf8NoBom -Path $statePath -Content $json

if ($PassThru) {
    [pscustomobject]@{
        feature_ref   = $FeatureRef
        state         = 'pending-confirmation'
        artifact_path = $statePath
    }
}
