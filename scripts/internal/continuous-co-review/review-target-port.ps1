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

function Get-ReviewTargetVerificationPlanCapture {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RepoRoot)

    $path = Join-Path $RepoRoot '.specrew/verification-plan.json'
    if (-not [IO.File]::Exists($path)) {
        return [pscustomobject]@{ present = $false; sha256 = $null; bytes = $null }
    }
    $bytes = [IO.File]::ReadAllBytes($path)
    $sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    return [pscustomobject]@{ present = $true; sha256 = $sha256; bytes = $bytes }
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
    $machineryPaths = @($digest.machinery_paths | ForEach-Object { ([string]$_ -replace '\\', '/').Trim('/') } | Sort-Object -Unique)
    $machineryPathBytes = [Text.Encoding]::UTF8.GetBytes(($machineryPaths -join "`n"))
    $machineryPathsSha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($machineryPathBytes)).ToLowerInvariant()
    return [pscustomobject]@{
        origin_head = $head.stdout; reviewed_state_digest = [string]$digest.tree_id
        machinery_paths = @($machineryPaths); machinery_paths_sha256 = $machineryPathsSha256
    }
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
    # The canonical code digest deliberately excludes .specrew/**. The selected verification plan is
    # nevertheless a project-owned campaign input, so freeze its exact bytes alongside the code tree and
    # bind its hash into the target's currentness check. It is never read live after this capture.
    $verificationPlan = Get-ReviewTargetVerificationPlanCapture -RepoRoot $origin

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
            machinery_paths = @($before.machinery_paths); machinery_paths_sha256 = $before.machinery_paths_sha256
            verification_plan_present = [bool]$verificationPlan.present; verification_plan_sha256 = $verificationPlan.sha256
            verification_plan_bytes = $(if ($verificationPlan.present) { [byte[]]$verificationPlan.bytes } else { $null })
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

function New-GitReviewTargetVerificationCopy {
    <#
        Creates a second linked worktree from the already-frozen target identity. Controller
        verification executes only in this copy; the reviewer target remains byte-identical to
        its initial baseline. No live origin state is re-resolved here.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Snapshot,
        [string]$RunId = ([string]$Snapshot.run_id + '-verification')
    )
    foreach ($name in @('target_digest', 'snapshot_path', 'workspace_root', 'git_root', 'origin_repo', 'origin_head_before')) {
        if (-not $Snapshot.PSObject.Properties[$name] -or [string]::IsNullOrWhiteSpace([string]$Snapshot.$name)) {
            throw "review-target-verification-copy-missing:$name"
        }
    }
    if (-not (Test-ReviewAuthorityIdentifier -Value $RunId -Kind run)) { throw "review-target-invalid-run-id:$RunId" }
    $gitRoot = [IO.Path]::GetFullPath([string]$Snapshot.git_root)
    $externalRoot = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath([string]$Snapshot.workspace_root))
    $workspaceRoot = Join-Path $externalRoot ('rt-' + (New-ReviewTargetWorkspaceToken))
    if ([IO.Directory]::Exists($workspaceRoot) -or [IO.File]::Exists($workspaceRoot)) { throw 'review-target-workspace-collision' }

    $relativeSnapshot = [IO.Path]::GetRelativePath([IO.Path]::GetFullPath([string]$Snapshot.workspace_root), [IO.Path]::GetFullPath([string]$Snapshot.snapshot_path))
    if ($relativeSnapshot.StartsWith('..')) { throw 'review-target-verification-copy-subtree-invalid' }
    $added = $false
    try {
        $add = Invoke-ReviewTargetGit -WorkingDirectory $gitRoot -Arguments @('worktree', 'add', '--detach', '--no-checkout', $workspaceRoot, [string]$Snapshot.origin_head_before)
        if ($add.exit_code -ne 0) { throw ('review-target-worktree-add-failed:' + $add.stderr) }
        $added = $true
        $checkout = Invoke-ReviewTargetGit -WorkingDirectory $workspaceRoot -Arguments @('read-tree', '--reset', '-u', [string]$Snapshot.target_digest)
        if ($checkout.exit_code -ne 0) { throw ('review-target-tree-checkout-failed:' + $checkout.stderr) }
        $snapshotPath = if ($relativeSnapshot -ceq '.') { $workspaceRoot } else { Join-Path $workspaceRoot $relativeSnapshot }
        if (-not [IO.Directory]::Exists($snapshotPath)) { throw 'review-target-snapshot-subtree-missing' }

        if ([bool]$Snapshot.verification_plan_present) {
            if (-not $Snapshot.PSObject.Properties['verification_plan_bytes'] -or $null -eq $Snapshot.verification_plan_bytes) {
                throw 'review-target-verification-copy-plan-bytes-missing'
            }
            $bytes = [byte[]]$Snapshot.verification_plan_bytes
            $sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
            if ($sha256 -cne [string]$Snapshot.verification_plan_sha256) { throw 'review-target-verification-copy-plan-mismatch' }
            $targetPlan = Join-Path $snapshotPath '.specrew/verification-plan.json'
            [IO.Directory]::CreateDirectory((Split-Path -Parent $targetPlan)) | Out-Null
            [IO.File]::WriteAllBytes($targetPlan, $bytes)
        }
        if (-not (Get-Command -Name 'Get-ContinuousCoReviewWorktreeSourceHashes' -ErrorAction SilentlyContinue)) {
            . (Join-Path $PSScriptRoot 'worktree-reviewer.ps1')
        }
        return [pscustomobject]@{
            schema_version = '1.0'; target_kind = 'code-verification-copy'; run_id = $RunId
            target_digest = [string]$Snapshot.target_digest; snapshot_path = $snapshotPath; workspace_root = $workspaceRoot
            origin_repo = [string]$Snapshot.origin_repo; git_root = $gitRoot
            origin_head_before = [string]$Snapshot.origin_head_before; origin_digest_before = [string]$Snapshot.origin_digest_before
            machinery_paths = @($Snapshot.machinery_paths); machinery_paths_sha256 = [string]$Snapshot.machinery_paths_sha256
            verification_plan_present = [bool]$Snapshot.verification_plan_present; verification_plan_sha256 = [string]$Snapshot.verification_plan_sha256
            source_hashes_before = Get-ContinuousCoReviewWorktreeSourceHashes -WorktreePath $snapshotPath
            suppression_environment = Get-ReviewTargetSuppressionEnvironment
        }
    }
    catch {
        if ($added) { $null = Invoke-ReviewTargetGit -WorkingDirectory $gitRoot -Arguments @('worktree', 'remove', '--force', $workspaceRoot) }
        throw
    }
}

