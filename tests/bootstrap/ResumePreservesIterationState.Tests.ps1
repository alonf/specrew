$ErrorActionPreference = 'Stop'

# F-174 / DF-006 (handoff from F-182). REGRESSION floor for "the session-start rewrite must NOT reset
# done->not-started on resume". The F-182 dogfood hit a `specrew start` that re-scaffolded committed iteration
# state, clobbering state.md + tasks-progress.yml back to "not-started / pending" and leaving tasks.md "planned".
# F-174 owns the session-start/state rewrite, so it must PROVE its resume path is non-destructive: running the
# bootstrap (full OR welcome-back) leaves committed iteration artifacts BYTE-IDENTICAL - it never regenerates them.

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HostEventAdapter.ps1"
. "$base/SessionStateAccessor.ps1"
. "$base/ProjectMetadataAccessor.ps1"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
. "$base/ValidationEngine.ps1"
. "$base/DirectiveEngine.ps1"
. "$base/SessionBootstrapManager.ps1"

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }
function Assert-Equal { param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message) if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$evt = '{"session_id":"sess-1","source":"startup","hook_event_name":"SessionStart"}'
$root = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-df006-" + [guid]::NewGuid().ToString('N'))
$iterDir = Join-Path $root 'specs/feat-x/iterations/001'
New-Item -ItemType Directory -Path $iterDir -Force | Out-Null
# Hermetic: its own repo root (round-6 lesson) so the bootstrap's internal git delta scans THIS tiny tree.
& git -C $root init -q 2>$null | Out-Null
& git -C $root -c user.email='t@t' -c user.name='t' commit -q --allow-empty -m init 2>$null | Out-Null

# Committed iteration state in a DONE / implementation-complete shape - the exact thing DF-006 saw clobbered.
$stateMd = @(
    '# Iteration State: 001', '', '**Current Phase**: implement', '**Iteration Status**: executing',
    '**Last Completed Task**: T015 - final task done', '**Tasks Remaining**: (none)'
) -join "`n"
$tasksProgress = @(
    'schema: v1', 'tasks:', '  - id: T001', '    status: completed', '  - id: T002', '    status: completed',
    '  - id: T015', '    status: completed'
) -join "`n"
$tasksMd = @('# Tasks: feat-x', '', '- [x] T001 done', '- [x] T002 done', '- [x] T015 done') -join "`n"
$stateMdPath = Join-Path $iterDir 'state.md'
$tasksProgressPath = Join-Path $iterDir 'tasks-progress.yml'
$tasksMdPath = Join-Path $root 'specs/feat-x/tasks.md'
Set-Content -LiteralPath $stateMdPath -Value $stateMd -Encoding UTF8
Set-Content -LiteralPath $tasksProgressPath -Value $tasksProgress -Encoding UTF8
Set-Content -LiteralPath $tasksMdPath -Value $tasksMd -Encoding UTF8

# Hash the committed iteration artifacts BEFORE any bootstrap.
$watched = @($stateMdPath, $tasksProgressPath, $tasksMdPath)
$before = @{}
foreach ($p in $watched) { $before[$p] = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }

# A valid, portable anchor naming feat-x -> the bootstrap resolves the RESUME (welcome-back) path.
@{ session_state = @{ active = $true; feature_ref = 'feat-x'; feature_path = (Join-Path $root 'specs/feat-x'); boundary_type = 'implement'; iteration_number = '001'; auth_commit_hash = 'x'; recorded_at = 't' } } |
    ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'start-context.json') -Encoding UTF8

try {
    # 1. RESUME (welcome-back): the primary DF-006 scenario.
    $r = Invoke-SpecrewSessionBootstrap -RawEvent $evt -HostName claude -ProjectRoot $root -StatePath (Join-Path $root 'start-context.json') -BaseBranch 'main'
    Assert-Equal $r.mode 'welcome-back' 'valid anchor resolves the RESUME (welcome-back) path'
    foreach ($p in $watched) {
        $after = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
        Assert-Equal $after $before[$p] ("resume left $(Split-Path $p -Leaf) BYTE-IDENTICAL (not regenerated/clobbered)")
    }
    # The done-state tokens survive; no not-started/pending regression was written.
    $stateNow = Get-Content -LiteralPath $stateMdPath -Raw
    Assert-True ($stateNow -match 'T015 - final task done') 'state.md still records the completed final task'
    Assert-True (-not ($stateNow -match 'not-started|not started')) 'state.md was NOT reset to not-started'
    $progNow = Get-Content -LiteralPath $tasksProgressPath -Raw
    Assert-Equal (([regex]::Matches($progNow, 'status: completed')).Count) 3 'tasks-progress.yml still shows all 3 tasks completed (no done->pending reset)'
    Assert-True (-not ($progNow -match 'status:\s*(pending|not-started)')) 'tasks-progress.yml has NO pending/not-started regression'

    # 2. FULL (no anchor): the bootstrap must be non-destructive on the cold path too.
    $r2 = Invoke-SpecrewSessionBootstrap -RawEvent $evt -HostName claude -ProjectRoot $root -StatePath (Join-Path $root 'absent.json') -BaseBranch 'main'
    Assert-Equal $r2.mode 'full' 'no anchor resolves the full bootstrap path'
    foreach ($p in $watched) {
        $after = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
        Assert-Equal $after $before[$p] ("full bootstrap also left $(Split-Path $p -Leaf) byte-identical")
    }
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "`n=== ResumePreservesIterationState.Tests.ps1: all assertions passed ===" -ForegroundColor Green
