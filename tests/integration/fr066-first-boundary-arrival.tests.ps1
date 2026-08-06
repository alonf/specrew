$ErrorActionPreference = 'Stop'

# T087 — FR-066 RED fixtures (F-198 iteration 011).
#
# FR-066: on a project's FIRST arrival at a lifecycle boundary, boundary state MUST be synchronized
# and the boundary record established BEFORE the first boundary packet renders. A packet MUST NOT be
# the event that creates the boundary state it reports.
#
# The live hole, located during planning:
#
#   `Set-SpecrewPendingBoundaryCrossingScope` THROWS when boundary enforcement was never
#   bootstrapped (shared-governance.ps1: "Boundary enforcement state cannot accept a scoped
#   crossing"). Boundary sync catches that at sync-boundary-state.ps1:1660 and degrades to
#   `HasPendingVerdict = $false` behind a `Write-Warning` — a value INDISTINGUISHABLE from
#   "there is legitimately no pending verdict". Sync then reports success, no artifact is written,
#   and the conformance provider's else-branch still emits a boundary stop naming a boundary with
#   NO marker text. That is the Antigravity "headers but no marker" shape.
#
# These fixtures assert the CORRECTED behaviour and are expected to FAIL against HEAD until T088 and
# T089 land. A fixture that passes before the fix proves nothing.
#
# Carried practice, binding for this iteration (see plan.md):
#   INCONCLUSIVE is a third outcome. "No signal at all" is a FIXTURE defect, never a pass.
#
# Run standalone:
#   pwsh -NoProfile -File tests/integration/fr066-first-boundary-arrival.tests.ps1

$script:Red = 0
$script:Hard = 0
function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Red { param([string]$m) Write-Host "RED (expected until the fix lands): $m" -ForegroundColor Yellow; $script:Red++ }
function Write-Measured { param([string]$m) Write-Host "MEASURED: $m" -ForegroundColor Cyan }
function Write-Inconclusive { param([string]$m) Write-Host "INCONCLUSIVE (fixture defect, NOT a pass): $m" -ForegroundColor Magenta; $script:Hard++ }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$sync = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("fr066-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null

function New-UnbootstrappedProject {
    # $InitialBoundary = '' builds a project that has NOT yet reached any boundary, so the boundary
    # sync under test is the thing that ADVANCES it. CASE 4 needs that: the defect is about a boundary
    # sync persisted and then failed to back out of, which cannot be observed on a fixture whose
    # boundary was already on disk before sync ran.
    param([string]$InitialBoundary = 'specify')
    # A brand-new project that reached a boundary WITHOUT `specrew start` having written the
    # boundary_enforcement block. This is the first-arrival shape: a feature and a spec exist, a
    # session cursor exists, and there is no cursor baseline and no verdict history — because
    # nothing has ever bootstrapped them.
    $proj = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
    $featureDir = Join-Path $proj 'specs\050-host-neutral-gate'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew\runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $featureDir -Force | Out-Null
    # The specify boundary upserts a feature claim into .squad/active-features.yml; without the
    # directory the atomic write throws and the probe never reaches the crossing path. Found by the
    # INCONCLUSIVE guard, not by a false pass.
    New-Item -ItemType Directory -Path (Join-Path $proj '.squad') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $proj '.squad\active-features.yml') -Value "claims: []`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureDir 'spec.md') `
        -Value "# Feature Specification: Host-Neutral Gate Enforcement`n`nThe authoritative contract." -Encoding UTF8

    # The un-bootstrapped shape is SPECIFIC, and the first revision of this fixture got it wrong.
    # `NeedsMigration` is `Exists AND schema in (v0,v1) AND boundary_enforcement is null`
    # (shared-governance.ps1:1797). A **v2** context with no enforcement block is not
    # un-bootstrapped — it is MALFORMED, and the ledger read throws fail-closed before the crossing
    # path is ever reached. That produced two INCONCLUSIVE results rather than a false pass, which
    # is the guard working. The real pre-bootstrap project is schema **v1** with no enforcement
    # block: a project that never ran `specrew start` under the current schema.
    $ctx = [ordered]@{
        schema        = 'v1'
        feature_path  = $featureDir
        session_state = [ordered]@{
            active = $true; boundary_type = $(if ([string]::IsNullOrWhiteSpace($InitialBoundary)) { $null } else { $InitialBoundary })
            feature_ref = '050-host-neutral-gate'; iteration_number = ''
            recorded_at = '2026-08-03T00:00:00Z'
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'),
        ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $proj init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'fixture git init failed' }
    $null = & git -C $proj config core.autocrlf false
    $null = & git -C $proj add -A
    $null = & git -C $proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m 'fixture baseline'
    if ($LASTEXITCODE -ne 0) { throw 'fixture baseline commit failed' }
    return $proj
}

function New-FixtureTranscript {
    param([string]$Proj)
    $dir = Join-Path $Proj '.specrew\runtime'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $path = Join-Path $dir ('transcript-' + [guid]::NewGuid().ToString('N') + '.jsonl')
    $turns = @(
        @{ role = 'user'; text = 'Start the feature.' },
        @{ role = 'assistant'; text = 'I authored the specification and recorded the decisions. Here is where things stand.' }
    )
    $lines = foreach ($t in $turns) {
        ([pscustomobject]@{
                type    = $t.role
                message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = $t.text }) }
            } | ConvertTo-Json -Depth 8 -Compress)
    }
    [System.IO.File]::WriteAllLines($path, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
    return $path
}

