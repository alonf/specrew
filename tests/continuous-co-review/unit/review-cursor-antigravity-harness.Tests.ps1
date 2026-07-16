$ErrorActionPreference = 'Stop'

Describe 'Cursor and Antigravity production file-primary harness adapters (T055)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-store.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-result-ingestor.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-host-catalog.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-harness-contract.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-cursor-harness-port.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-antigravity-harness-port.ps1')

        function script:New-T055Invocation {
            param([Parameter(Mandatory)][string]$Root)
            $snapshot = Join-Path $Root 'snapshot'; $stage = Join-Path $Root 'stage'
            New-Item -ItemType Directory -Path $snapshot, $stage -Force | Out-Null
            return [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-demo'; run_id = 'run-one'; target_digest = 'digest-one'
                snapshot_path = $snapshot; review_scope = 'Review the complete frozen source tree.'
                prompt_path = (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md')
                candidate_result_path = (Join-Path $stage 'candidate.json'); candidate_report_path = (Join-Path $stage 'candidate.md')
                deadline = '2026-07-17T00:00:00Z'
            }
        }

        function script:Get-T055Case {
            param([Parameter(Mandatory)][ValidateSet('cursor-agent', 'antigravity')][string]$Name)
            if ($Name -ceq 'cursor-agent') {
                return [pscustomobject]@{
                    name = 'cursor-agent'; constructor = ${function:New-ReviewCursorAgentFilePrimaryHarnessPort}; harness_id = 'cursor-agent-file-primary'
                    command = 'cursor-agent'; pre_arguments = @('--print', '--trust', '--force'); timeout = 600
                }
            }
            return [pscustomobject]@{
                name = 'antigravity'; constructor = ${function:New-ReviewAntigravityFilePrimaryHarnessPort}; harness_id = 'antigravity-file-primary'
                command = 'agy'; pre_arguments = @('--dangerously-skip-permissions', '--print-timeout', '15m', '--print'); timeout = 900
            }
        }
    }

    It 'dispatches both checked-in catalog constructors through the generic production factory' -ForEach @(
        @{ name = 'cursor-agent'; expected = 'cursor-agent-file-primary' }
        @{ name = 'antigravity'; expected = 'antigravity-file-primary' }
    ) {
        $port = New-ReviewProductionHarnessPort -HostName $name -TimeoutSeconds 600
        $port.id | Should -Be $expected
        $port.host | Should -Be $name
        $port.result_transport | Should -Be 'file-primary'
        $port.stdout_authority | Should -BeFalse
    }

    It 'renders the exact order-sensitive vector with the bounded prompt last' -ForEach @(
        @{ name = 'cursor-agent' }
        @{ name = 'antigravity' }
    ) {
        $case = Get-T055Case -Name $name
        $invocation = New-T055Invocation -Root (Join-Path $TestDrive "spec-$name")
        $port = & $case.constructor -TimeoutSeconds $case.timeout -AvailabilityProbe { $true }
        (& $port.preflight $invocation).ok | Should -BeTrue
        $spec = & $port.build_process $invocation ([ordered]@{ SPECREW_REFOCUS_DISABLE = '1'; SPECREW_DISABLE_EVENTS = 'SessionStart,Stop'; SECRET = 'drop' })
        $spec.command | Should -Be $case.command
        $spec.prompt_transport | Should -Be 'argument'
        $spec.stdin_text | Should -BeNullOrEmpty
        @($spec.argument_list)[0..($case.pre_arguments.Count - 1)] | Should -Be $case.pre_arguments
        $spec.argument_list.Count | Should -Be ($case.pre_arguments.Count + 1)
        $prompt = [string]$spec.argument_list[-1]
        $prompt | Should -Match ([regex]::Escape([IO.Path]::GetFullPath($invocation.candidate_result_path)))
        $prompt | Should -Match 'run-one'
        $prompt | Should -Match 'digest-one'
        @($spec.environment_delta.Keys) | Should -Be @('SPECREW_REFOCUS_DISABLE', 'SPECREW_DISABLE_EVENTS')
        $spec.environment_delta.Contains('SECRET') | Should -BeFalse
    }

    It 'uses exactly one adapter invocation and accepts only the raw candidate file' -ForEach @(
        @{ name = 'cursor-agent' }
        @{ name = 'antigravity' }
    ) {
        $case = Get-T055Case -Name $name
        $invocation = New-T055Invocation -Root (Join-Path $TestDrive "invoke-$name")
        $calls = [Collections.Generic.List[object]]::new()
        $candidate = [pscustomobject][ordered]@{
            schema_version = '1.0'; run_id = 'run-one'; target_digest = 'digest-one'
            completion = 'complete'; verdict = 'pass'; summary = "$name fixture"; findings = @()
        }
        $candidateJson = $candidate | ConvertTo-Json -Depth 20 -Compress
        $invoker = {
            param($worktree, $prompt, $timeout)
            $calls.Add([pscustomobject]@{ worktree = $worktree; prompt = $prompt; timeout = $timeout }) | Out-Null
            [IO.File]::WriteAllText($invocation.candidate_result_path, $candidateJson, [Text.UTF8Encoding]::new($false))
            return [pscustomobject]@{ exit_code = 0; stdout = '{"verdict":"not-authority"}'; stderr = '' }
        }.GetNewClosure()
        $port = & $case.constructor -TimeoutSeconds $case.timeout -AgentInvoker $invoker -AvailabilityProbe { $true }
        $activity = & $port.invoke $invocation @{}
        $calls.Count | Should -Be 1
        $calls[0].timeout | Should -Be $case.timeout
        $activity.stdout_authority | Should -BeFalse
        $read = Read-ReviewCandidateResult -Path $invocation.candidate_result_path -ExpectedRunId run-one -ExpectedTargetDigest digest-one
        $read.valid | Should -BeTrue
        $read.candidate.summary | Should -Be "$name fixture"
    }

    It 'fails unavailable-command preflight without calling the injected adapter' -ForEach @(
        @{ name = 'cursor-agent' }
        @{ name = 'antigravity' }
    ) {
        $case = Get-T055Case -Name $name
        $invocation = New-T055Invocation -Root (Join-Path $TestDrive "unavailable-$name")
        $calls = 0
        $invoker = { param($worktree, $prompt, $timeout) $calls++; throw 'must-not-run' }.GetNewClosure()
        $port = & $case.constructor -TimeoutSeconds $case.timeout -AgentInvoker $invoker -AvailabilityProbe { $false }
        $preflight = & $port.preflight $invocation
        $preflight.ok | Should -BeFalse
        $preflight.reason | Should -Be "$name-unavailable"
        $calls | Should -Be 0
    }
}
