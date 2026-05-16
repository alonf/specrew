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

    foreach ($surface in @(
            '.github',
            '.specrew',
            'docs',
            'extensions',
            'scripts',
            'templates',
            'Specrew.psd1',
            'Specrew.psm1'
        )) {
        Copy-ReleaseSurface -SourcePath (Join-Path -Path $SourceRoot -ChildPath $surface) -DestinationPath (Join-Path -Path $DestinationRoot -ChildPath $surface)
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\distribution-module-publish'
$workspaceParent = Join-Path -Path $scratchRoot -ChildPath 'workspace'
$workspaceRoot = Join-Path -Path $workspaceParent -ChildPath 'Specrew'
$summaryPath = Join-Path -Path $scratchRoot -ChildPath 'release-summary.md'
$releaseScript = Join-Path -Path $repoRoot -ChildPath 'scripts\internal\invoke-module-release.ps1'

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
        -GitRefName v0.18.0 `
        -AllowEphemeralSigningCertificate `
        -SummaryPath $summaryPath 2>&1
)
$dryRunExitCode = $LASTEXITCODE

if ($dryRunExitCode -ne 0) {
    Write-Fail ("Dry-run release flow failed with exit code {0}. Output:`n{1}" -f $dryRunExitCode, ($dryRunOutput -join [Environment]::NewLine))
    exit 1
}

$manifestContent = Get-Content -LiteralPath (Join-Path -Path $workspaceRoot -ChildPath 'Specrew.psd1') -Raw -Encoding UTF8
if ($manifestContent -notmatch "ModuleVersion = '0\.18\.0'") {
    Write-Fail 'Dry-run release flow did not stamp Specrew.psd1 to the config version.'
    exit 1
}
Write-Pass 'Dry-run release flow stamps Specrew.psd1 from .specrew/config.yml.'

foreach ($file in @('Specrew.psd1', 'Specrew.psm1')) {
    $signature = Get-AuthenticodeSignature -FilePath (Join-Path -Path $workspaceRoot -ChildPath $file)
    if ($null -eq $signature.SignerCertificate) {
        Write-Fail ("Dry-run release flow did not record a signer certificate for '{0}'." -f $file)
        exit 1
    }

    if ($signature.Status -notin @('Valid', 'NotTrusted', 'UnknownError')) {
        Write-Fail ("Dry-run release flow did not sign '{0}' successfully (status: {1})." -f $file, $signature.Status)
        exit 1
    }
}
Write-Pass 'Dry-run release flow signs the manifest and module entry point.'

if (-not (Test-Path -LiteralPath $summaryPath -PathType Leaf)) {
    Write-Fail 'Dry-run release flow did not write a release summary artifact.'
    exit 1
}

$summaryContent = Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8
foreach ($pattern in @(
        'Mode: `dry-run`',
        'Signing source: `ephemeral-dry-run`',
        'Publish action: `Publish-Module -WhatIf only`'
    )) {
    if ($summaryContent -notmatch [regex]::Escape($pattern)) {
        Write-Fail ("Dry-run release summary missed expected text '{0}'." -f $pattern)
        exit 1
    }
}
Write-Pass 'Dry-run release summary records the manual-gated WhatIf path.'

Reset-ReleaseWorkspace -SourceRoot $repoRoot -DestinationRoot $workspaceRoot
$publishModeOutput = @(
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $releaseScript `
        -RepositoryRoot $workspaceRoot `
        -ReleaseMode publish `
        -GitRefType branch `
        -GitRefName 019-specrew-distribution-module 2>&1
)
$publishModeExitCode = $LASTEXITCODE

if ($publishModeExitCode -eq 0) {
    Write-Fail 'Publish mode unexpectedly succeeded without a tag-scoped manual release.'
    exit 1
}

$publishModeText = $publishModeOutput -join [Environment]::NewLine
if ($publishModeText -notmatch 'Live publish requires a tag ref') {
    Write-Fail 'Publish mode failure did not explain the tag-scoped manual gate.'
    exit 1
}
Write-Pass 'Publish mode refuses to run outside the tagged manual gate.'

Reset-ReleaseWorkspace -SourceRoot $repoRoot -DestinationRoot $workspaceRoot
$exportPassword = ConvertTo-SecureString -String 'SpecrewTest123!' -AsPlainText -Force
$exportedCertPath = Join-Path -Path $scratchRoot -ChildPath 'publish-mode-test-cert.pfx'
$exportedCert = $null
$publishNoKeyOutput = @()
$publishNoKeyExitCode = 0

try {
    $exportedCert = New-SelfSignedCertificate `
        -Subject 'CN=Specrew Publish Test' `
        -Type CodeSigningCert `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -NotAfter (Get-Date).AddYears(1)
    Export-PfxCertificate -Cert $exportedCert -FilePath $exportedCertPath -Password $exportPassword | Out-Null
    $certBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($exportedCertPath))

    $publishNoKeyOutput = @(
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $releaseScript `
            -RepositoryRoot $workspaceRoot `
            -ReleaseMode publish `
            -GitRefType tag `
            -GitRefName v0.18.0 `
            -SigningCertBase64 $certBase64 `
            -SigningCertPassword 'SpecrewTest123!' 2>&1
    )
    $publishNoKeyExitCode = $LASTEXITCODE
}
finally {
    if ($null -ne $exportedCert) {
        $certPath = 'Cert:\CurrentUser\My\{0}' -f $exportedCert.Thumbprint
        if (Test-Path -LiteralPath $certPath) {
            Remove-Item -LiteralPath $certPath -Force -ErrorAction SilentlyContinue
        }
    }

    if (Test-Path -LiteralPath $exportedCertPath) {
        Remove-Item -LiteralPath $exportedCertPath -Force -ErrorAction SilentlyContinue
    }
}

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
