$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 / T048: synchronous application service over target/harness/runtime/store/clock ports.
# One call performs at most one external invocation; it never schedules background work or retries a
# provider invisibly. Fixture ports are executable foundation proof, not production-support claims.

if (-not (Get-Command -Name 'Invoke-ReviewResultIngress' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-result-ingestor.ps1') }
if (-not (Get-Command -Name 'New-GitReviewTargetSnapshot' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-target-port.ps1') }
if (-not (Get-Command -Name 'Get-ContinuousCoReviewAuthorityDecision' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-authority-cutover.ps1') }
if (-not (Get-Command -Name 'New-ReviewProgressEvent' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-progress-projection.ps1') }
if (-not (Get-Command -Name 'Resolve-ContinuousCoReviewDesignContextSelection' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-design-context.ps1') }
if (-not (Get-Command -Name 'New-ReviewRunRecoveryFact' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-run-reconciler.ps1') }

function New-ReviewSystemClockPort {
    return [pscustomobject]@{
        kind = 'system'
        utc_now = { [DateTimeOffset]::UtcNow.ToString('o') }
        monotonic_ms = { [Environment]::TickCount64 }
    }
}

function New-ReviewFixtureClockPort {
    param([string[]]$UtcValues = @('2026-07-16T00:00:00Z'), [long[]]$MonotonicValues = @(0, 1000))
    $utcQueue = [Collections.Generic.Queue[string]]::new(); foreach ($value in $UtcValues) { $utcQueue.Enqueue($value) }
    $monoQueue = [Collections.Generic.Queue[long]]::new(); foreach ($value in $MonotonicValues) { $monoQueue.Enqueue($value) }
    $utcState = [pscustomobject]@{ queue = $utcQueue; last = $UtcValues[-1] }
    $monoState = [pscustomobject]@{ queue = $monoQueue; last = $MonotonicValues[-1] }
    $utc = { if ($utcState.queue.Count -gt 0) { $utcState.last = $utcState.queue.Dequeue() }; return $utcState.last }.GetNewClosure()
    $mono = { if ($monoState.queue.Count -gt 0) { $monoState.last = $monoState.queue.Dequeue() }; return [long]$monoState.last }.GetNewClosure()
    return [pscustomobject]@{ kind = 'fixture'; utc_now = $utc; monotonic_ms = $mono }
}

function Read-ReviewClockUtc { param([Parameter(Mandatory)]$ClockPort); return [string](& $ClockPort.utc_now) }
function Read-ReviewClockMonotonic { param([Parameter(Mandatory)]$ClockPort); return [long](& $ClockPort.monotonic_ms) }

function ConvertTo-ReviewObservedTimestampString {
    param([AllowNull()]$Value)
    if ($Value -is [datetime]) { return ([DateTimeOffset]$Value).ToUniversalTime().ToString('o') }
    if ($Value -is [datetimeoffset]) { return ([DateTimeOffset]$Value).ToUniversalTime().ToString('o') }
    return [string]$Value
}

function Write-ReviewOrchestrationProgress {
    param(
        [AllowNull()][scriptblock]$Sink,
        [Parameter(Mandatory)]$ClockPort,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Stage,
        [string]$Message,
        [AllowNull()]$ProcessTreeLive,
        [AllowNull()]$OutputActivity,
        [AllowNull()]$ValidatedFindingCount,
        [ValidateRange(0, 86400000)][long]$ElapsedMilliseconds = 0,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900,
        [AllowNull()]$Usage
    )
    if ($null -eq $Sink) { return }
    try {
        $event = New-ReviewProgressEvent -CampaignId $CampaignId -RunId $RunId -Stage $Stage -ObservedAt (Read-ReviewClockUtc -ClockPort $ClockPort) `
            -ElapsedMilliseconds $ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds -Message $Message -ProcessTreeLive $ProcessTreeLive `
            -OutputActivity $OutputActivity -ValidatedFindingCount $ValidatedFindingCount -Usage $Usage
        & $Sink $event
    }
    catch {
        # Progress is informational. A renderer/collector failure cannot change review authority,
        # spend, containment, or terminal publication.
        $null = $_
    }
}

function New-ReviewRunStateFact {
    param([string]$CampaignId, [string]$RunId, [string]$TargetDigest, [string]$HarnessId, [string]$State)
    return [pscustomobject][ordered]@{ schema_version = '1.0'; campaign_id = $CampaignId; run_id = $RunId; target_digest = $TargetDigest; harness_id = $HarnessId; state = $State }
}

function New-GitReviewTargetPort {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$OriginRepo, [string]$ExternalRoot)
    # Capture CommandInfo objects as well as values. A PowerShell closure is backed by a dynamic
    # module and cannot otherwise resolve private functions from the module that constructed it.
    $prepareCommand = Get-Command -Name 'New-GitReviewTargetSnapshot' -CommandType Function
    $currentnessCommand = Get-Command -Name 'Test-GitReviewTargetCurrentness' -CommandType Function
    $integrityCommand = Get-Command -Name 'Test-GitReviewTargetSnapshotIntegrity' -CommandType Function
    $protectCommand = Get-Command -Name 'Enable-ReviewTargetReadOnlyProtection' -CommandType Function
    $unprotectCommand = Get-Command -Name 'Disable-ReviewTargetReadOnlyProtection' -CommandType Function
    $disposeCommand = Get-Command -Name 'Remove-GitReviewTargetSnapshot' -CommandType Function
    $prepare = { param($runId) & $prepareCommand -OriginRepo $OriginRepo -RunId $runId -ExternalRoot $ExternalRoot }.GetNewClosure()
    $currentness = { param($snapshot) & $currentnessCommand -Snapshot $snapshot }.GetNewClosure()
    $integrity = { param($snapshot) & $integrityCommand -Snapshot $snapshot }.GetNewClosure()
    $protect = { param($snapshot, $externalWritablePath) & $protectCommand -Snapshot $snapshot -ExternalWritablePath $externalWritablePath }.GetNewClosure()
    $unprotect = { param($snapshot, $lease) & $unprotectCommand -Snapshot $snapshot -Lease $lease }.GetNewClosure()
    $dispose = { param($snapshot) & $disposeCommand -Snapshot $snapshot }.GetNewClosure()
    return [pscustomobject]@{ kind = 'git'; prepare = $prepare; currentness = $currentness; integrity = $integrity; protect = $protect; unprotect = $unprotect; dispose = $dispose }
}

function New-ReviewFixtureTargetPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SnapshotPath,
        [string]$TargetDigest = 'fixture-digest',
        [ValidateSet('current', 'snapshot-moved', 'unknown')][string]$Currentness = 'current',
        [bool]$IntegrityPass = $true,
        [string[]]$IntegrityChangedPaths = @()
    )
    $suppressionEnvironment = Get-ReviewTargetSuppressionEnvironment
    $prepare = { param($runId) [pscustomobject]@{ schema_version = '1.0'; target_kind = 'fixture'; run_id = $runId; target_digest = $TargetDigest; snapshot_path = $SnapshotPath; workspace_root = $SnapshotPath; origin_repo = $null; suppression_environment = $suppressionEnvironment } }.GetNewClosure()
    $checkCurrentness = { param($snapshot) [pscustomobject]@{ classification = $Currentness; exact = ($Currentness -ceq 'current'); reason = 'fixture-currentness' } }.GetNewClosure()
    $checkIntegrity = { param($snapshot) [pscustomobject]@{ intact = $IntegrityPass; classification = $(if ($IntegrityPass) { 'intact' } else { 'snapshot-tampered' }); changed_paths = @($IntegrityChangedPaths) } }.GetNewClosure()
    $protect = { param($snapshot, $externalWritablePath) [pscustomobject]@{ ok = $true; reason = 'fixture-read-only'; lease = $null } }
    $unprotect = { param($snapshot, $lease) [pscustomobject]@{ ok = $true; reason = 'fixture-read-only-removed' } }
    $dispose = { param($snapshot) [pscustomobject]@{ removed = $true; failure_reason = $null } }
    return [pscustomobject]@{ kind = 'fixture'; prepare = $prepare; currentness = $checkCurrentness; integrity = $checkIntegrity; protect = $protect; unprotect = $unprotect; dispose = $dispose }
}

function New-ReviewFixtureHarnessPort {
    [CmdletBinding()]
    param(
        [string]$HarnessId = 'fixture-harness',
        [bool]$PreflightPass = $true,
        [AllowNull()]$Candidate,
        [string]$RawCandidate
    )
    $preflight = { param($invocation) [pscustomobject]@{ ok = $PreflightPass; reason = $(if ($PreflightPass) { 'fixture-ready' } else { 'fixture-harness-unavailable' }) } }.GetNewClosure()
    $invoke = {
        param($invocation, $environment)
        if ($null -ne $Candidate) { $json = $Candidate | ConvertTo-Json -Depth 20 -Compress; [IO.File]::WriteAllText([string]$invocation.candidate_result_path, $json, [Text.UTF8Encoding]::new($false)) }
        elseif (-not [string]::IsNullOrEmpty($RawCandidate)) { [IO.File]::WriteAllText([string]$invocation.candidate_result_path, $RawCandidate, [Text.UTF8Encoding]::new($false)) }
        return [pscustomobject]@{ exit_code = 0; output_activity = $true; suppression_observed = [string]$environment.SPECREW_REFOCUS_DISABLE }
    }.GetNewClosure()
    return [pscustomobject]@{ id = $HarnessId; preflight = $preflight; invoke = $invoke }
}

function New-ReviewFixtureRuntimePort {
    [CmdletBinding()]
    param(
        [bool]$PreflightPass = $true,
        [ValidateSet('completed', 'launch-failed', 'timed-out', 'terminated', 'containment-violated', 'abandoned')][string]$Outcome = 'completed',
        [bool]$TerminationVerified = $true,
        [ValidateSet('verified', 'violated', 'unknown')][string]$Containment = 'verified',
        [string]$FailureReason,
        [AllowNull()]$Usage
    )
    $preflight = { param($invocation) [pscustomobject]@{ ok = $PreflightPass; reason = $(if ($PreflightPass) { 'fixture-runtime-ready' } else { 'fixture-runtime-unavailable' }) } }.GetNewClosure()
    $invoke = {
        param($harness, $invocation, $onStarted, $environment, $progress)
        if ($Outcome -ceq 'launch-failed') { return [pscustomobject]@{ runtime_outcome = 'launch-failed'; termination_verified = $true; containment = 'unknown'; failure_reason = $(if ($FailureReason) { $FailureReason } else { 'fixture launch failed' }); process_tree_live = $false; output_activity = $false } }
        & $onStarted ([pscustomobject][ordered]@{
            schema_version = '1.0'; runtime_id = 'fixture-runtime'; platform = 'fixture'; containment_kind = 'fixture'
            containment_id = 'fixture-contained-process'; process_id = $PID
            process_started_at = (Get-Process -Id $PID).StartTime.ToUniversalTime().ToString('o')
        })
        if ($null -ne $progress) { try { & $progress ([pscustomobject]@{ process_tree_live = $true; output_activity = $false }) } catch { $null = $_ } }
        $harnessResult = & $harness.invoke $invocation $environment
        return [pscustomobject]@{
            runtime_outcome = $Outcome; termination_verified = $TerminationVerified; containment = $Containment
            failure_reason = $FailureReason; process_tree_live = (-not $TerminationVerified); output_activity = [bool]$harnessResult.output_activity
            usage = $Usage
        }
    }.GetNewClosure()
    $recover = {
        param($receipt)
        $valid = $null -ne $receipt -and [string]$receipt.runtime_id -ceq 'fixture-runtime' -and [string]$receipt.containment_kind -ceq 'fixture'
        return [pscustomobject]@{ termination_verified = $valid; containment = $(if ($valid) { 'verified' } else { 'unknown' }); process_tree_live = $false; failure_reason = $(if ($valid) { $null } else { 'fixture-recovery-receipt-mismatch' }) }
    }
    return [pscustomobject]@{ id = 'fixture-runtime'; platform = 'fixture'; containment = 'fixture'; preflight = $preflight; invoke = $invoke; recover = $recover }
}

function New-ReviewFixtureVerificationPort {
    # Explicit test port: orchestration fixtures that are not exercising FR-048 can keep their
    # synthetic target digest without inventing a Git repository or a provider command.
    $execute = {
        param($snapshot)
        return [pscustomobject]@{
            ok = $true; reason = 'fixture-verification-ready'; state = 'fixture'
            review_scope_suffix = ''; command_count = 0; evidence_count = 0
        }
    }
    return [pscustomobject]@{ kind = 'fixture'; execute = $execute }
}

function Get-ReviewCampaignVerificationSupportManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)

    # The reviewer snapshot is intentionally the machinery-stripped canonical digest tree. Project
    # verification is different: release/distribution checks may legitimately need committed Specrew
    # mirrors and governance configuration. Stage only TRACKED machinery from the snapshot's pinned
    # origin commit, never the origin working tree, and remove it again before harness preflight.
    foreach ($name in @('snapshot_path', 'origin_head_before', 'machinery_paths_sha256')) {
        if (-not $Snapshot.PSObject.Properties[$name] -or [string]::IsNullOrWhiteSpace([string]$Snapshot.$name)) {
            return [pscustomobject]@{ commit = ''; paths = @(); files = @() }
        }
    }

    $snapshotPath = [IO.Path]::GetFullPath([string]$Snapshot.snapshot_path)
    $commit = [string]$Snapshot.origin_head_before
    # VOCABULARY CAPTURE (T066 attempt 06 finding f2): the digest resolver already
    # performed the one live marker/host scan that defines reviewable content. The
    # target port freezes that exact normalized vocabulary and currentness-binds its
    # hash. Verification reuses it without a second origin scan; only FILE CONTENT is
    # read from the pinned commit.
    $frozenPaths = @($Snapshot.machinery_paths |
            ForEach-Object { ([string]$_ -replace '\\', '/').Trim('/') } |
            Sort-Object -Unique)
    $pathBytes = [Text.Encoding]::UTF8.GetBytes(($frozenPaths -join "`n"))
    $pathHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($pathBytes)).ToLowerInvariant()
    if ($pathHash -cne [string]$Snapshot.machinery_paths_sha256) {
        throw 'verification-support-machinery-vocabulary-binding-mismatch'
    }
    $paths = @($frozenPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -cne '.git' })
    if ($paths.Count -eq 0) { return [pscustomobject]@{ commit = $commit; paths = @(); files = @() } }

    $files = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    for ($offset = 0; $offset -lt $paths.Count; $offset += 80) {
        $end = [Math]::Min($offset + 80, $paths.Count) - 1
        $chunk = @($paths[$offset..$end])
        $listed = Invoke-ReviewTargetGit -WorkingDirectory $snapshotPath -Arguments (@('ls-tree', '-r', '--name-only', $commit, '--') + $chunk)
        if ($listed.exit_code -ne 0) { throw ('verification-support-list-failed:' + $listed.stderr) }
        foreach ($file in @([string]$listed.stdout -split "`r?`n")) {
            $normalized = ([string]$file -replace '\\', '/').Trim()
            if ([string]::IsNullOrWhiteSpace($normalized)) { continue }
            # The selected plan is captured independently from current origin bytes,
            # hash-bound by the target port, and already materialized in the snapshot.
            # It is controller input, not pinned support to overwrite or remove.
            if ($normalized -ceq '.specrew/verification-plan.json') { continue }
            $full = [IO.Path]::GetFullPath((Join-Path $snapshotPath $normalized))
            if (-not (Test-ReviewTargetPathUnderRoot -Path $full -Root $snapshotPath)) { throw "verification-support-path-unsafe:$normalized" }
            $null = $files.Add($normalized)
        }
    }
    return [pscustomobject]@{ commit = $commit; paths = @($paths); files = @($files | Sort-Object) }
}

function Remove-ReviewCampaignVerificationSupport {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SnapshotPath, [Parameter(Mandatory)]$Manifest)

    $root = [IO.Path]::GetFullPath($SnapshotPath)
    $pathComparer = if ([OperatingSystem]::IsWindows()) { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal }
    $parents = [Collections.Generic.HashSet[string]]::new($pathComparer)
    foreach ($relative in @($Manifest.files)) {
        $full = [IO.Path]::GetFullPath((Join-Path $root ([string]$relative)))
        if (-not (Test-ReviewTargetPathUnderRoot -Path $full -Root $root)) { throw "verification-support-cleanup-path-unsafe:$relative" }
        for ($parent = Split-Path -Parent $full;
            -not [string]::IsNullOrWhiteSpace($parent) -and (Test-ReviewTargetPathUnderRoot -Path $parent -Root $root);
            $parent = Split-Path -Parent $parent) {
            $null = $parents.Add($parent)
        }
        if ([IO.File]::Exists($full)) { [IO.File]::Delete($full) }
        elseif (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Force }
    }
    foreach ($directory in @($parents | Sort-Object { $_.Length } -Descending)) {
        if ([IO.Directory]::Exists($directory) -and [IO.Directory]::GetFileSystemEntries($directory).Count -eq 0) {
            [IO.Directory]::Delete($directory, $false)
        }
    }
    $left = @($Manifest.files | Where-Object { Test-Path -LiteralPath (Join-Path $root ([string]$_)) })
    if ($left.Count -gt 0) { throw ('verification-support-cleanup-incomplete:' + ($left -join ',')) }
}

function Remove-ReviewCampaignVerificationMachinery {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SnapshotPath, [Parameter(Mandatory)]$Manifest)

    $root = [IO.Path]::GetFullPath($SnapshotPath)
    foreach ($relative in @($Manifest.paths | Sort-Object { ([string]$_).Length } -Descending)) {
        $full = [IO.Path]::GetFullPath((Join-Path $root ([string]$relative)))
        if (-not (Test-ReviewTargetPathUnderRoot -Path $full -Root $root)) { throw "verification-machinery-purge-path-unsafe:$relative" }
        if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
    }
    $left = @($Manifest.paths | Where-Object { Test-Path -LiteralPath (Join-Path $root ([string]$_)) })
    if ($left.Count -gt 0) { throw ('verification-machinery-purge-incomplete:' + ($left -join ',')) }
}

function Add-ReviewCampaignVerificationSupport {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)

    $manifest = Get-ReviewCampaignVerificationSupportManifest -Snapshot $Snapshot
    if (@($manifest.files).Count -eq 0) { return $manifest }
    $snapshotPath = [IO.Path]::GetFullPath([string]$Snapshot.snapshot_path)
    foreach ($relative in @($manifest.files)) {
        if (Test-Path -LiteralPath (Join-Path $snapshotPath ([string]$relative))) {
            throw "verification-support-path-collision:$relative"
        }
    }
    try {
        for ($offset = 0; $offset -lt @($manifest.files).Count; $offset += 80) {
            $end = [Math]::Min($offset + 80, @($manifest.files).Count) - 1
            $chunk = @($manifest.files[$offset..$end])
            $restored = Invoke-ReviewTargetGit -WorkingDirectory $snapshotPath -Arguments (@('restore', "--source=$($manifest.commit)", '--worktree', '--') + $chunk)
            if ($restored.exit_code -ne 0) { throw ('verification-support-restore-failed:' + $restored.stderr) }
        }
        return $manifest
    }
    catch {
        $restoreFailure = [string]$_.Exception.Message
        $rollbackFailures = [Collections.Generic.List[string]]::new()
        try { Remove-ReviewCampaignVerificationSupport -SnapshotPath $snapshotPath -Manifest $manifest }
        catch { $rollbackFailures.Add('exact-cleanup:' + [string]$_.Exception.Message) }
        # A chunked restore can fail after creating files the exact manifest cleanup cannot
        # remove. Always attempt the complete authoritative machinery purge as the rollback
        # backstop, and preserve every cleanup failure in the controller-visible reason.
        try { Remove-ReviewCampaignVerificationMachinery -SnapshotPath $snapshotPath -Manifest $manifest }
        catch { $rollbackFailures.Add('machinery-purge:' + [string]$_.Exception.Message) }
        if ($rollbackFailures.Count -gt 0) {
            throw ('verification-support-staging-failed:' + $restoreFailure + ';verification-support-rollback-failed:' + ($rollbackFailures -join '|'))
        }
        throw ('verification-support-staging-failed:' + $restoreFailure)
    }
}

function Invoke-ReviewCampaignFrozenVerification {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot, [string]$EvidencePath)

    foreach ($name in @('Get-ContinuousCoReviewSelectedVerificationPlan', 'Invoke-ContinuousCoReviewVerificationPlan')) {
        if (-not (Get-Command -Name $name -ErrorAction SilentlyContinue)) {
            . (Join-Path $PSScriptRoot 'verification-plan-runner.ps1')
            break
        }
    }
    if (-not (Get-Command -Name 'Copy-ContinuousCoReviewImplementerEvidence' -ErrorAction SilentlyContinue)) {
        . (Join-Path $PSScriptRoot 'test-evidence-recorder.ps1')
    }

    $snapshotPath = [IO.Path]::GetFullPath([string]$Snapshot.snapshot_path)
    $targetDigest = [string]$Snapshot.target_digest
    $selected = Get-ContinuousCoReviewSelectedVerificationPlan -RepoRoot $snapshotPath
    if (-not [bool]$selected.available) {
        return [pscustomobject]@{
            ok = $false; reason = ('verification-not-configured:' + [string]$selected.reason); state = 'verification-not-configured'
            review_scope_suffix = ''; command_count = 0; evidence_count = 0
        }
    }

    $before = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $snapshotPath
    if ($null -eq $before -or -not [bool]$before.ok -or [string]$before.tree_id -cne $targetDigest) {
        return [pscustomobject]@{
            ok = $false; reason = 'verification-target-digest-mismatch-before-execution'; state = 'verification-preflight-failed'
            review_scope_suffix = ''; command_count = 0; evidence_count = 0
        }
    }

    $support = $null
    $execution = $null
    $executionFailure = $null
    $cleanupFailure = $null
    $preparationComplete = $false
    try {
        $support = Add-ReviewCampaignVerificationSupport -Snapshot $Snapshot
        $execution = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $snapshotPath -Plan $selected.plan
    }
    catch { $executionFailure = [string]$_.Exception.Message }
    finally {
        if ($null -ne $support) {
            try { Remove-ReviewCampaignVerificationSupport -SnapshotPath $snapshotPath -Manifest $support }
            catch { $cleanupFailure = [string]$_.Exception.Message }
        }
    }
    try {
    if (-not [string]::IsNullOrWhiteSpace($cleanupFailure)) {
        return [pscustomobject]@{
            ok = $false; reason = ('verification-support-cleanup-failed:' + $cleanupFailure); state = 'verification-preflight-failed'
            review_scope_suffix = ''; command_count = 0; evidence_count = 0
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($executionFailure)) {
        return [pscustomobject]@{
            ok = $false; reason = ('verification-runner-failed:' + $executionFailure); state = 'verification-preflight-failed'
            review_scope_suffix = ''; command_count = 0; evidence_count = 0
        }
    }
    if ([string]$execution.state -cne 'configured') {
        return [pscustomobject]@{
            ok = $false; reason = ('verification-plan-not-runnable:' + [string]$execution.reason); state = [string]$execution.state
            review_scope_suffix = ''; command_count = [int]$execution.command_count; evidence_count = @($execution.evidence).Count
        }
    }

    # A verification command may create ignored caches or its transient result transport, but it may
    # not change the canonical frozen source. A changed digest stops before the provider grant is spent.
    $after = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $snapshotPath
    if ($null -eq $after -or -not [bool]$after.ok -or [string]$after.tree_id -cne $targetDigest) {
        return [pscustomobject]@{
            ok = $false; reason = 'verification-mutated-frozen-target'; state = 'verification-preflight-failed'
            review_scope_suffix = ''; command_count = [int]$execution.command_count; evidence_count = @($execution.evidence).Count
        }
    }

    $evidence = @($execution.evidence)
    $joined = @(Test-ContinuousCoReviewPlanEvidenceInjectable -PlanEvidence $evidence -Plan $selected.plan -CurrentDigest $targetDigest)
    # The raw accessor deliberately preserves command arrays with a unary-comma return. A direct
    # assignment unwraps that transport layer; @() here would nest the complete list as one element.
    $planCommands = Get-ContinuousCoReviewVerificationRawProp -Object $selected.plan -Name 'commands'
    $planIds = @($planCommands | ForEach-Object { [string](Get-ContinuousCoReviewContractProp -Object $_ -Name 'command_id') })
    $evidenceIds = @($evidence | ForEach-Object { [string](Get-ContinuousCoReviewContractProp -Object $_ -Name 'command_id') })
    $joinComplete = ($joined.Count -eq $evidence.Count) -and ($evidence.Count -eq $planIds.Count) -and
        (@($joined | Where-Object { -not [bool]$_.injectable }).Count -eq 0)
    foreach ($commandId in $planIds) {
        if (@($evidenceIds | Where-Object { $_ -ceq $commandId }).Count -ne 1) { $joinComplete = $false; break }
    }
    if (-not $joinComplete) {
        return [pscustomobject]@{
            ok = $false; reason = 'verification-evidence-not-exactly-joinable'; state = 'verification-preflight-failed'
            review_scope_suffix = ''; command_count = $planIds.Count; evidence_count = $evidence.Count
        }
    }

    $failedIds = @($evidence | Where-Object { -not [bool]$_.command_succeeded } | ForEach-Object { [string]$_.command_id })
    if ($failedIds.Count -gt 0) {
        # A red configured command is controller evidence, not work for a paid reviewer. Stop before
        # evidence injection, harness preflight, claim acquisition, or spend; the reservation is
        # released by the caller. Output stays private by default. The stable reason directs the
        # operator to the existing human-authorized, command-scoped bounded-disclosure path.
        return [pscustomobject]@{
            ok = $false
            reason = 'verification-command-failed:' + ($failedIds -join ',') + ':diagnostics-require-command-scoped-disclosure'
            state = 'verification-failed'
            review_scope_suffix = ''
            command_count = $planIds.Count
            evidence_count = $evidence.Count
            failed_command_ids = @($failedIds)
        }
    }

    $injectedPath = if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
        $reviewDirectory = Join-Path $snapshotPath '.review'
        [IO.Directory]::CreateDirectory($reviewDirectory) | Out-Null
        Join-Path $reviewDirectory 'implementer-evidence.json'
    }
    else { [IO.Path]::GetFullPath($EvidencePath) }
    if ((Test-ReviewTargetPathUnderRoot -Path $injectedPath -Root $snapshotPath) -and -not [string]::IsNullOrWhiteSpace($EvidencePath)) {
        return [pscustomobject]@{
            ok = $false; reason = 'verification-evidence-path-inside-frozen-target'; state = 'verification-preflight-failed'
            review_scope_suffix = ''; command_count = $planIds.Count; evidence_count = $evidence.Count
        }
    }
    $injected = Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $snapshotPath -OutputPath $injectedPath -DigestTreeId $targetDigest -Plan $selected.plan
    if (-not $injected -or -not [IO.File]::Exists($injectedPath)) {
        return [pscustomobject]@{
            ok = $false; reason = 'verification-evidence-injection-failed'; state = 'verification-preflight-failed'
            review_scope_suffix = ''; command_count = $planIds.Count; evidence_count = $evidence.Count
        }
    }
    try {
        $injectedRecord = [IO.File]::ReadAllText($injectedPath, [Text.UTF8Encoding]::new($false, $true)) | ConvertFrom-Json
        $injectedRuns = if ($injectedRecord.PSObject.Properties['runs']) { @($injectedRecord.runs) } else { @() }
        foreach ($commandId in $planIds) {
            if (@($injectedRuns | Where-Object { [string]$_.command_id -ceq $commandId }).Count -ne 1) {
                throw "injected-command-cardinality:$commandId"
            }
        }
    }
    catch {
        return [pscustomobject]@{
            ok = $false; reason = ('verification-evidence-injection-invalid:' + [string]$_.Exception.Message); state = 'verification-preflight-failed'
            review_scope_suffix = ''; command_count = $planIds.Count; evidence_count = $evidence.Count
        }
    }

    $supportScope = ''
    if ($null -ne $support -and @($support.files).Count -gt 0) {
        $supportScope = @"
Tracked methodology support used by verification came only from pinned commit $([string]$support.commit)
and was removed before reviewer harness preflight; the reviewer-visible tree remains machinery-stripped.
"@
    }
    $scopeSuffix = @"

CONTROLLER VERIFICATION EVIDENCE: Read the controller-owned file at $injectedPath. The controller executed the selected
project verification plan against this exact frozen digest before reviewer launch and injected one joined record
for each of $($planIds.Count) declared command(s). Treat failed, timed-out, or missing-required-result records as
approval-blocking evidence; never turn a configured verification failure into a clean result.
$supportScope
"@
    $preparationComplete = $true
    return [pscustomobject]@{
        ok = $true; reason = 'verification-evidence-ready'; state = 'configured'; review_scope_suffix = $scopeSuffix
        command_count = $planIds.Count; evidence_count = $evidence.Count
    }
    }
    finally {
        if ($null -ne $support) { Remove-ReviewCampaignVerificationMachinery -SnapshotPath $snapshotPath -Manifest $support }
        # Verification, evidence injection, and the final machinery purge are controller-owned
        # preparation. Re-baseline only after successful evidence projection and purge; failed
        # verification snapshots retain their original baseline until disposal.
        if ($preparationComplete -and $Snapshot.PSObject.Properties['source_hashes_before'] -and (Get-Command -Name 'Get-ContinuousCoReviewWorktreeSourceHashes' -ErrorAction SilentlyContinue)) {
            $Snapshot.source_hashes_before = Get-ContinuousCoReviewWorktreeSourceHashes -WorktreePath $snapshotPath
        }
    }
}

function New-ReviewProductionVerificationPort {
    $command = Get-Command -Name 'Invoke-ReviewCampaignFrozenVerification' -CommandType Function
    $copyCommand = Get-Command -Name 'New-GitReviewTargetVerificationCopy' -CommandType Function
    $disposeCommand = Get-Command -Name 'Remove-GitReviewTargetSnapshot' -CommandType Function
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewWorktreeSourceHashes' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'worktree-reviewer.ps1') }
    $hashCommand = Get-Command -Name 'Get-ContinuousCoReviewWorktreeSourceHashes' -CommandType Function
    $execute = {
        param($snapshot, $paths)
        if ($null -eq $paths -or -not $paths.PSObject.Properties['implementer_evidence_path']) {
            return [pscustomobject]@{ ok = $false; reason = 'verification-external-evidence-path-missing'; state = 'verification-preflight-failed'; review_scope_suffix = ''; command_count = 0; evidence_count = 0 }
        }
        $originalBefore = & $hashCommand -WorktreePath ([string]$snapshot.snapshot_path)
        $verificationCopy = $null
        $result = $null
        $disposeFailure = $null
        try {
            $verificationCopy = & $copyCommand -Snapshot $snapshot
            $result = & $command -Snapshot $verificationCopy -EvidencePath ([string]$paths.implementer_evidence_path)
        }
        catch {
            $result = [pscustomobject]@{ ok = $false; reason = ('verification-copy-failed:' + $_.Exception.Message); state = 'verification-preflight-failed'; review_scope_suffix = ''; command_count = 0; evidence_count = 0 }
        }
        finally {
            if ($null -ne $verificationCopy) {
                try {
                    $disposed = & $disposeCommand -Snapshot $verificationCopy
                    if (-not [bool]$disposed.removed) { $disposeFailure = [string]$disposed.failure_reason }
                }
                catch { $disposeFailure = [string]$_.Exception.Message }
            }
        }
        $originalAfter = & $hashCommand -WorktreePath ([string]$snapshot.snapshot_path)
        $changed = [Collections.Generic.List[string]]::new()
        foreach ($key in @(@($originalBefore.Keys) + @($originalAfter.Keys) | Sort-Object -Unique)) {
            $beforeValue = if ($originalBefore.ContainsKey($key)) { [string]$originalBefore[$key] } else { '<missing>' }
            $afterValue = if ($originalAfter.ContainsKey($key)) { [string]$originalAfter[$key] } else { '<missing>' }
            if ($beforeValue -cne $afterValue) { $changed.Add([string]$key) | Out-Null }
        }
        if ($changed.Count -gt 0) {
            return [pscustomobject]@{ ok = $false; reason = ('verification-mutated-original-frozen-target:' + (@($changed | Select-Object -First 20) -join ',')); state = 'verification-preflight-failed'; review_scope_suffix = ''; command_count = 0; evidence_count = 0 }
        }
        if (-not [string]::IsNullOrWhiteSpace($disposeFailure)) {
            return [pscustomobject]@{ ok = $false; reason = ('verification-copy-disposal-failed:' + $disposeFailure); state = 'verification-preflight-failed'; review_scope_suffix = ''; command_count = 0; evidence_count = 0 }
        }
        $result | Add-Member -NotePropertyName original_frozen_target_unchanged -NotePropertyValue $true -Force
        $result | Add-Member -NotePropertyName verification_copy_disposed -NotePropertyValue $true -Force
        return $result
    }.GetNewClosure()
    return [pscustomobject]@{ kind = 'production'; execute = $execute }
}

function Complete-ReviewPreInvocationFailure {
    param(
        [string]$StoreRoot, [string]$StagingRoot, [string]$CampaignId, [string]$RunId, [string]$TargetDigest, [string]$HarnessId,
        $Reservation, [object[]]$Spends, [string]$Reason, [string]$ObservedAt, [string]$StartedAt, [long]$DurationMs,
        [ValidateSet('preflight-failed', 'claim-contended', 'launch-failed')][string]$RuntimeOutcome, [ValidateSet('verified', 'unknown')][string]$Containment = 'unknown'
    )
    if ($null -ne $Reservation) {
        $releaseDecision = Resolve-ReviewCampaignReleaseDecision -Reservation $Reservation -Reason $Reason -ObservedAt $ObservedAt -Spends $Spends
        if ($releaseDecision.permitted) { Write-ReviewCampaignReleaseFact -StoreRoot $StoreRoot -Fact $releaseDecision.fact | Out-Null }
    }
    return Invoke-ReviewResultIngress -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $TargetDigest -HarnessId $HarnessId -RuntimeOutcome $RuntimeOutcome -Invoked $false -TerminationVerified $true -Containment $Containment -Currentness unknown -StartedAt $StartedAt -EndedAt $ObservedAt -DurationMs $DurationMs -FailureReason $Reason
}

function Get-ReviewCampaignStableToken {
    param([Parameter(Mandatory)][string]$Value, [ValidateRange(8, 32)][int]$Length = 16)
    $bytes = [Text.Encoding]::UTF8.GetBytes($Value)
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant().Substring(0, $Length)
}

function ConvertTo-ReviewCampaignSlug {
    param([Parameter(Mandatory)][string]$Value, [ValidateRange(8, 60)][int]$MaximumLength = 48)
    $slug = ($Value.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) { $slug = 'review' }
    if ($slug.Length -le $MaximumLength) { return $slug }
    $hash = Get-ReviewCampaignStableToken -Value $Value -Length 12
    return ($slug.Substring(0, $MaximumLength - 13).TrimEnd('-') + '-' + $hash)
}

function Test-ReviewCampaignTargetRootWritable {
    param([Parameter(Mandatory)][string]$Path)
    $probePath = $null
    try {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            return [pscustomobject]@{ ok = $false; reason = 'path-is-file' }
        }
        # Candidate roots are intentionally retained after both successful and failed file probes.
        # Deleting an empty-looking shared directory races another process populating it between
        # inspection and deletion; individual rt-* worktrees remain the cleanup unit.
        [IO.Directory]::CreateDirectory($Path) | Out-Null
        $probePath = Join-Path $Path ('.specrew-write-probe-' + [guid]::NewGuid().ToString('N'))
        $stream = [IO.File]::Open($probePath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $stream.Dispose(); [IO.File]::Delete($probePath); $probePath = $null
        return [pscustomobject]@{ ok = $true; reason = 'writable' }
    }
    catch {
        if ($probePath -and [IO.File]::Exists($probePath)) { try { [IO.File]::Delete($probePath) } catch { $null = $_ } }
        return [pscustomobject]@{ ok = $false; reason = $_.Exception.GetType().Name }
    }
}

function Get-ReviewCampaignRepositoryToken {
    param([Parameter(Mandatory)][string]$GitRoot)
    $identity = [IO.Path]::GetFullPath($GitRoot)
    if ([OperatingSystem]::IsWindows()) { $identity = $identity.ToUpperInvariant() }
    # Filesystem namespace only: immutable campaign/run identity remains full-length in authority
    # facts, while the workspace leaf is drawn from 96 independent random source bits (about 83
    # effective namespace bits after case-folding). Sixteen hex characters keep the repository
    # namespace bounded without becoming review authority.
    return Get-ReviewCampaignStableToken -Value $identity -Length 16
}

function Resolve-ReviewCampaignTargetExternalRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [string]$RequestedRoot
    )
    $root = (Resolve-Path -LiteralPath $RepoRoot).Path
    $gitRootResult = Invoke-ReviewTargetGit -WorkingDirectory $root -Arguments @('rev-parse', '--show-toplevel')
    if ($gitRootResult.exit_code -ne 0) { throw ('review-campaign-target-root-repo-invalid:' + $gitRootResult.stderr) }
    $gitRoot = [IO.Path]::GetFullPath($gitRootResult.stdout)

    if (-not [string]::IsNullOrWhiteSpace($RequestedRoot)) {
        $requestedFull = [IO.Path]::GetFullPath($RequestedRoot, $root)
        if (Test-ReviewTargetPathUnderRoot -Path $requestedFull -Root $gitRoot) { throw 'review-campaign-target-root-inside-origin' }
        $probe = Test-ReviewCampaignTargetRootWritable -Path $requestedFull
        if (-not $probe.ok) { throw ('review-campaign-target-root-unusable:' + $probe.reason) }
        return $requestedFull
    }

    $repoToken = Get-ReviewCampaignRepositoryToken -GitRoot $gitRoot
    $candidates = [Collections.Generic.List[string]]::new()
    $parent = Split-Path -Parent $root
    if (-not [string]::IsNullOrWhiteSpace($parent)) { $candidates.Add((Join-Path $parent '.specrew-targets')) | Out-Null }
    if ([OperatingSystem]::IsWindows()) {
        # AppData\Local\Temp reproduced MAX_PATH failure on this repository. Keep the fallback
        # under the writable user home with a deliberately short leaf; --run-root remains the
        # escape hatch for unusually long homes or constrained layouts. The repo-token namespace
        # directory is intentionally retained (at most one per resolved repository identity):
        # deleting a shared empty-looking root races concurrent runs. Individual rt-* worktrees
        # are still removed by the target port.
        $userHome = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        if (-not [string]::IsNullOrWhiteSpace($userHome)) { $candidates.Add((Join-Path $userHome ".sr/$repoToken")) | Out-Null }
    }
    else {
        $candidates.Add((Join-Path ([IO.Path]::GetTempPath()) "specrew-review-targets/$repoToken")) | Out-Null
    }

    $failures = [Collections.Generic.List[string]]::new()
    $comparer = if ([OperatingSystem]::IsWindows()) { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal }
    $seen = [Collections.Generic.HashSet[string]]::new($comparer)
    foreach ($candidate in @($candidates)) {
        $full = [IO.Path]::GetFullPath($candidate)
        if (-not $seen.Add($full)) { continue }
        if (Test-ReviewTargetPathUnderRoot -Path $full -Root $gitRoot) {
            $failures.Add("inside-origin:$full") | Out-Null
            continue
        }
        $probe = Test-ReviewCampaignTargetRootWritable -Path $full
        if ($probe.ok) { return $full }
        $failures.Add("$($probe.reason):$full") | Out-Null
    }
    throw ('review-campaign-target-root-unavailable:' + ($failures -join ','))
}

