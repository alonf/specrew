# F-198 Iteration 005 — PRODUCTION-PATH honesty matrix for the co-review findings 2/3/4/5/6/7/8.
#
# This drives the REAL surfaces (the deployed dispatcher + the real `specrew hooks doctor` command), not the
# helpers in isolation, and it REPLACES the earlier version of this suite that ENCODED the very defects the
# maintainer flagged (it asserted an ambient env value was persisted, and that an arbitrary version read healthy
# with NO current-version comparison). The corrected model (maintainer decision 2026-07-14, "fix fully now"):
#
#   * observed_host_version is a BOUNDED, shell-free `--version` probe of the resolved host CLI, run ONLY at
#     SessionStart. SPECREW_OBSERVED_HOST_VERSION is GONE - no ambient/secret value is ever the source or persisted.
#   * `healthy`/`ready` REQUIRE the SessionStart-observed version to MATCH an INDEPENDENTLY probed CURRENT version
#     (the doctor + Codex preflight probe the live host binding and supply it). A bare receipt never reads healthy.
#   * Stop launches NO probe and cannot overwrite/promote the SessionStart version fact.
#
# The probe target is controlled deterministically with a FAKE `codex` on PATH (a .cmd shim, exactly like an
# npm-installed CLI), so these tests never depend on which real CLI is installed. The fake also drops a marker
# file every time it runs, which lets us PROVE that Stop launches no probe.
#
# 'script' suite (Write-Pass/Write-Fail; exit 0 green / 1 red) - it spawns the REAL dispatcher + REAL CLI as children.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$scratchRoot = Join-Path $repoRoot '.scratch/f198-hook-health-prod'
$projectRoot = Join-Path $scratchRoot 'project'
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null

# The REAL governed-project fixture (deployed dispatcher copy + real refocus engine), reused so the dispatcher
# resolves its project root from $PSScriptRoot exactly as a downstream deploy does.
. (Join-Path $PSScriptRoot 'refocus-dispatcher-fixture.ps1')
$fixture = New-RefocusDispatcherFixture -ProjectRoot $projectRoot -RepoRoot $repoRoot
$dispatcher = $fixture.dispatcher
$hostBinding = $fixture.host_binding

# The receipt module in-process (to set up doctor-project receipts and read them back).
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/hook-health-receipt.ps1')

$hookHealthStore = Join-Path $projectRoot '.specrew/runtime/hook-health'
function Reset-HookHealthStore { if (Test-Path -LiteralPath $hookHealthStore) { Remove-Item -LiteralPath $hookHealthStore -Recurse -Force } }
function Get-ReceiptFiles { if (-not (Test-Path -LiteralPath $hookHealthStore)) { return @() } return @(Get-ChildItem -LiteralPath $hookHealthStore -Filter '*.json' -File -ErrorAction SilentlyContinue) }
function Get-ReceiptForEvent {
    param([string]$Event)
    $file = Join-Path $hookHealthStore ('codex-cli-' + $Event.ToLowerInvariant() + '.json')
    if (-not (Test-Path -LiteralPath $file)) { return $null }
    return (Get-Content -LiteralPath $file -Raw)
}
function Get-ReceiptVersion {
    param([string]$Event)
    $raw = Get-ReceiptForEvent -Event $Event
    if ($null -eq $raw) { return '<no-receipt>' }
    return [string]($raw | ConvertFrom-Json).observed_host_version
}

# A clearly-synthetic version that can NEVER collide with a real installed codex (real codex is 0.144.x).
$script:FakeVersion = 'codex-cli 0.0.0-specrewtest'

