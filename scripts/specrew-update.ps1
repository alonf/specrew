param(
    [string]$ProjectPath = '.',
    [switch]$InfoMode,
    [switch]$All,
    [switch]$Specrew,
    [switch]$Squad,
    [switch]$SpecKit,
    [switch]$SkipUpdateCheck,
    [switch]$UpstreamLatest,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

$versionCheckHelperPath = Join-Path $PSScriptRoot 'internal\version-check.ps1'
if (-not (Test-Path -LiteralPath $versionCheckHelperPath -PathType Leaf)) {
    throw "Missing version-check helper '$versionCheckHelperPath'."
}
. $versionCheckHelperPath

function Get-NativeExitCode {
    if (Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue) {
        return $global:LASTEXITCODE
    }

    return 0
}

function Convert-UnixStyleArguments {
    param(
        [string]$ProjectPath,
        [bool]$InfoMode,
        [bool]$All,
        [bool]$Specrew,
        [bool]$Squad,
        [bool]$SpecKit,
        [bool]$SkipUpdateCheck,
        [bool]$UpstreamLatest,
        [bool]$Help,
        [string[]]$CliArgs
    )

    $result = [ordered]@{
        ProjectPath     = $ProjectPath
        InfoMode        = $InfoMode
        All             = $All
        Specrew         = $Specrew
        Squad           = $Squad
        SpecKit         = $SpecKit
        SkipUpdateCheck = $SkipUpdateCheck
        UpstreamLatest  = $UpstreamLatest
        Help            = $Help
    }

    if (-not $CliArgs -or $CliArgs.Count -eq 0) {
        return [pscustomobject]$result
    }

    $index = 0
    while ($index -lt $CliArgs.Count) {
        $arg = $CliArgs[$index]
        switch ($arg) {
            '--project-path' {
                $index++
                if ($index -ge $CliArgs.Count) {
                    throw '--project-path requires a value.'
                }

                $result.ProjectPath = $CliArgs[$index]
            }
            '--info' {
                $result.InfoMode = $true
            }
            '--all' {
                $result.All = $true
            }
            '--specrew' {
                $result.Specrew = $true
            }
            '--squad' {
                $result.Squad = $true
            }
            '--spec-kit' {
                $result.SpecKit = $true
            }
            '--skip-update-check' {
                $result.SkipUpdateCheck = $true
            }
            '--upstream-latest' {
                $result.UpstreamLatest = $true
            }
            '--help' {
                $result.Help = $true
            }
            default {
                throw ("Unknown argument '{0}'." -f $arg)
            }
        }

        $index++
    }

    return [pscustomobject]$result
}

function Show-Usage {
    @'
specrew update [options]

Options:
  -ProjectPath | --project-path <path>
                         Target Specrew-managed project directory (defaults to current directory)
  -InfoMode | --info     Show current vs latest known versions without mutating the project
  -All | --all           Update Specrew, Spec Kit, and Squad together
  -Specrew | --specrew   Update Specrew-managed project surfaces only
  -Squad | --squad       Upgrade Squad to the latest known compatible version
  -SpecKit | --spec-kit  Upgrade Spec Kit to the latest known compatible version
  -SkipUpdateCheck | --skip-update-check
                         Skip the PSGallery latest-version check for this run
  -UpstreamLatest | --upstream-latest
                         Target upstream-latest versions instead of Specrew-validated
                         max_tested versions. Use this when you accept the risk of
                         running dependencies Specrew has not yet validated against.
  -Help | --help         Show usage

Behavior:
  - Bare `specrew update` refreshes Specrew-managed project assets only.
  - `specrew update --info` reports current versions alongside both LatestSupported
    (the highest version Specrew has validated against) and UpstreamLatest (advisory).
    Default upgrade targets the LatestSupported version.
  - `--upstream-latest` switches the upgrade target to UpstreamLatest. Use with care:
    Specrew may not have validated against versions beyond max_tested.
  - When Specrew-only update completes, the command still notifies you if newer Squad or Spec Kit versions are available.
'@ | Write-Host
}

function Get-ParsedVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $match = [regex]::Match($Value, '(?<version>\d+\.\d+\.\d+(?:\.\d+)?)')
    if (-not $match.Success) {
        throw "Could not parse $Name version from '$Value'."
    }

    return [version]$match.Groups['version'].Value
}

function Get-SpecrewUpdateDowngradeGuardResult {
    param(
        [AllowNull()]
        [string]$RunningVersion,

        [AllowNull()]
        [string]$ProjectBaselineVersion
    )

    if ([string]::IsNullOrWhiteSpace($ProjectBaselineVersion)) {
        return [pscustomobject]@{
            ShouldRefuse = $false
            Reason       = 'project-baseline-absent'
        }
    }

    try {
        $runningSemanticVersion = Get-ParsedVersion -Value $RunningVersion -Name 'running Specrew module'
    }
    catch {
        return [pscustomobject]@{
            ShouldRefuse = $true
            Reason       = 'running-version-unparsable'
            Detail       = $_.Exception.Message
        }
    }

    try {
        $projectSemanticVersion = Get-ParsedVersion -Value $ProjectBaselineVersion -Name 'project Specrew baseline'
    }
    catch {
        return [pscustomobject]@{
            ShouldRefuse = $true
            Reason       = 'project-baseline-unparsable'
            Detail       = $_.Exception.Message
        }
    }

    if ($runningSemanticVersion -lt $projectSemanticVersion) {
        return [pscustomobject]@{
            ShouldRefuse = $true
            Reason       = 'running-module-older-than-project'
        }
    }

    return [pscustomobject]@{
        ShouldRefuse = $false
        Reason       = 'running-module-current-or-newer'
    }
}

function Write-SpecrewUpdateDowngradeRefusal {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$GuardResult,

        [AllowNull()]
        [string]$RunningVersion,

        [AllowNull()]
        [string]$ProjectBaselineVersion
    )

    $runningDisplay = if ([string]::IsNullOrWhiteSpace($RunningVersion)) { 'unknown' } else { $RunningVersion }
    $baselineDisplay = if ([string]::IsNullOrWhiteSpace($ProjectBaselineVersion)) { 'unknown' } else { $ProjectBaselineVersion }

    Write-Output 'ERROR: Refusing to run specrew update because this Specrew module cannot safely update the target project baseline.'
    Write-Output ("Running Specrew module version: {0}" -f $runningDisplay)
    Write-Output ("Project baseline (.specrew/config.yml specrew_version): {0}" -f $baselineDisplay)
    if ($GuardResult.Reason -eq 'project-baseline-unparsable' -or $GuardResult.Reason -eq 'running-version-unparsable') {
        Write-Output ("Reason: {0}" -f $GuardResult.Reason)
    }
    else {
        Write-Output 'Reason: running Specrew module is older than the project baseline.'
    }
    Write-Output 'No project files were changed.'
    Write-Output 'To proceed, update the module with Update-Module Specrew, or set SPECREW_MODULE_PATH to a matching Specrew development tree before retrying.'
}

