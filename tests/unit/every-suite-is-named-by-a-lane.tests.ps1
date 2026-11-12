[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Every assertion runs and is counted; the run fails at the end if any failed, so a red run names every
# failing check, not only the first. A prerequisite (a file the rest cannot run without) still stops at once.
$script:AssertionCount = 0
$script:Failures = [Collections.Generic.List[string]]::new()
function Assert-True {
    param([bool] $Condition, [string] $Message)
    $script:AssertionCount++
    if (-not $Condition) {
        $script:Failures.Add($Message)
        Write-Host "FAIL: $Message" -ForegroundColor Red
        return
    }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-Prerequisite {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# W66 (maintainer ruling, 2026-08-26): THE NINTH CANNOT BE WRITTEN INTO THE SILENCE.
#
# Measured: the verification plan named 45 suite files; 384 existed on disk. Every round of the
# beta3 walk ran the lanes, saw green, and reported green - while 331 suites went unrun and twelve
# of them were red, including two live product defects and two checks that were measuring the wrong
# universe (DRIFT-199-I001-134). The gap was invisible because nothing compared the two lists.
#
# The ruling splits the fix by cost. THIS is the fast half: it LISTS and COMPARES, it does not
# execute, so it costs seconds and belongs in the lane that runs every round. A suite written into
# no lane fails here immediately, which is the durable property - the failure arrives when the file
# is added, not weeks later when someone happens to run a census. The slow half - executing every
# suite - is the release gate, where slowness is affordable and a tag cannot be cut without it.
#
# WHY A FILE-NAME COMPARISON IS THE RIGHT CHECK: a lane names its suites literally in the command it
# runs, so membership is decidable by reading the plan. Nothing here asserts that a suite PASSES;
# that is the lanes' own job. This asserts only that some lane would notice.
#
# FR-011 (feature 206): WHAT COUNTS AS A TEST IS ONE DEFINITION, NOT A FILE-NAME PATTERN. This guard counted
# only files named *test.ps1 or *tests.ps1, so 35 script-style suites ran in no lane, no CI step and no
# release manifest, and the guard that exists to notice that shared the blind spot. The census in
# tests/support/test-census.ps1 is the one definition, read by this guard and by the release full sweep.
# SC-004 is proved below on temp fixtures, both ways: an unregistered script of any file name fails the
# comparison, and removing it makes the comparison pass.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'tests/support/test-census.ps1')

# --- The census: every test under tests/ ---------------------------------------------------------
function Get-CensusTests {
    param([Parameter(Mandatory)][string] $Root)
    @(Get-SpecrewTestCensus -RepoRoot $Root | Where-Object { $_.Included } | ForEach-Object { [pscustomobject]@{ Path = $_.Path; Kind = $_.Kind } })
}

function Get-CensusExclusions { Get-SpecrewTestCensusExclusions }
function Get-CensusHeld { Get-SpecrewTestCensusHeld }
function Get-CensusRegistries { @(Get-SpecrewTestCensusRegistries) }

# A literal test path in a command, a workflow or a registry: tests/<anything>.ps1, either separator.
$script:TestPathPattern = '(?i)(?<![A-Za-z0-9_.-])tests/[A-Za-z0-9/._-]+?\.ps1(?![A-Za-z0-9])'
function Get-TestPathsIn {
    param([string] $Text)
    @([regex]::Matches(($Text -replace '\\', '/'), $script:TestPathPattern) | ForEach-Object { $_.Value })
}
# Comment lines name files without running them, so they name nothing.
function Get-UncommentedText {
    param([string] $Path)
    (@(Get-Content -LiteralPath $Path -Encoding UTF8) | Where-Object { $_ -notmatch '^\s*#' }) -join "`n"
}

# --- What the lanes, the release manifest and CI name ---------------------------------------------
function Get-NamedTests {
    param([Parameter(Mandatory)][string] $Root)
    $named = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $laneNamed = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $ciNamed = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $registriesRead = [Collections.Generic.List[string]]::new()
    $planCommands = @()
    $planPath = Join-Path $Root '.specrew/verification-plan.json'
    if (Test-Path -LiteralPath $planPath -PathType Leaf) {
        $planCommands = @((Get-Content -LiteralPath $planPath -Raw -Encoding UTF8 | ConvertFrom-Json).commands)
    }
    # Signoff-cadence lanes (maintainer ruling 2026-10-14, 202 DRIFT-013): mid-iteration checkpoint rounds
    # verify only the active feature's lanes, and the carried-forward lanes are parked here until the
    # signoff round restores them to the plan. A parked lane still runs before signoff, so its suites
    # count as named; a lane in neither file is the state this guard exists to catch.
    $parkedCommands = @()
    $parkedPath = Join-Path $Root '.specrew/verification-plan.signoff-lanes.json'
    if (Test-Path -LiteralPath $parkedPath -PathType Leaf) {
        $parkedCommands = @((Get-Content -LiteralPath $parkedPath -Raw -Encoding UTF8 | ConvertFrom-Json).commands)
    }
    foreach ($command in @($planCommands + $parkedCommands)) {
        foreach ($argument in @($command.arguments)) {
            foreach ($hit in @(Get-TestPathsIn -Text ([string]$argument))) {
                [void]$named.Add($hit)
                [void]$laneNamed.Add($hit)
            }
        }
    }
    # The ruling splits cadence by cost, so a suite may legitimately run only before a tag. That is a
    # DECISION, and a decision has to be readable: the release-cadence suites are listed in the open,
    # one per line, and this guard treats that list as the second lane.
    $releaseNamed = @()
    $manifestPath = Join-Path $Root '.specrew/release-gate-suites.txt'
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        $releaseNamed = @(Get-Content -LiteralPath $manifestPath -Encoding UTF8 |
                ForEach-Object { $_.Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith('#') } |
                ForEach-Object { $_ -replace '\\', '/' })
    }
    foreach ($entry in $releaseNamed) { [void]$named.Add($entry); [void]$laneNamed.Add($entry) }
    # A CI step runs what it names (FR-011: "no lane, CI step or release manifest").
    $workflowRoot = Join-Path $Root '.github/workflows'
    if (Test-Path -LiteralPath $workflowRoot -PathType Container) {
        foreach ($workflow in @(Get-ChildItem -LiteralPath $workflowRoot -File | Where-Object { $_.Extension -in @('.yml', '.yaml') })) {
            foreach ($hit in @(Get-TestPathsIn -Text (Get-UncommentedText -Path $workflow.FullName))) { [void]$ciNamed.Add($hit); [void]$named.Add($hit) }
        }
    }
    # A registry runner that a CI step runs runs every script it lists (tests/support/test-census.ps1).
    foreach ($registry in @(Get-CensusRegistries)) {
        $registryPath = Join-Path $Root $registry
        if (-not $ciNamed.Contains($registry) -or -not (Test-Path -LiteralPath $registryPath -PathType Leaf)) { continue }
        $registriesRead.Add($registry)
        foreach ($hit in @(Get-TestPathsIn -Text (Get-UncommentedText -Path $registryPath))) { [void]$named.Add($hit) }
    }
    return [pscustomobject]@{
        Named = $named; LaneNamed = $laneNamed; PlanCommands = $planCommands.Count; ParkedCommands = $parkedCommands.Count
        ReleaseCount = $releaseNamed.Count; CiNamed = $ciNamed; RegistriesRead = @($registriesRead)
    }
}

function Get-UnnamedTests {
    param([Parameter(Mandatory)][string] $Root)
    $names = Get-NamedTests -Root $Root
    @(Get-CensusTests -Root $Root | Where-Object { -not $names.Named.Contains($_.Path) } | ForEach-Object { $_.Path })
}

# --- This repository -------------------------------------------------------------------------------
Assert-Prerequisite (Test-Path -LiteralPath (Join-Path $repoRoot '.specrew/verification-plan.json') -PathType Leaf) 'the verification plan exists to be read'
Assert-Prerequisite (Test-Path -LiteralPath (Join-Path $repoRoot '.specrew/release-gate-suites.txt') -PathType Leaf) 'the release-cadence manifest exists'
$names = Get-NamedTests -Root $repoRoot
if (Test-Path -LiteralPath (Join-Path $repoRoot '.specrew/verification-plan.signoff-lanes.json') -PathType Leaf) {
    Assert-True ($names.ParkedCommands -ge 1) 'the parked signoff lanes file names at least one lane'
}
Assert-True ($names.LaneNamed.Count -ge 40) ("the per-round lanes and the release manifest name suites to compare against (found {0})" -f $names.LaneNamed.Count)
Assert-True ($names.ReleaseCount -ge 1) ("the release gate names suites too (found {0})" -f $names.ReleaseCount)

$registries = @(Get-CensusRegistries)
Assert-True (@($names.RegistriesRead).Count -eq $registries.Count) ("every census registry is still run by a CI step, so the scripts it lists count as named (read: {0} of {1})" -f @($names.RegistriesRead).Count, $registries.Count)

$census = @(Get-CensusTests -Root $repoRoot)
Assert-True ($census.Count -ge 400) ("the census finds the repository's tests (found {0})" -f $census.Count)

# Exclusions are DECLARED, in the open, each with a reason, and each must still name a file: an
# exclusion is a decision someone can read and argue with; silence is not.
$exclusions = Get-CensusExclusions
$staleExclusions = @($exclusions.Keys | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_) -PathType Leaf) })
$unreasoned = @($exclusions.Keys | Where-Object { [string]::IsNullOrWhiteSpace([string]$exclusions[$_]) })
Assert-True ($staleExclusions.Count -eq 0 -and $unreasoned.Count -eq 0) ("every census exclusion names a file that exists, with a reason{0}" -f $(
        if ($staleExclusions.Count + $unreasoned.Count -gt 0) { "`n  STALE: " + ($staleExclusions -join ', ') + "`n  NO REASON: " + ($unreasoned -join ', ') } else { '' }))

