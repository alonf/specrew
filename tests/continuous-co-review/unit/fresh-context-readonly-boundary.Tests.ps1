$ErrorActionPreference = 'Stop'

# Trace: T039, FR-009, FR-010, SEC-002, SEC-003, SEC-006, OBS-009, SC-005, TG-011.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T039 TG-011 fresh-context readonly boundary obeys implementation-rules.yml redacted evidence policy' {
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
        $script:CreatedAt = [datetime] '2026-06-18T00:39:00Z'
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Get-T039ExecutionCommand {
                $command = Get-Command -Name 'Invoke-ContinuousCoReviewReviewerExecution' -ErrorAction SilentlyContinue
                $null = ($command | Should -Not -BeNullOrEmpty)
                return $command
            }

        function New-T039Request {
                return [pscustomobject][ordered]@{
                    schema_version   = '1.0'
                    run_id           = 'run-t039'
                    checkpoint_id    = 'checkpoint-t039'
                    created_at       = '2026-06-18T00:39:00Z'
                    provider_request = [pscustomobject][ordered]@{
                        requested_host    = 'fixture'
                        requested_model   = 'fixture-reviewer'
                        authorization_ref = 'local-fixture-only'
                        timeout_seconds   = 30
                        fallback_policy   = 'none'
                    }
                }
            }

        function New-T039Candidate {
                return [pscustomobject][ordered]@{
                    host              = 'fixture'
                    model             = 'fixture-reviewer'
                    adapter_id        = 'reviewer-host-adapter-fixture'
                    authorization_ref = 'local-fixture-only'
                    authorized        = $true
                    timeout_seconds   = 30
                }
            }

        function New-T039FindingsResult {
                return [pscustomobject][ordered]@{
                    schema_version = '1.0'
                    run_id         = 'run-t039'
                    status         = 'no_findings'
                    reviewer       = [pscustomobject][ordered]@{
                        host       = 'fixture'
                        model      = 'fixture-reviewer'
                        adapter_id = 'reviewer-host-adapter-fixture'
                    }
                    findings       = @()
                    created_at     = '2026-06-18T00:39:00Z'
                }
            }

        function New-T039Sandbox {
                $sandboxRoot = Join-Path $TestDrive 'readonly-sandbox'
                $sourceRoot = Join-Path $sandboxRoot 'src'
                $stateRoot = Join-Path $sandboxRoot '.specrew'
                New-Item -ItemType Directory -Path $sourceRoot -Force | Out-Null
                New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $sourceRoot 'sentinel.ps1') -Value '$value = "unchanged"' -Encoding UTF8
                Set-Content -LiteralPath (Join-Path $stateRoot 'start-context.json') -Value '{"boundary":"before-implement"}' -Encoding UTF8
                return $sandboxRoot
            }

        function Get-T039FileHashMap {
                param(
                    [Parameter(Mandatory)]
                    [string] $Root
                )

                $hashes = @{}
                Get-ChildItem -LiteralPath $Root -File -Recurse | ForEach-Object {
                    $relative = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
                    $hashes[$relative] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                }
                return $hashes
            }

        function Invoke-T039Execution {
                param(
                    [string] $SandboxRoot,
                    [scriptblock] $InvokeAdapter
                )

                $command = Get-T039ExecutionCommand
                $workspace = New-ContinuousCoReviewRunWorkspace -RootPath (Join-Path $TestDrive 'workspace') -RunId 'run-t039'
                $requestBundle = Write-ContinuousCoReviewRequestBundle -Workspace $workspace -Request (New-T039Request)
                return & $command `
                    -Request (New-T039Request) `
                    -RequestBundle $requestBundle `
                    -RunRoot (Join-Path $TestDrive 'runs') `
                    -SchemaRoot $script:SchemaRoot `
                    -Candidates @(New-T039Candidate) `
                    -InvokeAdapter $InvokeAdapter `
                    -ReadOnlyRoot $SandboxRoot `
                    -CreatedAt $script:CreatedAt
            }
}

    

    

    

    

    

    

    

    It 'declares the fresh-context execution command before readonly boundary checks' {
        Get-T039ExecutionCommand | Should -Not -BeNullOrEmpty
    }

    It 'passes an immutable request bundle to the reviewer adapter instead of mutable source state' {
        $sandboxRoot = New-T039Sandbox
        $capture = @{ Bundle = $null }
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            $capture.Bundle = $RequestBundle
            return [pscustomobject][ordered]@{
                kind                   = 'findings-result'
                provider_invocation    = [pscustomobject][ordered]@{ invocation_id = 'invocation-run-t039-1'; run_id = $Request.run_id; attempt_number = 1; requested_host = $Request.provider_request.requested_host; requested_model = $Request.provider_request.requested_model; actual_host = $Candidate.host; actual_model = $Candidate.model; adapter_id = $Candidate.adapter_id }
                findings_result        = New-T039FindingsResult
                infrastructure_failure = $null
            }
        }

        $result = Invoke-T039Execution -SandboxRoot $sandboxRoot -InvokeAdapter $adapter

        $capture.Bundle.immutable | Should -Be $true
        (Test-Path -LiteralPath $capture.Bundle.request_path -PathType Leaf) | Should -Be $true
        $result.findings_result.status | Should -Be 'no_findings'
    }

    It 'does not edit source files or mutate Specrew state while running the readonly reviewer boundary' {
        $sandboxRoot = New-T039Sandbox
        $before = Get-T039FileHashMap -Root $sandboxRoot
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            return [pscustomobject][ordered]@{
                kind                   = 'findings-result'
                provider_invocation    = [pscustomobject][ordered]@{ invocation_id = 'invocation-run-t039-1'; run_id = $Request.run_id; attempt_number = 1; requested_host = $Request.provider_request.requested_host; requested_model = $Request.provider_request.requested_model; actual_host = $Candidate.host; actual_model = $Candidate.model; adapter_id = $Candidate.adapter_id }
                findings_result        = New-T039FindingsResult
                infrastructure_failure = $null
            }
        }

        Invoke-T039Execution -SandboxRoot $sandboxRoot -InvokeAdapter $adapter | Out-Null
        $after = Get-T039FileHashMap -Root $sandboxRoot

        ($after.Keys | Sort-Object) -join ',' | Should -Be (($before.Keys | Sort-Object) -join ',')
        foreach ($key in $before.Keys) {
            $after[$key] | Should -Be $before[$key]
        }
    }

    It 'does not stage commits or push branches from the readonly execution path' {
        $sandboxRoot = New-T039Sandbox
        $gitCalls = New-Object System.Collections.ArrayList
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            return [pscustomobject][ordered]@{
                kind                   = 'findings-result'
                provider_invocation    = [pscustomobject][ordered]@{ invocation_id = 'invocation-run-t039-1'; run_id = $Request.run_id; attempt_number = 1; requested_host = $Request.provider_request.requested_host; requested_model = $Request.provider_request.requested_model; actual_host = $Candidate.host; actual_model = $Candidate.model; adapter_id = $Candidate.adapter_id }
                findings_result        = New-T039FindingsResult
                infrastructure_failure = $null
            }
        }

        $command = Get-T039ExecutionCommand
        $workspace = New-ContinuousCoReviewRunWorkspace -RootPath (Join-Path $TestDrive 'git-workspace') -RunId 'run-t039'
        $requestBundle = Write-ContinuousCoReviewRequestBundle -Workspace $workspace -Request (New-T039Request)
        & $command -Request (New-T039Request) -RequestBundle $requestBundle -RunRoot (Join-Path $TestDrive 'git-runs') -SchemaRoot $script:SchemaRoot -Candidates @(New-T039Candidate) -InvokeAdapter $adapter -ReadOnlyRoot $sandboxRoot -GitCommand {
            param([string[]] $Arguments)
            $null = $gitCalls.Add(($Arguments -join ' '))
            if (($Arguments -contains 'add') -or ($Arguments -contains 'commit') -or ($Arguments -contains 'push')) {
                throw 'readonly reviewer attempted git mutation'
            }
        } -CreatedAt $script:CreatedAt | Out-Null

        ($gitCalls -join "`n") | Should -Not -Match '(?m)\b(add|commit|push)\b'
    }

    It 'does not persist raw prompts, transcripts, full stdout, full stderr, environment, credentials, or tokens by default' {
        $sandboxRoot = New-T039Sandbox
        $rawSecret = 'RAW_T039_SECRET_TOKEN_PROMPT_TRANSCRIPT_STDOUT_STDERR'
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            return [pscustomobject][ordered]@{
                kind                   = 'findings-result'
                provider_invocation    = [pscustomobject][ordered]@{
                    invocation_id         = 'invocation-run-t039-1'
                    run_id                = $Request.run_id
                    attempt_number        = 1
                    requested_host        = $Request.provider_request.requested_host
                    requested_model       = $Request.provider_request.requested_model
                    actual_host           = $Candidate.host
                    actual_model          = $Candidate.model
                    adapter_id            = $Candidate.adapter_id
                    stdout_capture_policy = 'parse-json-only'
                    stderr_capture_policy = 'status-only'
                }
                findings_result        = New-T039FindingsResult
                infrastructure_failure = $null
                raw_stdout             = $rawSecret
                raw_stderr             = $rawSecret
                raw_prompt             = $rawSecret
                raw_transcript         = $rawSecret
            }
        }

        $result = Invoke-T039Execution -SandboxRoot $sandboxRoot -InvokeAdapter $adapter
        $resultJson = $result | ConvertTo-Json -Depth 100
        $persistedText = (
            Get-ChildItem -LiteralPath $TestDrive -File -Recurse |
                ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }
        ) -join "`n"

        $resultJson | Should -Not -Match $rawSecret
        $persistedText | Should -Not -Match $rawSecret
        $resultJson | Should -Not -Match '(?i)raw_prompt|raw_transcript|raw_stdout|raw_stderr|environment|credential|token'
    }
}
