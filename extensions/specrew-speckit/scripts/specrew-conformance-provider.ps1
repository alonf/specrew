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
#   - SUBSTANTIAL non-boundary stop (post-intake): a long hand-back lacking the packet -> the within-phase
#     "proceed?" / checkpoint case the every-stop rule targets.
#   FALSE-POSITIVE GUARD: if the last assistant message already RENDERED the packet (>=4 of the 6 section headers,
#   or - at a boundary - a captured packet whose ToBoundary matches the working boundary) -> no block.
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
#   Esc-interrupted turn / headless exec (a real-host dogfood concern). (3) DETECTION SCOPE: the boundary trigger
#   fires on a STATE advance (working cursor moved via sync); an artifact hand-written without advancing the cursor
#   is the cooperative layer's residual. (4) the design-analysis lens workshop (after spec.md exists) is not
#   excluded by the pre-spec proxy - a known residual, dogfood-tunable. Fully FAIL-OPEN: any error / uncertainty
#   degrades to NO block (allow the stop) - blocking is the narrow exception, never the default.

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }  # best-effort UTF-8 (child half of the dispatcher's encoding contract)

$script:SpecrewReentryHeaders = @('What I Just Did', 'Why I Stopped', 'What Needs Your Review', 'What Happens Next', 'Discussion Prompts', 'What I Need From You')
$script:SpecrewBlockCap = 3
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

function Set-SpecrewBlockCount {
    # Persist the count for $Key and VERIFY it landed (read-back). Returns $true only when the increment is durably
    # readable - the caller blocks ONLY on $true, so a persistent / non-atomic write failure can never start an
    # uncappable block loop on a host without a built-in cap (145 HANG-2 fail-open).
    param([string]$Path, [string]$Key, [int]$Count)
    try {
        $dir = Split-Path -Parent $Path
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ([pscustomobject]@{ key = $Key; count = $Count } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $back = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (($back.PSObject.Properties.Name -contains 'count') -and ([int]$back.count -eq $Count) -and ($back.PSObject.Properties.Name -contains 'key') -and ([string]$back.key -eq $Key)) { return $true }
        }
    }
    catch { $null = $_ }
    return $false
}