function Invoke-ReviewTargetNativeCommand {
    param(
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $FileName
    foreach ($argument in $Arguments) { [void]$start.ArgumentList.Add($argument) }
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
    [void]$process.Start(); $stdout = $process.StandardOutput.ReadToEnd(); $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit(); $exitCode = $process.ExitCode; $process.Dispose()
    return [pscustomobject]@{ exit_code = $exitCode; stdout = $stdout.Trim(); stderr = $stderr.Trim() }
}

function Get-ReviewTargetEffectiveUserId {
    if (-not [OperatingSystem]::IsLinux()) { return $null }
    $identity = Invoke-ReviewTargetNativeCommand -FileName 'id' -Arguments @('-u')
    $effectiveUserId = 0
    if ($identity.exit_code -ne 0 -or -not [int]::TryParse($identity.stdout, [ref]$effectiveUserId)) {
        throw ('review-target-effective-user-id-unavailable:' + $identity.stderr)
    }
    return $effectiveUserId
}

function Remove-ReviewTargetWindowsDeny {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Sid)
    $identity = '*' + $Sid
    $removed = Invoke-ReviewTargetNativeCommand -FileName 'icacls.exe' -Arguments @($Root, '/remove:d', $identity, '/T', '/C', '/Q')
    if ($removed.exit_code -ne 0) { throw ('icacls-deny-remove-failed:' + $removed.stderr) }
}

function Disable-ReviewTargetReadOnlyProtection {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot, [AllowNull()]$Lease)
    $root = [IO.Path]::GetFullPath([string]$Snapshot.snapshot_path)
    if (-not [IO.Directory]::Exists($root)) { return [pscustomobject]@{ ok = $true; reason = 'snapshot-already-absent' } }
    try {
        if ([OperatingSystem]::IsWindows()) {
            $sections = [Security.AccessControl.AccessControlSections]::All
            $currentSid = if ($null -ne $Lease -and $Lease.PSObject.Properties['sid']) {
                [string]$Lease.sid
            }
            else { [Security.Principal.WindowsIdentity]::GetCurrent().User.Value }
            Remove-ReviewTargetWindowsDeny -Root $root -Sid $currentSid
            if ($null -ne $Lease -and $Lease.PSObject.Properties['original_sddl'] -and -not [string]::IsNullOrWhiteSpace([string]$Lease.original_sddl)) {
                $acl = Get-Acl -LiteralPath $root
                $acl.SetSecurityDescriptorSddlForm([string]$Lease.original_sddl, $sections)
                Set-Acl -LiteralPath $root -AclObject $acl
            }
        }
        else {
            $leasePlatform = if ($null -ne $Lease -and $Lease.PSObject.Properties['platform']) { [string]$Lease.platform } else { '' }
            $mountedReadOnly = $leasePlatform -ceq 'linux-bind-readonly'
            if (-not $mountedReadOnly -and [OperatingSystem]::IsLinux() -and (Get-ReviewTargetEffectiveUserId) -eq 0) {
                $mountPoint = Invoke-ReviewTargetNativeCommand -FileName 'mountpoint' -Arguments @('-q', $root)
                $mountedReadOnly = $mountPoint.exit_code -eq 0
            }
            if ($mountedReadOnly) {
                $unmounted = Invoke-ReviewTargetNativeCommand -FileName 'umount' -Arguments @($root)
                if ($unmounted.exit_code -ne 0) { throw ('readonly-bind-unmount-failed:' + $unmounted.stderr) }
            }
            $restored = Invoke-ReviewTargetNativeCommand -FileName 'chmod' -Arguments @('-R', 'u+w', $root)
            if ($restored.exit_code -ne 0) { throw ('chmod-restore-failed:' + $restored.stderr) }
        }
        return [pscustomobject]@{ ok = $true; reason = 'review-target-write-protection-removed' }
    }
    catch { return [pscustomobject]@{ ok = $false; reason = ('review-target-write-protection-restore-failed:' + $_.Exception.Message) } }
}

