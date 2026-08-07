$ErrorActionPreference = 'Stop'

# T081. The permanent form of the falsifiability proof done once by hand during T082
# (DRIFT-198-I009-041): a git-checkout A/B against the pre-fix file showed 3 of 15 fixtures failing.
# That was a one-time manual check, not a durable gate. This file makes it permanent: mutate
# Get-ReviewAuthorityStorePath back to LEXICAL-ONLY containment (the pre-fix shape - no reparse-point
# walk at the root or at any ancestor), run the REAL T082 link fixtures against the mutant in a child
# process, and require them to fail. Same shape as path-identity-mutation-gate.Tests.ps1 - a fixture
# set is only worth its runtime if it can fail, and this proves it stays able to on every future edit.

Describe 'review-authority-store link-containment falsifiability (mutation gate, T081)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:StorePath = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-store.ps1'
        $script:CorePath = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1'
        $script:PathIdentityPath = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/path-identity.ps1'
        $script:FixturePath = Join-Path $script:RepoRoot 'tests/continuous-co-review/unit/review-authority-store.Tests.ps1'
        $script:MutantRoots = [System.Collections.Generic.List[string]]::new()

        function New-LinkBlindStoreMutant {
            # Reverts Get-ReviewAuthorityStorePath to the PRE-T082 shape: lexical prefix comparison
            # only, no reparse-point check at the root and no per-component ancestor walk. Derived
            # from the current (fixed) file by removing exactly the block T082 added, rather than
            # hand-written to be caught - the same discipline path-identity-mutation-gate.Tests.ps1 uses.
            $root = Join-Path ([IO.Path]::GetTempPath()) ('specrew-store-mutant-' + [Guid]::NewGuid().ToString('N').Substring(0, 12))
            $null = New-Item -ItemType Directory -Path $root -Force
            $script:MutantRoots.Add($root)
            $mutantPath = Join-Path $root 'review-authority-store.ps1'
            $source = Get-Content -LiteralPath $script:StorePath -Raw

            # The mutant needs REAL siblings at its OWN $PSScriptRoot: both this file's and
            # review-authority-store.Tests.ps1's self-load guards are $PSScriptRoot-relative
            # (`. (Join-Path $PSScriptRoot 'review-authority-core.ps1')` etc.), which resolves to
            # THIS scratch directory once the mutant is dot-sourced from here, not to the real tree.
            Copy-Item -LiteralPath $script:CorePath -Destination (Join-Path $root 'review-authority-core.ps1') -Force
            Copy-Item -LiteralPath $script:PathIdentityPath -Destination (Join-Path $root 'path-identity.ps1') -Force

            $pattern = '(?s)(\$comparison = Get-ContinuousCoReviewPathComparison -Path \$root -WhenUndetermined ''same''\r?\n    if \(-not \$full\.StartsWith\(\$prefix, \$comparison\)\) \{ throw "review-store-path-escape:\$RelativePath" \}\r?\n).*?(\r?\n    return \$full\r?\n\})'
            $replacement = '$1' + "`n    return `$full`n}"
            $mutated = [regex]::Replace($source, $pattern, $replacement)
            if ($mutated -eq $source) { throw 'link-blind mutation did not apply - Get-ReviewAuthorityStorePath was refactored and this gate must be updated, not deleted' }

            Set-Content -LiteralPath $mutantPath -Value $mutated -Encoding UTF8

            # Positive proof the mutation actually removed the containment behaviour, not just text.
            $verifyRoot = Join-Path $root 'verify'
            $verifyOutside = Join-Path $root 'verify-outside'
            $null = New-Item -ItemType Directory -Path $verifyOutside -Force
            $verify = & 'pwsh' '-NoProfile' '-Command' @"
`$ErrorActionPreference = 'Stop'
. '$($script:CorePath)'
. '$($script:PathIdentityPath)'
. '$mutantPath'
`$link = '$verifyRoot'
try { New-Item -ItemType SymbolicLink -Path `$link -Target '$verifyOutside' -ErrorAction Stop | Out-Null } catch { 'SKIP'; exit 0 }
try { `$p = Get-ReviewAuthorityStorePath -StoreRoot `$link -RelativePath 'campaigns/x/grants/g.json'; "ACCEPTED:`$p" } catch { "REFUSED:`$(`$_.Exception.Message)" }
"@
            $verifyLine = @($verify | Where-Object { $_ -match '^(ACCEPTED|REFUSED|SKIP)' }) | Select-Object -Last 1
            if ([string]::IsNullOrWhiteSpace($verifyLine)) { throw ("mutant did not load; output: " + ($verify -join ' | ')) }
            if ($verifyLine -eq 'SKIP') { return @{ Path = $mutantPath; Verified = $false } }
            if (-not $verifyLine.StartsWith('ACCEPTED')) { throw "mutation did not actually remove containment - the mutant still refused a linked root ($verifyLine)" }
            return @{ Path = $mutantPath; Verified = $true }
        }

        function Invoke-StoreFixturesAgainst {
            param([Parameter(Mandatory)][string]$StorePath)
            $inner = "`$env:SPECREW_AUTHORITY_STORE_UNDER_TEST = '$StorePath'; `$r = Invoke-Pester -Path '$($script:FixturePath)' -PassThru -Output None; `"failed=`$(`$r.FailedCount) passed=`$(`$r.PassedCount)`""
            $out = & 'pwsh' '-NoProfile' '-Command' $inner 2>&1
            $summary = @($out | Where-Object { $_ -match '^failed=\d+ passed=\d+$' }) | Select-Object -Last 1
            if ([string]::IsNullOrWhiteSpace($summary)) { throw ("fixtures did not report a summary; output: " + ($out -join ' | ')) }
            if ($summary -match '^failed=(\d+) passed=(\d+)$') { return [pscustomobject]@{ Failed = [int]$Matches[1]; Passed = [int]$Matches[2] } }
            throw "unparsable fixture summary: $summary"
        }
    }

    AfterAll {
        foreach ($root in $script:MutantRoots) {
            try { if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force } }
            catch { $null = $_ }
        }
    }

    It 'CONTROL: the T082 fixtures pass against the real, contained store' {
        $result = Invoke-StoreFixturesAgainst -StorePath $script:StorePath
        $result.Failed | Should -Be 0 -Because 'the mutant result below is only meaningful if the unmutated baseline is green on this runner'
        $result.Passed | Should -BeGreaterThan 0 -Because 'a fixture set that runs zero assertions cannot detect anything'
    }

    It 'catches a link-blind store: the reparse-point fixtures fail against the pre-T082 shape' {
        $mutant = New-LinkBlindStoreMutant
        if (-not $mutant.Verified) {
            Set-ItResult -Skipped -Because 'this runner refuses symlink creation; the link-blind mutant cannot be verified to have actually lost containment here'
            return
        }
        $result = Invoke-StoreFixturesAgainst -StorePath $mutant.Path
        $result.Failed | Should -BeGreaterThan 0 -Because 'a store that accepts a linked root or a linked ancestor is wrong on every volume; a fixture set that cannot notice that is not testing containment at all'
    }
}
