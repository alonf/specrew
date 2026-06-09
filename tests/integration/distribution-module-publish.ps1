[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Copy-ReleaseSurface {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Missing release surface '$SourcePath'."
    }

    $item = Get-Item -LiteralPath $SourcePath
    if ($item.PSIsContainer) {
        Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Recurse -Force
        return
    }

    $parent = Split-Path -Parent $DestinationPath
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -Path $parent -ItemType Directory -Force
    }

    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
}

function Get-PackagedFileList {
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath
    )

    $manifest = Import-PowerShellDataFile -Path $ManifestPath
    return @($manifest.FileList | ForEach-Object { [string]$_ })
}

function Reset-ReleaseWorkspace {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$DestinationRoot
    )

    if (Test-Path -LiteralPath $DestinationRoot) {
        if ($PSCmdlet.ShouldProcess($DestinationRoot, 'Reset release workspace')) {
            Remove-Item -LiteralPath $DestinationRoot -Recurse -Force
        }
    }

    if ($PSCmdlet.ShouldProcess($DestinationRoot, 'Create release workspace')) {
        $null = New-Item -Path $DestinationRoot -ItemType Directory -Force
    }

    $fileList = Get-PackagedFileList -ManifestPath (Join-Path -Path $SourceRoot -ChildPath 'Specrew.psd1')
    if ('scripts/internal/invoke-module-release.ps1' -notin $fileList) {
        throw "Specrew.psd1 FileList is missing required packaged entry 'scripts/internal/invoke-module-release.ps1'."
    }

    foreach ($relativePath in $fileList) {
        $normalizedRelativePath = $relativePath -replace '/', '\'
        Copy-ReleaseSurface `
            -SourcePath (Join-Path -Path $SourceRoot -ChildPath $normalizedRelativePath) `
            -DestinationPath (Join-Path -Path $DestinationRoot -ChildPath $normalizedRelativePath)
    }

    Copy-ReleaseSurface `
        -SourcePath (Join-Path -Path $SourceRoot -ChildPath '.specrew\config.yml') `
        -DestinationPath (Join-Path -Path $DestinationRoot -ChildPath '.specrew\config.yml')
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\distribution-module-publish'
$workspaceParent = Join-Path -Path $scratchRoot -ChildPath 'workspace'
$workspaceRoot = Join-Path -Path $workspaceParent -ChildPath 'Specrew'
$summaryPath = Join-Path -Path $scratchRoot -ChildPath 'release-summary.md'
$releaseScript = Join-Path -Path $workspaceRoot -ChildPath 'scripts\internal\invoke-module-release.ps1'
$expectedVersion = [string](Import-PowerShellDataFile -Path (Join-Path -Path $repoRoot -ChildPath 'Specrew.psd1')).ModuleVersion
$expectedTag = 'v{0}' -f $expectedVersion

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

Reset-ReleaseWorkspace -SourceRoot $repoRoot -DestinationRoot $workspaceRoot

if (-not (Get-Command -Name Publish-Module -ErrorAction SilentlyContinue)) {
    Write-Fail 'Publish-Module is unavailable in this environment.'
    exit 1
}

$dryRunOutput = @(
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $releaseScript `
        -RepositoryRoot $workspaceRoot `
        -ReleaseMode dry-run `
        -GitRefType tag `
        -GitRefName $expectedTag `
        -SummaryPath $summaryPath 2>&1
)
$dryRunExitCode = $LASTEXITCODE

if ($dryRunExitCode -ne 0) {
    Write-Fail ("Dry-run release flow failed with exit code {0}. Output:`n{1}" -f $dryRunExitCode, ($dryRunOutput -join [Environment]::NewLine))
    exit 1
}

$manifestContent = Get-Content -LiteralPath (Join-Path -Path $workspaceRoot -ChildPath 'Specrew.psd1') -Raw -Encoding UTF8
if ($manifestContent -notmatch ("ModuleVersion = '{0}'" -f [regex]::Escape($expectedVersion))) {
    Write-Fail 'Dry-run release flow did not stamp Specrew.psd1 to the config version.'
    exit 1
}
Write-Pass 'Dry-run release flow stamps Specrew.psd1 from .specrew/config.yml.'

foreach ($file in @('Specrew.psd1', 'Specrew.psm1')) {
    $signature = Get-AuthenticodeSignature -FilePath (Join-Path -Path $workspaceRoot -ChildPath $file)
    if ($null -ne $signature.SignerCertificate) {
        Write-Fail ("Dry-run release flow unexpectedly signed '{0}'." -f $file)
        exit 1
    }

    if ($signature.Status -ne 'NotSigned') {
        Write-Fail ("Dry-run release flow should leave '{0}' unsigned (status: {1})." -f $file, $signature.Status)
        exit 1
    }
}
Write-Pass 'Dry-run release flow leaves the manifest and module entry point unsigned.'

if (-not (Test-Path -LiteralPath $summaryPath -PathType Leaf)) {
    Write-Fail 'Dry-run release flow did not write a release summary artifact.'
    exit 1
}

