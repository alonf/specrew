# Feature 206, T033 (FR-015, SC-008, bug list item 37, design D1-a): the governance check allowed a review task verdict
# of pass, needs-work or blocked only, and an `accepted` review could not hold a non-passing task, so a task deferred by
# a recorded decision had to be written `pass` with a note (iteration 001's T003, DRIFT-206-I001-027). review.md now
# accepts `deferred` on a row that names the deferring decision, `decision <id>`, an entry in .squad/decisions.md. A
# deferred row with no decision id, or naming one the ledger does not hold, fails; needs-work and blocked beside
# `accepted` still fail. Feature 203's T014 (scheduled after sign-off by its plan, with no decision) is not covered.
#
# Each case runs the validator on a temp fixture and looks only for the messages this rule writes.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('deferred-verdict-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Work -Force

    function New-ReviewFixture {
        param([string]$Name, [string]$T002Verdict, [string]$T002Notes)
        $root = Join-Path $script:Work $Name
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $root 'scripts\internal') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $root 'extensions\specrew-speckit\scripts') -Force
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\dashboard-renderer.ps1') -Destination (Join-Path $root 'scripts\internal\dashboard-renderer.ps1')
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1') -Destination (Join-Path $root 'extensions\specrew-speckit\scripts\shared-governance.ps1')
        $null = New-Item -ItemType Directory -Path (Join-Path $root '.squad') -Force
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot '.squad\team.md') -Destination (Join-Path $root '.squad\team.md')
        Set-Content -LiteralPath (Join-Path $root '.squad\decisions.md') -Encoding UTF8 -Value ("# Decisions`n`n## 2026-11-15T10:00:00Z — Defer T002 to the next iteration`n`n- **Decision ID**: f909-defer-t002`n- **Approving Human**: maintainer`n")
        $dir = Join-Path $root 'specs\909-deferred\iterations\001'
        $null = New-Item -ItemType Directory -Path $dir -Force
        Set-Content -LiteralPath (Join-Path $root 'specs\909-deferred\spec.md') -Value '# Feature Specification: 909-deferred' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'plan.md') -Encoding UTF8 -Value (@(
                '# Plan', '', '**Status**: reviewing', '', '## Tasks', '',
                '| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |',
                '| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |',
                '| T001 | First | FR-001 | US1 | 1 | Implementer | src/** | done | | | |',
                '| T002 | Second | FR-002 | US1 | 1 | Implementer | src/** | deferred | | | |'
            ) -join "`n")
        Set-Content -LiteralPath (Join-Path $dir 'state.md') -Value "# Iteration State: 001`n`n**Schema**: v2`n**Iteration Status**: reviewing`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'drift-log.md') -Value "# Drift Log`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $dir 'review.md') -Encoding UTF8 -Value (@(
                '# Review', '', '**Overall Verdict**: accepted', '', '## Task Verdicts', '',
                '| Task | Verdict | Notes |', '| --- | --- | --- |',
                '| T001 | pass | Implemented and tested. |',
                ('| T002 | {0} | {1} |' -f $T002Verdict, $T002Notes),
                '', '## Gap Ledger', '', 'No gaps.'
            ) -join "`n")
        return [pscustomobject]@{ Root = $root; Iteration = $dir }
    }

    function Invoke-FixtureValidator {
        param($Fixture)
        return (@(& pwsh -NoProfile -File $script:Validator -ProjectPath $Fixture.Root -IterationPath $Fixture.Iteration 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
    }
}

AfterAll {
    if ((Split-Path -Leaf $script:Work) -like 'deferred-verdict-*') { Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'A deferred task verdict names the decision that deferred it (FR-015, SC-008)' {
    It 'accepts a deferred row naming an existing decision beside an accepted review' {
        $output = Invoke-FixtureValidator -Fixture (New-ReviewFixture -Name 'ok' -T002Verdict 'deferred' -T002Notes 'Moved to iteration 002 by decision `f909-defer-t002`.')
        $output | Should -Not -Match "invalid verdict 'deferred'"
        $output | Should -Not -Match 'while tasks remain non-passing'
        $output | Should -Not -Match 'is deferred but'
    }

    It 'fails a deferred row that names no decision' {
        $output = Invoke-FixtureValidator -Fixture (New-ReviewFixture -Name 'no-id' -T002Verdict 'deferred' -T002Notes 'Moved to iteration 002.')
        $output | Should -Match "task 'T002' is deferred but names no decision"
    }

    It 'fails a deferred row naming a decision the ledger does not hold' {
        $output = Invoke-FixtureValidator -Fixture (New-ReviewFixture -Name 'missing' -T002Verdict 'deferred' -T002Notes 'Moved by decision `f909-no-such-decision`.')
        $output | Should -Match "task 'T002' is deferred by decision 'f909-no-such-decision', which \.squad/decisions\.md does not hold"
    }

    It 'still fails needs-work beside an accepted review' {
        $output = Invoke-FixtureValidator -Fixture (New-ReviewFixture -Name 'needs-work' -T002Verdict 'needs-work' -T002Notes 'Not finished.')
        $output | Should -Match "cannot record overall verdict 'accepted' while tasks remain non-passing: T002"
    }
}
