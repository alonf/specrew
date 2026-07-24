$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# iter-008 — the HOST-NEUTRAL co-review SERVICE. The single API surface for the co-review capabilities, consumed
# by TWO peers: the Claude Stop-hook navigator (today) AND a future MCP server (any MCP host, tomorrow). No
# host-specific surfacing here — each function returns structured data; the host integration (stop-block,
# inject-note, an MCP tool result) is the CONSUMER's job. The MCP server is a THIN wrapper:
#   trigger_review   -> Start-ContinuousCoReviewServiceRun     (fire a review of the committed state; detached)
#   get_review_status-> Get-ContinuousCoReviewServiceStatus    (a run's lifecycle status, or all pending)
#   get_review_findings-> Get-ContinuousCoReviewServiceFindings(a run's FindingsResult — the durable thread)
#   ask_reviewer     -> Invoke-ContinuousCoReviewServiceAsk    (a follow-up question about a run's findings)
# This is the "small refactor now" so the MCP is easy later. See iter-008 design-analysis (MCP-readiness).

. (Join-Path $PSScriptRoot 'continuous-co-review-navigator.ps1')   # pending-dir / run-dir / pending-entries helpers
. (Join-Path $PSScriptRoot 'worktree-review-orchestrator.ps1')     # the trigger pipeline + auto-resolution

function New-ContinuousCoReviewServiceRunId {
    if (Get-Command -Name 'New-SpecrewIsolatedTaskRunId' -ErrorAction SilentlyContinue) { return (New-SpecrewIsolatedTaskRunId) }
    return ('ccr-{0}' -f ([guid]::NewGuid().ToString('N')))
}

function Get-ContinuousCoReviewCheckpointIdentity {
    # The CHECKPOINT identity for auto-fire dedup and pending-entry registration = the CERTIFIED
    # reviewed-state digest (working tree), falling back to the HEAD subtree only when the digest
    # cannot be computed. Fixes the codex finding of run 20260708T225439577 (the D-197-I010-004
    # follow-on): keying dedup on HEAD^{tree} meant an UNCOMMITTED edit after a fired commit kept the
    # old key and was deduped as already-reviewed, so the auto path never reviewed dirty increments -
    # the one identity that materialization, the gate, and now the dedup share is the digest. The
    # original HEAD-tree choice guarded a 50s digest cost that no longer exists (batched git calls
    # brought it to ~0.2-2s), and this only runs on implement-stage material stops.
    param([Parameter(Mandatory)][string]$RepoRoot)
    try {
        if (-not (Get-Command -Name 'Get-ContinuousCoReviewReviewedStateDigest' -ErrorAction SilentlyContinue)) {
            $lp = Join-Path $PSScriptRoot '_load.ps1'
            if (Test-Path -LiteralPath $lp -PathType Leaf) { . $lp }
        }
        $dg = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $RepoRoot
        if ($null -ne $dg -and [bool]$dg.ok -and -not [string]::IsNullOrWhiteSpace([string]$dg.tree_id)) {
            return ([string]$dg.tree_id).Trim()
        }
    }
    catch { $null = $_ }
    return (Get-ContinuousCoReviewWorktreeIdentity -RepoRoot $RepoRoot)
}

function Get-ContinuousCoReviewWorktreeIdentity {
    # The FAST identity = HEAD's reviewed SUBTREE tree-id (nested-project aware). Retained as the
    # digest-failure FALLBACK for Get-ContinuousCoReviewCheckpointIdentity (it misses dirty
    # working-tree changes by construction - do not key dedup on it directly).
    param([Parameter(Mandatory)][string]$RepoRoot)
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    $prefixRaw = (& git -C $resolved rev-parse --show-prefix 2>$null)
    $prefix = if ($null -ne $prefixRaw) { ([string]$prefixRaw).Trim().TrimEnd('/') } else { '' }
    $treeId = if ([string]::IsNullOrWhiteSpace($prefix)) {
        (& git -C $resolved rev-parse 'HEAD^{tree}' 2>$null)
    }
    else {
        $gitRoot = (& git -C $resolved rev-parse --show-toplevel 2>$null).Trim()
        (& git -C $gitRoot rev-parse "HEAD:$prefix" 2>$null)
    }
    if ([string]::IsNullOrWhiteSpace($treeId)) { return $null }
    return ([string]$treeId).Trim()
}