function New-ReviewCampaignTargetPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [string]$RequestedRoot
    )
    $targetRoot = Resolve-ReviewCampaignTargetExternalRoot -RepoRoot $RepoRoot -RequestedRoot $RequestedRoot
    return New-GitReviewTargetPort -OriginRepo ((Resolve-Path -LiteralPath $RepoRoot).Path) -ExternalRoot $targetRoot
}

function Resolve-ReviewCampaignPublicIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [string]$FeatureId,
        [string]$IterationNumber,
        [string]$RunId
    )
    $root = (Resolve-Path -LiteralPath $RepoRoot).Path
    $feature = $FeatureId
    if ([string]::IsNullOrWhiteSpace($feature)) {
        $featureRoot = $null
        if (Get-Command -Name 'Get-ContinuousCoReviewNavigatorFeatureRoot' -ErrorAction SilentlyContinue) {
            try { $featureRoot = Get-ContinuousCoReviewNavigatorFeatureRoot -RepoRoot $root } catch { $featureRoot = $null }
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$featureRoot)) { $feature = Split-Path -Leaf $featureRoot }
    }
    if ([string]::IsNullOrWhiteSpace($feature)) {
        $branch = Invoke-ReviewTargetGit -WorkingDirectory $root -Arguments @('branch', '--show-current')
        if ($branch.exit_code -eq 0 -and -not [string]::IsNullOrWhiteSpace($branch.stdout) -and (Test-Path -LiteralPath (Join-Path $root "specs/$($branch.stdout)") -PathType Container)) {
            $feature = $branch.stdout
        }
    }
    if (-not (Test-ReviewCampaignFeatureIdentity -Value $feature)) { throw 'review-campaign-active-feature-unresolved' }
    $featureDirectory = Join-Path $root "specs/$feature"
    if (-not (Test-Path -LiteralPath $featureDirectory -PathType Container)) { throw "review-campaign-feature-missing:$feature" }

    $iteration = $IterationNumber
    if ([string]::IsNullOrWhiteSpace($iteration)) {
        $iterationsRoot = Join-Path $featureDirectory 'iterations'
        if (Test-Path -LiteralPath $iterationsRoot -PathType Container) {
            $iteration = @(Get-ChildItem -LiteralPath $iterationsRoot -Directory | Where-Object { $_.Name -match '^\d{3,}$' } | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty Name)
        }
    }
    if ($iteration -is [array]) { $iteration = if ($iteration.Count -gt 0) { [string]$iteration[0] } else { '' } }
    if (-not (Test-ReviewCampaignIterationIdentity -Value $iteration)) { throw 'review-campaign-active-iteration-unresolved' }

    $featureSlug = ConvertTo-ReviewCampaignSlug -Value $feature -MaximumLength 44
    $campaignId = "cmp-$featureSlug-i$iteration"
    $lineageId = "lin-$featureSlug"
    if ([string]::IsNullOrWhiteSpace($RunId)) {
        $stamp = [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssfff')
        $RunId = "run-$stamp-" + [guid]::NewGuid().ToString('N').Substring(0, 8)
    }
    if (-not (Test-ReviewAuthorityIdentifier -Value $RunId -Kind run)) { throw "review-campaign-invalid-run-id:$RunId" }
    $reservationId = 'res-' + (Get-ReviewCampaignStableToken -Value "$campaignId/$RunId/reservation" -Length 20)
    return [pscustomobject][ordered]@{
        campaign_id = $campaignId; run_id = $RunId; reservation_id = $reservationId
        target_lineage = $lineageId; feature_id = $feature; iteration_number = [string]$iteration
    }
}

