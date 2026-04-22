# validate-versions.ps1
# Validates Spec Kit and Squad versions meet Specrew minimum requirements

<#
.SYNOPSIS
    Validates platform version compatibility for Specrew.

.DESCRIPTION
    Checks that Spec Kit and Squad are installed at versions compatible with Specrew.
    Required versions default to Spec Kit >= 0.7.3 and Squad >= 0.9.1.

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
    [string]$MinimumSpecKitVersion = '0.7.3',
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

    $rawVersionOutput = @()
    $probeError = $null
    try {
        $rawVersionOutput = @(& $CommandName --version 2>&1)
    }
    catch {
        $probeError = $_.Exception.Message
        $rawVersionOutput = @([string]$probeError)
    }

    $directProbeExitCode = Get-NativeExitCode
    $rawVersion = Get-VersionOutputLine -OutputLines $rawVersionOutput -PreferredPattern ('^{0}\b' -f [regex]::Escape($CommandName))
    if ($rawVersion) {
        return [pscustomobject]@{
            RawVersion  = [string]$rawVersion
            ProbeError  = if ($directProbeExitCode -eq 0) { $null } else { $probeError }
            VersionFrom = 'command'
        }
    }

    if ($CommandName -eq 'specify') {
        $uvToolVersion = Get-UvToolVersion -ToolName 'specify' -PackageName 'specify-cli'
        if ($uvToolVersion) {
            if (-not $probeError) {
                $probeError = ($rawVersionOutput | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
            }

            return [pscustomobject]@{
                RawVersion  = [string]$uvToolVersion
                ProbeError  = if ($directProbeExitCode -eq 0) { $null } else { [string]$probeError }
                VersionFrom = 'uv-tool-list'
            }
        }
    }

    if (-not $probeError) {
        $probeError = ($rawVersionOutput | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
    }

    return [pscustomobject]@{
        RawVersion  = [string]($rawVersionOutput | Select-Object -First 1)
        ProbeError  = if ($directProbeExitCode -eq 0) { $null } else { [string]$probeError }
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
        'Spec Kit' { 'uv tool install --reinstall --upgrade "specify-cli>={0}"' -f $MinimumVersion }
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
        -InstallCommand ('uv tool install --upgrade "specify-cli>={0}"' -f $MinimumSpecKitVersion)
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
