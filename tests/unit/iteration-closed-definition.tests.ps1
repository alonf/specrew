# Feature 206, T006 (FR-008a, design D3): one definition of "closed", used by every path.
#   closed = in .specrew/closed-iterations.yml, or state.md Iteration Status `complete` / `abandoned`, or a
#            status that claims closure in the words the validator already reads as a claim ("closed",
#            "closeout complete", "closure complete") with no negation or future wording before it
#            (maintainer ruling 2026-11-11, option 1 with conditions);
#   a .specrew/legacy-frozen.yml entry is never closed (it is judged by nothing, T008);
#   a review verdict alone never makes an iteration closed, and the state.md text heuristic decides nothing.
# The validator's closed filter, the dashboard check (through the renderer) and the renderer use it.
#
# Everything runs on a temp-folder fixture project with the real shared library and renderer dot-sourced.
# No specrew start, update or init; no hooks; nothing written outside the temp folder.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:SharedGovernance = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    . $script:SharedGovernance
    . (Join-Path $script:RepoRoot 'scripts\internal\dashboard-renderer.ps1')

    $script:Root = Join-Path ([System.IO.Path]::GetTempPath()) ('closed-def-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Root '.specrew') -Force

    function New-FixtureIteration {
        param([string]$Feature, [string]$Iteration, [string]$StateBody, [string]$ReviewVerdict)
        $featureDir = Join-Path $script:Root (Join-Path 'specs' $Feature)
        $dir = Join-Path $featureDir (Join-Path 'iterations' $Iteration)
        $null = New-Item -ItemType Directory -Path $dir -Force
        $spec = Join-Path $featureDir 'spec.md'
        if (-not (Test-Path -LiteralPath $spec)) { Set-Content -LiteralPath $spec -Value "# Feature Specification: $Feature" -Encoding UTF8 }
        if ($null -ne $StateBody) { Set-Content -LiteralPath (Join-Path $dir 'state.md') -Value ("# Iteration State: $Iteration`n`n**Schema**: v2`n" + $StateBody) -Encoding UTF8 }
        if ($ReviewVerdict) { Set-Content -LiteralPath (Join-Path $dir 'review.md') -Value ("# Review`n`n**Overall Verdict**: $ReviewVerdict`n") -Encoding UTF8 }
    }

    New-FixtureIteration -Feature '901-fixture' -Iteration '001' -StateBody "**Iteration Status**: reviewing`n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '002' -StateBody "**Iteration Status**: complete`n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '003' -StateBody "**Iteration Status**: abandoned`n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '004' -StateBody "**Iteration Status**: retro`n" -ReviewVerdict 'accepted'
    New-FixtureIteration -Feature '901-fixture' -Iteration '005' -StateBody "**Current Phase**: iteration-closeout`n**Iteration Status**: reviewing`n`nRETRO COMPLETE; iteration closed.`n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '006' -StateBody "**Iteration Status**: complete`n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '007' -StateBody "**Iteration Status**: ``Complete```n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '008' -StateBody $null -ReviewVerdict 'accepted'
    New-FixtureIteration -Feature '901-fixture' -Iteration '009' -StateBody "**Iteration Status**: executing`n"
    # Option 1: a status that claims closure in the validator's own closure-claim words, no index entry.
    New-FixtureIteration -Feature '901-fixture' -Iteration '010' -StateBody "**Iteration Status**: iteration closed on 2026-05-02 via iteration-closeout boundary commit ``abc1234```n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '011' -StateBody "**Iteration Status**: iteration-closeout complete on 2026-05-18; feature-closeout remains unopened`n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '012' -StateBody "**Iteration Status**: Closure complete`n"
    # Negative cases (maintainer condition 1): none of these is a claim of closure.
    New-FixtureIteration -Feature '901-fixture' -Iteration '013' -StateBody "**Iteration Status**: not closed`n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '014' -StateBody "**Iteration Status**: not yet closed`n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '015' -StateBody "**Iteration Status**: to be closed after review`n"
    New-FixtureIteration -Feature '901-fixture' -Iteration '016' -StateBody "**Iteration Status**: blocked`n"
    # A real status shape from this repository: the claim is in the first sentence; the later 'pending' is about
    # feature-closeout, not this iteration.
    New-FixtureIteration -Feature '901-fixture' -Iteration '017' -StateBody "**Iteration Status**: Iteration 001 is closed. Feature-closeout remains unopened pending fresh authorization.`n"

    Set-Content -LiteralPath (Join-Path $script:Root '.specrew\closed-iterations.yml') -Encoding UTF8 -Value @'
closed:
  - feature: 901-fixture
    iteration: 001
    closed_at: 2026-08-06T14:49:04Z
  - feature: 901-fixture
    iteration: 006
    closed_at: 2026-08-06T14:49:04Z
'@
    Set-Content -LiteralPath (Join-Path $script:Root '.specrew\legacy-frozen.yml') -Encoding UTF8 -Value @'
schema: v1
closed_on: 2026-11-10
entries:
  - iteration: 901-fixture/006
    reason: fixture entry, delivered but never formally closed
'@

    $null = & git -C $script:Root init --quiet 2>&1
}

