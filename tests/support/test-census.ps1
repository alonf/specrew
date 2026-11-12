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

        # The T014/T015 rulings (maintainer, 2026-11-12) on the scripts no lane ran before this census. Each was
        # read for writes to the real home folder; a red one is excluded only by the maintainer's ruling (FR-012).
        'tests/integration/substantive-interaction-model-iteration2.ps1' = 'stale README assertion (section removed by b27f35c4); bug list item 16, fixed in iteration 002'
        'tests/integration/distribution-module-init.ps1'                 = 'writes the real home; not run until feature 203''s private test home is merged (specrew-init deploys the hook files)'
        'tests/manual/multi-host-smoke.ps1'                              = 'writes the real home; not run until feature 203''s private test home is merged (installed specrew init and start; bug list item 18)'
        'tests/integration/team-management.ps1'                         = 'writes the real home; not run until feature 203''s private test home is merged'
        'tests/integration/update-command.ps1'                           = 'writes the real home; not run until feature 203''s private test home is merged'
        'tests/integration/validate-baseline-team.ps1'                   = 'writes the real home; not run until feature 203''s private test home is merged'
        'tests/manual/copilot-squad-smoke.ps1'                           = 'writes the real home; not run until feature 203''s private test home is merged'
        'tests/integration/distribution-module-publish.ps1'              = 'would publish to PSGallery if PSGALLERY_API_KEY is set; bug list item 17 (severity high)'
        'tests/integration/feature-017-dashboard-core.ps1'               = 'red: its healthy fixture is not a Specrew project to `specrew where` ("requires a Specrew-managed project"); bug list item 19, fixed in iteration 002'
        'tests/integration/feature-018-rich-dashboard.ps1'               = 'red: the rendered rich dashboard no longer matches rich-capable-expected.txt (golden file or velocity change, not established); bug list item 20, fixed in iteration 002'
        'tests/integration/validator-hardening-iteration2.ps1'           = 'red: specrew start classifies the agent and charter files it wrote itself as user changes and pauses (assertion 3; bug 2b''s cause beyond copilot-instructions); bug list item 21; SC-002 required in iteration 002, then the release manifest'
        'tests/integration/project-path-resolution-regression.ps1'       = 'SC-001 not met in iteration 001: supervised runs 3 and 4 wrote into this repository (both rewrote specs/206-bug-bash/iterations/001/state.md; run 4 left a .specrew-squad-probe-* folder at its root); the script refuses to run until bug list items 23, 24 and 25 are fixed; required in iteration 002'
    }
}

# HELD (maintainer, 2026-11-12): a test that no lane, CI step or registry ran before this census counted it
# is held - counted by the lane guard, listed but not run by the release full sweep - until it is read for
# writes to the real home folder (FR-012). T014 read the 36 that were held; T015 registered or excluded each
# by the maintainer's ruling, and the lane guard requires this list to be empty. An entry added here later
# must name a test that nothing runs, with its reason.
function Get-SpecrewTestCensusHeld {
    return [ordered]@{}
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
