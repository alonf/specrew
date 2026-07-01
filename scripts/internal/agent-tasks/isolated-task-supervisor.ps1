<#
.SYNOPSIS
    The detached supervisor body for the isolated-task launcher (the "watchdog" role).

.DESCRIPTION
    This script is the DETACHED process `Start-SpecrewIsolatedTask` fires via `pwsh -File`. It runs
    to completion EVEN AFTER its parent (the Stop-hook provider) exits - that is the whole point of
    the launcher: the expensive task runs off the provider's budget.

    It reads a single job JSON (no -ArgumentList quoting hell), then:
      1. Spawns the harness `-Command` IN the materialized worktree (cwd = worktree), redirecting
         the child's stdio to FILES (the child's stdout IS the reviewer result -> result.out). The
         redirect at every hop is the load-bearing T076 cross-platform-detachment rule.
      2. Enforces its OWN timeout in plain PowerShell ($child.HasExited poll + Stop-Process -Force
         on deadline) - NOT an OS process-group flag (most portable + testable). On timeout it kills
         the child PROCESS TREE (the harness may have spawned its own reviewer subprocess).
      3. Writes a terminal status.json AND read-modify-writes the registry's status field to a
         terminal value (running -> done | timed-out | failed).
      4. DISPOSES the worktree in a `finally` so a timed-out/killed run STILL deletes it - orphan
         safety by construction (this feature exists to prevent the orphaned-worktree/zombie leak).

    Only `disposition: discard` is implemented (review). The job carries access/disposition for the
    future seams; this body asserts the built path and disposes by discard.

.NOTES
    F-184 footprint: NONE. PowerShell 7.x. Standalone (NOT dot-sourced) so the launcher can be
    dot-sourced for its functions without ever running this supervisor loop.
