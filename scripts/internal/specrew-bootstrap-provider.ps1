# Specrew B2 bootstrap provider (Feature 174, FR-001/FR-002/FR-020).
# Registered as a provider row in refocus-scopes.json. The SpecrewHookDispatcher
# invokes this on SessionStart with `--event-json <json>` and injects its stdout.
# It fires on B2 ONLY (launch: source startup|resume|clear) and stays SILENT on B1
# (source compact) so F-171 B1 post-compaction behaviour is unchanged (FR-011).
# Fail-open doctrine (P1): any error -> no output, exit 0; never block a session.
#
#   --event-json <json>     the host SessionStart event (dispatcher contract)
#   --project-root <path>   optional override (testability); else resolve up to .specrew

$ErrorActionPreference = 'Stop'

# SPECREW-UTF8-OUTPUT (F-174 iter-10, Prop-145 P3): declare UTF-8 stdout/stderr so non-ASCII provider output -
# notably the handover content this provider INLINES into the SessionStart directive (Hebrew/emoji/unicode
# dialogue captured into 'Recent conversation') - is not mangled to '?' by the child pwsh's default OEM console
# codepage when the dispatcher captures it. The dispatcher reads UTF-8 (ProcessStartInfo.StandardOutputEncoding);
# this is the child half of that contract. Fail-open.
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }  # best-effort: a host that rejects UTF-8 console encoding must still run (fail-open)

function Get-BootstrapProjectRoot {
    $c = (Get-Location).Path
    while (-not [string]::IsNullOrWhiteSpace($c)) {
        if (Test-Path -LiteralPath (Join-Path $c '.specrew') -PathType Container) { return $c }
        $p = Split-Path -Parent $c
        if ($p -eq $c) { break }
        $c = $p
    }
    return (Get-Location).Path
}

function Get-SpecrewContractDeliveryMode {
    # T007/M1 (F-174 iter-10): the ONE seam deciding how the SessionStart launch contract reaches the agent -
    # 'inline' (the full body in the directive) or 'pointer' (the agent reads .specrew/last-start-prompt.md).
    # Default is BEHAVIOR-PRESERVING; flipping a host is a one-line change HERE.
    #   claude  -> pointer. DISPROVEN 2026-06-14 (iter-11 real-host, Claude Code v2.1.177): SessionStart IS plain
    #              STDOUT, but the host caps hook STDOUT at 10,000 chars too - an oversized payload is saved to a
    #              file and the model receives only a ~2KB preview + a file pointer. CONFIRMED live: the ~58KB
    #              inline-contract directive was dropped, the orientation banner never rendered. The earlier
    #              "stdout has no additionalContext cap" premise was empirically WRONG. So claude joins the pointer
    #              arm: the directive stays lean (the banner + BOUNDED resume context inline; the full ~45KB
    #              contract pointed-at on disk). RESIDUAL (maintainer's call): claude skims past file pointers (the
    #              iter-6 disproof), so in pointer mode the contract's user-profile/expertise adaptation (banner
    #              item 3) is not read - it degrades to the /specrew-user-profile fallback. That is a graceful,
    #              integrity-SAFE degrade (governance is SCRIPT-enforced, not directive-borne); the follow-up
    #              option is to extract+inline JUST the small user-profile block to restore item 3.
    #   codex   -> pointer. ROLLOUT-PROVEN 2026-06-10 to silently DROP the oversized (~50KB) SessionStart
    #              additionalContext; codex reads files, so the lean pointer lands.
    #   antigravity -> pointer. T006 binds the verified PreInvocation injectSteps path before real-host
    #              parity evidence exists, so keep the hook output lean and put the full contract on disk.
    #   copilot -> inline. UNVERIFIED drop. copilot/cursor deliver SessionStart via additionalContext /
    #   cursor  -> inline. additional_context (the SAME mechanism codex drops). The host research matrix
    #              (specs/171-specrew-refocus/research-matrix.md) records a 10k cap only for CLAUDE's
    #              additionalContext - NONE is documented for copilot/cursor, and copilot rendered in-band in BOTH
    #              the iter-8 and iter-11 dogfoods. An oversized drop is SUSPECTED (same mechanism) but UNPROVEN;
    #              flipping on suspicion would regress a host that works, so they stay inline. TO FLIP once
    #              confirmed on-host (both are in the dogfood loop): move the host into the pointer arm below.
    #              Residual tracked in the T009 continuity docs. (NOTE: even inline hosts get the BOUNDED handover/
    #              reconciliation below - that cap is mode-independent; only the 45KB contract is mode-gated.)
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $HostKind)
    switch ($HostKind) {
        'codex'       { return 'pointer' }
        'claude'      { return 'pointer' }
        'antigravity' { return 'pointer' }
        default       { return 'inline' }   # copilot / cursor
    }
}