function New-ReviewUnavailableHarnessPort {
    param([string]$HarnessId = 'unavailable-harness', [string]$Reason = 'production-harness-unavailable')
    $preflight = { param($invocation) [pscustomobject]@{ ok = $false; reason = $Reason } }.GetNewClosure()
    $invoke = { param($invocation, $environment) throw $Reason }.GetNewClosure()
    return [pscustomobject]@{ id = $HarnessId; preflight = $preflight; invoke = $invoke }
}

function New-ReviewUnavailableRuntimePort {
    param([string]$Reason = 'production-runtime-unavailable')
    $preflight = { param($invocation) [pscustomobject]@{ ok = $false; reason = $Reason } }.GetNewClosure()
    $invoke = { param($harness, $invocation, $onStarted, $environment) throw $Reason }.GetNewClosure()
    $recover = { param($receipt) [pscustomobject]@{ termination_verified = $false; containment = 'unknown'; process_tree_live = $null; failure_reason = $Reason } }.GetNewClosure()
    return [pscustomobject]@{ id = 'unavailable-runtime'; platform = 'unknown'; containment = 'unknown'; preflight = $preflight; invoke = $invoke; recover = $recover }
}

function New-ReviewCampaignProductionPorts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [string]$ReviewerHost,
        [string]$Model,
        [string]$TargetRoot,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900
    )
    # The one target-root policy is reused by live execution and reconciliation. It prefers the
    # short sibling root proven by T060, falls back to a writable platform root when the parent is
    # unavailable, supports an explicit external override, and fails with a domain-named reason.
    $target = New-ReviewCampaignTargetPort -RepoRoot $RepoRoot -RequestedRoot $TargetRoot
    $harness = if (Get-Command -Name 'New-ReviewProductionHarnessPort' -ErrorAction SilentlyContinue) {
        New-ReviewProductionHarnessPort -HostName $ReviewerHost -Model $Model -TimeoutSeconds $TimeoutSeconds
    }
    else { New-ReviewUnavailableHarnessPort -HarnessId $(if ($ReviewerHost) { $ReviewerHost } else { 'unselected-harness' }) -Reason 'production-harness-catalog-not-installed' }
    $runtime = if (Get-Command -Name 'New-ReviewProductionRuntimePort' -ErrorAction SilentlyContinue) {
        New-ReviewProductionRuntimePort -TimeoutSeconds $TimeoutSeconds
    }
    else { New-ReviewUnavailableRuntimePort -Reason 'production-os-runtime-not-installed' }
    return [pscustomobject]@{
        target = $target; harness = $harness; runtime = $runtime; verification = New-ReviewProductionVerificationPort; clock = New-ReviewSystemClockPort
        prompt_path = (Join-Path $PSScriptRoot 'reviewer-candidate-prompt.md')
    }
}

