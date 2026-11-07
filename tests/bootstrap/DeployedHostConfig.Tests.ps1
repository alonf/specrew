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
# Feature 203 T002 follow-up (DRIFT-016): the deployed command runs the project's generated launcher, which holds the
# dispatcher call, so the command line no longer names the dispatcher. Found by T006's sweep (DRIFT-046): this check had
# been red since then, outside every lane. What the hook runs is the command plus the launcher it names.
function Get-HookDispatch {
    param([string]$Decoded)
    $launcher = [regex]::Match($Decoded, 'Join-Path \$projectRoot ''([^'']+specrew-hook-launch\.ps1)''')
    if (-not $launcher.Success) { return $Decoded }
    $path = Join-Path $repoRoot $launcher.Groups[1].Value
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) ("the launcher the hook names is on disk: {0}" -f $launcher.Groups[1].Value)
    return ($Decoded + "`n" + (Get-Content -LiteralPath $path -Raw))
}

Assert-True (Test-Path -LiteralPath $claudeCfg) 'self-host .claude/settings.local.json exists on disk'
$cfg = Get-Content -LiteralPath $claudeCfg -Raw | ConvertFrom-Json
Assert-True ($null -ne $cfg.hooks.PSObject.Properties['SessionStart']) 'deployed config carries SessionStart (bootstrap, B1/B2)'
Assert-True ($null -eq $cfg.hooks.PSObject.Properties['SessionEnd']) 'SessionEnd hook is ABSENT on disk (iter-4 removed it; build != live in reverse)'
Assert-True ($null -ne $cfg.hooks.PSObject.Properties['Stop']) 'deployed config carries the Stop handover hook ON DISK (iter-4 rolling handover)'
$stopCmd = [string]$cfg.hooks.Stop[0].hooks[0].command
# The deployed hook now passes its script through -EncodedCommand (base64 UTF-16LE), so the
# dispatch arguments are no longer literal text in the command line. Decode before asserting -
# the property under test is what the hook DOES, not how the argument happens to be spelled. A
# grep-only pin went red the day the deployment changed shape, outside every verification lane.
$stopDispatch = $stopCmd
$encoded = [regex]::Match($stopCmd, '-EncodedCommand\s+([A-Za-z0-9+/=]+)')
if ($encoded.Success) {
    $stopDispatch = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encoded.Groups[1].Value))
}
Assert-True ($stopDispatch -match "-Event\s+'?Stop'?\b") 'deployed Stop command dispatches -Event Stop'
Assert-True ((Get-HookDispatch $stopDispatch).Contains('specrew-hook-dispatcher.ps1')) 'deployed Stop command points at the dispatcher'

# iter-9.1/iter-10 closure: the PostToolUse hook (mid-turn handover refresh during picker phases like the
# design workshop, where no end-of-turn Stop fires) must be live ON DISK, not just in the deployer code. The
# external review found the live claude config was missing it (build != live) - this guards the re-deploy.
Assert-True ($null -ne $cfg.hooks.PSObject.Properties['PostToolUse']) 'deployed config carries the PostToolUse handover-refresh hook ON DISK (iter-9.1 mid-turn refresh)'
$postCmd = [string]$cfg.hooks.PostToolUse[0].hooks[0].command
$postDispatch = $postCmd
$postEncoded = [regex]::Match($postCmd, '-EncodedCommand\s+([A-Za-z0-9+/=]+)')
if ($postEncoded.Success) {
    $postDispatch = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($postEncoded.Groups[1].Value))
}
Assert-True ($postDispatch -match "-Event\s+'?PostToolUse'?\b") 'deployed PostToolUse command dispatches -Event PostToolUse'
Assert-True ((Get-HookDispatch $postDispatch).Contains('specrew-hook-dispatcher.ps1')) 'deployed PostToolUse command points at the dispatcher'

Write-Host 'DeployedHostConfig: all tests passed.' -ForegroundColor Green
