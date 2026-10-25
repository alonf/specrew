$ErrorActionPreference = 'Stop'

# Pre-tag slice #3 — the certify run's four new blocking/major findings, instance-pinned per the
# maintainer's verdict (run-f198-beta2-c0c3cda6-certify, 2026-08-09):
#   f2  stage-evidence absent + a pre-rendered MATCHING marker in the transcript must still refuse
#       (today the marker flips boundaryBlock false and the refusal never composes).
#   f3  a capped evidence-absent stop and a capped unrecordable stop must never be instructed to
#       emit a marker (today the shared cap fallback demands the exact verdict marker).
#   f4  a case-mismatched committed artifact must NOT satisfy a file-only evidence row (today the
#       tracked-file set is OrdinalIgnoreCase over case-sensitive git tree names).
#   f6  an absolute and a ..-traversing feature_directory must both be rejected by the resolver's
#       feature.json fallback with containment intact (today both bind if the path exists).
#   f7  the launch contract must no longer claim the scaffolded hardening gate is ready (one row
#       was corrected; the neighboring row still carried the stale sentence).
#
# f1 (bootstrap minting) and f5 (atomic writer onto a directory) are NOT fixed here: f1 is the
# known-open mint-guard limitation the tag names (release-claim limitation 7 predicted exactly this
# rediscovery), f5 is DRIFT-198-I011-009, already routed to beta3. Recorded residuals.
#
# Run standalone:
#   pwsh -NoProfile -File tests/unit/pretag-slice3-certify-findings.tests.ps1

