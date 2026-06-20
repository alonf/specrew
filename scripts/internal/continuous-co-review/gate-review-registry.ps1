$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T059 / FR-032: the gate-keyed registry. A single host Stop-hook call routes through the
# dispatcher, which consults THIS registry: a lifecycle stage maps to the reviewer registered
# for it. Iteration 003 registers exactly ONE - code review at the implement checkpoint.
# design-lens / plan / tasks / spec are deliberately UNREGISTERED no-op extension points: a
# future per-gate reviewer is added as a registry entry HERE, never as a hook or dispatcher
# change. This is what keeps "fire on every stop" from meaning "review on every stop".

function Get-ContinuousCoReviewGateReviewRegistry {
    return @(
        [pscustomobject][ordered]@{
            stage         = 'implement'
            reviewer_kind = 'code-review'
            runner        = 'checkpoint-review-orchestrator'
            description   = 'Fresh-context co-review of the implement increment against the design contract.'
        }
    )
}

function Get-ContinuousCoReviewRegisteredReviewer {
    param(
        [Parameter(Mandatory)]
        [string] $Stage,

        [object[]] $Registry
    )

    $resolvedRegistry = if ($PSBoundParameters.ContainsKey('Registry')) { @($Registry) } else { @(Get-ContinuousCoReviewGateReviewRegistry) }
    foreach ($entry in $resolvedRegistry) {
        $entryStage = [string] (Get-ReviewerContractPropertyValue -Object $entry -Name 'stage')
        if ($entryStage -eq $Stage) {
            return $entry
        }
    }

    return $null
}

function Test-ContinuousCoReviewStageRegistered {
    param(
        [Parameter(Mandatory)]
        [string] $Stage,

        [object[]] $Registry
    )

    $registryParam = @{}
    if ($PSBoundParameters.ContainsKey('Registry')) { $registryParam['Registry'] = $Registry }
    return ($null -ne (Get-ContinuousCoReviewRegisteredReviewer -Stage $Stage @registryParam))
}
