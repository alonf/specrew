$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T059 / FR-032 / SC-023: the gate-review dispatcher. A single host Stop-hook call invokes
# this once per stop. It decides (1) is this a real CHECKPOINT (an increment was produced)
# vs a casual mid-task yield, and (2) which gate/stage this stop belongs to, then dispatches
# ONLY to a reviewer registered for that stage. Casual stops and unregistered stages are
# no-ops - zero reviewer spawn. The dispatcher only DECIDES; T060 acts on a 'dispatch'
# decision by invoking the checkpoint-review orchestrator.

function New-ContinuousCoReviewDispatchDecision {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('dispatch', 'no-op')]
        [string] $Action,

        [Parameter(Mandatory)]
        [string] $Reason,

        [Parameter(Mandatory)]
        [string] $Stage,

        [AllowNull()] $Reviewer
    )

    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        action         = $Action
        reason         = $Reason
        stage          = $Stage
        reviewer       = $Reviewer
    }
}

function Test-ContinuousCoReviewCheckpointReached {
    # A real checkpoint for a code-review stage = there is a reviewable change-set since the
    # baseline. No baseline / no reviewable change = a casual yield (no-op). Any change-set
    # infrastructure failure is treated as NOT a checkpoint (the dispatcher stays a no-op;
    # the deterministic gate floor remains the backstop).
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [AllowNull()]
        [string] $BaselineRef,

        [string[]] $ExcludedPathPatterns = @()
    )

    if ([string]::IsNullOrWhiteSpace($BaselineRef)) {
        return $false
    }

    $changeSet = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $RepoRoot -BaselineRef $BaselineRef -CheckpointId 'dispatch-probe' -ExcludedPathPatterns $ExcludedPathPatterns -RunId 'dispatch-probe'
    if ($changeSet.status -ne 'reviewable') {
        return $false
    }

    return ([int] $changeSet.reviewable_path_count -gt 0)
}

function Invoke-ContinuousCoReviewGateDispatch {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $Stage,

        [AllowNull()]
        [string] $BaselineRef,

        [string[]] $ExcludedPathPatterns = @(),

        [object[]] $Registry,

        # Explicit checkpoint signal (e.g. from the Stop hook). When omitted (detected via
        # PSBoundParameters) the dispatcher detects a checkpoint from the reviewable change-set.
        [bool] $CheckpointReached
    )

    $registryParam = @{}
    if ($PSBoundParameters.ContainsKey('Registry')) { $registryParam['Registry'] = $Registry }

    # 1. Gate routing: only a registered stage can dispatch.
    $reviewer = Get-ContinuousCoReviewRegisteredReviewer -Stage $Stage @registryParam
    if ($null -eq $reviewer) {
        return New-ContinuousCoReviewDispatchDecision -Action 'no-op' -Reason 'no-reviewer-registered-for-stage' -Stage $Stage
    }

    # 2. Real checkpoint vs casual yield.
    $isCheckpoint = if ($PSBoundParameters.ContainsKey('CheckpointReached')) {
        [bool] $CheckpointReached
    }
    else {
        Test-ContinuousCoReviewCheckpointReached -RepoRoot $RepoRoot -BaselineRef $BaselineRef -ExcludedPathPatterns $ExcludedPathPatterns
    }

    if (-not $isCheckpoint) {
        return New-ContinuousCoReviewDispatchDecision -Action 'no-op' -Reason 'no-reviewable-checkpoint' -Stage $Stage -Reviewer $reviewer
    }

    # 3. Dispatch to the registered reviewer (T060 invokes it).
    return New-ContinuousCoReviewDispatchDecision -Action 'dispatch' -Reason 'registered-checkpoint' -Stage $Stage -Reviewer $reviewer
}

function Invoke-ContinuousCoReviewGateCheckpoint {
    # T060 / FR-024: the one-call entry a Stop hook fires. It dispatches (T059) and, ONLY on a
    # 'dispatch' decision, invokes the registered runner (iteration 003: the checkpoint-review
    # orchestrator, auto-anchored as a signoff run). A no-op decision runs NO reviewer - this
    # is where "fire on every stop" becomes "review only a registered checkpoint".
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $Stage,

        [string] $CheckpointId = 'implement-checkpoint',

        [string] $BaselineRef = 'HEAD',

        [string] $TrunkName = 'main',

        [object[]] $Registry,

        [bool] $CheckpointReached,

        [AllowNull()] $ProviderRequest,

        [string[]] $DesignContextRefs = @(),

        [object[]] $Candidates = @(),

        [AllowNull()] $ReviewerConfiguration,

        [string] $SchemaRoot,

        [string] $RunRoot,

        [string[]] $ExcludedPathPatterns = @(),

        [scriptblock] $InvokeAdapter,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $dispatchParams = @{ RepoRoot = $RepoRoot; Stage = $Stage; BaselineRef = $BaselineRef; ExcludedPathPatterns = $ExcludedPathPatterns }
    if ($PSBoundParameters.ContainsKey('Registry')) { $dispatchParams['Registry'] = $Registry }
    if ($PSBoundParameters.ContainsKey('CheckpointReached')) { $dispatchParams['CheckpointReached'] = $CheckpointReached }
    $decision = Invoke-ContinuousCoReviewGateDispatch @dispatchParams

    if ($decision.action -ne 'dispatch') {
        return [pscustomobject][ordered]@{ schema_version = '1.0'; dispatched = $false; decision = $decision; review = $null }
    }

    $reviewParams = @{
        RepoRoot             = $RepoRoot
        CheckpointId         = $CheckpointId
        BaselineRef          = $BaselineRef
        TrunkName            = $TrunkName
        ProviderRequest      = $ProviderRequest
        DesignContextRefs    = $DesignContextRefs
        Candidates           = $Candidates
        SchemaRoot           = $SchemaRoot
        RunRoot              = $RunRoot
        ExcludedPathPatterns = $ExcludedPathPatterns
        RebaselineToLastPass = $true
        CreatedAt            = $CreatedAt
    }
    if ($PSBoundParameters.ContainsKey('ReviewerConfiguration')) { $reviewParams['ReviewerConfiguration'] = $ReviewerConfiguration }
    if ($PSBoundParameters.ContainsKey('InvokeAdapter')) { $reviewParams['InvokeAdapter'] = $InvokeAdapter }

    $review = Invoke-ContinuousCoReviewCheckpointReview @reviewParams
    return [pscustomobject][ordered]@{ schema_version = '1.0'; dispatched = $true; decision = $decision; review = $review }
}
