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

    It 'STRUCTURAL: exactly one definition of each path-identity function exists in the tree' {
        # THE defect that regenerated this class for five review rounds. A SECOND
        # `Get-ContinuousCoReviewPathComparison` lived in verification-plan-contract.ps1, took no
        # parameters, and keyed off `$IsWindows`. `_load.ps1` loads that file AFTER path-identity.ps1,
        # so the duplicate SHADOWED the real primitive for every consumer in a loaded context - and
        # because it declared no `param()` block, PowerShell silently swallowed the -Path and
        # -WhenUndetermined arguments its callers passed rather than failing. Every call site that
        # had been "routed through the primitive" was still getting the OS-family answer. A shadow is
        # invisible at every individual call site, which is exactly why point fixes never converged.
        # NOTE ON METHOD (accepted residual, maintainer decision 2026-07-28): these three structural
        # tests are GREP-based, not AST-based. They catch the exact spellings that produced the nine
        # path-identity defects in this iteration, and they would have caught the shadowing duplicate
        # that five review rounds missed. They would NOT catch a sufficiently different spelling -
        # a definition built via `Set-Item function:`, a comparer selected through a variable, or a
        # dedup written with Group-Object. Accepted as a residual rather than hardened further; an
        # AST-based check is the durable form if this class ever recurs.
        $sourceRoot = Join-Path $script:RepoRoot 'scripts'
        $names = @(
            'Get-ContinuousCoReviewPathCaseSensitive'
            'Get-ContinuousCoReviewPathComparison'
            'Get-ContinuousCoReviewPathComparer'
            'ConvertTo-ContinuousCoReviewLiteralPathspec'
            'Get-ContinuousCoReviewCaseFlippedName'
        )
        $files = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Filter '*.ps1') +
            @(Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot '.specify/extensions') -Recurse -File -Filter '*.ps1' -ErrorAction SilentlyContinue) +
            @(Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'extensions') -Recurse -File -Filter '*.ps1' -ErrorAction SilentlyContinue)
        foreach ($name in $names) {
            $definers = @($files | Where-Object {
                    (Get-Content -LiteralPath $_.FullName -Raw) -match ('(?m)^\s*function\s+' + [regex]::Escape($name) + '\s*\{')
                })
            @($definers).Count | Should -Be 1 -Because "'$name' must have exactly ONE definition; a same-named duplicate silently shadows the primitive (found: $(@($definers | ForEach-Object { $_.Name }) -join ', '))"
        }
    }

    It 'STRUCTURAL: no path comparison decides case from the OS family outside the primitive' {
        # The convergence assessment's item (a). An `IsWindows`-keyed comparer is wrong on a
        # case-insensitive macOS volume in BOTH directions, and every one of these that survives is a
        # site the primitive does not actually govern. path-identity.ps1 is the ONLY file permitted to
        # decide case semantics, and it decides them from the volume.
        # BOTH trees. `.specify/extensions` is deployed into consumer projects and cannot reach the
        # primitive, so a guard there must pick the FAIL-CLOSED direction unconditionally and state
        # why - never branch on the OS family, which is the same defect wearing a different coat.
        $sourceRoots = @(
            # `scripts/internal` WHOLE, not just the continuous-co-review subtree. Scanning the subtree
            # is how two defects hid at once (DRIFT-198-I009-037): a SEVENTH OS-family case shortcut sat
            # in `review-engine-resolution.ps1`, gating a delete-authorizing containment check, and
            # `specrew-hook-dispatcher.ps1` needed a not-a-path annotation that could only be added to
            # the `extensions/` MIRROR this scan could see - diverging the mirror from its own
            # authoritative source and breaking provider parity. Scan where the source of truth lives.
            (Join-Path $script:RepoRoot 'scripts/internal')
            (Join-Path $script:RepoRoot '.specify/extensions')
            # The CANONICAL packaged source. `.specify/extensions` is a deployed MIRROR of it, and a
            # correction applied only to the mirror never reaches a consumer: `specrew init` and
            # `specrew update` ship from here (co-review finding, run run-f198-i009-2c6d7cb8-sweep).
            (Join-Path $script:RepoRoot 'extensions')
        )
        $offenders = [Collections.Generic.List[string]]::new()
        foreach ($file in @($sourceRoots | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object { Get-ChildItem -LiteralPath $_ -Recurse -File -Filter '*.ps1' })) {
            if ($file.Name -ceq 'path-identity.ps1') { continue }
            $lineNumber = 0
            foreach ($line in @(Get-Content -LiteralPath $file.FullName)) {
                $lineNumber++
                if ($line -match '^\s*#') { continue }
                # An OS test used to PICK a string comparison/comparer on the same line.
                if ($line -match '(IsWindows)' -and $line -match 'StringComparison\]::|StringComparer\]::') {
                    $offenders.Add("$($file.Name):$lineNumber") | Out-Null
                }
            }
        }
        @($offenders).Count | Should -Be 0 -Because "case semantics come from the volume via the primitive, never from the OS family (offenders: $($offenders -join ', '))"
    }

    It 'STRUCTURAL: path collections are never deduplicated with a case-folding default' {
        # The convergence assessment's item (a) again, in its dedup form. `Sort-Object -Unique` folds
        # case by default, which silently discarded one of two case-distinct machinery directories
        # (DRIFT-198-I009-016) and one of two case-distinct operator exclusions (DRIFT-198-I009-023).
        # Every such call over paths must state its case rule explicitly.
        $sourceRoots = @(
            # `scripts/internal` WHOLE, not just the continuous-co-review subtree. Scanning the subtree
            # is how two defects hid at once (DRIFT-198-I009-037): a SEVENTH OS-family case shortcut sat
            # in `review-engine-resolution.ps1`, gating a delete-authorizing containment check, and
            # `specrew-hook-dispatcher.ps1` needed a not-a-path annotation that could only be added to
            # the `extensions/` MIRROR this scan could see - diverging the mirror from its own
            # authoritative source and breaking provider parity. Scan where the source of truth lives.
            (Join-Path $script:RepoRoot 'scripts/internal')
            (Join-Path $script:RepoRoot '.specify/extensions')
            # The CANONICAL packaged source. `.specify/extensions` is a deployed MIRROR of it, and a
            # correction applied only to the mirror never reaches a consumer: `specrew init` and
            # `specrew update` ship from here (co-review finding, run run-f198-i009-2c6d7cb8-sweep).
            (Join-Path $script:RepoRoot 'extensions')
        )
        $offenders = [Collections.Generic.List[string]]::new()
        foreach ($file in @($sourceRoots | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object { Get-ChildItem -LiteralPath $_ -Recurse -File -Filter '*.ps1' })) {
            $lineNumber = 0
            foreach ($line in @(Get-Content -LiteralPath $file.FullName)) {
                $lineNumber++
                if ($line -match '^\s*#') { continue }
                if ($line -match 'Sort-Object\s+-Unique') {
                    # A dedup over something that is NOT a path (version strings, attempt counts,
                    # supplier identity tokens) is exempt, but only when it SAYS SO on the line. The
                    # marker is deliberately explicit: an unannotated dedup is treated as a path.
                    if ($line -match 'specrew-dedup-not-a-path') { continue }
                    # `-CaseSensitive` USED TO SATISFY THIS TEST, and that is why DRIFT-198-I009-033
                    # shipped: the switch flips only the case flag and leaves the comparison
                    # CULTURE-aware, so composed and decomposed Unicode spellings - which Git and
                    # macOS both produce, and which the Ordinal maps upstream deliberately keep apart -
                    # collapsed anyway, and the dropped path was never compared again. There is no
                    # correct Sort-Object spelling for a path collection; route it through
                    # Get-ContinuousCoReviewOrdinalUniquePath, which is Ordinal in both dedup and order.
                    $offenders.Add("$($file.Name):$lineNumber") | Out-Null
                }
            }
        }
        @($offenders).Count | Should -Be 0 -Because "a path dedup must state its case rule; the default folds case (offenders: $($offenders -join ', '))"
    }

    It 'STRUCTURAL: a containment guard present in the deployed mirror also exists in the canonical source' {
        # The miss this test exists to prevent. The extensions sweep was applied to
        # `.specify/extensions`, which is a deployed MIRROR. `specrew init` and `specrew update` ship
        # from `extensions/`, the canonical packaged source, so the corrected containment guard never
        # reached a consumer and the shipped helper still wrote through project-controlled links
        # (co-review finding, run run-f198-i009-2c6d7cb8-sweep).
        #
        # The two trees are LEGITIMATELY divergent - the mirror is a stripped variant - so this is
        # deliberately NOT a byte-parity check, which would fail for correct reasons. It asserts only
        # that a NAMED SAFETY GUARD present in one is present in the other.
        $guards = @('Assert-ManagedTargetContained', 'Assert-ManagedMutationAllowed')
        foreach ($guard in $guards) {
            $canonical = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1'
            $mirror = Join-Path $script:RepoRoot '.specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1'
            foreach ($file in @($canonical, $mirror)) {
                if (-not (Test-Path -LiteralPath $file)) { continue }
                (Get-Content -LiteralPath $file -Raw) | Should -Match ([regex]::Escape($guard)) `
                    -Because "the '$guard' containment guard must exist in BOTH the canonical source and the deployed mirror; a mirror-only fix never ships to a consumer ($file)"
            }
        }
    }

    It 'STRUCTURAL: every deployment mutator traverses the containment choke point, in BOTH trees' {
        # DRIFT-198-I009-031, and the third appearance of this containment class after -011 (deletion)
        # and -025 (the Set-ManagedFile write). Each of those corrections guarded the ONE door the
        # reviewer had reached, and the guard ended up called from exactly one of five mutators - so
        # directory creation, team/routing/history writes, and a RECURSIVE host-skill delete all still
        # ran unchecked, and a consumer-controlled ancestor junction could redirect them outside the
        # project. Enumerating mutators is the check that a per-site fix cannot pass.
        $mutators = @('Ensure-Directory', 'Write-MissingFile', 'Set-ManagedFile', 'Set-ManagedBlock', 'Set-ManagedTableRows')
        $deployScripts = @(
            (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1')
            (Join-Path $script:RepoRoot '.specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1')
        )
        $ungated = [Collections.Generic.List[string]]::new()

        foreach ($deployScript in @($deployScripts | Where-Object { Test-Path -LiteralPath $_ })) {
            $lines = @(Get-Content -LiteralPath $deployScript)
            $treeLabel = if ($deployScript -match '\.specify') { 'mirror' } else { 'canonical' }

            foreach ($mutator in $mutators) {
                $start = -1
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match ('^function\s+' + [regex]::Escape($mutator) + '\s*\{')) { $start = $i; break }
                }
                if ($start -lt 0) { continue }
                # Body runs to the next top-level function declaration.
                $end = $lines.Count - 1
                for ($j = $start + 1; $j -lt $lines.Count; $j++) {
                    if ($lines[$j] -match '^function\s+') { $end = $j - 1; break }
                }
                $body = [string]::Join("`n", $lines[$start..$end])
                if ($body -notmatch 'Assert-ManagedMutationAllowed') {
                    $ungated.Add("$treeLabel/$mutator") | Out-Null
                }
            }

            # A recursive delete is the highest-consequence mutation in the script: require the gate
            # within the few lines above it, not merely somewhere in the file.
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match 'Remove-Item\s+-LiteralPath.*-Recurse') {
                    $windowStart = [Math]::Max(0, $i - 5)
                    $window = [string]::Join("`n", $lines[$windowStart..$i])
                    if ($window -notmatch 'Assert-ManagedMutationAllowed') {
                        $ungated.Add("$treeLabel/recursive-delete:line$($i + 1)") | Out-Null
                    }
                }
            }
        }

        @($ungated).Count | Should -Be 0 -Because "every mutator and every recursive delete must pass the containment choke point in BOTH the canonical source and the deployed mirror (ungated: $($ungated -join ', '))"
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
