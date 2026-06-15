$ErrorActionPreference = 'Stop'

# F-174 iteration 010. Regression floor for the `specrew start` recovery path — the ONLY recovery seam for
# antigravity (no hooks) and any non-hook launch. Pins THREE things the iter-10 robustness mandate requires:
#   T001 - Get-CoordinatorResumePromptBlock renders the `## Resume Reconciliation` block (re-computed CURRENT
#          git delta vs the last stop) so the resuming agent is handed the ACTUAL tree, not a stale snapshot.
#   T008 - the snapshot is shape-tolerant: it accepts EITHER the raw session anchor (Get-SpecrewSessionAnchor:
#          `boundary`/`iteration`, no `task_id`) OR the mapped generator shape (`boundary_type`/
#          `iteration_number`/`task_id`) WITHOUT throwing under Set-StrictMode -Version Latest. Before the
#          ConvertTo-NormalizedResumeSessionState fix a raw-anchor call threw "property iteration_number
#          cannot be found" -> a HARD throw inside Get-StartPrompt (the call is not try-wrapped) -> crashed
#          `specrew start` / silent provider fail-open: the D-009 trap class. This is the regression guard.
#   Fail-safe - a $null SessionState (with a resolvable feature path) still renders, never throws.

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
. "$repoRoot/scripts/internal/coordinator-resume.ps1"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function New-ResumeFixture {
    param([string]$Root)
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    & git -C $Root init -q 2>&1 | Out-Null
    & git -C $Root config user.email 'fixture@specrew.test' 2>&1 | Out-Null
    & git -C $Root config user.name 'Specrew Fixture' 2>&1 | Out-Null
    & git -C $Root config commit.gpgsign false 2>&1 | Out-Null
    # A real feature + iteration so feature_ref/iteration resolve cleanly.
    $iterDir = Join-Path $Root 'specs/feat-x/iterations/001'
    New-Item -ItemType Directory -Path $iterDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $iterDir 'plan.md') -Value "# Plan`n`n**Status**: executing`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $Root 'README.md') -Value "seed`n" -Encoding UTF8
    & git -C $Root add -A 2>&1 | Out-Null
    & git -C $Root commit -q -m 'seed' 2>&1 | Out-Null
    $headSha = (& git -C $Root rev-parse HEAD).Trim()
    # Seed a rolling handover whose from_commit == HEAD (so the delta is "since the last stop").
    $handoverDir = Join-Path $Root '.specrew/handover'
    Write-SpecrewRollingHandover -HandoverDir $handoverDir -Source 'Stop' -FromHost 'claude' `
        -RecordedAt '2026-06-11T22:00:00Z' -FromCommit $headSha -ActiveFeature 'feat-x' -ActiveBoundary 'implement' `
        -MechanicalSections @{ 'What I just did' = 'seeded the fixture' } | Out-Null
    # An UNCOMMITTED user file -> the delta surfaces it -> the "READ those files" directive fires.
    Set-Content -LiteralPath (Join-Path $Root 'notes.md') -Value "work in progress`n" -Encoding UTF8
    return $headSha
}

$root = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t008-" + [guid]::NewGuid().ToString('N'))
try {
    $headSha = New-ResumeFixture -Root $root
    $featPath = Join-Path $root 'specs/feat-x'

    # --- A. Unit: ConvertTo-NormalizedResumeSessionState maps BOTH shapes; $null -> $null. ---
    Assert-True ($null -eq (ConvertTo-NormalizedResumeSessionState -SessionState $null)) 'normalizer: $null -> $null'
    $rawAnchor = [pscustomobject]@{ feature_ref = 'feat-x'; feature_path = $featPath; boundary = 'implement'; iteration = '001' }
    $normRaw = ConvertTo-NormalizedResumeSessionState -SessionState $rawAnchor
    Assert-True ($normRaw.iteration_number -eq '001') 'normalizer: raw `iteration` -> `iteration_number`'
    Assert-True ($normRaw.boundary_type -eq 'implement') 'normalizer: raw `boundary` -> `boundary_type`'
    Assert-True ($normRaw.PSObject.Properties.Match('task_id').Count -gt 0) 'normalizer: `task_id` always present (null on raw anchor)'
    $mappedIn = [pscustomobject]@{ feature_ref = 'feat-x'; feature_path = $featPath; boundary_type = 'plan'; iteration_number = '007'; task_id = 'T003' }
    $normMapped = ConvertTo-NormalizedResumeSessionState -SessionState $mappedIn
    Assert-True ($normMapped.iteration_number -eq '007' -and $normMapped.task_id -eq 'T003') 'normalizer: mapped shape passes through unchanged'

    # --- B. MAPPED generator shape: the reconciliation block renders with the re-computed CURRENT delta. ---
    $mapped = [pscustomobject]@{ feature_ref = 'feat-x'; feature_path = $featPath; boundary_type = 'implement'; iteration_number = '001'; task_id = $null }
    $blockMapped = Get-CoordinatorResumePromptBlock -ProjectRoot $root -ResolvedFeaturePath $featPath -SessionState $mapped
    Assert-True ($null -ne $blockMapped) 'mapped shape: block is not null'
    Assert-True ($blockMapped -match '## Welcome Back Snapshot') 'mapped shape: Welcome Back Snapshot present'
    Assert-True ($blockMapped -match '## Resume Reconciliation') 'mapped shape: Resume Reconciliation block present (T001)'
    Assert-True ($blockMapped -match 'Last captured stop: 2026-06-11T22:00:00Z') 'mapped shape: surfaces the handover last-stop timestamp'
    Assert-True ($blockMapped -match 'boundary implement') 'mapped shape: surfaces the last-stop boundary'
    Assert-True ($blockMapped -match 'notes\.md') 'mapped shape: surfaces the changed user file (re-computed delta)'
    Assert-True ($blockMapped -match 'READ those files') 'mapped shape: directs the agent to READ + continue'

    # --- C. RAW anchor shape: MUST NOT throw (the D-009 hardening regression guard, T008). ---
    $blockRaw = $null
    $threw = $false
    try { $blockRaw = Get-CoordinatorResumePromptBlock -ProjectRoot $root -ResolvedFeaturePath $featPath -SessionState $rawAnchor }
    catch { $threw = $true }
    Assert-True (-not $threw) 'raw anchor shape: does NOT throw under StrictMode (was the D-009 hard-throw before the fix)'
    Assert-True ($null -ne $blockRaw -and ($blockRaw -match '## Resume Reconciliation')) 'raw anchor shape: still renders the reconciliation block'
    Assert-True ($blockRaw -match 'notes\.md') 'raw anchor shape: surfaces the same re-computed delta as the mapped shape'

    # --- D. Fail-safe: $null SessionState + resolvable feature path still renders (never throws). ---
    $blockNull = Get-CoordinatorResumePromptBlock -ProjectRoot $root -ResolvedFeaturePath $featPath -SessionState $null
    Assert-True ($null -ne $blockNull -and ($blockNull -match '## Welcome Back Snapshot')) 'null SessionState: renders from the resolved feature path'

    Write-Host "`n=== CoordinatorResumeReconciliation.Tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