function Get-ExtensionVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    $manifestContent = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8
    $versionMatch = [regex]::Match($manifestContent, '(?m)^\s*version:\s*"?(?<version>[^"\r\n]+)')
    if (-not $versionMatch.Success) {
        throw "Could not determine version from '$ManifestPath'."
    }

    return $versionMatch.Groups['version'].Value.Trim()
}

function Get-ConfigMap {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    $map = @{}
    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        return $map
    }

    foreach ($line in @(Get-Content -LiteralPath $ConfigPath -Encoding UTF8)) {
        $match = [regex]::Match($line, '^(?<key>[a-z_]+):\s*"?(?<value>[^"\r\n]*)"?\s*$')
        if ($match.Success) {
            $map[$match.Groups['key'].Value] = $match.Groups['value'].Value
        }
    }

    return $map
}

function Set-YamlScalarValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $escapedKey = [regex]::Escape($Key)
    $replacement = '{0}: "{1}"' -f $Key, $Value.Replace('"', '\"')
    if ($Content -match ("(?m)^\s*{0}:\s*" -f $escapedKey)) {
        return [regex]::Replace($Content, "(?m)^\s*${escapedKey}:\s*.*$", $replacement)
    }

    $trimmed = $Content.TrimEnd()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return $replacement + [Environment]::NewLine
    }

    return $trimmed + [Environment]::NewLine + $replacement + [Environment]::NewLine
}

function Update-SpecrewConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [AllowNull()]
        [string]$SpecrewVersion,

        [AllowNull()]
        [string]$SpecKitVersion,

        [AllowNull()]
        [string]$SquadVersion
    )

    $existingContent = if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
        Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8
    }
    else {
        ''
    }

    $updatedContent = $existingContent
    $updatedContent = Set-YamlScalarValue -Content $updatedContent -Key 'schema' -Value 'v1'
    if (-not [string]::IsNullOrWhiteSpace($SpecrewVersion)) {
        $updatedContent = Set-YamlScalarValue -Content $updatedContent -Key 'specrew_version' -Value $SpecrewVersion
    }
    if (-not [string]::IsNullOrWhiteSpace($SpecKitVersion)) {
        $updatedContent = Set-YamlScalarValue -Content $updatedContent -Key 'speckit_version' -Value $SpecKitVersion
    }
    if (-not [string]::IsNullOrWhiteSpace($SquadVersion)) {
        $updatedContent = Set-YamlScalarValue -Content $updatedContent -Key 'squad_version' -Value $SquadVersion
    }

    if ($updatedContent -eq $existingContent) {
        return 'preserved'
    }

    [System.IO.File]::WriteAllText($ConfigPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
    return 'updated'
}

function Get-FirstNonEmptyOutputLine {
    param(
        [AllowEmptyCollection()]
        [string[]]$OutputLines
    )

    return @($OutputLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)[0]
}

