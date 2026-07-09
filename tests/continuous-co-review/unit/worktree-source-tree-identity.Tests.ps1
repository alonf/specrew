#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
    Identity unification (escalation 20260708T211331029, FR-025 class): the reviewer worktree must
    materialize from the SAME tree the reviewed-state digest certifies. Before the fix it archived
    HEAD while the gate digested the WORKING TREE - uncommitted changes were certified as reviewed
    without ever being seen. The load-bearing regression here: a dirty working tree's content IS in
    the reviewer's worktree (and in .review/changes.diff) when the digest tree is the source.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\..\scripts\internal\continuous-co-review\_load.ps1')
    . (Join-Path $PSScriptRoot '..\..\..\scripts\internal\continuous-co-review\worktree-reviewer.ps1')

    function New-IdentityTestRepo {
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

Describe 'New-ContinuousCoReviewStrippedWorktree source-tree identity' {
    It 'materializes UNCOMMITTED working-tree content when the digest tree is the source (the false-allow fix)' {
        $repo = New-IdentityTestRepo -Root (Join-Path $TestDrive 'repo-dirty')
        $baseline = (& git -C $repo rev-parse HEAD).Trim()
        # Dirty the working tree AFTER the commit - the exact bypass scenario the escalation named.
        [System.IO.File]::WriteAllText((Join-Path $repo 'src.ps1'), "function Get-Thing { 'UNCOMMITTED-v2' }`n")

        $dg = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $dg.ok | Should -BeTrue

        $wt = New-ContinuousCoReviewStrippedWorktree -RepoRoot $repo -BaselineRef $baseline -SourceTreeId ([string]$dg.tree_id) -EphemeralRoot $TestDrive
        try {
            # The reviewer sees EXACTLY what the gate certifies: the dirty content, not HEAD.
            $materialized = Get-Content -LiteralPath (Join-Path $wt.worktree_path 'src.ps1') -Raw
            $materialized | Should -Match 'UNCOMMITTED-v2'
            $materialized | Should -Not -Match 'committed-v1'
            # The change-set entry point shows the uncommitted change too.
            $diff = Get-Content -LiteralPath (Join-Path $wt.worktree_path '.review\changes.diff') -Raw
            $diff | Should -Match 'UNCOMMITTED-v2'
            # And the materialized tree id IS the certified digest subtree (identical identity).
            [string]$wt.tree_id | Should -Be ([string]$dg.tree_id)
        }
        finally {
            Remove-Item -LiteralPath $wt.worktree_path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'falls back to HEAD when no source tree is passed (digest-failure / legacy behavior)' {
        $repo = New-IdentityTestRepo -Root (Join-Path $TestDrive 'repo-head')
        $baseline = (& git -C $repo rev-parse HEAD).Trim()
        [System.IO.File]::WriteAllText((Join-Path $repo 'src.ps1'), "function Get-Thing { 'UNCOMMITTED-v2' }`n")

        $wt = New-ContinuousCoReviewStrippedWorktree -RepoRoot $repo -BaselineRef $baseline -EphemeralRoot $TestDrive
        try {
            (Get-Content -LiteralPath (Join-Path $wt.worktree_path 'src.ps1') -Raw) | Should -Match 'committed-v1'
        }
        finally {
            Remove-Item -LiteralPath $wt.worktree_path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
