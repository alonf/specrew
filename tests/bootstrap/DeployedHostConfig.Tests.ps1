$ErrorActionPreference = 'Stop'

# Closure test (iter-003 send-back evidence floor, iter-4 pivot): read the ACTUAL committed self-host
# hook config ON DISK and assert the iter-4 Stop handover hook is really deployed AND the superseded
# SessionEnd hook is really GONE - NOT the deployer's return object, NOT a scratch project, NOT a
# dispatcher-direct smoke. A host-hook claim is only true when the deployed config on disk carries it;
# removing a hook in deployer CODE does not remove it on disk without a re-deploy (build != live, in
# reverse). (The scratch deployer test in tests/integration/refocus-deploy remains - necessary, not sufficient.)
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
Assert-True ($null -eq $cfg.hooks.PSObject.Properties['SessionEnd']) 'SessionEnd hook is ABSENT on disk (iter-4 removed it; build != live in reverse)'
Assert-True ($null -ne $cfg.hooks.PSObject.Properties['Stop']) 'deployed config carries the Stop handover hook ON DISK (iter-4 rolling handover)'
$stopCmd = [string]$cfg.hooks.Stop[0].hooks[0].command
Assert-True ($stopCmd -match '-Event\s+Stop') 'deployed Stop command dispatches -Event Stop'
Assert-True ($stopCmd.Contains('specrew-hook-dispatcher.ps1')) 'deployed Stop command points at the dispatcher'

Write-Host 'DeployedHostConfig: all tests passed.' -ForegroundColor Green
