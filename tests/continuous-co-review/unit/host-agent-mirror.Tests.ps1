$ErrorActionPreference = 'Stop'

# Trace: T055, FR-018, FR-019, INT-010, INT-013, SC-014, SC-015, SC-016, SEC-008.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T055 host agent mirror support' {
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
        $script:CreatedAt = [datetime] '2026-06-19T01:55:00Z'
    }

    BeforeEach {
        $script:MirrorRoot = Join-Path $script:RepoRoot '.scratch/t055-host-agent-mirror'
        if (Test-Path -LiteralPath $script:MirrorRoot) { Remove-Item -LiteralPath $script:MirrorRoot -Recurse -Force }
        New-Item -ItemType Directory -Path (Join-Path $script:MirrorRoot 'scripts/internal/continuous-co-review') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/code-review-agent.md') -Destination (Join-Path $script:MirrorRoot 'scripts/internal/continuous-co-review/code-review-agent.md') -Force
    }

    AfterEach {
        if (Test-Path -LiteralPath $script:MirrorRoot) { Remove-Item -LiteralPath $script:MirrorRoot -Recurse -Force }
    }

    function New-T055ProviderRequest {
        return [pscustomobject][ordered]@{
            requested_host    = 'fixture'
            requested_model   = 'fixture-reviewer'
            authorization_ref = 'local-fixture-only'
            timeout_seconds   = 60
            fallback_policy   = 'none'
        }
    }

    function New-T055ChangeSet {
        return [pscustomobject][ordered]@{
            baseline_ref          = 'baseline-t055'
            diff_ref              = 'diffs/run-t055.diff'
            diff_inline           = "diff --git a/scripts/internal/continuous-co-review/host-agent-mirror.ps1 b/scripts/internal/continuous-co-review/host-agent-mirror.ps1`n+best effort mirror`n"
            diff_content          = "diff --git a/scripts/internal/continuous-co-review/host-agent-mirror.ps1 b/scripts/internal/continuous-co-review/host-agent-mirror.ps1`n+best effort mirror`n"
            diff_hash             = 'sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            changed_paths         = @('scripts/internal/continuous-co-review/host-agent-mirror.ps1')
            reviewable_path_count = 1
            excluded_paths        = @()
        }
    }

    function New-T055Request {
        return New-ContinuousCoReviewRequest `
            -RunId 'run-t055' `
            -CheckpointId 'checkpoint-t055' `
            -BaselineRef 'baseline-t055' `
            -ChangeSet (New-T055ChangeSet) `
            -DesignContextRefs @('specs/197-continuous-co-review/spec.md', 'specs/197-continuous-co-review/implementation-rules.yml') `
            -AllowedPaths @('scripts/internal/continuous-co-review/', 'tests/continuous-co-review/') `
            -ForbiddenPaths @('hosts/', 'extensions/specrew-speckit/scripts/provider-adapter.ps1') `
            -ProviderRequest (New-T055ProviderRequest) `
            -RoundNumber 1 `
            -PriorFindings @() `
            -SchemaRoot $script:SchemaRoot `
            -CreatedAt $script:CreatedAt
    }

    It 'plans native host agent mirrors as non-authoritative and not runtime-required' {
        $plan = New-ContinuousCoReviewHostAgentMirrorPlan -RepoRoot $script:MirrorRoot -Hosts @('claude', 'github-copilot', 'generic-agents')

        $plan.runtime_authority | Should Be 'composed-prompt'
        $plan.mirror_authority | Should Be $false
        $plan.canonical_path | Should Be 'scripts/internal/continuous-co-review/code-review-agent.md'
        $plan.canonical_hash | Should Match '^sha256:[0-9a-f]{64}$'
        @($plan.targets).Count | Should Be 3
        foreach ($target in @($plan.targets)) {
            $target.authoritative | Should Be $false
            $target.runtime_required | Should Be $false
            $target.mirror_semantics | Should Be 'best-effort-native-copy-only'
        }
    }

    It 'writes best-effort native copies with canonical source and hash metadata' {
        $result = Sync-ContinuousCoReviewHostAgentMirrors -RepoRoot $script:MirrorRoot -Hosts @('claude') -PassThru
        $mirrorPath = Join-Path $script:MirrorRoot '.claude/agents/specrew-code-review-agent.md'
        $mirrorContent = Get-Content -LiteralPath $mirrorPath -Raw

        $result.runtime_authority | Should Be 'composed-prompt'
        $result.mirror_authority | Should Be $false
        @($result.written).Count | Should Be 1
        $mirrorContent | Should Match 'best-effort native host mirror'
        $mirrorContent | Should Match 'Runtime authority remains the injected composed prompt'
        $mirrorContent | Should Match 'Canonical source: scripts/internal/continuous-co-review/code-review-agent.md'
        $mirrorContent | Should Match 'Canonical hash: sha256:[0-9a-f]{64}'
        $mirrorContent | Should Match 'Proposal 145 Rubric Phases'
    }

    It 'keeps runtime prompt composition authoritative when native mirrors are absent or stale' {
        Sync-ContinuousCoReviewHostAgentMirrors -RepoRoot $script:MirrorRoot -Hosts @('claude') -PassThru | Out-Null
        Set-Content -LiteralPath (Join-Path $script:MirrorRoot '.claude/agents/specrew-code-review-agent.md') -Value 'STALE MIRROR SHOULD NOT BE USED' -Encoding UTF8

        $request = New-T055Request
        $prompt = New-ContinuousCoReviewPrompt -Request $request -SchemaRoot $script:SchemaRoot -CreatedAt $script:CreatedAt

        $prompt.prompt_content | Should Match 'Proposal 145 Rubric Phases'
        $prompt.prompt_content | Should Match 'best effort mirror'
        $prompt.prompt_content | Should Not Match 'STALE MIRROR SHOULD NOT BE USED'
        $prompt.reviewer_instruction_hash | Should Be $request.reviewer_instruction.content_hash
    }
}
