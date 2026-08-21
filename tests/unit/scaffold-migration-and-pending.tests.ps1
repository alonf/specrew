#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W41 (2026-08-21): can a project that hand-authored the closeout artifacts to work around the crash
# ever receive generated versions?
#
# The concern was that the workaround becomes permanent and invisible, because
# `Write-MissingScaffoldFile` records `preserved` and returns when the target exists. Measured, and the
# premise does not hold for the five closeout artifacts: they are written by `Write-ScaffoldFile`, which
# UPDATES. `Write-MissingScaffoldFile` governs a different set - the dashboard, the hardening gate and
# the trap-reapplication record.
#
# What decides the outcome is whether the ITERATION is accepted, not whether the artifact is:
#
#   not accepted  -> the generated version overwrites the hand-authored one. The workaround ends.
#   accepted      -> the artifact is protected and the generated version lands at `<name>.pending`,
#                    because overwriting an artifact under an accepted verdict would silently alter
#                    accepted evidence.
#
# Both halves are pinned here, because "we decided not to change this" is only a decision if the
# behaviour it rests on is guarded. The gap that WAS real - nothing ever mentioned a `.pending` file
# again - is closed and pinned too.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Generator = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1'

    function script:New-Fixture {
        param([switch]$Accepted)
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w41-' + [guid]::NewGuid().ToString('N'))
        $target = Join-Path $root 'specs/199-beta3-stabilization'
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        Copy-Item -Path (Join-Path $script:RepoRoot 'specs/199-beta3-stabilization/*') -Destination $target -Recurse -Force
        $iteration = Join-Path $target 'iterations/001'
        $reviewPath = Join-Path $iteration 'review.md'
        $review = Get-Content -LiteralPath $reviewPath -Raw -Encoding UTF8
        if (-not $Accepted) { $review = $review -replace '\*\*Overall Verdict\*\*:\s*accepted', '**Overall Verdict**: needs-rework' }
        [IO.File]::WriteAllText($reviewPath, $review, [Text.UTF8Encoding]::new($false))
        Get-ChildItem -LiteralPath $iteration -Filter '*.pending' -File -ErrorAction SilentlyContinue | Remove-Item -Force
        # The workaround a project would have applied to get past the crash.
        [IO.File]::WriteAllText((Join-Path $iteration 'code-map.md'), "# HAND-AUTHORED WORKAROUND`n", [Text.UTF8Encoding]::new($false))
        return [pscustomobject]@{ Root = $root; Iteration = $iteration }
    }
    function script:Invoke-Generator {
        param([Parameter(Mandatory)][string]$IterationDirectory)
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $script:Generator -IterationDirectory $IterationDirectory -SummaryOnly *> $null
    }
}

Describe 'W41 a hand-authored workaround does not become permanent' {
    It 'THE MIGRATION CASE: an unaccepted iteration receives the generated version' {
        # This is the decision. If it ever stops holding, a project that papered over the crash keeps
        # its placeholder for good, and the reason to leave the writer alone disappears with it.
        $f = New-Fixture
        try {
            Invoke-Generator -IterationDirectory $f.Iteration
            $content = Get-Content -LiteralPath (Join-Path $f.Iteration 'code-map.md') -Raw -Encoding UTF8
            $content | Should -Not -Match 'HAND-AUTHORED WORKAROUND'
            $content | Should -Match 'Code Map'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'an ACCEPTED iteration keeps its artifact and diverts the generated version to .pending' {
        # Not a gap: overwriting an artifact under an accepted verdict would silently alter accepted
        # evidence. Non-destructive, and the human decides.
        $f = New-Fixture -Accepted
        try {
            Invoke-Generator -IterationDirectory $f.Iteration
            (Get-Content -LiteralPath (Join-Path $f.Iteration 'code-map.md') -Raw -Encoding UTF8) | Should -Match 'HAND-AUTHORED WORKAROUND'
            (Test-Path -LiteralPath (Join-Path $f.Iteration 'code-map.md.pending') -PathType Leaf) | Should -BeTrue
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W41 a diverted artifact does not wait in silence' {
    It 'names every .pending sibling at validation' {
        # The gap that WAS real. The only notice used to be a WARN at scaffold time, which scrolls past,
        # and nothing in the lifecycle mentioned the file again.
        $t = $null; $e = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'), [ref]$t, [ref]$e)
        foreach ($name in @('Test-ScaffoldPendingSiblings', 'Write-TrustHardeningWarning')) {
            $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $n.Name -eq $name }, $true) | Select-Object -First 1
            if (-not $fn) { throw "$name not found" }
            . ([scriptblock]::Create($fn.Extent.Text))
        }
        $script:ValidatorSoftWarnings = 0

        $f = New-Fixture -Accepted
        try {
            Invoke-Generator -IterationDirectory $f.Iteration
            $errors = [System.Collections.Generic.List[string]]::new()
            $before = $script:ValidatorSoftWarnings
            Test-ScaffoldPendingSiblings -IterationDirectory $f.Iteration -Errors $errors
            ($script:ValidatorSoftWarnings - $before) | Should -Be 1 -Because 'a waiting generated artifact must be mentioned'
            @($errors).Count | Should -Be 0 -Because 'it is information to reconcile, not a governance failure'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'says nothing when there is nothing waiting' {
        # Clears any .pending first, because this case is about the CHECK, not the generator - and the
        # generator legitimately produces some even on an unaccepted iteration (see the case below).
        $f = New-Fixture
        try {
            Invoke-Generator -IterationDirectory $f.Iteration
            Get-ChildItem -LiteralPath $f.Iteration -Filter '*.pending' -File -ErrorAction SilentlyContinue | Remove-Item -Force
            $t = $null; $e = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'), [ref]$t, [ref]$e)
            foreach ($name in @('Test-ScaffoldPendingSiblings', 'Write-TrustHardeningWarning')) {
                $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                        $n.Name -eq $name }, $true) | Select-Object -First 1
                . ([scriptblock]::Create($fn.Extent.Text))
            }
            $script:ValidatorSoftWarnings = 0
            $errors = [System.Collections.Generic.List[string]]::new()
            Test-ScaffoldPendingSiblings -IterationDirectory $f.Iteration -Errors $errors
            $script:ValidatorSoftWarnings | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'protects a verdict-bearing artifact even when the iteration is not accepted' {
        # Refines the summary above, and it matters for the migration question. Protection is not keyed
        # ONLY on the iteration: an artifact whose OWN content carries pass/blocked rows is protected on
        # its own account. coverage-evidence.md and reviewer-index.md do, so a project that hand-authored
        # one of those with a verdict row keeps it and receives .pending instead - permanently.
        #
        # That is deliberate rather than a gap: those files hold judgements, and overwriting a judgement
        # is not a migration, it is a deletion. What was wrong was that the .pending waited in silence,
        # and that is what the warning above fixes.
        $f = New-Fixture
        try {
            Invoke-Generator -IterationDirectory $f.Iteration
            $pending = @(Get-ChildItem -LiteralPath $f.Iteration -Filter '*.pending' -File | ForEach-Object { $_.Name })
            $pending | Should -Contain 'coverage-evidence.md.pending'
            # ...while a non-verdict-bearing artifact was still migrated in place.
            (Get-Content -LiteralPath (Join-Path $f.Iteration 'code-map.md') -Raw -Encoding UTF8) | Should -Not -Match 'HAND-AUTHORED'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

}