function Get-VersionValidationResults {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ValidateScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$MinimumSpecKitVersion,

        [Parameter(Mandatory = $true)]
        [string]$MinimumSquadVersion
    )

    return @(
        & $ValidateScriptPath `
            -MinimumSpecKitVersion $MinimumSpecKitVersion `
            -MinimumSquadVersion $MinimumSquadVersion `
            -PassThru
    )
}

function Get-OverrideVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    return $value.Trim()
}

function Get-HighestSemanticVersion {
    param(
        [AllowEmptyCollection()]
        [string[]]$Candidates
    )

    $bestVersion = $null
    $bestText = $null
    foreach ($candidate in @($Candidates)) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        try {
            $parsed = Get-ParsedVersion -Value $candidate -Name 'candidate'
            if ($null -eq $bestVersion -or $parsed -gt $bestVersion) {
                $bestVersion = $parsed
                $bestText = $parsed.ToString()
            }
        }
        catch {
            continue
        }
    }

    return $bestText
}

function Get-LatestGitTagVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repository
    )

    $output = @(& git ls-remote --tags --refs $Repository 2>&1)
    if ((Get-NativeExitCode) -ne 0) {
        return $null
    }

    $versions = foreach ($line in $output) {
        $match = [regex]::Match([string]$line, 'refs/tags/(?<tag>v?\d+\.\d+\.\d+(?:\.\d+)?)$')
        if ($match.Success) {
            $match.Groups['tag'].Value
        }
    }

    return Get-HighestSemanticVersion -Candidates $versions
}

function Get-LatestNpmPackageVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    $output = @(& npm view $PackageName version 2>&1)
    if ((Get-NativeExitCode) -ne 0) {
        return $null
    }

    return Get-HighestSemanticVersion -Candidates $output
}

function Get-LatestVersionInfo {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Specrew', 'Spec Kit', 'Squad')]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$SpecrewVersion
    )

    switch ($Platform) {
        'Specrew' {
            $override = Get-OverrideVersion -Name 'SPECREW_UPDATE_LATEST_SPECREW'
            if ($override) {
                return [pscustomobject]@{
                    Version = $override
                    Source  = 'override'
                    Known   = $true
                }
            }

            # Check PSGallery first as the authoritative latest published source.
            $skip = if ($null -ne $SkipUpdateCheck) { [bool]$SkipUpdateCheck } else { $false }
            try {
                $psgInfo = Get-PSGalleryLatestVersion -ProjectRoot $RepoRoot -SkipCheck $skip
                if ($null -ne $psgInfo -and -not [string]::IsNullOrWhiteSpace($psgInfo.LatestVersion)) {
                    return [pscustomobject]@{
                        Version = $psgInfo.LatestVersion
                        Source  = $psgInfo.Source
                        Known   = $true
                    }
                }
            }
            catch {
                # Fall back on query failure
            }

            # Prefer the actually-installed module's manifest as the fallback "latest known" version.
            # Git tags lag behind real shipping (we ship 0.22.0 without yet tagging v0.22.0),
            # so origin-tags drift falsely reports older versions. Module manifest is authoritative.
            $moduleVersion = $null
            try {
                $moduleVersion = Get-SpecrewInstalledVersion -ProjectRoot $RepoRoot
            }
            catch {
                $moduleVersion = $null
            }

            if ($moduleVersion) {
                return [pscustomobject]@{
                    Version = $moduleVersion
                    Source  = 'module-manifest'
                    Known   = $true
                }
            }

            # Fall back to origin-tags only when no module manifest is reachable.
            $remoteUrl = @(& git -C $RepoRoot remote get-url origin 2>$null)
            $remoteVersion = if ((Get-NativeExitCode) -eq 0 -and $remoteUrl) {
                Get-LatestGitTagVersion -Repository ([string]$remoteUrl[0])
            }
            else {
                $null
            }

            if ($remoteVersion) {
                return [pscustomobject]@{
                    Version = $remoteVersion
                    Source  = 'origin-tags'
                    Known   = $true
                }
            }

            return [pscustomobject]@{
                Version = $SpecrewVersion
                Source  = 'local-source'
                Known   = $true
            }
        }
        'Spec Kit' {
            $override = Get-OverrideVersion -Name 'SPECREW_UPDATE_LATEST_SPECKIT'
            if ($override) {
                return [pscustomobject]@{
                    Version = $override
                    Source  = 'override'
                    Known   = $true
                }
            }

            $latest = Get-LatestGitTagVersion -Repository 'https://github.com/github/spec-kit.git'
            return [pscustomobject]@{
                Version = $latest
                Source  = if ($latest) { 'github-tags' } else { 'unavailable' }
                Known   = -not [string]::IsNullOrWhiteSpace($latest)
            }
        }
        'Squad' {
            $override = Get-OverrideVersion -Name 'SPECREW_UPDATE_LATEST_SQUAD'
            if ($override) {
                return [pscustomobject]@{
                    Version = $override
                    Source  = 'override'
                    Known   = $true
                }
            }

            $latest = Get-LatestNpmPackageVersion -PackageName '@bradygaster/squad-cli'
            return [pscustomobject]@{
                Version = $latest
                Source  = if ($latest) { 'npm' } else { 'unavailable' }
                Known   = -not [string]::IsNullOrWhiteSpace($latest)
            }
        }
    }
}

function Get-SpecKitInstallArguments {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $gitReference = if ($Version.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
        $Version
    }
    else {
        'v{0}' -f $Version
    }

    return @(
        'tool',
        'install',
        '--force',
        'specify-cli',
        '--from',
        ('git+https://github.com/github/spec-kit.git@{0}' -f $gitReference)
    )
}

function Install-PlatformVersion {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Spec Kit', 'Squad')]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    switch ($Platform) {
        'Spec Kit' {
            if (-not (Get-Command -Name 'uv' -ErrorAction SilentlyContinue)) {
                throw "Cannot upgrade Spec Kit because 'uv' is unavailable."
            }

            & uv @(Get-SpecKitInstallArguments -Version $Version)
            if ((Get-NativeExitCode) -ne 0) {
                throw ("Failed to upgrade Spec Kit to {0}." -f $Version)
            }
        }
        'Squad' {
            if (-not (Get-Command -Name 'npm' -ErrorAction SilentlyContinue)) {
                throw "Cannot upgrade Squad because 'npm' is unavailable."
            }

            & npm install -g ("@bradygaster/squad-cli@{0}" -f $Version)
            if ((Get-NativeExitCode) -ne 0) {
                throw ("Failed to upgrade Squad to {0}." -f $Version)
            }
        }
    }
}

function Get-RequestedScopes {
    param(
        [bool]$All,
        [bool]$Specrew,
        [bool]$Squad,
        [bool]$SpecKit
    )

    $selectedSpecific = @()
    if ($Specrew) { $selectedSpecific += 'Specrew' }
    if ($Squad) { $selectedSpecific += 'Squad' }
    if ($SpecKit) { $selectedSpecific += 'Spec Kit' }

    if ($All -and $selectedSpecific.Count -gt 0) {
        throw 'Use either --all or explicit platform flags, not both.'
    }

    if ($All) {
        return @('Specrew', 'Spec Kit', 'Squad')
    }

    if ($selectedSpecific.Count -gt 0) {
        return $selectedSpecific
    }

    return @('Specrew')
}

function Compare-VersionState {
    param(
        [AllowNull()]
        [string]$CurrentVersion,

        [AllowNull()]
        [string]$LatestVersion
    )

    if ([string]::IsNullOrWhiteSpace($LatestVersion)) {
        return 'unknown'
    }

    if ([string]::IsNullOrWhiteSpace($CurrentVersion)) {
        return 'not-installed'
    }

    try {
        $current = Get-ParsedVersion -Value $CurrentVersion -Name 'current'
        $latest = Get-ParsedVersion -Value $LatestVersion -Name 'latest'
        if ($current -lt $latest) {
            return 'update-available'
        }

        if ($current -gt $latest) {
            return 'ahead-of-known'
        }

        return 'current'
    }
    catch {
        return 'unknown'
    }
}

function Get-TemplateRefreshMappings {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    return @(
        [pscustomobject]@{
            SourceRoot         = Join-Path -Path $RootPath -ChildPath '.specify\templates'
            TargetRelativeRoot = '.specify\templates'
            SourceLabelRoot    = '.specify/templates'
        }
        [pscustomobject]@{
            SourceRoot         = Join-Path -Path $RootPath -ChildPath '.squad\templates'
            TargetRelativeRoot = '.squad'
            SourceLabelRoot    = '.squad/templates'
        }
        [pscustomobject]@{
            SourceRoot         = Join-Path -Path $RootPath -ChildPath '.github\workflows'
            TargetRelativeRoot = '.github\workflows'
            SourceLabelRoot    = '.github/workflows'
        }
    )
}

function Get-TemplateInventory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $inventory = @{}
    foreach ($mapping in @(Get-TemplateRefreshMappings -RootPath $RootPath)) {
        if (-not (Test-Path -LiteralPath $mapping.SourceRoot -PathType Container)) {
            continue
        }

        $files = @(Get-ChildItem -LiteralPath $mapping.SourceRoot -File -Recurse | Sort-Object FullName)
        foreach ($file in $files) {
            $relativeSourcePath = [System.IO.Path]::GetRelativePath($mapping.SourceRoot, $file.FullName)
            $projectRelativePath = Join-Path -Path $mapping.TargetRelativeRoot -ChildPath $relativeSourcePath
            $normalizedKey = $projectRelativePath.Replace('/', '\')
            $inventory[$normalizedKey] = [pscustomobject]@{
                SourcePath          = $file.FullName
                RelativeSourcePath  = $relativeSourcePath.Replace('\', '/')
                ProjectRelativePath = $normalizedKey
                TargetPath          = Join-Path -Path $ProjectPath -ChildPath $projectRelativePath
                SourceTemplatePath  = '{0}/{1}' -f $mapping.SourceLabelRoot.TrimEnd('/'), $relativeSourcePath.Replace('\', '/')
            }
        }
    }

    return $inventory
}

function Get-NullableFileContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

function Get-ContentHash {
    param(
        [AllowNull()]
        [string]$Content
    )

    if ($null -eq $Content) {
        return $null
    }

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Content)
        return ([System.BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
}

function Resolve-PreviousSpecrewRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentRoot,

        [AllowNull()]
        [string]$CurrentVersion,

        [AllowNull()]
        [string]$ProjectVersion
    )

    if ([string]::IsNullOrWhiteSpace($ProjectVersion)) {
        return $null
    }

    if ($ProjectVersion -eq $CurrentVersion) {
        return $CurrentRoot
    }

    $parentRoot = Split-Path -Parent $CurrentRoot
    if ([string]::IsNullOrWhiteSpace($parentRoot)) {
        return $null
    }

    $candidateRoot = Join-Path -Path $parentRoot -ChildPath $ProjectVersion
    $candidateUpdateScript = Join-Path -Path $candidateRoot -ChildPath 'scripts\specrew-update.ps1'
    if ((Test-Path -LiteralPath $candidateRoot -PathType Container) -and (Test-Path -LiteralPath $candidateUpdateScript -PathType Leaf)) {
        return $candidateRoot
    }

    return $null
}

function Get-TemplateArtifactBaseName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRelativePath
    )

    $trimmed = $ProjectRelativePath.TrimStart('.', '\', '/')
    $safeName = $trimmed -replace '[\\/:*?"<>|]+', '__'
    $safeName = $safeName.Trim('_')
    if ([string]::IsNullOrWhiteSpace($safeName)) {
        return 'template-refresh'
    }

    return $safeName
}

function Ensure-ParentDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }
}

function Format-ConflictArtifactContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserContent,

        [Parameter(Mandatory = $true)]
        [string]$ModuleContent,

        [Parameter(Mandatory = $true)]
        [string]$PreservedAt,

        [Parameter(Mandatory = $true)]
        [string]$ModuleVersion,

        [Parameter(Mandatory = $true)]
        [string]$SourceTemplatePath
    )

    $builder = [System.Text.StringBuilder]::new()
    $null = $builder.Append('<<<<<<< user-version (preserved at: ').Append($PreservedAt).Append(')').Append([Environment]::NewLine)
    $null = $builder.Append($UserContent)
    if (-not $UserContent.EndsWith("`n")) {
        $null = $builder.Append([Environment]::NewLine)
    }

    $null = $builder.Append('=======').Append([Environment]::NewLine)
    $null = $builder.Append($ModuleContent)
    if (-not $ModuleContent.EndsWith("`n")) {
        $null = $builder.Append([Environment]::NewLine)
    }

    $null = $builder.Append('>>>>>>> module-version (specrew_version: ').Append($ModuleVersion).Append(', source: ').Append($SourceTemplatePath).Append(')').Append([Environment]::NewLine)
    return $builder.ToString()
}

