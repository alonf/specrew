$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewExecutionValue {
    param(
        [AllowNull()]
        $Object,

        [Parameter(Mandatory)]
        [string] $Name,

        [AllowNull()]
        $DefaultValue = $null
    )

    if ($null -eq $Object) {
        return $DefaultValue
    }

    if (Test-ReviewerContractPropertyExists -Object $Object -Name $Name) {
        $value = Get-ReviewerContractPropertyValue -Object $Object -Name $Name
        if ($null -ne $value) {
            return $value
        }
    }

    return $DefaultValue
}

function Get-ContinuousCoReviewMutationSourceRoots {
    param(
        [AllowNull()]
        $Request
    )

    $changeSet = Get-ContinuousCoReviewExecutionValue -Object $Request -Name 'change_set'
    $changedPaths = @(
        foreach ($changedPath in @(Get-ContinuousCoReviewExecutionValue -Object $changeSet -Name 'changed_paths' -DefaultValue @())) {
            if (-not [string]::IsNullOrWhiteSpace([string] $changedPath)) {
                [string] $changedPath
            }
        }
    )

    if (@($changedPaths).Count -gt 0) {
        return @($changedPaths)
    }

    return @('scripts/internal/continuous-co-review', 'tests/continuous-co-review')
}

function New-ContinuousCoReviewExecutionFailureResult {
    param(
        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        [string] $Category,

        [Parameter(Mandatory)]
        [string] $Message,

        [AllowNull()]
        $SafeDetails,

        [AllowNull()]
        [string] $InvocationId,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $failure = New-ContinuousCoReviewInfrastructureFailure -RunId $Request.run_id -InvocationId $InvocationId -Category $Category -Message $Message -SafeDetails $SafeDetails -CreatedAt $CreatedAt
    return [pscustomobject][ordered]@{
        schema_version          = '1.0'
        run_id                  = $Request.run_id
        kind                    = 'infrastructure-failure'
        provider_invocation     = $null
        findings_result         = $null
        infrastructure_failure  = $failure
        fallback_used           = $false
        attempted_candidates    = @()
        request_bundle          = $null
        readonly_boundary       = 'fresh-context-request-bundle-only'
    }
}

function New-ContinuousCoReviewExecutionRequestBundle {
    param(
        [Parameter(Mandatory)]
        [string] $RunRoot,

        [Parameter(Mandatory)]
        $Request
    )

    New-Item -ItemType Directory -Path $RunRoot -Force | Out-Null
    $workspaceRoot = Join-Path $RunRoot '_request-bundles'
    New-Item -ItemType Directory -Path $workspaceRoot -Force | Out-Null
    $workspacePath = Join-Path $workspaceRoot $Request.run_id
    if (-not (Test-Path -LiteralPath $workspacePath -PathType Container)) {
        New-Item -ItemType Directory -Path $workspacePath -Force | Out-Null
    }

    $requestPath = Join-Path $workspacePath 'review-request.json'
    if (-not (Test-Path -LiteralPath $requestPath -PathType Leaf)) {
        $Request | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $requestPath -Encoding UTF8 -NoNewline
    }

    $requestHash = Get-ContinuousCoReviewExecutionValue -Object $Request -Name 'request_hash'
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        run_id         = $Request.run_id
        workspace_path = $workspacePath
        request_path   = $requestPath
        request_hash   = $requestHash
        immutable      = $true
    }
}

function Test-ContinuousCoReviewCandidateMatchesRequest {
    param(
        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        $Candidate
    )

    $providerRequest = Get-ContinuousCoReviewExecutionValue -Object $Request -Name 'provider_request'
    $requestedHost = Get-ContinuousCoReviewExecutionValue -Object $providerRequest -Name 'requested_host'
    $requestedModel = Get-ContinuousCoReviewExecutionValue -Object $providerRequest -Name 'requested_model'
    $candidateHost = Get-ContinuousCoReviewExecutionValue -Object $Candidate -Name 'host'
    $candidateModel = Get-ContinuousCoReviewExecutionValue -Object $Candidate -Name 'model'

    if (-not [string]::IsNullOrWhiteSpace([string] $requestedHost) -and $requestedHost -ne $candidateHost) {
        return $false
    }
    if (-not [string]::IsNullOrWhiteSpace([string] $requestedModel) -and $requestedModel -ne $candidateModel) {
        return $false
    }

    return $true
}

