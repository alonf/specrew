# Feature 185 FR-011 / FR-015 - the conformance Stop-provider (DETECTION logic).
#
# This is a CONSUMER of the EXISTING hook dispatcher + provider catalog (refocus-scopes.json), registered
# as kind=inject events=[Stop] order=40 - it runs AFTER the handover provider (order 30) has done the
# verdict capture (which advances last_authorized_boundary via the authorization writer on a captured marker).
# It is an isolated script the dispatcher invokes; it does NOT edit HandoverStore.ps1 and NEVER calls the
# verdict-authority write path - it is a strictly READ-ONLY consumer of the gate STATE, so it physically
# cannot break what keeps the lifecycle honest. Its only write is a best-effort forensic journal
# (.specrew/runtime/conformance-journal.jsonl), which is diagnostics, never gate state.
#
# ARG CONTRACT: the dispatcher invokes inject providers with DOUBLE-dash flags (--host-kind, --source-event,
# --transcript-path) via ProcessStartInfo.ArgumentList. PowerShell's single-dash `param()` binding REJECTS
# a `--flag` token (it reads as `-flag`), so a `param()`/[CmdletBinding()] block makes the script exit 1 at
# the binding boundary BEFORE its body runs - a per-stop PROVIDER_FAILED WARN, not a no-op. So parse $args
# MANUALLY, the in-repo convention the handover provider uses (specrew-handover-provider.ps1:50-58). NO param().
#
# WHAT IT DETECTS (the three #2884-era deviations + the FR-015 every-stop packet discipline at the boundary
# frontier; the within-phase-checkpoint half of FR-015 stays COOPERATIVE in general.md rule 9, already shipped):
#   #2 SILENT BOUNDARY ADVANCE (the #2884 headline + FR-015 frontier): the WORKING boundary is ahead of the
#      last HUMAN-authorized boundary with NO verdict captured. Detected by REUSING the canonical
#      Get-SpecrewPendingVerdictState (the same committed-!=-authorized truth the resume + `specrew where`
#      surface) - NOT a second, drift-prone boundary-from-artifacts inference (FR-008 reuse; the advisor's
#      "a parallel inference engine is itself a #2884-class bug" warning). FALSE-POSITIVE GUARD: if the agent
#      rendered a boundary verdict PACKET this turn (Get-SpecrewCapturedBoundaryPacket Found) it is a
#      legitimate awaiting-verdict / human-in-the-loop stop -> no nudge (and an APPROVED marker already
#      advanced the cursor at order 30, so the pending condition is false anyway). Multi-boundary-in-one-turn
#      is out of the strict one-at-a-time scope; the packet guard suppresses its false positive.
#   #1 INTAKE QUESTION while an active feature exists: the last assistant turn asks the human "what to build"
#      though a spec.md is already on disk -> redirect to continue the active feature.
#   #3 RAW SPEC KIT: a raw `specify[.exe] workflow` SDD-engine invocation this turn -> redirect to the governed flow.
#
# DETECTION-SCOPE CEILING (honest; 145 CH-1): #2 fires on an advance recorded in STATE - the WORKING cursor
# (session_state.boundary_type, moved ahead by the sync path) is ahead of last_authorized_boundary with no
# captured verdict. An artifact HAND-WRITTEN without advancing the working cursor (never running sync) leaves
# working == authorized -> no fire; that residual is covered by the cooperative layer + the resume re-anchor,
# NOT this lever. A from-artifacts inference engine was deliberately rejected as itself #2884-class (FR-008).
# DELIVERY CEILING (honest, per drift-log D-003): the deterministic ENFORCEMENT is the STATE - the cursor does
# not advance without a captured marker, and the resume surfaces "AWAITING YOUR VERDICT". This provider's
# stdout correction is a best-effort per-turn ACCELERATOR; its model-delivery on a Stop hook is host-variable
# (on Claude plain Stop stdout is user-visible; reliable model-injection would need the decision:block channel,
# a broader dispatcher change the split-guard watches - deferred to the cross-host dogfood, NOT built here).
# Fully FAIL-OPEN: any error degrades to no-correction and NEVER blocks the stop. Empty stdout = silent no-op.

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }  # best-effort UTF-8 (child half of the dispatcher's encoding contract)

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
        # Not a governed project root (or run outside one) - nothing to check.
        return
    }
    # Only run on an end-of-turn Stop-class event (the registration already gates this; defensive).
    if (-not [string]::IsNullOrWhiteSpace($sourceEventArg) -and ($sourceEventArg.ToLowerInvariant() -notin @('stop', 'agentstop'))) {
        return
    }

    # --- component resolution (fail-open: if a component cannot load, that detection lane simply skips) ---
    # shared-governance.ps1 ships BESIDE this provider (extensions/.specify both) - gives the canonical
    # Get-SpecrewPendingVerdictState + boundary-order helpers, reused so there is no parallel inference engine.
    $sgBeside = Join-Path $PSScriptRoot 'shared-governance.ps1'
    if (Test-Path -LiteralPath $sgBeside -PathType Leaf) { try { . $sgBeside } catch { $null = $_ } }
    # ConversationCaptureAccessor.ps1 lives under scripts/internal/bootstrap (self-host tree) or the installed
    # module - gives Get-SpecrewCapturedBoundaryPacket (the false-positive guard) + Get-SpecrewConversationTurnFromLine.
    $ccCandidates = New-Object System.Collections.Generic.List[string]
    $ccCandidates.Add((Join-Path $projectRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')) | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH)) {
        $ccCandidates.Add((Join-Path $env:SPECREW_MODULE_PATH 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')) | Out-Null
    }
    $ccLoaded = $false
    foreach ($cc in $ccCandidates) {
        if (Test-Path -LiteralPath $cc -PathType Leaf) { try { . $cc; $ccLoaded = $true; break } catch { $null = $_ } }
    }
    if (-not $ccLoaded) {
        try {
            $mod = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.ModuleBase 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1') } |
                Select-Object -First 1
            if ($mod) { . (Join-Path $mod.ModuleBase 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1'); $ccLoaded = $true }
        }
        catch { $null = $_ }
    }

    $corrections = New-Object System.Collections.Generic.List[string]

    # ============================================================================================
    # Deviation #2 (#2884 headline) + FR-015 boundary-frontier: SILENT BOUNDARY ADVANCE
    # ============================================================================================
    if (Get-Command Get-SpecrewPendingVerdictState -ErrorAction SilentlyContinue) {
        $pending = $null
        try { $pending = Get-SpecrewPendingVerdictState -ProjectRoot $projectRoot } catch { $pending = $null }
        if ($null -ne $pending -and [bool]$pending.HasPendingVerdict) {
            $working = [string]$pending.WorkingBoundary
            $lastAuth = [string]$pending.LastAuthorizedBoundary

            # FALSE-POSITIVE GUARD: a verdict packet rendered THIS turn FOR THE PENDING boundary = the agent IS
            # surfacing this exact crossing for the human (a legitimate awaiting-verdict stop) -> no nudge. Match
            # the packet's TO boundary to the WORKING boundary: Get-SpecrewCapturedBoundaryPacket returns the LAST
            # marker ANYWHERE in the 500-line tail, so a STALE / unrelated packet (a different, already-consumed
            # crossing) must NOT suppress a genuine NEW silent advance (145 TI-2/F1). Both sides are normalized.
            $packetRendered = $false
            if ($ccLoaded -and -not [string]::IsNullOrWhiteSpace($transcriptPathArg) -and
                (Get-Command Get-SpecrewCapturedBoundaryPacket -ErrorAction SilentlyContinue)) {
                try {
                    $pkt = Get-SpecrewCapturedBoundaryPacket -TranscriptPath $transcriptPathArg
                    if ($null -ne $pkt -and [bool]$pkt.Found) {
                        $pktTo = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pkt.ToBoundary)
                        $workNorm = Normalize-SpecrewCanonicalBoundaryType -Boundary $working
                        if (-not [string]::IsNullOrWhiteSpace($pktTo) -and $pktTo -eq $workNorm) { $packetRendered = $true }
                    }
                }
                catch { $null = $_ }
            }
            if (-not $packetRendered) {
                # The CONTIGUOUS one-boundary-at-a-time crossing the cursor can authorize NEXT: last_authorized ->
                # its successor (NOT predecessor(working) -> working, which on a multi-gate gap names a LATER
                # crossing the order-30 capture refuses as MARKER_CURSOR_MISMATCH - 145 F2). On a single-gap advance
                # the two collapse to the same crossing. A non-canonical / absent from-boundary (no verdict recorded
                # yet - the first gate) suppresses the explicit marker template (its <a-z-> -> <a-z-> grammar cannot
                # carry a non-canonical token - 145 F7c); the prose still names the crossing to render.
                $fromBoundary = $null
                $toBoundary = $working
                try {
                    if (Get-Command Get-SpecrewBoundaryOrder -ErrorAction SilentlyContinue) {
                        $order = @(Get-SpecrewBoundaryOrder)
                        $authIdx = if ([string]::IsNullOrWhiteSpace($lastAuth)) { -1 } else { [Array]::IndexOf($order, (Normalize-SpecrewCanonicalBoundaryType -Boundary $lastAuth)) }
                        if (($authIdx + 1) -ge 0 -and ($authIdx + 1) -lt $order.Count) {
                            $toBoundary = $order[$authIdx + 1]
                            if ($authIdx -ge 0) { $fromBoundary = $order[$authIdx] }
                        }
                    }
                }
                catch { $null = $_ }

                # Fire-once per (working, lastAuth): re-nudge only on a NEW unauthorized advance, not every turn.
                $alreadyNudged = $false
                $journalKey = ("silent-advance|{0}|{1}" -f $working, $lastAuth)
                $journalPath = Join-Path $projectRoot '.specrew/runtime/conformance-journal.jsonl'
                try {
                    if (Test-Path -LiteralPath $journalPath -PathType Leaf) {
                        $lastLine = Get-Content -LiteralPath $journalPath -Tail 1 -Encoding UTF8 -ErrorAction Stop
                        if (-not [string]::IsNullOrWhiteSpace($lastLine)) {
                            $lastRec = $lastLine | ConvertFrom-Json -ErrorAction Stop
                            if (($lastRec.PSObject.Properties.Name -contains 'key') -and ([string]$lastRec.key -eq $journalKey)) { $alreadyNudged = $true }
                        }
                    }
                }
                catch { $null = $_ }

                if (-not $alreadyNudged) {
                    $crossingLabel = if (-not [string]::IsNullOrWhiteSpace($fromBoundary)) { ("{0} -> {1}" -f $fromBoundary, $toBoundary) } else { ("into '{0}' (the first unauthorized boundary)" -f $toBoundary) }
                    $msg = New-Object System.Text.StringBuilder
                    [void]$msg.AppendLine('[specrew-conformance] SILENT BOUNDARY ADVANCE detected (FR-011 #2 / FR-015)')
                    [void]$msg.AppendLine('')
                    [void]$msg.AppendLine([string]$pending.Message)
                    [void]$msg.AppendLine('')
                    [void]$msg.AppendLine(("STOP advancing the lifecycle. Render the FULL six-section human re-entry packet for the {0} crossing (What I Just Did / Why I Stopped / What Needs Your Review / What Happens Next / Discussion Prompts / What I Need From You), then emit the verdict marker as the LAST line:" -f $crossingLabel))
                    if (-not [string]::IsNullOrWhiteSpace($fromBoundary)) {
                        [void]$msg.AppendLine(("    <!-- SPECREW-VERDICT-BOUNDARY: {0} -> {1} -->" -f $fromBoundary, $toBoundary))
                    }
                    else {
                        [void]$msg.AppendLine(("    (emit the contiguous verdict marker for the first unauthorized crossing into '{0}' as the LAST line)" -f $toBoundary))
                    }
                    [void]$msg.Append('Wait for the human''s explicit verdict before producing any further next-phase artifact. Do NOT record the authorization yourself; the verdict is captured from your rendered packet + the human''s reply.')
                    $corrections.Add($msg.ToString()) | Out-Null

                    # Best-effort forensic journal (NOT gate state - never touches verdict_history / the cursor).
                    try {
                        $jdir = Split-Path -Parent $journalPath
                        if ($jdir -and -not (Test-Path -LiteralPath $jdir)) { New-Item -ItemType Directory -Path $jdir -Force | Out-Null }
                        $rec = [pscustomobject]@{ event = 'silent-advance-nudge'; key = $journalKey; recorded_at = (Get-Date).ToUniversalTime().ToString('o'); working = $working; last_authorized = $lastAuth; host = $hostKindArg; source = $sourceEventArg }
                        ($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $journalPath -Encoding UTF8
                    }
                    catch { $null = $_ }
                }
            }
        }
    }
    else {
        # F4 (145): the headline silent-advance detector going dark must be VISIBLE (the codebase's
        # degrade-to-silence-but-WARN doctrine), not an undetectable no-op indistinguishable from 'all clear'.
        # The gate STATE + the resume 'AWAITING YOUR VERDICT' surface remain the authority regardless.
        [Console]::Error.WriteLine('[specrew-conformance] WARN CONFORMANCE_DETECTOR_UNAVAILABLE shared-governance/Get-SpecrewPendingVerdictState did not load; the silent-advance lane is dark this stop (the gate STATE + resume surface remain the authority).')
    }

    # ============================================================================================
    # Deviations #1 (intake question while a feature exists) and #3 (raw Spec Kit) - this-turn transcript signals.
    # ============================================================================================
    if ($ccLoaded -and -not [string]::IsNullOrWhiteSpace($transcriptPathArg) -and
        (Test-Path -LiteralPath $transcriptPathArg -PathType Leaf) -and
        (Get-Command Get-SpecrewConversationTurnFromLine -ErrorAction SilentlyContinue)) {
        $lastAssistantText = $null
        try {
            $tail = @(Get-Content -LiteralPath $transcriptPathArg -Tail 200 -Encoding UTF8 -ErrorAction Stop)
            for ($k = $tail.Count - 1; $k -ge 0; $k--) {
                $turn = Get-SpecrewConversationTurnFromLine -Line $tail[$k]
                if ($null -ne $turn -and [string]$turn.role -eq 'assistant' -and -not [string]::IsNullOrWhiteSpace([string]$turn.text)) {
                    $lastAssistantText = [string]$turn.text; break
                }
            }
        }
        catch { $lastAssistantText = $null }

        if (-not [string]::IsNullOrWhiteSpace($lastAssistantText)) {
            # #1 - intake question. Realistic phrasings; require a question + an existing spec (active feature).
            $intakeRx = [regex]::new('(?i)\bwhat\b[^.?!]{0,60}\b(?:do you want|would you like|are you looking|should we|are we|can i help you)\b[^.?!]{0,40}\b(?:build|create|make|work on)\b|(?i)\bwhat\b[^.?!]{0,40}\b(?:feature|app|project|product)\b[^.?!]{0,40}\b(?:build|create|want|like)\b|(?i)\bwhat (?:do you want|would you like) to build\b')
            if ($intakeRx.IsMatch($lastAssistantText)) {
                $specExists = $false; $specPath = $null
                try {
                    $specs = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'specs') -Directory -ErrorAction Stop |
                        ForEach-Object { Join-Path $_.FullName 'spec.md' } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
                    if ($specs.Count -gt 0) { $specExists = $true; $specPath = $specs[0] }
                }
                catch { $specExists = $false }
                if ($specExists) {
                    $corrections.Add(("[specrew-conformance] INTAKE QUESTION while an active feature exists (FR-011 #1)`n`nYou asked the human what to build, but a feature is already in flight (spec exists at {0}). Do NOT restart intake or ask 'what do you want to build' - the spec answers that. Read it, then continue the active feature at its current lifecycle position." -f $specPath)) | Out-Null
                }
            }

            # #3 - raw Spec Kit SDD-engine invocation (the un-governed `specify[.exe] workflow`).
            $rawRx = [regex]::new('(?i)\bspecify(?:\.exe)?\s+workflow\b')
            if ($rawRx.IsMatch($lastAssistantText)) {
                $corrections.Add("[specrew-conformance] RAW SPEC KIT invocation detected (FR-011 #3)`n`nA raw Spec Kit SDD-engine invocation ('specify workflow') was used. Specrew governs the lifecycle; do NOT run the un-governed 'specify.exe workflow' automation - it bypasses the boundary gates. Route through the Specrew design workshop and the governed /speckit.* commands (or the governed lifecycle scripts) so the gates are honored.") | Out-Null
            }
        }
    }

    if ($corrections.Count -gt 0) {
        # The dispatcher captures stdout as this provider's injection fragment (order 40).
        Write-Output ($corrections.ToArray() -join "`n`n")
    }
    return
}
catch {
    [Console]::Error.WriteLine("[specrew-conformance] WARN CONFORMANCE_PROVIDER_FAILED $($_.Exception.Message)")
    return
}
