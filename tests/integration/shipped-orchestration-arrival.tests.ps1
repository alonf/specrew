$ErrorActionPreference = 'Stop'

# DRIFT-198-I011-012 — ORCHESTRATION-PATH REACHABILITY: the shipped skill ordering gates BEFORE it
# syncs, so FR-066's delivered arrival-state code is unreachable at the exact moment it exists for.
#
# Found by the maintainer's pre-tag manual test on a fresh consumer project, NOT by any engine test.
#
# The mechanism, verified at source in
# extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md:
#   block 1 : Test-SpecrewBoundaryAuthorization RETURNS Authorized=false at a first boundary (no
#             authorization can exist yet, and the matcher cannot represent the first crossing);
#             the skill's OWN next line — `throw $authorization.Reason` — aborts the skill.
#             (An earlier revision of this header said the gate "THROWS"; the gate returns, the
#             skill throws. The distinction matters: the abort is the shipped orchestration's text.)
#   block 2 : sync-boundary-state.ps1 — the arrival sync — is never reached.
# So no crossing is recorded, no pending-verdict-stop.md is written, and the gate-stop skill's
# no-artifact fallback then instructs the agent to INVENT a marker (observed: `specify -> specify`,
# July's F1 signature).
#
# PROBE HISTORY, kept because refused evidence is still evidence:
#   - `-CurrentBoundary ''`       -> parameter-binding failure. A probe defect, refused as a RED.
#   - `-CurrentBoundary 'intake'` -> canonical-vocabulary rejection inside the gate, NOT the
#                                    product's first-boundary refusal. Refused as a RED.
# Both REDs fired for the wrong reason. This revision executes the skill's OWN fenced powershell
# blocks, extracted from the shipped markdown at run time, in the order the skill states them,
# against a real bootstrapped consumer project — the orchestration is the subject under test, and
# the probe cannot drift from the shipped text because it IS the shipped text.
#
# The assertions below state the DESIRED first-arrival contract (FR-066 through the shipped path):
#   A. the arrival crossing is recorded (pending_crossing intake -> specify);
#   B. pending-verdict-stop.md exists and carries the intake -> specify marker;
#   C. advancement is REFUSED until the human's verdict (the gate blocking is correct — the defect
#      is only that it fires before arrival is recorded);
#   D. after the verdict entry the capture writer mints ({from: null, to: specify}) is recorded,
#      the gate AUTHORIZES — i.e. the first crossing is representable, not permanently blocked.
# A RED on any of these against a tree that claims FR-066 is a regression of this finding.
#
# This is the third instance of the reachability class (T089's unreachable branch; finding 2's
# three-mint-site funnel; this). Orchestration-path fixtures are the structural cure and belong in
# the release gate — see the beta3 row.
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
# 1. The ORDERING assertion, read from the shipped skill itself rather than from a copy of it here.
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
    Write-Red ("the shipped skill GATES BEFORE IT SYNCS (gate line {0} precedes sync line {1}): at a first boundary the gate refuses, the skill's own throw aborts it, the arrival sync never runs, and FR-066's arrival state is unreachable through the shipped path" -f $gateLine, $syncLine)
}
else {
    Write-Pass 'the shipped skill records the arrival BEFORE the advancement gate — the gate blocks advancement, not arrival'
}

