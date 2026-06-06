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

function New-CliShim {
    param(
        [Parameter(Mandatory = $true)][string]$DirectoryPath,
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $shimPath = Join-Path -Path $DirectoryPath -ChildPath ("{0}.cmd" -f $CommandName)
    [System.IO.File]::WriteAllText($shimPath, $Content, [System.Text.UTF8Encoding]::new($false))
    return $shimPath
}

function Invoke-TestScriptWithShimPath {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$ShimPath
    )

    $originalPath = $env:PATH
    try {
        $env:PATH = "{0}{1}{2}" -f $ShimPath, [System.IO.Path]::PathSeparator, $originalPath
        return Invoke-TestScript -ScriptPath $ScriptPath -ArgumentList $ArgumentList
    }
    finally {
        $env:PATH = $originalPath
    }
}

function Invoke-InteractiveStart {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string[]]$Inputs
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'pwsh'
    $null = $startInfo.ArgumentList.Add('-NoProfile')
    $null = $startInfo.ArgumentList.Add('-ExecutionPolicy')
    $null = $startInfo.ArgumentList.Add('Bypass')
    $null = $startInfo.ArgumentList.Add('-File')
    $null = $startInfo.ArgumentList.Add($ScriptPath)
    $null = $startInfo.ArgumentList.Add('-ProjectPath')
    $null = $startInfo.ArgumentList.Add($ProjectRoot)
    $null = $startInfo.ArgumentList.Add('-NoLaunch')
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::Start($startInfo)

    # Drain stdout AND stderr concurrently from the moment the child starts. Both streams
    # are redirected, and `specrew start` emits a large recovery transcript; if we block in
    # WaitForExit() before reading, the child blocks writing once the OS pipe buffer fills
    # and neither side progresses (the classic redirected-stream deadlock). ReadToEndAsync
    # keeps the pipes drained throughout, including while we are still writing stdin.
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    foreach ($inputValue in $Inputs) {
        Start-Sleep -Milliseconds 150
        $process.StandardInput.WriteLine($inputValue)
    }
    $process.StandardInput.Close()
    $process.WaitForExit()

    return @{
        ExitCode = $process.ExitCode
        Output   = $stdoutTask.GetAwaiter().GetResult() + $stderrTask.GetAwaiter().GetResult()
    }
}

function Add-BootstrapValidationSurface {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $templatesRoot = Join-Path $ProjectRoot '.specify\templates'
    $workflowsRoot = Join-Path $ProjectRoot '.github\workflows'
    foreach ($path in @((Join-Path $ProjectRoot '.squad\agents'), (Join-Path $ProjectRoot '.github\agents'), $templatesRoot, $workflowsRoot)) {
        $null = New-Item -ItemType Directory -Path $path -Force
    }

    foreach ($templateName in @('agent-file-template.md', 'checklist-template.md', 'constitution-template.md', 'plan-template.md', 'spec-template.md', 'tasks-template.md')) {
        [System.IO.File]::WriteAllText((Join-Path $templatesRoot $templateName), "# $templateName`n", [System.Text.UTF8Encoding]::new($false))
    }

    [System.IO.File]::WriteAllText((Join-Path $workflowsRoot 'specrew.yml'), "name: specrew`n", [System.Text.UTF8Encoding]::new($false))
}

function Remove-SkillCatalogRoots {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    foreach ($relativeDirectory in @('.claude\skills', '.github\skills', '.agents\skills')) {
        $path = Join-Path $ProjectRoot $relativeDirectory
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }
}

function Assert-SkillCatalogRootsExist {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    foreach ($relativeDirectory in @('.claude\skills', '.github\skills', '.agents\skills')) {
        $path = Join-Path $ProjectRoot $relativeDirectory
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            Write-Fail "Expected repaired skill catalog directory: $path"
            exit 1
        }
    }
}