function Limit-SpecrewInlineBlock {
    # F-174 iter-11 (P2): bound a variable-length block inlined into the SessionStart directive so the assembled
    # hook payload stays under the host's output cap. Claude Code v2.1.177 silently drops hook output over 10,000
    # chars to a file + a ~2KB preview, so the directive never reaches the model; codex/copilot/cursor caps are
    # the same-or-unknown. The mechanical handover sections (esp. "What I just did") are an unbounded git-delta log
    # that repeats the full uncommitted-file list per entry (~6KB in the iter-11 worst case) - inlining them
    # verbatim alone blew the cap. Truncate at a line boundary when possible and append an elision pointer to the
    # full on-disk source (the agent reads it for depth). Behavior on under-budget input: returns $Text unchanged.
    [CmdletBinding()]
    [OutputType([string])]
    param([AllowNull()][string]$Text, [int]$MaxChars = 480, [string]$Pointer = '')
    if ([string]::IsNullOrEmpty($Text) -or $Text.Length -le $MaxChars) { return $Text }
    $cut = $Text.Substring(0, $MaxChars)
    $nl = $cut.LastIndexOf("`n")
    if ($nl -gt [int]($MaxChars / 2)) { $cut = $cut.Substring(0, $nl) }
    $note = if ([string]::IsNullOrWhiteSpace($Pointer)) { '... (truncated to fit the session-start delivery cap)' }
            else { ('... (truncated to fit the session-start delivery cap; full content at {0})' -f $Pointer) }
    return ($cut.TrimEnd() + "`n" + $note)
}

