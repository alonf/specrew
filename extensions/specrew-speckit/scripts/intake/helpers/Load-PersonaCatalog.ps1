<#
.SYNOPSIS
Load persona catalog from YAML data.

.DESCRIPTION
Loads persona definitions from .specify/intake/personas.yml.
Returns array of persona objects with id, name, description, and question_bank_path.

Implements FR-028, FR-029 for Feature 049 Iteration 003.

.PARAMETER IntakeDataRoot
Root path for intake data catalogs. Defaults to .specify/intake/

.EXAMPLE
$personas = Load-PersonaCatalog -IntakeDataRoot ".specify/intake"

.NOTES
Mirror parity: This file must remain functionally identical to:
  .specify/extensions/specrew-speckit/scripts/intake/helpers/Load-PersonaCatalog.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Load-PersonaCatalog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$IntakeDataRoot
    )

    $parserPath = Join-Path $PSScriptRoot 'Read-IntakeYaml.ps1'
    if (-not (Get-Command Read-IntakeYamlDocument -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $parserPath -PathType Leaf)) {
        . $parserPath
    }

    if ([string]::IsNullOrEmpty($IntakeDataRoot)) {
        $IntakeDataRoot = Join-Path (Get-Location) '.specify\intake'
    }

    $personasPath = Join-Path $IntakeDataRoot 'personas.yml'

    if (-not (Test-Path $personasPath)) {
        Write-Warning "Personas catalog not found: $personasPath"
        return @()
    }

    try {
        $personasContent = Get-Content $personasPath -Raw

        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            $personasData = $personasContent | ConvertFrom-Yaml
            return $personasData.personas
        }

        if (Get-Command Read-IntakeYamlDocument -ErrorAction SilentlyContinue) {
            return Read-IntakeYamlDocument -Path $personasPath -Kind 'personas'
        }

        Write-Verbose "No YAML parser available, returning empty persona list"
        return @()
    } catch {
        Write-Error "Failed to load persona catalog: $_"
        return @()
    }
}
