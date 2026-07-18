$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 / T046: target-neutral review snapshot port. The production code adapter uses a real
# external `git worktree` sharing the origin object database; the thin non-code adapter proves the
# port is not code-specific. The origin remains the sole product-code mutation authority.

if (-not (Get-Command -Name 'Resolve-ReviewCurrentness' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-authority-core.ps1') }
if (-not (Get-Command -Name 'Get-ContinuousCoReviewReviewedStateDigest' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'reviewed-state-digest.ps1') }

function Invoke-ReviewTargetGit {
    param(
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $start = [System.Diagnostics.ProcessStartInfo]::new()
    $start.FileName = 'git'
    foreach ($argument in $Arguments) { [void]$start.ArgumentList.Add([string]$argument) }
    $start.WorkingDirectory = $WorkingDirectory
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.StandardOutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $start.StandardErrorEncoding = [System.Text.UTF8Encoding]::new($false)
    $process = [System.Diagnostics.Process]::new(); $process.StartInfo = $start
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd(); $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit(); $exitCode = $process.ExitCode; $process.Dispose()
    return [pscustomobject]@{ exit_code = $exitCode; stdout = $stdout.Trim(); stderr = $stderr.Trim() }
}

function Get-ReviewTargetSuppressionEnvironment {
    # These are process-local reviewer controls, not ambient authority switches. The checked-in target
    # has Specrew machinery stripped by the canonical digest, and an installed hook that still fires
    # receives the established all-event no-op signal.
    return [ordered]@{
        SPECREW_REFOCUS_DISABLE = '1'
        SPECREW_DISABLE_EVENTS = 'SessionStart,UserPromptSubmit,PostToolUse,Stop'
    }
}

function Test-ReviewTargetPathUnderRoot {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Root)
    if (Get-Command -Name 'Test-ContinuousCoReviewPathUnderRoot' -ErrorAction SilentlyContinue) {
        return [bool](Test-ContinuousCoReviewPathUnderRoot -Path $Path -Root $Root)
    }
    $pathFull = [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $comparison = if ([OperatingSystem]::IsWindows()) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    return $pathFull.Equals($rootFull, $comparison) -or $pathFull.StartsWith($rootFull + [IO.Path]::DirectorySeparatorChar, $comparison)
}

function New-ReviewTargetWorkspaceToken {
    # Twelve independent random bytes encode to 16 URL-safe characters: 96 source bits (about
    # 83 bits of namespace entropy after case-folding) with 33 fewer path characters than the
    # former run-token + full-GUID leaf.
    $bytes = [Security.Cryptography.RandomNumberGenerator]::GetBytes(12)
    return [Convert]::ToBase64String($bytes).Replace('+', '-').Replace('/', '_')
}

function Get-GitReviewTargetOriginEvidence {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$OriginRepo)
    $origin = (Resolve-Path -LiteralPath $OriginRepo).Path
    $head = Invoke-ReviewTargetGit -WorkingDirectory $origin -Arguments @('rev-parse', 'HEAD')
    if ($head.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace($head.stdout)) { throw ('review-target-head-unavailable:' + $head.stderr) }
    $digest = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $origin
    if ($null -eq $digest -or -not $digest.ok -or [string]::IsNullOrWhiteSpace([string]$digest.tree_id)) {
        $reason = if ($null -ne $digest) { [string]$digest.failure_reason } else { 'null-digest' }
        throw "review-target-digest-unavailable:$reason"
    }
    return [pscustomobject]@{ origin_head = $head.stdout; reviewed_state_digest = [string]$digest.tree_id }
}

function New-GitReviewTargetSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OriginRepo,
        [Parameter(Mandatory)][string]$RunId,
        [string]$ExternalRoot
    )
    if (-not (Test-ReviewAuthorityIdentifier -Value $RunId -Kind run)) { throw "review-target-invalid-run-id:$RunId" }
    $origin = (Resolve-Path -LiteralPath $OriginRepo).Path
    $gitRootResult = Invoke-ReviewTargetGit -WorkingDirectory $origin -Arguments @('rev-parse', '--show-toplevel')
    if ($gitRootResult.exit_code -ne 0) { throw ('review-target-not-git:' + $gitRootResult.stderr) }
    $gitRoot = [IO.Path]::GetFullPath($gitRootResult.stdout)
    $prefixResult = Invoke-ReviewTargetGit -WorkingDirectory $origin -Arguments @('rev-parse', '--show-prefix')
    if ($prefixResult.exit_code -ne 0) { throw ('review-target-prefix-unavailable:' + $prefixResult.stderr) }
    $prefix = $prefixResult.stdout.Trim().TrimEnd('/')
    $before = Get-GitReviewTargetOriginEvidence -OriginRepo $origin

    if ([string]::IsNullOrWhiteSpace($ExternalRoot)) { $ExternalRoot = Join-Path ([IO.Path]::GetTempPath()) 'specrew-review-targets' }
    $externalFull = [IO.Path]::GetFullPath($ExternalRoot)
    if ((Test-ReviewTargetPathUnderRoot -Path $externalFull -Root $gitRoot) -or (Test-ReviewTargetPathUnderRoot -Path $externalFull -Root $origin)) {
        throw 'review-target-external-root-inside-origin'
    }
    [IO.Directory]::CreateDirectory($externalFull) | Out-Null
    # The full run ID remains in immutable authority metadata. A URL-safe token drawn from 96
    # independent random bits keeps the filesystem name bounded with strong cross-run uniqueness.
    $workspaceRoot = Join-Path $externalFull ('rt-' + (New-ReviewTargetWorkspaceToken))
    if ([IO.Directory]::Exists($workspaceRoot) -or [IO.File]::Exists($workspaceRoot)) {
        throw 'review-target-workspace-collision'
    }
    $added = $false
    try {
        # Create a genuine linked worktree (shared objects), then checkout the canonical current-state
        # tree into that worktree's private index without moving any origin ref/index/working file.
        $add = Invoke-ReviewTargetGit -WorkingDirectory $gitRoot -Arguments @('worktree', 'add', '--detach', '--no-checkout', $workspaceRoot, 'HEAD')
        if ($add.exit_code -ne 0) { throw ('review-target-worktree-add-failed:' + $add.stderr) }
        $added = $true
        $checkout = Invoke-ReviewTargetGit -WorkingDirectory $workspaceRoot -Arguments @('read-tree', '--reset', '-u', $before.reviewed_state_digest)
        if ($checkout.exit_code -ne 0) { throw ('review-target-tree-checkout-failed:' + $checkout.stderr) }
        $snapshotPath = if ([string]::IsNullOrWhiteSpace($prefix)) { $workspaceRoot } else { Join-Path $workspaceRoot $prefix }
        if (-not [IO.Directory]::Exists($snapshotPath)) { throw 'review-target-snapshot-subtree-missing' }
        if ((Test-ReviewTargetPathUnderRoot -Path $workspaceRoot -Root $gitRoot) -or (Test-ReviewTargetPathUnderRoot -Path $workspaceRoot -Root $origin)) { throw 'review-target-worktree-inside-origin' }
        if (-not (Get-Command -Name 'Get-ContinuousCoReviewWorktreeSourceHashes' -ErrorAction SilentlyContinue)) {
            . (Join-Path $PSScriptRoot 'worktree-reviewer.ps1')
        }
        $sourceHashes = Get-ContinuousCoReviewWorktreeSourceHashes -WorktreePath $snapshotPath
        return [pscustomobject]@{
            schema_version = '1.0'; target_kind = 'code'; run_id = $RunId; target_digest = $before.reviewed_state_digest
            snapshot_path = $snapshotPath; workspace_root = $workspaceRoot; origin_repo = $origin; git_root = $gitRoot
            origin_head_before = $before.origin_head; origin_digest_before = $before.reviewed_state_digest
            source_hashes_before = $sourceHashes; suppression_environment = Get-ReviewTargetSuppressionEnvironment
        }
    }
    catch {
        if ($added) { $null = Invoke-ReviewTargetGit -WorkingDirectory $gitRoot -Arguments @('worktree', 'remove', '--force', $workspaceRoot) }
        # A failed add never proves ownership of a path that appeared after the pre-check. Leave it
        # untouched; only a successfully registered worktree is safe for this invocation to remove.
        throw
    }
}