function Reset-SpecrewBlockCount {
    param([string]$Path)
    try { if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue } }
    catch { $null = $_ }
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
    param([string]$ProjectRoot, [AllowNull()][string]$BootstrapDir)
    try {
        if ([string]::IsNullOrWhiteSpace($BootstrapDir)) { return $false }
        $pma = Join-Path $BootstrapDir 'ProjectMetadataAccessor.ps1'
        if (-not (Test-Path -LiteralPath $pma -PathType Leaf)) { return $false }
        try { . $pma } catch { return $false }
        if (-not (Get-Command Get-SpecrewWorkshopProgress -ErrorAction SilentlyContinue)) { return $false }
        $specsDir = Join-Path $ProjectRoot 'specs'
        if (-not (Test-Path -LiteralPath $specsDir -PathType Container)) { return $false }
        foreach ($d in (Get-ChildItem -LiteralPath $specsDir -Directory -ErrorAction Stop)) {
            $wp = $null
            try { $wp = Get-SpecrewWorkshopProgress -ProjectRoot $ProjectRoot -FeatureRef $d.Name } catch { $wp = $null }
            if ($null -ne $wp -and [bool]$wp.has_applicability -and (@($wp.remaining).Count -gt 0)) { return $true }
        }
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

    # #3 RAW SPEC KIT - a CHEAP raw-text scan of the recent tail (NO per-line JSON parse). NEGATION GUARD: skip a
    # match whose preceding context is a prohibition / quote (the contract's OWN "do NOT run the raw `specify.exe
    # workflow`" prose) so it does not false-fire (dogfood + 145 fix-followup). Also suppressed in-workshop below.
    $rawHit = $false
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

    # --- WORKSHOP EXCLUSION (FR-015): the design workshop's per-lens questions are the ONLY exclusion from the
    # every-stop packet rule. The lens workshop CONTINUES after create-new-feature.ps1 scaffolds spec.md, so the old
    # pre-spec proxy false-blocked a lens question once spec.md existed (dogfood). Detect the workshop ROBUSTLY (the
    # reused Get-SpecrewWorkshopProgress: a confirmed lens agenda with lenses still remaining) and, while in it,
    # SUPPRESS every signal (no block, no #1, no #3). ---
    $bootstrapDir = $null; $inWorkshop = $false
    if ($hasPending -or $anySpec -or $rawHit) {
        $bootstrapDir = Resolve-SpecrewBootstrapDir -ProjectRoot $projectRoot
        $inWorkshop = Test-SpecrewWorkshopInProgress -ProjectRoot $projectRoot -BootstrapDir $bootstrapDir
    }
    if ($inWorkshop) { $rawHit = $false }  # a workshop lens question owes no packet and is not a raw-Spec-Kit deviation.

    # --- EXPENSIVE transcript parse ONLY when a packet-owed trigger is structurally possible AND not in-workshop
    # (PERF: the per-line ConvertFrom-Json parse is the dominant Stop-hook cost and scales with session size; a
    # no-trigger / in-workshop stop skips it entirely). ---
    $lastAssistantText = $null; $intakeHit = $false; $ccLoaded = $false
    if (($hasPending -or $anySpec) -and (-not $inWorkshop)) {
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
    }
    $packetPresent = Test-SpecrewReentryPacketPresent -Text $lastAssistantText
    $substantial = (-not [string]::IsNullOrWhiteSpace($lastAssistantText)) -and ($lastAssistantText.Length -ge $script:SpecrewSubstantialChars)

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
    $blockWarranted = $canAssess -and (-not $packetPresent) -and ($hasPending -or ($anySpec -and $substantial))

    # Boundary false-positive guard: at a boundary, a captured packet whose ToBoundary matches the working boundary
    # is a legitimate awaiting-verdict stop (the agent surfaced THIS crossing) -> no block (145 TI-2/F1). (The
    # header-phrase $packetPresent check above already covers the non-boundary case.)
    if ($blockWarranted -and $hasPending -and $ccLoaded -and -not [string]::IsNullOrWhiteSpace($transcriptPathArg) -and
        (Get-Command Get-SpecrewCapturedBoundaryPacket -ErrorAction SilentlyContinue)) {
        try {
            $pkt = Get-SpecrewCapturedBoundaryPacket -TranscriptPath $transcriptPathArg
            if ($null -ne $pkt -and [bool]$pkt.Found) {
                $pktTo = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pkt.ToBoundary)
                $workNorm = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pending.WorkingBoundary)
                if (-not [string]::IsNullOrWhiteSpace($pktTo) -and $pktTo -eq $workNorm) { $blockWarranted = $false }
            }
        }
        catch { $null = $_ }
    }

    $blockStatePath = Join-Path $projectRoot '.specrew/runtime/conformance-stop-block.json'
    $journalPath = Join-Path $projectRoot '.specrew/runtime/conformance-journal.jsonl'
    $blockReason = $null
    $corrections = New-Object System.Collections.Generic.List[string]
    $capped = $false
    # The advance identity the consecutive-block cap keys on: a boundary advance is working|lastAuth; a non-boundary
    # substantial stop is the constant 'substantial'. A NEW advance (different key) starts a fresh count; the agent
    # rendering the packet (not blockWarranted) resets it. No time window (145 HANG-1).
    $advanceKey = if ($hasPending) { ("{0}|{1}" -f [string]$pending.WorkingBoundary, [string]$pending.LastAuthorizedBoundary) } else { 'substantial' }

    if ($blockWarranted) {
        $count = Get-SpecrewBlockCount -Path $blockStatePath -Key $advanceKey
        if ($count -ge $script:SpecrewBlockCap) {
            # Over the consecutive-block cap - stop blocking to avoid a hang; degrade to a plain nudge this turn.
            $capped = $true
            [Console]::Error.WriteLine(("[specrew-conformance] WARN STOP_BLOCK_CAP packet still absent after {0} consecutive blocks; releasing the stop (degrading to a nudge) to avoid a hang." -f $count))
        }
        elseif (Set-SpecrewBlockCount -Path $blockStatePath -Key $advanceKey -Count ($count + 1)) {
            # Block ONLY when the increment durably persisted (145 HANG-2): a host without a built-in cap relies on
            # this counter, so an unverifiable write must NOT start an uncappable loop.
            # Build the packet directive. At a boundary, include the CONTIGUOUS last_authorized -> successor marker.
            $sb = New-Object System.Text.StringBuilder
            [void]$sb.AppendLine('Specrew: you ended the turn without the six-section re-entry packet, so the human cannot see the situation or what they need to do. Render it NOW as your message, then stop again:')
            [void]$sb.AppendLine('## What I Just Did / ## Why I Stopped / ## What Needs Your Review / ## What Happens Next / ## Discussion Prompts / ## What I Need From You')
            [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
            if ($hasPending) {
                $working = [string]$pending.WorkingBoundary
                $lastAuth = [string]$pending.LastAuthorizedBoundary
                $fromBoundary = $null; $toBoundary = $working
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
        Reset-SpecrewBlockCount -Path $blockStatePath
    }

    # If not blocking (not warranted, or capped), surface the cooperative nudges instead.
    if ([string]::IsNullOrWhiteSpace($blockReason)) {
        if ($capped) {
            $corrections.Add('[specrew-conformance] RE-ENTRY PACKET still missing (FR-015) - render the six-section packet (What I Just Did / Why I Stopped / What Needs Your Review / What Happens Next / Discussion Prompts / What I Need From You) so the human knows the state and the next action.') | Out-Null
        }
        if ($intakeHit) { $corrections.Add(("[specrew-conformance] INTAKE QUESTION while an active feature exists (FR-011 #1)`n`nYou asked the human what to build, but a feature is already in flight (spec exists at {0}). Do NOT restart intake - read it and continue the active feature." -f $specPath)) | Out-Null }
        if ($rawHit) { $corrections.Add("[specrew-conformance] RAW SPEC KIT invocation detected (FR-011 #3)`n`nDo NOT run the un-governed 'specify workflow' automation - route through the Specrew design workshop and the governed /speckit.* commands so the gates are honored.") | Out-Null }
    }

    # --- forensic journal (diagnostics only - never gate state) ---
    if (-not [string]::IsNullOrWhiteSpace($blockReason) -or $capped -or $intakeHit -or $rawHit) {
        try {
            $jdir = Split-Path -Parent $journalPath
            if ($jdir -and -not (Test-Path -LiteralPath $jdir)) { New-Item -ItemType Directory -Path $jdir -Force | Out-Null }
            $evt = if (-not [string]::IsNullOrWhiteSpace($blockReason)) { 'stop-block' } elseif ($capped) { 'stop-block-capped' } else { 'nudge' }
            $jWorking = if ($null -ne $pending) { [string]$pending.WorkingBoundary } else { '' }
            $jAuth = if ($null -ne $pending) { [string]$pending.LastAuthorizedBoundary } else { '' }
            $rec = [pscustomobject]@{ event = $evt; recorded_at = (Get-Date).ToUniversalTime().ToString('o'); has_pending = $hasPending; working = $jWorking; last_authorized = $jAuth; substantial = $substantial; intake = $intakeHit; raw = $rawHit; host = $hostKindArg; source = $sourceEventArg }
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
