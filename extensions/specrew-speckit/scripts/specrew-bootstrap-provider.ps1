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
    param($Result, [AllowNull()][string]$ContractBody = $null)
    $d = $Result.directive
    $reads = @($d.required_reads)
    $contractRead = if ($reads.Count -ge 1 -and -not [string]::IsNullOrWhiteSpace([string]$reads[0])) { [string]$reads[0] } else { '.specrew/last-start-prompt.md' }
    $stateRead = if ($reads.Count -ge 2 -and -not [string]::IsNullOrWhiteSpace([string]$reads[1])) { [string]$reads[1] } else { '.specrew/start-context.json' }
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('[specrew-bootstrap] SessionStart B2 - render this as VISIBLE PROSE before any structured picker (render-first; FR-004/FR-020).')
    $lines.Add(("Bootstrap mode: {0}." -f $d.mode))
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
    $lines.Add('On your FIRST response - REGARDLESS of the user''s first message (even a task such as "create a feature ...") - LEAD with the orientation drawn from the contract ABOVE (rendered inline; you do not need to open a file), THEN act on their request. Never skip it.')
    $lines.Add('Render, in order: (1) orientation - Specrew version, host, project, branch, lifecycle position; (2) any validated handover summary; (3) a one-line state reason when non-default; (4) a brief recommended next step for THIS state; (5) the Resume / New / Pick-feature menu as TEXT. Offer Resume only when a valid active session exists.')
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
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($args[$i] -eq '--event-json' -and ($i + 1) -lt $args.Count) { $eventJson = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--project-root' -and ($i + 1) -lt $args.Count) { $rootOverride = [string]$args[$i + 1] }
    }

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
    $result = Invoke-SpecrewSessionBootstrap -RawEvent $eventJson -HostName claude -ProjectRoot $root -BaseBranch 'main' -JournalPath $journalPath

    # FR-023: the hook DRIVES - write the SAME launch contract + ensure boundary_enforcement on disk. The
    # manager component owns this logic (Write-SpecrewLaunchContractArtifact); the adapter invokes it here
    # so the pure classification path (Invoke-SpecrewSessionBootstrap) stays test-isolated from the
    # generator's StrictMode-Latest dependency tree. Inside the fail-open try: a broken deployed resolution
    # surfaces as no-write + exit 0 (caught by the T038 deployed floor), never a blocked session.
    # iter-7 T044: capture the contract path, read its body, and INLINE it into the directive (Ruling b) -
    # the agent acts on the in-context contract instead of being told to read a file it skips.
    $contractPath = Write-SpecrewLaunchContractArtifact -ProjectRoot $root -Mode $result.mode -SessionState $result.validity.anchor
    $contractBody = if ($contractPath -and (Test-Path -LiteralPath $contractPath)) { Get-Content -LiteralPath $contractPath -Raw } else { '' }

    Write-Output (Format-BootstrapDirective -Result $result -ContractBody $contractBody)
    exit 0
}
catch {
    [Console]::Error.WriteLine("[specrew-bootstrap] WARN PROVIDER_FAILED $($_.Exception.Message)")
    exit 0
}