# --- Every test on disk is named by at least one lane, CI step or the release manifest -------------
$unnamed = @($census | Where-Object { -not $names.Named.Contains($_.Path) } | ForEach-Object { $_.Path })
Assert-True ($unnamed.Count -eq 0) ("every test file on disk is named by a verification lane, a CI step or the release manifest{0}" -f $(
        if ($unnamed.Count -gt 0) {
            "`n  UNNAMED (" + $unnamed.Count + "): they run nowhere, so nothing would notice them failing:`n    " + ($unnamed -join "`n    ") +
            "`n  Add each to a lane, a CI step or .specrew/release-gate-suites.txt, or list it in the census exclusions with a reason."
        } else { '' }))

# --- Held: tests the sweep lists but does not run until they are read (maintainer, 2026-11-12) ----------
# A script that no lane, CI step or registry ran before is not run by the sweep until it has been read
# for home writes (FR-012, T014). It is still a test, so the comparison above still counts it. The held
# list may hold only such scripts: one that something already runs has nothing to wait for.
$held = Get-CensusHeld
$censusPaths = @($census | ForEach-Object { $_.Path })
$heldNotTests = @($held.Keys | Where-Object { $censusPaths -notcontains $_ })
$heldNamed = @($held.Keys | Where-Object { $names.Named.Contains($_) })
$heldUnreasoned = @($held.Keys | Where-Object { [string]::IsNullOrWhiteSpace([string]$held[$_]) })
Assert-True ($heldNotTests.Count + $heldNamed.Count + $heldUnreasoned.Count -eq 0) ("every held script is a test in the census, has a reason, and is named by no lane, CI step or registry{0}" -f $(
        if ($heldNotTests.Count + $heldNamed.Count + $heldUnreasoned.Count -gt 0) {
            "`n  NOT A TEST: " + ($heldNotTests -join ', ') + "`n  ALREADY NAMED: " + ($heldNamed -join ', ') + "`n  NO REASON: " + ($heldUnreasoned -join ', ')
        } else { '' }))

