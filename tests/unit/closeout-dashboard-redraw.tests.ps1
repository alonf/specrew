# Feature 206, T035 (FR-017, SC-010, bug list item 41, design D3-a): the closeout sync drew the iteration dashboard when
# the retro -> iteration-closeout crossing opened; the verdict capture then moved the phase lines and sealed the
# iteration, and nothing redrew it. The sealed snapshot showed the phase as retro, 0 SP delivered and an "awaiting your
# verdict" banner. The capture now redraws the dashboard after its mirrors and before its seal; a redraw that fails
# warns and never blocks the seal.
#
# A temp project at the iteration-closeout arrival, as the sealed-iteration suite builds it; the capture runs in-process.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    $script:Roots = New-Object System.Collections.Generic.List[string]

    function New-CloseoutArrivalProject {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('closeout-redraw-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $script:Roots.Add($root) | Out-Null
        $iter = Join-Path $root 'specs/001-fixture/iterations/001'
        $null = New-Item -ItemType Directory -Path $iter -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force
        $utf8 = [Text.UTF8Encoding]::new($false)
        [IO.File]::WriteAllText((Join-Path $root '.specrew/config.yml'), "version: 1`n", $utf8)
        [IO.File]::WriteAllText((Join-Path $root 'specs/001-fixture/spec.md'), "# Feature Specification: Fixture`n", $utf8)
        [IO.File]::WriteAllText((Join-Path $iter 'plan.md'), "# Iteration Plan: 001`n`n**Status**: retro`n**Capacity**: 3/20 story_points`n`n## Tasks`n`n| Task | Requirement | Title | Story | Effort | Status |`n| ---- | ----------- | ----- | ----- | ------ | ------ |`n| T-001 | FR-001 | Do the thing | S-1 | 2 | done |`n| T-002 | FR-001 | Test the thing | S-1 | 1 | done |`n", $utf8)
        [IO.File]::WriteAllText((Join-Path $iter 'state.md'), "# Iteration State: 001`n`n**Schema**: v2`n**Current Phase**: retro`n**Iteration Status**: retro`n**Last Completed Task**: T-002`n**Tasks Remaining**: 0`n", $utf8)
        [IO.File]::WriteAllText((Join-Path $iter 'review.md'), "# Review: Iteration 001`n`n**Overall Verdict**: accepted`n", $utf8)
        [IO.File]::WriteAllText((Join-Path $iter 'retro.md'), "# Retro: Iteration 001`n`nWhat went well.`n", $utf8)
        $ctx = [ordered]@{
            schema               = 'v2'
            feature_path         = (Join-Path $root 'specs/001-fixture')
            session_state        = [ordered]@{ active = $true; boundary_type = 'iteration-closeout'; feature_ref = '001-fixture'; iteration_number = '001'; recorded_at = '2026-09-10T12:30:00Z' }
            boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'retro'; pending_next_boundary = 'iteration-closeout'; verdict_history = @(); bypass_history = @() }
        }
        [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), $utf8)
        # What the closeout sync drew at the arrival, before the verdict.
        [IO.File]::WriteAllText((Join-Path $iter 'dashboard.md'), "# Velocity Dashboard Snapshot`n`nphase RETRO | 3 SP planned | 0 SP delivered`nAWAITING YOUR VERDICT`n", $utf8)
        return [pscustomobject]@{ Root = $root; Iteration = $iter }
    }

    function Invoke-CloseoutCapture {
        param($Project)
        return Add-SpecrewBoundaryAuthorization -ProjectRoot $Project.Root -CurrentBoundary 'retro' -AuthorizedBoundary 'iteration-closeout' -AuthorizingHuman 'Fixture Human' -VerdictText 'approved for iteration-closeout' -EvidenceSource 'hook-captured-from-transcript'
    }
}

AfterAll {
    foreach ($root in $script:Roots) {
        if ((Split-Path -Leaf $root) -like 'closeout-redraw-*') { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'The capture redraws the closeout dashboard before it seals (FR-017, SC-010)' {
    It 'seals a dashboard that shows the delivered points, the iteration-closeout phase and the iteration as shipped' {
        $project = New-CloseoutArrivalProject
        $null = Invoke-CloseoutCapture -Project $project
        $dashboard = Get-Content -LiteralPath (Join-Path $project.Iteration 'dashboard.md') -Raw
        $dashboard | Should -Match '(?i)phase ITERATION-CLOSEOUT'
        $dashboard | Should -Match '3 SP planned \| 3 SP delivered'
        $dashboard | Should -Match '(?s)RECENT SHIPPED.*iter-001'
        $dashboard | Should -Not -Match 'AWAITING YOUR VERDICT'
        Test-SpecrewIterationSealed -IterationDirectory $project.Iteration | Should -BeTrue
        $integrity = Test-SpecrewIterationSealIntegrity -IterationDirectory $project.Iteration
        @(@($integrity.drifted) + @($integrity.missing) + @($integrity.added)).Count | Should -Be 0 -Because 'the seal is taken after the redraw'
    }

    It 'still seals, with a warning, when the redraw fails' {
        $project = New-CloseoutArrivalProject
        $script:RedrawCalls = 0
        function Invoke-SpecrewCloseoutDashboardRedraw { param($ProjectRoot, $IterationDirectory, $Feature, $Iteration) $script:RedrawCalls++; throw 'renderer unavailable (fixture)' }
        try {
            $stderr = Join-Path $project.Root 'stderr.txt'
            $previous = [Console]::Error
            $writer = [IO.StreamWriter]::new($stderr)
            [Console]::SetError($writer)
            try { $null = Invoke-CloseoutCapture -Project $project }
            finally { $writer.Flush(); $writer.Dispose(); [Console]::SetError($previous) }
            $script:RedrawCalls | Should -Be 1
            Test-SpecrewIterationSealed -IterationDirectory $project.Iteration | Should -BeTrue
            Get-Content -LiteralPath $stderr -Raw | Should -Match 'CLOSEOUT_DASHBOARD_NOT_REDRAWN'
        }
        finally {
            Remove-Item -Path Function:\Invoke-SpecrewCloseoutDashboardRedraw -ErrorAction SilentlyContinue
            . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
        }
    }
}
