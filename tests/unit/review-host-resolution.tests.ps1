[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# Beta3 walk regression (2026-08-17, W19): `specrew review --live --approve-round` died at the harness preflight with
# `unselected-harness` ("No reviewer has been chosen for this project yet") at a project whose reviewer-hosts.json had a
# host allowed and authorized: the only place the host was resolved from the project config was skipped whenever a round
# was being approved. Feature 203 T008 (FR-010) removed the per-round approval, and with it the reason for the skip: the
# configured host is resolved for every run, and its recorded authorization reference is the host's, never a round's.
#
# Asserted structurally because the behavioural path ends in a real reviewer invocation. The mutation proof at the
# bottom keeps the guard honest.

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

$cliText = Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8
$shipped = Get-HostResolutionGuardConditions -ScriptText $cliText
Assert-True ($shipped.AssignmentCount -ge 1) 'the CLI still resolves the campaign host from the configured reviewer'
$approvalGates = @($shipped.Conditions | Where-Object { $_ -match 'ApproveRound|roundApproval|AuthorizationRef|PauseChoice' })
Assert-True ($approvalGates.Count -eq 0) 'host resolution is never gated on an approval or a reference: every run resolves the configured reviewer'

# The reference on file buys nothing: no assignment carries a configured authorization_ref into a launch.
$cliAst = [System.Management.Automation.Language.Parser]::ParseInput($cliText, [ref]$null, [ref]$null)
$refAssignments = @($cliAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
            $node.Right.Extent.Text -match 'configuredReviewer\.authorization_ref'
        }, $true))
Assert-True (@($refAssignments).Count -eq 0) 'a recorded authorization reference is never read as a round''s authority'
$launch = [regex]::Match($cliText, '(?s)\$campaignRun = Invoke-ReviewCampaignCommand.{0,800}?-ProgressSink \$progressSink').Value
Assert-True (-not [string]::IsNullOrWhiteSpace($launch)) 'the campaign launch exists to check'
Assert-True ($launch -notmatch 'GrantAuthorizationRef') 'the launch passes no grant reference: the review budget is its authority'

# MUTATION PROOF: gate host resolution on something else again and the guard must fail.
$mutated = $cliText.Replace(
    'if ($null -ne $configuredReviewer -and [string]::IsNullOrWhiteSpace($campaignHost)) {',
    'if ($null -ne $configuredReviewer -and [string]::IsNullOrWhiteSpace($campaignHost) -and [string]::IsNullOrWhiteSpace([string]$parsedArgs.AuthorizationRef)) {')
Assert-True ($mutated -ne $cliText) 'mutation fixture actually adds a gate'
$mutatedResult = Get-HostResolutionGuardConditions -ScriptText $mutated
$mutatedGated = @($mutatedResult.Conditions | Where-Object { $_ -match 'ApproveRound|roundApproval|AuthorizationRef|PauseChoice' })
Assert-True ($mutatedGated.Count -gt 0) 'mutation proof: an added gate on host resolution is detected by this guard'

# The consumer-facing text that fired on this defect must not assert a cause it has not established.
$cliText = Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8
$noReviewerLine = @($cliText -split "`r?`n" | Where-Object { $_ -match 'No reviewer has been chosen' })
Assert-True (@($noReviewerLine).Count -ge 1) 'the no-reviewer setup guidance is still present for the case it was written for'

Write-Host 'review host resolution: all assertions pass' -ForegroundColor Green
