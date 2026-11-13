[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if (-not $Condition) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-Match {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if ($Text -notmatch $Pattern) {
        Write-Fail ("{0}`nObserved output:`n{1}" -f $FailureMessage, $Text)
        return $false
    }

    return $true
}

function Assert-NotMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if ($Text -match $Pattern) {
        Write-Fail ("{0}`nObserved output:`n{1}" -f $FailureMessage, $Text)
        return $false
    }

    return $true
}

function Assert-FirstLineMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    $firstLine = @(
        ($Text -split "\r?\n") |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -First 1
    )[0]

    if ([string]::IsNullOrWhiteSpace($firstLine) -or $firstLine -notmatch $Pattern) {
        Write-Fail ("{0}`nFirst output line:`n{1}`nObserved output:`n{2}" -f $FailureMessage, $firstLine, $Text)
        return $false
    }

    return $true
}

function Set-ContentUtf8 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Reset-ScratchRoot {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            if ($attempt -ge 4) {
                throw
            }

            Start-Sleep -Seconds 2
        }
    }
}


# B5F-062 (maintainer ruling 2026-11-12): this suite tests the validator's SCOPE rules - which iterations a run
# validates - not iteration content. It used to copy the repository's real feature 013 into a fresh git repo for
# every case (about 8 s each) and then validate that feature's full-size closed iteration (about 64 s per run),
# about 1284 s in all. The fixture is now built ONCE as a seeded git repo with a bare remote, and each case gets a
# fresh copy of it, so cases stay independent. Feature 013 is replaced by a minimal feature with the same shape the
# cases rely on:
#   - iteration 001: touched by the scoped cases, a small but real `complete` iteration that passes the validator's
#     checks for that status, and listed in .specrew/closed-iterations.yml (the closed-iteration filter's 1 skip);
#   - iteration 002: open (`executing`), untouched, and invalid because it has no state.md - the
#     `FAIL ... iterations/002` the unscoped cases must surface. It is committed without state.md (the old fixture
#     deleted it per case after the seed commit; the diff base never contained the deletion either way).
# The .specrew, .squad, .github and .specify copies are kept: the .specify mirror and its install record are what
# the hand-edit case exercises.
$minimalFeatureFiles = [ordered]@{
    'iterations\001\plan.md'                   = @'
# Iteration Plan: 001 - Scope fixture

**Schema**: v1
**Status**: complete
**Capacity**: 1/20 story_points
**Started**: 2026-05-12
**Completed**: 2026-05-12

## Effort Model

| Setting | Value |
| --- | --- |
| Effort Unit | story_points |
| Capacity per Iteration | 20 |
| Iteration Bounding | scope |
| Time Limit (hours) | n/a |
| Overcommit Threshold | 1.0 |
| Defer Strategy | manual |
| Calibration Enabled | true |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T001 | Fixture task | FR-001 | US1 | 1 | Implementer | done | 1 | pass |
'@
    'iterations\001\state.md'                  = @'
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: T001 (Fixture task)
**Tasks Remaining**: none
**In Progress**: none
**Baseline Ref**: commit 0000000 (fixture baseline)
**Updated**: 2026-05-12
**Current Phase**: complete
**Iteration Status**: Closeout validation green; iteration 001 closed
'@
    'iterations\001\drift-log.md'              = @'
# Drift Log: Iteration 001

No drift events recorded.
'@
    'iterations\001\review.md'                 = @'
# Review: Iteration 001

**Overall Verdict**: accepted

## Task Verdicts

| Task | Verdict | Notes |
| --- | --- | --- |
| T001 | pass | Fixture task accepted. |

## Gap Ledger

No known gaps remain.
'@
    'iterations\001\retro.md'                  = @'
# Retrospective: Iteration 001

## Estimation Accuracy

Planned 1, actual 1.

## Drift Summary

No drift.

## Process Notes

None.

## Improvement Actions

None.
'@
    'iterations\001\quality\hardening-gate.md' = @'
# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Iteration Ref**: `specs/013-validator-hardening/iterations/001`
**Overall Verdict**: ready
**Reviewed By**: Fixture Reviewer
**Reviewed At**: 2026-05-12
**Post-Implementation Verification**: review accepted
**Verified At**: 2026-05-12

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | None. | `false` | Fixture. | - |
| `error-handling-expectations` | `error-handling` | `not-applicable` | `not-applicable` | `not-needed` | None. | `false` | Fixture. | - |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | None. | `false` | Fixture. | - |
| `test-integrity-targets` | `test-integrity` | `not-applicable` | `not-applicable` | `not-needed` | None. | `false` | Fixture. | - |
| `operational-resilience-concerns` | `operational` | `not-applicable` | `not-applicable` | `not-needed` | None. | `false` | Fixture. | - |
'@
    'iterations\002\plan.md'                   = @'
# Iteration Plan: 002 - Untouched invalid fixture

**Schema**: v1
**Status**: executing
**Capacity**: 1/20 story_points
**Started**: 2026-05-13

## Effort Model

| Setting | Value |
| --- | --- |
| Effort Unit | story_points |
| Capacity per Iteration | 20 |
| Iteration Bounding | scope |
| Time Limit (hours) | n/a |
| Overcommit Threshold | 1.0 |
| Defer Strategy | manual |
| Calibration Enabled | true |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T002 | Fixture task | FR-001 | US1 | 1 | Implementer | in-progress | - | - |
'@
}