function New-MinimalProject {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
    $null = & git -C $ProjectRoot init --quiet 2>&1
    $null = & git -C $ProjectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $ProjectRoot config user.name 'Test User' 2>&1

    foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', '.github\skills', '.claude\skills', '.agents\skills', 'specs\022-hotfix-schema-tests\iterations\001')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/022-hotfix-schema-tests`"`n}", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'specs\022-hotfix-schema-tests\spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $ProjectRoot add -A 2>&1
    $null = & git -C $ProjectRoot commit -m 'Seed project' --quiet 2>&1
    $null = & git -C $ProjectRoot branch -M main 2>&1
    $null = & git -C $ProjectRoot checkout -b 022-hotfix-schema-tests 2>&1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$initScript = Join-Path $repoRoot 'scripts\specrew-init.ps1'

$scratchRoot = Join-Path $repoRoot '.scratch\start-recovery-flow'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

$shimRoot = Join-Path $scratchRoot 'path-shims'
$null = New-Item -ItemType Directory -Path $shimRoot -Force
New-CliShim -DirectoryPath $shimRoot -CommandName 'uv' -Content @'
@echo off
if /I "%~1 %~2"=="tool list" (
  echo specify-cli v1.0.0
  echo - specify
  exit /b 0
)
echo uv 0.7.0
exit /b 0
'@ | Out-Null
New-CliShim -DirectoryPath $shimRoot -CommandName 'node' -Content @'
@echo off
echo v24.0.0
exit /b 0
'@ | Out-Null
New-CliShim -DirectoryPath $shimRoot -CommandName 'npm' -Content @'
@echo off
echo 10.0.0
exit /b 0
'@ | Out-Null
New-CliShim -DirectoryPath $shimRoot -CommandName 'gh' -Content @'
@echo off
echo gh version 2.0.0
exit /b 0
'@ | Out-Null
New-CliShim -DirectoryPath $shimRoot -CommandName 'specify' -Content @'
@echo off
if /I "%~1"=="--version" (
  echo Usage: specify [OPTIONS] COMMAND [ARGS]...
  echo No such option: --version
  exit /b 2
)
if /I "%~1"=="version" (
  echo GitHub Spec Kit - Spec-Driven Development Toolkit
  echo CLI Version    1.0.0
  echo Template Version    0.8.4
  exit /b 0
)
exit /b 0
'@ | Out-Null
New-CliShim -DirectoryPath $shimRoot -CommandName 'squad' -Content @'
@echo off
if /I "%~1"=="--version" (
  echo 0.9.1
  exit /b 0
)
exit /b 0
'@ | Out-Null

function New-StaleProject {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    New-MinimalProject -ProjectRoot $ProjectRoot
    $syncResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @('-ProjectPath', $ProjectRoot, '-BoundaryType', 'plan', '-FeatureRef', '022-hotfix-schema-tests', '-IterationNumber', '001')
    if ($syncResult.ExitCode -ne 0) {
        throw ("Failed to seed plan boundary state:`n{0}" -f ($syncResult.Output -join [Environment]::NewLine))
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
}

# Interactive stale-state flow with invalid input visibility
$interactiveProject = Join-Path $scratchRoot 'interactive'
New-StaleProject -ProjectRoot $interactiveProject
$interactiveResult = Invoke-InteractiveStart -ScriptPath $startScript -ProjectRoot $interactiveProject -Inputs @('z', 'A')
if ($interactiveResult.ExitCode -ne 0) {
    Write-Fail ("Interactive recovery flow should not dead-end:`n{0}" -f $interactiveResult.Output)
    exit 1
}

foreach ($pattern in @('Stale state detected', 'A\) re-anchor to the correct feature', 'B\) create a new feature', 'C\) exit and manually fix state', 'WARN: Invalid recovery choice', 'Prepared Specrew start context')) {
    if ($interactiveResult.Output -notmatch $pattern) {
        Write-Fail "Interactive recovery flow is missing expected output: $pattern"
        exit 1
    }
}

$interactiveContext = Get-Content -LiteralPath (Join-Path $interactiveProject '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if ($interactiveContext.recovery_session.entry_mode -ne 'detected-stale-state' -or $interactiveContext.recovery_session.selected_choice -ne 'A' -or $interactiveContext.recovery_session.bypass_gate -or $interactiveContext.recovery_session.approval_mode_changed) {
    Write-Fail 'Interactive recovery did not persist the expected recovery_session contract.'
    exit 1
}

$interactivePrompt = Get-Content -LiteralPath (Join-Path $interactiveProject '.specrew\last-start-prompt.md') -Raw -Encoding UTF8
if ($interactivePrompt -notmatch '## Recovery Mode' -or $interactivePrompt -notmatch 'Recovery choice A selected') {
    Write-Fail 'Interactive recovery prompt did not persist recovery guidance.'
    exit 1
}

Write-Pass 'Interactive stale-state recovery accepts invalid then valid input and persists recovery diagnostics'

# Explicit --recover bypass
$recoverProject = Join-Path $scratchRoot 'recover-flag'
New-StaleProject -ProjectRoot $recoverProject
$recoverResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $recoverProject, '-NoLaunch', '-Recover')
if ($recoverResult.ExitCode -ne 0) {
    Write-Fail ("--recover should bypass the stale-state gate:`n{0}" -f ($recoverResult.Output -join [Environment]::NewLine))
    exit 1
}

$recoverContext = Get-Content -LiteralPath (Join-Path $recoverProject '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if ($recoverContext.recovery_session.entry_mode -ne 'explicit-recover-flag' -or -not $recoverContext.recovery_session.bypass_gate -or $recoverContext.recovery_session.approval_mode_changed) {
    Write-Fail '--recover did not persist the expected bypass recovery contract.'
    exit 1
}

if (($recoverResult.Output -join [Environment]::NewLine) -notmatch 'Prepared Specrew start context') {
    Write-Fail '--recover did not continue through start artifact preparation.'
    exit 1
}

Write-Pass '--recover bypasses stale-state blocking without changing approval behavior'

# specrew start missing skill-catalog auto-repair
$startGapProject = Join-Path $scratchRoot 'start-skill-gap'
New-MinimalProject -ProjectRoot $startGapProject
Remove-SkillCatalogRoots -ProjectRoot $startGapProject
$startGapResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $startGapProject, '-NoLaunch', '-HostKind', 'codex', '-SkipUpdateCheck')
if ($startGapResult.ExitCode -ne 0) {
    Write-Fail ("specrew start should auto-repair missing skill catalog roots:`n{0}" -f ($startGapResult.Output -join [Environment]::NewLine))
    exit 1
}

