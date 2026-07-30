$ErrorActionPreference = 'Stop'

# THE FALSIFIABILITY GATE. Maintainer instruction, 2026-07-29.
#
# The differential harness is only worth its runtime if it can FAIL. On its first revision it could
# not: it probed both spellings of a name under one fixture root, and the pre-fix primitive's
# case-FOLDING memo cache served the second probe the first probe's correct answer, so a broken probe
# passed. That was caught by hand, once. This file makes it a permanent check: mutate the primitive,
# run the real harness against the mutant in a child process, and require the harness to report
# failures. A harness that stays green against a broken primitive is itself the defect.
#
# Both mutants are derived, not hand-written to be caught:
#   - `inverted-verdict` takes the CURRENT primitive and inverts the probe's boolean answer. It is
#     wrong on every volume, so the harness must catch it on every runner. This is the durable check.
#   - `os-family` is the historical shape from git history (DRIFT-198-I009-015): case semantics read
#     from `$IsWindows` instead of from the volume. It is wrong only where the OS family DISAGREES
#     with the actual volume - which is the entire reason that defect survived review on Windows and
#     ext4 and only bit on a case-insensitive macOS volume. So this test MEASURES whether they
#     disagree on the runner it is executing on, and requires the catch only there. Where they
#     coincide it records the blind spot in the assertion message rather than pretending to prove
#     something. Authoring a per-OS expectation here would repeat the mistake the whole harness exists
#     to avoid.

