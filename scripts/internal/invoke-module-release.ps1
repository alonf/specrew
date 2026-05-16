[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'SigningCertPassword', Justification = 'GitHub Actions and local release tests supply secrets as strings; the script converts them before use.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password', Justification = 'Internal helper parameters are immediately converted to SecureString values for certificate import/export.')]
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path,

    [ValidateSet('dry-run', 'publish')]
    [string]$ReleaseMode = 'dry-run',

    [AllowEmptyString()]
    [string]$GitRefType = '',

    [AllowEmptyString()]
    [string]$GitRefName = '',

    [AllowEmptyString()]
    [string]$SigningCertBase64 = $env:SIGNING_CERT_BASE64,

    [AllowEmptyString()]
    [string]$SigningCertPassword = $env:SIGNING_CERT_PASSWORD,

    [AllowEmptyString()]
    [string]$PSGalleryApiKey = $env:PSGALLERY_API_KEY,

    [string]$SummaryPath,

    [switch]$AllowEphemeralSigningCertificate
)

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

function Set-SpecrewManifestVersion {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [Parameter(Mandatory = $true)][string]$Version
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Missing module manifest '$ManifestPath'."
    }

    $content = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8
    $updated = [regex]::Replace($content, "(?m)^(\s*ModuleVersion\s*=\s*)'[^']*'\s*$", ('$1''{0}''' -f $Version), 1)
    if ($updated -eq $content) {
        throw "Could not locate ModuleVersion in '$ManifestPath'."
    }

    if ($PSCmdlet.ShouldProcess($ManifestPath, ("Set ModuleVersion to {0}" -f $Version))) {
        [System.IO.File]::WriteAllText($ManifestPath, $updated, [System.Text.UTF8Encoding]::new($false))
    }
}

function Get-SpecrewManifestVersion {
    param([Parameter(Mandatory = $true)][string]$ManifestPath)

    $manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
    return [string]$manifest.Version
}

function Test-RefVersionAlignment {
    param(
        [Parameter(Mandatory = $true)][string]$ReleaseMode,
        [AllowEmptyString()][string]$GitRefType,
        [AllowEmptyString()][string]$GitRefName,
        [Parameter(Mandatory = $true)][string]$ExpectedVersion
    )

    if ([string]::IsNullOrWhiteSpace($GitRefType) -or [string]::IsNullOrWhiteSpace($GitRefName)) {
        if ($ReleaseMode -eq 'publish') {
            throw 'Live publish requires a workflow run that targets a v*.* tag ref.'
        }

        return
    }

    if ($GitRefType -ne 'tag') {
        if ($ReleaseMode -eq 'publish') {
            throw ("Live publish requires a tag ref, but the workflow is running against ref type '{0}'." -f $GitRefType)
        }

        return
    }

    if ($GitRefName -notmatch '^v(?<version>.+)$') {
        throw ("Tag '{0}' does not follow the required v*.* format." -f $GitRefName)
    }

    $tagVersion = $Matches.version
    if ($tagVersion -ne $ExpectedVersion) {
        throw ("Tag version '{0}' does not match .specrew/config.yml specrew_version '{1}'." -f $tagVersion, $ExpectedVersion)
    }
}

