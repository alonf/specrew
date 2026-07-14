[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# DRIFT-198-I003-009 (2026-07-14): Update-IterationStateFromTaskProgress previously replaced the ENTIRE
# '## Execution Summary' section (everything up to the next '## ' heading) with three generated bullets on
# EVERY task-progress sync — silently destroying the hand-authored execution narrative (the observed
# iteration-003/005 committed-state truncations: a rich ~600-line execution record collapsed to a thin
# machinery digest). This focused suite proves the fix at the function seam, with no bootstrap dependency:
# the generated digest lives in a marker-bounded MANAGED block, user narrative survives every sync, refreshes
# are idempotent, and the legacy machinery-owned shapes (generated digest / scaffold placeholder) migrate.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\task-progress.ps1')

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('tp-managed-summary-' + [guid]::NewGuid().ToString('N'))
$iterDir = Join-Path $scratch 'specs\099-fixture\iterations\001'
New-Item -ItemType Directory -Path $iterDir -Force | Out-Null

$tasks = [ordered]@{
    'T001' = [ordered]@{ title = 'first'; status = 'done'; started_at = ''; completed_at = '2026-07-14T10:00:00Z'; blocked_reason = '' }
    'T002' = [ordered]@{ title = 'second'; status = 'in-progress'; started_at = ''; completed_at = ''; blocked_reason = '' }
    'T003' = [ordered]@{ title = 'third'; status = 'pending'; started_at = ''; completed_at = ''; blocked_reason = '' }
}

function Invoke-Update {
    Update-IterationStateFromTaskProgress -ProjectRoot $scratch -FeatureRef '099-fixture' -IterationNumber '001' -Tasks $tasks -ResolvedFeaturePath (Join-Path $scratch 'specs\099-fixture') | Out-Null
}

try {
    $statePath = Join-Path $iterDir 'state.md'
    $sentinelA = 'Piece 3 DONE - the navigator FIRE decision consumes the per-lineage lease (narrative sentinel 7719).'
    $sentinelB = 'Co-review catch before T013 code (run 1446b84c, blocking) - fixed in place (narrative sentinel 7720).'

    # ---- Case 1: RICH hand-authored narrative under Execution Summary survives a sync; digest lands in the
    #      managed block ABOVE it.
    @(
        '# Iteration State: 001'
        ''
        '**Schema**: v1'
        '**Last Completed Task**: T001'
        '**Tasks Remaining**: T003'
        '**In Progress**: T002'
        '**Baseline Ref**: abc1234'
        '**Updated**: 2026-07-14T09:00:00Z'
        ''
        '## Execution Summary'
        ''
        ('- ' + $sentinelA)
        ''
        '### A rich subsection the machinery must never eat'
        ''
        ('- ' + $sentinelB)
        ''
        '## Notes'
        ''
        '- A note that lives in its own section.'
    ) -join [Environment]::NewLine | Set-Content -LiteralPath $statePath -Encoding UTF8

    Invoke-Update
    $after1 = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
    if ($after1 -notmatch [regex]::Escape($sentinelA) -or $after1 -notmatch [regex]::Escape($sentinelB)) {
        Fail 'Case 1: a task-progress sync destroyed hand-authored Execution Summary narrative.'
    }
    if ($after1 -notmatch [regex]::Escape('<!-- specrew:task-progress-summary:begin -->') -or $after1 -notmatch 'Task progress: 1 complete, 1 in-progress, 1 pending, 0 blocked') {
        Fail 'Case 1: the generated digest must be present in its marker-bounded managed block.'
    }
    if ($after1 -notmatch '- A note that lives in its own section\.') {
        Fail 'Case 1: sections beyond Execution Summary must be untouched.'
    }
    Write-Pass 'Case 1: rich narrative survives a sync; the managed digest is added above it'

    # ---- Case 2: a SECOND sync refreshes the managed block IN PLACE (idempotent; narrative still intact).
    $tasks['T002'].status = 'done'; $tasks['T002'].completed_at = '2026-07-14T11:00:00Z'
    Invoke-Update
    $after2 = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
    if ($after2 -notmatch [regex]::Escape($sentinelA) -or $after2 -notmatch [regex]::Escape($sentinelB)) {
        Fail 'Case 2: the second sync destroyed the narrative.'
    }
    if (([regex]::Matches($after2, [regex]::Escape('<!-- specrew:task-progress-summary:begin -->'))).Count -ne 1) {
        Fail 'Case 2: repeated syncs must refresh ONE managed block, never accumulate duplicates.'
    }
    if ($after2 -notmatch 'Task progress: 2 complete, 0 in-progress, 1 pending, 0 blocked') {
        Fail 'Case 2: the managed block must carry the REFRESHED digest.'
    }
    Write-Pass 'Case 2: the managed block refreshes in place (idempotent) and the narrative survives'

    # ---- Case 3: MIGRATION - a machinery-owned body (the scaffold placeholder) is replaced wholesale
    #      (no stale scaffold text left behind; the pre-fix contract for machinery-owned content is kept).
    @(
        '# Iteration State: 001'
        ''
        '**Schema**: v1'
        '**Baseline Ref**: abc1234'
        '**Updated**: 2026-07-14T09:00:00Z'
        ''
        '## Execution Summary'
        ''
        '- Execution has not started yet.'
        '- This artifact was scaffolded before task execution so resume state can be updated after each task.'
    ) -join [Environment]::NewLine | Set-Content -LiteralPath $statePath -Encoding UTF8
    Invoke-Update
    $after3 = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
    if ($after3 -match 'Execution has not started yet' -or $after3 -match 'scaffolded before task execution') {
        Fail 'Case 3: a machinery-owned scaffold body must be migrated wholesale into the managed digest.'
    }
    if ($after3 -notmatch 'Task progress: 2 complete') {
        Fail 'Case 3: the managed digest must be present after migration.'
    }
    Write-Pass 'Case 3: machinery-owned scaffold text migrates wholesale (no stale placeholder survives)'

    # ---- Case 4: no Execution Summary section at all -> a fresh one is appended with only the managed block.
    @(
        '# Iteration State: 001'
        ''
        '**Schema**: v1'
        '**Baseline Ref**: abc1234'
        '**Updated**: 2026-07-14T09:00:00Z'
    ) -join [Environment]::NewLine | Set-Content -LiteralPath $statePath -Encoding UTF8
    Invoke-Update
    $after4 = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
    if ($after4 -notmatch '## Execution Summary' -or $after4 -notmatch [regex]::Escape('<!-- specrew:task-progress-summary:end -->')) {
        Fail 'Case 4: a missing Execution Summary section must be appended with the managed block.'
    }
    Write-Pass 'Case 4: a missing Execution Summary section is appended cleanly'

    Write-Host ''
    Write-Host '=== task-progress-managed-summary.tests.ps1: all assertions passed ===' -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
