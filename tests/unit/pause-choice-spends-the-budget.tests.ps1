[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# Beta3 walk regression (2026-08-17, W21), restated by feature 203 T008 (FR-004, FR-010): the pause menu offers
# "1. Fix these and run another review round". In beta3 answering 1 died on a spent allowance that nothing on the path
# checked; the fix then made option 1 a round approval. T008 removed the per-round approval: the review budget approved
# with the implementation pays for the round, so option 1 needs no approval of its own and must not ask for one. The
# budget still caps it, checked before any answer is consumed, and options 2 and 3 spend nothing.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$reviewCli = Join-Path $repoRoot 'scripts\specrew-review.ps1'
Assert-True (Test-Path -LiteralPath $reviewCli -PathType Leaf) 'review CLI exists'
$cliText = Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8
$cliAst = [System.Management.Automation.Language.Parser]::ParseInput($cliText, [ref]$null, [ref]$null)

# No path mints a round reference or captures a round approval any more.
$mints = @($cliAst.FindAll({ param($node) $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Right.Extent.Text -match 'campaign_id.*-round-' }, $true))
Assert-True ($mints.Count -eq 0) 'the CLI derives no per-round grant reference'
Assert-True ($cliText -notmatch 'Get-SpecrewReviewRoundApprovalAuthorization|roundApprovalRequested') 'no pause answer is turned into a round approval, because none exists'

# The cap is the round budget, checked inside the pause-answer path before the immutable answer is built.
$pauseRegionStart = $cliText.IndexOf('$pauseAnswer = [string]$parsedArgs.PauseChoice')
$budgetIndex = $cliText.IndexOf('continuation_available', $pauseRegionStart)
Assert-True ($pauseRegionStart -gt 0 -and $budgetIndex -gt $pauseRegionStart) 'the round-budget check lives inside the pause-answer path'
$decisionBeforeBudget = $cliText.IndexOf('New-ReviewCampaignPauseDecisionFact', $pauseRegionStart)
Assert-True ($decisionBeforeBudget -gt $budgetIndex) 'the budget refusal precedes constructing the immutable pause decision, so a capped attempt consumes no answer'
$budgetGate = [regex]::Match($cliText.Substring($pauseRegionStart), "(?s)if \(\`$choice -ceq 'fix-and-continue'\) \{.{0,1500}?continuation_available").Value
Assert-True (-not [string]::IsNullOrWhiteSpace($budgetGate)) 'only the answer that runs a round meets the budget gate; stopping and abandoning spend nothing'

# --- Round-13 findings (DRIFT-199-I001-122), pinned structurally where the behavior lives ---

# F2: the clean-round early exit speaks in the present tense ("covers your files as they are now"),
# so it must consult the PRESENT tree - currentness and can_approve_current are ingest-time facts,
# true when the result landed and silent about every source edit since.
$r13RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$r13CliText = Get-Content -LiteralPath (Join-Path $r13RepoRoot 'scripts\specrew-review.ps1') -Raw -Encoding UTF8
$r13Shortcut = [regex]::Match($r13CliText, '(?s)\$cleanShortcutHolds = \$false.{0,2500}?if \(\$cleanShortcutHolds\)').Value
Assert-True (-not [string]::IsNullOrWhiteSpace($r13Shortcut)) 'the clean-round early exit guards itself before speaking in the present tense'
Assert-True ($r13Shortcut.Contains('Get-ContinuousCoReviewReviewedStateDigest')) 'the shortcut recomputes the current tree, not the ingest-time currentness'
Assert-True ($r13Shortcut.Contains('target_digest')) 'the recomputed tree is compared against the tree the clean result actually covered'

# F4: every stop-here attempt writes transport evidence under the system temp path; the finally that
# disposes the snapshot must dispose the attempt directory too, or attempts accumulate forever.
$r13OrchText = Get-Content -LiteralPath (Join-Path $r13RepoRoot 'scripts\internal\continuous-co-review\review-campaign-orchestrator.ps1') -Raw -Encoding UTF8
$r13Finally = [regex]::Match($r13OrchText, '(?s)specrew-stop-here-evidence.{0,5000}?finally \{.{0,3500}?Remove-GitReviewTargetSnapshot.{0,3000}?\n            \}').Value
Assert-True (-not [string]::IsNullOrWhiteSpace($r13Finally)) 'the stop-here verification finally block exists to check'
Assert-True ($r13Finally.Contains('$evidenceDirectory')) 'the finally disposes the attempt evidence directory, not only the git snapshot'

Write-Host 'pause choice spends the budget: all assertions pass' -ForegroundColor Green
