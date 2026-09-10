# FIX 5, REVERSED ONTO BETA4: the seal is written at AUTHORIZATION, never at arrival, and every other
# writer either never touches a sealed iteration or skips it.
#
# The root, measured on a consumer project (B4F-063): the closeout sync sealed the iteration at the
# boundary's ARRIVAL, freezing `Iteration Status: retro` in; the human's verdict then established
# `complete`, the capture's advance wrote it, and the arrival-time seal flagged the verdict's own write; a
# later session's resume wrote `ready-for-review` and tripped it again. A seal that freezes a pre-verdict
# value is wrong regardless. So: the seal is the closeout verdict capture's LAST act, after its own
# advance; the resume's task-progress writers SKIP a sealed iteration and journal the skip; `specrew reseal`
# is the human's move for iterations sealed before this rule, and the trust-hardening refusal names it.
#
# -MutateSealAtArrival puts the old ordering back (sealed on arrival, nothing at authorization): Case 1 and
# Case 1b go red - the verdict's own advance is flagged as tampering, at the next iteration's plan sync too.
# -MutateNoSkip removes the sealed check from the resume path: Case 2 goes red.
# Each leaves every other case green, which is the discrimination the ruling asked for.

param([switch] $MutateSealAtArrival, [switch] $MutateNoSkip)

$ErrorActionPreference = 'Stop'
$script:Failures = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host ("  PASS: {0}" -f $Message) }
    else { Write-Host ("  FAIL: {0}" -f $Message); $script:Failures++ }
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$governance = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1'
$taskProgress = Join-Path $repoRoot 'scripts/internal/task-progress.ps1'
$validator = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/validate-governance.ps1'
$front = Join-Path $repoRoot 'scripts/specrew.ps1'

Write-Host 'sealed-iteration-writers'
Write-Host '  --- preconditions ---'
foreach ($f in @($governance, $taskProgress, $validator, $front)) { Assert-True (Test-Path -LiteralPath $f -PathType Leaf) ('present: ' + (Split-Path -Leaf $f)) }
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE'; exit 1 }
. $governance
. $taskProgress

if ($MutateSealAtArrival) {
    # THE MUTATION: the pre-fix ordering. The fixture seals at arrival (below, on this switch) and the
    # authorization's last act is a no-op - exactly what stood before, one function.
    function Invoke-SpecrewCloseoutSeal { param($ProjectRoot, $IterationDirectory, $Feature, $Iteration) return $null }
    Write-Host '  (MUTATION ACTIVE: sealed at arrival, nothing at authorization)'
}
if ($MutateNoSkip) {
    # THE MUTATION, at the SITE: task-progress.ps1 with both sealed guards removed - the pre-fix resume path -
    # loaded from a temp copy beside the original so its own dot-source of shared-governance still resolves.
    $sealedGuard = 'if \(\(Get-Command -Name ''Test-SpecrewIterationSealed'' -ErrorAction SilentlyContinue\) -and \(Test-SpecrewIterationSealed -IterationDirectory \(Split-Path -Parent \$(statePath|path)\)\)\) \{'
    $mutantText = (Get-Content -LiteralPath $taskProgress -Raw -Encoding UTF8) -replace $sealedGuard, 'if ($false) {'
    if ($mutantText -match 'Test-SpecrewIterationSealed') { Write-Host '  FAIL: the mutation did not remove both sealed guards'; exit 1 }
    $mutantPath = Join-Path (Split-Path -Parent $taskProgress) '_mutant-task-progress.ps1'
    [IO.File]::WriteAllText($mutantPath, $mutantText, [Text.UTF8Encoding]::new($false))
    try { . $mutantPath } finally { Remove-Item -LiteralPath $mutantPath -Force -ErrorAction SilentlyContinue }
    Write-Host '  (MUTATION ACTIVE: the sealed check is gone from the resume path''s two writers)'
}

function Get-FileHashes {
    param([string]$Directory)
    $map = @{}
    foreach ($f in @(Get-ChildItem -LiteralPath $Directory -File -Force | Where-Object { $_.Name -cne '.specrew-iteration-seal.json' })) {
        $map[$f.Name] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    }
    return $map
}

