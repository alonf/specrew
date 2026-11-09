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

# Feature 203 T008 (maintainer classification 2026-11-09, class A; the 2026-11-09 mapping removed option 1 and
# fix-and-continue): no pause answer can start a round any more, so the budget is not checked inside the pause-answer
# path - it is checked once, at every launch, before anything is reserved. What stays: an answer that is not
# `stop-here` is refused before anything is read or built, so a retired answer consumes nothing.
$pauseBlock = @($cliAst.FindAll({ param($node) $node -is [System.Management.Automation.Language.IfStatementAst] -and
            $node.Clauses.Count -gt 0 -and $node.Clauses[0].Item1.Extent.Text -match '^\-not \[string\]::IsNullOrWhiteSpace\(\$pauseAnswer\)$' }, $true)) | Select-Object -First 1
Assert-True ($null -ne $pauseBlock) 'the pause-answer path is found'
$pauseText = $pauseBlock.Extent.Text
Assert-True ($pauseText -notmatch 'Invoke-ReviewCampaignCommand|Invoke-ReviewCampaignRun|continuation_available') 'no pause answer starts a round or meets the budget gate'
$retiredAt = $pauseText.IndexOf("if ([string]`$pauseAnswer -cne 'stop-here')")
Assert-True ($retiredAt -gt 0) 'an answer that is not stop-here is refused'
Assert-True ($retiredAt -lt $pauseText.IndexOf('Resolve-ReviewCampaignPublicIdentity') -and $retiredAt -lt $pauseText.IndexOf('New-ReviewCampaignPauseDecisionFact')) 'the refusal comes before anything is read or built, so a retired answer consumes nothing'
$orchText = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\internal\continuous-co-review\review-campaign-orchestrator.ps1') -Raw -Encoding UTF8
$commandText = [regex]::Match($orchText, '(?s)function Invoke-ReviewCampaignCommand \{.*?\n\}').Value
Assert-True (-not [string]::IsNullOrWhiteSpace($commandText)) 'the launch command is found'
$gateAt = $commandText.IndexOf('THE BUDGET GATE, for every launch')
Assert-True ($gateAt -gt 0 -and $gateAt -lt $commandText.IndexOf('Invoke-ReviewCampaignRun ')) 'the budget gate runs at every launch, before the run that reserves anything'

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
