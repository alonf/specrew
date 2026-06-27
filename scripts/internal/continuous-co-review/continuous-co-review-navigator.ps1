$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T078 / T079 (FR-026 / FR-030 / FR-031): the async co-review NAVIGATOR + the pending registry & reaper.
#
# This is the in-glob LOGIC of the always-on co-review navigator (the pair-programming navigator that
# auto-fires a fresh-context co-review at every real implement checkpoint, host-neutral, non-blocking).
# A THIN entry-point at extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1 is
# what the F-185 hook dispatcher invokes on Stop/SessionStart (it locates + dot-sources THIS file via
# the module-base ladder, then calls Invoke-ContinuousCoReviewNavigator). Keeping the logic here makes
# it unit-testable by direct dot-source (like every other CCR module) and keeps the dispatcher-facing
# surface a one-file loader.
#
# THE WHOLE-PIPELINE SHAPE (per the iteration-005 design):
#   On each Stop, FAST (well inside the ~20s provider budget; #2885), it NEVER waits for a review:
#     1. REAP first (T079): scan .specrew/review/pending/. A done entry -> surface its verdict (a
#        blocking verdict emits the 185 <<<SPECREW-STOP-BLOCK>>> sentinel + a directive; else a brief
#        inject note), then retire it. A past-deadline-but-supervisor-alive entry -> Stop the task
#        (kill + cleanup). A supervisor-gone-with-no-terminal-status entry -> mark crashed + clean the
#        orphaned worktree. (Backstops the supervisor's own finally-dispose for the DEAD-launcher case.)
#     2. If this Stop is a real implement CHECKPOINT (reuse the Phase A
#        Invoke-ContinuousCoReviewGateDispatch detection - do NOT re-derive) AND the current reviewed
#        tree-id differs from the last-FIRED tree-id (dedup via the Iteration-004 digest), FIRE
#        Start-SpecrewIsolatedTask {read-only, discard, code-review} with a reviewer -Command that
#        emits a verdict JSON on stdout (captured to the run's result_path). Record the fired tree-id.
#        Return immediately.
#     3. Otherwise no-op, emitting NOTHING (a no-op stop must not perturb the dispatcher's merged result).
#   On SessionStart, SWEEP: reap cross-session orphans (pending entries from a prior session - kill any
#     live supervisor, clean orphaned worktrees) so a session that died mid-review never leaks.
#
# CONCURRENCY: one pending review at a time for the navigator. A new checkpoint SUPERSEDES an
#   un-reaped prior (Stop the prior, then fire the replacement).
#
# F-184 footprint: NONE. Non-protected script under the CCR internal location. PowerShell 7.x.

# --- shared launcher (single source) -------------------------------------------------------------
# The navigator FIRES + REAPS through the general isolated-task launcher (T077). Dot-source it if its
# functions are not already present (the dispatcher-facing loader resolves the path; tests dot-source
# the launcher themselves). Resolution is best-effort: a miss leaves Start/Stop-SpecrewIsolatedTask
# undefined and the navigator degrades to its fail-open no-op (the caller WARNs once).
if (-not (Get-Command -Name 'Start-SpecrewIsolatedTask' -ErrorAction SilentlyContinue)) {
    # This file lives at scripts/internal/continuous-co-review/; the launcher is its SIBLING-DIR file
    # scripts/internal/agent-tasks/isolated-task-launcher.ps1. So one parent (scripts/internal) + the
    # agent-tasks leaf - NOT two parents (which would land at scripts/agent-tasks and miss).
    $script:NavigatorLauncherCandidates = @(
        (Join-Path (Split-Path -Parent $PSScriptRoot) 'agent-tasks/isolated-task-launcher.ps1')
    )
    foreach ($cand in $script:NavigatorLauncherCandidates) {
        if (Test-Path -LiteralPath $cand -PathType Leaf) { . $cand; break }
    }
}

# --- the CCR engine (single source) --------------------------------------------------------------
# FIRST-LIVE-RUN FIX (iter-006 e2e): the navigator's CHECKPOINT DETECTION (the Phase A gate-dispatch
# reuse + Get-...MergeBaseAnchor + Get-...CheckpointDiff) and the reviewer plan / promotion / blackboard
# all need the CCR engine (_load.ps1: checkpoint-diff-provider, gate-review-dispatcher, the request
# builder, the catalog/selection/authorization, the blackboard writer). The dispatcher-facing provider
# dot-sources ONLY this file, and the checkpoint detection runs BEFORE New-...ReviewerPlan's own
# lazy-load - so without _load here the navigator NO-OPS on EVERY live Stop (the checkpoint functions are
# undefined). Dot-source it if absent (a _load function gates it; _load does NOT load this navigator, so
# no circular). Best-effort: a miss leaves the navigator at its fail-open no-op.
if (-not (Get-Command -Name 'Get-ContinuousCoReviewCheckpointDiff' -ErrorAction SilentlyContinue)) {
    $script:NavigatorEngineLoad = Join-Path $PSScriptRoot '_load.ps1'
    if (Test-Path -LiteralPath $script:NavigatorEngineLoad -PathType Leaf) { . $script:NavigatorEngineLoad }
}

function Get-ContinuousCoReviewNavigatorModuleBase {
    # T082 HAZARD A: the detached reviewer pwsh runs with cwd = the materialized read-only WORKTREE,
    # which contains NO Specrew scripts (it is a `git archive` content export of the reviewed project).
    # So the fired -Command cannot dot-source the execution engine / adapters / contracts relative to
    # its cwd. We resolve the Specrew module base HERE (in-repo, at fire) from THIS file's own location
    # and thread the ABSOLUTE path into the -Command. This file lives at
    # scripts/internal/continuous-co-review/, so the module base (where scripts/, extensions/ live) is
    # three parents up. SPECREW_MODULE_PATH is the fallback (it is what the provider + the test harness
    # set). The returned base is the dir that CONTAINS scripts/internal/continuous-co-review/_load.ps1.
    $candidates = New-Object System.Collections.Generic.List[string]
    try {
        $fromHere = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
        if (-not [string]::IsNullOrWhiteSpace($fromHere)) { [void]$candidates.Add($fromHere) }
    }
    catch { $null = $_ }
    if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH)) { [void]$candidates.Add($env:SPECREW_MODULE_PATH) }
    foreach ($base in $candidates.ToArray()) {
        $probe = Join-Path $base 'scripts/internal/continuous-co-review/_load.ps1'
        if (Test-Path -LiteralPath $probe -PathType Leaf) {
            try { return (Resolve-Path -LiteralPath $base).Path } catch { return $base }
        }
    }
    return $null
}

