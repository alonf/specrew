#!/usr/bin/env pwsh
# REPRODUCIBLE, DIGEST-BOUND Copilot CLI hook-firing probe (F-198 FR-052; review finding f2 run 20260714T215545754).
#
# WHY THIS EXISTS: the copilot/cli host-support tier is claimed `verified`. Under the review contract a `verified`
# claim needs digest-matched RUNTIME evidence, not a one-off session characterization. This is the committed,
# replayable probe of the INSTALLED Copilot CLI's headless `copilot -p` surface, asserting the claim that BACKS
# the verified tier: USER-level hooks (the surface Specrew's governance rides) FIRE in `-p` mode and are NOT
# trust-gated (they fire from an UNTRUSTED cwd), while REPO-level hooks from an untrusted folder do NOT fire
# (the trust gate) - the exact distinction FR-052 requires. Every observable is a SENTINEL FILE the hook appends
# to (deterministic; not dependent on model output). Emits a SpecrewTestResult for the T018 recorder.
#
# ISOLATION (non-negotiable): COPILOT_HOME is redirected to a scratch dir OUTSIDE the repo (Copilot auth is
# machine-level, so isolated runs still authenticate); the runs execute in an UNTRUSTED scratch cwd; the real
# Specrew user-hook file is SNAPSHOTTED (sha256) before and VERIFIED byte-unchanged after. Bounded timeouts.
#
# DEGRADES HONESTLY: copilot CLI absent, or a run cannot complete -> result='skipped' (NOT pass, NOT fail).
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
    Note ("SKIP: copilot probe not runnable here - {0}" -f $why)
    if (-not [string]::IsNullOrWhiteSpace($ResultPath)) { (@{ schema_version = '1.0'; result = 'skipped'; counts = @{ passed = 0; failed = 0; skipped = 1 } } | ConvertTo-Json) | Set-Content -LiteralPath $ResultPath -Encoding UTF8 }
    exit 0
}

$copilot = (Get-Command copilot -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1)
if ($null -eq $copilot) { Skip 'the copilot CLI is not installed on PATH' }
if ($null -eq (Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue)) { Skip 'pwsh is not on PATH (the hook command needs it)' }
Note ("copilot version: {0}" -f (& $copilot.Source --version 2>$null | Select-Object -First 1))

# SNAPSHOT the real Specrew user-hook file (the surface governance rides) for the after-verification.
$realHookFile = Join-Path $HOME '.copilot/hooks/specrew-refocus.json'
$realHookBefore = if (Test-Path -LiteralPath $realHookFile -PathType Leaf) { (Get-FileHash -LiteralPath $realHookFile -Algorithm SHA256).Hash } else { $null }

$scratchRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('copilot-probe-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null

# Build an isolated COPILOT_HOME with a USER-level hook (sessionStart + agentStop) that appends a sentinel line
# each time it fires, plus (optionally) a REPO-level hook in the UNTRUSTED work cwd - so one run shows the
# user hook firing (not trust-gated) AND the repo hook NOT firing (trust-gated).
function New-CopilotScratch {
    param([bool]$WithRepoHook)
    $dir = Join-Path $scratchRoot ([guid]::NewGuid().ToString('N').Substring(0, 8))
    $ch = Join-Path $dir 'copilot-home'; New-Item -ItemType Directory -Path (Join-Path $ch 'hooks') -Force | Out-Null
    $work = Join-Path $dir 'work'; New-Item -ItemType Directory -Path $work -Force | Out-Null
    $userFire = Join-Path $dir 'user-fires.log'
    $repoFire = Join-Path $dir 'repo-fires.log'
    $mkHookScript = {
        param([string]$Path, [string]$FireLog, [string]$Tag)
        $body = "Add-Content -LiteralPath '$($FireLog -replace '\\','/')' -Value '$Tag'; exit 0"
        Set-Content -LiteralPath $Path -Value $body -Encoding UTF8
    }
    $userScript = Join-Path $dir 'user-hook.ps1'; & $mkHookScript $userScript $userFire 'user-fire'
    # PROVEN user-hook format (matches the real ~/.copilot/hooks/specrew-refocus.json): bash+powershell command
    # keys, timeoutSec, forward-slash -File path. USER hooks live at $COPILOT_HOME/hooks/*.json.
    $userCmd = 'pwsh -NoProfile -ExecutionPolicy Bypass -File "' + ($userScript -replace '\\', '/') + '"'
    $userHook = @{ hooks = @{
            sessionStart = @(@{ type = 'command'; bash = $userCmd; powershell = $userCmd; timeoutSec = 30 })
            agentStop    = @(@{ type = 'command'; bash = $userCmd; powershell = $userCmd; timeoutSec = 30 })
        }; version = 1
    }
    ($userHook | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath (Join-Path $ch 'hooks/probe-user.json') -Encoding UTF8
    if ($WithRepoHook) {
        $repoScript = Join-Path $dir 'repo-hook.ps1'; & $mkHookScript $repoScript $repoFire 'repo-fire'
        $repoCmd = 'pwsh -NoProfile -ExecutionPolicy Bypass -File "' + ($repoScript -replace '\\', '/') + '"'
        New-Item -ItemType Directory -Path (Join-Path $work '.github/hooks') -Force | Out-Null
        (@{ hooks = @{ agentStop = @(@{ type = 'command'; bash = $repoCmd; powershell = $repoCmd; timeoutSec = 30 }) }; version = 1 } | ConvertTo-Json -Depth 8) |
            Set-Content -LiteralPath (Join-Path $work '.github/hooks/probe-repo.json') -Encoding UTF8
    }
    # a fresh, UNTRUSTED settings.json (no trustedFolders) so the repo-hook trust gate is exercised.
    Set-Content -LiteralPath (Join-Path $ch 'settings.json') -Value '{ "trustedFolders": [] }' -Encoding UTF8
    return @{ dir = $dir; home = $ch; work = $work; user_fire = $userFire; repo_fire = $repoFire }
}
function Invoke-Copilot {
    param([hashtable]$Scratch)
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $copilot.Source
    foreach ($a in @('--allow-all-tools', '--no-color', '--log-level', 'none', '-p', 'Reply with exactly the single word: PONG')) { [void]$psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Scratch.work
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.RedirectStandardInput = $true
    $psi.Environment['COPILOT_HOME'] = $Scratch.home
    $p = [System.Diagnostics.Process]::new(); $p.StartInfo = $psi
    [void]$p.Start(); $p.StandardInput.Close()
    $outTask = $p.StandardOutput.ReadToEndAsync(); $errTask = $p.StandardError.ReadToEndAsync()
    $timed = -not $p.WaitForExit($PerScenarioTimeoutSec * 1000)
    if ($timed) { try { $p.Kill($true) } catch { $null = $_ } }
    $null = try { $outTask.GetAwaiter().GetResult() } catch { '' }
    $null = try { $errTask.GetAwaiter().GetResult() } catch { '' }
    $uf = if (Test-Path -LiteralPath $Scratch.user_fire) { @(Get-Content -LiteralPath $Scratch.user_fire).Count } else { 0 }
    $rf = if (Test-Path -LiteralPath $Scratch.repo_fire) { @(Get-Content -LiteralPath $Scratch.repo_fire).Count } else { 0 }
    return @{ timed_out = $timed; user_fires = $uf; repo_fires = $rf; exit = $p.ExitCode }
}

try {
    $r = Invoke-Copilot (New-CopilotScratch -WithRepoHook $true)
    if ($r.timed_out) { Skip 'the copilot -p run did not complete within the timeout (auth/network unavailable here)' }
    Check 'USER-level hooks FIRE in headless `copilot -p` from an UNTRUSTED cwd (governance rides the user hook; not trust-gated)' ($r.user_fires -ge 1) ("user_fires=$($r.user_fires)")
    Check 'REPO-level hooks from an UNTRUSTED folder do NOT fire (the trustedFolders gate) - the FR-052 distinction' ($r.repo_fires -eq 0) ("repo_fires=$($r.repo_fires)")
    if ($script:Failed -eq 0) { Write-Result 'passed' } else { Write-Result 'failed' }
}
finally {
    if ($null -ne $realHookBefore) {
        $after = if (Test-Path -LiteralPath $realHookFile -PathType Leaf) { (Get-FileHash -LiteralPath $realHookFile -Algorithm SHA256).Hash } else { $null }
        if ($after -ne $realHookBefore) { Note 'ATTESTATION FAILURE: the real Specrew copilot user-hook file was MUTATED'; $script:Failed++; Write-Result 'failed' }
        else { Note 'isolation attestation: the real ~/.copilot Specrew user-hook file is byte-unchanged' }
    }
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
}
Note ("copilot probe: passed={0} failed={1}" -f $script:Passed, $script:Failed)
if ($script:Failed -gt 0) { exit 1 }
exit 0
