# validate-versions.ps1
# Validates Spec Kit and Squad versions meet Specrew minimum requirements

<#
.SYNOPSIS
    Validates platform version compatibility for Specrew.

.DESCRIPTION
    Checks that Spec Kit and Squad are installed at versions compatible with Specrew.
    Required versions default to Spec Kit >= 0.8.4 and Squad >= 0.9.1.

.PARAMETER SpecKitVersion
    Installed Spec Kit version (optional, auto-detected if omitted).

.PARAMETER SquadVersion
    Installed Squad version (optional, auto-detected if omitted).

.PARAMETER MinimumSpecKitVersion
    Minimum required Spec Kit version.

.PARAMETER MinimumSquadVersion
    Minimum required Squad version.

.PARAMETER PassThru
    Return structured validation results instead of exiting directly.

.EXAMPLE
    .\validate-versions.ps1

.EXAMPLE
    .\validate-versions.ps1 -PassThru
#>

[CmdletBinding()]
param(
    [string]$SpecKitVersion,
    [string]$SquadVersion,
    [string]$MinimumSpecKitVersion = '0.8.4',
    [string]$MinimumSquadVersion = '0.9.1',
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-NativeExitCode {
    if (Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue) {
        return $global:LASTEXITCODE
    }

    return 0
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

function Get-VersionOutputLine {
    param(
        [AllowEmptyCollection()]
        [string[]]$OutputLines,

        [string]$PreferredPattern
    )

    foreach ($line in @($OutputLines)) {
        if (-not $line) {
            continue
        }

        if ($PreferredPattern -and $line -notmatch $PreferredPattern) {
            continue
        }

        if ([regex]::Match($line, '\d+\.\d+\.\d+(?:\.\d+)?').Success) {
            return [string]$line
        }
    }

    foreach ($line in @($OutputLines)) {
        if ($line -and [regex]::Match($line, '\d+\.\d+\.\d+(?:\.\d+)?').Success) {
            return [string]$line
        }
    }

    return $null
}

function Get-UvToolVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    if (-not (Get-Command -Name 'uv' -ErrorAction SilentlyContinue)) {
        return $null
    }

    $uvOutput = @(& uv tool list 2>&1)
    if ((Get-NativeExitCode) -ne 0) {
        return $null
    }

    $preferredPattern = '^(?:{0}|{1})\b' -f [regex]::Escape($PackageName), [regex]::Escape($ToolName)
    return Get-VersionOutputLine -OutputLines $uvOutput -PreferredPattern $preferredPattern
}

function Get-SpecKitGitReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $trimmedVersion = $Version.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmedVersion)) {
        throw 'Spec Kit version cannot be empty.'
    }

    if ($trimmedVersion.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $trimmedVersion
    }

    return ('v{0}' -f $trimmedVersion)
}

function Get-SpecKitInstallCommandText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [bool]$ForceInstall
    )

    $arguments = @('tool', 'install')
    if ($ForceInstall) {
        $arguments += '--force'
    }

    $arguments += @(
        'specify-cli',
        '--from',
        ('git+https://github.com/github/spec-kit.git@{0}' -f (Get-SpecKitGitReference -Version $Version))
    )

    return ('uv {0}' -f ($arguments -join ' '))
}

function Get-VersionProbePlan {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    switch ($CommandName) {
        'specify' {
            return @(
                [pscustomobject]@{
                    ArgumentList     = @('--version')
                    PreferredPattern = ('^{0}\b' -f [regex]::Escape($CommandName))
                    VersionFrom      = 'command'
                    Environment      = @{}
                },
                [pscustomobject]@{
                    ArgumentList     = @('version')
                    PreferredPattern = 'CLI Version'
                    VersionFrom      = 'command:version'
                    Environment      = @{
                        PYTHONIOENCODING = 'utf-8'
                    }
                }
            )
        }
        default {
            return @(
                [pscustomobject]@{
                    ArgumentList     = @('--version')
                    PreferredPattern = ('^{0}\b' -f [regex]::Escape($CommandName))
                    VersionFrom      = 'command'
                    Environment      = @{}
                }
            )
        }
    }
}

