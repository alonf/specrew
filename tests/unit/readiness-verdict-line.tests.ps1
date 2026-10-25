# B4F-071: THE OVERALL VERDICT LINE COMES FROM THE LEDGER, AND EVERY READER QUOTES IT VERBATIM.
#
# On the router-skill project (Copilot CLI 1.0.83, 2026-09-10) the before-implement readiness sub-agent read
# the ledger and wrote "Overall verdict: BLOCKED for implementation - no tasks -> before-implement
# authorization exists". The crew summarized the passing artifact checks as PASS, dropped that line, and
# announced T201. readiness-verdict.ps1 prints that line from the ledger; the command makes it the report's
# first line; the coordinator quotes it verbatim. This suite pins the script's two answers and the three
# surfaces that name it. Mutation (recorded, not a switch): `-ge` -> `-gt` in the script makes Case 2 red.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script_ = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/readiness-verdict.ps1'
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')

function New-LedgerRoot {
    param([string]$LastAuthorized, [string]$Working, [switch]$WithPendingCrossing, [string[]]$VerdictChain = @())
    $root = Join-Path ([IO.Path]::GetTempPath()) ('rvl-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture/iterations/001') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/iterations/001/plan.md'), "# Iteration Plan: 001`n`n**Status**: planning`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/iterations/001/quality-placeholder.md'), "x`n", [Text.UTF8Encoding]::new($false))
    $ctx = [ordered]@{
        schema = 'v2'; feature_path = (Join-Path $root 'specs/001-fixture')
        session_state = [ordered]@{ active = $true; boundary_type = $Working; feature_ref = '001-fixture'; iteration_number = '001'; recorded_at = '2026-09-10T12:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = $LastAuthorized; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    # -VerdictChain writes the ledger's verdict rows in order, e.g. 'plan','tasks','iteration-closeout','plan'.
    $rows = [System.Collections.Generic.List[object]]::new(); $from = 'specify'
    foreach ($to in $VerdictChain) {
        $rows.Add([ordered]@{ from_boundary = $from; to_boundary = $to; verdict_text = ('approved for ' + $to); authorizing_human = 'Fixture Human'; recorded_at = '2026-09-10T12:00:00Z'; auth_commit_hash = 'abc1234' }) | Out-Null
        $from = $to
    }
    $ctx.boundary_enforcement.verdict_history = @($rows.ToArray())
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    if ($WithPendingCrossing) {
        # a real commit, because the scoped crossing binds to a git tree
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-fixture/iterations/001/quality') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/iterations/001/quality/hardening-gate.md'), "# Hardening Gate`n", [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/runtime/`n", [Text.UTF8Encoding]::new($false))
        $null = & git -C $root init -q -b main 2>&1; $null = & git -C $root config user.email 'f@f' 2>&1; $null = & git -C $root config user.name 'f' 2>&1
        $null = & git -C $root add -A 2>&1; $null = & git -C $root commit -q -m fixture 2>&1
        $head = (@(& git -C $root rev-parse HEAD 2>&1))[0].ToString().Trim()
        $null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $root -WorkingBoundary $Working -BoundaryCommitHash $head -RecordedAt '2026-09-10T12:00:01Z' 2>$null
    }
    return $root
}
function Invoke-Line { param([string]$Root) $o = (& pwsh -NoProfile -File $script_ -ProjectPath $Root 2>&1 | ForEach-Object { [string]$_ }) -join "`n"; return [pscustomobject]@{ Code = $LASTEXITCODE; Out = $o.Trim() } }

Write-Host 'readiness-verdict-line'
$roots = New-Object System.Collections.Generic.List[string]
try {
    Write-Host '  --- Case 1: the router-skill shape - authorized through tasks, tasks -> before-implement pending ---'
    $r1 = New-LedgerRoot -LastAuthorized 'tasks' -Working 'before-implement' -WithPendingCrossing; $roots.Add($r1) | Out-Null
    $l1 = Invoke-Line -Root $r1
    Assert-True ($l1.Code -eq 0) 'the script exits 0 - the line is evidence, not a gate'
    Assert-True ($l1.Out -match '^Overall verdict: BLOCKED for implementation') ('the line says BLOCKED (got: ' + $l1.Out.Substring(0, [Math]::Min(80, $l1.Out.Length)) + ')')
    Assert-True ($l1.Out -match "authorized through 'tasks'|last authorized boundary is 'tasks'") 'and names how far the ledger authorizes: tasks'
    Assert-True ($l1.Out -match "pending crossing is 'tasks -> before-implement'") 'and the pending crossing'
    Assert-True ($l1.Out -match "approved for before-implement") 'and the one move that clears it'
    Assert-True (@($l1.Out -split "`n").Count -eq 1) 'it is ONE line'

    Write-Host '  --- Case 2: authorized through before-implement ---'
    $r2 = New-LedgerRoot -LastAuthorized 'before-implement' -Working 'before-implement'; $roots.Add($r2) | Out-Null
    $l2 = Invoke-Line -Root $r2
    Assert-True ($l2.Out -match '^Overall verdict: READY for implementation') 'the line says READY when the ledger says before-implement'
    Write-Host '  --- Case 3: authorized past it ---'
    $r3 = New-LedgerRoot -LastAuthorized 'review-signoff' -Working 'review-signoff'; $roots.Add($r3) | Out-Null
    Assert-True ((Invoke-Line -Root $r3).Out -match '^Overall verdict: READY') 'a later authorized boundary is READY too'
    Write-Host '  --- Case 4: nothing pending, nothing authorized past plan ---'
    $r4 = New-LedgerRoot -LastAuthorized 'plan' -Working 'plan'; $roots.Add($r4) | Out-Null
    $l4 = Invoke-Line -Root $r4
    Assert-True ($l4.Out -match '^Overall verdict: BLOCKED' -and $l4.Out -match 'no crossing is pending') 'BLOCKED, and says no crossing is pending'

    Write-Host '  --- R2 (PRED-BETA4-029): a previous iteration''s closeout is not this iteration''s implementation approval ---'
    $r5 = New-LedgerRoot -LastAuthorized 'iteration-closeout' -Working 'plan' -VerdictChain @('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout'); $roots.Add($r5) | Out-Null
    $l5 = Invoke-Line -Root $r5
    Assert-True ($l5.Out -match '^Overall verdict: BLOCKED') 'last authorized iteration-closeout (001 closed), a new cycle with nothing authorized: BLOCKED - the ordinal would have said READY'
    Assert-True ($l5.Out -match "previous iteration's closeout") 'and it says why: the last authorization is the previous iteration''s closeout'
    $r6 = New-LedgerRoot -LastAuthorized 'before-implement' -Working 'before-implement' -VerdictChain @('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout', 'plan', 'tasks', 'before-implement'); $roots.Add($r6) | Out-Null
    Assert-True ((Invoke-Line -Root $r6).Out -match '^Overall verdict: READY') 'the second cycle authorized through before-implement: READY - the cycle, not the whole history, decides'
    $r7 = New-LedgerRoot -LastAuthorized 'tasks' -Working 'tasks' -VerdictChain @('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout', 'plan', 'tasks'); $roots.Add($r7) | Out-Null
    $l7 = Invoke-Line -Root $r7
    Assert-True ($l7.Out -match '^Overall verdict: BLOCKED' -and $l7.Out -match "cycle is authorized through 'tasks'") 'the second cycle at tasks: BLOCKED, naming how far this cycle is authorized'

    Write-Host '  --- R2 follow-up (PRED-BETA4-031): an approval invalidated by a scoped correction is not current authority ---'
    # The reviewer's reproduction through the real correction API, in the boundary-correction-ledger fixture's
    # shape: a historical tasks -> before-implement approval, the current scoped crossing, a scoped invalidation
    # resulting in tasks. Effective authority: tasks; effective approvals: none. Raw history still holds the
    # approval, and readiness must not recover it.
    . (Join-Path $repoRoot 'scripts/internal/bootstrap/HandoverStore.ps1')
    $r8 = Join-Path ([IO.Path]::GetTempPath()) ('rvl-corr-' + [guid]::NewGuid().ToString('N').Substring(0, 8)); $roots.Add($r8) | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $r8 '.specrew') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $r8 'README.md'), "# Fixture`n", [Text.UTF8Encoding]::new($false))
    $null = & git -C $r8 init -q 2>&1; $null = & git -C $r8 config user.email 'f@f' 2>&1; $null = & git -C $r8 config user.name 'f' 2>&1
    $null = & git -C $r8 add README.md 2>&1; $null = & git -C $r8 commit -q -m 'fixture' 2>&1
    $commit8 = ([string](& git -C $r8 rev-parse HEAD)).Trim().ToLowerInvariant()
    $tree8 = ([string](& git -C $r8 rev-parse 'HEAD^{tree}')).Trim().ToLowerInvariant()
    $original8 = [ordered]@{ from_boundary = 'tasks'; to_boundary = 'before-implement'; verdict_text = 'approved for before-implement'; authorizing_human = 'human@example.test'; recorded_at = '2026-09-01T10:00:00Z'; auth_commit_hash = $commit8; evidence_source = 'hook-captured-from-transcript'; kind = 'standard' }
    $originalId8 = Get-SpecrewBoundaryAuthorizationEntryId -Entry $original8
    $scope8 = New-SpecrewBoundaryCrossingIdentity -FromBoundary 'tasks' -ToBoundary 'before-implement' -WorkingBoundary 'before-implement' -BoundaryCommitHash $commit8 -ArtifactStateId $tree8 -RecordedAt '2026-09-02T10:00:00Z'
    $ctx8 = [ordered]@{
        schema = 'v2'
        session_state = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '001-fixture'; feature_path = $null; iteration_number = '001'; task_id = $null; auth_commit_hash = $commit8; recorded_at = '2026-09-02T10:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'before-implement'; pending_next_boundary = $null; pending_crossing = $scope8; policy_classes = Get-SpecrewBoundaryPolicyClassMap -ProjectRoot $r8; verdict_history = @($original8); correction_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $r8 '.specrew/start-context.json'), (($ctx8 | ConvertTo-Json -Depth 24) + "`n"), [Text.UTF8Encoding]::new($false))
    Assert-True ((Invoke-Line -Root $r8).Out -match '^Overall verdict: READY') '(control) before the correction the approval is current and readiness is READY'
    $written8 = Add-SpecrewBoundaryAuthorizationCorrection -ProjectRoot $r8 -OriginalEntryId $originalId8 -ScopeFromBoundary 'tasks' -ScopeToBoundary 'before-implement' -WorkingBoundary 'before-implement' -ScopeBoundaryCommitHash $commit8 -ScopeArtifactStateId $tree8 -ResultingLastAuthorizedBoundary 'tasks' -CorrectingAuthority 'human@example.test' -AuthorityVerdictText 'approved for tasks' -AuthorityAuthCommitHash $commit8 -Reason 'The approval was for a different scoped crossing and is invalidated for this one.' -RecordedAt '2026-09-02T10:05:00Z'
    Assert-True ([bool]$written8.Appended) 'the scoped invalidation is recorded through the real correction API'
    $eff8 = Get-SpecrewBoundaryEnforcementState -ProjectRoot $r8
    Assert-True ([string]$eff8.EffectiveState['last_authorized_boundary'] -eq 'tasks' -and @($eff8.EffectiveState['verdict_history']).Count -eq 0 -and @($eff8.State['verdict_history']).Count -eq 1) 'effective authority is tasks with no effective approvals, while raw history still holds the one'
    $l8 = Invoke-Line -Root $r8
    Assert-True ($l8.Out -match '^Overall verdict: BLOCKED') ('after the correction readiness is BLOCKED - the invalidated approval is not recovered from raw history (got: ' + $l8.Out.Substring(0, [Math]::Min(90, $l8.Out.Length)) + ')')

    Write-Host '  --- the surfaces that carry the line ---'
    foreach ($rel in @('extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md', '.specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md')) {
        $cmd = Get-Content -LiteralPath (Join-Path $repoRoot $rel) -Raw -Encoding UTF8
        Assert-True ($cmd -match 'readiness-verdict\.ps1' -and $cmd -match '(?i)first line of your report, verbatim') ("the command names the script and the verbatim first-line rule: " + $rel)
        Assert-True ($cmd -match '(?i)artifact checks that all pass do not make the overall verdict READY') ("and says passing artifacts are not the verdict: " + $rel)
    }
    $coord = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md') -Raw -Encoding UTF8
    Assert-True ($coord -match 'readiness-verdict\.ps1' -and $coord -match '(?i)quoted VERBATIM as the first line') 'the coordinator quotes the line verbatim in the packet'
    Assert-True ($coord -match '(?i)never summarized as the overall verdict') 'and never summarizes passing artifacts as the verdict'
    $manifest = Get-Content -LiteralPath (Join-Path $repoRoot 'Specrew.psd1') -Raw -Encoding UTF8
    Assert-True ($manifest -match "'extensions/specrew-speckit/scripts/readiness-verdict\.ps1'") 'the script ships: it is in the package FileList'
    Assert-True ((Get-Content -LiteralPath $script_ -Raw) -ceq (Get-Content -LiteralPath (Join-Path $repoRoot '.specify/extensions/specrew-speckit/scripts/readiness-verdict.ps1') -Raw)) 'the deployed mirror is byte-identical'
}
finally { foreach ($r in $roots) { if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } } }

if ($script:Failures -gt 0) { Write-Host ("readiness-verdict-line: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'readiness-verdict-line: all cases passed'
exit 0