function Invoke-ReviewCampaignCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [string]$FeatureId,
        [string]$IterationNumber,
        [string]$RunId,
        [string]$ReviewerHost,
        [string]$Model,
        [string]$GrantAuthorizationRef,
        [AllowEmptyCollection()][string[]]$DesignContextRefs = @(),
        [string]$ReviewScope = 'Review the complete frozen target and return the versioned candidate JSON contract.',
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900,
        [string]$AuthorityConfigPath,
        [string]$StoreRoot,
        [string]$StagingRoot,
        [string]$TargetRoot,
        [AllowNull()]$Ports,
        [scriptblock]$ProgressSink
    )
    $progressCollector = New-ReviewProgressCollector -ExternalSink $ProgressSink
    $authority = Get-ContinuousCoReviewAuthorityDecision -ConfigPath $AuthorityConfigPath
    if (-not $authority.campaign_authority_enabled) {
        return [pscustomobject]@{
            status = 'suppressed'; reason = ('campaign-authority-disabled:' + $authority.reason); invoked = $false; result = $null
            authority_mode = $authority.mode; diagnostics = Get-ReviewProgressDiagnostics -Events @($progressCollector.events)
        }
    }
    $root = (Resolve-Path -LiteralPath $RepoRoot).Path
    $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $root -FeatureId $FeatureId -IterationNumber $IterationNumber -RunId $RunId
    # T034b: reject every invalid explicit ref before grant persistence, harness selection,
    # reservation, snapshot creation, or provider spend. Omitted refs use the same auto resolver
    # as legacy review and carry an explicit bounded partial-evidence degrade when none resolve.
    $designContext = Resolve-ContinuousCoReviewDesignContextSelection -RepoRoot $root -DesignContextFiles $DesignContextRefs -FeatureId $FeatureId
    if (-not $designContext.valid) {
        return [pscustomobject][ordered]@{
            status = 'not-started'; reason = [string]$designContext.reason; invoked = $false; result = $null
            campaign_id = $identity.campaign_id; run_id = $identity.run_id; target_lineage = $identity.target_lineage
            authority_mode = 'campaign'; design_context = 'unresolved'; resolved_design_context = @()
            unresolved_design_context = @($designContext.unresolved_refs)
            diagnostics = Get-ReviewProgressDiagnostics -Events @($progressCollector.events)
        }
    }
    try { $ReviewScope = Add-ContinuousCoReviewDesignContextToScope -ReviewScope $ReviewScope -Selection $designContext }
    catch {
        return [pscustomobject][ordered]@{
            status = 'not-started'; reason = [string]$_.Exception.Message; invoked = $false; result = $null
            campaign_id = $identity.campaign_id; run_id = $identity.run_id; target_lineage = $identity.target_lineage
            authority_mode = 'campaign'; design_context = [string]$designContext.classification
            resolved_design_context = @($designContext.resolved_refs); unresolved_design_context = @()
            diagnostics = Get-ReviewProgressDiagnostics -Events @($progressCollector.events)
        }
    }
    if ([string]::IsNullOrWhiteSpace($StoreRoot)) { $StoreRoot = Join-Path $root '.specrew/review/authority' }
    if ([string]::IsNullOrWhiteSpace($StagingRoot)) {
        $repoToken = Get-ReviewCampaignStableToken -Value $root -Length 20
        $StagingRoot = Join-Path ([IO.Path]::GetTempPath()) "specrew-review-staging/$repoToken"
    }
    $StagingRoot = [IO.Path]::GetFullPath($StagingRoot)
    if (Test-ReviewTargetPathUnderRoot -Path $StagingRoot -Root $root) {
        throw "review-campaign-staging-root-inside-origin:$StagingRoot"
    }
    if (-not [string]::IsNullOrWhiteSpace($GrantAuthorizationRef)) {
        # One human authorization reference creates at most one campaign slot. A new run that reuses
        # the same reference sees the already-spent grant; it does not mint another allowance slot.
        $grantId = 'grant-' + (Get-ReviewCampaignStableToken -Value "$($identity.campaign_id)/$GrantAuthorizationRef" -Length 20)
        $grant = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'grant'; campaign_id = $identity.campaign_id; grant_id = $grantId
            slots = 1; authority_kind = 'human'; authorization_ref = $GrantAuthorizationRef
            observed_at = [DateTimeOffset]::UtcNow.ToString('o')
        }
        $existingGrant = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $identity.campaign_id -Kind grants | Where-Object { [string]$_.grant_id -ceq $grantId })
        if ($existingGrant.Count -eq 0) {
            try { Add-ReviewCampaignGrantFact -StoreRoot $StoreRoot -Fact $grant | Out-Null }
            catch {
                if ($_.Exception.Message -notlike 'review-store-corruption:conflicting-immutable-fact:*') { throw }
                $existingGrant = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $identity.campaign_id -Kind grants | Where-Object { [string]$_.grant_id -ceq $grantId })
                if ($existingGrant.Count -ne 1) { throw }
            }
        }
        if ($existingGrant.Count -gt 0 -and ([string]$existingGrant[0].authorization_ref -cne $GrantAuthorizationRef -or [int]$existingGrant[0].slots -ne 1)) {
            throw "review-store-corruption:grant-identity-mismatch:$grantId"
        }
    }
    if ($null -eq $Ports) { $Ports = New-ReviewCampaignProductionPorts -RepoRoot $root -ReviewerHost $ReviewerHost -Model $Model -TargetRoot $TargetRoot -TimeoutSeconds $TimeoutSeconds }
    $run = Invoke-ReviewCampaignRun -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $identity.campaign_id -RunId $identity.run_id `
        -ReservationId $identity.reservation_id -TargetLineage $identity.target_lineage -TargetPort $Ports.target -HarnessPort $Ports.harness `
        -RuntimePort $Ports.runtime -VerificationPort $Ports.verification -ClockPort $Ports.clock -PromptPath ([string]$Ports.prompt_path) -TimeoutSeconds $TimeoutSeconds `
        -ReviewScope $ReviewScope -DesignContextEmpty:([bool]$designContext.design_context_empty) `
        -ProgressSink $progressCollector.sink -AuthorityConfigPath $AuthorityConfigPath
    return [pscustomobject][ordered]@{
        status = $run.status; reason = $run.reason; invoked = $run.invoked; result = $run.result
        result_path = $(if ($run.PSObject.Properties['result_path']) { $run.result_path } else { $null })
        report_path = $(if ($run.PSObject.Properties['report_path']) { $run.report_path } else { $null })
        campaign_id = $identity.campaign_id; run_id = $identity.run_id; target_lineage = $identity.target_lineage
        store_root = [IO.Path]::GetFullPath($StoreRoot); authority_mode = 'campaign'
        design_context = [string]$designContext.classification; resolved_design_context = @($designContext.resolved_refs)
        unresolved_design_context = @()
        diagnostics = Get-ReviewProgressDiagnostics -Events @($progressCollector.events)
    }
}

