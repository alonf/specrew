# The test census: one definition of "a test" for this repository (FR-011).
#
# Read by the lane-coverage guard (tests/unit/every-suite-is-named-by-a-lane.tests.ps1) and by the release
# full sweep (tests/full-powershell-test-sweep.ps1), so what the guard requires to be named and what the
# release runs cannot drift apart. Before this file, both used the file name (*test.ps1, *tests.ps1), and
# 35 script-style suites ran in no lane, no CI step and no release manifest without either one noticing.
#
# THE RULE. Every .ps1 under tests/ is a test, whatever its file name, except:
#   (a) a file under a directory named fixtures/, or under tests/support/: fixtures and support helpers;
#   (b) a file on the exclusion list below, each with its reason.
# A test whose source has a Describe block is a Pester suite; any other is a script, run with -File.
#
# In the census is not the same as safe to run on any machine. The test files that write the real home
# folder are tests and stay here (CI runs them on disposable runners); what keeps them off a developer's
# machine is that machine's never-run list, not this file.

# Files under tests/ that are not tests and are outside rule (a). One reason per entry. An entry whose file
# is gone fails the lane guard, so this list cannot rot.
function Get-SpecrewTestCensusExclusions {
    [ordered]@{
        'tests/full-powershell-test-sweep.ps1'             = 'runner, not a suite: the release full sweep; it runs this census'
        'tests/f198-regression-suite.ps1'                  = 'runner, not a suite: the curated F-198 registry; Specrew CI runs it, so the scripts it lists count as named (see the registries below)'
        'tests/f198-iteration006-foundation.ps1'           = 'runner, not a suite: runs a fixed list of continuous-co-review suites that are each named in their own right'
        'tests/cross-platform-verify.ps1'                  = 'runner, not a suite: the cross-platform verification entry point; runs suites that are each named in their own right'
        'tests/bootstrap/TurnRecordTestSupport.ps1'        = 'support helper outside tests/support/: dot-sourced by the bootstrap suites'
        'tests/integration/refocus-dispatcher-fixture.ps1' = 'support helper outside tests/support/: the governed-project fixture dot-sourced by the refocus and hook-suppression suites'
        'tests/host-probes/deployed-hook-harness.ps1'      = 'support helper: dot-sourced by the host-binding suites and the host probes'
        'tests/host-probes/probe-fixture-redaction.ps1'    = 'support helper: dot-sourced by the payload capture probe and the suites that check its fixtures'
        'tests/host-probes/codex-stop-contract-probe.ps1'  = 'live host probe, run by hand: drives the real Codex CLI; no lane can run it'
        'tests/host-probes/copilot-hook-firing-probe.ps1'  = 'live host probe, run by hand: drives the real Copilot CLI; no lane can run it'
        'tests/host-probes/host-payload-capture-probe.ps1' = 'live host probe, run by hand: records real host payloads; no lane can run it'
        'tests/host-probes/walk-capture-hook.ps1'          = 'not a test: a capture hook installed for a live walk'
        'tests/integration/_ctl-spec.ps1'                  = 'empty 0-byte file, not a test; deleted by T016 (feature 206, iteration 002)'
    }
}

