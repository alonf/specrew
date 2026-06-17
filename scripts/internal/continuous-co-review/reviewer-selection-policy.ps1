$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Select-ContinuousCoReviewReviewerCandidate {
    param(
        [Parameter(Mandatory)]
        $Catalog,

        [AllowNull()]
        [string] $RequestedHost,

        [AllowNull()]
        [string] $RequestedModel,

        [switch] $FallbackOnly
    )

    $eligible = @(
        foreach ($candidate in @($Catalog.hosts)) {
            if (-not [bool] $candidate.allowed) { continue }
            if (-not [bool] $candidate.installed) { continue }
            if ($FallbackOnly -and -not [bool] $candidate.fallback_allowed) { continue }
            if (-not [string]::IsNullOrWhiteSpace($RequestedHost) -and $candidate.host -ne $RequestedHost) { continue }
            if (-not [string]::IsNullOrWhiteSpace($RequestedModel) -and $candidate.model -ne $RequestedModel) { continue }

            $authorization = Test-ContinuousCoReviewReviewerAuthorization -Candidate $candidate
            if (-not $authorization.authorized) { continue }

            [pscustomobject][ordered]@{
                host                       = $candidate.host
                model                      = $candidate.model
                adapter_id                 = $candidate.adapter_id
                review_class_rank          = [int] $candidate.review_class_rank
                model_source               = $candidate.model_source
                cost_class                 = $candidate.cost_class
                authorization_ref          = $authorization.authorization_ref
                fallback_allowed           = [bool] $candidate.fallback_allowed
                authorized                 = $true
                exact_alternate_authorized = [bool] $candidate.fallback_allowed
                timeout_seconds            = [int] (Get-ContinuousCoReviewCatalogValue -Object $candidate -Name 'timeout_seconds' -DefaultValue 30)
                selection_reason           = 'highest-authorized-review-class-rank'
            }
        }
    )

    $selection = @($eligible | Sort-Object -Property @{ Expression = 'review_class_rank'; Descending = $true }, @{ Expression = 'host'; Descending = $false } | Select-Object -First 1)
    if (@($selection).Count -eq 0) {
        return $null
    }

    return $selection[0]
}
