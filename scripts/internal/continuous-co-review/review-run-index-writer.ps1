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
        [string] $DiffHash,

        [AllowNull()]
        [string] $ReviewedRef,

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
        [string] $Scope,

        [AllowNull()]
        [string] $ReviewedTreeId,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $createdAtText = ConvertTo-ContinuousCoReviewRunIndexIsoTimestamp -Timestamp $CreatedAt
    $requestHash = Get-ContinuousCoReviewRunIndexProperty -Object $ReviewRequest -Name 'request_hash'
    if ($null -eq $requestHash) {
        $requestHash = Get-ContinuousCoReviewRunIndexProperty -Object $RequestBundle -Name 'request_hash'
    }

    # T058 / FR-027: the gate floor (FR-025) recomputes freshness from baseline_ref to
    # the working tree and matches diff_hash, and the incremental baseline advances to
    # reviewed_ref only on a pass. Surface both directly on the durable run record so
    # neither the gate nor the next review has to re-parse review-request.json.
    $resolvedDiffHash = if (-not [string]::IsNullOrWhiteSpace($DiffHash)) {
        $DiffHash
    }
    else {
        $changeSet = Get-ContinuousCoReviewRunIndexProperty -Object $ReviewRequest -Name 'change_set'
        Get-ContinuousCoReviewRunIndexProperty -Object $changeSet -Name 'diff_hash'
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
        diff_hash                 = $resolvedDiffHash
        reviewed_ref              = $ReviewedRef
        reviewed_tree_id          = $ReviewedTreeId
        scope                     = $Scope
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
        [string] $DiffHash,

        [AllowNull()]
        [string] $ReviewedRef,

        [AllowNull()]
        [string] $Scope,

        [AllowNull()]
        [string] $ReviewedTreeId,

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
        -DiffHash $DiffHash `
        -ReviewedRef $ReviewedRef `
        -Scope $Scope `
        -ReviewedTreeId $ReviewedTreeId `
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

function Invoke-ContinuousCoReviewResolverGit {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    Push-Location -LiteralPath $RepoRoot
    try {
        $output = @(& git @Arguments 2>$null)
        $exit = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    return [pscustomobject]@{ ExitCode = $exit; Output = @($output) }
}

function Get-ContinuousCoReviewGitIsAncestor {
    # T066 / FR-025: lineage identity. Returns $true when <Ancestor> is an ancestor of
    # (or equal to) <Descendant>. A non-resolvable ref or a git failure returns $false
    # (fail-closed: a run we cannot prove is on this lineage is not a candidate).
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [AllowNull()]
        [string] $Ancestor,

        [string] $Descendant = 'HEAD'
    )

    if ([string]::IsNullOrWhiteSpace($Ancestor)) {
        return $false
    }

    $result = Invoke-ContinuousCoReviewResolverGit -RepoRoot $RepoRoot -Arguments @('merge-base', '--is-ancestor', $Ancestor, $Descendant)
    return ($result.ExitCode -eq 0)
}

function Get-ContinuousCoReviewMergeBaseAnchor {
    # T066 / FR-025 (HOLE B): the trusted anchor co-review must cover back to is the
    # merge-base of HEAD with the trunk - "co-review must cover everything the feature
    # added on top of shipped trunk". Returns the 40-hex anchor commit, or $null.
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [string] $TrunkName = 'main',

        [string] $HeadRef = 'HEAD'
    )

    $result = Invoke-ContinuousCoReviewResolverGit -RepoRoot $RepoRoot -Arguments @('merge-base', $TrunkName, $HeadRef)
    if ($result.ExitCode -ne 0 -or @($result.Output).Count -eq 0) {
        return $null
    }

    $anchor = ([string] $result.Output[0]).Trim()
    if ($anchor -notmatch '^[0-9a-f]{40}$') {
        return $null
    }

    return $anchor
}

