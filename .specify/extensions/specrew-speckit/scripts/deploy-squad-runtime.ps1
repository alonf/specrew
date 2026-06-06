[CmdletBinding()]
param(
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

function Add-DeploymentAction {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $null = $Actions.Add([pscustomobject]@{
            Action = $Action
            Path   = $Path
        })
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (Test-Path -LiteralPath $Path) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved-directory' -Path $Path
        return
    }

    Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-create-directory' } else { 'created-directory' }) -Path $Path
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-MissingFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (Test-Path -LiteralPath $TargetPath) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
        return
    }

    Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-create' } else { 'created' }) -Path $TargetPath
    if (-not $DryRun) {
        $parent = Split-Path -Parent $TargetPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
    }
}

function Set-ManagedFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-create' } else { 'created' }) -Path $TargetPath
        if (-not $DryRun) {
            $parent = Split-Path -Parent $TargetPath
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }

            [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
        }

        return
    }

    $existingContent = Get-Content -LiteralPath $TargetPath -Raw
    if ($existingContent -eq $Content) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
        return
    }

    Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-update' } else { 'updated' }) -Path $TargetPath
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
    }
}

function Get-ManagedBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    return @(
        "<!-- >>> specrew-managed $Name >>> -->"
        $Content.Trim()
        "<!-- <<< specrew-managed $Name <<< -->"
    ) -join [Environment]::NewLine
}

function Remove-LegacyManagedContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BlockName,

        [Parameter(Mandatory = $true)]
        [string]$ExistingContent
    )

    $updatedContent = $ExistingContent
    $migrated = $false

    switch ($BlockName) {
        'ceremonies' {
            $legacyPattern = '(?ms)\s*<!-- specrew:ceremony:[^>]+:start -->.*?<!-- specrew:ceremony:[^>]+:end -->\s*'
            $replacement = [regex]::Replace($updatedContent, $legacyPattern, [Environment]::NewLine + [Environment]::NewLine)
            if ($replacement -ne $updatedContent) {
                $updatedContent = $replacement
                $migrated = $true
            }
        }
        'directives' {
            $legacyPattern = '(?ms)\s*## Specrew Directives\s*(?:\r?\n)+(?:<!-- specrew:directive:[^>]+:start -->.*?<!-- specrew:directive:[^>]+:end -->\s*)+'
            $replacement = [regex]::Replace($updatedContent, $legacyPattern, [Environment]::NewLine + [Environment]::NewLine)
            if ($replacement -ne $updatedContent) {
                $updatedContent = $replacement
                $migrated = $true
            }
        }
        'baseline-roles' {
            $legacyRows = @(
                'Spec Steward',
                'Planner',
                'Implementer',
                'Reviewer',
                'Retro Facilitator'
            ) | ForEach-Object { [regex]::Escape($_) }
            $legacyRowPattern = '(?m)^\|\s*[^|]+\s*\|\s*(?:' + ($legacyRows -join '|') + ')\s*\|.*\r?\n?'
            $replacement = [regex]::Replace($updatedContent, $legacyRowPattern, '')
            if ($replacement -ne $updatedContent) {
                $updatedContent = $replacement
                $migrated = $true
            }
        }
    }

    if ($migrated) {
        $updatedContent = [regex]::Replace($updatedContent, '(?m)(\r?\n){3,}', [Environment]::NewLine + [Environment]::NewLine)
        $updatedContent = $updatedContent.TrimEnd()
        if (-not [string]::IsNullOrWhiteSpace($updatedContent)) {
            $updatedContent += [Environment]::NewLine
        }
    }

    return [pscustomobject]@{
        Migrated = $migrated
        Content  = $updatedContent
    }
}

