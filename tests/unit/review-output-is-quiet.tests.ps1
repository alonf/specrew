# PRED-BETA4-048 / B4F-056 (located): THE REVIEWER SCAFFOLD'S OWN OUTPUT DOES NOT STALE THE REVIEW IT RECORDS.
#
# The router-skill sign-off of 2026-09-13: after the final round the coverage state read
# `source_drift = dashboard.md, plan.md` and the Stop hook asked for a coverage decision the sign-off had
# already made. `dashboard.md` is written by scaffold-reviewer-artifacts.ps1 (sixth in its reviewer index) and
# by the closeout auto-render; `security-surface.md` is the scaffold's other output; neither was in the ONE
# execution-record classifier (Test-SpecrewLifecycleExecutionRecordPath), so the product's review output
# counted as uncovered source. `review.md` itself was already quiet - measured, source_drift_count 0 at the
# review.md commit. Case 2 runs the real drift function on a real repository: a covered tree, then a commit
# adding the two files, reads zero source drift; a plan.md edit still stales (W51's ruling kept).
# Mutation (recorded, not a switch): the two names removed from the allowlist reds cases 1 and 2.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/reviewed-state-digest.ps1')

Write-Host 'review-output-is-quiet'
Write-Host '  --- case 1: the classifier reads the scaffold''s outputs as records ---'
$feature = '001-feat'
foreach ($name in @('dashboard.md', 'security-surface.md', 'review.md', 'retro.md', 'state.md')) {
    Assert-True ([bool](Test-SpecrewLifecycleExecutionRecordPath -Path ("specs/$feature/iterations/001/$name") -FeatureId $feature)) ("$name under the iteration is an execution record (quiet)")
}
Assert-True (-not [bool](Test-SpecrewLifecycleExecutionRecordPath -Path "specs/$feature/iterations/001/plan.md" -FeatureId $feature)) 'plan.md is NOT a record - the standard the code was judged against stales (W51 kept)'
Assert-True (-not [bool](Test-SpecrewLifecycleExecutionRecordPath -Path "specs/$feature/spec.md" -FeatureId $feature)) 'spec.md is NOT a record'

Write-Host '  --- case 2: the real drift function on a real repository ---'
$root = Join-Path ([IO.Path]::GetTempPath()) ('roq-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
try {
    $iter = Join-Path $root "specs/$feature/iterations/001"
    New-Item -ItemType Directory -Path $iter, (Join-Path $root 'src'), (Join-Path $root '.specrew') -Force | Out-Null
    & git -C $root init -q -b main
    & git -C $root config user.email 'f@f'; & git -C $root config user.name 'f'; & git -C $root config core.autocrlf false
    [IO.File]::WriteAllText((Join-Path $root 'src/app.ps1'), "function Get-App { 'v1' }`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $root "specs/$feature/spec.md"), "# Feature Specification: Feat`n`nBody.`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $iter 'plan.md'), "# Iteration Plan: 001`n`n**Status**: implementing`n", [Text.UTF8Encoding]::new($false))
    New-Item -ItemType Directory -Path (Join-Path $root '.specify') -Force | Out-Null
    # the active feature, as the classifier resolves it (start-context first, feature.json second)
    [IO.File]::WriteAllText((Join-Path $root '.specify/feature.json'), ('{{"feature":"{0}","feature_directory":"specs/{0}"}}' -f $feature), [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ('{{"schema":"v2","session_state":{{"active":true,"feature_ref":"{0}","boundary_type":"before-implement"}}}}' -f $feature), [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/`n", [Text.UTF8Encoding]::new($false))
    & git -C $root add -A 2>$null; & git -C $root commit -q -m reviewed 2>$null
    $covered = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root
    Assert-True ([bool]$covered.ok) 'the covered digest is computed on the reviewed commit'

    # the finalization: review.md, dashboard.md and security-surface.md written by the scaffold after the round
    [IO.File]::WriteAllText((Join-Path $iter 'review.md'), "# Review`n`n**Overall Verdict**: accepted`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $iter 'dashboard.md'), "# Dashboard`n`nrendered`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $iter 'security-surface.md'), "# Security surface`n`nnone`n", [Text.UTF8Encoding]::new($false))
    & git -C $root add -A 2>$null; & git -C $root commit -q -m 'review records' 2>$null
    $current = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root
    $drift = Get-SpecrewReviewedTreeSourceDrift -ProjectRoot $root -CitedTreeId ([string]$covered.tree_id) -CurrentTreeId ([string]$current.tree_id)
    Assert-True ([bool]$drift.comparable -and @($drift.changed).Count -ge 3) ('the trees differ by the three records ({0} changed)' -f @($drift.changed).Count)
    Assert-True (@($drift.source).Count -eq 0) ('and NONE of them is source drift - the review''s own records do not stale it (source: {0})' -f (@($drift.source) -join ','))

    # the control: a plan.md edit after the round DOES stale, as ruled
    [IO.File]::WriteAllText((Join-Path $iter 'plan.md'), "# Iteration Plan: 001`n`n**Status**: implementing`n`n| T1 | corrected row |`n", [Text.UTF8Encoding]::new($false))
    & git -C $root add -A 2>$null; & git -C $root commit -q -m 'plan rows' 2>$null
    $current2 = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root
    $drift2 = Get-SpecrewReviewedTreeSourceDrift -ProjectRoot $root -CitedTreeId ([string]$covered.tree_id) -CurrentTreeId ([string]$current2.tree_id)
    Assert-True (@($drift2.source).Count -eq 1 -and ([string]$drift2.source[0]) -match 'plan\.md$') ('a plan.md edit after the round is source drift, as ruled (source: {0})' -f (@($drift2.source) -join ','))
}
finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($script:Failures -gt 0) { Write-Host ("review-output-is-quiet: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'review-output-is-quiet: all cases passed'
exit 0
