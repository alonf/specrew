#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# DRIFT-006 (2026-08-22, found by a downstream closeout): one retro scaffold run emitted seven `.pending`
# siblings for seven files the same run had just created.
#
# Two causes, both mine:
#
#  1. scaffold-retro-artifact.ps1 invoked the reviewer scaffold TWICE - once with -PassThru to collect
#     actions, once with -SummaryOnly to print. Harmless while -SummaryOnly skipped the writes. W40
#     removed that skip, correctly, and the second call became a second writing pass.
#  2. The artifact-protection check asks `does this file exist and does the iteration read accepted`.
#     After the first pass, every artifact existed - so the second pass judged files it had authored
#     moments earlier to be protected human evidence and diverted all of them.
#
# Cosmetic in isolation. Not cosmetic in effect: the `.pending` warning added the day before exists so a
# human reads it and decides, and seven false ones per closeout is how a signal becomes wallpaper.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

    function script:New-AcceptedIteration {
        # Accepted, because that is the state in which protection engages - and every closeout is
        # accepted by the time the retro scaffold runs, so this is the normal case, not a corner.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('drift006-' + [guid]::NewGuid().ToString('N'))
        $target = Join-Path $root 'specs/199-beta3-stabilization'
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        Copy-Item -Path (Join-Path $script:RepoRoot 'specs/199-beta3-stabilization/*') -Destination $target -Recurse -Force
        $iteration = Join-Path $target 'iterations/001'
        Get-ChildItem -LiteralPath $iteration -Filter '*.pending' -File -ErrorAction SilentlyContinue | Remove-Item -Force
        # The five closeout artifacts absent, exactly as they are when a closeout begins.
        foreach ($name in @('code-map.md', 'coverage-evidence.md', 'reviewer-index.md', 'review-diagrams.md',
                'dependency-report.md', 'dashboard.md')) {
            Remove-Item -LiteralPath (Join-Path $iteration $name) -Force -ErrorAction SilentlyContinue
        }
        Remove-Item -LiteralPath (Join-Path $target 'current-architecture.md') -Force -ErrorAction SilentlyContinue
        return [pscustomobject]@{ Root = $root; Iteration = $iteration }
    }

    function script:Get-Pending {
        param([Parameter(Mandatory)][string]$IterationDirectory)
        return @(Get-ChildItem -LiteralPath $IterationDirectory -Filter '*.pending' -File -ErrorAction SilentlyContinue |
                ForEach-Object { $_.Name })
    }
}

Describe 'DRIFT-006 a run does not divert the files it just created' {
    It 'ACCEPTANCE: a closeout on an accepted iteration produces no .pending junk' {
        $f = New-AcceptedIteration
        try {
            & pwsh -NoProfile -NonInteractive -File (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1') `
                -IterationDirectory $f.Iteration *> $null
            $LASTEXITCODE | Should -Be 0
            @(Get-Pending -IterationDirectory $f.Iteration) | Should -BeNullOrEmpty -Because 'every one of those files was written by this same run'
            (Test-Path -LiteralPath (Join-Path $f.Iteration 'code-map.md') -PathType Leaf) | Should -BeTrue
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the retro scaffold invokes the reviewer scaffold exactly once' {
        # Structural, and the string it counts is a call, not a comment: an ampersand invocation of the
        # helper path variable. Two of them is the defect, whatever the reason for the second.
        $t = $null; $e = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\scaffold-retro-artifact.ps1'), [ref]$t, [ref]$e)
        @($e).Count | Should -Be 0
        $invocations = @($ast.FindAll({
                    param($n)
                    ($n -is [System.Management.Automation.Language.CommandAst]) -and
                    ($n.InvocationOperator -ne [System.Management.Automation.Language.TokenKind]::Unknown) -and
                    ("$($n.CommandElements[0].Extent.Text)" -eq '$reviewerArtifactScriptPath')
                }, $true))
        @($invocations).Count | Should -Be 1 -Because 'the second call was a second WRITING pass once -SummaryOnly stopped skipping work'
    }

    It 'a re-run rewrites nothing it does not have to, and still diverts nothing' {
        # The second run sees the first run's files as pre-existing, which is correct - but their content
        # is identical, so there is nothing to protect and nothing to update. Recording 'unchanged' is
        # what keeps a legitimate re-run from filling the directory with copies of itself.
        $f = New-AcceptedIteration
        try {
            $scaffold = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1'
            & pwsh -NoProfile -NonInteractive -File $scaffold -IterationDirectory $f.Iteration *> $null
            $before = (Get-Item -LiteralPath (Join-Path $f.Iteration 'code-map.md')).LastWriteTimeUtc
            & pwsh -NoProfile -NonInteractive -File $scaffold -IterationDirectory $f.Iteration *> $null
            $LASTEXITCODE | Should -Be 0
            @(Get-Pending -IterationDirectory $f.Iteration) | Should -BeNullOrEmpty
            (Get-Item -LiteralPath (Join-Path $f.Iteration 'code-map.md')).LastWriteTimeUtc |
                Should -Be $before -Because 'identical content is not a change'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'still protects a genuinely different pre-existing artifact' {
        # The W41 decision survives this fix. A file that existed before the run and whose content
        # differs is still diverted rather than overwritten - that is the whole point of the mechanism,
        # and narrowing it to "not what I just wrote" must not narrow it to nothing.
        $f = New-AcceptedIteration
        try {
            [IO.File]::WriteAllText((Join-Path $f.Iteration 'code-map.md'), "# HAND-AUTHORED, DIFFERENT`n",
                [Text.UTF8Encoding]::new($false))
            & pwsh -NoProfile -NonInteractive -File (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1') `
                -IterationDirectory $f.Iteration *> $null
            @(Get-Pending -IterationDirectory $f.Iteration) | Should -Contain 'code-map.md.pending'
            (Get-Content -LiteralPath (Join-Path $f.Iteration 'code-map.md') -Raw -Encoding UTF8) | Should -Match 'HAND-AUTHORED'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