function Format-BootstrapDirective {
    param($Result, [AllowNull()][string]$ContractBody = $null, [AllowNull()]$InFlight = $null, [AllowNull()]$PendingVerdict = $null, [AllowNull()][string]$SpecrewVersion = $null, [AllowNull()][string]$Branch = $null)
    $d = $Result.directive
    $reads = @($d.required_reads)
    $contractRead = if ($reads.Count -ge 1 -and -not [string]::IsNullOrWhiteSpace([string]$reads[0])) { [string]$reads[0] } else { '.specrew/last-start-prompt.md' }
    $stateRead = if ($reads.Count -ge 2 -and -not [string]::IsNullOrWhiteSpace([string]$reads[1])) { [string]$reads[1] } else { '.specrew/start-context.json' }
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('[specrew-bootstrap] SessionStart B2 - render this as VISIBLE PROSE before any structured picker (render-first; FR-004/FR-020).')
    $lines.Add(("Bootstrap mode: {0}." -f $d.mode))
    # FR-001 (banner fix, 2026-06-10): the orientation BANNER is mandatory on EVERY host and must render
    # FIRST. It was skipped on claude (the render instruction sat AFTER the ~45KB inline contract, so claude
    # skimmed past it to the task; copilot rendered it). Hoist the full, EXPANDED banner mandate to the TOP -
    # before the contract - and name the "how we work" + user-profile/expertise content the human expects.
    $lines.Add('=== MANDATORY FIRST ACTION - render before anything else, on EVERY host ===')
    $lines.Add('On your VERY FIRST response - BEFORE anything else and REGARDLESS of the user''s first message (even a task like "create a feature ...") - render the Specrew ORIENTATION BANNER as visible prose, THEN act on the request. The banner is mandatory on every host; never skip it. Render, in order:')
    $lines.Add('  (1) Specrew is governing this session, and HOW we work: a spec-driven lifecycle with human-authorized boundaries - you DRIVE the gates and do NOT free-run the SDLC.')
    $lines.Add('  (2) Specrew version, the host you are, the project + branch, and the current lifecycle position.')
    $lines.Add('  (3) How you will adapt to the HUMAN - the user-profile / expertise dials from the contract (e.g. "I''ll treat you as an expert on Software Architecture ...") - so they see what you know about them. If the contract carries NO user-profile/expertise adaptation (none is set), instead tell them they can set how you adapt by running /specrew-user-profile - the hook cannot ask, but they can (FR-025).')
    $lines.Add('  (4) Any validated handover summary; (5) a one-line state reason when non-default; (6) a brief recommended next step for THIS state; (7) the Resume / New / Pick-feature menu as TEXT (offer Resume only when a valid active session exists).')
    # F-174 iter-11 (T009, DF-2): EMBED the resolved version + branch in the directive TEXT so a pointer-mode
    # host (codex - it does NOT inline the contract, so the version/branch never reached its banner; the
    # iteration-010 codex pointer-banner showed "not resolved") renders a COMPLETE banner item 2 from literal
    # values. claude/copilot/cursor get these from the inlined contract; this makes the directive self-sufficient.
    # Fail-soft: a value that could not be resolved is omitted (the agent falls back to what it can see).
    $resolved = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($SpecrewVersion)) { $resolved.Add("Specrew version $SpecrewVersion") | Out-Null }
    if (-not [string]::IsNullOrWhiteSpace($Branch)) { $resolved.Add("branch $Branch") | Out-Null }
    if ($resolved.Count -gt 0) {
        $lines.Add(("  Resolved for THIS session (use these LITERAL values in banner item 2 - do NOT render 'unknown'/'not resolved'): {0}." -f ($resolved.ToArray() -join '; ')))
    }
    # FR-002/FR-023 (iter-7 T044, Ruling b): DRIVE by INLINING the contract, not pointing at a file. The
    # iter-6 directive told the agent to READ last-start-prompt.md BEFORE acting; the side-by-side disproof
    # showed the agent never read it (a file is a skip the agent self-orients past). So when the contract
    # body is available, inline it HERE - the agent acts on the in-context contract, with no file to skip;
    # the file stays the durable reference re-consulted at later boundaries. Fallback to the read-the-file
    # directive only when the body could not be captured (deployed resolution failure).
    if (-not [string]::IsNullOrWhiteSpace($ContractBody)) {
        $lines.Add(("Your governed launch contract for THIS session is BELOW - the SAME contract specrew start hands the agent (FR-023): the full lifecycle rules, governance, boundary authorization, the user-profile/expertise adaptation, and the coordinator framing. Follow it EXACTLY; do NOT bypass clarify or governance gates, and do NOT drive from raw Spec Kit scripts. The same contract is saved at {0} (and the current lifecycle state at {1}) for reference as you work each boundary." -f $contractRead, $stateRead))
        $lines.Add('')
        $lines.Add('===== BEGIN SPECREW LAUNCH CONTRACT (follow this) =====')
        $lines.Add($ContractBody.TrimEnd())
        $lines.Add('===== END SPECREW LAUNCH CONTRACT =====')
        $lines.Add('')
    }
    else {
        # POINTER mode (claude + codex - hosts whose hook-output cap drops the ~45KB inline contract; F-174 iter-11
        # P2). The contract is NOT inlined - it is on disk - so name everything that lives ONLY in it (incl. the
        # user-profile/expertise adaptation that feeds banner item 3 + the coordinator framing) and the explicit
        # item-3 fallback, since a host that skims the pointer (claude, iter-6 disproof) would otherwise render an
        # empty item 3. Governance itself is script-enforced, so skimming the contract does NOT bypass any gate.
        $lines.Add(("DRIVE this session from the governed contract (FR-023): READ {0} (the authoritative Specrew launch contract - the full lifecycle rules, governance scripts, boundary authorization, policy classes, the user-profile/expertise adaptation that feeds banner item 3, and the coordinator framing) and {1} (the current lifecycle state) from the project root BEFORE acting. Follow the governed lifecycle EXACTLY as that contract directs; do NOT bypass clarify or governance gates, and do NOT drive the work from raw Spec Kit scripts. (Banner item 3 lives ONLY in that contract here - read it; if it carries no adaptation or you cannot read it, use the /specrew-user-profile fallback named at the top - do NOT invent one.)" -f $contractRead, $stateRead))
    }
    if ($d.PSObject.Properties['handover'] -and $null -ne $d.handover -and $d.handover.present) {
        if ($d.handover.placeholder) {
            $lines.Add('[!] HOLLOW HANDOVER (rare) - the previous session''s Stop hook captured NO session delta (git unavailable?), so resume context is reduced to the lifecycle artifacts + git state. Re-derive the situation from the artifacts and surface this gap to the human - you are the backstop.')
        }
        else {
            $lines.Add(("Validated handover captured by the previous session (as of {0}; boundary: {1}). This is your resume context - surface it (render item 2), do not merely cite that it exists. The mechanical sections are hook-captured git/session state; any interpretive sections are agent-authored:" -f $d.handover.recorded_at, $d.handover.active_boundary))
            # F-174 iter-11 (P2): the inlined handover is the dominant SessionStart-payload bloat - the "What I
            # just did" mechanical log repeats the full uncommitted-file list per entry (~6KB in the iter-11
            # worst case), and inlining every section verbatim alone exceeded the host's 10K hook-output cap (the
            # whole directive was then dropped to a file on claude). Bound it two ways: a per-section char cap AND
            # a running TOTAL budget across sections - so one fat mechanical section cannot starve the rest, and
            # the agent reads the full on-disk handover for depth. Interpretive sections are normally short; in
            # practice the cap only bites the mechanical git-delta log.
            $hoPointer = 'file:///.specrew/handover/session-handover.md'
            $hoBudget = 380
            # F-174 iter-11 (P2 + Prop-145 RES-1): the tight handover budget MUST be spent on the AGENT-AUTHORED
            # interpretive sections FIRST - those (open questions, working hypothesis) are the only resume context
            # NO other block carries, and the FR-022 footer promises "what you hand off == what the next session
            # inherits". Iterating in raw section order spent the budget on the mechanical "What I just did"
            # git-delta log first (which the RECONCILIATION + IN-FLIGHT scans below already re-derive) and starved
            # the interpretive tail - the exact opposite of the intent. So: agent-owned sections first, then the
            # rest; cap "What I just did" hardest; and charge ONLY the content length against the budget, never the
            # elision-note boilerplate (else one truncated section's note alone ate ~1/3 of the budget).
            $agentOwned = @(Get-SpecrewHandoverAgentOwnedSections)
            $allKeys = @($d.handover.sections.Keys)
            $orderedKeys = @(@($allKeys | Where-Object { $agentOwned -contains $_ }) + @($allKeys | Where-Object { $agentOwned -notcontains $_ }))
            foreach ($k in $orderedKeys) {
                $c = [string]$d.handover.sections[$k]
                if (-not (Test-SpecrewHandoverSectionAuthored -Content $c)) { continue }
                if ($hoBudget -le 0) {
                    $lines.Add(("  - (further handover sections omitted to fit the delivery cap; read {0})" -f $hoPointer))
                    break
                }
                $secCap = [Math]::Min(($(if ($k -match 'just did') { 140 } else { 220 })), $hoBudget)
                $rendered = Limit-SpecrewInlineBlock -Text $c -MaxChars $secCap -Pointer $hoPointer
                $hoBudget -= [Math]::Min($c.Length, $secCap)   # charge CONTENT only, not the elision-note boilerplate
                $clines = @($rendered -split "`r?`n")
                if ($clines.Count -le 1) {
                    $lines.Add(("  - {0}: {1}" -f $k, $rendered))
                }
                else {
                    $lines.Add(("  - {0}:" -f $k))
                    foreach ($cl in $clines) { $lines.Add(("      {0}" -f $cl)) }
                }
            }
        }
    }
    # F-174 iter-10 (T001): the resume RECONCILIATION - the CURRENT delta re-computed NOW vs the snapshot
    # above, so the agent reads what changed SINCE the last stop and continues from the REAL state (the
    # snapshot may predate the latest work: antigravity, no-PostToolUse hosts, and hard-kills all lag the
    # disk). Lean: a pointer to the changed files; the agent does the reading.
    if ($d.PSObject.Properties['reconciliation'] -and $null -ne $d.reconciliation -and -not [string]::IsNullOrWhiteSpace([string]$d.reconciliation.directive_text)) {
        $lines.Add('')
        $lines.Add('=== RESUME RECONCILIATION (current tree, re-computed now) ===')
        # F-174 iter-11 (P2): the reconciliation re-lists the changed files (overlaps the handover delta) - bound
        # it too so the assembled payload stays under the host hook-output cap; the agent reads the tree itself.
        # NOTE (2026-06-15): this 300 excerpt is a DOGFOODED resume floor - do NOT cut it to buy cap headroom
        # (DirectiveDeliveryCap guards it >= 300). Recover headroom from the co-resident refocus B2 tail instead;
        # the durable reduction is Proposal 191 (pre-compute the in-flight digest to a file + pointer).
        $lines.Add((Limit-SpecrewInlineBlock -Text ([string]$d.reconciliation.directive_text) -MaxChars 300 -Pointer 'file:///.specrew/handover/session-handover.md'))
    }
    # F-174 iteration 011 (T006 part 2, FR-027 / decision f174-i011-verdict-authority-stop-hook): committed !=
    # authorized. When a boundary was mechanically crossed (sync) but NOT human-authorized (no captured verdict),
    # the resume MUST surface "awaiting your verdict" and the agent MUST NOT treat the committed boundary as
    # approved, MUST NOT advance on it, and MUST NOT record an authorization itself. This is the SECOND-CHANCE
    # re-confirm surface: on a verdict-capture hook host the human's re-confirmation is captured by the next
    # hook fire; on hosts without that capture path (including Antigravity's bounded hook slice) the agent
    # relays it. Surfaced HIGH (right after the resume context) because it
    # is integrity-critical - a committed boundary read as approved is exactly the DF-4/DF-5 failure.
    if ($null -ne $PendingVerdict -and [bool]$PendingVerdict.HasPendingVerdict) {
        $lines.Add('')
        $lines.Add('=== AWAITING YOUR VERDICT (committed != authorized - FR-027) ===')
        $lines.Add([string]$PendingVerdict.Message)
        $lines.Add('Treat that boundary as NOT YET approved: do NOT advance the lifecycle on it and do NOT record an authorization yourself. SURFACE this in your orientation banner and ASK the human to confirm; their actual response is the verdict (captured by the next hook fire, or their explicit confirmation), else stay at the prior authorized boundary.')
    }
    # F-174 T050 round-2 (the last-mile resume gap): the intent + status ARE on disk, but neither a hollow
    # handover ("re-derive from the artifacts" - skimmed as an abstract pointer) nor full mode (the contract's
    # project-state stub is empty; the hook makes no scan) ever SURFACED them - so copilot asked "what do you
    # want to build" with the answer in spec.md, and codex reported the hollow handover then stopped. Surface
    # the deterministic disk scan HERE, with the concrete next action named (content gets followed; pointers
    # get skimmed - the iter-7 inline-the-contract lesson).
    if ($null -ne $InFlight -and [bool]$InFlight.in_flight) {
        $lines.Add('')
        $lines.Add(('=== IN-FLIGHT WORK ON DISK (deterministic scan - this project is NOT new) ===') )
        $lines.Add(("Feature {0} is in flight on this branch. The intent and status live in FILES - read them FIRST, before asking the human anything:" -f $InFlight.feature_ref))
        if ($InFlight.spec_exists) { $lines.Add(("  - the intent (what we are building): {0}" -f $InFlight.spec_path)) }
        if (@($InFlight.done).Count -gt 0) {
            # F-174 iter-11 (T008, DF-1): surface each done lens's DECISION (one line from its record), not just
            # the lens NAME, so a pointer/terse host (codex) can SYNTHESIZE "what we decided so far" instead of
            # echoing lens names. Fall back to the bare names when no decision record could be parsed.
            $ddProp = $InFlight.PSObject.Properties['done_decisions']
            # F-174 iter-11 (real-host fix 2026-06-14): an EMPTY @() returned from an if-EXPRESSION branch collapses
            # to $null under StrictMode-Latest, so `$x = if(..){@(..)}else{@()}` makes $x null when the value is
            # empty -> `$x.Count` then THROWS ("property 'Count' cannot be found") -> the whole directive fails ->
            # the bootstrap banner never surfaces. This bit on a real workshop with done lenses but NO parseable
            # decision summaries (done_decisions = empty array). Use DIRECT assignment (no if-expression), which
            # preserves an empty array (Count 0). $ddProp.Value truthiness is $false for $null AND for an empty
            # array, so the guard also avoids the @($null)->1-element-of-null trap.
            $decisions = @()
            if ($ddProp -and $ddProp.Value) { $decisions = @($ddProp.Value) }
            if ($decisions.Count -gt 0) {
                $lines.Add(("  - design-workshop DECISIONS recorded so far (records under specs/{0}/workshop/) - SYNTHESIZE these into a 'what we decided so far' recap for the human; do NOT just echo lens names:" -f $InFlight.feature_ref))
                # F-174 iter-11 (P2): cap BOTH the per-summary length AND the number of decisions inlined so the
                # whole recap cannot blow the host hook-output cap (a full 9-lens workshop dumps ~1KB here). The
                # lens name + decision-point heads are enough to synthesize; the full records are on disk.
                # F-174 iter-11 (P2 + Prop-145 RES-3): inline the per-lens SUMMARY for the first few, but ALWAYS
                # name EVERY decided lens (the overflow lenses get their bare names on one line, not just a count) -
                # a pointer/skimming host that will not open the on-disk records still needs the full agenda to
                # synthesize the recap. Lens names are short + catalog-bounded, so this stays budget-neutral.
                $decMax = 3
                $decShown = @($decisions | Select-Object -First $decMax)
                foreach ($dec in $decShown) { $lines.Add(("      * {0}: {1}" -f $dec.lens, (Limit-SpecrewInlineBlock -Text ([string]$dec.summary) -MaxChars 95))) }
                $decRest = @(@($decisions | Select-Object -Skip $decMax) | ForEach-Object { [string]$_.lens })
                if ($decRest.Count -gt 0) { $lines.Add(("      * (also decided - synthesize from the records on disk under specs/{0}/workshop/): {1}" -f $InFlight.feature_ref, ($decRest -join ', '))) }
                $named = @($decisions | ForEach-Object { [string]$_.lens })
                $bare = @($InFlight.done | Where-Object { $named -notcontains $_ })
                if ($bare.Count -gt 0) { $lines.Add(("      (also recorded done, no decision record: {0})" -f ($bare -join ', '))) }
            }
            else {
                $lines.Add(("  - design-workshop lenses already DONE (records under specs/{0}/workshop/): {1}" -f $InFlight.feature_ref, (@($InFlight.done) -join ', ')))
            }
        }
        if (@($InFlight.remaining).Count -gt 0) { $lines.Add(("  - workshop lenses REMAINING (from lens-applicability.json): {0}" -f (@($InFlight.remaining) -join ', '))) }
        # Codex round-3 lesson: with lens records but NO persisted agenda, "resume at the recorded position"
        # was too open - the host re-ran specify (rewrote spec.md) instead of continuing the workshop. When
        # records exist, name the only safe move explicitly - and distinguish the three shapes:
        #   remaining > 0                          -> resume at that exact lens
        #   agenda persisted + all selected done   -> workshop COMPLETE; resume at the boundary, don't redo it
        #   records but NO agenda (codex shape)    -> re-propose the remaining agenda, continue the workshop
        $next = if (@($InFlight.remaining).Count -gt 0) { ("resume the design workshop at the next remaining lens: {0}" -f @($InFlight.remaining)[0]) }
        elseif ([bool]$InFlight.has_applicability -and @($InFlight.done).Count -gt 0) { 'the design workshop is COMPLETE (every selected lens is recorded done) - do NOT redo or re-propose it; resume at the lifecycle position AFTER the workshop (typically presenting the specify boundary packet / awaiting the human verdict, or the recorded boundary)' }
        elseif (@($InFlight.done).Count -gt 0) { 'CONTINUE the design workshop: the agenda was not persisted, so RE-PROPOSE the remaining lens agenda to the human (skipping the DONE lenses above) and proceed lens-by-lens. Do NOT re-run specify and do NOT rewrite spec.md - the spec already exists' }
        else { 'resume at the recorded lifecycle position (read the spec + workshop records to locate it)' }
        $lines.Add(("When the human says 'continue' (or similar), {0}. Do NOT restart discovery, do NOT re-ask completed lenses, and do NOT ask 'what do you want to build' - spec.md answers that. Open your welcome-back with a 1-2 sentence SYNTHESIS of what we have decided so far (from the decisions/records above - synthesize the substance, do NOT just list lens names) and your resume point, then proceed." -f $next))
    }
    $lines.Add('Reminder (do not skip): your FIRST response MUST open with the MANDATORY orientation banner described at the top, and only THEN address the user''s request.')
    if (@($d.validation_findings).Count -gt 0) {
        $lines.Add(("State notes: {0}." -f ((@($d.validation_findings)) -join '; ')))
    }
    $lines.Add('Handover protocol (FR-022): to carry your INTERPRETIVE context across a session switch - your open questions + working hypothesis, which NO hook can author - persist it via `specrew handover author --from <file>` (a markdown body with `## ` section headers; run `specrew handover --help` for the section names), so what you hand off == what the next session inherits. Refresh before you expect to stop. On Claude the Stop hook ALSO captures your rendered boundary packet verbatim, but it is transcript-blind for the interpretive sections - only you can author those. NEVER delete + recreate .specrew/handover/session-handover.md with generic file tools - a crash between the delete and the create loses the handover; the writer (and `specrew handover author`) replaces the file ATOMICALLY and keeps session-handover.md.old as the crash backup (the bootstrap reader falls back to it automatically).')
    $lines.Add('This directive is advisory and non-authorizing: it never advances a lifecycle boundary on its own.')
    return ($lines -join "`n")
}

