$ErrorActionPreference = 'Stop'

# Trace: T058, T066, FR-025, FR-027, NFR-002, TG-013.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T058/T066 run index records identity and resolves the lineage-valid last passing run' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function New-FakeRunRecord {
                param($Root, $RunId, $BaselineRef, $DiffHash, $ReviewedRef, $TreeId, $Status, $CreatedAt)
                $directory = Join-Path (Join-Path $Root '.specrew/review/inline') $RunId
                New-Item -ItemType Directory -Path $directory -Force | Out-Null
                ([pscustomobject][ordered]@{
                    schema_version = '1.0'; run_id = $RunId; checkpoint_id = 'cp'; baseline_ref = $BaselineRef
                    diff_hash = $DiffHash; reviewed_ref = $ReviewedRef; reviewed_tree_id = $TreeId; status = $Status
                    created_at = $CreatedAt; updated_at = $CreatedAt
                } | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath (Join-Path $directory 'review-run.json') -Encoding UTF8 -NoNewline
            }

        function Invoke-IdxGit { param($Root, [string[]] $GitArgs) Push-Location $Root; try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location } }
}

    

    

    It 'records diff_hash, reviewed_ref, and reviewed_tree_id on the durable run record' {
        $request = [pscustomobject][ordered]@{ schema_version = '2.0'; run_id = 'run-a'; request_hash = 'rh'; change_set = [pscustomobject]@{ diff_hash = 'sha256:abc' } }
        $result = Write-ContinuousCoReviewRunIndex -RepoRoot $TestDrive -RunId 'run-a' -CheckpointId 'cp' -BaselineRef 'b' -ReviewedRef 'head1' -ReviewedTreeId 'tree123' -ReviewRequest $request -GateVerdict ([pscustomobject]@{ state = 'pass' })
        $written = Get-Content -LiteralPath $result.review_run_path -Raw | ConvertFrom-Json
        $written.diff_hash | Should -Be 'sha256:abc'
        $written.reviewed_ref | Should -Be 'head1'
        $written.reviewed_tree_id | Should -Be 'tree123'
        $written.status | Should -Be 'pass'
    }

    It 'returns null when there is no inline evidence' {
        $emptyRoot = Join-Path $TestDrive 'empty-repo'
        New-Item -ItemType Directory -Path $emptyRoot -Force | Out-Null
        Get-ContinuousCoReviewLastPassingReviewState -RepoRoot $emptyRoot | Should -Be $null
    }

    It 'returns the most recent pass/escalated run and skips blocked runs (fixture mode, no lineage filter)' {
        $root = Join-Path $TestDrive 'resolver-repo'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        New-FakeRunRecord -Root $root -RunId 'r1' -BaselineRef 'b1' -DiffHash 'h1' -ReviewedRef 'rev1' -TreeId 't1' -Status 'pass' -CreatedAt '2026-06-20T00:00:01Z'
        New-FakeRunRecord -Root $root -RunId 'r2' -BaselineRef 'b2' -DiffHash 'h2' -ReviewedRef 'rev2' -TreeId 't2' -Status 'blocked' -CreatedAt '2026-06-20T00:00:02Z'
        New-FakeRunRecord -Root $root -RunId 'r3' -BaselineRef 'b3' -DiffHash 'h3' -ReviewedRef 'rev3' -TreeId 't3' -Status 'escalated' -CreatedAt '2026-06-20T00:00:03Z'
        $state = Get-ContinuousCoReviewLastPassingReviewState -RepoRoot $root
        $state.run_id | Should -Be 'r3'
        $state.reviewed_tree_id | Should -Be 't3'
    }

    It 'lineage filter excludes a pass whose reviewed_ref is NOT an ancestor of HEAD (cross-branch isolation)' {
        $root = Join-Path $TestDrive 'lineage-repo'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        Invoke-IdxGit $root @('init', '-q'); Invoke-IdxGit $root @('config', 'user.email', 't@e.c'); Invoke-IdxGit $root @('config', 'user.name', 't')
        Set-Content -LiteralPath (Join-Path $root 'a.txt') -Value '0' -Encoding UTF8
        Invoke-IdxGit $root @('add', '-A'); Invoke-IdxGit $root @('commit', '-q', '-m', 'c0')
        $onChain = (& git -C $root rev-parse HEAD).Trim()
        # A divergent commit reachable from a side branch but NOT from HEAD.
        Invoke-IdxGit $root @('checkout', '-q', '-b', 'side')
        Set-Content -LiteralPath (Join-Path $root 'b.txt') -Value '1' -Encoding UTF8
        Invoke-IdxGit $root @('add', '-A'); Invoke-IdxGit $root @('commit', '-q', '-m', 'side')
        $offChain = (& git -C $root rev-parse HEAD).Trim()
        Invoke-IdxGit $root @('checkout', '-q', 'master')
        Invoke-IdxGit $root @('checkout', '-q', '-B', 'main')

        New-FakeRunRecord -Root $root -RunId 'rc' -BaselineRef 'x' -DiffHash 'h' -ReviewedRef $onChain  -TreeId 'tc' -Status 'pass' -CreatedAt '2026-06-20T00:00:01Z'
        New-FakeRunRecord -Root $root -RunId 'ro' -BaselineRef 'x' -DiffHash 'h' -ReviewedRef $offChain -TreeId 'to' -Status 'pass' -CreatedAt '2026-06-20T00:00:09Z'

        # Without lineage (fixture mode) the newer off-chain run wins; WITH lineage it is excluded.
        (Get-ContinuousCoReviewLastPassingReviewState -RepoRoot $root).run_id | Should -Be 'ro'
        (Get-ContinuousCoReviewLastPassingReviewState -RepoRoot $root -AncestorOfRef 'HEAD').run_id | Should -Be 'rc'
    }

    It 'Get-ContinuousCoReviewGitIsAncestor is true for an ancestor and false for an unknown ref' {
        $root = Join-Path $TestDrive 'anc-repo'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        Invoke-IdxGit $root @('init', '-q'); Invoke-IdxGit $root @('config', 'user.email', 't@e.c'); Invoke-IdxGit $root @('config', 'user.name', 't')
        Set-Content -LiteralPath (Join-Path $root 'a.txt') -Value '0' -Encoding UTF8
        Invoke-IdxGit $root @('add', '-A'); Invoke-IdxGit $root @('commit', '-q', '-m', 'c0')
        $c0 = (& git -C $root rev-parse HEAD).Trim()
        Get-ContinuousCoReviewGitIsAncestor -RepoRoot $root -Ancestor $c0 -Descendant 'HEAD' | Should -Be $true
        Get-ContinuousCoReviewGitIsAncestor -RepoRoot $root -Ancestor ('0' * 40) -Descendant 'HEAD' | Should -Be $false
        Get-ContinuousCoReviewGitIsAncestor -RepoRoot $root -Ancestor $null -Descendant 'HEAD' | Should -Be $false
    }

    It 'Get-ContinuousCoReviewMergeBaseAnchor returns the merge-base with the trunk' {
        $root = Join-Path $TestDrive 'mb-repo'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        Invoke-IdxGit $root @('init', '-q'); Invoke-IdxGit $root @('config', 'user.email', 't@e.c'); Invoke-IdxGit $root @('config', 'user.name', 't')
        Set-Content -LiteralPath (Join-Path $root 'a.txt') -Value '0' -Encoding UTF8
        Invoke-IdxGit $root @('add', '-A'); Invoke-IdxGit $root @('commit', '-q', '-m', 'base')
        Invoke-IdxGit $root @('branch', '-M', 'main')
        $base = (& git -C $root rev-parse HEAD).Trim()
        Invoke-IdxGit $root @('checkout', '-q', '-b', 'feature')
        Set-Content -LiteralPath (Join-Path $root 'a.txt') -Value '1' -Encoding UTF8
        Invoke-IdxGit $root @('add', '-A'); Invoke-IdxGit $root @('commit', '-q', '-m', 'feat')
        Get-ContinuousCoReviewMergeBaseAnchor -RepoRoot $root -TrunkName 'main' | Should -Be $base
    }
}