function Test-ContinuousCoReviewAvailabilityFallbackAllowed {
    param(
        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        $Failure,

        [Parameter(Mandatory)]
        $Candidate
    )

    $providerRequest = Get-ContinuousCoReviewExecutionValue -Object $Request -Name 'provider_request'
    $fallbackPolicy = [string] (Get-ContinuousCoReviewExecutionValue -Object $providerRequest -Name 'fallback_policy' -DefaultValue 'none')
    if ($fallbackPolicy -ne 'one-authorized-availability-fallback') {
        return $false
    }

    if (-not [bool] (Get-ContinuousCoReviewExecutionValue -Object $Failure -Name 'fallback_allowed' -DefaultValue $false)) {
        return $false
    }

    if (-not [bool] (Get-ContinuousCoReviewExecutionValue -Object $Candidate -Name 'authorized' -DefaultValue $false)) {
        return $false
    }

    return [bool] (Get-ContinuousCoReviewExecutionValue -Object $Candidate -Name 'exact_alternate_authorized' -DefaultValue $false)
}


function New-ContinuousCoReviewMutationInvalidatedAttemptResult {
    param(
        [Parameter(Mandatory)]
        $Request,

        [AllowNull()]
        $ProviderInvocation,

        [Parameter(Mandatory)]
        $MutationGuard,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $invocationId = if ($null -ne $ProviderInvocation) { $ProviderInvocation.invocation_id } else { $null }
    $failure = New-ContinuousCoReviewInfrastructureFailure -RunId $Request.run_id -InvocationId $invocationId -Category 'workspace-mutation-invalidated' -Message 'Reviewer execution mutated source, Git, or Specrew state and was invalidated as unsafe.' -SafeDetails ([pscustomobject][ordered]@{ mutation_guard = $MutationGuard }) -CreatedAt $CreatedAt
    return [pscustomobject][ordered]@{
        kind                   = 'infrastructure-failure'
        provider_invocation    = $ProviderInvocation
        findings_result        = $null
        infrastructure_failure = $failure
        mutation_guard         = $MutationGuard
    }
}

function Invoke-ContinuousCoReviewGuardedAdapterAttempt {
    param(
        [Parameter(Mandatory)]
        [scriptblock] $AdapterInvoker,

        [Parameter(Mandatory)]
        $Candidate,

        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        $RequestBundle,

        [Parameter(Mandatory)]
        [int] $AttemptNumber,

        [string] $RepoRoot,

        [scriptblock] $GitCommand,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    if ([string]::IsNullOrWhiteSpace($RepoRoot) -or -not (Get-Command -Name 'New-ContinuousCoReviewWorkspaceMutationSnapshot' -ErrorAction SilentlyContinue)) {
        return & $AdapterInvoker $Candidate $Request $RequestBundle $AttemptNumber
    }

    $excludeRoots = @($RequestBundle.workspace_path)
    $sourceRoots = @(Get-ContinuousCoReviewMutationSourceRoots -Request $Request)
    $before = New-ContinuousCoReviewWorkspaceMutationSnapshot -RepoRoot $RepoRoot -SourceRoots $sourceRoots -ExcludeRoots $excludeRoots -GitCommand $GitCommand -CreatedAt $CreatedAt
    $attemptResult = & $AdapterInvoker $Candidate $Request $RequestBundle $AttemptNumber
    $after = New-ContinuousCoReviewWorkspaceMutationSnapshot -RepoRoot $RepoRoot -SourceRoots $sourceRoots -ExcludeRoots $excludeRoots -GitCommand $GitCommand -CreatedAt $CreatedAt
    $mutationGuard = Compare-ContinuousCoReviewWorkspaceMutationSnapshot -Before $before -After $after
    if ([bool] $mutationGuard.mutated) {
        return New-ContinuousCoReviewMutationInvalidatedAttemptResult -Request $Request -ProviderInvocation $attemptResult.provider_invocation -MutationGuard $mutationGuard -CreatedAt $CreatedAt
    }

    if ($null -ne $attemptResult -and ($attemptResult.PSObject.Properties.Name -notcontains 'mutation_guard')) {
        $attemptResult | Add-Member -NotePropertyName 'mutation_guard' -NotePropertyValue $mutationGuard
    }
    return $attemptResult
}

function Invoke-ContinuousCoReviewDefaultAdapter {
    param(
        [Parameter(Mandatory)]
        $Candidate,

        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        $RequestBundle,

        [Parameter(Mandatory)]
        [int] $AttemptNumber,

        [string] $SchemaRoot,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $functionName = Get-ContinuousCoReviewReviewerHostAdapterFunctionName -AdapterId $Candidate.adapter_id
    if ([string]::IsNullOrWhiteSpace($functionName)) {
        return [pscustomobject][ordered]@{
            kind                   = 'infrastructure-failure'
            provider_invocation    = $null
            findings_result        = $null
            infrastructure_failure = New-ContinuousCoReviewInfrastructureFailure -RunId $Request.run_id -Category 'missing-provider' -Message 'No reviewer adapter function is registered for the requested adapter id.' -SafeDetails ([pscustomobject]@{ adapter_id = $Candidate.adapter_id }) -CreatedAt $CreatedAt
        }
    }

    $command = Get-Command -Name $functionName -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        return [pscustomobject][ordered]@{
            kind                   = 'infrastructure-failure'
            provider_invocation    = $null
            findings_result        = $null
            infrastructure_failure = New-ContinuousCoReviewInfrastructureFailure -RunId $Request.run_id -Category 'missing-provider' -Message 'Reviewer adapter command is not loaded.' -SafeDetails ([pscustomobject]@{ adapter_id = $Candidate.adapter_id }) -CreatedAt $CreatedAt
        }
    }

    return & $command -Request $Request -RequestBundlePath $RequestBundle.request_path -SchemaRoot $SchemaRoot -Candidate $Candidate -AttemptNumber $AttemptNumber -CreatedAt $CreatedAt
}

function Copy-ContinuousCoReviewExecutionAttemptResult {
    param(
        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        $AttemptResult,

        [Parameter(Mandatory)]
        $RequestBundle,

        [Parameter(Mandatory)]
        [bool] $FallbackUsed,

        [Parameter(Mandatory)]
        [object[]] $AttemptedCandidates
    )

    return [pscustomobject][ordered]@{
        schema_version          = '1.0'
        run_id                  = $Request.run_id
        kind                    = $AttemptResult.kind
        provider_invocation     = $AttemptResult.provider_invocation
        findings_result         = $AttemptResult.findings_result
        infrastructure_failure  = $AttemptResult.infrastructure_failure
        fallback_used           = $FallbackUsed
        attempted_candidates    = @($AttemptedCandidates)
        request_bundle          = $RequestBundle
        readonly_boundary       = 'fresh-context-request-bundle-only'
        mutation_guard          = Get-ContinuousCoReviewExecutionValue -Object $AttemptResult -Name 'mutation_guard'
    }
}

function Invoke-ContinuousCoReviewReviewerExecution {
    param(
        [Parameter(Mandatory)]
        $Request,

        [AllowNull()]
        $RequestBundle,

        [Parameter(Mandatory)]
        [string] $RunRoot,

        [string] $SchemaRoot,

        [Parameter(Mandatory)]
        [object[]] $Candidates,

        [scriptblock] $InvokeAdapter,

        [AllowNull()]
        [string] $ReadOnlyRoot,

        [scriptblock] $GitCommand,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $bundle = if ($null -ne $RequestBundle) {
        $RequestBundle
    }
    else {
        New-ContinuousCoReviewExecutionRequestBundle -RunRoot $RunRoot -Request $Request
    }

    $guardRepoRoot = if (-not [string]::IsNullOrWhiteSpace($ReadOnlyRoot)) { (Resolve-Path -LiteralPath $ReadOnlyRoot).Path } else { (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path }

    $authorizedCandidates = @(
        foreach ($candidate in @($Candidates)) {
            if ([bool] (Get-ContinuousCoReviewExecutionValue -Object $candidate -Name 'authorized' -DefaultValue (-not [string]::IsNullOrWhiteSpace([string] (Get-ContinuousCoReviewExecutionValue -Object $candidate -Name 'authorization_ref'))))) {
                $candidate
            }
        }
    )

    if (@($authorizedCandidates).Count -eq 0) {
        $failureResult = New-ContinuousCoReviewExecutionFailureResult -Request $Request -Category 'unauthorized-provider' -Message 'No authorized reviewer candidate was provided.' -SafeDetails ([pscustomobject]@{ candidate_count = @($Candidates).Count }) -CreatedAt $CreatedAt
        $failureResult.request_bundle = $bundle
        return $failureResult
    }

    $primaryCandidate = $authorizedCandidates[0]
    if (-not (Test-ContinuousCoReviewCandidateMatchesRequest -Request $Request -Candidate $primaryCandidate)) {
        $failureResult = New-ContinuousCoReviewExecutionFailureResult -Request $Request -Category 'unavailable-requested-model' -Message 'The selected reviewer candidate does not match the requested host/model authorization.' -SafeDetails ([pscustomobject]@{ candidate_host = $primaryCandidate.host; candidate_model = $primaryCandidate.model }) -CreatedAt $CreatedAt
        $failureResult.request_bundle = $bundle
        return $failureResult
    }

    $attempted = New-Object System.Collections.ArrayList
    $adapterInvoker = if ($InvokeAdapter) {
        $InvokeAdapter
    }
    else {
        {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            Invoke-ContinuousCoReviewDefaultAdapter -Candidate $Candidate -Request $Request -RequestBundle $RequestBundle -AttemptNumber $AttemptNumber -SchemaRoot $SchemaRoot -CreatedAt $CreatedAt
        }
    }

    [void] $attempted.Add($primaryCandidate)
    $primaryResult = Invoke-ContinuousCoReviewGuardedAdapterAttempt -AdapterInvoker $adapterInvoker -Candidate $primaryCandidate -Request $Request -RequestBundle $bundle -AttemptNumber 1 -RepoRoot $guardRepoRoot -GitCommand $GitCommand -CreatedAt $CreatedAt
    if ($primaryResult.kind -eq 'findings-result') {
        return Copy-ContinuousCoReviewExecutionAttemptResult -Request $Request -AttemptResult $primaryResult -RequestBundle $bundle -FallbackUsed:$false -AttemptedCandidates @($attempted)
    }

    $fallbackCandidate = $null
    foreach ($candidate in @($authorizedCandidates | Select-Object -Skip 1)) {
        if (Test-ContinuousCoReviewAvailabilityFallbackAllowed -Request $Request -Failure $primaryResult.infrastructure_failure -Candidate $candidate) {
            $fallbackCandidate = $candidate
            break
        }
    }

    if ($null -eq $fallbackCandidate) {
        return Copy-ContinuousCoReviewExecutionAttemptResult -Request $Request -AttemptResult $primaryResult -RequestBundle $bundle -FallbackUsed:$false -AttemptedCandidates @($attempted)
    }

    [void] $attempted.Add($fallbackCandidate)
    $fallbackResult = Invoke-ContinuousCoReviewGuardedAdapterAttempt -AdapterInvoker $adapterInvoker -Candidate $fallbackCandidate -Request $Request -RequestBundle $bundle -AttemptNumber 2 -RepoRoot $guardRepoRoot -GitCommand $GitCommand -CreatedAt $CreatedAt
    return Copy-ContinuousCoReviewExecutionAttemptResult -Request $Request -AttemptResult $fallbackResult -RequestBundle $bundle -FallbackUsed:$true -AttemptedCandidates @($attempted)
}
