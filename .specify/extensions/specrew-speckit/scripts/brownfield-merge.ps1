# brownfield-merge.ps1
# Merges Specrew configuration into existing Spec Kit / Squad installations

<#
.SYNOPSIS
    Handles brownfield scenarios where Spec Kit or Squad are already installed.
    Preserves existing specs, governance, and team configuration while adding
    Specrew's baseline roles and governance artifacts.

.DESCRIPTION
    Detects existing project state and safely merges Specrew baseline configuration:
    - Preserves existing specs, governance artifacts, and user customizations
    - Merges baseline roles into existing Squad team without overwriting
    - Reports conflicts when dependencies are incompatible
    - Supports dry-run mode for reviewable merge preview

.PARAMETER ProjectPath
    Path to the target project directory.

.PARAMETER DryRun
    Show planned changes without writing files.

.PARAMETER PassThru
    Return structured merge analysis results.

.EXAMPLE
    .\brownfield-merge.ps1 -ProjectPath "C:\Projects\ExistingApp" -DryRun
#>

[CmdletBinding()]
param(
    [AllowEmptyCollection()]
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [switch]$DryRun,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Get-BrownfieldState {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $state = [pscustomobject]@{
        HasSpecify           = Test-Path -LiteralPath (Join-Path $ProjectPath '.specify')
        HasSquad             = Test-Path -LiteralPath (Join-Path $ProjectPath '.squad')
        HasSpecrewConfig     = Test-Path -LiteralPath (Join-Path $ProjectPath '.specrew\config.yml')
        HasSpecrewExtension  = Test-Path -LiteralPath (Join-Path $ProjectPath '.specify\extensions\specrew-speckit\extension.yml')
        HasSpecrewSource     = Test-Path -LiteralPath (Join-Path $ProjectPath 'extensions\specrew-speckit')
        HasSquadTeam         = Test-Path -LiteralPath (Join-Path $ProjectPath '.squad\team.md')
        HasSquadAgents       = Test-Path -LiteralPath (Join-Path $ProjectPath '.squad\agents')
        HasSquadCeremonies   = Test-Path -LiteralPath (Join-Path $ProjectPath '.squad\ceremonies.md')
        ExistingSpecs        = @()
        ExistingRoles        = @()
        ExistingCeremonies   = @()
        Conflicts            = [System.Collections.ArrayList]::new()
    }

    if ($state.HasSpecify) {
        $specsPath = Join-Path $ProjectPath 'specs'
        if (Test-Path -LiteralPath $specsPath) {
            $state.ExistingSpecs = @(Get-ChildItem -LiteralPath $specsPath -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
        }
    }

    if ($state.HasSquadTeam) {
        $teamPath = Join-Path $ProjectPath '.squad\team.md'
        $teamContent = Get-Content -LiteralPath $teamPath -Raw
        $rolePattern = '(?m)^\|\s*([^|]+)\s*\|'
        $matches = [regex]::Matches($teamContent, $rolePattern)
        $roles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($match in $matches) {
            $roleName = $match.Groups[1].Value.Trim()
            if ($roleName -notin @('Role', '----', '')) {
                $null = $roles.Add($roleName)
            }
        }
        $state.ExistingRoles = @($roles)
    }

    if ($state.HasSquadCeremonies) {
        $ceremoniesPath = Join-Path $ProjectPath '.squad\ceremonies.md'
        $ceremoniesContent = Get-Content -LiteralPath $ceremoniesPath -Raw
        $ceremonyHeadingPattern = '(?m)^##\s+(.+?)(?:\s*\{[^}]*\})?\s*$'
        $matches = [regex]::Matches($ceremoniesContent, $ceremonyHeadingPattern)
        $ceremonies = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($match in $matches) {
            $ceremonyName = $match.Groups[1].Value.Trim()
            if (-not [string]::IsNullOrWhiteSpace($ceremonyName)) {
                $null = $ceremonies.Add($ceremonyName)
            }
        }
        $state.ExistingCeremonies = @($ceremonies)
    }

    return $state
}

function Test-HasRoleConflict {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [string[]]$ExistingRoles,
        
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [string[]]$BaselineRoles
    )

    $conflicts = @()
    foreach ($baselineRole in $BaselineRoles) {
        if ($baselineRole -in $ExistingRoles) {
            $conflicts += $baselineRole
        }
    }

    return $conflicts
}

function Test-IsCanonicalSquadAgentSource {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [pscustomobject]$State
    )

    return ($State.HasSpecrewSource -and $State.HasSquadAgents)
}