function Set-ManagedBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$BlockName,

        [Parameter(Mandatory = $true)]
        [string]$ManagedContent,

        [string]$BaseContentIfMissing = '',

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    $managedBlock = Get-ManagedBlock -Name $BlockName -Content $ManagedContent
    $startMarker = [regex]::Escape("<!-- >>> specrew-managed $BlockName >>> -->")
    $endMarker = [regex]::Escape("<!-- <<< specrew-managed $BlockName <<< -->")
    $managedPattern = "(?ms)\s*$startMarker.*?$endMarker\s*"

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-create' } else { 'created' }) -Path $TargetPath
        if (-not $DryRun) {
            $parent = Split-Path -Parent $TargetPath
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }

            $parts = @()
            if (-not [string]::IsNullOrWhiteSpace($BaseContentIfMissing)) {
                $parts += $BaseContentIfMissing.TrimEnd()
            }

            $parts += $managedBlock
            $content = ($parts -join ([Environment]::NewLine + [Environment]::NewLine)) + [Environment]::NewLine
            [System.IO.File]::WriteAllText($TargetPath, $content, [System.Text.UTF8Encoding]::new($false))
        }

        return
    }

    $existingContent = Get-Content -LiteralPath $TargetPath -Raw
    $legacyMigration = Remove-LegacyManagedContent -BlockName $BlockName -ExistingContent $existingContent
    if ($legacyMigration.Migrated) {
        $existingContent = $legacyMigration.Content
    }

    if ($existingContent -match $managedPattern) {
        $updatedContent = [regex]::Replace($existingContent, $managedPattern, ([Environment]::NewLine + [Environment]::NewLine + $managedBlock + [Environment]::NewLine + [Environment]::NewLine))
    }
    else {
        $trimmedExistingContent = $existingContent.TrimEnd()
        if ([string]::IsNullOrWhiteSpace($trimmedExistingContent)) {
            $updatedContent = $managedBlock
        }
        else {
            $updatedContent = $trimmedExistingContent + [Environment]::NewLine + [Environment]::NewLine + $managedBlock
        }
    }

    $updatedContent = $updatedContent.TrimEnd() + [Environment]::NewLine
    if ($updatedContent -eq $existingContent) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
        return
    }

    Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-update' } else { 'updated' }) -Path $TargetPath
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($TargetPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
    }
}

function Set-ManagedTableRows {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$TableSectionHeader,

        [Parameter(Mandatory = $true)]
        [string[]]$Rows,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        return
    }

    $existingContent = Get-Content -LiteralPath $TargetPath -Raw
    
    $escapedHeader = [regex]::Escape($TableSectionHeader)
    $tablePattern = "($escapedHeader[^\r\n]*\r?\n(?:.*?\r?\n)*?\|[^\r\n]+\|\r?\n\|[\s\-|]+\|\r?\n)"
    
    if ($existingContent -match $tablePattern) {
        $headerAndSeparator = $Matches[1]
        
        $index = $existingContent.IndexOf($headerAndSeparator)
        if ($index -lt 0) { return }
        
        $postTableContent = $existingContent.Substring($index + $headerAndSeparator.Length)
        
        $existingBodyLines = [System.Collections.Generic.List[string]]::new()
        $lines = $postTableContent -split '\r?\n'
        $tableEndIndex = 0
        foreach ($line in $lines) {
            if ($line -match '^\s*\|') {
                $null = $existingBodyLines.Add($line)
                $tableEndIndex++
            }
            else {
                break
            }
        }
        
        $trailingLines = $lines[$tableEndIndex..($lines.Count - 1)]
        $trailingContent = $trailingLines -join [Environment]::NewLine
        
        $newKeys = @{}
        foreach ($newRow in $Rows) {
            $key = Get-TableRowKey -RowLine $newRow
            if ($key) {
                $newKeys[$key] = $newRow
            }
        }
        
        $mergedBodyLines = [System.Collections.Generic.List[string]]::new()
        foreach ($newRow in $Rows) {
            $null = $mergedBodyLines.Add($newRow)
        }
        
        foreach ($existingRow in $existingBodyLines) {
            $key = Get-TableRowKey -RowLine $existingRow
            if ($key -and -not $newKeys.ContainsKey($key)) {
                $null = $mergedBodyLines.Add($existingRow)
            }
        }
        
        $preContent = $existingContent.Substring(0, $index)
        $bodyContent = ($mergedBodyLines | ForEach-Object { $_ + [Environment]::NewLine }) -join ''
        
        $updatedContent = $preContent + $headerAndSeparator + $bodyContent
        if (-not [string]::IsNullOrWhiteSpace($trailingContent)) {
            $updatedContent += $trailingContent
        }
        
        if ($updatedContent -ne $existingContent) {
            Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-update' } else { 'updated' }) -Path $TargetPath
            if (-not $DryRun) {
                [System.IO.File]::WriteAllText($TargetPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
            }
        }
        else {
            Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
        }
    }
    else {
        Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
    }
}

function Get-TableRowKey {
    param([string]$RowLine)
    $parts = $RowLine -split '\|'
    if ($parts.Count -gt 1) {
        return $parts[1].Trim()
    }
    return $null
}

