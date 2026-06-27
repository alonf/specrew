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

function Get-ContinuousCoReviewWorktreeIdentity {
    # The FAST reviewed-state identity = HEAD's reviewed SUBTREE tree-id (nested-project aware). git's tracked tree
    # excludes gitignored content, so there is no node_modules force-add (the 50s digest cost is gone). It changes
    # when the user commits an increment, so the dedup fires once per committed checkpoint.
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
        [int]$TimeoutSeconds = 900,
        [switch]$Detached
    )
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    if ([string]::IsNullOrWhiteSpace($RunId)) { $RunId = New-ContinuousCoReviewServiceRunId }
    $runDir = Get-ContinuousCoReviewNavigatorRunDir -RepoRoot $resolved -RunId $RunId
    if (-not (Test-Path -LiteralPath $runDir)) { New-Item -ItemType Directory -Path $runDir -Force | Out-Null }

    if (-not $Detached) {
        $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $resolved -RunDir $runDir -RunId $RunId -BaselineRef $BaselineRef -CodeWriterHost $CodeWriterHost -TimeoutSeconds $TimeoutSeconds
        # Pass the failure_reason through, and read tree_id null-safely - a FAILED run (e.g. no-authorized-reviewer-host)
        # writes no tree_id, and a bare `.Value` on the missing property would crash the caller into a messy stack
        # instead of a clean, actionable status (the door relies on this to fail loud rather than silently).
        $failReason = if ($st.PSObject.Properties['failure_reason']) { [string]$st.failure_reason } else { '' }
        $treeIdVal = if ($st.PSObject.Properties['tree_id']) { $st.PSObject.Properties['tree_id'].Value } else { $null }
        $digestVal = if ($st.PSObject.Properties['reviewed_digest_tree_id']) { [string]$st.reviewed_digest_tree_id } else { '' }
        return [pscustomobject]@{ run_id = $RunId; run_dir = $runDir; status = ([string]$st.status); failure_reason = $failReason; reviewed_digest_tree_id = $digestVal; detached = $false; tree_id = $treeIdVal }
    }

    if ([string]::IsNullOrWhiteSpace($TreeId)) { $TreeId = Get-ContinuousCoReviewWorktreeIdentity -RepoRoot $resolved }
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
    & $writeReg $null 'running' $null
    # Spawn detached, stdio redirected to files (an un-redirected child inherits our pipes and BLOCKS on Unix).
    $entry = Join-Path $PSScriptRoot 'worktree-review-detached-entry.ps1'
    $spawnArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $entry, '-RepoRoot', $resolved, '-RunDir', $runDir, '-RunId', $RunId, '-RegistryPath', $regPath, '-TimeoutSeconds', $TimeoutSeconds)
    if (-not [string]::IsNullOrWhiteSpace($BaselineRef)) { $spawnArgs += @('-BaselineRef', $BaselineRef) }
    if (-not [string]::IsNullOrWhiteSpace($CodeWriterHost)) { $spawnArgs += @('-CodeWriterHost', $CodeWriterHost) }
    try {
        $proc = Start-Process -FilePath (Get-Command pwsh).Source -ArgumentList $spawnArgs -PassThru -WindowStyle Hidden `
            -RedirectStandardOutput (Join-Path $runDir 'entry.out.log') -RedirectStandardError (Join-Path $runDir 'entry.err.log')
    }
    catch {
        & $writeReg $null 'failed' @{ failure_reason = ('detached-spawn-failed: ' + $_.Exception.Message) }
        throw
    }
    & $writeReg $proc.Id 'running' $null
    return [pscustomobject]@{ run_id = $RunId; run_dir = $runDir; status = 'running'; supervisor_pid = $proc.Id; tree_id = $TreeId; detached = $true }
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
    $reviewerHost = Resolve-ContinuousCoReviewReviewerHost -RepoRoot $resolved -CodeWriterHost $CodeWriterHost
    $askHost = if ($reviewerHost) { $reviewerHost.host } else { 'claude' }
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