if (($startGapResult.Output -join [Environment]::NewLine) -notmatch 'Skill catalog auto-repair completed') {
    Write-Fail 'specrew start did not report skill catalog auto-repair completion.'
    exit 1
}

Assert-SkillCatalogRootsExist -ProjectRoot $startGapProject
Write-Pass 'specrew start auto-repairs missing skill catalog roots before normal continuation'

# specrew init non-force missing skill-catalog deployable-gap repair
$initGapProject = Join-Path $scratchRoot 'init-skill-gap'
New-MinimalProject -ProjectRoot $initGapProject
Add-BootstrapValidationSurface -ProjectRoot $initGapProject
Remove-SkillCatalogRoots -ProjectRoot $initGapProject
$initGapResult = Invoke-TestScriptWithShimPath -ScriptPath $initScript -ArgumentList @('-ProjectPath', $initGapProject, '-SkipUpdateCheck') -ShimPath $shimRoot
if ($initGapResult.ExitCode -ne 0) {
    Write-Fail ("specrew init should repair missing skill catalog roots on non-force path:`n{0}" -f ($initGapResult.Output -join [Environment]::NewLine))
    exit 1
}

if (($initGapResult.Output -join [Environment]::NewLine) -notmatch 'skill catalog directories are missing') {
    Write-Fail 'specrew init non-force path did not surface the skill catalog deployment gap.'
    exit 1
}

Assert-SkillCatalogRootsExist -ProjectRoot $initGapProject
Write-Pass 'specrew init non-force path treats missing skill catalog roots as a deployable gap'

# specrew init -Force must also leave no missing skill-catalog roots
$forceInitGapProject = Join-Path $scratchRoot 'init-force-skill-gap'
New-MinimalProject -ProjectRoot $forceInitGapProject
Add-BootstrapValidationSurface -ProjectRoot $forceInitGapProject
Remove-SkillCatalogRoots -ProjectRoot $forceInitGapProject
$forceInitGapResult = Invoke-TestScriptWithShimPath -ScriptPath $initScript -ArgumentList @('-ProjectPath', $forceInitGapProject, '-Force', '-SkipUpdateCheck') -ShimPath $shimRoot
if ($forceInitGapResult.ExitCode -ne 0) {
    Write-Fail ("specrew init -Force should repair missing skill catalog roots:`n{0}" -f ($forceInitGapResult.Output -join [Environment]::NewLine))
    exit 1
}

Assert-SkillCatalogRootsExist -ProjectRoot $forceInitGapProject
Write-Pass 'specrew init -Force validates repaired skill catalog roots before success'

# FR-024 end-to-end: confirm-gated cleanup of a stale cross-worktree session.
# A saved session anchors a deleted/external feature worktree (feature_path missing). Choice A
# must NOT re-anchor; it must prompt for confirmation; on 'y' it clears ONLY the runtime session
# refs (start-context session_state + the matching active-sessions entry), preserves sibling
# sessions and feature artifacts, makes no commits, and the cleared state must STICK after the
# full start run (the end-of-run start-context regeneration must not silently re-anchor it).
$cleanupProject = Join-Path $scratchRoot 'stale-cleanup-e2e'
New-MinimalProject -ProjectRoot $cleanupProject
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

# Missing + outside-the-worktree feature path (never created).
$deletedExternalPath = (Join-Path $scratchRoot 'deleted-external-051\specs\051-old-merged') -replace '\\', '/'
$projectPathForward = ($cleanupProject -replace '\\', '/')