function Get-DirectiveDeployment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectivePath
    )

    $content = Get-Content -LiteralPath $DirectivePath -Raw
    $directiveTitlePattern = [regex]::new('^\s*#\s*Directive:\s*', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $content = $directiveTitlePattern.Replace($content, '## ', 1)
    $content = [regex]::Replace($content, '(?ms)\r?\n---\r?\n\r?\n\*\*Deployment\*\*:.*$', '')
    return $content.Trim()
}

function Get-BaselineRoleDefinitions {
    return @(
        [pscustomobject]@{
            Name           = 'Spec Steward'
            AgentDirectory = 'spec-steward'
            TemplatePath   = 'agents/spec-steward/charter.md'
            DirectivePaths = @('directives/spec-authority.md')
        }
        [pscustomobject]@{
            Name           = 'Planner'
            AgentDirectory = 'planner'
            TemplatePath   = 'agents/planner/charter.md'
            DirectivePaths = @('directives/spec-authority.md', 'directives/traceability.md')
        }
        [pscustomobject]@{
            Name           = 'Implementer'
            AgentDirectory = 'implementer'
            TemplatePath   = 'agents/implementer/charter.md'
            DirectivePaths = @('directives/spec-authority.md', 'directives/drift-reporting.md')
        }
        [pscustomobject]@{
            Name           = 'Reviewer'
            AgentDirectory = 'reviewer'
            TemplatePath   = 'agents/reviewer/charter.md'
            DirectivePaths = @('directives/spec-authority.md', 'directives/drift-reporting.md')
        }
        [pscustomobject]@{
            Name           = 'Retro Facilitator'
            AgentDirectory = 'retro-facilitator'
            TemplatePath   = 'agents/retro-facilitator/charter.md'
            DirectivePaths = @('directives/spec-authority.md')
        }
    )
}

function Get-ActiveSkillRoots {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    return @(
        [pscustomobject]@{ Name = 'claude'; Path = Join-Path $ProjectPath '.claude\skills' }
        [pscustomobject]@{ Name = 'cursor'; Path = Join-Path $ProjectPath '.cursor\rules' }
        [pscustomobject]@{ Name = 'github'; Path = Join-Path $ProjectPath '.github\skills' }
        [pscustomobject]@{ Name = 'agents'; Path = Join-Path $ProjectPath '.agents\skills' }
    )
}

function Get-SlashCommandSkillCatalog {
    return @(
        [pscustomobject]@{ Directory = 'specrew-help'; Name = 'help'; LegacySlashCommand = '/specrew.help' }
        [pscustomobject]@{ Directory = 'specrew-review'; Name = 'review'; LegacySlashCommand = '/specrew.review' }
        [pscustomobject]@{ Directory = 'specrew-status'; Name = 'status'; LegacySlashCommand = '/specrew.status' }
        [pscustomobject]@{ Directory = 'specrew-team'; Name = 'team'; LegacySlashCommand = '/specrew.team' }
        [pscustomobject]@{ Directory = 'specrew-update'; Name = 'update'; LegacySlashCommand = '/specrew.update' }
        [pscustomobject]@{ Directory = 'specrew-version'; Name = 'version'; LegacySlashCommand = '/specrew.version' }
        [pscustomobject]@{ Directory = 'specrew-where'; Name = 'where'; LegacySlashCommand = '/specrew.where' }
    )
}

function Get-ManagedSkillMarkerContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillDirectory
    )

    return @(
        'schema: v1'
        'owner: specrew'
        'kind: project-skill'
        ('directory: {0}' -f $SkillDirectory)
    ) -join [Environment]::NewLine
}

function Get-LegacySpecrewSkillDefinitions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillsTemplateRoot
    )

    $definitions = New-Object System.Collections.Generic.List[object]

    $genericSkillFiles = @(Get-ChildItem -LiteralPath $SkillsTemplateRoot -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' } | Sort-Object Name)
    foreach ($skillFile in $genericSkillFiles) {
        $definitions.Add([pscustomobject]@{
                Directory      = 'specrew-{0}' -f $skillFile.BaseName
                CurrentContent = Get-Content -LiteralPath $skillFile.FullName -Raw
                Kind           = 'generic'
                LegacyContent  = Get-Content -LiteralPath $skillFile.FullName -Raw
            })
    }

    foreach ($slashSkill in Get-SlashCommandSkillCatalog) {
        $skillSourcePath = Join-Path (Join-Path $SkillsTemplateRoot $slashSkill.Directory) 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillSourcePath -PathType Leaf)) {
            continue
        }

        $definitions.Add([pscustomobject]@{
                Directory          = $slashSkill.Directory
                CurrentContent     = Get-Content -LiteralPath $skillSourcePath -Raw
                Kind               = 'slash-command'
                LegacySlashCommand = $slashSkill.LegacySlashCommand
            })
    }

    return $definitions.ToArray()
}