function Format-DeletionArtifactContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRelativePath,

        [Parameter(Mandatory = $true)]
        [string]$PreservedAt,

        [Parameter(Mandatory = $true)]
        [string]$PreviousVersion,

        [Parameter(Mandatory = $true)]
        [string]$CurrentVersion,

        [Parameter(Mandatory = $true)]
        [string]$SourceTemplatePath
    )

    return @(
        '# Specrew template deletion review'
        ''
        ('preserved_at_utc: {0}' -f $PreservedAt)
        ('template_path: {0}' -f $ProjectRelativePath)
        ('previous_specrew_version: {0}' -f $PreviousVersion)
        ('current_specrew_version: {0}' -f $CurrentVersion)
        ('previous_source: {0}' -f $SourceTemplatePath)
        'resolution: pending-manual-review'
        ''
        'The current Specrew module no longer ships this template.'
        'Review the preserved project file and decide whether to keep it, archive it, or remove it manually.'
    ) -join [Environment]::NewLine
}

function Get-TemplateChangeClassification {
    param(
        [AllowNull()]
        [string]$BaselineContent,

        [AllowNull()]
        [string]$ProjectContent,

        [AllowNull()]
        [string]$CurrentContent,

        [Parameter(Mandatory = $true)]
        [string]$CurrentVersion,

        [AllowNull()]
        [string]$ProjectVersion
    )

    if ($null -eq $CurrentContent) {
        return 'absent'
    }

    if ($null -eq $ProjectContent) {
        if ($null -eq $BaselineContent) {
            return 'new-template'
        }

        return 'module-only'
    }

    if ($null -eq $BaselineContent) {
        if ($ProjectContent -eq $CurrentContent) {
            return 'no-change'
        }

        if ($CurrentVersion -eq $ProjectVersion) {
            return 'user-only'
        }

        return 'both-modified'
    }

    $userChanged = ($ProjectContent -ne $BaselineContent)
    $moduleChanged = ($CurrentContent -ne $BaselineContent)

    if (-not $userChanged -and -not $moduleChanged) {
        return 'no-change'
    }
    if ($userChanged -and -not $moduleChanged) {
        return 'user-only'
    }
    if (-not $userChanged -and $moduleChanged) {
        return 'module-only'
    }

    return 'both-modified'
}