# ---------------------------------------------------------------------------------------------
# CASE 1 — boundary sync on a first arrival it cannot record.
# ---------------------------------------------------------------------------------------------

Write-Host "`n--- CASE 1: sync must not report success when it could not establish the crossing ---`n" -ForegroundColor White

$proj = New-UnbootstrappedProject
$syncOut = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $sync -ProjectPath $proj -BoundaryType 'specify' -FeatureRef 'specs/050-host-neutral-gate' 2>&1) -join "`n")
$syncExit = $LASTEXITCODE

$json = $null
$jsonMatch = [regex]::Match($syncOut, '(?s)\{.*?"success".*?\}')
if ($jsonMatch.Success) { try { $json = $jsonMatch.Value | ConvertFrom-Json } catch { $json = $null } }

if ($null -eq $json) {
    Write-Inconclusive 'sync emitted no parseable result object — the probe never reached the decision it is meant to measure'
    Write-Measured ("sync exit={0}; output head: {1}" -f $syncExit, (($syncOut -replace '\s+', ' ').Trim() | ForEach-Object { $_.Substring(0, [Math]::Min(220, $_.Length)) }))
}
else {
    $reportedSuccess = [bool]$json.success
    $hasPending = [bool]$json.pending_verdict_has_pending
    $marker = [string]$json.pending_verdict_marker
    # Match either wording: the pre-T088 text and the post-T088 text. The console warning is kept
    # deliberately (a human reading the terminal should still see it); what changed is that the
    # STATE now travels too, so the second assertion below stops firing.
    $warned = ($syncOut -match 'could not write the pending-verdict stop artifact') -or ($syncOut -match 'could not establish the boundary crossing record')
    $stateTravels = ($null -ne $json.boundary_record_status) -and ([string]$json.boundary_record_status -ne 'established')
    Write-Measured ("boundary_record_status={0}; failure_reason_present={1}; is_first_boundary={2}" -f `
            $(if ($null -eq $json.boundary_record_status) { '(absent)' } else { $json.boundary_record_status }), `
        (-not [string]::IsNullOrWhiteSpace([string]$json.boundary_record_failure_reason)), $json.is_first_boundary)
    $artifactPath = Join-Path $proj '.specrew\runtime\pending-verdict-stop.md'
    $artifactExists = Test-Path -LiteralPath $artifactPath

    Write-Measured ("sync success={0}; has_pending={1}; marker={2}; artifact_written={3}; degrade-warning emitted={4}" -f `
            $reportedSuccess, $hasPending, $(if ([string]::IsNullOrWhiteSpace($marker)) { '(null)' } else { $marker }), $artifactExists, $warned)

    # FR-066: a first arrival the sync could not record must NOT be reported as an ordinary success
    # with "no pending verdict". Those two states are different and must be distinguishable.
    if ($reportedSuccess -and -not $hasPending -and -not $artifactExists) {
        Write-Red 'sync reports SUCCESS with has_pending=false and no artifact, after failing to establish the crossing — indistinguishable from a legitimate "no pending verdict"'
    }
    else {
        Write-Pass 'sync distinguishes "could not establish the crossing" from "no pending verdict"'
    }

    if ($warned -and -not $stateTravels) {
        Write-Red 'the failure is surfaced only as a Write-Warning — a warning is not a state a caller can branch on (NFR-002: legitimate paths announce themselves)'
    }
    elseif ($stateTravels) {
        Write-Pass 'the failure travels as a branchable state (boundary_record_status), not only as console text'
    }
}

# ---------------------------------------------------------------------------------------------
# CASE 2 — the packet surface, on a boundary whose record was never established.
# ---------------------------------------------------------------------------------------------

Write-Host "`n--- CASE 2: no approval options and no marker before the record exists ---`n" -ForegroundColor White

$transcript = New-FixtureTranscript -Proj $proj
$cmd = "Set-Location -LiteralPath '$proj'; & '$provider' --host-kind claude --source-event Stop --transcript-path '$transcript'"
$provOut = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1) -join "`n")
$provExit = $LASTEXITCODE
$provFaulted = ($provExit -ne 0) -or ($provOut -match 'Exception:|ParserError|CommandNotFoundException')
Write-Measured ("provider exit={0}; faulted={1}" -f $provExit, $provFaulted)

$blocked = $provOut -match '<<<SPECREW-STOP-BLOCK>>>'
$namesBoundary = $provOut -match 'BOUNDARY stop'
$carriesMarker = $provOut -match 'SPECREW-VERDICT-BOUNDARY:'
$flat = ($provOut -replace '\s+', ' ').Trim()
Write-Measured ("provider blocked={0}; announces a BOUNDARY stop={1}; supplies marker text={2}" -f $blocked, $namesBoundary, $carriesMarker)
Write-Measured ("block text (first 300 chars): {0}" -f $(if ($flat.Length -eq 0) { '(empty)' } else { $flat.Substring(0, [Math]::Min(300, $flat.Length)) }))

if ($provFaulted) {
    # The probe never reached a decision. Not a pass, not a finding — a fixture defect.
    Write-Inconclusive 'the provider faulted rather than deciding — this measures nothing about FR-066'
}
elseif (-not $blocked) {
    # The provider RAN and CHOSE silence. That is a decision, and for a first boundary whose record
    # was never established it is the wrong one: sync reported success, no crossing exists, and the
    # consumer's very first boundary passes with no enforcement surface at all. The original premise
    # of this case was the Antigravity "headers but no marker" shape; measurement says the
    # un-bootstrapped project produces something quieter and worse. Recorded as measured, not as
    # assumed — that marker-less block belongs to a DIFFERENT state (enforcement present, crossing
    # scope absent), which T086 already exercises.
    Write-Red 'the provider runs and emits NOTHING at a first boundary whose crossing was never established — the first boundary passes with no enforcement surface, while sync reported success'
}
elseif ($namesBoundary -and -not $carriesMarker) {
    Write-Red 'the provider announces a BOUNDARY stop but supplies NO marker — the "headers but no marker" shape, where a verdict can never be captured'
}
elseif ($namesBoundary -and $carriesMarker) {
    Write-Red 'the provider names a boundary and supplies a marker for a crossing the sync never recorded — the packet is creating the state it reports'
}
else {
    Write-Pass 'the provider does not present a boundary crossing that was never established'
}

# ---------------------------------------------------------------------------------------------
# CASE 3 — the unrecordable crossing must NOT be converted into an authorized cursor.
#
# DRIFT-198-I011-004 (certification finding 2), re-scoped on measurement 2026-08-06. The finding as
# filed names `specrew-start.ps1:2643` and frames the defect as "the recovery INSTRUCTION points at a
# path that mints authorization". The consequence-graph walk found that understates it on two axes:
#
#   1. THREE live mint sites, not one. `specrew-start.ps1:2643` (the launcher),
#      `SessionBootstrapManager.ps1:262` (the SessionStart HOOK - the path this project actually runs),
#      and `shared-governance.ps1:3070` (inside the authorization writer). A fourth,
#      `shared-governance.ps1:3247`, already passes $null - proof the safe form exists.
#   2. NO HUMAN ACTION IS REQUIRED. Sync persists `session_state.boundary_type`
#      (sync-boundary-state.ps1:1672) BEFORE the crossing write throws. The next session's hook reads
#      that value back through SessionStateAccessor.ps1:38 -> SessionBootstrapManager.ps1:204,212 and
#      initializes `last_authorized_boundary` AT that boundary. Merely OPENING the next session
#      converts a crossing that failed to record into an authorized one, instruction or not.
#
# So this case measures the HOOK seam, not the initializer in isolation: a fix proven only against
# `Initialize-...` called directly would repeat T089's unreachable-branch defect, where the code was
# correct and the path never reached it.
# ---------------------------------------------------------------------------------------------

Write-Host "`n--- CASE 3: a failed crossing must not become an authorized cursor ---`n" -ForegroundColor White

$proj3 = New-UnbootstrappedProject
$sync3Out = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $sync -ProjectPath $proj3 -BoundaryType 'specify' -FeatureRef 'specs/050-host-neutral-gate' 2>&1) -join "`n")
$json3 = $null
$m3 = [regex]::Match($sync3Out, '(?s)\{.*?"success".*?\}')
if ($m3.Success) { try { $json3 = $m3.Value | ConvertFrom-Json } catch { $json3 = $null } }