function Test-IsManagedLegacySkillDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillDirectoryPath,

        [Parameter(Mandatory = $true)]
        [psobject]$Definition
    )

    $managedMarkerPath = Join-Path $SkillDirectoryPath '.specrew-managed'
    if (Test-Path -LiteralPath $managedMarkerPath -PathType Leaf) {
        return $true
    }

    $skillPath = Join-Path $SkillDirectoryPath 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) {
        return $false
    }

    $content = Get-Content -LiteralPath $skillPath -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        return $false
    }

    # Feature 160 (Proposal 161): provenance-by-content. A dir whose SKILL.md
    # text equals this definition's canonical content — ordinal comparison of the
    # DECODED text (line endings are significant; file encoding/BOM is not part
    # of the contract) — is Specrew-managed even without a marker, including when
    # canonical content carries front matter, which the heuristic below would
    # otherwise classify as user-edited. An exact text match means there are no
    # user customizations, so recognizing it as managed cannot lose user data.
    # The marker (checked above) remains the primary signal; this recovers
    # marker-less legacy dirs that still hold our canonical content. Genuinely
    # user-edited content does not match and stays preserved.
    foreach ($propertyName in @('CurrentContent', 'LegacyContent')) {
        if ($Definition.PSObject.Properties.Name -contains $propertyName) {
            $canonical = [string]$Definition.$propertyName
            if (-not [string]::IsNullOrEmpty($canonical) -and [System.String]::Equals($content, $canonical, [System.StringComparison]::Ordinal)) {
                return $true
            }
        }
    }

    if ($content.TrimStart().StartsWith('---', [System.StringComparison]::Ordinal)) {
        return $false
    }

    if ($Definition.Kind -eq 'generic') {
        if ($content -eq $Definition.LegacyContent) {
            return $true
        }

        # Feature 161 (CONFIRMED, harness scenario S7): Specrew v0.21.0–v0.23.0
        # deployed generic skills into .copilot/skills with NO sidecar marker and
        # NO front matter, and generic template content drifted from v0.26.0 —
        # so the equality check above compares stale legacy content against the
        # CURRENT template, fails, and froze Specrew's own dirs as "user-edited"
        # forever. Recognize the pre-marker generic legacy signature instead:
        # content that has already failed the front-matter check (above) and
        # carries this skill's own directory-name heading plus the structural
        # **Type**/**Schema** lines is Specrew's drifted legacy content, not
        # user-authored work. Anything else still falls through to preserve.
        return (
            $content.StartsWith('# {0}' -f $Definition.Directory, [System.StringComparison]::Ordinal) -and
            $content.Contains('**Type**: ') -and
            $content.Contains('**Schema**: v1')
        )
    }

    $legacyNamespaceLine = '**Namespace**: ' + [char]96 + '/specrew' + [char]96
    $legacyCommandLine = '**Canonical command**: ' + [char]96 + $Definition.LegacySlashCommand + [char]96

    return (
        $content.StartsWith('# {0}' -f $Definition.Directory, [System.StringComparison]::Ordinal) -and
        $content.Contains($legacyNamespaceLine) -and
        $content.Contains($legacyCommandLine)
    )
}

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
$extensionRoot = Split-Path -Parent $PSScriptRoot
$templateRoot = Join-Path $extensionRoot 'squad-templates'
$legacySkillsRoot = Join-Path $resolvedProjectPath '.copilot\skills'
$squadRoot = Join-Path $resolvedProjectPath '.squad'
$squadAgentsRoot = Join-Path $squadRoot 'agents'
$coordinatorPromptPath = Join-Path $resolvedProjectPath '.github\agents\squad.agent.md'
$ceremoniesPath = Join-Path $squadRoot 'ceremonies.md'
$teamPath = Join-Path $squadRoot 'team.md'
$actions = [System.Collections.ArrayList]::new()

