#requires -Version 7.0
# D-197-I010-002 / FR-016 + SC-022 (maintainer directive 2026-07-08): the CCR CORE is AI-host-free.
# Harness specifics (names, binaries, flags, prompt transport, independence pairings) live ONLY in
# reviewer-host-catalog.ps1 (the sanctioned host-data seam) and in host-side code. This guard scans
# every core script for lowercase harness-name literals in CODE (comments excluded) so the class of
# defect the maintainer caught - a hardcoded claude fallback, a claude<->codex pairing - cannot
# silently return.

Describe 'host-neutral CCR core (D-197-I010-002)' {

    BeforeAll {
        $script:CoreDir = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..' 'scripts' 'internal' 'continuous-co-review')).Path
        # The catalog IS the host-data home; presentation renders catalog rows verbatim.
        $script:ExcludedFiles = @('reviewer-host-catalog.ps1')
        # Lowercase harness tokens; a leading . / - / word char (dot-dirs like .claude, file names,
        # compound words) does not count. CLAUDE.md is uppercase and case-sensitively ignored.
        $script:BannedToken = [regex]::new('(?<![.\w/-])(claude|codex|copilot|antigravity)(?![\w-])')
    }

    It 'no core script names a reviewer harness in code (catalog excluded; comments ignored)' {
        $violations = New-Object System.Collections.Generic.List[string]
        foreach ($file in (Get-ChildItem -LiteralPath $script:CoreDir -Filter '*.ps1' -File)) {
            if ($script:ExcludedFiles -contains $file.Name) { continue }
            $lineNo = 0
            foreach ($line in (Get-Content -LiteralPath $file.FullName -Encoding UTF8)) {
                $lineNo++
                $m = $script:BannedToken.Match($line)
                if (-not $m.Success) { continue }
                # Comment tolerance: a token at/after the line's first '#' is prose, not code. (A '#'
                # inside a string before the token would false-allow - acceptable for a guard; the
                # goal is catching hardcoded host BEHAVIOR, which cannot live inside a comment.)
                $hashAt = $line.IndexOf('#')
                if ($hashAt -ge 0 -and $m.Index -gt $hashAt) { continue }
                $violations.Add(("{0}:{1}: {2}" -f $file.Name, $lineNo, $line.Trim())) | Out-Null
            }
        }
        ($violations -join "`n") | Should -BeNullOrEmpty -Because 'harness specifics live ONLY in reviewer-host-catalog.ps1 (the core stays AI-host-free; maintainer directive 2026-07-08)'
    }

    It 'the selection policy derives independence from the catalog, not a hardcoded pairing' {
        $policy = Get-Content -LiteralPath (Join-Path $script:CoreDir 'reviewer-selection-policy.ps1') -Raw
        $policy | Should -Match ([regex]::Escape('$_.host -ne $CodeWriterHost')) -Because 'the independence preference is a generic different-harness rule over catalog data'
    }
}