# ---------------------------------------------------------------------------------------------
# 2. The BEHAVIOURAL assertions: execute the skill's own fenced blocks, in its stated order,
#    against a fresh BOOTSTRAPPED consumer project, and measure the first-arrival contract.
# ---------------------------------------------------------------------------------------------
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("shiporch-" + [guid]::NewGuid().ToString('N'))
$proj = Join-Path $scratch 'p'
$tools = Join-Path $scratch 'tools'
$savedModulePath = $env:SPECREW_MODULE_PATH
try {
    # -- Consumer-project scaffold (shape proven by the T087 harness: specs + spec.md,
    #    .squad/active-features.yml for the specify claim upsert, git baseline for crossing scopes).
    $featureDir = Join-Path $proj 'specs\050-host-neutral-gate'
    $deployedScripts = Join-Path $proj '.specify\extensions\specrew-speckit\scripts'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew\runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $deployedScripts -Force | Out-Null
    New-Item -ItemType Directory -Path $featureDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj '.squad') -Force | Out-Null
    New-Item -ItemType Directory -Path $tools -Force | Out-Null

    # The deployed governance surface the skill dot-sources, copied from the ENGINE UNDER TEST.
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1') `
        -Destination (Join-Path $deployedScripts 'shared-governance.ps1') -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\sync-boundary-state.ps1') `
        -Destination (Join-Path $deployedScripts 'sync-boundary-state.ps1') -Force
    # The wrapper resolves the internal engine via $env:SPECREW_MODULE_PATH (path 0) — point it at
    # THIS repo so the subject under test is the working tree, never an installed module.
    $env:SPECREW_MODULE_PATH = $repoRoot

    Set-Content -LiteralPath (Join-Path $proj '.squad\active-features.yml') -Value "claims: []`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir 'spec.md') `
        -Value "# Feature Specification: Host-Neutral Gate Enforcement`n`nThe authoritative contract." -Encoding UTF8

    # /speckit.specify outputs, pre-written so the skill's own gates can resolve the feature: the
    # workshop gate reads .specify/feature.json, and block 2 reads it for the FeatureRef.
    [System.IO.File]::WriteAllText((Join-Path $proj '.specify\feature.json'),
        ('{{"feature_directory":"{0}"}}' -f ($featureDir -replace '\\', '\\\\')), [System.Text.UTF8Encoding]::new($false))
    # Workshop records with per-lens human confirmation — the workshop gate demands them, and an
    # inadequate scaffold here must read as INCONCLUSIVE (probe defect), never as a RED.
    [System.IO.File]::WriteAllText((Join-Path $featureDir 'lens-applicability.json'),
        '{"schema":"v2","workshop_intake":true,"selected":["architecture-core"],"workshop":{"architecture-core":{"agenda":["q1"],"decision":"modular monolith","depth":"expert-terse","moved_on":true,"confirmation":"human-confirmed","confirmation_scope":"lens-question"}}}',
        [System.Text.UTF8Encoding]::new($false))

    # A fresh project at its FIRST boundary: session cursor blank (the skill's own fallback line is
    # part of the computation under test), nothing authorized yet.
    $ctx = [ordered]@{
        schema        = 'v2'
        feature_path  = $featureDir
        session_state = [ordered]@{ active = $true; boundary_type = ''; feature_ref = '050-host-neutral-gate'; iteration_number = ''; recorded_at = '2026-08-08T00:00:00Z' }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))

    # Bootstrap boundary enforcement with the ENGINE'S OWN initializer, not a hand-rolled shape —
    # a hand-written v2 block risks the malformed-state throw (the T087 false-pass class), which
    # would be a RED for the wrong reason.
    $bootstrap = Join-Path $tools 'bootstrap.ps1'
    [System.IO.File]::WriteAllText($bootstrap, @"
`$ErrorActionPreference = 'Stop'
. '$($deployedScripts -replace "'", "''")\shared-governance.ps1'
Initialize-SpecrewBoundaryEnforcementState -ProjectRoot '.' | Out-Null
'BOOTSTRAP_OK'
"@, [System.Text.UTF8Encoding]::new($false))
    Push-Location $proj
    try { $bootOut = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $bootstrap 2>&1) -join ' ') }
    finally { Pop-Location }
    $ctxAfterBoot = Get-Content -LiteralPath (Join-Path $proj '.specrew\start-context.json') -Raw | ConvertFrom-Json
    $be = $ctxAfterBoot.PSObject.Properties['boundary_enforcement']
    if ($bootOut -notmatch 'BOOTSTRAP_OK' -or $null -eq $be -or $null -eq $be.Value) {
        Write-Inconclusive ("boundary enforcement did not bootstrap — the probe cannot reach the ordering it measures. Output: {0}" -f $bootOut.Substring(0, [Math]::Min(200, $bootOut.Length)))
        exit 2
    }
    if (@($be.Value.verdict_history).Count -ne 0 -or $null -ne $be.Value.last_authorized_boundary) {
        Write-Inconclusive 'the bootstrapped enforcement state is not the first-arrival shape (history not empty or cursor set) — fixture defect'
        exit 2
    }

    $null = & git -C $proj init --quiet
    if ($LASTEXITCODE -ne 0) { Write-Inconclusive 'fixture git init failed'; exit 2 }
    $null = & git -C $proj config core.autocrlf false
    $null = & git -C $proj add -A
    $null = & git -C $proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m 'fixture baseline'
    if ($LASTEXITCODE -ne 0) { Write-Inconclusive 'fixture baseline commit failed'; exit 2 }

    # -- Extract the skill's fenced powershell blocks VERBATIM and execute them in stated order.
    $doc = Get-Content -LiteralPath $skillDoc -Raw
    $blockMatches = [regex]::Matches($doc, '(?ms)^```powershell\s*\r?\n(.*?)^```')
    if ($blockMatches.Count -lt 2) {
        Write-Inconclusive ("expected at least 2 fenced powershell blocks in the shipped skill; found {0} — the orchestration cannot be executed as shipped" -f $blockMatches.Count)
        exit 2
    }
    Write-Measured ("shipped skill carries {0} fenced powershell block(s); executing them in stated order" -f $blockMatches.Count)

    $abortedAtBlock = 0
    $runLog = New-Object System.Collections.Generic.List[string]
    for ($b = 0; $b -lt $blockMatches.Count; $b++) {
        $blockPath = Join-Path $tools ("block-{0}.ps1" -f ($b + 1))
        [System.IO.File]::WriteAllText($blockPath, $blockMatches[$b].Groups[1].Value, [System.Text.UTF8Encoding]::new($false))
        Push-Location $proj
        try { $out = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $blockPath 2>&1) -join "`n"); $code = $LASTEXITCODE }
        finally { Pop-Location }
        $runLog.Add(("block {0}: exit={1}; out: {2}" -f ($b + 1), $code, (($out -replace '\s+', ' ').Trim()))) | Out-Null
        if ($code -ne 0) { $abortedAtBlock = $b + 1; break }
    }
    $runText = ($runLog -join "`n")
    foreach ($entry in $runLog) { Write-Measured ($entry.Substring(0, [Math]::Min(260, $entry.Length))) }
    if ($abortedAtBlock -gt 0) { Write-Measured ("the shipped orchestration ABORTED at block {0} of {1}" -f $abortedAtBlock, $blockMatches.Count) }

    # -- A. The arrival crossing is recorded.
    $ctxAfterRun = Get-Content -LiteralPath (Join-Path $proj '.specrew\start-context.json') -Raw | ConvertFrom-Json
    $pendingCrossing = $null
    $beAfter = $ctxAfterRun.PSObject.Properties['boundary_enforcement']
    if ($null -ne $beAfter -and $null -ne $beAfter.Value) {
        $pcProp = $beAfter.Value.PSObject.Properties['pending_crossing']
        if ($null -ne $pcProp) { $pendingCrossing = $pcProp.Value }
    }
    if ($null -ne $pendingCrossing -and [string]$pendingCrossing.from_boundary -eq 'intake' -and [string]$pendingCrossing.to_boundary -eq 'specify') {
        Write-Pass 'the first-arrival crossing is recorded through the shipped path (pending_crossing intake -> specify)'
    }
    else {
        Write-Red ("no first-arrival crossing was recorded through the shipped path (pending_crossing: {0}) — the orchestration aborted before the arrival sync could run" -f $(if ($null -eq $pendingCrossing) { 'null' } else { ('{0} -> {1}' -f $pendingCrossing.from_boundary, $pendingCrossing.to_boundary) }))
    }

    # -- B. The pending-verdict stop artifact exists with the first-crossing marker.
    $artifact = Join-Path $proj '.specrew\runtime\pending-verdict-stop.md'
    $artifactExists = Test-Path -LiteralPath $artifact -PathType Leaf
    $artifactMarker = if ($artifactExists) { (Get-Content -LiteralPath $artifact -Raw) -match 'intake\s*->\s*specify' } else { $false }
    Write-Measured ("pending-verdict-stop.md written by the shipped ordering: {0}; carries intake -> specify: {1}" -f $artifactExists, $artifactMarker)
    if ($artifactExists -and $artifactMarker) {
        Write-Pass 'pending-verdict-stop.md exists with the intake -> specify marker — the gate-stop skill has controller truth to read'
    }
    else {
        Write-Red 'no pending-verdict-stop.md with the intake -> specify marker exists after the shipped orchestration — the gate-stop skill has NO controller truth, which is the marker-invention precondition (July F1)'
    }

    # -- C. Advancement is refused until the human's verdict (the correct half of today's behavior).
    if ($runText -match 'SPECREW_BOUNDARY_BLOCKED') {
        Write-Pass 'advancement past the first boundary is refused pending the human verdict'
    }
    else {
        Write-Red 'no advancement refusal fired at an unauthorized first boundary — the gate did not block'
    }

    # -- D. The crossing is REPRESENTABLE: after the verdict entry the shipped capture writer mints,
    #       the gate authorizes. The entry shape {from: null, to: specify} is byte-what
    #       Invoke-SpecrewBoundaryVerdictCapture passes (PendingFromBoundary=null,
    #       PendingToBoundary='specify' — Get-SpecrewPendingBoundaryCrossing's first-boundary
    #       contract), so this measures the GATE against recorded reality, not a synthetic shape.
    $verdictLeg = Join-Path $tools 'verdict-leg.ps1'
    [System.IO.File]::WriteAllText($verdictLeg, @"
`$ErrorActionPreference = 'Stop'
. '$($deployedScripts -replace "'", "''")\shared-governance.ps1'
`$state = Get-SpecrewBoundaryEnforcementState -ProjectRoot '.'
`$cursor = [string]`$state.EffectiveState['last_authorized_boundary']
`$pc = Get-SpecrewPendingBoundaryCrossing -LastAuthorizedBoundary `$cursor -WorkingBoundary 'specify'
'DETECTOR pending=' + [bool]`$pc.HasPendingVerdict + ' from=' + [string]`$pc.PendingFromBoundary + ' markerFrom=' + [string]`$pc.PendingFromMarkerBoundary + ' to=' + [string]`$pc.PendingToBoundary
Add-SpecrewBoundaryAuthorization -ProjectRoot '.' -CurrentBoundary `$pc.PendingFromBoundary -AuthorizedBoundary 'specify' ``
    -AuthorizingHuman 'maintainer' -VerdictText 'approved for specify' -EvidenceSource 'human-confirmed-at-resume' -OutOfBandReason 'fixture directly records the measured human verdict after the arrival stop' -Kind 'standard' | Out-Null
'ENTRY_WRITTEN'
`$gate = Test-SpecrewBoundaryAuthorization -ProjectRoot '.' -CurrentBoundary 'specify' -RequestedBoundary 'specify'
'GATE authorized=' + [bool]`$gate.Authorized + ' decision=' + [string]`$gate.Decision + ' reason=' + ([string]`$gate.Reason -replace '\s+', ' ')
"@, [System.Text.UTF8Encoding]::new($false))
    Push-Location $proj
    try { $legOut = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $verdictLeg 2>&1) -join "`n"); $legCode = $LASTEXITCODE }
    finally { Pop-Location }
    $legFlat = ($legOut -replace '\s+', ' ').Trim()
    Write-Measured ("verdict leg: exit={0}; {1}" -f $legCode, $legFlat.Substring(0, [Math]::Min(300, $legFlat.Length)))
    if ($legCode -ne 0 -or $legOut -notmatch 'ENTRY_WRITTEN') {
        Write-Inconclusive 'the verdict entry could not be written — the gate-representability leg never reached the gate'
    }
    elseif ($legOut -match 'GATE authorized=True') {
        Write-Pass 'the gate authorizes the first crossing once the capture-minted entry ({from: null, to: specify}) is recorded — the crossing is representable'
    }
    else {
        Write-Red 'the gate STAYS BLOCKED after the human verdict entry the capture writer mints — the first crossing is unrepresentable in the authorization gate, so the reorder alone cannot fix first arrival'
    }
}
finally {
    if ($null -eq $savedModulePath) { Remove-Item Env:SPECREW_MODULE_PATH -ErrorAction SilentlyContinue }
    else { $env:SPECREW_MODULE_PATH = $savedModulePath }
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
Write-Host '=== shipped-orchestration-arrival: the shipped path records arrival before gating, stops with controller truth, and authorizes after the verdict ===' -ForegroundColor Green
exit 0