if (-not (Test-Path -LiteralPath $squadRoot) -and -not $DryRun) {
    throw "Squad must be initialized before deploying runtime surfaces. Missing '$squadRoot'."
}

if ($DryRun -and -not (Test-Path -LiteralPath $squadRoot)) {
    Add-DeploymentAction -Actions $actions -Action 'would-create-directory' -Path $squadRoot
}

Ensure-Directory -Path $squadAgentsRoot -Actions $actions
Ensure-Directory -Path (Join-Path $squadRoot 'casting') -Actions $actions

$skillsTemplateRoot = Join-Path $templateRoot 'skills'
$activeSkillRoots = @(Get-ActiveSkillRoots -ProjectPath $resolvedProjectPath)
$managedSkillDefinitions = @(Get-LegacySpecrewSkillDefinitions -SkillsTemplateRoot $skillsTemplateRoot)

if (Test-Path -LiteralPath $legacySkillsRoot -PathType Container) {
    $legacySkillDirectories = @(Get-ChildItem -LiteralPath $legacySkillsRoot -Directory | Where-Object { $_.Name -like 'specrew-*' } | Sort-Object Name)
    foreach ($legacySkillDirectory in $legacySkillDirectories) {
        $definition = $managedSkillDefinitions | Where-Object { $_.Directory -eq $legacySkillDirectory.Name } | Select-Object -First 1
        if ($null -eq $definition) {
            Add-DeploymentAction -Actions $actions -Action 'preserved-legacy-unmanaged-skill' -Path $legacySkillDirectory.FullName
            continue
        }

        if (Test-IsManagedLegacySkillDirectory -SkillDirectoryPath $legacySkillDirectory.FullName -Definition $definition) {
            Add-DeploymentAction -Actions $actions -Action $(if ($DryRun) { 'would-remove-legacy-managed-skill' } else { 'removed-legacy-managed-skill' }) -Path $legacySkillDirectory.FullName
            if (-not $DryRun) {
                Remove-Item -LiteralPath $legacySkillDirectory.FullName -Recurse -Force
            }
            continue
        }

        Add-DeploymentAction -Actions $actions -Action 'preserved-legacy-unmanaged-skill' -Path $legacySkillDirectory.FullName
    }
}

foreach ($activeSkillRoot in $activeSkillRoots) {
    Ensure-Directory -Path $activeSkillRoot.Path -Actions $actions

    foreach ($definition in $managedSkillDefinitions) {
        $skillDirectoryPath = Join-Path $activeSkillRoot.Path $definition.Directory
        Ensure-Directory -Path $skillDirectoryPath -Actions $actions
        Set-ManagedFile -TargetPath (Join-Path $skillDirectoryPath 'SKILL.md') -Content $definition.CurrentContent -Actions $actions
        Set-ManagedFile -TargetPath (Join-Path $skillDirectoryPath '.specrew-managed') -Content (Get-ManagedSkillMarkerContent -SkillDirectory $definition.Directory) -Actions $actions
    }
}

$coordinatorGovernancePath = Join-Path $templateRoot 'coordinator\specrew-governance.md'
if (-not (Test-Path -LiteralPath $coordinatorGovernancePath -PathType Leaf)) {
    throw "Missing coordinator governance template: $coordinatorGovernancePath"
}

if (Test-Path -LiteralPath $coordinatorPromptPath -PathType Leaf) {
    $coordinatorGovernanceContent = Get-Content -LiteralPath $coordinatorGovernancePath -Raw
    Set-ManagedBlock -TargetPath $coordinatorPromptPath -BlockName 'specrew-governance' -ManagedContent $coordinatorGovernanceContent -Actions $actions
}
else {
    Add-DeploymentAction -Actions $actions -Action 'skipped' -Path $coordinatorPromptPath
}

$ceremonyContent = (@(
        foreach ($ceremonyPath in @(
                (Join-Path $templateRoot 'ceremonies\planning.md'),
                (Join-Path $templateRoot 'ceremonies\review-demo.md')
            )) {
            (Get-Content -LiteralPath $ceremonyPath -Raw).Trim()
        }
    ) -join ([Environment]::NewLine + [Environment]::NewLine + '---' + [Environment]::NewLine + [Environment]::NewLine))
Set-ManagedBlock -TargetPath $ceremoniesPath -BlockName 'ceremonies' -ManagedContent $ceremonyContent -BaseContentIfMissing '# Ceremonies' -Actions $actions

