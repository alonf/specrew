# T078 / T079 (FR-026 / FR-030 / FR-031): the co-review NAVIGATOR provider - the dispatcher-facing
# THIN loader for the always-on async co-review navigator.
#
# This is a CONSUMER of the EXISTING F-185 hook dispatcher + provider catalog (refocus-scopes.json),
# registered as kind=inject events=[Stop,agentStop,stop,SessionStart] order=50 - it runs AFTER the
# conformance provider (order 40).
#
# KNOWN STOP-BLOCK COLLISION (flagged for Planner, NOT fixable in-glob): the dispatcher's
# $stopBlockReason is LAST-WRITER-WINS with no merge/priority logic. Because the navigator runs LAST
# (order 50 > conformance's 40), a navigator stop-block OVERWRITES a conformance stop-block emitted on
# the SAME Stop. Each provider is a separate child process and cannot see another's stdout, so the
# navigator CANNOT coordinate ("emit only if conformance did not") from here. In the implement window a
# blocking co-review verdict can co-occur with a conformance MATERIAL-work block (changed files, no
# packet); today the navigator's block would be the only one delivered, dropping the conformance packet
# directive that turn. Containing this needs the DISPATCHER to merge/prioritize competing stop-block
# reasons (an out-of-glob / F-184 change) - routed to Planner as a design question. Mitigation today:
# the navigator blocks ONLY on its own distinct blocking-co-review verdict (a narrow, infrequent event),
# and a dropped conformance block re-fires on the next Stop (the gate STATE remains the authority).
#
# The provider itself does almost NOTHING - it locates + dot-sources the in-glob navigator LOGIC
# (scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1, which dot-sources the
# launcher + _load.ps1) via the module-base candidate ladder, then calls Invoke-ContinuousCoReviewNavigator
# and translates the returned decision into the dispatcher's stdout contract:
#   - decision.stop_block set       -> print '<<<SPECREW-STOP-BLOCK>>>' + the directive (the dispatcher
#                                       force-continues the turn via the host's stop-block envelope).
#   - decision.inject_notes present -> print them (a plain inject the dispatcher merges as a fragment).
#   - no-op                         -> print NOTHING (a no-op stop must not perturb the merged result).
# It is FAST + non-blocking by construction (the navigator reaps cheaply and FIRES a DETACHED launcher
# that the provider never waits for) and FULLY FAIL-OPEN: any error/uncertainty -> no output, exit 0.
#
# ARG CONTRACT (the dispatcher's double-dash convention, like conformance): the dispatcher invokes
# inject providers with --host-kind / --source-event / --transcript-path via ProcessStartInfo.ArgumentList.
# A PowerShell param()/[CmdletBinding()] block REJECTS a '--flag' token (binds as '-flag' and exits 1 at
# the binding boundary BEFORE the body runs), so parse $args MANUALLY. NO param().
#
# F-184 footprint: NONE. Non-protected script in the deployed extension scripts tree (the registration
# side; the navigator logic is non-protected too). PowerShell 7.x. exit 0 ALWAYS (fail-open).

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }

function Resolve-CoReviewNavigatorLogicPath {
    # Locate scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1. Clone the
    # Resolve-SpecrewBootstrapDir candidate ladder: project tree (the deployed extension's own root, or
    # the self-host repo) -> $env:SPECREW_MODULE_PATH -> the installed Specrew ModuleBase. $null if none
    # resolves (the caller WARNs once + no-ops; downstream this is the FileList-gap symptom - the CCR
    # tree is currently NOT in the .psd1 FileList, a feature-wide packaging gap flagged for closeout).
    param([string]$ProjectRoot, [string]$Rel = 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
    $rel = $Rel

    # When this provider is the DEPLOYED copy under <project>/.specify/extensions/specrew-speckit/scripts,
    # the CCR logic is NOT beside it - it ships (once the FileList is fixed) under the installed
    # ModuleBase. When it is the in-repo SOURCE copy (extensions/specrew-speckit/scripts), the repo root
    # two levels up holds scripts/internal/... Probe the source-repo layout first (self-host + tests),
    # then the env override, then the installed module.
    $candidateBases = New-Object System.Collections.Generic.List[string]
    # source-repo: <repo>/extensions/specrew-speckit/scripts -> <repo>
    $maybeRepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    if (-not [string]::IsNullOrWhiteSpace($maybeRepoRoot)) { [void]$candidateBases.Add($maybeRepoRoot) }
    foreach ($b in @($ProjectRoot, $env:SPECREW_MODULE_PATH)) {
        if (-not [string]::IsNullOrWhiteSpace($b)) { [void]$candidateBases.Add($b) }
    }
    foreach ($base in $candidateBases.ToArray()) {
        $probe = Join-Path $base $rel
        if (Test-Path -LiteralPath $probe -PathType Leaf) { return $probe }
    }
    try {
        $mod = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.ModuleBase $rel) -PathType Leaf } | Select-Object -First 1
        if ($mod) { return (Join-Path $mod.ModuleBase $rel) }
    }
    catch { $null = $_ }
    return $null
}

# --- manual $args parse (the double-dash contract; NO param()) ---
$sourceEventArg = $null
$hostKindArg = $null
for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq '--source-event' -and ($i + 1) -lt $args.Count) { $sourceEventArg = [string]$args[$i + 1] }
    # M1 fix (145 iter-006): --host-kind IS the code-writer host - thread it to the navigator so reviewer
    # selection is code-writer-INDEPENDENT by logic (claude->codex, codex->claude), not merely by which
    # hosts the catalog authorizes. --transcript-path stays accepted-but-unused (the navigator works off
    # git state + the registry, not the transcript).
    elseif ($args[$i] -eq '--host-kind' -and ($i + 1) -lt $args.Count) { $hostKindArg = [string]$args[$i + 1] }
}

