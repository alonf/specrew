# FIX 6 (B4F-066, PRED-BETA4-023): ONE DERIVATION OF THE PLAN SYNC'S TARGET ITERATION.
#
# Verbatim from the router-skill project: the plan-boundary sync run as `-BoundaryType plan -IterationNumber
# 002` reported the boundary record established for 002 and, in the same invocation, WARNed
# CROSSING_NOT_MINTED_OWED_ARTIFACTS_ABSENT - "'plan' owes plan.md for iteration 003". The sync wrote the
# cursor at 002, the gated crossing constructor read it back, and the owed-artifact check added one because
# "iteration-closeout -> plan opens the NEXT iteration" - a rule written for the closeout AUTHORIZATION's
# rebind, where the cursor still names the closed iteration. Two callers, one check, one guess.
#
# The rule now: the check derives nothing; New-SpecrewPendingCrossingScope resolves the target ONCE, from
# the crossing's WORKING boundary - cursor + 1 only while the working boundary is still iteration-closeout;
# the cursor itself once the plan sync has moved it. The sync derives nothing of its own.
#
# Two fixtures, both through the REAL sync wrapper the product resolves through the module:
#   (a) 001 closed and sealed by its verdict, 002 scaffolded through scaffold-iteration-plan.ps1 in the
#       product's own order, then the plan sync for 002 - the check targeted 003 here too, before the fix:
#       the defect is universal, not a consequence of a pre-scaffold.
#   (b) the router-skill shape: 002 scaffolded BEFORE the closeout verdict, so the authorization's rebind
#       mints the closeout -> plan crossing; the plan sync for 002 then refused on 003 and OVERWROTE that
#       crossing with null - the sync destroyed what the verdict opened.
# -MutateIndependentDerivation restores the +1 inside the check, in a temp copy of the module tree that
# both this process and the sync wrapper resolve through: (a) and (b) go red on 003.

param([switch] $MutateIndependentDerivation)

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$moduleTree = $repoRoot
$mutantTree = $null
if ($MutateIndependentDerivation) {
    # THE MUTATION, at the SITE, in a tree of its own: the module tree copied, and the +1 put back into
    # Test-SpecrewBoundaryOwedArtifactsOnDisk exactly where it stood. The sync wrapper resolves through
    # SPECREW_MODULE_PATH, so pointing it at the copy runs the real sync against the mutant.
    $mutantTree = Join-Path ([IO.Path]::GetTempPath()) ('psti-mutant-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    foreach ($part in @('scripts', 'extensions', 'templates')) {
        $null = & robocopy (Join-Path $repoRoot $part) (Join-Path $mutantTree $part) /E /NFL /NDL /NJH /NJS /NP /XD .scratch 2>&1
    }
    foreach ($file in @('Specrew.psd1', 'Specrew.psm1')) { Copy-Item -LiteralPath (Join-Path $repoRoot $file) -Destination (Join-Path $mutantTree $file) -Force }
    $mutantGovernance = Join-Path $mutantTree 'extensions/specrew-speckit/scripts/shared-governance.ps1'
    $govText = Get-Content -LiteralPath $mutantGovernance -Raw -Encoding UTF8
    $site = "    if (`$result.Kind -eq 'iteration-file') {"
    if (([regex]::Matches($govText, [regex]::Escape($site))).Count -ne 1) { Write-Host '  FAIL: the mutation site is not unique'; exit 1 }
    $restored = $site + "`n        `$fromCanonical = Normalize-SpecrewCanonicalBoundaryType -Boundary `$FromBoundary`n        if (`$canonical -eq 'plan' -and `$fromCanonical -eq 'iteration-closeout' -and `$iteration -match '^\d+`$') { `$iteration = ('{0:000}' -f ([int]`$iteration + 1)) }"
    [IO.File]::WriteAllText($mutantGovernance, $govText.Replace($site, $restored), [Text.UTF8Encoding]::new($false))
    $moduleTree = $mutantTree
    Write-Host '  (MUTATION ACTIVE: the +1 is back inside the owed-artifact check, in a temp module tree)'
}
$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $moduleTree
$governance = Join-Path $moduleTree 'extensions/specrew-speckit/scripts/shared-governance.ps1'
$scaffolder = Join-Path $moduleTree 'extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1'
$syncWrapper = Join-Path $repoRoot '.specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1'

Write-Host 'plan-sync-target-iteration'
Write-Host '  --- preconditions ---'
foreach ($f in @($governance, $scaffolder, $syncWrapper)) { Assert-True (Test-Path -LiteralPath $f -PathType Leaf) ('present: ' + (Split-Path -Leaf $f)) }
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE'; exit 1 }
. $governance

