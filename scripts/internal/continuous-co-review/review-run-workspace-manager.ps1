$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function New-ContinuousCoReviewRunWorkspace {
    param(
        [Parameter(Mandatory)]
        [string] $RootPath,

        [Parameter(Mandatory)]
        [string] $RunId
    )

    New-Item -ItemType Directory -Path $RootPath -Force | Out-Null
    $workspacePath = Join-Path $RootPath $RunId
    if (Test-Path -LiteralPath $workspacePath) {
        $suffix = 1
        do {
            $workspacePath = Join-Path $RootPath ("$RunId-$suffix")
            $suffix++
        } while (Test-Path -LiteralPath $workspacePath)
    }

    New-Item -ItemType Directory -Path $workspacePath -Force | Out-Null
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        run_id         = $RunId
        path           = $workspacePath
        immutable      = $true
    }
}

function Write-ContinuousCoReviewRequestBundle {
    param(
        [Parameter(Mandatory)]
        $Workspace,

        [Parameter(Mandatory)]
        $Request
    )

    if ($Workspace.run_id -ne $Request.run_id) {
        throw "Request run id '$($Request.run_id)' does not match workspace run id '$($Workspace.run_id)'."
    }

    $requestPath = Join-Path $Workspace.path 'review-request.json'
    if (Test-Path -LiteralPath $requestPath) {
        throw "Review request bundle already exists for run id '$($Workspace.run_id)'."
    }

    $requestJson = $Request | ConvertTo-Json -Depth 100
    $Request | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $requestPath -Encoding UTF8 -NoNewline
    $requestHash = if (Test-ReviewerContractPropertyExists -Object $Request -Name 'request_hash') {
        Get-ReviewerContractPropertyValue -Object $Request -Name 'request_hash'
    }
    else {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($requestJson)
            [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant()
        }
        finally {
            $sha.Dispose()
        }
    }
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        run_id         = $Workspace.run_id
        workspace_path = $Workspace.path
        request_path   = $requestPath
        request_hash   = $requestHash
        immutable      = $true
    }
}

function Complete-ContinuousCoReviewRunWorkspace {
    param(
        [Parameter(Mandatory)]
        $Workspace,

        [Parameter(Mandatory)]
        [bool] $PreserveDebug,

        [Parameter(Mandatory)]
        $GateVerdict,

        [scriptblock] $CleanupAction
    )

    if ($PreserveDebug) {
        return [pscustomobject][ordered]@{
            schema_version   = '1.0'
            run_id           = $Workspace.run_id
            gate_verdict     = $GateVerdict
            cleanup_status   = 'preserved-for-debug'
            cleanup_failure  = $null
        }
    }

    try {
        if ($CleanupAction) {
            & $CleanupAction
        }
        else {
            Remove-Item -LiteralPath $Workspace.path -Recurse -Force
        }

        return [pscustomobject][ordered]@{
            schema_version   = '1.0'
            run_id           = $Workspace.run_id
            gate_verdict     = $GateVerdict
            cleanup_status   = 'cleaned'
            cleanup_failure  = $null
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            schema_version   = '1.0'
            run_id           = $Workspace.run_id
            gate_verdict     = $GateVerdict
            cleanup_status   = 'failed'
            cleanup_failure  = New-ContinuousCoReviewInfrastructureFailure `
                -RunId $Workspace.run_id `
                -Category 'cleanup-failed' `
                -Message 'Temporary review run workspace cleanup failed.' `
                -SafeDetails ([pscustomobject]@{ cleanup_stage = 'temporary-run-workspace'; run_id = $Workspace.run_id }) `
                -Retryable $true `
                -FallbackAllowed $false
        }
    }
}
