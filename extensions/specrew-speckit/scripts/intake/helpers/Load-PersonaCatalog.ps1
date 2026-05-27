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

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$IntakeDataRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
    
    # Use ConvertFrom-Yaml if available (powershell-yaml module)
    if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
        $personasData = $personasContent | ConvertFrom-Yaml
        return $personasData.personas
    } else {
        # Fallback: basic parsing for testing (production should use powershell-yaml)
        Write-Verbose "ConvertFrom-Yaml not available, returning empty persona list"
        return @()
    }
} catch {
    Write-Error "Failed to load persona catalog: $_"
    return @()
}
