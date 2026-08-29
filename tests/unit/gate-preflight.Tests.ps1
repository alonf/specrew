Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'Boundary gate preflight' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        . (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
        . (Join-Path $repoRoot 'scripts/internal/gate-preflight.ps1')

        function New-PreflightRepo {
            param([Parameter(Mandatory)][string]$Name, [string]$ReleaseModel = 'local-only')
            $root = Join-Path $TestDrive $Name
            $null = New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force
            $null = New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-demo') -Force
            Set-Content -LiteralPath (Join-Path $root '.specrew/repository-governance.yml') -Value "release_model: $ReleaseModel`nrelease_model_provenance: recorded`npublish_target: null`n" -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $root 'specs/001-demo/spec.md') -Value "# Demo`n" -Encoding UTF8
            & git -C $root init -q -b main
            & git -C $root config user.name preflight
            & git -C $root config user.email preflight@example.invalid
            & git -C $root add .
            & git -C $root commit -qm baseline
            return $root
        }
    }

    It 'treats the remote push check as not applicable for local-only projects' {
        $root = New-PreflightRepo 'local'
        $result = Invoke-SpecrewGatePreflight -ProjectRoot $root -BoundaryType specify -FeatureRef 001-demo
        $result.ok | Should -BeTrue
        ($result.checks | Where-Object name -eq pushed-head).status | Should -Be 'not-applicable'
    }

    It 'fails when a remote-delivered branch is not pushed at HEAD' {
        # T016 (FR-025): retargeted, not weakened. The unpushed HEAD is still refused at EVERY boundary -
        # under the name of the job that actually needs it, `verdict-commit-durable`, because three readers
        # resolve a boundary's auth_commit_hash back against git. `pushed-head` keeps only the DELIVERY job
        # its own schema describes, so at `specify` it is not-applicable and at a closeout it is the one that
        # refuses. Both halves are asserted here so neither can be silently dropped.
        $remote = Join-Path $TestDrive 'origin.git'
        & git init --bare -q $remote
        $root = New-PreflightRepo 'remote' 'push-only'
        & git -C $root remote add origin $remote
        & git -C $root push -q -u origin main
        Set-Content -LiteralPath (Join-Path $root 'README.md') -Value 'new' -Encoding UTF8
        & git -C $root add README.md
        & git -C $root commit -qm local-only-commit

        $atSpecify = Invoke-SpecrewGatePreflight -ProjectRoot $root -BoundaryType specify -FeatureRef 001-demo
        $atSpecify.ok | Should -BeFalse
        ($atSpecify.checks | Where-Object name -eq 'verdict-commit-durable').status | Should -Be 'fail'
        ($atSpecify.checks | Where-Object name -eq 'verdict-commit-durable').message | Should -Match 'git push origin'
        ($atSpecify.checks | Where-Object name -eq 'pushed-head').status | Should -Be 'not-applicable'

        $atCloseout = Invoke-SpecrewGatePreflight -ProjectRoot $root -BoundaryType iteration-closeout -FeatureRef 001-demo
        $atCloseout.ok | Should -BeFalse
        ($atCloseout.checks | Where-Object name -eq 'pushed-head').message | Should -Match 'not pushed'
    }

    It 'classifies dirty governance records separately from product or methodology paths' {
        $root = New-PreflightRepo 'dirty'
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force
        Set-Content -LiteralPath (Join-Path $root '.specrew/runtime/fact.json') -Value '{}'
        Set-Content -LiteralPath (Join-Path $root 'README.md') -Value 'dirty'
        $result = Invoke-SpecrewGatePreflight -ProjectRoot $root -BoundaryType specify -FeatureRef 001-demo
        $check = $result.checks | Where-Object name -eq working-tree
        $check.status | Should -Be fail
        @($check.evidence | Where-Object writer -eq governance-record).Count | Should -Be 1
        @($check.evidence | Where-Object writer -eq product-or-methodology).Count | Should -Be 1
    }

    It 'fails when task statuses or state summaries disagree' {
        $root = New-PreflightRepo 'tasks'
        $iteration = Join-Path $root 'specs/001-demo/iterations/001'
        $null = New-Item -ItemType Directory -Path (Join-Path $iteration 'quality') -Force
        Set-Content -LiteralPath (Join-Path $iteration 'plan.md') -Value '# Plan'
        Set-Content -LiteralPath (Join-Path $iteration 'quality/hardening-gate.md') -Value '# Gate'
        Set-Content -LiteralPath (Join-Path $iteration 'tasks-progress.yml') -Value "schema: v1`ntasks:`n  T001:`n    status: pending`n"
        Set-Content -LiteralPath (Join-Path $iteration 'state.md') -Value "# State`n`n**Tasks Remaining**: (none)`n**In Progress**: (none)`n"
        & git -C $root add .
        & git -C $root commit -qm inconsistent-tasks
        $result = Invoke-SpecrewGatePreflight -ProjectRoot $root -BoundaryType before-implement -FeatureRef 001-demo -IterationNumber 001
        $result.ok | Should -BeFalse
        ($result.checks | Where-Object name -eq task-state).status | Should -Be fail
    }

    It 'fails before a review-signoff packet when review.md is absent' {
        $root = New-PreflightRepo 'missing-review'
        $iteration = Join-Path $root 'specs/001-demo/iterations/001'
        $null = New-Item -ItemType Directory -Path $iteration -Force
        & git -C $root add .
        $result = Invoke-SpecrewGatePreflight -ProjectRoot $root -BoundaryType review-signoff -FeatureRef 001-demo -IterationNumber 001
        $result.ok | Should -BeFalse
        ($result.checks | Where-Object name -eq owed-artifact).message | Should -Match 'review.md'
    }

    It 'is wired before the boundary ratchet and every state mutation for initialized beta3 projects' {
        $source = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/internal/sync-boundary-state.ps1') -Raw -Encoding UTF8
        $preflightIndex = $source.IndexOf('Invoke-SpecrewGatePreflight', [StringComparison]::Ordinal)
        $ratchetIndex = $source.IndexOf('Invoke-SpecrewBoundaryRatchetGate', [StringComparison]::Ordinal)
        $preflightIndex | Should -BeGreaterThan -1
        $ratchetIndex | Should -BeGreaterThan $preflightIndex
        $source | Should -Match "repository-governance\.yml"
    }
}
