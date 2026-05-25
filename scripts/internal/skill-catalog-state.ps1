# Shared skill-catalog state helpers for start/init repair paths.

Set-StrictMode -Version Latest

$script:SkillCatalogDetectHostsPath = Join-Path $PSScriptRoot 'detect-hosts.ps1'
if (-not (Get-Command Get-SpecrewSupportedHostKinds -ErrorAction SilentlyContinue)) {
    if (-not (Test-Path -LiteralPath $script:SkillCatalogDetectHostsPath -PathType Leaf)) {
        throw "Missing detect-hosts helper '$script:SkillCatalogDetectHostsPath'."
    }

    . $script:SkillCatalogDetectHostsPath
}

function Assert-SpecrewSkillCatalogHostHelpers {
    if (-not (Get-Command Get-SpecrewSupportedHostKinds -ErrorAction SilentlyContinue) -or
        -not (Get-Command Get-SpecrewHostSkillRoot -ErrorAction SilentlyContinue)) {
        throw "Skill-catalog host helpers were not loaded from '$script:SkillCatalogDetectHostsPath'."
    }
}

function Resolve-SpecrewSkillCatalogDeploymentScriptPath {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $deploymentScriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
    if (-not (Test-Path -LiteralPath $deploymentScriptPath -PathType Leaf)) {
        throw "Missing skill-catalog deployment script '$deploymentScriptPath'."
    }

    return $deploymentScriptPath
}

function Get-SpecrewSkillCatalogRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    Assert-SpecrewSkillCatalogHostHelpers

    $rootsByPath = [ordered]@{}
    foreach ($hostKind in Get-SpecrewSupportedHostKinds) {
        $rootPath = Get-SpecrewHostSkillRoot -HostKind $hostKind -ProjectPath $ProjectPath
        $normalizedPath = [System.IO.Path]::GetFullPath($rootPath)
        if (-not $rootsByPath.Contains($normalizedPath)) {
            $rootsByPath[$normalizedPath] = [pscustomobject]@{
                Path      = $normalizedPath
                HostKinds = New-Object System.Collections.Generic.List[string]
                Exists    = $false
            }
        }

        $rootsByPath[$normalizedPath].HostKinds.Add([string]$hostKind) | Out-Null
    }

    foreach ($entry in $rootsByPath.GetEnumerator()) {
        $entry.Value.Exists = Test-Path -LiteralPath $entry.Value.Path -PathType Container
        [pscustomobject]@{
            Path      = $entry.Value.Path
            HostKinds = @($entry.Value.HostKinds.ToArray())
            Exists    = [bool]$entry.Value.Exists
        }
    }
}

function Get-SpecrewSkillCatalogState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $roots = @(Get-SpecrewSkillCatalogRoot -ProjectPath $ProjectPath)
    $missingRoots = @($roots | Where-Object { -not $_.Exists })

    return [pscustomobject]@{
        ProjectPath     = $ProjectPath
        RequiredRoots   = @($roots)
        MissingRoots    = @($missingRoots)
        HasMissingRoots = ($missingRoots.Count -gt 0)
    }
}

function Format-SpecrewSkillCatalogRoots {
    param(
        [AllowEmptyCollection()]
        [object[]]$Roots
    )

    return (@($Roots) | ForEach-Object {
            $hostList = (@($_.HostKinds) -join ',')
            if ([string]::IsNullOrWhiteSpace($hostList)) {
                [string]$_.Path
            }
            else {
                '{0} ({1})' -f $_.Path, $hostList
            }
        }) -join '; '
}

function Invoke-SpecrewSkillCatalogRepair {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [string]$DeploymentScriptPath = '',

        [switch]$DryRun
    )

    $beforeState = Get-SpecrewSkillCatalogState -ProjectPath $ProjectPath
    if (-not $beforeState.HasMissingRoots) {
        return [pscustomobject]@{
            Repaired        = $false
            BeforeState     = $beforeState
            AfterState      = $beforeState
            DeploymentScript = $DeploymentScriptPath
            Actions         = @()
        }
    }

    if ([string]::IsNullOrWhiteSpace($DeploymentScriptPath)) {
        $DeploymentScriptPath = Resolve-SpecrewSkillCatalogDeploymentScriptPath
    }

    $deploymentActions = @(
        & $DeploymentScriptPath `
            -ProjectPath $ProjectPath `
            -DryRun:$DryRun `
            -PassThru
    )

    $afterState = Get-SpecrewSkillCatalogState -ProjectPath $ProjectPath
    return [pscustomobject]@{
        Repaired        = (-not $afterState.HasMissingRoots)
        BeforeState     = $beforeState
        AfterState      = $afterState
        DeploymentScript = $DeploymentScriptPath
        Actions         = @($deploymentActions)
    }
}