function Invoke-TemplateRefresh {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$CurrentRoot,

        [AllowNull()]
        [string]$PreviousRoot,

        [Parameter(Mandatory = $true)]
        [string]$CurrentVersion,

        [AllowNull()]
        [string]$ProjectVersion
    )

    $actions = [System.Collections.ArrayList]::new()
    $artifactRoot = Join-Path -Path $ProjectPath -ChildPath '.specrew\template-conflicts'
    $currentInventory = Get-TemplateInventory -RootPath $CurrentRoot -ProjectPath $ProjectPath
    $previousInventory = if ($PreviousRoot) {
        Get-TemplateInventory -RootPath $PreviousRoot -ProjectPath $ProjectPath
    }
    else {
        @{}
    }

    if ($PreviousRoot -or $currentVersion -eq $ProjectVersion) {
        foreach ($projectRelativePath in @($currentInventory.Keys | Sort-Object)) {
            $currentTemplate = $currentInventory[$projectRelativePath]
            $previousTemplate = if ($previousInventory.ContainsKey($projectRelativePath)) { $previousInventory[$projectRelativePath] } else { $null }
            $baselineContent = if ($null -ne $previousTemplate) { Get-NullableFileContent -Path $previousTemplate.SourcePath } else { $null }
            $projectContent = Get-NullableFileContent -Path $currentTemplate.TargetPath
            $currentContent = Get-NullableFileContent -Path $currentTemplate.SourcePath
            $classification = Get-TemplateChangeClassification `
                -BaselineContent $baselineContent `
                -ProjectContent $projectContent `
                -CurrentContent $currentContent `
                -CurrentVersion $CurrentVersion `
                -ProjectVersion $ProjectVersion

            switch ($classification) {
                'module-only' {
                    Ensure-ParentDirectory -Path $currentTemplate.TargetPath
                    Write-Utf8FileAtomic -Path $currentTemplate.TargetPath -Content $currentContent
                    $null = $actions.Add([pscustomobject]@{
                            Action   = 'template-updated'
                            Detail   = $currentTemplate.ProjectRelativePath
                            Template = $currentTemplate.ProjectRelativePath
                        })
                }
                'new-template' {
                    Ensure-ParentDirectory -Path $currentTemplate.TargetPath
                    Write-Utf8FileAtomic -Path $currentTemplate.TargetPath -Content $currentContent
                    $null = $actions.Add([pscustomobject]@{
                            Action   = 'template-added'
                            Detail   = $currentTemplate.ProjectRelativePath
                            Template = $currentTemplate.ProjectRelativePath
                        })
                }
                'both-modified' {
                    $preservedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
                    $artifactBaseName = Get-TemplateArtifactBaseName -ProjectRelativePath $currentTemplate.ProjectRelativePath
                    $artifactPath = Join-Path -Path $artifactRoot -ChildPath ('{0}.conflict' -f $artifactBaseName)
                    $conflictContent = Format-ConflictArtifactContent `
                        -UserContent $projectContent `
                        -ModuleContent $currentContent `
                        -PreservedAt $preservedAt `
                        -ModuleVersion $CurrentVersion `
                        -SourceTemplatePath $currentTemplate.SourceTemplatePath

                    Write-Utf8FileAtomic -Path $artifactPath -Content $conflictContent
                    Write-Utf8FileAtomic -Path $currentTemplate.TargetPath -Content $conflictContent
                    $null = $actions.Add([pscustomobject]@{
                            Action   = 'template-conflict'
                            Detail   = ('{0} -> {1}' -f $currentTemplate.ProjectRelativePath, $artifactPath)
                            Template = $currentTemplate.ProjectRelativePath
                        })
                }
            }
        }

        foreach ($projectRelativePath in @($previousInventory.Keys | Sort-Object)) {
            if ($currentInventory.ContainsKey($projectRelativePath)) {
                continue
            }

            $previousTemplate = $previousInventory[$projectRelativePath]
            if (-not (Test-Path -LiteralPath $previousTemplate.TargetPath -PathType Leaf)) {
                continue
            }

            $preservedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
            $artifactBaseName = Get-TemplateArtifactBaseName -ProjectRelativePath $projectRelativePath
            $artifactPath = Join-Path -Path $artifactRoot -ChildPath ('{0}.deletion' -f $artifactBaseName)
            $artifactContent = Format-DeletionArtifactContent `
                -ProjectRelativePath $projectRelativePath `
                -PreservedAt $preservedAt `
                -PreviousVersion $(if ($ProjectVersion) { $ProjectVersion } else { 'unknown' }) `
                -CurrentVersion $CurrentVersion `
                -SourceTemplatePath $previousTemplate.SourceTemplatePath

            Write-Utf8FileAtomic -Path $artifactPath -Content $artifactContent
            $null = $actions.Add([pscustomobject]@{
                    Action   = 'template-deleted'
                    Detail   = ('{0} -> {1}' -f $projectRelativePath, $artifactPath)
                    Template = $projectRelativePath
                })
        }
    }
    else {
        $null = $actions.Add([pscustomobject]@{
                Action   = 'template-baseline-unavailable'
                Detail   = ('Could not locate module version {0}; template refresh fell back to managed asset updates only.' -f $ProjectVersion)
                Template = $null
            })
    }

    return $actions
}

$parsedArgs = Convert-UnixStyleArguments `
    -ProjectPath $ProjectPath `
    -InfoMode $InfoMode.IsPresent `
    -All $All.IsPresent `
    -Specrew $Specrew.IsPresent `
    -Squad $Squad.IsPresent `
    -SpecKit $SpecKit.IsPresent `
    -SkipUpdateCheck $SkipUpdateCheck.IsPresent `
    -UpstreamLatest $UpstreamLatest.IsPresent `
    -Help $Help.IsPresent `
    -CliArgs $CliArgs

$ProjectPath = $parsedArgs.ProjectPath
$InfoMode = [bool]$parsedArgs.InfoMode
$All = [bool]$parsedArgs.All
$Specrew = [bool]$parsedArgs.Specrew
$Squad = [bool]$parsedArgs.Squad
$SpecKit = [bool]$parsedArgs.SpecKit
$SkipUpdateCheck = [bool]$parsedArgs.SkipUpdateCheck
$UpstreamLatest = [bool]$parsedArgs.UpstreamLatest
$Help = [bool]$parsedArgs.Help

if ($Help) {
    Show-Usage
    exit 0
}

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
$repoRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $resolvedProjectPath '.specrew\config.yml'
$specrewManifestPath = Join-Path $repoRoot 'extensions\specrew-speckit\extension.yml'
$validateVersionsScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-versions.ps1'
$deploySpeckitExtensionScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-speckit-extension.ps1'
$deploySquadRuntimeScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'

# Load module-side supported-versions declaration (Proposal 079). Maintainer-managed
# data shipped with the module. Falls back to historical hardcoded mins if the file
# is missing or malformed (graceful degradation; warns the user).
$supportedVersions = Get-SpecrewSupportedVersions
if ($null -ne $supportedVersions) {
    $minimumSpecKitVersion = $supportedVersions.Speckit.Min
    $minimumSquadVersion = $supportedVersions.Squad.Min
}
else {
    Write-Warning "Could not load module-side scripts/internal/supported-versions.yml. Falling back to historical minimums (Spec Kit 0.8.4 / Squad 0.9.1); --info status will use two-state model."
    $minimumSpecKitVersion = '0.8.4'
    $minimumSquadVersion = '0.9.1'
}

foreach ($requiredPath in @($specrewManifestPath, $validateVersionsScript, $deploySpeckitExtensionScript, $deploySquadRuntimeScript)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        Write-Error ("Required helper is missing: {0}" -f $requiredPath)
        exit 1
    }
}

if (-not (Test-Path -LiteralPath $resolvedProjectPath -PathType Container)) {
    Write-Error ("Project path does not exist: {0}" -f $resolvedProjectPath)
    exit 1
}

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    Write-Error ("Project is not Specrew-managed. Missing '{0}'." -f $configPath)
    exit 1
}

$scopes = @()
try {
    $scopes = @(Get-RequestedScopes -All $All -Specrew $Specrew -Squad $Squad -SpecKit $SpecKit)
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}

$projectConfig = Get-ConfigMap -ConfigPath $configPath
$sourceSpecrewVersion = Get-ExtensionVersion -ManifestPath $specrewManifestPath
$projectSpecrewBaselineVersion = if ($projectConfig.ContainsKey('specrew_version')) {
    [string]$projectConfig['specrew_version']
}
else {
    $null
}
$deployedSpecrewManifestPath = Join-Path $resolvedProjectPath '.specify\extensions\specrew-speckit\extension.yml'
$currentSpecrewVersion = if (Test-Path -LiteralPath $deployedSpecrewManifestPath -PathType Leaf) {
    Get-ExtensionVersion -ManifestPath $deployedSpecrewManifestPath
}
elseif ($projectSpecrewBaselineVersion) {
    $projectSpecrewBaselineVersion
}
else {
    $null
}

if (-not $InfoMode) {
    $downgradeGuard = Get-SpecrewUpdateDowngradeGuardResult `
        -RunningVersion $sourceSpecrewVersion `
        -ProjectBaselineVersion $projectSpecrewBaselineVersion

    if ($downgradeGuard.ShouldRefuse) {
        Write-SpecrewUpdateDowngradeRefusal `
            -GuardResult $downgradeGuard `
            -RunningVersion $sourceSpecrewVersion `
            -ProjectBaselineVersion $projectSpecrewBaselineVersion
        exit 1
    }
}

