$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewReviewerModelCapability {
    param(
        [Parameter(Mandatory)]
        $Catalog,

        [AllowNull()]
        [string] $RequestedHost,

        [AllowNull()]
        [string] $RequestedModel
    )

    $available = @(
        foreach ($candidate in @($Catalog.hosts)) {
            if (-not [bool] $candidate.allowed) { continue }
            if (-not [bool] $candidate.installed) { continue }
            if (-not [string]::IsNullOrWhiteSpace($RequestedHost) -and $candidate.host -ne $RequestedHost) { continue }
            if (-not [string]::IsNullOrWhiteSpace($RequestedModel) -and $candidate.model -ne $RequestedModel) { continue }

            [pscustomobject][ordered]@{
                host              = $candidate.host
                model             = $candidate.model
                adapter_id        = $candidate.adapter_id
                review_class_rank = [int] $candidate.review_class_rank
                model_source      = $candidate.model_source
                cost_class        = $candidate.cost_class
                authorization_ref = $candidate.authorization_ref
                fallback_allowed  = [bool] $candidate.fallback_allowed
                discovery_order   = @('explicit-config', 'allowlist', 'cli-model-list', 'cli-help-introspection', 'human-entered')
            }
        }
    )

    return [pscustomobject][ordered]@{
        schema_version     = '1.0'
        requested_host     = $RequestedHost
        requested_model    = $RequestedModel
        available          = @($available)
        discovery_strategy = 'explicit-config-first'
    }
}
