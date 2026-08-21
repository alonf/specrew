#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W40 (2026-08-21, KeyContextAI retro): the reviewer closeout artifacts had no working generator on the
# path that actually runs, and a scaffold reported failure while half-succeeding.
#
# The five artifacts closeout REQUIRES - code-map.md, dependency-report.md, coverage-evidence.md,
# reviewer-index.md, review-diagrams.md - were written inside a block guarded by `if (-not $SummaryOnly)`,
# and `scaffold-retro-artifact.ps1` invokes the generator WITH -SummaryOnly. So the retro flow printed a
# digest line naming `reviewer-index.md` and wrote none of them, and the closeout gate refused. Every
# project that reaches closeout hits it.
#
# One flag was doing two jobs. Output suppression already lived on its own further down, which is what
# -SummaryOnly means and all it should ever have meant.
#
# BEHAVIOURAL, against a REAL iteration: the defect was invisible to reading (the writers are all there,
# a few lines below a guard) and invisible to -DryRun and to -WhatIf, which is how it shipped.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Generator = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1'
    $script:RetroScaffold = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/scaffold-retro-artifact.ps1'
    $script:RequiredArtifacts = @('code-map.md', 'dependency-report.md', 'coverage-evidence.md',
        'reviewer-index.md', 'review-diagrams.md')

    function script:New-IterationFixture {
        # A real iteration, taken from this project's own - a synthetic one would not exercise the
        # table parsing the generator does, and a generator that only works on invented input is the
        # defect this suite exists to catch.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w40-' + [guid]::NewGuid().ToString('N'))
        $source = Join-Path $script:RepoRoot 'specs/199-beta3-stabilization'
        $target = Join-Path $root 'specs/199-beta3-stabilization'
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        Copy-Item -Path (Join-Path $source '*') -Destination $target -Recurse -Force
        $iteration = Join-Path $target 'iterations/001'
        foreach ($name in $script:RequiredArtifacts) {
            Remove-Item -LiteralPath (Join-Path $iteration $name) -Force -ErrorAction SilentlyContinue
        }
        return $iteration
    }
    function script:Get-MissingArtifacts {
        param([Parameter(Mandatory)][string]$IterationDirectory)
        return @($script:RequiredArtifacts | Where-Object {
                -not (Test-Path -LiteralPath (Join-Path $IterationDirectory $_) -PathType Leaf)
            })
    }
}

Describe 'W40 the reviewer closeout artifacts have a working generator' {
    It 'ACCEPTANCE: produces all five against a real iteration in -SummaryOnly, the mode retro uses' {
        # The exact invocation scaffold-retro-artifact.ps1 makes. Before the fix this wrote nothing
        # while printing a digest line that NAMED reviewer-index.md.
        $iteration = New-IterationFixture
        try {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $script:Generator -IterationDirectory $iteration -SummaryOnly *> $null
            $missing = Get-MissingArtifacts -IterationDirectory $iteration
            @($missing).Count | Should -Be 0 -Because "closeout requires these and -SummaryOnly is how the retro flow asks for them (missing: $($missing -join ', '))"
        }
        finally { Remove-Item -LiteralPath (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $iteration))) -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'produces all five on the ordinary path too' {
        $iteration = New-IterationFixture
        try {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $script:Generator -IterationDirectory $iteration *> $null
            @(Get-MissingArtifacts -IterationDirectory $iteration).Count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $iteration))) -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'writes nothing under -DryRun, which is what made the defect invisible' {
        # -DryRun and -WhatIf both looked healthy while the real path wrote nothing, so the fix must not
        # quietly turn a preview into a write either.
        $iteration = New-IterationFixture
        try {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $script:Generator -IterationDirectory $iteration -SummaryOnly -DryRun *> $null
            @(Get-MissingArtifacts -IterationDirectory $iteration).Count | Should -Be 5
        }
        finally { Remove-Item -LiteralPath (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $iteration))) -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W40 a scaffold that fails partway says what it wrote' {
    It 'names both what landed and what did not when the sub-step fails' {
        # retro.md is already written when the reviewer sub-step runs, so a bare non-zero exit leaves a
        # caller unable to classify the result from the exit code - which is how the missing artifacts
        # went unnoticed until a gate refused them, much later.
        $retro = Get-Content -LiteralPath $script:RetroScaffold -Raw -Encoding UTF8
        $retro | Should -Match 'PARTIAL SCAFFOLD'
        $retro | Should -Match 'WROTE:'
        $retro | Should -Match 'DID NOT WRITE'
        # And it must tell the reader how to finish the job rather than only that it failed - the
        # reachable-action property from W39.
        $retro | Should -Match 'Re-run only the reviewer'
        $retro | Should -Match 'does not need redoing'
    }

    It 'still exits non-zero on partial completion, so a caller is not told it succeeded' {
        $retro = Get-Content -LiteralPath $script:RetroScaffold -Raw -Encoding UTF8
        $retro | Should -Match 'exit 1'
    }
}