# --- And the lanes may not name suites that do not exist ------------------------------------------
# The mirror failure: a lane naming a deleted file runs nothing and reports success for it.
$stale = @($names.LaneNamed | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_) -PathType Leaf) })
Assert-True ($stale.Count -eq 0) ("every suite the lanes name still exists{0}" -f $(
        if ($stale.Count -gt 0) { "`n  STALE: " + ($stale -join ', ') } else { '' }))

# --- SC-004, both ways, on fixtures ---------------------------------------------------------------
# Without this, the comparison above could pass because it is broken rather than because the lanes are
# complete - the exact failure mode the W66 ruling is about. The fixture is a temp folder with one lane,
# one release-manifest entry and one CI step, each naming a test; a fixture file and a support helper sit
# beside them and must not count.
function New-CensusFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('census-fixture-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    foreach ($dir in @('.specrew', '.github/workflows', 'tests/unit', 'tests/integration/fixtures', 'tests/support')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $root $dir) -Force
    }
    $plan = [ordered]@{ schema_version = '1.0'; commands = @([ordered]@{ command_id = 'lane'; executable = 'pwsh'; arguments = @('-NoProfile', '-File', 'tests/unit/lane-named.tests.ps1') }) }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/verification-plan.json'), ($plan | ConvertTo-Json -Depth 5))
    [IO.File]::WriteAllText((Join-Path $root '.specrew/release-gate-suites.txt'), "# release cadence`ntests/unit/release-named.tests.ps1`n")
    [IO.File]::WriteAllText((Join-Path $root '.github/workflows/ci.yml'), "jobs:`n  t:`n    steps:`n      # tests/integration/only-in-a-comment.ps1`n      - run: pwsh -File ./tests/integration/ci-named.ps1`n")
    foreach ($file in @('tests/unit/lane-named.tests.ps1', 'tests/unit/release-named.tests.ps1', 'tests/integration/ci-named.ps1',
            'tests/integration/fixtures/helper.ps1', 'tests/support/helper.ps1')) {
        [IO.File]::WriteAllText((Join-Path $root $file), "exit 0`n")
    }
    return $root
}