#>
param(
    [Parameter(Mandatory)][string]$JobPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- helpers (self-contained, except the co-located process-tree.ps1 sibling dot-sourced below) ---
function Write-SupervisorJson {
    param([string]$Path, $Object)
    $tmp = '{0}.{1}.tmp' -f $Path, ([guid]::NewGuid().ToString('N'))
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($tmp, ($Object | ConvertTo-Json -Depth 8), $utf8NoBom)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Update-SupervisorRegistryStatus {
    param([string]$RegistryPath, [string]$Status, [hashtable]$Extra = @{})
    if (-not $RegistryPath -or -not (Test-Path -LiteralPath $RegistryPath -PathType Leaf)) { return }
    try {
        $reg = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
        $reg | Add-Member -NotePropertyName 'status' -NotePropertyValue $Status -Force
        foreach ($k in $Extra.Keys) { $reg | Add-Member -NotePropertyName $k -NotePropertyValue $Extra[$k] -Force }
        Write-SupervisorJson -Path $RegistryPath -Object $reg
    }
    catch { $null = $_ }
}

# --- co-located process-tree kill helper (T091/FR-037, the ONE watchdog kill) --------------------
# The supervisor stays standalone (never dot-SOURCED itself, so the launcher can dot-source its own
# functions without running this loop), but it MAY dot-source this co-located sibling - the FileList
# always co-deploys process-tree.ps1 in this dir. Require it (throw, don't silently degrade the kill).
$processTreeHelper = Join-Path $PSScriptRoot 'process-tree.ps1'
if (-not (Test-Path -LiteralPath $processTreeHelper -PathType Leaf)) {
    throw "isolated-task-supervisor: missing co-located process-tree helper '$processTreeHelper'."
}
. $processTreeHelper

# --- load the job spec ---------------------------------------------------------------------------
$job = Get-Content -LiteralPath $JobPath -Raw | ConvertFrom-Json
$worktree = $job.worktree_path
$runDir = $job.run_dir
$statusPath = $job.status_path
$resultPath = $job.result_path
$resultErrPath = $job.result_err
$registryPath = $job.registry_path
$timeoutSec = [int]$job.timeout_sec
$command = $job.command

$terminalStatus = 'failed'
$childPid = $null
$childExit = $null

try {
    # Built path only: review = read-only + discard. (Job may carry future seams; assert here.)
    if ($job.access -ne 'read-only') { throw "supervisor: access '$($job.access)' not implemented" }
    if ($job.disposition -ne 'discard') { throw "supervisor: disposition '$($job.disposition)' not implemented" }

    # 1) Spawn the harness IN the worktree, child stdio -> files (stdout = the reviewer result).
    #    CROSS-PLATFORM QUOTING: do NOT pass the command via `pwsh -Command <string>` - an arbitrary
    #    command string loses its embedded quotes when Start-Process joins -ArgumentList on Linux
    #    (the WSL run proved this corrupts the child's script). Instead write the command to a
    #    harness.ps1 FILE and run `pwsh -File <path>`: a single file-path argument has no embedded
    #    quotes and survives Start-Process's arg-join identically on both platforms. This keeps the
    #    PROVEN detachment mechanism intact (Start-Process + file stdio redirect) and changes only
    #    WHAT is passed. Bonus: multi-line commands + the harness-as-evidence come for free.
    #    -WorkingDirectory makes the reviewer see the materialized snapshot as its repo root, so
    #    `$PWD` inside the harness is the worktree.
    $harnessPath = Join-Path $runDir 'harness.ps1'
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($harnessPath, $command, $utf8NoBom)
    $spArgs = @{
        FilePath               = 'pwsh'
        ArgumentList           = @('-NoProfile', '-NonInteractive', '-File', $harnessPath)
        WorkingDirectory       = $worktree
        PassThru               = $true
        RedirectStandardOutput = $resultPath
        RedirectStandardError  = $resultErrPath
    }
    if ($IsWindows) { $spArgs.WindowStyle = 'Hidden' }   # Windows-only; omit on Unix
    $child = Start-Process @spArgs
    $childPid = $child.Id

    # 2) Own timeout/kill loop (plain PowerShell - portable + testable).
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    $timedOut = $false
    while (-not $child.HasExited) {
        if ((Get-Date) -ge $deadline) {
            # Kill the child PROCESS TREE. The reviewer (claude -p / codex exec) is a GRANDCHILD of the
            # harness pwsh, so a single-pid kill ORPHANS it (T091/FR-037, WSL-gated). Stop-IsolatedTaskTree
            # snapshots the descendant tree and does graceful SIGTERM -> flush -> SIGKILL across platforms.
            Stop-SpecrewProcessTree -RootPid $child.Id -GraceSeconds 5
            $timedOut = $true
            break
        }
        Start-Sleep -Milliseconds 100
    }
    Start-Sleep -Milliseconds 300   # let the exit/kill settle

    $childAlive = $null -ne (Get-Process -Id $child.Id -ErrorAction SilentlyContinue)
    if ($timedOut) {
        $terminalStatus = 'timed-out'
    }
    else {
        $childExit = $child.ExitCode
        $terminalStatus = ($childExit -eq 0) ? 'done' : 'failed'
    }

    # 3) Terminal status.json (the reviewer's result is at result.out, captured by the redirect).
    $status = [ordered]@{
        schema_version = '1.0'
        run_id         = $job.run_id
        status         = $terminalStatus
        timed_out      = $timedOut
        child_pid      = $childPid
        child_exit     = $childExit
        child_alive    = $childAlive
        result_path    = $resultPath
        result_err     = $resultErrPath
        finished_at    = (Get-Date).ToUniversalTime().ToString('o')
    }
    Write-SupervisorJson -Path $statusPath -Object $status
}
catch {
    $terminalStatus = 'failed'
    try {
        Write-SupervisorJson -Path $statusPath -Object ([ordered]@{
                schema_version = '1.0'
                run_id         = $job.run_id
                status         = 'failed'
                error          = $_.Exception.Message
                child_pid      = $childPid
                finished_at    = (Get-Date).ToUniversalTime().ToString('o')
            })
    }
    catch { $null = $_ }
}
finally {
    # 4) DISPOSE in a finally - even a timed-out/killed/failed run deletes the worktree. This is the
    #    orphan-safety-by-construction guarantee. (discard = delete; merge/preserve are seams.)
    if ($worktree -and (Test-Path -LiteralPath $worktree)) {
        Remove-Item -LiteralPath $worktree -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Mark the registry terminal (read-modify-write; running -> terminal).
    Update-SupervisorRegistryStatus -RegistryPath $registryPath -Status $terminalStatus -Extra @{
        finished_at   = (Get-Date).ToUniversalTime().ToString('o')
        worktree_gone = (-not ($worktree -and (Test-Path -LiteralPath $worktree)))
    }
}