function Invoke-FixtureGit {
    param(
        [Parameter(Mandatory = $true)][string]$Step,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    # Every seed step is checked: a fixture step that fails silently makes every case below measure the wrong thing
    # (B4F-018's class) - with no seed commit there is no `main`, no `origin/main`, and every scoped case reports
    # `base-undetectable` for a reason that has nothing to do with scoping (census 34502784677).
    $output = @(& git @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw ("fixture seed: {0} failed: {1}" -f $Step, (($output | Where-Object { "$_" -notmatch 'LF will be replaced' }) -join ' | '))
    }
}

function New-SeedFixture {
    param([Parameter(Mandatory = $true)][string]$SeedRoot)

    $null = New-Item -ItemType Directory -Path $SeedRoot -Force

    foreach ($item in @('.specrew', '.squad', '.github', '.specify')) {
        $source = Join-Path $repoRoot $item
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $SeedRoot $item) -Recurse -Force
        }
    }

    # This fixture exercises diff scoping, not campaign provenance. The source repository's live campaign store
    # belongs to another feature and, copied into this isolated Feature 013 workspace, would make an accepted
    # review fail the beta3 feature/iteration evidence cross-check. Omit that unrelated authority state so the
    # accepted fixture review follows the validator's explicit no-store arm.
    # `.specrew/runtime` is ephemeral, gitignored, and NOT part of the tracked tree this fixture mirrors - a clean
    # checkout never has it, and on a developer machine its deep authority-snapshot trees can exceed path limits.
    foreach ($relative in @('.specrew\review\authority', '.specrew\runtime')) {
        $copied = Join-Path $SeedRoot $relative
        if (Test-Path -LiteralPath $copied) {
            Remove-Item -LiteralPath $copied -Recurse -Force
        }
    }

    # Keep iteration 001 in the copied closed-index so the unscoped cases also prove the default closed filter.
    # Iteration 002 is this suite's deliberately invalid untouched target; remove only its closeout entry so it is
    # an open invalid iteration rather than a skipped one.
    $closedIndexPath = Join-Path $SeedRoot '.specrew\closed-iterations.yml'
    if (Test-Path -LiteralPath $closedIndexPath) {
        $closedIndex = Get-Content -LiteralPath $closedIndexPath -Raw -Encoding UTF8
        $closedIndex = [regex]::Replace($closedIndex,
            '(?ms)^\s*-\s*feature:\s*013-validator-hardening\s*\r?\n\s*iteration:\s*002\s*\r?\n\s*closed_at:.*?(?:\r?\n|$)', '')
        Set-ContentUtf8 -Path $closedIndexPath -Content $closedIndex
    }
    $closedIndexText = if (Test-Path -LiteralPath $closedIndexPath) { Get-Content -LiteralPath $closedIndexPath -Raw -Encoding UTF8 } else { '' }
    if ($closedIndexText -notmatch '(?m)^\s*-\s*feature:\s*013-validator-hardening\s*\r?\n\s*iteration:\s*001\s*$') {
        throw "fixture seed: $closedIndexPath no longer records 013-validator-hardening iteration 001 as closed; the closed-iteration filter cases depend on it."
    }

    $featureRoot = Join-Path $SeedRoot 'specs\013-validator-hardening'
    foreach ($relativePath in $minimalFeatureFiles.Keys) {
        Set-ContentUtf8 -Path (Join-Path $featureRoot $relativePath) -Content $minimalFeatureFiles[$relativePath]
    }

    $remoteRoot = Join-Path $SeedRoot '.git-remote'
    Invoke-FixtureGit -Step 'git init' -Arguments @('-C', $SeedRoot, 'init', '--quiet')
    Invoke-FixtureGit -Step 'git config user.email' -Arguments @('-C', $SeedRoot, 'config', 'user.email', 'test@specrew.local')
    Invoke-FixtureGit -Step 'git config user.name' -Arguments @('-C', $SeedRoot, 'config', 'user.name', 'Test User')
    Invoke-FixtureGit -Step 'git config core.longpaths' -Arguments @('-C', $SeedRoot, 'config', 'core.longpaths', 'true')
    Add-Content -LiteralPath (Join-Path $SeedRoot '.git\info\exclude') -Value ([Environment]::NewLine + '.git-remote/' + [Environment]::NewLine)
    Invoke-FixtureGit -Step 'git add -A' -Arguments @('-C', $SeedRoot, 'add', '-A')
    Invoke-FixtureGit -Step 'seed commit' -Arguments @('-C', $SeedRoot, 'commit', '-m', 'Seed validator fixture', '--quiet')
    Invoke-FixtureGit -Step 'git branch -M main' -Arguments @('-C', $SeedRoot, 'branch', '-M', 'main')
    $null = New-Item -ItemType Directory -Path $remoteRoot -Force
    Invoke-FixtureGit -Step 'git init --bare' -Arguments @('-C', $remoteRoot, 'init', '--bare', '--quiet')
    Invoke-FixtureGit -Step 'git remote add origin' -Arguments @('-C', $SeedRoot, 'remote', 'add', 'origin', $remoteRoot)
    Invoke-FixtureGit -Step 'git push -u origin main' -Arguments @('-C', $SeedRoot, 'push', '--quiet', '-u', 'origin', 'main')
    Invoke-FixtureGit -Step 'git checkout -b feature-026' -Arguments @('-C', $SeedRoot, 'checkout', '--quiet', '-b', 'feature-026')
    # One pack instead of a loose object per file keeps the per-case copy small.
    Invoke-FixtureGit -Step 'git repack' -Arguments @('-C', $SeedRoot, 'repack', '-a', '-d', '-q')
    Invoke-FixtureGit -Step 'origin/main present' -Arguments @('-C', $SeedRoot, 'rev-parse', '--verify', 'refs/remotes/origin/main')
}

