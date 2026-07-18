$ErrorActionPreference = 'Stop'

# Trace: T046 / FR-059, FR-065 / SC-018.
Describe 'ReviewTargetPort production Git target and non-code fixture (T046)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-target-port.ps1')

        function script:New-TargetRepo {
            param([Parameter(Mandatory)][string]$Path)
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            & git -C $Path init -q 2>&1 | Out-Null
            & git -C $Path branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Path 'tracked.txt'), 'committed')
            New-Item -ItemType Directory -Path (Join-Path $Path '.specrew') -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $Path '.specrew/runtime.json'), '{}')
            [IO.File]::WriteAllText((Join-Path $Path 'AGENTS.md'), 'Specrew instructions')
            & git -C $Path -c user.name=target-test -c user.email=target@test.local add -A 2>&1 | Out-Null
            & git -C $Path -c user.name=target-test -c user.email=target@test.local commit -qm initial 2>&1 | Out-Null
        }
    }

    It 'freezes the exact dirty state in an external linked worktree while leaving origin code unchanged' {
        $origin = Join-Path $TestDrive 'origin'
        $external = Join-Path $TestDrive 'external'
        New-TargetRepo -Path $origin
        [IO.File]::WriteAllText((Join-Path $origin 'tracked.txt'), 'dirty-current')
        [IO.File]::WriteAllText((Join-Path $origin 'untracked.txt'), 'untracked-current')
        $before = Get-GitReviewTargetOriginEvidence -OriginRepo $origin

        $snapshot = New-GitReviewTargetSnapshot -OriginRepo $origin -RunId run-target -ExternalRoot $external
        try {
            (Test-ReviewTargetPathUnderRoot -Path $snapshot.workspace_root -Root $origin) | Should -BeFalse
            (Split-Path -Leaf $snapshot.workspace_root) | Should -Match '^rt-[A-Za-z0-9_-]{16}$'
            (Split-Path -Leaf $snapshot.workspace_root) | Should -Not -Match 'run-target'
            $snapshot.run_id | Should -Be 'run-target' -Because 'the full authority identity stays in metadata, not the bounded filesystem leaf'
            Test-Path -LiteralPath (Join-Path $snapshot.workspace_root '.git') | Should -BeTrue -Because 'this is a genuine linked git worktree sharing the object database'
            (Get-Content -LiteralPath (Join-Path $snapshot.snapshot_path 'tracked.txt') -Raw) | Should -Be 'dirty-current'
            (Get-Content -LiteralPath (Join-Path $snapshot.snapshot_path 'untracked.txt') -Raw) | Should -Be 'untracked-current'
            Test-Path -LiteralPath (Join-Path $snapshot.snapshot_path '.specrew') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $snapshot.snapshot_path 'AGENTS.md') | Should -BeFalse
            $snapshot.target_digest | Should -Be $before.reviewed_state_digest

            $snapshotTree = (& git -C $snapshot.workspace_root write-tree 2>$null).Trim()
            $snapshotTree | Should -Be $snapshot.target_digest
            $commonDir = (& git -C $snapshot.workspace_root rev-parse --git-common-dir 2>$null).Trim()
            $commonFull = if ([IO.Path]::IsPathRooted($commonDir)) { [IO.Path]::GetFullPath($commonDir) } else { [IO.Path]::GetFullPath((Join-Path $snapshot.workspace_root $commonDir)) }
            $commonFull | Should -Be ([IO.Path]::GetFullPath((Join-Path $origin '.git')))

            # A fallible reviewer can dirty its disposable copy, but the origin remains byte/digest/HEAD identical.
            [IO.File]::WriteAllText((Join-Path $snapshot.snapshot_path 'tracked.txt'), 'reviewer mutation')
            (Test-GitReviewTargetSnapshotIntegrity -Snapshot $snapshot).classification | Should -Be 'snapshot-tampered'
            (Get-Content -LiteralPath (Join-Path $origin 'tracked.txt') -Raw) | Should -Be 'dirty-current'
            $afterReviewerMutation = Get-GitReviewTargetOriginEvidence -OriginRepo $origin
            $afterReviewerMutation.origin_head | Should -Be $before.origin_head
            $afterReviewerMutation.reviewed_state_digest | Should -Be $before.reviewed_state_digest
            (Test-GitReviewTargetCurrentness -Snapshot $snapshot).classification | Should -Be 'current'

            # Later legitimate origin movement does not erase the review; it labels it snapshot-moved.
            [IO.File]::WriteAllText((Join-Path $origin 'tracked.txt'), 'implementer-moved')
            $moved = Test-GitReviewTargetCurrentness -Snapshot $snapshot
            $moved.classification | Should -Be 'snapshot-moved'
            $moved.exact | Should -BeFalse
        }
        finally {
            $removed = Remove-GitReviewTargetSnapshot -Snapshot $snapshot
            $removed.removed | Should -BeTrue
        }
    }

    It 'refuses an external root at or below the origin' {
        $origin = Join-Path $TestDrive 'origin-contained'
        New-TargetRepo -Path $origin
        { New-GitReviewTargetSnapshot -OriginRepo $origin -RunId run-contained -ExternalRoot (Join-Path $origin 'reviews') } | Should -Throw -ExpectedMessage '*external-root-inside-origin*'
        Test-Path -LiteralPath (Join-Path $origin 'reviews') | Should -BeFalse
    }

    It 'generates compact fixed-length workspace tokens without collapsing invocations' {
        $one = New-ReviewTargetWorkspaceToken
        $two = New-ReviewTargetWorkspaceToken
        $one | Should -Match '^[A-Za-z0-9_-]{16}$'
        $one | Should -Not -Be $two

        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-target-port.ps1') -Raw
        $source | Should -Match 'RandomNumberGenerator\]::GetBytes\(12\)'
    }

    It 'exposes the same neutral port fields for the thin non-code fixture' {
        $external = Join-Path $TestDrive 'non-code'
        $target = New-NonCodeReviewTargetFixture -RunId run-artifact -Content 'artifact body' -ExternalRoot $external
        try {
            foreach ($field in @('schema_version', 'target_kind', 'run_id', 'target_digest', 'snapshot_path', 'workspace_root', 'suppression_environment')) {
                $target.PSObject.Properties.Name | Should -Contain $field
            }
            $target.target_kind | Should -Be 'non-code-fixture'
            $target.target_digest | Should -Match '^[a-f0-9]{64}$'
            (Get-Content -LiteralPath (Join-Path $target.snapshot_path 'artifact.txt') -Raw) | Should -Be 'artifact body'
            $target.suppression_environment.SPECREW_REFOCUS_DISABLE | Should -Be '1'
        }
        finally { (Remove-NonCodeReviewTargetFixture -Snapshot $target).removed | Should -BeTrue }
    }

    It 'uses only the established process-local Specrew suppression controls' {
        $environment = Get-ReviewTargetSuppressionEnvironment
        @($environment.Keys) | Should -Be @('SPECREW_REFOCUS_DISABLE', 'SPECREW_DISABLE_EVENTS')
        $environment.SPECREW_REFOCUS_DISABLE | Should -Be '1'
        $environment.SPECREW_DISABLE_EVENTS | Should -Match 'Stop'
    }
}
