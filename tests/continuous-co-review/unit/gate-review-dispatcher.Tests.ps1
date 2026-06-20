$ErrorActionPreference = 'Stop'

# Trace: T059, FR-032, SC-023, IMPL-004, TG-013.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T059 gate-review dispatcher + gate-keyed registry (FR-032/SC-023)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    }

    function Invoke-DispGit { param($Root, [string[]] $GitArgs) Push-Location $Root; try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location } }

    It 'registers exactly ONE reviewer: code-review at implement' {
        $reg = @(Get-ContinuousCoReviewGateReviewRegistry)
        $reg.Count | Should Be 1
        $reg[0].stage | Should Be 'implement'
        $reg[0].reviewer_kind | Should Be 'code-review'
    }

    It 'SC-023: an UNREGISTERED stage (plan) is a no-op (zero spawn)' {
        $d = Invoke-ContinuousCoReviewGateDispatch -RepoRoot $script:RepoRoot -Stage 'plan' -CheckpointReached $true
        $d.action | Should Be 'no-op'
        $d.reason | Should Be 'no-reviewer-registered-for-stage'
    }

    It 'SC-023: design-lens / tasks / spec are unregistered no-op extension points' {
        foreach ($stage in @('design-lens', 'tasks', 'spec')) {
            (Invoke-ContinuousCoReviewGateDispatch -RepoRoot $script:RepoRoot -Stage $stage -CheckpointReached $true).action | Should Be 'no-op'
        }
    }

    It 'SC-023: a registered stage with NO reviewable checkpoint is a no-op (casual yield)' {
        $d = Invoke-ContinuousCoReviewGateDispatch -RepoRoot $script:RepoRoot -Stage 'implement' -CheckpointReached $false
        $d.action | Should Be 'no-op'
        $d.reason | Should Be 'no-reviewable-checkpoint'
    }

    It 'DISPATCHES for a registered stage at a real checkpoint' {
        $d = Invoke-ContinuousCoReviewGateDispatch -RepoRoot $script:RepoRoot -Stage 'implement' -CheckpointReached $true
        $d.action | Should Be 'dispatch'
        $d.reason | Should Be 'registered-checkpoint'
        $d.reviewer.reviewer_kind | Should Be 'code-review'
    }

    It 'detects a real checkpoint from the reviewable change-set when no explicit signal is given' {
        $repo = Join-Path $TestDrive 'disp-repo'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Invoke-DispGit $repo @('init', '-q'); Invoke-DispGit $repo @('config', 'user.email', 't@e.c'); Invoke-DispGit $repo @('config', 'user.name', 't')
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value '0' -Encoding UTF8
        Invoke-DispGit $repo @('add', '-A'); Invoke-DispGit $repo @('commit', '-q', '-m', 'c0')
        $base = (& git -C $repo rev-parse HEAD).Trim()
        # no change since baseline -> casual yield -> no-op
        (Invoke-ContinuousCoReviewGateDispatch -RepoRoot $repo -Stage 'implement' -BaselineRef $base).action | Should Be 'no-op'
        # a reviewable change -> dispatch
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value '1' -Encoding UTF8
        (Invoke-ContinuousCoReviewGateDispatch -RepoRoot $repo -Stage 'implement' -BaselineRef $base).action | Should Be 'dispatch'
    }
}