function New-FakeCodexBin {
    # A fake `codex` on its own dir - a Windows .cmd shim OR a POSIX shebang script (chmod +x), so the real
    # dispatcher/CLI probe resolves + runs it on either OS. It (1) drops a marker every time it runs (so we can prove
    # Stop never probes) and (2) self-reports a version. -Garbage prints non-version text (-> the probe normalizes to
    # unknown). Returns the dir (prepend it to a child's PATH).
    param([string]$Version = $script:FakeVersion, [switch]$Garbage)
    $dir = Join-Path $scratchRoot ('bin-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $emit = if ($Garbage) { 'this is not a version' } else { $Version }
    if ($IsWindows) {
        $body = "@echo off`r`necho fired>>`"%~dp0probe-fired.txt`"`r`necho $emit"
        [System.IO.File]::WriteAllText((Join-Path $dir 'codex.cmd'), $body, [System.Text.UTF8Encoding]::new($false))
    }
    else {
        $p = Join-Path $dir 'codex'
        $body = "#!/usr/bin/env sh`necho fired >> `"`$(dirname `"`$0`")/probe-fired.txt`"`necho '$emit'`n"
        [System.IO.File]::WriteAllText($p, $body, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::SetUnixFileMode($p, [System.IO.UnixFileMode]'UserRead,UserWrite,UserExecute,GroupRead,GroupExecute,OtherRead,OtherExecute')
    }
    return $dir
}
function Reset-ProbeMarker { param([string]$BinDir) Remove-Item -LiteralPath (Join-Path $BinDir 'probe-fired.txt') -Force -ErrorAction SilentlyContinue }
function Test-ProbeFired { param([string]$BinDir) return (Test-Path -LiteralPath (Join-Path $BinDir 'probe-fired.txt') -PathType Leaf) }

function Invoke-Dispatcher {
    # Drive the REAL dispatcher exactly as a host does: event JSON on stdin, the codex host binding, project cwd.
    # SPECREW_MODULE_PATH points the receipt-module resolver at this repo's module. -PathPrepend puts a fake host
    # bin dir first on the child PATH so the SessionStart probe resolves it; -ExtraEnv injects extra env (e.g. an
    # ambient SPECREW_OBSERVED_HOST_VERSION we prove is ignored).
    param([string]$Event = 'SessionStart', [string]$StdinJson = '', [hashtable]$ExtraEnv = @{}, [string]$PathPrepend)
    $stdoutPath = Join-Path $scratchRoot 'stdout.txt'
    $stderrPath = Join-Path $scratchRoot 'stderr.txt'
    $stdinPath = Join-Path $scratchRoot 'stdin.json'
    [System.IO.File]::WriteAllText($stdinPath, ($StdinJson ?? ''), [System.Text.UTF8Encoding]::new($false))
    $dispatcherArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', $Event, '-HostKind', 'codex')
    if (-not [string]::IsNullOrWhiteSpace($hostBinding)) { $dispatcherArgs += @('-HostBinding', $hostBinding) }
    $env0 = @{ SPECREW_MODULE_PATH = $repoRoot }
    if (-not [string]::IsNullOrWhiteSpace($PathPrepend)) { $env0['PATH'] = $PathPrepend + [System.IO.Path]::PathSeparator + $env:PATH }
    foreach ($k in $ExtraEnv.Keys) { $env0[$k] = $ExtraEnv[$k] }
    $saved = @{}
    foreach ($k in $env0.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k); [Environment]::SetEnvironmentVariable($k, $env0[$k]) }
    try {
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList $dispatcherArgs -WorkingDirectory $projectRoot -Wait -PassThru -NoNewWindow `
            -RedirectStandardInput $stdinPath -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        return @{ ExitCode = $proc.ExitCode }
    }
    finally {
        foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) }
    }
}

function Invoke-SpecrewCli {
    # Drive the REAL `specrew` CLI dispatcher (scripts/specrew.ps1) end to end. SPECREW_MODULE_PATH is deliberately
    # NOT set so the CLI runs in-place. -PathPrepend puts a fake host bin dir first on the child PATH so the
    # doctor's/preflight's independent live probe resolves it.
    param([string[]]$CliArgs, [string]$PathPrepend)
    $stdoutPath = Join-Path $scratchRoot 'cli-stdout.txt'
    $stderrPath = Join-Path $scratchRoot 'cli-stderr.txt'
    $cli = Join-Path $repoRoot 'scripts/specrew.ps1'
    $savedMp = [Environment]::GetEnvironmentVariable('SPECREW_MODULE_PATH')
    $savedPath = [Environment]::GetEnvironmentVariable('PATH')
    [Environment]::SetEnvironmentVariable('SPECREW_MODULE_PATH', $null)
    if (-not [string]::IsNullOrWhiteSpace($PathPrepend)) { [Environment]::SetEnvironmentVariable('PATH', $PathPrepend + [System.IO.Path]::PathSeparator + $savedPath) }
    try {
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $cli) + $CliArgs) `
            -WorkingDirectory $repoRoot -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $out = ((Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue) ?? '') + "`n" + ((Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue) ?? '')
        return @{ ExitCode = $proc.ExitCode; Output = $out }
    }
    finally {
        [Environment]::SetEnvironmentVariable('SPECREW_MODULE_PATH', $savedMp)
        [Environment]::SetEnvironmentVariable('PATH', $savedPath)
    }
}

$validSessionStart = '{"session_id":"sess-abc-123","source":"startup"}'

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- FINDING 2: the dispatcher records a receipt ONLY after the host envelope validates ---" -ForegroundColor Cyan

$goodBin = New-FakeCodexBin
Reset-HookHealthStore
$r = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -PathPrepend $goodBin
Assert-True ($r.ExitCode -eq 0) 'F2: a valid SessionStart fire exits 0 (fail-open)'
Assert-True (@(Get-ReceiptFiles).Count -eq 1) 'F2: a GENUINE host-shaped SessionStart fire records exactly one receipt'

$noReceiptCases = @(
    @{ Name = 'empty event (no stdin)'; Json = '' }
    @{ Name = 'malformed JSON'; Json = 'THIS_IS_NOT_JSON {{{ <<<' }
    @{ Name = 'non-host-shaped JSON array'; Json = '[1,2,3]' }
    @{ Name = 'non-host-shaped object (no host session id)'; Json = '{"foo":"bar"}' }
    @{ Name = 'empty JSON object'; Json = '{}' }
)
foreach ($c in $noReceiptCases) {
    Reset-HookHealthStore
    $rr = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $c.Json -PathPrepend $goodBin
    Assert-True ($rr.ExitCode -eq 0) ("F2: '{0}' still dispatches fail-open (exit 0)" -f $c.Name)
    Assert-True (@(Get-ReceiptFiles).Count -eq 0) ("F2: '{0}' records NO receipt (no false-green)" -f $c.Name)
}

Reset-HookHealthStore
$rp = Invoke-Dispatcher -Event 'PostToolUse' -StdinJson '{"session_id":"sess-abc-123","tool_name":"Bash"}' -PathPrepend $goodBin
Assert-True (@(Get-ReceiptFiles).Count -eq 0) 'F2: a host-shaped PostToolUse records NO receipt (only SessionStart/Stop are lifecycle proof points)'

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- FINDING 3: the version is a SessionStart probe fact; SPECREW_OBSERVED_HOST_VERSION is ignored and never persisted ---" -ForegroundColor Cyan

# 3a: an ambient (even version-shaped / secret) SPECREW_OBSERVED_HOST_VERSION is IGNORED - the probe wins, and the
#     env value never lands in the receipt.
Reset-HookHealthStore
$secret = 'SECRET_token_123'
$null = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -PathPrepend $goodBin -ExtraEnv @{ SPECREW_OBSERVED_HOST_VERSION = $secret }
Assert-True ((Get-ReceiptVersion -Event 'SessionStart') -eq $script:FakeVersion) 'F3: the recorded version is the PROBE result, not the ambient SPECREW_OBSERVED_HOST_VERSION'
$rawA = Get-ReceiptForEvent -Event 'SessionStart'
Assert-True ($null -ne $rawA -and ($rawA -notmatch 'SECRET_token_123') -and ($rawA -notmatch 'token_123')) 'F3: the ambient secret / version-shaped token never appears anywhere in the receipt'

# 3b: when the probe yields no usable version (garbage output), the receipt is the honest 'unknown' - the ambient
#     env value is NOT used as a fallback (token_123/abc123 can never influence health).
$garbageBin = New-FakeCodexBin -Garbage
Reset-HookHealthStore
$null = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -PathPrepend $garbageBin -ExtraEnv @{ SPECREW_OBSERVED_HOST_VERSION = 'token_123' }
Assert-True ((Get-ReceiptVersion -Event 'SessionStart') -eq 'unknown') 'F3: a probe that yields no version records unknown (the ambient env value is NOT a fallback)'
$rawB = Get-ReceiptForEvent -Event 'SessionStart'
Assert-True ($null -ne $rawB -and ($rawB -notmatch 'token_123')) 'F3: the version-shaped ambient token is not persisted even when the probe fails'

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- FINDING 6: Stop launches NO version probe (and records 'unknown') ---" -ForegroundColor Cyan

Reset-HookHealthStore
Reset-ProbeMarker -BinDir $goodBin
$null = Invoke-Dispatcher -Event 'Stop' -StdinJson $validSessionStart -PathPrepend $goodBin
Assert-True (-not (Test-ProbeFired -BinDir $goodBin)) 'F6: a Stop fire does NOT launch the version probe (the fake codex was never executed)'
Assert-True ((Get-ReceiptVersion -Event 'Stop') -eq 'unknown') 'F6: the Stop receipt records observed version = unknown (proof-of-fire only)'

Reset-HookHealthStore
Reset-ProbeMarker -BinDir $goodBin
$null = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -PathPrepend $goodBin
Assert-True (Test-ProbeFired -BinDir $goodBin) 'F6: a SessionStart fire DOES launch the version probe (the fake codex ran)'
Assert-True ((Get-ReceiptVersion -Event 'SessionStart') -eq $script:FakeVersion) 'F6: the SessionStart receipt records the probed version'

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- FINDING 7: a later Stop cannot overwrite or promote the SessionStart version fact ---" -ForegroundColor Cyan

Reset-HookHealthStore
$null = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -PathPrepend $goodBin
$null = Invoke-Dispatcher -Event 'Stop' -StdinJson $validSessionStart -PathPrepend $goodBin
Assert-True ((Get-ReceiptVersion -Event 'SessionStart') -eq $script:FakeVersion) 'F7: after a later Stop, the SessionStart receipt still holds the probed version'
Assert-True ((Get-ReceiptVersion -Event 'Stop') -eq 'unknown') 'F7: the Stop receipt is a separate file that carries unknown (it never overwrites the SessionStart version fact)'

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- FINDINGS 4/5/8: `specrew hooks doctor` surfaces tiers + hook-health + preflight, and PROBES the live version ---" -ForegroundColor Cyan

function New-DoctorProject {
    param([string]$Name, [AllowNull()][string]$ReceiptVersion)
    $p = Join-Path $scratchRoot $Name
    New-Item -ItemType Directory -Path (Join-Path $p '.specrew') -Force | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($ReceiptVersion)) {
        Write-SpecrewHookHealthReceipt -ProjectRoot $p -HostName 'codex' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion $ReceiptVersion | Out-Null
    }
    return $p
}
function Test-HasHealthyCodexRow { param([string]$Output) return [bool](@($Output -split "`r?`n" | Where-Object { $_ -match '^\s+codex\s+cli\s+healthy\b' }).Count) }

# (4) No receipt -> all three sections render; NO healthy row; preflight NOT ready.
$dpNone = New-DoctorProject -Name 'doctor-none' -ReceiptVersion $null
$d1 = Invoke-SpecrewCli -CliArgs @('hooks', 'doctor', '--project-path', $dpNone)
Assert-True ($d1.ExitCode -eq 0) 'F4: `specrew hooks doctor` exits 0'
Assert-True ($d1.Output -match 'host-support tiers') 'F4: the report surfaces the host-support TIERS section'
Assert-True ($d1.Output -match 'hook-health evidence') 'F4: the report surfaces the hook-health EVIDENCE section'
Assert-True ($d1.Output -match 'governance preflight') 'F4: the report surfaces the Codex untrusted-headless PREFLIGHT section'
Assert-True (-not (Test-HasHealthyCodexRow -Output $d1.Output)) 'F4: a no-receipt project renders NO healthy health row (never health-washed)'
Assert-True ($d1.Output -match 'ready to govern a headless run:\s*NO') 'F4: no receipt -> the Codex preflight renders NOT ready'

# (5+8) A fresh SessionStart receipt whose version MATCHES the live probe -> healthy + ready (via the REAL command).
$dpMatch = New-DoctorProject -Name 'doctor-match' -ReceiptVersion $script:FakeVersion
$d2 = Invoke-SpecrewCli -CliArgs @('hooks', 'doctor', '--project-path', $dpMatch) -PathPrepend $goodBin
Assert-True (Test-HasHealthyCodexRow -Output $d2.Output) 'F5/F8: a receipt whose version matches the independently probed live codex surfaces a HEALTHY codex row'
Assert-True ($d2.Output -match 'ready to govern a headless run:\s*YES') 'F5/F8: with a matching live probe the Codex preflight reports READY'

# (8) The SAME receipt, but the live probe does NOT match (no fake on PATH -> real/absent codex != the fake version)
#     -> NOT healthy, NOT ready. This proves the doctor/preflight genuinely PROBE the live version and never trust a
#     bare receipt (the false-green this fix closes).
$d3 = Invoke-SpecrewCli -CliArgs @('hooks', 'doctor', '--project-path', $dpMatch)
Assert-True (-not (Test-HasHealthyCodexRow -Output $d3.Output)) 'F8: the same receipt is NOT healthy when the live probe does not match it (the doctor probes; it never trusts a bare receipt)'
Assert-True ($d3.Output -match 'ready to govern a headless run:\s*NO') 'F8: the same receipt is NOT ready when the live probe does not match it'

# (5) An 'unknown'-version receipt never reads healthy/ready through the real command, even with the fake on PATH.
$dpUnknown = New-DoctorProject -Name 'doctor-unknown' -ReceiptVersion 'unknown'
$d4 = Invoke-SpecrewCli -CliArgs @('hooks', 'doctor', '--project-path', $dpUnknown) -PathPrepend $goodBin
Assert-True (-not (Test-HasHealthyCodexRow -Output $d4.Output)) 'F5: an unknown-version receipt never surfaces a healthy row through the command'
Assert-True ($d4.Output -match 'ready to govern a headless run:\s*NO') 'F5: an unknown-version receipt keeps the Codex preflight NOT ready'

# -----------------------------------------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host ''
if ($script:Failures -gt 0) {
    Write-Host ("F-198 iter-005 hook-health production-path suite: {0} assertion(s) FAILED" -f $script:Failures) -ForegroundColor Red
    exit 1
}
Write-Host 'F-198 iter-005 hook-health production-path suite: all assertions green.' -ForegroundColor Green
exit 0