function Test-SigningCertificateValidity {
    param([Parameter(Mandatory = $true)][System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate)

    $validityDays = ($Certificate.NotAfter.ToUniversalTime() - $Certificate.NotBefore.ToUniversalTime()).TotalDays
    if ($validityDays -gt 370) {
        throw ("Signing certificate validity ({0:N1} days) exceeds the approved 1-year model." -f $validityDays)
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

function Import-SecretSigningCertificate {
    param(
        [Parameter(Mandatory = $true)][string]$ScratchRoot,
        [Parameter(Mandatory = $true)][string]$Base64,
        [Parameter(Mandatory = $true)][string]$Password
    )

    $pfxPath = Join-Path -Path $ScratchRoot -ChildPath 'specrew-signing-cert.pfx'
    [System.IO.File]::WriteAllBytes($pfxPath, [Convert]::FromBase64String($Base64))
    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $certificate = Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation 'Cert:\CurrentUser\My' -Password $securePassword -Exportable
    if ($null -eq $certificate -or -not $certificate.HasPrivateKey) {
        throw 'Failed to import signing certificate with a private key.'
    }

    Test-SigningCertificateValidity -Certificate $certificate
    return [pscustomobject]@{
        Certificate = $certificate
        CleanupPath = $pfxPath
        Source      = 'github-secret'
    }
}

function New-DryRunSigningCertificate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    param([Parameter(Mandatory = $true)][string]$ScratchRoot)

    $certificate = $null
    if ($PSCmdlet.ShouldProcess($ScratchRoot, 'Create dry-run self-signed code-signing certificate')) {
        $certificate = New-SelfSignedCertificate `
            -Subject 'CN=Specrew Module Signing (Dry Run)' `
            -Type CodeSigningCert `
            -CertStoreLocation 'Cert:\CurrentUser\My' `
            -NotAfter (Get-Date).AddYears(1)
    }

    Test-SigningCertificateValidity -Certificate $certificate
    return [pscustomobject]@{
        Certificate = $certificate
        CleanupPath = $null
        Source      = 'ephemeral-dry-run'
    }
}

function Get-ReleaseSigningCertificate {
    param(
        [Parameter(Mandatory = $true)][string]$ScratchRoot,
        [Parameter(Mandatory = $true)][string]$ReleaseMode,
        [AllowEmptyString()][string]$Base64,
        [AllowEmptyString()][string]$Password,
        [bool]$AllowEphemeralFallback
    )

    if (-not [string]::IsNullOrWhiteSpace($Base64) -and -not [string]::IsNullOrWhiteSpace($Password)) {
        return Import-SecretSigningCertificate -ScratchRoot $ScratchRoot -Base64 $Base64 -Password $Password
    }

    if ($ReleaseMode -eq 'publish') {
        throw 'Live publish requires SIGNING_CERT_BASE64 and SIGNING_CERT_PASSWORD to be configured.'
    }

    if (-not $AllowEphemeralFallback) {
        throw 'Dry-run release requires signing secrets or -AllowEphemeralSigningCertificate.'
    }

    return New-DryRunSigningCertificate -ScratchRoot $ScratchRoot
}

function Set-ReleaseSignature {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory = $true)][string[]]$FilePaths,
        [Parameter(Mandatory = $true)][System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    $results = @()
    foreach ($filePath in $FilePaths) {
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            throw "Missing file to sign '$filePath'."
        }

        if (-not $PSCmdlet.ShouldProcess($filePath, 'Apply Authenticode signature')) {
            continue
        }

        $null = Set-AuthenticodeSignature -FilePath $filePath -Certificate $Certificate -HashAlgorithm SHA256
        $verifiedSignature = Get-AuthenticodeSignature -FilePath $filePath
        if ($null -eq $verifiedSignature.SignerCertificate -or $verifiedSignature.SignerCertificate.Thumbprint -ne $Certificate.Thumbprint) {
            throw ("Signature verification for '{0}' did not match the expected signing certificate." -f $filePath)
        }

        if ($verifiedSignature.Status -in @('NotSigned', 'HashMismatch', 'NotSupportedFileFormat')) {
            throw ("Authenticode signing failed for '{0}' with status '{1}'." -f $filePath, $verifiedSignature.Status)
        }

        $results += [pscustomobject]@{
            Path   = $filePath
            Status = [string]$verifiedSignature.Status
        }
    }

    return $results
}

function Write-ReleaseSummary {
    param(
        [AllowEmptyString()][string]$SummaryPath,
        [Parameter(Mandatory = $true)][string]$ReleaseMode,
        [Parameter(Mandatory = $true)][string]$ModuleVersion,
        [AllowEmptyString()][string]$GitRefType,
        [AllowEmptyString()][string]$GitRefName,
        [Parameter(Mandatory = $true)][string]$SigningSource,
        [Parameter(Mandatory = $true)][object[]]$SignatureResults
    )

    if ([string]::IsNullOrWhiteSpace($SummaryPath)) {
        return
    }

    $lines = @(
        '# Specrew module release summary',
        '',
        ('- Mode: `{0}`' -f $ReleaseMode),
        ('- Module version: `{0}`' -f $ModuleVersion),
        ('- Git ref: `{0}:{1}`' -f ($(if ([string]::IsNullOrWhiteSpace($GitRefType)) { 'n/a' } else { $GitRefType }), $(if ([string]::IsNullOrWhiteSpace($GitRefName)) { 'n/a' } else { $GitRefName }))),
        ('- Signing source: `{0}`' -f $SigningSource),
        ('- Publish action: `{0}`' -f $(if ($ReleaseMode -eq 'publish') { 'live Publish-Module' } else { 'Publish-Module -WhatIf only' })),
        ''
    )

    foreach ($signatureResult in $SignatureResults) {
        $lines += ('- Signature `{0}` → `{1}`' -f ([System.IO.Path]::GetFileName($signatureResult.Path)), $signatureResult.Status)
    }

    $content = ($lines -join [Environment]::NewLine) + [Environment]::NewLine
    [System.IO.File]::WriteAllText($SummaryPath, $content, [System.Text.UTF8Encoding]::new($false))
}

$resolvedRepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$configPath = Join-Path -Path $resolvedRepositoryRoot -ChildPath '.specrew\config.yml'
$manifestPath = Join-Path -Path $resolvedRepositoryRoot -ChildPath 'Specrew.psd1'
$modulePath = Join-Path -Path $resolvedRepositoryRoot -ChildPath 'Specrew.psm1'
$scratchRoot = $null
$certificateHandle = $null
$signatureResults = @()

try {
    $scratchRoot = New-ReleaseScratchRoot -RepositoryRoot $resolvedRepositoryRoot

    $moduleVersion = Get-SpecrewVersionFromConfig -ConfigPath $configPath
    Write-ReleaseInfo ("Resolved module version {0} from .specrew/config.yml." -f $moduleVersion)

    Test-RefVersionAlignment -ReleaseMode $ReleaseMode -GitRefType $GitRefType -GitRefName $GitRefName -ExpectedVersion $moduleVersion

    Set-SpecrewManifestVersion -ManifestPath $manifestPath -Version $moduleVersion
    $stampedManifestVersion = Get-SpecrewManifestVersion -ManifestPath $manifestPath
    if ($stampedManifestVersion -ne $moduleVersion) {
        throw ("Stamped manifest version '{0}' did not match config version '{1}'." -f $stampedManifestVersion, $moduleVersion)
    }
    Write-ReleaseInfo ("Stamped Specrew.psd1 to version {0}." -f $moduleVersion)

    $null = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    Write-ReleaseInfo 'Test-ModuleManifest succeeded after stamping.'

    $certificateHandle = Get-ReleaseSigningCertificate `
        -ScratchRoot $scratchRoot `
        -ReleaseMode $ReleaseMode `
        -Base64 $SigningCertBase64 `
        -Password $SigningCertPassword `
        -AllowEphemeralFallback $AllowEphemeralSigningCertificate.IsPresent
    Write-ReleaseInfo ("Using signing certificate source '{0}'." -f $certificateHandle.Source)

    $signatureResults = Set-ReleaseSignature -FilePaths @($manifestPath, $modulePath) -Certificate $certificateHandle.Certificate
    foreach ($signatureResult in $signatureResults) {
        Write-ReleaseInfo ("Signed {0} ({1})." -f ([System.IO.Path]::GetFileName($signatureResult.Path)), $signatureResult.Status)
    }

    $publishParameters = @{
        Path          = $resolvedRepositoryRoot
        Repository    = 'PSGallery'
        ErrorAction   = 'Stop'
        Verbose       = $true
        NuGetApiKey   = $(if ([string]::IsNullOrWhiteSpace($PSGalleryApiKey)) { 'DRY-RUN-NO-LIVE-KEY' } else { $PSGalleryApiKey })
    }

    if ($ReleaseMode -eq 'publish') {
        if ([string]::IsNullOrWhiteSpace($PSGalleryApiKey)) {
            throw 'Live publish requires the PSGALLERY_API_KEY secret.'
        }

        Write-ReleaseInfo 'Running live Publish-Module to PSGallery.'
        Publish-Module @publishParameters
    }
    else {
        Write-ReleaseInfo 'Running Publish-Module -WhatIf dry-run (no live publish).'
        Publish-Module @publishParameters -WhatIf
    }

    Write-ReleaseSummary `
        -SummaryPath $SummaryPath `
        -ReleaseMode $ReleaseMode `
        -ModuleVersion $moduleVersion `
        -GitRefType $GitRefType `
        -GitRefName $GitRefName `
        -SigningSource $certificateHandle.Source `
        -SignatureResults $signatureResults

    [pscustomobject]@{
        ReleaseMode      = $ReleaseMode
        ModuleVersion    = $moduleVersion
        GitRefType       = $GitRefType
        GitRefName       = $GitRefName
        SigningSource    = $certificateHandle.Source
        SignatureResults = $signatureResults
    }
}
catch {
    Write-Error ("Module release failed: {0}" -f $_.Exception.Message)
    throw
}
finally {
    if ($null -ne $certificateHandle -and $null -ne $certificateHandle.Certificate) {
        $certificatePath = 'Cert:\CurrentUser\My\{0}' -f $certificateHandle.Certificate.Thumbprint
        if (Test-Path -LiteralPath $certificatePath) {
            Remove-Item -LiteralPath $certificatePath -Force -ErrorAction SilentlyContinue
        }
    }

    if ($null -ne $certificateHandle -and -not [string]::IsNullOrWhiteSpace($certificateHandle.CleanupPath) -and (Test-Path -LiteralPath $certificateHandle.CleanupPath)) {
        Remove-Item -LiteralPath $certificateHandle.CleanupPath -Force -ErrorAction SilentlyContinue
    }

    if (-not [string]::IsNullOrWhiteSpace($scratchRoot) -and (Test-Path -LiteralPath $scratchRoot)) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
