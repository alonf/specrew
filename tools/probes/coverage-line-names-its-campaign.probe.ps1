# RELOCATED OUT OF tests/ 2026-09-02 - THIS IS A DEVELOPER PROBE, NOT A TEST (DRIFT-199-I003-025).
#
# It measures THIS REPOSITORY'S LIVE INSTANCE. It reads `.specrew/start-context.json` and whatever review
# campaigns are on disk - both GITIGNORED runtime state - and its no-campaign-yet case depends on the
# ambient coincidence that the active iteration differs from the campaign's.
#
# CONSEQUENCE, and it is why it moved: in a fresh clone `Get-SpecrewReviewCoverageState` answers
# available=$false, the coverage line comes back empty, and this file fails on its first assertion. It
# could NEVER have passed in a clean checkout, so it was never a test of the code - it was a probe of a
# developer's working tree, misfiled under tests/.
#
# It stayed invisible because the curated lanes never named it and the full-tree census - the only reader
# that would have run it - was not run until 2026-08-31.
#
# THE GATE WAS NOT WEAKENED TO ACCOMMODATE THIS. Per-file census exclusion was explicitly refused
# (maintainer, 2026-09-02): the census is all-or-nothing and the publish depends on it, so an exclusion
# list would carve a hole in the only reader that looks at the whole tree. An exclusion says "this test
# may fail"; this relocation says "this was never a test". The census keeps its every-test-on-disk promise
# honestly, because this file is no longer on that disk.
#
# HOW TO RUN IT: by hand, from a working developer checkout that has live review campaigns:
#   pwsh -NoProfile -File tools/probes/coverage-line-names-its-campaign.probe.ps1
# It will fail in a fresh clone, and that is correct behaviour, not a regression.
#
# The property it probes - T025 / DRIFT-199-I002-006, that a figure in a decision slot names the campaign
# it was read from - still deserves a real test built on a synthesized campaign fixture. That needs the
# campaign-budget record subsystem fixtured (Get-ReviewCampaignRoundBudgetState), which is a beta4 item,
# NOT a reason to keep a probe in the gate's subject set.
# Iteration 002, T025 (DRIFT-199-I002-006): the figure in a decision slot must be the figure that governs
# the decision.
#
# Field case, 2026-08-29: the plan boundary packet reported "1 of 4 rounds remaining" - iteration 001's
# CLOSED campaign - in the same message whose own measurement said iteration 002's covering round runs under
# its own campaign with a fresh allowance. The maintainer formed the one-iteration-versus-split ruling partly
# on that scarcity before the measurement corrected it. Same family as the refusal standard: a number in the
# decision slot with no instance attached to it.
#
# The maintainer's condition for fixing it here rather than in beta4: it must be naming-and-scope, not
# campaign-SELECTION logic - "the test is whether the fix changes what the function computes or only what it
# says". It changes only what it says: campaign_id was already in the coverage state and the active iteration
# was already in session_state.
#
# Mutations that turn this file red: drop the campaign suffix from the line (case 1); drop the
# no-campaign-yet clause (case 2); start selecting a different campaign (case 3 - the rounds figure itself
# would move, which is the line this fix must not cross).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

Write-Host 'Case 1: the live line names the campaign its figure belongs to'
$line = Get-SpecrewReviewCoverageLine -ProjectRoot $repoRoot
Assert-True (-not [string]::IsNullOrWhiteSpace($line)) 'this repository produces a coverage line'
Assert-True ($line -match 'rounds remaining in campaign cmp-') 'the rounds figure is attached to the campaign it was read from'

Write-Host 'Case 2: when the ACTIVE iteration has no campaign, the line says so'
# This repository is the live instance of exactly that shape: iteration 002 is active, and the only campaign
# on record belongs to iteration 001, which is closed.
$activeIteration = ''
$ctx = Get-Content -LiteralPath (Join-Path $repoRoot '.specrew/start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($null -ne $ctx.session_state) { $activeIteration = [string]$ctx.session_state.iteration_number }
$campaignIteration = if ($line -match 'campaign cmp-[a-z0-9-]+-i(?<n>\d+)') { $Matches['n'] } else { '' }
if (-not [string]::IsNullOrWhiteSpace($activeIteration) -and -not [string]::IsNullOrWhiteSpace($campaignIteration) -and
    $campaignIteration.TrimStart('0') -ne $activeIteration.TrimStart('0')) {
    Assert-True ($line -match ("iteration {0} has no campaign yet" -f $activeIteration)) 'the line names the ACTIVE iteration and says it has no campaign yet'
    Assert-True ($line -match 'fresh allowance') 'and that it therefore starts with a fresh allowance - the fact the decision actually needed'
}
else {
    # The active iteration owns the campaign: the line must NOT claim a fresh allowance it does not have.
    Assert-True ($line -notmatch 'has no campaign yet') 'when the active iteration owns the campaign, no fresh-allowance claim is made'
    Write-Pass 'the no-campaign-yet clause is correctly silent for this state'
}

Write-Host 'Case 3: labelling only - the rounds figure itself is unchanged'
$state = Get-SpecrewReviewCoverageState -ProjectRoot $repoRoot
$expectedRemaining = [Math]::Max(0, [int]$state.budget_total - [int]$state.rounds_used)
Assert-True ($line -match ("{0} of {1} rounds remaining" -f $expectedRemaining, [int]$state.budget_total)) 'the figure is exactly what the budget state computes - the fix changed what the line SAYS, not what it selects'
Assert-True ($line -match ('campaign ' + [regex]::Escape([string]$state.campaign_id))) 'and it names the campaign the state itself resolved, not one this line chose'

Write-Host 'Case 4: the rest of the coverage sentence is untouched'
Assert-True ($line -match 'Review coverage: last delivered review .+ covered tree [0-9a-f]{8}; \d+ source file\(s\) changed since;') 'the delivered-run, covered-tree and drift-count clauses are unchanged'

if ($script:failCount -gt 0) { throw ("coverage-line-names-its-campaign: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'coverage-line-names-its-campaign: all assertions passed' -ForegroundColor Green