function New-Workspace {
    param([Parameter(Mandatory = $true)][string]$WorkspaceName)

    # A fresh, independent copy of the seeded repository (working tree, .git and its own bare remote), on branch
    # feature-026 with main pushed to origin - the state every case used to build from scratch.
    $workspaceRoot = Join-Path $scratchRoot $WorkspaceName
    Copy-Item -LiteralPath $seedRoot -Destination $workspaceRoot -Recurse -Force
    Invoke-FixtureGit -Step "point $WorkspaceName at its own remote" -Arguments @('-C', $workspaceRoot, 'remote', 'set-url', 'origin', (Join-Path $workspaceRoot '.git-remote'))
    return $workspaceRoot
}

function Commit-Workspace {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $null = & git -C $WorkspaceRoot add -A 2>&1
    $null = & git -C $WorkspaceRoot commit -m $Message --quiet 2>&1
}

function Touch-IterationForDiff {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$RelativeIterationFile
    )

    Touch-RelativeFileForDiff -WorkspaceRoot $WorkspaceRoot -RelativePath $RelativeIterationFile
}

function Touch-RelativeFileForDiff {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $targetPath = Join-Path $WorkspaceRoot $RelativePath
    $content = Get-Content -LiteralPath $targetPath -Raw -Encoding UTF8
    Set-ContentUtf8 -Path $targetPath -Content ($content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + '<!-- changed-only fixture touch -->' + [Environment]::NewLine)
    Commit-Workspace -WorkspaceRoot $WorkspaceRoot -Message "Touch $RelativePath"
}

function Remove-OriginRemote {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $null = & git -C $WorkspaceRoot remote remove origin 2>&1
}

function Remove-OriginHeadTrackingRef {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $null = & git -C $WorkspaceRoot update-ref -d refs/remotes/origin/HEAD 2>&1
}

function Checkout-MainBranch {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $null = & git -C $WorkspaceRoot checkout main 2>&1
}

function Checkout-DetachedHead {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $null = & git -C $WorkspaceRoot checkout --detach HEAD 2>&1
}

