[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-LaneScript {
    param(
        [string]$ScriptPath,
        [string]$Label
    )

    Write-Host ("Running contract lane check: {0}" -f $Label) -ForegroundColor Cyan
    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath 2>&1)
    if ($LASTEXITCODE -ne 0) {
        foreach ($line in $output) {
            Write-Host $line
        }

        Write-Host ("FAIL: Contract lane check failed: {0}" -f $Label) -ForegroundColor Red
        exit 1
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$scriptMap = [ordered]@{
    'start command'            = Join-Path $repoRoot 'tests\integration\start-command.ps1'
    'review replay'            = Join-Path $repoRoot 'tests\integration\review-command.ps1'
    'lifecycle trace contract' = Join-Path $repoRoot 'tests\integration\lifecycle-trace-contract.ps1'
    'handoff governance jargon response' = Join-Path $repoRoot 'tests\integration\handoff-governance-jargon-response-test.ps1'
    'handoff governance plain-language response' = Join-Path $repoRoot 'tests\integration\handoff-governance-plain-language-response-test.ps1'
    'handoff governance review-file reference' = Join-Path $repoRoot 'tests\integration\handoff-governance-review-file-reference-test.ps1'
}

foreach ($label in $scriptMap.Keys) {
    $scriptPath = $scriptMap[$label]
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        Write-Host ("FAIL: Missing contract lane script: {0}" -f $scriptPath) -ForegroundColor Red
        exit 1
    }

    Invoke-LaneScript -ScriptPath $scriptPath -Label $label
}

Write-Host 'PASS: Contract validation lane checks passed' -ForegroundColor Green
exit 0