AfterAll {
    if ($script:Root -and (Test-Path -LiteralPath $script:Root)) { Remove-Item -LiteralPath $script:Root -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'Test-SpecrewIterationClosed: one definition (FR-008a)' {
    It 'is closed when the closed index has it, whatever state.md says' {
        Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration '001' | Should -BeTrue
    }

    It 'is closed when Iteration Status is complete' {
        Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration '002' | Should -BeTrue
    }

    It 'is closed when Iteration Status is abandoned' {
        Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration '003' | Should -BeTrue
    }

    It 'reads the status without backticks or case' {
        Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration '007' | Should -BeTrue
    }

    It 'is never closed by an accepted review alone' {
        Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration '004' | Should -BeFalse
        Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration '008' | Should -BeFalse
    }

    It 'is never closed by the state.md text heuristic' {
        Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration '005' | Should -BeFalse
    }

    It 'is not closed for a frozen entry, even one in the index with status complete' {
        Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration '006' | Should -BeFalse
    }

    It 'is closed when the status claims closure in the validator''s closure-claim words (option 1)' {
        foreach ($n in '010', '011', '012', '017') {
            Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration $n | Should -BeTrue -Because "iteration $n"
        }
    }

    It 'is not closed by a negated or future closure word, or by blocked (condition 1)' {
        foreach ($n in '013', '014', '015', '016') {
            Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration $n | Should -BeFalse -Because "iteration $n"
        }
    }

    It 'leaves Test-ClosedIterationStatus unchanged for its other callers' {
        # The closeout-evidence check still reads any closure word as a claim, as before T006.
        Test-ClosedIterationStatus -IterationStatus 'not closed' | Should -BeTrue
        Test-ClosedIterationStatus -IterationStatus 'to be closed after review' | Should -BeTrue
        Test-ClosedIterationStatus -IterationStatus 'blocked' | Should -BeFalse
    }

    It 'is open for an in-flight status' {
        Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration '009' | Should -BeFalse
    }

    It 'gives the same answers with a preloaded index and frozen list' {
        $index = Get-SpecrewClosedIterationIndex -ProjectRoot $script:Root
        $frozen = @(Get-SpecrewLegacyFrozenIterationKeys -ProjectRoot $script:Root)
        $frozen | Should -Be @('901-fixture/006')
        foreach ($n in '001', '002', '003', '004', '005', '006', '007', '008', '009', '010', '011', '012', '013', '014', '015', '016', '017') {
            $plain = Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration $n
            $preloaded = Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration $n -ClosedIndex $index -FrozenKeys $frozen
            $preloaded | Should -Be $plain -Because "iteration $n"
        }
    }
}

Describe 'The renderer and the dashboard check use the same definition (FR-008a)' {
    It 'marks is_closed exactly as Test-SpecrewIterationClosed answers' {
        $feature = @(Get-SpecrewFeatureRecords -ProjectRoot $script:Root) | Where-Object feature_ref -eq '901-fixture'
        $feature | Should -Not -BeNullOrEmpty
        foreach ($iteration in @($feature.iterations)) {
            $expected = Test-SpecrewIterationClosed -ProjectRoot $script:Root -Feature '901-fixture' -Iteration $iteration.iteration_ref
            [bool]$iteration.is_closed | Should -Be $expected -Because "iteration $($iteration.iteration_ref)"
        }
        @($feature.closed_iterations | ForEach-Object { $_.iteration_ref }) | Sort-Object | Should -Be @('001', '002', '003', '007', '010', '011', '012', '017')
    }

    It 'still reports the review verdict for display without using it for closure' {
        $feature = @(Get-SpecrewFeatureRecords -ProjectRoot $script:Root) | Where-Object feature_ref -eq '901-fixture'
        $retro = @($feature.iterations) | Where-Object iteration_ref -eq '004'
        $retro.review_verdict | Should -Be 'accepted'
        [bool]$retro.is_closed | Should -BeFalse
    }
}

Describe 'The validator''s closed filter uses the same definition (FR-008a)' {
    It 'calls Test-SpecrewIterationClosed and no longer consults the state.md heuristic' {
        $source = Get-Content -LiteralPath $script:Validator -Raw
        $filter = [regex]::Match($source, '(?s)\$closedSkippedCount = 0.*?Write-Host \$scopeBanner').Value
        $filter | Should -Not -BeNullOrEmpty
        $filter | Should -Match 'Test-SpecrewIterationClosed'
        $filter | Should -Not -Match 'Get-SpecrewClosedIterationFromStateFile'
    }

    It 'keeps the .specify mirrors identical to their sources' {
        foreach ($name in 'shared-governance.ps1', 'validate-governance.ps1') {
            $source = Join-Path $script:RepoRoot "extensions\specrew-speckit\scripts\$name"
            $mirror = Join-Path $script:RepoRoot ".specify\extensions\specrew-speckit\scripts\$name"
            (Get-FileHash -LiteralPath $mirror).Hash | Should -Be (Get-FileHash -LiteralPath $source).Hash -Because $name
        }
    }
}
