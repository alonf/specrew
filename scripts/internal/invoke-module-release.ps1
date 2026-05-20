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
    $updated = [regex]::Replace($content, "(?m)^(\s*ModuleVersion\s*=\s*)'[^']*'\s*$", ('$1''{0}''' -f $Version), 1)
    if ($updated -eq $content) {
        throw "Could not locate ModuleVersion in '$ManifestPath'."
    }

    $withPrerelease = [regex]::Replace($updated, "(?m)^(\s*Prerelease\s*=\s*)'[^']*'\s*$", ('$1''{0}''' -f $Prerelease), 1)
    if ($withPrerelease -eq $updated) {
        throw "Could not locate PrivateData.PSData.Prerelease in '$ManifestPath'."
    }

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
