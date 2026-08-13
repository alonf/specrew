$ErrorActionPreference = 'Stop'

# Pre-tag slice #4 — the re-certify's two new blocking findings
# (run-f198-beta2-4e7d002c-certify, maintainer verdict 2026-08-09):
#
#   stale-marker-captures-before-refusal: verdict CAPTURE runs before the conformance refusal
#   (order 30 vs 40, and alone on prompt-submit) and accepts marker+approval whenever a crossing is
#   pending — StageEvidenceAbsent deliberately keeps the crossing pending, so a human reply to a
#   stale evidence-less packet authorizes the crossing the refusal exists to protect. The RED pins
#   the SHIPPED path: marker rendered FIRST, then the human's approval reply, through the real
#   prompt-submit capture entry, with the stage's evidence absent from the bound tree —
#   authorization must NOT be written, and the refused verdict must land loudly in the journal.
#   (Lose-no-verdict applies to legitimate boundaries, not evidence-less ones; the human is
#   re-prompted once evidence exists.)
#
#   feature-path-prefix-false-containment: Get-SpecrewBoundaryStageEvidence resolved the feature
#   inside the project with a case-insensitive string prefix and no separator boundary — a
#   prefix sibling (C:/repo-other vs C:/repo) and, on case-sensitive volumes, a case-distinct
#   sibling (/tmp/Repo vs /tmp/repo) were accepted as in-project. Both must be refused via
#   canonical relative containment; the case-distinct arm runs where the volume permits distinct
#   siblings and records the leg where it cannot (the mutation-gate pattern).
#
# The quality-profile link-escape (major) is NOT fixed here — routed to the documented link class
# (release-claim limitations 1/3) with a claim sentence, per the same verdict.
#
# Run standalone:
#   pwsh -NoProfile -File tests/unit/pretag-slice4-capture-containment.tests.ps1