try {
    $projectRoot = (Get-Location).Path
    if ([string]::IsNullOrWhiteSpace($projectRoot) -or -not (Test-Path -LiteralPath (Join-Path $projectRoot '.specrew'))) {
        exit 0  # not a governed project root - nothing to do.
    }

    # Classify the event: SessionStart -> cross-session SWEEP; Stop-class -> reap+fire. The registration
    # binds exactly these; anything else is a defensive no-op.
    $evt = if ([string]::IsNullOrWhiteSpace($sourceEventArg)) { '' } else { $sourceEventArg.ToLowerInvariant() }
    $isSessionStart = ($evt -eq 'sessionstart')
    $isStop = ($evt -in @('stop', 'agentstop'))
    if (-not $isSessionStart -and -not $isStop) { exit 0 }

    # iter-008: config-select the review ENGINE. DEFAULT = legacy (the proven in-place path). co_review_engine=worktree
    # OPTS INTO the new pipeline (fast trigger + detached orchestrator + the host-neutral co-review service). The
    # worktree engine becomes the default at CUTOVER - after its correctness is proven by a contract-bearing e2e, not
    # before (the default selector is a 1-line change + a unit test; it does not change reviewed behavior). Read
    # best-effort from .specrew/config.yml BEFORE loading (it decides WHICH navigator to load).
    $engine = 'legacy'
    try {
        $cfgPath = Join-Path $projectRoot '.specrew/config.yml'
        if (Test-Path -LiteralPath $cfgPath -PathType Leaf) {
            foreach ($line in (Get-Content -LiteralPath $cfgPath -Encoding UTF8)) {
                if ($line -match '^\s*co_review_engine\s*:\s*([^#\r\n]+)') { $engine = ($Matches[1].Trim().Trim('"').Trim("'")).ToLowerInvariant(); break }
            }
        }
    }
    catch { $null = $_ }
    $rel = if ($engine -eq 'worktree') { 'scripts/internal/continuous-co-review/worktree-navigator.ps1' } else { 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1' }
    $navFn = if ($engine -eq 'worktree') { 'Invoke-ContinuousCoReviewWorktreeNavigator' } else { 'Invoke-ContinuousCoReviewNavigator' }

    $logicPath = Resolve-CoReviewNavigatorLogicPath -ProjectRoot $projectRoot -Rel $rel
    if ([string]::IsNullOrWhiteSpace($logicPath) -and $engine -eq 'worktree') {
        # worktree was opted into (co_review_engine=worktree) but its scripts are not deployed here (e.g. a
        # provider-only update on an older deploy). Fall back to the legacy navigator rather than go dark, and WARN
        # so the partial deploy is diagnosable.
        [Console]::Error.WriteLine("[specrew-co-review-navigator] WARN CO_REVIEW_WORKTREE_FALLBACK_LEGACY worktree engine is the default but worktree-navigator.ps1 did not resolve; falling back to the legacy navigator (re-deploy to get the worktree engine).")
        $rel = 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1'
        $navFn = 'Invoke-ContinuousCoReviewNavigator'
        $logicPath = Resolve-CoReviewNavigatorLogicPath -ProjectRoot $projectRoot -Rel $rel
    }
    if ([string]::IsNullOrWhiteSpace($logicPath)) {
        # Diagnosable degrade (NOT a silent dead provider): mirror conformance's *_UNAVAILABLE WARN.
        [Console]::Error.WriteLine("[specrew-co-review-navigator] WARN CO_REVIEW_NAVIGATOR_UNAVAILABLE the in-glob navigator logic ($rel) did not resolve under the project tree, SPECREW_MODULE_PATH, or the installed Specrew module; the co-review navigator is dark this event (the deterministic signoff gate floor remains the authority).")
        exit 0
    }
    . $logicPath
    if (-not (Get-Command -Name $navFn -ErrorAction SilentlyContinue)) {
        [Console]::Error.WriteLine("[specrew-co-review-navigator] WARN CO_REVIEW_NAVIGATOR_UNAVAILABLE the navigator logic loaded but $navFn is undefined; co-review navigator dark this event.")
        exit 0
    }

    # Optional config scalar: the co-review timeout (mirrors co_review_gate_enforcement). Read best-effort
    # from .specrew config if present; else the navigator's safe default applies.
    $navParams = @{ RepoRoot = $projectRoot }
    if ($isSessionStart) { $navParams['SessionStart'] = $true }
    # M1 fix (145 iter-006): thread the code-writer host (the dispatcher's --host-kind) so reviewer
    # selection is independent-by-logic, not config-incidental.
    if (-not [string]::IsNullOrWhiteSpace($hostKindArg)) { $navParams['CodeWriterHost'] = $hostKindArg }

    $decision = $null
    try { $decision = & $navFn @navParams }
    catch {
        [Console]::Error.WriteLine("[specrew-co-review-navigator] WARN CO_REVIEW_NAVIGATOR_FAILED $($_.Exception.Message)")
        exit 0
    }
    if ($null -eq $decision) { exit 0 }

    # Translate the decision into the dispatcher's stdout contract. STOP-BLOCK wins (force-continue);
    # else any inject notes; else NOTHING.
    if (-not [string]::IsNullOrWhiteSpace([string]$decision.stop_block)) {
        Write-Output ("<<<SPECREW-STOP-BLOCK>>>`n" + [string]$decision.stop_block)
        exit 0
    }
    $notes = @($decision.inject_notes | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($notes.Count -gt 0) {
        Write-Output ($notes -join "`n")
    }
    # no-op (action no-op/fired/swept with no surfaced verdict) -> emit nothing.
    exit 0
}
catch {
    [Console]::Error.WriteLine("[specrew-co-review-navigator] WARN CO_REVIEW_NAVIGATOR_FAILED $($_.Exception.Message)")
    exit 0
}
