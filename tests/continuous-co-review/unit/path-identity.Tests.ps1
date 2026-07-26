$ErrorActionPreference = 'Stop'

# Trace: DRIFT-198-I009-015/016/017. The ONE path-identity primitive. Case sensitivity is a VOLUME
# property, not an OS-family one, and there is no single safe default when it cannot be determined -
# containment must refuse an aliased path while machinery stripping must keep real source.
Describe 'path identity primitive' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/path-identity.ps1')
    }

    It 'derives case sensitivity from the volume and matches what the filesystem actually does' {
        $sensitive = Get-ContinuousCoReviewPathCaseSensitive -Path $script:RepoRoot
        $sensitive | Should -Not -BeNullOrEmpty -Because 'an existing directory always yields a determination'

        # Ground the answer against observed behaviour rather than a platform assumption.
        $probe = Join-Path $TestDrive 'volume-truth'
        New-Item -ItemType Directory -Path (Join-Path $probe 'Alpha') -Force | Out-Null
        $foldsCase = Test-Path -LiteralPath (Join-Path $probe 'alpha')
        (Get-ContinuousCoReviewPathCaseSensitive -Path (Join-Path $probe 'Alpha')) | Should -Be (-not $foldsCase)
    }

    It 'does NOT decide case semantics from the OS family, and spawns no subprocess' {
        # The defect: `IsWindows ? IgnoreCase : Ordinal` mis-answers on a case-insensitive macOS
        # volume in both directions. The primitive must measure the volume instead - and must do it
        # WITHOUT a subprocess: a `git config` probe reached from the digest's per-path loop hung the
        # Linux CI review suite silently, killing the process with no failing assertion.
        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/path-identity.ps1') -Raw
        $source | Should -Not -Match 'IsWindows\(\)\) \{ \[StringComparison\]::OrdinalIgnoreCase \}'
        $source | Should -Not -Match '&\s*git' -Because 'the probe must never fork a process on a hot path'
        $source | Should -Not -Match 'Start-Process|Invoke-Expression'
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
