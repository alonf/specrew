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

        [AllowNull()]
        [string] $CodeWriterHost,

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

    $rankedEligible = @($eligible | Sort-Object -Property @{ Expression = 'review_class_rank'; Descending = $true }, @{ Expression = 'host'; Descending = $false })
    # HOST-NEUTRAL independence preference (D-197-I010-002 / FR-016+SEC-004): prefer the STRONGEST
    # eligible candidate on a DIFFERENT harness than the code-writer - a pure policy over catalog
    # data, valid for any host including ones added later. Host specifics (names, binaries, flags)
    # live ONLY in reviewer-host-catalog.ps1; this core never names a harness.
    $preferredIndependent = $false
    $selection = @()
    if ([string]::IsNullOrWhiteSpace($RequestedHost) -and -not [string]::IsNullOrWhiteSpace($CodeWriterHost)) {
        $selection = @($rankedEligible | Where-Object { $_.host -ne $CodeWriterHost } | Select-Object -First 1)
        if (@($selection).Count -gt 0) { $preferredIndependent = $true }
    }

    if (@($selection).Count -eq 0) {
        $selection = @($rankedEligible | Select-Object -First 1)
    }

    if (@($selection).Count -eq 0) {
        return $null
    }

    if (-not [string]::IsNullOrWhiteSpace($RequestedHost)) {
        # honour-or-surface --host (T093/FR-035): an explicit request is HONOURED (the filter above
        # restricted eligibility to it); the caller surfaces the reason when it cannot be.
        $selection[0].selection_reason = 'requested-host-honoured'
    }
    elseif ($preferredIndependent) {
        $selection[0].selection_reason = 'preferred-independent-reviewer-for-code-writer-host'
    }

    # T093/FR-035 + SEC-004 (iter-009 D1): INDEPENDENCE is first-class selection evidence - a same-host
    # review fires immediately as a LABELLED fallback (never blocks, never silently substitutes), and
    # the label feeds the D4 tiered-evidence gate. 'unverified' = the code-writer host is unknown, so
    # independence cannot be asserted (the gate treats it as NOT independent - conservative).
    $independence = if ([string]::IsNullOrWhiteSpace($CodeWriterHost)) { 'unverified' }
    elseif ($selection[0].host -ne $CodeWriterHost) { 'independent' }
    else { 'same-host' }
    $selection[0] | Add-Member -NotePropertyName 'independence' -NotePropertyValue $independence -Force
    if ($independence -eq 'same-host' -and [string]::IsNullOrWhiteSpace($RequestedHost)) {
        $selection[0].selection_reason = 'same-host-fallback-no-independent-authorized'
    }

    return $selection[0]
}