$recordStatus3 = if ($null -ne $json3 -and $null -ne $json3.boundary_record_status) { [string]$json3.boundary_record_status } else { '(absent)' }
Write-Measured ("case 3 precondition: boundary_record_status={0}" -f $recordStatus3)

if ($recordStatus3 -ne 'unrecordable') {
    # The scenario never happened, so nothing below measures the defect. Third outcome, not a pass.
    Write-Inconclusive ("sync did not reach the unrecordable state (status={0}) — this case measures nothing about finding 2" -f $recordStatus3)
}
else {
    # 3a — the failure must leave a DURABLE record. Without one there is nothing any later process can
    # detect: the enforcement ledger does not exist yet (that is the whole condition), and
    # `specrew-start.ps1:2524` rebuilds start-context.json from scratch, forwarding only
    # `boundary_enforcement` and `user_profile`, so a context key would be dropped by the very
    # recovery path that needs to read it. Hence its own file.
    $recordPath3 = Join-Path $proj3 '.specrew\unrecordable-crossing.json'
    $recordExists3 = Test-Path -LiteralPath $recordPath3 -PathType Leaf
    $recordBoundary3 = $null
    $recordReason3 = $null
    if ($recordExists3) {
        try {
            $rec3 = Get-Content -LiteralPath $recordPath3 -Raw -Encoding UTF8 | ConvertFrom-Json
            $recordBoundary3 = [string]$rec3.boundary
            $recordReason3 = [string]$rec3.failure_reason
        }
        catch { $recordBoundary3 = $null }
    }
    Write-Measured ("durable record present={0}; boundary={1}; failure_reason_present={2}" -f `
            $recordExists3, $(if ($recordBoundary3) { $recordBoundary3 } else { '(none)' }), (-not [string]::IsNullOrWhiteSpace($recordReason3)))

    if (-not $recordExists3) {
        Write-Red 'the failed crossing leaves NO durable record — nothing downstream can detect it, so every bootstrap path is free to cursor over it'
    }
    elseif ([string]::IsNullOrWhiteSpace($recordBoundary3) -or [string]::IsNullOrWhiteSpace($recordReason3)) {
        Write-Red 'the durable record exists but does not name the boundary and the reason — a detector cannot tell the human WHAT failed'
    }
    else {
        Write-Pass 'the failed crossing leaves a durable, named record'
    }

    # 3b — THE LIVE PATH. Drive the real SessionStart seam (Write-SpecrewLaunchContractArtifact ->
    # SessionBootstrapManager.ps1:262) in a child process: its dependency chain sets
    # `Set-StrictMode -Version Latest` at FILE scope, which would leak into the cases above.
    $bootScript = Join-Path $scratch ('boot-' + [guid]::NewGuid().ToString('N') + '.ps1')
    $bootBody = @"
`$ErrorActionPreference = 'Stop'
. '$repoRoot/scripts/internal/bootstrap/SessionStateAccessor.ps1'
. '$repoRoot/scripts/internal/bootstrap/SessionBootstrapManager.ps1'
. '$repoRoot/scripts/internal/launch-contract.ps1'
. '$repoRoot/scripts/internal/coordinator-resume.ps1'
. '$repoRoot/scripts/internal/coordinator-prompt-surgery.ps1'
. '$repoRoot/scripts/internal/user-profile.ps1'
. '$repoRoot/extensions/specrew-speckit/scripts/shared-governance.ps1'
# The REAL anchor shape the hook receives (`boundary`/`iteration`, per SessionStateAccessor.ps1:38),
# carrying the boundary sync persisted before the crossing write failed.
`$anchor = [pscustomobject]@{
    active = `$true; feature_ref = '050-host-neutral-gate'
    feature_path = (Join-Path '$proj3' 'specs/050-host-neutral-gate')
    boundary = 'specify'; iteration = ''; auth_commit_hash = 'x'; recorded_at = '2026-08-03T00:00:00Z'
}
Write-SpecrewLaunchContractArtifact -ProjectRoot '$proj3' -Mode 'welcome-back' -SessionState `$anchor | Out-Null
"@
    [System.IO.File]::WriteAllText($bootScript, $bootBody, [System.Text.UTF8Encoding]::new($false))
    $bootOut = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $bootScript 2>&1) -join "`n")
    $bootExit = $LASTEXITCODE
    $bootFaulted = ($bootExit -ne 0)

    $ctxAfter = $null
    try { $ctxAfter = Get-Content -LiteralPath (Join-Path $proj3 '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $ctxAfter = $null }
    $beAfter = if ($null -ne $ctxAfter) { $ctxAfter.boundary_enforcement } else { $null }
    $cursorAfter = if ($null -ne $beAfter) { [string]$beAfter.last_authorized_boundary } else { '(no block)' }
    $verdictCount = if ($null -ne $beAfter -and $null -ne $beAfter.verdict_history) { @($beAfter.verdict_history).Count } else { -1 }

    Write-Measured ("hook bootstrap exit={0}; last_authorized_boundary={1}; verdict_history={2}" -f `
            $bootExit, $(if ([string]::IsNullOrWhiteSpace($cursorAfter)) { '(null)' } else { $cursorAfter }), $verdictCount)

    if ($bootFaulted) {
        Write-Inconclusive ("the SessionStart seam faulted rather than deciding — measures nothing about the mint. Output head: {0}" -f `
            (($bootOut -replace '\s+', ' ').Trim() | ForEach-Object { $_.Substring(0, [Math]::Min(220, $_.Length)) }))
    }
    elseif ($null -eq $beAfter) {
        Write-Inconclusive 'the SessionStart seam wrote no boundary_enforcement block at all — the probe never reached the initializer'
    }
    elseif ($cursorAfter -eq 'specify') {
        Write-Red 'opening the next session CONVERTED the unrecordable crossing into an authorized cursor (last_authorized_boundary=specify, verdict_history empty) — a boundary no human ever approved is now recorded as approved'
    }
    elseif ([string]::IsNullOrWhiteSpace($cursorAfter)) {
        Write-Pass 'the SessionStart seam refused to cursor over the failed crossing (last_authorized_boundary stays null, awaiting a human verdict)'
    }
    else {
        Write-Red ("the cursor was initialized at an unexpected boundary '{0}' — neither refused nor the failed boundary" -f $cursorAfter)
    }

    # 3c — the INSTRUCTION must surface the state for HUMAN confirmation and must never name a path
    # that mints authorization.
    #
    # FIXTURE DEFECT, caught by the INCONCLUSIVE guard on the first run and recorded rather than
    # quietly patched: this originally reused $proj3, but 3b's bootstrap WRITES the
    # boundary_enforcement block — so the project is no longer in the unrecordable state and the
    # provider correctly emits nothing. Measured as "blocked=False, pointsAtMint=False", which a
    # two-outcome harness would have scored as "the instruction does not name the mint path" — a
    # false PASS on a defect that is still live. 3c gets its own untouched project.
    $proj3c = New-UnbootstrappedProject
    $null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $sync -ProjectPath $proj3c -BoundaryType 'specify' -FeatureRef 'specs/050-host-neutral-gate' 2>&1
    $transcript3 = New-FixtureTranscript -Proj $proj3c
    $cmd3 = "Set-Location -LiteralPath '$proj3c'; & '$provider' --host-kind claude --source-event Stop --transcript-path '$transcript3'"
    $provOut3 = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -Command $cmd3 2>&1) -join "`n")
    $flat3 = ($provOut3 -replace '\s+', ' ').Trim()
    $blocked3 = $provOut3 -match '<<<SPECREW-STOP-BLOCK>>>'
    # The defective wording: it tells the human to run the bootstrap path, which is exactly the path
    # that mints the cursor. Any remedy phrased as "run start/bootstrap to create it" is the defect.
    $pointsAtMint3 = $flat3 -match '(?i)run the Specrew start/bootstrap path'
    $asksHuman3 = $flat3 -match '(?i)(human|you) must (confirm|approve|authorize)|awaiting your|needs your explicit'
    Write-Measured ("provider blocked={0}; instruction points at the bootstrap path={1}; asks for human confirmation={2}" -f $blocked3, $pointsAtMint3, $asksHuman3)

    if (-not $blocked3) {
        Write-Inconclusive 'the provider emitted no block on the unrecordable project — the instruction text cannot be measured'
    }
    elseif ($pointsAtMint3) {
        Write-Red 'the recovery instruction still names the start/bootstrap path — it points the human at the mechanism that mints the authorization it failed to record'
    }
    elseif (-not $asksHuman3) {
        Write-Red 'the instruction no longer names the mint path but does not surface the state for HUMAN confirmation either — the human is left with no way to resolve it'
    }
    else {
        Write-Pass 'the instruction surfaces the unrecordable state for human confirmation and names no authorization-minting path'
    }
}