function Add-ReviewCampaignHumanDisposition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][ValidateSet('accept-current', 'require-correction')][string]$Decision,
        [Parameter(Mandatory)][string]$AuthorizedBy,
        [Parameter(Mandatory)][string]$AuthorizationRef,
        [Parameter(Mandatory)][string]$Rationale
    )
    $result = Get-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage result
    if ($null -eq $result) { throw 'review-human-disposition-result-missing' }
    if ([string]$result.completion -cne 'complete' -or [string]$result.validation -cne 'valid' -or [string]$result.currentness -cne 'current') {
        throw 'review-human-disposition-requires-complete-current-valid-result'
    }
    if ($Decision -ceq 'accept-current' -and [string]$result.verdict -cne 'findings') { throw 'review-human-disposition-accept-requires-findings-result' }
    if ([string]::IsNullOrWhiteSpace($AuthorizedBy) -or [string]::IsNullOrWhiteSpace($AuthorizationRef) -or [string]::IsNullOrWhiteSpace($Rationale)) {
        throw 'review-human-disposition-requires-explicit-human-evidence'
    }
    $token = Get-ReviewCampaignStableToken -Value "$CampaignId/$RunId/$($result.target_digest)/$Decision/$AuthorizationRef" -Length 20
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'human-disposition'; disposition_id = "disposition-$token"
        campaign_id = $CampaignId; run_id = $RunId; target_digest = [string]$result.target_digest; decision = $Decision
        authority_kind = 'human'; authorized_by = $AuthorizedBy; authorization_ref = $AuthorizationRef; rationale = $Rationale
        observed_at = [DateTimeOffset]::UtcNow.ToString('o')
    }
    $existing = @(Get-ReviewCampaignHumanDispositionFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId | Where-Object { [string]$_.disposition_id -ceq $fact.disposition_id })
    if ($existing.Count -gt 0) {
        return [pscustomobject]@{ fact = $existing[0]; created = $false; idempotent = $true; path = $null }
    }
    try { $write = Write-ReviewCampaignHumanDispositionFact -StoreRoot $StoreRoot -Fact $fact }
    catch {
        if ($_.Exception.Message -notlike 'review-store-corruption:conflicting-immutable-fact:*') { throw }
        $existing = @(Get-ReviewCampaignHumanDispositionFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId | Where-Object { [string]$_.disposition_id -ceq $fact.disposition_id })
        if ($existing.Count -ne 1) { throw }
        return [pscustomobject]@{ fact = $existing[0]; created = $false; idempotent = $true; path = $null }
    }
    return [pscustomobject]@{ fact = $fact; created = $write.created; idempotent = $write.idempotent; path = $write.path }
}

