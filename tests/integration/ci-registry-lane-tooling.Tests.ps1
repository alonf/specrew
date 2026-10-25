$ErrorActionPreference = 'Stop'

# Trace: T013 / FR-022 (198-carried chore, ruled in scope as release hygiene).
#
# `generator-markdown-parity` refuses to fake a pass: with markdownlint absent it exits 2 as
# INCONCLUSIVE (the third-outcome rule) rather than reporting green. It runs inside the F-198
# honesty registry, which CI executes in the `deterministic-gate` job — a DIFFERENT runner from
# the `lint` job that installs the tool. `needs:` orders jobs; it does not share their tools.
# The lane therefore reported INCONCLUSIVE on every run, which is the standing main red the beta2
# closeout carried as a chore.
#
# The rule this pins is general, not a one-off patch: ANY workflow job that runs the registry
# suite must install the tooling the registry needs, so the same silent inconclusive cannot
# return under a different job name.
Describe 'CI jobs running the honesty registry carry its tooling (T013 / FR-022)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        $script:WorkflowPath = Join-Path $script:RepoRoot '.github/workflows/specrew-ci.yml'

        # Split the workflow into top-level job blocks (two-space indented keys under `jobs:`).
        function script:Get-WorkflowJobBlocks {
            param([Parameter(Mandatory)][string]$Path)
            $lines = @(Get-Content -LiteralPath $Path)
            $blocks = @{}
            $currentName = $null
            $current = [Collections.Generic.List[string]]::new()
            foreach ($line in $lines) {
                if ($line -match '^  (?<name>[A-Za-z0-9_-]+):\s*$') {
                    if ($null -ne $currentName) { $blocks[$currentName] = ($current -join "`n") }
                    $currentName = $Matches['name']
                    $current = [Collections.Generic.List[string]]::new()
                    continue
                }
                if ($null -ne $currentName) { $current.Add($line) }
            }
            if ($null -ne $currentName) { $blocks[$currentName] = ($current -join "`n") }
            return $blocks
        }
    }

    It 'the workflow parses into named job blocks' {
        $blocks = script:Get-WorkflowJobBlocks -Path $script:WorkflowPath
        $blocks.Keys | Should -Contain 'deterministic-gate'
        $blocks.Keys | Should -Contain 'lint'
    }

    It 'every job that runs the honesty registry also installs markdownlint-cli' {
        $blocks = script:Get-WorkflowJobBlocks -Path $script:WorkflowPath
        $registryJobs = @($blocks.Keys | Where-Object { $blocks[$_] -match 'f198-regression-suite\.ps1' })

        $registryJobs.Count | Should -BeGreaterThan 0
        foreach ($job in $registryJobs) {
            $blocks[$job] | Should -Match 'markdownlint-cli' -Because "job '$job' runs the registry, which needs markdownlint or it reports INCONCLUSIVE"
        }
    }

    It 'every registry job and step carry measured runtime headroom' {
        $blocks = script:Get-WorkflowJobBlocks -Path $script:WorkflowPath
        $registryJobs = @($blocks.Keys | Where-Object { $blocks[$_] -match 'f198-regression-suite\.ps1' })

        $registryJobs.Count | Should -BeGreaterThan 0
        foreach ($job in $registryJobs) {
            $jobTimeout = [regex]::Match($blocks[$job], '(?m)^    timeout-minutes:\s*(?<minutes>\d+)\s*$')
            $jobTimeout.Success | Should -BeTrue -Because "job '$job' must have a bounded timeout"
            [int]$jobTimeout.Groups['minutes'].Value | Should -BeGreaterOrEqual 60 -Because "the registry measured 19.22 minutes before setup and the remaining deterministic gates"

            $registryStep = [regex]::Match(
                $blocks[$job],
                '(?ms)^      - name: F-198 honesty regression suite.*?(?=^      - name:|\z)'
            )
            $registryStep.Success | Should -BeTrue
            $stepTimeout = [regex]::Match($registryStep.Value, '(?m)^        timeout-minutes:\s*(?<minutes>\d+)\s*$')
            $stepTimeout.Success | Should -BeTrue -Because 'the broad registry needs its own reviewable bound'
            [int]$stepTimeout.Groups['minutes'].Value | Should -BeGreaterOrEqual 30 -Because 'the measured registry runtime is 19.22 minutes'
        }
    }

    It 'the parity suite still refuses to fake a pass when the tool is absent' {
        # The third-outcome rule is the reason this chore matters; pin that it survives.
        $suite = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests/integration/generator-markdown-parity.tests.ps1') -Raw
        $suite | Should -Match 'Write-Inconclusive'
        $suite | Should -Match 'exit 2'
    }
}
