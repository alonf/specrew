$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 T012 TG-011 checkpoint diff provider obeys implementation-rules.yml' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    }

    function Get-T012CheckpointDiffCommand {
        $command = Get-Command -Name 'Get-ContinuousCoReviewCheckpointDiff' -ErrorAction SilentlyContinue
        $null = ($command | Should Not BeNullOrEmpty)
        return $command
    }

    function New-T012GitRepository {
        param(
            [Parameter(Mandatory)]
            [string] $Name
        )

        $repoPath = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $repoPath -Force | Out-Null
        Push-Location -LiteralPath $repoPath
        try {
            & git init | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'git init failed' }
            & git config user.email 'proposal-197@example.invalid' | Out-Null
            & git config user.name 'Proposal 197 Test' | Out-Null
            New-Item -ItemType Directory -Path 'src' -Force | Out-Null
            Set-Content -LiteralPath 'src/review-target.ps1' -Value "'baseline'" -Encoding UTF8
            & git add .
            if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
            & git commit -m 'baseline' | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
            $baseline = (& git rev-parse HEAD).Trim()
            if ($LASTEXITCODE -ne 0) { throw 'git rev-parse failed' }
        }
        finally {
            Pop-Location
        }

        return [pscustomobject]@{
            Path     = $repoPath
            Baseline = $baseline
        }
    }

    It 'declares the T012 checkpoint diff provider command before git-diff behavior is consumed' {
        Get-T012CheckpointDiffCommand | Should Not BeNullOrEmpty
    }

    It 'returns git diff changed paths, including out-of-band worktree edits, for FR-003 and OBS-004' {
        $repo = New-T012GitRepository -Name 'changed-paths'
        Set-Content -LiteralPath (Join-Path $repo.Path 'src/review-target.ps1') -Value "'changed outside editor host'" -Encoding UTF8

        $command = Get-T012CheckpointDiffCommand
        $changeSet = & $command -RepoRoot $repo.Path -BaselineRef $repo.Baseline -CheckpointId 'checkpoint-t012-changed-paths'

        $changeSet.status | Should Be 'reviewable'
        $changeSet.baseline_ref | Should Be $repo.Baseline
        ($changeSet.changed_paths -contains 'src/review-target.ps1') | Should Be $true
        $changeSet.reviewable_path_count | Should Be 1
        $changeSet.diff_hash | Should Match '^sha256:[0-9a-f]{64}$'
    }

    It 'separates excluded paths from reviewable paths without hiding their audit evidence' {
        $repo = New-T012GitRepository -Name 'excluded-paths'
        New-Item -ItemType Directory -Path (Join-Path $repo.Path 'generated') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo.Path 'src/review-target.ps1') -Value "'review me'" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repo.Path 'generated/output.txt') -Value 'generated diff' -Encoding UTF8
        Push-Location -LiteralPath $repo.Path
        try {
            & git add generated/output.txt
            if ($LASTEXITCODE -ne 0) { throw 'git add generated fixture failed' }
        }
        finally {
            Pop-Location
        }

        $command = Get-T012CheckpointDiffCommand
        $changeSet = & $command -RepoRoot $repo.Path -BaselineRef $repo.Baseline -CheckpointId 'checkpoint-t012-excluded-paths' -ExcludedPathPatterns @('generated/**')

        ($changeSet.changed_paths -contains 'src/review-target.ps1') | Should Be $true
        ($changeSet.changed_paths -contains 'generated/output.txt') | Should Be $false
        ($changeSet.excluded_paths -contains 'generated/output.txt') | Should Be $true
        $changeSet.reviewable_path_count | Should Be 1
    }

    It 'emits explicit no-reviewable-diff evidence instead of silently passing an empty checkpoint' {
        $repo = New-T012GitRepository -Name 'no-reviewable-diff'

        $command = Get-T012CheckpointDiffCommand
        $changeSet = & $command -RepoRoot $repo.Path -BaselineRef $repo.Baseline -CheckpointId 'checkpoint-t012-no-diff'

        $changeSet.status | Should Be 'skipped'
        $changeSet.skip_reason | Should Be 'no-reviewable-diff'
        $changeSet.reviewable_path_count | Should Be 0
        $changeSet.skipped_run.schema_version | Should Be '1.0'
        $changeSet.skipped_run.reason | Should Be 'no-reviewable-diff'
    }

    It 'returns a deterministic infrastructure failure when the checkpoint baseline is missing' {
        $repo = New-T012GitRepository -Name 'missing-baseline'

        $command = Get-T012CheckpointDiffCommand
        $changeSet = & $command -RepoRoot $repo.Path -BaselineRef 'missing-baseline-ref' -CheckpointId 'checkpoint-t012-missing-baseline'

        $changeSet.status | Should Be 'infrastructure_failure'
        $changeSet.failure.schema_version | Should Be '1.0'
        $changeSet.failure.category | Should Be 'command-invocation-failure'
        $changeSet.failure.safe_details.baseline_ref | Should Be 'missing-baseline-ref'
    }

    It 'keeps the diff hash stable for identical diff content and changes it for material diff changes' {
        $repo = New-T012GitRepository -Name 'hash-stability'
        Set-Content -LiteralPath (Join-Path $repo.Path 'src/review-target.ps1') -Value "'stable diff content'" -Encoding UTF8

        $command = Get-T012CheckpointDiffCommand
        $first = & $command -RepoRoot $repo.Path -BaselineRef $repo.Baseline -CheckpointId 'checkpoint-t012-hash-1'
        $second = & $command -RepoRoot $repo.Path -BaselineRef $repo.Baseline -CheckpointId 'checkpoint-t012-hash-2'
        Set-Content -LiteralPath (Join-Path $repo.Path 'src/review-target.ps1') -Value "'different diff content'" -Encoding UTF8
        $third = & $command -RepoRoot $repo.Path -BaselineRef $repo.Baseline -CheckpointId 'checkpoint-t012-hash-3'

        $first.diff_hash | Should Match '^sha256:[0-9a-f]{64}$'
        $second.diff_hash | Should Be $first.diff_hash
        $third.diff_hash | Should Not Be $first.diff_hash
    }
}
