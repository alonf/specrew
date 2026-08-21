[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path,

    [ValidateSet('dry-run', 'publish-prerelease', 'publish-stable', 'promote-prerelease')]
    [string]$ReleaseMode = 'dry-run',

    [AllowEmptyString()]
    [string]$GitRefType = '',

    [AllowEmptyString()]
    [string]$GitRefName = '',

    [AllowEmptyString()]
    [string]$PSGalleryApiKey = $env:PSGALLERY_API_KEY,

    [string]$SummaryPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Staging, stamping and identity are SHARED with the local-install path so the two
# cannot drift. What stays here is release-specific: mode resolution, the summary,
# and Publish-Module.
. (Join-Path $PSScriptRoot 'module-packaging.ps1')












function Write-ReleaseSummary {
    param(
        [AllowEmptyString()][string]$SummaryPath,
        [Parameter(Mandatory = $true)][string]$ReleaseMode,
        [Parameter(Mandatory = $true)][string]$ModuleVersion,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$ManifestPrerelease,
        [Parameter(Mandatory = $true)][string]$EffectiveVersion,
        [AllowEmptyString()][string]$GitRefType,
        [AllowEmptyString()][string]$GitRefName
    )

    if ([string]::IsNullOrWhiteSpace($SummaryPath)) {
        return
    }

    $lines = @(
        '# Specrew module release summary',
        '',
        ('- Mode: `{0}`' -f $ReleaseMode),
        ('- Module version: `{0}`' -f $ModuleVersion),
        ('- Published version: `{0}`' -f $EffectiveVersion),
        ('- Manifest prerelease field: `{0}`' -f $(if ([string]::IsNullOrWhiteSpace($ManifestPrerelease)) { '(empty)' } else { $ManifestPrerelease })),
        ('- Git ref: `{0}:{1}`' -f $(if ([string]::IsNullOrWhiteSpace($GitRefType)) { 'n/a' } else { $GitRefType }), $(if ([string]::IsNullOrWhiteSpace($GitRefName)) { 'n/a' } else { $GitRefName })),
        '- Signing: `disabled (unsigned release default)`',
        ('- Publish action: `{0}`' -f $(if ($ReleaseMode -eq 'dry-run') { 'Publish-Module -WhatIf only' } elseif ($ReleaseMode -eq 'promote-prerelease') { 'live Publish-Module (stable promotion)' } else { 'live Publish-Module' })),
        ''
    )

    $content = ($lines -join [Environment]::NewLine) + [Environment]::NewLine
    [System.IO.File]::WriteAllText($SummaryPath, $content, [System.Text.UTF8Encoding]::new($false))
}

$resolvedRepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$configPath = Join-Path -Path $resolvedRepositoryRoot -ChildPath '.specrew\config.yml'
$manifestPath = Join-Path -Path $resolvedRepositoryRoot -ChildPath 'Specrew.psd1'
$scratchRoot = $null
$stageRoot = $null

try {
    $scratchRoot = New-ReleaseScratchRoot -RepositoryRoot $resolvedRepositoryRoot

    $moduleVersion = Get-SpecrewVersionFromConfig -ConfigPath $configPath
    Write-ReleaseInfo ("Resolved module version {0} from .specrew/config.yml." -f $moduleVersion)

    $releaseStamp = Resolve-ReleaseStamp -ReleaseMode $ReleaseMode -GitRefType $GitRefType -GitRefName $GitRefName -ExpectedVersion $moduleVersion
    Write-ReleaseInfo ("Resolved release mode '{0}' to publish version {1}." -f $ReleaseMode, $releaseStamp.EffectiveVersion)
    if (
        -not [string]::IsNullOrWhiteSpace($releaseStamp.SourcePrereleaseTag) -and
        $releaseStamp.SourcePrereleaseTag -ne $releaseStamp.ManifestPrerelease
    ) {
        Write-ReleaseInfo ("Normalized prerelease tag suffix '{0}' to PowerShellGet manifest value '{1}'." -f $releaseStamp.SourcePrereleaseTag, $releaseStamp.ManifestPrerelease)
    }

    $stageRoot = New-ReleaseStageRoot -RepositoryRoot $resolvedRepositoryRoot -ScratchRoot $scratchRoot -ManifestPath $manifestPath
    $stagedManifestPath = Join-Path -Path $stageRoot -ChildPath 'Specrew.psd1'

    $buildId = Get-ReleaseBuildId -RepositoryRoot $resolvedRepositoryRoot
    $buildStampPath = Write-ReleaseBuildStamp -StageRoot $stageRoot -Commit $buildId
    Write-ReleaseInfo ("Stamped staged build identity {0} in {1}." -f $buildId, (Split-Path -Leaf $buildStampPath))

    Set-SpecrewManifestReleaseMetadata -ManifestPath $stagedManifestPath -Version $moduleVersion -Prerelease $releaseStamp.ManifestPrerelease
    $stampedManifestInfo = Get-SpecrewManifestReleaseInfo -ManifestPath $stagedManifestPath
    if ($stampedManifestInfo.ModuleVersion -ne $moduleVersion) {
        throw ("Stamped manifest version '{0}' did not match config version '{1}'." -f $stampedManifestInfo.ModuleVersion, $moduleVersion)
    }

    if ($stampedManifestInfo.Prerelease -ne $releaseStamp.ManifestPrerelease) {
        throw ("Stamped manifest prerelease '{0}' did not match expected prerelease '{1}'." -f $stampedManifestInfo.Prerelease, $releaseStamp.ManifestPrerelease)
    }
    Write-ReleaseInfo ("Stamped staged Specrew.psd1 to version {0} with prerelease '{1}'." -f $moduleVersion, $releaseStamp.ManifestPrerelease)

    $null = Test-ModuleManifest -Path $stagedManifestPath -ErrorAction Stop
    Write-ReleaseInfo 'Test-ModuleManifest succeeded after stamping.'
    Write-ReleaseInfo 'Skipping Authenticode signing; unsigned packages are now the default release path.'

    $publishParameters = @{
        Path        = $stageRoot
        Repository  = 'PSGallery'
        ErrorAction = 'Stop'
        Verbose     = $true
        NuGetApiKey = $(if ([string]::IsNullOrWhiteSpace($PSGalleryApiKey)) { 'DRY-RUN-NO-LIVE-KEY' } else { $PSGalleryApiKey })
    }

    if ($ReleaseMode -ne 'dry-run') {
        if ([string]::IsNullOrWhiteSpace($PSGalleryApiKey)) {
            throw 'Live publish requires the PSGALLERY_API_KEY secret.'
        }

        Write-ReleaseInfo ("Running live Publish-Module to PSGallery for {0}." -f $releaseStamp.EffectiveVersion)
        Publish-Module @publishParameters
    }
    else {
        Write-ReleaseInfo ("Running Publish-Module -WhatIf dry-run for {0} (no live publish)." -f $releaseStamp.EffectiveVersion)
        Publish-Module @publishParameters -WhatIf
    }

    Write-ReleaseSummary `
        -SummaryPath $SummaryPath `
        -ReleaseMode $ReleaseMode `
        -ModuleVersion $moduleVersion `
        -ManifestPrerelease $releaseStamp.ManifestPrerelease `
        -EffectiveVersion $releaseStamp.EffectiveVersion `
        -GitRefType $GitRefType `
        -GitRefName $GitRefName

    [pscustomobject]@{
        ReleaseMode      = $ReleaseMode
        ModuleVersion    = $moduleVersion
        EffectiveVersion = $releaseStamp.EffectiveVersion
        Prerelease       = $releaseStamp.ManifestPrerelease
        GitRefType       = $GitRefType
        GitRefName       = $GitRefName
        SigningMode      = 'unsigned-default'
    }
}
catch {
    Write-Error ("Module release failed: {0}" -f $_.Exception.Message)
    throw
}
finally {
    if (-not [string]::IsNullOrWhiteSpace($scratchRoot) -and (Test-Path -LiteralPath $scratchRoot)) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
