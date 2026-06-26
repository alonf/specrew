$ErrorActionPreference = 'Stop'

# Trace: T034, FR-012, SEC-005, INT-009, SC-005, TG-011.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T034 TG-011 reviewer-host-adapter-codex-exec obeys implementation-rules.yml safe argv floor' {
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
        $script:CreatedAt = [datetime] '2026-06-18T00:34:00Z'
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Get-T034Command {
                $command = Get-Command -Name 'Invoke-ContinuousCoReviewReviewerHostAdapterCodexExec' -ErrorAction SilentlyContinue
                $null = ($command | Should -Not -BeNullOrEmpty)
                return $command
            }

        function New-T034Request {
                return [pscustomobject][ordered]@{
                    schema_version   = '1.0'
                    run_id           = 'run-t034'
                    checkpoint_id    = 'checkpoint-t034'
                    created_at       = '2026-06-18T00:34:00Z'
                    provider_request = [pscustomobject][ordered]@{
                        requested_host    = 'codex'
                        requested_model   = 'codex-review-fixture'
                        authorization_ref = 'authz-codex-review-fixture'
                        timeout_seconds   = 30
                        fallback_policy   = 'none'
                    }
                }
            }

        function New-T034FindingsResultJson {
                $result = [pscustomobject][ordered]@{
                    schema_version = '1.0'
                    run_id         = 'run-t034'
                    status         = 'no_findings'
                    reviewer       = [pscustomobject][ordered]@{
                        host       = 'codex'
                        model      = 'codex-review-fixture'
                        adapter_id = 'reviewer-host-adapter-codex-exec'
                    }
                    findings       = @()
                    created_at     = '2026-06-18T00:34:00Z'
                }
                return ($result | ConvertTo-Json -Depth 100)
            }

        function Invoke-T034Adapter {
                param([scriptblock] $InvokeProcess)
                $command = Get-T034Command
                $requestPath = Join-Path $TestDrive 'request-bundle.json'
                Set-Content -LiteralPath $requestPath -Value '{}' -Encoding UTF8
                return & $command -Request (New-T034Request) -RequestBundlePath $requestPath -SchemaRoot $script:SchemaRoot -InvokeProcess $InvokeProcess -CreatedAt $script:CreatedAt
            }
}

    

    

    

    

    It 'declares the Codex exec adapter command before real host implementation' {
        Get-T034Command | Should -Not -BeNullOrEmpty
    }

    It 'invokes codex exec through argv/equivalent tokens and normalizes valid FindingsResult JSON' {
        $captured = @{}
        $process = {
            param($Executable, [string[]] $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory)
            $captured.Executable = $Executable
            $captured.ArgumentList = @($ArgumentList)
            return [pscustomobject][ordered]@{ exit_code = 0; stdout = (New-T034FindingsResultJson); stderr = 'ignored raw stderr'; timed_out = $false }
        }

        $result = Invoke-T034Adapter -InvokeProcess $process
        $validation = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $result.findings_result
        $invocationJson = $result.provider_invocation | ConvertTo-Json -Depth 100

        $captured.Executable | Should -Be 'codex'
        ($captured.ArgumentList -contains 'exec') | Should -Be $true
        $result.provider_invocation.adapter_id | Should -Be 'reviewer-host-adapter-codex-exec'
        @($result.provider_invocation.argv_summary).Count | Should -BeGreaterThan 1
        $invocationJson | Should -Not -Match '(?i)shell_command|command_line|joined_command|raw_stdout|raw_stderr|transcript'
        $result.kind | Should -Be 'findings-result'
        $validation.Valid | Should -Be $true
    }

    It 'returns deterministic InfrastructureFailure when codex exec cannot produce valid FindingsResult' {
        $process = {
            param($Executable, [string[]] $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory)
            return [pscustomobject][ordered]@{ exit_code = 1; stdout = (New-T034FindingsResultJson); stderr = 'secret token raw transcript'; timed_out = $false }
        }

        $first = Invoke-T034Adapter -InvokeProcess $process
        $second = Invoke-T034Adapter -InvokeProcess $process
        $validation = Test-ReviewerContractObject -ContractName 'InfrastructureFailure' -SchemaRoot $script:SchemaRoot -InputObject $first.infrastructure_failure
        $failureJson = $first.infrastructure_failure | ConvertTo-Json -Depth 100

        $first.kind | Should -Be 'infrastructure-failure'
        $first.infrastructure_failure.category | Should -Be 'nonzero-exit'
        $first.infrastructure_failure.failure_id | Should -Be $second.infrastructure_failure.failure_id
        $validation.Valid | Should -Be $true
        $failureJson | Should -Not -Match '(?i)secret|token|raw transcript|raw_stdout|raw_stderr'
    }

    It 'resolves a Windows codex.ps1 shim through the default process path while preserving read-only argv summary' {
        $runningOnWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
        if (-not $runningOnWindows) {
            return
        }

        $shimDirectory = Join-Path $TestDrive 'shim-bin'
        New-Item -ItemType Directory -Path $shimDirectory -Force | Out-Null
        $expectedJsonBytes = [System.Text.Encoding]::UTF8.GetBytes((New-T034FindingsResultJson))
        $expectedJsonBase64 = [Convert]::ToBase64String($expectedJsonBytes)
        $shimPath = Join-Path $shimDirectory 'codex.ps1'
        @(
            'param([Parameter(ValueFromRemainingArguments = $true)][string[]] $ShimArgs)'
            '$stdinText = [Console]::In.ReadToEnd()'
            "if (-not (`$ShimArgs -contains 'exec')) { exit 41 }"
            "if (-not (`$ShimArgs -contains '--sandbox')) { exit 42 }"
            "if (-not (`$ShimArgs -contains 'read-only')) { exit 43 }"
            "if (-not (`$ShimArgs -contains '--output-last-message')) { exit 44 }"
            'if ([string]::IsNullOrWhiteSpace($stdinText)) { exit 47 }'
            '$outputIndex = [array]::IndexOf($ShimArgs, ''--output-last-message'')'
            'if ($outputIndex -lt 0 -or ($outputIndex + 1) -ge $ShimArgs.Count) { exit 46 }'
            '$outputPath = $ShimArgs[$outputIndex + 1]'
            '$outputFullPath = if ([System.IO.Path]::IsPathRooted($outputPath)) { $outputPath } else { Join-Path (Get-Location).Path $outputPath }'
            "`$jsonBytes = [Convert]::FromBase64String('$expectedJsonBase64')"
            'Set-Content -LiteralPath $outputFullPath -Value ([System.Text.Encoding]::UTF8.GetString($jsonBytes)) -Encoding UTF8 -NoNewline'
            '[Console]::Out.WriteLine(''codex progress output is intentionally not FindingsResult JSON'')'
        ) | Set-Content -LiteralPath $shimPath -Encoding UTF8

        $oldPath = $env:Path
        try {
            $env:Path = "$shimDirectory;$oldPath"
            $command = Get-T034Command
            $requestPath = Join-Path $TestDrive 'request-bundle-shim.json'
            Set-Content -LiteralPath $requestPath -Value '{}' -Encoding UTF8

            $result = & $command -Request (New-T034Request) -RequestBundlePath $requestPath -SchemaRoot $script:SchemaRoot -CreatedAt $script:CreatedAt
            $validation = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $result.findings_result

            $result.kind | Should -Be 'findings-result'
            $result.provider_invocation.argv_summary[0] | Should -Be 'codex'
            ($result.provider_invocation.argv_summary -contains 'exec') | Should -Be $true
            ($result.provider_invocation.argv_summary -contains '--sandbox') | Should -Be $true
            ($result.provider_invocation.argv_summary -contains 'read-only') | Should -Be $true
            ($result.provider_invocation.argv_summary -contains '--output-last-message') | Should -Be $true
            $result.provider_invocation.readonly_mode_supported | Should -Be $true
            $result.provider_invocation.readonly_mode_detail | Should -Be 'codex exec --sandbox read-only'
            $validation.Valid | Should -Be $true
        }
        finally {
            $env:Path = $oldPath
        }
    }
}
