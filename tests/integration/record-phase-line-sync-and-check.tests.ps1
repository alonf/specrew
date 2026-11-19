# Feature 203, iteration 002, T023 (ii) (B5F-050, B5F-059): the boundary sync and the governance check, together, over
# the review sign-off and retro sequences. Feature 206's T034 (Get-SpecrewRecordApprovalState) is the one design for a
# record written before its approval; record-before-approval.tests.ps1 pins the check alone. This suite pins the
# sequence a crew walks: the record is written while the approval is pending and the check accepts it; the sync at
# that boundary accepts the tree; once the verdict is recorded the check requires the next phase line; and the sync's
# state-truth gate (Invoke-SpecrewIterationStateTruthGate, which brings the copies forward from the store) moves
# plan.md's Status there, after which the check passes again. The same for retro.md.
#
# The validator runs in its own process on a temp fixture, and each case looks only for the stale-status message, as in
# record-before-approval.tests.ps1: a fixture this small may fail other checks, which are not this suite's subject.
# The verdicts are written into the fixture's .specrew/start-context.json, as the recorded store reads; nothing here
# records a real approval. Everything runs in a temp folder this suite creates; no home is read or written.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\internal\sync-boundary-state.ps1')
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('record-phase-sync-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Work -Force
    $script:ReviewStale = "plan.md status '{0}' is stale: review.md exists"
    $script:RetroStale = "plan.md status '{0}' is stale: retro.md exists"
    $script:Feature = '909-sync-check'

    $script:Root = Join-Path $script:Work 'project'
    $script:Iteration = Join-Path $script:Root ('specs\{0}\iterations\001' -f $script:Feature)
    foreach ($dir in '.specrew', 'scripts\internal', 'extensions\specrew-speckit\scripts', '.squad', $script:Iteration.Substring($script:Root.Length + 1)) {
        $null = New-Item -ItemType Directory -Path (Join-Path $script:Root $dir) -Force
    }
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\dashboard-renderer.ps1') -Destination (Join-Path $script:Root 'scripts\internal\dashboard-renderer.ps1')
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1') -Destination (Join-Path $script:Root 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot '.squad\team.md') -Destination (Join-Path $script:Root '.squad\team.md')
    Set-Content -LiteralPath (Join-Path $script:Root '.squad\decisions.md') -Value '# Decisions' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:Root ('specs\{0}\spec.md' -f $script:Feature)) -Value ('# Feature Specification: {0}' -f $script:Feature) -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:Iteration 'plan.md') -Value "# Plan`n`n**Status**: executing`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:Iteration 'state.md') -Value (@(
            '# Iteration State: 001', '', '**Schema**: v1', '**Current Phase**: before-implement', '**Iteration Status**: executing',
            '**Baseline Ref**: HEAD', '**Updated**: 2026-11-19T00:00:00Z', '', '## Execution Summary', '',
            '- The tasks are done and the review record is written.'
        ) -join "`n") -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $script:Iteration 'drift-log.md') -Value "# Drift Log`n" -Encoding UTF8

    function script:Set-RecordedVerdict {
        # The store as the recorded verdict leaves it: the last authorized boundary, and the next crossing pending.
        param([Parameter(Mandatory)][string]$LastAuthorized, [AllowNull()][string]$PendingTo)
        $pending = if ($PendingTo) { @{ from = $LastAuthorized; to = $PendingTo; crossing_id = 'crossing-fixture' } } else { $null }
        $context = [ordered]@{
            schema_version       = '1.0'
            session_state        = [ordered]@{ active = $true; boundary_type = $LastAuthorized; feature_ref = $script:Feature; iteration_number = '001' }
            boundary_enforcement = [ordered]@{
                enabled = $true; last_authorized_boundary = $LastAuthorized; pending_next_boundary = $PendingTo; pending_crossing = $pending
                policy_classes = @{}; verdict_history = @(); correction_history = @(); bypass_history = @()
            }
        }
        Set-Content -LiteralPath (Join-Path $script:Root '.specrew\start-context.json') -Value ($context | ConvertTo-Json -Depth 6) -Encoding UTF8
    }

    function script:Invoke-Check {
        return (@(& pwsh -NoProfile -File $script:Validator -ProjectPath $script:Root -IterationPath $script:Iteration 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
    }

    function script:Invoke-SyncGate {
        # The sync's own gate at this boundary; a refusal throws '[iteration-state-truth-gate] ...'.
        param([Parameter(Mandatory)][string]$Boundary)
        Invoke-SpecrewIterationStateTruthGate -ProjectRoot $script:Root -BoundaryType $Boundary -FeatureRef $script:Feature -IterationNumber '001'
    }

    function script:Get-PlanStatus {
        $m = [regex]::Match((Get-Content -LiteralPath (Join-Path $script:Iteration 'plan.md') -Raw), '(?m)^\*\*Status\*\*:\s*(?<s>\S+)')
        return $m.Groups['s'].Value
    }
}

AfterAll {
    if ((Split-Path -Leaf $script:Work) -like 'record-phase-sync-*') { Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'The review sign-off sequence: the record before its verdict, then the sync moves the phase line' {
    It 'the check accepts review.md beside executing while the review-signoff verdict is pending' {
        Set-Content -LiteralPath (Join-Path $script:Iteration 'review.md') -Value "# Review`n`n**Overall Verdict**: accepted`n" -Encoding UTF8
        script:Set-RecordedVerdict -LastAuthorized 'before-implement' -PendingTo 'review-signoff'
        script:Invoke-Check | Should -Not -Match ([regex]::Escape(($script:ReviewStale -f 'executing')))
    }

    It 'the sync at review-signoff accepts the tree and leaves the phase line where the store is' {
        { script:Invoke-SyncGate -Boundary 'review-signoff' } | Should -Not -Throw
        script:Get-PlanStatus | Should -BeExactly 'executing'
    }

    It 'once the review-signoff verdict is recorded, the check requires reviewing' {
        script:Set-RecordedVerdict -LastAuthorized 'review-signoff' -PendingTo 'retro'
        script:Invoke-Check | Should -Match ([regex]::Escape(($script:ReviewStale -f 'executing')))
    }

    It 'the sync after the verdict moves plan.md to reviewing, and the check passes' {
        { script:Invoke-SyncGate -Boundary 'review-signoff' } | Should -Not -Throw
        script:Get-PlanStatus | Should -BeExactly 'reviewing'
        script:Invoke-Check | Should -Not -Match 'is stale: review\.md exists'
    }
}

Describe 'The retro sequence: the record before its verdict, then the sync moves the phase line' {
    It 'the check accepts retro.md beside reviewing while the retro verdict is pending' {
        Set-Content -LiteralPath (Join-Path $script:Iteration 'retro.md') -Value "# Retro`n" -Encoding UTF8
        script:Invoke-Check | Should -Not -Match ([regex]::Escape(($script:RetroStale -f 'reviewing')))
    }

    It 'the sync at retro accepts the tree and leaves the phase line where the store is' {
        { script:Invoke-SyncGate -Boundary 'retro' } | Should -Not -Throw
        script:Get-PlanStatus | Should -BeExactly 'reviewing'
    }

    It 'once the retro verdict is recorded, the check requires retro' {
        script:Set-RecordedVerdict -LastAuthorized 'retro' -PendingTo 'iteration-closeout'
        script:Invoke-Check | Should -Match ([regex]::Escape(($script:RetroStale -f 'reviewing')))
    }

    It 'the sync after the verdict moves plan.md to retro, and the check passes' {
        { script:Invoke-SyncGate -Boundary 'retro' } | Should -Not -Throw
        script:Get-PlanStatus | Should -BeExactly 'retro'
        script:Invoke-Check | Should -Not -Match 'is stale: retro\.md exists'
    }
}
