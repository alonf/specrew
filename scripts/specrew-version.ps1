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
  - Remediation guidance when compatibility is not met

Compatibility baseline:
  Minimum version for the slash-command surface is the first published Specrew
  release that ships Feature 024. Projects on a pre-v0.24.0 baseline must upgrade.

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
$installedVersionText = Get-SpecrewInstalledVersion -ProjectRoot $resolvedProjectPath
$installedVersion = ConvertTo-SpecrewSemanticVersion -Value $installedVersionText

# --- Project baseline version ---
$projectBaselineVersion = Get-SpecrewVersionConfigValue -ProjectRoot $resolvedProjectPath -Key 'specrew_version'
if ([string]::IsNullOrWhiteSpace($projectBaselineVersion)) {
    $projectBaselineVersion = Get-SpecrewVersionConfigValue -ProjectRoot $resolvedProjectPath -Key 'version'
}

# --- Slash-command minimum version ---
# Feature 024 slash-command minimum version: 0.24.0
$slashCommandMinVersionText = Get-SpecrewSlashCommandMinVersion
$slashCommandMinVersion = ConvertTo-SpecrewSemanticVersion -Value $slashCommandMinVersionText

# --- Compatibility verdict ---
$compatibilityVerdict = 'unknown'
$compatibilityDetails = New-Object System.Collections.Generic.List[string]

if ($null -eq $slashCommandMinVersion) {
    $compatibilityDetails.Add('Slash-command minimum version could not be parsed.') | Out-Null
}
elseif ($null -ne $installedVersion) {
    if ($installedVersion -ge $slashCommandMinVersion) {
        $compatibilityDetails.Add(("Installed version {0} meets the slash-command minimum ({1})." -f $installedVersionText, $slashCommandMinVersionText)) | Out-Null
    }
    else {
        $compatibilityDetails.Add(("Installed version {0} is older than the slash-command minimum ({1})." -f $installedVersionText, $slashCommandMinVersionText)) | Out-Null
        $compatibilityVerdict = 'incompatible'
    }
}
else {
    $compatibilityDetails.Add('Installed version could not be determined. Verify your Specrew module installation.') | Out-Null
}

$projectBaselineSemanticVersion = ConvertTo-SpecrewSemanticVersion -Value $projectBaselineVersion
if ([string]::IsNullOrWhiteSpace($projectBaselineVersion)) {
    $compatibilityDetails.Add('Project baseline version was not found in .specrew\config.yml.') | Out-Null
}
elseif ($null -eq $projectBaselineSemanticVersion) {
    $compatibilityDetails.Add(("Project baseline '{0}' could not be parsed." -f $projectBaselineVersion)) | Out-Null
}
elseif ($projectBaselineSemanticVersion -lt $slashCommandMinVersion) {
    $compatibilityDetails.Add(("Project baseline {0} predates the slash-command minimum ({1})." -f $projectBaselineVersion, $slashCommandMinVersionText)) | Out-Null
    $compatibilityVerdict = 'incompatible'
}
else {
    $compatibilityDetails.Add(("Project baseline {0} meets the slash-command minimum ({1})." -f $projectBaselineVersion, $slashCommandMinVersionText)) | Out-Null
}

if ($compatibilityVerdict -ne 'incompatible') {
    if ($null -ne $installedVersion -and $installedVersion -ge $slashCommandMinVersion -and $null -ne $projectBaselineSemanticVersion -and $projectBaselineSemanticVersion -ge $slashCommandMinVersion) {
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

$installedDisplay = if ($null -ne $installedVersion) { $installedVersionText } else { '(unknown)' }
$baselineDisplay = if (-not [string]::IsNullOrWhiteSpace($projectBaselineVersion)) { $projectBaselineVersion } else { '(not found in .specrew/config.yml)' }

Write-Host "  Installed version  : $installedDisplay"
Write-Host "  Project baseline   : $baselineDisplay"
Write-Host "  Slash-cmd minimum  : $slashCommandMinVersionText"
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
        Write-Output "WARNING: Specrew multi-host slash-command surface requires version $slashCommandMinVersionText or later."
        Write-Host 'Remediation:' -ForegroundColor Yellow
        Write-Host "  To upgrade the installed module : Update-Module Specrew"
        Write-Host "  To refresh project assets       : specrew update"
    }
    'unknown' {
        Write-Host "  Compatibility      : UNKNOWN" -ForegroundColor Yellow
        foreach ($detail in $compatibilityDetails) {
            Write-Host "  $detail"
        }
        Write-Host ''
        Write-Output "WARNING: Specrew version could not be determined."
        Write-Host 'Remediation:' -ForegroundColor Yellow
        Write-Host "  Verify Specrew is installed : Get-Module -Name Specrew -ListAvailable"
        Write-Host "  To install                  : Install-Module Specrew"
    }
}

Write-Host ''
exit 0