function Enable-ReviewTargetReadOnlyProtection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Snapshot,
        [Parameter(Mandatory)][string]$ExternalWritablePath
    )
    $root = [IO.Path]::GetFullPath([string]$Snapshot.snapshot_path)
    $external = [IO.Path]::GetFullPath($ExternalWritablePath)
    if (Test-ReviewTargetPathUnderRoot -Path $external -Root $root) {
        return [pscustomobject]@{ ok = $false; reason = 'review-target-writable-path-inside-snapshot'; lease = $null }
    }
    $externalParent = [IO.Path]::GetDirectoryName($external)
    if (-not [IO.Directory]::Exists($externalParent)) {
        return [pscustomobject]@{ ok = $false; reason = 'review-target-writable-parent-missing'; lease = $null }
    }
    $lease = $null
    $existingBlocked = $false
    $createBlocked = $false
    $externalWritable = $false
    try {
        if ([OperatingSystem]::IsWindows()) {
            $acl = Get-Acl -LiteralPath $root
            $originalSddl = $acl.GetSecurityDescriptorSddlForm([Security.AccessControl.AccessControlSections]::All)
            $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            $denyEntry = ('*{0}:(OI)(CI)(WD,AD,WEA,WA,DE,DC)' -f $currentSid)
            # Apply an explicit deny to every existing descendant. A root-only inheritable ACE is
            # insufficient when a checkout contains a child with an explicit allow ACE.
            $protected = Invoke-ReviewTargetNativeCommand -FileName 'icacls.exe' -Arguments @($root, '/deny', $denyEntry, '/T', '/C', '/Q')
            if ($protected.exit_code -ne 0) { throw ('icacls-deny-apply-failed:' + $protected.stderr) }
            $lease = [pscustomobject]@{ platform = 'windows-recursive-deny'; original_sddl = $originalSddl; sid = $currentSid }
        }
        elseif ([OperatingSystem]::IsLinux() -and (Get-ReviewTargetEffectiveUserId) -eq 0) {
            # chmod does not constrain uid 0. A self-bind followed by a read-only remount protects
            # the entire frozen tree in the reviewer's mount namespace, including against root.
            $bound = Invoke-ReviewTargetNativeCommand -FileName 'mount' -Arguments @('--bind', $root, $root)
            if ($bound.exit_code -ne 0) { throw ('readonly-bind-mount-failed:' + $bound.stderr) }
            $remounted = Invoke-ReviewTargetNativeCommand -FileName 'mount' -Arguments @('-o', 'remount,bind,ro', $root)
            if ($remounted.exit_code -ne 0) {
                $null = Invoke-ReviewTargetNativeCommand -FileName 'umount' -Arguments @($root)
                throw ('readonly-bind-remount-failed:' + $remounted.stderr)
            }
            $lease = [pscustomobject]@{ platform = 'linux-bind-readonly'; original_sddl = $null }
        }
        else {
            # No `--`: BSD chmod on macOS does not accept the GNU operand separator here.
            $protected = Invoke-ReviewTargetNativeCommand -FileName 'chmod' -Arguments @('-R', 'a-w', $root)
            if ($protected.exit_code -ne 0) { throw ('chmod-protect-failed:' + $protected.stderr) }
            $lease = [pscustomobject]@{ platform = 'posix'; original_sddl = $null }
        }

        $firstFile = Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction Stop | Select-Object -First 1
        if ($null -eq $firstFile) { throw 'review-target-write-protection-no-probe-file' }
        try {
            $stream = [IO.File]::Open($firstFile.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Write, [IO.FileShare]::Read)
            $stream.Dispose()
        }
        catch { $existingBlocked = $true }
        $newPath = Join-Path $root ('.specrew-readonly-probe-' + [guid]::NewGuid().ToString('N'))
        try {
            $stream = [IO.File]::Open($newPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            $stream.Dispose()
        }
        catch { $createBlocked = $true }
        $externalProbe = Join-Path $externalParent ('.specrew-external-write-probe-' + [guid]::NewGuid().ToString('N'))
        try {
            $stream = [IO.File]::Open($externalProbe, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            $stream.Dispose(); [IO.File]::Delete($externalProbe); $externalWritable = $true
        }
        catch { $externalWritable = $false }
        if (-not $existingBlocked -or -not $createBlocked -or -not $externalWritable) {
            $null = Disable-ReviewTargetReadOnlyProtection -Snapshot $Snapshot -Lease $lease
            if ([IO.File]::Exists($newPath)) { [IO.File]::Delete($newPath) }
            if ([IO.File]::Exists($externalProbe)) { [IO.File]::Delete($externalProbe) }
            $detail = 'existing={0};create={1};external={2}' -f $existingBlocked, $createBlocked, $externalWritable
            return [pscustomobject]@{
                ok = $false; reason = ('review-target-write-protection-probe-failed:' + $detail); lease = $null
                existing_write_blocked = $existingBlocked; create_blocked = $createBlocked; external_writable = $externalWritable
            }
        }
        return [pscustomobject]@{
            ok = $true; reason = 'review-target-os-read-only'; lease = $lease
            existing_write_blocked = $existingBlocked; create_blocked = $createBlocked; external_writable = $externalWritable
        }
    }
    catch {
        if ($null -ne $lease) { $null = Disable-ReviewTargetReadOnlyProtection -Snapshot $Snapshot -Lease $lease }
        return [pscustomobject]@{ ok = $false; reason = ('review-target-write-protection-failed:' + $_.Exception.Message); lease = $null }
    }
}

function Test-GitReviewTargetCurrentness {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)
    $after = Get-GitReviewTargetOriginEvidence -OriginRepo ([string]$Snapshot.origin_repo)
    $decision = Resolve-ReviewCurrentness -ReviewedDigest ([string]$Snapshot.target_digest) -CurrentDigest $after.reviewed_state_digest -OriginHeadBefore ([string]$Snapshot.origin_head_before) -OriginHeadAfter $after.origin_head
    $reasons = [Collections.Generic.List[string]]::new()
    if ([string]$decision.reason -cne 'exact-head-and-digest-match') { $reasons.Add([string]$decision.reason) | Out-Null }
    $currentPlan = Get-ReviewTargetVerificationPlanCapture -RepoRoot ([string]$Snapshot.origin_repo)
    $capturedPlanPresent = [bool]$Snapshot.verification_plan_present
    $planCurrent = ($capturedPlanPresent -eq [bool]$currentPlan.present) -and (
        (-not $capturedPlanPresent) -or ([string]$Snapshot.verification_plan_sha256 -ceq [string]$currentPlan.sha256)
    )
    if (-not $planCurrent) {
        $reasons.Add('verification-plan-changed') | Out-Null
        if ([string]$decision.classification -cne 'unknown') { $decision = [pscustomobject]@{ classification = 'snapshot-moved'; exact = $false; reason = $decision.reason } }
    }
    $machineryPathsCurrent = [string]$Snapshot.machinery_paths_sha256 -ceq [string]$after.machinery_paths_sha256
    if (-not $machineryPathsCurrent) {
        $reasons.Add('machinery-paths-changed') | Out-Null
        if ([string]$decision.classification -cne 'unknown') { $decision = [pscustomobject]@{ classification = 'snapshot-moved'; exact = $false; reason = $decision.reason } }
    }
    if ($reasons.Count -eq 0) { $reasons.Add('exact-head-and-digest-match') | Out-Null }
    return [pscustomobject]@{
        classification = $decision.classification; exact = $decision.exact; reason = ($reasons -join ','); reasons = @($reasons)
        origin_head_before = [string]$Snapshot.origin_head_before; origin_head_after = $after.origin_head
        reviewed_digest = [string]$Snapshot.target_digest; current_digest = $after.reviewed_state_digest
        verification_plan_current = $planCurrent; verification_plan_sha256 = $Snapshot.verification_plan_sha256
        machinery_paths_current = $machineryPathsCurrent; machinery_paths_sha256 = $Snapshot.machinery_paths_sha256
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
    $null = Disable-ReviewTargetReadOnlyProtection -Snapshot $Snapshot -Lease $null
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
