# Feature 185 FR-011 / FR-015 / FR-004 / FR-005 - the conformance Stop-provider (DETECTION + BLOCK delivery).
#
# This is a CONSUMER of the EXISTING hook dispatcher + provider catalog (refocus-scopes.json), registered
# as kind=inject events=[Stop] order=40 - it runs AFTER the handover provider (order 30) has done the
# verdict capture (which advances last_authorized_boundary via the authorization writer on a captured marker).
# It is an isolated script the dispatcher invokes; it does NOT edit HandoverStore.ps1 and NEVER calls the
# verdict-authority write path - it is a strictly READ-ONLY consumer of the gate STATE, so it physically
# cannot break what keeps the lifecycle honest. Its only writes are best-effort diagnostics under
# .specrew/runtime/ (the conformance journal + the stop-block loop-guard counter), never gate state.
#
# ARG CONTRACT: the dispatcher invokes inject providers with DOUBLE-dash flags (--host-kind, --source-event,
# --transcript-path) via ProcessStartInfo.ArgumentList. PowerShell's single-dash `param()` binding REJECTS
# a `--flag` token (it reads as `-flag`), so a `param()`/[CmdletBinding()] block makes the script exit 1 at
# the binding boundary BEFORE its body runs. So parse $args MANUALLY (the handover provider's convention). NO param().
#
# DELIVERY = BLOCK AT THE STOP (FR-015 maintainer ruling 2026-06-20): the 6-section re-entry packet must render
# AT the stop, not as a too-late next-turn nudge - a packet-less stop already leaves the human puzzled. So when a
# stop owes the packet and it is absent, this provider emits a BLOCK SENTINEL (`<<<SPECREW-STOP-BLOCK>>>` + the
# directive); the dispatcher translates it into the host's stop-block envelope (verified capability matrix,
# research/stop-block-capability-matrix.md: claude/codex/copilot decision:block, antigravity decision:continue,
# cursor followup_message), force-continuing the turn so the agent renders the packet before control returns.
#
# WHAT OWES THE PACKET (block triggers; the design workshop is the only exclusion):
#   - BOUNDARY stop: HasPendingVerdict (working boundary ahead of last-authorized, no captured verdict - the #2884
#     silent advance). REUSES the canonical Get-SpecrewPendingVerdictState (FR-008; not a parallel inference engine).
#     The block directive carries the CONTIGUOUS last_authorized -> successor verdict marker (145 F2).
#   - MATERIAL non-boundary stop: the current Stop handover reports changed user files or new commits, but the last
#     assistant message lacks the five-part context packet. This uses the same rolling-handover material signal as
#     the resume floor and deliberately does NOT block on prose length alone.
#   FALSE-POSITIVE GUARD: if the last assistant message already surfaced the exact pending boundary crossing (the
#   marker the capture path would accept) -> no block.
#
# #1 INTAKE QUESTION (asking "what to build" while a spec exists) and #3 RAW `specify[.exe] workflow`: cooperative
#   redirects, folded into the block directive when a block fires, else emitted as a plain inject nudge.
#
# LOOP GUARD (never hang a session): claude/codex have a built-in stop_hook_active cap (the dispatcher also
#   honours it - it does NOT block when already continuing). copilot/antigravity have none, so this provider keeps
#   its OWN consecutive-block counter (.specrew/runtime/conformance-stop-block.json), capped at $BLOCK_CAP within a
#   short window; over the cap -> stop blocking, degrade to a plain nudge, never trap. Reset when the packet appears.
#
# HONEST CEILINGS: (1) cursor cannot hard-block (followup_message re-triggers a NEW turn - the human may glimpse the
#   packet-less stop); declared best-effort. (2) capability != firing reliability - codex Stop does not fire on an
#   Esc-interrupted turn / headless exec (a real-host dogfood concern). (3) DETECTION SCOPE: boundary enforcement
#   keys off gate state; material-work enforcement keys off the current rolling-handover Stop snapshot. If either
#   signal is unavailable, the provider fails open. (4) the design-analysis lens workshop is explicitly excluded.
#   Fully FAIL-OPEN: any error / uncertainty
#   degrades to NO block (allow the stop) - blocking is the narrow exception, never the default.

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }  # best-effort UTF-8 (child half of the dispatcher's encoding contract)

$script:SpecrewReentryHeaders = @('What I Just Did', 'Why I Stopped', 'What Needs Your Review', 'What Happens Next', 'Discussion Prompts', 'What I Need From You')
$script:SpecrewBlockCap = 3
$script:SpecrewFireDedupWindowSec = 60  # idempotency: a duplicate hook fire for the SAME observable state within this window is a no-op.
$script:SpecrewMaterialHandoverMaxAgeSec = 300  # handover provider runs immediately before conformance; older snapshots are stale.
$script:SpecrewMaterialRetryWindowSec = 600  # after a material stop block, keep enforcing only during the forced-continue loop.
$script:SpecrewSubstantialChars = 600

function Test-SpecrewReentryPacketPresent {
    # >=4 of the 6 canonical section-header phrases present in the (flattened) last assistant message = the packet
    # was rendered. Phrase-based (not '## '-prefixed) so it survives the transcript flattening; >=4 (not all 6)
    # tolerates minor wording drift without letting a bare message through.
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    $hits = 0
    foreach ($h in $script:SpecrewReentryHeaders) { if ($Text -match [regex]::Escape($h)) { $hits++ } }
    return ($hits -ge 4)
}

function Get-SpecrewBlockCount {
    # Consecutive-block count for THIS advance ($Key = "<working>|<lastAuth>"). 0 if absent / a DIFFERENT advance /
    # unreadable. Keyed by the advance identity (NOT a time window): the count accumulates across consecutive
    # packet-less stops for the same advance regardless of how long each forced-continue turn takes (145 HANG-1: a
    # time window let a >120s/turn loop reset to 0 forever and never cap). A different advance is a fresh sequence.
    param([string]$Path, [string]$Key)
    try {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $rec = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (($rec.PSObject.Properties.Name -contains 'count') -and ($rec.PSObject.Properties.Name -contains 'key') -and ([string]$rec.key -eq $Key)) {
                return [int]$rec.count
            }
        }
    }
    catch { $null = $_ }
    return 0
}