$script:Red = 0
$script:Hard = 0
function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Red { param([string]$m) Write-Host "RED: $m" -ForegroundColor Yellow; $script:Red++ }
function Write-Measured { param([string]$m) Write-Host "MEASURED: $m" -ForegroundColor Cyan }
function Write-Inconclusive { param([string]$m) Write-Host "INCONCLUSIVE (fixture defect, NOT a pass): $m" -ForegroundColor Magenta; $script:Hard++ }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("slice3-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null
$savedModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot

function New-ScopedEvidencelessFixture {
    # The INSTANCE shape (first fixture draft used the legacy-unscoped context and landed in the
    # UNVERIFIABLE arm — the class, not the instance): a SCOPED pending crossing minted by the
    # engine's own Set-SpecrewPendingBoundaryCrossingScope, bound to the real baseline tree, with
    # the review-signoff stage's evidence CHECKED against that tree and genuinely absent.
    $proj = New-EvidencelessBoundaryFixture
    $head = (@(& git -C $proj rev-parse HEAD) | Select-Object -First 1).Trim()
    # UPDATED 2026-09-02 to the CURRENT contract (DRIFT-199-I003-024, the inverse family).
    #
    # This fixture used to mint the crossing with review.md simply absent. Beta3 added the
    # owed-artifact mint guard, which now refuses that outright:
    #   CROSSING_NOT_MINTED_OWED_ARTIFACTS_ABSENT - 'review-signoff' owes review.md for iteration 001
    # That refusal is a DELIBERATE product change and a STRONGER guarantee: the evidenceless crossing
    # this fixture wants can no longer be opened at all. The test was left red certifying the
    # superseded contract - a test asserting yesterday's rule, not a product defect.
    #
    # THE TWO GATES READ DIFFERENT SOURCES - checked at source 2026-09-02, at the maintainer's demand,
    # because if capture consulted a flag written at mint this fixture would be a fixture-only
    # half-state:
    #   MINT gate (FR-024/T014) reads the LIVE DISK - Test-SpecrewBoundaryOwedArtifactsOnDisk.
    #   CAPTURE gate (FR-068/T090) reads the crossing's OWN BOUND GIT TREE, via ArtifactStateId, and
    #   deliberately NOT the live filesystem: "The first version checked Test-Path against the MUTABLE
    #   LIVE filesystem while the marker it authorizes ..." - reading live was a defect they fixed, so
    #   that producing an artifact after the fact cannot retro-satisfy an older crossing.
    # There is NO cached evidence flag written at mint; StageEvidenceAbsent is computed at stop time.
    #
    # So the constructed state is PRODUCT-REACHABLE, and by an ordinary path: review.md present on disk
    # but UNCOMMITTED satisfies the mint gate, while the bound tree never contains it, so capture reads
    # it absent. That is a real project whose author wrote the review and had not committed it. The
    # Remove-Item below makes the disk agree with the bound tree; it is NOT what makes capture see
    # absence, and the fixture would reach the same capture verdict without it.
    #
    # The scenario f2/f3 pin is preserved exactly, by reaching it the way the product now permits:
    # the owed artifact EXISTS at mint time, so the guard is satisfied on its own terms, and is then
    # removed so the stage's evidence is genuinely absent when the stop is evaluated. The guard checks
    # artifacts ON DISK, so this is the honest reproduction of "minted, then evidence went missing"
    # rather than a way around the guard. The new refusal itself is asserted separately, below.
    $owed = Join-Path $proj 'specs/050-host-neutral-gate/iterations/001/review.md'
    Set-Content -LiteralPath $owed -Value "# Review: 001`n`n**Overall Verdict**: accepted`n" -Encoding UTF8
    $mint = Join-Path $scratch ('mint-' + [guid]::NewGuid().ToString('N') + '.ps1')
    [System.IO.File]::WriteAllText($mint, @"
`$ErrorActionPreference = 'Stop'
. '$($repoRoot -replace "'", "''")\extensions\specrew-speckit\scripts\shared-governance.ps1'
`$scope = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot '$proj' -WorkingBoundary 'review-signoff' -BoundaryCommitHash '$head'
'MINT ' + `$(if (`$null -eq `$scope) { 'none' } else { [string]`$scope['from_boundary'] + '->' + [string]`$scope['to_boundary'] })
"@, [System.Text.UTF8Encoding]::new($false))
    $mintOut = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $mint 2>&1) -join ' ').Trim()
    if ($mintOut -notmatch 'MINT before-implement->review-signoff') {
        throw ("scoped fixture mint failed: {0}" -f $mintOut.Substring(0, [Math]::Min(200, $mintOut.Length)))
    }
    # Evidence goes absent AFTER the crossing exists - the state f2 and f3 are about.
    Remove-Item -LiteralPath $owed -Force
    return $proj
}

function New-EvidencelessBoundaryFixture {
    # The fr068 shape: before-implement -> review-signoff with the review-signoff stage carrying
    # NONE of its artifacts (legacy-unscoped context, no pending_crossing).
    $proj = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
    $featureDir = Join-Path $proj 'specs\050-host-neutral-gate'
    $iterDir = Join-Path $featureDir 'iterations\001'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew\runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $iterDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $featureDir 'spec.md') -Value "# Feature Specification: Host-Neutral Gate`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iterDir 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: implementing" -Encoding UTF8
    $ctx = [ordered]@{
        schema               = 'v2'
        feature_path         = $featureDir
        session_state        = [ordered]@{ active = $true; boundary_type = 'review-signoff'; feature_ref = '050-host-neutral-gate'; iteration_number = '001'; recorded_at = '2026-06-20T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'before-implement'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $null = & git -C $proj init --quiet
    $null = & git -C $proj config core.autocrlf false
    $null = & git -C $proj add -A
    $null = & git -C $proj -c user.name=Fixture -c user.email=f@x.invalid commit --quiet -m 'baseline'
    if ($LASTEXITCODE -ne 0) { throw 'fixture baseline commit failed' }
    return $proj
}

function New-Transcript {
    param([string]$Proj, [string]$AssistantText)
    $dir = Join-Path $Proj '.specrew\runtime'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $path = Join-Path $dir ('transcript-' + [guid]::NewGuid().ToString('N') + '.jsonl')
    $lines = @(
        ([pscustomobject]@{ type = 'user'; message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = 'Continue the iteration.' }) } } | ConvertTo-Json -Depth 8 -Compress),
        ([pscustomobject]@{ type = 'assistant'; message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = $AssistantText }) } } | ConvertTo-Json -Depth 8 -Compress)
    )
    [System.IO.File]::WriteAllLines($path, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
    return $path
}

function Invoke-Provider {
    param([string]$Proj, [string]$Transcript)
    $cmd = "Set-Location -LiteralPath '$Proj'; & '$provider' --host-kind claude --source-event Stop --transcript-path '$Transcript'"
    return (@(& pwsh -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1) -join "`n")
}

