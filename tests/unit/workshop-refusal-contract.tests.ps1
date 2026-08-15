[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Test-AgendaRefusalCoverage {
    param([Parameter(Mandatory)][string]$SourceText)
    $tokens = $null
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput($SourceText, [ref]$tokens, [ref]$errors)
    if (@($errors).Count -gt 0) { return $false }
    $actionable = @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.ThrowStatementAst] -and
        $node.Extent.Text -match '(?i)render|wait|repair|retry|run|write|overwrite|clear|confirm'
    }, $true))
    if ($actionable.Count -lt 7) { return $false }
    return (@($actionable | Where-Object { $_.Extent.Text -notmatch 'New-SpecrewWorkshopAgendaRefusal' }).Count -eq 0)
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$agendaPath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1'
$providerPath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
$authorityPath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
$agenda = Get-Content -LiteralPath $agendaPath -Raw -Encoding UTF8
$provider = Get-Content -LiteralPath $providerPath -Raw -Encoding UTF8
$authority = Get-Content -LiteralPath $authorityPath -Raw -Encoding UTF8

Assert-True (Test-AgendaRefusalCoverage -SourceText $agenda) 'every discovered actionable agenda refusal uses the convergent refusal contract'
Assert-True ($authority -match '(?i)do not retry again' -and $authority -match '(?i)Never write lens-applicability\.json or any governed controller state by hand') 'canonical workshop refusal contract carries terminal escalation and the controller-write prohibition'
Assert-True ($provider -match '(?is)workshop-repair.*Get-SpecrewWorkshopRefusalContractText') 'provider workshop-repair surfaces append the same convergent refusal contract'
foreach ($reason in @('workshop-agenda-selected-entry-invalid','workshop-agenda-skipped-entry-invalid','workshop-agenda-digest-mismatch')) {
    Assert-True ($provider -match [regex]::Escape($reason)) "provider consumes strict controller failure '$reason' as a targeted repair"
}

$mutation = [regex]::Replace($agenda, 'New-SpecrewWorkshopAgendaRefusal', 'New-RemovedRefusalHelper', 1)
Assert-True (-not (Test-AgendaRefusalCoverage -SourceText $mutation)) 'mutation proof: bypassing the refusal helper makes the derived AST guard fail'

Write-Host 'workshop refusal contract: all assertions pass' -ForegroundColor Green
