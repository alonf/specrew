$ErrorActionPreference = 'Stop'

# Trace: T054, FR-020, SEC-008, SEC-009, OBS-012, SC-016, TG-013.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T054 workspace mutation guard and read-only invocation posture' {
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
        $script:CreatedAt = [datetime] '2026-06-19T01:54:00Z'
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function New-T054Request {
                param([string] $RunId = 'run-t054')
                return [pscustomobject][ordered]@{
                    schema_version   = '1.0'
                    run_id           = $RunId
                    checkpoint_id    = 'checkpoint-t054'
                    created_at       = '2026-06-19T01:54:00Z'
                    provider_request = [pscustomobject][ordered]@{ requested_host = 'codex'; requested_model = 'fixture'; authorization_ref = 'authz-t054'; timeout_seconds = 30; fallback_policy = 'none' }
                }
            }

        function New-T054Candidate {
                param([string] $AdapterId = 'reviewer-host-adapter-codex-exec')
                return [pscustomobject][ordered]@{ host = 'codex'; model = 'fixture'; adapter_id = $AdapterId; authorization_ref = 'authz-t054'; authorized = $true; exact_alternate_authorized = $false; timeout_seconds = 30 }
            }

        function New-T054FindingsResult {
                param([string] $RunId = 'run-t054')
                return [pscustomobject][ordered]@{
                    schema_version = '1.0'
                    run_id         = $RunId
                    status         = 'no_findings'
                    reviewer       = [pscustomobject][ordered]@{ host = 'codex'; model = 'fixture'; adapter_id = 'reviewer-host-adapter-codex-exec' }
                    findings       = @()
                    created_at     = '2026-06-19T01:54:00Z'
                }
            }

        function Initialize-T054RepoFixture {
                $repo = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
                New-Item -ItemType Directory -Path (Join-Path $repo 'scripts/internal/continuous-co-review') -Force | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $repo 'tests/continuous-co-review') -Force | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $repo 'specs/197-continuous-co-review/iterations/002') -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $repo 'scripts/internal/continuous-co-review/source.ps1') -Value 'before' -Encoding UTF8
                Set-Content -LiteralPath (Join-Path $repo 'specs/197-continuous-co-review/iterations/002/state.md') -Value 'before' -Encoding UTF8
                return $repo
            }

        function Invoke-T054Execution {
                param([string] $Repo, [scriptblock] $Adapter, [scriptblock] $GitCommand)
                return Invoke-ContinuousCoReviewReviewerExecution -Request (New-T054Request) -RunRoot (Join-Path $TestDrive 'runs') -SchemaRoot $script:SchemaRoot -Candidates @((New-T054Candidate)) -InvokeAdapter $Adapter -ReadOnlyRoot $Repo -GitCommand $GitCommand -CreatedAt $script:CreatedAt
            }
}

    

    

    

    

    

    It 'passes supported read-only/no-write flags to codex exec and records the posture' {
        $request = New-T054Request -RunId 'run-t054-readonly'
        $bundlePath = Join-Path $TestDrive 'prompt.txt'
        Set-Content -LiteralPath $bundlePath -Value 'composed prompt' -Encoding UTF8
        $capturedArgs = @()
        $process = {
            param($Executable, [string[]] $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory)
            $script:CapturedExecutable = $Executable
            $script:CapturedArgs = @($ArgumentList)
            return [pscustomobject][ordered]@{ exit_code = 0; stdout = ((New-T054FindingsResult -RunId $request.run_id) | ConvertTo-Json -Depth 20); stderr = ''; timed_out = $false }
        }

        $result = Invoke-ContinuousCoReviewReviewerHostAdapterCodexExec -Request $request -RequestBundlePath $bundlePath -SchemaRoot $script:SchemaRoot -Candidate (New-T054Candidate) -InvokeProcess $process -CreatedAt $script:CreatedAt

        $result.kind | Should -Be 'findings-result'
        ($script:CapturedArgs -contains '--sandbox') | Should -Be $true
        ($script:CapturedArgs -contains 'read-only') | Should -Be $true
        $result.provider_invocation.readonly_mode_requested | Should -Be $true
        $result.provider_invocation.readonly_mode_supported | Should -Be $true
        $result.provider_invocation.readonly_mode_detail | Should -Match 'read-only'
    }

    It 'invalidates a reviewer run when source files mutate during execution' {
        $repo = Initialize-T054RepoFixture
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            Set-Content -LiteralPath (Join-Path $repo 'scripts/internal/continuous-co-review/source.ps1') -Value 'after' -Encoding UTF8
            return [pscustomobject][ordered]@{ kind = 'findings-result'; provider_invocation = [pscustomobject][ordered]@{ invocation_id = 'invocation-source'; run_id = $Request.run_id; attempt_number = 1 }; findings_result = (New-T054FindingsResult -RunId $Request.run_id); infrastructure_failure = $null }
        }

        $result = Invoke-T054Execution -Repo $repo -Adapter $adapter

        $result.kind | Should -Be 'infrastructure-failure'
        $result.infrastructure_failure.category | Should -Be 'workspace-mutation-invalidated'
        $result.mutation_guard.source_mutated | Should -Be $true
        $result.findings_result | Should -Be $null
    }

    It 'invalidates a reviewer run when Specrew state mutates during execution' {
        $repo = Initialize-T054RepoFixture
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            Set-Content -LiteralPath (Join-Path $repo 'specs/197-continuous-co-review/iterations/002/state.md') -Value 'after' -Encoding UTF8
            return [pscustomobject][ordered]@{ kind = 'findings-result'; provider_invocation = [pscustomobject][ordered]@{ invocation_id = 'invocation-specrew'; run_id = $Request.run_id; attempt_number = 1 }; findings_result = (New-T054FindingsResult -RunId $Request.run_id); infrastructure_failure = $null }
        }

        $result = Invoke-T054Execution -Repo $repo -Adapter $adapter

        $result.infrastructure_failure.category | Should -Be 'workspace-mutation-invalidated'
        $result.mutation_guard.specrew_state_mutated | Should -Be $true
        $result.findings_result | Should -Be $null
    }

    It 'invalidates a reviewer run when Git state mutates during execution even if host flags are unavailable' {
        $repo = Initialize-T054RepoFixture
        $script:T054GitState = ''
        $git = { param([string[]] $Arguments) return @($script:T054GitState) }
        $adapter = {
            param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
            $script:T054GitState = ' M scripts/internal/continuous-co-review/source.ps1'
            return [pscustomobject][ordered]@{ kind = 'findings-result'; provider_invocation = [pscustomobject][ordered]@{ invocation_id = 'invocation-git'; run_id = $Request.run_id; attempt_number = 1; readonly_mode_supported = $false }; findings_result = (New-T054FindingsResult -RunId $Request.run_id); infrastructure_failure = $null }
        }

        $result = Invoke-T054Execution -Repo $repo -Adapter $adapter -GitCommand $git

        $result.infrastructure_failure.category | Should -Be 'workspace-mutation-invalidated'
        $result.mutation_guard.git_mutated | Should -Be $true
        $result.findings_result | Should -Be $null
    }
}
