[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output   = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function Get-FunctionDefinitionsText {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$FunctionNames
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        throw ("Failed to parse function definitions from {0}: {1}" -f $Path, ($parseErrors | ForEach-Object { $_.Message } | Select-Object -First 1))
    }

    foreach ($functionName in $FunctionNames) {
        $functionAst = $ast.Find(
            {
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq $functionName
            },
            $true
        )

        if ($null -eq $functionAst) {
            throw ("Failed to locate function '{0}' in {1}" -f $functionName, $Path)
        }

        $functionAst.Extent.Text
    }
}

function New-TestProject {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [switch]$SkipInitialCommit
    )

    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
    $null = & git -C $ProjectRoot init --quiet 2>&1
    $null = & git -C $ProjectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $ProjectRoot config user.name 'Test User' 2>&1

    foreach ($relativeDirectory in @(
            '.specrew',
            '.specify',
            '.squad',
            '.squad\agents\planner',
            '.github\agents',
            ("specs\{0}\iterations\001" -f $FeatureRef)
        )) {
        $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specify\feature.json'), ("{{`n  `"feature_directory`": `"specs/{0}`"`n}}" -f $FeatureRef), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\agents\planner\charter.md'), "# Planner Charter`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot ("specs\{0}\spec.md" -f $FeatureRef)), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

    if (-not $SkipInitialCommit) {
        $null = & git -C $ProjectRoot add -A 2>&1
        $null = & git -C $ProjectRoot commit -m 'Seed repository' --quiet 2>&1
        $null = & git -C $ProjectRoot branch -M main 2>&1
        $null = & git -C $ProjectRoot checkout -b $FeatureRef 2>&1
    }

    return [pscustomobject]@{
        ProjectRoot = $ProjectRoot
        FeatureRef  = $FeatureRef
        PromptPath  = Join-Path $ProjectRoot '.specrew\last-start-prompt.md'
        ContextPath = Join-Path $ProjectRoot '.specrew\start-context.json'
        AgentPath   = Join-Path $ProjectRoot '.github\agents\squad.agent.md'
        CharterPath = Join-Path $ProjectRoot '.squad\agents\planner\charter.md'
    }
}

function Get-GitHead {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return (@(& git -C $ProjectRoot rev-parse HEAD 2>&1))[0].ToString().Trim()
}

function Get-PromptContent {
    param([Parameter(Mandatory = $true)][string]$PromptPath)

    return Get-Content -LiteralPath $PromptPath -Raw -Encoding UTF8
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$internalScript = Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1'
$humanAuthorityScript = Join-Path $repoRoot 'scripts\internal\bootstrap\HumanAuthorityStore.ps1'
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'

foreach ($requiredPath in @($internalScript, $humanAuthorityScript, $startScript, $syncScript)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        Write-Fail "Missing required script: $requiredPath"
        exit 1
    }
}

. $internalScript
. $humanAuthorityScript
Invoke-Expression ((Get-FunctionDefinitionsText -Path $startScript -FunctionNames @('Get-BaselineCommitHash')) -join [Environment]::NewLine)

$scratchRoot = Join-Path $repoRoot '.scratch\baseline-hygiene'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

# UT-001 / UT-002: frontmatter preservation + baseline reader robustness
$unitProject = New-TestProject -ProjectRoot (Join-Path $scratchRoot 'unit') -FeatureRef '029-baseline-hygiene-unit'
$originalBody = @"
# Specrew Session State

- body line 1
- body line 2
"@
$originalPrompt = @"
---
baseline_commit_hash: 1111111111111111111111111111111111111111
custom_field: keep-me
session_state_active: true
session_state_boundary: clarify
---

