# Paired honesty tests for the tracker-only evidence bypass (F-198 FR-020 / SC-005,
# NFR-007): reconcile-toward-truth is accepted AND falsify-forward stales; every parse
# ambiguity fails closed. Uses a real temp git repo so the tree-object reads are the
# genuine article. The live gate wiring is additionally proven at this iteration's own
# signoff (the bypass announces itself in the gate message).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\continuous-co-review\checkpoint-diff-provider.ps1')
. (Join-Path $repoRoot 'scripts\internal\continuous-co-review\tracker-honesty-check.ps1')
$script:failCount = 0

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }

$fx = Join-Path ([System.IO.Path]::GetTempPath()) ("tracker-honesty-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path (Join-Path $fx 'specs\demo\iterations\001') | Out-Null
Set-Location $fx
git init --quiet
git config user.email 'fixture@test'; git config user.name 'fixture'

function Save-Tree {
    git add -A 2>$null | Out-Null
    git commit --allow-empty -m 'tree' --quiet
    (git write-tree)
}

# Reviewed tree: accepted review (T001 pass, T002 needs-work) + trackers mid-flight.
@'
# Review: Iteration 001

**Overall Verdict**: accepted

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001 | pass | done |
| T002 | FR-002 | needs-work | not yet |
'@ | Set-Content 'specs\demo\iterations\001\review.md'
@'
# Iteration State: 001

**Iteration Status**: executing
**Last Completed Task**: (none)
'@ | Set-Content 'specs\demo\iterations\001\state.md'
"T001: in-progress`nT002: planned" | Set-Content 'specs\demo\iterations\001\tasks-progress.yml'
'source content v1' | Set-Content 'app.txt'
$reviewedTree = Save-Tree

Write-Host "Test 1: reconcile-toward-truth is honest (paired: legitimate path works)"
"T001: done`nT002: planned" | Set-Content 'specs\demo\iterations\001\tasks-progress.yml'
@'
# Iteration State: 001

**Iteration Status**: executing
**Last Completed Task**: T001
'@ | Set-Content 'specs\demo\iterations\001\state.md'
$honestTree = Save-Tree
$delta = Get-ContinuousCoReviewTrackerOnlyDelta -RepoRoot $fx -FromTreeId $reviewedTree -ToTreeId $honestTree
if (-not $delta.TrackerOnly) { Write-Fail "tracker-only delta not recognized: $($delta | ConvertTo-Json -Compress)" }
else {
    $h = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $fx -FromTreeId $reviewedTree -ToTreeId $honestTree -TrackerPaths @($delta.Paths)
    if (-not $h.Honest) { Write-Fail "reconcile-toward-truth judged dishonest: $($h.Reason)" }
    else { Write-Pass "T001-done reconcile (accepted pass verdict) is honest; evidence would stay fresh" }
}

Write-Host "Test 2: falsify-forward stales (paired: abuse fails)"
"T001: done`nT002: done" | Set-Content 'specs\demo\iterations\001\tasks-progress.yml'
$falsifyTree = Save-Tree
$delta = Get-ContinuousCoReviewTrackerOnlyDelta -RepoRoot $fx -FromTreeId $reviewedTree -ToTreeId $falsifyTree
$h = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $fx -FromTreeId $reviewedTree -ToTreeId $falsifyTree -TrackerPaths @($delta.Paths)
if ($h.Honest) { Write-Fail "T002-done (needs-work in the accepted review) was accepted - false green" }
elseif ($h.Reason -notmatch 'T002') { Write-Fail "dishonest reason must name the offending task: $($h.Reason)" }
else { Write-Pass "claims-increasing edit (T002 done without a pass verdict) judged dishonest: stales" }

Write-Host "Test 3: a mixed delta (tracker + source) is never tracker-only"
'source content v2' | Set-Content 'app.txt'
$mixedTree = Save-Tree
$delta = Get-ContinuousCoReviewTrackerOnlyDelta -RepoRoot $fx -FromTreeId $reviewedTree -ToTreeId $mixedTree
if ($delta.TrackerOnly) { Write-Fail "mixed delta reported tracker-only" } else { Write-Pass "mixed delta falls through to the normal stale path" }
git checkout --quiet -- 'app.txt' 2>$null; 'source content v1' | Set-Content 'app.txt'

Write-Host "Test 4: unparseable tracker shape fails closed"
"T001: done`nsome free prose line" | Set-Content 'specs\demo\iterations\001\tasks-progress.yml'
$junkTree = Save-Tree
$delta = Get-ContinuousCoReviewTrackerOnlyDelta -RepoRoot $fx -FromTreeId $reviewedTree -ToTreeId $junkTree
$h = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $fx -FromTreeId $reviewedTree -ToTreeId $junkTree -TrackerPaths @($delta.Paths)
if ($h.Honest) { Write-Fail "unparseable tracker accepted - fail-open" } else { Write-Pass "non-canonical tracker shape declines the bypass (fail-closed)" }

Write-Host "Test 5: state.md 'complete' claim needs the accepted overall verdict"
"T001: in-progress`nT002: planned" | Set-Content 'specs\demo\iterations\001\tasks-progress.yml'
@'
# Iteration State: 001

**Iteration Status**: complete
**Last Completed Task**: (none)
'@ | Set-Content 'specs\demo\iterations\001\state.md'
$completeTree = Save-Tree
$delta = Get-ContinuousCoReviewTrackerOnlyDelta -RepoRoot $fx -FromTreeId $reviewedTree -ToTreeId $completeTree
$h = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $fx -FromTreeId $reviewedTree -ToTreeId $completeTree -TrackerPaths @($delta.Paths)
if (-not $h.Honest) { Write-Fail "complete claim with an ACCEPTED review judged dishonest: $($h.Reason)" }
else { Write-Pass "state.md complete claim is honest when the accepted review verdict is accepted" }

Write-Host "Test 6: missing accepted review record fails closed"
New-Item -ItemType Directory -Force -Path (Join-Path $fx 'specs\demo\iterations\002') | Out-Null
"T001: planned" | Set-Content 'specs\demo\iterations\002\tasks-progress.yml'
$noReviewBase = Save-Tree
"T001: done" | Set-Content 'specs\demo\iterations\002\tasks-progress.yml'
$noReviewEdit = Save-Tree
$h = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $fx -FromTreeId $noReviewBase -ToTreeId $noReviewEdit -TrackerPaths @('specs/demo/iterations/002/tasks-progress.yml')
if ($h.Honest) { Write-Fail "bypass granted with no accepted review record beside the tracker" } else { Write-Pass "no accepted review record beside the tracker declines the bypass (fail-closed)" }

Set-Location $repoRoot
Remove-Item -Recurse -Force $fx

Write-Host ""
if ($script:failCount -gt 0) { Write-Host "$script:failCount test(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "All tracker-honesty paired tests passed." -ForegroundColor Green
exit 0