function New-ClosedIterationProject {
    # A project with one feature, one iteration that has ARRIVED at iteration-closeout: plan.md with a tasks
    # table, tasks.md with every task checked, tasks-progress.yml, state.md at retro (the shape the consumer
    # was in), the closed-index entry written, the dashboard rendered - and NO seal, because the seal is the
    # verdict's, not the arrival's. -SealedAtArrival builds the pre-fix (and beta3-consumer) shape instead.
    param([switch] $SealedAtArrival)
    $root = Join-Path ([IO.Path]::GetTempPath()) ('siw-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $iter = Join-Path $root 'specs/001-fixture/iterations/001'
    New-Item -ItemType Directory -Path $iter -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
    $utf8 = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/spec.md'), "# Feature Specification: Fixture`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'plan.md'), @"
# Iteration Plan: 001

**Status**: retro

## Tasks

| Task | Requirement | Title | Story | Effort |
| ---- | ----------- | ----- | ----- | ------ |
| T-001 | FR-001 | Do the thing | S-1 | 2 |
| T-002 | FR-001 | Test the thing | S-1 | 1 |
"@ + "`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'tasks.md'), "# Tasks`n`n- [x] T-001 Do the thing`n- [x] T-002 Test the thing`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'tasks-progress.yml'), @"
feature: 001-fixture
iteration: "001"
tasks:
  T-001:
    title: Do the thing
    status: done
    started_at: "2026-09-10T10:00:00Z"
    completed_at: "2026-09-10T11:00:00Z"
    blocked_reason: ""
  T-002:
    title: Test the thing
    status: done
    started_at: "2026-09-10T11:00:00Z"
    completed_at: "2026-09-10T12:00:00Z"
    blocked_reason: ""
"@ + "`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'state.md'), @"
# Iteration State: 001

**Schema**: v2
**Current Phase**: retro
**Iteration Status**: retro
**Last Completed Task**: T-002
**Tasks Remaining**: 0
**In Progress**: none
**Baseline Ref**: abc1234
**Updated**: 2026-09-10T12:00:00Z

## Execution Summary

The work is done and reviewed.
"@ + "`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'review.md'), "# Review: Iteration 001`n`n**Overall Verdict**: accepted`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'retro.md'), "# Retro: Iteration 001`n`nWhat went well.`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.specrew/closed-iterations.yml'), "closed_iterations:`n  - feature: 001-fixture`n    iteration: `"001`"`n    closed_at: `"2026-09-10T12:30:00Z`"`n", $utf8)
    $ctx = [ordered]@{
        schema = 'v2'
        feature_path = (Join-Path $root 'specs/001-fixture')
        session_state = [ordered]@{ active = $true; boundary_type = 'iteration-closeout'; feature_ref = '001-fixture'; iteration_number = '001'; recorded_at = '2026-09-10T12:30:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'retro'; pending_next_boundary = 'iteration-closeout'; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'dashboard.md'), "# Dashboard`n`nCaptured At: arrival`n", $utf8)
    if ($SealedAtArrival) {
        # what the closeout sync used to do at the boundary's arrival - and what a consumer that closed an
        # iteration on beta3 still carries
        $null = Write-SpecrewIterationSeal -IterationDirectory $iter -Feature '001-fixture' -Iteration '001' -Source 'iteration-closeout'
    }
    return $root
}

$roots = New-Object System.Collections.Generic.List[string]
try {
    # ============ Case 1: closeout arrival -> verdict -> the seal is the verdict's last act ============
    Write-Host '  --- Case 1: the closeout verdict capture advances the records and then SEALS, as its last act ---'
    $root = New-ClosedIterationProject -SealedAtArrival:$MutateSealAtArrival; $roots.Add($root) | Out-Null
    $iter = Join-Path $root 'specs/001-fixture/iterations/001'
    Assert-True ((Test-SpecrewIterationSealed -IterationDirectory $iter) -eq [bool]$MutateSealAtArrival) 'fixture: at arrival the iteration is NOT sealed (the sync seals nothing) - unless the mutation put the old ordering back'
    $verdict = Add-SpecrewBoundaryAuthorization -ProjectRoot $root -CurrentBoundary 'retro' -AuthorizedBoundary 'iteration-closeout' -AuthorizingHuman 'Fixture Human' -VerdictText 'approved for iteration-closeout' -EvidenceSource 'hook-captured-from-transcript'
    Assert-True ($null -ne $verdict -and [string]$verdict.AuthorizedBoundary -ceq 'iteration-closeout') 'the verdict is recorded'
    $stateText = Get-Content -LiteralPath (Join-Path $iter 'state.md') -Raw
    Assert-True ($stateText -match '\*\*Iteration Status\*\*:\s*complete') 'its advance wrote complete into state.md'
    Assert-True ((Get-Content -LiteralPath (Join-Path $iter 'plan.md') -Raw) -match '\*\*Status\*\*:\s*complete') 'and into plan.md'
    Assert-True (Test-SpecrewIterationSealed -IterationDirectory $iter) 'and the iteration is sealed NOW - after the advance, as the capture''s last act'
    $after = Test-SpecrewIterationSealIntegrity -IterationDirectory $iter
    $touched = @(@($after.drifted) + @($after.missing) + @($after.added))
    Assert-True ($touched.Count -eq 0) ('the seal describes what the verdict accepted - nothing touched (touched: {0})' -f ($touched -join ','))
    $seal = Get-Content -LiteralPath (Get-SpecrewIterationSealPath -IterationDirectory $iter) -Raw | ConvertFrom-Json
    Assert-True ([string]$seal.source -ceq 'iteration-closeout-authorization') ('the seal names its writer: {0}' -f $seal.source)
    $journal = Get-Content -LiteralPath (Join-Path $root '.specrew/runtime/handover-journal.jsonl') -Raw
    Assert-True ($journal -match 'iteration-sealed-at-authorization') 'and the journal carries the seal'

    # ============ Case 1b: the next iteration's plan sync finds the seal intact =======================
    Write-Host '  --- Case 1b: the next iteration starts through its plan sync and 001''s seal is intact - the re-walk''s next step ---'
    $iter2 = Join-Path $root 'specs/001-fixture/iterations/002'
    New-Item -ItemType Directory -Path $iter2 -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $iter2 'plan.md'), "# Iteration Plan: 002`n`n**Status**: planning`n`n## Tasks`n`n| Task | Requirement | Title | Story | Effort |`n| ---- | ----------- | ----- | ----- | ------ |`n| T-003 | FR-002 | Next thing | S-2 | 2 |`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $iter2 'state.md'), "# Iteration State: 002`n`n**Schema**: v2`n**Current Phase**: plan`n**Iteration Status**: not-started`n", [Text.UTF8Encoding]::new($false))
    # what the plan sync does that can reach 001: the crossing mirrors capped at 'plan' (the store's last
    # authorization is 001's closeout), and the task-progress sync a resume runs through Get-TaskProgressSummary
    # with the START-CONTEXT iteration - still 001 at that moment on the consumer
    $null = Sync-SpecrewCrossingMirrors -ProjectRoot $root -AuthorizedBoundary 'plan' -FeatureRef '001-fixture' -IterationNumber '001' -Reason 'sync:plan'
    $null = Sync-SpecrewCrossingMirrors -ProjectRoot $root -AuthorizedBoundary 'plan' -FeatureRef '001-fixture' -IterationNumber '002' -Reason 'sync:plan'
    $null = Get-TaskProgressSummary -ProjectRoot $root -FeatureRef '001-fixture' -IterationNumber '001'
    $after1b = Test-SpecrewIterationSealIntegrity -IterationDirectory $iter
    $touched1b = @(@($after1b.drifted) + @($after1b.missing) + @($after1b.added))
    Assert-True ($touched1b.Count -eq 0) ('after the next iteration''s plan sync, 001''s seal is INTACT - no seal flag, no verdict re-ask (touched: {0})' -f ($touched1b -join ','))
    Assert-True ((Get-Content -LiteralPath (Join-Path $iter2 'state.md') -Raw) -match '\*\*Current Phase\*\*:\s*plan') 'and 002 is at plan, untouched by any seal'

    # ============ Case 2: resume on a sealed iteration leaves it untouched ===========================
    Write-Host '  --- Case 2: a session resume on a sealed iteration writes NOTHING and journals the skip ---'
    $root2 = New-ClosedIterationProject; $roots.Add($root2) | Out-Null
    $iter2 = Join-Path $root2 'specs/001-fixture/iterations/001'
    # sealed the way the verdict leaves it - by the verdict
    $null = Add-SpecrewBoundaryAuthorization -ProjectRoot $root2 -CurrentBoundary 'retro' -AuthorizedBoundary 'iteration-closeout' -AuthorizingHuman 'Fixture Human' -VerdictText 'approved for iteration-closeout' -EvidenceSource 'hook-captured-from-transcript'
    if ($MutateSealAtArrival) { $null = Write-SpecrewIterationSeal -IterationDirectory $iter2 -Feature '001-fixture' -Iteration '001' -Source 'iteration-closeout' }
    Assert-True (Test-SpecrewIterationSealed -IterationDirectory $iter2) 'fixture: sealed by the verdict'
    $hashesBefore = Get-FileHashes -Directory $iter2
    # the resume path: coordinator-resume.ps1 -> Get-TaskProgressSummary -> Sync-IterationTaskProgress -> Update-IterationStateFromTaskProgress
    $summary = Get-TaskProgressSummary -ProjectRoot $root2 -FeatureRef '001-fixture' -IterationNumber '001'
    Assert-True ($null -ne $summary) 'the resume still gets a summary to orient from'
    $hashesAfter = Get-FileHashes -Directory $iter2
    $changed = @($hashesBefore.Keys | Where-Object { $hashesBefore[$_] -cne $hashesAfter[$_] })
    Assert-True ($changed.Count -eq 0) ('and no sealed record changed (changed: {0})' -f ($changed -join ','))
    $state2 = Get-Content -LiteralPath (Join-Path $iter2 'state.md') -Raw
    Assert-True ($state2 -match '\*\*Iteration Status\*\*:\s*complete') 'state.md still says complete - the verdict''s value, not the derived ready-for-review the consumer saw'
    $after2 = Test-SpecrewIterationSealIntegrity -IterationDirectory $iter2
    Assert-True (@(@($after2.drifted) + @($after2.missing) + @($after2.added)).Count -eq 0) 'the seal is intact'
    $journal2 = if (Test-Path -LiteralPath (Join-Path $root2 '.specrew/runtime/handover-journal.jsonl')) { Get-Content -LiteralPath (Join-Path $root2 '.specrew/runtime/handover-journal.jsonl') -Raw } else { '' }
    Assert-True ($journal2 -match 'sealed-iteration-write-skipped' -and $journal2 -match 'task-progress:Sync-IterationTaskProgress') 'the skip is journaled, naming the writer'

    # ============ Case 3: the KeyContextAI shape, cleared by specrew reseal ==========================
    Write-Host '  --- Case 3: a consumer-shaped drift (sealed on beta3, then moved) is refused naming reseal, and reseal clears it ---'
    $root3 = New-ClosedIterationProject -SealedAtArrival; $roots.Add($root3) | Out-Null
    $iter3 = Join-Path $root3 'specs/001-fixture/iterations/001'
    # what the consumer showed: sealed on beta3 at arrival, then state.md and retro.md moved and dashboard.md re-rendered
    Add-Content -LiteralPath (Join-Path $iter3 'state.md') -Value "`n<!-- moved after the seal -->"
    Add-Content -LiteralPath (Join-Path $iter3 'retro.md') -Value "`nOne more line."
    Remove-Item -LiteralPath (Join-Path $iter3 'dashboard.md') -Force
    Start-Sleep -Milliseconds 20
    [IO.File]::WriteAllText((Join-Path $iter3 'dashboard.md'), "# Dashboard`n`nCaptured At: later`n", [Text.UTF8Encoding]::new($false))
    $errors = [System.Collections.Generic.List[string]]::new()
    # the validator's own gate function, loaded from its file so the text asserted is the text shipped
    $validatorText = Get-Content -LiteralPath $validator -Raw -Encoding UTF8
    $fnStart = $validatorText.IndexOf('function Test-ClosedIterationSeals {')
    $fnEnd = $validatorText.IndexOf("`nfunction ", $fnStart + 10)
    Invoke-Expression $validatorText.Substring($fnStart, $fnEnd - $fnStart)
    Test-ClosedIterationSeals -ProjectRoot $root3 -Errors $errors
    Assert-True ($errors.Count -eq 1) 'the trust gate refuses the drifted closed iteration'
    Assert-True ($errors.Count -eq 1 -and $errors[0] -match 'specrew reseal --feature 001-fixture --iteration 001') 'and the refusal NAMES the remedy with the feature and iteration filled in'
    Assert-True ($errors.Count -eq 1 -and $errors[0] -match 'git checkout') 'while keeping the revert for a session''s stray edit'
    $resealOut = (& pwsh -NoProfile -File $front reseal --project-path $root3 --feature 001-fixture --iteration 001 2>&1 | Out-String)
    $resealCode = $LASTEXITCODE
    Assert-True ($resealCode -eq 0) ('specrew reseal exits 0 (out: {0})' -f ($resealOut -replace '\s+', ' ').Substring(0, [Math]::Min(300, ($resealOut -replace '\s+', ' ').Length)))
    # The drifted list is printed in the seal manifest's enumeration order, which is the filesystem's: the
    # runner listed `retro.md,dashboard.md,state.md`, this machine `state.md,retro.md,dashboard.md`. A set
    # comparison, not an order (census 34518281283 - the only red on this file).
    $driftedSet = @()
    if ($resealOut -match 'precondition [^\r\n]*?drifted=(?<list>[^\s]*)') { $driftedSet = @($Matches['list'] -split ',' | Where-Object { $_ }) }
    Assert-True (($driftedSet -contains 'state.md') -and ($driftedSet -contains 'retro.md')) ('it prints the PRECONDITION: which sealed paths drifted (drifted={0})' -f ($driftedSet -join ','))
    Assert-True ($driftedSet -contains 'dashboard.md') 'including the dashboard re-rendered after the seal'
    Assert-True ($resealOut -match 'postcondition .*touched=0') 'and the POSTCONDITION: nothing touched after the re-seal'
    $errorsAfter = [System.Collections.Generic.List[string]]::new()
    Test-ClosedIterationSeals -ProjectRoot $root3 -Errors $errorsAfter
    Assert-True ($errorsAfter.Count -eq 0) 'the trust gate passes afterwards'
    $seal3 = Get-Content -LiteralPath (Get-SpecrewIterationSealPath -IterationDirectory $iter3) -Raw | ConvertFrom-Json
    Assert-True ([string]$seal3.source -ceq 'specrew-reseal') 'and the seal says a human re-sealed it'

    # ============ Case 4: the verb's refusals name what they looked for =============================
    Write-Host '  --- Case 4: reseal refuses an unsealed iteration and an open one, by name ---'
    $root4 = New-ClosedIterationProject; $roots.Add($root4) | Out-Null
    $iter4 = Join-Path $root4 'specs/001-fixture/iterations/001'
    $noSeal = (& pwsh -NoProfile -File $front reseal --project-path $root4 --feature 001-fixture --iteration 001 2>&1 | Out-String)
    Assert-True ($LASTEXITCODE -ne 0 -and $noSeal -match 'has no closeout seal') 'an iteration with no seal is refused: this re-seals, closeout seals for the first time'
    New-Item -ItemType Directory -Path (Join-Path $root4 'specs/001-fixture/iterations/002') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $root4 'specs/001-fixture/iterations/002/state.md'), "# Iteration State: 002`n`n**Current Phase**: before-implement`n**Iteration Status**: executing`n", [Text.UTF8Encoding]::new($false))
    $null = Write-SpecrewIterationSeal -IterationDirectory (Join-Path $root4 'specs/001-fixture/iterations/002') -Feature '001-fixture' -Iteration '002'
    $notClosed = (& pwsh -NoProfile -File $front reseal --project-path $root4 --feature 001-fixture --iteration 002 2>&1 | Out-String)
    Assert-True ($LASTEXITCODE -ne 0 -and $notClosed -match 'is not recorded as closed') 'a sealed-but-open iteration is refused: its seal is not a closeout seal'
    $missing = (& pwsh -NoProfile -File $front reseal --project-path $root4 --feature 001-fixture 2>&1 | Out-String)
    Assert-True ($LASTEXITCODE -ne 0 -and $missing -match '--iteration') 'a call without the iteration is refused naming the parameter - one iteration, named, never every one it can find'

    # ============ Case 5: the seal is written at authorization and nowhere at arrival ================
    Write-Host '  --- Case 5: the boundary sync writes no seal at arrival; the authorization writes it after its advance ---'
    $syncText = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/internal/sync-boundary-state.ps1') -Raw -Encoding UTF8
    Assert-True ($syncText -notmatch 'Write-SpecrewIterationSeal -IterationDirectory') 'the boundary sync no longer calls the seal writer - arrival seals nothing'
    $govText = Get-Content -LiteralPath $governance -Raw -Encoding UTF8
    $advanceAt = $govText.IndexOf("Sync-SpecrewCrossingMirrors -ProjectRoot `$ProjectRoot -AuthorizedBoundary `$authorizedCanonical")
    $sealAt = $govText.IndexOf('Invoke-SpecrewCloseoutSeal -ProjectRoot $ProjectRoot -IterationDirectory')
    Assert-True ($advanceAt -gt 0 -and $sealAt -gt $advanceAt) 'in the authorization, the seal follows the advance - the last act'
}
finally {
    foreach ($r in $roots) { if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:Failures -gt 0) {
    Write-Host ("sealed-iteration-writers: {0} FAILED" -f $script:Failures)
    exit 1
}
Write-Host 'sealed-iteration-writers: all cases passed'
exit 0
