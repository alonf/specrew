[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$RunDir,
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][string]$RegistryPath,
    [string]$BaselineRef,
    [string]$CodeWriterHost,
    [string]$RequestedHost,
    [int]$TimeoutSeconds = 900
)
# iter-008 — the DETACHED entry the worktree-navigator spawns (non-blocking). Runs the orchestrator (which writes
# result.out + status.json to $RunDir + disposes the ephemeral worktree), then flips the pending REGISTRY status
# (running -> the orchestrator's terminal status) so the navigator's existing reap consumes it exactly like the
# legacy supervisor path. All heavy work lives here, off the Stop budget.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Win32_Process.Create (the Windows detached spawn in co-review-service.ps1) gives THIS process NO inherited stdio
# - the parent deliberately inherits NOTHING so it cannot hold the host's stdout pipe open (the 20-min Stop). So
# self-redirect the PS streams to entry.out.log here, so a dot-source/load/run error is still diagnosable. Best-
# effort: a transcript failure must never abort the review (the orchestrator's status.json is the reliable record).
try { Start-Transcript -LiteralPath (Join-Path $RunDir 'entry.out.log') -Force -ErrorAction Stop | Out-Null } catch { $null = $_ }

. (Join-Path $PSScriptRoot 'worktree-review-orchestrator.ps1')

function Update-WorktreeRunRegistryStatus {
    param([string]$Path, [string]$Status, [hashtable]$Extra)
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
        $reg = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        $reg.status = $Status
        if ($Extra) { foreach ($k in $Extra.Keys) { $reg | Add-Member -NotePropertyName $k -NotePropertyValue $Extra[$k] -Force } }
        $json = $reg | ConvertTo-Json -Depth 10
        if (Get-Command -Name 'Write-SpecrewFileAtomic' -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $Path -Content $json }
        else { [System.IO.File]::WriteAllText($Path, $json) }
    }
    catch { $null = $_ }
}

# LEASE SELF-ADOPTION GATE (lease-lifecycle hardening 2026-07-15): adopt the lineage lease BEFORE any review
# work. Closes the parent-crash-before-handoff window: if the acquiring parent died before re-stamping the
# lease to this supervisor, this adoption (token+generation-matched) claims it; if the lease was meanwhile
# reclaimed/replaced (a different owner is authoritative), this supervisor EXITS without reviewing rather
# than run unprotected - never two authoritative reviewers for one lineage.
try {
    if (-not (Get-Command -Name 'Invoke-ContinuousCoReviewSupervisorLeaseGate' -ErrorAction SilentlyContinue)) {
        $leaseModule = Join-Path $PSScriptRoot 'co-review-lineage-lease.ps1'
        if (Test-Path -LiteralPath $leaseModule -PathType Leaf) { . $leaseModule }
    }
    if (Get-Command -Name 'Invoke-ContinuousCoReviewSupervisorLeaseGate' -ErrorAction SilentlyContinue) {
        $leaseGate = Invoke-ContinuousCoReviewSupervisorLeaseGate -RepoRoot $RepoRoot -RegistryPath $RegistryPath -SupervisorPid $PID
        if (-not [bool]$leaseGate.proceed) {
            Update-WorktreeRunRegistryStatus -Path $RegistryPath -Status 'failed' -Extra @{ failure_reason = ('supervisor-lease-gate: ' + [string]$leaseGate.reason) }
            try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { $null = $_ }
            exit 1
        }
    }
}
catch { $null = $_ }   # the gate itself failing open is handled inside; never abort the entry on gate plumbing

try {
    $params = @{ RepoRoot = $RepoRoot; RunDir = $RunDir; RunId = $RunId; TimeoutSeconds = $TimeoutSeconds }
    if (-not [string]::IsNullOrWhiteSpace($BaselineRef)) { $params.BaselineRef = $BaselineRef }
    if (-not [string]::IsNullOrWhiteSpace($CodeWriterHost)) { $params.CodeWriterHost = $CodeWriterHost }
    if (-not [string]::IsNullOrWhiteSpace($RequestedHost)) { $params.RequestedHost = $RequestedHost }
    $st = Invoke-ContinuousCoReviewWorktreeReviewRun @params
    $term = if ($null -ne $st -and ($st.PSObject.Properties.Name -contains 'status')) { [string]$st.status } else { 'failed' }
    $extra = @{}
    if ($null -ne $st -and ($st.PSObject.Properties.Name -contains 'failure_reason')) { $extra.failure_reason = [string]$st.failure_reason }
    # Propagate the reviewed-state digest the orchestrator computed (off the Stop budget) to the registry, so the
    # reap promotes the gate's identity, not the HEAD-tree (the freshness-mismatch bug).
    if ($null -ne $st -and ($st.PSObject.Properties.Name -contains 'reviewed_digest_tree_id')) { $extra.reviewed_digest_tree_id = [string]$st.reviewed_digest_tree_id }
    # T093/FR-035: propagate the independence label so the reap can surface a same-host fallback + the
    # authorize-an-independent-host upgrade ask (the answer upgrades the NEXT run; this one never blocked).
    if ($null -ne $st -and ($st.PSObject.Properties.Name -contains 'reviewer_independence')) { $extra.reviewer_independence = [string]$st.reviewer_independence }
    Update-WorktreeRunRegistryStatus -Path $RegistryPath -Status $term -Extra $extra
}
catch {
    Update-WorktreeRunRegistryStatus -Path $RegistryPath -Status 'failed' -Extra @{ failure_reason = ('detached-entry-exception: ' + $_.Exception.Message) }
}
try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { $null = $_ }
