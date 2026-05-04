# scaffold-governance.ps1
# Creates governance artifacts (constitution, iteration config, role assignments) for a downstream project

<#
.SYNOPSIS
    Scaffolds governance artifacts for a Specrew-managed project.

.DESCRIPTION
    Creates the downstream governance files required by the Specrew bootstrap:
    - .specrew\config.yml
    - .specrew\constitution.md
    - .specrew\iteration-config.yml
    - .specrew\role-assignments.yml

.PARAMETER ProjectPath
    Path to the target project directory.

.PARAMETER SpecrewVersion
    Specrew version to record in .specrew\config.yml.

.PARAMETER SpecKitVersion
    Detected Spec Kit version to record in .specrew\config.yml.

.PARAMETER SquadVersion
    Detected Squad version to record in .specrew\config.yml.

.PARAMETER BootstrapMode
    Bootstrap mode to record in .specrew\config.yml.

.PARAMETER DryRun
    Show intended changes without writing files.

.PARAMETER PassThru
    Return structured action details.

.EXAMPLE
    .\scaffold-governance.ps1 -ProjectPath "C:\Projects\MyApp"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [string]$SpecrewVersion = '0.1.0-dev',
    [string]$SpecKitVersion,
    [string]$SquadVersion,
    [ValidateSet('greenfield', 'brownfield')]
    [string]$BootstrapMode = 'greenfield',
    [switch]$DryRun,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-TargetFileContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplatePath,

        [Parameter(Mandatory = $true)]
        [string]$CreatedDate
    )

    $content = Get-Content -Path $TemplatePath -Raw
    return $content -replace '<!-- YYYY-MM-DD populated at bootstrap -->', $CreatedDate
}

function Save-ManagedFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    $targetExists = Test-Path -LiteralPath $TargetPath
    $action = if ($targetExists) {
        'preserved'
    }
    elseif ($DryRun) {
        'would-create'
    }
    else {
        'created'
    }

    $null = $Actions.Add([pscustomobject]@{
            Path   = $TargetPath
            Action = $action
        })

    if ($targetExists -or $DryRun) {
        return
    }

    $parent = Split-Path -Parent $TargetPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

$resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
$extensionRoot = Split-Path -Parent $PSScriptRoot
$templateRoot = Join-Path $extensionRoot 'templates'
$specrewRoot = Join-Path $resolvedProjectPath '.specrew'
$createdDate = Get-Date -Format 'yyyy-MM-dd'
$actions = [System.Collections.ArrayList]::new()

if (-not (Test-Path -LiteralPath $resolvedProjectPath)) {
    $null = $actions.Add([pscustomobject]@{
            Path   = $resolvedProjectPath
            Action = $(if ($DryRun) { 'would-create-directory' } else { 'created-directory' })
        })

    if (-not $DryRun) {
        New-Item -Path $resolvedProjectPath -ItemType Directory -Force | Out-Null
    }
}

if (-not (Test-Path -LiteralPath $specrewRoot)) {
    $null = $actions.Add([pscustomobject]@{
            Path   = $specrewRoot
            Action = $(if ($DryRun) { 'would-create-directory' } else { 'created-directory' })
        })

    if (-not $DryRun) {
        New-Item -Path $specrewRoot -ItemType Directory -Force | Out-Null
    }
}
else {
    $null = $actions.Add([pscustomobject]@{
            Path   = $specrewRoot
            Action = 'preserved-directory'
        })
}

$constitutionContent = Get-TargetFileContent -TemplatePath (Join-Path $templateRoot 'downstream-constitution.md') -CreatedDate $createdDate
$iterationConfigContent = Get-Content -Path (Join-Path $templateRoot 'iteration-config.yml') -Raw
$roleAssignmentsContent = Get-Content -Path (Join-Path $templateRoot 'role-assignments.yml') -Raw
$configContent = @"
specrew_version: "$SpecrewVersion"
speckit_version: "$SpecKitVersion"
squad_version: "$SquadVersion"
bootstrap_date: "$createdDate"
bootstrap_mode: "$BootstrapMode"
governance:
  constitution_path: ".specrew/constitution.md"
  iteration_config_path: ".specrew/iteration-config.yml"
  role_assignments_path: ".specrew/role-assignments.yml"
"@

Save-ManagedFile -TargetPath (Join-Path $specrewRoot 'constitution.md') -Content $constitutionContent -Actions $actions
Save-ManagedFile -TargetPath (Join-Path $specrewRoot 'iteration-config.yml') -Content $iterationConfigContent -Actions $actions
Save-ManagedFile -TargetPath (Join-Path $specrewRoot 'role-assignments.yml') -Content $roleAssignmentsContent -Actions $actions
Save-ManagedFile -TargetPath (Join-Path $specrewRoot 'config.yml') -Content $configContent -Actions $actions

if ($PassThru) {
    $actions
    return
}

$actions |
    Select-Object Action, Path |
    Format-Table -AutoSize

Write-Host ("Governance scaffolding {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $resolvedProjectPath)) -ForegroundColor Green
exit 0
