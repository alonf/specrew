<#
.SYNOPSIS
    The general isolated-task launcher - the Proposal 139 multi-agent foundation (the Layer-2
    headless-process-orchestration seam) arriving early. Review (continuous co-review) is its
    FIRST consumer.

.DESCRIPTION
    `Start-SpecrewIsolatedTask` always does three things, parameterized by two policies (access +
    disposition):

      1. SPAWN a harness (`-Command`) inside an ISOLATED git worktree materialized from a target
         tree-id, SUPERVISED with a timeout (the old "watchdog" role - kill on timeout, write a
         terminal status). It fires a DETACHED supervisor (`isolated-task-supervisor.ps1`) and
         RETURNS the run metadata immediately - the caller (a Stop-hook provider) never waits for
         the task. Cross-platform detachment requires redirecting the child's stdio to files at
         EVERY hop (the T076 spike proved a Windows-only version SHIPS A BUG that blocks the
         provider ~18s on Unix, where the child inherits the parent pipes); the provider must
         fire-and-return (NEVER `Start-Process -Wait`, which waits for the whole process tree).

      2. ACCESS mode - `read-only` (review) is BUILT. `read-write` (implementation) is a designed
         seam: it needs a real `git worktree` branched from base for merge-back, so it throws
         'not implemented' here (see the comment at the throw).

      3. DISPOSITION on completion - what the supervisor does with the worktree:
           - `discard`  delete it (review: nothing to merge). THE ONLY ONE BUILT NOW.
           - `merge`    3-way merge (base B, worktree, moved-base B') back, then delete. Designed,
                        DEFERRED to the merge-agent (Proposals 010/134/149). Throws here.
           - `preserve` keep for human inspection (failed/conflicted task). DEFERRED. Throws here.

    The launcher OWNS the full worktree lifecycle (create -> frozen -> dispose), ENTIRELY on the
    detached supervisor path so the provider/Stop-hook never pays for it. Orphan-safety is BY
    CONSTRUCTION: the supervisor self-limits (its own timeout + kill loop) and disposes in a
    `finally`, so even a timed-out/killed run leaves no orphaned worktree. `Stop-SpecrewIsolatedTask`
    is the cleanup helper a future reaper calls to reap zombie supervisors + orphaned worktrees
    from a DEAD launcher (the backstop, not the primary mechanism).

    THREE-TIER file layout (per the iteration-005 design):
      - The worktree + the reviewer scratch: ephemeral `$TEMP`, OUTSIDE the repo (throwaway per
        task; never inside the repo it snapshots).
      - The pending-task registry (launcher<->reaper signaling): stable `.specrew/review/pending/`
        (gitignored + digest-stripped) so it survives the fire->reap gap ACROSS a session boundary.
      - The persistent passing-run records the gate reads: in-repo `.specrew/review/runs/`
        (digest-stripped). (This file writes the pending registry + the supervisor mirrors a
        terminal record; promotion of a PASS to `runs/` is the provider/reaper's job, not here.)

    Because `.specrew/**` is already stripped from the reviewed tree-id, the worktree (materialized
    from that tree-id) is automatically clean of all bookkeeping - the reviewer sees only source.

.NOTES
    F-184 footprint: NONE. Non-protected script under a GENERAL location (signals shared 139
    infrastructure, not co-review-specific). PowerShell 7.x.
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- shared atomic write (single source) ---------------------------------------------------------
$script:IsolatedTaskAtomicWritePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'atomic-write.ps1'
if ((Test-Path -LiteralPath $script:IsolatedTaskAtomicWritePath -PathType Leaf) -and
    -not (Get-Command -Name 'Write-SpecrewFileAtomic' -ErrorAction SilentlyContinue)) {
    . $script:IsolatedTaskAtomicWritePath
}

function Get-SpecrewIsolatedTaskSupervisorPath {
    # The detached supervisor body lives in a SIBLING file (mirrors the spike's fire/launcher
    # split). It must run ONLY the supervisor loop; keeping it separate means dot-sourcing THIS
    # launcher to get the functions never runs the supervisor branch.
    return (Join-Path $PSScriptRoot 'isolated-task-supervisor.ps1')
}

function Get-SpecrewIsolatedTaskPendingDir {
    param([Parameter(Mandatory)][string]$RepoRoot)
    return (Join-Path $RepoRoot '.specrew/review/pending')
}

function Get-SpecrewIsolatedTaskEphemeralRoot {
    # The ephemeral worktree root - OUTSIDE the repo, in $TEMP. `[IO.Path]::GetTempPath()` honors
    # TMPDIR on Unix and TEMP/TMP on Windows, so a caller (or test) that redirects the env var
    # steers this on BOTH platforms. An explicit override wins for hermetic tests.
    if ($env:SPECREW_ISOLATED_TASK_TMP) { return $env:SPECREW_ISOLATED_TASK_TMP }
    return [System.IO.Path]::GetTempPath()
}

function New-SpecrewIsolatedTaskRunId {
    # Sortable + unique: UTC stamp + short guid.
    return ('{0}-{1}' -f (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfff'),
        ([guid]::NewGuid().ToString('N').Substring(0, 8)))
}

function Get-SpecrewIsolatedTaskHost {
    # Best-effort host label for the registry (which host fired the task). Not load-bearing here.
    foreach ($var in 'SPECREW_HOST', 'SPECREW_ACTIVE_HOST') {
        $val = [System.Environment]::GetEnvironmentVariable($var)
        if ($val) { return $val }
    }
    return 'unknown'
}

function New-SpecrewIsolatedTaskWorktree {
    <#
        Materialize a read-only snapshot of $TreeId into an EPHEMERAL dir OUTSIDE the repo.

        RO path: clean tree-content export via `git archive --output <tar>` + `tar -xf` - NO git
        worktree machinery needed. CRITICAL: archive to a FILE then extract; do NOT pipe
        `git archive | tar` in PowerShell - a native->native pipe routes the binary tar stream
        through .NET text decode/encode and CORRUPTS it (verified). The file hop is byte-exact and
        identical on bsdtar (Win11 System32) + GNU tar (Linux).

        The `read-write` future path needs a real `git worktree add` branched from base so the
        supervisor can merge changes back on `merge` disposition - DEFERRED (see Start-...'s throw).
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$TreeId,
        [Parameter(Mandatory)][string]$EphemeralRoot
    )

    $gitDir = Join-Path $RepoRoot '.git'
    $worktreeDir = Join-Path $EphemeralRoot ('specrew-itask-' + [guid]::NewGuid().ToString('N'))
    $tarPath = "$worktreeDir.tar"
    New-Item -ItemType Directory -Path $worktreeDir -Force | Out-Null

    # Archive the tree to a file (no cross-process pipe), then extract.
    & git --git-dir="$gitDir" archive --format=tar --output $tarPath $TreeId 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Remove-Item -LiteralPath $worktreeDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tarPath -Force -ErrorAction SilentlyContinue
        throw "git archive failed for tree-id '$TreeId' (exit $LASTEXITCODE)"
    }

    & tar -xf $tarPath -C $worktreeDir 2>&1 | Out-Null
    $tarExit = $LASTEXITCODE
    Remove-Item -LiteralPath $tarPath -Force -ErrorAction SilentlyContinue
    if ($tarExit -ne 0) {
        Remove-Item -LiteralPath $worktreeDir -Recurse -Force -ErrorAction SilentlyContinue
        throw "tar extract failed for tree-id '$TreeId' (exit $tarExit)"
    }

    return $worktreeDir
}

function Start-SpecrewIsolatedTask {
    <#
        The general launcher. Builds the review path; seams the rest. Returns run metadata
        IMMEDIATELY (fire-and-return); the detached supervisor does the work + disposes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,

        # The content-addressed reviewed tree-id (a git tree SHA) to materialize.
        [Parameter(Mandatory)][string]$TreeId,

        # Belt-and-suspenders: RO also launches the host in its native read-only mode upstream. Only
        # `read-only` is built; `read-write` (implementation, needs a branched git worktree for
        # merge-back) is a designed seam.
        [ValidateSet('read-only', 'read-write')]
        [string]$Access = 'read-only',

        # `discard` is built (review: nothing to merge). `merge`/`preserve` are designed seams.
        [ValidateSet('discard', 'merge', 'preserve')]
        [string]$Disposition = 'discard',

        # `code-review` is the first contract; other task kinds are a later contract registration
        # via the artifact+contract seam (NOT a new launcher).
        [string]$TaskKind = 'code-review',

        [Parameter(Mandatory)][int]$TimeoutSec,

        # The reviewer harness command to run IN the worktree. A single command string the
        # supervisor invokes via `pwsh -Command` with cwd = the worktree. Passed through the job
        # JSON (NOT -ArgumentList) to dodge cross-platform quoting hell.
        [Parameter(Mandatory)][string]$Command,

        # Where the supervisor writes status.json + result (and the job spec). A stable, caller-owned
        # directory (e.g. under .specrew/review/pending/<run-id>/) - NOT the ephemeral worktree.
        [Parameter(Mandatory)][string]$RunDir
    )

    # --- policy seams: build only the review path ------------------------------------------------
    if ($Access -eq 'read-write') {
        # DEFERRED: read-write needs a real `git worktree add -b <task-branch> <dir> <base>` so the
        # supervisor can capture the worktree's changes and (on `merge` disposition) 3-way merge
        # them back to the possibly-moved base. That is the implementation/multi-dev path
        # (Proposals 010/134/149), a feature of its own. Review is read-only.
        throw "Start-SpecrewIsolatedTask: -Access 'read-write' is not implemented (designed seam: needs a branched git worktree for merge-back; review uses read-only)."
    }
    if ($Disposition -eq 'merge') {
        # DEFERRED: merge -> the merge-agent. Clean -> merge + delete; conflict -> preserve + hand
        # off; failed -> discard. The conflict path IS the merge-agent (Proposals 010/134/149).
        throw "Start-SpecrewIsolatedTask: -Disposition 'merge' is not implemented (designed seam: 3-way merge-back to a moved base belongs to the merge-agent)."
    }
    if ($Disposition -eq 'preserve') {
        # DEFERRED: preserve keeps the worktree for human inspection of a failed/conflicted task.
        throw "Start-SpecrewIsolatedTask: -Disposition 'preserve' is not implemented (designed seam: human-inspection retention)."
    }
    # NOTE on -TaskKind: only `code-review` is wired today. Reviewing a plan/tasks/spec (or any
    # future task) is a later artifact+contract registration on this same seam, NOT a new launcher.

    $runId = New-SpecrewIsolatedTaskRunId
    $startedAt = (Get-Date).ToUniversalTime().ToString('o')
    $deadline = (Get-Date).ToUniversalTime().AddSeconds($TimeoutSec).ToString('o')
    $hostLabel = Get-SpecrewIsolatedTaskHost

    New-Item -ItemType Directory -Path $RunDir -Force | Out-Null

    # 1) Materialize the ephemeral worktree from the tree-id (RO export). Do this BEFORE firing so a
    #    materialization failure surfaces synchronously to the caller (no half-fired supervisor).
    $ephemeralRoot = Get-SpecrewIsolatedTaskEphemeralRoot
    $worktreePath = New-SpecrewIsolatedTaskWorktree -RepoRoot $RepoRoot -TreeId $TreeId -EphemeralRoot $ephemeralRoot

    # 2) Registry entry FIRST (status=running), so a late parent write can never clobber the
    #    supervisor's terminal update. The supervisor does a read-modify-write to a terminal status.
    $pendingDir = Get-SpecrewIsolatedTaskPendingDir -RepoRoot $RepoRoot
    New-Item -ItemType Directory -Path $pendingDir -Force | Out-Null
    $registryPath = Join-Path $pendingDir "$runId.json"
    $statusPath = Join-Path $RunDir 'status.json'
    $resultPath = Join-Path $RunDir 'result.out'      # the child's stdout = the reviewer result
    $resultErrPath = Join-Path $RunDir 'result.err'

    $registry = [ordered]@{
        schema_version = '1.0'
        run_id         = $runId
        supervisor_pid = $null            # filled after Start-Process
        host           = $hostLabel
        task_kind      = $TaskKind
        access         = $Access
        disposition    = $Disposition
        tree_id        = $TreeId
        worktree_path  = $worktreePath
        run_dir        = $RunDir
        status_path    = $statusPath
        result_path    = $resultPath
        started_at     = $startedAt
        deadline       = $deadline
        status         = 'running'        # running -> done | timed-out | failed
    }
    Write-SpecrewFileAtomic -Path $registryPath -Content (($registry | ConvertTo-Json -Depth 8))

    # The job spec the supervisor reads (NOT -ArgumentList: an arbitrary -Command string through
    # Start-Process quoting is cross-platform hell; a JSON file is robust + testable).
    $jobPath = Join-Path $RunDir 'job.json'
    $job = [ordered]@{
        schema_version = '1.0'
        run_id         = $runId
        repo_root      = $RepoRoot
        tree_id        = $TreeId
        access         = $Access
        disposition    = $Disposition
        task_kind      = $TaskKind
        command        = $Command
        worktree_path  = $worktreePath
        timeout_sec    = $TimeoutSec
        run_dir        = $RunDir
        registry_path  = $registryPath
        status_path    = $statusPath
        result_path    = $resultPath
        result_err     = $resultErrPath
    }
    Write-SpecrewFileAtomic -Path $jobPath -Content (($job | ConvertTo-Json -Depth 8))

    # 3) Fire the supervisor DETACHED. Redirect ITS stdio to files (cross-platform detachment: the
    #    load-bearing T076 rule). NO -Wait. Return immediately.
    $supervisor = Get-SpecrewIsolatedTaskSupervisorPath
    $supOut = Join-Path $RunDir 'supervisor.out.log'
    $supErr = Join-Path $RunDir 'supervisor.err.log'
    $spArgs = @{
        FilePath               = 'pwsh'
        ArgumentList           = @('-NoProfile', '-NonInteractive', '-File', $supervisor, '-JobPath', $jobPath)
        PassThru               = $true
        RedirectStandardOutput = $supOut
        RedirectStandardError  = $supErr
    }
    if ($IsWindows) { $spArgs.WindowStyle = 'Hidden' }   # Windows-only; omit on Unix
    $proc = Start-Process @spArgs

    # Record the supervisor pid into the registry (read-modify-write; the supervisor only writes the
    # terminal status fields after this).
    $registry.supervisor_pid = $proc.Id
    Write-SpecrewFileAtomic -Path $registryPath -Content (($registry | ConvertTo-Json -Depth 8))

    # Fire-and-return: hand back the run metadata. The caller does NOT wait.
    return [pscustomobject]([ordered]@{
            run_id         = $runId
            supervisor_pid = $proc.Id
            host           = $hostLabel
            task_kind      = $TaskKind
            access         = $Access
            disposition    = $Disposition
            tree_id        = $TreeId
            worktree_path  = $worktreePath
            run_dir        = $RunDir
            registry_path  = $registryPath
            status_path    = $statusPath
            result_path    = $resultPath
            started_at     = $startedAt
            deadline       = $deadline
            status         = 'running'
        })
}

function Stop-SpecrewIsolatedTask {
    <#
        Cleanup/reaper helper the FUTURE reaper calls for zombies + orphaned worktrees from a DEAD
        launcher. Orphan-safety is BY CONSTRUCTION (the supervisor self-limits + disposes in a
        finally); this is the BACKSTOP for the case the supervisor itself was killed before it could
        dispose. Idempotent: kills the supervisor pid if alive, removes the worktree if present,
        marks the registry entry terminal.

        Pass either a registry path or the parsed registry object (one of -RegistryPath/-Registry).
    #>
    [CmdletBinding()]
    param(
        [string]$RegistryPath,
        [psobject]$Registry,
        [string]$Reason = 'reaped'
    )

    if (-not $Registry) {
        if (-not $RegistryPath -or -not (Test-Path -LiteralPath $RegistryPath -PathType Leaf)) {
            throw "Stop-SpecrewIsolatedTask: provide -Registry or an existing -RegistryPath."
        }
        $Registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
    }

    # 1) Kill the supervisor if still alive (zombie from a dead launcher's orphan, or a stuck loop).
    $supPid = $null
    if ($Registry.PSObject.Properties.Name -contains 'supervisor_pid') { $supPid = $Registry.supervisor_pid }
    if ($supPid) {
        $alive = $null
        try { $alive = Get-Process -Id ([int]$supPid) -ErrorAction Stop } catch { $alive = $null }
        if ($alive) {
            try { Stop-Process -Id ([int]$supPid) -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
        }
    }

    # 2) Remove the orphaned worktree if it survived.
    $wt = $null
    if ($Registry.PSObject.Properties.Name -contains 'worktree_path') { $wt = $Registry.worktree_path }
    if ($wt -and (Test-Path -LiteralPath $wt)) {
        Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue
    }

    # 3) Mark the registry terminal so the reaper does not re-process it.
    if ($RegistryPath -and (Test-Path -LiteralPath $RegistryPath -PathType Leaf)) {
        try {
            $reg = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
            $reg | Add-Member -NotePropertyName 'status' -NotePropertyValue $Reason -Force
            $reg | Add-Member -NotePropertyName 'reaped_at' -NotePropertyValue ((Get-Date).ToUniversalTime().ToString('o')) -Force
            Write-SpecrewFileAtomic -Path $RegistryPath -Content (($reg | ConvertTo-Json -Depth 8))
        }
        catch { $null = $_ }
    }

    return [pscustomobject]([ordered]@{
            run_id         = ($Registry.PSObject.Properties.Name -contains 'run_id') ? $Registry.run_id : $null
            supervisor_pid = $supPid
            worktree_path  = $wt
            worktree_gone  = (-not ($wt -and (Test-Path -LiteralPath $wt)))
            status         = $Reason
        })
}
