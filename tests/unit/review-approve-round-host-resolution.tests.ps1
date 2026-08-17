[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# Beta3 walk regression (2026-08-17, W19): `specrew review --live --approve-round` died at the harness
# preflight with `unselected-harness`, whose consumer text asserts "No reviewer has been chosen for this
# project yet" - at a project whose .specrew/reviewer-hosts.json had copilot allowed, authorized, and
# running clean rounds minutes earlier. One guard was doing two jobs: skipping the configured-reviewer
# block under --approve-round correctly stops a SPENT authorization reference from pre-empting a fresh
# approval, but that block is also the ONLY place the reviewer HOST is resolved from the project config.
# Approving a round must not re-ask which reviewer to use.
#
# This is asserted structurally because the behavioural path ends in a real reviewer invocation that
# costs a round. The mutation proof at the bottom is what keeps the guard honest.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$reviewCli = Join-Path $repoRoot 'scripts\specrew-review.ps1'
Assert-True (Test-Path -LiteralPath $reviewCli -PathType Leaf) 'public review CLI exists'

function Get-HostResolutionGuardConditions {
    # Returns the enclosing `if` conditions of every assignment that resolves the campaign host from the
    # configured reviewer. Structure, not text matching: the defect was a CONDITION, so the condition is
    # what gets read.
    param([Parameter(Mandatory)][string]$ScriptText)

    $tokens = $null; $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptText, [ref]$tokens, [ref]$parseErrors)
    if ($null -ne $parseErrors -and @($parseErrors).Count -gt 0) { throw "review CLI does not parse: $($parseErrors[0].Message)" }

    $assignments = @($ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                $node.Left.Extent.Text -eq '$campaignHost' -and
                $node.Right.Extent.Text -match 'configuredReviewer\.host'
            }, $true))

    $conditions = [Collections.Generic.List[string]]::new()
    foreach ($assignment in $assignments) {
        $node = $assignment
        while ($null -ne $node) {
            if ($node -is [System.Management.Automation.Language.IfStatementAst]) {
                foreach ($clause in $node.Clauses) { $conditions.Add([string]$clause.Item1.Extent.Text) | Out-Null }
            }
            $node = $node.Parent
        }
    }
    return [pscustomobject]@{
        AssignmentCount = @($assignments).Count
        Conditions      = $conditions.ToArray()
    }
}

$shipped = Get-HostResolutionGuardConditions -ScriptText (Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8)
Assert-True ($shipped.AssignmentCount -ge 1) 'the CLI still resolves the campaign host from the configured reviewer'
$approveGated = @($shipped.Conditions | Where-Object { $_ -match 'ApproveRound' })
Assert-True ($approveGated.Count -eq 0) 'host resolution is never gated on --approve-round: approving a round does not re-ask which reviewer to use'

# The reference half MUST stay gated: that is the property the original guard existed to protect, and
# dropping it would let a spent reference silently satisfy a fresh approval.
$tokens = $null; $parseErrors = $null
$cliAst = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8), [ref]$tokens, [ref]$parseErrors)
$refAssignments = @($cliAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
            $node.Left.Extent.Text -eq '$campaignGrantAuthorizationRef' -and
            $node.Right.Extent.Text -match 'configuredReviewer\.authorization_ref'
        }, $true))
Assert-True (@($refAssignments).Count -ge 1) 'the CLI still reads a configured authorization reference when one applies'
$refGuarded = $false
foreach ($assignment in $refAssignments) {
    $node = $assignment
    while ($null -ne $node) {
        if ($node -is [System.Management.Automation.Language.IfStatementAst]) {
            foreach ($clause in $node.Clauses) { if ([string]$clause.Item1.Extent.Text -match 'ApproveRound') { $refGuarded = $true } }
        }
        $node = $node.Parent
    }
}
Assert-True $refGuarded 'a recorded authorization reference is still never taken while --approve-round is performing the decision now'

# MUTATION PROOF: reintroduce the original coupling and the guard must fail. Without this the assertions
# above pass for a file that no longer contains the code they claim to describe.
$mutated = (Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8).Replace(
    'if ([string]::IsNullOrWhiteSpace($campaignGrantAuthorizationRef)) {',
    'if ([string]::IsNullOrWhiteSpace($campaignGrantAuthorizationRef) -and -not [bool]$parsedArgs.ApproveRound) {')
Assert-True ($mutated -ne (Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8)) 'mutation fixture actually reintroduces the coupled guard'
$mutatedResult = Get-HostResolutionGuardConditions -ScriptText $mutated
$mutatedGated = @($mutatedResult.Conditions | Where-Object { $_ -match 'ApproveRound' })
Assert-True ($mutatedGated.Count -gt 0) 'mutation proof: recoupling host resolution to --approve-round is detected by this guard'

# The consumer-facing text that fired on this defect must not assert a cause it has not established.
$cliText = Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8
$noReviewerLine = @($cliText -split "`r?`n" | Where-Object { $_ -match 'No reviewer has been chosen' })
Assert-True (@($noReviewerLine).Count -ge 1) 'the no-reviewer setup guidance is still present for the case it was written for'

Write-Host 'review approve-round host resolution: all assertions pass' -ForegroundColor Green