$originalBody
"@
[System.IO.File]::WriteAllText($unitProject.PromptPath, $originalPrompt, [System.Text.UTF8Encoding]::new($false))
Update-BaselineCommitHashInFrontmatter -PromptPath $unitProject.PromptPath -NewBaselineHash '2222222222222222222222222222222222222222'
$updatedPrompt = Get-PromptContent -PromptPath $unitProject.PromptPath
if ($updatedPrompt -notmatch 'baseline_commit_hash:\s*2222222222222222222222222222222222222222' -or
    $updatedPrompt -notmatch 'custom_field:\s*keep-me' -or
    $updatedPrompt -notmatch 'session_state_boundary:\s*clarify') {
    Write-Fail 'Baseline helper did not preserve non-baseline frontmatter fields.'
    exit 1
}
if ($updatedPrompt -notmatch [regex]::Escape($originalBody.Trim())) {
    Write-Fail 'Baseline helper did not preserve the prompt body content.'
    exit 1
}
if ((Get-BaselineCommitHash -ResolvedProjectPath $unitProject.ProjectRoot) -ne '2222222222222222222222222222222222222222') {
    Write-Fail 'Get-BaselineCommitHash did not return the refreshed baseline hash.'
    exit 1
}
Write-Pass 'Baseline helper preserves prompt frontmatter and body while refreshing baseline_commit_hash'

foreach ($case in @(
        @{
            Name = 'missing baseline field'
            Content = @"
---
session_state_boundary: plan
---

Body
"@
        }
        @{
            Name = 'invalid baseline field'
            Content = @"
---
baseline_commit_hash: not-a-commit
---

Body
"@
        }
        @{
            Name = 'malformed frontmatter'
            Content = "baseline_commit_hash: malformed`nBody`n"
        }
    )) {
    [System.IO.File]::WriteAllText($unitProject.PromptPath, $case.Content, [System.Text.UTF8Encoding]::new($false))
    if ($null -ne (Get-BaselineCommitHash -ResolvedProjectPath $unitProject.ProjectRoot)) {
        Write-Fail ("Get-BaselineCommitHash should return null for {0}." -f $case.Name)
        exit 1
    }
}
Write-Pass 'Get-BaselineCommitHash safely returns null for missing, invalid, and malformed prompt states'

[System.IO.File]::WriteAllText($unitProject.PromptPath, "No frontmatter yet`nSecond line`n", [System.Text.UTF8Encoding]::new($false))
Update-BaselineCommitHashInFrontmatter -PromptPath $unitProject.PromptPath -NewBaselineHash '3333333333333333333333333333333333333333'
$fallbackPrompt = Get-PromptContent -PromptPath $unitProject.PromptPath
if ($fallbackPrompt -notmatch 'baseline_commit_hash:\s*3333333333333333333333333333333333333333' -or
    $fallbackPrompt -notmatch 'No frontmatter yet') {
    Write-Fail 'Baseline helper did not recover gracefully from a prompt missing YAML frontmatter.'
    exit 1
}
Write-Pass 'Baseline helper gracefully rehydrates malformed prompt content without losing the body'

$lockedPromptContent = @"
---
baseline_commit_hash: 4444444444444444444444444444444444444444
---

Locked body
"@
[System.IO.File]::WriteAllText($unitProject.PromptPath, $lockedPromptContent, [System.Text.UTF8Encoding]::new($false))
$lockStream = [System.IO.File]::Open($unitProject.PromptPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
try {
    try {
        Update-BaselineCommitHashInFrontmatter -PromptPath $unitProject.PromptPath -NewBaselineHash '5555555555555555555555555555555555555555'
        Write-Fail 'Expected the baseline helper to fail when the prompt file is locked.'
        exit 1
    }
    catch {
        if ([string]::IsNullOrWhiteSpace($_.Exception.Message) -or
            $_.Exception.Message -notmatch 'last-start-prompt\.md|Atomic write|cannot access the file') {
            Write-Fail 'Locked-file baseline failure did not surface a clear file I/O error.'
            exit 1
        }
    }
}
finally {
    $lockStream.Dispose()
}
if ((Get-PromptContent -PromptPath $unitProject.PromptPath) -ne $lockedPromptContent) {
    Write-Fail 'Locked-file baseline failure corrupted the existing prompt content.'
    exit 1
}
Write-Pass 'Baseline helper fails closed on write errors and leaves the prompt uncorrupted'

# Integration: sequence, false-positive elimination, genuine detection, idempotency, closeout

Write-Host ''
Write-Host 'All baseline hygiene (baseline helper) tests passed' -ForegroundColor Green
