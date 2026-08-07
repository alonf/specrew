#!/usr/bin/env pwsh
# REPRODUCIBLE, DIGEST-BOUND Codex Stop-contract probe (F-198 FR-051; review finding f2 run 20260714T215545754).
#
# WHY THIS EXISTS: the codex/cli host-support tier is claimed `verified`. Under the review contract a `verified`
# claim needs digest-matched RUNTIME evidence, not a one-off session characterization. This is the committed,
# replayable probe of the INSTALLED codex CLI's headless `codex exec` surface, asserting the response-shape
# contract that BACKS the verified tier - DETERMINISTICALLY, without depending on model compliance:
#   A {} (empty) allows: the Stop hook FIRES headlessly and the turn completes with NO force-continue.
#   C {"decision":"block",...} GATES: the hook force-continues the turn (structurally: the hook fires AGAIN and
#     a SECOND turn runs) - block-once + honoring stop_hook_active so it terminates cleanly.
#   D {"continue":false,...} (the Codex-manual shape) does NOT gate: the hook fires but there is NO force-continue.
# Every scenario's observable is a SENTINEL FILE the hook appends to (fire count) + the turn.completed count in
# codex's --json stream - both deterministic, neither dependent on what the model chooses to say.
#
# ISOLATION (non-negotiable): every codex invocation runs in a scratch dir OUTSIDE the repo with CODEX_HOME
# redirected to a scratch .codex (auth.json copied read-only so exec can authenticate; a minimal config.toml);
# the real ~/.codex is SNAPSHOTTED (sha256) before and VERIFIED byte-unchanged after. Bounded timeouts, tree-kill.
#
# HONEST SCOPE: covers the RUNNER-OBSERVABLE headless response-shape contract. The interactive trust-prompt
# acquisition is NOT reproducible PTY-less and remains HUMAN-OBSERVED provenance (the tier row + characterization).
#
# DEGRADES HONESTLY: codex CLI absent, or no auth -> result='skipped' (NOT pass, NOT fail): a reviewer worktree
# without the CLI records "unverifiable-here", never a false green. A green requires the CLI + auth.
[CmdletBinding()]
param(
    [string]$ResultPath,
    [int]$PerScenarioTimeoutSec = 150
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$script:Passed = 0; $script:Failed = 0
function Note([string]$m) { Write-Host $m }
function Check([string]$name, [bool]$ok, [string]$detail = '') {
    if ($ok) { $script:Passed++; Note ("PASS: {0}" -f $name) } else { $script:Failed++; Note ("FAIL: {0} {1}" -f $name, $detail) }
}
function Write-Result([string]$result) {
    if (-not [string]::IsNullOrWhiteSpace($ResultPath)) {
        (@{ schema_version = '1.0'; result = $result; counts = @{ passed = [int]$script:Passed; failed = [int]$script:Failed; skipped = 0 } } | ConvertTo-Json) | Set-Content -LiteralPath $ResultPath -Encoding UTF8
    }
}
function Skip([string]$why) {
    Note ("SKIP: codex probe not runnable here - {0}" -f $why)
    if (-not [string]::IsNullOrWhiteSpace($ResultPath)) { (@{ schema_version = '1.0'; result = 'skipped'; counts = @{ passed = 0; failed = 0; skipped = 1 } } | ConvertTo-Json) | Set-Content -LiteralPath $ResultPath -Encoding UTF8 }
    exit 0
}

$codex = (Get-Command codex -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1)
if ($null -eq $codex) { Skip 'the codex CLI is not installed on PATH' }
if ($null -eq (Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue)) { Skip 'pwsh is not on PATH (the hook command needs it)' }
$realHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$realAuth = Join-Path $realHome 'auth.json'
if (-not (Test-Path -LiteralPath $realAuth -PathType Leaf)) { Skip "no codex auth.json at $realAuth (headless exec cannot authenticate)" }
Note ("codex version: {0}" -f (& $codex.Source --version 2>$null | Select-Object -First 1))

$scratchRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-probe-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null
$watched = @('hooks.json', 'config.toml', 'auth.json') | ForEach-Object { Join-Path $realHome $_ } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
$before = @{}; foreach ($f in $watched) { $before[$f] = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash }

# One scratch codex home whose Stop hook (a) appends a sentinel line to a fire-log each time it fires, and
# (b) emits the scenario's response body (honoring stop_hook_active so a block terminates after one continue).
function New-CodexScratch {
    param([string]$Name, [string]$Mode)   # Mode: allow | block-once | continue-shape
    $dir = Join-Path $scratchRoot $Name
    $ch = Join-Path $dir '.codex'
    New-Item -ItemType Directory -Path $ch -Force | Out-Null
    Copy-Item -LiteralPath $realAuth -Destination (Join-Path $ch 'auth.json') -Force
    Set-Content -LiteralPath (Join-Path $ch 'config.toml') -Value 'model = "gpt-5.6-sol"' -Encoding UTF8
    $fireLog = Join-Path $dir 'fires.log'
    $hookBody = @'
$in = [Console]::In.ReadToEnd()
$active = $false
try { $o = $in | ConvertFrom-Json; if ($o.PSObject.Properties.Name -contains 'stop_hook_active') { $active = [bool]$o.stop_hook_active } } catch {}
Add-Content -LiteralPath '__FIRELOG__' -Value ("fire active=$active")
switch ('__MODE__') {
    'allow'          { [Console]::Out.Write('{}') }
    'continue-shape' { [Console]::Out.Write((@{ continue = $false; stopReason = 'x'; systemMessage = 'y' } | ConvertTo-Json -Compress)) }
    'block-once'     { if ($active) { [Console]::Out.Write('{}') } else { [Console]::Out.Write((@{ decision = 'block'; reason = 'Say OK.' } | ConvertTo-Json -Compress)) } }
}
exit 0
'@ -replace '__FIRELOG__', ($fireLog -replace '\\', '/') -replace '__MODE__', $Mode
    $hookScript = Join-Path $dir 'stop-hook.ps1'
    Set-Content -LiteralPath $hookScript -Value $hookBody -Encoding UTF8
    # PROVEN command format (matches the real ~/.codex/hooks.json): bare `pwsh`, -ExecutionPolicy Bypass,
    # forward-slash -File path in double quotes. A quoted full exe path + backslashes breaks codex's discovery.
    $cmd = 'pwsh -NoProfile -ExecutionPolicy Bypass -File "' + ($hookScript -replace '\\', '/') + '"'
    (@{ hooks = @{ Stop = @(@{ hooks = @(@{ type = 'command'; command = $cmd; timeout = 30 }) }) } } | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath (Join-Path $ch 'hooks.json') -Encoding UTF8
    return @{ dir = $dir; home = $ch; fire_log = $fireLog }
}
function Invoke-Codex {
    param([hashtable]$Scratch)
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $codex.Source
    foreach ($a in @('exec', '--json', '--skip-git-repo-check', '--dangerously-bypass-approvals-and-sandbox', '--dangerously-bypass-hook-trust', '-C', $Scratch.dir, 'Reply with exactly the single word: PONG')) { [void]$psi.ArgumentList.Add($a) }
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.RedirectStandardInput = $true
    $psi.Environment['CODEX_HOME'] = $Scratch.home
    $p = [System.Diagnostics.Process]::new(); $p.StartInfo = $psi
    [void]$p.Start(); $p.StandardInput.Close()
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $timed = -not $p.WaitForExit($PerScenarioTimeoutSec * 1000)
    if ($timed) { try { $p.Kill($true) } catch { $null = $_ } }
    $out = try { $outTask.GetAwaiter().GetResult() } catch { '' }
    $fires = if (Test-Path -LiteralPath $Scratch.fire_log) { @(Get-Content -LiteralPath $Scratch.fire_log).Count } else { 0 }
    $turns = ([regex]::Matches($out, 'turn\.completed')).Count
    return @{ timed_out = $timed; fires = $fires; turns = $turns }
}

try {
    # The structural discriminator (no model compliance needed): decision:block FORCE-CONTINUES the turn, which
    # re-fires the Stop hook (>=2 fires). A non-gating response ({} allow, or the Codex-manual {continue} shape)
    # lets the turn end after exactly ONE Stop fire. So C.fires>=2 vs A/D.fires==1 IS the gate proof.
    $a = Invoke-Codex (New-CodexScratch -Name 'A' -Mode 'allow')
    Check 'A (baseline): {} allows - the Stop hook fires headlessly EXACTLY once and the turn ends (no force-continue)' (($a.fires -eq 1) -and ($a.turns -ge 1) -and (-not $a.timed_out)) ("fires=$($a.fires) turns=$($a.turns)")

    $c = Invoke-Codex (New-CodexScratch -Name 'C' -Mode 'block-once')
    Check 'C: {"decision":"block"} GATES - it force-continues the turn, re-firing the Stop hook (>=2 fires), then terminates cleanly on stop_hook_active' (($c.fires -ge 2) -and (-not $c.timed_out)) ("fires=$($c.fires) turns=$($c.turns)")

    $d = Invoke-Codex (New-CodexScratch -Name 'D' -Mode 'continue-shape')
    Check 'D: the Codex-manual {"continue":false} shape does NOT gate - the hook fires EXACTLY once and the turn ends (no force-continue)' (($d.fires -eq 1) -and (-not $d.timed_out)) ("fires=$($d.fires) turns=$($d.turns)")

    if ($script:Failed -eq 0) { Write-Result 'passed' } else { Write-Result 'failed' }
}
finally {
    $mutated = @(); foreach ($f in $watched) { if ((Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash -ne $before[$f]) { $mutated += $f } }
    if ($mutated.Count -gt 0) { Note ("ATTESTATION FAILURE: real codex config MUTATED: {0}" -f ($mutated -join ', ')); $script:Failed++; Write-Result 'failed' }
    else { Note ("isolation attestation: real ~/.codex config byte-unchanged ({0} files)" -f $watched.Count) }
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
}
Note ("codex probe: passed={0} failed={1}" -f $script:Passed, $script:Failed)
if ($script:Failed -gt 0) { exit 1 }
exit 0