function Start-ContinuousCoReviewServiceRun {
    # TRIGGER. Fire a review of the committed state. -Detached spawns the detached orchestrator NON-BLOCKING and
    # registers a reap-compatible pending entry (the navigator/MCP fire-and-forget path); otherwise runs inline
    # (blocking). Returns @{ run_id; run_dir; status; supervisor_pid?; tree_id; detached }.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [string]$RunId,
        [string]$TreeId,
        [string]$BaselineRef,
        [string]$CodeWriterHost,
        # T093/FR-035: an explicit reviewer-host request (the --live door's --host). Honoured or
        # surfaced by the orchestrator's selection, never silently substituted.
        [string]$RequestedHost,
        [int]$TimeoutSeconds = 900,
        [string]$LineageId,
        [switch]$Detached
    )
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    # F-198 / T041: this legacy service cannot start a reviewer unless the single cutover seam says
    # legacy authority is active. Campaign/disabled/invalid/missing states suppress BEFORE run-dir,
    # lease, pending-registry, or process creation, so the obsolete path cannot consume spend.
    $authorityDecision = if (Get-Command -Name 'Get-ContinuousCoReviewAuthorityDecision' -ErrorAction SilentlyContinue) {
        Get-ContinuousCoReviewAuthorityDecision
    }
    else {
        [pscustomobject]@{ mode = 'disabled'; valid = $false; legacy_promotion_enabled = $false; reason = 'authority-cutover-helper-missing' }
    }
    if (-not [bool]$authorityDecision.legacy_promotion_enabled) {
        return [pscustomobject]@{
            run_id            = $RunId
            run_dir           = $null
            status            = 'suppressed'
            detached          = [bool]$Detached
            spawned           = $false
            suppressed_reason = ('legacy-authority-disabled:' + [string]$authorityDecision.reason)
            authority_mode    = [string]$authorityDecision.mode
        }
    }
    if ([string]::IsNullOrWhiteSpace($RunId)) { $RunId = New-ContinuousCoReviewServiceRunId }
    $runDir = Get-ContinuousCoReviewNavigatorRunDir -RepoRoot $resolved -RunId $RunId
    if (-not (Test-Path -LiteralPath $runDir)) { New-Item -ItemType Directory -Path $runDir -Force | Out-Null }

    if (-not $Detached) {
        $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $resolved -RunDir $runDir -RunId $RunId -BaselineRef $BaselineRef -CodeWriterHost $CodeWriterHost -RequestedHost $RequestedHost -TimeoutSeconds $TimeoutSeconds
        # Pass the failure_reason through, and read tree_id null-safely - a FAILED run (e.g. no-authorized-reviewer-host)
        # writes no tree_id, and a bare `.Value` on the missing property would crash the caller into a messy stack
        # instead of a clean, actionable status (the door relies on this to fail loud rather than silently).
        $failReason = if ($st.PSObject.Properties['failure_reason']) { [string]$st.failure_reason } else { '' }
        $treeIdVal = if ($st.PSObject.Properties['tree_id']) { $st.PSObject.Properties['tree_id'].Value } else { $null }
        $digestVal = if ($st.PSObject.Properties['reviewed_digest_tree_id']) { [string]$st.reviewed_digest_tree_id } else { '' }
        $elapsedVal = if ($st.PSObject.Properties['elapsed_seconds']) { $st.PSObject.Properties['elapsed_seconds'].Value } else { $null }
        $timeoutVal = if ($st.PSObject.Properties['timeout_seconds']) { $st.PSObject.Properties['timeout_seconds'].Value } else { $TimeoutSeconds }
        return [pscustomobject]@{ run_id = $RunId; run_dir = $runDir; status = ([string]$st.status); failure_reason = $failReason; reviewed_digest_tree_id = $digestVal; detached = $false; tree_id = $treeIdVal; elapsed_seconds = $elapsedVal; timeout_seconds = $timeoutVal }
    }

    if ([string]::IsNullOrWhiteSpace($TreeId)) { $TreeId = Get-ContinuousCoReviewCheckpointIdentity -RepoRoot $resolved }

    # T019 step 6 piece 2: acquire the per-lineage LEASE ATOMICALLY BEFORE spawning any reviewer. A failed acquire
    # (a duplicate same-generation fire, or a NEWER tree queued behind a LIVE owner reviewing an older tree)
    # SUPPRESSES the spawn - no reviewer starts, so it consumes neither provider spend NOR a review round. The
    # GENERATION is the reviewed-tree digest (TreeId). The owner PROCESS is stamped to the supervisor after spawn.
    if ([string]::IsNullOrWhiteSpace($LineageId)) { $LineageId = Resolve-ContinuousCoReviewRepoLineageId -RepoRoot $resolved }
    $leaseAcq = Request-ContinuousCoReviewLineageLease -RepoRoot $resolved -LineageId $LineageId -Generation $TreeId -RunId $RunId
    if (-not $leaseAcq.acquired) {
        return [pscustomobject]@{ run_id = $RunId; run_dir = $runDir; status = 'suppressed'; detached = $true; spawned = $false; suppressed_reason = ([string]$leaseAcq.reason); lineage_id = $LineageId; tree_id = $TreeId; generation = $TreeId }
    }
    $leaseOwnerToken = [string]$leaseAcq.lease.owner_token

    $regPath = Join-Path (Get-ContinuousCoReviewNavigatorPendingDir -RepoRoot $resolved) "$RunId.json"
    $resultPath = Join-Path $runDir 'result.out'
    $now = [datetime]::UtcNow
    $deadline = $now.AddSeconds($TimeoutSeconds + 120).ToString('o')
    $writeReg = {
        param([AllowNull()]$SupPid, [string]$Status, [hashtable]$Extra)
        $record = [ordered]@{
                schema_version = '1.0'; run_id = $RunId; engine = 'worktree'; status = $Status
                run_dir = $runDir; result_path = $resultPath; tree_id = $TreeId
                supervisor_pid = $SupPid; created_at = $now.ToString('o'); deadline = $deadline
            }
        if ($Extra) {
            foreach ($key in $Extra.Keys) { $record[$key] = $Extra[$key] }
        }
        $json = ([pscustomobject]$record | ConvertTo-Json -Depth 8)
        if (Get-Command -Name 'Write-SpecrewFileAtomic' -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $regPath -Content $json } else { [System.IO.File]::WriteAllText($regPath, $json) }
    }
    & $writeReg $null 'running' @{ lineage_id = $LineageId; generation = $TreeId; owner_token = $leaseOwnerToken }
    # Spawn detached, stdio redirected to files. An un-redirected child inherits our pipes and BLOCKS the parent.
    $entry = Join-Path $PSScriptRoot 'worktree-review-detached-entry.ps1'
    $spawnArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $entry, '-RepoRoot', $resolved, '-RunDir', $runDir, '-RunId', $RunId, '-RegistryPath', $regPath, '-TimeoutSeconds', $TimeoutSeconds)
    if (-not [string]::IsNullOrWhiteSpace($BaselineRef)) { $spawnArgs += @('-BaselineRef', $BaselineRef) }
    if (-not [string]::IsNullOrWhiteSpace($CodeWriterHost)) { $spawnArgs += @('-CodeWriterHost', $CodeWriterHost) }
    if (-not [string]::IsNullOrWhiteSpace($RequestedHost)) { $spawnArgs += @('-RequestedHost', $RequestedHost) }
    # ISSUE-1 ROOT FIX (the 20-minute Stop): spawn the detached review inheriting NOTHING, so it cannot hold the
    # dispatcher's - and TRANSITIVELY the HOST's - stdout pipe open. The host (Claude Code) launches the dispatcher
    # and reads its stdout to EOF with NO drain cap (it is the host, not our code), so any inherited pipe blocks the
    # host until the review exits (~the whole budget = the 20-30 min hang). Start-Process forces bInheritHandles=TRUE
    # (inherits EVERY inheritable handle, not just stdout/stderr), so neither -Redirect* nor clearing -11/-12 is
    # enough - a 4-level host->dispatcher->provider->review harness proved Start-Process+handle-clear = 11.1s
    # host-read vs Win32_Process.Create = 1.8s. On WINDOWS use Win32_Process.Create (CreateProcess with
    # bInheritHandles=FALSE + no parent stdio); on UNIX Start-Process -Redirect* already detaches cleanly (verified
    # 2.8s baseline on WSL). The detached-entry self-redirects its own stdio (CreateProcess has no console/shell
    # redirection, so the entry.out.log is written from inside the entry, not by the parent).
    $supPid = $null
    if ($IsWindows) {
        try {
            $quoted = @('"' + (Get-Command pwsh).Source + '"') + @($spawnArgs | ForEach-Object { '"' + (([string]$_) -replace '"', '\"') + '"' })
            # ShowWindow=SW_HIDE(0): Win32_Process.Create has no -WindowStyle Hidden equivalent, so without this the
            # detached pwsh pops a blank console window at EVERY checkpoint (Start-Process used -WindowStyle Hidden).
            $startup = New-CimInstance -ClassName Win32_ProcessStartup -ClientOnly -Property @{ ShowWindow = [uint16]0 }
            $spawn = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = ($quoted -join ' '); ProcessStartupInformation = $startup } -ErrorAction Stop
        }
        catch {
            $null = Complete-ContinuousCoReviewLineageLease -RepoRoot $resolved -LineageId $LineageId -Generation $TreeId -OwnerToken $leaseOwnerToken
            & $writeReg $null 'failed' @{ failure_reason = ('detached-spawn-failed: ' + $_.Exception.Message) }
            throw
        }
        if ($null -eq $spawn -or [int]$spawn.ReturnValue -ne 0 -or -not $spawn.ProcessId) {
            $rc = if ($null -ne $spawn) { [string]$spawn.ReturnValue } else { 'null' }
            $null = Complete-ContinuousCoReviewLineageLease -RepoRoot $resolved -LineageId $LineageId -Generation $TreeId -OwnerToken $leaseOwnerToken
            & $writeReg $null 'failed' @{ failure_reason = ("detached-spawn-failed: Win32_Process.Create rc=$rc") }
            throw "Win32_Process.Create failed (rc=$rc)"
        }
        $supPid = [int]$spawn.ProcessId
    }
    else {
        try {
            # NO -WindowStyle here: this IS the non-Windows branch (Windows uses Win32_Process.Create
            # above) and -WindowStyle throws NotSupported on Unix pwsh - it silently broke the WSL/Linux
            # detached fire before the reviewer ever started (co-review finding f2, run 20260708T112353271).
            $proc = Start-Process -FilePath (Get-Command pwsh).Source -ArgumentList $spawnArgs -PassThru `
                -RedirectStandardOutput (Join-Path $runDir 'entry.out.log') -RedirectStandardError (Join-Path $runDir 'entry.err.log')
        }
        catch {
            $null = Complete-ContinuousCoReviewLineageLease -RepoRoot $resolved -LineageId $LineageId -Generation $TreeId -OwnerToken $leaseOwnerToken
            & $writeReg $null 'failed' @{ failure_reason = ('detached-spawn-failed: ' + $_.Exception.Message) }
            throw
        }
        $supPid = [int]$proc.Id
    }
    # Stamp the lease's owner PROCESS to the reviewer supervisor now that it exists, so crash recovery tracks the
    # process actually running the review (not the parent that acquired the lease). REQUIRED POST-SPAWN
    # TRANSACTION (review finding f5, run 20260714T215545754): if this handoff fails, the lease still names the
    # SHORT-LIVED acquiring parent - once that parent exits, dead-owner reclamation could spawn a CONCURRENT
    # reviewer while this supervisor is still live. A failed handoff therefore deterministically STOPS the
    # spawned supervisor, marks the registry failed, releases the lease, and FAILS LOUDLY - never status=running
    # with an unprotected reviewer.
    $handoffOk = $false
    try { $handoffOk = [bool](Update-ContinuousCoReviewLineageLeaseOwnerProcess -RepoRoot $resolved -LineageId $LineageId -Generation $TreeId -OwnerToken $leaseOwnerToken -OwnerPid $supPid) }
    catch { $handoffOk = $false }
    if (-not $handoffOk) {
        try { Stop-Process -Id $supPid -Force -ErrorAction Stop } catch { [Console]::Error.WriteLine("[co-review] WARN SUPERVISOR_STOP_FAILED pid=$supPid after a failed lease owner handoff: $($_.Exception.Message)") }
        $null = Complete-ContinuousCoReviewLineageLease -RepoRoot $resolved -LineageId $LineageId -Generation $TreeId -OwnerToken $leaseOwnerToken
        & $writeReg $null 'failed' @{ failure_reason = 'lease-owner-handoff-failed: the supervisor could not be stamped as the lease owner; the spawned reviewer was stopped (never an unprotected running reviewer)' }
        throw "lease-owner-handoff-failed for run $RunId (lineage '$LineageId', generation '$TreeId'): the lease could not be re-stamped to the supervisor; the spawned reviewer was stopped."
    }
    & $writeReg $supPid 'running' @{ lineage_id = $LineageId; generation = $TreeId; owner_token = $leaseOwnerToken }
    return [pscustomobject]@{ run_id = $RunId; run_dir = $runDir; status = 'running'; supervisor_pid = $supPid; tree_id = $TreeId; detached = $true; lineage_id = $LineageId; generation = $TreeId }
}

function Get-ContinuousCoReviewServiceStatus {
    # STATUS. A run's lifecycle status (pending registry -> running/done/failed; else inline -> reaped); or, with
    # no RunId, every pending run. Pure read.
    param([Parameter(Mandatory)][string]$RepoRoot, [string]$RunId)
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    if ([string]::IsNullOrWhiteSpace($RunId)) {
        return @(Get-ContinuousCoReviewNavigatorPendingEntries -RepoRoot $resolved | ForEach-Object { $_.registry })
    }
    $regPath = Join-Path (Get-ContinuousCoReviewNavigatorPendingDir -RepoRoot $resolved) "$RunId.json"
    if (Test-Path -LiteralPath $regPath -PathType Leaf) { return (Get-Content -LiteralPath $regPath -Raw -Encoding UTF8 | ConvertFrom-Json) }
    # Reaped: the durable inline thread survives (findings-result.json for ANY real verdict; review-run.json only
    # when an affirmative pass was PROMOTED to gate evidence). Either means the run was reviewed.
    $inlineDir = Join-Path $resolved ".specrew/review/inline/$RunId"
    if ((Test-Path -LiteralPath (Join-Path $inlineDir 'findings-result.json') -PathType Leaf) -or (Test-Path -LiteralPath (Join-Path $inlineDir 'review-run.json') -PathType Leaf)) {
        $promoted = Test-Path -LiteralPath (Join-Path $inlineDir 'review-run.json') -PathType Leaf
        return [pscustomobject]@{ run_id = $RunId; status = 'reviewed'; reaped = $true; promoted_gate_evidence = $promoted }
    }
    return [pscustomobject]@{ run_id = $RunId; status = 'unknown' }
}

function Get-ContinuousCoReviewServiceFindings {
    # FINDINGS — the reviewer data. The durable promoted thread (inline/<run-id>/findings-result.json) if present,
    # else the pending result.out. Returns the parsed FindingsResult (or $null). The MCP `get_review_findings`
    # tool returns this verbatim; inline/<run-id>/ is the MCP resource.
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$RunId)
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    foreach ($p in @((Join-Path $resolved ".specrew/review/inline/$RunId/findings-result.json"),
            (Join-Path (Get-ContinuousCoReviewNavigatorRunDir -RepoRoot $resolved -RunId $RunId) 'result.out'))) {
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            try { $raw = Get-Content -LiteralPath $p -Raw -Encoding UTF8; if (-not [string]::IsNullOrWhiteSpace($raw)) { return ($raw | ConvertFrom-Json -Depth 100) } } catch { $null = $_ }
        }
    }
    return $null
}

function Get-ContinuousCoReviewAskPrompt {
    param([Parameter(Mandatory)][string]$Question, [AllowNull()]$PriorFindings)
    $priorJson = if ($null -ne $PriorFindings) { ($PriorFindings | ConvertTo-Json -Depth 100) } else { '(no prior findings on record)' }
    return @"
You are the Specrew co-reviewer answering a FOLLOW-UP QUESTION about a review you produced for this project.
Your current working directory IS the reviewed project. You are TRUSTED: READ any file and RUN any command to
verify your answer, but you are READ-ONLY on the source — do NOT modify any file.

Prior findings you produced (JSON):
$priorJson

The user's question:
$Question

Answer concisely and specifically, citing exact files/lines and the design reference where relevant. Plain text
only (no JSON wrapper).
"@
}

function Invoke-ContinuousCoReviewServiceAsk {
    # ASK — a follow-up question about a run's findings. Re-materializes the reviewed state in a fresh read-only
    # worktree and re-invokes the agentic host with the prior findings + the question (the same trusted
    # agent-in-worktree the review uses). Returns @{ answer; ok }. The MCP `ask_reviewer` tool wraps this.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Question,
        [string]$BaselineRef,
        [string]$CodeWriterHost,
        [int]$TimeoutSeconds = 300
    )
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    $prior = Get-ContinuousCoReviewServiceFindings -RepoRoot $resolved -RunId $RunId
    if ([string]::IsNullOrWhiteSpace($BaselineRef)) { $BaselineRef = Resolve-ContinuousCoReviewWorktreeBaseline -RepoRoot $resolved }
    $design = @(Resolve-ContinuousCoReviewWorktreeDesignContext -RepoRoot $resolved)
    # D-197-I010-002 (host-neutral core): no named-harness fallback - an unresolved reviewer host
    # fails soft with the stated reason instead of silently asking a hardcoded host.
    $reviewerHost = Resolve-ContinuousCoReviewReviewerHost -RepoRoot $resolved -CodeWriterHost $CodeWriterHost
    if ($null -eq $reviewerHost) {
        return [pscustomobject]@{ ok = $false; answer = $null; failure_reason = 'no-authorized-reviewer-host'; reviewer_host = $null }
    }
    $askHost = [string]$reviewerHost.host
    $wt = New-ContinuousCoReviewStrippedWorktree -RepoRoot $resolved -BaselineRef $BaselineRef -DesignContextFiles $design
    try {
        $prompt = Get-ContinuousCoReviewAskPrompt -Question $Question -PriorFindings $prior
        $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $wt.worktree_path -Prompt $prompt -HostName $askHost -TimeoutSeconds $TimeoutSeconds
        return [pscustomobject]@{ ok = ($r.exit_code -eq 0); answer = ([string]$r.stdout).Trim(); reviewer_host = $askHost }
    }
    finally {
        Remove-Item -LiteralPath $wt.worktree_path -Recurse -Force -ErrorAction SilentlyContinue
    }
}
