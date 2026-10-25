# Iteration 002, T021 (FR-030, SC-016; DRIFT-199-I002-009): the crossing mirrors and the ledger's word.
#
# DRIFT-199-I001-152: no writer owned state.md's phase at a crossing, so every project's state.md was
# wrong at every crossing, in the file a human opens to learn where they are. FR-030 as corrected at
# the plan verdict (DRIFT-199-I002-007): the crossing writer writes every enumerated COPY of
# last_authorized_boundary - state.md Current Phase (the boundary name) and plan.md Status (the
# validator's own enum, mapped) - in each file's existing vocabulary; state.md Iteration Status is
# derived by its own writer and touched only at iteration-closeout; the sync re-mirrors forward; the
# truth gate compares every copy and refuses a copy AHEAD of the store; a copy may lead by exactly the
# pending crossing during the arrival-to-verdict window.
#
# Every case asserts OBSERVABLE FILE OR STORE STATE, never that a call exists. Mutations that turn this
# file red: remove the Sync-SpecrewCrossingMirrors call from Add-SpecrewBoundaryAuthorization (1, 2);
# remove the forward-only rank check (4 rewrites the ahead copy); remove the pending-lead allowance (5);
# revert Set-TaskStatus to write 'complete' (6).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
. (Join-Path $repoRoot 'scripts\internal\gate-preflight.ps1')
. (Join-Path $repoRoot 'scripts\internal\task-progress.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-MirrorFixture {
    param(
        [string]$LastAuthorized,
        [string]$WorkingBoundary,
        [string]$CurrentPhase,
        [string]$IterationStatus = 'executing',
        [string]$PlanStatus,
        [string[]]$Extra = @()
    )
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("mirrors-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))
    $feature = Join-Path $root 'specs/001-feat'
    $iter = Join-Path $feature 'iterations/001'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $iter 'quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    $plan = @(
        '# Iteration Plan: 001', '', '**Schema**: v1', '**Spec**: [../../spec.md](../../spec.md)',
        ('**Status**: {0}' -f $PlanStatus), '**Capacity**: 1/20 story_points', '**Started**: 2026-08-29', '**Completed**:', '',
        '## Tasks', '',
        '| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |',
        '| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |',
        '| T001 | Fixture task | FR-001 | US1 | 1.0 | Implementer | src/** | planned | | | |', ''
    ) -join "`n"
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value $plan -Encoding UTF8
    $state = @(
        '# Iteration State: 001', '', '**Schema**: v1', ('**Current Phase**: {0}' -f $CurrentPhase), ('**Iteration Status**: {0}' -f $IterationStatus),
        '**Last Completed Task**: (none)', '**Tasks Remaining**: T001', '**In Progress**: (none)', '**Baseline Ref**: 0000000000000000000000000000000000000000',
        '**Updated**: 2026-08-29T00:00:00Z', '', '## Execution Summary', '', '- Execution is in progress.', ''
    ) -join "`n"
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value $state -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'quality/hardening-gate.md') -Value "# Hardening Gate`n`n**Overall Verdict**: ready" -Encoding UTF8
    foreach ($rel in $Extra) { Set-Content -LiteralPath (Join-Path $iter $rel) -Value ("# {0}" -f $rel) -Encoding UTF8 }
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root add -A
    & git -C $root commit -q -m fixture
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $context = [ordered]@{
        schema = 'v2'
        boundary_enforcement = [ordered]@{
            enabled = $true; last_authorized_boundary = $LastAuthorized; pending_next_boundary = $null
            policy_classes = [ordered]@{ specify = 'human-judgment-required'; clarify = 'human-judgment-required'; plan = 'human-judgment-required'; tasks = 'human-judgment-required'; 'before-implement' = 'human-judgment-required'; 'review-signoff' = 'human-judgment-required'; retro = 'human-judgment-required'; 'iteration-closeout' = 'human-judgment-required'; 'feature-closeout' = 'human-judgment-required' }
            verdict_history = @(); bypass_history = @()
        }
        generated_at_utc = '2026-08-29T00:00:00Z'
        session_state = [ordered]@{ active = $true; boundary_type = $WorkingBoundary; feature_ref = '001-feat'; feature_path = $feature; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-08-29T00:00:00Z' }
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($context | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Root = $root; Feature = $feature; Iter = $iter; Head = $head; StatePath = (Join-Path $iter 'state.md'); PlanPath = (Join-Path $iter 'plan.md') }
}
function Read-Meta { param([string]$Path, [string]$Label) return (Get-SpecrewMirrorMetadataValue -Path $Path -Label $Label) }
function Read-Enforcement { param([string]$Root) return (Get-Content -LiteralPath (Join-Path $Root '.specrew/start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).boundary_enforcement }

# ---------------------------------------------------------------------------------------------------
Write-Host 'Case 1: DRIFT-199-I001-152 reproduced then green - authorizing review-signoff writes both copies'
$f1 = New-MirrorFixture -LastAuthorized 'before-implement' -WorkingBoundary 'review-signoff' -CurrentPhase 'before-implement' -PlanStatus 'executing' -Extra @('review.md')
$null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f1.Root -WorkingBoundary 'review-signoff' -BoundaryCommitHash $f1.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
Assert-True ((Read-Meta $f1.StatePath 'Current Phase') -eq 'before-implement') 'before the verdict, state.md still says before-implement (the arrival is not the crossing)'
$auth1 = Add-SpecrewBoundaryAuthorization -ProjectRoot $f1.Root -CurrentBoundary 'before-implement' -AuthorizedBoundary 'review-signoff' -AuthorizingHuman 'unattributed' -VerdictText 'approved for review-signoff' -EvidenceSource 'hook-captured-from-transcript' 2>$null
Assert-True ((Read-Meta $f1.StatePath 'Current Phase') -eq 'review-signoff') 'state.md Current Phase is review-signoff the moment the crossing is recorded'
Assert-True ((Read-Meta $f1.PlanPath 'Status') -eq 'reviewing') "plan.md Status is 'reviewing' - the validator's own word, mapped from the boundary"
Assert-True ((Read-Meta $f1.StatePath 'Iteration Status') -eq 'executing') 'state.md Iteration Status is untouched (derived by its own writer, not a copy)'
Assert-True ($null -ne $auth1.Mirrors -and @($auth1.Mirrors.Wrote).Count -eq 2) 'the writer reports the two copies it wrote'

Write-Host 'Case 2: iteration-closeout authorized - Current Phase, plan Status and Iteration Status all read complete/closeout'
$f2 = New-MirrorFixture -LastAuthorized 'retro' -WorkingBoundary 'iteration-closeout' -CurrentPhase 'retro' -IterationStatus 'ready-for-review' -PlanStatus 'retro' -Extra @('review.md', 'retro.md')
$null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f2.Root -WorkingBoundary 'iteration-closeout' -BoundaryCommitHash $f2.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
$null = Add-SpecrewBoundaryAuthorization -ProjectRoot $f2.Root -CurrentBoundary 'retro' -AuthorizedBoundary 'iteration-closeout' -AuthorizingHuman 'unattributed' -VerdictText 'approved for iteration-closeout' -EvidenceSource 'hook-captured-from-transcript' 2>$null
Assert-True ((Read-Meta $f2.StatePath 'Current Phase') -eq 'iteration-closeout') 'state.md Current Phase is iteration-closeout'
Assert-True ((Read-Meta $f2.StatePath 'Iteration Status') -eq 'complete') 'state.md Iteration Status is complete - the one boundary-driven value it has'
Assert-True ((Read-Meta $f2.PlanPath 'Status') -eq 'complete') 'plan.md Status is complete'

Write-Host 'Case 3: the sync re-mirror heals a copy that is BEHIND the store'
$f3 = New-MirrorFixture -LastAuthorized 'review-signoff' -WorkingBoundary 'review-signoff' -CurrentPhase 'before-implement' -PlanStatus 'executing' -Extra @('review.md')
$r3 = Sync-SpecrewCrossingMirrors -ProjectRoot $f3.Root -AuthorizedBoundary 'review-signoff' -FeatureRef '001-feat' -IterationNumber '001' -Reason 'sync:test'
Assert-True ((Read-Meta $f3.StatePath 'Current Phase') -eq 'review-signoff' -and (Read-Meta $f3.PlanPath 'Status') -eq 'reviewing') 'both copies are brought forward to the store'
Assert-True (@(Get-SpecrewCrossingMirrorIssues -ProjectRoot $f3.Root -FeatureRef '001-feat' -IterationNumber '001').Count -eq 0) 'the truth check is clean after the re-mirror'

Write-Host 'Case 4: a copy AHEAD of the store is refused by name and never rewritten'
$f4 = New-MirrorFixture -LastAuthorized 'before-implement' -WorkingBoundary 'before-implement' -CurrentPhase 'retro' -PlanStatus 'retro'
$r4 = Sync-SpecrewCrossingMirrors -ProjectRoot $f4.Root -AuthorizedBoundary 'before-implement' -FeatureRef '001-feat' -IterationNumber '001' -Reason 'sync:test'
Assert-True ((Read-Meta $f4.StatePath 'Current Phase') -eq 'retro' -and (Read-Meta $f4.PlanPath 'Status') -eq 'retro') 'the ahead copies are left exactly as found'
$i4 = @(Get-SpecrewCrossingMirrorIssues -ProjectRoot $f4.Root -FeatureRef '001-feat' -IterationNumber '001')
Assert-True ($i4.Count -eq 2) 'the truth check names both ahead copies'
Assert-True (($i4 -join ' ') -match "state.md for iteration 001 says Current Phase 'retro', but the last authorized boundary is 'before-implement'" -and ($i4 -join ' ') -match 'correct the line by hand and record why in the drift log') 'the message names the file, the value, the authority, and the one action'

Write-Host 'Case 5: a copy may lead the store by exactly the pending crossing (the arrival-to-verdict window)'
$f5 = New-MirrorFixture -LastAuthorized 'review-signoff' -WorkingBoundary 'retro' -CurrentPhase 'retro' -PlanStatus 'retro' -Extra @('review.md', 'retro.md')
$null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $f5.Root -WorkingBoundary 'retro' -BoundaryCommitHash $f5.Head -RecordedAt '2026-08-29T00:00:01Z' 2>$null
$r5 = Sync-SpecrewCrossingMirrors -ProjectRoot $f5.Root -AuthorizedBoundary 'review-signoff' -FeatureRef '001-feat' -IterationNumber '001' -Reason 'sync:retro'
Assert-True ((Read-Meta $f5.StatePath 'Current Phase') -eq 'retro') 'the lead by one pending crossing is left alone by the re-mirror'
Assert-True (@(Get-SpecrewCrossingMirrorIssues -ProjectRoot $f5.Root -FeatureRef '001-feat' -IterationNumber '001').Count -eq 0) 'and the truth check accepts it'

Write-Host 'Case 6 (DRIFT-199-I002-009): a task completed through the ledger writer passes the boundary preflight task-state check'
$f6 = New-MirrorFixture -LastAuthorized 'before-implement' -WorkingBoundary 'before-implement' -CurrentPhase 'before-implement' -PlanStatus 'executing'
$null = Set-TaskComplete -ProjectRoot $f6.Root -FeatureRef '001-feat' -IterationNumber '001' -TaskId 'T001' 2>$null
$ledger6 = Get-Content -LiteralPath (Join-Path $f6.Iter 'tasks-progress.yml') -Raw -Encoding UTF8
Assert-True ($ledger6 -match '(?m)^\s*status:\s*"?done"?\s*$' -and $ledger6 -notmatch '(?m)^\s*status:\s*"?complete"?\s*$') "the ledger holds 'done', the word every consumer reads - never 'complete'"
$pf6 = Invoke-SpecrewGatePreflight -ProjectRoot $f6.Root -BoundaryType 'before-implement' -FeatureRef '001-feat' -IterationNumber '001'
$ts6 = @($pf6.checks | Where-Object { $_.name -eq 'task-state' })
Assert-True ($ts6.Count -eq 1 -and [string]$ts6[0].status -eq 'pass') 'the preflight task-state check passes on the writer''s own output'

Write-Host 'Case 7: CRLF records (the live tree writes state.md with CRLF) are read and written like LF ones'
$f7 = New-MirrorFixture -LastAuthorized 'review-signoff' -WorkingBoundary 'review-signoff' -CurrentPhase 'before-implement' -PlanStatus 'executing' -Extra @('review.md')
foreach ($pth in @($f7.StatePath, $f7.PlanPath)) {
    $txt = Get-Content -LiteralPath $pth -Raw -Encoding UTF8
    [System.IO.File]::WriteAllText($pth, ($txt -replace "`r?`n", "`r`n"), [System.Text.UTF8Encoding]::new($false))
}
Assert-True ((Read-Meta $f7.StatePath 'Current Phase') -eq 'before-implement') 'a CRLF Current Phase line is read'
$r7 = Sync-SpecrewCrossingMirrors -ProjectRoot $f7.Root -AuthorizedBoundary 'review-signoff' -FeatureRef '001-feat' -IterationNumber '001' -Reason 'sync:crlf'
Assert-True (@($r7.Wrote).Count -eq 2 -and (Read-Meta $f7.StatePath 'Current Phase') -eq 'review-signoff' -and (Read-Meta $f7.PlanPath 'Status') -eq 'reviewing') 'both CRLF copies are written forward'
Assert-True (((Get-Content -LiteralPath $f7.StatePath -Raw -Encoding UTF8) -split "`n" | Where-Object { $_ -match '^\*\*Current Phase\*\*' } | Select-Object -First 1) -match "`r$") 'the CRLF line ending is preserved by the rewrite'

foreach ($f in @($f1, $f2, $f3, $f4, $f5, $f6, $f7)) { try { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("crossing-mirrors: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'crossing-mirrors: all assertions passed' -ForegroundColor Green