function Invoke-Validator {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$ChangedOnly,
        [switch]$FullRun,
        [AllowNull()][string]$BaseBranch
    )

    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $validatorScriptPath, '-ProjectPath', $ProjectPath)
    if ($ChangedOnly) {
        $arguments += '-ChangedOnly'
    }
    if ($FullRun) {
        $arguments += '-FullRun'
    }

    $previousBaseRef = $env:GITHUB_BASE_REF
    $previousVerbose = $env:SPECREW_VALIDATOR_VERBOSE
    try {
        if ([string]::IsNullOrWhiteSpace($BaseBranch)) {
            Remove-Item Env:GITHUB_BASE_REF -ErrorAction SilentlyContinue
        }
        else {
            $env:GITHUB_BASE_REF = $BaseBranch
        }

        $env:SPECREW_VALIDATOR_VERBOSE = '1'

        $output = @(& pwsh @arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        if ($null -eq $previousBaseRef) {
            Remove-Item Env:GITHUB_BASE_REF -ErrorAction SilentlyContinue
        }
        else {
            $env:GITHUB_BASE_REF = $previousBaseRef
        }

        if ($null -eq $previousVerbose) {
            Remove-Item Env:SPECREW_VALIDATOR_VERBOSE -ErrorAction SilentlyContinue
        }
        else {
            $env:SPECREW_VALIDATOR_VERBOSE = $previousVerbose
        }
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Text     = ($output -join "`n")
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$closedIndexSource = Join-Path $repoRoot '.specrew\closed-iterations.yml'
# A unique temp root: short paths (no Windows 260-character trouble under .scratch/<workspace>/), and two runs of
# this suite cannot share or delete each other's workspaces.
$scratchRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('specrew-vg-changed-only-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
$seedRoot = Join-Path $scratchRoot 'seed'

foreach ($requiredPath in @($validatorScriptPath, $closedIndexSource)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing changed-only validator dependency: $requiredPath"
        exit 1
    }
}

New-SeedFixture -SeedRoot $seedRoot

$allChecksPassed = $true

$explicitChangedOnlyWorkspace = New-Workspace -WorkspaceName 'explicit-changed-only'
Touch-IterationForDiff -WorkspaceRoot $explicitChangedOnlyWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
$explicitChangedOnlyResult = Invoke-Validator -ProjectPath $explicitChangedOnlyWorkspace -ChangedOnly -BaseBranch 'main'
$explicitChangedOnlyChecksPassed = $true
if (-not (Assert-True -Condition ($explicitChangedOnlyResult.ExitCode -eq 0) -FailureMessage 'Explicit -ChangedOnly validation should pass when only the touched iteration remains in scope.')) { $allChecksPassed = $false; $explicitChangedOnlyChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $explicitChangedOnlyResult.Text -Pattern '^\[validator-scope\] changed-only to origin/main\.\.\.HEAD \(1 iterations, 1 files in diff\)$' -FailureMessage 'Explicit -ChangedOnly runs should emit the changed-only scope banner as the first informational line.')) { $allChecksPassed = $false; $explicitChangedOnlyChecksPassed = $false }
if (-not (Assert-Match -Text $explicitChangedOnlyResult.Text -Pattern '\[validator\] \(1/1\) validating .*iterations[/\\]001' -FailureMessage 'Explicit -ChangedOnly validation should still validate the touched iteration.')) { $allChecksPassed = $false; $explicitChangedOnlyChecksPassed = $false }
if (-not (Assert-NotMatch -Text $explicitChangedOnlyResult.Text -Pattern 'iterations\\002' -FailureMessage 'Explicit -ChangedOnly validation should skip untouched iterations.')) { $allChecksPassed = $false; $explicitChangedOnlyChecksPassed = $false }
# The timing assertions below check mode, elapsed_ms and iterations_validated - the substance. They used
# to also match `trigger_source=local`, which is not what any of them is testing: it came along because it
# sits on the same emitted line. The validator correctly reports `ci` under CI, so the pin made these eight
# assertions UNPASSABLE in CI and unfailable locally - the census was green on this commit twice and could
# not have caught it. The pin is DROPPED rather than widened to `local|ci`: matching an environment value
# at all is the defect, and an alternation would only make the wrong assertion pass.
if (-not (Assert-Match -Text $explicitChangedOnlyResult.Text -Pattern '\[validator-timing\] mode=scoped elapsed_ms=\d+ iterations_validated=1' -FailureMessage 'Explicit -ChangedOnly validation should emit scoped timing output.')) { $allChecksPassed = $false; $explicitChangedOnlyChecksPassed = $false }
if ($explicitChangedOnlyChecksPassed) {
    Write-Pass 'Explicit -ChangedOnly still validates only the touched iteration and emits the changed-only scope banner.'
}

$autoScopedWorkspace = New-Workspace -WorkspaceName 'auto-scoped-feature-branch'
Touch-IterationForDiff -WorkspaceRoot $autoScopedWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
$autoScopedResult = Invoke-Validator -ProjectPath $autoScopedWorkspace
$autoScopedChecksPassed = $true
if (-not (Assert-True -Condition ($autoScopedResult.ExitCode -eq 0) -FailureMessage 'Feature-branch validation with no flags should auto-scope and pass when only the touched iteration remains in scope.')) { $allChecksPassed = $false; $autoScopedChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $autoScopedResult.Text -Pattern '^\[validator-scope\] auto-scoped to origin/main\.\.\.HEAD \(1 iterations, 1 files in diff\)$' -FailureMessage 'Feature-branch validation with no flags should emit the auto-scoped banner as the first informational line.')) { $allChecksPassed = $false; $autoScopedChecksPassed = $false }
if (-not (Assert-NotMatch -Text $autoScopedResult.Text -Pattern 'iterations\\002' -FailureMessage 'Auto-scoped validation should skip untouched iterations.')) { $allChecksPassed = $false; $autoScopedChecksPassed = $false }
if (-not (Assert-Match -Text $autoScopedResult.Text -Pattern '\[validator-timing\] mode=scoped elapsed_ms=\d+ iterations_validated=1' -FailureMessage 'Auto-scoped validation should emit scoped timing output.')) { $allChecksPassed = $false; $autoScopedChecksPassed = $false }
if ($autoScopedChecksPassed) {
    Write-Pass 'Feature-branch validation with no flags auto-scopes and emits the banner first.'
}

