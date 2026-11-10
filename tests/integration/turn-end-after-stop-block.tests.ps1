# Feature 203 T011 (DRIFT-054; maintainer rulings 2026-11-10): A REPLY THAT FOLLOWS A STOP-HOOK BLOCK IS RECORDED AS A TURN END.
#
# The conformance provider judged the turn's declaration, used up its token and stepped the turn counter as soon as it
# did not block itself. A Stop check that runs in the same Stop and blocks - the co-review navigator after it, or any
# check - then force-continued a turn that had no token left: the reply to the block could not be declared ("matches no
# live session"), and its own Stop counted it as an undeclared turn, so the counter skipped (DRIFT-054: 1 to 3, then 3
# to 5). The ruling: a rule about ORDERING, not a navigator special case - a turn's token is used up, and its counter
# stepped, only after every check in that Stop has passed. Each Stop also leaves one history line (the record DRIFT-054
# found missing).
#
# Through the real dispatcher with a deployed copy of the repo's scripts and registry, the path a host takes. The block
# comes from a fixture check, placed once after the conformance provider (order 50) and once before it (order 35), so a
# fix that knows only one provider cannot pass.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host ("  PASS: {0}" -f $Message) }
    else { Write-Host ("  FAIL: {0}" -f $Message); $script:Failures++ }
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$priorProfilePath = $env:SPECREW_USER_PROFILE_PATH
$env:SPECREW_USER_PROFILE_PATH = Join-Path ([IO.Path]::GetTempPath()) ('no-profile-' + [guid]::NewGuid().ToString('N') + '.yml')
$store = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/turn-end-store.ps1'
$declarer = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/declare-turn-end.ps1'
$registry = Join-Path $repoRoot 'extensions/specrew-speckit/refocus-scopes.json'
. $store

function Invoke-Declare {
    param([string[]]$Arguments)
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    foreach ($a in @('-NoProfile', '-File', $declarer) + $Arguments) { $psi.ArgumentList.Add($a) }
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $out = $proc.StandardOutput.ReadToEnd(); $err = $proc.StandardError.ReadToEnd(); $proc.WaitForExit()
    return [pscustomobject]@{ Code = $proc.ExitCode; Out = $out; Err = $err }
}

