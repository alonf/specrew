# scaffold-governance.ps1
# Creates governance artifacts (constitution, iteration config, role assignments) for a downstream project

<#
.SYNOPSIS
    Scaffolds governance artifacts for a Specrew-managed project.

.DESCRIPTION
    Creates the downstream governance files required by the Specrew bootstrap:
    - .specrew\config.yml
    - .specrew\constitution.md
    - .specrew\iteration-config.yml (including Phase 2 routing-strength defaults)
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

        [AllowEmptyCollection()]
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

function Ensure-ManagedDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    $targetExists = Test-Path -LiteralPath $TargetPath
    $action = if ($targetExists) {
        'preserved-directory'
    }
    elseif ($DryRun) {
        'would-create-directory'
    }
    else {
        'created-directory'
    }

    $null = $Actions.Add([pscustomobject]@{
            Path   = $TargetPath
            Action = $action
        })

    if ($targetExists -or $DryRun) {
        return
    }

    New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
}

function Save-ManagedTemplateTree {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
        return
    }

    Ensure-ManagedDirectory -TargetPath $TargetRoot -Actions $Actions

    $sourceFiles = Get-ChildItem -LiteralPath $SourceRoot -File -Recurse | Sort-Object FullName
    foreach ($sourceFile in $sourceFiles) {
        $relativePath = [System.IO.Path]::GetRelativePath($SourceRoot, $sourceFile.FullName)
        $targetPath = Join-Path $TargetRoot $relativePath
        $content = Get-Content -LiteralPath $sourceFile.FullName -Raw
        Save-ManagedFile -TargetPath $targetPath -Content $content -Actions $Actions
    }
}

function Save-ConfigFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$QualityBlock,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        Save-ManagedFile -TargetPath $TargetPath -Content $Content -Actions $Actions
        return
    }

    $existingContent = Get-Content -LiteralPath $TargetPath -Raw
    if ($existingContent -match '(?m)^quality:\s*$') {
        $null = $Actions.Add([pscustomobject]@{
                Path   = $TargetPath
                Action = 'preserved'
            })
        return
    }

    $separator = if ($existingContent.EndsWith("`n")) { '' } else { "`r`n" }
    $updatedContent = $existingContent.TrimEnd() + $separator + "`r`n" + $QualityBlock
    $action = if ($DryRun) { 'would-update' } else { 'updated' }
    $null = $Actions.Add([pscustomobject]@{
            Path   = $TargetPath
            Action = $action
        })

    if ($DryRun) {
        return
    }

    [System.IO.File]::WriteAllText($TargetPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
}

$resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
$extensionRoot = Split-Path -Parent $PSScriptRoot
$templateRoot = Join-Path $extensionRoot 'templates'
$specrewRoot = Join-Path $resolvedProjectPath '.specrew'
$qualityTemplateRoot = Join-Path $templateRoot 'quality'
$presetTemplateRoot = Join-Path $qualityTemplateRoot 'presets'
$lensTemplateRoot = Join-Path $qualityTemplateRoot 'lenses'
$presetRoot = Join-Path $specrewRoot 'presets'
$lensRoot = Join-Path $specrewRoot 'lenses'
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

Ensure-ManagedDirectory -TargetPath $specrewRoot -Actions $actions
Ensure-ManagedDirectory -TargetPath $presetRoot -Actions $actions
Ensure-ManagedDirectory -TargetPath $lensRoot -Actions $actions

$constitutionContent = Get-TargetFileContent -TemplatePath (Join-Path $templateRoot 'downstream-constitution.md') -CreatedDate $createdDate
# The iteration-config template carries the default agent strength metadata used by
# Phase 2 strongest-available review routing.
$iterationConfigContent = Get-Content -Path (Join-Path $templateRoot 'iteration-config.yml') -Raw
$roleAssignmentsContent = Get-Content -Path (Join-Path $templateRoot 'role-assignments.yml') -Raw
$qualityBlock = @"
quality:
  presets_path: ".specrew/presets"
  lenses_path: ".specrew/lenses"
  findings_schema_version: "v1"
  evidence_directory_name: "quality"
"@
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
$qualityBlock
"@

Save-ManagedFile -TargetPath (Join-Path $specrewRoot 'constitution.md') -Content $constitutionContent -Actions $actions
Save-ManagedFile -TargetPath (Join-Path $specrewRoot 'iteration-config.yml') -Content $iterationConfigContent -Actions $actions
Save-ManagedFile -TargetPath (Join-Path $specrewRoot 'role-assignments.yml') -Content $roleAssignmentsContent -Actions $actions
Save-ConfigFile -TargetPath (Join-Path $specrewRoot 'config.yml') -Content $configContent -QualityBlock $qualityBlock -Actions $actions
Save-ManagedTemplateTree -SourceRoot $presetTemplateRoot -TargetRoot $presetRoot -Actions $actions
Save-ManagedTemplateTree -SourceRoot $lensTemplateRoot -TargetRoot $lensRoot -Actions $actions

if ($PassThru) {
    $actions
    return
}

$actions |
    Select-Object Action, Path |
    Format-Table -AutoSize

Write-Host ("Governance scaffolding {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $resolvedProjectPath)) -ForegroundColor Green
exit 0