$originHeadFallbackWorkspace = New-Workspace -WorkspaceName 'missing-origin-head'
Touch-IterationForDiff -WorkspaceRoot $originHeadFallbackWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-OriginHeadTrackingRef -WorkspaceRoot $originHeadFallbackWorkspace
$originHeadFallbackResult = Invoke-Validator -ProjectPath $originHeadFallbackWorkspace
$originHeadFallbackChecksPassed = $true
if (-not (Assert-True -Condition ($originHeadFallbackResult.ExitCode -eq 0) -FailureMessage 'Auto-scoped validation should fall back from missing origin/HEAD to origin/main and still pass.')) { $allChecksPassed = $false; $originHeadFallbackChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $originHeadFallbackResult.Text -Pattern '^\[validator-scope\] auto-scoped to origin/main\.\.\.HEAD \(1 iterations, 1 files in diff\)$' -FailureMessage 'Auto-scoped validation should still resolve origin/main when origin/HEAD is absent.')) { $allChecksPassed = $false; $originHeadFallbackChecksPassed = $false }
if ($originHeadFallbackChecksPassed) {
    Write-Pass 'Auto-scoped validation falls back from missing origin/HEAD to origin/main.'
}

# Feature 203 T002 follow-up (B5F-033): the three cases above were red from 040fb169 because this repository's
# `.specify` mirror no longer matched its install record, which the fixture copies. The record is now refreshed by
# tools/maintenance/refresh-specify-mirror-record.ps1, only from an exact copy of extensions/. This case proves the
# refresh did not weaken W43: a hand edit to a deployed file, with its source unchanged, still fails the validator.
$handEditWorkspace = New-Workspace -WorkspaceName 'deployed-hand-edit'
Touch-IterationForDiff -WorkspaceRoot $handEditWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Add-Content -LiteralPath (Join-Path $handEditWorkspace '.specify\extensions\specrew-speckit\scripts\validate-governance.ps1') -Value '# hand-patched to clear a blocker; extensions/ unchanged' -Encoding UTF8
$handEditResult = Invoke-Validator -ProjectPath $handEditWorkspace -ChangedOnly -BaseBranch 'main'
$handEditChecksPassed = $true
if (-not (Assert-True -Condition ($handEditResult.ExitCode -ne 0) -FailureMessage 'A hand edit to a deployed file with its source unchanged should still fail validation.')) { $allChecksPassed = $false; $handEditChecksPassed = $false }
if (-not (Assert-Match -Text $handEditResult.Text -Pattern 'does not match what was installed \(modified: scripts/validate-governance\.ps1\)' -FailureMessage 'The hand-edited deployed file should be named as modified, and only it.')) { $allChecksPassed = $false; $handEditChecksPassed = $false }
if ($handEditChecksPassed) {
    Write-Pass 'A hand edit to a deployed file with its source unchanged still fails validation, naming the file.'
}

$fullRunWorkspace = New-Workspace -WorkspaceName 'full-run-override'
Touch-IterationForDiff -WorkspaceRoot $fullRunWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
$fullRunResult = Invoke-Validator -ProjectPath $fullRunWorkspace -FullRun
$fullRunChecksPassed = $true
if (-not (Assert-True -Condition ($fullRunResult.ExitCode -ne 0) -FailureMessage '-FullRun should bypass auto-scope and continue to validate untouched invalid iterations.')) { $allChecksPassed = $false; $fullRunChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $fullRunResult.Text -Pattern '^\[validator-scope\] closed-iteration filter: 1 closed iterations skipped' -FailureMessage '-FullRun should first report that the valid closed fixture was excluded.')) { $allChecksPassed = $false; $fullRunChecksPassed = $false }
if (-not (Assert-Match -Text $fullRunResult.Text -Pattern '(?m)^\[validator-scope\] full-repo \(-FullRun override; 2 iterations\)$' -FailureMessage '-FullRun should emit the full-repo override banner.')) { $allChecksPassed = $false; $fullRunChecksPassed = $false }
if (-not (Assert-Match -Text $fullRunResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage '-FullRun should still report untouched iteration failures.')) { $allChecksPassed = $false; $fullRunChecksPassed = $false }
if (-not (Assert-Match -Text $fullRunResult.Text -Pattern '\[validator-timing\] mode=unscoped elapsed_ms=\d+ iterations_validated=1' -FailureMessage '-FullRun should emit unscoped timing output for the one open iteration.')) { $allChecksPassed = $false; $fullRunChecksPassed = $false }
if ($fullRunChecksPassed) {
    Write-Pass '-FullRun bypasses auto-scope and emits the expected full-repo banner.'
}