$fixture = New-CensusFixture
try {
    $fixtureCensus = @(Get-CensusTests -Root $fixture | ForEach-Object { $_.Path })
    Assert-True ($fixtureCensus -contains 'tests/integration/ci-named.ps1') 'fixture: a script named only by a CI step is a test in the census'
    Assert-True ($fixtureCensus -notcontains 'tests/integration/fixtures/helper.ps1' -and $fixtureCensus -notcontains 'tests/support/helper.ps1') 'fixture: a fixture file and a support helper are not tests (the listed rule)'
    $baseline = @(Get-UnnamedTests -Root $fixture)
    Assert-True ($baseline.Count -eq 0) ("fixture: with every test named, the comparison passes (unnamed: {0})" -f ($baseline -join ', '))

    foreach ($probe in @('tests/integration/zz-probe.ps1', 'tests/integration/zz-probe.tests.ps1', 'tests/integration/ZzProbe.Tests.ps1',
            'tests/integration/deeper/zz_probe.ps1', 'tests/integration/only-in-a-comment.ps1')) {
        $probePath = Join-Path $fixture $probe
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $probePath) -Force
        [IO.File]::WriteAllText($probePath, "exit 0`n")
        $withProbe = @(Get-UnnamedTests -Root $fixture)
        Assert-True ($withProbe.Count -eq 1 -and $withProbe[0] -eq $probe) ("SC-004: an unregistered '{0}' fails the comparison (unnamed: {1})" -f $probe, ($withProbe -join ', '))
        Remove-Item -LiteralPath $probePath -Force
        $withoutProbe = @(Get-UnnamedTests -Root $fixture)
        Assert-True ($withoutProbe.Count -eq 0) ("SC-004: with '{0}' removed, the comparison passes (unnamed: {1})" -f $probe, ($withoutProbe -join ', '))
    }
}
finally {
    Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue
}