$staleContext = @{
    schema               = 'v2'
    session_state        = @{
        active           = $true
        boundary_type    = 'tasks'
        feature_ref      = '051-old-merged'
        feature_path     = $deletedExternalPath
        iteration_number = '003'
        task_id          = 'T009'
        auth_commit_hash = 'deadbeef'
        recorded_at      = '2026-06-01T10:00:00Z'
    }
    boundary_enforcement = @{ enabled = $true; last_authorized_boundary = 'tasks' }
}
[System.IO.File]::WriteAllText((Join-Path $cleanupProject '.specrew\start-context.json'), ($staleContext | ConvertTo-Json -Depth 8), $utf8NoBom)

# active-sessions: the stale '051-old-merged' lock plus a sibling lock that must survive cleanup.
$activeSessionsYml = @"
sessions:
  - feature_id: "051-old-merged"
    feature_path: "$deletedExternalPath"
    started_at: "2026-06-01T10:00:00Z"
  - feature_id: "022-hotfix-schema-tests"
    feature_path: "$projectPathForward"
    started_at: "2026-06-02T10:00:00Z"
"@
[System.IO.File]::WriteAllText((Join-Path $cleanupProject '.specrew\active-sessions.yml'), $activeSessionsYml, $utf8NoBom)

# A feature artifact under specs/ that the cleanup must NEVER touch.
$preservedArtifact = Join-Path $cleanupProject 'specs\051-old-merged\iterations\003\state.md'
$null = New-Item -ItemType Directory -Path (Split-Path -Parent $preservedArtifact) -Force
[System.IO.File]::WriteAllText($preservedArtifact, 'preserved feature artifact', $utf8NoBom)

$commitsBefore = [int](& git -C $cleanupProject rev-list --count HEAD)

# Choice A on a missing path (no re-anchor) then 'y' to confirm the stale-ref cleanup.
$cleanupResult = Invoke-InteractiveStart -ScriptPath $startScript -ProjectRoot $cleanupProject -Inputs @('A', 'y')
if ($cleanupResult.ExitCode -ne 0) {
    Write-Fail ("FR-024 stale-cleanup flow should not dead-end:`n{0}" -f $cleanupResult.Output)
    exit 1
}

# Note: Read-SpecrewYesNo reads silently under redirected stdin (no prompt echo), so assert on
# the always-emitted Write-Output line that precedes the confirmation, not the prompt itself.
foreach ($pattern in @('Stale state detected', 'no longer exists on disk', 'Clearing it removes only the active-session', 'Cleared stale references:')) {
    if ($cleanupResult.Output -notmatch $pattern) {
        Write-Fail "FR-024 stale-cleanup flow is missing expected output: $pattern`nFull output:`n$($cleanupResult.Output)"
        exit 1
    }
}

$activeAfter = Get-Content -LiteralPath (Join-Path $cleanupProject '.specrew\active-sessions.yml') -Raw -Encoding UTF8
if ($activeAfter -match '051-old-merged') {
    Write-Fail "FR-024 cleanup did not remove the stale active-sessions entry.`n$activeAfter"
    exit 1
}
if ($activeAfter -notmatch '022-hotfix-schema-tests') {
    Write-Fail "FR-024 cleanup removed the sibling active-sessions entry it should have preserved.`n$activeAfter"
    exit 1
}

# The cleared session must STICK: the regenerated start-context must not re-anchor the stale feature.
$cleanupContext = Get-Content -LiteralPath (Join-Path $cleanupProject '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
$sessionActiveAfter = if ($null -ne $cleanupContext.session_state) { [bool]$cleanupContext.session_state.active } else { $false }
$sessionRefAfter = if ($null -ne $cleanupContext.session_state) { [string]$cleanupContext.session_state.feature_ref } else { '' }
if ($sessionActiveAfter -or $sessionRefAfter -eq '051-old-merged') {
    Write-Fail "FR-024 cleanup did not stick: regenerated start-context still anchors the stale session (active=$sessionActiveAfter, feature_ref='$sessionRefAfter')."
    exit 1
}
if ($cleanupContext.recovery_session.entry_mode -ne 'detected-stale-state' -or $cleanupContext.recovery_session.selected_choice -ne 'A') {
    Write-Fail 'FR-024 cleanup did not persist the expected detected-stale recovery_session contract.'
    exit 1
}

if (-not (Test-Path -LiteralPath $preservedArtifact)) {
    Write-Fail 'FR-024 cleanup touched a feature artifact under specs/ (must never happen).'
    exit 1
}
$commitsAfter = [int](& git -C $cleanupProject rev-list --count HEAD)
if ($commitsBefore -ne $commitsAfter) {
    Write-Fail "FR-024 cleanup made lifecycle commits ($commitsBefore -> $commitsAfter); it must make none."
    exit 1
}

Write-Pass 'FR-024 stale cross-worktree cleanup: choice A confirm->clear sticks end-to-end (refs cleared, sibling + artifacts preserved, no commits)'
exit 0
