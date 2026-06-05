param(
    [string]$ProjectPath = '.',
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

function Show-Usage {
    @'
specrew version - show the installed Specrew version and slash-command compatibility state

Usage:
  specrew version [--project-path <path>]

Options:
  --project-path <path>  Target Specrew project (default: current directory)
  --help                 Show this help message

Outputs:
  - Installed Specrew version
  - Project baseline version (from .specrew/config.yml)
  - Slash-command compatibility state (compatible / incompatible / unknown)
  - Remediation guidance when the installed module is older than the project baseline

Examples:
  specrew version
  specrew version --project-path /path/to/project
'@ | Write-Host
}

function Convert-UnixStyleVersionArguments {
    param(
        [string]$ProjectPath,
        [bool]$HelpMode,
        [string[]]$CliArgs
    )

    $result = [ordered]@{
        ProjectPath = $ProjectPath
        HelpMode    = $HelpMode
    }

    if (-not $CliArgs -or $CliArgs.Count -eq 0) {
        return [pscustomobject]$result
    }

    $knownArgs = @('--project-path', '--help', '-h')
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
            { $_ -match '^--project-path=(.+)$' } {
                $result.ProjectPath = $Matches[1]
            }
            '--help' { $result.HelpMode = $true }
            '-h'     { $result.HelpMode = $true }
            default {
                $isKnown = $false
                foreach ($known in $knownArgs) {
                    if ($arg -eq $known -or $arg.StartsWith(('{0}=' -f $known), [System.StringComparison]::OrdinalIgnoreCase)) {
                        $isKnown = $true
                        break
                    }
                }
                if (-not $isKnown) {
                    Write-Output "WARNING: Unsupported argument '$arg' for 'specrew version'. Run 'specrew version --help' for usage."
                    Write-Host "ERROR: Unsupported argument '$arg'." -ForegroundColor Red
                    Write-Host "Run 'specrew version --help' for usage or '/specrew-help' for the full Specrew catalog." -ForegroundColor Yellow
                    exit 1
                }
            }
        }
        $index++
    }

    return [pscustomobject]$result
}

$parsedArgs = Convert-UnixStyleVersionArguments -ProjectPath $ProjectPath -HelpMode $Help.IsPresent -CliArgs $CliArgs

if ($parsedArgs.HelpMode) {
    Show-Usage
    exit 0
}

$resolvedProjectPath = Resolve-ProjectPath -Path $parsedArgs.ProjectPath

# --- Installed version ---
# Get-SpecrewInstalledVersion returns the BASE version (feeds every semver comparison below).
# Get-SpecrewInstalledVersionInfo adds the prerelease label for the DISPLAY line only, so the
# report can show 0.31.0-beta3 instead of a bare 0.31.0 indistinguishable from a stable build.
$installedVersionText = Get-SpecrewInstalledVersion -ProjectRoot $resolvedProjectPath
$installedVersion = ConvertTo-SpecrewSemanticVersion -Value $installedVersionText
$installedVersionInfo = Get-SpecrewInstalledVersionInfo -ProjectRoot $resolvedProjectPath

# --- Project baseline version ---
$projectBaselineVersion = Get-SpecrewVersionConfigValue -ProjectRoot $resolvedProjectPath -Key 'specrew_version'
if ([string]::IsNullOrWhiteSpace($projectBaselineVersion)) {
    $projectBaselineVersion = Get-SpecrewVersionConfigValue -ProjectRoot $resolvedProjectPath -Key 'version'
}

# --- Compatibility verdict ---
$compatibilityVerdict = 'unknown'
$compatibilityDetails = New-Object System.Collections.Generic.List[string]

if ($null -eq $installedVersion) {
    $compatibilityDetails.Add('Installed version could not be determined. Verify your Specrew module installation.') | Out-Null
}
else {
    $compatibilityDetails.Add(("Installed version {0} is available for slash-command routing." -f $installedVersionText)) | Out-Null
}

$projectBaselineSemanticVersion = ConvertTo-SpecrewSemanticVersion -Value $projectBaselineVersion
if ([string]::IsNullOrWhiteSpace($projectBaselineVersion)) {
    $compatibilityDetails.Add('Project baseline version was not found in .specrew\config.yml.') | Out-Null
}
elseif ($null -eq $projectBaselineSemanticVersion) {
    $compatibilityDetails.Add(("Project baseline '{0}' could not be parsed." -f $projectBaselineVersion)) | Out-Null
}
elseif ($null -ne $installedVersion -and $installedVersion -lt $projectBaselineSemanticVersion) {
    $compatibilityDetails.Add(("Project baseline {0} is newer than installed Specrew {1}." -f $projectBaselineVersion, $installedVersionText)) | Out-Null
    $compatibilityVerdict = 'incompatible'
}
else {
    $compatibilityDetails.Add(("Project baseline {0} is serviceable by the installed Specrew version." -f $projectBaselineVersion)) | Out-Null
}

if ($compatibilityVerdict -ne 'incompatible') {
    if ($null -ne $installedVersion -and $null -ne $projectBaselineSemanticVersion -and $installedVersion -ge $projectBaselineSemanticVersion) {
        $compatibilityVerdict = 'compatible'
    }
    else {
        $compatibilityVerdict = 'unknown'
    }
}

# --- Output ---
Write-Host ''
Write-Host 'Specrew Version Report' -ForegroundColor Cyan
Write-Host '----------------------' -ForegroundColor Cyan

$installedDisplay = if ($null -ne $installedVersion) {
    if ($null -ne $installedVersionInfo -and -not [string]::IsNullOrWhiteSpace($installedVersionInfo.Display)) { $installedVersionInfo.Display } else { $installedVersionText }
}
else { '(unknown)' }
$baselineDisplay = if (-not [string]::IsNullOrWhiteSpace($projectBaselineVersion)) { $projectBaselineVersion } else { '(not found in .specrew/config.yml)' }

Write-Host "  Installed version  : $installedDisplay"
Write-Host "  Project baseline   : $baselineDisplay"
Write-Host '  Slash-command UX   : bundled with current Specrew runtime'
Write-Host ''

switch ($compatibilityVerdict) {
    'compatible' {
        Write-Host "  Compatibility      : COMPATIBLE" -ForegroundColor Green
        foreach ($detail in $compatibilityDetails) {
            Write-Host "  $detail"
        }
    }
    'incompatible' {
        Write-Host "  Compatibility      : INCOMPATIBLE" -ForegroundColor Red
        foreach ($detail in $compatibilityDetails) {
            Write-Host "  $detail"
        }
        Write-Host ''
        Write-Output 'WARNING: Installed Specrew is older than this project baseline.'
        Write-Host 'Remediation:' -ForegroundColor Yellow
        Write-Host '  To upgrade the installed module : Update-Module Specrew'
        Write-Host '  To use a matching development tree: set SPECREW_MODULE_PATH'
        Write-Host '  To refresh project assets after matching the module: specrew update'
    }
    'unknown' {
        Write-Host "  Compatibility      : UNKNOWN" -ForegroundColor Yellow
        foreach ($detail in $compatibilityDetails) {
            Write-Host "  $detail"
        }

        if ($null -eq $installedVersion) {
            Write-Host ''
            Write-Output "WARNING: Specrew version could not be determined."
            Write-Host 'Remediation:' -ForegroundColor Yellow
            Write-Host "  Verify Specrew is installed : Get-Module -Name Specrew -ListAvailable"
            Write-Host "  To install                  : Install-Module Specrew"
        }
    }
}

Write-Host ''
exit 0
