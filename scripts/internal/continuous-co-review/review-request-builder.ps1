$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Test-ContinuousCoReviewForbiddenPath {
    param(
        [Parameter(Mandatory)]
        [string] $ChangedPath,

        [string[]] $ForbiddenPaths = @()
    )

    $normalizedChangedPath = $ChangedPath.Replace('\', '/')
    foreach ($forbiddenPath in @($ForbiddenPaths)) {
        if ([string]::IsNullOrWhiteSpace($forbiddenPath)) {
            continue
        }

        $normalizedForbiddenPath = $forbiddenPath.Replace('\', '/')
        if ($normalizedForbiddenPath.EndsWith('/')) {
            if ($normalizedChangedPath.StartsWith($normalizedForbiddenPath)) {
                return $true
            }
        }
        elseif ($normalizedChangedPath -eq $normalizedForbiddenPath) {
            return $true
        }
    }

    return $false
}

function Copy-ContinuousCoReviewProviderRequest {
    param(
        [Parameter(Mandatory)]
        $ProviderRequest
    )

    $fallbackPolicy = if (Test-ReviewerContractPropertyExists -Object $ProviderRequest -Name 'fallback_policy') {
        Get-ReviewerContractPropertyValue -Object $ProviderRequest -Name 'fallback_policy'
    }
    else {
        'none'
    }

    return [pscustomobject][ordered]@{
        requested_host    = Get-ReviewerContractPropertyValue -Object $ProviderRequest -Name 'requested_host'
        requested_model   = Get-ReviewerContractPropertyValue -Object $ProviderRequest -Name 'requested_model'
        authorization_ref = Get-ReviewerContractPropertyValue -Object $ProviderRequest -Name 'authorization_ref'
        timeout_seconds   = [int] (Get-ReviewerContractPropertyValue -Object $ProviderRequest -Name 'timeout_seconds')
        fallback_policy   = $fallbackPolicy
    }
}

function New-ContinuousCoReviewRequest {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        [string] $BaselineRef,

        [Parameter(Mandatory)]
        $ChangeSet,

        [Parameter(Mandatory)]
        [string[]] $DesignContextRefs,

        [string[]] $AllowedPaths = @(),

        [string[]] $ForbiddenPaths = @(),

        [Parameter(Mandatory)]
        $ProviderRequest,

        [datetime] $CreatedAt = [datetime]::UtcNow,

        [string] $SchemaRoot
    )

    foreach ($changedPath in @($ChangeSet.changed_paths)) {
        if (Test-ContinuousCoReviewForbiddenPath -ChangedPath $changedPath -ForbiddenPaths $ForbiddenPaths) {
            throw "Review request change-set crosses forbidden path policy: $changedPath"
        }
    }

    $changeSetDto = [pscustomobject][ordered]@{
        baseline_ref          = $ChangeSet.baseline_ref
        diff_hash             = $ChangeSet.diff_hash
        changed_paths         = @($ChangeSet.changed_paths)
        reviewable_path_count = [int] $ChangeSet.reviewable_path_count
        excluded_paths        = @($ChangeSet.excluded_paths)
    }
    if (Test-ReviewerContractPropertyExists -Object $ChangeSet -Name 'diff_ref') {
        $changeSetDto | Add-Member -NotePropertyName 'diff_ref' -NotePropertyValue $ChangeSet.diff_ref
    }
    if (Test-ReviewerContractPropertyExists -Object $ChangeSet -Name 'diff_inline') {
        $changeSetDto | Add-Member -NotePropertyName 'diff_inline' -NotePropertyValue $ChangeSet.diff_inline
    }

    $requestWithoutHash = [pscustomobject][ordered]@{
        schema_version      = '1.0'
        run_id              = $RunId
        checkpoint_id       = $CheckpointId
        baseline_ref        = $BaselineRef
        review_kind         = 'code-change-set'
        change_set          = $changeSetDto
        design_context_refs = @($DesignContextRefs)
        allowed_paths       = @($AllowedPaths)
        forbidden_paths     = @($ForbiddenPaths)
        provider_request    = Copy-ContinuousCoReviewProviderRequest -ProviderRequest $ProviderRequest
        output_contract     = 'FindingsResult.v1'
        created_at          = $CreatedAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    $requestHash = "sha256:$(Get-ReviewerContractSha256Hex -Text (ConvertTo-ReviewerContractCanonicalJson -InputObject $requestWithoutHash))"
    $request = [pscustomobject][ordered]@{
        schema_version      = $requestWithoutHash.schema_version
        run_id              = $requestWithoutHash.run_id
        checkpoint_id       = $requestWithoutHash.checkpoint_id
        baseline_ref        = $requestWithoutHash.baseline_ref
        review_kind         = $requestWithoutHash.review_kind
        change_set          = $requestWithoutHash.change_set
        design_context_refs = $requestWithoutHash.design_context_refs
        allowed_paths       = $requestWithoutHash.allowed_paths
        forbidden_paths     = $requestWithoutHash.forbidden_paths
        provider_request    = $requestWithoutHash.provider_request
        output_contract     = $requestWithoutHash.output_contract
        request_hash        = $requestHash
        created_at          = $requestWithoutHash.created_at
    }

    if ($SchemaRoot) {
        Assert-ReviewerContractObject -ContractName 'ReviewRequest' -SchemaRoot $SchemaRoot -InputObject $request | Out-Null
    }

    return $request
}
