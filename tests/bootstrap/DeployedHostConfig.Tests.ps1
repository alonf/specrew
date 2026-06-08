$ErrorActionPreference = 'Stop'

# Closure test (iteration-003 send-back / D-002 evidence-standard fix): read the ACTUAL committed
# self-host hook config ON DISK and assert the SessionEnd handover hook is really deployed - NOT the
# deployer's return object, NOT a scratch project, NOT a dispatcher-direct smoke. This is the
# build != live fix the feature itself targets: a host-hook claim is only true when the deployed
# config on disk carries it. (The scratch-project deployer test in tests/integration/refocus-deploy
# remains - necessary, but it proves the deployer works, not that the real host is deployed.)
$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$claudeCfg = Join-Path $repoRoot '.claude/settings.local.json'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

Assert-True (Test-Path -LiteralPath $claudeCfg) 'self-host .claude/settings.local.json exists on disk'
$cfg = Get-Content -LiteralPath $claudeCfg -Raw | ConvertFrom-Json
Assert-True ($null -ne $cfg.hooks.PSObject.Properties['SessionStart']) 'deployed config carries SessionStart (bootstrap, B1/B2)'
Assert-True ($null -ne $cfg.hooks.PSObject.Properties['SessionEnd']) 'deployed config carries SessionEnd (D-002 handover hook present ON DISK)'
$endCmd = [string]$cfg.hooks.SessionEnd[0].hooks[0].command
Assert-True ($endCmd -match '-Event\s+SessionEnd') 'deployed SessionEnd command dispatches -Event SessionEnd'
Assert-True ($endCmd.Contains('specrew-hook-dispatcher.ps1')) 'deployed SessionEnd command points at the dispatcher'

Write-Host 'DeployedHostConfig: all tests passed.' -ForegroundColor Green
