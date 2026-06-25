$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-197 human-gated co-review status protocol (the host-neutral JOIN, 2026-06-26).
#
# The review fires async in an ISOLATED process and the human drives the poll by typing 'continue' (the only
# wake mechanism present on ALL hosts - the survey proved no portable auto-wake). For that to work, the
# navigator must REPORT status on every Stop/continue instead of leaving a running review silent. This pins
# the three new status notes + the one guard that keeps them off the cross-session sweep:
#   1. on FIRE              -> "[co-review] fired (run X) ... say 'continue' to check"
#   2. on reap, STILL RUNNING -> "[co-review] run X is still reviewing ... say 'continue'"
#   3. on reap, DEAD/crashed  -> "[co-review] run X did not finish ... INCONCLUSIVE (not a pass)"
#   guard: notes 2+3 fire ONLY on a normal Stop reap, NEVER on the SessionStart cross-session sweep (cleanup).

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
$env:SPECREW_MODULE_PATH = $repoRoot
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/_load.ps1')
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

function New-PendingRepo {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('hgstatus-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew/review/pending') -Force | Out-Null
    return $root
}
function Add-PendingEntry {
    param([string]$Root, [string]$RunId, [int]$SupervisorPid, [string]$Status = 'running')
    $pendingDir = Join-Path $Root '.specrew/review/pending'
    ([ordered]@{
            schema_version = '1.0'
            run_id         = $RunId
            supervisor_pid = $SupervisorPid
            worktree_path  = (Join-Path ([System.IO.Path]::GetTempPath()) ('hg-wt-' + [guid]::NewGuid().ToString('N')))
            run_dir        = (Join-Path $pendingDir $RunId)
            deadline       = ((Get-Date).ToUniversalTime().AddMinutes(10).ToString('o'))  # NOT past-deadline
            status         = $Status
            tree_id        = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
        } | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $pendingDir "$RunId.json") -Encoding UTF8
}

# --- (2) STILL RUNNING: a live supervisor (a sleeper) -> reap leaves it pending AND says "still reviewing". ---
$running = New-PendingRepo
$sleeper = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 60') -PassThru -WindowStyle Hidden
try {
    Add-PendingEntry -Root $running -RunId 'run-running' -SupervisorPid $sleeper.Id -Status 'running'
    $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $running -CrossSession:$false -TrunkName 'main' -Now ([datetime]::UtcNow)
    Assert-True (@($reap.inject_notes | Where-Object { $_ -match 'run-running' -and $_ -match 'still reviewing' }).Count -ge 1) "(2) a still-running review reports 'still reviewing' on a normal Stop reap"
    Assert-True (@($reap.reaped_run_ids) -notcontains 'run-running') "(2) the still-running review is NOT reaped (left pending, correctly)"
}
finally { try { Stop-Process -Id $sleeper.Id -Force -ErrorAction SilentlyContinue } catch { } ; Remove-Item -LiteralPath $running -Recurse -Force -ErrorAction SilentlyContinue }

# --- (3) DEAD/crashed: a supervisor that has exited -> reap says INCONCLUSIVE on a normal reap... ---
$dead = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'exit 0') -PassThru -WindowStyle Hidden
$dead.WaitForExit(); Start-Sleep -Milliseconds 300   # ensure the pid is gone (presence='absent')
$crashed = New-PendingRepo
try {
    Add-PendingEntry -Root $crashed -RunId 'run-dead' -SupervisorPid $dead.Id -Status 'running'
    $reapNormal = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $crashed -CrossSession:$false -TrunkName 'main' -Now ([datetime]::UtcNow)
    Assert-True (@($reapNormal.inject_notes | Where-Object { $_ -match 'run-dead' -and $_ -match 'INCONCLUSIVE' }).Count -ge 1) "(3) a dead reviewer reports INCONCLUSIVE (not a silent pass) on a normal Stop reap"

    # ...but is SILENT on the cross-session SessionStart sweep (cleanup of a prior session's orphan).
    Add-PendingEntry -Root $crashed -RunId 'run-dead' -SupervisorPid $dead.Id -Status 'running'   # re-plant (normal reap cleared it)
    $reapSweep = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $crashed -CrossSession:$true -TrunkName 'main' -Now ([datetime]::UtcNow)
    Assert-True (@($reapSweep.inject_notes | Where-Object { $_ -match 'INCONCLUSIVE' }).Count -eq 0) "(guard) the INCONCLUSIVE note is SILENT on the cross-session sweep (cleanup, not current status)"
}
finally { Remove-Item -LiteralPath $crashed -Recurse -Force -ErrorAction SilentlyContinue }

# --- (1) FIRE: a real checkpoint fire reports it is in-flight + how to drive the poll. ---
$fireRepo = Join-Path ([System.IO.Path]::GetTempPath()) ('hgfire-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $fireRepo 'src') -Force | Out-Null
try {
    & git -C $fireRepo init -q 2>&1 | Out-Null
    & git -C $fireRepo branch -m main 2>&1 | Out-Null
    Set-Content -LiteralPath (Join-Path $fireRepo 'src/app.txt') -Value 'base' -Encoding UTF8 -NoNewline
    & git -C $fireRepo -c user.name='t' -c user.email='t@t' add -A 2>&1 | Out-Null
    & git -C $fireRepo -c user.name='t' -c user.email='t@t' commit -q -m trunk 2>&1 | Out-Null
    & git -C $fireRepo -c user.name='t' -c user.email='t@t' checkout -q -b feature 2>&1 | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fireRepo '.specrew/runtime') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $fireRepo '.specrew/start-context.json') -Value (([ordered]@{ session_state = [ordered]@{ boundary_type = 'before-implement' } }) | ConvertTo-Json -Depth 6) -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fireRepo 'src/app.txt') -Value 'changed-for-review' -Encoding UTF8 -NoNewline
    & git -C $fireRepo -c user.name='t' -c user.email='t@t' add -A 2>&1 | Out-Null
    & git -C $fireRepo -c user.name='t' -c user.email='t@t' commit -q -m inc 2>&1 | Out-Null

    $dummy = "`$v = [ordered]@{ schema_version='1.0'; status='no_findings'; disposition='pass'; blocking=`$false; findings=@() }; [Console]::Out.Write((`$v | ConvertTo-Json -Depth 6 -Compress))"
    $fire = Invoke-ContinuousCoReviewNavigator -RepoRoot $fireRepo -TimeoutSec 30 -TrunkName 'main' -ReviewerCommandOverride $dummy
    Assert-True ($fire.action -eq 'fired') "(1) a real checkpoint fires"
    Assert-True (@($fire.inject_notes | Where-Object { $_ -match $fire.fired_run_id -and $_ -match "say 'continue'" }).Count -ge 1) "(1) the fire reports the review is in-flight + says 'continue' to check"
}
finally { Remove-Item -LiteralPath $fireRepo -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "`n=== human-gated-status-notes.tests.ps1: all assertions passed ===" -ForegroundColor Green
