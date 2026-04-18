# brownfield-merge.ps1
# Merges Specrew configuration into existing Spec Kit / Squad installations

<#
.SYNOPSIS
    Merges Specrew into an existing project with Spec Kit and/or Squad.

.DESCRIPTION
    Handles brownfield scenarios where Spec Kit or Squad are already installed.
    Preserves existing specs, governance, and team configuration while adding
    Specrew's baseline roles and governance artifacts.
    
    Implementation deferred to Iteration 1 (FR-002) with full brownfield support
    deferred to Iteration 2 (FR-020).

.PARAMETER ProjectPath
    Path to the target project directory

.EXAMPLE
    .\brownfield-merge.ps1 -ProjectPath "C:\Projects\ExistingApp"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

Write-Host "brownfield-merge.ps1: Placeholder script" -ForegroundColor Yellow
Write-Host "Implementation deferred to Iteration 1 (FR-002) / Iteration 2 (FR-020)" -ForegroundColor Yellow
Write-Host "Target path: $ProjectPath"

# TODO: Implement brownfield merge logic
# - Detect existing Spec Kit configuration
# - Detect existing Squad team configuration
# - Merge Specrew baseline roles into Squad team (non-destructive)
# - Create governance artifacts if missing
# - Report merge summary

exit 0
