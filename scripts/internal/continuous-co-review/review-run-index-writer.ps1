$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function ConvertTo-ContinuousCoReviewRunIndexIsoTimestamp {
    param(
        [datetime] $Timestamp = [datetime]::UtcNow
    )

    return $Timestamp.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-ContinuousCoReviewRunIndexProperty {
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

function Write-ContinuousCoReviewRunIndexJson {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [AllowNull()]
        $InputObject
    )

    $json = $InputObject | ConvertTo-Json -Depth 100
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $existingJson = Get-Content -LiteralPath $Path -Raw
        $existingCanonical = ConvertTo-ReviewerContractCanonicalJson -InputObject (ConvertFrom-ReviewerContractJson -Json $existingJson)
        $incomingCanonical = ConvertTo-ReviewerContractCanonicalJson -InputObject $InputObject
        if ($existingCanonical -ne $incomingCanonical) {
            throw "Durable review run index artifact already exists with different content: $Path"
        }

        return
    }

    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8 -NoNewline
}

function New-ContinuousCoReviewRunIndexRecord {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        [string] $BaselineRef,

        [AllowNull()]
        $ReviewRequest,

        [AllowNull()]
        $RequestBundle,

        [AllowNull()]
        $SpawnInvocation,

        [AllowNull()]
        $FindingsResult,

        [AllowNull()]
        $InfrastructureFailure,

        [AllowNull()]
        $ReviewThread,

        [AllowNull()]
        $GateVerdict,

        [AllowNull()]
        $CleanupResult,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $createdAtText = ConvertTo-ContinuousCoReviewRunIndexIsoTimestamp -Timestamp $CreatedAt
    $requestHash = Get-ContinuousCoReviewRunIndexProperty -Object $ReviewRequest -Name 'request_hash'
    if ($null -eq $requestHash) {
        $requestHash = Get-ContinuousCoReviewRunIndexProperty -Object $RequestBundle -Name 'request_hash'
    }

    $status = 'recorded'
    if ($null -ne $GateVerdict) {
        $status = Get-ContinuousCoReviewRunIndexProperty -Object $GateVerdict -Name 'state'
    }
    elseif ($null -ne $InfrastructureFailure) {
        $status = 'infrastructure_failure'
    }

    $requestedHost = Get-ContinuousCoReviewRunIndexProperty -Object $SpawnInvocation -Name 'requested_host'
    $requestedModel = Get-ContinuousCoReviewRunIndexProperty -Object $SpawnInvocation -Name 'requested_model'
    if ($null -eq $requestedHost -and $null -ne $ReviewRequest) {
        $providerRequest = Get-ContinuousCoReviewRunIndexProperty -Object $ReviewRequest -Name 'provider_request'
        $requestedHost = Get-ContinuousCoReviewRunIndexProperty -Object $providerRequest -Name 'requested_host'
        $requestedModel = Get-ContinuousCoReviewRunIndexProperty -Object $providerRequest -Name 'requested_model'
    }

    $actualHost = Get-ContinuousCoReviewRunIndexProperty -Object $SpawnInvocation -Name 'actual_host'
    $actualModel = Get-ContinuousCoReviewRunIndexProperty -Object $SpawnInvocation -Name 'actual_model'
    if (($null -eq $actualHost -or $null -eq $actualModel) -and $null -ne $FindingsResult) {
        $reviewer = Get-ContinuousCoReviewRunIndexProperty -Object $FindingsResult -Name 'reviewer'
        if ($null -eq $actualHost) {
            $actualHost = Get-ContinuousCoReviewRunIndexProperty -Object $reviewer -Name 'host'
        }
        if ($null -eq $actualModel) {
            $actualModel = Get-ContinuousCoReviewRunIndexProperty -Object $reviewer -Name 'model'
        }
    }

    $adapterId = Get-ContinuousCoReviewRunIndexProperty -Object $SpawnInvocation -Name 'adapter_id'
    if ($null -eq $adapterId -and $null -ne $FindingsResult) {
        $reviewer = Get-ContinuousCoReviewRunIndexProperty -Object $FindingsResult -Name 'reviewer'
        $adapterId = Get-ContinuousCoReviewRunIndexProperty -Object $reviewer -Name 'adapter_id'
    }

    return [pscustomobject][ordered]@{
        schema_version            = '1.0'
        run_id                    = $RunId
        checkpoint_id             = $CheckpointId
        baseline_ref              = $BaselineRef
        status                    = $status
        request_ref               = 'review-request.json'
        request_hash              = $requestHash
        invocation_ref            = if ($null -ne $SpawnInvocation) { 'spawn-invocation.json' } else { $null }
        invocation_id             = Get-ContinuousCoReviewRunIndexProperty -Object $SpawnInvocation -Name 'invocation_id'
        findings_result_ref       = if ($null -ne $FindingsResult) { 'findings-result.json' } else { $null }
        infrastructure_failure_ref = if ($null -ne $InfrastructureFailure) { 'infrastructure-failure.json' } else { $null }
        review_thread_ref         = if ($null -ne $ReviewThread) { 'review-thread.json' } else { $null }
        gate_verdict_ref          = if ($null -ne $GateVerdict) { 'gate-verdict.json' } else { $null }
        requested_host            = $requestedHost
        requested_model           = $requestedModel
        actual_host               = $actualHost
        actual_model              = $actualModel
        adapter_id                = $adapterId
        cleanup_status            = Get-ContinuousCoReviewRunIndexProperty -Object $CleanupResult -Name 'cleanup_status'
        cleanup_failure_ref       = if ($null -ne (Get-ContinuousCoReviewRunIndexProperty -Object $CleanupResult -Name 'cleanup_failure')) { 'cleanup-failure.json' } else { $null }
        created_at                = $createdAtText
        updated_at                = $createdAtText
    }
}

