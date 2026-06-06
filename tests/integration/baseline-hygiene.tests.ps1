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
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'

foreach ($requiredPath in @($internalScript, $startScript, $syncScript)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        Write-Fail "Missing required script: $requiredPath"
        exit 1
    }
}

. $internalScript
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
$lifecycleProject = New-TestProject -ProjectRoot (Join-Path $scratchRoot 'lifecycle') -FeatureRef '029-baseline-hygiene-lifecycle'
$boundaries = @('specify', 'clarify', 'plan', 'tasks', 'review-signoff', 'iteration-closeout', 'feature-closeout')

for ($index = 0; $index -lt $boundaries.Count; $index++) {
    $boundary = $boundaries[$index]
    if ($boundary -ne 'specify') {
        $targetPath = if (($index % 2) -eq 0) { $lifecycleProject.CharterPath } else { $lifecycleProject.AgentPath }
        Add-Content -LiteralPath $targetPath -Value ("boundary-{0}" -f $boundary) -Encoding UTF8
        $null = & git -C $lifecycleProject.ProjectRoot add -A 2>&1
        $null = & git -C $lifecycleProject.ProjectRoot commit -m ("Record {0} boundary work" -f $boundary) --quiet 2>&1
    }

    $syncResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
        '-ProjectPath', $lifecycleProject.ProjectRoot,
        '-BoundaryType', $boundary,
        '-FeatureRef', $lifecycleProject.FeatureRef,
        '-IterationNumber', '001'
    )
    if ($syncResult.ExitCode -ne 0) {
        Write-Fail ("Boundary sync failed for '{0}':`n{1}" -f $boundary, ($syncResult.Output -join [Environment]::NewLine))
        exit 1
    }

    $expectedHead = Get-GitHead -ProjectRoot $lifecycleProject.ProjectRoot
    $promptContent = Get-PromptContent -PromptPath $lifecycleProject.PromptPath
    if ($promptContent -notmatch ("baseline_commit_hash:\s*{0}" -f [regex]::Escape($expectedHead)) -or
        $promptContent -notmatch ("session_state_boundary:\s*{0}" -f [regex]::Escape($boundary))) {
        Write-Fail ("Boundary sync did not refresh baseline_commit_hash for '{0}'." -f $boundary)
        exit 1
    }

    if ($boundary -eq 'tasks') {
        $repeatSyncResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
            '-ProjectPath', $lifecycleProject.ProjectRoot,
            '-BoundaryType', $boundary,
            '-FeatureRef', $lifecycleProject.FeatureRef,
            '-IterationNumber', '001'
        )
        if ($repeatSyncResult.ExitCode -ne 0) {
            Write-Fail ("Repeated tasks boundary sync failed:`n{0}" -f ($repeatSyncResult.Output -join [Environment]::NewLine))
            exit 1
        }

        $repeatedPromptContent = Get-PromptContent -PromptPath $lifecycleProject.PromptPath
        if ($repeatedPromptContent -notmatch ("baseline_commit_hash:\s*{0}" -f [regex]::Escape($expectedHead)) -or
            [regex]::Matches($repeatedPromptContent, 'baseline_commit_hash:').Count -ne 1) {
            Write-Fail 'Repeated boundary sync did not remain idempotent.'
            exit 1
        }
    }

    $startResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @(
        '-ProjectPath', $lifecycleProject.ProjectRoot,
        '-NoLaunch'
    )
    if ($startResult.ExitCode -ne 0) {
        Write-Fail ("specrew start failed after '{0}' boundary sync:`n{1}" -f $boundary, ($startResult.Output -join [Environment]::NewLine))
        exit 1
    }

    $postStartPrompt = Get-PromptContent -PromptPath $lifecycleProject.PromptPath
    if ($postStartPrompt -match 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed') {
        Write-Fail ("Boundary-managed changes still triggered a false-positive pause after '{0}'." -f $boundary)
        exit 1
    }

    if ($boundary -eq 'clarify') {
        Add-Content -LiteralPath $lifecycleProject.AgentPath -Value 'user-change-after-baseline' -Encoding UTF8
        $null = & git -C $lifecycleProject.ProjectRoot add -A 2>&1
        $null = & git -C $lifecycleProject.ProjectRoot commit -m 'Out-of-band watched-file change' --quiet 2>&1

        $genuineChangeResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @(
            '-ProjectPath', $lifecycleProject.ProjectRoot,
            '-NoLaunch'
        )
        if ($genuineChangeResult.ExitCode -ne 0) {
            Write-Fail ("specrew start failed during genuine-change detection test:`n{0}" -f ($genuineChangeResult.Output -join [Environment]::NewLine))
            exit 1
        }

        $genuinePrompt = Get-PromptContent -PromptPath $lifecycleProject.PromptPath
        if ($genuinePrompt -notmatch 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed' -or
            $genuinePrompt -notmatch '\.github[/\\]agents[/\\]squad\.agent\.md') {
            Write-Fail 'A genuine out-of-band watched-file change was not surfaced by specrew start.'
            exit 1
        }

        $recoveredStartResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @(
            '-ProjectPath', $lifecycleProject.ProjectRoot,
            '-NoLaunch'
        )
        if ($recoveredStartResult.ExitCode -ne 0) {
            Write-Fail 'specrew start did not recover after the genuine-change pause path.'
            exit 1
        }
    }
}

$closeoutContext = Get-Content -LiteralPath $lifecycleProject.ContextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if ($closeoutContext.session_state.active -or $closeoutContext.session_state.boundary_type -ne 'feature-closeout') {
    Write-Fail 'Feature closeout did not preserve the inactive session-state sentinel in start-context.json.'
    exit 1
}
Write-Pass 'Boundary sync refreshes baseline at every lifecycle boundary, preserves genuine-change detection, and keeps feature closeout inactive'

