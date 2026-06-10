[CmdletBinding(PositionalBinding = $false)]
param(
    [Alias('project-path')]
    [string]$ProjectPath = (Get-Location).Path,
    [Alias('dry-run')]
    [switch]$DryRun,
    [switch]$Force,
    [Alias('speckit-version')]
    [string]$SpecKitVersion = '0.8.4',
    [Alias('squad-version')]
    [string]$SquadVersion = '0.9.1',
    [string]$Agents = 'copilot',
    [Alias('no-agents')]
    [switch]$NoAgents,
    [Alias('spec-kit-extension-only')]
    [switch]$SpecKitExtensionOnly,
    [switch]$SkipUpdateCheck,
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

$skillCatalogStateHelperPath = Join-Path $PSScriptRoot 'internal\skill-catalog-state.ps1'
if (-not (Test-Path -LiteralPath $skillCatalogStateHelperPath -PathType Leaf)) {
    throw "Missing skill-catalog state helper '$skillCatalogStateHelperPath'."
}
. $skillCatalogStateHelperPath

$initUtilitiesPath = Join-Path $PSScriptRoot 'init\_utilities.ps1'
if (-not (Test-Path -LiteralPath $initUtilitiesPath -PathType Leaf)) {
    throw "Missing init/_utilities.ps1 helper at '$initUtilitiesPath'."
}
. $initUtilitiesPath

$initPreflightPath = Join-Path $PSScriptRoot 'init\preflight.ps1'
if (-not (Test-Path -LiteralPath $initPreflightPath -PathType Leaf)) {
    throw "Missing init/preflight.ps1 helper at '$initPreflightPath'."
}
. $initPreflightPath

$initTemplateDeployPath = Join-Path $PSScriptRoot 'init\template-deploy.ps1'
if (-not (Test-Path -LiteralPath $initTemplateDeployPath -PathType Leaf)) {
    throw "Missing init/template-deploy.ps1 helper at '$initTemplateDeployPath'."
}
. $initTemplateDeployPath

$initSpecKitDeployPath = Join-Path $PSScriptRoot 'init\spec-kit-deploy.ps1'
if (-not (Test-Path -LiteralPath $initSpecKitDeployPath -PathType Leaf)) {
    throw "Missing init/spec-kit-deploy.ps1 helper at '$initSpecKitDeployPath'."
}
. $initSpecKitDeployPath

$initDependencyInstallPath = Join-Path $PSScriptRoot 'init\dependency-install.ps1'
if (-not (Test-Path -LiteralPath $initDependencyInstallPath -PathType Leaf)) {
    throw "Missing init/dependency-install.ps1 helper at '$initDependencyInstallPath'."
}
. $initDependencyInstallPath

$initAgentDetectionPath = Join-Path $PSScriptRoot 'init\agent-detection.ps1'
if (-not (Test-Path -LiteralPath $initAgentDetectionPath -PathType Leaf)) {
    throw "Missing init/agent-detection.ps1 helper at '$initAgentDetectionPath'."
}
. $initAgentDetectionPath

$initSquadDeployPath = Join-Path $PSScriptRoot 'init\squad-deploy.ps1'
if (-not (Test-Path -LiteralPath $initSquadDeployPath -PathType Leaf)) {
    throw "Missing init/squad-deploy.ps1 helper at '$initSquadDeployPath'."
}
. $initSquadDeployPath

$initPostBootstrapPath = Join-Path $PSScriptRoot 'init\post-bootstrap-output.ps1'
if (-not (Test-Path -LiteralPath $initPostBootstrapPath -PathType Leaf)) {
    throw "Missing init/post-bootstrap-output.ps1 helper at '$initPostBootstrapPath'."
}
. $initPostBootstrapPath

$initCrewBootstrapPath = Join-Path $PSScriptRoot 'init\crew-bootstrap.ps1'
if (-not (Test-Path -LiteralPath $initCrewBootstrapPath -PathType Leaf)) {
    throw "Missing init/crew-bootstrap.ps1 helper at '$initCrewBootstrapPath'."
}
. $initCrewBootstrapPath

function Get-ManagedAgentsBlock {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Agents
    )

    $lookup = Get-AgentLookup -Agents $Agents
    $lines = @(
        '# >>> specrew-managed agents >>>',
        '# Specrew-managed delegated-agent opt-in and detection state (FR-022).',
        'agents:'
    )

    foreach ($name in @('copilot', 'claude', 'codex')) {
        $agent = $lookup[$name]
        $lines += "  ${name}:"
        $lines += "    enabled: $(ConvertTo-YamlBoolean -Value $agent.Enabled)"
        $lines += "    access_path: $($agent.AccessPath)"
        $lines += "    availability: $($agent.Availability)"
    }

    $lines += '# <<< specrew-managed agents <<<'
    return $lines -join [Environment]::NewLine
}

