$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-ContinuousCoReviewCheckpointReview {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        [string] $BaselineRef,

        [string] $RunId,

        [Parameter(Mandatory)]
        $ProviderRequest,

        [string[]] $DesignContextRefs = @(),

        [object[]] $Candidates = @(),

        [AllowNull()]
        $Catalog,

        [AllowNull()]
        $ReviewerConfiguration,

        [scriptblock] $CommandResolver,

        [string] $SchemaRoot,

        [string] $RunRoot,

        [string[]] $ExcludedPathPatterns = @(),

        [string[]] $AllowedPaths = @(),

        [string[]] $ForbiddenPaths = @(),

        [scriptblock] $InvokeAdapter,

        [bool] $PreserveDebug = $false,

        [switch] $RebaselineToLastPass,

        [AllowNull()]
        [string] $Scope,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    $resolvedRunId = if ([string]::IsNullOrWhiteSpace($RunId)) { "run-$CheckpointId" } else { $RunId }
    $resolvedRunRoot = if ([string]::IsNullOrWhiteSpace($RunRoot)) {
        Join-Path $resolvedRepoRoot '.specrew/review/tmp'
    }
    else {
        $RunRoot
    }

    # T058 / FR-027: advance the review baseline to the last passing reviewed point so
    # each checkpoint reviews only its incremental diff. The baseline advances only on a
    # pass (the resolver returns only pass/escalated runs), so a missed or blocked
    # checkpoint keeps the baseline pinned and the next review re-covers that span.
    if ($RebaselineToLastPass) {
        $lastPassingState = Get-ContinuousCoReviewLastPassingReviewState -RepoRoot $resolvedRepoRoot -Scope $Scope
        if ($null -ne $lastPassingState -and -not [string]::IsNullOrWhiteSpace([string] $lastPassingState.reviewed_ref)) {
            $BaselineRef = [string] $lastPassingState.reviewed_ref
        }
    }

    # F3 (145 review): reviewed_ref is the current HEAD as PROVENANCE; the content
    # actually reviewed is the baseline->working-tree diff (which may include uncommitted
    # tracked edits beyond HEAD), captured authoritatively by diff_hash. reviewed_ref
    # advances the next incremental baseline only on a pass; because working-tree >= HEAD,
    # the next review re-covers any uncommitted span (safe over-review, never under-review).
    $reviewedRef = $null
    $headResult = Invoke-ContinuousCoReviewGit -RepoRoot $resolvedRepoRoot -Arguments @('rev-parse', 'HEAD')
    if ($headResult.ExitCode -eq 0 -and @($headResult.Output).Count -gt 0) {
        $headCandidate = ([string] $headResult.Output[0]).Trim()
        if ($headCandidate -match '^[0-9a-f]{40}$') {
            $reviewedRef = $headCandidate
        }
    }

    $changeSet = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $resolvedRepoRoot -BaselineRef $BaselineRef -CheckpointId $CheckpointId -ExcludedPathPatterns $ExcludedPathPatterns -RunId $resolvedRunId
    if ($changeSet.status -eq 'skipped') {
        $verdict = Invoke-ContinuousCoReviewInlineGateEvaluator -RunId $resolvedRunId -CheckpointId $CheckpointId -FindingsResult $null -ReviewThread $null -SkippedRun $changeSet.skipped_run -SchemaRoot $SchemaRoot -CreatedAt $CreatedAt
        $index = Write-ContinuousCoReviewSkippedRunIndex -RepoRoot $resolvedRepoRoot -RunId $resolvedRunId -CheckpointId $CheckpointId -BaselineRef $BaselineRef -SkippedRun $changeSet.skipped_run -GateVerdict $verdict -CreatedAt $CreatedAt
        return [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = $resolvedRunId
            status         = 'skipped'
            change_set     = $changeSet
            gate_verdict   = $verdict
            run_index      = $index
        }
    }

    if ($changeSet.status -eq 'infrastructure_failure') {
        $verdict = New-ContinuousCoReviewGateVerdict -RunId $resolvedRunId -CheckpointId $CheckpointId -State 'unsafe' -UnsafeReasons @($changeSet.failure.category) -RoundCount 0 -CreatedAt $CreatedAt
        $index = Write-ContinuousCoReviewRunIndex -RepoRoot $resolvedRepoRoot -RunId $resolvedRunId -CheckpointId $CheckpointId -BaselineRef $BaselineRef -InfrastructureFailure $changeSet.failure -GateVerdict $verdict -CreatedAt $CreatedAt
        return [pscustomobject][ordered]@{
            schema_version          = '1.0'
            run_id                  = $resolvedRunId
            status                  = 'infrastructure_failure'
            change_set              = $changeSet
            infrastructure_failure  = $changeSet.failure
            gate_verdict            = $verdict
            run_index               = $index
        }
    }

    $resolvedCatalog = if ($null -ne $Catalog) {
        $Catalog
    }
    else {
        Get-ContinuousCoReviewReviewerHostCatalog -Configuration $ReviewerConfiguration -CommandResolver $CommandResolver
    }
    $requestedHost = Get-ContinuousCoReviewCatalogValue -Object $ProviderRequest -Name 'requested_host'
    $requestedModel = Get-ContinuousCoReviewCatalogValue -Object $ProviderRequest -Name 'requested_model'
    $codeWriterHost = Get-ContinuousCoReviewCatalogValue -Object $ProviderRequest -Name 'code_writer_host'
    $capability = Get-ContinuousCoReviewReviewerModelCapability -Catalog $resolvedCatalog -RequestedHost $requestedHost -RequestedModel $requestedModel
    $resolvedCandidates = @($Candidates)
    if (@($resolvedCandidates).Count -eq 0) {
        $primaryCandidate = Select-ContinuousCoReviewReviewerCandidate -Catalog $resolvedCatalog -RequestedHost $requestedHost -RequestedModel $requestedModel -CodeWriterHost $codeWriterHost
        if ($null -ne $primaryCandidate) {
            $resolvedCandidates += $primaryCandidate
        }

        $fallbackCandidate = Select-ContinuousCoReviewReviewerCandidate -Catalog $resolvedCatalog -FallbackOnly
        if ($null -ne $fallbackCandidate -and (
                $null -eq $primaryCandidate -or
                $fallbackCandidate.host -ne $primaryCandidate.host -or
                $fallbackCandidate.model -ne $primaryCandidate.model
            )) {
            $resolvedCandidates += $fallbackCandidate
        }
    }

    $request = New-ContinuousCoReviewRequest -RunId $resolvedRunId -CheckpointId $CheckpointId -BaselineRef $BaselineRef -ChangeSet $changeSet -DesignContextRefs $DesignContextRefs -AllowedPaths $AllowedPaths -ForbiddenPaths $ForbiddenPaths -ProviderRequest $ProviderRequest -CreatedAt $CreatedAt -SchemaRoot $SchemaRoot
    $execution = Invoke-ContinuousCoReviewReviewerExecution -Request $request -RunRoot $resolvedRunRoot -SchemaRoot $SchemaRoot -Candidates $resolvedCandidates -InvokeAdapter $InvokeAdapter -ReadOnlyRoot $resolvedRepoRoot -CreatedAt $CreatedAt

    if ($execution.kind -eq 'findings-result') {
        $blackboard = Write-ContinuousCoReviewBlackboardThread -RepoRoot $resolvedRepoRoot -CheckpointId $CheckpointId -FindingsResult $execution.findings_result -DispositionTrail $null -EscalationRef $null -SchemaRoot $SchemaRoot -CreatedAt $CreatedAt
        $verdict = Invoke-ContinuousCoReviewInlineGateEvaluator -RunId $resolvedRunId -CheckpointId $CheckpointId -FindingsResult $execution.findings_result -ReviewThread $blackboard.review_thread -SkippedRun $null -SchemaRoot $SchemaRoot -CreatedAt $CreatedAt
        $cleanup = Complete-ContinuousCoReviewRunWorkspace -Workspace ([pscustomobject]@{ run_id = $resolvedRunId; path = $execution.request_bundle.workspace_path }) -PreserveDebug:$PreserveDebug -GateVerdict $verdict
        $index = Write-ContinuousCoReviewRunIndex -RepoRoot $resolvedRepoRoot -RunId $resolvedRunId -CheckpointId $CheckpointId -BaselineRef $BaselineRef -DiffHash $changeSet.diff_hash -ReviewedRef $reviewedRef -Scope $Scope -ReviewRequest $request -RequestBundle $execution.request_bundle -SpawnInvocation $execution.provider_invocation -FindingsResult $execution.findings_result -ReviewThread $blackboard.review_thread -GateVerdict $verdict -CleanupResult $cleanup -CreatedAt $CreatedAt
        return [pscustomobject][ordered]@{
            schema_version      = '1.0'
            run_id              = $resolvedRunId
            status              = $verdict.state
            change_set          = $changeSet
            capability          = $capability
            request             = $request
            execution           = $execution
            blackboard          = $blackboard
            gate_verdict        = $verdict
            cleanup             = $cleanup
            run_index           = $index
        }
    }

    $failureVerdict = New-ContinuousCoReviewGateVerdict -RunId $resolvedRunId -CheckpointId $CheckpointId -State 'unsafe' -UnsafeReasons @($execution.infrastructure_failure.category) -RoundCount 1 -CreatedAt $CreatedAt
    $failureCleanup = Complete-ContinuousCoReviewRunWorkspace -Workspace ([pscustomobject]@{ run_id = $resolvedRunId; path = $execution.request_bundle.workspace_path }) -PreserveDebug:$PreserveDebug -GateVerdict $failureVerdict
    $failureIndex = Write-ContinuousCoReviewRunIndex -RepoRoot $resolvedRepoRoot -RunId $resolvedRunId -CheckpointId $CheckpointId -BaselineRef $BaselineRef -DiffHash $changeSet.diff_hash -ReviewedRef $reviewedRef -Scope $Scope -ReviewRequest $request -RequestBundle $execution.request_bundle -SpawnInvocation $execution.provider_invocation -InfrastructureFailure $execution.infrastructure_failure -GateVerdict $failureVerdict -CleanupResult $failureCleanup -CreatedAt $CreatedAt
    return [pscustomobject][ordered]@{
        schema_version          = '1.0'
        run_id                  = $resolvedRunId
        status                  = 'infrastructure_failure'
        change_set              = $changeSet
        capability              = $capability
        request                 = $request
        execution               = $execution
        infrastructure_failure  = $execution.infrastructure_failure
        gate_verdict            = $failureVerdict
        cleanup                 = $failureCleanup
        run_index               = $failureIndex
    }
}

function Invoke-ContinuousCoReviewCheckpointReviewOrchestrator {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        [string] $BaselineRef,

        [string] $RunId,

        [Parameter(Mandatory)]
        $ProviderRequest,

        [string[]] $DesignContextRefs = @(),

        [object[]] $Candidates = @(),

        [AllowNull()]
        $Catalog,

        [AllowNull()]
        $ReviewerConfiguration,

        [scriptblock] $CommandResolver,

        [string] $SchemaRoot,

        [string] $RunRoot,

        [string[]] $ExcludedPathPatterns = @(),

        [string[]] $AllowedPaths = @(),

        [string[]] $ForbiddenPaths = @(),

        [scriptblock] $InvokeAdapter,

        [bool] $PreserveDebug = $false,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    return Invoke-ContinuousCoReviewCheckpointReview @PSBoundParameters
}
