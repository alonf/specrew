[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [switch]$DryRun,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

    Add-DeploymentAction -Actions $Actions -Action 'created-directory' -Path $Path
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

    Add-DeploymentAction -Actions $Actions -Action 'created' -Path $TargetPath
    if (-not $DryRun) {
        $parent = Split-Path -Parent $TargetPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
    }
}

function Ensure-ManagedMarkdownBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$BlockId,

        [Parameter(Mandatory = $true)]
        [string]$BlockContent,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    $startMarker = "<!-- specrew:{0}:start -->" -f $BlockId
    $endMarker = "<!-- specrew:{0}:end -->" -f $BlockId
    $managedBlock = @(
        $startMarker
        $BlockContent.TrimEnd()
        $endMarker
    ) -join [Environment]::NewLine

    $existingContent = if (Test-Path -LiteralPath $TargetPath) {
        Get-Content -LiteralPath $TargetPath -Raw
    }
    else {
        ''
    }

    if ($existingContent -match [regex]::Escape($startMarker)) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved-block' -Path ("{0} [{1}]" -f $TargetPath, $BlockId)
        return
    }

    $updatedContent = if ([string]::IsNullOrWhiteSpace($existingContent)) {
        $managedBlock + [Environment]::NewLine
    }
    else {
        ($existingContent.TrimEnd(), '', $managedBlock, '') -join [Environment]::NewLine
    }

    Add-DeploymentAction -Actions $Actions -Action 'updated' -Path ("{0} [{1}]" -f $TargetPath, $BlockId)
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($TargetPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
    }
}

function Ensure-DirectiveInCharter {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CharterPath,

        [Parameter(Mandatory = $true)]
        [string]$DirectiveId,

        [Parameter(Mandatory = $true)]
        [string]$DirectiveContent,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    $startMarker = "<!-- specrew:directive:{0}:start -->" -f $DirectiveId
    $endMarker = "<!-- specrew:directive:{0}:end -->" -f $DirectiveId
    $managedBlock = @(
        $startMarker
        $DirectiveContent.TrimEnd()
        $endMarker
    ) -join [Environment]::NewLine

    $charterContent = if (Test-Path -LiteralPath $CharterPath) {
        Get-Content -LiteralPath $CharterPath -Raw
    }
    else {
        ''
    }

    if ($charterContent -match [regex]::Escape($startMarker)) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved-directive' -Path ("{0} [{1}]" -f $CharterPath, $DirectiveId)
        return
    }

    if ($charterContent -match '(?m)^## Specrew Directives\s*$') {
        $updatedContent = ($charterContent.TrimEnd(), '', $managedBlock, '') -join [Environment]::NewLine
    }
    else {
        $updatedContent = ($charterContent.TrimEnd(), '', '## Specrew Directives', '', $managedBlock, '') -join [Environment]::NewLine
    }

    Add-DeploymentAction -Actions $Actions -Action 'updated-directive' -Path ("{0} [{1}]" -f $CharterPath, $DirectiveId)
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($CharterPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
    }
}

function Ensure-TeamMembers {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TeamPath,

        [Parameter(Mandatory = $true)]
        [object[]]$Members,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    $existingContent = if (Test-Path -LiteralPath $TeamPath) {
        Get-Content -LiteralPath $TeamPath -Raw
    }
    else {
        @(
            '# Squad Team'
            ''
            '## Coordinator'
            ''
            '| Name | Role | Notes |'
            '|------|------|-------|'
            '| Squad | Coordinator | Routes work and coordinates handoffs. |'
            ''
            '## Members'
            ''
            '| Name | Role | Charter | Status |'
            '|------|------|---------|--------|'
            ''
        ) -join [Environment]::NewLine
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.AddRange([string[]]($existingContent -split "`r?`n", 0, [System.StringSplitOptions]::None))

    $hasChanges = $false
    $membersHeaderIndex = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -eq '## Members') {
            $membersHeaderIndex = $index
            break
        }
    }

    if ($membersHeaderIndex -lt 0) {
        if ($lines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($lines[$lines.Count - 1])) {
            $lines.Add('')
        }

        $lines.Add('## Members')
        $lines.Add('')
        $lines.Add('| Name | Role | Charter | Status |')
        $lines.Add('|------|------|---------|--------|')
        $lines.Add('')
        $membersHeaderIndex = $lines.Count - 5
        $hasChanges = $true
    }

    $tableHeaderIndex = -1
    $tableSeparatorIndex = -1
    for ($index = $membersHeaderIndex + 1; $index -lt $lines.Count; $index++) {
        if ($tableHeaderIndex -lt 0 -and $lines[$index] -match '^\|\s*Name\s*\|\s*Role\s*\|\s*Charter\s*\|\s*Status\s*\|$') {
            $tableHeaderIndex = $index
            continue
        }

        if ($tableHeaderIndex -ge 0 -and $tableSeparatorIndex -lt 0 -and $lines[$index] -match '^\|\-') {
            $tableSeparatorIndex = $index
            continue
        }
    }

    if ($tableHeaderIndex -lt 0 -or $tableSeparatorIndex -lt 0) {
        throw "Could not locate the Squad members table in '$TeamPath'."
    }

    $insertIndex = $tableSeparatorIndex + 1
    while ($insertIndex -lt $lines.Count -and $lines[$insertIndex] -match '^\|') {
        $insertIndex++
    }

    foreach ($member in $Members) {
        $memberPattern = '^\|\s*{0}\s*\|' -f [regex]::Escape($member.Name)
        if ($lines -match $memberPattern) {
            continue
        }

        $row = '| {0} | {1} | `{2}` | {3} |' -f $member.Name, $member.Role, $member.Charter, $member.Status
        $lines.Insert($insertIndex, $row)
        $insertIndex++
        $hasChanges = $true
    }

    if (-not $hasChanges) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved-members' -Path $TeamPath
        return
    }

    Add-DeploymentAction -Actions $Actions -Action 'updated-members' -Path $TeamPath
    if (-not $DryRun) {
        $content = ($lines -join [Environment]::NewLine)
        if (-not $content.EndsWith([Environment]::NewLine)) {
            $content += [Environment]::NewLine
        }

        [System.IO.File]::WriteAllText($TeamPath, $content, [System.Text.UTF8Encoding]::new($false))
    }
}

$resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
$extensionRoot = Split-Path -Parent $PSScriptRoot
$templateRoot = Join-Path $extensionRoot 'squad-templates'
$copilotSkillsRoot = Join-Path $resolvedProjectPath '.copilot\skills'
$squadRoot = Join-Path $resolvedProjectPath '.squad'
$teamPath = Join-Path $squadRoot 'team.md'
$ceremoniesPath = Join-Path $squadRoot 'ceremonies.md'
$actions = [System.Collections.ArrayList]::new()

if (-not (Test-Path -LiteralPath $squadRoot) -and -not $DryRun) {
    throw "Squad must be initialized before deploying runtime surfaces. Missing '$squadRoot'."
}

if ($DryRun -and -not (Test-Path -LiteralPath $squadRoot)) {
    Add-DeploymentAction -Actions $actions -Action 'would-create-directory' -Path $squadRoot
}

if ($DryRun -and -not (Test-Path -LiteralPath $copilotSkillsRoot)) {
    Add-DeploymentAction -Actions $actions -Action 'would-create-directory' -Path $copilotSkillsRoot
}

Ensure-Directory -Path $copilotSkillsRoot -Actions $actions
Ensure-Directory -Path (Join-Path $squadRoot 'agents') -Actions $actions

$skillFiles = @(Get-ChildItem -LiteralPath (Join-Path $templateRoot 'skills') -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' -and $_.Name -ne 'iteration-resume.md' } | Sort-Object Name)
foreach ($skillFile in $skillFiles) {
    $skillName = 'specrew-{0}' -f $skillFile.BaseName
    $skillDir = Join-Path $copilotSkillsRoot $skillName
    Ensure-Directory -Path $skillDir -Actions $actions
    Write-MissingFile -TargetPath (Join-Path $skillDir 'SKILL.md') -Content (Get-Content -LiteralPath $skillFile.FullName -Raw) -Actions $actions
}

$ceremonyFiles = @(
    'planning.md'
    'review-demo.md'
) | ForEach-Object { Get-Item -LiteralPath (Join-Path $templateRoot ('ceremonies\{0}' -f $_)) }
foreach ($ceremonyFile in $ceremonyFiles) {
    Ensure-ManagedMarkdownBlock -TargetPath $ceremoniesPath -BlockId ("ceremony:{0}" -f $ceremonyFile.BaseName) -BlockContent (Get-Content -LiteralPath $ceremonyFile.FullName -Raw) -Actions $actions
}

$roleTemplates = @(
    @{ Slug = 'spec-steward'; Name = 'Spec Steward'; Role = 'Spec Steward'; Charter = '.squad/agents/spec-steward/charter.md'; Status = '✅ Active'; Directives = @('spec-authority', 'traceability', 'drift-reporting') }
    @{ Slug = 'planner'; Name = 'Planner'; Role = 'Planner'; Charter = '.squad/agents/planner/charter.md'; Status = '✅ Active'; Directives = @('spec-authority', 'traceability') }
    @{ Slug = 'implementer'; Name = 'Implementer'; Role = 'Implementer'; Charter = '.squad/agents/implementer/charter.md'; Status = '✅ Active'; Directives = @('spec-authority', 'drift-reporting') }
    @{ Slug = 'reviewer'; Name = 'Reviewer'; Role = 'Reviewer'; Charter = '.squad/agents/reviewer/charter.md'; Status = '✅ Active'; Directives = @('spec-authority', 'traceability', 'drift-reporting') }
    @{ Slug = 'retro-facilitator'; Name = 'Retro Facilitator'; Role = 'Retro Facilitator'; Charter = '.squad/agents/retro-facilitator/charter.md'; Status = '✅ Active'; Directives = @('spec-authority', 'traceability') }
)

foreach ($roleTemplate in $roleTemplates) {
    $targetAgentDir = Join-Path $squadRoot ('agents\{0}' -f $roleTemplate.Slug)
    Ensure-Directory -Path $targetAgentDir -Actions $actions

    $sourceCharter = Join-Path $templateRoot ('agents\{0}\charter.md' -f $roleTemplate.Slug)
    $targetCharter = Join-Path $targetAgentDir 'charter.md'
    Write-MissingFile -TargetPath $targetCharter -Content (Get-Content -LiteralPath $sourceCharter -Raw) -Actions $actions

    foreach ($directiveId in $roleTemplate.Directives) {
        $directivePath = Join-Path $templateRoot ('directives\{0}.md' -f $directiveId)
        Ensure-DirectiveInCharter -CharterPath $targetCharter -DirectiveId $directiveId -DirectiveContent (Get-Content -LiteralPath $directivePath -Raw) -Actions $actions
    }
}

Ensure-TeamMembers -TeamPath $teamPath -Members $roleTemplates -Actions $actions

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Squad runtime deployment {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $resolvedProjectPath)) -ForegroundColor Green
exit 0
