$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function ConvertTo-ContinuousCoReviewGateIsoTimestamp {
    param(
        [datetime] $Timestamp = [datetime]::UtcNow
    )

    return $Timestamp.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-ContinuousCoReviewGateProperty {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $Object,

        [Parameter(Mandatory)]
        [string] $Name
    )

    if ($null -eq $Object) {
        return $null
    }

    if (Test-ReviewerContractPropertyExists -Object $Object -Name $Name) {
        return Get-ReviewerContractPropertyValue -Object $Object -Name $Name
    }

    return $null
}

function New-ContinuousCoReviewGateVerdict {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        [string] $State,

        [string[]] $BlockingFindingIds = @(),

        [string[]] $UnsafeReasons = @(),

        [int] $RoundCount = 1,

        [AllowNull()]
        [string] $EscalationRef = $null,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $distinctBlockingIds = @($BlockingFindingIds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    $distinctUnsafeReasons = @($UnsafeReasons | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)

    return [pscustomobject][ordered]@{
        schema_version            = '1.0'
        verdict_id                = "verdict-$RunId"
        run_id                    = $RunId
        checkpoint_id             = $CheckpointId
        state                     = $State
        unresolved_blocking_count = @($distinctBlockingIds).Count
        blocking_finding_ids      = @($distinctBlockingIds)
        unsafe_reasons            = @($distinctUnsafeReasons)
        round_count               = $RoundCount
        escalation_ref            = if ([string]::IsNullOrWhiteSpace([string] $EscalationRef)) { $null } else { $EscalationRef }
        created_at                = ConvertTo-ContinuousCoReviewGateIsoTimestamp -Timestamp $CreatedAt
    }
}

function Get-ContinuousCoReviewLatestDispositionByFindingId {
    param(
        [AllowNull()]
        $ReviewThread
    )

    $latest = @{}
    if ($null -eq $ReviewThread) {
        return $latest
    }

    foreach ($disposition in @($ReviewThread.dispositions)) {
        $findingId = Get-ContinuousCoReviewGateProperty -Object $disposition -Name 'finding_id'
        if ([string]::IsNullOrWhiteSpace([string] $findingId)) {
            continue
        }

        $round = Get-ContinuousCoReviewGateProperty -Object $disposition -Name 'review_round'
        if ($null -eq $round) {
            $round = 0
        }

        if (-not $latest.ContainsKey($findingId)) {
            $latest[$findingId] = $disposition
            continue
        }

        $currentRound = Get-ContinuousCoReviewGateProperty -Object $latest[$findingId] -Name 'review_round'
        if ($null -eq $currentRound) {
            $currentRound = 0
        }

        if ([int] $round -ge [int] $currentRound) {
            $latest[$findingId] = $disposition
        }
    }

    return $latest
}

function Get-ContinuousCoReviewRoundCount {
    param(
        [AllowNull()]
        $ReviewThread
    )

    if ($null -eq $ReviewThread) {
        return 1
    }

    $maxRound = 0
    foreach ($disposition in @($ReviewThread.dispositions)) {
        $round = Get-ContinuousCoReviewGateProperty -Object $disposition -Name 'review_round'
        if ($null -ne $round -and [int] $round -gt $maxRound) {
            $maxRound = [int] $round
        }
    }

    return ($maxRound + 1)
}

function Get-ContinuousCoReviewFindingEffectiveState {
    param(
        [Parameter(Mandatory)]
        $Finding,

        [AllowNull()]
        $LatestDisposition
    )

    $resolution = Get-ContinuousCoReviewGateProperty -Object $Finding -Name 'resolution'
    $dispositionState = Get-ContinuousCoReviewGateProperty -Object $Finding -Name 'disposition'
    $resolutionState = Get-ContinuousCoReviewGateProperty -Object $resolution -Name 'state'
    $rationale = Get-ContinuousCoReviewGateProperty -Object $resolution -Name 'rationale'
    $fixEvidenceRef = Get-ContinuousCoReviewGateProperty -Object $resolution -Name 'fix_evidence_ref'

    if ($null -ne $LatestDisposition) {
        $latestState = Get-ContinuousCoReviewGateProperty -Object $LatestDisposition -Name 'state'
        if (-not [string]::IsNullOrWhiteSpace([string] $latestState)) {
            $dispositionState = $latestState
        }

        $latestRationale = Get-ContinuousCoReviewGateProperty -Object $LatestDisposition -Name 'rationale'
        if (-not [string]::IsNullOrWhiteSpace([string] $latestRationale)) {
            $rationale = $latestRationale
        }

        $latestFixEvidence = Get-ContinuousCoReviewGateProperty -Object $LatestDisposition -Name 'fix_evidence_ref'
        if (-not [string]::IsNullOrWhiteSpace([string] $latestFixEvidence)) {
            $fixEvidenceRef = $latestFixEvidence
        }
    }

    return [pscustomobject][ordered]@{
        disposition_state = $dispositionState
        resolution_state  = $resolutionState
        rationale         = $rationale
        fix_evidence_ref  = $fixEvidenceRef
    }
}

function Get-ContinuousCoReviewUnresolvedBlockingFindingInfo {
    param(
        [AllowNull()]
        $FindingsResult,

        [AllowNull()]
        $ReviewThread,

        [System.Collections.Generic.List[string]] $UnsafeReasons
    )

    $latestDispositions = Get-ContinuousCoReviewLatestDispositionByFindingId -ReviewThread $ReviewThread
    $unresolved = [System.Collections.Generic.List[object]]::new()

    if ($null -eq $FindingsResult) {
        $UnsafeReasons.Add('missing-findings-result')
        return @($unresolved)
    }

    foreach ($finding in @($FindingsResult.findings)) {
        $findingId = Get-ContinuousCoReviewGateProperty -Object $finding -Name 'finding_id'
        $severity = Get-ContinuousCoReviewGateProperty -Object $finding -Name 'severity'
        if ($severity -ne 'blocking') {
            continue
        }

        $latestDisposition = $null
        if ($latestDispositions.ContainsKey($findingId)) {
            $latestDisposition = $latestDispositions[$findingId]
        }

        $effectiveState = Get-ContinuousCoReviewFindingEffectiveState -Finding $finding -LatestDisposition $latestDisposition
        $originalDispositionState = Get-ContinuousCoReviewGateProperty -Object $finding -Name 'disposition'
        if (-not (Test-ReviewerFindingDispositionValue -Disposition ([string] $originalDispositionState))) {
            $UnsafeReasons.Add('unknown-blocking-disposition')
            continue
        }

        if (-not (Test-ReviewerFindingDispositionValue -Disposition ([string] $effectiveState.disposition_state))) {
            $UnsafeReasons.Add('unknown-blocking-disposition')
            continue
        }

        if (-not (Test-ReviewerFindingResolutionStateValue -State ([string] $effectiveState.resolution_state))) {
            $UnsafeReasons.Add('unknown-blocking-resolution-state')
            continue
        }

        if ($effectiveState.disposition_state -eq 'resolved') {
            if ($effectiveState.resolution_state -ne 'resolved') {
                $UnsafeReasons.Add('malformed-durable-state')
                continue
            }

            if ([string]::IsNullOrWhiteSpace([string] $effectiveState.fix_evidence_ref) -and [string]::IsNullOrWhiteSpace([string] $effectiveState.rationale)) {
                $UnsafeReasons.Add('missing-blocking-resolution-evidence')
            }
            continue
        }

        if ($effectiveState.disposition_state -eq 'rejected_with_rationale') {
            if ([string]::IsNullOrWhiteSpace([string] $effectiveState.rationale)) {
                $UnsafeReasons.Add('missing-rejection-rationale')
            }
            if ($effectiveState.resolution_state -eq 'unresolved') {
                $unresolved.Add([pscustomobject][ordered]@{
                        finding_id    = $findingId
                        fingerprint   = Get-ContinuousCoReviewGateProperty -Object $finding -Name 'fingerprint'
                        source_run_id = Get-ContinuousCoReviewGateProperty -Object $finding -Name 'source_run_id'
                    })
            }
            continue
        }

        if ($effectiveState.disposition_state -eq 'escalated_to_human' -or $effectiveState.resolution_state -eq 'escalated') {
            continue
        }

        if (($effectiveState.disposition_state -eq 'open' -or $effectiveState.disposition_state -eq 'accepted_fix_pending') -and $effectiveState.resolution_state -eq 'unresolved') {
            $unresolved.Add([pscustomobject][ordered]@{
                    finding_id    = $findingId
                    fingerprint   = Get-ContinuousCoReviewGateProperty -Object $finding -Name 'fingerprint'
                    source_run_id = Get-ContinuousCoReviewGateProperty -Object $finding -Name 'source_run_id'
                })
        }
    }

    return @($unresolved)
}

function Test-ContinuousCoReviewSameBlockingFindingPreviouslyUnresolved {
    param(
        [Parameter(Mandatory)]
        $CurrentBlockingInfo,

        [AllowNull()]
        $PriorFindingsResult
    )

    if ($null -eq $PriorFindingsResult) {
        return $false
    }

    foreach ($priorFinding in @($PriorFindingsResult.findings)) {
        if ((Get-ContinuousCoReviewGateProperty -Object $priorFinding -Name 'severity') -ne 'blocking') {
            continue
        }

        $priorResolution = Get-ContinuousCoReviewGateProperty -Object $priorFinding -Name 'resolution'
        $priorResolutionState = Get-ContinuousCoReviewGateProperty -Object $priorResolution -Name 'state'
        if ($priorResolutionState -ne 'unresolved') {
            continue
        }

        $priorFindingId = Get-ContinuousCoReviewGateProperty -Object $priorFinding -Name 'finding_id'
        $priorFingerprint = Get-ContinuousCoReviewGateProperty -Object $priorFinding -Name 'fingerprint'
        $priorRunId = Get-ContinuousCoReviewGateProperty -Object $priorFinding -Name 'source_run_id'

        if ($CurrentBlockingInfo.finding_id -eq $priorFindingId) {
            return $true
        }
        if (-not [string]::IsNullOrWhiteSpace([string] $CurrentBlockingInfo.fingerprint) -and $CurrentBlockingInfo.fingerprint -eq $priorFingerprint) {
            return $true
        }
        if (-not [string]::IsNullOrWhiteSpace([string] $CurrentBlockingInfo.source_run_id) -and $CurrentBlockingInfo.source_run_id -eq $PriorFindingsResult.run_id) {
            return $true
        }
        if (-not [string]::IsNullOrWhiteSpace([string] $CurrentBlockingInfo.source_run_id) -and $CurrentBlockingInfo.source_run_id -eq $priorRunId) {
            return $true
        }
    }

    return $false
}

function Invoke-ContinuousCoReviewInlineGateEvaluator {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [AllowNull()]
        $FindingsResult,

        [AllowNull()]
        $ReviewThread,

        [AllowNull()]
        $SkippedRun,

        [AllowNull()]
        $PriorFindingsResult,

        [int] $MaxReviewRounds = 2,

        [string] $SchemaRoot,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    if ($null -ne $SkippedRun) {
        $skipUnsafeReasons = [System.Collections.Generic.List[string]]::new()
        if ((Get-ContinuousCoReviewGateProperty -Object $SkippedRun -Name 'run_id') -ne $RunId) {
            $skipUnsafeReasons.Add('malformed-durable-state')
        }
        if ((Get-ContinuousCoReviewGateProperty -Object $SkippedRun -Name 'checkpoint_id') -ne $CheckpointId) {
            $skipUnsafeReasons.Add('malformed-durable-state')
        }

        if ($skipUnsafeReasons.Count -gt 0) {
            return New-ContinuousCoReviewGateVerdict -RunId $RunId -CheckpointId $CheckpointId -State 'unsafe' -UnsafeReasons @($skipUnsafeReasons) -RoundCount 0 -CreatedAt $CreatedAt
        }

        return New-ContinuousCoReviewGateVerdict -RunId $RunId -CheckpointId $CheckpointId -State 'skipped' -RoundCount 0 -CreatedAt $CreatedAt
    }

    $unsafeReasons = [System.Collections.Generic.List[string]]::new()

    if ($null -eq $FindingsResult) {
        $unsafeReasons.Add('missing-findings-result')
    }
    elseif ($SchemaRoot) {
        $findingsValidation = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $SchemaRoot -InputObject $FindingsResult
        if (-not $findingsValidation.Valid) {
            $unsafeReasons.Add('invalid-findings-schema')
        }
    }

    if ($null -eq $ReviewThread) {
        $unsafeReasons.Add('missing-review-thread')
    }
    elseif ($SchemaRoot) {
        $threadValidation = Test-ReviewerContractObject -ContractName 'ReviewThread' -SchemaRoot $SchemaRoot -InputObject $ReviewThread
        if (-not $threadValidation.Valid) {
            $unsafeReasons.Add('malformed-durable-state')
        }
    }

    if ($null -ne $FindingsResult -and (Get-ContinuousCoReviewGateProperty -Object $FindingsResult -Name 'run_id') -ne $RunId) {
        $unsafeReasons.Add('malformed-durable-state')
    }
    if ($null -ne $ReviewThread -and (Get-ContinuousCoReviewGateProperty -Object $ReviewThread -Name 'run_id') -ne $RunId) {
        $unsafeReasons.Add('malformed-durable-state')
    }
    if ($null -ne $ReviewThread -and (Get-ContinuousCoReviewGateProperty -Object $ReviewThread -Name 'checkpoint_id') -ne $CheckpointId) {
        $unsafeReasons.Add('malformed-durable-state')
    }

    $roundCount = Get-ContinuousCoReviewRoundCount -ReviewThread $ReviewThread
    $unresolvedBlocking = Get-ContinuousCoReviewUnresolvedBlockingFindingInfo -FindingsResult $FindingsResult -ReviewThread $ReviewThread -UnsafeReasons $unsafeReasons
    $blockingIds = @($unresolvedBlocking | ForEach-Object { $_.finding_id })

    if ($unsafeReasons.Count -gt 0) {
        return New-ContinuousCoReviewGateVerdict -RunId $RunId -CheckpointId $CheckpointId -State 'unsafe' -BlockingFindingIds $blockingIds -UnsafeReasons @($unsafeReasons) -RoundCount $roundCount -CreatedAt $CreatedAt
    }

    if (@($unresolvedBlocking).Count -eq 0) {
        return New-ContinuousCoReviewGateVerdict -RunId $RunId -CheckpointId $CheckpointId -State 'pass' -RoundCount $roundCount -CreatedAt $CreatedAt
    }

    $samePriorBlocking = @(
        foreach ($blockingInfo in @($unresolvedBlocking)) {
            if (Test-ContinuousCoReviewSameBlockingFindingPreviouslyUnresolved -CurrentBlockingInfo $blockingInfo -PriorFindingsResult $PriorFindingsResult) {
                $blockingInfo.finding_id
            }
        }
    )

    if (($roundCount -ge $MaxReviewRounds) -and (@($samePriorBlocking).Count -gt 0)) {
        $escalationRef = "human-escalation:${RunId}:$($samePriorBlocking -join ',')"
        return New-ContinuousCoReviewGateVerdict -RunId $RunId -CheckpointId $CheckpointId -State 'escalated' -BlockingFindingIds $blockingIds -RoundCount $roundCount -EscalationRef $escalationRef -CreatedAt $CreatedAt
    }

    return New-ContinuousCoReviewGateVerdict -RunId $RunId -CheckpointId $CheckpointId -State 'blocked' -BlockingFindingIds $blockingIds -RoundCount $roundCount -CreatedAt $CreatedAt
}
