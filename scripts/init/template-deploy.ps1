# Template deployment helpers for specrew-init.ps1 (extracted via Proposal 108 Slice 3)
#
# Depends on: scripts/init/_utilities.ps1 (Ensure-DirectoryExists, Get-SpecrewExecutionLayout, Add-Action)
#
# Functions:
#   - Copy-TemplateTree                Recursive template copy with diff/preserve semantics
#   - Invoke-BundledTemplateDeployment Deploy .specify/.squad/.github trees from templates/
#   - Test-BootstrappedProjectState    Validate the .specify/.squad/.github expected layout exists

Set-StrictMode -Version Latest

function Copy-TemplateTree {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,

        [Parameter(Mandatory = $true)]
        [bool]$OverwriteExisting,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly,

        [string[]]$ExcludedRelativePaths = @()
    )

    if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
        throw "Missing bundled template source '$SourceRoot'."
    }

    Ensure-DirectoryExists -Path $TargetRoot -PreviewOnly:$PreviewOnly

    $copied = 0
    $updated = 0
    $preserved = 0
    $excluded = @{}
    foreach ($path in @($ExcludedRelativePaths)) {
        if (-not [string]::IsNullOrWhiteSpace($path)) { $excluded[$path.Replace('\', '/')] = $true }
    }
    $sourceFiles = @(Get-ChildItem -LiteralPath $SourceRoot -File -Recurse | Sort-Object FullName | Where-Object {
            $relative = [IO.Path]::GetRelativePath($SourceRoot, $_.FullName).Replace('\', '/')
            -not $excluded.ContainsKey($relative)
        })

    foreach ($sourceFile in $sourceFiles) {
        $relativePath = [System.IO.Path]::GetRelativePath($SourceRoot, $sourceFile.FullName)
        $targetPath = Join-Path -Path $TargetRoot -ChildPath $relativePath
        $parent = Split-Path -Parent $targetPath
        if (-not [string]::IsNullOrWhiteSpace($parent)) {
            Ensure-DirectoryExists -Path $parent -PreviewOnly:$PreviewOnly
        }

        if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
            if (-not $OverwriteExisting) {
                $preserved++
                continue
            }

            $sourceContent = Get-Content -LiteralPath $sourceFile.FullName -Raw
            $targetContent = Get-Content -LiteralPath $targetPath -Raw
            if ($sourceContent -eq $targetContent) {
                $preserved++
                continue
            }

            if (-not $PreviewOnly) {
                Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetPath -Force
            }

            $updated++
            continue
        }

        if (-not $PreviewOnly) {
            Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetPath -Force
        }

        $copied++
    }

    return [pscustomobject]@{
        Copied    = $copied
        Updated   = $updated
        Preserved = $preserved
        Total     = $sourceFiles.Count
    }
}

function Get-SpecrewTemplateDeploymentProvider {
    # Init needs to distinguish an UNSET provider (greenfield: deploy the GitHub-ready generic
    # methodology gate) from an explicitly non-GitHub forge (do not deploy GitHub Actions YAML).
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $path = Join-Path $ProjectPath '.specrew/repository-governance.yml'
    if (-not [IO.File]::Exists($path)) { return '' }
    function ConvertFrom-ProviderScalar([string]$Value) {
        $withoutComment = @($Value -split '#', 2)[0].Trim()
        return $withoutComment.Trim([char[]]@('"', "'")).ToLowerInvariant()
    }
    $block = ''
    foreach ($line in [IO.File]::ReadAllLines($path)) {
        if ($line -match '^(?<key>[a-z_]+):\s*(?<value>.*)$') {
            $block = $Matches.key
            if ($block -ceq 'provider' -and -not [string]::IsNullOrWhiteSpace($Matches.value)) {
                return ConvertFrom-ProviderScalar -Value $Matches.value
            }
            continue
        }
        if ($block -ceq 'provider' -and $line -match '^\s+name:\s*(?<value>[^#]+)') {
            return ConvertFrom-ProviderScalar -Value $Matches.value
        }
        if ($block -ceq 'repository_governance' -and $line -match '^\s{2}provider:\s*(?<value>[^#]+)') {
            return ConvertFrom-ProviderScalar -Value $Matches.value
        }
    }
    return ''
}

function Invoke-BundledTemplateDeployment {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$ExecutionLayout,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [bool]$ForceRefresh,

        [Parameter(Mandatory = $true)]
        [bool]$SpecKitReady,

        [Parameter(Mandatory = $true)]
        [bool]$SquadReady,

        [Parameter(Mandatory = $true)]
        [bool]$HadSpecify,

        [Parameter(Mandatory = $true)]
        [bool]$HadSquad,

        [Parameter(Mandatory = $true)]
        [bool]$HadGitHub,

        [Parameter(Mandatory = $true)]
        [bool]$SpecKitExtensionOnly,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    if ([string]::IsNullOrWhiteSpace($ExecutionLayout.TemplateRoot)) {
        throw 'Bundled templates are unavailable for bootstrap.'
    }

    Add-Action -Actions $Actions -Step 'template-source' -Outcome ("{0}: {1}" -f $ExecutionLayout.Mode, $ExecutionLayout.TemplateRoot)

    $deployments = [System.Collections.ArrayList]::new()
    if ($SpecKitReady) {
        $null = $deployments.Add([pscustomobject]@{
                Name        = '.specify'
                SourceRoot  = Join-Path -Path $ExecutionLayout.TemplateRoot -ChildPath 'specify'
                TargetRoot  = Join-Path -Path $ProjectPath -ChildPath '.specify'
                HadExisting = $HadSpecify
            })
    }

    if (-not $SpecKitExtensionOnly -and $SquadReady) {
        $null = $deployments.Add([pscustomobject]@{
                Name        = '.squad'
                SourceRoot  = Join-Path -Path $ExecutionLayout.TemplateRoot -ChildPath 'squad'
                TargetRoot  = Join-Path -Path $ProjectPath -ChildPath '.squad'
                HadExisting = $HadSquad
            })
    }

    if (-not $SpecKitExtensionOnly) {
        $provider = Get-SpecrewTemplateDeploymentProvider -ProjectPath $ProjectPath
        $githubExclusions = if ([string]::IsNullOrWhiteSpace($provider) -or $provider -ceq 'github') {
            @()
        }
        else {
            @(Get-ChildItem -LiteralPath (Join-Path $ExecutionLayout.TemplateRoot 'github/workflows') -File |
                    ForEach-Object { 'workflows/{0}' -f $_.Name })
        }
        if (-not [string]::IsNullOrWhiteSpace($provider) -and $provider -cne 'github') {
            Add-Action -Actions $Actions -Step 'provider-gate' -Outcome (
                "skipped GitHub Actions workflows for recorded provider '{0}'; run governance manually: pwsh -File ./.specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath ." -f $provider
            )
        }
        $null = $deployments.Add([pscustomobject]@{
                Name        = '.github'
                SourceRoot  = Join-Path -Path $ExecutionLayout.TemplateRoot -ChildPath 'github'
                TargetRoot  = Join-Path -Path $ProjectPath -ChildPath '.github'
                HadExisting = $HadGitHub
                Exclusions  = @($githubExclusions)
            })
    }

    foreach ($deployment in $deployments) {
        if ($deployment.HadExisting -and -not $ForceRefresh) {
            Add-Action -Actions $Actions -Step 'template-copy' -Outcome ("preserved existing {0}; re-run with -Force to refresh bundled templates" -f $deployment.Name)
            continue
        }

        $exclusions = if ($deployment.PSObject.Properties['Exclusions']) { @($deployment.Exclusions) } else { @() }
        $result = Copy-TemplateTree -SourceRoot $deployment.SourceRoot -TargetRoot $deployment.TargetRoot -OverwriteExisting:$ForceRefresh -PreviewOnly:$PreviewOnly -ExcludedRelativePaths $exclusions
        $verb = if ($PreviewOnly) { 'would-sync' } else { 'synced' }
        Add-Action -Actions $Actions -Step 'template-copy' -Outcome ("{0} {1} from {2} ({3} new, {4} updated, {5} preserved)" -f $verb, $deployment.Name, $deployment.SourceRoot, $result.Copied, $result.Updated, $result.Preserved)
    }
}

function Test-BootstrappedProjectState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [bool]$SpecKitExtensionOnly
    )

    $failures = [System.Collections.Generic.List[string]]::new()
    $expectedSpecifyFiles = @(
        'agent-file-template.md',
        'checklist-template.md',
        'constitution-template.md',
        'plan-template.md',
        'spec-template.md',
        'tasks-template.md'
    )

    $specifyTemplatesRoot = Join-Path -Path $ProjectPath -ChildPath '.specify'
    $specifyTemplatesRoot = Join-Path -Path $specifyTemplatesRoot -ChildPath 'templates'
    if (-not (Test-Path -LiteralPath $specifyTemplatesRoot -PathType Container)) {
        $failures.Add("Missing required template directory '$specifyTemplatesRoot'.")
    }
    else {
        foreach ($expectedFile in $expectedSpecifyFiles) {
            $expectedPath = Join-Path -Path $specifyTemplatesRoot -ChildPath $expectedFile
            if (-not (Test-Path -LiteralPath $expectedPath -PathType Leaf)) {
                $failures.Add("Missing required Spec Kit template '$expectedPath'.")
            }
        }
    }

    if (-not $SpecKitExtensionOnly) {
        $squadAgentsRoot = Join-Path -Path $ProjectPath -ChildPath '.squad'
        $squadAgentsRoot = Join-Path -Path $squadAgentsRoot -ChildPath 'agents'
        if (-not (Test-Path -LiteralPath $squadAgentsRoot -PathType Container)) {
            $failures.Add("Missing required Squad agents directory '$squadAgentsRoot'.")
        }

        $workflowRoot = Join-Path -Path $ProjectPath -ChildPath '.github'
        $coordinatorPromptPath = Join-Path -Path $workflowRoot -ChildPath 'agents\squad.agent.md'
        $workflowRoot = Join-Path -Path $workflowRoot -ChildPath 'workflows'
        if (-not (Test-Path -LiteralPath $workflowRoot -PathType Container)) {
            $failures.Add("Missing required workflow directory '$workflowRoot'.")
        }
        else {
            $workflowCount = @(Get-ChildItem -LiteralPath $workflowRoot -File -ErrorAction SilentlyContinue).Count
            if ($workflowCount -lt 1) {
                $failures.Add("Expected at least one workflow under '$workflowRoot'.")
            }
        }

        if (-not (Test-Path -LiteralPath $coordinatorPromptPath -PathType Leaf)) {
            $failures.Add("Missing required coordinator prompt '$coordinatorPromptPath'.")
        }
    }

    return [pscustomobject]@{
        Succeeded = ($failures.Count -eq 0)
        Failures  = @($failures)
    }
}

