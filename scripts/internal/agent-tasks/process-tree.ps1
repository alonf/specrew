# Cross-platform graceful process-TREE kill, shared by the isolated-task supervisor (the async watchdog)
# AND the inline reviewer spawn (continuous-co-review/worktree-reviewer.ps1) - ONE kill mechanism, not two
# divergent ones (T091/FR-037, "consolidate on the supervisor"). The reviewer (claude -p / codex exec) may
# be a GRANDCHILD of the spawned process, so a single-pid kill orphans it; this snapshots the descendant
# tree and does graceful SIGTERM -> flush window -> SIGKILL so an in-flight finding (R1) can flush first.
Set-StrictMode -Version Latest

function Get-SpecrewProcessTreeDescendants {
    # Snapshot the full descendant tree (BFS via `pgrep -P`) BEFORE any kill - so a grandchild that the kill
    # would re-parent is still in the snapshot. Returns descendants only (NOT $RootPid), deepest-first.
    param([Parameter(Mandatory)][int]$RootPid)
    $ordered = [System.Collections.Generic.List[int]]::new()
    $frontier = @($RootPid)
    while ($frontier.Count -gt 0) {
        $next = [System.Collections.Generic.List[int]]::new()
        foreach ($p in $frontier) {
            $kids = @()
            try {
                $raw = & pgrep -P $p 2>$null
                $kids = @($raw | ForEach-Object { $i = 0; if ([int]::TryParse(($_.ToString().Trim()), [ref]$i)) { $i } } | Where-Object { $_ -gt 0 })
            }
            catch { $kids = @() }
            foreach ($k in $kids) { if (-not $ordered.Contains($k)) { $ordered.Add($k); $next.Add($k) } }
        }
        $frontier = $next.ToArray()
    }
    $ordered.Reverse()
    return , ($ordered.ToArray())
}

function Stop-SpecrewProcessTree {
    # Kill $RootPid AND its descendant(s), gracefully (SIGTERM -> flush) then hard (SIGKILL). Cross-platform.
    param([Parameter(Mandatory)][int]$RootPid, [int]$GraceSeconds = 5)
    if ($IsWindows) {
        try { & taskkill /PID $RootPid /T 2>&1 | Out-Null } catch { $null = $_ }          # graceful close
        if ($GraceSeconds -gt 0) { Start-Sleep -Seconds $GraceSeconds }
        try { & taskkill /PID $RootPid /T /F 2>&1 | Out-Null } catch { $null = $_ }        # force the tree
        return
    }
    # Unix. `kill` is a Stop-Process ALIAS in PowerShell, so resolve the Application binary explicitly.
    $killBin = Get-Command -Name 'kill' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $killBin) {
        foreach ($p in (@(Get-SpecrewProcessTreeDescendants -RootPid $RootPid) + @($RootPid))) { try { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
        return
    }
    # The kill order matters because of a spawn race: a descendant (the reviewer) can appear just before the
    # deadline, AND once the root dies its orphan re-parents to init and falls out of `pgrep -P` reach. So:
    # Pass 1 - graceful SIGTERM of the current descendants (the reviewer's flush window); the ROOT stays alive.
    foreach ($p in (Get-SpecrewProcessTreeDescendants -RootPid $RootPid)) { try { & $killBin.Source -TERM $p 2>$null } catch { $null = $_ } }
    if ($GraceSeconds -gt 0) { Start-Sleep -Seconds $GraceSeconds }
    # Pass 2 - RE-enumerate while the root is still alive (catches a descendant the first snapshot raced past) + SIGKILL.
    foreach ($p in (Get-SpecrewProcessTreeDescendants -RootPid $RootPid)) { try { & $killBin.Source -KILL $p 2>$null } catch { $null = $_ } }
    # Pass 3 - SIGKILL the root LAST (killing it earlier would orphan a late descendant out of pgrep's view).
    try { & $killBin.Source -KILL $RootPid 2>$null } catch { $null = $_ }
}
