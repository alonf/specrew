$ErrorActionPreference = 'Stop'

# Trace: T038, FR-009, FR-010, FR-016, INT-004, OBS-006, SC-010, TG-011.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T038 TG-011 reviewer execution engine obeys implementation-rules.yml bounded fallback policy' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
        $script:CreatedAt = [datetime] '2026-06-18T00:38:00Z'
    }

    function Get-T038Command {
        $command = Get-Command -Name 'Invoke-ContinuousCoReviewReviewerExecution' -ErrorAction SilentlyContinue
        $null = ($command | Should Not BeNullOrEmpty)
        return $command
    }

    function New-T038Request {
        param(
            [string] $RunId = 'run-t038',
            [string] $RequestedHost = 'claude',
            [string] $RequestedModel = 'claude-review-fixture',
            [string] $FallbackPolicy = 'one-authorized-availability-fallback'
        )

        return [pscustomobject][ordered]@{
            schema_version   = '1.0'
            run_id           = $RunId
            checkpoint_id    = 'checkpoint-t038'
            created_at       = '2026-06-18T00:38:00Z'
            provider_request = [pscustomobject][ordered]@{
                requested_host    = $RequestedHost
                requested_model   = $RequestedModel
                authorization_ref = "authz-$RequestedHost-$RequestedModel"
                timeout_seconds   = 30
                fallback_policy   = $FallbackPolicy
            }
        }
    }

    function New-T038Candidate {
        param(
            [string] $HostName,
            [string] $ModelId,
            [string] $AdapterId,
            [bool] $Authorized = $true,
            [bool] $ExactAlternateAuthorized = $false
        )

        return [pscustomobject][ordered]@{
            host                       = $HostName
            model                      = $ModelId
            adapter_id                 = $AdapterId
            authorization_ref          = if ($Authorized) { "authz-$HostName-$ModelId" } else { $null }
            authorized                 = $Authorized
            exact_alternate_authorized = $ExactAlternateAuthorized
            timeout_seconds            = 30
        }
    }

    function New-T038FindingsResult {
        param(
            [string] $RunId,
            [string] $HostName,
            [string] $ModelId,
            [string] $AdapterId
        )

        return [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = $RunId
            status         = 'no_findings'
            reviewer       = [pscustomobject][ordered]@{
                host       = $HostName
                model      = $ModelId
                adapter_id = $AdapterId
            }
            findings       = @()
            created_at     = '2026-06-18T00:38:00Z'
        }
    }

    function New-T038Failure {
        param(
            [string] $RunId,
            [string] $Category,
            [string] $InvocationId = "invocation-$RunId-failure"
        )

        return New-ContinuousCoReviewInfrastructureFailure -RunId $RunId -InvocationId $InvocationId -Category $Category -Message "Fixture $Category" -SafeDetails ([pscustomobject]@{ category = $Category }) -CreatedAt $script:CreatedAt
    }

    function Invoke-T038Engine {
        param(
            $Request = (New-T038Request),
            [object[]] $Candidates,
            [scriptblock] $InvokeAdapter
        )

        $command = Get-T038Command
        return & $command -Request $Request -RunRoot (Join-Path $TestDrive 'runs') -SchemaRoot $script:SchemaRoot -Candidates $Candidates -InvokeAdapter $InvokeAdapter -CreatedAt $script:CreatedAt
    }

    It 'declares the reviewer execution engine command before orchestrator wiring' {
        Get-T038Command | Should Not BeNullOrEmpty
    }

    It 'runs synchronously with one bounded fresh-context adapter attempt when primary succeeds' {
        $calls = New-Object System.Collections.ArrayList
        $request = New-T038Request -RunId 'run-t038-sync'
        $candidates = @(New-T038Candidate -HostName 'claude' -ModelId 'claude-review-fixture' -AdapterId 'reviewer-host-adapter-claude-prompt')
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            $null = $calls.Add($Candidate)
            return [pscustomobject][ordered]@{
                kind                  = 'findings-result'
                provider_invocation   = [pscustomobject][ordered]@{
                    invocation_id   = "invocation-$($Request.run_id)-$AttemptNumber"
                    run_id          = $Request.run_id
                    attempt_number  = $AttemptNumber
                    adapter_id      = $Candidate.adapter_id
                    requested_host  = $Request.provider_request.requested_host
                    requested_model = $Request.provider_request.requested_model
                    actual_host     = $Candidate.host
                    actual_model    = $Candidate.model
                    timeout_seconds = $Candidate.timeout_seconds
                }
                findings_result       = New-T038FindingsResult -RunId $Request.run_id -HostName $Candidate.host -ModelId $Candidate.model -AdapterId $Candidate.adapter_id
                infrastructure_failure = $null
            }
        }

        $result = Invoke-T038Engine -Request $request -Candidates $candidates -InvokeAdapter $adapter

        $calls.Count | Should Be 1
        $result.findings_result.status | Should Be 'no_findings'
        $result.provider_invocation.timeout_seconds | Should Be 30
        $result.fallback_used | Should Be $false
    }

    It 'maps a timeout attempt to deterministic InfrastructureFailure instead of no findings' {
        $request = New-T038Request -RunId 'run-t038-timeout'
        $candidates = @(New-T038Candidate -HostName 'claude' -ModelId 'claude-review-fixture' -AdapterId 'reviewer-host-adapter-claude-prompt')
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            return [pscustomobject][ordered]@{
                kind                   = 'infrastructure-failure'
                provider_invocation    = [pscustomobject][ordered]@{ invocation_id = "invocation-$($Request.run_id)-$AttemptNumber"; run_id = $Request.run_id; attempt_number = $AttemptNumber; requested_host = $Request.provider_request.requested_host; requested_model = $Request.provider_request.requested_model; actual_host = $Candidate.host; actual_model = $Candidate.model; timeout_seconds = 1 }
                findings_result        = $null
                infrastructure_failure = New-T038Failure -RunId $Request.run_id -Category 'timeout'
            }
        }

        $result = Invoke-T038Engine -Request $request -Candidates $candidates -InvokeAdapter $adapter
        $validation = Test-ReviewerContractObject -ContractName 'InfrastructureFailure' -SchemaRoot $script:SchemaRoot -InputObject $result.infrastructure_failure

        $result.infrastructure_failure.category | Should Be 'timeout'
        $validation.Valid | Should Be $true
        $result.findings_result | Should Be $null
    }

    It 'uses at most one pre-authorized availability fallback and records requested/actual provenance' {
        $calls = New-Object System.Collections.ArrayList
        $request = New-T038Request -RunId 'run-t038-fallback'
        $candidates = @(
            New-T038Candidate -HostName 'claude' -ModelId 'claude-review-fixture' -AdapterId 'reviewer-host-adapter-claude-prompt'
            New-T038Candidate -HostName 'copilot' -ModelId 'copilot-review-fixture' -AdapterId 'reviewer-host-adapter-copilot-prompt' -ExactAlternateAuthorized $true
            New-T038Candidate -HostName 'codex' -ModelId 'codex-review-fixture' -AdapterId 'reviewer-host-adapter-codex-exec' -ExactAlternateAuthorized $true
        )
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            $null = $calls.Add($Candidate)
            if ($AttemptNumber -eq 1) {
                return [pscustomobject][ordered]@{
                    kind                   = 'infrastructure-failure'
                    provider_invocation    = [pscustomobject][ordered]@{ invocation_id = "invocation-$($Request.run_id)-1"; run_id = $Request.run_id; attempt_number = 1; requested_host = $Request.provider_request.requested_host; requested_model = $Request.provider_request.requested_model; actual_host = $Candidate.host; actual_model = $Candidate.model }
                    findings_result        = $null
                    infrastructure_failure = New-T038Failure -RunId $Request.run_id -Category 'missing-provider'
                }
            }
            return [pscustomobject][ordered]@{
                kind                   = 'findings-result'
                provider_invocation    = [pscustomobject][ordered]@{ invocation_id = "invocation-$($Request.run_id)-2"; run_id = $Request.run_id; attempt_number = 2; requested_host = $Request.provider_request.requested_host; requested_model = $Request.provider_request.requested_model; actual_host = $Candidate.host; actual_model = $Candidate.model; adapter_id = $Candidate.adapter_id }
                findings_result        = New-T038FindingsResult -RunId $Request.run_id -HostName $Candidate.host -ModelId $Candidate.model -AdapterId $Candidate.adapter_id
                infrastructure_failure = $null
            }
        }

        $result = Invoke-T038Engine -Request $request -Candidates $candidates -InvokeAdapter $adapter

        $calls.Count | Should Be 2
        $result.fallback_used | Should Be $true
        $result.provider_invocation.requested_host | Should Be 'claude'
        $result.provider_invocation.requested_model | Should Be 'claude-review-fixture'
        $result.provider_invocation.actual_host | Should Be 'copilot'
        $result.provider_invocation.actual_model | Should Be 'copilot-review-fixture'
    }

    It 'hard-blocks an unavailable specifically requested model without exact alternate authorization' {
        $calls = New-Object System.Collections.ArrayList
        $request = New-T038Request -RunId 'run-t038-specific-unavailable' -RequestedHost 'claude' -RequestedModel 'specific-human-requested-model'
        $candidates = @(
            New-T038Candidate -HostName 'claude' -ModelId 'specific-human-requested-model' -AdapterId 'reviewer-host-adapter-claude-prompt'
            New-T038Candidate -HostName 'copilot' -ModelId 'different-fallback-model' -AdapterId 'reviewer-host-adapter-copilot-prompt' -ExactAlternateAuthorized $false
        )
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            $null = $calls.Add($Candidate)
            return [pscustomobject][ordered]@{
                kind                   = 'infrastructure-failure'
                provider_invocation    = [pscustomobject][ordered]@{ invocation_id = "invocation-$($Request.run_id)-$AttemptNumber"; run_id = $Request.run_id; attempt_number = $AttemptNumber; requested_host = $Request.provider_request.requested_host; requested_model = $Request.provider_request.requested_model; actual_host = $Candidate.host; actual_model = $Candidate.model }
                findings_result        = $null
                infrastructure_failure = New-T038Failure -RunId $Request.run_id -Category 'unavailable-requested-model'
            }
        }

        $result = Invoke-T038Engine -Request $request -Candidates $candidates -InvokeAdapter $adapter

        $calls.Count | Should Be 1
        $result.infrastructure_failure.category | Should Be 'unavailable-requested-model'
        $result.fallback_used | Should Be $false
    }

    It 'blocks silent downgrade when actual host/model differs without explicit authorized fallback provenance' {
        $request = New-T038Request -RunId 'run-t038-no-silent-downgrade' -RequestedHost 'claude' -RequestedModel 'claude-review-fixture' -FallbackPolicy 'none'
        $candidates = @(New-T038Candidate -HostName 'fixture' -ModelId 'fixture-reviewer' -AdapterId 'reviewer-host-adapter-fixture' -Authorized $true)
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            return [pscustomobject][ordered]@{
                kind                   = 'findings-result'
                provider_invocation    = [pscustomobject][ordered]@{ invocation_id = "invocation-$($Request.run_id)-$AttemptNumber"; run_id = $Request.run_id; attempt_number = $AttemptNumber; requested_host = $Request.provider_request.requested_host; requested_model = $Request.provider_request.requested_model; actual_host = $Candidate.host; actual_model = $Candidate.model; adapter_id = $Candidate.adapter_id }
                findings_result        = New-T038FindingsResult -RunId $Request.run_id -HostName $Candidate.host -ModelId $Candidate.model -AdapterId $Candidate.adapter_id
                infrastructure_failure = $null
            }
        }

        $result = Invoke-T038Engine -Request $request -Candidates $candidates -InvokeAdapter $adapter

        $result.findings_result | Should Be $null
        $result.infrastructure_failure.category | Should Match 'unauthorized-provider|unavailable-requested-model|fallback-exhausted'
        $result.fallback_used | Should Be $false
    }
}