function Get-SpecrewBlockRecord {
    param([string]$Path)
    try {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $rec = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (($rec.PSObject.Properties.Name -contains 'key') -and ($rec.PSObject.Properties.Name -contains 'count')) {
                return $rec
            }
        }
    }
    catch { $null = $_ }
    return $null
}

function Set-SpecrewBlockCount {
    # Persist the count for $Key and VERIFY it landed (read-back). Returns $true only when the increment is durably
    # readable - the caller blocks ONLY on $true, so a persistent / non-atomic write failure can never start an
    # uncappable block loop on a host without a built-in cap (145 HANG-2 fail-open).
    param([string]$Path, [string]$Key, [int]$Count)
    try {
        $dir = Split-Path -Parent $Path
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ([pscustomobject]@{ key = $Key; count = $Count; epoch = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $back = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (($back.PSObject.Properties.Name -contains 'count') -and ([int]$back.count -eq $Count) -and ($back.PSObject.Properties.Name -contains 'key') -and ([string]$back.key -eq $Key)) { return $true }
        }
    }
    catch { $null = $_ }
    return $false
}

function Get-SpecrewRecentMaterialRetryKey {
    param([AllowNull()]$Record)
    try {
        if ($null -eq $Record -or -not ($Record.PSObject.Properties.Name -contains 'key')) { return $null }
        $key = [string]$Record.key
        if ($key -notlike 'material|*') { return $null }
        if (-not ($Record.PSObject.Properties.Name -contains 'epoch')) { return $null }
        $age = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - [long]$Record.epoch
        if ($age -ge 0 -and $age -le $script:SpecrewMaterialRetryWindowSec) { return $key }
    }
    catch { $null = $_ }
    return $null
}

function Get-SpecrewMaterialSatisfiedKey {
    param([string]$Path)
    try {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $rec = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (($rec.PSObject.Properties.Name -contains 'key') -and -not [string]::IsNullOrWhiteSpace([string]$rec.key)) {
                return [string]$rec.key
            }
        }
    }
    catch { $null = $_ }
    return $null
}

function Set-SpecrewMaterialSatisfiedKey {
    param([string]$Path, [string]$Key)
    if ([string]::IsNullOrWhiteSpace($Key)) { return }
    try {
        $dir = Split-Path -Parent $Path
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ([pscustomobject]@{ key = $Key; epoch = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
    }
    catch { $null = $_ }
}

function Get-SpecrewCurrentStopMaterialSignal {
    # Deterministic non-boundary packet trigger. The handover provider (order 30) runs before this conformance
    # provider (order 40) and writes the latest Stop snapshot. Treat it as material ONLY when the current, fresh
    # Stop snapshot's newest activity bullet reports changed user files or new commits. Conversation-only Stop
    # refreshes update recorded_at but do not prepend an activity bullet, so their bullet timestamp will not match.
    param([string]$ProjectRoot, [AllowNull()][string]$BootstrapDir)
    $result = [pscustomobject]@{ material = $false; key = $null; reason = 'no-material-signal'; user_file_count = 0; new_commit_count = 0; active_feature = $null; active_boundary = $null }
    try {
        if ([string]::IsNullOrWhiteSpace($BootstrapDir)) { $result.reason = 'no-bootstrap-dir'; return $result }
        $store = Join-Path $BootstrapDir 'HandoverStore.ps1'
        if (-not (Test-Path -LiteralPath $store -PathType Leaf)) { $result.reason = 'no-handover-store'; return $result }
        if (-not (Get-Command ConvertFrom-SpecrewHandoverFile -ErrorAction SilentlyContinue)) {
            try { . $store } catch { $result.reason = 'handover-store-unloadable'; return $result }
        }
        if (-not (Get-Command ConvertFrom-SpecrewHandoverFile -ErrorAction SilentlyContinue)) { $result.reason = 'handover-parser-unavailable'; return $result }

        $path = Join-Path $ProjectRoot '.specrew/handover/session-handover.md'
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { $result.reason = 'no-handover'; return $result }
        $handover = ConvertFrom-SpecrewHandoverFile -Path $path
        if ($null -eq $handover) { $result.reason = 'unreadable-handover'; return $result }
        $result.active_feature = [string]$handover.active_feature
        $result.active_boundary = [string]$handover.active_boundary

        $source = [string]$handover.source
        if ([string]::IsNullOrWhiteSpace($source) -or $source.ToLowerInvariant() -notin @('stop', 'agentstop')) {
            $result.reason = 'not-stop-handover'; return $result
        }

        $recordedRaw = [string]$handover.recorded_at
        if ([string]::IsNullOrWhiteSpace($recordedRaw)) { $result.reason = 'missing-recorded-at'; return $result }
        $recordedAt = [datetime]::Parse($recordedRaw).ToUniversalTime()
        $age = ([datetime]::UtcNow - $recordedAt).TotalSeconds
        if ($age -lt -30 -or $age -gt $script:SpecrewMaterialHandoverMaxAgeSec) {
            $result.reason = 'stale-handover'; return $result
        }

        $activityTitle = 'What I just did (last 3-5 turns or last boundary work)'
        $activity = if ($handover.sections -and $handover.sections.Contains($activityTitle)) { [string]$handover.sections[$activityTitle] } else { '' }
        if ([string]::IsNullOrWhiteSpace($activity)) { $result.reason = 'no-activity-section'; return $result }
        $bullet = @($activity -split "`r?`n" | Where-Object { $_ -match '^\s*-\s+\[' } | Select-Object -First 1)
        if ($bullet.Count -eq 0) { $result.reason = 'no-activity-bullet'; return $result }

        $bulletText = [string]$bullet[0]
        $rx = [regex]::new('^\s*-\s+\[(?<stamp>[^\]]+)\]\s+\((?<source>[^)]+)\)\s+(?<files>\d+)\s+changed user file\(s\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $m = $rx.Match($bulletText)
        if (-not $m.Success) { $result.reason = 'activity-unrecognized'; return $result }
        if (($m.Groups['source'].Value).ToLowerInvariant() -notin @('stop', 'agentstop')) { $result.reason = 'activity-not-stop'; return $result }

        $activityAt = [datetime]::Parse($m.Groups['stamp'].Value).ToUniversalTime()
        if ([math]::Abs(($recordedAt - $activityAt).TotalSeconds) -gt 5) {
            $result.reason = 'activity-not-current-stop'; return $result
        }

        $files = [int]$m.Groups['files'].Value
        $commitMatch = [regex]::Match($bulletText, ';\s+(?<commits>\d+)\s+new commit\(s\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $commits = if ($commitMatch.Success -and -not [string]::IsNullOrWhiteSpace($commitMatch.Groups['commits'].Value)) { [int]$commitMatch.Groups['commits'].Value } else { 0 }
        if ($files -le 0 -and $commits -le 0) { $result.reason = 'no-user-files-or-commits'; return $result }

        $result.material = $true
        $result.reason = 'current-stop-material-delta'
        $result.user_file_count = $files
        $result.new_commit_count = $commits
        $stableMaterialSurface = ($bulletText -replace '^\s*-\s+\[[^\]]+\]\s+\([^)]+\)\s+', '').Trim()
        $surfaceHash = Get-SpecrewFireIdentity -Parts @($stableMaterialSurface)
        $result.key = ('material|{0}' -f $surfaceHash)
        return $result
    }
    catch {
        $result.reason = 'material-signal-unreadable'
        return $result
    }
}

function Reset-SpecrewBlockCount {
    param([string]$Path)
    try { if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue } }
    catch { $null = $_ }
}

function Get-SpecrewFireIdentity {
    # A stable identity for THIS Stop fire = a hash of the recent transcript tail + the boundary cursor + the source
    # event. Two fires with the same identity are the SAME observable state (a duplicate hook delivery for the same
    # message); the boundary force-continue loop produces a NEW message each turn -> a different identity.
    param([string[]]$Parts)
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes(($Parts -join '|'))
        return (-join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }))
    }
    catch { return '' }
}