function Set-IterationConfigAgents {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationConfigPath,

        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Agents,

        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    $managedBlock = Get-ManagedAgentsBlock -Agents $Agents
    if (-not (Test-Path -LiteralPath $IterationConfigPath)) {
        if ($PreviewOnly) {
            Add-Action -Actions $Actions -Step 'agent-config' -Outcome ("would create {0}" -f $IterationConfigPath)
            return
        }

        $parent = Split-Path -Parent $IterationConfigPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($IterationConfigPath, ($managedBlock + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
        Add-Action -Actions $Actions -Step 'agent-config' -Outcome ("created {0}" -f $IterationConfigPath)
        return
    }

    $content = Get-Content -LiteralPath $IterationConfigPath -Raw
    $managedPattern = '(?ms)(\r?\n)?# >>> specrew-managed agents >>>.*?# <<< specrew-managed agents <<<(\r?\n)?'
    $baseContent = [regex]::Replace($content, $managedPattern, '')
    $updatedContent = $baseContent.TrimEnd()

    if ([string]::IsNullOrWhiteSpace($updatedContent)) {
        $updatedContent = $managedBlock
    }
    else {
        $updatedContent = $updatedContent + [Environment]::NewLine + [Environment]::NewLine + $managedBlock
    }

    if ($PreviewOnly) {
        Add-Action -Actions $Actions -Step 'agent-config' -Outcome ("would update {0}" -f $IterationConfigPath)
        return
    }

    [System.IO.File]::WriteAllText($IterationConfigPath, ($updatedContent + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    Add-Action -Actions $Actions -Step 'agent-config' -Outcome ("updated {0}" -f $IterationConfigPath)
}

$explicitAgentsValueSpecified = $PSBoundParameters.ContainsKey('Agents')
$explicitNoAgentsSpecified = $PSBoundParameters.ContainsKey('NoAgents')
$cliArguments = @($CliArgs)

for ($cliIndex = 0; $cliIndex -lt $cliArguments.Count; $cliIndex++) {
    $cliArg = $cliArguments[$cliIndex]
    if ([string]::IsNullOrWhiteSpace($cliArg)) {
        continue
    }

    switch -Regex ($cliArg) {
        '^--dry-run$' {
            $DryRun = $true
            continue
        }
        '^--force$' {
            $Force = $true
            continue
        }
        '^--help$' {
            $Help = $true
            continue
        }
        '^--no-agents$' {
            $NoAgents = $true
            $explicitNoAgentsSpecified = $true
            continue
        }
        '^--agents=(.+)$' {
            $Agents = $Matches[1]
            $explicitAgentsValueSpecified = $true
            continue
        }
        '^--agents$' {
            if (($cliIndex + 1) -ge $cliArguments.Count -or [string]::IsNullOrWhiteSpace($cliArguments[$cliIndex + 1])) {
                Write-Error '--agents requires a value.'
                exit 3
            }

            $cliIndex++
            $Agents = $cliArguments[$cliIndex]
            $explicitAgentsValueSpecified = $true
            continue
        }
        '^--project-path=(.+)$' {
            $ProjectPath = $Matches[1]
            continue
        }
        '^--project-path$' {
            if (($cliIndex + 1) -ge $cliArguments.Count -or [string]::IsNullOrWhiteSpace($cliArguments[$cliIndex + 1])) {
                Write-Error '--project-path requires a value.'
                exit 3
            }

            $cliIndex++
            $ProjectPath = $cliArguments[$cliIndex]
            continue
        }
        '^--speckit-version=(.+)$' {
            $SpecKitVersion = $Matches[1]
            continue
        }
        '^--speckit-version$' {
            if (($cliIndex + 1) -ge $cliArguments.Count -or [string]::IsNullOrWhiteSpace($cliArguments[$cliIndex + 1])) {
                Write-Error '--speckit-version requires a value.'
                exit 3
            }

            $cliIndex++
            $SpecKitVersion = $cliArguments[$cliIndex]
            continue
        }
        '^--squad-version=(.+)$' {
            $SquadVersion = $Matches[1]
            continue
        }
        '^--squad-version$' {
            if (($cliIndex + 1) -ge $cliArguments.Count -or [string]::IsNullOrWhiteSpace($cliArguments[$cliIndex + 1])) {
                Write-Error '--squad-version requires a value.'
                exit 3
            }

            $cliIndex++
            $SquadVersion = $cliArguments[$cliIndex]
            continue
        }
        '^--spec-kit-extension-only$' {
            $SpecKitExtensionOnly = $true
            continue
        }
        '^--skip-update-check$' {
            $SkipUpdateCheck = $true
            continue
        }
        default {
            Write-Error ("Unknown option '{0}'." -f $cliArg)
            exit 3
        }
    }
}

if ($explicitAgentsValueSpecified -and $explicitNoAgentsSpecified) {
    Write-Error "Specify either --agents or --no-agents, not both."
    exit 3
}

if ($Help) {
    Show-Usage
    exit 0
}

# Pre-flight dependency check
Write-Step 'Checking required dependencies'
$preFlightCheck = Test-PreFlightDependencies -IncludeOptional

if (-not $preFlightCheck.AllOk) {
    $hasErrors = $preFlightCheck.MissingDeps.Count -gt 0 -or ($preFlightCheck.OutdatedDeps | Where-Object { $_.Tool -ne 'gh' }).Count -gt 0
    
    if ($preFlightCheck.MissingDeps.Count -gt 0) {
        Write-Host ''
        Write-Host 'Missing required dependencies:' -ForegroundColor Red
        Write-Host ''
        foreach ($dep in $preFlightCheck.MissingDeps) {
            if ($dep.Tool -eq 'gh') {
                Write-Host ("  [{0}] {1} (optional but recommended)" -f $dep.Platform, $dep.Tool) -ForegroundColor Yellow
                Write-Host ("      {0}" -f $dep.InstallHint) -ForegroundColor DarkGray
            } else {
                Write-Host ("  [{0}] {1} {2} (required: {3})" -f $dep.Platform, $dep.Tool, $dep.Current, $dep.Required) -ForegroundColor Red
                Write-Host ("      {0}" -f $dep.InstallHint) -ForegroundColor DarkGray
            }
            Write-Host ''
        }
    }
    
    if ($preFlightCheck.OutdatedDeps.Count -gt 0) {
        Write-Host ''
        Write-Host 'Outdated dependencies:' -ForegroundColor Yellow
        Write-Host ''
        foreach ($dep in $preFlightCheck.OutdatedDeps) {
            Write-Host ("  [{0}] {1} {2} (required: {3})" -f $dep.Platform, $dep.Tool, $dep.Current, $dep.Required) -ForegroundColor Yellow
            Write-Host ("      {0}" -f $dep.InstallHint) -ForegroundColor DarkGray
            Write-Host ''
        }
    }
    
    if ($hasErrors) {
        Write-Host 'Install all required dependencies before running specrew init.' -ForegroundColor Red
        exit 4
    } else {
        Write-Host 'All required dependencies are installed.' -ForegroundColor Green
    }
} else {
    Write-Host 'All required dependencies are installed.' -ForegroundColor Green
}
Write-Host ''

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
$executionLayout = Get-SpecrewExecutionLayout
$repoRoot = $executionLayout.RootPath
$validateVersionsScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-versions.ps1'
$deploySpeckitExtensionScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-speckit-extension.ps1'
$deploySquadRuntimeScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
$scaffoldGovernanceScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-governance.ps1'
$specrewExtensionManifestPath = Join-Path $repoRoot 'extensions\specrew-speckit\extension.yml'
$actions = [System.Collections.ArrayList]::new()

if (-not (Test-Path -LiteralPath $resolvedProjectPath)) {
    if ($DryRun) {
        Add-Action -Actions $actions -Step 'project-path' -Outcome "would create $resolvedProjectPath"
    }
    else {
        New-Item -Path $resolvedProjectPath -ItemType Directory -Force | Out-Null
        Add-Action -Actions $actions -Step 'project-path' -Outcome "created $resolvedProjectPath"
    }
}

$existingEntries = @(Get-ChildItem -Path $resolvedProjectPath -Force -ErrorAction SilentlyContinue)
$blockingEntries = @($existingEntries | Where-Object { $_.Name -ne '.git' })
$hadSpecify = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.specify')
$hadSquad = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.squad')
$hadGitHub = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.github')
$hadSpecifyContent = $hadSpecify -and ((@(
            Get-ChildItem -LiteralPath (Join-Path $resolvedProjectPath '.specify') -Force -ErrorAction SilentlyContinue
        ).Count) -gt 0)
$hadSquadContent = $hadSquad -and ((@(
            Get-ChildItem -LiteralPath (Join-Path $resolvedProjectPath '.squad') -Force -ErrorAction SilentlyContinue
        ).Count) -gt 0)
$hadGitHubContent = $hadGitHub -and ((@(
            Get-ChildItem -LiteralPath (Join-Path $resolvedProjectPath '.github') -Force -ErrorAction SilentlyContinue
        ).Count) -gt 0)
$hasSpecrewConfig = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.specrew\config.yml')
$alreadyBootstrapped = $hadSpecify -and $hasSpecrewConfig
if (-not $SpecKitExtensionOnly) {
    $alreadyBootstrapped = $alreadyBootstrapped -and $hadSquad -and $hadGitHub
}
$bootstrapMode = if ($hadSpecify -or $hadSquad) { 'brownfield' } else { 'greenfield' }
$shouldInitializeSpecify = -not $hadSpecify
$shouldInitializeSquad = -not $hadSquad
$shouldForceSpecifyInit = $Force -or ($blockingEntries.Count -eq 0)
$specifySurfaceReady = $hadSpecify -or $shouldInitializeSpecify
$squadSurfaceReady = $hadSquad -or $shouldInitializeSquad

if ($blockingEntries.Count -gt 0 -and -not $Force -and -not $hadSpecify -and -not $hadSquad) {
    Write-Error "Target directory '$resolvedProjectPath' is not empty. Re-run with -Force to allow bootstrap into a populated workspace."
    exit 3
}

if ($alreadyBootstrapped -and -not $Force) {
    Write-Step 'Checking idempotent bootstrap state'
    Add-Action -Actions $actions -Step 'specify-init' -Outcome 'preserved existing .specify'
    if (-not $SpecKitExtensionOnly) {
        Add-Action -Actions $actions -Step 'squad-init' -Outcome 'preserved existing .squad'
    }
    Add-Action -Actions $actions -Step 'template-source' -Outcome ("{0}: {1}" -f $executionLayout.Mode, $executionLayout.TemplateRoot)
    Add-Action -Actions $actions -Step 'template-copy' -Outcome 'preserved existing .specify; re-run with -Force to refresh bundled templates'
    if (-not $SpecKitExtensionOnly) {
        Add-Action -Actions $actions -Step 'template-copy' -Outcome 'preserved existing .squad; re-run with -Force to refresh bundled templates'
        Add-Action -Actions $actions -Step 'template-copy' -Outcome 'preserved existing .github; re-run with -Force to refresh bundled templates'
    }

    if ($DryRun) {
        Add-Action -Actions $actions -Step 'bootstrap-validation' -Outcome 'would validate .specify templates, .squad agents, .github workflows, and .github/agents/squad.agent.md'
    }
    else {
        $bootstrapValidation = Test-BootstrappedProjectState -ProjectPath $resolvedProjectPath -SpecKitExtensionOnly:$SpecKitExtensionOnly
        if (-not $bootstrapValidation.Succeeded) {
            foreach ($failure in $bootstrapValidation.Failures) {
                Write-Error $failure -ErrorAction Continue
            }

            exit 1
        }

        $skillCatalogState = if (-not $SpecKitExtensionOnly) {
            Get-SpecrewSkillCatalogState -ProjectPath $resolvedProjectPath
        }
        else {
            [pscustomobject]@{ HasMissingRoots = $false; MissingRoots = @() }
        }

        if ($skillCatalogState.HasMissingRoots) {
            Add-Action -Actions $actions -Step 'bootstrap-validation' -Outcome 'validated core bootstrap surfaces; skill catalog deployment gap detected'
            Add-Action -Actions $actions -Step 'skill-catalog-gap' -Outcome (Format-SpecrewSkillCatalogRoots -Roots $skillCatalogState.MissingRoots)
            Write-Host ("Specrew is already bootstrapped in '{0}', but skill catalog directories are missing. Repairing deployment gap." -f $resolvedProjectPath) -ForegroundColor Yellow

            $skillCatalogRepair = Invoke-SpecrewSkillCatalogRepair -ProjectPath $resolvedProjectPath -DeploymentScriptPath $deploySquadRuntimeScript -DryRun:$DryRun
            foreach ($deploymentAction in @($skillCatalogRepair.Actions)) {
                if ($deploymentAction.PSObject.Properties['Action'] -and $deploymentAction.PSObject.Properties['Path']) {
                    Add-Action -Actions $actions -Step 'squad-runtime' -Outcome ("{0}: {1}" -f $deploymentAction.Action, $deploymentAction.Path)
                }
            }

            if ($skillCatalogRepair.AfterState.HasMissingRoots) {
                foreach ($missingRoot in @($skillCatalogRepair.AfterState.MissingRoots)) {
                    Write-Error ("Missing required skill catalog directory after repair: {0}" -f $missingRoot.Path) -ErrorAction Continue
                }

                exit 1
            }

            Add-Action -Actions $actions -Step 'slash-surface' -Outcome 'repaired /specrew skill catalog across .claude/skills, .github/skills, and .agents/skills'
        }
        else {
            Add-Action -Actions $actions -Step 'bootstrap-validation' -Outcome 'validated .specify templates, .squad agents, .github workflows, and .github/agents/squad.agent.md'
            Write-Host ("Specrew is already bootstrapped in '{0}'. Re-run with -Force to refresh bundled templates." -f $resolvedProjectPath) -ForegroundColor Yellow
        }
    }

    Write-BootstrapSummary -Actions $actions -DryRunMode:$DryRun -ProjectPath $resolvedProjectPath -ShowGuidance:$false
    exit 0
}

if ($bootstrapMode -eq 'brownfield') {
    Write-Step 'Running brownfield merge analysis'
    $brownfieldMergeScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\brownfield-merge.ps1'
    $brownfieldReportJson = & $brownfieldMergeScript `
        -ProjectPath $resolvedProjectPath `
        -PassThru

    if ($null -eq $brownfieldReportJson) {
        Write-Error 'Brownfield merge analysis failed to produce a report.'
        exit 5
    }

    $brownfieldReport = $brownfieldReportJson | ConvertFrom-Json

    if ($DryRun) {
        $timestamp = [datetime]::UtcNow.ToString('yyyyMMddTHHmmss')
        $dryRunArtifactPath = Join-Path $resolvedProjectPath ".specrew\bootstrap-dry-run-${timestamp}.md"
        $dryRunContent = @(
            "# Bootstrap Dry-Run Report"
            ""
            "**Generated**: $([datetime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss')) UTC"
            "**Project**: $resolvedProjectPath"
            "**Mode**: brownfield"
            "**Status**: $($brownfieldReport.Status)"
            ""
            "## Brownfield Analysis"
            ""
            "- Preserved specs: $($brownfieldReport.PreservedSpecs.Count)"
            "- Preserved roles: $($brownfieldReport.PreservedRoles.Count)"
            "- Preserved ceremonies: $($brownfieldReport.PreservedCeremonies.Count)"
            "- Role conflicts: $($brownfieldReport.RoleConflicts.Count)"
            "- Ceremony conflicts: $($brownfieldReport.CeremonyConflicts.Count)"
            "- Mergeable roles: $($brownfieldReport.MergeableRoles.Count)"
            "- Mergeable ceremonies: $($brownfieldReport.MergeableCeremonies.Count)"
            ""
        )

        if ($brownfieldReport.Conflicts.Count -gt 0) {
            $dryRunContent += "## Conflicts"
            $dryRunContent += ""
            foreach ($conflict in $brownfieldReport.Conflicts) {
                $dryRunContent += "### $($conflict.Type)"
                $dryRunContent += ""
                $dryRunContent += "**Description**: $($conflict.Description)"
                $dryRunContent += ""
                $dryRunContent += "**Resolution**: $($conflict.Resolution)"
                $dryRunContent += ""
            }
        }

        if ($brownfieldReport.Warnings.Count -gt 0) {
            $dryRunContent += "## Warnings"
            $dryRunContent += ""
            foreach ($warning in $brownfieldReport.Warnings) {
                $dryRunContent += "### $($warning.Type)"
                $dryRunContent += ""
                $dryRunContent += "**Description**: $($warning.Description)"
                $dryRunContent += ""
                $dryRunContent += "**Resolution**: $($warning.Resolution)"
                $dryRunContent += ""
            }
        }

        $dryRunContent += "## Planned Actions"
        $dryRunContent += ""
        $dryRunContent += "The following actions would be performed during actual bootstrap:"
        $dryRunContent += ""
        $dryRunContent += "1. Preserve existing specs: $($brownfieldReport.PreservedSpecs -join ', ')"
        if ($brownfieldReport.MergeableRoles.Count -gt 0) {
            $dryRunContent += "2. Merge baseline roles: $($brownfieldReport.MergeableRoles -join ', ')"
        }
        if ($brownfieldReport.MergeableCeremonies.Count -gt 0) {
            $dryRunContent += "3. Merge ceremonies: $($brownfieldReport.MergeableCeremonies -join ', ')"
        }
        $dryRunContent += ""

        $parentDir = Split-Path -Parent $dryRunArtifactPath
        if (-not (Test-Path -LiteralPath $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($dryRunArtifactPath, ($dryRunContent -join [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
        Write-Host "Dry-run report written to: $dryRunArtifactPath" -ForegroundColor Cyan
    }

    if ($brownfieldReport.Conflicts.Count -gt 0) {
        Write-Host 'Brownfield merge conflicts detected:' -ForegroundColor Red
        foreach ($conflict in $brownfieldReport.Conflicts) {
            Write-Host "  - [$($conflict.Type)] $($conflict.Description)" -ForegroundColor Red
            Write-Host "    Resolution: $($conflict.Resolution)" -ForegroundColor Yellow
        }
        Write-Host ''
        Write-Host 'Bootstrap cannot proceed until conflicts are resolved. Run with --dry-run to generate a detailed report, review conflicts, then manually merge or rename conflicting roles/ceremonies before re-running bootstrap.' -ForegroundColor Red
        exit 5
    }

    if ($brownfieldReport.Warnings.Count -gt 0) {
        Write-Host 'Brownfield merge warnings:' -ForegroundColor Yellow
        foreach ($warning in $brownfieldReport.Warnings) {
            Write-Host "  - [$($warning.Type)] $($warning.Description)" -ForegroundColor Yellow
            Write-Host "    Resolution: $($warning.Resolution)" -ForegroundColor Cyan
        }
        Write-Host ''
    }

    Add-Action -Actions $actions -Step 'brownfield-analysis' -Outcome ("status={0}, conflicts={1}, warnings={2}" -f $brownfieldReport.Status, $brownfieldReport.Conflicts.Count, $brownfieldReport.Warnings.Count)
}

Write-Step 'Validating platform dependencies'
$requiredPlatforms = if ($SpecKitExtensionOnly) { @('Spec Kit') } else { @('Spec Kit', 'Squad') }
$versionResults = @(
    Invoke-VersionValidation -ScriptPath $validateVersionsScript -MinimumSpecKitVersion $SpecKitVersion -MinimumSquadVersion $SquadVersion |
        Where-Object { $requiredPlatforms -contains $_.Platform }
)
$missingDependencies = @($versionResults | Where-Object { -not $_.IsInstalled })
$preInstallFailureExitCode = Resolve-DependencyValidationIssue -Results $versionResults -Actions $actions -PreviewOnly:$DryRun -IncludeMissing:$false -AfterInstallAttempt:$false
if ($preInstallFailureExitCode -ne 0 -and -not $DryRun) {
    exit $preInstallFailureExitCode
}

foreach ($dependency in $missingDependencies) {
    Write-Step ("Installing missing dependency: {0}" -f $dependency.Platform)
    try {
        Install-MissingDependency -Dependency $dependency -PreviewOnly:$DryRun
        Add-Action -Actions $actions -Step 'dependency' -Outcome ("{0}: {1}" -f $dependency.Platform, $(if ($DryRun) { 'would install' } else { 'installed' }))
    }
    catch {
        Write-Error $_
        exit 4
    }
}

if ($missingDependencies.Count -gt 0 -and -not $DryRun) {
    $versionResults = @(
        Invoke-VersionValidation -ScriptPath $validateVersionsScript -MinimumSpecKitVersion $SpecKitVersion -MinimumSquadVersion $SquadVersion |
            Where-Object { $requiredPlatforms -contains $_.Platform }
    )
    $postInstallFailureExitCode = Resolve-DependencyValidationIssue -Results $versionResults -Actions $actions -PreviewOnly:$false -IncludeMissing:$true -AfterInstallAttempt:$true
    if ($postInstallFailureExitCode -ne 0) {
        exit $postInstallFailureExitCode
    }
}

$resolvedAgents = @()
if (-not $SpecKitExtensionOnly) {
Write-Step 'Detecting Copilot runtime and delegated agents'
    $agentDetection = Get-AgentDetection -WorkingDirectory $repoRoot
    try {
        $resolvedAgents = Resolve-AgentSelection -DetectedAgents $agentDetection.Agents -DisableAll:$NoAgents -RequestedAgents $Agents
    }
    catch {
        Write-Error $_
        exit 3
    }

    Add-Action -Actions $actions -Step 'agent-detection' -Outcome (Format-AgentSummary -Agents $resolvedAgents)

    if (-not $agentDetection.AuthContextAvailable) {
        Write-Host 'GitHub auth context is unavailable in this environment. Continuing without failing bootstrap.' -ForegroundColor Yellow
    }

    if (-not $agentDetection.DelegatedMetadataAvailable) {
        Write-Host 'Delegated-agent metadata is unavailable in this environment. Continuing without failing bootstrap.' -ForegroundColor Yellow
    }
}

if ($shouldInitializeSpecify) {
    Write-Step 'Running specify init'
    if ($DryRun) {
        Write-Host ("[dry-run] specify init --here --ai copilot --script ps --ignore-agent-tools{0}" -f $(if ($shouldForceSpecifyInit) { ' --force' } else { '' })) -ForegroundColor Yellow
        Add-Action -Actions $actions -Step 'specify-init' -Outcome 'would initialize .specify'
    }
    else {
        $specifyArguments = @('init', '--here', '--ai', 'copilot', '--script', 'ps', '--ignore-agent-tools')
        if ($shouldForceSpecifyInit) {
            $specifyArguments += '--force'
        }

        Write-Step 'Preflighting specify init'
        $specifyPreflight = Test-SpecifyInitPreflight -ProjectPath $resolvedProjectPath -ArgumentList $specifyArguments -SpecKitVersion $SpecKitVersion
        if (-not $specifyPreflight.Ready) {
            Write-Error $specifyPreflight.FailureMessage
            exit 1
        }

        if ($specifyPreflight.Repaired) {
            Add-Action -Actions $actions -Step 'dependency' -Outcome ("Spec Kit: {0}" -f $specifyPreflight.RepairOutcome)
        }

        $specifyInitResult = Invoke-NativeCommandForOutput -FilePath 'specify' -ArgumentList $specifyArguments -WorkingDirectory $resolvedProjectPath
        if ($specifyInitResult.ExitCode -ne 0) {
            $failureSummary = Get-FirstNonEmptyOutputLine -OutputLines $specifyInitResult.Output
            if ($failureSummary) {
                Write-Error ("specify init failed after preflight: {0}" -f $failureSummary)
            }
            else {
                Write-Error 'specify init failed after preflight with no diagnostic output.'
            }

            exit 1
        }

        Add-Action -Actions $actions -Step 'specify-init' -Outcome 'initialized .specify'
    }
}
else {
    if ($hadSpecify) {
        Add-Action -Actions $actions -Step 'specify-init' -Outcome 'preserved existing .specify'
    }
    else {
        Add-Action -Actions $actions -Step 'specify-init' -Outcome 'skipped: brownfield bootstrap does not initialize missing .specify'
    }
}

if (-not $SpecKitExtensionOnly -and $shouldInitializeSquad) {
    Write-Step 'Running squad init'
    $squadInitPlan = Get-SquadInitPlan -ProbeRoot $repoRoot
    if ($squadInitPlan.SupportsNonInteractive) {
        if ($DryRun) {
            Write-Host ("[dry-run] squad {0}" -f ($squadInitPlan.ArgumentList -join ' ')) -ForegroundColor Yellow
            Add-Action -Actions $actions -Step 'squad-init' -Outcome 'would initialize .squad via squad init --non-interactive'
        }
        else {
            Invoke-NativeCommand -FilePath 'squad' -ArgumentList $squadInitPlan.ArgumentList -WorkingDirectory $resolvedProjectPath
            Add-Action -Actions $actions -Step 'squad-init' -Outcome 'initialized .squad via squad init --non-interactive'
        }
    }
    else {
        Write-Step 'Scaffolding .squad fallback'
        Write-Host '[info] squad init --non-interactive is unavailable; using direct .squad scaffold fallback.' -ForegroundColor Yellow
        Initialize-SquadFallbackScaffold -ProjectPath $resolvedProjectPath -PreviewOnly:$DryRun
        Add-Action -Actions $actions -Step 'squad-init' -Outcome ($(if ($DryRun) { 'would initialize .squad via fallback scaffold' } else { 'initialized .squad via fallback scaffold' }))
    }
}
else {
    if (-not $SpecKitExtensionOnly -and $hadSquad) {
        Add-Action -Actions $actions -Step 'squad-init' -Outcome 'preserved existing .squad'
    }
    elseif (-not $SpecKitExtensionOnly) {
        Add-Action -Actions $actions -Step 'squad-init' -Outcome 'skipped: brownfield bootstrap does not initialize missing .squad'
    }
}

Write-Step 'Deploying Specrew Spec Kit extension'
if ($specifySurfaceReady) {
    $specKitDeploymentResult = Invoke-SpecKitExtensionDeployment `
        -ProjectPath $resolvedProjectPath `
        -RepoRoot $repoRoot `
        -FallbackScriptPath $deploySpeckitExtensionScript `
        -PreviewOnly:$DryRun

    $specKitDeploymentAction = if ($null -ne $specKitDeploymentResult -and $specKitDeploymentResult.PSObject.Properties['Action']) {
        [string]$specKitDeploymentResult.Action
    }
    else {
        if ($DryRun) { 'would-install' } else { 'installed' }
    }

    $specKitDeploymentPath = if ($null -ne $specKitDeploymentResult -and $specKitDeploymentResult.PSObject.Properties['Path']) {
        [string]$specKitDeploymentResult.Path
    }
    else {
        Join-Path $resolvedProjectPath '.specify\extensions\specrew-speckit'
    }

    Add-Action -Actions $actions -Step 'spec-kit-extension' -Outcome ("{0}: {1}" -f $specKitDeploymentAction, $specKitDeploymentPath)
}
else {
    Add-Action -Actions $actions -Step 'spec-kit-extension' -Outcome 'skipped: .specify is absent in brownfield workspace'
}

Write-Step 'Deploying bundled project templates'
Invoke-BundledTemplateDeployment `
    -ExecutionLayout $executionLayout `
    -ProjectPath $resolvedProjectPath `
    -ForceRefresh:$Force `
    -SpecKitReady:$specifySurfaceReady `
    -SquadReady:$squadSurfaceReady `
    -HadSpecify:$hadSpecifyContent `
    -HadSquad:$hadSquadContent `
    -HadGitHub:$hadGitHubContent `
    -SpecKitExtensionOnly:$SpecKitExtensionOnly `
    -Actions $actions `
    -PreviewOnly:$DryRun

if (-not $SpecKitExtensionOnly) {
    $resolvedSpecKitVersion = (($versionResults | Where-Object { $_.Platform -eq 'Spec Kit' } | Select-Object -First 1).Version)
    if ([string]::IsNullOrWhiteSpace($resolvedSpecKitVersion)) {
        $resolvedSpecKitVersion = $SpecKitVersion
    }

    $resolvedSquadVersion = (($versionResults | Where-Object { $_.Platform -eq 'Squad' } | Select-Object -First 1).Version)
    if ([string]::IsNullOrWhiteSpace($resolvedSquadVersion)) {
        $resolvedSquadVersion = $SquadVersion
    }

    $specrewManifestContent = Get-Content -LiteralPath $specrewExtensionManifestPath -Raw
    $specrewVersionMatch = [regex]::Match($specrewManifestContent, '(?m)^\s*version:\s*"?(?<version>[^"\r\n]+)')
    $resolvedSpecrewVersion = if ($specrewVersionMatch.Success) { $specrewVersionMatch.Groups['version'].Value.Trim() } else { '0.1.0-dev' }

    Write-Step 'Scaffolding downstream governance'
    $governanceActions = @(
        & $scaffoldGovernanceScript `
            -ProjectPath $resolvedProjectPath `
            -SpecrewVersion $resolvedSpecrewVersion `
            -SpecKitVersion $resolvedSpecKitVersion `
            -SquadVersion $resolvedSquadVersion `
            -BootstrapMode $bootstrapMode `
            -DryRun:$DryRun `
            -PassThru
    )

    foreach ($governanceAction in $governanceActions) {
        Add-Action -Actions $actions -Step 'governance-scaffold' -Outcome ("{0}: {1}" -f $governanceAction.Action, $governanceAction.Path)
    }

    # F-051 US2: per-session file classification (FR-004/005/006). Generate the
    # per-session .gitignore block and untrack any previously committed per-session files.
    Write-Step 'Applying per-session file classification'
    $fileClassificationScript = Join-Path $PSScriptRoot 'internal\file-classification.ps1'
    if (Test-Path -LiteralPath $fileClassificationScript -PathType Leaf) {
        . $fileClassificationScript
        if ($DryRun) {
            Add-Action -Actions $actions -Step 'file-classification' -Outcome 'would update .gitignore with per-session patterns and untrack any tracked per-session files'
        }
        else {
            $addedPatterns = @(Update-GitignoreForSession -ProjectRoot $resolvedProjectPath)
            if ($addedPatterns.Count -gt 0) {
                Add-Action -Actions $actions -Step 'file-classification' -Outcome ("added {0} per-session pattern(s) to .gitignore" -f $addedPatterns.Count)
            }
            else {
                Add-Action -Actions $actions -Step 'file-classification' -Outcome '.gitignore already covers per-session patterns'
            }
            $untracked = @(Remove-TrackedPerSessionFiles -ProjectRoot $resolvedProjectPath)
            if ($untracked.Count -gt 0) {
                Add-Action -Actions $actions -Step 'file-classification' -Outcome ("untracked {0} previously committed per-session file(s) via git rm --cached" -f $untracked.Count)
            }
        }
    }

    Write-Step 'Deploying Squad runtime'
    $iterationConfigPath = Join-Path $resolvedProjectPath '.specrew\iteration-config.yml'
    Set-IterationConfigAgents -IterationConfigPath $iterationConfigPath -Agents $resolvedAgents -Actions $actions -PreviewOnly:$DryRun

    if ($squadSurfaceReady) {
        $squadDeploymentActions = @(
            & $deploySquadRuntimeScript `
                -ProjectPath $resolvedProjectPath `
                -DryRun:$DryRun `
                -PassThru
        )

        foreach ($deploymentAction in $squadDeploymentActions) {
            Add-Action -Actions $actions -Step 'squad-runtime' -Outcome ("{0}: {1}" -f $deploymentAction.Action, $deploymentAction.Path)
        }

        Add-Action -Actions $actions -Step 'slash-surface' -Outcome 'provisioned /specrew-where, /specrew-status, /specrew-update, /specrew-team, /specrew-review, /specrew-help, /specrew-version across .claude/skills, .github/skills, and .agents/skills'
    }
    else {
        Add-Action -Actions $actions -Step 'squad-runtime' -Outcome 'skipped: .squad is absent in brownfield workspace'
    }
}

Write-Step 'Seeding canonical Crew team at .specrew/team/'
# Proposal 108 Slice 9: .specrew/team/agents/<role>.md is the SINGLE SOURCE OF TRUTH for
# the 5-agent baseline + user-added specialists. Each host's Install-<Kind>CrewRuntime reads
# from here at `specrew start --host <kind>` time and translates to the host's native location.
if (Get-Command Initialize-SpecrewTeam -ErrorAction SilentlyContinue) {
    $teamSeed = Initialize-SpecrewTeam -ProjectPath $resolvedProjectPath -DryRun:$DryRun
    foreach ($action in $teamSeed.Actions) {
        $stepName = if ($action.Action -eq 'preserved') { 'team-canonical-preserved' } else { 'team-canonical' }
        Add-Action -Actions $actions -Step $stepName -Outcome ("{0}: {1}" -f $action.Action, $action.Path)
    }
}

# Feature 171 (T017): deploy refocus hooks for detected hosts. This step MUST run
# after the Squad-runtime/skill-surface deployment above — that is what provisions
# the project's .claude/ folder in a greenfield init, and claude detection is
# directory-based (review-caught defect: an earlier anchor ran before .claude
# existed, silently skipping claude on greenfield). The deploy script respects
# recorded opt-outs and fails open: hook problems never fail init.
Write-Step 'Deploying refocus hooks'
if ($specifySurfaceReady) {
    if ($DryRun) {
        Add-Action -Actions $actions -Step 'refocus-hooks' -Outcome 'would deploy refocus hooks for detected hosts'
    }
    else {
        . (Join-Path $repoRoot 'scripts\internal\refocus-deploy-integration.ps1')
        $refocusHookActions = @(Invoke-RefocusHookDeployment -ProjectPath $resolvedProjectPath -DeployScriptPath (Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1'))
        if ($refocusHookActions.Count -eq 0) {
            Add-Action -Actions $actions -Step 'refocus-hooks' -Outcome 'no hook-capable hosts detected'
        }
        foreach ($hookAction in $refocusHookActions) {
            Add-Action -Actions $actions -Step 'refocus-hooks' -Outcome ('{0}: {1}' -f $hookAction.HostKind, $hookAction.Detail)
        }
    }
}
else {
    Add-Action -Actions $actions -Step 'refocus-hooks' -Outcome 'skipped: .specify is absent in brownfield workspace'
}

# FR-025 (iter-8 T049): capture the user-profile expertise dials at init when the profile is ABSENT and the
# session is INTERACTIVE, so hook-driven users (who may never run `specrew start`) still get the expertise
# adaptation in the bootstrap banner. NON-interactive / -Force / CI / piped inits skip silently so
# automation never blocks on Read-Host. Fail-open: a profile-capture error never fails init.
Write-Step 'Setting up the Crew Interaction Profile'
if ($DryRun) {
    Add-Action -Actions $actions -Step 'user-profile' -Outcome 'would capture the Crew Interaction Profile when absent + interactive'
}
else {
    try {
        . (Join-Path $repoRoot 'scripts\internal\user-profile.ps1')
        $profileOutcome = Invoke-SpecrewInitProfileCapture -Force:$Force
        $profileMsg = switch ($profileOutcome) {
            'preserved' { 'existing Crew Interaction Profile preserved (user-level; set once across all projects)' }
            'captured' { 'captured the Crew Interaction Profile (first run)' }
            default { 'skipped: non-interactive or -Force init (set it later with `specrew start` or `/specrew-user-profile`)' }
        }
        Add-Action -Actions $actions -Step 'user-profile' -Outcome $profileMsg
    }
    catch {
        Add-Action -Actions $actions -Step 'user-profile' -Outcome ("skipped: profile capture error ({0})" -f $_.Exception.Message)
    }
}

Write-Step 'Configuring git for boundary-commit hygiene'
# F-040 dogfooding fix (calc-v2 + tip-calc 2026-05-23): when the project is in a git repo,
# silence the LF/CRLF warning wall that otherwise dumps 150+ lines on the user during
# `git add` for the very first boundary commit. Use `core.safecrlf=false` (warnings off) +
# `core.autocrlf=true` on Windows / `input` on POSIX (right normalization). Both are scoped
# to THIS repo only via `git config --local`, so we don't touch the user's global config.
$gitRepoCheck = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.git') -PathType Container
if ($gitRepoCheck -and -not $DryRun) {
    try {
        & git -C $resolvedProjectPath config --local core.safecrlf false 2>$null
        $global:LASTEXITCODE = 0
        $autocrlfValue = if ($IsWindows -or $env:OS -eq 'Windows_NT') { 'true' } else { 'input' }
        & git -C $resolvedProjectPath config --local core.autocrlf $autocrlfValue 2>$null
        $global:LASTEXITCODE = 0
        Add-Action -Actions $actions -Step 'git-config' -Outcome ("set local core.safecrlf=false + core.autocrlf={0} to suppress harmless CRLF warnings on first commit" -f $autocrlfValue)
    }
    catch {
        Add-Action -Actions $actions -Step 'git-config' -Outcome ("skipped (git config failed: {0})" -f $_.Exception.Message)
    }
}
elseif ($gitRepoCheck -and $DryRun) {
    Add-Action -Actions $actions -Step 'git-config' -Outcome 'would set local core.safecrlf + core.autocrlf to suppress CRLF warnings'
}
else {
    Add-Action -Actions $actions -Step 'git-config' -Outcome 'skipped (no .git directory found; this is not a git repo yet)'
}

Write-Step 'Validating bootstrapped project state'
if ($DryRun) {
    Add-Action -Actions $actions -Step 'bootstrap-validation' -Outcome 'would validate .specify templates, .squad agents, .github workflows, and .github/agents/squad.agent.md'
}
else {
    $bootstrapValidation = Test-BootstrappedProjectState -ProjectPath $resolvedProjectPath -SpecKitExtensionOnly:$SpecKitExtensionOnly
    if (-not $bootstrapValidation.Succeeded) {
        foreach ($failure in $bootstrapValidation.Failures) {
            Write-Error $failure -ErrorAction Continue
        }

        exit 1
    }

    Add-Action -Actions $actions -Step 'bootstrap-validation' -Outcome 'validated .specify templates, .squad agents, .github workflows, and .github/agents/squad.agent.md'
    if (-not $SpecKitExtensionOnly) {
        $finalSkillCatalogState = Get-SpecrewSkillCatalogState -ProjectPath $resolvedProjectPath
        if ($finalSkillCatalogState.HasMissingRoots) {
            foreach ($missingRoot in @($finalSkillCatalogState.MissingRoots)) {
                Write-Error ("Missing required skill catalog directory after deployment: {0}" -f $missingRoot.Path) -ErrorAction Continue
            }

            exit 1
        }

        Add-Action -Actions $actions -Step 'skill-catalog' -Outcome 'validated .claude/skills, .github/skills, and .agents/skills'
    }
}

Write-BootstrapSummary -Actions $actions -DryRunMode:$DryRun -ProjectPath $resolvedProjectPath -ShowGuidance:(-not $SpecKitExtensionOnly -and $squadSurfaceReady)

if (-not $DryRun) {
    $psGalleryUpdateWarning = Get-PSGalleryUpdateWarning -ProjectRoot $resolvedProjectPath -SkipCheck:$SkipUpdateCheck
    if (-not [string]::IsNullOrWhiteSpace($psGalleryUpdateWarning)) {
        Write-Output ("WARN: {0}" -f $psGalleryUpdateWarning)
    }
}

exit 0
