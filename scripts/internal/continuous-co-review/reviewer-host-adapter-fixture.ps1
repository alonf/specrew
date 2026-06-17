$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function New-ContinuousCoReviewFixtureSpawnInvocation {
    param(
        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        [int] $ExitCode
    )

    return [pscustomobject][ordered]@{
        schema_version         = '1.0'
        invocation_id          = "invocation-$($Request.run_id)-fixture-001"
        run_id                 = $Request.run_id
        attempt_number         = 1
        adapter_id             = 'reviewer-host-adapter-fixture'
        requested_host         = $Request.provider_request.requested_host
        requested_model        = $Request.provider_request.requested_model
        actual_host            = 'fixture'
        actual_model           = 'fixture-reviewer'
        argv_summary           = @('fixture-reviewer', '--stdin-request-json')
        working_directory_ref  = '.specrew/review/inline'
        timeout_seconds        = [int] $Request.provider_request.timeout_seconds
        stdout_capture_policy  = 'parse-json-only'
        stderr_capture_policy  = 'status-only'
        exit_code              = $ExitCode
        failure_category       = $null
        started_at             = $Request.created_at
        ended_at               = $Request.created_at
    }
}

function New-ContinuousCoReviewFixtureThread {
    param(
        [Parameter(Mandatory)]
        $Request,

        [Parameter(Mandatory)]
        $FindingsResult
    )

    $dispositions = @(
        foreach ($finding in @($FindingsResult.findings)) {
            [pscustomobject][ordered]@{
                disposition_id   = "disposition-$($finding.finding_id)"
                finding_id       = $finding.finding_id
                state            = $finding.disposition
                rationale        = $finding.resolution.rationale
                fix_evidence_ref = $finding.resolution.fix_evidence_ref
                review_round     = 0
                actor_role       = 'reviewer'
                recorded_at      = $FindingsResult.created_at
            }
        }
    )

    return [pscustomobject][ordered]@{
        schema_version      = '1.0'
        thread_id           = "thread-$($Request.run_id)"
        run_id              = $Request.run_id
        checkpoint_id       = $Request.checkpoint_id
        findings            = @($FindingsResult.findings | ForEach-Object { $_.finding_id })
        dispositions        = @($dispositions)
        resolution_summary  = 'Fixture reviewer thread created from normalized findings.'
        escalation_ref      = $null
        created_at          = $FindingsResult.created_at
        updated_at          = $FindingsResult.created_at
    }
}

function New-ContinuousCoReviewFixtureGateVerdict {
    param(
        [Parameter(Mandatory)]
        $Request,

        [AllowNull()]
        $FindingsResult,

        [AllowNull()]
        $InfrastructureFailure
    )

    if ($null -ne $InfrastructureFailure) {
        return [pscustomobject][ordered]@{
            schema_version             = '1.0'
            verdict_id                 = "verdict-$($Request.run_id)"
            run_id                     = $Request.run_id
            checkpoint_id              = $Request.checkpoint_id
            state                      = 'unsafe'
            unresolved_blocking_count  = 0
            blocking_finding_ids       = @()
            unsafe_reasons             = @($InfrastructureFailure.category)
            round_count                = 1
            escalation_ref             = $null
            created_at                 = $Request.created_at
        }
    }

    $blockingFindingIds = @(
        foreach ($finding in @($FindingsResult.findings)) {
            $resolutionState = $finding.resolution.state
            if (($finding.severity -eq 'blocking') -and ($finding.disposition -eq 'open') -and ($resolutionState -eq 'unresolved')) {
                $finding.finding_id
            }
        }
    )
    $state = if ($blockingFindingIds.Count -gt 0) { 'blocked' } else { 'pass' }

    return [pscustomobject][ordered]@{
        schema_version             = '1.0'
        verdict_id                 = "verdict-$($Request.run_id)"
        run_id                     = $Request.run_id
        checkpoint_id              = $Request.checkpoint_id
        state                      = $state
        unresolved_blocking_count  = $blockingFindingIds.Count
        blocking_finding_ids       = @($blockingFindingIds)
        unsafe_reasons             = @()
        round_count                = 1
        escalation_ref             = $null
        created_at                 = $Request.created_at
    }
}

function Invoke-ContinuousCoReviewFixtureReviewerPath {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $RunRoot,

        [Parameter(Mandatory)]
        $Request,

        [AllowNull()]
        [AllowEmptyString()]
        [string] $FixtureStdout,

        [int] $FixtureExitCode = 0,

        [string] $SchemaRoot
    )

    $workspace = New-ContinuousCoReviewRunWorkspace -RootPath $RunRoot -RunId $Request.run_id
    $requestBundle = Write-ContinuousCoReviewRequestBundle -Workspace $workspace -Request $Request
    $invocation = New-ContinuousCoReviewFixtureSpawnInvocation -Request $Request -ExitCode $FixtureExitCode

    $normalized = ConvertTo-ContinuousCoReviewNormalizedResult `
        -RunId $Request.run_id `
        -InvocationId $invocation.invocation_id `
        -ExitCode $FixtureExitCode `
        -Stdout $FixtureStdout `
        -TimedOut:$false `
        -SchemaRoot $SchemaRoot `
        -CreatedAt ([datetime] $Request.created_at)

    $thread = $null
    $verdict = $null
    if ($normalized.kind -eq 'findings-result') {
        $thread = New-ContinuousCoReviewFixtureThread -Request $Request -FindingsResult $normalized.findings_result
        $verdict = New-ContinuousCoReviewFixtureGateVerdict -Request $Request -FindingsResult $normalized.findings_result -InfrastructureFailure $null
    }
    else {
        $verdict = New-ContinuousCoReviewFixtureGateVerdict -Request $Request -FindingsResult $null -InfrastructureFailure $normalized.infrastructure_failure
    }

    return [pscustomobject][ordered]@{
        schema_version          = '1.0'
        run_id                  = $Request.run_id
        live_host_invoked       = $false
        request_bundle          = $requestBundle
        provider_invocation     = $invocation
        findings_result         = $normalized.findings_result
        infrastructure_failure  = $normalized.infrastructure_failure
        review_thread           = $thread
        gate_verdict            = $verdict
    }
}
