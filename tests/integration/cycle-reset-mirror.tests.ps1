# Iteration 002, round-3 blocking finding (DRIFT-199-I002-030): starting a new iteration must not write the
# new iteration's copies forward past their own state.
#
# THE DEFECT. `last_authorized_boundary` is GLOBAL - the store keeps no iteration beside it, and
# verdict_history entries carry none either. So on the first `plan` sync of a NEW iteration the last
# authorization is the PREVIOUS iteration's `iteration-closeout`, and the truth gate replayed it into the
# new iteration. Measured before the fix:
#
#     BEFORE: **Status**: planning
#     first plan sync (store last-authorized = iteration-closeout) -> **Status**: complete
#     later `plan` authorization                                   -> **Status**: complete   (forward-only)
#
# The next `tasks` sync then rejects a plan mirror reading `complete` where `planning` is required. Every
# next-iteration cycle wedged, deterministically, against an acceptance bar that names a wedged gate.
#
# WHY NO SUITE SAW IT: every existing mirror fixture starts MID-iteration, so none of them ever crossed a
# cycle boundary. The fixture wrote the precondition the product denies - the same shape as T018.
#
# Mutations that turn this file red: remove the cap in sync-boundary-state.ps1; cap on the wrong side
# (>= instead of >), which would stop legitimate same-boundary mirroring.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-CycleFixture {
    # A REAL project: enforcement state with the PREVIOUS iteration's closeout as the global last
    # authorization, and a fresh iteration 003 scaffold. This is the cycle boundary no existing mirror
    # fixture crossed, because every one of them starts mid-iteration.
    param([string]$Status = 'planning', [string]$LastAuthorized = 'iteration-closeout')
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("cycle-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = [System.IO.Path]::GetFullPath((Join-Path $root (Join-Path 'specs' '001-feat')))
    $iter = [System.IO.Path]::GetFullPath((Join-Path $feature (Join-Path 'iterations' '003')))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    New-Item -ItemType Directory -Force -Path $iter | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value ("# Iteration Plan: 003`n`n**Status**: {0}`n" -f $Status) -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value "# Iteration State: 003`n`n**Current Phase**: plan`n**Iteration Status**: executing`n" -Encoding UTF8
    $context = [ordered]@{
        schema = 'v2'
        feature_path = $feature
        boundary_enforcement = [ordered]@{
            enabled = $true; last_authorized_boundary = $LastAuthorized; pending_next_boundary = $null
            policy_classes = [ordered]@{ specify = 'human-judgment-required'; clarify = 'human-judgment-required'; plan = 'human-judgment-required'; tasks = 'human-judgment-required'; 'before-implement' = 'human-judgment-required'; 'review-signoff' = 'human-judgment-required'; retro = 'human-judgment-required'; 'iteration-closeout' = 'human-judgment-required'; 'feature-closeout' = 'human-judgment-required' }
            verdict_history = @(); bypass_history = @()
        }
        generated_at_utc = '2026-08-30T00:00:00Z'
        session_state = [ordered]@{ active = $true; boundary_type = 'plan'; feature_ref = '001-feat'; feature_path = $feature; iteration_number = '003'; recorded_at = '2026-08-30T00:00:00Z' }
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($context | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Root = $root; Iteration = $iter; Plan = (Join-Path $iter 'plan.md') }
}
function Get-PlanStatus { param([string]$Path) $m = [regex]::Match((Get-Content -LiteralPath $Path -Raw -Encoding UTF8), '\*\*Status\*\*:\s*(?<v>\S+)'); if ($m.Success) { return $m.Groups['v'].Value } return '' }

# INVOKE THE REAL GATE, never a restatement of it.
#
# The first version of this file reimplemented the cap inside the test helper - so both mutations of the
# production code produced ZERO failures, and the suite "passed" against a reverted fix. That is the exact
# defect this batch catalogued twice (DRIFT-199-I002-014: a diagnosis that reimplements the subject instead
# of invoking it), reproduced by me in the guard written to prove the fix for it. The gate runs in a child
# process because the sync script is a script, not a module.
function Invoke-Gate {
    param([string]$Root, [string]$BoundaryType)
    $script = (Resolve-Path (Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1')).Path
    $command = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Continue'
. '$script'
try { Invoke-SpecrewIterationStateTruthGate -ProjectRoot '$Root' -BoundaryType '$BoundaryType' -FeatureRef '001-feat' -IterationNumber '003' } catch { Write-Host ('gate-threw: ' + `$_.Exception.Message) }
"@
    return ((& pwsh -NoProfile -Command $command 2>&1) | ForEach-Object { [string]$_ }) -join ' '
}

Write-Host 'Case 1: THE CYCLE - a fresh iteration''s plan mirror does not advance on its first plan sync'
$f1 = New-CycleFixture
Assert-True ((Get-PlanStatus -Path $f1.Plan) -eq 'planning') 'the new iteration starts at planning'
$null = Invoke-Gate -Root $f1.Root -BoundaryType 'plan'
$after1 = Get-PlanStatus -Path $f1.Plan
Assert-True ($after1 -ne 'complete') ('the plan mirror is NOT written forward to complete by the previous iteration''s closeout (is: ' + $after1 + ')')
Assert-True ($after1 -eq 'planning') 'it is still exactly planning - the state the new iteration is actually in'

Write-Host 'Case 2: the following tasks sync does not force it either, so the cycle is not wedged'
$null = Invoke-Gate -Root $f1.Root -BoundaryType 'tasks'
$after2 = Get-PlanStatus -Path $f1.Plan
Assert-True ($after2 -ne 'complete') ('after the tasks sync the plan mirror is still not complete (is: ' + $after2 + ')')

Write-Host 'Case 2b: the CHECKER is capped too - a fresh iteration is not reported as behind the record'
# FOUND BY REPLAYING A REAL CYCLE END TO END, not by a fixture. With the writer capped, the copies were
# correctly left alone - and the checker then compared them against the GLOBAL `iteration-closeout` and
# reported them "behind the authority record", telling the human to re-run the sync for
# 'iteration-closeout'. That advice re-creates the wedge the writer's cap had just prevented: the silent
# forward-write had become a loud, wrong refusal. Both sides of the comparison need the same ceiling.
$f2b = New-CycleFixture
$out2b = Invoke-Gate -Root $f2b.Root -BoundaryType 'plan'
Assert-True ($out2b -notmatch 'behind the authority record') 'the fresh iteration is NOT reported as behind the record'
Assert-True ($out2b -notmatch "Re-run the boundary sync for 'iteration-closeout'") 'and the human is not told to re-mirror the previous iteration''s closeout into this one'

Write-Host 'Case 3: an EARLIER authorization is replayed as itself, never inflated to the boundary'
# The cap must be strictly greater-than. Capping unconditionally would set the replay to the boundary being
# synced, which mirrors FORWARD past the actual authorization - the same over-mirroring, arrived at from
# the other side. The mapping makes this observable: a `plan` authorization writes plan.md `planning`, a
# `review-signoff` authorization writes `reviewing`. So syncing review-signoff while only `plan` is
# authorized must leave `planning`.
$f3 = New-CycleFixture -LastAuthorized 'plan'
$null = Invoke-Gate -Root $f3.Root -BoundaryType 'review-signoff'
$after3 = Get-PlanStatus -Path $f3.Plan
Assert-True ($after3 -eq 'planning') ('a plan-level authorization stays plan-level at a later boundary, and is not inflated to reviewing (is: ' + $after3 + ')')

Write-Host 'Case 4: an iteration genuinely being closed out still mirrors its own closeout'
$f4 = New-CycleFixture -Status 'complete' -LastAuthorized 'iteration-closeout'
$null = Invoke-Gate -Root $f4.Root -BoundaryType 'iteration-closeout'
Assert-True ((Get-PlanStatus -Path $f4.Plan) -eq 'complete') 'closing THIS iteration is not capped - only a boundary LATER than the one being synced is'

foreach ($f in @($f1, $f2b, $f3, $f4)) { try { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("cycle-reset-mirror: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'cycle-reset-mirror: all assertions passed' -ForegroundColor Green
