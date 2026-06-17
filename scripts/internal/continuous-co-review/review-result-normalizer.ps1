$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function New-ContinuousCoReviewNormalizedFailure {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [AllowNull()]
        [string] $InvocationId,

        [Parameter(Mandatory)]
        [string] $Category,

        [Parameter(Mandatory)]
        [string] $Message,

        [AllowNull()]
        $SafeDetails,

        [datetime] $CreatedAt
    )

    return [pscustomobject][ordered]@{
        kind                   = 'infrastructure-failure'
        findings_result        = $null
        infrastructure_failure = New-ContinuousCoReviewInfrastructureFailure `
            -RunId $RunId `
            -InvocationId $InvocationId `
            -Category $Category `
            -Message $Message `
            -SafeDetails $SafeDetails `
            -CreatedAt $CreatedAt
    }
}

function ConvertTo-ContinuousCoReviewNormalizedResult {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [AllowNull()]
        [string] $InvocationId,

        [Parameter(Mandatory)]
        [int] $ExitCode,

        [AllowNull()]
        [AllowEmptyString()]
        [string] $Stdout,

        [bool] $TimedOut = $false,

        [string] $SchemaRoot,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    if ($TimedOut) {
        return New-ContinuousCoReviewNormalizedFailure -RunId $RunId -InvocationId $InvocationId -Category 'timeout' -Message 'Reviewer process exceeded the configured timeout.' -SafeDetails ([pscustomobject]@{ invocation_id = $InvocationId }) -CreatedAt $CreatedAt
    }

    if ($ExitCode -ne 0) {
        return New-ContinuousCoReviewNormalizedFailure -RunId $RunId -InvocationId $InvocationId -Category 'nonzero-exit' -Message 'Reviewer process exited with a nonzero code.' -SafeDetails ([pscustomobject]@{ exit_code = $ExitCode; invocation_id = $InvocationId }) -CreatedAt $CreatedAt
    }

    if ([string]::IsNullOrWhiteSpace($Stdout)) {
        return New-ContinuousCoReviewNormalizedFailure -RunId $RunId -InvocationId $InvocationId -Category 'empty-stdout' -Message 'Reviewer process returned no stdout.' -SafeDetails ([pscustomobject]@{ invocation_id = $InvocationId }) -CreatedAt $CreatedAt
    }

    try {
        $result = $Stdout | ConvertFrom-Json -Depth 100
    }
    catch {
        return New-ContinuousCoReviewNormalizedFailure -RunId $RunId -InvocationId $InvocationId -Category 'invalid-json' -Message 'Reviewer stdout was not valid JSON.' -SafeDetails ([pscustomobject]@{ parser = 'ConvertFrom-Json'; invocation_id = $InvocationId }) -CreatedAt $CreatedAt
    }

    $validation = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $SchemaRoot -InputObject $result
    if (-not $validation.Valid) {
        return New-ContinuousCoReviewNormalizedFailure -RunId $RunId -InvocationId $InvocationId -Category 'schema-mismatch' -Message 'Reviewer JSON did not match FindingsResult.' -SafeDetails ([pscustomobject]@{ contract = 'FindingsResult'; error_count = @($validation.Errors).Count; invocation_id = $InvocationId }) -CreatedAt $CreatedAt
    }

    return [pscustomobject][ordered]@{
        kind                   = 'findings-result'
        findings_result        = $result
        infrastructure_failure = $null
    }
}