function Get-ContinuousCoReviewNavigatorTimeoutSeconds {
    # T082 / condition-c: the co-review timeout config scalar. iteration 002 proved a real codex
    # full-iteration review needs ~300s (a 120s rerun timed out, so no findings landed). This raises the
    # navigator default OFF 120 to a value that clears a real codex run, and makes it project-overridable
    # via .specrew/config.yml `co_review_timeout_seconds` (mirroring Get-ContinuousCoReviewGateEnforcementEnabled's
    # quote-strip + inline-comment-tolerant grammar). This is the ADAPTER/host-call budget (how long the
    # reviewer process may run); the launcher's own supervisor TimeoutSec is kept ABOVE it (see
    # Invoke-ContinuousCoReviewNavigator) so the adapter times out gracefully before the supervisor hard-kills.
    param([Parameter(Mandatory)][string]$RepoRoot, [int]$Default = 300)
    $configPath = Join-Path $RepoRoot '.specrew/config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { return $Default }
    try {
        foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
            if ($line -match '^\s*co_review_timeout_seconds:\s*[''"]?(?<value>[^''"#]+?)[''"]?\s*(?:#.*)?$') {
                $parsed = 0
                if ([int]::TryParse(($Matches['value'].Trim()), [ref]$parsed) -and $parsed -gt 0) { return $parsed }
            }
        }
    }
    catch { $null = $_ }
    return $Default
}

function Get-ContinuousCoReviewNavigatorFeatureRoot {
    # Resolve the ACTIVE feature directory (repo-relative, e.g. 'specs/197-continuous-co-review') so the
    # reviewer gets the right design context. The navigator is GENERIC (it must work in any governed
    # project), so it never hardcodes a feature path. Source of truth = .specify/feature.json
    # feature_directory (the canonical resolver every other Specrew script uses - task-progress.ps1,
    # worktree-awareness.ps1); fallback = .specrew/start-context.json session_state.feature_path. Returns
    # a repo-relative path, or $null when no feature is resolvable (the caller then fires no real review -
    # fail-open, never a stub).
    param([Parameter(Mandatory)][string]$RepoRoot)
    $featureJsonPath = Join-Path $RepoRoot '.specify/feature.json'
    if (Test-Path -LiteralPath $featureJsonPath -PathType Leaf) {
        try {
            $fj = Get-Content -LiteralPath $featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if (($fj.PSObject.Properties.Name -contains 'feature_directory') -and -not [string]::IsNullOrWhiteSpace([string]$fj.feature_directory)) {
                $rel = ([string]$fj.feature_directory).Replace('\', '/').TrimEnd('/')
                if (Test-Path -LiteralPath (Join-Path $RepoRoot $rel) -PathType Container) { return $rel }
            }
        }
        catch { $null = $_ }
    }
    $scPath = Join-Path $RepoRoot '.specrew/start-context.json'
    if (Test-Path -LiteralPath $scPath -PathType Leaf) {
        try {
            $sc = Get-Content -LiteralPath $scPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $fp = $null
            if ($sc.PSObject.Properties['session_state'] -and $null -ne $sc.session_state -and $sc.session_state.PSObject.Properties['feature_path']) {
                $fp = [string]$sc.session_state.feature_path
            }
            elseif ($sc.PSObject.Properties['feature_path']) {
                $fp = [string]$sc.feature_path
            }
            if (-not [string]::IsNullOrWhiteSpace($fp)) {
                $full = $fp
                if (-not [System.IO.Path]::IsPathRooted($fp)) { $full = Join-Path $RepoRoot $fp }
                if (Test-Path -LiteralPath $full -PathType Container) {
                    try { return ([System.IO.Path]::GetRelativePath((Resolve-Path -LiteralPath $RepoRoot).Path, (Resolve-Path -LiteralPath $full).Path)).Replace('\', '/') }
                    catch { $null = $_ }
                }
            }
        }
        catch { $null = $_ }
    }
    return $null
}

function Get-ContinuousCoReviewNavigatorDesignContextRefs {
    # Resolve the design-context refs the reviewer needs (ReviewRequest.v2 REQUIRES at least one, else
    # New-ContinuousCoReviewRequest throws and the fire fail-opens to no-op - no real review). Generic:
    # probe the active feature dir for spec.md + the LATEST iteration's design-analysis.md + workshop/.
    # Returns repo-relative refs (the request builder reads them under RepoRoot). Empty when nothing
    # resolves (caller fires no real review).
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$FeatureRoot)
    $refs = New-Object System.Collections.Generic.List[string]
    $featureFull = Join-Path $RepoRoot $FeatureRoot
    $specPath = Join-Path $featureFull 'spec.md'
    if (Test-Path -LiteralPath $specPath -PathType Leaf) { [void]$refs.Add(("$FeatureRoot/spec.md")) }

    # The latest iteration's design-analysis.md (highest-numbered iterations/NNN/), so the review reflects
    # the iteration actually being implemented - not a hardcoded iterations/001.
    $iterationsRoot = Join-Path $featureFull 'iterations'
    if (Test-Path -LiteralPath $iterationsRoot -PathType Container) {
        $iterDirs = @(Get-ChildItem -LiteralPath $iterationsRoot -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^\d+$' } | Sort-Object -Property @{ Expression = { [int]$_.Name } } -Descending)
        foreach ($iter in $iterDirs) {
            $da = Join-Path $iter.FullName 'design-analysis.md'
            if (Test-Path -LiteralPath $da -PathType Leaf) { [void]$refs.Add(("$FeatureRoot/iterations/$($iter.Name)/design-analysis.md")); break }
        }
    }

    # spec.md is the minimum; if neither spec nor design-analysis exists, return empty (no real review).
    return @($refs.ToArray() | Select-Object -Unique)
}

function Get-ContinuousCoReviewNavigatorPendingDir {
    # The pending-task registry dir (launcher<->reaper signaling). Stable, in-repo, gitignored +
    # digest-stripped (.specrew/** is out of the reviewed tree-id), so it survives the fire->reap gap
    # ACROSS a session boundary for the SessionStart sweep. Mirrors Get-SpecrewIsolatedTaskPendingDir;
    # redefined here so the navigator does not require the launcher to be loaded just to find the dir
    # during a reap-only path.
    param([Parameter(Mandatory)][string]$RepoRoot)
    return (Join-Path $RepoRoot '.specrew/review/pending')
}

function Get-ContinuousCoReviewNavigatorRunDir {
    # Per-run scratch dir under the pending registry (status.json + result.out + job/harness). Lives
    # beside the registry so a single sweep over .specrew/review/pending/ finds both the registry
    # entry (<run-id>.json) and its run dir (<run-id>/).
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$RunId)
    return (Join-Path (Get-ContinuousCoReviewNavigatorPendingDir -RepoRoot $RepoRoot) $RunId)
}

function Get-ContinuousCoReviewNavigatorStatePath {
    # The navigator's own dedup state (the last-FIRED reviewed tree-id). Under .specrew/runtime/
    # (gitignored, regenerated per machine). A read/write miss disables dedup (re-fire is safe), never
    # blocks.
    param([Parameter(Mandatory)][string]$RepoRoot)
    return (Join-Path $RepoRoot '.specrew/runtime/co-review-navigator-state.json')
}

function Get-ContinuousCoReviewNavigatorLastFiredTreeId {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $path = Get-ContinuousCoReviewNavigatorStatePath -RepoRoot $RepoRoot
    try {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $rec = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if ($rec.PSObject.Properties.Name -contains 'last_fired_tree_id') {
                return [string]$rec.last_fired_tree_id
            }
        }
    }
    catch { $null = $_ }
    return $null
}

function Set-ContinuousCoReviewNavigatorLastFiredTreeId {
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$TreeId, [AllowNull()][string]$RunId)
    $path = Get-ContinuousCoReviewNavigatorStatePath -RepoRoot $RepoRoot
    try {
        $dir = Split-Path -Parent $path
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ([pscustomobject]@{
                last_fired_tree_id = $TreeId
                last_fired_run_id  = $RunId
                fired_at           = (Get-Date).ToUniversalTime().ToString('o')
            } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $path -Encoding UTF8 -ErrorAction Stop
    }
    catch { $null = $_ }
}

function Get-ContinuousCoReviewNavigatorPendingEntries {
    # Every registry entry (<run-id>.json directly under the pending dir). Each is the launcher's
    # registry object plus its on-disk path. Unreadable/partial files are skipped (fail-open).
    param([Parameter(Mandatory)][string]$RepoRoot)
    $pendingDir = Get-ContinuousCoReviewNavigatorPendingDir -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $pendingDir -PathType Container)) { return @() }
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($file in @(Get-ChildItem -LiteralPath $pendingDir -Filter '*.json' -File -ErrorAction SilentlyContinue)) {
        try {
            $reg = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            $entries.Add([pscustomobject]@{ registry_path = $file.FullName; registry = $reg }) | Out-Null
        }
        catch { $null = $_ }
    }
    return $entries.ToArray()
}