function Invoke-VersionProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [hashtable]$Environment = @{}
    )

    $rawOutput = @()
    $probeError = $null
    $originalEnvironment = @{}
    foreach ($entry in $Environment.GetEnumerator()) {
        $originalEnvironment[$entry.Key] = [Environment]::GetEnvironmentVariable($entry.Key, 'Process')
        [Environment]::SetEnvironmentVariable($entry.Key, [string]$entry.Value, 'Process')
    }

    try {
        try {
            $rawOutput = @(& $CommandName @ArgumentList 2>&1)
        }
        catch {
            $probeError = $_.Exception.Message
            $rawOutput = @([string]$probeError)
        }
    }
    finally {
        foreach ($entry in $Environment.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($entry.Key, $originalEnvironment[$entry.Key], 'Process')
        }
    }

    $exitCode = Get-NativeExitCode
    if (-not $probeError -and $exitCode -ne 0) {
        $probeError = ($rawOutput | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
    }

    return [pscustomobject]@{
        Output     = @($rawOutput | ForEach-Object { [string]$_ })
        ExitCode   = $exitCode
        ProbeError = if ($probeError) { [string]$probeError } else { $null }
    }
}

function Get-CommandVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    if (-not $command) {
        return [pscustomobject]@{
            RawVersion  = $null
            ProbeError  = $null
            VersionFrom = $null
        }
    }

    $probeError = $null
    $rawVersion = $null
    $lastProbeOutput = @()
    foreach ($probe in @(Get-VersionProbePlan -CommandName $CommandName)) {
        $probeResult = Invoke-VersionProbe -CommandName $CommandName -ArgumentList $probe.ArgumentList -Environment $probe.Environment
        $lastProbeOutput = @($probeResult.Output)
        $probeVersion = Get-VersionOutputLine -OutputLines $probeResult.Output -PreferredPattern $probe.PreferredPattern
        if ($probeVersion -and $probeResult.ExitCode -eq 0) {
            return [pscustomobject]@{
                RawVersion  = [string]$probeVersion
                ProbeError  = $null
                VersionFrom = [string]$probe.VersionFrom
            }
        }

        if (-not $rawVersion -and $probeVersion) {
            $rawVersion = [string]$probeVersion
        }

        if (-not $probeError -and $probeResult.ProbeError) {
            $probeError = [string]$probeResult.ProbeError
        }
    }

    if ($CommandName -eq 'specify') {
        $uvToolVersion = Get-UvToolVersion -ToolName 'specify' -PackageName 'specify-cli'
        if ($uvToolVersion) {
            return [pscustomobject]@{
                RawVersion  = [string]$uvToolVersion
                ProbeError  = if ($probeError) { [string]$probeError } else { 'specify did not return a parseable version from its command surfaces' }
                VersionFrom = 'uv-tool-list'
            }
        }
    }

    if (-not $probeError) {
        $probeError = ($lastProbeOutput | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
    }

    return [pscustomobject]@{
        RawVersion  = if ($rawVersion) { [string]$rawVersion } else { [string]($lastProbeOutput | Select-Object -First 1) }
        ProbeError  = if ($probeError) { [string]$probeError } else { $null }
        VersionFrom = 'command'
    }
}

