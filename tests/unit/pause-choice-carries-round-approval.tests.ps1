[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# Beta3 walk regression (2026-08-17, W21): the pause menu offers "1. Fix these and run another review
# round" and tells the human to answer with --pause-choice. Answering 1 could not do what it offered.
#
# TWO COUNTERS, ONE CHECKED. The answer passed the round-BUDGET check (which had room: 1 of 4), was
# written as an immutable pause decision, and the run then died 0.2s later on a spent ALLOWANCE - a
# different resource with no check on this path - reporting the bare token `allowance-exhausted` with no
# sentence and no next action. Measured three times in one session. The third occurrence consumed the
# answer and left the campaign with NO pending pause AND no round run: the exact wedge the stop-here
# ordering in this same file was written to prevent, reachable through the other option.
#
# The fix is the one the file's own philosophy states: approving a round is a decision, not an
# identifier, so choosing "run another round" from the menu IS that decision. The round budget still
# caps it, and options 2 and 3 must keep spending nothing.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$reviewCli = Join-Path $repoRoot 'scripts\specrew-review.ps1'
Assert-True (Test-Path -LiteralPath $reviewCli -PathType Leaf) 'review CLI exists'
$cliText = Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8

function Get-RoundApprovalPredicate {
    # The predicate that decides whether a round approval is being performed, read structurally so this
    # guard describes behaviour rather than a chosen variable spelling.
    param([Parameter(Mandatory)][string]$ScriptText)
    $tokens = $null; $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptText, [ref]$tokens, [ref]$parseErrors)
    if ($null -ne $parseErrors -and @($parseErrors).Count -gt 0) { throw "review CLI does not parse: $($parseErrors[0].Message)" }

    # The mint is the single place a fresh one-slot grant reference is derived.
    $mintAssignments = @($ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                $node.Left.Extent.Text -eq '$campaignGrantAuthorizationRef' -and
                $node.Right.Extent.Text -match 'campaign_id.*round'
            }, $true))
    $conditions = [Collections.Generic.List[string]]::new()
    foreach ($assignment in $mintAssignments) {
        $node = $assignment
        while ($null -ne $node) {
            if ($node -is [System.Management.Automation.Language.IfStatementAst]) {
                foreach ($clause in $node.Clauses) { $conditions.Add([string]$clause.Item1.Extent.Text) | Out-Null }
            }
            $node = $node.Parent
        }
    }
    return [pscustomobject]@{ MintCount = @($mintAssignments).Count; Conditions = $conditions.ToArray() }
}

$mint = Get-RoundApprovalPredicate -ScriptText $cliText
Assert-True ($mint.MintCount -ge 1) 'the CLI still derives a one-slot grant reference when a round is approved'
$mintGuard = @($mint.Conditions) -join ' ; '
Assert-True ($mintGuard -match 'ApproveRound|roundApprovalRequested') 'the mint is still gated on a round approval rather than firing unconditionally'

# The behavioural claim: the predicate that gates the mint must be satisfied by a pause answer of 1.
$approvalPredicateAssignments = @([System.Management.Automation.Language.Parser]::ParseInput($cliText, [ref]$null, [ref]$null).FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
            $node.Right.Extent.Text -match 'ApproveRound' -and
            $node.Right.Extent.Text -match 'PauseChoice' -and
            # The parsed-args literal names both fields too; the PREDICATE is the one that combines them.
            $node.Right.Extent.Text -match '-or' -and $node.Right.Extent.Text -match '-c?in'
        }, $true))
Assert-True (@($approvalPredicateAssignments).Count -ge 1) 'answering the pause with "run another round" is treated as approving that round'
$predicateText = [string]$approvalPredicateAssignments[0].Right.Extent.Text
Assert-True ($predicateText -match "'1'" -and $predicateText -match 'fix-and-continue') 'both spellings the surface accepts for option 1 carry the approval (the number shown and the choice name behind it)'
Assert-True ($predicateText -notmatch "'2'|'3'|stop-here|abandon") 'options that spend nothing are never turned into an approval to spend'

# The cap must still be the round budget, checked before any answer is consumed.
Assert-True ($cliText -match 'budget_exhausted') 'the round budget still gates fix-and-continue'
# Scoped to the pause-answer region: an unrelated decision-fact call exists earlier in the allowance-reset
# path, so a whole-file first-index comparison would compare the wrong two things.
$pauseRegionStart = $cliText.IndexOf('$pauseAnswer = [string]$parsedArgs.PauseChoice')
$budgetIndex = $cliText.IndexOf('budget_exhausted', $pauseRegionStart)
Assert-True ($pauseRegionStart -gt 0 -and $budgetIndex -gt $pauseRegionStart) 'the round-budget check lives inside the pause-answer path'
$decisionBeforeBudget = $cliText.IndexOf('New-ReviewCampaignPauseDecisionFact', $pauseRegionStart)
Assert-True ($decisionBeforeBudget -gt $budgetIndex) 'the budget refusal still precedes constructing the immutable pause decision, so a capped attempt consumes no answer'

# MUTATION PROOF: drop option 1 from the approval predicate and the guard must fail.
$mutated = $cliText.Replace("([string]`$parsedArgs.PauseChoice -cin @('1', 'fix-and-continue'))", '$false')
Assert-True ($mutated -ne $cliText) 'mutation fixture actually removes option 1 from the approval predicate'
$mutatedAssignments = @([System.Management.Automation.Language.Parser]::ParseInput($mutated, [ref]$null, [ref]$null).FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
            $node.Right.Extent.Text -match 'ApproveRound' -and
            $node.Right.Extent.Text -match 'PauseChoice' -and
            # The parsed-args literal names both fields too; the PREDICATE is the one that combines them.
            $node.Right.Extent.Text -match '-or' -and $node.Right.Extent.Text -match '-c?in'
        }, $true))
Assert-True (@($mutatedAssignments).Count -eq 0) 'mutation proof: removing option 1 from the approval predicate is detected by this guard'

Write-Host 'pause choice carries round approval: all assertions pass' -ForegroundColor Green