function Test-GitReviewTargetCurrentness {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)
    $after = Get-GitReviewTargetOriginEvidence -OriginRepo ([string]$Snapshot.origin_repo)
    $decision = Resolve-ReviewCurrentness -ReviewedDigest ([string]$Snapshot.target_digest) -CurrentDigest $after.reviewed_state_digest -OriginHeadBefore ([string]$Snapshot.origin_head_before) -OriginHeadAfter $after.origin_head
    return [pscustomobject]@{
        classification = $decision.classification; exact = $decision.exact; reason = $decision.reason
        origin_head_before = [string]$Snapshot.origin_head_before; origin_head_after = $after.origin_head
        reviewed_digest = [string]$Snapshot.target_digest; current_digest = $after.reviewed_state_digest
    }
}

function Test-GitReviewTargetSnapshotIntegrity {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewWorktreeSourceHashes' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'worktree-reviewer.ps1') }
    $after = Get-ContinuousCoReviewWorktreeSourceHashes -WorktreePath ([string]$Snapshot.snapshot_path)
    $before = $Snapshot.source_hashes_before
    $changed = [System.Collections.Generic.List[string]]::new()
    $keys = @(@($before.Keys) + @($after.Keys) | Sort-Object -Unique)
    foreach ($key in $keys) {
        $beforeValue = if ($before.ContainsKey($key)) { [string]$before[$key] } else { '<missing>' }
        $afterValue = if ($after.ContainsKey($key)) { [string]$after[$key] } else { '<missing>' }
        if ($beforeValue -cne $afterValue) { $changed.Add([string]$key) | Out-Null }
    }
    return [pscustomobject]@{ intact = ($changed.Count -eq 0); classification = $(if ($changed.Count -eq 0) { 'intact' } else { 'snapshot-tampered' }); changed_paths = @($changed) }
}