function Test-HasCeremonyConflict {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [string[]]$ExistingCeremonies,
        
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [string[]]$SpecrewCeremonies
    )

    $conflicts = @()
    foreach ($specrew in $SpecrewCeremonies) {
        if ($specrew -in $ExistingCeremonies) {
            $conflicts += $specrew
        }
    }

    return $conflicts
}

function Get-MergeReport {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [pscustomobject]$State,
        
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [string[]]$BaselineRoles,
        
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [string[]]$SpecrewCeremonies
    )

    $report = [pscustomobject]@{
        Status               = 'ready'
        PreservedSpecs       = $State.ExistingSpecs
        PreservedRoles       = $State.ExistingRoles
        PreservedCeremonies  = $State.ExistingCeremonies
        RoleConflicts        = @()
        CeremonyConflicts    = @()
        MergeableRoles       = @()
        MergeableCeremonies  = @()
        CanonicalRoles       = @()
        Warnings             = [System.Collections.ArrayList]::new()
        Conflicts            = [System.Collections.ArrayList]::new()
    }

    $hasCanonicalSquadAgents = Test-IsCanonicalSquadAgentSource -State $State
    if ($hasCanonicalSquadAgents) {
        $report.CanonicalRoles = @($BaselineRoles | Where-Object { $_ -in $State.ExistingRoles })
        $report.RoleConflicts = @()
    }
    else {
        $report.RoleConflicts = @(Test-HasRoleConflict -ExistingRoles $State.ExistingRoles -BaselineRoles $BaselineRoles)
    }
    $report.CeremonyConflicts = @(Test-HasCeremonyConflict -ExistingCeremonies $State.ExistingCeremonies -SpecrewCeremonies $SpecrewCeremonies)
    
    $report.MergeableRoles = @($BaselineRoles | Where-Object { $_ -notin $State.ExistingRoles })
    $report.MergeableCeremonies = @($SpecrewCeremonies | Where-Object { $_ -notin $report.CeremonyConflicts })

    if ($report.RoleConflicts.Count -gt 0) {
        $null = $report.Conflicts.Add([pscustomobject]@{
            Type        = 'role'
            Description = "Existing roles conflict with Specrew baseline: $($report.RoleConflicts -join ', ')"
            Resolution  = 'Specrew will preserve existing role definitions in .squad/agents/. Review agent charters after bootstrap to merge Specrew directives manually if needed.'
        })
    }

    if ($report.CeremonyConflicts.Count -gt 0) {
        $null = $report.Warnings.Add([pscustomobject]@{
            Type        = 'ceremony'
            Description = "Existing ceremonies conflict with Specrew definitions: $($report.CeremonyConflicts -join ', ')"
            Resolution  = 'Specrew will preserve existing ceremony definitions. Review .squad/ceremonies.md to merge Specrew ceremony guidance manually if needed.'
        })
    }

    if (-not $State.HasSpecify -and $State.HasSquad) {
        $null = $report.Warnings.Add([pscustomobject]@{
            Type        = 'partial-platform'
            Description = 'Squad is initialized but Spec Kit is missing'
            Resolution  = 'Brownfield bootstrap will skip Spec Kit extension deployment. Run `specify init` manually, then re-run `specrew init` to complete the installation.'
        })
    }

    if ($State.HasSpecify -and -not $State.HasSquad) {
        $null = $report.Warnings.Add([pscustomobject]@{
            Type        = 'partial-platform'
            Description = 'Spec Kit is initialized but Squad is missing'
            Resolution  = 'Brownfield bootstrap will skip Squad runtime deployment. Run `squad init` manually, then re-run `specrew init` to complete the installation.'
        })
    }

    if ($State.ExistingSpecs.Count -gt 0) {
        $null = $report.Warnings.Add([pscustomobject]@{
            Type        = 'existing-specs'
            Description = "Found existing specs: $($State.ExistingSpecs -join ', ')"
            Resolution  = 'Existing specs will be preserved. Specrew will merge governance artifacts without modifying existing spec content.'
        })
    }

    if ($report.Conflicts.Count -gt 0) {
        $report.Status = 'conflicts-detected'
    }
    elseif ($report.Warnings.Count -gt 0) {
        $report.Status = 'warnings-present'
    }

    return $report
}

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath

if (-not (Test-Path -LiteralPath $resolvedProjectPath)) {
    Write-Error "Project path '$resolvedProjectPath' does not exist."
    exit 1
}

if (-not $PassThru) {
    Write-Host "==> Analyzing brownfield project state" -ForegroundColor Cyan
}

$state = Get-BrownfieldState -ProjectPath $resolvedProjectPath

$baselineRoles = @('Spec Steward', 'Planner', 'Implementer', 'Reviewer', 'Retro Facilitator')
$specrewCeremonies = @('Specrew: Planning', 'Specrew: Review/Demo')

$report = Get-MergeReport -State $state -BaselineRoles $baselineRoles -SpecrewCeremonies $specrewCeremonies

if ($PassThru) {
    # Return only the report object as JSON to avoid PowerShell auto-formatting
    $report | ConvertTo-Json -Depth 10 -Compress
    exit 0
}

Write-Host ''
Write-Host "Brownfield merge analysis for: $resolvedProjectPath" -ForegroundColor Green
Write-Host "Status: $($report.Status)" -ForegroundColor $(if ($report.Status -eq 'ready') { 'Green' } elseif ($report.Status -eq 'warnings-present') { 'Yellow' } else { 'Red' })
Write-Host ''

if ($state.PreservedSpecs.Count -gt 0) {
    Write-Host "Preserved specs: $($state.PreservedSpecs.Count)" -ForegroundColor Cyan
}

if ($state.PreservedRoles.Count -gt 0) {
    Write-Host "Preserved roles: $($state.PreservedRoles -join ', ')" -ForegroundColor Cyan
}

if ($report.MergeableRoles.Count -gt 0) {
    Write-Host "Mergeable baseline roles: $($report.MergeableRoles -join ', ')" -ForegroundColor Green
}

if ($report.RoleConflicts.Count -gt 0) {
    Write-Host "Role conflicts: $($report.RoleConflicts -join ', ')" -ForegroundColor Yellow
}

if ($report.CanonicalRoles.Count -gt 0) {
    Write-Host "Canonical roles: $($report.CanonicalRoles -join ', ')" -ForegroundColor Cyan
}

if ($report.MergeableCeremonies.Count -gt 0) {
    Write-Host "Mergeable ceremonies: $($report.MergeableCeremonies -join ', ')" -ForegroundColor Green
}

if ($report.CeremonyConflicts.Count -gt 0) {
    Write-Host "Ceremony conflicts: $($report.CeremonyConflicts -join ', ')" -ForegroundColor Yellow
}

Write-Host ''
if ($report.Conflicts.Count -gt 0) {
    Write-Host 'Conflicts:' -ForegroundColor Red
    foreach ($conflict in $report.Conflicts) {
        Write-Host "  - [$($conflict.Type)] $($conflict.Description)" -ForegroundColor Red
        Write-Host "    Resolution: $($conflict.Resolution)" -ForegroundColor Yellow
    }
    Write-Host ''
}

if ($report.Warnings.Count -gt 0) {
    Write-Host 'Warnings:' -ForegroundColor Yellow
    foreach ($warning in $report.Warnings) {
        Write-Host "  - [$($warning.Type)] $($warning.Description)" -ForegroundColor Yellow
        Write-Host "    Resolution: $($warning.Resolution)" -ForegroundColor Cyan
    }
    Write-Host ''
}

if ($DryRun) {
    Write-Host 'Dry run complete. Merge strategy validated.' -ForegroundColor Yellow
}

exit 0