function Get-ContinuousCoReviewNavigatorSupervisorPresence {
    # TRI-STATE supervisor liveness for the reap (dogfood finding 2: do not treat a transient
    # Get-Process FAILURE as crashed-and-kill). Returns one of:
    #   'present' - the supervisor pid is a live process (leave the entry running).
    #   'absent'  - Get-Process UNAMBIGUOUSLY reports no such process (a dead pid throws
    #               NoProcessFoundForGivenId / category ObjectNotFound) OR the pid is missing/zero
    #               (nothing to be alive). This is the ONLY signal that licenses an orphan reap.
    #   'unknown' - Get-Process threw something OTHER than not-found (e.g. transient/permission).
    #               A genuinely-running review must NOT be reaped on a transient error; the caller
    #               leaves it pending for the next reap.
    param([AllowNull()]$Registry)
    if ($null -eq $Registry -or -not ($Registry.PSObject.Properties.Name -contains 'supervisor_pid')) { return 'absent' }
    $supPid = $Registry.supervisor_pid
    if (-not $supPid) { return 'absent' }
    try {
        $null = Get-Process -Id ([int]$supPid) -ErrorAction Stop
        return 'present'
    }
    catch {
        # Discriminate: "no such process" is a DEFINITE absence; anything else is transient/unknown.
        # Verified empirically (pwsh 7.x): a dead pid throws FullyQualifiedErrorId
        # 'NoProcessFoundForGivenId,...' with CategoryInfo.Category 'ObjectNotFound'.
        $fqid = [string]$_.FullyQualifiedErrorId
        $isNotFound = ($fqid -like 'NoProcessFoundForGivenId*') -or
                      ($null -ne $_.CategoryInfo -and $_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::ObjectNotFound)
        if ($isNotFound) { return 'absent' }
        return 'unknown'
    }
}

function Test-ContinuousCoReviewNavigatorSupervisorAlive {
    # BACK-COMPAT boolean wrapper: $true only when the supervisor is definitively 'present'. The reap
    # uses the tri-state directly (it must distinguish 'absent' from 'unknown'); other callers that
    # only ask "is it running" keep the simple boolean.
    param([AllowNull()]$Registry)
    return ((Get-ContinuousCoReviewNavigatorSupervisorPresence -Registry $Registry) -eq 'present')
}

function Test-ContinuousCoReviewNavigatorPastDeadline {
    # Is the registry entry past its supervisor-recorded deadline (UTC ISO-8601)? A missing/garbage
    # deadline -> NOT past-deadline (do not reap a still-running task on an unparseable timestamp).
    param([AllowNull()]$Registry, [datetime]$Now = [datetime]::UtcNow)
    if ($null -eq $Registry -or -not ($Registry.PSObject.Properties.Name -contains 'deadline')) { return $false }
    $raw = [string]$Registry.deadline
    if ([string]::IsNullOrWhiteSpace($raw)) { return $false }
    try {
        $deadline = [datetime]::Parse($raw, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal)
        return ($Now -gt $deadline)
    }
    catch { return $false }
}

