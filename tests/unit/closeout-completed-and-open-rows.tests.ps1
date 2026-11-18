# Feature 206, T036 (FR-018, SC-011, bug list item 44, design D4-a): the governance check failed a closed iteration
# twice. plan.md had no Completed date, and the hardening gate's rows were still open. The check applies only once
# plan.md is at complete, which happens after the closeout verdict, so the closeout packet was shown with both open.
#
# Two fixes, two places:
#   - the mirror write that moves plan.md to complete writes the Completed date, once: a date already there is kept;
#   - the retro -> iteration-closeout arrival names the hardening gate's open items in the pending-verdict artifact,
#     so the packet the human reads lists them before the verdict.
# The arrival cases drive the real boundary sync on a temp git project.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    $script:SyncScript = Join-Path $script:RepoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
    $script:Roots = New-Object System.Collections.Generic.List[string]
    $script:Utf8 = [Text.UTF8Encoding]::new($false)

    function New-CloseoutFixture {
        param([string]$PlanBody, [string]$GateBody)
        $root = Join-Path ([IO.Path]::GetTempPath()) ('closeout-rows-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $script:Roots.Add($root) | Out-Null
        foreach ($d in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\001-test-feature\iterations\001\quality')) { $null = New-Item -ItemType Directory -Path (Join-Path $root $d) -Force }
        [IO.File]::WriteAllText((Join-Path $root '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/001-test-feature`"`n}", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.squad\team.md'), "# Team`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.squad\config.json'), "{}`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.squad\decisions.md'), "# Decisions`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.github\agents\squad.agent.md'), "# Squad Agent`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root 'specs\001-test-feature\spec.md'), "# Spec`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root 'README.md'), "# Test Repo`n", $script:Utf8)
        $iter = Join-Path $root 'specs\001-test-feature\iterations\001'
        [IO.File]::WriteAllText((Join-Path $iter 'plan.md'), $PlanBody, $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $iter 'state.md'), "# Iteration State: 001`n`n**Current Phase**: retro`n**Iteration Status**: retro`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $iter 'review.md'), "# Iteration Review: 001`n`n**Overall Verdict**: accepted`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $iter 'retro.md'), "# Iteration Retro: 001`n", $script:Utf8)
        if ($GateBody) { [IO.File]::WriteAllText((Join-Path $iter 'quality\hardening-gate.md'), $GateBody, $script:Utf8) }
        $ctx = [ordered]@{
            schema               = 'v2'
            feature_path         = (Join-Path $root 'specs\001-test-feature')
            generated_at_utc     = '2026-06-22T00:00:00Z'
            session_state        = [ordered]@{ active = $true; boundary_type = $null; feature_ref = '001-test-feature'; feature_path = (Join-Path $root 'specs\001-test-feature'); iteration_number = '001'; task_id = $null; auth_commit_hash = $null; recorded_at = '2026-06-22T00:00:00Z' }
            boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'retro'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
        }
        [IO.File]::WriteAllText((Join-Path $root '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), $script:Utf8)
        return [pscustomobject]@{ Root = $root; Iteration = $iter; Plan = (Join-Path $iter 'plan.md') }
    }

    function Invoke-RetroArrival {
        param($Fixture)
        $root = $Fixture.Root
        $null = & git -C $root init --quiet 2>&1
        $null = & git -C $root add -A 2>&1
        $null = & git -C $root -c user.email=t@specrew.local -c user.name=T commit -m seed --quiet 2>&1
        $null = & git -C $root branch -M main 2>&1
        $null = & git -C $root checkout -q -b 001-test-feature 2>&1
        $null = & pwsh -NoProfile -File $script:SyncScript -ProjectPath $root -BoundaryType retro -FeatureRef 001-test-feature -IterationNumber 001 -AuthCommitHash HEAD 2>&1
        $LASTEXITCODE | Should -Be 0 -Because 'the retro arrival sync succeeds'
        $artifact = Join-Path $root '.specrew\runtime\pending-verdict-stop.md'
        Test-Path -LiteralPath $artifact -PathType Leaf | Should -BeTrue -Because 'the retro -> iteration-closeout crossing is open'
        return (Get-Content -LiteralPath $artifact -Raw -Encoding UTF8)
    }

    $script:OpenGate = @"
# Hardening Gate: 001

**Post-Implementation Verification**: pending
**Verified At**: pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Notes |
| ------- | -------- | ------ | -------------- | ----------------------- | ----------------- | -------- | ----- |
| ``security-surface`` | ``security`` | ``addressed`` | ``planning-time-analysis`` | ``pending-post-implementation`` | input validation | true | |
| ``test-integrity-targets`` | ``verification`` | ``addressed`` | ``runtime-evidence`` | ``recorded`` | named tests | true | |
"@ + "`n"
    $script:ClosedGate = @"
# Hardening Gate: 001

**Post-Implementation Verification**: recorded in review.md
**Verified At**: 2026-11-15T10:00:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Notes |
| ------- | -------- | ------ | -------------- | ----------------------- | ----------------- | -------- | ----- |
| ``test-integrity-targets`` | ``verification`` | ``addressed`` | ``runtime-evidence`` | ``recorded`` | named tests | true | |
"@ + "`n"
}

AfterAll {
    foreach ($root in $script:Roots) {
        if ((Split-Path -Leaf $root) -like 'closeout-rows-*') { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'The mirror write that moves plan.md to complete writes the Completed date (FR-018, SC-011)' {
    It 'fills a blank Completed line with the date of the verdict' {
        $f = New-CloseoutFixture -PlanBody "# Iteration Plan: 001`n`n**Status**: retro`n**Started**: 2026-11-10`n**Completed**:`n"
        $null = Sync-SpecrewCrossingMirrors -ProjectRoot $f.Root -AuthorizedBoundary 'iteration-closeout' -FeatureRef '001-test-feature' -IterationNumber '001' -NowUtc '2026-11-16T10:00:00Z'
        $plan = Get-Content -LiteralPath $f.Plan -Raw
        $plan | Should -Match '(?m)^\*\*Status\*\*:\s*complete\s*$'
        $plan | Should -Match '(?m)^\*\*Completed\*\*: 2026-11-16\s*$'
    }

    It 'adds the Completed line after Started when the plan has none' {
        $f = New-CloseoutFixture -PlanBody "# Iteration Plan: 001`n`n**Status**: retro`n**Started**: 2026-11-10`n`n## Tasks`n"
        $null = Sync-SpecrewCrossingMirrors -ProjectRoot $f.Root -AuthorizedBoundary 'iteration-closeout' -FeatureRef '001-test-feature' -IterationNumber '001' -NowUtc '2026-11-16T10:00:00Z'
        $plan = Get-Content -LiteralPath $f.Plan -Raw
        $plan | Should -Match '(?m)^\*\*Started\*\*: 2026-11-10\r?\n\*\*Completed\*\*: 2026-11-16\r?$'
        ([regex]::Matches($plan, '(?m)^\*\*Completed\*\*:')).Count | Should -Be 1
    }

    It 'keeps a Completed date already recorded, and a second write changes nothing' {
        $f = New-CloseoutFixture -PlanBody "# Iteration Plan: 001`n`n**Status**: retro`n**Started**: 2026-11-10`n**Completed**:`n"
        $null = Sync-SpecrewCrossingMirrors -ProjectRoot $f.Root -AuthorizedBoundary 'iteration-closeout' -FeatureRef '001-test-feature' -IterationNumber '001' -NowUtc '2026-11-16T10:00:00Z'
        $first = Get-Content -LiteralPath $f.Plan -Raw
        $null = Sync-SpecrewCrossingMirrors -ProjectRoot $f.Root -AuthorizedBoundary 'iteration-closeout' -FeatureRef '001-test-feature' -IterationNumber '001' -NowUtc '2026-11-20T10:00:00Z'
        Get-Content -LiteralPath $f.Plan -Raw | Should -BeExactly $first
    }

    It 'writes no Completed date for a boundary that does not move plan.md to complete' {
        $f = New-CloseoutFixture -PlanBody "# Iteration Plan: 001`n`n**Status**: review`n**Started**: 2026-11-10`n**Completed**:`n"
        $null = Sync-SpecrewCrossingMirrors -ProjectRoot $f.Root -AuthorizedBoundary 'retro' -FeatureRef '001-test-feature' -IterationNumber '001' -NowUtc '2026-11-16T10:00:00Z'
        Get-Content -LiteralPath $f.Plan -Raw | Should -Match '(?m)^\*\*Completed\*\*:\s*$'
    }
}

Describe 'The closeout arrival names the hardening gate''s open items before the verdict (FR-018, SC-011)' {
    It 'lists each open row and the pending verification lines in the pending-verdict artifact' {
        $f = New-CloseoutFixture -PlanBody "# Iteration Plan: 001`n`n**Status**: retro`n**Started**: 2026-11-10`n**Completed**:`n" -GateBody $script:OpenGate
        $artifact = Invoke-RetroArrival -Fixture $f
        $artifact | Should -Match 'Boundary to ask for: retro -> iteration-closeout'
        $artifact | Should -Match 'Open in quality/hardening-gate\.md'
        $artifact | Should -Match "concern 'security-surface'"
        $artifact | Should -Not -Match "concern 'test-integrity-targets'"
        $artifact | Should -Match 'Post-Implementation Verification'
        $artifact | Should -Match 'Verified At'
    }

    It 'lists nothing when the gate is closed' {
        $f = New-CloseoutFixture -PlanBody "# Iteration Plan: 001`n`n**Status**: retro`n**Started**: 2026-11-10`n**Completed**:`n" -GateBody $script:ClosedGate
        $artifact = Invoke-RetroArrival -Fixture $f
        $artifact | Should -Match 'Boundary to ask for: retro -> iteration-closeout'
        $artifact | Should -Not -Match 'Open in quality/hardening-gate\.md'
    }
}
