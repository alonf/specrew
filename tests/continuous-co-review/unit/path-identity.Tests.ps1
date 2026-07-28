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

    It 'reads two case-distinct siblings as a case-SENSITIVE volume, not an aliased one' {
        # The defect: the probe declared a volume case-INSENSITIVE whenever the case-flipped name
        # resolved. A case-sensitive volume may legitimately hold BOTH `Repo` and `REPO` as distinct
        # directories, so that test returned exactly the wrong comparer and every downstream identity
        # then folded genuinely distinct paths (co-review finding, run run-f198-i009-aab37c3b-codex-2).
        # Existence alone cannot answer it; the directory LISTING can.
        $parent = Join-Path $TestDrive 'case-distinct-siblings'
        New-Item -ItemType Directory -Path (Join-Path $parent 'Repo') -Force | Out-Null
        if (Test-Path -LiteralPath (Join-Path $parent 'REPO')) {
            Set-ItResult -Skipped -Because 'this volume folds case; the two-sibling collision cannot be materialized here'
            return
        }
        New-Item -ItemType Directory -Path (Join-Path $parent 'REPO') -Force | Out-Null

        (Get-ContinuousCoReviewPathCaseSensitive -Path (Join-Path $parent 'Repo')) |
            Should -BeTrue -Because 'two distinct directories differing only by case PROVE the volume preserves case'
        (Get-ContinuousCoReviewPathComparison -Path (Join-Path $parent 'Repo') -WhenUndetermined 'same') |
            Should -Be ([StringComparison]::Ordinal)
    }

    It 'is reachable from a consumer loaded WITHOUT the shared loader (DRIFT-198-I009-018)' {
        # The regression: `_load.ps1` loads this primitive first, but consumers are also dot-sourced
        # DIRECTLY - worktree-reviewer.ps1, the campaign orchestrator, and several suites all take
        # that door. Through it the primitive was absent, every call site took its silent fallback,
        # and containment compared with a case rule the volume never chose. It answered wrongly on
        # Linux only (Windows and macOS volumes fold case, so the wrong rule matched the right one),
        # which is why one CI runner failed and the other two stayed green.
        $pwshPath = (Get-Process -Id $PID).Path
        $consumers = @(
            'review-design-context.ps1'
            'worktree-reviewer.ps1'
            'reviewed-state-digest.ps1'
            'review-authority-store.ps1'
            'review-target-port.ps1'
            'verification-plan-runner.ps1'
        )
        foreach ($consumer in $consumers) {
            $consumerPath = Join-Path $script:RepoRoot "scripts/internal/continuous-co-review/$consumer"
            # A CHILD process: only the consumer is loaded, so nothing another suite already
            # dot-sourced into this session can mask an absent dependency.
            $probe = ". '$consumerPath'; if (Get-Command -Name 'Get-ContinuousCoReviewPathComparison' -ErrorAction SilentlyContinue) { 'REACHABLE' } else { 'MISSING' }"
            $observed = (& $pwshPath -NoProfile -NonInteractive -Command $probe 2>&1 | Select-Object -Last 1)
            "$observed" | Should -Be 'REACHABLE' -Because "$consumer compares paths and must load the primitive into its OWN scope"
        }
    }

    It 'lets no consumer fall back to a case rule the volume did not choose (DRIFT-198-I009-018)' {
        # The durable guard. A `Get-Command`-guarded call that silently substitutes a DIFFERENT
        # comparison when the primitive is missing is the same defect as an `$IsWindows` shortcut:
        # it answers, it answers wrongly, and nothing reports it. Consumers must call the primitive
        # unconditionally and load it at file scope instead.
        $sourceRoot = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review'
        $consumers = @(Get-ChildItem -LiteralPath $sourceRoot -Filter '*.ps1' -File |
                Where-Object { $_.Name -ne 'path-identity.ps1' } |
                Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match 'Get-ContinuousCoReviewPathCompar(ison|er)\s+-Path' })
        @($consumers).Count | Should -BeGreaterThan 0 -Because 'the primitive must have real consumers for this guard to mean anything'

        foreach ($consumer in $consumers) {
            $source = Get-Content -LiteralPath $consumer.FullName -Raw
            # The load guard wraps a DOT-SOURCE; the banned fallback wraps a CALL.
            $source | Should -Not -Match "(?s)Get-Command -Name 'Get-ContinuousCoReviewPathCompar(ison|er)'.{0,120}?\{\s*[\r\n]*\s*Get-ContinuousCoReviewPathCompar" `
                -Because "$($consumer.Name) must call the primitive directly, never guard it with a substitute comparison"
            $source | Should -Match "\.\s*\(Join-Path \`$PSScriptRoot 'path-identity\.ps1'\)" `
                -Because "$($consumer.Name) must load the primitive into its own scope"
        }
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
