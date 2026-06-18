$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewAdapterValue {
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

function ConvertTo-ContinuousCoReviewAdapterIsoTimestamp {
    param(
        [datetime] $Timestamp = [datetime]::UtcNow
    )

    return $Timestamp.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
}


function Get-ContinuousCoReviewReadOnlyInvocationPolicy {
    param(
        [Parameter(Mandatory)]
        [string] $Executable,

        [string[]] $ArgumentList = @()
    )

    $normalizedExecutable = [System.IO.Path]::GetFileNameWithoutExtension($Executable).ToLowerInvariant()
    if ($normalizedExecutable -eq 'codex') {
        return [pscustomobject][ordered]@{
            requested = $true
            supported = $true
            detail    = 'codex exec --sandbox read-only'
            arguments = @('--sandbox', 'read-only')
        }
    }

    return [pscustomobject][ordered]@{
        requested = $true
        supported = $false
        detail    = 'host has no supported read-only/no-write flag in Proposal 197 adapter catalog; mutation guard remains authoritative'
        arguments = @()
    }
}

function Invoke-ContinuousCoReviewAdapterProcess {
    param(
        [Parameter(Mandatory)]
        [string] $Executable,

        [string[]] $ArgumentList = @(),

        [Parameter(Mandatory)]
        [string] $StandardInputPath,

        [int] $TimeoutSeconds = 30,

        [string] $WorkingDirectory
    )

    $processStart = [System.Diagnostics.ProcessStartInfo]::new()
    $processStart.FileName = $Executable
    foreach ($argument in @($ArgumentList)) {
        [void] $processStart.ArgumentList.Add($argument)
    }
    $processStart.RedirectStandardInput = $true
    $processStart.RedirectStandardOutput = $true
    $processStart.RedirectStandardError = $true
    $processStart.UseShellExecute = $false
    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        $processStart.WorkingDirectory = $WorkingDirectory
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $processStart
    try {
        [void] $process.Start()
        $requestText = Get-Content -LiteralPath $StandardInputPath -Raw
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.StandardInput.Write($requestText)
        $process.StandardInput.Close()
        $completed = $process.WaitForExit([Math]::Max(1, $TimeoutSeconds) * 1000)
        if (-not $completed) {
            $process.Kill($true)
            try { $process.WaitForExit() } catch { }
            return [pscustomobject][ordered]@{
                exit_code = $null
                stdout    = ''
                stderr    = ''
                timed_out = $true
            }
        }

        [void] $stderrTask.GetAwaiter().GetResult()
        return [pscustomobject][ordered]@{
            exit_code = $process.ExitCode
            stdout    = $stdoutTask.GetAwaiter().GetResult()
            stderr    = ''
            timed_out = $false
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            exit_code = -1
            stdout    = ''
            stderr    = ''
            timed_out = $false
            exception = $_.Exception.GetType().Name
        }
    }
    finally {
        $process.Dispose()
    }
}

function New-ContinuousCoReviewAdapterInvocation {
    param(
        [Parameter(Mandatory)]
        $Request,

        [AllowNull()]
        $Candidate,

        [Parameter(Mandatory)]
        [string] $AdapterId,

        [Parameter(Mandatory)]
        [string] $Executable,

        [string[]] $ArgumentList = @(),

        [int] $AttemptNumber = 1,

        [AllowNull()]
        [int] $ExitCode,

        [AllowNull()]
        [string] $FailureCategory,

        [datetime] $CreatedAt = [datetime]::UtcNow,

        [bool] $ReadOnlyModeRequested = $true,

        [bool] $ReadOnlyModeSupported = $false,

        [string] $ReadOnlyModeDetail = 'not-recorded'
    )

    $providerRequest = Get-ContinuousCoReviewAdapterValue -Object $Request -Name 'provider_request'
    $timeoutSeconds = [int] (Get-ContinuousCoReviewAdapterValue -Object $Candidate -Name 'timeout_seconds' -DefaultValue (Get-ContinuousCoReviewAdapterValue -Object $providerRequest -Name 'timeout_seconds' -DefaultValue 30))
    $requestedHost = Get-ContinuousCoReviewAdapterValue -Object $providerRequest -Name 'requested_host'
    $requestedModel = Get-ContinuousCoReviewAdapterValue -Object $providerRequest -Name 'requested_model'
    $actualHost = Get-ContinuousCoReviewAdapterValue -Object $Candidate -Name 'host' -DefaultValue $requestedHost
    $actualModel = Get-ContinuousCoReviewAdapterValue -Object $Candidate -Name 'model' -DefaultValue $requestedModel
    $timestamp = ConvertTo-ContinuousCoReviewAdapterIsoTimestamp -Timestamp $CreatedAt

    return [pscustomobject][ordered]@{
        schema_version         = '1.0'
        invocation_id          = "invocation-$($Request.run_id)-$AdapterId-$AttemptNumber"
        run_id                 = $Request.run_id
        attempt_number         = [int] $AttemptNumber
        adapter_id             = $AdapterId
        requested_host         = $requestedHost
        requested_model        = $requestedModel
        actual_host            = $actualHost
        actual_model           = $actualModel
        argv_summary           = @($Executable) + @($ArgumentList)
        working_directory_ref  = 'request-bundle-workspace'
        readonly_mode_requested = [bool] $ReadOnlyModeRequested
        readonly_mode_supported = [bool] $ReadOnlyModeSupported
        readonly_mode_detail    = $ReadOnlyModeDetail
        timeout_seconds        = $timeoutSeconds
        stdout_capture_policy  = 'parse-json-only'
        stderr_capture_policy  = 'status-only'
        exit_code              = $ExitCode
        failure_category       = $FailureCategory
        started_at             = $timestamp
        ended_at               = $timestamp
    }
}

function Invoke-ContinuousCoReviewReviewerHostAdapterCommand {
    param(
        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        [string] $RequestBundlePath,

        [Parameter(Mandatory)]
        [string] $AdapterId,

        [Parameter(Mandatory)]
        [string] $Executable,

        [string[]] $ArgumentList = @(),

        [string] $SchemaRoot,

        [scriptblock] $InvokeProcess,

        [AllowNull()]
        $Candidate,

        [int] $AttemptNumber = 1,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $providerRequest = Get-ContinuousCoReviewAdapterValue -Object $Request -Name 'provider_request'
    $timeoutSeconds = [int] (Get-ContinuousCoReviewAdapterValue -Object $Candidate -Name 'timeout_seconds' -DefaultValue (Get-ContinuousCoReviewAdapterValue -Object $providerRequest -Name 'timeout_seconds' -DefaultValue 30))
    $workingDirectory = Split-Path -Parent $RequestBundlePath

    $readOnlyPolicy = Get-ContinuousCoReviewReadOnlyInvocationPolicy -Executable $Executable -ArgumentList $ArgumentList
    $effectiveArgumentList = @($ArgumentList) + @($readOnlyPolicy.arguments)
    $processInvoker = if ($InvokeProcess) { $InvokeProcess } else { ${function:Invoke-ContinuousCoReviewAdapterProcess} }
    try {
        $processResult = & $processInvoker $Executable ([string[]] $effectiveArgumentList) $RequestBundlePath $timeoutSeconds $workingDirectory
    }
    catch {
        $invocation = New-ContinuousCoReviewAdapterInvocation -Request $Request -Candidate $Candidate -AdapterId $AdapterId -Executable $Executable -ArgumentList $effectiveArgumentList -AttemptNumber $AttemptNumber -ExitCode $null -FailureCategory 'command-invocation-failure' -CreatedAt $CreatedAt -ReadOnlyModeRequested:([bool] $readOnlyPolicy.requested) -ReadOnlyModeSupported:([bool] $readOnlyPolicy.supported) -ReadOnlyModeDetail $readOnlyPolicy.detail
        $failure = New-ContinuousCoReviewInfrastructureFailure -RunId $Request.run_id -InvocationId $invocation.invocation_id -Category 'command-invocation-failure' -Message 'Reviewer adapter process could not be invoked.' -SafeDetails ([pscustomobject]@{ adapter_id = $AdapterId }) -CreatedAt $CreatedAt
        return [pscustomobject][ordered]@{
            kind                   = 'infrastructure-failure'
            provider_invocation    = $invocation
            findings_result        = $null
            infrastructure_failure = $failure
        }
    }

    $exitCode = if ($null -eq $processResult.exit_code) { $null } else { [int] $processResult.exit_code }
    $timedOut = [bool] (Get-ContinuousCoReviewAdapterValue -Object $processResult -Name 'timed_out' -DefaultValue $false)
    $stdout = [string] (Get-ContinuousCoReviewAdapterValue -Object $processResult -Name 'stdout' -DefaultValue '')
    $invocation = New-ContinuousCoReviewAdapterInvocation -Request $Request -Candidate $Candidate -AdapterId $AdapterId -Executable $Executable -ArgumentList $effectiveArgumentList -AttemptNumber $AttemptNumber -ExitCode $exitCode -FailureCategory $null -CreatedAt $CreatedAt -ReadOnlyModeRequested:([bool] $readOnlyPolicy.requested) -ReadOnlyModeSupported:([bool] $readOnlyPolicy.supported) -ReadOnlyModeDetail $readOnlyPolicy.detail

    $normalized = ConvertTo-ContinuousCoReviewNormalizedResult -RunId $Request.run_id -InvocationId $invocation.invocation_id -ExitCode $(if ($null -eq $exitCode) { -1 } else { $exitCode }) -Stdout $stdout -TimedOut:$timedOut -SchemaRoot $SchemaRoot -CreatedAt $CreatedAt
    if ($normalized.kind -eq 'infrastructure-failure') {
        $invocation.failure_category = $normalized.infrastructure_failure.category
    }

    return [pscustomobject][ordered]@{
        kind                   = $normalized.kind
        provider_invocation    = $invocation
        findings_result        = $normalized.findings_result
        infrastructure_failure = $normalized.infrastructure_failure
    }
}

function Invoke-ContinuousCoReviewReviewerHostAdapterClaudePrompt {
    param(
        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        [string] $RequestBundlePath,

        [string] $SchemaRoot,

        [scriptblock] $InvokeProcess,

        [AllowNull()]
        $Candidate,

        [int] $AttemptNumber = 1,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    return Invoke-ContinuousCoReviewReviewerHostAdapterCommand -Request $Request -RequestBundlePath $RequestBundlePath -AdapterId 'reviewer-host-adapter-claude-prompt' -Executable 'claude' -ArgumentList @('-p') -SchemaRoot $SchemaRoot -InvokeProcess $InvokeProcess -Candidate $Candidate -AttemptNumber $AttemptNumber -CreatedAt $CreatedAt
}