$baselineRoles = @(Get-BaselineRoleDefinitions)

# Add explicit team status metadata to signal Squad readiness
$teamStatusBlock = @"
**Team Status**: configured  
**Baseline Roles**: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator  
**Configuration**: Specrew-managed baseline
"@
Set-ManagedBlock -TargetPath $teamPath -BlockName 'team-status' -ManagedContent $teamStatusBlock -BaseContentIfMissing '# Squad Team' -Actions $actions

# Update team.md Members table with baseline roles
$membersTableRows = @()
foreach ($baselineRole in $baselineRoles) {
    $membersTableRows += ('| {0} | {1} | `.squad/agents/{2}/charter.md` | baseline |' -f $baselineRole.AgentDirectory, $baselineRole.Name, $baselineRole.AgentDirectory)
}
if ($membersTableRows.Count -gt 0) {
    Set-ManagedTableRows -TargetPath $teamPath -TableSectionHeader '## Members' -Rows $membersTableRows -Actions $actions
}

# Also maintain the Specrew Baseline Roles section for documentation
$teamContentLines = @(
    '## Specrew Baseline Roles'
    ''
    '| Role | Charter | Status |'
    '| ---- | ------- | ------ |'
)
foreach ($baselineRole in $baselineRoles) {
    $teamContentLines += ('| {0} | `.squad/agents/{1}/charter.md` | baseline |' -f $baselineRole.Name, $baselineRole.AgentDirectory)
}
Set-ManagedBlock -TargetPath $teamPath -BlockName 'baseline-roles' -ManagedContent ($teamContentLines -join [Environment]::NewLine) -BaseContentIfMissing '# Squad Team' -Actions $actions

# Update routing.md with baseline role routing
$routingPath = Join-Path $squadRoot 'routing.md'
$routingTableRows = @(
    '| Specification governance | spec-steward | Spec authoring, requirement authority, drift detection |'
    '| Planning & traceability | planner | Iteration planning, task breakdown, requirement tracing |'
    '| Implementation | implementer | Code changes, feature delivery, execution follow-through |'
    '| Code review | reviewer | PR review, quality checks, acceptance validation |'
    '| Retrospectives | retro-facilitator | Iteration retrospectives, process improvements |'
)
Set-ManagedTableRows -TargetPath $routingPath -TableSectionHeader '## Routing Table' -Rows $routingTableRows -Actions $actions

# Update casting/registry.json with baseline role entries
$registryPath = Join-Path $squadRoot 'casting\registry.json'
$registryAgents = [ordered]@{}
foreach ($baselineRole in $baselineRoles) {
    $registryAgents[$baselineRole.AgentDirectory] = @{
        name = $baselineRole.Name
        role = $baselineRole.Name
        status = 'baseline'
        charter = ".squad/agents/$($baselineRole.AgentDirectory)/charter.md"
    }
}
$registryContent = @{
    agents = $registryAgents
} | ConvertTo-Json -Depth 10
Set-ManagedFile -TargetPath $registryPath -Content $registryContent -Actions $actions

foreach ($baselineRole in $baselineRoles) {
    $agentDirectory = Join-Path $squadAgentsRoot $baselineRole.AgentDirectory
    Ensure-Directory -Path $agentDirectory -Actions $actions

    $charterTemplate = Get-Content -LiteralPath (Join-Path $templateRoot $baselineRole.TemplatePath) -Raw
    $directiveContent = @(
        foreach ($directivePath in $baselineRole.DirectivePaths) {
            Get-DirectiveDeployment -DirectivePath (Join-Path $templateRoot $directivePath)
        }
    ) -join ([Environment]::NewLine + [Environment]::NewLine)

    Set-ManagedBlock -TargetPath (Join-Path $agentDirectory 'charter.md') -BlockName 'directives' -ManagedContent $directiveContent -BaseContentIfMissing $charterTemplate -Actions $actions

    # Create history.md for each baseline role
    $historyPath = Join-Path $agentDirectory 'history.md'
    $historyContent = @"
# $($baselineRole.Name) History

Project-specific learnings and patterns discovered during work.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->
"@
    Write-MissingFile -TargetPath $historyPath -Content $historyContent -Actions $actions
}

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Squad runtime deployment {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $resolvedProjectPath)) -ForegroundColor Green
exit 0