function ConvertFrom-ContinuousCoReviewNavigatorVerdict {
    # Parse a reviewer verdict from a completed run's result file. The reviewer harness emits a verdict
    # JSON on stdout (captured to result.out by the supervisor's stdio redirect). The canonical shape is
    # { disposition, blocking, findings } - but a FindingsResult.v1 ({ status, findings }) is also
    # accepted (the real reviewer emits that), with blocking inferred from a blocking finding. Returns
    # a normalized @{ ok; blocking; disposition; summary; raw } or ok=$false if nothing parseable.
    param([AllowNull()][string]$ResultPath)
    $out = [pscustomobject]@{ ok = $false; blocking = $false; disposition = $null; summary = $null; raw = $null }
    if ([string]::IsNullOrWhiteSpace($ResultPath) -or -not (Test-Path -LiteralPath $ResultPath -PathType Leaf)) { return $out }
    $text = $null
    try { $text = Get-Content -LiteralPath $ResultPath -Raw -Encoding UTF8 } catch { return $out }
    if ([string]::IsNullOrWhiteSpace($text)) { return $out }
    $verdict = $null
    try { $verdict = $text | ConvertFrom-Json -ErrorAction Stop }
    catch {
        # Tolerate prose around the JSON: take the outermost {...} span.
        $first = $text.IndexOf('{'); $last = $text.LastIndexOf('}')
        if ($first -ge 0 -and $last -gt $first) {
            try { $verdict = $text.Substring($first, $last - $first + 1) | ConvertFrom-Json -ErrorAction Stop } catch { $verdict = $null }
        }
    }
    if ($null -eq $verdict) { return $out }

    $out.ok = $true
    $out.raw = $verdict

    # disposition (canonical verdict shape) OR status (FindingsResult.v1).
    if ($verdict.PSObject.Properties.Name -contains 'disposition' -and -not [string]::IsNullOrWhiteSpace([string]$verdict.disposition)) {
        $out.disposition = [string]$verdict.disposition
    }
    elseif ($verdict.PSObject.Properties.Name -contains 'status' -and -not [string]::IsNullOrWhiteSpace([string]$verdict.status)) {
        $out.disposition = [string]$verdict.status
    }

    # blocking: an explicit boolean wins; else infer from a blocking-severity finding or a
    # block/reject/fail disposition.
    $blocking = $false
    if ($verdict.PSObject.Properties.Name -contains 'blocking') {
        try { $blocking = [bool]$verdict.blocking } catch { $blocking = $false }
    }
    if (-not $blocking -and ($verdict.PSObject.Properties.Name -contains 'findings') -and $null -ne $verdict.findings) {
        foreach ($f in @($verdict.findings)) {
            $sev = if ($null -ne $f -and ($f.PSObject.Properties.Name -contains 'severity')) { [string]$f.severity } else { '' }
            $disp = if ($null -ne $f -and ($f.PSObject.Properties.Name -contains 'disposition')) { [string]$f.disposition } else { '' }
            if ($sev -match '(?i)^(blocking|block|critical|high)$' -or $disp -match '(?i)^block') { $blocking = $true; break }
        }
    }
    if (-not $blocking -and -not [string]::IsNullOrWhiteSpace([string]$out.disposition) -and ([string]$out.disposition) -match '(?i)\b(block|reject|fail)') {
        $blocking = $true
    }
    $out.blocking = $blocking

    # is_stub: the default placeholder reviewer (Build-...ReviewerCommand) marks itself reviewer='stub'.
    # It ALWAYS emits pass without actually reviewing, so it must never become gate evidence (else the
    # signoff gate is auto-satisfiable by plumbing). A real reviewer omits the marker. (closeout / flag 2)
    $isStub = ($verdict.PSObject.Properties.Name -contains 'reviewer') -and (([string]$verdict.reviewer).Trim() -eq 'stub')
    $out | Add-Member -NotePropertyName is_stub -NotePropertyValue ([bool]$isStub) -Force

    # A short human summary line (finding count + first comment), for the inject/STOP-BLOCK directive.
    $findingCount = 0
    $firstComment = $null
    if (($verdict.PSObject.Properties.Name -contains 'findings') -and $null -ne $verdict.findings) {
        $arr = @($verdict.findings)
        $findingCount = $arr.Count
        foreach ($f in $arr) {
            if ($null -ne $f -and ($f.PSObject.Properties.Name -contains 'comment') -and -not [string]::IsNullOrWhiteSpace([string]$f.comment)) { $firstComment = [string]$f.comment; break }
        }
    }
    $out.summary = ("{0} finding(s){1}" -f $findingCount, ($(if ($firstComment) { ": $firstComment" } else { '' })))
    return $out
}

function Clear-ContinuousCoReviewNavigatorEntry {
    # Retire a fully-processed registry entry (move it out of the active pending dir so a later reap
    # does not re-surface it). We DELETE both the registry json and its run dir - the durable PASS
    # record the gate enforces lives separately in .specrew/review/inline/ (written by the promotion above).
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$RegistryPath, [AllowNull()]$Registry)
    try {
        $runDir = $null
        if ($null -ne $Registry -and ($Registry.PSObject.Properties.Name -contains 'run_dir')) { $runDir = [string]$Registry.run_dir }
        if (Test-Path -LiteralPath $RegistryPath -PathType Leaf) { Remove-Item -LiteralPath $RegistryPath -Force -ErrorAction SilentlyContinue }
        if (-not [string]::IsNullOrWhiteSpace($runDir) -and (Test-Path -LiteralPath $runDir)) {
            Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch { $null = $_ }
}

function Write-ContinuousCoReviewNavigatorBlackboard {
    # T083: route a REAL reviewer's COMPLETE FindingsResult (all severities) to the durable blackboard
    # thread under .specrew/review/inline/<run-id>/ (findings-result.json + review-thread.json), run_id
    # NORMALIZED to the registry run-id so the full findings co-locate with the gate record. The reap's
    # Clear-...Entry deletes only pending/<run-id>/ (a SEPARATE dir); inline/ survives -> NO reap-ordering
    # change. EXCLUDES the stub (no real findings). FAIL-OPEN: any error/miss returns $null and the caller
    # degrades to the one-line summary note; the navigator never throws to the dispatcher. (T083)
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)]$Verdict,
        [datetime]$Now = [datetime]::UtcNow
    )
    if (($Verdict.PSObject.Properties.Name -contains 'is_stub') -and $Verdict.is_stub) { return $null }
    if ($null -eq $Verdict.raw) { return $null }
    # The blackboard writer lives in review-blackboard-writer.ps1; the provider path dot-sources only the
    # navigator + launcher, so lazy-load _load (the same in-scope pattern as Add-...PassRunRecord).
    if (-not (Get-Command -Name 'Write-ContinuousCoReviewBlackboardThread' -ErrorAction SilentlyContinue)) {
        try { $loadPath = Join-Path $PSScriptRoot '_load.ps1'; if (Test-Path -LiteralPath $loadPath -PathType Leaf) { . $loadPath } } catch { $null = $_ }
        if (-not (Get-Command -Name 'Write-ContinuousCoReviewBlackboardThread' -ErrorAction SilentlyContinue)) { return $null }
    }
    try {
        $findings = $Verdict.raw
        # NORMALIZE run_id to the registry run-id (co-locate with the gate record under inline/<run-id>/).
        if ($findings.PSObject.Properties.Name -contains 'run_id') { $findings.run_id = $RunId }
        else { $findings | Add-Member -NotePropertyName run_id -NotePropertyValue $RunId -Force }
        Write-ContinuousCoReviewBlackboardThread -RepoRoot $RepoRoot -CheckpointId ("nav-$RunId") -FindingsResult $findings -CreatedAt $Now | Out-Null
        return ".specrew/review/inline/$RunId/"
    }
    catch { return $null }
}

function Get-ContinuousCoReviewNavigatorFailureReason {
    # Read the detached reviewer's SAFE failure sidecar (review-failure.json, written by the reviewer
    # -Command on a non-findings-result) and format a one-line reason for the reap's advisory note, so a
    # checkpoint that produced no verdict SAYS WHY (input-too-large / timeout / schema-mismatch / nonzero-exit
    # / ...) instead of a bare "no parseable verdict". The sidecar carries only the contract-scrubbed
    # category + message (no stdout/stderr/prompt content). Missing/unreadable -> $null (the caller falls back
    # to the generic note). Read BEFORE Clear-...Entry retires the run dir.
    param([Parameter(Mandatory)][string]$RepoRoot, [AllowNull()]$Registry)
    try {
        $runDir = if ($null -ne $Registry -and ($Registry.PSObject.Properties.Name -contains 'run_dir')) { [string]$Registry.run_dir } else { $null }
        if ([string]::IsNullOrWhiteSpace($runDir)) { return $null }
        $sidecar = Join-Path $runDir 'review-failure.json'
        if (-not (Test-Path -LiteralPath $sidecar -PathType Leaf)) { return $null }
        $rec = Get-Content -LiteralPath $sidecar -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $cat = if ($rec.PSObject.Properties.Name -contains 'category') { [string]$rec.category } else { '' }
        $msg = if ($rec.PSObject.Properties.Name -contains 'message') { [string]$rec.message } else { '' }
        if ([string]::IsNullOrWhiteSpace($cat) -and [string]::IsNullOrWhiteSpace($msg)) { return $null }
        if ([string]::IsNullOrWhiteSpace($msg)) { return $cat }
        if ([string]::IsNullOrWhiteSpace($cat)) { return $msg }
        return ("{0} - {1}" -f $cat, $msg)
    }
    catch { return $null }
}

