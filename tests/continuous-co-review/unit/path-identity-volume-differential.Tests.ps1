$ErrorActionPreference = 'Stop'

# Trace: DRIFT-198-I009-032 / -033, and the maintainer's 2026-07-29 decision that review-and-fix
# rounds are no longer the certification instrument for this surface.
#
# THE ORACLE IS THE VOLUME.
#
# Six review rounds found path-identity defects while this repository's own focused suites stayed
# green. The sharpest case is commit `0e0048b0`: `path-identity.Tests.ps1` passed 39/39 - including a
# test written for DRIFT-198-I009-032's exact scenario - while the probe returned the OPPOSITE of the
# truth on a case-insensitive volume. Same-author tests cannot falsify the model that wrote them.
#
# So no expectation in this file is authored. Every one is MEASURED: create real entries on the
# filesystem the test is running on, enumerate what the OS actually did, and assert the primitive
# against that observation. Nothing is skipped for platform - where a volume cannot materialize a
# scenario, the fact that it could not IS the measurement, and the primitive is held to that instead.
# A run on a single volume proves one volume; the value comes from running this on all three CI
# volumes, where the same assertions have different measured right answers.

Describe 'path identity differential property harness (the volume is the oracle)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path

        # The primitive under test is normally the repository's own. SPECREW_PATH_IDENTITY_UNDER_TEST
        # lets the MUTATION GATE point this harness at a deliberately-broken primitive and require the
        # harness to fail - the permanent form of a check that was, on its first revision, only "I
        # verified this once by hand". See path-identity-mutation-gate.Tests.ps1.
        # Loaded FIRST on purpose: review-design-context.ps1 self-loads the primitive only when the
        # name is absent, so whichever copy is dot-sourced here wins for the whole run.
        $script:PrimitiveUnderTest = if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_PATH_IDENTITY_UNDER_TEST)) {
            $env:SPECREW_PATH_IDENTITY_UNDER_TEST
        }
        else {
            Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/path-identity.ps1'
        }
        . $script:PrimitiveUnderTest
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-design-context.ps1')

        $script:VolumeOracleFixtures = [System.Collections.Generic.List[string]]::new()

        function New-VolumeOracleFixtureRoot {
            $root = Join-Path ([IO.Path]::GetTempPath()) ('specrew-volume-oracle-' + [Guid]::NewGuid().ToString('N').Substring(0, 12))
            $null = New-Item -ItemType Directory -Path $root -Force
            $script:VolumeOracleFixtures.Add($root)
            return (Resolve-Path -LiteralPath $root).Path
        }

        function Get-ObservedEntryName {
            # What the OS actually holds, read back by enumeration. Enumeration returns true on-disk
            # spellings, so this is measurement rather than assumption - the distinction the whole file
            # rests on.
            param([Parameter(Mandatory)][string]$Directory)
            return @([IO.Directory]::GetFileSystemEntries($Directory) | ForEach-Object { [IO.Path]::GetFileName($_) })
        }

        function New-DirectoryIfVolumeAllows {
            # Some fixtures cannot exist on some volumes - that is data, not an error.
            param([Parameter(Mandatory)][string]$Path)
            try { $null = New-Item -ItemType Directory -Path $Path -Force; return $true }
            catch { return $false }
        }
    }

    AfterAll {
        foreach ($fixture in $script:VolumeOracleFixtures) {
            try { if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force } }
            catch { $null = $_ }
        }
    }

    # The reported DRIFT-198-I009-032 failure needs flip(asked spelling) to EQUAL the real on-disk
    # spelling, which only happens for an all-caps/all-lower pair. A mixed-case fixture such as
    # `Alpha`/`ALPHA` passes even against the broken probe - which is precisely how the authored suite
    # stayed green. Both orientations are covered so neither direction can hide.
    It 'agrees with the volume about a case-flipped lookup, under <RealName> asked as <AskedName>' -ForEach @(
        @{ RealName = 'REPO'; AskedName = 'repo' }
        @{ RealName = 'data'; AskedName = 'DATA' }
    ) {
        # A FRESH fixture root per probed spelling, deliberately. Sharing one root let the primitive's
        # own memo answer the second probe from the first probe's cache entry - and because that cache
        # was a case-FOLDING hashtable, the two spellings collided and the broken probe returned the
        # correct cached answer. The bug survived the test. Isolating each spelling means each probe is
        # measured cold, which is the only way this assertion can fail when the probe is wrong.
        foreach ($spelling in @($RealName, $AskedName)) {
            $root = New-VolumeOracleFixtureRoot
            $null = New-DirectoryIfVolumeAllows -Path (Join-Path $root $RealName)

            # MEASURE: what does this volume hold, and does the other spelling resolve?
            $listed = Get-ObservedEntryName -Directory $root
            $bothListed = ($listed -ccontains $RealName) -and ($listed -ccontains $AskedName)
            $askedResolves = [IO.Directory]::Exists((Join-Path $root $AskedName))
            $measuredSensitive = -not ($askedResolves -and -not $bothListed)

            $probePath = Join-Path $root $spelling
            if (-not [IO.Directory]::Exists($probePath)) { continue }
            $verdict = Get-ContinuousCoReviewPathCaseSensitive -Path $probePath
            $verdict | Should -Not -BeNullOrEmpty -Because 'an existing directory always yields a determination'
            $verdict | Should -Be $measuredSensitive -Because "this volume was MEASURED case-sensitive=$measuredSensitive (on-disk listing: [$([string]::Join(', ', @($listed)))]; '$AskedName' resolves=$askedResolves), and the spelling the caller happens to pass must never change the answer - asked here as '$spelling'"
        }
    }

    It 'matches the volume on whether two case-distinct siblings can coexist' {
        $root = New-VolumeOracleFixtureRoot
        $null = New-DirectoryIfVolumeAllows -Path (Join-Path $root 'Repo')
        $null = New-DirectoryIfVolumeAllows -Path (Join-Path $root 'REPO')

        $listed = Get-ObservedEntryName -Directory $root
        $bothListed = ($listed -ccontains 'Repo') -and ($listed -ccontains 'REPO')

        $verdict = Get-ContinuousCoReviewPathCaseSensitive -Path $root
        $verdict | Should -Not -BeNullOrEmpty
        $verdict | Should -Be $bothListed -Because "the volume was MEASURED holding [$([string]::Join(', ', @($listed)))]; two distinct spellings coexisting is something only a case-preserving volume can do, and one collapsed entry proves it folds"
    }

    It 'agrees with the volume about whether a case-aliased root is the SAME directory' {
        # This is the DRIFT-198-I009-015 containment bypass measured rather than argued: if the volume
        # resolves the aliased spelling to the very same directory, containment reporting OUTSIDE lets a
        # caller-supplied external root sit physically inside the origin.
        $root = New-VolumeOracleFixtureRoot
        $realPath = Join-Path $root 'TARGET'
        $null = New-DirectoryIfVolumeAllows -Path $realPath
        $aliasedPath = Join-Path $root 'target'

        $listed = Get-ObservedEntryName -Directory $root
        $bothListed = ($listed -ccontains 'TARGET') -and ($listed -ccontains 'target')
        $aliasExists = [IO.Directory]::Exists($aliasedPath)
        $aliasIsSameDirectory = ($aliasExists -and -not $bothListed)

        $under = Test-ContinuousCoReviewPathUnderRoot -Path $aliasedPath -Root $realPath
        $under | Should -Be $aliasIsSameDirectory -Because "the volume was MEASURED with listing [$([string]::Join(', ', @($listed)))] and alias-resolves=$aliasExists, so the aliased spelling names the SAME directory=$aliasIsSameDirectory; containment must answer what the filesystem does, not what the OS family suggests"
    }

    It 'never drops a path the volume keeps apart (composed vs decomposed Unicode)' {
        # DRIFT-198-I009-033. `Sort-Object -Unique -CaseSensitive` flips only the case flag; the
        # comparison stays CULTURE-aware, and these two spellings are culture-equivalent while being
        # byte-distinct. Git and macOS both produce them.
        $root = New-VolumeOracleFixtureRoot
        $composed = 'caf' + [char]0x00E9              # cafe with a precomposed acute
        $decomposed = 'cafe' + [char]0x0301           # cafe + combining acute
        $null = New-DirectoryIfVolumeAllows -Path (Join-Path $root $composed)
        $null = New-DirectoryIfVolumeAllows -Path (Join-Path $root $decomposed)

        # MEASURE how many distinct entries this volume actually holds.
        $listed = Get-ObservedEntryName -Directory $root
        $observed = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($name in $listed) { $null = $observed.Add($name) }

        $deduped = @(Get-ContinuousCoReviewOrdinalUniquePath -Path @($composed, $decomposed))

        # THE PROPERTY: dedup may never retain fewer paths than the volume distinguishes. Over-retention
        # is safe - where the volume folds, both spellings select the same file. Under-retention silently
        # removes a path from the comparison, and a path never compared can be modified undetected.
        $deduped.Count | Should -BeGreaterOrEqual $observed.Count -Because "the volume was MEASURED holding $($observed.Count) distinct entr(y/ies); retaining fewer drops a real path and integrity can then report intact for a modified file"

        # And on a volume that distinguishes them, prove the replaced spelling actually under-retains -
        # otherwise this test could pass on a normalising volume without ever exercising the defect.
        $cultureAware = @(@($composed, $decomposed) | Sort-Object -Unique -CaseSensitive)
        if ($observed.Count -gt $cultureAware.Count) {
            $deduped.Count | Should -BeGreaterThan $cultureAware.Count -Because "this volume keeps $($observed.Count) spellings apart while the culture-aware dedup collapsed them to $($cultureAware.Count) - the exact DRIFT-198-I009-033 defect, measured on this runner"
        }
    }

    It 'gives every path-identity consumer the same verdict the volume gives' {
        # The primitive is now a single point of total failure: every call site routes through it, so one
        # wrong answer is wrong everywhere at once. Pin the derived helpers to the same measurement.
        $root = New-VolumeOracleFixtureRoot
        $null = New-DirectoryIfVolumeAllows -Path (Join-Path $root 'CASE')
        $listed = Get-ObservedEntryName -Directory $root
        $bothListed = ($listed -ccontains 'CASE') -and ($listed -ccontains 'case')
        $foldedLookupResolves = [IO.Directory]::Exists((Join-Path $root 'case'))
        $measuredSensitive = -not ($foldedLookupResolves -and -not $bothListed)

        $comparison = Get-ContinuousCoReviewPathComparison -Path $root -WhenUndetermined 'distinct'
        $comparer = Get-ContinuousCoReviewPathComparer -Path $root -WhenUndetermined 'distinct'

        $expectedComparison = if ($measuredSensitive) { [System.StringComparison]::Ordinal } else { [System.StringComparison]::OrdinalIgnoreCase }
        $comparison | Should -Be $expectedComparison -Because "the comparison must follow the MEASURED volume rule (case-sensitive=$measuredSensitive)"
        $comparer.Equals('CASE', 'case') | Should -Be (-not $measuredSensitive) -Because 'the comparer and the comparison cannot disagree about the same volume'
    }
}