$conflictingFlagsWorkspace = New-Workspace -WorkspaceName 'conflicting-flags'
$conflictingFlagsResult = Invoke-Validator -ProjectPath $conflictingFlagsWorkspace -ChangedOnly -FullRun
$conflictingFlagsChecksPassed = $true
if (-not (Assert-True -Condition ($conflictingFlagsResult.ExitCode -ne 0) -FailureMessage 'Passing both -ChangedOnly and -FullRun should fail fast.')) { $allChecksPassed = $false; $conflictingFlagsChecksPassed = $false }
if (-not (Assert-Match -Text $conflictingFlagsResult.Text -Pattern '-FullRun and -ChangedOnly are mutually exclusive' -FailureMessage 'Conflicting flag validation should explain the invalid combination clearly.')) { $allChecksPassed = $false; $conflictingFlagsChecksPassed = $false }
if ($conflictingFlagsChecksPassed) {
    Write-Pass 'Conflicting -ChangedOnly and -FullRun flags fail fast with a clear error.'
}

$mainWorkspace = New-Workspace -WorkspaceName 'main-default-full-repo'
Checkout-MainBranch -WorkspaceRoot $mainWorkspace
$mainResult = Invoke-Validator -ProjectPath $mainWorkspace
$mainChecksPassed = $true
if (-not (Assert-True -Condition ($mainResult.ExitCode -ne 0) -FailureMessage 'Main-branch validation with no flags should stay full-repo and surface untouched iteration failures.')) { $allChecksPassed = $false; $mainChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $mainResult.Text -Pattern '^\[validator-scope\] closed-iteration filter: 1 closed iterations skipped' -FailureMessage 'Main-branch validation should first report the closed iteration it excludes.')) { $allChecksPassed = $false; $mainChecksPassed = $false }
if (-not (Assert-Match -Text $mainResult.Text -Pattern '(?m)^\[validator-scope\] full-repo \(on main; 2 iterations\)$' -FailureMessage 'Main-branch validation should emit the on-main full-repo banner.')) { $allChecksPassed = $false; $mainChecksPassed = $false }
if (-not (Assert-Match -Text $mainResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage 'Main-branch validation should still report untouched iteration failures.')) { $allChecksPassed = $false; $mainChecksPassed = $false }
if ($mainChecksPassed) {
    Write-Pass 'Main-branch validation remains full-repo by default.'
}