function New-ClosedFirstIterationRepo {
    # A git project with one feature whose iteration 001 has ARRIVED at iteration-closeout (the cursor on
    # 001 at iteration-closeout, retro authorized), everything the sync's gates read present and committed.
    $root = Join-Path ([IO.Path]::GetTempPath()) ('psti-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $utf8 = [Text.UTF8Encoding]::new($false)
    foreach ($d in @('.specrew/runtime', '.specify', '.squad', '.github/agents', 'specs/001-fixture/iterations/001')) { New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/config.yml'), "project_name: fixture`nspecrew_version: `"0.40.0`"`nbootstrap_date: `"2026-09-01`"`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.specify/feature.json'), "{`n  `"feature_directory`": `"specs/001-fixture`"`n}`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.squad/team.md'), "# Team`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.squad/config.json'), "{}`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.squad/decisions.md'), "# Decisions`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.github/agents/squad.agent.md'), "# Squad Agent`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root 'README.md'), "# Fixture`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/runtime/`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/spec.md'), "# Feature Specification: Fixture`n`n## Requirements`n`n- **FR-001**: Do the thing.`n", $utf8)
    $iter = Join-Path $root 'specs/001-fixture/iterations/001'
    [IO.File]::WriteAllText((Join-Path $iter 'plan.md'), "# Iteration Plan: 001`n`n**Status**: retro`n`n## Tasks`n`n| Task | Requirement | Title | Story | Effort |`n| ---- | ----------- | ----- | ----- | ------ |`n| T-001 | FR-001 | Do the thing | S-1 | 2 |`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'tasks.md'), "# Tasks`n`n- [x] T-001 Do the thing`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'tasks-progress.yml'), "feature: 001-fixture`niteration: `"001`"`ntasks:`n  T-001:`n    title: Do the thing`n    status: done`n    started_at: `"2026-09-10T10:00:00Z`"`n    completed_at: `"2026-09-10T11:00:00Z`"`n    blocked_reason: `"`"`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'state.md'), "# Iteration State: 001`n`n**Schema**: v2`n**Current Phase**: retro`n**Iteration Status**: retro`n**Last Completed Task**: T-001`n**Tasks Remaining**: 0`n**In Progress**: none`n**Baseline Ref**: abc1234`n**Updated**: 2026-09-10T12:00:00Z`n`n## Execution Summary`n`nDone.`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'review.md'), "# Review: Iteration 001`n`n**Overall Verdict**: accepted`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'retro.md'), "# Retro: Iteration 001`n`nWhat went well.`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $iter 'dashboard.md'), "# Dashboard`n`nCaptured At: arrival`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $root '.specrew/closed-iterations.yml'), "closed_iterations:`n  - feature: 001-fixture`n    iteration: `"001`"`n    closed_at: `"2026-09-10T12:30:00Z`"`n", $utf8)
    $null = & git -C $root init -q -b 001-fixture 2>&1
    $null = & git -C $root config user.email 'fixture@specrew.local' 2>&1
    $null = & git -C $root config user.name 'Fixture' 2>&1
    $null = & git -C $root add -A 2>&1
    $null = & git -C $root commit -q -m 'closed iteration 001' 2>&1
    $head = (@(& git -C $root rev-parse HEAD 2>&1))[0].ToString().Trim()
    $ctx = [ordered]@{
        schema = 'v2'
        feature_path = (Join-Path $root 'specs/001-fixture')
        session_state = [ordered]@{ active = $true; boundary_type = 'iteration-closeout'; feature_ref = '001-fixture'; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-09-10T12:30:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'retro'; pending_next_boundary = 'iteration-closeout'; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), $utf8)
    $null = & git -C $root add -A 2>&1
    $null = & git -C $root commit -q -m 'cursor at iteration-closeout' 2>&1
    return $root
}
function Read-Enforcement { param([string]$Root) return (Get-Content -LiteralPath (Join-Path $Root '.specrew/start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).boundary_enforcement }
function Read-RefusedIterations {
    param([string]$Root)
    $p = Join-Path $Root '.specrew/runtime/handover-journal.jsonl'
    if (-not (Test-Path -LiteralPath $p)) { return @() }
    return @(Get-Content -LiteralPath $p -Encoding UTF8 | Where-Object { $_ -match 'crossing-not-minted-owed-artifacts-absent' } | ForEach-Object { [string](($_ | ConvertFrom-Json).iteration) })
}
function Invoke-PlanSync {
    param([string]$Root)
    $head = (@(& git -C $Root rev-parse HEAD 2>&1))[0].ToString().Trim()
    $out = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $syncWrapper -ProjectPath $Root -BoundaryType plan -FeatureRef 001-fixture -IterationNumber 002 -AuthCommitHash $head 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $out }
}
function Invoke-Scaffold002 {
    param([string]$Root)
    $out = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $scaffolder -SpecPath (Join-Path $Root 'specs/001-fixture/spec.md') -IterationNumber 002 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    if ($LASTEXITCODE -ne 0) { Write-Host ('  scaffold output: ' + $out) }
    Assert-True ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath (Join-Path $Root 'specs/001-fixture/iterations/002/plan.md'))) 'scaffold-iteration-plan.ps1 wrote 002/plan.md'
    $null = & git -C $Root add -A 2>&1
    $null = & git -C $Root commit -q -m 'scaffold 002' 2>&1
}

$roots = New-Object System.Collections.Generic.List[string]
try {
    # ============ (a) the product's own order: verdict, scaffold, plan sync ============================
    Write-Host '  --- (a) 001 closed by its verdict, 002 scaffolded through the scaffolder, then the plan sync for 002 ---'
    $rootA = New-ClosedFirstIterationRepo; $roots.Add($rootA) | Out-Null
    $verdictA = Add-SpecrewBoundaryAuthorization -ProjectRoot $rootA -CurrentBoundary 'retro' -AuthorizedBoundary 'iteration-closeout' -AuthorizingHuman 'Fixture Human' -VerdictText 'approved for iteration-closeout' -EvidenceSource 'hook-captured-from-transcript' 2>$null
    Assert-True ($null -ne $verdictA -and [string]$verdictA.AuthorizedBoundary -ceq 'iteration-closeout') '(a) the closeout verdict is recorded'
    Assert-True (Test-SpecrewIterationSealed -IterationDirectory (Join-Path $rootA 'specs/001-fixture/iterations/001')) '(a) and 001 is sealed by it'
    $refusedAtVerdictA = @(Read-RefusedIterations -Root $rootA)
    Assert-True ($refusedAtVerdictA.Count -eq 1 -and $refusedAtVerdictA[0] -eq '002') ('(a) the rebind at authorization refuses naming 002 - the correct target, plan.md not yet scaffolded (named: {0})' -f ($refusedAtVerdictA -join ','))
    Assert-True ($null -eq (Read-Enforcement -Root $rootA).pending_crossing) '(a) so no crossing is open yet'
    $null = & git -C $rootA add -A 2>&1; $null = & git -C $rootA commit -q -m 'closeout authorized' 2>&1
    Invoke-Scaffold002 -Root $rootA
    $syncA = Invoke-PlanSync -Root $rootA
    if ($syncA.ExitCode -ne 0) { Write-Host ('  sync output: ' + $syncA.Output) }
    Assert-True ($syncA.ExitCode -eq 0) '(a) the plan sync for 002 exits 0'
    Assert-True ($syncA.Output -match 'iteration_number\s*[:=]\s*"?002' -or ((Get-Content -LiteralPath (Join-Path $rootA '.specrew/start-context.json') -Raw) -match '"iteration_number":\s*"002"')) '(a) the record says 002'
    Assert-True ($syncA.Output -notmatch 'iteration 003') '(a) and the same invocation does NOT ask for iteration 003'
    $refusedA = @(Read-RefusedIterations -Root $rootA)
    Assert-True (@($refusedA | Where-Object { $_ -eq '003' }).Count -eq 0) ('(a) the journal carries no refusal naming 003 (refusals: {0})' -f ($refusedA -join ','))
    $crossingA = (Read-Enforcement -Root $rootA).pending_crossing
    Assert-True ($null -ne $crossingA -and [string]$crossingA.from_boundary -eq 'iteration-closeout' -and [string]$crossingA.to_boundary -eq 'plan') '(a) the crossing for 002 is MINTED: iteration-closeout -> plan'
    Assert-True ($null -ne $crossingA -and [string]$crossingA.working_boundary -eq 'plan') '(a) with the working boundary at plan'
    # R2 (PRED-BETA4-029), the reviewer's product-order probe on this very fixture: closeout 001 -> scaffold 002
    # -> plan sync 002 -> readiness. The ledger's last authorization is 001's iteration-closeout, which sorts
    # after before-implement; readiness for 002 must not borrow it.
    $readinessA = (& pwsh -NoProfile -File (Join-Path $moduleTree 'extensions/specrew-speckit/scripts/readiness-verdict.ps1') -ProjectPath $rootA -AsJson 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    $readinessObj = $null; try { $readinessObj = $readinessA | ConvertFrom-Json } catch { $readinessObj = $null }
    Assert-True ($null -ne $readinessObj -and -not [bool]$readinessObj.authorized -and [string]$readinessObj.last_authorized_boundary -eq 'iteration-closeout') ('(a) R2: readiness after the next iteration''s plan sync is BLOCKED - 001''s closeout is not 002''s implementation approval (got: {0})' -f ($readinessA -replace '\s+', ' ').Substring(0, [Math]::Min(160, ($readinessA -replace '\s+', ' ').Length)))

    # ============ (b) the router-skill shape: scaffold, verdict, plan sync ============================
    Write-Host '  --- (b) the router-skill shape: 002 scaffolded BEFORE the closeout verdict, then the plan sync for 002 ---'
    $rootB = New-ClosedFirstIterationRepo; $roots.Add($rootB) | Out-Null
    Invoke-Scaffold002 -Root $rootB
    $verdictB = Add-SpecrewBoundaryAuthorization -ProjectRoot $rootB -CurrentBoundary 'retro' -AuthorizedBoundary 'iteration-closeout' -AuthorizingHuman 'Fixture Human' -VerdictText 'approved for iteration-closeout' -EvidenceSource 'hook-captured-from-transcript' 2>$null
    Assert-True ($null -ne $verdictB) '(b) the closeout verdict is recorded'
    $crossingB0 = (Read-Enforcement -Root $rootB).pending_crossing
    Assert-True ($null -ne $crossingB0 -and [string]$crossingB0.to_boundary -eq 'plan' -and [string]$crossingB0.working_boundary -eq 'iteration-closeout') '(b) the rebind at authorization MINTS iteration-closeout -> plan (002/plan.md exists), working boundary still iteration-closeout'
    Assert-True (@(Read-RefusedIterations -Root $rootB).Count -eq 0) '(b) and refuses nothing'
    $null = & git -C $rootB add -A 2>&1; $null = & git -C $rootB commit -q -m 'closeout authorized' 2>&1
    $syncB = Invoke-PlanSync -Root $rootB
    if ($syncB.ExitCode -ne 0) { Write-Host ('  sync output: ' + $syncB.Output) }
    Assert-True ($syncB.ExitCode -eq 0) '(b) the plan sync for 002 exits 0'
    Assert-True ($syncB.Output -notmatch 'iteration 003') '(b) and does NOT ask for iteration 003'
    $refusedB = @(Read-RefusedIterations -Root $rootB)
    Assert-True (@($refusedB | Where-Object { $_ -eq '003' }).Count -eq 0) ('(b) the journal carries no refusal naming 003 (refusals: {0})' -f ($refusedB -join ','))
    $crossingB = (Read-Enforcement -Root $rootB).pending_crossing
    Assert-True ($null -ne $crossingB -and [string]$crossingB.from_boundary -eq 'iteration-closeout' -and [string]$crossingB.to_boundary -eq 'plan') '(b) the crossing the verdict opened SURVIVES the sync - the sync did not overwrite it with null'
    Assert-True ($null -ne $crossingB -and [string]$crossingB.working_boundary -eq 'plan') '(b) and now carries the working boundary plan'

    # ============ the check itself, both callers' shapes ==============================================
    Write-Host '  --- the check derives nothing; the constructor resolves the target from the working boundary ---'
    $owedClosed = Test-SpecrewBoundaryOwedArtifactsOnDisk -ProjectRoot $rootA -Boundary 'plan' -FromBoundary 'iteration-closeout' -FeatureRef '001-fixture' -IterationNumber '002'
    Assert-True ([string]$owedClosed.Iteration -eq '002' -and -not [bool]$owedClosed.Absent) 'handed 002 for iteration-closeout -> plan, the check looks at 002 - not 003'
    $owedMissing = Test-SpecrewBoundaryOwedArtifactsOnDisk -ProjectRoot $rootA -Boundary 'plan' -FromBoundary 'iteration-closeout' -FeatureRef '001-fixture' -IterationNumber '003'
    Assert-True ([string]$owedMissing.Iteration -eq '003' -and [bool]$owedMissing.Absent) 'handed 003, it looks at 003 and finds nothing - the value in is the value read'
}
finally {
    foreach ($r in $roots) { if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }
    if ($null -ne $mutantTree -and (Test-Path -LiteralPath $mutantTree)) { Remove-Item -LiteralPath $mutantTree -Recurse -Force -ErrorAction SilentlyContinue }
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
}

if ($script:Failures -gt 0) {
    Write-Host ("plan-sync-target-iteration: {0} FAILED" -f $script:Failures)
    exit 1
}
Write-Host 'plan-sync-target-iteration: all cases passed'
exit 0