function Invoke-ReviewCampaignRun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$StagingRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$ReservationId,
        [Parameter(Mandatory)][string]$TargetLineage,
        [Parameter(Mandatory)]$TargetPort,
        [Parameter(Mandatory)]$HarnessPort,
        [Parameter(Mandatory)]$RuntimePort,
        [Parameter(Mandatory)]$VerificationPort,
        [Parameter(Mandatory)]$ClockPort,
        [Parameter(Mandatory)][string]$PromptPath,
        [string]$ReviewScope = 'Review the complete frozen target and return the versioned candidate JSON contract.',
        [switch]$DesignContextEmpty,
        [ValidateScript({
            $limits = Get-ReviewAuthorityTimingLimits
            if ($_ -lt 1 -or $_ -gt [int]$limits.max_invocation_timeout_seconds) {
                throw "TimeoutSeconds must be between 1 and $($limits.max_invocation_timeout_seconds)."
            }
            return $true
        })][int]$TimeoutSeconds = 900,
        [scriptblock]$ProgressSink,
        [string]$AuthorityConfigPath
    )
    $authority = Get-ContinuousCoReviewAuthorityDecision -ConfigPath $AuthorityConfigPath
    if (-not $authority.campaign_authority_enabled) { return [pscustomobject]@{ status = 'suppressed'; reason = ('campaign-authority-disabled:' + $authority.reason); invoked = $false; result = $null } }
    $attemptStartedAt = Read-ReviewClockUtc -ClockPort $ClockPort
    $attemptMono = Read-ReviewClockMonotonic -ClockPort $ClockPort
    $progressWatch = [Diagnostics.Stopwatch]::StartNew()
    Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage 'requested' -Message 'run requested' -ElapsedMilliseconds 0 -TimeoutSeconds $TimeoutSeconds

    $placeholderDigest = 'pending-target'
    Write-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage requested -Fact (New-ReviewRunStateFact -CampaignId $CampaignId -RunId $RunId -TargetDigest $placeholderDigest -HarnessId ([string]$HarnessPort.id) -State requested) | Out-Null
    $reservationResult = Request-ReviewCampaignReservationFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -ReservationId $ReservationId -ObservedAt (Read-ReviewClockUtc -ClockPort $ClockPort)
    if (-not $reservationResult.acquired) {
        Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage failed -Message ([string]$reservationResult.reason) -ProcessTreeLive $false -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
        return [pscustomobject]@{ status = 'not-started'; reason = $reservationResult.reason; invoked = $false; result = $null }
    }
    $reservation = $reservationResult.fact
    Write-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage reserved -Fact (New-ReviewRunStateFact -CampaignId $CampaignId -RunId $RunId -TargetDigest $placeholderDigest -HarnessId ([string]$HarnessPort.id) -State reserved) | Out-Null

    $snapshot = $null; $disposeSnapshot = $true; $targetProtection = $null
    try {
        try {
            $snapshot = & $TargetPort.prepare $RunId
            $targetDigest = [string]$snapshot.target_digest
            $paths = Initialize-ReviewRunStaging -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId
            $verification = & $VerificationPort.execute $snapshot $paths
            if (-not [bool]$verification.ok) {
                $reason = [string]$verification.reason
                $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
                $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends @() -Reason $reason -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome preflight-failed
                Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage failed -Message $reason -ProcessTreeLive $false -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
                return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path; report_path = $failed.report_path }
            }
            $effectiveReviewScope = $ReviewScope + [string]$verification.review_scope_suffix
            $deadline = ([DateTimeOffset]::Parse((Read-ReviewClockUtc -ClockPort $ClockPort))).AddSeconds($TimeoutSeconds).ToString('o')
            $invocation = [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $CampaignId; run_id = $RunId; target_digest = $targetDigest
                snapshot_path = [string]$snapshot.snapshot_path; review_scope = $effectiveReviewScope; prompt_path = [IO.Path]::GetFullPath($PromptPath)
                candidate_result_path = $paths.candidate_result_path; candidate_report_path = $paths.candidate_report_path; deadline = $deadline
            }
            $contract = Test-ReviewAuthorityContractObject -ContractName ReviewInvocation -InputObject $invocation -ExpectedCampaignId $CampaignId -ExpectedRunId $RunId -ExpectedTargetDigest $targetDigest
            $targetReady = -not [string]::IsNullOrWhiteSpace($targetDigest) -and [IO.Directory]::Exists([string]$snapshot.snapshot_path) -and [IO.File]::Exists([string]$invocation.prompt_path)
            $protection = if ($TargetPort.PSObject.Properties['protect']) {
                & $TargetPort.protect $snapshot ([string]$invocation.candidate_result_path)
            }
            elseif ([string]$TargetPort.kind -ceq 'fixture') { [pscustomobject]@{ ok = $true; reason = 'fixture-read-only'; lease = $null } }
            else { [pscustomobject]@{ ok = $false; reason = 'review-target-protection-port-missing'; lease = $null } }
            if ([bool]$protection.ok) { $targetProtection = $protection.lease }
            # Protection is a prerequisite, not merely another collected boolean. Do not let a
            # host adapter inspect or bootstrap inside an unprotected governed target.
            $harnessReady = if ([bool]$protection.ok) { & $HarnessPort.preflight $invocation } else { [pscustomobject]@{ ok = $false; reason = 'blocked-by-target-protection' } }
            $runtimeReady = if ([bool]$protection.ok) { & $RuntimePort.preflight $invocation } else { [pscustomobject]@{ ok = $false; reason = 'blocked-by-target-protection' } }
            $preflight = @{ target = $targetReady; target_protection = [bool]$protection.ok; store = $true; contract = [bool]$contract.valid; containment = $targetReady; verification = [bool]$verification.ok; harness = [bool]$harnessReady.ok; runtime = [bool]$runtimeReady.ok }
            if (@($preflight.Values | Where-Object { -not [bool]$_ }).Count -gt 0) {
                $reason = 'preflight-failed:' + (@($preflight.Keys | Where-Object { -not [bool]$preflight[$_] } | Sort-Object) -join ',')
                $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
                $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends @() -Reason $reason -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome preflight-failed
                Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage failed -Message $reason -ProcessTreeLive $false -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
                return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path; report_path = $failed.report_path }
            }
        }
        catch {
            $reason = 'preflight-failed:' + $_.Exception.Message
            $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
            $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $placeholderDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends @() -Reason $reason -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome preflight-failed
            Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage failed -Message $reason -ProcessTreeLive $false -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
            return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path; report_path = $failed.report_path }
        }

        Write-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage preflighted -Fact (New-ReviewRunStateFact -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -State preflighted) | Out-Null
        try {
            $contractVersion = if ($HarnessPort.PSObject.Properties['contract_version']) { [string]$HarnessPort.contract_version } else { '1.0' }
            $priorResults = @(Get-ReviewAuthorityCampaignRunResults -StoreRoot $StoreRoot -CampaignId $CampaignId)
            $duplicate = Test-ReviewCampaignDuplicateCombination -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -ContractVersion $contractVersion -Runs $priorResults
            if ($duplicate.duplicate) {
                $priorIds = (@($duplicate.prior_run_ids | Select-Object -First 10) -join ',')
                Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage duplicate-warning -Message ("same target/harness/contract previously reviewed by: $priorIds") -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
            }
        }
        catch {
            # Duplicate detection is advisory and cannot block or authorize a run.
            $null = $_
        }
        $claim = Request-ReviewAuthorityClaim -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -TargetLineage $TargetLineage -ObservedAt (Read-ReviewClockUtc -ClockPort $ClockPort)
        if (-not $claim.acquired) {
            $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
            $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends @() -Reason ('claim-not-acquired:' + $claim.reason) -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome claim-contended -Containment unknown
            Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage failed -Message ('claim-not-acquired:' + $claim.reason) -ProcessTreeLive $false -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
            return [pscustomobject]@{ status = 'not-started'; reason = ('claim-not-acquired:' + $claim.reason); invoked = $false; result = $failed.result; result_path = $failed.result_path; report_path = $failed.report_path }
        }
        Write-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage claimed -Fact (New-ReviewRunStateFact -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -State claimed) | Out-Null
        Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage 'preflighted' -Message 'target, verification, store, contract, containment, harness, and runtime preflight passed' -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds

        $readClockCommand = Get-Command -Name 'Read-ReviewClockUtc' -CommandType Function
        $getFactsCommand = Get-Command -Name 'Get-ReviewAuthorityCampaignFacts' -CommandType Function
        $resolveSpendCommand = Get-Command -Name 'Resolve-ReviewCampaignSpendDecision' -CommandType Function
        $writeSpendCommand = Get-Command -Name 'Write-ReviewCampaignSpendFact' -CommandType Function
        $writeRunCommand = Get-Command -Name 'Write-ReviewRunAuthorityFact' -CommandType Function
        $newRunFactCommand = Get-Command -Name 'New-ReviewRunStateFact' -CommandType Function
        $newRecoveryFactCommand = Get-Command -Name 'New-ReviewRunRecoveryFact' -CommandType Function
        $writeRecoveryFactCommand = Get-Command -Name 'Write-ReviewRunRecoveryFact' -CommandType Function
        $writeProgressCommand = Get-Command -Name 'Write-ReviewOrchestrationProgress' -CommandType Function
        $onStarted = {
            param($runtimeReceipt)
            $startedAt = & $readClockCommand -ClockPort $ClockPort
            $recoveryFact = & $newRecoveryFactCommand -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) `
                -TargetLineage $TargetLineage -RuntimeReceipt $runtimeReceipt -Snapshot $snapshot -StagingRoot $StagingRoot `
                -InvocationStartedAt $startedAt -InvocationStartedMonotonicMs $attemptMono
            & $writeRecoveryFactCommand -StoreRoot $StoreRoot -Fact $recoveryFact | Out-Null
            $existingSpends = @(& $getFactsCommand -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind spend)
            $existingReleases = @(& $getFactsCommand -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind releases)
            $spendDecision = & $resolveSpendCommand -Reservation $reservation -InvocationStartedAt $startedAt -Preflight $preflight -Spends $existingSpends -Releases $existingReleases
            if (-not $spendDecision.permitted) { throw ('review-invocation-spend-refused:' + $spendDecision.reason) }
            & $writeSpendCommand -StoreRoot $StoreRoot -Fact $spendDecision.fact | Out-Null
            & $writeRunCommand -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage invoked -Fact (& $newRunFactCommand -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -State invoked) | Out-Null
            & $writeProgressCommand -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage running -Message 'reviewer invoked under verified containment' -ProcessTreeLive $true -OutputActivity $false -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
        }.GetNewClosure()

        $runtimeProgress = {
            param($sample)
            $treeLive = if ($null -ne $sample -and $sample.PSObject.Properties['process_tree_live']) { $sample.process_tree_live } else { $true }
            $activity = if ($null -ne $sample -and $sample.PSObject.Properties['output_activity']) { $sample.output_activity } else { $null }
            & $writeProgressCommand -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage running -Message 'reviewer heartbeat; activity is not semantic progress' -ProcessTreeLive $treeLive -OutputActivity $activity -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
        }.GetNewClosure()

        try { $runtimeResult = & $RuntimePort.invoke $HarnessPort $invocation $onStarted $snapshot.suppression_environment $runtimeProgress }
        catch { $runtimeResult = [pscustomobject]@{ runtime_outcome = 'abandoned'; termination_verified = $false; containment = 'unknown'; failure_reason = ('runtime-adapter-failed:' + $_.Exception.Message); process_tree_live = $null; output_activity = $null } }
        $spends = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind spend | Where-Object { [string]$_.run_id -ceq $RunId })
        $invoked = $spends.Count -gt 0
        if (-not $invoked) {
            $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
            $reason = if ($runtimeResult.failure_reason) { [string]$runtimeResult.failure_reason } else { 'launch failed before invocation' }
            $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends $spends -Reason $reason -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome launch-failed -Containment unknown
            Complete-ReviewAuthorityClaim -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -TargetLineage $TargetLineage -Disposition abandoned -ObservedAt $endedAt | Out-Null
            Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage failed -Message $reason -ProcessTreeLive $false -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
            return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path; report_path = $failed.report_path }
        }

        $observedUsage = if ($runtimeResult.PSObject.Properties['usage']) { $runtimeResult.usage } else { $null }
        Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage 'terminalizing' -Message 'runtime returned; validating target and candidate' -ProcessTreeLive $runtimeResult.process_tree_live -OutputActivity $runtimeResult.output_activity -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds -Usage $observedUsage
        $containment = [string]$runtimeResult.containment; $runtimeOutcome = [string]$runtimeResult.runtime_outcome
        $failureReason = [string]$runtimeResult.failure_reason
        try { $integrity = & $TargetPort.integrity $snapshot } catch { $integrity = [pscustomobject]@{ intact = $false; classification = 'integrity-check-failed' } }
        if (-not $integrity.intact) {
            $containment = 'violated'; $runtimeOutcome = 'containment-violated'
            $changedPaths = @()
            if ($integrity.PSObject.Properties['changed_paths']) {
                $changedPaths = @($integrity.changed_paths | ForEach-Object { [string]$_ } | Select-Object -First 20)
            }
            $integrityReason = 'target-integrity-failed:' + [string]$integrity.classification
            if ($changedPaths.Count -gt 0) { $integrityReason += ':' + ($changedPaths -join ',') }
            $failureReason = if ([string]::IsNullOrWhiteSpace($failureReason)) { $integrityReason } else { $failureReason + ';' + $integrityReason }
            $failureReason = ConvertTo-ReviewAuthorityBoundedText -Value $failureReason -MaximumLength 1900
        }
        try { $currentness = & $TargetPort.currentness $snapshot } catch { $currentness = [pscustomobject]@{ classification = 'unknown'; exact = $false; reason = 'currentness-check-failed' } }
        $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort
        $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
        $startedAt = ConvertTo-ReviewObservedTimestampString -Value $spends[0].invocation_started_at
        $degradeReason = if ($DesignContextEmpty) { 'DESIGN_CONTEXT_EMPTY: no spec, design analysis, or formal contract resolved; this run is partial evidence and cannot approve the current target.' } else { $null }
        $ingress = Invoke-ReviewResultIngress -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -RuntimeOutcome $runtimeOutcome -Invoked $true -TerminationVerified ([bool]$runtimeResult.termination_verified) -Containment $containment -Currentness ([string]$currentness.classification) -StartedAt $startedAt -EndedAt $endedAt -DurationMs $duration -FailureReason $failureReason -ControllerDegradeReason $degradeReason
        if ($ingress.published) {
            Complete-ReviewAuthorityClaim -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -TargetLineage $TargetLineage -Disposition released -ObservedAt (Read-ReviewClockUtc -ClockPort $ClockPort) | Out-Null
            $findingCount = if ($ingress.candidate_category -ceq 'valid' -and [string]$ingress.result.completion -ceq 'complete' -and [string]$ingress.result.validation -ceq 'valid') { @($ingress.result.findings).Count } else { $null }
            Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage 'terminal' -Message $ingress.reason -ProcessTreeLive $false -OutputActivity $runtimeResult.output_activity -ValidatedFindingCount $findingCount -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds -Usage $observedUsage
            return [pscustomobject]@{ status = 'terminal'; reason = $ingress.reason; invoked = $true; result = $ingress.result; result_path = $ingress.result_path; report_path = $ingress.report_path }
        }
        # A reviewer tree may still be using the frozen target. Recovery owns disposal after it proves
        # termination; removing the worktree here could race a live process or strand an OS-specific
        # cleanup failure.
        $disposeSnapshot = $false
        Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage failed -Message $ingress.reason -ProcessTreeLive $runtimeResult.process_tree_live -OutputActivity $runtimeResult.output_activity -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds -Usage $observedUsage
        return [pscustomobject]@{ status = 'awaiting-termination-verification'; reason = $ingress.reason; invoked = $true; result = $null; result_path = $null }
    }
    finally {
        if ($null -ne $snapshot -and $disposeSnapshot) {
            if ($TargetPort.PSObject.Properties['unprotect']) { try { $null = & $TargetPort.unprotect $snapshot $targetProtection } catch { $null = $_ } }
            try { $null = & $TargetPort.dispose $snapshot } catch { $null = $_ }
        }
    }
}
