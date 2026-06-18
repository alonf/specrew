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


function New-ContinuousCoReviewReviewerInstructionMetadata {
    param(
        [string] $CanonicalPath = 'scripts/internal/continuous-co-review/code-review-agent.md',
        [string[]] $MirrorRefs = @(),
        [string] $RepoRoot
    )

    $root = if ($RepoRoot) { (Resolve-Path -LiteralPath $RepoRoot).Path } else { (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path }
    $instructionPath = Join-Path $root $CanonicalPath
    if (-not (Test-Path -LiteralPath $instructionPath -PathType Leaf)) {
        throw "Canonical reviewer instruction source not found: $instructionPath"
    }

    $content = Get-Content -LiteralPath $instructionPath -Raw
    return [pscustomobject][ordered]@{
        schema_version = 'reviewer-instruction.v1'
        canonical_path = $CanonicalPath.Replace('\\', '/')
        content_hash   = "sha256:$(Get-ReviewerContractSha256Hex -Text $content)"
        mirror_refs    = @($MirrorRefs)
    }
}

function New-ContinuousCoReviewDesignContextFromRefs {
    param(
        [string[]] $DesignContextRefs = @(),
        [string] $RepoRoot
    )

    $root = if ($RepoRoot) { (Resolve-Path -LiteralPath $RepoRoot).Path } else { (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path }
    $sources = @()
    $chunks = @()
    foreach ($ref in @($DesignContextRefs)) {
        if ([string]::IsNullOrWhiteSpace($ref)) { continue }
        $normalizedRef = $ref.Replace('\\', '/')
        $candidate = Join-Path $root $normalizedRef
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $content = Get-Content -LiteralPath $candidate -Raw
            $chunks += "## $normalizedRef`n$content"
            $hash = "sha256:$(Get-ReviewerContractSha256Hex -Text $content)"
        }
        else {
            $chunks += "## $normalizedRef`nDesign context source reference supplied; file content was not bundled by this caller."
            $hash = "sha256:$(Get-ReviewerContractSha256Hex -Text $normalizedRef)"
        }
        $sources += [pscustomobject][ordered]@{ path = $normalizedRef; content_hash = $hash }
    }

    if ($sources.Count -eq 0) {
        throw 'ReviewRequest.v2 requires at least one design context source.'
    }

    return [pscustomobject][ordered]@{
        content = ($chunks -join "`n`n")
        sources = @($sources)
    }
}

function New-ContinuousCoReviewDefaultVisibilityPolicy {
    return [pscustomobject][ordered]@{
        policy_id        = 'proposal-197-review-visibility.v1'
        allowed_context  = @('ReviewRequest.v2 design_context', 'canonical reviewer instruction', 'exact change_set diff_content', 'prior_findings')
        excluded_context = @('secrets', 'token stores', 'raw transcripts', 'environment variables', 'ambient machine state', 'unrelated temporary files')
    }
}

function New-ContinuousCoReviewDefaultDoPolicy {
    return [pscustomobject][ordered]@{
        policy_id          = 'proposal-197-review-do-policy.v1'
        allowed_actions    = @('read supplied prompt context', 'return FindingsResult.v1 JSON')
        forbidden_actions  = @('modify source files', 'modify Git state', 'modify Specrew state', 'write fixes', 'run live web search', 'install dependencies')
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

        [string[]] $DesignContextRefs = @(),

        [AllowNull()]
        $DesignContext,

        [string[]] $AllowedPaths = @(),

        [string[]] $ForbiddenPaths = @(),

        [Parameter(Mandatory)]
        $ProviderRequest,

        [AllowNull()]
        $ReviewerInstruction,

        [string] $ReviewerInstructionPath = 'scripts/internal/continuous-co-review/code-review-agent.md',

        [string[]] $ReviewerInstructionMirrorRefs = @(),

        [int] $RoundNumber = 1,

        [object[]] $PriorFindings = @(),

        [AllowNull()]
        $VisibilityPolicy,

        [AllowNull()]
        $DoPolicy,

        [datetime] $CreatedAt = [datetime]::UtcNow,

        [string] $SchemaRoot,

        [string] $RepoRoot
    )

    foreach ($changedPath in @($ChangeSet.changed_paths)) {
        if (Test-ContinuousCoReviewForbiddenPath -ChangedPath $changedPath -ForbiddenPaths $ForbiddenPaths) {
            throw "Review request change-set crosses forbidden path policy: $changedPath"
        }
    }

    $diffContent = $null
    if (Test-ReviewerContractPropertyExists -Object $ChangeSet -Name 'diff_content') {
        $diffContent = [string] (Get-ReviewerContractPropertyValue -Object $ChangeSet -Name 'diff_content')
    }
    elseif (Test-ReviewerContractPropertyExists -Object $ChangeSet -Name 'diff_inline') {
        $diffContent = [string] (Get-ReviewerContractPropertyValue -Object $ChangeSet -Name 'diff_inline')
    }
    if ([string]::IsNullOrWhiteSpace($diffContent)) {
        throw 'ReviewRequest.v2 requires exact diff/change-set content in change_set.diff_content or change_set.diff_inline.'
    }

    $changeSetDto = [pscustomobject][ordered]@{
        baseline_ref          = $ChangeSet.baseline_ref
        diff_hash             = $ChangeSet.diff_hash
        diff_content          = $diffContent
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

    $designContextDto = if ($null -ne $DesignContext) { $DesignContext } else { New-ContinuousCoReviewDesignContextFromRefs -DesignContextRefs $DesignContextRefs -RepoRoot $RepoRoot }
    $instructionDto = if ($null -ne $ReviewerInstruction) { $ReviewerInstruction } else { New-ContinuousCoReviewReviewerInstructionMetadata -CanonicalPath $ReviewerInstructionPath -MirrorRefs $ReviewerInstructionMirrorRefs -RepoRoot $RepoRoot }
    $visibilityPolicyDto = if ($null -ne $VisibilityPolicy) { $VisibilityPolicy } else { New-ContinuousCoReviewDefaultVisibilityPolicy }
    $doPolicyDto = if ($null -ne $DoPolicy) { $DoPolicy } else { New-ContinuousCoReviewDefaultDoPolicy }

    $requestWithoutHash = [pscustomobject][ordered]@{
        schema_version       = '2.0'
        run_id               = $RunId
        checkpoint_id        = $CheckpointId
        baseline_ref         = $BaselineRef
        review_kind          = 'code-change-set'
        change_set           = $changeSetDto
        design_context       = $designContextDto
        reviewer_instruction = $instructionDto
        round_number         = [int] $RoundNumber
        prior_findings       = @($PriorFindings)
        visibility_policy    = $visibilityPolicyDto
        do_policy            = $doPolicyDto
        allowed_paths        = @($AllowedPaths)
        forbidden_paths      = @($ForbiddenPaths)
        provider_request     = Copy-ContinuousCoReviewProviderRequest -ProviderRequest $ProviderRequest
        output_contract      = 'FindingsResult.v1'
        created_at           = $CreatedAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    $requestHash = "sha256:$(Get-ReviewerContractSha256Hex -Text (ConvertTo-ReviewerContractCanonicalJson -InputObject $requestWithoutHash))"
    $request = [pscustomobject][ordered]@{
        schema_version       = $requestWithoutHash.schema_version
        run_id               = $requestWithoutHash.run_id
        checkpoint_id        = $requestWithoutHash.checkpoint_id
        baseline_ref         = $requestWithoutHash.baseline_ref
        review_kind          = $requestWithoutHash.review_kind
        change_set           = $requestWithoutHash.change_set
        design_context       = $requestWithoutHash.design_context
        reviewer_instruction = $requestWithoutHash.reviewer_instruction
        round_number         = $requestWithoutHash.round_number
        prior_findings       = $requestWithoutHash.prior_findings
        visibility_policy    = $requestWithoutHash.visibility_policy
        do_policy            = $requestWithoutHash.do_policy
        allowed_paths        = $requestWithoutHash.allowed_paths
        forbidden_paths      = $requestWithoutHash.forbidden_paths
        provider_request     = $requestWithoutHash.provider_request
        output_contract      = $requestWithoutHash.output_contract
        request_hash         = $requestHash
        created_at           = $requestWithoutHash.created_at
    }

    if ($SchemaRoot) {
        Assert-ReviewerContractObject -ContractName 'ReviewRequest' -SchemaRoot $SchemaRoot -InputObject $request | Out-Null
    }

    return $request
}