# Error handling: git HEAD unavailable should warn and continue without corrupting prompt state
$warningProject = New-TestProject -ProjectRoot (Join-Path $scratchRoot 'warning') -FeatureRef '029-baseline-hygiene-warning' -SkipInitialCommit
$warningResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $warningProject.ProjectRoot,
    '-BoundaryType', 'specify',
    '-FeatureRef', $warningProject.FeatureRef
)
if ($warningResult.ExitCode -ne 0) {
    Write-Fail ("Boundary sync should continue when HEAD is unavailable:`n{0}" -f ($warningResult.Output -join [Environment]::NewLine))
    exit 1
}
$warningOutput = $warningResult.Output -join [Environment]::NewLine
if ($warningOutput -notmatch 'WARNING: Boundary sync ''specify'' could not refresh baseline_commit_hash') {
    Write-Fail 'Boundary sync did not emit the expected warning when HEAD could not be resolved.'
    exit 1
}
if ((Get-PromptContent -PromptPath $warningProject.PromptPath) -match 'baseline_commit_hash:') {
    Write-Fail 'Boundary sync should not stamp baseline_commit_hash when HEAD cannot be resolved.'
    exit 1
}
Write-Pass 'Boundary sync warns clearly and leaves the prompt uncorrupted when HEAD cannot be resolved'

# SC-009 (Feature 141 FR-013): fresh-greenfield baseline-commit handling.
# Prove-first outcome (maintainer C+nudge decision 2026-06-03): preserve the Feature-029
# zero-commit fail-safe (no stamp, NO auto-commit) AND nudge the user to establish history;
# once a commit exists the baseline resolves to a real HEAD and stays consistent across the
# start packet (last-start-prompt.md) and the boundary-state HEAD anchor.
$sc009Zero = New-TestProject -ProjectRoot (Join-Path $scratchRoot 'sc009-greenfield') -FeatureRef '141-fr013-greenfield' -SkipInitialCommit

# (1) zero-commit greenfield: `specrew start` must not stamp a baseline, must emit guidance, must not corrupt.
$sc009StartResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $sc009Zero.ProjectRoot, '-NoLaunch')
if ($sc009StartResult.ExitCode -ne 0) {
    Write-Fail ("SC-009: specrew start should succeed (fail-safe) in a zero-commit greenfield:`n{0}" -f ($sc009StartResult.Output -join [Environment]::NewLine))
    exit 1
}
$sc009StartOutput = $sc009StartResult.Output -join [Environment]::NewLine
if ($sc009StartOutput -notmatch 'No baseline commit yet' -or $sc009StartOutput -notmatch 'initial commit') {
    Write-Fail ("SC-009: zero-commit greenfield start did not emit the baseline guidance nudge:`n{0}" -f $sc009StartOutput)
    exit 1
}
if (-not (Test-Path -LiteralPath $sc009Zero.PromptPath)) {
    Write-Fail 'SC-009: specrew start did not write a prompt in the zero-commit greenfield.'
    exit 1
}
$sc009ZeroPrompt = Get-PromptContent -PromptPath $sc009Zero.PromptPath
if ($sc009ZeroPrompt -match 'baseline_commit_hash:') {
    Write-Fail 'SC-009: zero-commit greenfield must NOT stamp baseline_commit_hash (Feature-029 fail-safe).'
    exit 1
}
if ($null -ne (Get-BaselineCommitHash -ResolvedProjectPath $sc009Zero.ProjectRoot)) {
    Write-Fail 'SC-009: Get-BaselineCommitHash must return null when no baseline is stamped.'
    exit 1
}
Write-Pass 'SC-009: zero-commit greenfield start emits baseline guidance, does not stamp a baseline, and leaves the prompt uncorrupted'

# (2) after the first real commit: the boundary baseline-refresh path (Get-SpecrewCurrentHeadCommitHash
#     + Update-BaselineCommitHashInFrontmatter -- exactly what sync-boundary-state.ps1:1209-1210 runs)
#     resolves the baseline to a real HEAD and keeps it consistent with what the reader resolves.
$null = & git -C $sc009Zero.ProjectRoot add -A 2>&1
$null = & git -C $sc009Zero.ProjectRoot commit -m 'Initial commit (establishes baseline)' --quiet 2>&1
$sc009Head = Get-GitHead -ProjectRoot $sc009Zero.ProjectRoot
$sc009Resolved = Get-SpecrewCurrentHeadCommitHash -ProjectRoot $sc009Zero.ProjectRoot
if ($sc009Resolved -ne $sc009Head) {
    Write-Fail 'SC-009: Get-SpecrewCurrentHeadCommitHash must resolve to the real HEAD once a commit exists.'
    exit 1
}
Update-BaselineCommitHashInFrontmatter -PromptPath $sc009Zero.PromptPath -NewBaselineHash $sc009Resolved
$sc009CommitPrompt = Get-PromptContent -PromptPath $sc009Zero.PromptPath
if ($sc009CommitPrompt -notmatch ("baseline_commit_hash:\s*{0}" -f [regex]::Escape($sc009Head))) {
    Write-Fail 'SC-009: after the first commit, baseline_commit_hash must resolve to the real HEAD.'
    exit 1
}
if ((Get-BaselineCommitHash -ResolvedProjectPath $sc009Zero.ProjectRoot) -ne $sc009Head) {
    Write-Fail 'SC-009: the stamped baseline must stay consistent with what the baseline reader resolves (start packet vs boundary-state HEAD).'
    exit 1
}
Write-Pass 'SC-009: once a commit exists, the baseline resolves to a real HEAD and stays consistent across the start packet and boundary state'

Write-Host ''
Write-Host 'All baseline hygiene tests passed' -ForegroundColor Green
exit 0
