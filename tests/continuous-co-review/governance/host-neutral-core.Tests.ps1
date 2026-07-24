#requires -Version 7.0
# D-197-I010-002 / FR-016 + SC-022 (maintainer directive 2026-07-08): the CCR policy and
# orchestration core is AI-host-free. Host literals are permitted only in this closed, auditable set
# of catalog, adapter, support, and containment-boundary scripts. This guard scans every other core
# script for lowercase harness-name literals in CODE (comments excluded), so the class of defect the
# maintainer caught - a hardcoded fallback or host pairing in generic policy - cannot silently return.

Describe 'host-neutral CCR core (D-197-I010-002)' {

    BeforeAll {
        $script:CoreDir = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..' 'scripts' 'internal' 'continuous-co-review')).Path
        # Closed host-bound seam. Adding a host-aware core script requires an explicit governance
        # decision here; a wildcard exclusion would make this boundary unauditable.
        $script:HostBoundBoundaryFiles = @(
            'checkpoint-diff-provider.ps1'
            'hook-health-receipt.ps1'
            'host-support-doctor.ps1'
            'host-support-tier.ps1'
            'review-antigravity-harness-port.ps1'
            'review-claude-harness-port.ps1'
            'review-codex-harness-port.ps1'
            'review-copilot-harness-port.ps1'
            'review-cursor-harness-port.ps1'
            'reviewer-host-catalog.ps1'
            'worktree-reviewer.ps1'
        )
        # Lowercase harness tokens; a leading . / - / word char (dot-dirs like .claude, file names,
        # compound words) does not count. CLAUDE.md is uppercase and case-sensitively ignored.
        $script:BannedToken = [regex]::new('(?<![.\w/-])(claude|codex|copilot|cursor|antigravity)(?![\w-])')
    }

    It 'the closed host-bound seam names existing scripts exactly once' {
        @($script:HostBoundBoundaryFiles | Select-Object -Unique).Count |
            Should -Be $script:HostBoundBoundaryFiles.Count -Because 'duplicate allowlist rows obscure boundary review'

        $missing = @($script:HostBoundBoundaryFiles | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path $script:CoreDir $_) -PathType Leaf)
        })
        ($missing -join "`n") | Should -BeNullOrEmpty -Because 'stale allowlist rows weaken the host-bound seam'
    }

    It 'no host-neutral core script names a reviewer harness in code (closed host-bound seam excluded; comments ignored)' {
        $violations = New-Object System.Collections.Generic.List[string]
        foreach ($file in (Get-ChildItem -LiteralPath $script:CoreDir -Filter '*.ps1' -File)) {
            if ($script:HostBoundBoundaryFiles -contains $file.Name) { continue }
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
        ($violations -join "`n") | Should -BeNullOrEmpty -Because 'host literals stay inside the closed host-bound seam; generic policy and orchestration remain AI-host-free'
    }

    It 'the selection policy derives independence from the catalog, not a hardcoded pairing' {
        $policy = Get-Content -LiteralPath (Join-Path $script:CoreDir 'reviewer-selection-policy.ps1') -Raw
        $policy | Should -Match ([regex]::Escape('$_.host -ne $CodeWriterHost')) -Because 'the independence preference is a generic different-harness rule over catalog data'
    }
}