function Invoke-ContinuousCoReviewNavigatorReap {
    # T079 REAP (runs at the top of every navigator Stop, AND - via -CrossSession - as the SessionStart
    # sweep). Walks every pending registry entry and classifies it:
    #   - terminal status (done|timed-out|failed|reaped|crashed): surface a verdict if a result exists,
    #     then retire the entry. A blocking done-verdict produces a STOP-BLOCK directive; a clean one a
    #     brief inject note; a non-done terminal an inject note (the run did not produce a verdict).
    #   - running + past-deadline + supervisor PRESENT: the supervisor overran its own kill loop (or is
    #     wedged) -> Stop-SpecrewIsolatedTask (kill + worktree cleanup + mark reaped).
    #   - running + supervisor DEFINITIVELY ABSENT + no terminal status: a DEAD launcher/supervisor
    #     orphan -> Stop-SpecrewIsolatedTask marks it crashed + cleans the orphaned worktree (the
    #     backstop the launcher's own finally-dispose cannot cover when the supervisor itself was
    #     killed).
    #   - running + supervisor present + within deadline: leave it (still working).
    #   - running + supervisor presence UNKNOWN (a transient Get-Process error, NOT not-found) + within
    #     deadline: leave it PENDING (dogfood finding 2: a transient probe failure must not prematurely
    #     reap a genuinely-running review; the next reap re-checks). Past-deadline still reaps it
    #     regardless (the deadline is an independent terminal signal).
    # A reaped NON-BLOCKING PASS (disposition pass / no blocking findings) is PROMOTED to durable gate
    # evidence (.specrew/review/inline/<run-id>/review-run.json) so an auto-fired checkpoint PASS becomes
    # fresh evidence the signoff freshness+coverage gate accepts; a blocking/failed verdict is NOT.
    # Returns @{ stop_block; inject_notes[]; reaped_run_ids[]; promoted_run_ids[] }. stop_block is the
    # FIRST blocking verdict's directive (one STOP-BLOCK per stop). CrossSession skips verdict surfacing
    # AND promotion (a prior session's verdict is stale for THIS turn) and only kills+cleans orphans.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [switch]$CrossSession,
        [string]$TrunkName = 'main',
        [datetime]$Now = [datetime]::UtcNow
    )
    $result = [pscustomobject]@{ stop_block = $null; inject_notes = (New-Object System.Collections.Generic.List[string]); reaped_run_ids = (New-Object System.Collections.Generic.List[string]); promoted_run_ids = (New-Object System.Collections.Generic.List[string]) }
    $terminalStatuses = @('done', 'timed-out', 'failed', 'reaped', 'crashed')

    foreach ($entry in (Get-ContinuousCoReviewNavigatorPendingEntries -RepoRoot $RepoRoot)) {
        $reg = $entry.registry
        $regPath = $entry.registry_path
        $status = if ($null -ne $reg -and ($reg.PSObject.Properties.Name -contains 'status')) { [string]$reg.status } else { '' }
        $runId = if ($null -ne $reg -and ($reg.PSObject.Properties.Name -contains 'run_id')) { [string]$reg.run_id } else { '' }
        $resultPath = if ($null -ne $reg -and ($reg.PSObject.Properties.Name -contains 'result_path')) { [string]$reg.result_path } else { $null }
        # Promote the reviewed-state DIGEST (the gate's identity, computed off the Stop budget by the orchestrator and
        # propagated to the registry), falling back to the HEAD-tree only for older records. Promoting the HEAD-tree
        # never matched the gate's working-tree digest -> every promoted pass read 'stale' (P-145 identity divergence).
        $treeId = if ($null -ne $reg -and ($reg.PSObject.Properties.Name -contains 'reviewed_digest_tree_id') -and -not [string]::IsNullOrWhiteSpace([string]$reg.reviewed_digest_tree_id)) { [string]$reg.reviewed_digest_tree_id } elseif ($null -ne $reg -and ($reg.PSObject.Properties.Name -contains 'tree_id')) { [string]$reg.tree_id } else { $null }

        $isTerminal = ($status -in $terminalStatuses)
        # TRI-STATE presence (finding 2): 'present' / 'absent' (definite) / 'unknown' (transient error).
        $presence = Get-ContinuousCoReviewNavigatorSupervisorPresence -Registry $reg
        $pastDeadline = Test-ContinuousCoReviewNavigatorPastDeadline -Registry $reg -Now $Now

        if ($isTerminal) {
            if (-not $CrossSession) {
                # Surface the verdict (done runs carry one at result_path; others did not finish cleanly).
                $verdict = ConvertFrom-ContinuousCoReviewNavigatorVerdict -ResultPath $resultPath
                if ($status -eq 'done' -and $verdict.ok) {
                    # T083: route the REAL reviewer's full findings (all severities) to the durable
                    # blackboard (fail-open -> $null; the stub is excluded inside). T084: surface the thread.
                    $threadRef = Write-ContinuousCoReviewNavigatorBlackboard -RepoRoot $RepoRoot -RunId $runId -Verdict $verdict -Now $Now
                    $threadSuffix = if ($threadRef) { " Full findings (all severities): $threadRef" } else { '' }
                    if ($verdict.blocking) {
                        if ($null -eq $result.stop_block) {
                            $result.stop_block = (Build-ContinuousCoReviewNavigatorStopBlock -Verdict $verdict -RunId $runId -BlackboardRef $threadRef)
                        }
                    }
                    elseif (($verdict.PSObject.Properties.Name -contains 'is_stub') -and $verdict.is_stub) {
                        # The default PLACEHOLDER stub always emits pass without reviewing. Surface it as
                        # advisory feedback ONLY; it must NOT promote to durable gate evidence (that would
                        # make the signoff gate auto-satisfiable by plumbing). The gate stays unsatisfied
                        # until the real reviewer is wired (the post-closeout fast-follow). (closeout / flag 2)
                        $result.inject_notes.Add(("[co-review] checkpoint navigator fired (run {0}) - plumbing OK, but the real reviewer is not wired yet, so this is NOT counted as gate evidence." -f $runId)) | Out-Null
                    }
                    elseif ((-not [string]::IsNullOrWhiteSpace([string]$verdict.disposition)) -and ([string]$verdict.disposition -match '(?i)^\s*(pass|approved|clean|no.?findings)\s*$')) {
                        $result.inject_notes.Add(("[co-review] checkpoint review PASSED (run {0}): {1}.{2}" -f $runId, $verdict.summary, $threadSuffix)) | Out-Null
                        # PROMOTE only on an AFFIRMATIVE pass disposition (pass/approved/clean/no-findings) -
                        # NEVER on mere absence-of-blocking, else a 'needs-work'/'partial'/unparseable verdict
                        # would launder to a gate 'pass'. The stub is excluded above; this makes the promotion
                        # adversarially sound for the real reviewer too. (145 G-197-I005-01)
                        $promotedId = Add-ContinuousCoReviewNavigatorPassRunRecord -RepoRoot $RepoRoot -RunId $runId -TreeId $treeId -TrunkName $TrunkName -Now $Now
                        if (-not [string]::IsNullOrWhiteSpace($promotedId)) { $result.promoted_run_ids.Add($promotedId) | Out-Null }
                    }
                    else {
                        # Non-blocking but NOT an affirmative pass (needs-work / partial / no parseable pass
                        # disposition): advisory only, NEVER gate evidence. (145 G-197-I005-01)
                        $result.inject_notes.Add(("[co-review] checkpoint review run {0} returned a non-blocking, non-pass verdict ('{1}') - advisory only, NOT counted as gate evidence.{2}" -f $runId, ([string]$verdict.disposition), $threadSuffix)) | Out-Null
                    }
                }
                elseif ($status -eq 'done' -and -not $verdict.ok) {
                    # STATE THE REASON: a done run with no parseable verdict used to be a bare "no verdict"
                    # note (the EnglishIntake unparseable case - the human never learned it was an oversize
                    # input). Surface the SAFE failure category/message from the sidecar so the checkpoint
                    # says WHY; advisory only, never gate evidence.
                    $failReason = Get-ContinuousCoReviewNavigatorFailureReason -RepoRoot $RepoRoot -Registry $reg
                    $reasonSuffix = if (-not [string]::IsNullOrWhiteSpace($failReason)) { (" Reason: {0}." -f $failReason) } else { '' }
                    $result.inject_notes.Add(("[co-review] checkpoint review run {0} completed but produced no parseable verdict (advisory only, NOT gate evidence).{1}" -f $runId, $reasonSuffix)) | Out-Null
                }
                else {
                    $result.inject_notes.Add(("[co-review] checkpoint review run {0} ended '{1}' without a verdict (no blocking signal); a re-review fires on the next changed checkpoint." -f $runId, $status)) | Out-Null
                }
            }
            # Retire the terminal entry (its worktree was already disposed by the supervisor's finally).
            Clear-ContinuousCoReviewNavigatorEntry -RepoRoot $RepoRoot -RegistryPath $regPath -Registry $reg
            $result.reaped_run_ids.Add($runId) | Out-Null
            continue
        }

        # Non-terminal (running). Decide whether it is an orphan to kill/clean.
        $shouldStop = $false
        $reason = 'reaped'
        if ($pastDeadline) {
            # Past its deadline: reap regardless of presence ('present' = wedged/overran its own kill
            # loop; 'unknown' = we cannot prove it alive AND it is overdue). The deadline is an
            # independent terminal signal, so a transient probe error does not save an overdue entry.
            $shouldStop = $true; $reason = 'reaped'
        }
        elseif ($presence -eq 'absent') {
            # Supervisor DEFINITIVELY gone with no terminal status: a DEAD-launcher orphan (worktree may
            # have leaked). Only a not-found result reaches here - a transient 'unknown' does NOT (it
            # falls through to "leave pending" below), so a genuinely-running review is never reaped on a
            # transient Get-Process failure (finding 2).
            $shouldStop = $true; $reason = 'crashed'
        }
        elseif ($CrossSession -and $presence -eq 'present') {
            # Cross-session sweep: a still-"running" entry from a PRIOR session whose supervisor is
            # somehow still alive is a cross-session leak -> kill + clean (a new session must not inherit
            # a prior session's live review).
            $shouldStop = $true; $reason = 'reaped'
        }

        if ($shouldStop) {
            if (Get-Command -Name 'Stop-SpecrewIsolatedTask' -ErrorAction SilentlyContinue) {
                try { $null = Stop-SpecrewIsolatedTask -RegistryPath $regPath -Reason $reason } catch { $null = $_ }
            }
            else {
                # Launcher not loaded (degraded): best-effort inline cleanup so an orphan still gets
                # reaped (kill supervisor + remove worktree + mark terminal).
                Invoke-ContinuousCoReviewNavigatorInlineReap -RegistryPath $regPath -Registry $reg -Reason $reason
            }
            Clear-ContinuousCoReviewNavigatorEntry -RepoRoot $RepoRoot -RegistryPath $regPath -Registry $reg
            $result.reaped_run_ids.Add($runId) | Out-Null
            # HUMAN-GATED STATUS - ONLY on a normal Stop reap, NEVER on the cross-session SessionStart sweep
            # (that cleans PRIOR-session orphans and must stay silent - it is cleanup, not current status).
            if ($reason -eq 'crashed' -and -not $CrossSession) {
                # A DEAD reviewer (supervisor gone, no terminal verdict) is INCONCLUSIVE. Say so rather than
                # reaping it silently, so the human reruns instead of assuming a pass - the gate never
                # advances on an inconclusive run (no passing evidence was collected).
                $result.inject_notes.Add(("[co-review] run {0} did not finish - the reviewer process is gone with no verdict, so this checkpoint is INCONCLUSIVE (not a pass). A fresh review fires on the next changed checkpoint; rerun if you need it now." -f $runId)) | Out-Null
            }
        }
        elseif (-not $CrossSession) {
            # HUMAN-GATED STATUS: a genuinely-running review is left PENDING (correct) - but SAY SO. It was
            # silent before, so 'continue' was a blind guess. Now each Stop/continue reports it is still in
            # flight; the verdict is surfaced the moment it finishes. The human drives the poll by continuing
            # (the host-neutral "wake" - every host has a human + a Stop, none has a portable auto-wake).
            $result.inject_notes.Add(("[co-review] run {0} is still reviewing in the background - say 'continue' to check again, or keep working; its verdict is surfaced here as soon as it finishes." -f $runId)) | Out-Null
        }
    }
    return $result
}

