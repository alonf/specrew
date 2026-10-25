Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $syncScript = Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1'
    . $syncScript

    function Invoke-ConstraintVisibilityGit {
        param(
            [Parameter(Mandatory = $true)][string]$Repo,
            [Parameter(Mandatory = $true)][string[]]$Arguments
        )

        $output = @(& git -C $Repo @Arguments 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
        }
        return $output
    }

    function New-ConstraintVisibilityRepo {
        param([Parameter(Mandatory = $true)][string]$Path)

        New-Item -ItemType Directory -Path (Join-Path $Path '.specrew') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $Path '.squad\events') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $Path 'specs\001-visible\iterations\001') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $Path '.specrew\iteration-config.yml') -Value "capacity_per_iteration: 20`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $Path 'specs\001-visible\iterations\001\state.md') -Value "# Iteration State`n`n**Baseline Ref**: base-a`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $Path '.squad\decisions.md') -Value "# Decisions Ledger`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $Path '.squad\events\lifecycle-events.jsonl') -Value '' -Encoding UTF8

        Invoke-ConstraintVisibilityGit -Repo $Path -Arguments @('init', '-q') | Out-Null
        Invoke-ConstraintVisibilityGit -Repo $Path -Arguments @('config', 'user.email', 'constraint-visibility@example.invalid') | Out-Null
        Invoke-ConstraintVisibilityGit -Repo $Path -Arguments @('config', 'user.name', 'Constraint Visibility Fixture') | Out-Null
        Invoke-ConstraintVisibilityGit -Repo $Path -Arguments @('add', '-A') | Out-Null
        Invoke-ConstraintVisibilityGit -Repo $Path -Arguments @('commit', '-q', '-m', 'baseline') | Out-Null
        $previousCommit = (@(Invoke-ConstraintVisibilityGit -Repo $Path -Arguments @('rev-parse', 'HEAD')))[0].ToString().Trim()

        Set-Content -LiteralPath (Join-Path $Path '.specrew\iteration-config.yml') -Value "capacity_per_iteration: 35`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $Path 'specs\001-visible\iterations\001\state.md') -Value "# Iteration State`n`n**Baseline Ref**: base-b`n" -Encoding UTF8
        Invoke-ConstraintVisibilityGit -Repo $Path -Arguments @('add', '-A') | Out-Null
        Invoke-ConstraintVisibilityGit -Repo $Path -Arguments @('commit', '-q', '-m', 'edit constraints') | Out-Null
        $currentCommit = (@(Invoke-ConstraintVisibilityGit -Repo $Path -Arguments @('rev-parse', 'HEAD')))[0].ToString().Trim()

        return [pscustomobject]@{
            PreviousCommit = $previousCommit
            CurrentCommit = $currentCommit
        }
    }
}

Describe 'Constraint edits are visible at governed boundary sync' {
    It 'records capacity and review-baseline edits in both human and machine ledgers' {
        $fixture = New-ConstraintVisibilityRepo -Path $TestDrive

        $changes = @(Get-SpecrewConstraintChanges `
            -ProjectRoot $TestDrive `
            -FeatureRef '001-visible' `
            -IterationNumber '001' `
            -PreviousCommitHash $fixture.PreviousCommit `
            -CurrentCommitHash $fixture.CurrentCommit)

        $changes.Count | Should -Be 2
        @($changes.Field) | Should -Contain 'capacity_per_iteration'
        @($changes.Field) | Should -Contain 'review_baseline_ref'

        Publish-SpecrewConstraintChangeRecords -ProjectRoot $TestDrive -BoundaryType 'review-signoff' -Changes $changes -NowUtc '2026-08-13T10:00:00Z'

        $ledger = Get-Content -LiteralPath (Join-Path $TestDrive '.squad\decisions.md') -Raw -Encoding UTF8
        $ledger | Should -Match 'Constraint change detected: capacity_per_iteration'
        $ledger | Should -Match 'Previous Value\*\*: 20'
        $ledger | Should -Match 'Current Value\*\*: 35'
        $ledger | Should -Match 'Constraint change detected: review_baseline_ref'
        $ledger | Should -Match 'This record makes the edit visible; it does not authorize the change.'

        $events = @(Read-SpecrewJsonLines -Path (Join-Path $TestDrive '.squad\events\lifecycle-events.jsonl'))
        @($events | Where-Object { $_.event_type -eq 'constraint-change' }).Count | Should -Be 2
        @($events | Where-Object { $_.payload.field -eq 'capacity_per_iteration' })[0].payload.previous_value | Should -Be '20'
        @($events | Where-Object { $_.payload.field -eq 'capacity_per_iteration' })[0].payload.current_value | Should -Be '35'
    }

    It 'deduplicates the same commit-to-commit change across a refused boundary retry' {
        $fixture = New-ConstraintVisibilityRepo -Path $TestDrive
        $changes = @(Get-SpecrewConstraintChanges -ProjectRoot $TestDrive -FeatureRef '001-visible' -IterationNumber '001' -PreviousCommitHash $fixture.PreviousCommit -CurrentCommitHash $fixture.CurrentCommit)

        Publish-SpecrewConstraintChangeRecords -ProjectRoot $TestDrive -BoundaryType 'review-signoff' -Changes $changes -NowUtc '2026-08-13T10:00:00Z'
        Publish-SpecrewConstraintChangeRecords -ProjectRoot $TestDrive -BoundaryType 'review-signoff' -Changes $changes -NowUtc '2026-08-13T10:01:00Z'

        $ledger = Get-Content -LiteralPath (Join-Path $TestDrive '.squad\decisions.md') -Raw -Encoding UTF8
        ([regex]::Matches($ledger, '\*\*Change Key\*\*:')).Count | Should -Be 2
        $events = @(Read-SpecrewJsonLines -Path (Join-Path $TestDrive '.squad\events\lifecycle-events.jsonl'))
        @($events | Where-Object { $_.event_type -eq 'constraint-change' }).Count | Should -Be 2
    }

    It 'wires visibility before the review signoff gate can refuse the boundary' {
        $source = Get-Content -LiteralPath $syncScript -Raw -Encoding UTF8
        $visibilityCall = $source.LastIndexOf('Publish-SpecrewConstraintChangeRecords')
        $gateCall = $source.LastIndexOf('Invoke-ContinuousCoReviewSignoffGateIfEnabled')

        $visibilityCall | Should -BeGreaterThan 0
        $gateCall | Should -BeGreaterThan $visibilityCall
    }
}