# --- The release full sweep uses the same definition ----------------------------------------------
# Listed, never run: -ListOnly prints the files the sweep would run ("LIST") and the held ones ("HELD"), and
# exits before running any of them.
function Compare-Listing {
    param([string[]] $Listed, [string[]] $Expected, [string] $Message, [int] $Exit)
    $onlyListed = @($Listed | Where-Object { $Expected -notcontains $_ })
    $onlyExpected = @($Expected | Where-Object { $Listed -notcontains $_ })
    Assert-True ($Exit -eq 0 -and $onlyListed.Count -eq 0 -and $onlyExpected.Count -eq 0) ("{0} (exit {1}; listed {2}; expected {3}; only listed: {4}; missing: {5})" -f
        $Message, $Exit, @($Listed).Count, @($Expected).Count, (@($onlyListed | Select-Object -First 5) -join ', '), (@($onlyExpected | Select-Object -First 5) -join ', '))
}
$sweep = Join-Path $repoRoot 'tests/full-powershell-test-sweep.ps1'
$sweepOutput = @(& pwsh -NoProfile -NonInteractive -File $sweep -ListOnly 2>&1 | ForEach-Object { [string]$_ })
$sweepExit = $LASTEXITCODE
$sweepListed = @($sweepOutput | Where-Object { $_ -match '^LIST (pester|script) (\S.*)$' } | ForEach-Object { '{0} {1}' -f $Matches[1], $Matches[2] } | Sort-Object)
$sweepHeld = @($sweepOutput | Where-Object { $_ -match '^HELD (pester|script) (\S.*)$' } | ForEach-Object { '{0} {1}' -f $Matches[1], $Matches[2] } | Sort-Object)
$censusToRun = @($census | Where-Object { -not $held.Contains($_.Path) } | ForEach-Object { '{0} {1}' -f $_.Kind, $_.Path } | Sort-Object)
$censusHeld = @($census | Where-Object { $held.Contains($_.Path) } | ForEach-Object { '{0} {1}' -f $_.Kind, $_.Path } | Sort-Object)
Assert-True ($sweepListed.Count -ge 400) ("the release full sweep lists the tests it would run (found {0})" -f $sweepListed.Count)
Compare-Listing -Listed $sweepListed -Expected $censusToRun -Exit $sweepExit -Message 'the release full sweep lists exactly the census to run, with the same kinds'
Compare-Listing -Listed $sweepHeld -Expected $censusHeld -Exit $sweepExit -Message 'the release full sweep marks exactly the held scripts as held'

