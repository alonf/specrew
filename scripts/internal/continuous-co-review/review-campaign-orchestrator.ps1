$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 / T048: synchronous application service over target/harness/runtime/store/clock ports.
# One call performs at most one external invocation; it never schedules background work or retries a
# provider invisibly. Fixture ports are executable foundation proof, not production-support claims.

if (-not (Get-Command -Name 'Invoke-ReviewResultIngress' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-result-ingestor.ps1') }
if (-not (Get-Command -Name 'New-GitReviewTargetSnapshot' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-target-port.ps1') }
if (-not (Get-Command -Name 'Get-ContinuousCoReviewAuthorityDecision' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-authority-cutover.ps1') }

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
        [AllowNull()]$ValidatedFindingCount
    )
    if ($null -eq $Sink) { return }
    $event = [pscustomobject][ordered]@{
        schema_version = '1.0'; campaign_id = $CampaignId; run_id = $RunId; stage = $Stage
        observed_at = Read-ReviewClockUtc -ClockPort $ClockPort; message = $Message
        process_tree_live = $ProcessTreeLive; output_activity = $OutputActivity
        validated_finding_count = $ValidatedFindingCount; authority = $false
    }
    & $Sink $event
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
    $disposeCommand = Get-Command -Name 'Remove-GitReviewTargetSnapshot' -CommandType Function
    $prepare = { param($runId) & $prepareCommand -OriginRepo $OriginRepo -RunId $runId -ExternalRoot $ExternalRoot }.GetNewClosure()
    $currentness = { param($snapshot) & $currentnessCommand -Snapshot $snapshot }.GetNewClosure()
    $integrity = { param($snapshot) & $integrityCommand -Snapshot $snapshot }.GetNewClosure()
    $dispose = { param($snapshot) & $disposeCommand -Snapshot $snapshot }.GetNewClosure()
    return [pscustomobject]@{ kind = 'git'; prepare = $prepare; currentness = $currentness; integrity = $integrity; dispose = $dispose }
}

function New-ReviewFixtureTargetPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SnapshotPath,
        [string]$TargetDigest = 'fixture-digest',
        [ValidateSet('current', 'snapshot-moved', 'unknown')][string]$Currentness = 'current',
        [bool]$IntegrityPass = $true
    )
    $suppressionEnvironment = Get-ReviewTargetSuppressionEnvironment
    $prepare = { param($runId) [pscustomobject]@{ schema_version = '1.0'; target_kind = 'fixture'; run_id = $runId; target_digest = $TargetDigest; snapshot_path = $SnapshotPath; workspace_root = $SnapshotPath; origin_repo = $null; suppression_environment = $suppressionEnvironment } }.GetNewClosure()
    $checkCurrentness = { param($snapshot) [pscustomobject]@{ classification = $Currentness; exact = ($Currentness -ceq 'current'); reason = 'fixture-currentness' } }.GetNewClosure()
    $checkIntegrity = { param($snapshot) [pscustomobject]@{ intact = $IntegrityPass; classification = $(if ($IntegrityPass) { 'intact' } else { 'snapshot-tampered' }); changed_paths = @() } }.GetNewClosure()
    $dispose = { param($snapshot) [pscustomobject]@{ removed = $true; failure_reason = $null } }
    return [pscustomobject]@{ kind = 'fixture'; prepare = $prepare; currentness = $checkCurrentness; integrity = $checkIntegrity; dispose = $dispose }
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
        [string]$FailureReason
    )
    $preflight = { param($invocation) [pscustomobject]@{ ok = $PreflightPass; reason = $(if ($PreflightPass) { 'fixture-runtime-ready' } else { 'fixture-runtime-unavailable' }) } }.GetNewClosure()
    $invoke = {
        param($harness, $invocation, $onStarted, $environment)
        if ($Outcome -ceq 'launch-failed') { return [pscustomobject]@{ runtime_outcome = 'launch-failed'; termination_verified = $true; containment = 'unknown'; failure_reason = $(if ($FailureReason) { $FailureReason } else { 'fixture launch failed' }); process_tree_live = $false; output_activity = $false } }
        & $onStarted
        $harnessResult = & $harness.invoke $invocation $environment
        return [pscustomobject]@{
            runtime_outcome = $Outcome; termination_verified = $TerminationVerified; containment = $Containment
            failure_reason = $FailureReason; process_tree_live = (-not $TerminationVerified); output_activity = [bool]$harnessResult.output_activity
        }
    }.GetNewClosure()
    return [pscustomobject]@{ id = 'fixture-runtime'; preflight = $preflight; invoke = $invoke }
}

function Complete-ReviewPreInvocationFailure {
    param(
        [string]$StoreRoot, [string]$StagingRoot, [string]$CampaignId, [string]$RunId, [string]$TargetDigest, [string]$HarnessId,
        $Reservation, [object[]]$Spends, [string]$Reason, [string]$ObservedAt, [string]$StartedAt, [long]$DurationMs,
        [ValidateSet('preflight-failed', 'launch-failed')][string]$RuntimeOutcome, [ValidateSet('verified', 'unknown')][string]$Containment = 'unknown'
    )
    if ($null -ne $Reservation) {
        $releaseDecision = Resolve-ReviewCampaignReleaseDecision -Reservation $Reservation -Reason $Reason -ObservedAt $ObservedAt -Spends $Spends
        if ($releaseDecision.permitted) { Write-ReviewCampaignReleaseFact -StoreRoot $StoreRoot -Fact $releaseDecision.fact | Out-Null }
    }
    return Invoke-ReviewResultIngress -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $TargetDigest -HarnessId $HarnessId -RuntimeOutcome $RuntimeOutcome -Invoked $false -TerminationVerified $true -Containment $Containment -Currentness unknown -StartedAt $StartedAt -EndedAt $ObservedAt -DurationMs $DurationMs -FailureReason $Reason
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
        [Parameter(Mandatory)]$ClockPort,
        [Parameter(Mandatory)][string]$PromptPath,
        [string]$ReviewScope = 'Review the complete frozen target and return the versioned candidate JSON contract.',
        [ValidateRange(1, 86400)][int]$TimeoutSeconds = 900,
        [scriptblock]$ProgressSink,
        [string]$AuthorityConfigPath
    )
    $authority = Get-ContinuousCoReviewAuthorityDecision -ConfigPath $AuthorityConfigPath
    if (-not $authority.campaign_authority_enabled) { return [pscustomobject]@{ status = 'suppressed'; reason = ('campaign-authority-disabled:' + $authority.reason); invoked = $false; result = $null } }
    $attemptStartedAt = Read-ReviewClockUtc -ClockPort $ClockPort
    $attemptMono = Read-ReviewClockMonotonic -ClockPort $ClockPort
    Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage 'requested' -Message 'run requested'

    $placeholderDigest = 'pending-target'
    Write-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage requested -Fact (New-ReviewRunStateFact -CampaignId $CampaignId -RunId $RunId -TargetDigest $placeholderDigest -HarnessId ([string]$HarnessPort.id) -State requested) | Out-Null
    $reservationResult = Request-ReviewCampaignReservationFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -ReservationId $ReservationId -ObservedAt (Read-ReviewClockUtc -ClockPort $ClockPort)
    if (-not $reservationResult.acquired) { return [pscustomobject]@{ status = 'not-started'; reason = $reservationResult.reason; invoked = $false; result = $null } }
    $reservation = $reservationResult.fact
    Write-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage reserved -Fact (New-ReviewRunStateFact -CampaignId $CampaignId -RunId $RunId -TargetDigest $placeholderDigest -HarnessId ([string]$HarnessPort.id) -State reserved) | Out-Null

    $snapshot = $null; $claimHeld = $false
    try {
        try {
            $snapshot = & $TargetPort.prepare $RunId
            $targetDigest = [string]$snapshot.target_digest
            $paths = Initialize-ReviewRunStaging -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId
            $deadline = ([DateTimeOffset]::Parse((Read-ReviewClockUtc -ClockPort $ClockPort))).AddSeconds($TimeoutSeconds).ToString('o')
            $invocation = [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $CampaignId; run_id = $RunId; target_digest = $targetDigest
                snapshot_path = [string]$snapshot.snapshot_path; review_scope = $ReviewScope; prompt_path = [IO.Path]::GetFullPath($PromptPath)
                candidate_result_path = $paths.candidate_result_path; candidate_report_path = $paths.candidate_report_path; deadline = $deadline
            }
            $contract = Test-ReviewAuthorityContractObject -ContractName ReviewInvocation -InputObject $invocation -ExpectedCampaignId $CampaignId -ExpectedRunId $RunId -ExpectedTargetDigest $targetDigest
            $targetReady = -not [string]::IsNullOrWhiteSpace($targetDigest) -and [IO.Directory]::Exists([string]$snapshot.snapshot_path) -and [IO.File]::Exists([string]$invocation.prompt_path)
            $harnessReady = & $HarnessPort.preflight $invocation
            $runtimeReady = & $RuntimePort.preflight $invocation
            $preflight = @{ target = $targetReady; store = $true; contract = [bool]$contract.valid; containment = $targetReady; harness = [bool]$harnessReady.ok }
            if (-not $runtimeReady.ok) { $preflight.harness = $false }
            if (@($preflight.Values | Where-Object { -not [bool]$_ }).Count -gt 0) {
                $reason = 'preflight-failed:' + (@($preflight.Keys | Where-Object { -not [bool]$preflight[$_] } | Sort-Object) -join ',')
                $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
                $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends @() -Reason $reason -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome preflight-failed
                return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path }
            }
        }
        catch {
            $reason = 'preflight-failed:' + $_.Exception.Message
            $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
            $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $placeholderDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends @() -Reason $reason -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome preflight-failed
            return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path }
        }

        Write-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage preflighted -Fact (New-ReviewRunStateFact -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -State preflighted) | Out-Null
        $claim = Request-ReviewAuthorityClaim -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -TargetLineage $TargetLineage -ObservedAt (Read-ReviewClockUtc -ClockPort $ClockPort)
        if (-not $claim.acquired) {
            $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
            $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends @() -Reason ('claim-not-acquired:' + $claim.reason) -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome preflight-failed -Containment verified
            return [pscustomobject]@{ status = 'not-started'; reason = ('claim-not-acquired:' + $claim.reason); invoked = $false; result = $failed.result; result_path = $failed.result_path }
        }
        $claimHeld = $true
        Write-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage claimed -Fact (New-ReviewRunStateFact -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -State claimed) | Out-Null
        Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage 'preflighted' -Message 'target, store, contract, containment, harness, and runtime preflight passed'

        $readClockCommand = Get-Command -Name 'Read-ReviewClockUtc' -CommandType Function
        $getFactsCommand = Get-Command -Name 'Get-ReviewAuthorityCampaignFacts' -CommandType Function
        $resolveSpendCommand = Get-Command -Name 'Resolve-ReviewCampaignSpendDecision' -CommandType Function
        $writeSpendCommand = Get-Command -Name 'Write-ReviewCampaignSpendFact' -CommandType Function
        $writeRunCommand = Get-Command -Name 'Write-ReviewRunAuthorityFact' -CommandType Function
        $newRunFactCommand = Get-Command -Name 'New-ReviewRunStateFact' -CommandType Function
        $onStarted = {
            $startedAt = & $readClockCommand -ClockPort $ClockPort
            $existingSpends = @(& $getFactsCommand -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind spend)
            $existingReleases = @(& $getFactsCommand -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind releases)
            $spendDecision = & $resolveSpendCommand -Reservation $reservation -InvocationStartedAt $startedAt -Preflight $preflight -Spends $existingSpends -Releases $existingReleases
            if (-not $spendDecision.permitted) { throw ('review-invocation-spend-refused:' + $spendDecision.reason) }
            & $writeSpendCommand -StoreRoot $StoreRoot -Fact $spendDecision.fact | Out-Null
            & $writeRunCommand -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage invoked -Fact (& $newRunFactCommand -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -State invoked) | Out-Null
        }.GetNewClosure()

        try { $runtimeResult = & $RuntimePort.invoke $HarnessPort $invocation $onStarted $snapshot.suppression_environment }
        catch { $runtimeResult = [pscustomobject]@{ runtime_outcome = 'abandoned'; termination_verified = $false; containment = 'unknown'; failure_reason = ('runtime-adapter-failed:' + $_.Exception.Message); process_tree_live = $null; output_activity = $null } }
        $spends = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind spend | Where-Object { [string]$_.run_id -ceq $RunId })
        $invoked = $spends.Count -gt 0
        if (-not $invoked) {
            $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort; $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
            $reason = if ($runtimeResult.failure_reason) { [string]$runtimeResult.failure_reason } else { 'launch failed before invocation' }
            $failed = Complete-ReviewPreInvocationFailure -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -Reservation $reservation -Spends $spends -Reason $reason -ObservedAt $endedAt -StartedAt $attemptStartedAt -DurationMs $duration -RuntimeOutcome launch-failed -Containment unknown
            Complete-ReviewAuthorityClaim -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -TargetLineage $TargetLineage -Disposition abandoned -ObservedAt $endedAt | Out-Null
            $claimHeld = $false
            return [pscustomobject]@{ status = 'failed'; reason = $reason; invoked = $false; result = $failed.result; result_path = $failed.result_path }
        }

        Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage 'terminalizing' -Message 'runtime returned; validating target and candidate' -ProcessTreeLive $runtimeResult.process_tree_live -OutputActivity $runtimeResult.output_activity
        $containment = [string]$runtimeResult.containment; $runtimeOutcome = [string]$runtimeResult.runtime_outcome
        try { $integrity = & $TargetPort.integrity $snapshot } catch { $integrity = [pscustomobject]@{ intact = $false; classification = 'integrity-check-failed' } }
        if (-not $integrity.intact) { $containment = 'violated'; $runtimeOutcome = 'containment-violated' }
        try { $currentness = & $TargetPort.currentness $snapshot } catch { $currentness = [pscustomobject]@{ classification = 'unknown'; exact = $false; reason = 'currentness-check-failed' } }
        $endedAt = Read-ReviewClockUtc -ClockPort $ClockPort
        $duration = [Math]::Max(0, (Read-ReviewClockMonotonic -ClockPort $ClockPort) - $attemptMono)
        $startedAt = ConvertTo-ReviewObservedTimestampString -Value $spends[0].invocation_started_at
        $ingress = Invoke-ReviewResultIngress -StoreRoot $StoreRoot -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId -TargetDigest $targetDigest -HarnessId ([string]$HarnessPort.id) -RuntimeOutcome $runtimeOutcome -Invoked $true -TerminationVerified ([bool]$runtimeResult.termination_verified) -Containment $containment -Currentness ([string]$currentness.classification) -StartedAt $startedAt -EndedAt $endedAt -DurationMs $duration -FailureReason ([string]$runtimeResult.failure_reason)
        if ($ingress.published) {
            Complete-ReviewAuthorityClaim -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -TargetLineage $TargetLineage -Disposition released -ObservedAt (Read-ReviewClockUtc -ClockPort $ClockPort) | Out-Null
            $claimHeld = $false
            $findingCount = if ($ingress.candidate_category -ceq 'valid') { @($ingress.result.findings).Count } else { $null }
            Write-ReviewOrchestrationProgress -Sink $ProgressSink -ClockPort $ClockPort -CampaignId $CampaignId -RunId $RunId -Stage 'terminal' -Message $ingress.reason -ProcessTreeLive $false -OutputActivity $runtimeResult.output_activity -ValidatedFindingCount $findingCount
            return [pscustomobject]@{ status = 'terminal'; reason = $ingress.reason; invoked = $true; result = $ingress.result; result_path = $ingress.result_path; report_path = $ingress.report_path }
        }
        return [pscustomobject]@{ status = 'awaiting-termination-verification'; reason = $ingress.reason; invoked = $true; result = $null; result_path = $null }
    }
    finally {
        if ($null -ne $snapshot) { try { $null = & $TargetPort.dispose $snapshot } catch { $null = $_ } }
    }
}
