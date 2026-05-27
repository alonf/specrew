<#
.SYNOPSIS
Resolve auto-decision defaults based on detected stack.

.DESCRIPTION
Loads auto-decision defaults from stack-specific YAML file, falling back to generic.yml.
Returns hashtable of default decisions for low-expertise scenarios (dial 1-3, Mode C).

Implements FR-028, FR-031 for Feature 049 Iteration 003.

.PARAMETER IntakeDataRoot
Root path for intake data catalogs. Defaults to .specify/intake/

.PARAMETER Stack
Detected repository stack ('dotnet', 'python', 'nodejs', 'generic').

.EXAMPLE
$defaults = Resolve-AutoDecision -IntakeDataRoot ".specify/intake" -Stack "dotnet"

.NOTES
Mirror parity: This file must remain functionally identical to:
  .specify/extensions/specrew-speckit/scripts/intake/helpers/Resolve-AutoDecision.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-AutoDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$IntakeDataRoot,

        [Parameter(Mandatory = $false)]
        [string]$Stack = 'generic'
    )

    $parserPath = Join-Path $PSScriptRoot 'Read-IntakeYaml.ps1'
    if (-not (Get-Command Read-IntakeYamlDocument -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $parserPath -PathType Leaf)) {
        . $parserPath
    }

    if ([string]::IsNullOrEmpty($IntakeDataRoot)) {
        $IntakeDataRoot = Join-Path (Get-Location) '.specify\intake'
    }

    $autoDecisionDir = Join-Path $IntakeDataRoot 'auto-decision-defaults'
    $stackSpecificPath = Join-Path $autoDecisionDir "$Stack.yml"
    $genericPath = Join-Path $autoDecisionDir 'generic.yml'
    $decisionPath = $genericPath

    if (Test-Path $stackSpecificPath) {
        $decisionPath = $stackSpecificPath
        Write-Verbose "Using stack-specific auto-decisions: $Stack"
    } else {
        Write-Verbose "Using generic auto-decisions (stack-specific not found: $Stack)"
    }

    if (-not (Test-Path $decisionPath)) {
        Write-Warning "Auto-decision defaults not found: $decisionPath"
        return @{}
    }

    try {
        $decisionContent = Get-Content $decisionPath -Raw
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            $decisionData = $decisionContent | ConvertFrom-Yaml
            return $decisionData.defaults
        }

        if (Get-Command Read-IntakeYamlDocument -ErrorAction SilentlyContinue) {
            return Read-IntakeYamlDocument -Path $decisionPath -Kind 'defaults'
        }

        Write-Verbose "No YAML parser available, returning empty auto-decisions"
        return @{}
    } catch {
        Write-Error "Failed to load auto-decision defaults: $_"
        return @{}
    }
}