function New-ContinuousCoReviewRunSkippedIndexRecord {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        [string] $BaselineRef,

        [Parameter(Mandatory)]
        [string] $Reason,

        [AllowNull()]
        [string] $DiffHash,

        [AllowNull()]
        $GateVerdict,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $createdAtText = ConvertTo-ContinuousCoReviewRunIndexIsoTimestamp -Timestamp $CreatedAt
    return [pscustomobject][ordered]@{
        schema_version   = '1.0'
        run_id           = $RunId
        checkpoint_id    = $CheckpointId
        baseline_ref     = $BaselineRef
        status           = 'skipped'
        reason           = $Reason
        diff_hash        = $DiffHash
        gate_verdict_ref = if ($null -ne $GateVerdict) { 'gate-verdict.json' } else { $null }
        created_at       = $createdAtText
        updated_at       = $createdAtText
    }
}

function Write-ContinuousCoReviewRunIndex {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        [string] $BaselineRef,

        [AllowNull()]
        $ReviewRequest,

        [AllowNull()]
        $RequestBundle,

        [AllowNull()]
        $SpawnInvocation,

        [AllowNull()]
        $FindingsResult,

        [AllowNull()]
        $InfrastructureFailure,

        [AllowNull()]
        $ReviewThread,

        [AllowNull()]
        $GateVerdict,

        [AllowNull()]
        $CleanupResult,

        [AllowNull()]
        $SkippedRun,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    $runRoot = Join-Path $resolvedRepoRoot ".specrew/review/inline/$RunId"
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null

    if ($null -ne $SkippedRun) {
        $skipReason = Get-ContinuousCoReviewRunIndexProperty -Object $SkippedRun -Name 'reason'
        if ([string]::IsNullOrWhiteSpace([string] $skipReason)) {
            $skipReason = 'no-reviewable-diff'
        }
        $skipDiffHash = Get-ContinuousCoReviewRunIndexProperty -Object $SkippedRun -Name 'diff_hash'
        $skippedRecord = New-ContinuousCoReviewRunSkippedIndexRecord `
            -RunId $RunId `
            -CheckpointId $CheckpointId `
            -BaselineRef $BaselineRef `
            -Reason $skipReason `
            -DiffHash $skipDiffHash `
            -GateVerdict $GateVerdict `
            -CreatedAt $CreatedAt
        $skippedPath = Join-Path $runRoot 'review-run-skipped.json'
        Write-ContinuousCoReviewRunIndexJson -Path $skippedPath -InputObject $skippedRecord
        if ($null -ne $GateVerdict) {
            Write-ContinuousCoReviewRunIndexJson -Path (Join-Path $runRoot 'gate-verdict.json') -InputObject $GateVerdict
        }

        return [pscustomobject][ordered]@{
            schema_version          = '1.0'
            run_id                  = $RunId
            review_root             = $runRoot
            review_run_skipped_path = $skippedPath
            review_run_skipped      = $skippedRecord
        }
    }

    $runRecord = New-ContinuousCoReviewRunIndexRecord `
        -RunId $RunId `
        -CheckpointId $CheckpointId `
        -BaselineRef $BaselineRef `
        -ReviewRequest $ReviewRequest `
        -RequestBundle $RequestBundle `
        -SpawnInvocation $SpawnInvocation `
        -FindingsResult $FindingsResult `
        -InfrastructureFailure $InfrastructureFailure `
        -ReviewThread $ReviewThread `
        -GateVerdict $GateVerdict `
        -CleanupResult $CleanupResult `
        -CreatedAt $CreatedAt

    if ($null -ne $ReviewRequest) { Write-ContinuousCoReviewRunIndexJson -Path (Join-Path $runRoot 'review-request.json') -InputObject $ReviewRequest }
    if ($null -ne $SpawnInvocation) { Write-ContinuousCoReviewRunIndexJson -Path (Join-Path $runRoot 'spawn-invocation.json') -InputObject $SpawnInvocation }
    if ($null -ne $InfrastructureFailure) { Write-ContinuousCoReviewRunIndexJson -Path (Join-Path $runRoot 'infrastructure-failure.json') -InputObject $InfrastructureFailure }
    if ($null -ne $GateVerdict) { Write-ContinuousCoReviewRunIndexJson -Path (Join-Path $runRoot 'gate-verdict.json') -InputObject $GateVerdict }

    $cleanupFailure = Get-ContinuousCoReviewRunIndexProperty -Object $CleanupResult -Name 'cleanup_failure'
    if ($null -ne $cleanupFailure) { Write-ContinuousCoReviewRunIndexJson -Path (Join-Path $runRoot 'cleanup-failure.json') -InputObject $cleanupFailure }

    $runPath = Join-Path $runRoot 'review-run.json'
    Write-ContinuousCoReviewRunIndexJson -Path $runPath -InputObject $runRecord

    return [pscustomobject][ordered]@{
        schema_version  = '1.0'
        run_id          = $RunId
        review_root     = $runRoot
        review_run_path = $runPath
        review_run      = $runRecord
    }
}

function Write-ContinuousCoReviewReviewRunIndex {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        [string] $BaselineRef,

        [AllowNull()]
        $ReviewRequest,

        [AllowNull()]
        $RequestBundle,

        [AllowNull()]
        $SpawnInvocation,

        [AllowNull()]
        $FindingsResult,

        [AllowNull()]
        $InfrastructureFailure,

        [AllowNull()]
        $ReviewThread,

        [AllowNull()]
        $GateVerdict,

        [AllowNull()]
        $CleanupResult,

        [AllowNull()]
        $SkippedRun,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    return Write-ContinuousCoReviewRunIndex @PSBoundParameters
}

function Write-ContinuousCoReviewSkippedRunIndex {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        [string] $BaselineRef,

        [Parameter(Mandatory)]
        $SkippedRun,

        [AllowNull()]
        $GateVerdict,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    return Write-ContinuousCoReviewRunIndex `
        -RepoRoot $RepoRoot `
        -RunId $RunId `
        -CheckpointId $CheckpointId `
        -BaselineRef $BaselineRef `
        -SkippedRun $SkippedRun `
        -GateVerdict $GateVerdict `
        -CreatedAt $CreatedAt
}
