$ErrorActionPreference = 'Stop'

# Trace: T056, FR-021, OBS-011, IMPL-010, SC-014, SC-017, SC-018, TG-013.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T056 deterministic prompt composer and adapter seam evidence' {
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
        $script:CreatedAt = [datetime] '2026-06-19T02:56:00Z'
    }

    function New-T056ProviderRequest {
        return [pscustomobject][ordered]@{
            requested_host    = 'claude'
            requested_model   = 'claude-review-fixture'
            authorization_ref = 'authz-claude-review-fixture'
            timeout_seconds   = 30
            fallback_policy   = 'none'
        }
    }

    function New-T056ChangeSet {
        return [pscustomobject][ordered]@{
            baseline_ref          = 'baseline-t056'
            diff_ref              = 'diffs/run-t056.diff'
            diff_inline           = "diff --git a/scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1 b/scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1`n+adapter uses composed runtime prompt`n"
            diff_content          = "diff --git a/scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1 b/scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1`n+adapter uses composed runtime prompt`n"
            diff_hash             = 'sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd'
            changed_paths         = @('scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1')
            reviewable_path_count = 1
            excluded_paths        = @()
        }
    }

    function New-T056Request {
        param(
            [string] $RunId = 'run-t056',
            [object[]] $PriorFindings = @([pscustomobject][ordered]@{ finding_id = 'finding-t056-prior'; status = 'accepted_fix_pending' })
        )

        return New-ContinuousCoReviewRequest `
            -RunId $RunId `
            -CheckpointId 'checkpoint-t056' `
            -BaselineRef 'baseline-t056' `
            -ChangeSet (New-T056ChangeSet) `
            -DesignContextRefs @('specs/197-continuous-co-review/spec.md', 'specs/197-continuous-co-review/implementation-rules.yml') `
            -AllowedPaths @('scripts/internal/continuous-co-review/', 'tests/continuous-co-review/') `
            -ForbiddenPaths @('hosts/', 'extensions/specrew-speckit/scripts/provider-adapter.ps1') `
            -ProviderRequest (New-T056ProviderRequest) `
            -RoundNumber 2 `
            -PriorFindings $PriorFindings `
            -SchemaRoot $script:SchemaRoot `
            -CreatedAt $script:CreatedAt
    }

    function New-T056FindingsResultJson {
        param([string] $RunId = 'run-t056')
        $result = [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = $RunId
            status         = 'no_findings'
            reviewer       = [pscustomobject][ordered]@{
                host       = 'claude'
                model      = 'claude-review-fixture'
                adapter_id = 'reviewer-host-adapter-claude-prompt'
            }
            findings       = @()
            created_at     = '2026-06-19T02:56:00Z'
        }
        return ($result | ConvertTo-Json -Depth 100)
    }

    function Invoke-T056ClaudeAdapter {
        param(
            $Request = (New-T056Request),
            [scriptblock] $InvokeProcess
        )

        $requestPath = Join-Path $TestDrive 'review-request.json'
        $Request | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $requestPath -Encoding UTF8 -NoNewline
        return Invoke-ContinuousCoReviewReviewerHostAdapterClaudePrompt -Request $Request -RequestBundlePath $requestPath -SchemaRoot $script:SchemaRoot -InvokeProcess $InvokeProcess -CreatedAt $script:CreatedAt
    }

    It 'composes deterministic prompts with rubric, design context, exact diff, round/prior findings, policies, do-policy, and FindingsResult contract' {
        $request = New-T056Request
        $first = New-ContinuousCoReviewPrompt -Request $request -SchemaRoot $script:SchemaRoot -CreatedAt $script:CreatedAt
        $second = New-ContinuousCoReviewPrompt -Request $request -SchemaRoot $script:SchemaRoot -CreatedAt $script:CreatedAt
        $content = $first.prompt_content

        $first.prompt_hash | Should Be $second.prompt_hash
        $content | Should Match 'Proposal 145 Rubric Phases'
        $content | Should Match 'FR-017'
        $content | Should Match 'diff --git a/scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1'
        $content | Should Match 'Round number: 2'
        $content | Should Match 'finding-t056-prior'
        $content | Should Match 'Visibility Policy'
        $content | Should Match 'Do Policy'
        $content | Should Match 'FindingsResult.v1'
    }

    It 'passes the composed prompt, not the fixture request bundle, to the outbound adapter process' {
        $captured = @{}
        $process = {
            param($Executable, [string[]] $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory)
            $captured.Executable = $Executable
            $captured.ArgumentList = @($ArgumentList)
            $captured.StandardInputPath = $StandardInputPath
            $captured.StandardInput = Get-Content -LiteralPath $StandardInputPath -Raw
            return [pscustomobject][ordered]@{ exit_code = 0; stdout = (New-T056FindingsResultJson); stderr = 'ignored'; timed_out = $false }
        }

        $result = Invoke-T056ClaudeAdapter -InvokeProcess $process

        $captured.Executable | Should Be 'claude'
        ($captured.ArgumentList -contains '-p') | Should Be $true
        [System.IO.Path]::GetFileName($captured.StandardInputPath) | Should Be 'review-prompt.md'
        $captured.StandardInput | Should Match 'Proposal 145 Rubric Phases'
        $captured.StandardInput | Should Match 'FR-017'
        $captured.StandardInput | Should Match 'adapter uses composed runtime prompt'
        $captured.StandardInput | Should Match 'Round number: 2'
        $captured.StandardInput | Should Match 'finding-t056-prior'
        $captured.StandardInput | Should Match 'Visibility Policy'
        $captured.StandardInput | Should Match 'Do Policy'
        $captured.StandardInput | Should Match 'FindingsResult.v1'
        $captured.StandardInput | Should Not Match 'fixture-owned outbound prompt'
        $result.kind | Should Be 'findings-result'
    }

    It 'fails before invocation when the exact diff is empty instead of sending an empty prompt' {
        $request = New-T056Request -RunId 'run-t056-empty-diff'
        $request.change_set.diff_content = ''
        $invoked = $false
        $process = {
            param($Executable, [string[]] $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory)
            $script:unused = $Executable, $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory
            $invoked = $true
            return [pscustomobject][ordered]@{ exit_code = 0; stdout = '{}'; stderr = ''; timed_out = $false }
        }

        $result = Invoke-T056ClaudeAdapter -Request $request -InvokeProcess $process

        $invoked | Should Be $false
        $result.kind | Should Be 'infrastructure-failure'
        $result.infrastructure_failure.category | Should Be 'schema-mismatch'
    }

    It 'does not allow a fixture-owned request-bundle prompt to bypass runtime prompt injection' {
        $request = New-T056Request -RunId 'run-t056-bypass'
        $requestPath = Join-Path $TestDrive 'fixture-owned-prompt.txt'
        Set-Content -LiteralPath $requestPath -Value 'fixture-owned outbound prompt' -Encoding UTF8 -NoNewline
        $captured = @{}
        $process = {
            param($Executable, [string[]] $ArgumentList, $StandardInputPath, $TimeoutSeconds, $WorkingDirectory)
            $captured.StandardInputPath = $StandardInputPath
            $captured.StandardInput = Get-Content -LiteralPath $StandardInputPath -Raw
            return [pscustomobject][ordered]@{ exit_code = 0; stdout = (New-T056FindingsResultJson -RunId 'run-t056-bypass'); stderr = 'ignored'; timed_out = $false }
        }

        $result = Invoke-ContinuousCoReviewReviewerHostAdapterClaudePrompt -Request $request -RequestBundlePath $requestPath -SchemaRoot $script:SchemaRoot -InvokeProcess $process -CreatedAt $script:CreatedAt

        [System.IO.Path]::GetFileName($captured.StandardInputPath) | Should Be 'review-prompt.md'
        $captured.StandardInput | Should Not Match 'fixture-owned outbound prompt'
        $captured.StandardInput | Should Match 'Proposal 145 Rubric Phases'
        $result.kind | Should Be 'findings-result'
    }
}
