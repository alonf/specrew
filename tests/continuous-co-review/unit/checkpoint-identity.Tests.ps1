#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
    Checkpoint-identity dedup fix (codex finding, run 20260708T225439577 - the D-197-I010-004
    follow-on): the auto-fire dedup key must be the CERTIFIED digest identity, so an UNCOMMITTED
    edit after a fired commit changes the key and a new review fires. HEAD-tree keying deduped
    dirty increments as "already reviewed this tree".
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\..\scripts\internal\continuous-co-review\_load.ps1')
    . (Join-Path $PSScriptRoot '..\..\..\scripts\internal\continuous-co-review\co-review-service.ps1')

    function New-CheckpointTestRepo {
        param([Parameter(Mandatory)][string]$Root)
        $null = New-Item -ItemType Directory -Path $Root -Force
        & git -C $Root init --initial-branch=main 2>$null | Out-Null
        & git -C $Root config user.email 'specrew-test@example.invalid' 2>$null | Out-Null
        & git -C $Root config user.name 'Specrew Test' 2>$null | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $Root 'src.ps1'), "function Get-Thing { 'committed-v1' }`n")
        & git -C $Root add . 2>$null | Out-Null
        & git -C $Root commit -m 'baseline' 2>$null | Out-Null
        return (Resolve-Path -LiteralPath $Root).Path
    }
}

Describe 'Get-ContinuousCoReviewCheckpointIdentity' {
    It 'equals the certified digest identity on a clean tree' {
        $repo = New-CheckpointTestRepo -Root (Join-Path $TestDrive 'repo-clean')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        (Get-ContinuousCoReviewCheckpointIdentity -RepoRoot $repo) | Should -Be $digest
    }

    It 'CHANGES when the working tree gets dirty after a commit (the dedup-bypass regression)' {
        $repo = New-CheckpointTestRepo -Root (Join-Path $TestDrive 'repo-dirty')
        $cleanKey = Get-ContinuousCoReviewCheckpointIdentity -RepoRoot $repo
        $headTree = Get-ContinuousCoReviewWorktreeIdentity -RepoRoot $repo

        # The exact bypass scenario: an uncommitted edit after the last fired checkpoint.
        [System.IO.File]::WriteAllText((Join-Path $repo 'src.ps1'), "function Get-Thing { 'UNCOMMITTED-v2' }`n")

        $dirtyKey = Get-ContinuousCoReviewCheckpointIdentity -RepoRoot $repo
        $dirtyKey | Should -Not -Be $cleanKey                       # the fix: dirty => new key => fires
        (Get-ContinuousCoReviewWorktreeIdentity -RepoRoot $repo) | Should -Be $headTree  # the OLD key would NOT have changed
        # And the new key is the certified digest of the dirty tree - one identity everywhere.
        $dirtyKey | Should -Be ([string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id)
    }

    It 'returns to the clean key when the dirty edit is committed (stable, content-addressed)' {
        $repo = New-CheckpointTestRepo -Root (Join-Path $TestDrive 'repo-commit')
        [System.IO.File]::WriteAllText((Join-Path $repo 'src.ps1'), "function Get-Thing { 'v2' }`n")
        $dirtyKey = Get-ContinuousCoReviewCheckpointIdentity -RepoRoot $repo
        & git -C $repo add . 2>$null | Out-Null
        & git -C $repo commit -m 'v2' 2>$null | Out-Null
        # Same content, now committed: the digest identity is content-addressed, so the key is stable
        # across the commit - no double-fire for the same reviewed content.
        (Get-ContinuousCoReviewCheckpointIdentity -RepoRoot $repo) | Should -Be $dirtyKey
    }
}