$summaryContent = Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8
foreach ($pattern in @(
        'Mode: `dry-run`',
        'Signing: `disabled (unsigned release default)`',
        'Publish action: `Publish-Module -WhatIf only`'
    )) {
    if ($summaryContent -notmatch [regex]::Escape($pattern)) {
        Write-Fail ("Dry-run release summary missed expected text '{0}'." -f $pattern)
        exit 1
    }
}
Write-Pass 'Dry-run release summary records the manual-gated WhatIf path.'

Reset-ReleaseWorkspace -SourceRoot $repoRoot -DestinationRoot $workspaceRoot
$prereleaseSummaryPath = Join-Path -Path $scratchRoot -ChildPath 'release-summary-prerelease.md'
$workspaceManifestPath = Join-Path -Path $workspaceRoot -ChildPath 'Specrew.psd1'
$workspaceManifestContent = Get-Content -LiteralPath $workspaceManifestPath -Raw -Encoding UTF8
$workspaceManifestWithPrerelease = [regex]::Replace(
    $workspaceManifestContent,
    "(?m)^(\s*Prerelease\s*=\s*)'[^']*'\s*$",
    '$1''beta2''',
    1
)
if ($workspaceManifestWithPrerelease -eq $workspaceManifestContent -and $workspaceManifestContent -notmatch "Prerelease\s*=\s*'beta2'") {
    Write-Fail 'Could not prepare an already-stamped prerelease manifest fixture.'
    exit 1
}
[System.IO.File]::WriteAllText($workspaceManifestPath, $workspaceManifestWithPrerelease, [System.Text.UTF8Encoding]::new($false))

$prereleaseDryRunOutput = @(
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $releaseScript `
        -RepositoryRoot $workspaceRoot `
        -ReleaseMode dry-run `
        -GitRefType tag `
        -GitRefName ('{0}-beta2' -f $expectedTag) `
        -SummaryPath $prereleaseSummaryPath 2>&1
)
$prereleaseDryRunExitCode = $LASTEXITCODE

if ($prereleaseDryRunExitCode -ne 0) {
    Write-Fail ("Dry-run prerelease flow failed with exit code {0}. Output:`n{1}" -f $prereleaseDryRunExitCode, ($prereleaseDryRunOutput -join [Environment]::NewLine))
    exit 1
}

$prereleaseSummaryContent = Get-Content -LiteralPath $prereleaseSummaryPath -Raw -Encoding UTF8
foreach ($pattern in @(
        ('Published version: `{0}-beta2`' -f $expectedVersion),
        'Manifest prerelease field: `beta2`'
    )) {
    if ($prereleaseSummaryContent -notmatch [regex]::Escape($pattern)) {
        Write-Fail ("Dry-run prerelease summary missed expected text '{0}'." -f $pattern)
        exit 1
    }
}
Write-Pass 'Dry-run release flow accepts an already-stamped prerelease manifest.'

Reset-ReleaseWorkspace -SourceRoot $repoRoot -DestinationRoot $workspaceRoot
$publishModeOutput = @(
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $releaseScript `
        -RepositoryRoot $workspaceRoot `
        -ReleaseMode publish-stable `
        -GitRefType branch `
        -GitRefName 019-specrew-distribution-module 2>&1
)
$publishModeExitCode = $LASTEXITCODE

if ($publishModeExitCode -eq 0) {
    Write-Fail 'Publish mode unexpectedly succeeded without a tag-scoped manual release.'
    exit 1
}

$publishModeText = $publishModeOutput -join [Environment]::NewLine
if ($publishModeText -notmatch 'requires a tag ref') {
    Write-Fail 'Publish mode failure did not explain the tag-scoped manual gate.'
    exit 1
}
Write-Pass 'Publish mode refuses to run outside the tagged manual gate.'

Reset-ReleaseWorkspace -SourceRoot $repoRoot -DestinationRoot $workspaceRoot
$publishNoKeyOutput = @()
$publishNoKeyExitCode = 0

$publishNoKeyOutput = @(
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $releaseScript `
        -RepositoryRoot $workspaceRoot `
        -ReleaseMode publish-stable `
        -GitRefType tag `
        -GitRefName $expectedTag 2>&1
)
$publishNoKeyExitCode = $LASTEXITCODE

if ($publishNoKeyExitCode -eq 0) {
    Write-Fail 'Publish mode unexpectedly succeeded without PSGALLERY_API_KEY.'
    exit 1
}

$publishNoKeyText = $publishNoKeyOutput -join [Environment]::NewLine
if ($publishNoKeyText -notmatch 'PSGALLERY_API_KEY') {
    Write-Fail 'Publish mode failure did not explain the missing PSGALLERY_API_KEY secret.'
    exit 1
}
Write-Pass 'Publish mode reports missing PSGALLERY_API_KEY clearly.'

Write-Host ''
Write-Host 'Distribution module publish workflow tests passed.' -ForegroundColor Green
exit 0