function Get-ValidationResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [string]$MinimumVersion,

        [AllowNull()]
        [pscustomobject]$Detection,

        [Parameter(Mandatory = $true)]
        [string]$InstallCommand
    )

    $isInstalled = [bool](Get-Command -Name $CommandName -ErrorAction SilentlyContinue)
    $detectedVersion = if ($Detection) { $Detection.RawVersion } else { $null }
    $probeError = if ($Detection) { $Detection.ProbeError } else { $null }
    $versionSource = if ($Detection) { $Detection.VersionFrom } else { $null }
    $parsedDetectedVersion = $null
    $isCompatible = $false
    $versionParseError = $null

    if ($detectedVersion) {
        try {
            $parsedDetectedVersion = Get-ParsedVersion -Value $detectedVersion -Name $Platform
            $isCompatible = $parsedDetectedVersion -ge (Get-ParsedVersion -Value $MinimumVersion -Name "$Platform minimum")
        }
        catch {
            $versionParseError = $_.Exception.Message
        }
    }

    $isOperational = $isInstalled -and [string]::IsNullOrWhiteSpace($probeError) -and [string]::IsNullOrWhiteSpace($versionParseError)
    $repairCommand = switch ($Platform) {
        'Spec Kit' { Get-SpecKitInstallCommandText -Version $MinimumVersion -ForceInstall $true }
        'Squad' { 'npm install -g "@bradygaster/squad-cli@{0}"' -f $MinimumVersion }
        default { $InstallCommand }
    }

    [pscustomobject]@{
        Platform               = $Platform
        CommandName            = $CommandName
        IsInstalled            = $isInstalled
        IsOperational          = $isOperational
        RawVersion             = $detectedVersion
        Version                = if ($parsedDetectedVersion) { $parsedDetectedVersion.ToString() } else { $null }
        VersionSource          = $versionSource
        ProbeError             = $probeError
        ValidationError        = $versionParseError
        MinimumVersion         = $MinimumVersion
        IsCompatible           = $isCompatible
        SuggestedInstall       = $InstallCommand
        SuggestedUpgrade       = $InstallCommand
        SuggestedRepair        = $repairCommand
    }
}

$resolvedSpecKitVersion = if ($PSBoundParameters.ContainsKey('SpecKitVersion')) {
    [pscustomobject]@{
        RawVersion  = $SpecKitVersion
        ProbeError  = $null
        VersionFrom = 'parameter'
    }
}
else {
    Get-CommandVersion -CommandName 'specify'
}

$resolvedSquadVersion = if ($PSBoundParameters.ContainsKey('SquadVersion')) {
    [pscustomobject]@{
        RawVersion  = $SquadVersion
        ProbeError  = $null
        VersionFrom = 'parameter'
    }
}
else {
    Get-CommandVersion -CommandName 'squad'
}

$results = @(
    Get-ValidationResult -Platform 'Spec Kit' `
        -CommandName 'specify' `
        -MinimumVersion $MinimumSpecKitVersion `
        -Detection $resolvedSpecKitVersion `
        -InstallCommand (Get-SpecKitInstallCommandText -Version $MinimumSpecKitVersion -ForceInstall $false)
    Get-ValidationResult -Platform 'Squad' `
        -CommandName 'squad' `
        -MinimumVersion $MinimumSquadVersion `
        -Detection $resolvedSquadVersion `
        -InstallCommand ('npm install -g "@bradygaster/squad-cli@{0}"' -f $MinimumSquadVersion)
)

if ($PassThru) {
    $results
    return
}

$results |
    Select-Object Platform, IsInstalled, IsOperational, Version, MinimumVersion, IsCompatible |
    Format-Table -AutoSize

$failures = @($results | Where-Object { (-not $_.IsInstalled) -or (-not $_.IsOperational) -or (-not $_.IsCompatible) })
if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        if (-not $failure.IsInstalled) {
            Write-Error ("{0} is not installed. Run '{1}'." -f $failure.Platform, $failure.SuggestedInstall)
        }
        elseif (-not $failure.IsOperational) {
            $failureDetail = if ($failure.ProbeError) { $failure.ProbeError } elseif ($failure.ValidationError) { $failure.ValidationError } else { 'the command did not complete successfully' }
            Write-Error ("{0} is installed but the '{1}' command is not healthy ({2}). Run '{3}' to repair it." -f $failure.Platform, $failure.CommandName, $failureDetail, $failure.SuggestedRepair)
        }
        else {
            Write-Error ("Specrew requires {0} >= {1} but found {2}. Run '{3}' to upgrade." -f $failure.Platform, $failure.MinimumVersion, $failure.Version, $failure.SuggestedUpgrade)
        }
    }

    exit 1
}

Write-Host 'Platform versions are compatible with Specrew.' -ForegroundColor Green
exit 0