function Resolve-SpecrewBootstrapDir {
    # The scripts/internal/bootstrap dir (ConversationCaptureAccessor + ProjectMetadataAccessor). Direct candidates
    # (project tree, then SPECREW_MODULE_PATH) FIRST; the Get-Module -ListAvailable scan (slow over OneDrive /
    # multi-version) runs ONLY if they miss. $null if none resolves.
    param([string]$ProjectRoot)
    foreach ($base in @($ProjectRoot, $env:SPECREW_MODULE_PATH)) {
        if ([string]::IsNullOrWhiteSpace($base)) { continue }
        $bd = Join-Path $base 'scripts/internal/bootstrap'
        if (Test-Path -LiteralPath (Join-Path $bd 'ConversationCaptureAccessor.ps1') -PathType Leaf) { return $bd }
    }
    try {
        $mod = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.ModuleBase 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1') } | Select-Object -First 1
        if ($mod) { return (Join-Path $mod.ModuleBase 'scripts/internal/bootstrap') }
    }
    catch { $null = $_ }
    return $null
}

function Test-SpecrewWorkshopInProgress {
    # FR-015: the design workshop's per-lens questions are the ONLY exclusion from the every-stop packet rule. The
    # lens workshop CONTINUES after create-new-feature.ps1 scaffolds spec.md, so a pre-spec proxy is WRONG (the
    # dogfood false-blocked a lens question once spec.md existed). REUSE the canonical Get-SpecrewWorkshopProgress
    # (lens-applicability.json `selected` + workshop/*.md done records): a feature with a confirmed lens agenda
    # (has_applicability) and lenses still REMAINING is mid-workshop. Returns $true ONLY on a positive, readable
    # detection (a real workshop state); any miss / read error -> $false (a missing signal does not fabricate a
    # workshop, so a genuine boundary still enforces). FR-008 reuse - not a parallel workshop-state inference.
    # SCOPED TO THE ACTIVE FEATURE (145 OB-1): check ONLY $FeatureRef - a DIFFERENT (abandoned) feature whose
    # workshop still has lenses remaining must NOT suppress the ACTIVE feature's enforcement (the old whole-project
    # loop let one stale feature silently disable every block for the active one - the exact #2884 gate-slip). An
    # unresolved $FeatureRef -> $false (do NOT suppress; fail toward enforcement, the safe direction).
    param([string]$ProjectRoot, [AllowNull()][string]$BootstrapDir, [AllowNull()][string]$FeatureRef)
    try {
        if ([string]::IsNullOrWhiteSpace($BootstrapDir) -or [string]::IsNullOrWhiteSpace($FeatureRef)) { return $false }
        $pma = Join-Path $BootstrapDir 'ProjectMetadataAccessor.ps1'
        if (-not (Test-Path -LiteralPath $pma -PathType Leaf)) { return $false }
        try { . $pma } catch { return $false }
        if (-not (Get-Command Get-SpecrewWorkshopProgress -ErrorAction SilentlyContinue)) { return $false }
        $wp = $null
        try { $wp = Get-SpecrewWorkshopProgress -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef } catch { $wp = $null }
        if ($null -ne $wp -and [bool]$wp.has_applicability -and (@($wp.remaining).Count -gt 0)) { return $true }
    }
    catch { $null = $_ }
    return $false
}

function Test-SpecrewWorkshopComplete {
    # Complements Test-SpecrewWorkshopInProgress for the pre-boundary scaffold suppression. A feature with no
    # active boundary/authorization can still have completed its lens workshop; in that case material work after
    # the workshop must not be suppressed as "initial intake".
    param([string]$ProjectRoot, [AllowNull()][string]$BootstrapDir, [AllowNull()][string]$FeatureRef)
    try {
        if ([string]::IsNullOrWhiteSpace($BootstrapDir) -or [string]::IsNullOrWhiteSpace($FeatureRef)) { return $false }
        $pma = Join-Path $BootstrapDir 'ProjectMetadataAccessor.ps1'
        if (-not (Test-Path -LiteralPath $pma -PathType Leaf)) { return $false }
        try { . $pma } catch { return $false }
        if (-not (Get-Command Get-SpecrewWorkshopProgress -ErrorAction SilentlyContinue)) { return $false }
        $wp = $null
        try { $wp = Get-SpecrewWorkshopProgress -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef } catch { $wp = $null }
        return ($null -ne $wp -and [bool]$wp.has_applicability -and (@($wp.selected).Count -gt 0) -and (@($wp.remaining).Count -eq 0))
    }
    catch { $null = $_ }
    return $false
}

# --- manual $args parse (the double-dash contract; B1 - NO param()) ---
$hostKindArg = $null
$sourceEventArg = $null
$transcriptPathArg = $null
for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq '--host-kind' -and ($i + 1) -lt $args.Count) { $hostKindArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--source-event' -and ($i + 1) -lt $args.Count) { $sourceEventArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--transcript-path' -and ($i + 1) -lt $args.Count) { $transcriptPathArg = [string]$args[$i + 1] }
}