# ---------------------------------------------------------------------------------------------
# CASE 4 — the DOUBLE failure: the crossing cannot be recorded AND the refusal record cannot be
# written. Certification round 2, sole blocking finding, against the finding-2 fix itself.
#
# The defect: boundary sync persists the ADVANCED session boundary before attempting the crossing.
# When the crossing failed, the refusal latch was the only durable thing keeping the next bootstrap
# from minting authorization — and if writing THAT failed too, the catch merely warned and returned.
# The advanced boundary stayed on disk with no refusal record, so the next bootstrap took the
# ordinary no-record path and initialized last_authorized_boundary AT the failed boundary.
#
# The comment eleven lines above the defect already stated the rule it broke: "A warning is NOT a
# state a caller can branch on (NFR-002)". A warning in a dying session cannot bind the next one.
#
# ACCEPTANCE CRITERION (maintainer, 2026-08-07), asserted here rather than an implementation shape:
# after the double failure there must be NO state a later bootstrap can mint authorization from.
# ---------------------------------------------------------------------------------------------

Write-Host "`n--- CASE 4: a double write failure must leave nothing to mint from ---`n" -ForegroundColor White

# A project that has NOT yet reached a boundary: the sync under test is what advances it.
$proj4 = New-UnbootstrappedProject -InitialBoundary ''