# HELD (maintainer, 2026-11-12): tests that no lane, CI step or registry ran before this census counted
# them. They are tests - the lane guard counts them, and fails until each is registered - but the release
# full sweep lists them as held and does not run them, because a script is read for writes to the real
# home folder before it is run (FR-012), and that reading is T014. At T015 every entry moves to registered
# or to the exclusions with its reason, and a test then requires this list to be empty. The lane guard
# fails if an entry here is already named somewhere, or is not a test.
function Get-SpecrewTestCensusHeld {
    $reason = 'not read yet (T014)'
    $held = [ordered]@{}
    foreach ($path in @(
            'tests/integration/brownfield-merge.ps1'
            'tests/integration/carry-forward-closed-iteration.ps1'
            'tests/integration/concurrency-sizing.ps1'
            'tests/integration/descriptive-reference-authored-prose.ps1'
            'tests/integration/descriptive-reference-excluded-surfaces.ps1'
            'tests/integration/distribution-module-init.ps1'
            'tests/integration/distribution-module-publish.ps1'
            'tests/integration/feature-017-dashboard-core.ps1'
            'tests/integration/feature-018-render-budget.ps1'
            'tests/integration/feature-018-rich-dashboard.ps1'
            'tests/integration/gap-governance.ps1'
            'tests/integration/hardening-gate-contract.ps1'
            'tests/integration/lockout-chain-cap.ps1'
            'tests/integration/mechanical-findings-contract.ps1'
            'tests/integration/project-path-resolution-regression.ps1'
            'tests/integration/quality-evidence-governance.ps1'
            'tests/integration/quality-profile-foundation.ps1'
            'tests/integration/reviewer-artifacts.ps1'
            'tests/integration/reviewer-closeout-governance.ps1'
            'tests/integration/reviewer-regression-event.ps1'
            'tests/integration/reviewer-regression-ledger.ps1'
            'tests/integration/reviewer-regression-withdrawal.ps1'
            'tests/integration/specrew-start-auto-continue-preservation.ps1'
            'tests/integration/specrew-start-baseline-tracking.ps1'
            'tests/integration/specrew-start-change-detector.ps1'
            'tests/integration/specrew-start-end-to-end.ps1'
            'tests/integration/specrew-start-parameter-handling.ps1'
            'tests/integration/specrew-start-pause-and-confirm.ps1'
            'tests/integration/substantive-interaction-model-iteration2.ps1'
            'tests/integration/team-management.ps1'
            'tests/integration/update-command.ps1'
            'tests/integration/validate-baseline-team.ps1'
            'tests/integration/validator-hardening-iteration1.ps1'
            'tests/integration/validator-hardening-iteration2.ps1'
            'tests/manual/copilot-squad-smoke.ps1'
            'tests/manual/multi-host-smoke.ps1')) {
        $held[$path] = $reason
    }
    return $held
}

# Runners that a CI step runs and that list the scripts they run. A script one of them lists runs whenever
# the runner does, so the lane guard counts it as named - but only while a CI step still names the runner.
function Get-SpecrewTestCensusRegistries {
    @(
        'tests/f198-regression-suite.ps1'
        'tests/integration/validation-contract-lane.ps1'
    )
}

# Every .ps1 under tests/, sorted by path: Path (repository-relative, forward slashes), Kind (pester or
# script), Included (a test by the rule), Reason (why not, when not), Held (a test the sweep does not run
# yet) and HeldReason.
function Get-SpecrewTestCensus {
    param([Parameter(Mandatory)][string] $RepoRoot)
    $root = (Resolve-Path -LiteralPath $RepoRoot).Path
    $testsRoot = Join-Path $root 'tests'
    if (-not (Test-Path -LiteralPath $testsRoot -PathType Container)) { return @() }
    $exclusions = Get-SpecrewTestCensusExclusions
    $held = Get-SpecrewTestCensusHeld
    $entries = foreach ($file in @(Get-ChildItem -LiteralPath $testsRoot -Recurse -File -Filter '*.ps1')) {
        $relative = $file.FullName.Substring($root.Length + 1) -replace '\\', '/'
        $kind = if ([string](Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8) -match '(?m)^\s*Describe\s+[''"]') { 'pester' } else { 'script' }
        $reason = if ($relative -match '(?i)(^|/)fixtures/') { 'rule: under a fixtures/ directory' }
        elseif ($relative -match '(?i)^tests/support/') { 'rule: a support helper under tests/support/' }
        elseif ($exclusions.Contains($relative)) { 'excluded: ' + [string]$exclusions[$relative] }
        else { $null }
        $isHeld = ($null -eq $reason) -and $held.Contains($relative)
        [pscustomobject]@{
            Path = $relative; Kind = $kind; Included = ($null -eq $reason); Reason = $reason
            Held = $isHeld; HeldReason = $(if ($isHeld) { [string]$held[$relative] } else { $null })
        }
    }
    return @($entries | Sort-Object -Property Path -Culture ([cultureinfo]::InvariantCulture))
}