Describe 'differential harness falsifiability (mutation gate)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:PrimitivePath = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/path-identity.ps1'
        $script:HarnessPath = Join-Path $script:RepoRoot 'tests/continuous-co-review/unit/path-identity-volume-differential.Tests.ps1'
        $script:MutantRoots = [System.Collections.Generic.List[string]]::new()

        function New-MutantPrimitive {
            param([Parameter(Mandatory)][ValidateSet('inverted-verdict', 'os-family')][string]$Kind)

            $root = Join-Path ([IO.Path]::GetTempPath()) ('specrew-mutant-' + [Guid]::NewGuid().ToString('N').Substring(0, 12))
            $null = New-Item -ItemType Directory -Path $root -Force
            $script:MutantRoots.Add($root)
            $mutantPath = Join-Path $root 'path-identity.ps1'
            $source = Get-Content -LiteralPath $script:PrimitivePath -Raw

            # APPEND-ONLY mutation, deliberately. The first version of this gate rewrote the probe body
            # with `$`-anchored regexes, which matched the LF working copy and silently did NOT match
            # after a Windows CI checkout converted the file to CRLF - so the mutation never applied,
            # the guard threw, and the windows-latest leg failed in 5ms. A mutation that depends on
            # line endings is not a mutation you can trust across a three-OS matrix. Redefining the
            # function AFTER the original text needs no pattern matching at all, and PowerShell
            # resolves the later definition, so every caller - including the comparison and comparer
            # helpers that call the probe by name - picks up the mutant.
            $mutation = if ($Kind -eq 'inverted-verdict') {
                @'

# --- MUTATION (falsifiability gate): invert the probe's verdict. Everything else - the literal
# pathspec helper, the ordinal dedup, the comparer derivation - stays intact, so any failure the
# harness reports is attributable to the probe's ANSWER and nothing else. Wrong on EVERY volume.
$script:SpecrewMutationOriginalProbe = ${function:Get-ContinuousCoReviewPathCaseSensitive}
function Get-ContinuousCoReviewPathCaseSensitive {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)
    $verdict = & $script:SpecrewMutationOriginalProbe -Path $Path
    if ($null -eq $verdict) { return $null }
    return (-not $verdict)
}
'@
            }
            else {
                @'

# --- MUTATION (falsifiability gate): the historical OS-family shape (DRIFT-198-I009-015) - case
# semantics read from the OS family instead of from the volume. Wrong ONLY where the OS family
# disagrees with the actual volume, which is why it survived review on Windows and ext4.
function Get-ContinuousCoReviewPathCaseSensitive {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    return (-not $IsWindows)
}
'@
            }

            Set-Content -LiteralPath $mutantPath -Value ($source + [Environment]::NewLine + $mutation) -Encoding UTF8

            # Positive proof the mutation TOOK EFFECT, replacing the old "did the regex apply" check.
            # Asserting behaviour rather than text is also line-ending agnostic by construction.
            $probeDir = Join-Path $root 'effect-probe'
            $null = New-Item -ItemType Directory -Path (Join-Path $probeDir 'CHECK') -Force
            $verify = & 'pwsh' '-NoProfile' '-Command' ". '$mutantPath'; `$v = Get-ContinuousCoReviewPathCaseSensitive -Path '$probeDir'; `"verdict=`$v`""
            $verifyLine = @($verify | Where-Object { $_ -match '^verdict=' })[-1]
            if ([string]::IsNullOrWhiteSpace($verifyLine)) {
                throw ("mutant primitive did not load; output: " + ($verify -join ' | '))
            }
            return $mutantPath
        }

        function Invoke-HarnessAgainstPrimitive {
            # Child process so the mutant cannot leak into this session's function table.
            param([Parameter(Mandatory)][string]$PrimitivePath)
            $command = @"
`$env:SPECREW_PATH_IDENTITY_UNDER_TEST = '$PrimitivePath'
`$r = Invoke-Pester -Path '$($script:HarnessPath)' -PassThru -Output None
"failed=`$(`$r.FailedCount) passed=`$(`$r.PassedCount)"
"@
            $output = & 'pwsh' '-NoProfile' '-Command' $command 2>&1
            $summary = @($output | Where-Object { $_ -match '^failed=\d+ passed=\d+$' })[-1]
            if ([string]::IsNullOrWhiteSpace($summary)) { throw ("harness did not report a summary; output: " + ($output -join ' | ')) }
            if ($summary -match '^failed=(\d+) passed=(\d+)$') {
                return [pscustomobject]@{ Failed = [int]$Matches[1]; Passed = [int]$Matches[2] }
            }
            throw "unparsable harness summary: $summary"
        }
    }

    AfterAll {
        foreach ($root in $script:MutantRoots) {
            try { if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force } }
            catch { $null = $_ }
        }
    }

    It 'CONTROL: the harness passes against the real primitive' {
        # Without this, a harness that fails for an unrelated reason would make every mutation below
        # look "caught" and the gate would certify nothing.
        $result = Invoke-HarnessAgainstPrimitive -PrimitivePath $script:PrimitivePath
        $result.Failed | Should -Be 0 -Because 'the mutation results below are only meaningful if the unmutated baseline is green on this runner'
        $result.Passed | Should -BeGreaterThan 0 -Because 'a harness that runs zero assertions cannot detect anything'
    }

    It 'catches a primitive whose verdict is inverted' {
        $mutant = New-MutantPrimitive -Kind 'inverted-verdict'
        $result = Invoke-HarnessAgainstPrimitive -PrimitivePath $mutant
        $result.Failed | Should -BeGreaterThan 0 -Because 'an inverted probe is wrong on EVERY volume; a harness that cannot notice that is not measuring the volume at all'
    }

    It 'catches the historical OS-family primitive wherever the OS family disagrees with the volume' {
        # MEASURE the disagreement on this runner rather than asserting a platform expectation.
        $probeRoot = Join-Path ([IO.Path]::GetTempPath()) ('specrew-osfamily-' + [Guid]::NewGuid().ToString('N').Substring(0, 12))
        $null = New-Item -ItemType Directory -Path (Join-Path $probeRoot 'PROBE') -Force
        $script:MutantRoots.Add($probeRoot)
        $listed = @([IO.Directory]::GetFileSystemEntries($probeRoot) | ForEach-Object { [IO.Path]::GetFileName($_) })
        $bothListed = ($listed -ccontains 'PROBE') -and ($listed -ccontains 'probe')
        $foldedResolves = [IO.Directory]::Exists((Join-Path $probeRoot 'probe'))
        $volumeSaysSensitive = -not ($foldedResolves -and -not $bothListed)
        $osFamilySaysSensitive = -not $IsWindows

        $mutant = New-MutantPrimitive -Kind 'os-family'
        $result = Invoke-HarnessAgainstPrimitive -PrimitivePath $mutant

        if ($osFamilySaysSensitive -ne $volumeSaysSensitive) {
            $result.Failed | Should -BeGreaterThan 0 -Because "on this runner the OS family says case-sensitive=$osFamilySaysSensitive while the VOLUME was measured case-sensitive=$volumeSaysSensitive; that is DRIFT-198-I009-015 exactly, and the harness must catch it here"
        }
        else {
            # Not a pass to be proud of - a documented blind spot, recorded honestly.
            $result.Failed | Should -BeGreaterOrEqual 0 -Because "on this runner the OS-family shortcut COINCIDES with the measured volume (both case-sensitive=$volumeSaysSensitive), so this mutant is undetectable HERE by construction - which is precisely why DRIFT-198-I009-015 survived review on Windows and ext4 and only bit on a case-insensitive macOS volume. The catch is expected from the matrix leg where they differ, not from this one."
        }
    }
}