function Invoke-ContinuousCoReviewNavigatorInlineReap {
    # Degraded backstop for the orphan-kill path when Stop-SpecrewIsolatedTask (the launcher) could not
    # be loaded. Mirrors its three steps: kill the supervisor pid, remove the worktree, mark the
    # registry terminal. Idempotent + fail-open.
    param([Parameter(Mandatory)][string]$RegistryPath, [AllowNull()]$Registry, [string]$Reason = 'reaped')
    try {
        $supPid = if ($null -ne $Registry -and ($Registry.PSObject.Properties.Name -contains 'supervisor_pid')) { $Registry.supervisor_pid } else { $null }
        if ($supPid) {
            try { $null = Get-Process -Id ([int]$supPid) -ErrorAction Stop; Stop-Process -Id ([int]$supPid) -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
        }
        $wt = if ($null -ne $Registry -and ($Registry.PSObject.Properties.Name -contains 'worktree_path')) { [string]$Registry.worktree_path } else { $null }
        # The worktree is a `git archive | tar` EXPORT into a plain temp dir (see
        # New-SpecrewIsolatedTaskWorktree: RO path = `git archive --output <tar>` + `tar -xf`, NOT
        # `git worktree add`), so there is NO `.git/worktrees/<id>` admin metadata to prune.
        # Remove-Item -Recurse -Force is therefore the COMPLETE + correct cleanup (no `git worktree
        # remove`/`prune` needed) - finding 4.
        if ($wt -and (Test-Path -LiteralPath $wt)) { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $RegistryPath -PathType Leaf) {
            try {
                $reg = Get-Content -LiteralPath $RegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $reg | Add-Member -NotePropertyName 'status' -NotePropertyValue $Reason -Force
                $reg | Add-Member -NotePropertyName 'reaped_at' -NotePropertyValue ((Get-Date).ToUniversalTime().ToString('o')) -Force
                ($reg | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $RegistryPath -Encoding UTF8
            }
            catch { $null = $_ }
        }
    }
    catch { $null = $_ }
}

function Test-ContinuousCoReviewVerdictIsPromotablePass {
    # The CANONICAL "is this an affirmative pass that may promote to durable gate evidence?" decision, used by BOTH
    # producers: the navigator reap (detached path) and the /specrew-review inline door (the host-neutral F3
    # checkpoint, for a straight-through host whose Stop hook never fires the reap). Promote ONLY on an affirmative
    # disposition (pass/approved/clean/no-findings) - NEVER on mere absence-of-blocking (a needs-work / partial /
    # unparseable verdict must not launder to a gate pass), and NEVER on the placeholder stub. Mirrors the reap's
    # inline elseif-chain so the two producers agree by construction.
    param([AllowNull()]$Verdict)
    if ($null -eq $Verdict) { return $false }
    $ok = ($Verdict.PSObject.Properties['ok']) -and [bool]$Verdict.ok
    if (-not $ok) { return $false }
    if (($Verdict.PSObject.Properties['blocking']) -and [bool]$Verdict.blocking) { return $false }
    if (($Verdict.PSObject.Properties['is_stub']) -and [bool]$Verdict.is_stub) { return $false }
    $disp = if ($Verdict.PSObject.Properties['disposition']) { [string]$Verdict.disposition } else { '' }
    return ($disp -match '(?i)^\s*(pass|approved|clean|no.?findings)\s*$')
}

function Add-ContinuousCoReviewNavigatorPassRunRecord {
    # PART 2 (FR-024 gate wiring): promote a reaped NON-BLOCKING PASS to a DURABLE passing-run record
    # the signoff gate (Get-ContinuousCoReviewSignoffGateDecision) accepts. The gate checks THREE
    # things, not just freshness, so a record carrying only the tree-id would still be REJECTED:
    #   1. FRESHNESS  - a passing run's reviewed_tree_id == the current reviewed-state digest. We record
    #                   the tree-id the navigator actually FIRED on (the registry's tree_id).
    #   2. LINEAGE    - reviewed_ref must be a real commit that is an ancestor-of-or-equal-to HEAD. We
    #                   record HEAD-at-reap (equal-to-itself satisfies the ancestor test).
    #   3. COVERAGE   - the chain's baseline_ref must be ancestor-of-or-equal-to the merge-base anchor.
    #                   We record baseline_ref = the merge-base-with-trunk anchor itself, so the
    #                   single-link chain reaches the anchor immediately (no gap).
    # status MUST be 'pass' (the writer maps GateVerdict.state -> status; the gate only accepts
    # pass|escalated). Writes via the EXISTING writer Write-ContinuousCoReviewRunIndex, which lands the
    # record at .specrew/review/inline/<run-id>/review-run.json - the path the gate reader actually
    # walks (NOT .specrew/review/runs/, which the design comments name but no shipped gate code reads;
    # see the navigator-hardening report). Fail-open: ANY failure (missing dep, no anchor, unresolvable
    # HEAD, writer throw) returns $null and the reap proceeds without promotion (a blocking gate at
    # signoff is the safe outcome of a missing record, never a false pass).
    #
    # LAZY DEP-LOAD, INLINE BY DESIGN (do NOT extract to a helper): on the PRODUCTION path the provider
    # dot-sources only THIS navigator (which loads the launcher); the run-index writer + its deps live in
    # _load.ps1, NOT loaded there. We load _load.ps1 HERE, in THIS function's scope, so the dot-sourced
    # Write-ContinuousCoReviewRunIndex (+ its transitive deps) resolve via the call-stack walk from the
    # Write-... call BELOW. A separate "Initialize-deps" function CANNOT work: PowerShell dot-sources into
    # the CALLEE's scope, which dies on return, so the writer would vanish before this function used it
    # (verified). Loading here is paid only on an actual PASS promotion (rare), never on the hot Stop reap.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$RunId,
        [AllowNull()][string]$TreeId,
        [string]$TrunkName = 'main',
        [datetime]$Now = [datetime]::UtcNow
    )
    try {
        if ([string]::IsNullOrWhiteSpace($RunId) -or [string]::IsNullOrWhiteSpace($TreeId)) { return $null }

        # Lazily bring in the writer + its deps INTO THIS SCOPE (see the header note). Idempotent: if
        # _load already ran (e.g. the in-process test path), Get-Command short-circuits the dot-source.
        if (-not (Get-Command -Name 'Write-ContinuousCoReviewRunIndex' -ErrorAction SilentlyContinue)) {
            try {
                $loadPath = Join-Path $PSScriptRoot '_load.ps1'
                if (Test-Path -LiteralPath $loadPath -PathType Leaf) { . $loadPath }
            }
            catch { $null = $_ }
        }
        if (-not (Get-Command -Name 'Write-ContinuousCoReviewRunIndex' -ErrorAction SilentlyContinue)) { return $null }

        # Idempotence: if a durable record for this run already exists, do not re-promote (the writer
        # would throw on a content mismatch; a second reap of the same run is a no-op).
        $existing = Join-Path $RepoRoot (".specrew/review/inline/$RunId/review-run.json")
        if (Test-Path -LiteralPath $existing -PathType Leaf) { return $RunId }

        # COVERAGE anchor = merge-base with trunk. No anchor -> cannot prove coverage -> skip promotion
        # (the gate would block at signoff; a missing record is the safe outcome).
        if (-not (Get-Command -Name 'Get-ContinuousCoReviewMergeBaseAnchor' -ErrorAction SilentlyContinue)) { return $null }
        $anchor = Get-ContinuousCoReviewMergeBaseAnchor -RepoRoot $RepoRoot -TrunkName $TrunkName
        if ([string]::IsNullOrWhiteSpace([string]$anchor)) { return $null }

        # LINEAGE ref = current HEAD (via the encoding-immune git helper - raw `& git` throws the
        # StandardOutputEncoding error in the hook provider context).
        $reviewedRef = $null
        if (Get-Command -Name 'Invoke-ContinuousCoReviewGit' -ErrorAction SilentlyContinue) {
            $headResult = Invoke-ContinuousCoReviewGit -RepoRoot $RepoRoot -Arguments @('rev-parse', 'HEAD')
            if ($headResult.ExitCode -eq 0 -and @($headResult.Output).Count -gt 0) {
                $headCandidate = ([string]$headResult.Output[0]).Trim()
                if ($headCandidate -match '^[0-9a-f]{40}$') { $reviewedRef = $headCandidate }
            }
        }
        if ([string]::IsNullOrWhiteSpace($reviewedRef)) { return $null }

        # A pass GateVerdict so the writer records status='pass' (the gate's accepted set).
        $checkpointId = "nav-$RunId"
        if (-not (Get-Command -Name 'New-ContinuousCoReviewGateVerdict' -ErrorAction SilentlyContinue)) { return $null }
        $verdict = New-ContinuousCoReviewGateVerdict -RunId $RunId -CheckpointId $checkpointId -State 'pass' -RoundCount 1 -CreatedAt $Now

        $null = Write-ContinuousCoReviewRunIndex -RepoRoot $RepoRoot -RunId $RunId -CheckpointId $checkpointId `
            -BaselineRef ([string]$anchor) -ReviewedRef $reviewedRef -ReviewedTreeId $TreeId `
            -GateVerdict $verdict -CreatedAt $Now
        return $RunId
    }
    catch { $null = $_; return $null }
}

function Build-ContinuousCoReviewNavigatorStopBlock {
    # The directive body a blocking co-review verdict force-continues the turn with (the dispatcher
    # wraps it in the host's stop-block envelope). Names the finding so the human/agent acts on it.
    param([Parameter(Mandatory)]$Verdict, [AllowNull()][string]$RunId, [AllowNull()][string]$BlackboardRef)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('Specrew co-review (navigator): the fresh-context checkpoint review of your latest increment returned a BLOCKING finding. Address it before continuing, then re-stop:')
    [void]$sb.AppendLine(("- run {0}: {1}" -f $RunId, $Verdict.summary))
    if ($null -ne $Verdict.raw -and ($Verdict.raw.PSObject.Properties.Name -contains 'findings') -and $null -ne $Verdict.raw.findings) {
        foreach ($f in @($Verdict.raw.findings)) {
            $sev = if ($null -ne $f -and ($f.PSObject.Properties.Name -contains 'severity')) { [string]$f.severity } else { '' }
            $disp = if ($null -ne $f -and ($f.PSObject.Properties.Name -contains 'disposition')) { [string]$f.disposition } else { '' }
            if ($sev -match '(?i)^(blocking|block|critical|high)$' -or $disp -match '(?i)^block') {
                $loc = if ($f.PSObject.Properties.Name -contains 'location') { [string]$f.location } else { '' }
                $cmt = if ($f.PSObject.Properties.Name -contains 'comment') { [string]$f.comment } else { '' }
                [void]$sb.AppendLine(("  BLOCKING {0}{1}" -f ($(if ($loc) { "[$loc] " } else { '' })), $cmt))
            }
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($BlackboardRef)) {
        [void]$sb.AppendLine(("Full findings (all severities) - the durable review thread: {0}" -f $BlackboardRef))
    }
    [void]$sb.AppendLine('This is a co-review navigator block (not a boundary verdict); do NOT emit a SPECREW-VERDICT-BOUNDARY marker. The review ran in an isolated read-only worktree; nothing was changed in your tree.')
    return $sb.ToString().TrimEnd()
}

function Get-ContinuousCoReviewNavigatorImplementStage {
    # Map the active boundary cursor (start-context.json session_state.boundary_type) to the gate-review
    # registry stage. Implementation work happens AFTER the before-implement verdict is authorized and
    # BEFORE review-signoff, so the cursor reads 'before-implement' during active implementation. The
    # registry routes the stage 'implement'. So: a cursor that normalizes to 'before-implement' IS the
    # implementation window -> return 'implement' (the registered stage). Anything else -> $null (the
    # navigator only auto-fires the implement-stage code reviewer; other stages are unregistered no-ops).
    param([Parameter(Mandatory)][string]$RepoRoot)
    $scPath = Join-Path $RepoRoot '.specrew/start-context.json'
    if (-not (Test-Path -LiteralPath $scPath -PathType Leaf)) { return $null }
    try {
        $sc = Get-Content -LiteralPath $scPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $boundary = $null
        if ($sc.PSObject.Properties['session_state'] -and $null -ne $sc.session_state -and $sc.session_state.PSObject.Properties['boundary_type']) {
            $boundary = [string]$sc.session_state.boundary_type
        }
        # start-context schema v2 has NO session_state cursor; the boundary lives under boundary_enforcement.
        # last_authorized_boundary normalizes to 'before-implement' during active implementation - exactly the
        # value the old session_state.boundary_type cursor carried at that point (see the comment above and the
        # firing window: the navigator only fires DURING implement) - so the implement-stage check below is
        # behavior-preserving; this only reads the migrated field. The iter-007 real-host dogfood proved the
        # navigator was reading the dead old field on a v2 project and silently no-opping every checkpoint.
        if ([string]::IsNullOrWhiteSpace($boundary) -and $sc.PSObject.Properties['boundary_enforcement'] -and $null -ne $sc.boundary_enforcement -and $sc.boundary_enforcement.PSObject.Properties['last_authorized_boundary']) {
            $boundary = [string]$sc.boundary_enforcement.last_authorized_boundary
        }
        if ([string]::IsNullOrWhiteSpace($boundary)) { return $null }
        if (Get-Command -Name 'Normalize-SpecrewCanonicalBoundaryType' -ErrorAction SilentlyContinue) {
            $norm = Normalize-SpecrewCanonicalBoundaryType -Boundary $boundary
        }
        else {
            $norm = $boundary.Trim().ToLowerInvariant()
        }
        if ($norm -eq 'before-implement' -or $norm -eq 'implement') { return 'implement' }
        return $null
    }
    catch { return $null }
}