# --- A held script is not run by the sweep's real run (fixture) -----------------------------------
# The sweep and the census are copied into a temp repository with two trivial scripts, one of them held
# by the fixture's own census. Each writes a marker OUTSIDE that repository when it runs (inside it, the
# marker would trip the sweep's caller-contamination check). Only the fixture's two files run.
$sweepBase = Join-Path ([IO.Path]::GetTempPath()) ('census-sweep-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
$sweepRepo = Join-Path $sweepBase 'repo'
$markers = Join-Path $sweepBase 'markers'
try {
    foreach ($dir in @('tests/unit', 'tests/integration', 'tests/support')) { $null = New-Item -ItemType Directory -Path (Join-Path $sweepRepo $dir) -Force }
    $null = New-Item -ItemType Directory -Path $markers -Force
    Copy-Item -LiteralPath $sweep -Destination (Join-Path $sweepRepo 'tests/full-powershell-test-sweep.ps1')
    $censusSource = Join-Path $repoRoot 'tests/support/test-census.ps1'
    $censusText = if (Test-Path -LiteralPath $censusSource -PathType Leaf) { Get-Content -LiteralPath $censusSource -Raw -Encoding UTF8 } else { '' }
    # The fixture's held list replaces the repository's: a later definition of the function wins.
    $censusText += "`nfunction Get-SpecrewTestCensusHeld { [ordered]@{ 'tests/integration/zz-held.tests.ps1' = 'fixture: held' } }`n"
    [IO.File]::WriteAllText((Join-Path $sweepRepo 'tests/support/test-census.ps1'), $censusText)
    foreach ($fixtureScript in @(@{ Path = 'tests/unit/ok.tests.ps1'; Marker = 'ok-ran' }, @{ Path = 'tests/integration/zz-held.tests.ps1'; Marker = 'held-ran' })) {
        $markerPath = (Join-Path $markers $fixtureScript.Marker).Replace("'", "''")
        [IO.File]::WriteAllText((Join-Path $sweepRepo $fixtureScript.Path), "[IO.File]::WriteAllText('$markerPath', 'ran')`nexit 0`n")
    }
    & git -C $sweepRepo init --quiet
    & git -C $sweepRepo add -- tests
    & git -C $sweepRepo -c user.name='Census Fixture' -c user.email='census-fixture@example.invalid' commit --quiet -m 'fixture: held'
    $fixtureSweep = Join-Path $sweepRepo 'tests/full-powershell-test-sweep.ps1'
    $fixtureList = @(& pwsh -NoProfile -NonInteractive -File $fixtureSweep -ListOnly 2>&1 | ForEach-Object { [string]$_ })
    $fixtureListExit = $LASTEXITCODE
    Assert-True ($fixtureListExit -eq 0 -and $fixtureList -contains 'HELD script tests/integration/zz-held.tests.ps1' -and
        $fixtureList -notcontains 'LIST script tests/integration/zz-held.tests.ps1' -and $fixtureList -contains 'LIST script tests/unit/ok.tests.ps1') ("fixture: -ListOnly marks a held script as held, not as to be run (exit {0}: {1})" -f $fixtureListExit, ($fixtureList -join ' | '))
    $fixtureRun = @(& pwsh -NoProfile -NonInteractive -File $fixtureSweep -MaxParallel 1 -PerFileTimeoutSeconds 120 2>&1 | ForEach-Object { [string]$_ })
    $fixtureRunExit = $LASTEXITCODE
    $okRan = Test-Path -LiteralPath (Join-Path $markers 'ok-ran') -PathType Leaf
    $heldRan = Test-Path -LiteralPath (Join-Path $markers 'held-ran') -PathType Leaf
    Assert-True ($fixtureRunExit -eq 0 -and $okRan -and -not $heldRan) ("fixture: the sweep's real run skips a held script and runs the rest (exit {0}; ran ok: {1}; ran held: {2}; output: {3})" -f
        $fixtureRunExit, $okRan, $heldRan, (@($fixtureRun | Select-Object -Last 3) -join ' | '))
}
finally {
    Remove-Item -LiteralPath $sweepBase -Recurse -Force -ErrorAction SilentlyContinue
}

# --- T015 (maintainer ruling 2026-11-12): the start-path scripts redirect the user profile themselves -----
# `specrew start` writes ~/.specrew/user-profile.yml when it is missing (scripts/specrew-start.ps1, the path
# from scripts/internal/user-profile.ps1). Each script below runs it, so each points SPECREW_USER_PROFILE_PATH
# at a temp file before its first start call, and never relies on the shell that runs it to have done so.
$startPathScripts = @(
    'tests/integration/project-path-resolution-regression.ps1'
    'tests/integration/specrew-start-auto-continue-preservation.ps1'
    'tests/integration/specrew-start-baseline-tracking.ps1'
    'tests/integration/specrew-start-change-detector.ps1'
    'tests/integration/specrew-start-end-to-end.ps1'
    'tests/integration/specrew-start-parameter-handling.ps1'
    'tests/integration/specrew-start-pause-and-confirm.ps1'
    'tests/integration/validator-hardening-iteration2.ps1'
)
foreach ($startPathScript in $startPathScripts) {
    $startPathText = Get-UncommentedText -Path (Join-Path $repoRoot $startPathScript)
    $profileOverride = [regex]::Match($startPathText, '(?m)^\s*\$env:SPECREW_USER_PROFILE_PATH\s*=\s*[^\r\n]*GetTempPath\(\)')
    $firstStartCall = $startPathText.IndexOf('specrew-start.ps1', [StringComparison]::OrdinalIgnoreCase)
    Assert-True ($profileOverride.Success -and $firstStartCall -ge 0 -and $profileOverride.Index -lt $firstStartCall) ("{0} sets SPECREW_USER_PROFILE_PATH to a temp file before it first names specrew-start.ps1 (override found: {1}; first start reference at {2})" -f
        $startPathScript, $profileOverride.Success, $firstStartCall)
}

# --- T015 (maintainer ruling 2026-11-12): the held list is empty, and each held script is where the ruling put it ---
# Every script T014 read is now registered (a CI step or the release manifest) or excluded with its reason; the
# held list exists only while a reading is owed, and none is.
Assert-True ($held.Count -eq 0) ("the census holds no script back: each is registered or excluded with its reason (held: {0})" -f (@($held.Keys) -join ', '))

$perPush = @(
    'tests/integration/brownfield-merge.ps1'
    'tests/integration/carry-forward-closed-iteration.ps1'
    'tests/integration/concurrency-sizing.ps1'
    'tests/integration/descriptive-reference-authored-prose.ps1'
    'tests/integration/descriptive-reference-excluded-surfaces.ps1'
    'tests/integration/feature-018-render-budget.ps1'
    'tests/integration/gap-governance.ps1'
    'tests/integration/hardening-gate-contract.ps1'
    'tests/integration/lockout-chain-cap.ps1'
    'tests/integration/mechanical-findings-contract.ps1'
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
)
$releaseOnly = @(
    'tests/integration/validator-hardening-iteration1.ps1'
)
$notInCi = @($perPush | Where-Object { -not $names.CiNamed.Contains($_) })
Assert-True ($notInCi.Count -eq 0) ("the scripts registered per push are named by a CI step (missing: {0})" -f ($notInCi -join ', '))
$notInRelease = @($releaseOnly | Where-Object { -not $names.LaneNamed.Contains($_) -or $names.CiNamed.Contains($_) })
Assert-True ($notInRelease.Count -eq 0) ("the slow scripts are in the release manifest, not a per-push CI step (wrong: {0})" -f ($notInRelease -join ', '))

$homeWriter = 'writes the real home; not run until feature 203''s private test home is merged'
$rulingExclusions = [ordered]@{
    'tests/integration/substantive-interaction-model-iteration2.ps1' = 'stale README assertion (section removed by b27f35c4)'
    'tests/integration/distribution-module-init.ps1'                 = $homeWriter
    'tests/manual/multi-host-smoke.ps1'                              = $homeWriter
    'tests/integration/team-management.ps1'                          = $homeWriter
    'tests/integration/update-command.ps1'                           = $homeWriter
    'tests/integration/validate-baseline-team.ps1'                   = $homeWriter
    'tests/manual/copilot-squad-smoke.ps1'                           = $homeWriter
    'tests/integration/distribution-module-publish.ps1'              = 'would publish to PSGallery if PSGALLERY_API_KEY is set'
    'tests/integration/feature-017-dashboard-core.ps1'               = 'red: '
    'tests/integration/feature-018-rich-dashboard.ps1'               = 'red: '
    'tests/integration/validator-hardening-iteration2.ps1'           = 'red: '
    'tests/integration/project-path-resolution-regression.ps1'       = 'awaits the maintainer'
}
foreach ($excludedPath in $rulingExclusions.Keys) {
    $declared = if ($exclusions.Contains($excludedPath)) { [string]$exclusions[$excludedPath] } else { '' }
    Assert-True ($declared.StartsWith([string]$rulingExclusions[$excludedPath], [StringComparison]::Ordinal) -and -not $names.Named.Contains($excludedPath)) ("{0} is excluded with the reason '{1}' and is named by no lane (declared: '{2}')" -f
        $excludedPath, $rulingExclusions[$excludedPath], $declared)
}

# --- SC-001's fixture is what a fresh checkout has (reviewer ruling 2026-11-12, under the maintainer's delegation) --
# project-path-resolution-regression.ps1 builds its fixture by copying this repository's .specrew. A copy of the
# working folder took the developer's gitignored session state with it (last-start-prompt.md, start-context.json,
# and the authority, review and runtime stores), so `specrew start` met a stale prompt and the result depended on
# whoever ran it. The copy takes the files git tracks.
$sc001Text = Get-UncommentedText -Path (Join-Path $repoRoot 'tests/integration/project-path-resolution-regression.ps1')
Assert-True ($sc001Text -match 'ls-files[^\r\n]*\.specrew') "SC-001's fixture copies only the files git tracks under .specrew, so its result does not depend on the developer's session files"
# A fresh copy of a governed project has features but no session files, which `specrew start` reads as stale
# state; with no console it refuses (item 1, T001). The start case chooses recovery A itself, so SC-001 measures
# path resolution (maintainer, option 1, 2026-11-12).
Assert-True ($sc001Text -match "(?s)scripts\\specrew-start\.ps1'\s*\r?\n\s*Arguments\s*=\s*'[^']*-RecoveryChoice A\b") "SC-001's start case passes -RecoveryChoice A, so a fresh fixture's missing session files cannot stop it"

Write-Host ''
if ($script:Failures.Count -gt 0) {
    Write-Host ("every suite is named by a lane: {0} of {1} assertions failed" -f $script:Failures.Count, $script:AssertionCount) -ForegroundColor Red
    exit 1
}
Write-Host ("every suite is named by a lane: all {0} assertions pass" -f $script:AssertionCount) -ForegroundColor Green