function Remove-GitReviewTargetSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)
    $gitRoot = [string]$Snapshot.git_root; $workspaceRoot = [string]$Snapshot.workspace_root
    $remove = Invoke-ReviewTargetGit -WorkingDirectory $gitRoot -Arguments @('worktree', 'remove', '--force', $workspaceRoot)
    $null = Invoke-ReviewTargetGit -WorkingDirectory $gitRoot -Arguments @('worktree', 'prune')
    return [pscustomobject]@{ removed = ($remove.exit_code -eq 0 -and -not [IO.Directory]::Exists($workspaceRoot)); failure_reason = $(if ($remove.exit_code -eq 0) { $null } else { $remove.stderr }) }
}

function New-NonCodeReviewTargetFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content,
        [string]$ExternalRoot
    )
    if (-not (Test-ReviewAuthorityIdentifier -Value $RunId -Kind run)) { throw "review-target-invalid-run-id:$RunId" }
    if ([string]::IsNullOrWhiteSpace($ExternalRoot)) { $ExternalRoot = Join-Path ([IO.Path]::GetTempPath()) 'specrew-review-targets' }
    [IO.Directory]::CreateDirectory($ExternalRoot) | Out-Null
    $workspace = Join-Path ([IO.Path]::GetFullPath($ExternalRoot)) ('review-target-{0}-{1}' -f $RunId, [guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($workspace) | Out-Null
    $path = Join-Path $workspace 'artifact.txt'
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
    $digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Content))).ToLowerInvariant()
    return [pscustomobject]@{
        schema_version = '1.0'; target_kind = 'non-code-fixture'; run_id = $RunId; target_digest = $digest
        snapshot_path = $workspace; workspace_root = $workspace; origin_repo = $null; git_root = $null
        suppression_environment = Get-ReviewTargetSuppressionEnvironment
    }
}

function Remove-NonCodeReviewTargetFixture {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)
    $path = [string]$Snapshot.workspace_root
    if ([IO.Directory]::Exists($path)) { [IO.Directory]::Delete($path, $true) }
    return [pscustomobject]@{ removed = -not [IO.Directory]::Exists($path); failure_reason = $null }
}
