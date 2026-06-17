$ErrorActionPreference = 'Stop'

# Trace: T037, FR-012, SEC-005, INT-009, SC-005, SC-012, TG-011.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T037 TG-011 reviewer-host-adapter-antigravity-prompt obeys implementation-rules.yml safe argv floor' {
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
        $script:CreatedAt = [datetime] '2026-06-18T00:37:00Z'
    }

    function Get-T037Command {
        $command = Get-Command -Name 'Invoke-ContinuousCoReviewReviewerHostAdapterAntigravityPrompt' -ErrorAction SilentlyContinue
        $null = ($command | Should Not BeNullOrEmpty)
        return $command
    }

    function New-T037Request {
        return [pscustomobject][ordered]@{
            schema_version   = '1.0'
            run_id           = 'run-t037'
            checkpoint_id    = 'checkpoint-t037'
            created_at       = '2026-06-18T00:37:00Z'
            provider_request = [pscustomobject][ordered]@{
                requested_host    = 'antigravity'
                requested_model   = 'antigravity-review-fixture'
                authorization_ref = 'authz-antigravity-review-fixture'
                timeout_seconds   = 30
                fallback_policy   = 'none'
            }
        }
    }

    function New-T037FindingsResultJson {
        $result = [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = 'run-t037'
            status         = 'no_findings'
            reviewer       = [pscustomobject][ordered]@{
                host       = 'antigravity'
                model      = 'antigravity-review-fixture'
                adapter_id = 'reviewer-host-adapter-antigravity-prompt'
            }
            findings       = @()
            created_at     = '2026-06-18T00:37:00Z'
        }
        return ($result | ConvertTo-Json -Depth 100)
    }

    function Invoke-T037Adapter {
        param([scriptblock] $InvokeProcess)
        $command = Get-T037Command
        $requestPath = Join-Path $TestDrive 'request-bundle.json'
        Set-Content -LiteralPath $requestPath -Value '{}' -Encoding UTF8
        return & $command -Request (New-T037Request) -RequestBundlePath $requestPath -SchemaRoot $script:SchemaRoot -InvokeProcess $InvokeProcess -CreatedAt $script:CreatedAt
    }

    It 'declares the Antigravity prompt adapter command before real host implementation' {
        Get-T037Command | Should Not BeNullOrEmpty
    }

    It 'invokes antigravity -p through argv/equivalent tokens and normalizes valid FindingsResult JSON' {
        $captured = @{}
        $process = {
            param($Executable, [string[]] $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory)
            $captured.Executable = $Executable
            $captured.ArgumentList = @($ArgumentList)
            return [pscustomobject][ordered]@{ exit_code = 0; stdout = (New-T037FindingsResultJson); stderr = 'ignored raw stderr'; timed_out = $false }
        }

        $result = Invoke-T037Adapter -InvokeProcess $process
        $validation = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $result.findings_result
        $invocationJson = $result.provider_invocation | ConvertTo-Json -Depth 100

        $captured.Executable | Should Be 'antigravity'
        ($captured.ArgumentList -contains '-p') | Should Be $true
        $result.provider_invocation.adapter_id | Should Be 'reviewer-host-adapter-antigravity-prompt'
        @($result.provider_invocation.argv_summary).Count | Should BeGreaterThan 1
        $invocationJson | Should Not Match '(?i)shell_command|command_line|joined_command|raw_stdout|raw_stderr|transcript'
        $result.kind | Should Be 'findings-result'
        $validation.Valid | Should Be $true
    }

    It 'returns deterministic InfrastructureFailure when antigravity -p cannot produce valid FindingsResult' {
        $process = {
            param($Executable, [string[]] $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory)
            return [pscustomobject][ordered]@{ exit_code = 127; stdout = ''; stderr = 'secret token raw transcript'; timed_out = $false }
        }

        $first = Invoke-T037Adapter -InvokeProcess $process
        $second = Invoke-T037Adapter -InvokeProcess $process
        $validation = Test-ReviewerContractObject -ContractName 'InfrastructureFailure' -SchemaRoot $script:SchemaRoot -InputObject $first.infrastructure_failure
        $failureJson = $first.infrastructure_failure | ConvertTo-Json -Depth 100

        $first.kind | Should Be 'infrastructure-failure'
        $first.infrastructure_failure.category | Should Be 'nonzero-exit'
        $first.infrastructure_failure.failure_id | Should Be $second.infrastructure_failure.failure_id
        $validation.Valid | Should Be $true
        $failureJson | Should Not Match '(?i)secret|token|raw transcript|raw_stdout|raw_stderr'
    }
}
