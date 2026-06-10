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

function Format-BootstrapDirective {
    param($Result, [AllowNull()][string]$ContractBody = $null, [AllowNull()]$InFlight = $null)
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
        $lines.Add(("DRIVE this session from the governed contract (FR-023): READ {0} (the authoritative Specrew launch contract - the full lifecycle rules, governance scripts, boundary authorization, and policy classes) and {1} (the current lifecycle state) from the project root BEFORE acting. Follow the governed lifecycle EXACTLY as that contract directs; do NOT bypass clarify or governance gates, and do NOT drive the work from raw Spec Kit scripts." -f $contractRead, $stateRead))
    }
    if ($d.PSObject.Properties['handover'] -and $null -ne $d.handover -and $d.handover.present) {
        if ($d.handover.placeholder) {
            $lines.Add('[!] HOLLOW HANDOVER - the previous session did NOT author a handover body (the rolling handover is a placeholder). Your resume context is REDUCED to the lifecycle artifacts + git state. Re-derive the situation from the artifacts; do NOT present rich resume context you do not actually have. You are the backstop - surface this gap to the human.')
        }
        else {
            $lines.Add(("Validated handover authored by the previous session (as of {0}; boundary: {1}). Surface this as your resume context (render item 2) - do not merely cite that it exists:" -f $d.handover.recorded_at, $d.handover.active_boundary))
            foreach ($k in $d.handover.sections.Keys) {
                $c = [string]$d.handover.sections[$k]
                if (Test-SpecrewHandoverSectionAuthored -Content $c) { $lines.Add(("  - {0}: {1}" -f $k, $c)) }
            }
        }
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
        if (@($InFlight.done).Count -gt 0) { $lines.Add(("  - design-workshop lenses already DONE (records under specs/{0}/workshop/): {1}" -f $InFlight.feature_ref, (@($InFlight.done) -join ', '))) }
        if (@($InFlight.remaining).Count -gt 0) { $lines.Add(("  - workshop lenses REMAINING (from lens-applicability.json): {0}" -f (@($InFlight.remaining) -join ', '))) }
        # Codex round-3 lesson: with lens records but NO persisted agenda, "resume at the recorded position"
        # was too open - the host re-ran specify (rewrote spec.md) instead of continuing the workshop. When
        # records exist, the resume point is ALWAYS the workshop; name the only safe move explicitly.
        $next = if (@($InFlight.remaining).Count -gt 0) { ("resume the design workshop at the next remaining lens: {0}" -f @($InFlight.remaining)[0]) }
        elseif (@($InFlight.done).Count -gt 0) { 'CONTINUE the design workshop: the agenda was not persisted, so RE-PROPOSE the remaining lens agenda to the human (skipping the DONE lenses above) and proceed lens-by-lens. Do NOT re-run specify and do NOT rewrite spec.md - the spec already exists' }
        else { 'resume at the recorded lifecycle position (read the spec + workshop records to locate it)' }
        $lines.Add(("When the human says 'continue' (or similar), {0}. Do NOT restart discovery, do NOT re-ask completed lenses, and do NOT ask 'what do you want to build' - spec.md answers that. Confirm your resume point to the human in one line, then proceed." -f $next))
    }
    $lines.Add('Reminder (do not skip): your FIRST response MUST open with the MANDATORY orientation banner described at the top - Specrew + how-we-work + version/host/project/branch/lifecycle position + the user-profile/expertise adaptation (what you know about the human) - and only THEN address the user''s request.')
    if (@($d.validation_findings).Count -gt 0) {
        $lines.Add(("State notes: {0}." -f ((@($d.validation_findings)) -join '; ')))
    }
    $lines.Add('Handover protocol (FR-022): whenever you render a re-entry / boundary packet, FIRST persist it as the handover body via Write-SpecrewHandoverContext, THEN render the packet FROM that file - so what the human sees == what the next session inherits. Refresh before you expect to stop. The Stop hook preserves your body but is transcript-blind and cannot author it; only you can.')
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
    if ($hostKind -notin @('claude', 'codex', 'copilot', 'cursor')) { $hostKind = 'claude' }

    # B1 (compact) is unchanged - the bootstrap is B2 only (FR-011).
    $source = $null
    if (-not [string]::IsNullOrWhiteSpace($eventJson)) {
        try { $source = ($eventJson | ConvertFrom-Json).source } catch { $source = $null }
    }
    if ($source -eq 'compact') { exit 0 }

    $root = if ($rootOverride) { $rootOverride } else { Get-BootstrapProjectRoot }

    # Component resolution (D-001 downstream deploy): components sit beside the provider in the
    # self-host tree (scripts/internal/bootstrap); in a downstream project the provider deploys to
    # the extension tree while the components ship in the installed Specrew module (FileList), so
    # fall back to the module's scripts/internal/bootstrap. SPECREW_MODULE_PATH (the documented
    # dev-tree override, honored by specrew.ps1) wins first so a dev/unpublished module is testable.
    $bdir = Join-Path $PSScriptRoot 'bootstrap'
    if (-not (Test-Path -LiteralPath $bdir)) {
        $devBdir = if ($env:SPECREW_MODULE_PATH) { Join-Path $env:SPECREW_MODULE_PATH 'scripts/internal/bootstrap' } else { $null }
        if ($devBdir -and (Test-Path -LiteralPath $devBdir)) { $bdir = $devBdir }
        else {
            $mod = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending | Select-Object -First 1
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
    $contractPath = Write-SpecrewLaunchContractArtifact -ProjectRoot $root -Mode $result.mode -SessionState $result.validity.anchor -SpecrewVersion $specrewVersion
    $contractBody = if ($contractPath -and (Test-Path -LiteralPath $contractPath)) { Get-Content -LiteralPath $contractPath -Raw } else { '' }

    # Host delivery policy (F-174 codex fix, 2026-06-10 - DELIVERY only; contract FRAMING unchanged):
    #   claude         -> INLINE the full contract. Claude SKIPS a "read this file" pointer and self-orients
    #                     past it (the iter-6 disproof), so the contract must be in-context.
    #   codex          -> POINTER to the file. Codex silently DROPS the oversized (~50KB) SessionStart
    #                     additionalContext (rollout-proven 2026-06-10: nothing surfaced, codex vibe-coded
    #                     past every gate) AND it reads files - so hand it the lean read-the-file directive
    #                     (Format-BootstrapDirective's else branch, which also says don't bypass gates /
    #                     don't drive from raw Spec Kit).
    #   copilot/cursor -> INLINE for now. UNVERIFIED on those hosts (different injection envelopes); left
    #                     native pending an empirical test. Flip to the pointer here if they drop too.
    $inlineContract = ($hostKind -ne 'codex')
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

    Write-Output (Format-BootstrapDirective -Result $result -ContractBody $directiveBody -InFlight $inFlight)
    exit 0
}
catch {
    [Console]::Error.WriteLine("[specrew-bootstrap] WARN PROVIDER_FAILED $($_.Exception.Message)")
    exit 0
}