$sessionStateWorkspace = New-Workspace -WorkspaceName 'session-state-only'
$sessionPromptPath = Join-Path $sessionStateWorkspace '.specrew\last-start-prompt.md'
if (-not (Test-Path -LiteralPath $sessionPromptPath -PathType Leaf)) {
    Set-ContentUtf8 -Path $sessionPromptPath -Content "# Session prompt fixture`n"
}
Touch-RelativeFileForDiff -WorkspaceRoot $sessionStateWorkspace -RelativePath '.specrew\last-start-prompt.md'
$sessionStateResult = Invoke-Validator -ProjectPath $sessionStateWorkspace -ChangedOnly -BaseBranch 'main'
$sessionStateChecksPassed = $true
if (-not (Assert-True -Condition ($sessionStateResult.ExitCode -eq 0) -FailureMessage 'Changed-only validation should stay scoped when only .specrew\last-start-prompt.md changes.')) { $allChecksPassed = $false; $sessionStateChecksPassed = $false }
if (-not (Assert-NotMatch -Text $sessionStateResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation:' -FailureMessage 'Session-state prompt changes should not trigger full-validation fallback.')) { $allChecksPassed = $false; $sessionStateChecksPassed = $false }
if (-not (Assert-Match -Text $sessionStateResult.Text -Pattern '\[validator-timing\] mode=scoped elapsed_ms=\d+ iterations_validated=0' -FailureMessage 'Session-state prompt changes should emit scoped timing output with zero validated iterations.')) { $allChecksPassed = $false; $sessionStateChecksPassed = $false }
if ($sessionStateChecksPassed) {
    Write-Pass 'Session-state prompt changes stay scoped and do not trigger full-validation fallback.'
}

$identityNowWorkspace = New-Workspace -WorkspaceName 'identity-now-only'
Touch-RelativeFileForDiff -WorkspaceRoot $identityNowWorkspace -RelativePath '.squad\identity\now.md'
$identityNowResult = Invoke-Validator -ProjectPath $identityNowWorkspace -ChangedOnly -BaseBranch 'main'
$identityNowChecksPassed = $true
if (-not (Assert-True -Condition ($identityNowResult.ExitCode -eq 0) -FailureMessage 'Changed-only validation should stay scoped when only .squad\identity\now.md changes.')) { $allChecksPassed = $false; $identityNowChecksPassed = $false }
if (-not (Assert-NotMatch -Text $identityNowResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation:' -FailureMessage '.squad\identity\now.md changes should not trigger full-validation fallback.')) { $allChecksPassed = $false; $identityNowChecksPassed = $false }
if (-not (Assert-Match -Text $identityNowResult.Text -Pattern '\[validator-timing\] mode=scoped elapsed_ms=\d+ iterations_validated=0' -FailureMessage '.squad\identity\now.md changes should emit scoped timing output with zero validated iterations.')) { $allChecksPassed = $false; $identityNowChecksPassed = $false }
if ($identityNowChecksPassed) {
    Write-Pass '.squad\identity\now.md changes stay scoped and do not trigger full-validation fallback.'
}

$configWorkspace = New-Workspace -WorkspaceName 'config-global-state'
Touch-RelativeFileForDiff -WorkspaceRoot $configWorkspace -RelativePath '.specrew\config.yml'
$configResult = Invoke-Validator -ProjectPath $configWorkspace -ChangedOnly -BaseBranch 'main'
$configChecksPassed = $true
if (-not (Assert-True -Condition ($configResult.ExitCode -ne 0) -FailureMessage 'Changed-only validation should fall back to unscoped validation when .specrew\config.yml changes.')) { $allChecksPassed = $false; $configChecksPassed = $false }
if (-not (Assert-Match -Text $configResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage '.specrew\config.yml changes should still validate untouched iterations and surface their failures.')) { $allChecksPassed = $false; $configChecksPassed = $false }
if (-not (Assert-Match -Text $configResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation: global-state-changed' -FailureMessage '.specrew\config.yml changes should emit the expected full-validation fallback reason.')) { $allChecksPassed = $false; $configChecksPassed = $false }
if (-not (Assert-Match -Text $configResult.Text -Pattern '\[validator-timing\] mode=unscoped elapsed_ms=\d+ iterations_validated=1' -FailureMessage '.specrew\config.yml changes should emit unscoped timing output for the open iteration.')) { $allChecksPassed = $false; $configChecksPassed = $false }
if ($configChecksPassed) {
    Write-Pass '.specrew\config.yml changes force unscoped validation so untouched iteration failures still surface.'
}

$wisdomWorkspace = New-Workspace -WorkspaceName 'wisdom-global-state'
Touch-RelativeFileForDiff -WorkspaceRoot $wisdomWorkspace -RelativePath '.squad\identity\wisdom.md'
$wisdomResult = Invoke-Validator -ProjectPath $wisdomWorkspace -ChangedOnly -BaseBranch 'main'
$wisdomChecksPassed = $true
if (-not (Assert-True -Condition ($wisdomResult.ExitCode -ne 0) -FailureMessage 'Changed-only validation should fall back to unscoped validation when .squad\identity\wisdom.md changes.')) { $allChecksPassed = $false; $wisdomChecksPassed = $false }
if (-not (Assert-Match -Text $wisdomResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage '.squad\identity\wisdom.md changes should still validate untouched iterations and surface their failures.')) { $allChecksPassed = $false; $wisdomChecksPassed = $false }
if (-not (Assert-Match -Text $wisdomResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation: global-state-changed' -FailureMessage '.squad\identity\wisdom.md changes should emit the expected full-validation fallback reason.')) { $allChecksPassed = $false; $wisdomChecksPassed = $false }
if (-not (Assert-Match -Text $wisdomResult.Text -Pattern '\[validator-timing\] mode=unscoped elapsed_ms=\d+ iterations_validated=1' -FailureMessage '.squad\identity\wisdom.md changes should emit unscoped timing output for the open iteration.')) { $allChecksPassed = $false; $wisdomChecksPassed = $false }
if ($wisdomChecksPassed) {
    Write-Pass '.squad\identity\wisdom.md changes force unscoped validation so untouched iteration failures still surface.'
}

$noRemoteWorkspace = New-Workspace -WorkspaceName 'no-remote-default-full-repo'
Touch-IterationForDiff -WorkspaceRoot $noRemoteWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-OriginRemote -WorkspaceRoot $noRemoteWorkspace
$noRemoteResult = Invoke-Validator -ProjectPath $noRemoteWorkspace
$noRemoteChecksPassed = $true
if (-not (Assert-True -Condition ($noRemoteResult.ExitCode -ne 0) -FailureMessage 'Feature-branch validation with no remote should fall back to full-repo validation.')) { $allChecksPassed = $false; $noRemoteChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $noRemoteResult.Text -Pattern '^\[validator-scope\] closed-iteration filter: 1 closed iterations skipped' -FailureMessage 'No-remote validation should first report the closed iteration it excludes.')) { $allChecksPassed = $false; $noRemoteChecksPassed = $false }
if (-not (Assert-Match -Text $noRemoteResult.Text -Pattern '(?m)^\[validator-scope\] full-repo \(base-undetectable; 2 iterations\)$' -FailureMessage 'No-remote validation should emit the base-undetectable banner.')) { $allChecksPassed = $false; $noRemoteChecksPassed = $false }
if (-not (Assert-Match -Text $noRemoteResult.Text -Pattern 'FAIL .*iterations[/\\]002' -FailureMessage 'No-remote validation should still report untouched iteration failures through the full-repo path.')) { $allChecksPassed = $false; $noRemoteChecksPassed = $false }
if (-not (Assert-Match -Text $noRemoteResult.Text -Pattern '\[validator\] Auto-scope fallback to full validation: base-ref-undetectable' -FailureMessage 'No-remote validation should emit the verbose auto-scope fallback reason.')) { $allChecksPassed = $false; $noRemoteChecksPassed = $false }
if ($noRemoteChecksPassed) {
    Write-Pass 'No-remote validation falls back to full-repo with the base-undetectable banner.'
}

$detachedWorkspace = New-Workspace -WorkspaceName 'detached-head-default-full-repo'
Touch-IterationForDiff -WorkspaceRoot $detachedWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-OriginRemote -WorkspaceRoot $detachedWorkspace
Checkout-DetachedHead -WorkspaceRoot $detachedWorkspace
$detachedResult = Invoke-Validator -ProjectPath $detachedWorkspace
$detachedChecksPassed = $true
if (-not (Assert-True -Condition ($detachedResult.ExitCode -ne 0) -FailureMessage 'Detached-HEAD validation without a detectable base should fall back to full-repo validation.')) { $allChecksPassed = $false; $detachedChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $detachedResult.Text -Pattern '^\[validator-scope\] closed-iteration filter: 1 closed iterations skipped' -FailureMessage 'Detached-HEAD validation should first report the closed iteration it excludes.')) { $allChecksPassed = $false; $detachedChecksPassed = $false }
if (-not (Assert-Match -Text $detachedResult.Text -Pattern '(?m)^\[validator-scope\] full-repo \(base-undetectable; 2 iterations\)$' -FailureMessage 'Detached-HEAD validation without a detectable base should emit the base-undetectable banner.')) { $allChecksPassed = $false; $detachedChecksPassed = $false }
if ($detachedChecksPassed) {
    Write-Pass 'Detached-HEAD validation without a detectable base falls back to full-repo with the base-undetectable banner.'
}

$fallbackWorkspace = New-Workspace -WorkspaceName 'fallback-unscoped'
Touch-IterationForDiff -WorkspaceRoot $fallbackWorkspace -RelativeIterationFile 'specs\013-validator-hardening\iterations\001\plan.md'
Remove-OriginRemote -WorkspaceRoot $fallbackWorkspace
$fallbackResult = Invoke-Validator -ProjectPath $fallbackWorkspace -ChangedOnly
$fallbackChecksPassed = $true
if (-not (Assert-True -Condition ($fallbackResult.ExitCode -ne 0) -FailureMessage 'Changed-only validation should fall back to unscoped validation when the diff base cannot be resolved.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-FirstLineMatch -Text $fallbackResult.Text -Pattern '^\[validator-scope\] closed-iteration filter: 1 closed iterations skipped' -FailureMessage 'Explicit -ChangedOnly fallback should first report the closed iteration it excludes.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern '(?m)^\[validator-scope\] full-repo \(base-undetectable; 2 iterations\)$' -FailureMessage 'Explicit -ChangedOnly fallback should emit the base-undetectable full-repo banner when the base cannot be resolved.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-NotMatch -Text $fallbackResult.Text -Pattern '\[validator\].*validating .*iterations[/\\]001' -FailureMessage 'Base-resolution fallback should exclude the closed touched iteration from the unscoped validation loop.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern 'iterations[/\\]002' -FailureMessage 'Base-resolution fallback should validate untouched iterations through the unscoped path.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern '\[validator\] -ChangedOnly fallback to full validation: base-ref-undetectable' -FailureMessage 'Base-resolution fallback should emit the expected verbose fallback reason.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if (-not (Assert-Match -Text $fallbackResult.Text -Pattern '\[validator-timing\] mode=unscoped elapsed_ms=\d+ iterations_validated=1' -FailureMessage 'Base-resolution fallback should emit unscoped timing output for the open iteration.')) { $allChecksPassed = $false; $fallbackChecksPassed = $false }
if ($fallbackChecksPassed) {
    Write-Pass 'Changed-only mode falls back to full validation with a base-undetectable banner when the PR base ref cannot be resolved.'
}

if (-not $allChecksPassed) {
    # Kept for diagnosis; it is a uniquely named temp folder this run created.
    Write-Host ("Fixture workspaces kept for inspection: {0}" -f $scratchRoot)
    exit 1
}

Reset-ScratchRoot -Path $scratchRoot
Write-Pass 'Changed-only governance validation covers scoped iterations, global-state fallback, and full-validation fallback.'
exit 0
