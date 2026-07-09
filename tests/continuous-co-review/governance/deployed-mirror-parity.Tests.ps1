#requires -Version 7.0
# F-197 deployed-mirror parity guard (closes the gap behind drift-log D-197-I009-001).
#
# The iter-008 worktree cutover updated the SOURCE co-review navigator provider (worktree-navigator.ps1 +
# Invoke-ContinuousCoReviewWorktreeNavigator) but the DEPLOYED `.specify` mirror was never re-synced - it
# still called the LEGACY Invoke-ContinuousCoReviewNavigator, so the provider went DARK on every Stop and the
# auto co-review was silently dead for days, masked by manual `specrew review --live`.
#
# Why nothing caught it: the deploy-completeness test deploys a FRESH copy into a TestDrive (it validates the
# deploy SCRIPT), and the governance validator has form-vs-meaning + state-mirror parity but NO
# .specify-extension-vs-source parity. So a stale COMMITTED mirror was invisible. This guard makes that drift
# class fail LOUD: the F-197-owned deployed extension files must be content-identical to their source.

Describe 'F-197 deployed extension files mirror source (D-197-I009-001 guard)' {

    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        # F-197-owned files that MUST be mirrored source (extensions/...) -> deploy (.specify/extensions/...).
        # Add a row here whenever F-197 adds a deployed extension-scripts surface.
        $script:MirroredRel = @(
            'extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1'
        )
    }

    It 'every F-197-owned deployed extension file is content-identical to source' {
        # ENVIRONMENT GUARD (co-review finding 2026-07-08, run 20260708T113633825): this is a META-test
        # about the REAL repo's committed mirror state. The continuous co-review worktree deliberately
        # STRIPS .specify/ (machinery), so inside a review worktree - or any checkout without the
        # deployed mirror - there is nothing to compare: SKIP with the reason, never a false FAIL.
        if (-not (Test-Path -LiteralPath (Join-Path $script:RepoRoot '.specify') -PathType Container)) {
            Set-ItResult -Skipped -Because 'no .specify/ deployed mirror in this checkout (e.g. the stripped co-review worktree) - parity is a real-repo meta-check'
            return
        }
        $drift = [System.Collections.Generic.List[string]]::new()
        foreach ($rel in $script:MirroredRel) {
            $src = Join-Path $script:RepoRoot $rel
            $dep = Join-Path $script:RepoRoot ($rel -replace '^extensions/', '.specify/extensions/')
            if (-not (Test-Path -LiteralPath $src -PathType Leaf)) { $drift.Add("source missing: $rel"); continue }
            if (-not (Test-Path -LiteralPath $dep -PathType Leaf)) { $drift.Add("deployed mirror missing: $dep"); continue }
            # Normalize line endings only (CRLF<->LF is a deploy artifact, not real drift); any other
            # difference - a renamed function, a changed path - is real and must fail.
            $srcN = (Get-Content -LiteralPath $src -Raw) -replace "`r`n", "`n"
            $depN = (Get-Content -LiteralPath $dep -Raw) -replace "`r`n", "`n"
            if ($srcN -ne $depN) { $drift.Add("deployed DRIFTS from source: $rel (re-sync the .specify mirror)") }
        }
        $drift -join '; ' | Should -BeNullOrEmpty -Because 'a deployed extension file drifting from source makes the runtime dark while the source tests stay green (D-197-I009-001)'
    }
}
