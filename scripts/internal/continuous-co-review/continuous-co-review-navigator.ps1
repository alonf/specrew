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
        $treeId = if ($null -ne $reg -and ($reg.PSObject.Properties.Name -contains 'tree_id')) { [string]$reg.tree_id } else { $null }

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

function New-ContinuousCoReviewNavigatorReviewerPlan {
    # T082 (FIRE, in-repo): build everything the detached reviewer needs that REQUIRES in-repo resources
    # (the git history, the catalog/install-probe/authorization state, the feature's design context and
    # the canonical reviewer instruction). This is the orchestrator's SELECT + REQUEST-BUILD seams, run
    # in-repo at fire; the detached -Command then runs ONLY the EXECUTE seam against the worktree. The
    # request is pre-built here (diff + design context + code-review-agent.md all resolve under the real
    # repo root) and serialized to the run dir; the detached command loads it and passes it straight into
    # the execution engine, which re-serializes it INTO the worktree so the host's cwd stays inside the
    # disposable export (the read-only primary control). Returns a plan object, or $null to FAIL OPEN
    # (the caller fires NO real review - never a stub) on any missing prerequisite.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$TreeId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$RunDir,
        [AllowNull()][string]$BaselineRef,
        [AllowNull()][string]$CodeWriterHost,
        [int]$ReviewerTimeoutSec = 300,
        [string]$TrunkName = 'main',
        [datetime]$Now = [datetime]::UtcNow
    )

    # The execution engine + request builder + catalog/selection must be loaded (the provider path
    # dot-sources only the navigator + launcher; _load brings these in). A miss -> no real review.
    if (-not (Get-Command -Name 'New-ContinuousCoReviewRequest' -ErrorAction SilentlyContinue)) {
        try {
            $loadPath = Join-Path $PSScriptRoot '_load.ps1'
            if (Test-Path -LiteralPath $loadPath -PathType Leaf) { . $loadPath }
        }
        catch { $null = $_ }
    }
    foreach ($fn in @('New-ContinuousCoReviewRequest', 'Get-ContinuousCoReviewCheckpointDiff', 'Get-ContinuousCoReviewReviewerHostCatalog', 'Select-ContinuousCoReviewReviewerCandidate')) {
        if (-not (Get-Command -Name $fn -ErrorAction SilentlyContinue)) { return $null }
    }

    # MODULE BASE (HAZARD A): resolved from this file's own location; threaded into the -Command so the
    # detached pwsh can dot-source _load.ps1 from the REAL tree, not its worktree cwd.
    $moduleBase = Get-ContinuousCoReviewNavigatorModuleBase
    if ([string]::IsNullOrWhiteSpace($moduleBase)) { return $null }

    # SELECT (host-neutral): pick a code-writer-INDEPENDENT reviewer host. The code-writer host is the
    # CURRENT host (the one that just stopped); the policy maps claude->codex, codex->claude. NO
    # host-name literal enters this logic - the policy owns the mapping. install/allowed/authorization
    # are repo/host facts resolved HERE, in-repo.
    # M1 fix (145 iter-006): the code-writer host is threaded as -CodeWriterHost from the dispatcher's
    # --host-kind (the provider passes it). SPECREW_HOST/SPECREW_ACTIVE_HOST are the FALLBACK only -
    # Specrew does not set them in a hook child, so WITHOUT the threaded host the policy would tiebreak
    # alphabetically and could pick the code-writer's OWN host (not independent). Authorization config
    # contains the blast radius today, but the independence is now real-by-logic, not config-incidental.
    $resolvedCodeWriterHost = $CodeWriterHost
    if ([string]::IsNullOrWhiteSpace($resolvedCodeWriterHost)) {
        foreach ($var in 'SPECREW_HOST', 'SPECREW_ACTIVE_HOST') {
            $val = [System.Environment]::GetEnvironmentVariable($var)
            if (-not [string]::IsNullOrWhiteSpace($val)) { $resolvedCodeWriterHost = $val; break }
        }
    }
    # T086 (145 iter-006): LOAD the persisted HUMAN-authorized reviewer config (.specrew/reviewer-hosts.json)
    # READ-ONLY. The default catalog ships every host allowed=$false, so without a project authorization
    # there is NO eligible host -> $null candidate -> fail-open (no review, never a stub). A human authorizes
    # once via `specrew review --host <h> --authorization-ref <ref>` (which persists this file); the navigator
    # only READS it - it NEVER writes or self-authorizes (the authorization_ref is the human-provenance
    # anchor; the Proposal 190 self-authorization hole). Absent/unparseable -> $null -> the default -> fail-open.
    $reviewerHostsPath = Join-Path $RepoRoot '.specrew/reviewer-hosts.json'
    # INT-006 bridge (iter-007): if no authorization is persisted yet, sync it from the code-implementation
    # lens's HUMAN reviewer choice (the feature's implementation-rules.yml reviewer_preference). The lens
    # already ASKS the question and records the answer there, but nothing connected it to this catalog -> the
    # human-selected reviewer was captured yet never authorized -> silent fail-open. The bridge authorizes
    # ONLY a human-selected host (never auto-authorizes - SEC-004 / Proposal 190). Deterministic + idempotent.
    if (-not (Test-Path -LiteralPath $reviewerHostsPath -PathType Leaf)) {
        if (Get-Command -Name 'Sync-ContinuousCoReviewReviewerAuthorizationFromWorkshop' -ErrorAction SilentlyContinue) {
            try { $null = Sync-ContinuousCoReviewReviewerAuthorizationFromWorkshop -RepoRoot $RepoRoot } catch { $null = $_ }
        }
    }
    $reviewerConfig = $null
    if (Test-Path -LiteralPath $reviewerHostsPath -PathType Leaf) {
        try { $reviewerConfig = (Get-Content -LiteralPath $reviewerHostsPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100) } catch { $reviewerConfig = $null }
    }
    $catalog = Get-ContinuousCoReviewReviewerHostCatalog -Configuration $reviewerConfig
    $candidate = Select-ContinuousCoReviewReviewerCandidate -Catalog $catalog -CodeWriterHost $resolvedCodeWriterHost
    if ($null -eq $candidate) { return $null }   # no authorized independent host installed -> no review.

    # CANDIDATE TIMEOUT (condition-c, the SECOND timeout): the adapter kills the reviewer subprocess at
    # candidate.timeout_seconds (default 30 - far below a real codex run). Thread the raised co-review
    # timeout onto the selected candidate so the host call actually has ~300s, not 30s.
    $candidate | Add-Member -NotePropertyName 'timeout_seconds' -NotePropertyValue ([int]$ReviewerTimeoutSec) -Force

    # FEATURE + DESIGN CONTEXT: ReviewRequest.v2 requires >=1 design-context ref. Resolve the active
    # feature dir generically and collect spec.md + the latest design-analysis. None -> no real review.
    $featureRoot = Get-ContinuousCoReviewNavigatorFeatureRoot -RepoRoot $RepoRoot
    if ([string]::IsNullOrWhiteSpace($featureRoot)) { return $null }
    $designRefs = @(Get-ContinuousCoReviewNavigatorDesignContextRefs -RepoRoot $RepoRoot -FeatureRoot $featureRoot)
    if (@($designRefs).Count -eq 0) { return $null }

    # BASELINE: the merge-base-with-trunk anchor (the live-review + signoff-gate anchor). Resolve here if
    # the caller did not supply it. No baseline -> cannot diff -> no real review.
    $resolvedBaseline = $BaselineRef
    if ([string]::IsNullOrWhiteSpace($resolvedBaseline) -and (Get-Command -Name 'Get-ContinuousCoReviewMergeBaseAnchor' -ErrorAction SilentlyContinue)) {
        $resolvedBaseline = Get-ContinuousCoReviewMergeBaseAnchor -RepoRoot $RepoRoot -TrunkName $TrunkName
    }
    if ([string]::IsNullOrWhiteSpace($resolvedBaseline)) { return $null }

    # DIFF + REQUEST (in-repo, against the REAL repo): the orchestrator's diff/request seams. The diff is
    # computed against the real repo's git history (the worktree has no .git). A non-reviewable diff (no
    # changed paths) or a build throw -> no real review (fail-open).
    $checkpointId = "nav-$RunId"
    try {
        # SCAFFOLDING EXCLUSION (the noise fix): the auto-fired review covers USER-AUTHORED code only, not
        # the Specrew/host-DEPLOYED scaffolding the project carries (dotdirs, the shadowed co-review copy,
        # CLAUDE.md/AGENTS.md). On the EnglishIntake dogfood that was 706 files / 5.1 MB -> ~34 files /
        # 340 KB - the difference between a reviewer-host-input-overflow (unparseable) and a real review.
        # The default is principled + project-configurable (Get-...DefaultExcludedPathPatterns); the
        # provider's own param default stays @() so every OTHER caller (gate dispatch, signoff coverage,
        # digest) is unchanged.
        $excludedPatterns = @(Get-ContinuousCoReviewDefaultExcludedPathPatterns -RepoRoot $RepoRoot)
        $changeSet = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $RepoRoot -BaselineRef $resolvedBaseline -CheckpointId $checkpointId -ExcludedPathPatterns $excludedPatterns -RunId $RunId
        if ($null -eq $changeSet -or ([string]$changeSet.status) -ne 'reviewable') { return $null }

        $providerRequest = [pscustomobject][ordered]@{
            requested_host    = $null
            requested_model   = $null
            code_writer_host  = $resolvedCodeWriterHost
            authorization_ref = $candidate.authorization_ref
            timeout_seconds   = [int]$ReviewerTimeoutSec
            fallback_policy   = 'none'
        }
        # The CANONICAL REVIEWER INSTRUCTION (code-review-agent.md) lives under the SPECREW MODULE BASE,
        # NOT under the reviewed project root. New-ContinuousCoReviewRequest resolves it relative to
        # -RepoRoot by default, which would fail for any project that is not the Specrew repo itself. So
        # build the instruction metadata from the module base here and pass it in (the builder then skips
        # its own RepoRoot-relative file resolution). The design-context refs DO live in the reviewed
        # project (the feature dir), so those correctly resolve under -RepoRoot.
        $reviewerInstruction = $null
        if (Get-Command -Name 'New-ContinuousCoReviewReviewerInstructionMetadata' -ErrorAction SilentlyContinue) {
            $reviewerInstruction = New-ContinuousCoReviewReviewerInstructionMetadata -RepoRoot $moduleBase
        }
        $request = New-ContinuousCoReviewRequest -RunId $RunId -CheckpointId $checkpointId -BaselineRef $resolvedBaseline `
            -ChangeSet $changeSet -DesignContextRefs $designRefs -ProviderRequest $providerRequest `
            -ReviewerInstruction $reviewerInstruction -RepoRoot $RepoRoot -CreatedAt $Now
    }
    catch { return $null }

    # Serialize the pre-built request + the selected candidate to the IN-REPO run dir. The detached
    # command reads these (they are inputs, not durable records - the run dir is reaped after).
    try {
        if (-not (Test-Path -LiteralPath $RunDir -PathType Container)) { New-Item -ItemType Directory -Path $RunDir -Force | Out-Null }
        $requestPath = Join-Path $RunDir 'reviewer-request.json'
        $candidatePath = Join-Path $RunDir 'reviewer-candidate.json'
        ($request | ConvertTo-Json -Depth 100) | Set-Content -LiteralPath $requestPath -Encoding UTF8
        ($candidate | ConvertTo-Json -Depth 20) | Set-Content -LiteralPath $candidatePath -Encoding UTF8
    }
    catch { return $null }

    return [pscustomobject]@{
        module_base    = $moduleBase
        request_path   = $requestPath
        candidate_path = $candidatePath
        candidate      = $candidate
        request        = $request
        design_refs    = @($designRefs)
        feature_root   = $featureRoot
        baseline_ref   = $resolvedBaseline
        reviewer_timeout_seconds = [int]$ReviewerTimeoutSec
    }
}

