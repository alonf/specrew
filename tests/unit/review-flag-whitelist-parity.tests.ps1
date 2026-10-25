[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# THE COUNTERMEASURE THAT WAS RECORDED BUT NEVER WRITTEN (2026-08-17, W20).
#
# scripts/specrew.ps1 carries a comment stating that THIS FILE "now DERIVES the expected set from
# specrew-review.ps1's own parameter aliases, so the next flag is covered by the invariant instead of by
# whoever remembers this line." The file had never existed - no path in the working tree, no entry in git
# history - so the class it was meant to close stayed open behind a comment asserting it was closed.
#
# The class: a flag is added to scripts/specrew-review.ps1 and not to the `review` whitelist in
# scripts/specrew.ps1, so the command the product's own messages tell people to run exits "Unsupported
# argument" and reads as an unimplemented mechanism. Recorded twice (2026-07-09 and 2026-08-12) with a
# hand-enumerated "quartet" test as the first countermeasure - a guard over a hand-written list, which
# cannot see a fifth flag.
#
# Derivation, not enumeration: the aliases on the review script's own parameters ARE the public flag
# names, so this stays true for flags nobody has written yet.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$reviewCli = Join-Path $repoRoot 'scripts\specrew-review.ps1'
$frontDoor = Join-Path $repoRoot 'scripts\specrew.ps1'
Assert-True (Test-Path -LiteralPath $reviewCli -PathType Leaf) 'review script exists'
Assert-True (Test-Path -LiteralPath $frontDoor -PathType Leaf) 'front-door CLI exists'

function Get-ScriptAst {
    param([Parameter(Mandatory)][string]$Text)
    $tokens = $null; $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$tokens, [ref]$parseErrors)
    if ($null -ne $parseErrors -and @($parseErrors).Count -gt 0) { throw "script does not parse: $($parseErrors[0].Message)" }
    return $ast
}

# --- the expected set: every alias declared on the review script's parameters ---
$reviewAst = Get-ScriptAst -Text (Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8)
Assert-True ($null -ne $reviewAst.ParamBlock) 'review script declares a parameter block'
$declaredFlags = [Collections.Generic.List[string]]::new()
foreach ($parameter in @($reviewAst.ParamBlock.Parameters)) {
    foreach ($attribute in @($parameter.Attributes)) {
        if ($attribute.TypeName.GetReflectionAttributeType() -ne [System.Management.Automation.AliasAttribute]) { continue }
        foreach ($argument in @($attribute.PositionalArguments)) {
            if ($argument -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                $declaredFlags.Add([string]$argument.Value) | Out-Null
            }
        }
    }
}
$declaredFlags = @($declaredFlags | Sort-Object -Unique)
Assert-True (@($declaredFlags).Count -ge 15) ("review script declares its public flags as parameter aliases (found {0})" -f @($declaredFlags).Count)
foreach ($known in @('approve-round', 'pause-choice', 'pause-rationale', 'baseline-ref', 'code-writer-host')) {
    Assert-True (@($declaredFlags) -contains $known) "derivation actually sees the flag '$known' the earlier hand-written guard had to be told about"
}

# --- the actual set: the string literals in the front door's `review` whitelist ---
$frontDoorAst = Get-ScriptAst -Text (Get-Content -LiteralPath $frontDoor -Raw -Encoding UTF8)
$reviewWhitelistCalls = @($frontDoorAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.CommandAst] -and
            [string]$node.GetCommandName() -eq 'Assert-OptionArguments' -and
            $node.Extent.Text -match "-CommandName\s+\`$CommandName" -and
            $node.Extent.Text -match '--live'
        }, $true))
Assert-True (@($reviewWhitelistCalls).Count -eq 1) 'the front door has exactly one review-command whitelist to keep in parity'
$whitelisted = @($reviewWhitelistCalls[0].FindAll({
            param($node) $node -is [System.Management.Automation.Language.StringConstantExpressionAst]
        }, $true) | ForEach-Object { [string]$_.Value } | Where-Object { $_ -match '^--' })
Assert-True (@($whitelisted).Count -ge 20) ("the review whitelist enumerates its accepted flags (found {0})" -f @($whitelisted).Count)

# --- the invariant ---
$missing = @($declaredFlags | Where-Object { @($whitelisted) -notcontains ('--' + $_) })
Assert-True (@($missing).Count -eq 0) ("every flag the review script accepts is reachable through the front door consumers are told to run (missing: {0})" -f (@($missing | ForEach-Object { '--' + $_ }) -join ', '))

# MUTATION PROOF: a newly added flag that the front door does not know about must fail this test. Without
# it, the invariant would pass on a file whose derivation silently found nothing.
$mutatedReview = (Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8).Replace(
    "    [Alias('code-writer-host')]",
    "    [Alias('a-brand-new-flag-nobody-whitelisted')]`n    [string]`$BrandNewFlag,`n    [Alias('code-writer-host')]")
Assert-True ($mutatedReview -ne (Get-Content -LiteralPath $reviewCli -Raw -Encoding UTF8)) 'mutation fixture actually adds an un-whitelisted flag'
$mutatedAst = Get-ScriptAst -Text $mutatedReview
$mutatedFlags = [Collections.Generic.List[string]]::new()
foreach ($parameter in @($mutatedAst.ParamBlock.Parameters)) {
    foreach ($attribute in @($parameter.Attributes)) {
        if ($attribute.TypeName.GetReflectionAttributeType() -ne [System.Management.Automation.AliasAttribute]) { continue }
        foreach ($argument in @($attribute.PositionalArguments)) {
            if ($argument -is [System.Management.Automation.Language.StringConstantExpressionAst]) { $mutatedFlags.Add([string]$argument.Value) | Out-Null }
        }
    }
}
$mutatedMissing = @($mutatedFlags | Where-Object { @($whitelisted) -notcontains ('--' + $_) })
Assert-True (@($mutatedMissing).Count -gt 0) 'mutation proof: a flag added to the review script without a front-door entry is caught by this invariant'

Write-Host 'review flag whitelist parity: all assertions pass' -ForegroundColor Green
