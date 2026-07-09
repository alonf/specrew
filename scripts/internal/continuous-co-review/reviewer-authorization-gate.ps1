$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Test-ContinuousCoReviewReviewerAuthorization {
    param(
        [Parameter(Mandatory)]
        $Candidate
    )

    $costClass = [string] (Get-ContinuousCoReviewCatalogValue -Object $Candidate -Name 'cost_class' -DefaultValue 'non-default')
    $modelSource = [string] (Get-ContinuousCoReviewCatalogValue -Object $Candidate -Name 'model_source' -DefaultValue 'human-entered')
    $authorizationRef = Get-ContinuousCoReviewCatalogValue -Object $Candidate -Name 'authorization_ref'
    $requiresExplicitAuthorization = (
        ($costClass -ne 'default') -or
        ($modelSource -eq 'human-entered') -or
        ([string]::IsNullOrWhiteSpace([string] $authorizationRef))
    )

    $authorized = if ($requiresExplicitAuthorization) {
        -not [string]::IsNullOrWhiteSpace([string] $authorizationRef)
    }
    else {
        $true
    }

    return [pscustomobject][ordered]@{
        schema_version     = '1.0'
        authorized         = [bool] $authorized
        category           = if ($authorized) { 'authorized' } else { 'unauthorized-provider' }
        authorization_ref  = if ([string]::IsNullOrWhiteSpace([string] $authorizationRef)) { $null } else { [string] $authorizationRef }
        host               = Get-ContinuousCoReviewCatalogValue -Object $Candidate -Name 'host'
        model              = Get-ContinuousCoReviewCatalogValue -Object $Candidate -Name 'model'
        adapter_id         = Get-ContinuousCoReviewCatalogValue -Object $Candidate -Name 'adapter_id'
        authorization_mode = if ($requiresExplicitAuthorization) { 'explicit' } else { 'default-local' }
    }
}
