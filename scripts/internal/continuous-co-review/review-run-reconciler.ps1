$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Restart recovery is an application operation, not a pure plan. The controller persists one
# closed, immutable recovery receipt after OS containment is verified and before the spend fact is
# published. A later controller process can therefore prove the original tree dead, publish the
# spent/abandoned terminal envelope, retire the claim, and only then remove the frozen target.

if (-not (Get-Command -Name 'Get-ContinuousCoReviewPathCaseSensitive' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'path-identity.ps1') }
if (-not (Get-Command -Name 'Get-ReviewRunReconciliationPlan' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-authority-store.ps1') }
if (-not (Get-Command -Name 'Invoke-ReviewResultIngress' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-result-ingestor.ps1') }

function New-ReviewRunRecoveryFact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$TargetDigest,
        [Parameter(Mandatory)][string]$HarnessId,
        [Parameter(Mandatory)][string]$TargetLineage,
        [Parameter(Mandatory)]$RuntimeReceipt,
        [Parameter(Mandatory)]$Snapshot,
        [Parameter(Mandatory)][string]$StagingRoot,
        [Parameter(Mandatory)][string]$InvocationStartedAt,
        [Parameter(Mandatory)][long]$InvocationStartedMonotonicMs
    )
    foreach ($name in @('runtime_id', 'platform', 'containment_kind', 'containment_id', 'process_id', 'process_started_at')) {
        if ($null -eq $RuntimeReceipt.PSObject.Properties[$name]) { throw "review-recovery-runtime-receipt-missing:$name" }
    }
    $notApplicable = 'not-applicable'
    $targetKind = [string]$Snapshot.target_kind
    $bindingNames = @(
        'verification_plan_present', 'verification_plan_sha256',
        'machinery_paths', 'machinery_paths_sha256',
        'excluded_path_patterns', 'excluded_path_patterns_sha256'
    )
    if ($targetKind -ceq 'code') {
        foreach ($name in $bindingNames) {
            if ($null -eq $Snapshot.PSObject.Properties[$name]) { throw "review-recovery-snapshot-binding-missing:$name" }
        }
    }
    $verificationPlanPresent = $Snapshot.PSObject.Properties['verification_plan_present'] -and [bool]$Snapshot.verification_plan_present
    $verificationPlanSha256 = if ($Snapshot.PSObject.Properties['verification_plan_sha256'] -and -not [string]::IsNullOrWhiteSpace([string]$Snapshot.verification_plan_sha256)) { [string]$Snapshot.verification_plan_sha256 } else { $notApplicable }
    $machineryPaths = if ($Snapshot.PSObject.Properties['machinery_paths']) { Get-ContinuousCoReviewOrdinalUniquePath -Path @($Snapshot.machinery_paths | ForEach-Object { ([string]$_ -replace '\\', '/').Trim('/') }) } else { @() }
    $machineryPathsSha256 = if ($Snapshot.PSObject.Properties['machinery_paths_sha256'] -and -not [string]::IsNullOrWhiteSpace([string]$Snapshot.machinery_paths_sha256)) { [string]$Snapshot.machinery_paths_sha256 } else { $notApplicable }
    $excludedPathPatterns = if ($Snapshot.PSObject.Properties['excluded_path_patterns']) { Get-ContinuousCoReviewOrdinalUniquePath -Path @($Snapshot.excluded_path_patterns | ForEach-Object { ([string]$_ -replace '\\', '/').Trim() }) } else { @() }
    $excludedPathPatternsSha256 = if ($Snapshot.PSObject.Properties['excluded_path_patterns_sha256'] -and -not [string]::IsNullOrWhiteSpace([string]$Snapshot.excluded_path_patterns_sha256)) { [string]$Snapshot.excluded_path_patterns_sha256 } else { $notApplicable }
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'recovery'; campaign_id = $CampaignId; run_id = $RunId
        target_digest = $TargetDigest; harness_id = $HarnessId; target_lineage = $TargetLineage
        runtime_id = [string]$RuntimeReceipt.runtime_id; platform = [string]$RuntimeReceipt.platform
        containment_kind = [string]$RuntimeReceipt.containment_kind; containment_id = [string]$RuntimeReceipt.containment_id
        process_id = [int]$RuntimeReceipt.process_id; process_started_at = [string]$RuntimeReceipt.process_started_at
        invocation_started_at = $InvocationStartedAt; invocation_started_monotonic_ms = $InvocationStartedMonotonicMs
        target_kind = $targetKind; snapshot_path = [IO.Path]::GetFullPath([string]$Snapshot.snapshot_path)
        workspace_root = [IO.Path]::GetFullPath([string]$Snapshot.workspace_root)
        origin_repo = $(if ($Snapshot.PSObject.Properties['origin_repo'] -and -not [string]::IsNullOrWhiteSpace([string]$Snapshot.origin_repo)) { [IO.Path]::GetFullPath([string]$Snapshot.origin_repo) } else { $notApplicable })
        git_root = $(if ($Snapshot.PSObject.Properties['git_root'] -and -not [string]::IsNullOrWhiteSpace([string]$Snapshot.git_root)) { [IO.Path]::GetFullPath([string]$Snapshot.git_root) } else { $notApplicable })
        origin_head_before = $(if ($Snapshot.PSObject.Properties['origin_head_before'] -and -not [string]::IsNullOrWhiteSpace([string]$Snapshot.origin_head_before)) { [string]$Snapshot.origin_head_before } else { $notApplicable })
        verification_plan_present = [bool]$verificationPlanPresent; verification_plan_sha256 = $verificationPlanSha256
        machinery_paths = @($machineryPaths); machinery_paths_sha256 = $machineryPathsSha256
        excluded_path_patterns = @($excludedPathPatterns); excluded_path_patterns_sha256 = $excludedPathPatternsSha256
        staging_root = [IO.Path]::GetFullPath($StagingRoot)
    }
    $validation = Test-ReviewAuthorityContractObject -ContractName RecoveryFact -InputObject $fact -ExpectedCampaignId $CampaignId -ExpectedRunId $RunId -ExpectedTargetDigest $TargetDigest
    if (-not $validation.valid) { throw ('review-recovery-fact-invalid:' + ($validation.errors -join ',')) }
    return $fact
}

function Get-ReviewRecoverySnapshot {
    param([Parameter(Mandatory)]$Fact)
    $names = @($Fact.PSObject.Properties.Name)
    $historicalBindings = @(
        'verification_plan_present', 'verification_plan_sha256',
        'machinery_paths', 'machinery_paths_sha256'
    )
    $currentBindings = @(
        'verification_plan_present', 'verification_plan_sha256',
        'machinery_paths', 'machinery_paths_sha256',
        'excluded_path_patterns', 'excluded_path_patterns_sha256'
    )
    $historicalBindingComplete = @($historicalBindings | Where-Object { $names -notcontains $_ }).Count -eq 0
    $currentBindingComplete = @($currentBindings | Where-Object { $names -notcontains $_ }).Count -eq 0
    $bindingShape = if ($currentBindingComplete) { 'current-v1' } elseif ($historicalBindingComplete) { 'historical-v1' } else { 'unbound' }
    $verificationPlanSha256 = if ($historicalBindingComplete -and [string]$Fact.verification_plan_sha256 -cne 'not-applicable') { [string]$Fact.verification_plan_sha256 } else { $null }
    $machineryPathsSha256 = if ($historicalBindingComplete -and [string]$Fact.machinery_paths_sha256 -cne 'not-applicable') { [string]$Fact.machinery_paths_sha256 } else { $null }
    $machineryPaths = @()
    if ($historicalBindingComplete) { $machineryPaths = @($Fact.machinery_paths) }
    $excludedPathPatterns = @()
    if ($currentBindingComplete) { $excludedPathPatterns = @($Fact.excluded_path_patterns) }
    $excludedPathPatternsSha256 = if ($currentBindingComplete -and [string]$Fact.excluded_path_patterns_sha256 -cne 'not-applicable') { [string]$Fact.excluded_path_patterns_sha256 } else { $null }
    return [pscustomobject]@{
        schema_version = '1.0'; target_kind = [string]$Fact.target_kind; run_id = [string]$Fact.run_id
        target_digest = [string]$Fact.target_digest; snapshot_path = [string]$Fact.snapshot_path
        workspace_root = [string]$Fact.workspace_root
        origin_repo = $(if ([string]$Fact.origin_repo -ceq 'not-applicable') { $null } else { [string]$Fact.origin_repo })
        git_root = $(if ([string]$Fact.git_root -ceq 'not-applicable') { $null } else { [string]$Fact.git_root })
        origin_head_before = $(if ([string]$Fact.origin_head_before -ceq 'not-applicable') { $null } else { [string]$Fact.origin_head_before })
        verification_plan_present = $(if ($historicalBindingComplete) { [bool]$Fact.verification_plan_present } else { $false })
        verification_plan_sha256 = $verificationPlanSha256
        machinery_paths = $machineryPaths
        machinery_paths_sha256 = $machineryPathsSha256
        excluded_path_patterns = $excludedPathPatterns
        excluded_path_patterns_sha256 = $excludedPathPatternsSha256
        recovery_binding_complete = $currentBindingComplete
        recovery_binding_shape = $bindingShape
    }
}

function Get-ReviewRecoveryDurationMilliseconds {
    param([Parameter(Mandatory)]$Fact, [Parameter(Mandatory)]$ClockPort)
    $now = [long](& $ClockPort.monotonic_ms)
    $started = [long]$Fact.invocation_started_monotonic_ms
    $observed = $now - $started
    $maximum = [long](Get-ReviewAuthorityTimingLimits).max_duration_ms
    # A reboot resets the monotonic source and a long administrative delay is not reviewer runtime.
    # In either case the original interval is unavailable, so publish zero recovery-duration rather
    # than clamp or fabricate a bounded measurement. The result remains abandoned/non-approving.
    if ($observed -lt 0 -or $observed -gt $maximum) { return 0L }
    return $observed
}

function ConvertTo-ReviewRecoveryTimestampString {
    param([Parameter(Mandatory)]$Value)
    if ($Value -is [datetime]) { return ([DateTimeOffset]$Value).ToUniversalTime().ToString('o') }
    if ($Value -is [datetimeoffset]) { return ([DateTimeOffset]$Value).ToUniversalTime().ToString('o') }
    return [string]$Value
}

function Invoke-ReviewRunReconciliation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$TargetLineage,
        [Parameter(Mandatory)]$TargetPort,
        [Parameter(Mandatory)]$RuntimePort,
        [Parameter(Mandatory)]$ClockPort
    )
    $plan = Get-ReviewRunReconciliationPlan -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -TargetLineage $TargetLineage
    $actions = @($plan.actions)
    $observedAt = [string](& $ClockPort.utc_now)

    if ('retire-claim-released' -in $actions) {
        $claim = Complete-ReviewAuthorityClaim -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -TargetLineage $TargetLineage -Disposition released -ObservedAt $observedAt
        return [pscustomobject]@{ status = 'complete'; reason = $claim.reason; actions = $actions; result = (Get-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage result) }
    }
    if ($actions.Count -eq 1 -and $actions[0] -in @('complete', 'no-work')) {
        return [pscustomobject]@{ status = 'complete'; reason = $actions[0]; actions = $actions; result = (Get-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage result) }
    }

    if ('release-non-invoked-reservation' -in $actions) {
        $reservations = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind reservations | Where-Object { [string]$_.run_id -ceq $RunId })
        $spends = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind spend)
        $releases = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind releases)
        if ($reservations.Count -ne 1) { return [pscustomobject]@{ status = 'blocked'; reason = 'reconciliation-reservation-identity-ambiguous'; actions = $actions; result = $null } }
        $release = Resolve-ReviewCampaignReleaseDecision -Reservation $reservations[0] -Reason 'restart-reconciliation: non-invoked reservation released' -ObservedAt $observedAt -Spends $spends -Releases $releases
        if (-not $release.permitted -and $release.reason -cne 'reservation-already-released') { return [pscustomobject]@{ status = 'blocked'; reason = $release.reason; actions = $actions; result = $null } }
        if ($release.permitted) { Write-ReviewCampaignReleaseFact -StoreRoot $StoreRoot -Fact $release.fact | Out-Null }
        if ('retire-claim-abandoned' -in $actions) { Complete-ReviewAuthorityClaim -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -TargetLineage $TargetLineage -Disposition abandoned -ObservedAt $observedAt | Out-Null }
        return [pscustomobject]@{ status = 'complete'; reason = 'non-invoked-reservation-reconciled'; actions = $actions; result = $null }
    }

    if (@($actions | Where-Object { $_ -in @('publish-spent-abandoned-result', 'continue-validation-and-classification') }).Count -eq 0) {
        return [pscustomobject]@{ status = 'blocked'; reason = ('reconciliation-actions-unsupported:' + ($actions -join ',')); actions = $actions; result = $null }
    }
    $recovery = Get-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage recovery
    if ($null -eq $recovery) { return [pscustomobject]@{ status = 'blocked'; reason = 'reconciliation-recovery-fact-missing'; actions = $actions; result = $null } }
    if ([string]$recovery.target_lineage -cne $TargetLineage) { return [pscustomobject]@{ status = 'blocked'; reason = 'reconciliation-target-lineage-mismatch'; actions = $actions; result = $null } }
    if ($null -eq $RuntimePort.PSObject.Properties['recover'] -or $RuntimePort.recover -isnot [scriptblock]) {
        return [pscustomobject]@{ status = 'blocked'; reason = 'reconciliation-runtime-recovery-unsupported'; actions = $actions; result = $null }
    }
    if ([string]$RuntimePort.id -cne [string]$recovery.runtime_id) { return [pscustomobject]@{ status = 'blocked'; reason = 'reconciliation-runtime-id-mismatch'; actions = $actions; result = $null } }
    $termination = & $RuntimePort.recover $recovery
    if ($null -eq $termination -or -not [bool]$termination.termination_verified) {
        $why = if ($null -ne $termination -and $termination.PSObject.Properties['failure_reason']) { [string]$termination.failure_reason } else { 'termination-not-verified' }
        return [pscustomobject]@{ status = 'blocked'; reason = ('reconciliation-' + $why); actions = $actions; result = $null }
    }

    $snapshot = Get-ReviewRecoverySnapshot -Fact $recovery
    if ([string]$snapshot.target_kind -ceq 'code' -and -not [bool]$snapshot.recovery_binding_complete) {
        $currentness = [pscustomobject]@{ classification = 'unknown'; exact = $false; reason = 'recovery-target-binding-unavailable' }
    }
    else {
        try { $currentness = & $TargetPort.currentness $snapshot }
        catch { $currentness = [pscustomobject]@{ classification = 'unknown'; exact = $false; reason = 'recovery-currentness-check-failed' } }
    }
    $duration = Get-ReviewRecoveryDurationMilliseconds -Fact $recovery -ClockPort $ClockPort
    $failure = 'restart-reconciliation: interrupted invoked run verified dead and closed as spent/abandoned'
    $ingress = Invoke-ReviewResultIngress -StoreRoot $StoreRoot -StagingRoot ([string]$recovery.staging_root) -CampaignId $CampaignId -RunId $RunId `
        -TargetDigest ([string]$recovery.target_digest) -HarnessId ([string]$recovery.harness_id) -RuntimeOutcome abandoned -Invoked $true `
        -TerminationVerified $true -Containment ([string]$termination.containment) -Currentness ([string]$currentness.classification) `
        -StartedAt (ConvertTo-ReviewRecoveryTimestampString -Value $recovery.invocation_started_at) -EndedAt $observedAt -DurationMs $duration -FailureReason $failure
    if (-not $ingress.published) { return [pscustomobject]@{ status = 'blocked'; reason = $ingress.reason; actions = $actions; result = $null } }

    # The plan's validating boundary predates publication and may not list claim retirement yet.
    # After this executor publishes the terminal envelope, retire any claim still owned by this run
    # in the same reconciliation call; the operation is idempotent when no active claim remains.
    Complete-ReviewAuthorityClaim -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -TargetLineage $TargetLineage -Disposition abandoned -ObservedAt $observedAt | Out-Null

    # ANY PATH THAT SPENDS A ROUND OWES THE PAUSE THAT LETS THE HUMAN ANSWER FOR IT.
    #
    # This is the SECOND publish path that passes `Invoked: $true`, and until now it was the only one
    # that never wrote a pause. The orchestrator's terminal path writes one; this one closes an
    # interrupted invoked run as spent/abandoned and returned without one - so the round was charged to
    # the allowance and the campaign was left with nothing for the human to answer. The next round then
    # fails closed on `pause-record-missing-for-completed-round` and tells the human to check a folder
    # permission. Spending the round and wedging the campaign were one act.
    #
    # The guard that reads pause absence reasons carefully about a pause write that FAILS; it does not
    # consider a publish path that never ATTEMPTS one. Recorded as DRIFT-199-I002-018; fixed here rather
    # than deferred because an interrupted long round is exactly the exposure the next round carries.
    #
    # ProjectName is display-only (it addresses the human in the pause surface) and is derived from the
    # campaign identity, which encodes it - the same shape as the orchestrator's own fallback. RepoRoot
    # comes from the recovery fact. Nothing here is invented: every input is read from a durable fact.
    $pauseProjectName = if ([string]$CampaignId -match '^cmp-(?<name>.+)-i\d+$') { $Matches['name'] }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$recovery.git_root)) { Split-Path -Leaf ([string]$recovery.git_root) }
    else { [string]$CampaignId }
    try {
        $null = Add-ReviewCampaignRoundPause -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId `
            -TargetDigest ([string]$recovery.target_digest) -ProjectName $pauseProjectName -Result $ingress.result `
            -ObservedAt $observedAt -RepoRoot ([string]$recovery.git_root)
    }
    catch {
        # FAIL-SOFT, BUT NEVER SILENT. The same tolerance as the orchestrator's - a pause that cannot be
        # recorded must not destroy a published result - except that the cause is written down. A
        # fail-soft that discards its exception guarantees that whatever reads its absence will
        # misdiagnose it, which is precisely how this defect's sibling sent a human to check a writable
        # folder. Every fail-soft owes a trace.
        [Console]::Error.WriteLine(("[specrew-review] WARN REVIEW_PAUSE_WRITE_FAILED_RECONCILER campaign '{0}' run '{1}': {2}" -f $CampaignId, $RunId, $_.Exception.Message))
    }

    $cleanup = $null
    try { $cleanup = & $TargetPort.dispose $snapshot } catch { $cleanup = [pscustomobject]@{ removed = $false; failure_reason = $_.Exception.Message } }
    return [pscustomobject]@{
        status = 'terminal'; reason = $ingress.reason; actions = $actions; result = $ingress.result
        result_path = $ingress.result_path; report_path = $ingress.report_path; cleanup = $cleanup
    }
}