# INJECTION: make the refusal-record write fail deterministically by occupying its exact path with a
# DIRECTORY. This is the real failure the finding describes (the record cannot be persisted), induced
# without stubbing the writer — the production code path runs unmodified.
$recordPath4 = Join-Path $proj4 '.specrew\unrecordable-crossing.json'
New-Item -ItemType Directory -Path $recordPath4 -Force | Out-Null

$sync4Out = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $sync -ProjectPath $proj4 -BoundaryType 'specify' -FeatureRef 'specs/050-host-neutral-gate' 2>&1) -join "`n")

# What ended up on disk is the whole question: a persisted advanced boundary with no refusal record
# is exactly the mintable state.
$ctx4 = $null
try { $ctx4 = Get-Content -LiteralPath (Join-Path $proj4 '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $ctx4 = $null }
$persistedBoundary4 = if ($null -ne $ctx4 -and $null -ne $ctx4.session_state) { [string]$ctx4.session_state.boundary_type } else { '' }
$recordIsFile4 = (Test-Path -LiteralPath $recordPath4 -PathType Leaf)
Write-Measured ("after double failure: persisted boundary={0}; refusal record is a readable file={1}" -f `
        $(if ([string]::IsNullOrWhiteSpace($persistedBoundary4)) { '(none)' } else { $persistedBoundary4 }), $recordIsFile4)

if ($null -eq $ctx4) {
    Write-Inconclusive 'start-context.json is unreadable after the run — the probe cannot tell what state was left behind'
}
else {
    # Drive the REAL SessionStart seam, the path that actually mints. Asserting on the outcome rather
    # than on sync's internals keeps this a test of the criterion, not of one implementation of it.
    $bootScript4 = Join-Path $scratch ('boot4-' + [guid]::NewGuid().ToString('N') + '.ps1')
    $bootBody4 = @"
`$ErrorActionPreference = 'Stop'
. '$repoRoot/scripts/internal/bootstrap/SessionStateAccessor.ps1'
. '$repoRoot/scripts/internal/bootstrap/SessionBootstrapManager.ps1'
. '$repoRoot/scripts/internal/launch-contract.ps1'
. '$repoRoot/scripts/internal/coordinator-resume.ps1'
. '$repoRoot/scripts/internal/coordinator-prompt-surgery.ps1'
. '$repoRoot/scripts/internal/user-profile.ps1'
. '$repoRoot/extensions/specrew-speckit/scripts/shared-governance.ps1'
# The anchor the hook builds from whatever sync actually left on disk.
`$ctx = Get-Content -LiteralPath '$proj4/.specrew/start-context.json' -Raw -Encoding UTF8 | ConvertFrom-Json
`$b = if (`$null -ne `$ctx.session_state) { [string]`$ctx.session_state.boundary_type } else { '' }
`$anchor = [pscustomobject]@{
    active = `$true; feature_ref = '050-host-neutral-gate'
    feature_path = (Join-Path '$proj4' 'specs/050-host-neutral-gate')
    boundary = `$b; iteration = ''; auth_commit_hash = 'x'; recorded_at = '2026-08-03T00:00:00Z'
}
Write-SpecrewLaunchContractArtifact -ProjectRoot '$proj4' -Mode 'welcome-back' -SessionState `$anchor | Out-Null
"@
    [System.IO.File]::WriteAllText($bootScript4, $bootBody4, [System.Text.UTF8Encoding]::new($false))
    $bootOut4 = (@(& pwsh -NoProfile -ExecutionPolicy Bypass -File $bootScript4 2>&1) -join "`n")
    $bootExit4 = $LASTEXITCODE

    $ctxAfter4 = $null
    try { $ctxAfter4 = Get-Content -LiteralPath (Join-Path $proj4 '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $ctxAfter4 = $null }
    $beAfter4 = if ($null -ne $ctxAfter4) { $ctxAfter4.boundary_enforcement } else { $null }
    $cursor4 = if ($null -ne $beAfter4) { [string]$beAfter4.last_authorized_boundary } else { '(no block)' }
    Write-Measured ("hook bootstrap exit={0}; last_authorized_boundary={1}" -f $bootExit4, $(if ([string]::IsNullOrWhiteSpace($cursor4)) { '(null)' } else { $cursor4 }))

    if ($bootExit4 -ne 0) {
        Write-Inconclusive ("the SessionStart seam faulted rather than deciding: {0}" -f (($bootOut4 -replace '\s+', ' ').Trim() | ForEach-Object { $_.Substring(0, [Math]::Min(200, $_.Length)) }))
    }
    elseif ($cursor4 -eq 'specify') {
        Write-Red 'the DOUBLE failure left a mintable state: neither the crossing nor a refusal record persisted, yet the advanced boundary did — and the next bootstrap authorized it (last_authorized_boundary=specify)'
    }
    elseif ([string]::IsNullOrWhiteSpace($cursor4) -or $cursor4 -eq '(no block)') {
        Write-Pass 'after the double failure there is no state to mint authorization from (cursor stays null)'
    }
    else {
        Write-Red ("the cursor was initialized at an unexpected boundary '{0}'" -f $cursor4)
    }
}

Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
if ($script:Hard -gt 0) {
    Write-Host "=== T087: $($script:Hard) INCONCLUSIVE case(s) — fix the fixture before reading any result ===" -ForegroundColor Magenta
    exit 2
}
if ($script:Red -gt 0) {
    Write-Host "=== T087: $($script:Red) RED assertion(s) — expected until T088/T089 land ===" -ForegroundColor Yellow
    exit 1
}
Write-Host '=== T087: all assertions green ===' -ForegroundColor Green
exit 0