$validationResults = @()
try {
    $validationResults = @(Get-VersionValidationResults -ValidateScriptPath $validateVersionsScript -MinimumSpecKitVersion $minimumSpecKitVersion -MinimumSquadVersion $minimumSquadVersion)
}
catch {
    Write-Error ("Failed to probe installed Spec Kit / Squad versions. {0}" -f $_.Exception.Message)
    exit 1
}

$validationByPlatform = @{}
foreach ($result in $validationResults) {
    $validationByPlatform[$result.Platform] = $result
}

$latestByPlatform = @{
    'Specrew'  = Get-LatestVersionInfo -Platform 'Specrew' -RepoRoot $repoRoot -SpecrewVersion $sourceSpecrewVersion
    'Spec Kit' = Get-LatestVersionInfo -Platform 'Spec Kit' -RepoRoot $repoRoot -SpecrewVersion $sourceSpecrewVersion
    'Squad'    = Get-LatestVersionInfo -Platform 'Squad' -RepoRoot $repoRoot -SpecrewVersion $sourceSpecrewVersion
}

$specKitCurrent = if ($validationByPlatform.ContainsKey('Spec Kit') -and $validationByPlatform['Spec Kit'].Version) {
    [string]$validationByPlatform['Spec Kit'].Version
} elseif ($projectConfig.ContainsKey('speckit_version')) {
    [string]$projectConfig['speckit_version']
} else {
    $null
}

$squadCurrent = if ($validationByPlatform.ContainsKey('Squad') -and $validationByPlatform['Squad'].Version) {
    [string]$validationByPlatform['Squad'].Version
} elseif ($projectConfig.ContainsKey('squad_version')) {
    [string]$projectConfig['squad_version']
} else {
    $null
}

$specKitUpstream = if ($latestByPlatform['Spec Kit'].Known) { [string]$latestByPlatform['Spec Kit'].Version } else { $null }
$squadUpstream = if ($latestByPlatform['Squad'].Known) { [string]$latestByPlatform['Squad'].Version } else { $null }

# Proposal 079: LatestSupported = max_tested from supported-versions.yml; UpstreamLatest = upstream-latest (advisory).
# For Specrew itself, the supported-versions matrix does not apply (Specrew defines itself); LatestSupported mirrors UpstreamLatest.
$specKitMaxTested = if ($null -ne $supportedVersions) { [string]$supportedVersions.Speckit.MaxTested } else { $null }
$squadMaxTested = if ($null -ne $supportedVersions) { [string]$supportedVersions.Squad.MaxTested } else { $null }

# Proposal 079 AC5: --upstream-latest opts into the historical two-state model.
# Status reflects current-vs-upstream comparison (not current-vs-max_tested).
$specKitStatus = if ($null -ne $supportedVersions -and -not $UpstreamLatest) {
    Get-SpecrewVersionStatus -Current $specKitCurrent -Min $supportedVersions.Speckit.Min -MaxTested $specKitMaxTested
} else {
    Compare-VersionState -CurrentVersion $specKitCurrent -LatestVersion $specKitUpstream
}

$squadStatus = if ($null -ne $supportedVersions -and -not $UpstreamLatest) {
    Get-SpecrewVersionStatus -Current $squadCurrent -Min $supportedVersions.Squad.Min -MaxTested $squadMaxTested
} else {
    Compare-VersionState -CurrentVersion $squadCurrent -LatestVersion $squadUpstream
}

$infoRows = @(
    [pscustomobject]@{
        Platform        = 'Specrew'
        Current         = if ($currentSpecrewVersion) { $currentSpecrewVersion } else { 'not-recorded' }
        LatestSupported = if ($latestByPlatform['Specrew'].Known) { $latestByPlatform['Specrew'].Version } else { 'unavailable' }
        UpstreamLatest  = if ($latestByPlatform['Specrew'].Known) { $latestByPlatform['Specrew'].Version } else { 'unavailable' }
        Status          = Compare-VersionState -CurrentVersion $currentSpecrewVersion -LatestVersion $latestByPlatform['Specrew'].Version
        Source          = $latestByPlatform['Specrew'].Source
    }
    [pscustomobject]@{
        Platform        = 'Spec Kit'
        Current         = if ($specKitCurrent) { $specKitCurrent } else { 'not-installed' }
        LatestSupported = if ($specKitMaxTested) { $specKitMaxTested } else { 'unavailable' }
        UpstreamLatest  = if ($specKitUpstream) { $specKitUpstream } else { 'unavailable' }
        Status          = $specKitStatus
        Source          = $latestByPlatform['Spec Kit'].Source
    }
    [pscustomobject]@{
        Platform        = 'Squad'
        Current         = if ($squadCurrent) { $squadCurrent } else { 'not-installed' }
        LatestSupported = if ($squadMaxTested) { $squadMaxTested } else { 'unavailable' }
        UpstreamLatest  = if ($squadUpstream) { $squadUpstream } else { 'unavailable' }
        Status          = $squadStatus
        Source          = $latestByPlatform['Squad'].Source
    }
)

