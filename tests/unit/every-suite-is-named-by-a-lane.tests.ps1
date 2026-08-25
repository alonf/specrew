[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

# --- What the lanes name -------------------------------------------------------------------------
$planPath = Join-Path $repoRoot '.specrew/verification-plan.json'
Assert-True (Test-Path -LiteralPath $planPath -PathType Leaf) 'the verification plan exists to be read'
$plan = Get-Content -LiteralPath $planPath -Raw -Encoding UTF8 | ConvertFrom-Json

$named = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($command in @($plan.commands)) {
    foreach ($argument in @($command.arguments)) {
        foreach ($hit in [regex]::Matches([string]$argument, '(?i)tests/[A-Za-z0-9/._-]+?\.tests\.ps1')) {
            [void]$named.Add(($hit.Value -replace '\\', '/'))
        }
    }
}
Assert-True ($named.Count -ge 40) ("the per-round lanes name suites to compare against (found {0})" -f $named.Count)

# --- What the RELEASE GATE names ------------------------------------------------------------------
# The ruling splits cadence by cost, so a suite may legitimately run only before a tag. That is a
# DECISION, and a decision has to be readable: the release-cadence suites are listed in the open,
# one per line, and this guard treats that list as the second lane. A suite in neither list is in
# neither cadence, which is the state that hid twelve failures.
$manifestPath = Join-Path $repoRoot '.specrew/release-gate-suites.txt'
Assert-True (Test-Path -LiteralPath $manifestPath -PathType Leaf) 'the release-cadence manifest exists'
$releaseNamed = @(Get-Content -LiteralPath $manifestPath -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith('#') })
foreach ($entry in $releaseNamed) { [void]$named.Add(($entry -replace '\\', '/')) }
Assert-True ($releaseNamed.Count -ge 1) ("the release gate names suites too (found {0})" -f $releaseNamed.Count)

# --- What exists on disk -------------------------------------------------------------------------
# The same definition the disk-wide census uses: a test file is one whose name ends in test.ps1 or
# tests.ps1. Fixtures, probes and support scripts under tests/ are not tests and are not required to
# be in a lane - that distinction is the census's, and this check inherits it rather than inventing
# a second one.
$onDisk = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'tests') -Recurse -File -Filter '*.ps1' |
        Where-Object { $_.Name -match '(?i)tests?\.ps1$' } |
        ForEach-Object { ((Resolve-Path -LiteralPath $_.FullName -Relative) -replace '^\.[\\/]', '' -replace '\\', '/') })
Assert-True ($onDisk.Count -ge $named.Count) 'the disk census found at least as many suites as the plan names'

# --- Every suite on disk is named by at least one lane -------------------------------------------
# Exemptions are DECLARED HERE, in the open, each with a reason. An exemption is a decision someone
# can read and argue with; silence is not.
$exempt = @(
    # The census runner itself and the curated registry are RUNNERS, not suites: they execute other
    # files. Naming them in a lane would nest the whole tree inside one lane command.
    'tests/full-powershell-test-sweep.ps1'
    'tests/f198-regression-suite.ps1'
    'tests/f198-iteration006-foundation.ps1'
    'tests/cross-platform-verify.ps1'
)
$unnamed = @($onDisk | Where-Object { -not $named.Contains($_) -and $exempt -notcontains $_ })

Assert-True (@($unnamed).Count -eq 0) ("every test file on disk is named by at least one verification lane{0}" -f $(
    if (@($unnamed).Count -gt 0) {
        "`n  UNNAMED (" + @($unnamed).Count + "): they run in no lane, so nothing would notice them failing:`n    " + (@($unnamed) -join "`n    ") +
        "`n  Add each to a command in .specrew/verification-plan.json, or declare it exempt in this file with a reason."
    } else { '' }))

# --- MUTATION PROOF: a suite written into no lane is detected -------------------------------------
# Without this, the check above could pass because the comparison is broken rather than because the
# lanes are complete - the exact failure mode this whole ruling is about.
$phantom = 'tests/unit/a-suite-nobody-put-in-a-lane.tests.ps1'
$phantomUnnamed = @(@($onDisk + $phantom) | Where-Object { -not $named.Contains($_) -and $exempt -notcontains $_ })
Assert-True (@($phantomUnnamed).Count -eq 1 -and $phantomUnnamed[0] -eq $phantom) 'mutation proof: a suite in no lane is caught by this comparison'

# --- And the plan may not name suites that do not exist ------------------------------------------
# The mirror failure: a lane naming a deleted file runs nothing and reports success for it.
$stale = @($named | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_) -PathType Leaf) })
Assert-True (@($stale).Count -eq 0) ("every suite the lanes name still exists{0}" -f $(
    if (@($stale).Count -gt 0) { "`n  STALE: " + (@($stale) -join ', ') } else { '' }))

Write-Host 'every suite is named by a lane: all assertions pass' -ForegroundColor Green