# A scratch project whose deployed registry carries a fixture Stop check at -GateOrder, blocking while its flag exists.
function New-GatedProject {
    param([int]$GateOrder)
    $root = Join-Path ([IO.Path]::GetTempPath()) ('teasb-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
    $deployed = Join-Path $root '.specify/extensions/specrew-speckit'
    New-Item -ItemType Directory -Path $deployed -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/scripts') -Destination (Join-Path $deployed 'scripts') -Recurse -Force
    $catalog = Get-Content -LiteralPath $registry -Raw -Encoding UTF8 | ConvertFrom-Json
    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($row in @($catalog.providers)) { if ([string]$row.id -ne 'co-review-navigator') { $rows.Add($row) } }
    $rows.Add([pscustomobject]@{ id = 'fixture-gate'; kind = 'inject'; events = @('Stop'); order = $GateOrder; budget_share = 0.1; command = 'fixture-gate.ps1' })
    $catalog.providers = $rows.ToArray()
    [IO.File]::WriteAllText((Join-Path $deployed 'refocus-scopes.json'), ($catalog | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    $gate = @'
param()
$flag = Join-Path (Get-Location).Path '.specrew/runtime/fixture-gate-block'
if (Test-Path -LiteralPath $flag) { [Console]::Out.Write("<<<SPECREW-STOP-BLOCK>>>`nA fixture check blocks this Stop: answer it, then stop again.") }
exit 0
'@
    [IO.File]::WriteAllText((Join-Path $deployed 'scripts/fixture-gate.ps1'), $gate, [Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Root = $root; Dispatcher = (Join-Path $deployed 'scripts/specrew-hook-dispatcher.ps1') }
}

function Invoke-Dispatch {
    param([pscustomobject]$Project, [string]$Event, [hashtable]$EventFields)
    $json = ($EventFields | ConvertTo-Json -Compress)
    Push-Location $Project.Root
    try { return (& pwsh -NoProfile -File $Project.Dispatcher -Event $Event -HostKind 'claude' -EventJson $json 2>&1 | Out-String) }
    finally { Pop-Location }
}

function Get-History {
    param([string]$StateRoot)
    $path = Join-Path $StateRoot 'turn-history.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    return @(Get-Content -LiteralPath $path -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
}

$projects = [System.Collections.Generic.List[string]]::new()
try {
    foreach ($case in @(@{ Name = 'a later check (order 50)'; Order = 50 }, @{ Name = 'an earlier check (order 35)'; Order = 35 })) {
        Write-Host ("  --- a Stop blocked by {0} ---" -f $case.Name)
        $project = New-GatedProject -GateOrder $case.Order
        $projects.Add($project.Root)
        $session = 'S11-' + $case.Order
        $paths = Get-SpecrewTurnEndPaths -ProjectRoot $project.Root -HostKind 'claude' -SessionId $session

        $null = Invoke-Dispatch -Project $project -Event 'UserPromptSubmit' -EventFields @{ session_id = $session; prompt = 'hello' }
        $token = Read-SpecrewTurnToken -StateRoot $paths.StateRoot
        $turnBefore = Get-SpecrewTurnId -StateRoot $paths.StateRoot
        Assert-True (-not [string]::IsNullOrWhiteSpace($token)) 'the turn starts and its token is handed out'
        $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'a quiet turn', '-ProjectRoot', $project.Root, '-Token', $token, '-AsJson')
        Assert-True ($r.Code -eq 0) 'the turn is declared with its token'

        [IO.File]::WriteAllText((Join-Path $project.Root '.specrew/runtime/fixture-gate-block'), 'block', [Text.UTF8Encoding]::new($false))
        $blocked = Invoke-Dispatch -Project $project -Event 'Stop' -EventFields @{ session_id = $session; stop_hook_active = $false }
        Assert-True ($blocked -match 'A fixture check blocks this Stop') 'the Stop is blocked by the fixture check'
        Assert-True ((Read-SpecrewTurnToken -StateRoot $paths.StateRoot) -ceq $token) 'the block keeps the turn''s token: a check that has not passed has not ended the turn'
        Assert-True ((Get-SpecrewTurnId -StateRoot $paths.StateRoot) -ceq $turnBefore) 'and the counter still names the same turn'

        $r = Invoke-Declare @('-Kind', 'conversational', '-Summary', 'answered the block', '-ProjectRoot', $project.Root, '-Token', $token, '-AsJson')
        Assert-True ($r.Code -eq 0) ('the reply that follows the block is declared with the same token (refusal: {0})' -f (($r.Err -replace '\s+', ' ').Trim()))
        $record = Read-SpecrewTurnEndRecord -Path $paths.RecordPath
        Assert-True ($null -ne $record -and [string]$record.summary -ceq 'answered the block' -and [string]$record.turn_token -ceq $token) 'and recorded as that turn''s end'

        Remove-Item -LiteralPath (Join-Path $project.Root '.specrew/runtime/fixture-gate-block') -Force
        $passed = Invoke-Dispatch -Project $project -Event 'Stop' -EventFields @{ session_id = $session; stop_hook_active = $true }
        Assert-True ($passed -notmatch 'SPECREW-STOP-BLOCK') 'the next Stop passes every check'
        Assert-True ([string]::IsNullOrWhiteSpace((Read-SpecrewTurnToken -StateRoot $paths.StateRoot))) 'only now is the token used up'
        Assert-True ((Get-SpecrewTurnId -StateRoot $paths.StateRoot) -ceq ('turn-{0}' -f ([int]($turnBefore -replace 'turn-', '') + 1))) 'and the counter steps once: a blocked turn and its continuation are one turn'

        $history = @(Get-History -StateRoot $paths.StateRoot)
        Assert-True ($history.Count -eq 2) ('each Stop leaves one history line ({0})' -f $history.Count)
        if ($history.Count -eq 2) {
            Assert-True ([string]$history[0].turn_id -ceq $turnBefore -and [string]$history[0].token -ceq 'kept' -and -not [bool]$history[0].counter_stepped -and @($history[0].blocked_by) -contains 'fixture-gate') 'the first names the turn judged, the token kept, no step, and the check that blocked'
            Assert-True ([string]$history[1].turn_id -ceq $turnBefore -and [string]$history[1].declaration_kind -ceq 'conversational' -and [string]$history[1].token -ceq 'consumed' -and [bool]$history[1].counter_stepped -and @($history[1].blocked_by).Count -eq 0) 'the second names the same turn, its declaration, the token used up and the step'
        }
    }
}
finally {
    foreach ($p in $projects) { if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue } }
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
    if ($null -eq $priorProfilePath) { Remove-Item Env:\SPECREW_USER_PROFILE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_USER_PROFILE_PATH = $priorProfilePath }
}

if ($script:Failures -gt 0) { Write-Host ("turn-end-after-stop-block: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'turn-end-after-stop-block: all cases passed'
exit 0
