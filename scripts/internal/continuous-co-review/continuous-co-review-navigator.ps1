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
    $isStub = ($verdict.PSObject.Properties.Name -contains 'reviewer') -and ([string]$verdict.reviewer -eq 'stub')
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
                    if ($verdict.blocking) {
                        if ($null -eq $result.stop_block) {
                            $result.stop_block = (Build-ContinuousCoReviewNavigatorStopBlock -Verdict $verdict -RunId $runId)
                        }
                    }
                    elseif (($verdict.PSObject.Properties.Name -contains 'is_stub') -and $verdict.is_stub) {
                        # The default PLACEHOLDER stub always emits pass without reviewing. Surface it as
                        # advisory feedback ONLY; it must NOT promote to durable gate evidence (that would
                        # make the signoff gate auto-satisfiable by plumbing). The gate stays unsatisfied
                        # until the real reviewer is wired (the post-closeout fast-follow). (closeout / flag 2)
                        $result.inject_notes.Add(("[co-review] checkpoint navigator fired (run {0}) - plumbing OK, but the real reviewer is not wired yet, so this is NOT counted as gate evidence." -f $runId)) | Out-Null
                    }
                    else {
                        $result.inject_notes.Add(("[co-review] checkpoint review PASSED (run {0}): {1}" -f $runId, $verdict.summary)) | Out-Null
                        # PROMOTE the non-blocking PASS to durable gate evidence so this auto-fired
                        # checkpoint becomes fresh evidence the signoff gate accepts. Blocking/failed are
                        # NOT promoted (only a clean PASS advances the reviewed baseline); a stub is excluded above.
                        $promotedId = Add-ContinuousCoReviewNavigatorPassRunRecord -RepoRoot $RepoRoot -RunId $runId -TreeId $treeId -TrunkName $TrunkName -Now $Now
                        if (-not [string]::IsNullOrWhiteSpace($promotedId)) { $result.promoted_run_ids.Add($promotedId) | Out-Null }
                    }
                }
                elseif ($status -eq 'done' -and -not $verdict.ok) {
                    $result.inject_notes.Add(("[co-review] checkpoint review completed (run {0}) but emitted no parseable verdict; treat as advisory." -f $runId)) | Out-Null
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
        }
        # else: within deadline AND (present OR presence-unknown). Leave it PENDING - a transient
        # 'unknown' probe failure on a still-running review is re-checked on the next reap (finding 2).
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
    param([Parameter(Mandatory)]$Verdict, [AllowNull()][string]$RunId)
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

function Build-ContinuousCoReviewNavigatorReviewerCommand {
    # The reviewer harness -Command (a pwsh one-liner string the supervisor runs IN the worktree, cwd =
    # the materialized read-only snapshot). For THIS cut it is a MINIMAL verdict-emitting stub: it
    # confirms it can read the worktree (the diff would be reviewed here) and writes a verdict JSON
    # { schema_version, disposition, blocking, findings } to STDOUT, which the supervisor's stdio
    # redirect captures to result.out (the reaper parses that). The REAL reviewer would instead compose
    # scripts/internal/continuous-co-review/code-review-agent.md against the worktree's diff vs the
    # design contract via the existing adapter/execution engine and emit a FindingsResult.v1 - a later
    # wiring on this same seam, NOT a new launcher. An explicit -ReviewerCommand override (e.g. a test's
    # fast dummy, or the real reviewer once wired) wins.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$TreeId,
        [AllowNull()][string]$ReviewerCommandOverride
    )
    if (-not [string]::IsNullOrWhiteSpace($ReviewerCommandOverride)) { return $ReviewerCommandOverride }

    # Default stub: emit a no-findings PASS verdict (the navigator plumbing is the deliverable; the
    # verdict content is the real reviewer's job). $PWD inside the harness is the worktree.
    return @"
`$ErrorActionPreference = 'Stop'
# (Real reviewer would review the worktree diff here; this stub emits a structurally-valid verdict.)
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

        # The co-review timeout (config scalar; safe default mirrors the gate-enforcement default).
        [int]$TimeoutSec = 120,

        # The trunk the checkpoint baseline merge-bases against (threaded like the rest of the gate).
        [string]$TrunkName = 'main',

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
    $command = Build-ContinuousCoReviewNavigatorReviewerCommand -RepoRoot $RepoRoot -TreeId $treeId -ReviewerCommandOverride $ReviewerCommandOverride

        try {
            $run = Start-SpecrewIsolatedTask -RepoRoot $RepoRoot -TreeId $treeId `
                -Access 'read-only' -Disposition 'discard' -TaskKind 'code-review' `
                -TimeoutSec $TimeoutSec -Command $command -RunDir $runDir
            # Record the fired tree-id for dedup. Use the run's own run_id (the launcher generated its own).
            Set-ContinuousCoReviewNavigatorLastFiredTreeId -RepoRoot $RepoRoot -TreeId $treeId -RunId ([string]$run.run_id)
            $decision.action = 'fired'
            $decision.reason = 'registered-checkpoint'
            $decision.fired_run_id = [string]$run.run_id
            $decision.fired_tree_id = $treeId
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