try {
    $projectRoot = (Get-Location).Path
    if ([string]::IsNullOrWhiteSpace($projectRoot) -or -not (Test-Path -LiteralPath (Join-Path $projectRoot '.specrew'))) {
        return  # not a governed project root - nothing to check.
    }
    if (-not [string]::IsNullOrWhiteSpace($sourceEventArg) -and ($sourceEventArg.ToLowerInvariant() -notin @('stop', 'agentstop'))) {
        return  # only an end-of-turn Stop-class event (the registration already gates this; defensive).
    }

    # --- component resolution (fail-open: a component that cannot load simply disables its lane) ---
    # shared-governance.ps1 ships BESIDE this provider - the canonical Get-SpecrewPendingVerdictState + boundary order.
    $sgBeside = Join-Path $PSScriptRoot 'shared-governance.ps1'
    if (Test-Path -LiteralPath $sgBeside -PathType Leaf) { try { . $sgBeside } catch { $null = $_ } }

    # --- CHEAP signals first (no per-line transcript parse) ---
    # Pending-verdict state (the boundary trigger) - reused canonical helper; WARN loudly if it cannot load (F4).
    $pending = $null
    if (Get-Command Get-SpecrewPendingVerdictState -ErrorAction SilentlyContinue) {
        try { $pending = Get-SpecrewPendingVerdictState -ProjectRoot $projectRoot } catch { $pending = $null }
    }
    else {
        [Console]::Error.WriteLine('[specrew-conformance] WARN CONFORMANCE_DETECTOR_UNAVAILABLE shared-governance/Get-SpecrewPendingVerdictState did not load; the boundary lane is dark this stop (the gate STATE + resume surface remain the authority).')
    }
    $hasPending = ($null -ne $pending -and [bool]$pending.HasPendingVerdict)

    # Any feature spec on disk (cheap dir check) -> the substantial + #1 triggers need this.
    $anySpec = $false; $specPath = $null
    try {
        $specs = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'specs') -Directory -ErrorAction Stop |
            ForEach-Object { Join-Path $_.FullName 'spec.md' } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
        if ($specs.Count -gt 0) { $anySpec = $true; $specPath = $specs[0] }
    }
    catch { $anySpec = $false }

    # Active feature ref (145 OB-1): the workshop exclusion must scope to THIS feature, not the whole project.
    # session_state.feature_ref is canonical; fall back to the spec dir found above; null -> the exclusion fails
    # toward enforcement (it does not suppress a different feature's workshop onto the active one).
    $activeFeatureRef = $null
    $activeFeatureFromSessionState = $false
    $startContextReadable = $false
    $hasActiveLifecycleBoundary = $false
    $hasBoundaryAuthorization = $false
    try {
        $scPath = Join-Path $projectRoot '.specrew/start-context.json'
        if (Test-Path -LiteralPath $scPath -PathType Leaf) {
            $sc = Get-Content -LiteralPath $scPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $startContextReadable = $true
            if ($sc.PSObject.Properties['session_state'] -and $null -ne $sc.session_state -and $sc.session_state.PSObject.Properties['feature_ref'] -and -not [string]::IsNullOrWhiteSpace([string]$sc.session_state.feature_ref)) {
                $activeFeatureRef = [string]$sc.session_state.feature_ref
                $activeFeatureFromSessionState = $true
            }
            if ($sc.PSObject.Properties['session_state'] -and $null -ne $sc.session_state -and $sc.session_state.PSObject.Properties['boundary_type'] -and -not [string]::IsNullOrWhiteSpace([string]$sc.session_state.boundary_type)) {
                $hasActiveLifecycleBoundary = $true
            }
            if ($sc.PSObject.Properties['boundary_enforcement'] -and $null -ne $sc.boundary_enforcement) {
                if ($sc.boundary_enforcement.PSObject.Properties['last_authorized_boundary'] -and -not [string]::IsNullOrWhiteSpace([string]$sc.boundary_enforcement.last_authorized_boundary)) {
                    $hasBoundaryAuthorization = $true
                }
                if ($sc.boundary_enforcement.PSObject.Properties['verdict_history'] -and @($sc.boundary_enforcement.verdict_history).Count -gt 0) {
                    $hasBoundaryAuthorization = $true
                }
            }
        }
    }
    catch { $null = $_ }
    $bootstrapDir = Resolve-SpecrewBootstrapDir -ProjectRoot $projectRoot

    # If lifecycle state is still pre-boundary / anchorless, the rolling Stop handover is the fresher scoped signal.
    # In a multi-feature repo, falling back to the first specs/* directory can incorrectly borrow an abandoned
    # feature's workshop state and suppress a real material-work packet for the active feature.
    $materialSignal = Get-SpecrewCurrentStopMaterialSignal -ProjectRoot $projectRoot -BootstrapDir $bootstrapDir
    if (-not $activeFeatureFromSessionState -and $null -ne $materialSignal -and -not [string]::IsNullOrWhiteSpace([string]$materialSignal.active_feature)) {
        $activeFeatureRef = [string]$materialSignal.active_feature
    }
    if ([string]::IsNullOrWhiteSpace($activeFeatureRef) -and -not [string]::IsNullOrWhiteSpace($specPath)) {
        $activeFeatureRef = Split-Path (Split-Path $specPath -Parent) -Leaf
    }
    $preBoundaryWorkshopCandidate = $startContextReadable -and (-not $hasActiveLifecycleBoundary) -and (-not $hasBoundaryAuthorization)
    $workshopComplete = $false
    if ($preBoundaryWorkshopCandidate) {
        $workshopComplete = Test-SpecrewWorkshopComplete -ProjectRoot $projectRoot -BootstrapDir $bootstrapDir -FeatureRef $activeFeatureRef
    }
    $preBoundaryWorkshop = $preBoundaryWorkshopCandidate -and (-not $workshopComplete)

    # #3 RAW SPEC KIT - a CHEAP raw-text scan of the recent tail (NO per-line JSON parse). NEGATION GUARD: skip a
    # match whose preceding context is a prohibition / quote (the contract's OWN "do NOT run the raw `specify.exe
    # workflow`" prose) so it does not false-fire (dogfood + 145 fix-followup). Also suppressed in-workshop below.
    $rawHit = $false
    $rawTail = ''
    if (-not [string]::IsNullOrWhiteSpace($transcriptPathArg) -and (Test-Path -LiteralPath $transcriptPathArg -PathType Leaf)) {
        try {
            $rawTail = (@(Get-Content -LiteralPath $transcriptPathArg -Tail 40 -Encoding UTF8 -ErrorAction Stop) -join "`n")
            foreach ($mm in ([regex]::new('(?i)\bspecify(?:\.exe)?\s+workflow\b')).Matches($rawTail)) {
                $pre = $rawTail.Substring([Math]::Max(0, $mm.Index - 24), [Math]::Min(24, $mm.Index))
                if ($pre.Contains([char]96) -or ($pre -match '(?i)\b(not|never|raw|un|forbidden|avoid|don)\b')) { continue }  # prohibition/quote prose, not an invocation
                $rawHit = $true; break
            }
        }
        catch { $null = $_ }
    }

    # Material-work lane (Proposal 145 follow-up): the old length-only "substantial" trigger over-blocked normal
    # discussion, so use the deterministic rolling-handover signal written by the preceding Stop provider instead.
    $materialStop = ($null -ne $materialSignal -and [bool]$materialSignal.material)
    $blockStatePath = Join-Path $projectRoot '.specrew/runtime/conformance-stop-block.json'
    $materialSatisfiedPath = Join-Path $projectRoot '.specrew/runtime/conformance-material-satisfied.json'
    $existingBlockRecord = Get-SpecrewBlockRecord -Path $blockStatePath
    $materialRetryKey = Get-SpecrewRecentMaterialRetryKey -Record $existingBlockRecord
    $materialSatisfiedKey = Get-SpecrewMaterialSatisfiedKey -Path $materialSatisfiedPath
    if ($preBoundaryWorkshop) {
        # Feature scaffolding during initial lens intake is workshop material, not a within-phase hand-back.
        $materialStop = $false
        $materialRetryKey = $null
    }

    # (IDEMPOTENCY check is performed BELOW - after the role-aware last-assistant message + the workshop/marker state
    # are computed - so the fire-identity captures the FULL decision-relevant state. An EARLY tail-40 identity falsely
    # deduped a genuine second boundary stop when the distinguishing message fell outside tail-40, or across a
    # workshop-completion flip; 145 IDEMP-1 / SC-1.)

    # --- WORKSHOP EXCLUSION (FR-015): the design workshop's per-lens questions are the ONLY exclusion from the
    # every-stop packet rule. The lens workshop CONTINUES after create-new-feature.ps1 scaffolds spec.md, so the old
    # pre-spec proxy false-blocked a lens question once spec.md existed (dogfood). Detect the workshop ROBUSTLY (the
    # reused Get-SpecrewWorkshopProgress: a confirmed lens agenda with lenses still remaining) and, while in it,
    # SUPPRESS every signal (no block, no #1, no #3). ---
    $inWorkshop = $false
    if ($hasPending -or $anySpec -or $rawHit -or $materialStop) {
        if ([string]::IsNullOrWhiteSpace($bootstrapDir)) { $bootstrapDir = Resolve-SpecrewBootstrapDir -ProjectRoot $projectRoot }
        $inWorkshop = Test-SpecrewWorkshopInProgress -ProjectRoot $projectRoot -BootstrapDir $bootstrapDir -FeatureRef $activeFeatureRef
    }
    if ($inWorkshop) { $rawHit = $false }  # a workshop lens question owes no packet and is not a raw-Spec-Kit deviation.

    # --- EXPENSIVE transcript parse ONLY when a packet-owed trigger is structurally possible AND not in-workshop
    # (PERF: the per-line ConvertFrom-Json parse is the dominant Stop-hook cost and scales with session size; a
    # no-trigger / in-workshop stop skips it entirely). ---
    $lastAssistantText = $null; $intakeHit = $false; $ccLoaded = $false; $markerForPendingCrossing = $false
    $pendingCrossing = $null
    if ($hasPending -and (Get-Command Get-SpecrewPendingBoundaryCrossing -ErrorAction SilentlyContinue)) {
        try { $pendingCrossing = Get-SpecrewPendingBoundaryCrossing -LastAuthorizedBoundary ([string]$pending.LastAuthorizedBoundary) -WorkingBoundary ([string]$pending.WorkingBoundary) } catch { $pendingCrossing = $null }
    }
    if (($hasPending -or $anySpec -or $materialStop -or -not [string]::IsNullOrWhiteSpace($materialRetryKey)) -and (-not $inWorkshop)) {
        if ([string]::IsNullOrWhiteSpace($bootstrapDir)) { $bootstrapDir = Resolve-SpecrewBootstrapDir -ProjectRoot $projectRoot }
        if (-not [string]::IsNullOrWhiteSpace($bootstrapDir)) {
            $cc = Join-Path $bootstrapDir 'ConversationCaptureAccessor.ps1'
            if (Test-Path -LiteralPath $cc -PathType Leaf) { try { . $cc; $ccLoaded = $true } catch { $null = $_ } }
        }
        if ($ccLoaded -and -not [string]::IsNullOrWhiteSpace($transcriptPathArg) -and (Test-Path -LiteralPath $transcriptPathArg -PathType Leaf) -and
            (Get-Command Get-SpecrewConversationTurnFromLine -ErrorAction SilentlyContinue)) {
            try {
                $tail = @(Get-Content -LiteralPath $transcriptPathArg -Tail 200 -Encoding UTF8 -ErrorAction Stop)
                for ($k = $tail.Count - 1; $k -ge 0; $k--) {
                    $turn = Get-SpecrewConversationTurnFromLine -Line $tail[$k]
                    if ($null -ne $turn -and [string]$turn.role -eq 'assistant' -and -not [string]::IsNullOrWhiteSpace([string]$turn.text)) { $lastAssistantText = [string]$turn.text; break }
                }
            }
            catch { $lastAssistantText = $null }
        }
        # #1 intake question (needs the role-aware last assistant text + a spec on disk).
        if ($anySpec -and -not [string]::IsNullOrWhiteSpace($lastAssistantText)) {
            $intakeRx = [regex]::new('(?i)\bwhat\b[^.?!]{0,60}\b(?:do you want|would you like|are you looking|should we|are we|can i help you)\b[^.?!]{0,40}\b(?:build|create|make|work on)\b|(?i)\bwhat\b[^.?!]{0,40}\b(?:feature|app|project|product)\b[^.?!]{0,40}\b(?:build|create|want|like)\b|(?i)\bwhat (?:do you want|would you like) to build\b')
            if ($intakeRx.IsMatch($lastAssistantText)) { $intakeHit = $true }
        }
        # BOUNDARY VERDICT MARKER (Antigravity dogfood gap): at a boundary the six-section HEADERS alone do NOT
        # authorize the crossing - the <!-- SPECREW-VERDICT-BOUNDARY --> marker is what captures the verdict. A weak
        # host rendered the headers but NOT the marker, so the verdict was never captured (last_authorized stayed
        # none) yet the header check suppressed the block. So at a boundary, suppress ONLY when the marker for the
        # PENDING crossing is present; headers without that marker still block.
        if ($hasPending -and $ccLoaded -and (Get-Command Get-SpecrewCapturedBoundaryPacket -ErrorAction SilentlyContinue)) {
            try {
                $pkt = Get-SpecrewCapturedBoundaryPacket -TranscriptPath $transcriptPathArg
                if ($null -ne $pkt -and [bool]$pkt.Found -and $null -ne $pendingCrossing -and [bool]$pendingCrossing.HasPendingVerdict) {
                    $pktFrom = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pkt.FromBoundary)
                    $pktTo = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pkt.ToBoundary)
                    $expectedFrom = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pendingCrossing.PendingFromMarkerBoundary)
                    $expectedTo = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pendingCrossing.PendingToMarkerBoundary)
                    if (-not [string]::IsNullOrWhiteSpace($pktTo) -and $pktFrom -eq $expectedFrom -and $pktTo -eq $expectedTo) { $markerForPendingCrossing = $true }
                }
            }
            catch { $null = $_ }
        }
    }
    $packetPresent = Test-SpecrewReentryPacketPresent -Text $lastAssistantText
    # ISSUE-2 PERF REVERT: the flush/read-race RE-READ (4x tail-200 parse, ~17s on a large transcript) is REMOVED.
    # It was an UNCONFIRMED mitigation (the instrumented false-negative never reproduced) and it taxed every
    # material stop AND starved the navigator (order 50) of the shared 20s Stop budget, so co-review stopped firing.
    # If the flush-race double-render ever reproduces WITH a captured dx_ record, re-add a CHEAP variant (a tiny
    # last-line re-read, not a full 200-line parse). The dx_* journal keeps the decision observable in the meantime.
    $substantial = (-not [string]::IsNullOrWhiteSpace($lastAssistantText)) -and ($lastAssistantText.Length -ge $script:SpecrewSubstantialChars)

    # --- IDEMPOTENCY (duplicate-fire guard, 145 IDEMP-1 / SC-1): dedup a re-fired hook for the SAME observable DECISION
    # state, processed ONCE. The identity uses the ROLE-AWARE last-assistant message (the SAME view the block decision
    # reads - NOT a coarse tail-40 that collides when the distinguishing message is >40 entries back) PLUS the boundary
    # cursor and the marker / workshop / pending discriminators - so two genuinely-different stops, or a
    # workshop-completion flip, get DIFFERENT identities and are NOT falsely deduped (the dangerous missed-enforcement
    # direction). Computed AFTER those signals exist. Best-effort + fail-open: a read/write miss just disables dedup,
    # never blocks the stop. The force-continue loop is unaffected (each forced re-render is a NEW message).
    $idWorking = if ($null -ne $pending) { [string]$pending.WorkingBoundary } else { '' }
    $idAuth = if ($null -ne $pending) { [string]$pending.LastAuthorizedBoundary } else { '' }
    $fireIdentity = Get-SpecrewFireIdentity -Parts @([string]$lastAssistantText, $idWorking, $idAuth, ("m={0}" -f [int][bool]$markerForPendingCrossing), ("w={0}" -f [int][bool]$inWorkshop), ("pbw={0}" -f [int][bool]$preBoundaryWorkshop), ("p={0}" -f [int][bool]$hasPending), ("mat={0}" -f [string]$materialSignal.key), ("mr={0}" -f [string]$materialRetryKey), [string]$sourceEventArg)
    $lastFirePath = Join-Path $projectRoot '.specrew/runtime/conformance-last-fire.json'
    if (-not [string]::IsNullOrWhiteSpace($fireIdentity)) {
        try {
            if (Test-Path -LiteralPath $lastFirePath -PathType Leaf) {
                $lf = Get-Content -LiteralPath $lastFirePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                if (($lf.PSObject.Properties.Name -contains 'identity') -and ([string]$lf.identity -eq $fireIdentity) -and ($lf.PSObject.Properties.Name -contains 'epoch')) {
                    $age = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - [long]$lf.epoch
                    if ($age -ge 0 -and $age -le $script:SpecrewFireDedupWindowSec) { return }  # duplicate fire -> idempotent no-op
                }
            }
        }
        catch { $null = $_ }
        try {
            $rdir = Split-Path -Parent $lastFirePath
            if ($rdir -and -not (Test-Path -LiteralPath $rdir)) { New-Item -ItemType Directory -Path $rdir -Force | Out-Null }
            ([pscustomobject]@{ identity = $fireIdentity; epoch = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $lastFirePath -Encoding UTF8
        }
        catch { $null = $_ }
    }

    # --- block decision: does this stop owe the packet, and is the packet absent? ---
    # BOUNDARY stops (HasPendingVerdict) owe the packet regardless of the workshop proxy - a pending verdict means a
    # boundary was already crossed, so we are inherently PAST intake. The SUBSTANTIAL non-boundary trigger is gated on
    # a spec existing ($anySpec = past intake), which excludes the pre-spec design-workshop window; the design-analysis
    # lens workshop AFTER spec.md is a documented residual (dogfood-tunable).
    # FIX C (145 F1-CC-FAIL-CLOSED): only block when we ACTUALLY READ the last assistant message - we cannot claim
    # "the packet is absent" without reading it. If ConversationCaptureAccessor did not load (stale install) or there
    # is no transcript, $lastAssistantText is null -> do NOT block (fail-open, matching the Get-SpecrewPendingVerdictState
    # fail-open; never block a correctly-rendered packet we simply could not see, and never go fail-CLOSED on a missing
    # component). This is the same failure-class -> same direction (allow) as the boundary-trigger load failure above.
    $canAssess = -not [string]::IsNullOrWhiteSpace($lastAssistantText)
    # BOUNDARY stop: owes the verdict MARKER (not just the six headers) - the marker is what captures the verdict;
    #   headers WITHOUT it leave the gate un-authorized (the Antigravity dogfood: a packet rendered, no marker,
    #   last_authorized stayed `none`). $markerForPendingCrossing also subsumes the old false-positive guard (a
    #   captured marker for THIS crossing = a legitimate awaiting-verdict stop, 145 TI-2/F1).
    # NON-BOUNDARY material hand-back: the packet headers suffice (a within-phase stop has no verdict marker).
    # FIX C (145 F1-CC): $canAssess gates both - we never claim "absent" without reading the message (fail-open).
    # Hard-block ONLY genuine DECISION-YIELD stops = a BOUNDARY (pending verdict + missing marker). The earlier
    # "substantial" (>=600-char) non-boundary trigger was DROPPED (maintainer 2026-06-21): a long but communicative
    # DISCUSSION / status answer is not a decision-yield and must not be force-blocked into a packet. The replacement
    # hard block is deterministic material work only: the current Stop handover reports changed user files or new
    # commits. Once a packet has been rendered for the same material surface, later quick discussion while the tree
    # stays dirty is allowed; a changed material surface requires a fresh packet.
    $boundaryBlock = $hasPending -and (-not $markerForPendingCrossing)
    $materialAlreadySatisfied = $materialStop -and (-not [string]::IsNullOrWhiteSpace([string]$materialSignal.key)) -and ([string]$materialSignal.key -eq [string]$materialSatisfiedKey)
    $materialInitialBlock = (-not $hasPending) -and $materialStop -and (-not $packetPresent) -and (-not $materialAlreadySatisfied)
    $materialRetryBlock = (-not $hasPending) -and (-not [string]::IsNullOrWhiteSpace($materialRetryKey)) -and (-not $packetPresent)
    $materialBlock = $materialInitialBlock -or $materialRetryBlock
    $blockKind = if ($boundaryBlock) { 'boundary' } elseif ($materialBlock) { 'material' } else { 'none' }
    $blockWarranted = $canAssess -and ($blockKind -ne 'none')

    $journalPath = Join-Path $projectRoot '.specrew/runtime/conformance-journal.jsonl'
    $blockReason = $null
    $corrections = New-Object System.Collections.Generic.List[string]
    $capped = $false
    $cappedKind = $null
    # The advance identity the consecutive-block cap keys on: a boundary advance is working|lastAuth; a material
    # non-boundary stop is keyed by the current handover snapshot. A NEW advance/snapshot starts a fresh count; the agent
    # rendering the packet (not blockWarranted) resets it. No time window (145 HANG-1).
    # The if-guard also protects the $pending null-deref under the leaked StrictMode; the else value is an unused
    # placeholder ($advanceKey is read only inside the blockWarranted branch, which implies $hasPending; 145 SC-3).
    $advanceKey = if ($blockKind -eq 'boundary' -and $hasPending) {
        ("{0}|{1}" -f [string]$pending.WorkingBoundary, [string]$pending.LastAuthorizedBoundary)
    }
    elseif ($blockKind -eq 'material' -and $materialInitialBlock -and -not [string]::IsNullOrWhiteSpace([string]$materialSignal.key)) {
        [string]$materialSignal.key
    }
    elseif ($blockKind -eq 'material' -and -not [string]::IsNullOrWhiteSpace($materialRetryKey)) {
        [string]$materialRetryKey
    }
    else { 'na' }

    if ($blockWarranted) {
        $count = Get-SpecrewBlockCount -Path $blockStatePath -Key $advanceKey
        if ($count -ge $script:SpecrewBlockCap) {
            # Over the consecutive-block cap - stop blocking to avoid a hang; degrade to a plain nudge this turn.
            $capped = $true
            $cappedKind = $blockKind
            $capSubject = if ($blockKind -eq 'material') { 'material-work packet' } else { 'verdict marker' }
            [Console]::Error.WriteLine(("[specrew-conformance] WARN STOP_BLOCK_CAP {0} still absent or wrong after {1} consecutive blocks; releasing the stop (degrading to a nudge) to avoid a hang." -f $capSubject, $count))
        }
        elseif (Set-SpecrewBlockCount -Path $blockStatePath -Key $advanceKey -Count ($count + 1)) {
            # Block ONLY when the increment durably persisted (145 HANG-2): a host without a built-in cap relies on
            # this counter, so an unverifiable write must NOT start an uncappable loop.
            # Build the packet directive. At a boundary, include the CONTIGUOUS last_authorized -> successor marker.
            $sb = New-Object System.Text.StringBuilder
            if ($blockKind -eq 'boundary') {
                [void]$sb.AppendLine('Specrew: boundary state is pending, but your last message did not expose the verdict marker for the pending boundary crossing. Render the full six-section re-entry packet NOW as your message, then stop again:')
                [void]$sb.AppendLine('## What I Just Did / ## Why I Stopped / ## What Needs Your Review / ## What Happens Next / ## Discussion Prompts / ## What I Need From You')
                [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
                $fromBoundary = if ($null -ne $pendingCrossing -and [bool]$pendingCrossing.HasPendingVerdict) { [string]$pendingCrossing.PendingFromMarkerBoundary } else { $null }
                $toBoundary = if ($null -ne $pendingCrossing -and [bool]$pendingCrossing.HasPendingVerdict) { [string]$pendingCrossing.PendingToMarkerBoundary } else { [string]$pending.WorkingBoundary }
                [void]$sb.AppendLine('')
                [void]$sb.AppendLine([string]$pending.Message)
                if (-not [string]::IsNullOrWhiteSpace($fromBoundary)) {
                    [void]$sb.AppendLine(("This is a BOUNDARY stop ({0} -> {1}); emit the verdict marker as the LAST line: <!-- SPECREW-VERDICT-BOUNDARY: {0} -> {1} -->" -f $fromBoundary, $toBoundary))
                }
                else {
                    [void]$sb.AppendLine(("This is a BOUNDARY stop into '{0}' (the first unauthorized boundary); emit the contiguous verdict marker as the LAST line." -f $toBoundary))
                }
                [void]$sb.AppendLine('Do NOT record the authorization yourself; the verdict is captured from your rendered packet + the human''s reply.')
            }
            elseif ($blockKind -eq 'material') {
                [void]$sb.AppendLine('Specrew: this Stop followed material work, but your last message did not render the required non-boundary context packet. Render the five-part context packet NOW as your message, then stop again:')
                [void]$sb.AppendLine('## What I Just Did / ## Why I Stopped / ## What Needs Your Review / ## What Happens Next / ## What I Need From You')
                [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
                [void]$sb.AppendLine('This is a NON-BOUNDARY material-work stop; do NOT emit a SPECREW-VERDICT-BOUNDARY marker.')
            }
            if ($intakeHit) { [void]$sb.AppendLine('Also: an active feature already exists - do NOT ask what to build; continue it.') }
            if ($rawHit) { [void]$sb.AppendLine('Also: do NOT run the raw `specify workflow` SDD engine - route through the governed Specrew flow.') }
            $blockReason = $sb.ToString().TrimEnd()
        }
        else {
            # The counter increment could not be persisted/verified -> the cap cannot be guaranteed on a capless
            # host -> do NOT block (fail-open, 145 HANG-2). A hang with no diagnostic is the worst outcome, so WARN.
            [Console]::Error.WriteLine('[specrew-conformance] WARN STOP_BLOCK_COUNTER_UNWRITABLE cannot persist the loop-guard counter; releasing the stop (no block) to stay fail-open.')
        }
    }
    else {
        # Packet present, or nothing owed -> the agent complied; clear the loop-guard counter.
        if ($materialStop -and $packetPresent -and -not [string]::IsNullOrWhiteSpace([string]$materialSignal.key)) {
            Set-SpecrewMaterialSatisfiedKey -Path $materialSatisfiedPath -Key ([string]$materialSignal.key)
        }
        Reset-SpecrewBlockCount -Path $blockStatePath
    }

    # If not blocking (not warranted, or capped), surface the cooperative nudges instead.
    if ([string]::IsNullOrWhiteSpace($blockReason)) {
        if ($capped) {
            if ($cappedKind -eq 'material') {
                $corrections.Add('[specrew-conformance] MATERIAL-WORK STOP packet still missing (FR-015) - render the five-part context packet with file:/// references before handing control back.') | Out-Null
            }
            else {
                $corrections.Add('[specrew-conformance] BOUNDARY VERDICT MARKER still missing or wrong (FR-011/FR-015) - render the six-section packet and emit the exact pending-crossing SPECREW-VERDICT-BOUNDARY marker so the human verdict can be captured.') | Out-Null
            }
        }
        if ($intakeHit) { $corrections.Add(("[specrew-conformance] INTAKE QUESTION while an active feature exists (FR-011 #1)`n`nYou asked the human what to build, but a feature is already in flight (spec exists at {0}). Do NOT restart intake - read it and continue the active feature." -f $specPath)) | Out-Null }
        if ($rawHit) { $corrections.Add("[specrew-conformance] RAW SPEC KIT invocation detected (FR-011 #3)`n`nDo NOT run the un-governed 'specify workflow' automation - route through the Specrew design workshop and the governed /speckit.* commands so the gates are honored.") | Out-Null }
    }

    # --- forensic journal (diagnostics only - never gate state) ---
    # Also record EVERY material stop (not only blocks) so a spurious material block is diagnosable against the
    # passing case (D-197-I009 conformance false-negative: a valid packet on disk still evaluated packetPresent=false).
    if (-not [string]::IsNullOrWhiteSpace($blockReason) -or $capped -or $intakeHit -or $rawHit -or $materialStop) {
        try {
            $jdir = Split-Path -Parent $journalPath
            if ($jdir -and -not (Test-Path -LiteralPath $jdir)) { New-Item -ItemType Directory -Path $jdir -Force | Out-Null }
            $evt = if (-not [string]::IsNullOrWhiteSpace($blockReason)) { 'stop-block' } elseif ($capped) { 'stop-block-capped' } elseif ($intakeHit -or $rawHit) { 'nudge' } else { 'observe' }
            $jWorking = if ($null -ne $pending) { [string]$pending.WorkingBoundary } else { '' }
            $jAuth = if ($null -ne $pending) { [string]$pending.LastAuthorizedBoundary } else { '' }
            # dx_* = the actual inputs to the packetPresent decision, so a wrong block is no longer silent.
            $diagLat = [string]$lastAssistantText
            $diagHits = 0; foreach ($dh in $script:SpecrewReentryHeaders) { if (-not [string]::IsNullOrEmpty($diagLat) -and $diagLat -match [regex]::Escape($dh)) { $diagHits++ } }
            # NO content snippet is recorded: dx_lat_len + dx_lat_hits diagnose a false-negative (hits<4 = the
            # packet was not seen; len distinguishes a short stale message from the long packet) WITHOUT writing
            # any conversation text to the (local, git-ignored) journal. Maintainer privacy call 2026-06-28.
            $rec = [pscustomobject]@{ event = $evt; recorded_at = (Get-Date).ToUniversalTime().ToString('o'); has_pending = $hasPending; working = $jWorking; last_authorized = $jAuth; substantial = $substantial; material = $materialStop; block_kind = $blockKind; intake = $intakeHit; raw = $rawHit; host = $hostKindArg; source = $sourceEventArg; dx_transcript_arg = (-not [string]::IsNullOrWhiteSpace($transcriptPathArg)); dx_transcript_exists = ((-not [string]::IsNullOrWhiteSpace($transcriptPathArg)) -and (Test-Path -LiteralPath $transcriptPathArg -PathType Leaf)); dx_cc_loaded = $ccLoaded; dx_lat_len = $diagLat.Length; dx_lat_hits = $diagHits; dx_packet_present = $packetPresent; dx_material_retry = (-not [string]::IsNullOrWhiteSpace($materialRetryKey)) }
            ($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $journalPath -Encoding UTF8
        }
        catch { $null = $_ }
    }

    # --- emit: a block sentinel (the dispatcher force-continues), else the plain inject nudges, else nothing ---
    if (-not [string]::IsNullOrWhiteSpace($blockReason)) {
        Write-Output ("<<<SPECREW-STOP-BLOCK>>>`n" + $blockReason)
    }
    elseif ($corrections.Count -gt 0) {
        Write-Output ($corrections.ToArray() -join "`n`n")
    }
    return
}
catch {
    [Console]::Error.WriteLine("[specrew-conformance] WARN CONFORMANCE_PROVIDER_FAILED $($_.Exception.Message)")
    return
}