function Build-ContinuousCoReviewNavigatorReviewerCommand {
    # The reviewer harness -Command (a pwsh string the supervisor runs IN the worktree, cwd = the
    # materialized read-only snapshot). T082 wires the REAL policy-driven reviewer:
    #   - An explicit -ReviewerCommandOverride (a test's fast dummy) STILL wins.
    #   - With a $Plan (built in-repo at fire by New-...ReviewerPlan), emit a THIN command that
    #     dot-sources the resolved Specrew module base (HAZARD A: by ABSOLUTE path, not cwd-relative),
    #     reads the pre-built request + selected candidate from the in-repo run dir, runs
    #     Invoke-ContinuousCoReviewReviewerExecution against the worktree (-SkipMutationGuard: the
    #     isolated read-only export is the primary control - condition-b), and writes the resulting
    #     FindingsResult.v1 to STDOUT (the channel the reaper parses). On an infrastructure-failure it
    #     emits NOTHING so the reap degrades to the "ended without a verdict" advisory note.
    #   - With NEITHER an override NOR a plan, fall back to the verdict-emitting stub (reviewer='stub'):
    #     the navigator plumbing still proves out, but the stub never promotes to gate evidence (the
    #     is_stub guard). This path is reached only when the in-repo prerequisites for a real review are
    #     absent (no feature/design context, no reviewable diff, no authorized independent host).
    # HAZARD B (threading): the launcher passes -Command as a STRING job payload (not -ArgumentList), so
    # the command embeds only ABSOLUTE FILE PATHS (the module base + the two run-dir json files) as
    # single-quoted PowerShell literals - no host/model object is interpolated into code. Single-quoting
    # + doubling embedded single quotes is correct on BOTH Windows and Linux (no shell re-parsing - pwsh
    # -Command receives the literal string from the job spec).
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$TreeId,
        [AllowNull()][string]$ReviewerCommandOverride,
        [AllowNull()]$Plan
    )
    if (-not [string]::IsNullOrWhiteSpace($ReviewerCommandOverride)) { return $ReviewerCommandOverride }

    if ($null -ne $Plan) {
        # Single-quote a path as a PowerShell literal (double any embedded single quote).
        $q = { param($s) "'" + ([string]$s).Replace("'", "''") + "'" }
        $moduleBaseLit = & $q $Plan.module_base
        $requestLit = & $q $Plan.request_path
        $candidateLit = & $q $Plan.candidate_path

        return @"
`$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
# T082 detached reviewer EXECUTE seam (cwd = the isolated read-only worktree; NO .git, NO Specrew scripts).
# HAZARD A: dot-source the execution engine + adapters + contracts from the REAL module base (absolute),
# resolved in-repo at fire - NOT from this cwd.
`$moduleBase = $moduleBaseLit
`$loadPath = Join-Path `$moduleBase 'scripts/internal/continuous-co-review/_load.ps1'
. `$loadPath
# The request + selected candidate were built IN-REPO (real git history + design context + the canonical
# reviewer instruction) and serialized to the run dir; load them as inputs.
`$request = Get-Content -LiteralPath $requestLit -Raw -Encoding UTF8 | ConvertFrom-Json
`$candidate = Get-Content -LiteralPath $candidateLit -Raw -Encoding UTF8 | ConvertFrom-Json
# EXECUTE against the worktree. -RunRoot is a subdir of THIS worktree (cwd), so the engine re-serializes
# the request and the host's working dir stay INSIDE the disposable export (the read-only primary control,
# condition-b). -SkipMutationGuard: the in-repo guard cannot function on this path (its Specrew-own roots +
# git status are absent in the export) - the export itself is the guarantee; the skip is stamped on the result.
`$runRoot = Join-Path `$PWD.Path '.specrew-reviewer-run'
`$execution = Invoke-ContinuousCoReviewReviewerExecution -Request `$request -RunRoot `$runRoot -Candidates @(`$candidate) -SkipMutationGuard
if (`$null -ne `$execution -and ([string]`$execution.kind) -eq 'findings-result' -and `$null -ne `$execution.findings_result) {
    [Console]::Out.Write((`$execution.findings_result | ConvertTo-Json -Depth 100 -Compress))
}
else {
    # STATE THE REASON (NFR-001): the host produced no findings-result (timeout / nonzero-exit /
    # input-too-large / schema-mismatch / unauthorized). result.out stays EMPTY so the reaper never reads a
    # malformed verdict or a false PASS - but persist the SAFE failure category + message to a sidecar in the
    # run dir, so the reaper surfaces WHY instead of a bare "no parseable verdict". Best-effort (a write miss
    # just falls back to the generic advisory). The category/message are already secret-scrubbed by the
    # contract; no stdout/stderr/prompt content is written here.
    try {
        `$failCat = if (`$null -ne `$execution -and `$null -ne `$execution.infrastructure_failure) { [string]`$execution.infrastructure_failure.category } else { 'no-findings-result' }
        `$failMsg = if (`$null -ne `$execution -and `$null -ne `$execution.infrastructure_failure) { [string]`$execution.infrastructure_failure.message } else { 'Reviewer produced no parseable findings-result.' }
        `$failPath = Join-Path (Split-Path -Parent $requestLit) 'review-failure.json'
        ([pscustomobject][ordered]@{ schema_version = '1.0'; status = 'infrastructure-failure'; category = `$failCat; message = `$failMsg } | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath `$failPath -Encoding UTF8
    }
    catch { `$null = `$_ }
}
"@
    }

    # No override and no plan: the verdict-emitting stub (plumbing only; never gate evidence).
    return @"
`$ErrorActionPreference = 'Stop'
# (No real-reviewer plan was built - missing feature/design context, no reviewable diff, or no authorized
# independent host. Emit a structurally-valid stub verdict so the plumbing still proves out; the is_stub
# marker keeps it OUT of gate evidence.)
`$verdict = [ordered]@{
    schema_version = '1.0'
    run_id         = '$TreeId'
    status         = 'no_findings'
    disposition    = 'pass'
    blocking       = `$false
    findings       = @()
    reviewed_root  = `$PWD.Path
    reviewer       = 'stub'
}
[Console]::Out.Write((`$verdict | ConvertTo-Json -Depth 6 -Compress))
"@
}

function Invoke-ContinuousCoReviewNavigator {
    # The navigator entry the dispatcher-facing loader calls on each Stop (and, with -SessionStart, on
    # SessionStart). FAST + non-blocking: reap, then maybe fire, then return a decision object. It NEVER
    # waits for a review. The loader translates the returned decision into the dispatcher's stdout
    # contract (a stop_block -> the <<<SPECREW-STOP-BLOCK>>> sentinel; inject_notes -> a plain inject;
    # nothing on a no-op).
    param(
        [Parameter(Mandatory)][string]$RepoRoot,

        # SessionStart sweep mode: reap cross-session orphans only (no fire, no verdict surfacing).
        [switch]$SessionStart,

        # The LAUNCHER/SUPERVISOR timeout (how long the supervisor lets the whole detached task run before
        # a hard kill). 0 (the production default) = DERIVE it from the co-review timeout config (the
        # reviewer/adapter budget) plus a buffer, so the supervisor budget always sits ABOVE the adapter
        # budget and the adapter times out GRACEFULLY before the supervisor hard-kills (condition-c). A
        # caller that passes an explicit value (the test suite's fast 30s) wins verbatim. iteration 002
        # proved a real codex review needs ~300s, so the derived default clears it.
        [int]$TimeoutSec = 0,

        # The REVIEWER/ADAPTER timeout (the host-call budget threaded onto the selected candidate, which
        # is where the adapter actually kills the codex/claude subprocess). 0 = read it from
        # .specrew/config.yml co_review_timeout_seconds (default 300). This is the SECOND, distinct timeout
        # from the launcher budget above (Catch: the adapter's candidate.timeout_seconds default is 30,
        # far below a real codex run; this raises it).
        [int]$ReviewerTimeoutSec = 0,

        # The trunk the checkpoint baseline merge-bases against (threaded like the rest of the gate).
        [string]$TrunkName = 'main',

        # M1 fix (145 iter-006): the CODE-WRITER host (the host that just stopped), threaded from the
        # dispatcher's --host-kind by the provider, so reviewer selection is code-writer-INDEPENDENT by
        # logic (not merely by authorization config). Empty -> the plan falls back to
        # SPECREW_HOST/SPECREW_ACTIVE_HOST (unset in a hook child today), then the policy rank/tiebreak.
        [AllowNull()][string]$CodeWriterHost,

        # Test/real-reviewer seam: override the default verdict-emitting stub -Command.
        [AllowNull()][string]$ReviewerCommandOverride,

        # Test seam: inject the dispatch decision instead of computing it (so a unit test need not stand
        # up a full lifecycle). When omitted, the navigator computes it from the stage + checkpoint.
        [AllowNull()][bool]$CheckpointReachedOverride,

        [datetime]$Now = [datetime]::UtcNow
    )

    # FAIL-OPEN IS THE CONTRACT (finding 3): the navigator must NEVER throw to the dispatcher - any
    # internal error returns a no-op decision so the merged Stop result is never perturbed. This does
    # NOT depend on the loader's own guard; the whole body is wrapped here and Set-StrictMode is on
    # INSIDE so even a strict-mode violation (unset var / missing property) fails open rather than
    # bubbling. The decision object is built FIRST so the catch can return it as a clean no-op.
    Set-StrictMode -Version Latest

    $decision = [pscustomobject]@{
        mode             = $(if ($SessionStart) { 'sweep' } else { 'stop' })
        action           = 'no-op'
        reason           = $null
        stop_block       = $null
        inject_notes     = @()
        fired_run_id     = $null
        fired_tree_id    = $null
        reaped_run_ids   = @()
        promoted_run_ids = @()
    }

    try {
        # TIMEOUT RESOLUTION (condition-c). Two distinct budgets:
        #   - $resolvedReviewerTimeout: the host-call (adapter) budget, read from config (default 300),
        #     threaded onto the selected candidate so the adapter does not kill codex at its 30s default.
        #   - $resolvedTimeoutSec: the launcher/supervisor budget. An explicit -TimeoutSec wins (the test
        #     suite's fast 30s); otherwise it is DERIVED as the reviewer budget + a 60s buffer so the
        #     supervisor always sits above the adapter (the adapter times out gracefully first).
        $resolvedReviewerTimeout = if ($ReviewerTimeoutSec -gt 0) { $ReviewerTimeoutSec } else { Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $RepoRoot }
        $resolvedTimeoutSec = if ($TimeoutSec -gt 0) { $TimeoutSec } else { $resolvedReviewerTimeout + 60 }

        # 1) REAP first (always). SessionStart -> cross-session sweep (orphan kill/clean only). TrunkName
        #    threads through so a reaped PASS promotes against the right merge-base anchor.
        $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $RepoRoot -CrossSession:$SessionStart -TrunkName $TrunkName -Now $Now
        $decision.stop_block = $reap.stop_block
        $decision.inject_notes = @($reap.inject_notes)
        $decision.reaped_run_ids = @($reap.reaped_run_ids)
        $decision.promoted_run_ids = @($reap.promoted_run_ids)

        if ($SessionStart) {
            $decision.action = $(if (@($reap.reaped_run_ids).Count -gt 0) { 'swept' } else { 'no-op' })
            $decision.reason = 'session-start-sweep'
            return $decision
        }

    # If a reaped verdict is blocking, the stop already owes a STOP-BLOCK this turn; still proceed to
    # consider firing the NEXT review (the blocking finding is about the PRIOR increment; a fresh
    # increment still deserves its own review). But a fire is gated on a real, changed checkpoint below.

    # 2) FIRE? Only at a real implement checkpoint with a changed reviewed tree-id (dedup).
    $stage = Get-ContinuousCoReviewNavigatorImplementStage -RepoRoot $RepoRoot
    if ([string]::IsNullOrWhiteSpace($stage)) {
        $decision.reason = 'not-in-implement-stage'
        return $decision   # no-op (emits nothing) outside the implementation window.
    }

    # Reuse the Phase A dispatch detection (do NOT re-derive checkpoint logic). The baseline is the
    # trunk merge-base (NOT HEAD - HEAD is empty right after a semantic commit), matching the live
    # review + signoff gate anchor.
    if (-not (Get-Command -Name 'Invoke-ContinuousCoReviewGateDispatch' -ErrorAction SilentlyContinue)) {
        $decision.reason = 'dispatch-unavailable'
        return $decision   # degraded: the CCR logic is not loaded; fail-open no-op.
    }

    $baselineRef = $null
    if (Get-Command -Name 'Get-ContinuousCoReviewMergeBaseAnchor' -ErrorAction SilentlyContinue) {
        $baselineRef = Get-ContinuousCoReviewMergeBaseAnchor -RepoRoot $RepoRoot -TrunkName $TrunkName
    }

    $dispatchParams = @{ RepoRoot = $RepoRoot; Stage = $stage; BaselineRef = $baselineRef }
    if ($PSBoundParameters.ContainsKey('CheckpointReachedOverride') -and $null -ne $CheckpointReachedOverride) {
        $dispatchParams['CheckpointReached'] = [bool]$CheckpointReachedOverride
    }
    $dispatch = Invoke-ContinuousCoReviewGateDispatch @dispatchParams
    if ($null -eq $dispatch -or [string]$dispatch.action -ne 'dispatch') {
        $decision.reason = if ($null -ne $dispatch) { [string]$dispatch.reason } else { 'no-dispatch' }
        return $decision   # casual yield / unregistered stage -> no-op.
    }

    # 3) DEDUP: compute the current reviewed tree-id; skip firing if it equals the last-FIRED one.
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewReviewedStateDigest' -ErrorAction SilentlyContinue)) {
        $decision.reason = 'digest-unavailable'
        return $decision
    }
    $digest = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $RepoRoot
    if ($null -eq $digest -or -not [bool]$digest.ok -or [string]::IsNullOrWhiteSpace([string]$digest.tree_id)) {
        $decision.reason = 'digest-failed'
        return $decision   # cannot identify the increment -> do not fire (fail-open).
    }
    $treeId = [string]$digest.tree_id
    $lastFired = Get-ContinuousCoReviewNavigatorLastFiredTreeId -RepoRoot $RepoRoot
    if (-not [string]::IsNullOrWhiteSpace($lastFired) -and $lastFired -eq $treeId) {
        $decision.action = 'no-op'
        $decision.reason = 'dedup-unchanged-tree-id'
        return $decision   # the increment under review has not changed since the last fire.
    }

    # LAUNCHER-AVAILABILITY FIRST (finding 1): check we can ACTUALLY fire BEFORE superseding the prior
    # review. The old order superseded (Stopped the prior running review) and only THEN checked the
    # launcher, so on a launcher-unavailable path it killed the prior review and returned a no-op with
    # NO replacement fired - a strictly-worse state (a healthy in-flight review destroyed for nothing).
    # Now: bail to the fail-open no-op here, leaving any prior review running, when we cannot fire.
    if (-not (Get-Command -Name 'Start-SpecrewIsolatedTask' -ErrorAction SilentlyContinue)) {
        $decision.reason = 'launcher-unavailable'
        return $decision   # degraded: cannot fire; fail-open no-op (the loader WARNed once). Prior review left intact.
    }

    # CONCURRENCY: one pending review at a time. A new checkpoint SUPERSEDES an un-reaped prior - Stop
    # any still-running navigator review before firing the replacement (the reap above already retired
    # terminal + orphaned entries; this handles a still-alive-within-deadline prior). We only reach here
    # once the launcher is confirmed available, so we never kill a prior without firing a replacement.
    foreach ($entry in (Get-ContinuousCoReviewNavigatorPendingEntries -RepoRoot $RepoRoot)) {
        $reg = $entry.registry
        $status = if ($null -ne $reg -and ($reg.PSObject.Properties.Name -contains 'status')) { [string]$reg.status } else { '' }
        if ($status -eq 'running') {
            if (Get-Command -Name 'Stop-SpecrewIsolatedTask' -ErrorAction SilentlyContinue) {
                try { $null = Stop-SpecrewIsolatedTask -RegistryPath $entry.registry_path -Reason 'reaped' } catch { $null = $_ }
            }
            else {
                Invoke-ContinuousCoReviewNavigatorInlineReap -RegistryPath $entry.registry_path -Registry $reg -Reason 'reaped'
            }
            Clear-ContinuousCoReviewNavigatorEntry -RepoRoot $RepoRoot -RegistryPath $entry.registry_path -Registry $reg
        }
    }

    $runId = if (Get-Command -Name 'New-SpecrewIsolatedTaskRunId' -ErrorAction SilentlyContinue) { New-SpecrewIsolatedTaskRunId } else { ('nav-{0}' -f ([guid]::NewGuid().ToString('N'))) }
    $runDir = Get-ContinuousCoReviewNavigatorRunDir -RepoRoot $RepoRoot -RunId $runId

    # Build the REAL reviewer plan IN-REPO (select + diff + request), unless a test supplied an explicit
    # override -Command (which bypasses the policy path entirely). $null plan -> Build-... falls back to
    # the stub (no feature/design context, no reviewable diff, or no authorized independent host); the
    # stub never promotes to gate evidence. The candidate host call gets the RAISED reviewer timeout; the
    # supervisor budget ($resolvedTimeoutSec) stays above it.
    $plan = $null
    if ([string]::IsNullOrWhiteSpace($ReviewerCommandOverride)) {
        $plan = New-ContinuousCoReviewNavigatorReviewerPlan -RepoRoot $RepoRoot -TreeId $treeId -RunId $runId -RunDir $runDir `
            -BaselineRef $baselineRef -CodeWriterHost $CodeWriterHost -ReviewerTimeoutSec $resolvedReviewerTimeout -TrunkName $TrunkName -Now $Now
    }
    $command = Build-ContinuousCoReviewNavigatorReviewerCommand -RepoRoot $RepoRoot -TreeId $treeId -ReviewerCommandOverride $ReviewerCommandOverride -Plan $plan

        try {
            $run = Start-SpecrewIsolatedTask -RepoRoot $RepoRoot -TreeId $treeId `
                -Access 'read-only' -Disposition 'discard' -TaskKind 'code-review' `
                -TimeoutSec $resolvedTimeoutSec -Command $command -RunDir $runDir
            # Record the fired tree-id for dedup. Use the run's own run_id (the launcher generated its own).
            Set-ContinuousCoReviewNavigatorLastFiredTreeId -RepoRoot $RepoRoot -TreeId $treeId -RunId ([string]$run.run_id)
            $decision.action = 'fired'
            $decision.reason = 'registered-checkpoint'
            $decision.fired_run_id = [string]$run.run_id
            $decision.fired_tree_id = $treeId
            # HUMAN-GATED STATUS PROTOCOL (the host-neutral join): the review runs ASYNC in an ISOLATED
            # process, so tell the human it is in flight + how to drive the check. The "wake" is the human
            # typing 'continue' (no host has a portable auto-wake; every host has a human + a Stop). The
            # status is reported on each subsequent Stop by the reap (running / passed / inconclusive), and
            # review-signoff fail-closed refuses to advance until a passing review is collected.
            $decision.inject_notes = @(@($decision.inject_notes) + ("[co-review] fired (run {0}) - an independent reviewer is reviewing this checkpoint in the background. Keep working or say 'continue' to check; the verdict is surfaced here the moment it is ready, and review-signoff will not advance until a passing review is collected." -f [string]$run.run_id))
            # Observability (tests + diagnostics): whether the REAL policy reviewer was wired this fire, the
            # host-call budget threaded onto it, and the supervisor budget. NOT load-bearing for the contract.
            $decision | Add-Member -NotePropertyName reviewer_wired -NotePropertyValue ([bool]($null -ne $plan)) -Force
            $decision | Add-Member -NotePropertyName reviewer_timeout_seconds -NotePropertyValue ([int]$resolvedReviewerTimeout) -Force
            $decision | Add-Member -NotePropertyName supervisor_timeout_seconds -NotePropertyValue ([int]$resolvedTimeoutSec) -Force
        }
        catch {
            $decision.action = 'no-op'
            $decision.reason = ('fire-failed: ' + $_.Exception.Message)
        }
        return $decision
    }
    catch {
        # OUTER FAIL-OPEN (finding 3): any unexpected internal error (incl. a Set-StrictMode violation)
        # collapses to a clean no-op decision - we NEVER throw to the dispatcher. The decision object
        # already carries every field; reset it to a no-op carrying the error reason for diagnostics.
        $decision.action = 'no-op'
        $decision.reason = ('navigator-error: ' + $_.Exception.Message)
        $decision.stop_block = $null
        $decision.inject_notes = @()
        $decision.fired_run_id = $null
        $decision.fired_tree_id = $null
        return $decision
    }
}
