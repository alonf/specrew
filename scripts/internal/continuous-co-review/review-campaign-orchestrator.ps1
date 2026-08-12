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
# HARD dependency: the ONE path-identity primitive. Guarded on a name unique to it, never on a name
# a same-named duplicate could satisfy (DRIFT-198-I009-027).
if (-not (Get-Command -Name 'Get-ContinuousCoReviewPathCaseSensitive' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'path-identity.ps1') }

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
        # Progress is side-channel information. Never let a sink's return values join the runtime adapter's
        # pipeline and change the shape of the authority-bearing result.
        $null = & $Sink $event
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
    param(
        [Parameter(Mandatory)][string]$OriginRepo,
        [string]$ExternalRoot,
        [AllowEmptyCollection()][string[]]$ExcludedPathPatterns = @()
    )
    # Capture CommandInfo objects as well as values. A PowerShell closure is backed by a dynamic
    # module and cannot otherwise resolve private functions from the module that constructed it.
    $prepareCommand = Get-Command -Name 'New-GitReviewTargetSnapshot' -CommandType Function
    $currentnessCommand = Get-Command -Name 'Test-GitReviewTargetCurrentness' -CommandType Function
    $integrityCommand = Get-Command -Name 'Test-GitReviewTargetSnapshotIntegrity' -CommandType Function
    $protectCommand = Get-Command -Name 'Enable-ReviewTargetReadOnlyProtection' -CommandType Function
    $unprotectCommand = Get-Command -Name 'Disable-ReviewTargetReadOnlyProtection' -CommandType Function
    $disposeCommand = Get-Command -Name 'Remove-GitReviewTargetSnapshot' -CommandType Function
    $prepare = {
        param($runId)
        & $prepareCommand -OriginRepo $OriginRepo -RunId $runId -ExternalRoot $ExternalRoot -ExcludedPathPatterns $ExcludedPathPatterns
    }.GetNewClosure()
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
        $null = & $onStarted ([pscustomobject][ordered]@{
            schema_version = '1.0'; runtime_id = 'fixture-runtime'; platform = 'fixture'; containment_kind = 'fixture'
            containment_id = 'fixture-contained-process'; process_id = $PID
            process_started_at = (Get-Process -Id $PID).StartTime.ToUniversalTime().ToString('o')
        })
        if ($null -ne $progress) { try { $null = & $progress ([pscustomobject]@{ process_tree_live = $true; output_activity = $false }) } catch { $null = $_ } }
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
    $frozenPaths = Get-ContinuousCoReviewOrdinalUniquePath -Path @($Snapshot.machinery_paths |
            ForEach-Object { ([string]$_ -replace '\\', '/').Trim('/') })
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
        # LITERAL pathspecs for the same reason as the restore below: a machinery identity holding
        # glob metacharacters must not select unrelated tracked source into the support manifest.
        $chunk = @($paths[$offset..$end] | ForEach-Object { ConvertTo-ContinuousCoReviewLiteralPathspec -Path $_ })
        $listed = @(Get-GitReviewTargetTreeEntries -WorkingDirectory $snapshotPath -TreeId $commit -Pathspec $chunk)
        foreach ($entry in $listed) {
            # Verification support is controller scaffolding, not product source. Never
            # materialize a symlink from it into the otherwise-contained verification copy.
            if ([string]$entry.mode -ceq '120000') { continue }
            $normalized = ([string]$entry.path -replace '\\', '/').Trim()
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
    # Volume-derived, never OS-family: this dedupes parent directories for cleanup, so folding two
    # case-distinct parents would leave one uncleaned. 'distinct' keeps both when undetermined.
    $pathComparer = Get-ContinuousCoReviewPathComparer -Path $root -WhenUndetermined 'distinct'
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
            # LITERAL pathspecs, never raw names: these are frozen repository identities, and Git
            # would read a legal name holding `*`, `?`, or `[]` as a glob. That let a machinery
            # identity select a DIFFERENT tracked path, restore it into the verification copy where
            # it could change the command result, then remove it again - leaving the post-run digest
            # matching target_digest and certifying green evidence for a composition that is not the
            # authorized candidate (co-review finding, run run-f198-i009-aab37c3b-codex-2).
            $chunk = @($manifest.files[$offset..$end] | ForEach-Object { ConvertTo-ContinuousCoReviewLiteralPathspec -Path $_ })
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
        # T007 / FR-013. `reason` is UNCHANGED, byte for byte: it is the machine token AND the pointer
        # to the human-authorized disclosure door, three fixtures assert it by exact equality, and the
        # seal is not what this improves. The DIAGNOSIS rides beside it - facts the controller already
        # owns (command, exit code, duration, timeout, classification, and the env_refs the plan
        # allowed), never command output. See Get-ContinuousCoReviewVerificationFailureDiagnosis.
        return [pscustomobject]@{
            ok = $false
            reason = 'verification-command-failed:' + ($failedIds -join ',') + ':diagnostics-require-command-scoped-disclosure'
            state = 'verification-failed'
            review_scope_suffix = ''
            command_count = $planIds.Count
            evidence_count = $evidence.Count
            failed_command_ids = @($failedIds)
            diagnosis = (Get-ContinuousCoReviewVerificationFailureDiagnosis -Evidence $evidence)
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
    # The human-readable name of each command that actually ran, for the success message. A plan's
    # `label` is written for a person; the command_id is not, so the id is only a fallback.
    $commandLabels = @(
        foreach ($command in @($selected.plan.commands)) {
            $label = [string](Get-ReviewAuthorityProperty -Object $command -Name 'label')
            if ([string]::IsNullOrWhiteSpace($label)) { $label = [string](Get-ReviewAuthorityProperty -Object $command -Name 'command_id') }
            if (-not [string]::IsNullOrWhiteSpace($label)) { $label }
        }
    )
    return [pscustomobject]@{
        ok = $true; reason = 'verification-evidence-ready'; state = 'configured'; review_scope_suffix = $scopeSuffix
        command_count = $planIds.Count; evidence_count = $evidence.Count; command_labels = @($commandLabels)
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
    # Captured as a COMMAND OBJECT, like the four above, because $execute below is invoked as a PORT in a
    # foreign scope where ambient function names do not resolve. Guarded on the exact function needed
    # rather than on a sibling name: a guard that probes a DIFFERENT name from the primitive it wants is
    # how DRIFT-198-I009-027's shadow survived, and a stale copy of path-identity.ps1 satisfies
    # `Get-ContinuousCoReviewPathCaseSensitive` while lacking this one.
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewOrdinalUniquePath' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'path-identity.ps1') }
    $uniquePathCommand = Get-Command -Name 'Get-ContinuousCoReviewOrdinalUniquePath' -CommandType Function
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
        # Ordinal, matching the maps: `-CaseSensitive` leaves Sort-Object CULTURE-aware, so a
        # byte-distinct key the maps kept apart collapsed here and its file was never compared - the
        # integrity check could then report the frozen target intact after a real mutation
        # (DRIFT-198-I009-033).
        foreach ($key in (& $uniquePathCommand -Path @(@($originalBefore.Keys) + @($originalAfter.Keys)))) {
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
    $slotRestored = $false
    if ($null -ne $Reservation) {
        $releaseDecision = Resolve-ReviewCampaignReleaseDecision -Reservation $Reservation -Reason $Reason -ObservedAt $ObservedAt -Spends $Spends
        if ($releaseDecision.permitted) {
            Write-ReviewCampaignReleaseFact -StoreRoot $StoreRoot -Fact $releaseDecision.fact | Out-Null
            $slotRestored = $true
        }
    }

    # F4's REAL residue, and the fix for it. Measured in the T067 timeline: a release restored a slot,
    # NO run and NO refusal event followed, and a fresh human authorization was minted three minutes
    # later anyway. The slot was available and was never OFFERED, so the human paid for an authorization
    # they did not need. A restored slot that nobody is told about is the same class as a demotion
    # nobody is told about.
    #
    # CARRIED AS STRUCTURED DATA, NEVER APPENDED TO A REASON STRING. Three separate surfaces would break
    # if this were prose in `$Reason`:
    #
    #  - the RELEASE FACT's reason (resolved above) is machine-classified and IMMUTABLE, and it is the
    #    field releases are counted and classified BY - the same counting this feature's own analysis
    #    used. Prose there is permanent ledger pollution.
    #  - the campaign's RETURNED reason is asserted by exact equality in three fixtures.
    #  - the persisted `failure_reason` must keep EQUALLING that returned reason. An existing fixture
    #    pins it, and it is right to: a run whose stored record and reported reason differ leaves a
    #    reader unable to tell which is authoritative. That is the honest-state class this feature is
    #    about, and the first cut of this change broke it.
    #
    # This is the same shape the demotion marks and the verification diagnosis already use: the machine
    # token stays pure, the human sentence rides beside it as data, and a human-facing surface renders
    # it. Said ONLY when a slot actually came back - a note that appeared regardless would tell the
    # human they still hold an authorization they have in fact spent.
    $ingress = Invoke-ReviewResultIngress -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $TargetDigest -HarnessId $HarnessId -RuntimeOutcome $RuntimeOutcome -Invoked $false -TerminationVerified $true -Containment $Containment -Currentness unknown -StartedAt $StartedAt -EndedAt $ObservedAt -DurationMs $DurationMs -FailureReason $Reason
    $ingress | Add-Member -NotePropertyName slot_restored -NotePropertyValue $slotRestored -Force
    $ingress | Add-Member -NotePropertyName slot_restored_note -NotePropertyValue $(
        if ($slotRestored) { 'The review did not start, so no round was used and the authorization you already gave is still available. You do not need to issue a new one; fix what this message names and run the review again.' }
        else { '' }
    ) -Force
    return $ingress
}

function Get-ReviewCampaignRoundBudgetTotal {
    # N1: the runaway fuse, per CAMPAIGN (clarified 2026-08-10 - a per-tree-state budget would reset
    # on every fix round and never bind). Default 4: deep enough that a legitimate round-5-class
    # blocker does not hit the reset ceremony mid-flow, small enough that a runaway dies fast.
    [CmdletBinding()]
    param([AllowEmptyString()][string]$RepoRoot = '')
    $default = 4
    if ([string]::IsNullOrWhiteSpace($RepoRoot)) { return $default }
    $configPath = Join-Path $RepoRoot '.specrew/config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { return $default }
    try {
        foreach ($line in @(Get-Content -LiteralPath $configPath -Encoding UTF8)) {
            if ($line -match '^\s*co_review_max_rounds:\s*[''"]?(?<value>\d+)[''"]?\s*(?:#.*)?$') {
                $parsed = 0
                if ([int]::TryParse($Matches['value'], [ref]$parsed) -and $parsed -gt 0) { return $parsed }
            }
        }
    }
    catch { $null = $_ }
    return $default
}

function Add-ReviewCampaignRoundPause {
    # T001 / FR-001. THE ROUND TERMINAL. Every round ends here: the engine records what it found and
    # what it cost, then hands the decision back to the human. It never starts another round on its
    # own - that is the whole point. Ledger F8 measured what the missing pause cost: fifteen fix
    # rounds on one target with no sanctioned way to stop.
    #
    # Cost is CUMULATIVE across the campaign, so the human sees what the campaign has spent rather
    # than what this one round took.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$TargetDigest,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)][string]$ObservedAt,
        [AllowEmptyString()][string]$RepoRoot = ''
    )

    # A prior ROUND is one that reached a terminal: it published a result, or it recorded a pause,
    # or both. Infrastructure failures are excluded here for the same reason FR-014 keeps them off
    # the allowance - a consumer must not be charged a round for an engine defect.
    $priorResults = @()
    try { $priorResults = @(Get-ReviewAuthorityCampaignRunResults -StoreRoot $StoreRoot -CampaignId $CampaignId) } catch { $priorResults = @() }
    # A recorded budget reset moves where counting STARTS. Rounds before it stay on the record - they
    # are immutable facts and the campaign's history is the point - they simply no longer count against
    # the allowance the human just topped up. Absent, this is $null and nothing is excluded.
    $budgetResetAt = $null
    try {
        $budgetReset = Get-ReviewCampaignLatestBudgetReset -StoreRoot $StoreRoot -CampaignId $CampaignId
        if ($null -ne $budgetReset) { $budgetResetAt = [string](Get-ReviewAuthorityProperty -Object $budgetReset -Name 'observed_at') }
    }
    catch { $budgetResetAt = $null }
    $invokedPrior = @($priorResults | Where-Object {
            $priorStartedAt = [string](Get-ReviewAuthorityProperty -Object $_ -Name 'started_at')
            [string](Get-ReviewAuthorityProperty -Object $_ -Name 'run_id') -cne $RunId -and
            [string](Get-ReviewAuthorityProperty -Object $_ -Name 'runtime_outcome') -notin @('preflight-failed', 'claim-contended', 'launch-failed') -and
            ([string]::IsNullOrWhiteSpace($budgetResetAt) -or ([string]::IsNullOrWhiteSpace($priorStartedAt)) -or $priorStartedAt -gt $budgetResetAt)
        })
    $priorRunIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($prior in $invokedPrior) { $null = $priorRunIds.Add([string](Get-ReviewAuthorityProperty -Object $prior -Name 'run_id')) }
    try {
        $runsRoot = Get-ReviewAuthorityStorePath -StoreRoot $StoreRoot -RelativePath ((Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $CampaignId) + '/runs')
        if ([IO.Directory]::Exists($runsRoot)) {
            foreach ($runDirectory in [IO.Directory]::EnumerateDirectories($runsRoot)) {
                $name = [IO.Path]::GetFileName($runDirectory)
                if ($name -ceq $RunId) { continue }
                $pausePath = [IO.Path]::Combine($runDirectory, 'pending-pause.json')
                if (-not [IO.File]::Exists($pausePath)) { continue }
                # This second source exists because a round that paused counts even if its result is
                # unreadable. It must honour the reset for the same reason the first one does - counting
                # a pre-reset round here would silently undo the top-up the human just recorded.
                if (-not [string]::IsNullOrWhiteSpace($budgetResetAt)) {
                    $pausedAt = ''
                    try { $pausedAt = [string](Get-ReviewAuthorityProperty -Object (Get-Content -LiteralPath $pausePath -Raw | ConvertFrom-Json) -Name 'observed_at') }
                    catch { $pausedAt = '' }
                    if (-not [string]::IsNullOrWhiteSpace($pausedAt) -and $pausedAt -le $budgetResetAt) { continue }
                }
                $null = $priorRunIds.Add($name)
            }
        }
    }
    catch { $null = $_ }
    $roundsUsed = $priorRunIds.Count + 1

    $elapsedMs = [double]([long](Get-ReviewAuthorityProperty -Object $Result -Name 'duration_ms'))
    foreach ($prior in $invokedPrior) {
        $priorMs = [long](Get-ReviewAuthorityProperty -Object $prior -Name 'duration_ms')
        if ($priorMs -gt 0) { $elapsedMs += $priorMs }
    }

    # Assigned to a variable BEFORE wrapping. Get-ReviewAuthorityProperty returns collections with
    # -NoEnumerate, so `@(Get-ReviewAuthorityProperty ...)` inline nests the whole findings array inside
    # a single element and the decision counted a wrapper instead of findings. The callee now flattens
    # defensively as well; this line is corrected too, because relying on a downstream repair to make a
    # wrong call right is how the next caller gets it wrong again.
    $resultFindings = Get-ReviewAuthorityProperty -Object $Result -Name 'findings'
    # -Result carried so an unfinished review cannot render as a clean one: findings=0 on a timed-out
    # run means WE DO NOT KNOW, not NOTHING WAS FOUND.
    $decision = Resolve-ReviewCampaignPauseDecision -Result $Result -Findings @($resultFindings) `
        -RoundsUsed $roundsUsed -BudgetTotal (Get-ReviewCampaignRoundBudgetTotal -RepoRoot $RepoRoot) `
        -ElapsedMinutes ([Math]::Round($elapsedMs / 60000, 0))

    $fact = New-ReviewCampaignPendingPauseFact -CampaignId $CampaignId -RunId $RunId -TargetDigest $TargetDigest -Decision $decision -ObservedAt $ObservedAt
    $recorded = $false
    try { $recorded = [bool](Write-ReviewCampaignPendingPauseFact -StoreRoot $StoreRoot -Fact $fact).created }
    catch { $recorded = $false }

    if (-not (Get-Command -Name 'Format-ReviewCampaignPauseSurface' -ErrorAction SilentlyContinue)) {
        $navigator = Join-Path $PSScriptRoot 'continuous-co-review-navigator.ps1'
        if (Test-Path -LiteralPath $navigator -PathType Leaf) { try { . $navigator } catch { $null = $_ } }
    }
    $surface = if (Get-Command -Name 'Format-ReviewCampaignPauseSurface' -ErrorAction SilentlyContinue) {
        Format-ReviewCampaignPauseSurface -ProjectName $ProjectName -Decision $decision
    }
    else { $null }

    return [pscustomobject]@{ recorded = $recorded; decision = $decision; fact = $fact; surface = $surface }
}

function Invoke-ReviewCampaignStopHereLanding {
    # T002 / FR-005. The "stop here" choice, landed as ONE action.
    #
    # T067's endgame is why this exists: a bare stop ruling wedged against the signoff gate, because
    # accepted-residuals-on-an-unreviewed-tree was inexpressible. The session correctly refused to
    # bypass, and the human was left adjudicating between two governors by hand - which a consumer
    # cannot do. Composing the three sanctioned steps removes the collision instead of documenting it.
    #
    # The ORDER is a safety property, not sequencing convenience:
    #   1. verify the frozen tree            - so acceptance describes a tree that was just checked
    #   2. record the identity-bound accept  - so the gate has something real to consult
    #   3. sync the gate                     - which now finds the evidence it demands
    # A failed step STOPS the chain. Accepting residuals against an unverified tree is precisely the
    # state this feature exists to make impossible, so it must not be reachable by falling forward.
    #
    # Each step is an injectable port with a real default, matching this module's existing port
    # style, so the composition is testable without a live reviewer.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$AuthorizedBy,
        [Parameter(Mandatory)][string]$AuthorizationRef,
        [Parameter(Mandatory)][string]$Rationale,
        [scriptblock]$GatingPrecondition,
        [scriptblock]$VerifyPort,
        [scriptblock]$AcceptPort,
        [scriptblock]$GateSyncPort
    )

    $context = [pscustomobject]@{
        project_root = $ProjectRoot; store_root = $StoreRoot; campaign_id = $CampaignId; run_id = $RunId
        authorized_by = $AuthorizedBy; authorization_ref = $AuthorizationRef; rationale = $Rationale
    }

    if ($null -eq $VerifyPort) {
        $VerifyPort = {
            param($ctx)
            # THIS DEFAULT HAD NEVER EXECUTED. It called New-GitReviewTargetSnapshot with -RepoRoot -
            # a parameter that does not exist - and supplied no -RunId, which is mandatory. PowerShell
            # threw on the binding before verification began, so the PUBLIC option-2 path could not
            # complete a sign-off at all. Every fixture in the stop-here suite injects -VerifyPort,
            # including the ones added the same morning to guard this very landing, so nothing saw it.
            #
            # CORRECTING THE ARGUMENTS IS NOT THE FIX. The fix is that the defaults now RUN in at least
            # one path (see campaign-stop-here-real-ports.Tests.ps1); otherwise the next defect inside
            # this function is exactly as invisible and we meet it a round later.
            # IT REUSES THE PRODUCTION VERIFICATION PORT rather than calling the verifier directly, and
            # that is the actual fix rather than the argument correction.
            #
            # Correcting -OriginRepo/-RunId made the call bind, and the chain still stopped at
            # verification reporting "no verification plan" for a project that HAS one. The reason is a
            # second defect the first one was hiding: `.specrew/**` is excluded from the snapshot tree,
            # so the plan is captured as bytes and materialized only by New-GitReviewTargetVerificationCopy.
            # Verifying against the raw snapshot could therefore NEVER find a plan - the default was
            # wrong in two independent ways, and one throw concealed the other.
            #
            # New-ReviewProductionVerificationPort already does the whole sequence the campaign run
            # relies on: make the verification copy, run the plan inside it, dispose it, and confirm the
            # ORIGINAL frozen target was not mutated. Reusing it means stop-here verifies exactly the way
            # a review round does, and there is one implementation to keep correct instead of two that
            # drift.
            $snapshot = $null
            $verification = $null
            try {
                $snapshot = New-GitReviewTargetSnapshot -OriginRepo $ctx.project_root -RunId $ctx.run_id
                # implementer_evidence_path is a FILE, not a directory - the ingestor builds it as
                # `<run>/implementer-evidence.json`. Passing a directory made the evidence writer try to
                # OPEN it and fail with an access error, which surfaced as a warning while verification
                # carried on: the exact shape of a defect that a fixture with an injected port could
                # never have shown, found on the second run of the real one.
                # UNIQUE PER ATTEMPT, not per run. A fixed path per run id collides the moment stop-here
                # is attempted twice for the same round - which is exactly what a REFUSED landing now
                # invites, since the answer survives and the human is told to try again. The second
                # attempt then fails writing evidence, and verification reports a failure that has
                # nothing to do with the project. Found by running this test twice.
                $evidenceDirectory = Join-Path ([IO.Path]::GetTempPath()) ("specrew-stop-here-evidence/" + [string]$ctx.run_id + '/' + [guid]::NewGuid().ToString('N').Substring(0, 12))
                [IO.Directory]::CreateDirectory($evidenceDirectory) | Out-Null
                $evidenceFile = Join-Path $evidenceDirectory 'implementer-evidence.json'
                $verificationPort = New-ReviewProductionVerificationPort
                $verification = & $verificationPort.execute $snapshot ([pscustomobject]@{ implementer_evidence_path = $evidenceFile })
            }
            finally {
                # The snapshot is a linked git worktree. Leaving it behind on every stop-here accumulates
                # worktrees the consumer never asked for and git later complains about.
                if ($null -ne $snapshot) {
                    try { Remove-GitReviewTargetSnapshot -Snapshot $snapshot | Out-Null } catch { $null = $_ }
                }
            }
            # The diagnosis is carried THROUGH the port, not dropped here. A port that narrows its
            # result to {ok, reason} is where a derived explanation quietly dies (FR-013).
            return [pscustomobject]@{
                ok = [bool]$verification.ok; reason = [string]$verification.reason
                diagnosis = [string](Get-ReviewAuthorityProperty -Object $verification -Name 'diagnosis')
                command_labels = (Get-ReviewAuthorityProperty -Object $verification -Name 'command_labels')
            }
        }
    }
    if ($null -eq $AcceptPort) {
        $AcceptPort = {
            param($ctx)
            $disposition = Add-ReviewCampaignHumanDisposition -StoreRoot $ctx.store_root -CampaignId $ctx.campaign_id `
                -RunId $ctx.run_id -Decision accept-current -AuthorizedBy $ctx.authorized_by `
                -AuthorizationRef $ctx.authorization_ref -Rationale $ctx.rationale
            return [pscustomobject]@{ ok = ($null -ne $disposition); reason = 'residuals-accepted' }
        }
    }
    if ($null -eq $GateSyncPort) {
        $GateSyncPort = {
            param($ctx)
            # signoff-gate-wiring.ps1 is NOT in _load.ps1's set, so this default threw
            # "Invoke-ContinuousCoReviewSignoffGateIfEnabled is not recognized" the first time it was
            # ever executed. Third load-order defect of the day in a production default, and the third
            # found by running rather than by testing - the suites dot-source this file in BeforeAll,
            # which is a load order production does not have.
            if (-not (Get-Command -Name 'Invoke-ContinuousCoReviewSignoffGateIfEnabled' -ErrorAction SilentlyContinue)) {
                $gateWiring = Join-Path $PSScriptRoot 'signoff-gate-wiring.ps1'
                if (Test-Path -LiteralPath $gateWiring -PathType Leaf) { try { . $gateWiring } catch { $null = $_ } }
            }
            Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $ctx.project_root -BoundaryType 'review-signoff'
            return [pscustomobject]@{ ok = $true; reason = 'signoff-gate-allow' }
        }
    }

    if ($null -eq $GatingPrecondition) {
        $GatingPrecondition = {
            param($ctx)
            # READ THE RESULT, NEVER THE SUMMARY (maintainer ruling 2026-08-11, live-store hazard).
            #
            # This landing completes review sign-off. Until now it trusted that the human had been shown
            # an accurate decision surface - and DRIFT-199-I001-033 wrote a pending-pause fact into the
            # LIVE store reading `blocking 0, major 0, minor 1, "Nothing here blocks you. Stopping here
            # saves the minor findings as follow-ups"` for a round whose result holds 2 BLOCKING and 5
            # MAJOR findings. The fix corrected the code; it could not correct a fact already written,
            # and authority facts are immutable by design. So the surface actively RECOMMENDED the
            # option that completes sign-off on a round with two blocking findings.
            #
            # A derived count is written by whatever logic held at the time. The terminal result is what
            # the reviewer actually returned. Those are different trust levels, and only one of them is
            # safe to sign off against. Fails CLOSED: an unreadable or absent result refuses, because a
            # sign-off that cannot see what it is signing off is the failure this whole feature exists
            # to prevent.
            #
            # Severities are read POST-demotion, which is correct rather than incidental: the T005
            # contract lowers a gating finding that states no concrete failure scenario, and a finding
            # the contract demoted genuinely does not gate. This counts what still gates.
            $result = $null
            try { $result = Get-ReviewRunAuthorityFact -StoreRoot $ctx.store_root -CampaignId $ctx.campaign_id -RunId $ctx.run_id -Stage result }
            catch { $result = $null }
            if ($null -eq $result) {
                return [pscustomobject]@{
                    ok = $false; reason = 'stop-here-result-unavailable'
                    diagnosis = 'Specrew cannot find the saved result for this review round, so it cannot confirm what the round found. Run a fresh review of your files as they are now before completing sign-off: specrew review --live'
                }
            }
            # Direct assignment, never @(...) around the call: the accessor returns collections with
            # -NoEnumerate, and wrapping the CALL nests the whole list as one element. That exact trap
            # is what produced the wrong fact this guard exists to catch.
            $rawFindings = Get-ReviewAuthorityProperty -Object $result -Name 'findings'
            $findings = [Collections.Generic.List[object]]::new()
            foreach ($item in @($rawFindings)) {
                if ($null -eq $item) { continue }
                if ($item -is [System.Collections.IEnumerable] -and $item -isnot [string] -and $item -isnot [System.Collections.IDictionary]) {
                    foreach ($inner in $item) { if ($null -ne $inner) { $findings.Add($inner) | Out-Null } }
                    continue
                }
                $findings.Add($item) | Out-Null
            }
            $blocking = 0; $major = 0
            foreach ($finding in $findings) {
                switch (([string](Get-ReviewAuthorityProperty -Object $finding -Name 'severity')).Trim().ToLowerInvariant()) {
                    'blocking' { $blocking++ }
                    'major' { $major++ }
                }
            }

            # ARM 1 - BLOCKING ALWAYS REFUSES. Accepting a blocking finding as a residual defeats what
            # the severity means. No summary agreement can license it.
            if ($blocking -gt 0) {
                return [pscustomobject]@{
                    ok = $false; reason = ('stop-here-refused-blocking-findings:blocking={0}' -f $blocking)
                    diagnosis = ('This review round found {0} finding{1} that must be fixed before sign-off. Fix them and run another round: reply with option 1 and a new authorization reference.' -f $blocking, $(if ($blocking -eq 1) { '' } else { 's' }))
                }
            }

            # ARMS 2 AND 3 - CONSENT GIVEN AGAINST FALSE INFORMATION IS NOT CONSENT.
            #
            # Majors are MEANT to be acceptable as residuals: the decision surface itself says "Look at
            # the major findings; fix what matters to you, then stop here." Refusing them outright would
            # leave stop-here technically present and practically dead, since a minor-only round never
            # needed it - minors do not gate.
            #
            # So the question is not whether majors are acceptable. It is whether the human SAW them.
            # The live-store hazard was never that majors might be accepted; it was that the surface
            # said there were none while the result held five. What must be verified is that the number
            # they consented to is the number that is true.
            #
            # This is STRICTER than a plain "no majors" test where it matters: a summary claiming 5
            # majors when the result holds 7 passes "no majors" and fails this. Tighter on the failure
            # that occurred, looser on the one that never did.
            #
            # Both counts are POST-demotion - the pause fact's counts are derived from the ingested
            # result, whose severities the T005 contract has already lowered - so a demoted finding is
            # counted identically on both sides and cannot manufacture a false mismatch.
            if ($major -gt 0) {
                $pauseRecord = $null
                try {
                    $pauseRecord = @(Get-ReviewCampaignPauseRecords -StoreRoot $ctx.store_root -CampaignId $ctx.campaign_id |
                            Where-Object { [string]$_.run_id -ceq [string]$ctx.run_id }) | Select-Object -First 1
                }
                catch { $pauseRecord = $null }

                if ($null -eq $pauseRecord) {
                    return [pscustomobject]@{
                        ok = $false; reason = ('stop-here-refused-consent-unverifiable:major={0}' -f $major)
                        diagnosis = ('This round found {0} finding{1} worth your attention, but Specrew has no record of the summary you were shown, so it cannot treat your answer as informed. Run a fresh review of your files as they are now to see the real numbers: specrew review --live' -f $major, $(if ($major -eq 1) { '' } else { 's' }))
                    }
                }

                $shownMajor = [int](Get-ReviewAuthorityProperty -Object $pauseRecord.pause -Name 'major_count')
                if ($shownMajor -ne $major) {
                    return [pscustomobject]@{
                        ok = $false; reason = ('stop-here-refused-summary-mismatch:shown={0};actual={1}' -f $shownMajor, $major)
                        diagnosis = ('The summary you were shown does not match what this round found - it reported {0} finding{1} needing your attention, and the round actually found {2}. Specrew cannot treat your answer as informed, so sign-off will not complete. Run a fresh review of your files as they are now to see the real numbers: specrew review --live' -f $shownMajor, $(if ($shownMajor -eq 1) { '' } else { 's' }), $major)
                    }
                }
            }

            return [pscustomobject]@{ ok = $true; reason = ('consent-matches-result:major={0}' -f $major) }
        }
    }

    $steps = [Collections.Generic.List[object]]::new()
    # The precondition runs FIRST, before verification, so a gating round costs nothing at all: no
    # frozen-tree verification, no residual acceptance, no gate sync. A failed step stops the chain.
    $ordered = @(
        @{ name = 'gating-precondition'; port = $GatingPrecondition },
        @{ name = 'verification'; port = $VerifyPort },
        @{ name = 'residual-acceptance'; port = $AcceptPort },
        @{ name = 'gate-sync'; port = $GateSyncPort }
    )

    $failedStep = $null
    $failureReason = $null
    $failureDiagnosis = ''
    $verificationLabels = @()
    foreach ($step in $ordered) {
        $outcome = $null
        try { $outcome = & $step.port $context }
        catch { $outcome = [pscustomobject]@{ ok = $false; reason = [string]$_.Exception.Message } }
        $ok = ($null -ne $outcome -and [bool]$outcome.ok)
        $steps.Add([pscustomobject]@{ name = [string]$step.name; ok = $ok; reason = [string]$outcome.reason })
        if ($ok -and [string]$step.name -ceq 'verification') {
            # Read defensively: a port returning the ordinary {ok, reason} shape must not throw here.
            # DIRECT ASSIGNMENT, never @(...): the accessor preserves arrays with a unary-comma
            # -NoEnumerate return, so wrapping nests the whole list as ONE element and the message
            # renders "1 command: System.Object[]". The same trap is documented at the evidence join
            # above; it caught this line too.
            $verificationLabels = Get-ReviewAuthorityProperty -Object $outcome -Name 'command_labels'
        }
        if (-not $ok) {
            $failedStep = [string]$step.name
            $failureReason = [string]$outcome.reason
            # Read defensively: most ports return {ok, reason} only, and a missing property must not
            # throw under StrictMode.
            $failureDiagnosis = [string](Get-ReviewAuthorityProperty -Object $outcome -Name 'diagnosis')
            break
        }
    }

    $landed = ($null -eq $failedStep)
    $message = if ($landed) {
        # Maintainer ruling 2026-08-10. The starter plan means a project is never left unable to verify,
        # but it can now be verifying ONLY governance while its own tests never run - and being told
        # "verification passed". That is a degradation the consumer cannot SEE, the same class as a
        # silent demotion.
        #
        # The answer is honest reporting, not shadow-detection: name what actually ran, here, in the one
        # sentence that tells a human the check happened. A project reading "1 command: Specrew
        # governance validation" can act on it; a count alone, in reviewer-facing text, tells them
        # nothing. Rendered only when the verification step supplied labels, so a port that returns the
        # ordinary {ok, reason} shape produces no dangling fragment.
        $labels = @(@($verificationLabels) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
        $ran = if ($labels.Count -gt 0) {
            ' ({0} command{1}: {2})' -f $labels.Count, $(if ($labels.Count -eq 1) { '' } else { 's' }), ($labels -join ', ')
        }
        else { '' }
        ('Review is signed off. Any remaining minor findings are saved as follow-ups, and the final check ran on your files exactly as they were{0}.' -f $ran)
    }
    else {
        $whatFailed = switch ($failedStep) {
            'verification' { 'the final check on your files did not pass' }
            'residual-acceptance' { 'the remaining findings could not be recorded as accepted' }
            default { 'sign-off could not be completed' }
        }
        # T007 / FR-013. This sentence tells the human to "fix what the message above names", so the
        # message has to NAME something. A sealed verification failure used to arrive here as a machine
        # token and a locked door, which named nothing they could act on. The derived diagnosis is
        # rendered only when a step supplied one - a section that is always present, most often empty,
        # teaches the reader to skip exactly where the useful part appears.
        $diagnosisSection = if ([string]::IsNullOrWhiteSpace($failureDiagnosis)) { '' }
        else { ([Environment]::NewLine * 2) + 'What the check reported:' + [Environment]::NewLine + $failureDiagnosis + ([Environment]::NewLine * 2) }
        ('Stopping here did not finish: {0} ({1}). Nothing was signed off, and your review findings are unchanged. ' -f $whatFailed, $failureReason) +
        $diagnosisSection +
        'What to do next: fix what the message above names, then choose "stop here" again - the whole landing runs as one step, so there is nothing else for you to reconcile by hand.'
    }

    return [pscustomobject]@{
        landed      = $landed
        steps       = @($steps)
        failed_step = $failedStep
        reason      = $failureReason
        message     = $message
    }
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
    # Volume-derived, never OS-family: this dedupes candidate external target roots. 'distinct' keeps
    # two case-distinct candidates apart when the volume cannot be determined, so a viable root is
    # never silently discarded as a duplicate of another.
    $comparer = Get-ContinuousCoReviewPathComparer -Path $gitRoot -WhenUndetermined 'distinct'
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
        [string]$RequestedRoot,
        [AllowEmptyCollection()][string[]]$ExcludedPathPatterns = @()
    )
    $targetRoot = Resolve-ReviewCampaignTargetExternalRoot -RepoRoot $RepoRoot -RequestedRoot $RequestedRoot
    return New-GitReviewTargetPort -OriginRepo ((Resolve-Path -LiteralPath $RepoRoot).Path) -ExternalRoot $targetRoot -ExcludedPathPatterns $ExcludedPathPatterns
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
        # DRIFT-199-I001-007: the stamp separator must stay LOWERCASE-SAFE. Run ids become
        # filesystem path segments under the authority store, so the identifier rule's
        # lowercase-only, case-SENSITIVE match is a path-identity containment rule (the beta2
        # certify-round-3 class) and is never relaxed to accommodate a minter. The ISO-style
        # 'T' separator this format used to carry could not satisfy it, so every run without an
        # explicit --run-id died at identity resolution before a reviewer was invoked.
        $stamp = [DateTimeOffset]::UtcNow.ToString('yyyyMMdd-HHmmssfff')
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
        [AllowEmptyCollection()][string[]]$ExcludedPathPatterns = @(),
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900
    )
    # The one target-root policy is reused by live execution and reconciliation. It prefers the
    # short sibling root proven by T060, falls back to a writable platform root when the parent is
    # unavailable, supports an explicit external override, and fails with a domain-named reason.
    $target = New-ReviewCampaignTargetPort -RepoRoot $RepoRoot -RequestedRoot $TargetRoot -ExcludedPathPatterns $ExcludedPathPatterns
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
        [switch]$ReviewerHostExplicit,
        [string]$Model,
        [string]$GrantAuthorizationRef,
        [AllowEmptyCollection()][string[]]$DesignContextRefs = @(),
        [AllowEmptyCollection()][string[]]$ExcludedPathPatterns = @(),
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
    if ($ReviewerHostExplicit) {
        $hostDefinition = Get-ContinuousCoReviewProductionHarnessDefinition -HostName $ReviewerHost
        $hostCommandAvailable = $null -ne $hostDefinition -and
            -not [string]::IsNullOrWhiteSpace([string]$hostDefinition.command) -and
            $null -ne (Get-Command -Name ([string]$hostDefinition.command) -ErrorAction SilentlyContinue)
        $hostAuthorized = -not [string]::IsNullOrWhiteSpace($GrantAuthorizationRef)
        if ($null -eq $hostDefinition -or -not $hostCommandAvailable -or -not $hostAuthorized) {
            # T014: SAY WHICH OF THE THREE FAILED.
            #
            # One sentence used to cover three unrelated conditions - not catalogued, not installed, not
            # approved - so a MISSING APPROVAL read as "codex is not installed" and sent the consumer to
            # reinstall a tool that works perfectly. It fires on exactly the path a human answering a
            # pause takes, because that path supplies a host and may not supply an approval.
            #
            # Ordered from the condition the consumer can act on most directly. Approval is checked LAST
            # of the three but reported FIRST when it is the only failure, because it is the one they
            # can fix in the next keystroke.
            $failedCondition = if ($null -eq $hostDefinition) { 'not-cataloged' }
            elseif (-not $hostCommandAvailable) { 'not-installed' }
            else { 'not-approved' }
            $conditionSentence = switch ($failedCondition) {
                'not-cataloged' { "Specrew does not recognise the reviewer '$ReviewerHost'. Check the name, or list the reviewers this project can use with: specrew review --list-hosts" }
                'not-installed' { "The reviewer '$ReviewerHost' is set up for this project, but its command is not on this machine. Install it, or choose one that is available with: specrew review --list-hosts" }
                default { "This review round needs your approval before it can run. Approve it with: specrew review --live --approve-round" }
            }
            # THE TOKEN ITSELF MUST STOP LYING, not just the sentence beside it. For the two genuine
            # host conditions the host really is the problem, so the long-standing
            # `requested-host-not-available:` prefix is KEPT - other tooling classifies on it, and
            # renaming a true token to add detail would be churn. A MISSING APPROVAL is not a host
            # problem at all, so it gets its own token; that conflation is the whole defect.
            $reasonToken = if ($failedCondition -ceq 'not-approved') { 'review-round-not-approved' }
            else { "requested-host-not-available:{0}:{1}" -f $failedCondition, $ReviewerHost }
            return [pscustomobject][ordered]@{
                status = 'not-started'
                reason = $reasonToken
                # The human sentence rides BESIDE the machine token, never inside it - the token is
                # classified and counted, the sentence is read.
                reason_detail = $conditionSentence
                host_condition = $failedCondition
                invoked = $false; result = $null; campaign_id = $identity.campaign_id; run_id = $identity.run_id
                target_lineage = $identity.target_lineage; authority_mode = 'campaign'
                design_context = [string]$designContext.classification
                resolved_design_context = @($designContext.resolved_refs); unresolved_design_context = @()
                resolved_timeout_seconds = $TimeoutSeconds
                diagnostics = Get-ReviewProgressDiagnostics -Events @($progressCollector.events)
            }
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
    # FR-003, WIRED TO THE COMMAND. This check existed as Test-ReviewCampaignContinuationAuthorized and
    # nothing in production called it, so a round that ended in a pause did not stop the next one from
    # spending - the exact self-minted continuation ledger obs-6 recorded, where one grant was stretched
    # across seven rounds. It sits BEFORE grant persistence, harness selection, reservation and snapshot,
    # so a refusal costs nothing.
    #
    # The digest is deliberately NOT consulted here. A moved tree SUPERSEDES a pause for the purpose of
    # quieting the stop surface (Test-ReviewCampaignPendingPauseQuiet), but it does not authorize a
    # spend: fixing the code is not answering the question. Only the human's numbered reply is.
    $latestPause = $null
    try { $latestPause = Get-ReviewCampaignLatestPause -StoreRoot $StoreRoot -CampaignId $identity.campaign_id }
    catch { $latestPause = $null }

    # A PAUSE THAT COULD NOT BE WRITTEN MUST NOT READ AS "NO PAUSE".
    #
    # Recording the pause is deliberately forgiving - Add-ReviewCampaignRoundPause swallows write
    # errors and the round still returns its terminal result, because a pause that cannot be recorded
    # must not destroy a review the human already paid for. That tolerance was HARMLESS while nothing
    # read pause facts. This guard reads them, so the same tolerance became an open door: a failed
    # write leaves no pause, the guard sees nothing to enforce, and the next command reserves and
    # invokes another reviewer with no numbered answer given - the unbounded loop the feature exists to
    # stop.
    #
    # ADDING A CONSUMER CHANGES THE RISK OF AN EXISTING TOLERANCE. The fail-soft was not wrong before
    # and is not wrong now; what changed is that something now depends on its output.
    #
    # So absence is checked against the store's own evidence rather than trusted: if the newest INVOKED
    # round has no pause fact, the pause is MISSING rather than absent, and this fails closed. The
    # invoked filter is FR-014's, so a pre-invocation failure - which correctly publishes a run record
    # without ever pausing - cannot trip it.
    if ($null -eq $latestPause) {
        $newestInvoked = $null
        try {
            $newestInvoked = @(Get-ReviewAuthorityCampaignRunResults -StoreRoot $StoreRoot -CampaignId $identity.campaign_id |
                    Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'runtime_outcome') -notin @('preflight-failed', 'claim-contended', 'launch-failed') } |
                    Sort-Object -Property { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'started_at') }) | Select-Object -Last 1
        }
        catch { $newestInvoked = $null }
        if ($null -ne $newestInvoked) {
            return [pscustomobject][ordered]@{
                status = 'paused'; reason = 'review-round-paused:pause-record-missing-for-completed-round'
                invoked = $false; result = $null
                campaign_id = $identity.campaign_id; run_id = $identity.run_id; target_lineage = $identity.target_lineage
                store_root = [IO.Path]::GetFullPath($StoreRoot); authority_mode = 'campaign'
                design_context = [string]$designContext.classification
                resolved_design_context = @($designContext.resolved_refs); unresolved_design_context = @()
                pause = $null; pause_decision = $null
                pause_run_id = [string](Get-ReviewAuthorityProperty -Object $newestInvoked -Name 'run_id')
                pause_surface = @(
                    'A review round finished, but Specrew could not save the record of what it found.',
                    '',
                    'Because that record is missing, Specrew cannot tell whether you have answered it, so it will not start another review.',
                    'This protects you from paying for rounds nobody asked for.',
                    '',
                    'What to do: check that Specrew can write to its own folder under .specrew/review/authority, then run the review again.'
                )
                continuation_authorized = $false
                continuation_reason = 'pause-record-missing-for-completed-round'
                diagnostics = Get-ReviewProgressDiagnostics -Events @($progressCollector.events)
            }
        }
    }
    if ($null -ne $latestPause) {
        $pauseDecisions = @()
        if ($null -ne $latestPause.decision) { $pauseDecisions = @($latestPause.decision) }
        $roundsSinceDecision = 0
        if ($null -ne $latestPause.decision) {
            # WHAT THIS COUNTER MEASURES, stated because the last counter that left it implicit took a
            # day to pin (T008's naming convention): it is INVOKED ROUNDS SINCE THE HUMAN'S ANSWER. It
            # is NOT runs, and it is NOT allowance slots.
            #
            # The distinction is FR-014's own, and this counter broke it hours after the requirement was
            # honoured elsewhere. A pre-invocation failure PUBLISHES a run record - correctly, that is
            # FR-014 working - so counting run records made a round that never launched a reviewer
            # consume the answer, while the F4 disclosure on the very same failure told the human their
            # authorization was still available. Same requirement, two counters, opposite behaviour.
            #
            # The filter is FR-014's existing discriminator, reused verbatim rather than re-derived, so
            # the two cannot drift apart: a run whose runtime_outcome is preflight-failed,
            # claim-contended, or launch-failed never reached a reviewer and therefore never spent the
            # round the human authorized.
            $decidedAt = [string](Get-ReviewAuthorityProperty -Object $latestPause.decision -Name 'observed_at')
            if (-not [string]::IsNullOrWhiteSpace($decidedAt)) {
                try {
                    $roundsSinceDecision = @(Get-ReviewAuthorityCampaignRunResults -StoreRoot $StoreRoot -CampaignId $identity.campaign_id |
                            Where-Object {
                                $startedAt = [string](Get-ReviewAuthorityProperty -Object $_ -Name 'started_at')
                                -not [string]::IsNullOrWhiteSpace($startedAt) -and $startedAt -gt $decidedAt -and
                                [string](Get-ReviewAuthorityProperty -Object $_ -Name 'runtime_outcome') -notin @('preflight-failed', 'claim-contended', 'launch-failed')
                            }).Count
                }
                catch { $roundsSinceDecision = 0 }
            }
        }
        $continuation = Test-ReviewCampaignContinuationAuthorized -PendingPause $latestPause.pause `
            -PauseDecisions $pauseDecisions -RoundsSinceDecision $roundsSinceDecision
        if (-not $continuation.authorized) {
            # The findings come from the RESULT, not from the pause fact - the fact stores counts only,
            # which is exactly why the resumed surface had nothing to show. Read defensively and
            # unwrapped with a direct assignment: the accessor returns collections with -NoEnumerate.
            # The navigator is NOT in _load.ps1's set, so it must be pulled in the same lazy way
            # Add-ReviewCampaignRoundPause already does for its sibling renderer. Missed here because
            # every fixture dot-sources the navigator in BeforeAll - so the suite was green while the
            # shipped path threw "Format-ReviewCampaignOutstandingPause is not recognized" on the first
            # real paused invocation. A fixture can only prove the shape it invents, and it invented a
            # load order production does not have.
            if (-not (Get-Command -Name 'Format-ReviewCampaignOutstandingPause' -ErrorAction SilentlyContinue)) {
                $navigatorModule = Join-Path $PSScriptRoot 'continuous-co-review-navigator.ps1'
                if (Test-Path -LiteralPath $navigatorModule -PathType Leaf) { try { . $navigatorModule } catch { $null = $_ } }
            }
            $pausedRoundFindings = $null
            try {
                $pausedResult = Get-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $identity.campaign_id `
                    -RunId ([string]$latestPause.run_id) -Stage result
                if ($null -ne $pausedResult) { $pausedRoundFindings = Get-ReviewAuthorityProperty -Object $pausedResult -Name 'findings' }
            }
            catch { $pausedRoundFindings = $null }
            return [pscustomobject][ordered]@{
                status = 'paused'; reason = ('review-round-paused:' + [string]$continuation.reason)
                invoked = $false; result = $null
                campaign_id = $identity.campaign_id; run_id = $identity.run_id; target_lineage = $identity.target_lineage
                store_root = [IO.Path]::GetFullPath($StoreRoot); authority_mode = 'campaign'
                design_context = [string]$designContext.classification
                resolved_design_context = @($designContext.resolved_refs); unresolved_design_context = @()
                # The surface the human must answer, carried OUT so the CLI can re-render it verbatim
                # rather than reconstructing a decision from a status string.
                pause = $latestPause.pause
                pause_decision = $latestPause.decision
                pause_run_id = [string]$latestPause.run_id
                pause_surface = @(Format-ReviewCampaignOutstandingPause `
                        -ProjectName $(if (-not [string]::IsNullOrWhiteSpace($FeatureId)) { $FeatureId } else { Split-Path -Leaf $root }) `
                        -Fact $latestPause.pause -Findings $pausedRoundFindings)
                continuation_authorized = $false
                continuation_reason = [string]$continuation.reason
                diagnostics = Get-ReviewProgressDiagnostics -Events @($progressCollector.events)
            }
        }
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
    if ($null -eq $Ports) {
        $Ports = New-ReviewCampaignProductionPorts -RepoRoot $root -ReviewerHost $ReviewerHost -Model $Model -TargetRoot $TargetRoot `
            -ExcludedPathPatterns $ExcludedPathPatterns -TimeoutSeconds $TimeoutSeconds
    }
    $run = Invoke-ReviewCampaignRun -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $identity.campaign_id -RunId $identity.run_id `
        -ReservationId $identity.reservation_id -TargetLineage $identity.target_lineage -TargetPort $Ports.target -HarnessPort $Ports.harness `
        -RuntimePort $Ports.runtime -VerificationPort $Ports.verification -ClockPort $Ports.clock -PromptPath ([string]$Ports.prompt_path) -TimeoutSeconds $TimeoutSeconds `
        -ReviewScope $ReviewScope -DesignContextEmpty:([bool]$designContext.design_context_empty) `
        -ProgressSink $progressCollector.sink -AuthorityConfigPath $AuthorityConfigPath
    # THIS PROJECTION IS WHERE TWO CAPABILITIES DIED, and both were fully built on either side of it.
    # Invoke-ReviewCampaignRun returns `pause` on a terminal round and slot_restored/_note on a
    # pre-invocation failure; specrew-review.ps1 already contains the code to render the restored-slot
    # note. The explicit field list in between silently dropped all three, so the decision surface never
    # reached a consumer and F4's disclosure was fixed everywhere except the one place it travels.
    # Same shape as the demoted-mark drop in the result ingestor: a closed field list that nobody
    # updated when a field was added upstream.
    return [pscustomobject][ordered]@{
        status = $run.status; reason = $run.reason; invoked = $run.invoked; result = $run.result
        result_path = $(if ($run.PSObject.Properties['result_path']) { $run.result_path } else { $null })
        report_path = $(if ($run.PSObject.Properties['report_path']) { $run.report_path } else { $null })
        campaign_id = $identity.campaign_id; run_id = $identity.run_id; target_lineage = $identity.target_lineage
        store_root = [IO.Path]::GetFullPath($StoreRoot); authority_mode = 'campaign'
        design_context = [string]$designContext.classification; resolved_design_context = @($designContext.resolved_refs)
        unresolved_design_context = @()
        pause = (Get-ReviewAuthorityProperty -Object $run -Name 'pause')
        slot_restored = [bool](Get-ReviewAuthorityProperty -Object $run -Name 'slot_restored')
        slot_restored_note = [string](Get-ReviewAuthorityProperty -Object $run -Name 'slot_restored_note')
        continuation_authorized = $true
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
                # slot_restored/_note are carried, not dropped. A result narrowed at a boundary is where
                # an explanation dies - the verification diagnosis was lost at exactly this shape, and
                # `reason` is deliberately untouched so the exact-equality fixtures still hold.
                return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path; report_path = $failed.report_path; slot_restored = [bool](Get-ReviewAuthorityProperty -Object $failed -Name 'slot_restored'); slot_restored_note = [string](Get-ReviewAuthorityProperty -Object $failed -Name 'slot_restored_note') }
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
                if (-not [bool]$protection.ok) { $reason += ':' + [string]$protection.reason }
                $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
                $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends @() -Reason $reason -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome preflight-failed
                Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage failed -Message $reason -ProcessTreeLive $false -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
                # slot_restored/_note are carried, not dropped. A result narrowed at a boundary is where
                # an explanation dies - the verification diagnosis was lost at exactly this shape, and
                # `reason` is deliberately untouched so the exact-equality fixtures still hold.
                return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path; report_path = $failed.report_path; slot_restored = [bool](Get-ReviewAuthorityProperty -Object $failed -Name 'slot_restored'); slot_restored_note = [string](Get-ReviewAuthorityProperty -Object $failed -Name 'slot_restored_note') }
            }
        }
        catch {
            $reason = 'preflight-failed:' + $_.Exception.Message
            $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
            $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $placeholderDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends @() -Reason $reason -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome preflight-failed
            Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage failed -Message $reason -ProcessTreeLive $false -ElapsedMilliseconds $progressWatch.ElapsedMilliseconds -TimeoutSeconds $TimeoutSeconds
            # Carried here too. These returns are indented differently from their siblings, which is
            # exactly why a bulk edit missed them and the source guard caught it.
            return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path; report_path = $failed.report_path; slot_restored = [bool](Get-ReviewAuthorityProperty -Object $failed -Name 'slot_restored'); slot_restored_note = [string](Get-ReviewAuthorityProperty -Object $failed -Name 'slot_restored_note') }
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
            # A contended claim is a PRE-INVOCATION failure like the others: -Spends @() above means the
            # release permits, so the slot comes back and the human owes nothing. Its status reads
            # 'not-started' rather than 'failed', which is exactly why the first source guard - keyed on
            # the status literal - could not see this line.
            return [pscustomobject]@{ status = 'not-started'; reason = ('claim-not-acquired:' + $claim.reason); invoked = $false; result = $failed.result; result_path = $failed.result_path; report_path = $failed.report_path; slot_restored = [bool](Get-ReviewAuthorityProperty -Object $failed -Name 'slot_restored'); slot_restored_note = [string](Get-ReviewAuthorityProperty -Object $failed -Name 'slot_restored_note') }
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
            # Carried here too. These returns are indented differently from their siblings, which is
            # exactly why a bulk edit missed them and the source guard caught it.
            return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path; report_path = $failed.report_path; slot_restored = [bool](Get-ReviewAuthorityProperty -Object $failed -Name 'slot_restored'); slot_restored_note = [string](Get-ReviewAuthorityProperty -Object $failed -Name 'slot_restored_note') }
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
            # FR-001: the round ENDS here. Record what it found and what the campaign has spent, then
            # hand the decision to the human. Fail-soft: a pause that cannot be recorded must not
            # destroy a published review result, so the round still returns its terminal outcome.
            $roundPause = $null
            try {
                $roundPause = Add-ReviewCampaignRoundPause -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId `
                    -TargetDigest $targetDigest -ProjectName $FeatureId -Result $ingress.result `
                    -ObservedAt (Read-ReviewClockUtc -ClockPort $ClockPort) -RepoRoot $RepoRoot
            }
            catch { $roundPause = $null }
            return [pscustomobject]@{ status = 'terminal'; reason = $ingress.reason; invoked = $true; result = $ingress.result; result_path = $ingress.result_path; report_path = $ingress.report_path; pause = $roundPause }
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