function ConvertTo-ContinuousCoReviewReviewState {
    param([AllowNull()] $Record)

    if ($null -eq $Record) {
        return $null
    }

    return [pscustomobject][ordered]@{
        run_id           = Get-ContinuousCoReviewRunIndexProperty -Object $Record -Name 'run_id'
        checkpoint_id    = Get-ContinuousCoReviewRunIndexProperty -Object $Record -Name 'checkpoint_id'
        baseline_ref     = Get-ContinuousCoReviewRunIndexProperty -Object $Record -Name 'baseline_ref'
        diff_hash        = Get-ContinuousCoReviewRunIndexProperty -Object $Record -Name 'diff_hash'
        reviewed_ref     = Get-ContinuousCoReviewRunIndexProperty -Object $Record -Name 'reviewed_ref'
        reviewed_tree_id = Get-ContinuousCoReviewRunIndexProperty -Object $Record -Name 'reviewed_tree_id'
        scope            = Get-ContinuousCoReviewRunIndexProperty -Object $Record -Name 'scope'
        status           = Get-ContinuousCoReviewRunIndexProperty -Object $Record -Name 'status'
    }
}

function Get-ContinuousCoReviewPassingReviewRuns {
    # T066 / FR-025: read all durable .specrew/review/inline pass|escalated runs, newest
    # first. When -AncestorOfRef is supplied (production), filter to runs whose reviewed_ref
    # is an ancestor of that ref (git lineage) so a DIFFERENT feature/branch's run can never
    # be selected. When it is omitted (fixtures), no lineage filter is applied.
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [AllowNull()]
        [string] $AncestorOfRef
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    $inlineRoot = Join-Path $resolvedRepoRoot '.specrew/review/inline'
    if (-not (Test-Path -LiteralPath $inlineRoot -PathType Container)) {
        return @()
    }

    $passingStates = @('pass', 'escalated')
    $candidates = New-Object System.Collections.Generic.List[object]
    foreach ($runDirectory in @(Get-ChildItem -LiteralPath $inlineRoot -Directory -ErrorAction SilentlyContinue)) {
        $runPath = Join-Path $runDirectory.FullName 'review-run.json'
        if (-not (Test-Path -LiteralPath $runPath -PathType Leaf)) {
            continue
        }

        try {
            $record = Get-Content -LiteralPath $runPath -Raw | ConvertFrom-Json -Depth 100
        }
        catch {
            continue
        }

        $status = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $record -Name 'status')
        if ($passingStates -notcontains $status) {
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($AncestorOfRef)) {
            $reviewedRef = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $record -Name 'reviewed_ref')
            if (-not (Get-ContinuousCoReviewGitIsAncestor -RepoRoot $resolvedRepoRoot -Ancestor $reviewedRef -Descendant $AncestorOfRef)) {
                continue
            }
        }

        [void] $candidates.Add($record)
    }

    # F6 (145 review): sort by parsed UTC DateTime, not the raw string.
    return @(
        $candidates | Sort-Object -Property `
            @{ Expression = {
                    $createdAtValue = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $_ -Name 'created_at')
                    $parsed = [datetime]::MinValue
                    [void] [datetime]::TryParse($createdAtValue, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref] $parsed)
                    $parsed
                }; Descending = $true
            }, `
            @{ Expression = { [string] (Get-ContinuousCoReviewRunIndexProperty -Object $_ -Name 'run_id') }; Descending = $true }
    )
}

function Get-ContinuousCoReviewLastPassingReviewState {
    # T058/T066 / FR-025 / FR-027: the latest pass|escalated run on this lineage. The
    # incremental review baseline (FR-027) advances to its reviewed_ref; the gate (FR-025)
    # checks the current reviewed-state tree-id against it and verifies the chain reaches
    # the merge-base anchor. Identity is now git lineage (reviewed_ref ancestor of
    # -AncestorOfRef), not a scope string; -AncestorOfRef omitted = fixture mode (no filter).
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [AllowNull()]
        [string] $AncestorOfRef
    )

    $runs = @(Get-ContinuousCoReviewPassingReviewRuns -RepoRoot $RepoRoot -AncestorOfRef $AncestorOfRef)
    if ($runs.Count -eq 0) {
        return $null
    }

    return ConvertTo-ContinuousCoReviewReviewState -Record $runs[0]
}