try {
    $eventJson = ''
    $rootOverride = $null
    $hostKind = 'claude'
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($args[$i] -eq '--event-json' -and ($i + 1) -lt $args.Count) { $eventJson = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--project-root' -and ($i + 1) -lt $args.Count) { $rootOverride = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--host-kind' -and ($i + 1) -lt $args.Count) { $hostKind = [string]$args[$i + 1] }
    }
    # Hooks only deploy for these kinds; an unknown value fails safe to the claude default.
    if ($hostKind -notin @('claude', 'codex', 'copilot', 'cursor', 'antigravity')) { $hostKind = 'claude' }

    # B1 (compact) is unchanged - the bootstrap is B2 only (FR-011).
    $source = $null
    if (-not [string]::IsNullOrWhiteSpace($eventJson)) {
        try { $source = ($eventJson | ConvertFrom-Json).source } catch { $source = $null }
    }
    if ($source -eq 'compact') { exit 0 }

    $root = if ($rootOverride) { [System.IO.Path]::GetFullPath($rootOverride) } else { Get-BootstrapProjectRoot }

    # Component resolution (D-001 downstream deploy): components sit beside the provider in the
    # source tree (scripts/internal/bootstrap); in a self-host dogfood the provider may execute from
    # the deployed .specify mirror, so prefer the project-local source tree before any ambient
    # SPECREW_MODULE_PATH/installed-module fallback. Downstream projects normally lack scripts/internal,
    # so they still resolve through the dev-tree override or the installed module (FileList).
    $bdir = Join-Path $PSScriptRoot 'bootstrap'
    if (-not (Test-Path -LiteralPath $bdir)) {
        $selfHostBdir = Join-Path $root 'scripts/internal/bootstrap'
        $devBdir = if ($env:SPECREW_MODULE_PATH) { Join-Path $env:SPECREW_MODULE_PATH 'scripts/internal/bootstrap' } else { $null }
        if (Test-Path -LiteralPath $selfHostBdir) { $bdir = $selfHostBdir }
        elseif ($devBdir -and (Test-Path -LiteralPath $devBdir)) { $bdir = $devBdir }
        else {
            # F-174 iter-11 (P1): pick the newest installed module that ACTUALLY CONTAINS scripts/internal/bootstrap,
            # not blindly the newest. Not every Specrew version ships the bootstrap components in its FileList (0.34.0
            # did; 0.35.0/0.36.0 did not), so "newest module" can resolve to a bootstrap-LESS path -> the dot-source
            # below throws -> the top-level try swallows it -> exit 0 -> the hook silently writes NOTHING. Filtering
            # for the bootstrap dir makes the fallback land on a version that can actually serve it. Fail-open is
            # unchanged: if NO installed module carries bootstrap, $bdir stays the (absent) co-located path and the
            # dot-source fails into the same silent no-op - but a bootstrap-bearing older module is no longer skipped.
            $mod = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.ModuleBase 'scripts/internal/bootstrap') } |
                Select-Object -First 1
            if ($mod) { $bdir = Join-Path $mod.ModuleBase 'scripts/internal/bootstrap' }
        }
    }
    foreach ($f in 'HostEventAdapter', 'SessionStateAccessor', 'ProjectMetadataAccessor', 'HandoverStore', 'ClassificationEngine', 'ValidationEngine', 'DirectiveEngine', 'SessionBootstrapManager', 'LauncherIntegration') {
        . (Join-Path $bdir "$f.ps1")
    }

    # FR-023: the hook hands the agent the SAME launch contract `specrew start` does, via the SAME
    # generator (Get-StartPrompt) - no second hand-rolled directive (no drift). Resolve the generator +
    # its transitive deps through the SAME 3-tier chain that found $bdir (co-located | SPECREW_MODULE_PATH |
    # installed module): launch-contract.ps1 + coordinator-resume.ps1 live in scripts/internal;
    # shared-governance.ps1 (boundary policy-class map + boundary_enforcement state) lives in the extension
    # scripts tree. Deriving from $bdir inherits the bootstrap components' proven deployed resolution.
    $internalDir = Split-Path $bdir -Parent
    $moduleRoot = Split-Path (Split-Path $internalDir)
    . (Join-Path $internalDir 'launch-contract.ps1')
    . (Join-Path $internalDir 'coordinator-resume.ps1')
    # iter-7 T043: the coordinator-surgery step + the user-profile reader carry the user-profile/expertise
    # adaptation + per-host coordinator framing into the contract (the content iter-6 omitted). Same 3-tier
    # resolution (both live in scripts/internal beside launch-contract.ps1).
    . (Join-Path $internalDir 'coordinator-prompt-surgery.ps1')
    . (Join-Path $internalDir 'user-profile.ps1')
    . (Join-Path (Join-Path $moduleRoot 'extensions/specrew-speckit/scripts') 'shared-governance.ps1')

    # Launcher<->hook dedupe (FR-007, SC-002): if `specrew start` just bootstrapped this session,
    # stay silent so the startup yields exactly one bootstrap surface.
    $nowUtc = (Get-Date).ToUniversalTime().ToString('o')
    if (Test-SpecrewLauncherBootstrapRecent -ProjectRoot $root -NowUtc $nowUtc) { exit 0 }

    $journalPath = Join-Path $root '.specrew/runtime/bootstrap-journal.jsonl'
    $result = Invoke-SpecrewSessionBootstrap -RawEvent $eventJson -HostName $hostKind -ProjectRoot $root -BaseBranch 'main' -JournalPath $journalPath

    # F-174 iter-10 double-render dedupe: capture the manager's canonical key (== safe_session_id, the SAME id
    # the journal records) NOW. The ATOMIC render CLAIM is taken LATER - right before Write-Output (see there) -
    # so every fallible step (the contract write + the in-flight scan below) runs BEFORE the claim and the only
    # thing between winning the claim and emitting is pure string building, which cannot suppress a sibling fire.
    $renderDedupeKey = [string]$result.record.dedupe_key

    # FR-023: the hook DRIVES - write the SAME launch contract + ensure boundary_enforcement on disk. The
    # manager component owns this logic (Write-SpecrewLaunchContractArtifact); the adapter invokes it here
    # so the pure classification path (Invoke-SpecrewSessionBootstrap) stays test-isolated from the
    # generator's StrictMode-Latest dependency tree. Inside the fail-open try: a broken deployed resolution
    # surfaces as no-write + exit 0 (caught by the T038 deployed floor), never a blocked session.
    # iter-7 T044: capture the contract path, read its body, and INLINE it into the directive (Ruling b) -
    # the agent acts on the in-context contract instead of being told to read a file it skips. The contract
    # file is ALWAYS written here (the codex pointer path below depends on it existing on disk).
    # Resolve the Specrew version from the module manifest ($moduleRoot came from the same 3-tier chain) so the
    # mandatory orientation banner renders the REAL version, not "Specrew: unknown" (the surgery defaults to
    # "unknown" with no version). Fail-soft: an unreadable manifest leaves it null (banner falls back to unknown).
    $specrewVersion = $null
    try { $specrewVersion = [string]((Import-PowerShellDataFile -Path (Join-Path $moduleRoot 'Specrew.psd1')).ModuleVersion) } catch { $specrewVersion = $null }
    # F-174 iter-11 (T009, DF-2): resolve the branch HERE (in the fallible-work region, BEFORE the atomic render
    # claim below) so the directive can embed the literal version + branch for pointer-mode hosts. Must NOT run
    # after the claim (the claim->emit window must stay pure string building - a git call could fail/hang).
    $branch = $null
    try { $branch = ([string](& git -C $root rev-parse --abbrev-ref HEAD 2>$null)).Trim(); if ([string]::IsNullOrWhiteSpace($branch)) { $branch = $null } } catch { $branch = $null }
    $contractPath = Write-SpecrewLaunchContractArtifact -ProjectRoot $root -Mode $result.mode -SessionState $result.validity.anchor -SpecrewVersion $specrewVersion
    $contractBody = if ($contractPath -and (Test-Path -LiteralPath $contractPath)) { Get-Content -LiteralPath $contractPath -Raw } else { '' }

    # Host delivery policy (DELIVERY only; contract FRAMING unchanged). The per-host inline-vs-pointer rule +
    # its rationale + the copilot/cursor UNVERIFIED-drop residual live in the ONE testable seam below (T007/M1).
    $inlineContract = ((Get-SpecrewContractDeliveryMode -HostKind $hostKind) -eq 'inline')
    $directiveBody = if ($inlineContract) { $contractBody } else { '' }

    # F-174 T050 round-2: deterministic in-flight disk scan for the directive (the last-mile resume gap).
    # Feature source: the validated anchor first, else the branch (the pre-boundary workshop window - same
    # resolver the Stop floor-writer uses). Fail open: any error -> no block (never blocks the bootstrap).
    $inFlight = $null
    try {
        $ifFeature = $null
        if ($null -ne $result.validity.anchor -and -not [string]::IsNullOrWhiteSpace([string]$result.validity.anchor.feature_ref)) {
            $ifFeature = [string]$result.validity.anchor.feature_ref
        }
        if ([string]::IsNullOrWhiteSpace($ifFeature)) { $ifFeature = Resolve-SpecrewBranchFeatureRef -ProjectRoot $root }
        if (-not [string]::IsNullOrWhiteSpace($ifFeature)) { $inFlight = Get-SpecrewWorkshopProgress -ProjectRoot $root -FeatureRef $ifFeature }
    }
    catch { $inFlight = $null }

    # F-174 iteration 011 (T006 part 2, FR-027): the honest "committed != authorized" gate state, read from the
    # SAME boundary_enforcement the sync writes. When the working boundary is ahead of the last HUMAN-authorized
    # one, the directive surfaces "awaiting your verdict" (below). Fail-open (the helper never throws + never
    # fabricates a pending state; the guard is belt-and-suspenders for a missing-helper deploy edge).
    $pendingVerdict = $null
    try { $pendingVerdict = Get-SpecrewPendingVerdictState -ProjectRoot $root } catch { $pendingVerdict = $null }

    # F-174 iter-10 ATOMIC double-render dedupe (the CLAIM). codex fires SessionStart twice per launch
    # near-SIMULTANEOUSLY (worktree dogfood 2026-06-13: two fires ~microseconds apart, same session id +
    # source), so a recency/record-after-render scheme cannot dedupe them - both check before either records
    # and BOTH render (the dogfood saw exactly that: two render markers ~10us apart). Elect exactly ONE
    # renderer with an ATOMIC create-if-absent claim per (session, source): the winner renders, every
    # concurrent sibling finds the claim present and exits silent. Events with no usable host session id receive
    # a per-launch fallback token before this point, so they never collapse into a global bucket; the historical
    # 'no-session' sentinel remains fail-open for older callers. /clear (different source) wins its OWN claim
    # -> re-renders. Fail-open (the claim returns $true on any non-"already-exists" error). The claim sits HERE
    # - the last step before emit, AFTER all fallible work (Invoke, contract write,
    # in-flight scan) - so the winner->emit window holds only pure string building; a transient failure in one
    # fire cannot suppress the other. Invoke already ran, so the journal records BOTH fires (forensic count
    # intact); only one RENDERS. Scope: the bootstrap directive only - the refocus banner (provider order 10) +
    # handover (order 30) still re-run on the duplicate dispatcher fire (the refocus-banner doubling is the
    # known benign residual; a dispatcher-level dedupe was rejected for blast radius - highest in the chain).
    if ($renderDedupeKey -and $renderDedupeKey -ne 'no-session') {
        if (-not (Request-SpecrewHookRenderClaim -ProjectRoot $root -DedupeKey $renderDedupeKey -Source ([string]$source) -RecordedAt $nowUtc)) { exit 0 }
    }
    Write-Output (Format-BootstrapDirective -Result $result -ContractBody $directiveBody -InFlight $inFlight -PendingVerdict $pendingVerdict -SpecrewVersion $specrewVersion -Branch $branch)
    exit 0
}
catch {
    [Console]::Error.WriteLine("[specrew-bootstrap] WARN PROVIDER_FAILED $($_.Exception.Message)")
    exit 0
}
