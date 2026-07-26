$ErrorActionPreference = 'Stop'

# Trace: DRIFT-198-I009-015/016/017. The ONE path-identity primitive. Case sensitivity is a VOLUME
# property, not an OS-family one, and there is no single safe default when it cannot be determined -
# containment must refuse an aliased path while machinery stripping must keep real source.
Describe 'path identity primitive' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/path-identity.ps1')
    }

    It 'derives case sensitivity from the volume and agrees with git core.ignorecase' {
        $sensitive = Get-ContinuousCoReviewPathCaseSensitive -Path $script:RepoRoot
        $sensitive | Should -Not -BeNullOrEmpty -Because 'a Git worktree always yields a determination'

        $ignoreCase = (& git -C $script:RepoRoot config --get core.ignorecase 2>$null | Select-Object -First 1)
        if (-not [string]::IsNullOrWhiteSpace([string]$ignoreCase)) {
            $expected = -not ([string]$ignoreCase).Trim().Equals('true', [StringComparison]::OrdinalIgnoreCase)
            $sensitive | Should -Be $expected -Because 'git already probed this volume at init'
        }
    }

    It 'does NOT decide case semantics from the OS family' {
        # The defect: `IsWindows ? IgnoreCase : Ordinal` mis-answers on a case-insensitive macOS
        # volume in both directions. The primitive must consult the volume instead.
        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/path-identity.ps1') -Raw
        $source | Should -Not -Match 'IsWindows\(\)\) \{ \[StringComparison\]::OrdinalIgnoreCase \}'
        $source | Should -Match 'core\.ignorecase'
    }

    It 'walks up to the nearest existing directory so a not-yet-created path still resolves' {
        # The external target root does not exist yet when containment is checked, and its VOLUME is
        # what matters - so an absent leaf must not degrade to undetermined.
        $absent = Join-Path $script:RepoRoot ('no-such-child-' + [guid]::NewGuid().ToString('N'))
        (Get-ContinuousCoReviewPathCaseSensitive -Path $absent) |
            Should -Be (Get-ContinuousCoReviewPathCaseSensitive -Path $script:RepoRoot)
    }

    It 'resolves an undetermined volume to the direction each caller declares is safe' {
        $containment = Get-ContinuousCoReviewPathComparison -Path '' -WhenUndetermined 'same'
        $stripping = Get-ContinuousCoReviewPathComparison -Path '' -WhenUndetermined 'distinct'

        (Get-ContinuousCoReviewPathCaseSensitive -Path '') | Should -BeNullOrEmpty
        $containment | Should -Be ([StringComparison]::OrdinalIgnoreCase) -Because 'containment must refuse an aliased path, not admit it'
        $stripping | Should -Be ([StringComparison]::Ordinal) -Because 'stripping must never remove a case-distinct reviewable path'
    }

    It 'requires the caller to state its safe direction' {
        # An implicit default is silently unsafe for one of the two consumers.
        $parameterAttribute = (Get-Command Get-ContinuousCoReviewPathComparison).Parameters['WhenUndetermined'].Attributes |
            Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | Select-Object -First 1
        $parameterAttribute.Mandatory | Should -BeTrue
    }

    It 'yields a matching equality comparer' {
        $comparer = Get-ContinuousCoReviewPathComparer -Path $script:RepoRoot -WhenUndetermined 'distinct'
        $comparison = Get-ContinuousCoReviewPathComparison -Path $script:RepoRoot -WhenUndetermined 'distinct'
        $expected = if ($comparison -eq [StringComparison]::OrdinalIgnoreCase) { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal }
        $comparer | Should -Be $expected
    }

    It 'escapes literal identities as git literal pathspecs' {
        (ConvertTo-ContinuousCoReviewLiteralPathspec -Path 'generated[1]/tool.ps1') | Should -Be ':(literal)generated[1]/tool.ps1'
        (ConvertTo-ContinuousCoReviewLiteralPathspec -Path 'a\b') | Should -Be ':(literal)a/b'
    }

    It 'never writes while probing, so an OS-protected reviewer target stays byte-identical' {
        $probe = Join-Path $TestDrive 'readonly-probe'
        New-Item -ItemType Directory -Path $probe -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $probe 'Alpha.txt') -Value 'x' -Encoding UTF8
        $before = @(Get-ChildItem -LiteralPath $probe -Force | ForEach-Object { $_.Name }) | Sort-Object

        $null = Get-ContinuousCoReviewPathCaseSensitive -Path $probe

        $after = @(Get-ChildItem -LiteralPath $probe -Force | ForEach-Object { $_.Name }) | Sort-Object
        $after | Should -Be $before
    }
}
