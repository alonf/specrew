$ErrorActionPreference = 'Stop'

# DRIFT-198-I011-012 — ORCHESTRATION-PATH REACHABILITY: the shipped skill ordering gates BEFORE it
# syncs, so FR-066's delivered arrival-state code is unreachable at the exact moment it exists for.
#
# Found by the maintainer's pre-tag manual test on a fresh consumer project, NOT by any engine test.
#
# The mechanism, verified at source in
# extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md:
#   block 1, line 28 : Test-SpecrewBoundaryAuthorization  -> THROWS at a first boundary (no
#                      authorization can exist yet), aborting the skill
#   block 2, line 40 : sync-boundary-state.ps1            -> the arrival sync, never reached
# so no crossing is recorded, no pending-verdict-stop.md is written, and the gate-stop skill's
# no-artifact fallback then instructs the agent to INVENT a marker (observed: `specify -> specify`,
# July's F1 signature).
#
# WHY EVERY ENGINE TEST MISSED IT, and why this harness is shaped differently: the existing suites
# invoke the sync FUNCTION directly. That proves the engine records an arrival correctly — and it does.
# It cannot prove the shipped ORCHESTRATION ever calls it. **The tested path was not the shipped path.**
# This harness therefore executes the skill's OWN powershell blocks, in the order the skill states them,
# against a real project — the orchestration is the subject under test, not the engine.
#
# This is the third instance of the reachability class (T089's unreachable branch; finding 2's
# three-mint-site funnel; this). Orchestration-path fixtures are the structural cure and belong in the
# release gate — see the beta3 row.
#
# Run standalone:
#   pwsh -NoProfile -File tests/integration/shipped-orchestration-arrival.tests.ps1

$script:Red = 0
$script:Hard = 0
function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Red { param([string]$m) Write-Host "RED: $m" -ForegroundColor Yellow; $script:Red++ }
function Write-Measured { param([string]$m) Write-Host "MEASURED: $m" -ForegroundColor Cyan }
function Write-Inconclusive { param([string]$m) Write-Host "INCONCLUSIVE (fixture defect, NOT a pass): $m" -ForegroundColor Magenta; $script:Hard++ }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$skillDoc = Join-Path $repoRoot 'extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-specify.md'

if (-not (Test-Path -LiteralPath $skillDoc -PathType Leaf)) {
    Write-Inconclusive "the shipped sync-specify skill was not found at $skillDoc"
    exit 2
}

# ---------------------------------------------------------------------------------------------
# The ORDERING assertion, read from the shipped skill itself rather than from a copy of it here.
# ---------------------------------------------------------------------------------------------
$lines = @(Get-Content -LiteralPath $skillDoc)
$gateLine = -1; $syncLine = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($gateLine -lt 0 -and $lines[$i] -match 'Test-SpecrewBoundaryAuthorization') { $gateLine = $i + 1 }
    if ($syncLine -lt 0 -and $lines[$i] -match 'sync-boundary-state\.ps1') { $syncLine = $i + 1 }
}
Write-Measured ("shipped skill: authorization gate at line {0}; arrival sync at line {1}" -f $gateLine, $syncLine)

if ($gateLine -lt 0 -or $syncLine -lt 0) {
    Write-Inconclusive 'could not locate both the authorization gate and the arrival sync in the shipped skill — the ordering cannot be measured'
}
elseif ($gateLine -lt $syncLine) {
    Write-Red ("the shipped skill GATES BEFORE IT SYNCS (gate line {0} precedes sync line {1}). At a first boundary Test-SpecrewBoundaryAuthorization throws — no authorization can exist yet — so the arrival sync never runs, no crossing is recorded, and FR-066's arrival state is unreachable through the shipped path" -f $gateLine, $syncLine)
}
else {
    Write-Pass 'the shipped skill records the arrival BEFORE the authorization gate — the gate blocks advancement, not arrival'
}

# ---------------------------------------------------------------------------------------------
# The BEHAVIOURAL assertion: execute the skill's own first block against a fresh project and observe
# whether it aborts before the arrival sync could ever run.
# ---------------------------------------------------------------------------------------------
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("shiporch-" + [guid]::NewGuid().ToString('N'))
$proj = Join-Path $scratch 'p'
New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
try {
    # A fresh project at its FIRST boundary: enforcement bootstrapped, nothing authorized yet.
    $ctx = [ordered]@{
        schema               = 'v2'
        feature_path         = (Join-Path $proj 'specs\050-host-neutral-gate')
        session_state        = [ordered]@{ active = $true; boundary_type = 'specify'; feature_ref = '050-host-neutral-gate'; iteration_number = ''; recorded_at = '2026-08-08T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = $null; pending_next_boundary = $null; pending_crossing = $null; verdict_history = @(); correction_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))

    $probe = Join-Path $scratch 'probe.ps1'
    $body = @"
`$ErrorActionPreference = 'Stop'
. '$repoRoot/extensions/specrew-speckit/scripts/shared-governance.ps1'
try {
    # 'intake' is the canonical pre-specify position. Passing '' bound-failed and produced a FALSE
    # RED — a probe defect masquerading as the product refusing.
    `$a = Test-SpecrewBoundaryAuthorization -ProjectRoot '$proj' -CurrentBoundary 'intake' -RequestedBoundary 'specify'
    'GATE_RESULT authorized=' + [bool]`$a.Authorized
}
catch { 'GATE_THREW ' + (`$_.Exception.Message -replace '\s+',' ') }
"@
    [System.IO.File]::WriteAllText($probe, $body, [System.Text.UTF8Encoding]::new($false))
    $gateOut = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $probe 2>&1) -join ' ').Trim()
    Write-Measured ("first-boundary gate outcome: {0}" -f $gateOut.Substring(0, [Math]::Min(180, $gateOut.Length)))

    $artifact = Join-Path $proj '.specrew\runtime\pending-verdict-stop.md'
    $artifactExists = Test-Path -LiteralPath $artifact -PathType Leaf
    Write-Measured ("pending-verdict-stop.md written by the shipped ordering: {0}" -f $artifactExists)

    if ($gateOut -match 'GATE_THREW' -or $gateOut -match 'authorized=False') {
        Write-Red 'the authorization gate refuses at a first boundary, and it runs BEFORE the arrival sync — so no pending crossing is recorded and no pending-verdict-stop.md exists for the gate-stop skill to read'
    }
    elseif (-not $artifactExists) {
        Write-Red 'the gate passed but no pending-verdict-stop.md was produced through the shipped ordering'
    }
    else {
        Write-Pass 'the shipped ordering produces the arrival artifact at a first boundary'
    }
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($script:Hard -gt 0) {
    Write-Host "=== shipped-orchestration-arrival: $($script:Hard) INCONCLUSIVE ===" -ForegroundColor Magenta
    exit 2
}
if ($script:Red -gt 0) {
    Write-Host "=== shipped-orchestration-arrival: $($script:Red) RED assertion(s) ===" -ForegroundColor Yellow
    exit 1
}
Write-Host '=== shipped-orchestration-arrival: the shipped path records arrival before gating ===' -ForegroundColor Green
exit 0