$script:Red = 0
$script:Hard = 0
function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Red { param([string]$m) Write-Host "RED: $m" -ForegroundColor Yellow; $script:Red++ }
function Write-Measured { param([string]$m) Write-Host "MEASURED: $m" -ForegroundColor Cyan }
function Write-Inconclusive { param([string]$m) Write-Host "INCONCLUSIVE (fixture defect, NOT a pass): $m" -ForegroundColor Magenta; $script:Hard++ }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$handoverProvider = Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1'
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("slice4-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null
$savedModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot

try {
    # -----------------------------------------------------------------------------------------
    # CAPTURE — evidence-less crossing, marker rendered FIRST, human approval reply through the
    # real prompt-submit entry. Authorization must NOT be written; the refusal must be journaled.
    # -----------------------------------------------------------------------------------------
    $proj = Join-Path $scratch 'p'
    $featureDir = Join-Path $proj 'specs\050-host-neutral-gate'
    $iterDir = Join-Path $featureDir 'iterations\001'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew\runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $iterDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $featureDir 'spec.md') -Value "# Feature Specification: Host-Neutral Gate`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iterDir 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: implementing" -Encoding UTF8
    $ctx = [ordered]@{
        schema               = 'v2'
        feature_path         = $featureDir
        session_state        = [ordered]@{ active = $true; boundary_type = 'review-signoff'; feature_ref = '050-host-neutral-gate'; host = 'claude'; iteration_number = '001'; recorded_at = '2026-06-20T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'before-implement'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $null = & git -C $proj init --quiet
    $null = & git -C $proj config core.autocrlf false
    $null = & git -C $proj add -A
    $null = & git -C $proj -c user.name=Fixture -c user.email=f@x.invalid commit --quiet -m 'baseline'
    if ($LASTEXITCODE -ne 0) { throw 'capture fixture baseline commit failed' }
    $head = (@(& git -C $proj rev-parse HEAD) | Select-Object -First 1).Trim()

    # Mint the SCOPED crossing with the engine's own writer, bound to the real tree — the shape in
    # which StageEvidenceAbsent is computed from the bound tree (review.md genuinely absent).
    $mint = Join-Path $scratch 'mint.ps1'
    [System.IO.File]::WriteAllText($mint, @"
`$ErrorActionPreference = 'Stop'
. '$($repoRoot -replace "'", "''")\extensions\specrew-speckit\scripts\shared-governance.ps1'
`$scope = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot '$proj' -WorkingBoundary 'review-signoff' -BoundaryCommitHash '$head'
'MINT ' + `$(if (`$null -eq `$scope) { 'none' } else { [string]`$scope['from_boundary'] + '->' + [string]`$scope['to_boundary'] })
`$pv = Get-SpecrewPendingVerdictState -ProjectRoot '$proj'
'PRESTATE pending=' + [bool]`$pv.HasPendingVerdict + ' evidence_absent=' + [bool]`$pv.StageEvidenceAbsent
"@, [System.Text.UTF8Encoding]::new($false))
    $mintOut = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $mint 2>&1) -join ' ').Trim()
    Write-Measured ("capture fixture: {0}" -f $mintOut.Substring(0, [Math]::Min(200, $mintOut.Length)))
    if ($mintOut -notmatch 'MINT before-implement->review-signoff' -or $mintOut -notmatch 'evidence_absent=True') {
        Write-Inconclusive 'the scoped evidence-less state did not materialize — the capture leg cannot measure the finding'
        exit 2
    }

    # The SHIPPED sequence: the assistant's packet with the matching marker exists FIRST in the
    # transcript; the human's approval arrives as the prompt-submit message.
    $tx = Join-Path $scratch 'transcript.jsonl'
    $turns = @(
        @{ role = 'user'; text = 'Where do we stand?' },
        @{ role = 'assistant'; text = "boundary packet for review signoff. <!-- SPECREW-VERDICT-BOUNDARY: before-implement -> review-signoff --> What's your verdict?" }
    )
    $lines = foreach ($t in $turns) { (@{ type = $t.role; message = @{ role = $t.role; content = @(@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress) }
    [System.IO.File]::WriteAllText($tx, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))

    $null = & pwsh -NoProfile -File $handoverProvider --project-root $proj --host-kind claude --source-event UserPromptSubmit --transcript-path $tx --last-user-message 'approved for review-signoff' 2>$null

    $after = (Get-Content -LiteralPath (Join-Path $proj '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).boundary_enforcement
    $journalPath = Join-Path $proj '.specrew\runtime\handover-journal.jsonl'
    $journal = if (Test-Path $journalPath) { (@(Get-Content $journalPath) -join "`n") } else { '' }
    $authorized = ([string]$after.last_authorized_boundary -eq 'review-signoff') -or (@($after.verdict_history).Count -gt 0)
    $refusalJournaled = $journal -match 'evidence' -and $journal -match 'approved for review-signoff'
    Write-Measured ("capture: last_authorized={0}; history_count={1}; refusal-journaled={2}" -f [string]$after.last_authorized_boundary, @($after.verdict_history).Count, $refusalJournaled)
    if (-not $authorized -and $refusalJournaled) {
        Write-Pass 'capture: the human approval of an evidence-less crossing is REFUSED — no authorization written, and the refused verdict is journaled loudly for the re-prompt'
    }
    elseif ($authorized) {
        Write-Red 'capture: the prompt-submit capture AUTHORIZED an evidence-less crossing from a pre-rendered marker + human approval — the stale packet defeated FR-068 before any refusal could compose'
    }
    else {
        Write-Red 'capture: authorization was withheld but the refused verdict was NOT journaled — a silent drop is a lost human verdict, not a refusal'
    }

    # -----------------------------------------------------------------------------------------
    # CONTAINMENT — the evidence gate's feature resolution must refuse prefix and case-distinct
    # siblings via canonical relative containment.
    # -----------------------------------------------------------------------------------------
    $rootProj = Join-Path $scratch 'repo'
    $rootFeature = Join-Path $rootProj 'specs\050-host-neutral-gate'
    $rootIter = Join-Path $rootFeature 'iterations\001'
    New-Item -ItemType Directory -Path $rootIter -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $rootFeature 'spec.md') -Value "# Spec`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $rootIter 'review.md') -Value "# Review`n`nBody." -Encoding UTF8
    $campaignRun = Join-Path $rootProj '.specrew\review\authority\campaigns\cmp-050-host-neutral-gate-i001\runs\run-valid-control'
    New-Item -ItemType Directory -Path $campaignRun -Force | Out-Null
    [System.IO.File]::WriteAllText(
        (Join-Path $campaignRun 'result.json'),
        '{"schema_version":"1.0","campaign_id":"cmp-050-host-neutral-gate-i001","run_id":"run-valid-control","completion":"complete","validation":"valid","verdict":"clean"}',
        [System.Text.UTF8Encoding]::new($false)
    )
    $null = & git -C $rootProj init --quiet
    $null = & git -C $rootProj config core.autocrlf false
    $null = & git -C $rootProj add -A
    $null = & git -C $rootProj -c user.name=Fixture -c user.email=f@x.invalid commit --quiet -m 'baseline'
    $rootTree = (@(& git -C $rootProj rev-parse 'HEAD^{tree}') | Select-Object -First 1).Trim()

    function Invoke-EvidenceProbe {
        param([string]$FeaturePath)
        $probe = Join-Path $scratch ('probe-' + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.ps1')
        [System.IO.File]::WriteAllText($probe, @"
`$ErrorActionPreference = 'Stop'
. '$($repoRoot -replace "'", "''")\extensions\specrew-speckit\scripts\shared-governance.ps1'
`$r = Get-SpecrewBoundaryStageEvidence -ProjectRoot '$rootProj' -Boundary 'review-signoff' -FeaturePath '$FeaturePath' -IterationNumber '001' -ArtifactStateId '$rootTree'
'satisfied=' + [bool]`$r.Satisfied + ' checked=' + [bool]`$r.Checked + ' unverifiable=' + [bool]`$r.Unverifiable
"@, [System.Text.UTF8Encoding]::new($false))
        return (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $probe 2>&1) -join ' ').Trim()
    }

    # In-project control: the genuine feature path must stay verifiable (the fix must not refuse
    # the legitimate shape).
    $ctrl = Invoke-EvidenceProbe -FeaturePath $rootFeature
    Write-Measured ("containment control (in-project): {0}" -f $ctrl)
    if ($ctrl -notmatch 'satisfied=True') {
        Write-Inconclusive 'the in-project control does not verify — the probes below cannot be read'
    }

    # Prefix sibling: <root>-other must be UNVERIFIABLE (not resolvable inside this project).
    $prefixSibling = ($rootProj + '-other')
    New-Item -ItemType Directory -Path (Join-Path $prefixSibling 'specs\050-host-neutral-gate') -Force | Out-Null
    $prefixOut = Invoke-EvidenceProbe -FeaturePath (Join-Path $prefixSibling 'specs\050-host-neutral-gate')
    Write-Measured ("containment prefix-sibling: {0}" -f $prefixOut)
    if ($prefixOut -match 'unverifiable=True') {
        Write-Pass 'containment: a prefix sibling (repo-other vs repo) is refused — the feature cannot be resolved inside this project'
    }
    else {
        Write-Red ("containment: a prefix sibling is accepted as in-project ({0}) — no separator boundary on the containment check" -f $prefixOut)
    }

    # Case-distinct sibling: only constructible on a case-sensitive volume; on case-insensitive
    # volumes the two names are one directory and the leg is recorded, not skipped silently.
    $caseName = Join-Path (Split-Path $rootProj -Parent) 'REPO'
    $caseDistinct = $false
    try {
        New-Item -ItemType Directory -Path $caseName -Force | Out-Null
        $caseDistinct = -not (Test-Path -LiteralPath (Join-Path $caseName 'specs'))
    }
    catch { $caseDistinct = $false }
    if ($caseDistinct) {
        New-Item -ItemType Directory -Path (Join-Path $caseName 'specs\050-host-neutral-gate') -Force | Out-Null
        $caseOut = Invoke-EvidenceProbe -FeaturePath (Join-Path $caseName 'specs\050-host-neutral-gate')
        Write-Measured ("containment case-distinct sibling: {0}" -f $caseOut)
        if ($caseOut -match 'unverifiable=True') {
            Write-Pass 'containment: a case-distinct sibling checkout is refused on this case-sensitive volume'
        }
        else {
            Write-Red ("containment: a case-distinct sibling checkout is accepted as in-project ({0})" -f $caseOut)
        }
    }
    else {
        Write-Measured 'containment case-distinct leg: this volume folds case (the sibling IS the project directory) — the leg is not constructible here and runs on the case-sensitive CI volume instead; recorded, not silently skipped'
    }
}
finally {
    if ($null -eq $savedModulePath) { Remove-Item Env:SPECREW_MODULE_PATH -ErrorAction SilentlyContinue }
    else { $env:SPECREW_MODULE_PATH = $savedModulePath }
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($script:Hard -gt 0) {
    Write-Host "=== pretag-slice4-capture-containment: $($script:Hard) INCONCLUSIVE ===" -ForegroundColor Magenta
    exit 2
}
if ($script:Red -gt 0) {
    Write-Host "=== pretag-slice4-capture-containment: $($script:Red) RED assertion(s) ===" -ForegroundColor Yellow
    exit 1
}
Write-Host '=== pretag-slice4-capture-containment: capture refuses evidence-less authorization; containment holds a separator boundary ===' -ForegroundColor Green
exit 0