if ($InfoMode) {
    Write-Host ("Version info for {0}" -f $resolvedProjectPath) -ForegroundColor Green
    $infoRows | Format-Table -AutoSize

    # Proposal 079 AC5: when --upstream-latest is set, the user has opted into upstream-prominent display.
    # Suppress the advisory text (no need to warn about something the user explicitly chose to see).
    # Proposal 079: Advisory line when upstream beyond max_tested OR notes set on the supported declaration.
    if ($null -ne $supportedVersions -and -not $UpstreamLatest) {
        $advisoryLines = @()
        foreach ($advisoryRow in @(
            [pscustomobject]@{ Platform = 'Spec Kit'; Current = $specKitCurrent; MaxTested = $specKitMaxTested; Upstream = $specKitUpstream; Notes = $supportedVersions.Speckit.Notes; Status = $specKitStatus }
            [pscustomobject]@{ Platform = 'Squad';    Current = $squadCurrent;   MaxTested = $squadMaxTested;   Upstream = $squadUpstream;   Notes = $supportedVersions.Squad.Notes;   Status = $squadStatus }
        )) {
            $upstreamBeyond = $false
            if ($advisoryRow.MaxTested -and $advisoryRow.Upstream) {
                $maxParsed = ConvertTo-SpecrewSemanticVersion -Value $advisoryRow.MaxTested
                $upstreamParsed = ConvertTo-SpecrewSemanticVersion -Value $advisoryRow.Upstream
                if ($maxParsed -and $upstreamParsed -and ($upstreamParsed -gt $maxParsed)) {
                    $upstreamBeyond = $true
                }
            }

            if ($upstreamBeyond) {
                $advisoryLines += ("Note: {0} {1} is available upstream but Specrew has validated only through {2}. Status '{3}' reflects this. Upgrading beyond {2} is at your own risk; consider waiting for a Specrew release that validates against {1}." -f $advisoryRow.Platform, $advisoryRow.Upstream, $advisoryRow.MaxTested, $advisoryRow.Status)
            }

            if (-not [string]::IsNullOrWhiteSpace($advisoryRow.Notes)) {
                $advisoryLines += ("Note ({0}): {1}" -f $advisoryRow.Platform, $advisoryRow.Notes)
            }
        }

        foreach ($advisoryLine in $advisoryLines) {
            Write-Host $advisoryLine -ForegroundColor Yellow
        }
    }

    exit 0
}

