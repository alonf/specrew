# PRED-BETA4-051: THE COVERAGE STATE'S `exhausted` IS THE ACTIVE ITERATION'S, NOT THE LAST DELIVERED REVIEW'S.
#
# Field, router-skill project on e9334af1, twice: the coverage-decision block demanded "approved for allowance
# reset / continue without coverage / hold" while its own line said "iteration 003 has no campaign yet, so it
# starts with a fresh allowance". The state selected the last DELIVERED review's campaign (i002, 4 of 4 spent)
# and read `exhausted` from it; the label knew better and the predicate did not. The fixture is that store's
# shape: campaign i002 with four delivered runs covering the base tree, campaign i003 with two budget-reset
# facts and no grants, session_state.iteration_number 003, source moved since. Mutation (recorded, not a
# switch): the iteration check removed from the state reds case 1's `exhausted $false` and nothing else.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/reviewed-state-digest.ps1')

function New-RouterShapedStore {
    param([string]$ActiveIteration)
    $root = Join-Path ([IO.Path]::GetTempPath()) ('csai-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path (Join-Path $root 'src'), (Join-Path $root '.specrew'), (Join-Path $root 'scripts/internal') -Force | Out-Null
    # the engine, so rounds come from the ONE production counter
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/internal/continuous-co-review') -Destination (Join-Path $root 'scripts/internal/continuous-co-review') -Recurse -Force
    [IO.File]::WriteAllText((Join-Path $root 'src/app.ts'), "export const a = 1;`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/`n", [Text.UTF8Encoding]::new($false))
    & git -C $root init -q -b main; & git -C $root config user.email 'f@f'; & git -C $root config user.name 'f'
    & git -C $root add -A 2>$null; & git -C $root commit -q -m base 2>$null
    $covered = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root).tree_id
    # campaign i002: four delivered runs on the covered tree - the allowance spent
    $c2 = 'cmp-001-feat-i002'
    for ($n = 1; $n -le 4; $n++) {
        $runId = ('run-20260913-00000000{0}-aaaaaaa{0}' -f $n)
        $runDir = Join-Path $root ('.specrew/review/authority/campaigns/{0}/runs/{1}' -f $c2, $runId)
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        $result = [ordered]@{
            schema_version = '1.0'; campaign_id = $c2; run_id = $runId; target_digest = $covered; harness_id = 'fx'
            completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'; termination_verified = $true
            containment = 'verified'; currentness = 'current'; validation = 'valid'; can_approve_current = $false
            failure_reason = $null; summary = 's'; findings = @(); started_at = ('2026-09-13T02:0{0}:00Z' -f $n)
            ended_at = ('2026-09-13T02:0{0}:30Z' -f $n); duration_ms = 30000; examined_paths = @('src/app.ts')
        }
        [IO.File]::WriteAllText((Join-Path $runDir 'result.json'), ($result | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    }
    # campaign i003: two budget-reset facts, no grants, no runs - the router-skill store's shape
    $c3 = 'cmp-001-feat-i003'
    $resets = Join-Path $root ('.specrew/review/authority/campaigns/{0}/budget-resets' -f $c3)
    New-Item -ItemType Directory -Path $resets -Force | Out-Null
    foreach ($id in @('reset-1', 'reset-2')) {
        [IO.File]::WriteAllText((Join-Path $resets ($id + '.json')), (([ordered]@{ schema_version = '1.0'; fact_type = 'round-budget-reset'; campaign_id = $c3; reset_id = $id; observed_at = '2026-09-13T10:08:00Z' }) | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
    }
    $ctx = [ordered]@{ schema = 'v2'; session_state = [ordered]@{ active = $true; feature_ref = '001-feat'; iteration_number = $ActiveIteration; boundary_type = 'before-implement' } }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    # source moved since the delivered review
    [IO.File]::WriteAllText((Join-Path $root 'src/app.ts'), "export const a = 2;`n", [Text.UTF8Encoding]::new($false))
    & git -C $root add -A 2>$null; & git -C $root commit -q -m 'iteration work' 2>$null
    return $root
}

Write-Host 'coverage-state-active-iteration'
$r3 = New-RouterShapedStore -ActiveIteration '003'
$r2 = New-RouterShapedStore -ActiveIteration '002'
try {
    Write-Host '  --- case 1: the field shape - the delivered campaign is i002 (spent), the active iteration is 003 ---'
    $s = Get-SpecrewReviewCoverageState -ProjectRoot $r3
    Assert-True ([bool]$s.available -and [string]$s.campaign_id -eq 'cmp-001-feat-i002') ('the state reads the last delivered review''s campaign (got {0})' -f $s.campaign_id)
    Assert-True ([int]$s.rounds_used -eq 4 -and [int]$s.budget_total -eq 4) ('and that campaign''s counter: {0} of {1}' -f $s.rounds_used, $s.budget_total)
    Assert-True ([string]$s.campaign_iteration -eq '002' -and [string]$s.active_iteration -eq '003' -and -not [bool]$s.campaign_is_active) ('the state carries the distinction: campaign iteration {0}, active iteration {1}, campaign_is_active {2}' -f $s.campaign_iteration, $s.active_iteration, $s.campaign_is_active)
    Assert-True (-not [bool]$s.exhausted) 'and exhausted is FALSE - the active iteration''s allowance is fresh; the coverage-decision block does not fire'
    Assert-True ([int]$s.source_drift_count -ge 1) ('source has moved since the delivered review ({0}), so nothing else suppressed the block' -f $s.source_drift_count)
    $line = Get-SpecrewReviewCoverageLine -ProjectRoot $r3
    Assert-True ($line -match 'iteration 003 has no campaign yet, so it starts with a fresh allowance' -and $line -match '0 of 4 rounds remaining in campaign cmp-001-feat-i002') ('the coverage line says whose rounds those are, from the state''s own fields (' + $line + ')')

    Write-Host '  --- case 2: the same store with the active iteration still 002 - the original W52 stop, kept ---'
    $s2 = Get-SpecrewReviewCoverageState -ProjectRoot $r2
    Assert-True ([bool]$s2.campaign_is_active -and [bool]$s2.exhausted) ('when the delivered campaign IS the active iteration''s, an exhausted allowance still reads exhausted (campaign_is_active {0}, exhausted {1})' -f $s2.campaign_is_active, $s2.exhausted)
    $line2 = Get-SpecrewReviewCoverageLine -ProjectRoot $r2
    Assert-True ($line2 -match '0 of 4 rounds remaining in campaign cmp-001-feat-i002' -and $line2 -notmatch 'fresh allowance') 'and the line names the campaign without the fresh-allowance sentence'
}
finally {
    foreach ($d in @($r3, $r2)) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:Failures -gt 0) { Write-Host ("coverage-state-active-iteration: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'coverage-state-active-iteration: all cases passed'
exit 0
