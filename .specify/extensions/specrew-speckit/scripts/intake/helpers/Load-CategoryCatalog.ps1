<#
.SYNOPSIS
Load category catalog from YAML data.

.DESCRIPTION
Loads category definitions from .specify/intake/categories.yml.
Returns array of category objects representing the 12 intake categories.

Implements FR-028, FR-029 for Feature 049 Iteration 003.

.PARAMETER IntakeDataRoot
Root path for intake data catalogs. Defaults to .specify/intake/

.EXAMPLE
$categories = Load-CategoryCatalog -IntakeDataRoot ".specify/intake"

.NOTES
Mirror parity: This file must remain functionally identical to:
  .specify/extensions/specrew-speckit/scripts/intake/helpers/Load-CategoryCatalog.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Load-CategoryCatalog {
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

    $categoriesPath = Join-Path $IntakeDataRoot 'categories.yml'

    if (-not (Test-Path $categoriesPath)) {
        Write-Warning "Categories catalog not found: $categoriesPath"
        return @()
    }

    try {
        $categoriesContent = Get-Content $categoriesPath -Raw

        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            $categoriesData = $categoriesContent | ConvertFrom-Yaml
            return $categoriesData.categories
        }

        if (Get-Command Read-IntakeYamlDocument -ErrorAction SilentlyContinue) {
            return Read-IntakeYamlDocument -Path $categoriesPath -Kind 'categories'
        }

        Write-Verbose "No YAML parser available, returning empty category list"
        return @()
    } catch {
        Write-Error "Failed to load category catalog: $_"
        return @()
    }
}