$summary = [System.Collections.ArrayList]::new()
$installFailureMessage = $null
$previousSpecrewRoot = Resolve-PreviousSpecrewRoot `
    -CurrentRoot $repoRoot `
    -CurrentVersion $sourceSpecrewVersion `
    -ProjectVersion $currentSpecrewVersion

if ($scopes -contains 'Specrew') {
    $versionTransition = if ([string]::IsNullOrWhiteSpace($currentSpecrewVersion)) {
        'not-recorded -> {0}' -f $sourceSpecrewVersion
    }
    else {
        '{0} -> {1}' -f $currentSpecrewVersion, $sourceSpecrewVersion
    }

    $null = $summary.Add([pscustomobject]@{
            Platform = 'Specrew'
            Action   = 'module-version-detected'
            Detail   = $versionTransition
        })
}

if ($scopes -contains 'Specrew') {
    if (Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.specify') -PathType Container) {
        # Feature 171 (T017): capture refocus-catalog user keys BEFORE the wholesale
        # mirror so per-trigger disables + user provider rows survive the update
        # (managed-with-overlay; update never silently flips a disable decision).
        . (Join-Path $repoRoot 'scripts\internal\refocus-deploy-integration.ps1')
        $refocusOverlay = Get-RefocusCatalogOverlay -ProjectPath $resolvedProjectPath

        $specKitDeploymentActions = @(
            & $deploySpeckitExtensionScript `
                -ProjectPath $resolvedProjectPath `
                -RefreshExisting `
                -PassThru
        )

        if (Set-RefocusCatalogOverlay -ProjectPath $resolvedProjectPath -Overlay $refocusOverlay) {
            $null = $summary.Add([pscustomobject]@{ Platform = 'Specrew'; Action = 'refocus-catalog-overlay'; Detail = 'user trigger flags/provider rows re-applied after canonical refresh' })
        }

        foreach ($action in $specKitDeploymentActions) {
            $null = $summary.Add([pscustomobject]@{
                    Platform = 'Specrew'
                    Action   = [string]$action.Action
                    Detail   = [string]$action.Path
                })
        }
    }
    else {
        $null = $summary.Add([pscustomobject]@{
                Platform = 'Specrew'
                Action   = 'skipped'
                Detail   = '.specify is absent in this project'
            })
    }

    if (Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.squad') -PathType Container) {
        $squadDeploymentActions = @(
            & $deploySquadRuntimeScript `
                -ProjectPath $resolvedProjectPath `
                -PassThru
        )

        foreach ($action in $squadDeploymentActions) {
            $null = $summary.Add([pscustomobject]@{
                    Platform = 'Specrew'
                    Action   = [string]$action.Action
                    Detail   = [string]$action.Path
                })
        }

        $null = $summary.Add([pscustomobject]@{
                Platform = 'Specrew'
                Action   = 'slash-surface-refreshed'
                Detail   = '/specrew-where, /specrew-status, /specrew-update, /specrew-team, /specrew-review, /specrew-help, /specrew-version across .claude/skills, .github/skills, and .agents/skills'
            })
    }
    else {
        $null = $summary.Add([pscustomobject]@{
                Platform = 'Specrew'
                Action   = 'skipped'
                Detail   = '.squad is absent in this project'
            })
    }

    # Feature 171 (T017): deploy refocus hooks AFTER the Squad-runtime refresh that
    # provisions .claude/skills (and therefore .claude). claude detection is
    # directory-based, so deploying earlier would skip Claude on a workspace that only
    # gains .claude during THIS update (PR #2152 codex review — same ordering the init
    # path already uses). Fail-open; respects recorded opt-outs.
    if (Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.specify') -PathType Container) {
        . (Join-Path $repoRoot 'scripts\internal\refocus-deploy-integration.ps1')
        foreach ($hookAction in @(Invoke-RefocusHookDeployment -ProjectPath $resolvedProjectPath -DeployScriptPath (Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1'))) {
            $null = $summary.Add([pscustomobject]@{ Platform = 'Specrew'; Action = [string]$hookAction.Action; Detail = ('{0}: {1}' -f $hookAction.HostKind, $hookAction.Detail) })
        }
    }

    $templateRefreshActions = @(
        Invoke-TemplateRefresh `
            -ProjectPath $resolvedProjectPath `
            -CurrentRoot $repoRoot `
            -PreviousRoot $previousSpecrewRoot `
            -CurrentVersion $sourceSpecrewVersion `
            -ProjectVersion $currentSpecrewVersion
    )

    foreach ($action in $templateRefreshActions) {
        $null = $summary.Add([pscustomobject]@{
                Platform = 'Specrew'
                Action   = [string]$action.Action
                Detail   = [string]$action.Detail
            })
    }
}

foreach ($platform in @('Spec Kit', 'Squad')) {
    if ($scopes -notcontains $platform) {
        continue
    }

    $latestInfo = $latestByPlatform[$platform]
    $platformMaxTested = if ($platform -eq 'Spec Kit') { $specKitMaxTested } else { $squadMaxTested }

    # Proposal 079: default upgrade target is LatestSupported (max_tested).
    # --upstream-latest opts into the historical behavior (upstream-latest).
    # Fall back to upstream-latest if max_tested is unavailable (supported-versions.yml missing).
    $upgradeTarget = if ($UpstreamLatest -and $latestInfo.Known) {
        [string]$latestInfo.Version
    }
    elseif ($platformMaxTested) {
        $platformMaxTested
    }
    elseif ($latestInfo.Known) {
        [string]$latestInfo.Version
    }
    else {
        $null
    }

    if (-not $upgradeTarget) {
        Write-Error ("Cannot update {0} because no upgrade target could be determined (supported-versions.yml missing and upstream-latest unavailable)." -f $platform)
        exit 1
    }

    $currentVersion = if ($validationByPlatform.ContainsKey($platform)) {
        [string]$validationByPlatform[$platform].Version
    }
    else {
        $null
    }

    $platformStatus = if ($platform -eq 'Spec Kit') { $specKitStatus } else { $squadStatus }

    # Skip upgrade when already current OR ahead of supported (user intentionally beyond max_tested).
    # ahead-of-supported requires --upstream-latest to actually do anything (and even then, upstream might equal current).
    if ($platformStatus -eq 'current') {
        $null = $summary.Add([pscustomobject]@{
                Platform = $platform
                Action   = 'already-current'
                Detail   = $upgradeTarget
            })
        continue
    }

    if ($platformStatus -eq 'ahead-of-supported' -and -not $UpstreamLatest) {
        $null = $summary.Add([pscustomobject]@{
                Platform = $platform
                Action   = 'ahead-of-supported'
                Detail   = ("Current {0} is beyond Specrew-validated max_tested {1}. Use --upstream-latest to target upstream. No action taken." -f $currentVersion, $platformMaxTested)
            })
        continue
    }

    try {
        Install-PlatformVersion -Platform $platform -Version $upgradeTarget
        $null = $summary.Add([pscustomobject]@{
                Platform = $platform
                Action   = 'upgraded'
                Detail   = $upgradeTarget
            })
    }
    catch {
        $installFailureMessage = $_.Exception.Message
        $null = $summary.Add([pscustomobject]@{
                Platform = $platform
                Action   = 'failed'
                Detail   = $installFailureMessage
            })
        break
    }
}

$postValidationResults = @()
try {
    $postValidationResults = @(Get-VersionValidationResults -ValidateScriptPath $validateVersionsScript -MinimumSpecKitVersion $minimumSpecKitVersion -MinimumSquadVersion $minimumSquadVersion)
}
catch {
    Write-Error ("Failed to refresh recorded versions after update. {0}" -f $_.Exception.Message)
    exit 1
}

$postValidationByPlatform = @{}
foreach ($result in $postValidationResults) {
    $postValidationByPlatform[$result.Platform] = $result
}

$configAction = Update-SpecrewConfig `
    -ConfigPath $configPath `
    -SpecrewVersion $(if ($scopes -contains 'Specrew') { $sourceSpecrewVersion } else { $null }) `
    -SpecKitVersion $(if ($postValidationByPlatform.ContainsKey('Spec Kit')) { [string]$postValidationByPlatform['Spec Kit'].Version } elseif ($projectConfig.ContainsKey('speckit_version')) { [string]$projectConfig['speckit_version'] } else { $null }) `
    -SquadVersion $(if ($postValidationByPlatform.ContainsKey('Squad')) { [string]$postValidationByPlatform['Squad'].Version } elseif ($projectConfig.ContainsKey('squad_version')) { [string]$projectConfig['squad_version'] } else { $null })

$null = $summary.Add([pscustomobject]@{
        Platform = 'Specrew'
        Action   = $configAction
        Detail   = $configPath
    })

Write-Host ("Update summary for {0}" -f $resolvedProjectPath) -ForegroundColor Green
$summary | Format-Table -AutoSize

$otherUpdates = @($infoRows | Where-Object { $scopes -notcontains $_.Platform -and ($_.Status -eq 'update-available' -or $_.Status -eq 'update-available-supported') })
if ($otherUpdates.Count -gt 0) {
    Write-Host ''
    Write-Host 'Additional platform updates are available:' -ForegroundColor Yellow
    $otherUpdates | Select-Object Platform, Current, LatestSupported, UpstreamLatest | Format-Table -AutoSize
}

$psGalleryUpdateWarning = Get-PSGalleryUpdateWarning -ProjectRoot $resolvedProjectPath -SkipCheck:$SkipUpdateCheck
if (-not [string]::IsNullOrWhiteSpace($psGalleryUpdateWarning)) {
    Write-Output ("WARN: {0}" -f $psGalleryUpdateWarning)
}

if ($installFailureMessage) {
    Write-Error $installFailureMessage
    exit 1
}

exit 0