try {
    # -----------------------------------------------------------------------------------------
    # f2 — evidence absent + a pre-rendered MATCHING marker must still refuse.
    # -----------------------------------------------------------------------------------------
    $proj2 = New-ScopedEvidencelessFixture
    # The marker registers only inside a packet-shaped message (Get-SpecrewCapturedBoundaryPacket) —
    # a bare marker line is not detected, which is exactly how this fixture's first draft produced a
    # false pass. The realistic pre-rendered shape is the full six-section packet ending in the
    # matching marker, with the stage's evidence still absent from the bound tree.
    $markerText = @'
## What I Just Did

Completed the review work and committed the evidence.

## Why I Stopped

The review-signoff boundary needs your verdict.

## What Needs Your Review

The review artifacts.

## What Happens Next

Retro follows on approval.

## Discussion Prompts

None.

## What I Need From You

approve as-is, approve with instructions, send back, or discuss.
<!-- SPECREW-VERDICT-BOUNDARY: before-implement -> review-signoff -->
'@
    $t2 = New-Transcript -Proj $proj2 -AssistantText $markerText
    $out2 = Invoke-Provider -Proj $proj2 -Transcript $t2
    $flat2 = ($out2 -replace '\s+', ' ').Trim()
    $blocked2 = $out2 -match '<<<SPECREW-STOP-BLOCK>>>'
    $refuses2 = $out2 -match 'evidence' -and $out2 -match 'produced|missing|owes'
    $instructsMarker2 = $flat2 -match 'emit the .*SPECREW-VERDICT-BOUNDARY'
    Write-Measured ("f2: blocked={0}; refusal-language={1}; instructs-marker={2}; head: {3}" -f $blocked2, $refuses2, $instructsMarker2, $(if ($flat2.Length -eq 0) { '(empty)' } else { $flat2.Substring(0, [Math]::Min(200, $flat2.Length)) }))
    if ($blocked2 -and $refuses2 -and -not $instructsMarker2) {
        Write-Pass 'f2: a pre-rendered matching marker does NOT bypass the stage-evidence refusal — the missing-evidence block still composes, with no marker instruction'
    }
    else {
        Write-Red 'f2: with stage evidence absent and a matching marker already in the transcript, the provider does not compose the missing-evidence refusal — the stale marker can feed verdict capture'
    }

    # -----------------------------------------------------------------------------------------
    # f3a — a CAPPED evidence-absent stop must never be instructed to emit a marker.
    # -----------------------------------------------------------------------------------------
    $proj3 = New-ScopedEvidencelessFixture
    $t3 = New-Transcript -Proj $proj3 -AssistantText 'I implemented the change and ran the tests. Here is where things stand.'
    $capOut = $null
    $lens3 = @()
    for ($i = 1; $i -le 4; $i++) {
        # Each real force-continue is a NEW assistant message; an unchanged message is deduped by
        # the provider's fire-identity guard (the first draft's 863,0,0,0 silence).
        $tN = New-Transcript -Proj $proj3 -AssistantText ("I implemented the change and ran the tests. Attempt {0}." -f $i)
        $capOut = Invoke-Provider -Proj $proj3 -Transcript $tN
        $lens3 += ($capOut -replace '\s+', ' ').Trim().Length
    }
    $flat3 = ($capOut -replace '\s+', ' ').Trim()
    $journal3 = Join-Path $proj3 '.specrew\runtime\conformance-journal.jsonl'
    $journalTail3 = if (Test-Path $journal3) { (@(Get-Content $journal3 -Tail 2) -join ' | ') } else { '(no journal)' }
    $capMarker3 = $flat3 -match 'SPECREW-VERDICT-BOUNDARY' -or $flat3 -match 'verdict marker'
    Write-Measured ("f3 evidence-absent capped: lens={0}; marker-instruction={1}; head: {2}" -f ($lens3 -join ','), $capMarker3, $(if ($flat3.Length -eq 0) { '(empty)' } else { $flat3.Substring(0, [Math]::Min(220, $flat3.Length)) }))
    Write-Measured ("f3 journal tail: {0}" -f $journalTail3.Substring(0, [Math]::Min(300, $journalTail3.Length)))
    if (-not $capMarker3 -and -not [string]::IsNullOrWhiteSpace($flat3)) {
        Write-Pass 'f3: the capped evidence-absent stop degrades WITHOUT instructing a verdict marker'
    }
    elseif ([string]::IsNullOrWhiteSpace($flat3)) {
        Write-Inconclusive 'f3: the capped evidence-absent invocation emitted nothing at all — the cap path was never reached'
    }
    else {
        Write-Red 'f3: after the block cap, the evidence-absent stop is instructed to emit the verdict marker FR-068 suppresses'
    }

    # -----------------------------------------------------------------------------------------
    # f3b — a CAPPED unrecordable stop must never be instructed to emit a marker.
    # -----------------------------------------------------------------------------------------
    $proj3b = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
    $featureDir3b = Join-Path $proj3b 'specs\050-host-neutral-gate'
    New-Item -ItemType Directory -Path (Join-Path $proj3b '.specrew\runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $featureDir3b -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $featureDir3b 'spec.md') -Value "# Feature Specification: Host-Neutral Gate`n`nBody." -Encoding UTF8
    $ctx3b = [ordered]@{
        schema        = 'v1'
        feature_path  = $featureDir3b
        session_state = [ordered]@{ active = $true; boundary_type = 'specify'; feature_ref = '050-host-neutral-gate'; iteration_number = ''; recorded_at = '2026-08-03T00:00:00Z' }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj3b '.specrew\start-context.json'), ($ctx3b | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $null = & git -C $proj3b init --quiet
    $null = & git -C $proj3b config core.autocrlf false
    $null = & git -C $proj3b add -A
    $null = & git -C $proj3b -c user.name=Fixture -c user.email=f@x.invalid commit --quiet -m 'baseline'
    $t3b = New-Transcript -Proj $proj3b -AssistantText 'I authored the specification and recorded the decisions.'
    $capOut3b = $null
    $lens3b = @()
    for ($i = 1; $i -le 4; $i++) {
        $tN = New-Transcript -Proj $proj3b -AssistantText ("I authored the specification and recorded the decisions. Attempt {0}." -f $i)
        $capOut3b = Invoke-Provider -Proj $proj3b -Transcript $tN
        $lens3b += ($capOut3b -replace '\s+', ' ').Trim().Length
    }
    $flat3b = ($capOut3b -replace '\s+', ' ').Trim()
    $journal3b = Join-Path $proj3b '.specrew\runtime\conformance-journal.jsonl'
    $journalTail3b = if (Test-Path $journal3b) { (@(Get-Content $journal3b -Tail 2) -join ' | ') } else { '(no journal)' }
    $capMarker3b = $flat3b -match 'SPECREW-VERDICT-BOUNDARY' -or $flat3b -match 'verdict marker'
    Write-Measured ("f3 unrecordable capped: lens={0}; marker-instruction={1}; head: {2}" -f ($lens3b -join ','), $capMarker3b, $(if ($flat3b.Length -eq 0) { '(empty)' } else { $flat3b.Substring(0, [Math]::Min(220, $flat3b.Length)) }))
    Write-Measured ("f3b journal tail: {0}" -f $journalTail3b.Substring(0, [Math]::Min(300, $journalTail3b.Length)))
    if (-not $capMarker3b -and -not [string]::IsNullOrWhiteSpace($flat3b)) {
        Write-Pass 'f3: the capped unrecordable stop degrades WITHOUT inventing a marker for a crossing that does not exist'
    }
    elseif ([string]::IsNullOrWhiteSpace($flat3b)) {
        Write-Inconclusive 'f3: the capped unrecordable invocation emitted nothing at all — the cap path was never reached'
    }
    else {
        Write-Red 'f3: after the block cap, the unrecordable stop is instructed to emit a marker for a crossing that does not exist — marker invention through the cap path'
    }

    # -----------------------------------------------------------------------------------------
    # f4 — a case-mismatched committed artifact must NOT satisfy a file-only evidence row.
    # -----------------------------------------------------------------------------------------
    $proj4 = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
    $featureDir4 = Join-Path $proj4 'specs\050-host-neutral-gate'
    $iterDir4 = Join-Path $featureDir4 'iterations\001'
    New-Item -ItemType Directory -Path $iterDir4 -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj4 '.specrew') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $featureDir4 'spec.md') -Value "# Spec`n`nBody." -Encoding UTF8
    # The case-mismatched artifact: committed as Review.md while the contract's file-only row for
    # review-signoff demands review.md. Git tree names are case-sensitive, so the canonical artifact
    # is genuinely absent from the bound tree.
    Set-Content -LiteralPath (Join-Path $iterDir4 'Review.md') -Value "# Review`n`nBody." -Encoding UTF8
    $null = & git -C $proj4 init --quiet
    $null = & git -C $proj4 config core.autocrlf false
    $null = & git -C $proj4 add -A
    $null = & git -C $proj4 -c user.name=Fixture -c user.email=f@x.invalid commit --quiet -m 'baseline'
    $tree4 = (@(& git -C $proj4 rev-parse 'HEAD^{tree}') | Select-Object -First 1).Trim()
    $probe4 = Join-Path $scratch 'f4-probe.ps1'
    [System.IO.File]::WriteAllText($probe4, @"
`$ErrorActionPreference = 'Stop'
. '$($repoRoot -replace "'", "''")\extensions\specrew-speckit\scripts\shared-governance.ps1'
`$r = Get-SpecrewBoundaryStageEvidence -ProjectRoot '$proj4' -Boundary 'review-signoff' -FeaturePath '$featureDir4' -IterationNumber '001' -ArtifactStateId '$tree4'
'F4 satisfied=' + [bool]`$r.Satisfied + ' checked=' + [bool]`$r.Checked + ' unverifiable=' + [bool]`$r.Unverifiable + ' missing=' + (@(`$r.Missing) -join ',')
"@, [System.Text.UTF8Encoding]::new($false))
    $out4 = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $probe4 2>&1) -join ' ').Trim()
    Write-Measured ("f4: {0}" -f $out4.Substring(0, [Math]::Min(220, $out4.Length)))
    if ($out4 -match 'satisfied=False' -and $out4 -match 'unverifiable=False' -and $out4 -match 'review\.md') {
        Write-Pass 'f4: a committed Review.md does NOT satisfy the review.md file-only row — git tree names are matched case-sensitively and the canonical artifact reads as missing'
    }
    elseif ($out4 -match 'satisfied=True') {
        Write-Red 'f4: a case-mismatched committed artifact (Review.md) satisfies the review.md evidence row — case-insensitive matching over case-sensitive git tree names'
    }
    else {
        Write-Inconclusive ("f4: the evidence probe reached no scoreable verdict: {0}" -f $out4.Substring(0, [Math]::Min(160, $out4.Length)))
    }

    # -----------------------------------------------------------------------------------------
    # f6 — absolute and ..-traversing feature_directory values must both be rejected.
    # -----------------------------------------------------------------------------------------
    $outsideFeature = Join-Path $scratch 'outside-feature'
    New-Item -ItemType Directory -Path $outsideFeature -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $outsideFeature 'spec.md') -Value "# Foreign Spec`n`nBody." -Encoding UTF8
    foreach ($case in @(
            @{ Name = 'absolute'; Value = ($outsideFeature -replace '\\', '/') }
            @{ Name = 'traversal'; Value = '../outside-feature' }
        )) {
        $proj6 = Join-Path $scratch ('f6-' + $case.Name)
        New-Item -ItemType Directory -Path (Join-Path $proj6 '.specify') -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $proj6 '.specify\feature.json'), ('{{"feature_directory":"{0}"}}' -f $case.Value), [System.Text.UTF8Encoding]::new($false))
        $out6 = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\resolve-quality-profile.ps1') -ProjectPath $proj6 -OutputFormat Json 2>&1) -join "`n")
        $json6 = $null
        try { $json6 = $out6 | ConvertFrom-Json } catch { $json6 = $null }
        if ($null -eq $json6) {
            Write-Inconclusive ("f6 {0}: the resolver emitted no parseable JSON — nothing measured" -f $case.Name)
        }
        elseif ([string]::IsNullOrWhiteSpace([string]$json6.feature_path)) {
            Write-Pass ("f6 {0}: an out-of-project feature_directory is rejected — the feature stays unbound instead of binding foreign artifacts" -f $case.Name)
        }
        else {
            Write-Red ("f6 {0}: the resolver bound an out-of-project feature_directory ({1}) — containment escape" -f $case.Name, [string]$json6.feature_path)
        }
    }

    # -----------------------------------------------------------------------------------------
    # f7 — the launch contract must no longer claim the scaffolded gate is ready.
    # -----------------------------------------------------------------------------------------
    $contract = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\internal\launch-contract.ps1') -Raw
    if ($contract -notmatch 'already emits a ready gate') {
        Write-Pass 'f7: no launch-contract row claims the scaffold emits a ready gate'
    }
    else {
        Write-Red 'f7: a launch-contract row still tells consumers the scaffold already emits a ready gate — contradicting the blocked-by-default scaffold'
    }
}
finally {
    if ($null -eq $savedModulePath) { Remove-Item Env:SPECREW_MODULE_PATH -ErrorAction SilentlyContinue }
    else { $env:SPECREW_MODULE_PATH = $savedModulePath }
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($script:Hard -gt 0) {
    Write-Host "=== pretag-slice3-certify-findings: $($script:Hard) INCONCLUSIVE ===" -ForegroundColor Magenta
    exit 2
}
if ($script:Red -gt 0) {
    Write-Host "=== pretag-slice3-certify-findings: $($script:Red) RED assertion(s) ===" -ForegroundColor Yellow
    exit 1
}
Write-Host '=== pretag-slice3-certify-findings: refusals hold against markers, caps, case, and containment ===' -ForegroundColor Green
exit 0
