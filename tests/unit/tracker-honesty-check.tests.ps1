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

# DEC-198-I003: the honesty parser must fail-closed on non-canonical / unmapped / injected
# claim shapes (co-review catch: extract-and-ignore was a false-green door contradicting the
# TrackerClaims data model + the module's own I3 fail-direction). Each abuse below is a clean
# tracker-only delta whose ONLY change is the abusive claim; each must DECLINE the bypass.
function New-AbuseFixture {
    param([string]$Iter, [string]$BaselineTracker, [string]$BaselineContent, [string]$AbuseContent)
    $dir = "specs\demo\iterations\$Iter"
    New-Item -ItemType Directory -Force -Path (Join-Path $fx $dir) | Out-Null
    @"
# Review: Iteration $Iter

**Overall Verdict**: accepted

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001 | pass | done |
"@ | Set-Content (Join-Path $dir 'review.md')
    $BaselineContent | Set-Content (Join-Path $dir $BaselineTracker)
    $base = Save-Tree
    $AbuseContent | Set-Content (Join-Path $dir $BaselineTracker)
    $abuse = Save-Tree
    $delta = Get-ContinuousCoReviewTrackerOnlyDelta -RepoRoot $fx -FromTreeId $base -ToTreeId $abuse
    [pscustomobject]@{ Base = $base; Abuse = $abuse; Delta = $delta }
}

Write-Host "Test 7: non-canonical Iteration Status in state.md fails closed (canonical-enum requirement)"
$f7 = New-AbuseFixture -Iter '010' -BaselineTracker 'state.md' `
    -BaselineContent "# Iteration State: 010`n`n**Iteration Status**: executing`n**Last Completed Task**: (none)`n" `
    -AbuseContent    "# Iteration State: 010`n`n**Iteration Status**: shipped`n**Last Completed Task**: (none)`n"
$h = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $fx -FromTreeId $f7.Base -ToTreeId $f7.Abuse -TrackerPaths @($f7.Delta.Paths)
if (-not $f7.Delta.TrackerOnly) { Write-Fail "Test 7 delta not tracker-only: $($f7.Delta | ConvertTo-Json -Compress)" }
elseif ($h.Honest) { Write-Fail "non-canonical Iteration Status 'shipped' passed as honest - fail-open" }
else { Write-Pass "non-canonical Iteration Status declines the bypass (fail-closed)" }

Write-Host "Test 8: non-canonical task status in tasks-progress.yml fails closed"
$f8 = New-AbuseFixture -Iter '011' -BaselineTracker 'tasks-progress.yml' `
    -BaselineContent "T001: planned`n" -AbuseContent "T001: shipped`n"
$h = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $fx -FromTreeId $f8.Base -ToTreeId $f8.Abuse -TrackerPaths @($f8.Delta.Paths)
if ($h.Honest) { Write-Fail "non-canonical task status 'shipped' passed as honest - fail-open" }
else { Write-Pass "non-canonical task status declines the bypass (fail-closed)" }

Write-Host "Test 9: unrecognized Last Completed Task free-text fails closed"
$f9 = New-AbuseFixture -Iter '012' -BaselineTracker 'state.md' `
    -BaselineContent "# Iteration State: 012`n`n**Iteration Status**: executing`n**Last Completed Task**: (none)`n" `
    -AbuseContent    "# Iteration State: 012`n`n**Iteration Status**: executing`n**Last Completed Task**: everything shipped and complete`n"
$h = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $fx -FromTreeId $f9.Base -ToTreeId $f9.Abuse -TrackerPaths @($f9.Delta.Paths)
if ($h.Honest) { Write-Fail "unrecognized Last Completed Task free-text passed as honest - fail-open" }
else { Write-Pass "unrecognized Last Completed Task claim shape declines the bypass (fail-closed)" }

Write-Host "Test 10: an injected capacity claim in state.md fails closed (foreign TrackerClaim)"
$f10 = New-AbuseFixture -Iter '013' -BaselineTracker 'state.md' `
    -BaselineContent "# Iteration State: 013`n`n**Iteration Status**: executing`n**Last Completed Task**: (none)`n" `
    -AbuseContent    "# Iteration State: 013`n`n**Iteration Status**: executing`n**Last Completed Task**: (none)`n**Capacity**: 99/26 story_points`n"
$h = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $fx -FromTreeId $f10.Base -ToTreeId $f10.Abuse -TrackerPaths @($f10.Delta.Paths)
if ($h.Honest) { Write-Fail "injected capacity claim passed as honest - fail-open" }
else { Write-Pass "injected capacity claim (foreign to the tracker) declines the bypass (fail-closed)" }

Write-Host "Test 11: the legitimate canonical reconcile STILL passes (paired: fix did not over-close)"
$f11 = New-AbuseFixture -Iter '014' -BaselineTracker 'tasks-progress.yml' `
    -BaselineContent "T001: in-progress`n" -AbuseContent "T001: done`n"
$h = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $fx -FromTreeId $f11.Base -ToTreeId $f11.Abuse -TrackerPaths @($f11.Delta.Paths)
if (-not $h.Honest) { Write-Fail "canonical T001->done reconcile (accepted pass) wrongly declined after the fix: $($h.Reason)" }
else { Write-Pass "canonical reconcile still honest - the fix fails closed on abuse without over-closing the legitimate path" }

Set-Location $repoRoot
Remove-Item -Recurse -Force $fx

Write-Host ""
if ($script:failCount -gt 0) { Write-Host "$script:failCount test(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "All tracker-honesty paired tests passed." -ForegroundColor Green
exit 0
