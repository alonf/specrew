# F-198 Prop-145 - PRODUCTION-PATH honesty matrix, driven through the REAL dispatcher + the real `specrew hooks
# doctor` command. The model (maintainer Option A, amended): hook health = INDEPENDENT hook-LIVENESS (a fresh,
# well-formed receipt shows the configured hook path was observed firing - MONITORING evidence, not authenticated)
# + a NON-PROMOTING ambient-path-binding version DIAGNOSTIC. The version NEVER promotes liveness or readiness. This
# suite proves: receipt-after-validation; the version is the ambient probe (no env source, source=ambient-path-binding);
# Stop launches no probe and cannot clobber the SessionStart fact; a hijacked ComSpec cannot substitute the shim
# interpreter (Windows); and a substituted PATH shim's version CANNOT create hook health/readiness without a receipt.
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

. (Join-Path $PSScriptRoot 'refocus-dispatcher-fixture.ps1')
$fixture = New-RefocusDispatcherFixture -ProjectRoot $projectRoot -RepoRoot $repoRoot
$dispatcher = $fixture.dispatcher
$hostBinding = $fixture.host_binding
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/hook-health-receipt.ps1')

$hookHealthStore = Join-Path $projectRoot '.specrew/runtime/hook-health'
function Reset-HookHealthStore { if (Test-Path -LiteralPath $hookHealthStore) { Remove-Item -LiteralPath $hookHealthStore -Recurse -Force } }
function Get-ReceiptFiles { if (-not (Test-Path -LiteralPath $hookHealthStore)) { return @() } return @(Get-ChildItem -LiteralPath $hookHealthStore -Filter '*.json' -File -ErrorAction SilentlyContinue) }
function Get-ReceiptForEvent { param([string]$Event) $f = Join-Path $hookHealthStore ('codex-cli-' + $Event.ToLowerInvariant() + '.json'); if (-not (Test-Path -LiteralPath $f)) { return $null } return (Get-Content -LiteralPath $f -Raw) }
function Get-ReceiptField { param([string]$Event, [string]$Field) $raw = Get-ReceiptForEvent -Event $Event; if ($null -eq $raw) { return '<no-receipt>' } return [string]($raw | ConvertFrom-Json).$Field }

$script:FakeVersion = 'codex-cli 0.0.0-specrewtest'

function New-FakeCodexBin {
    param([string]$Version = $script:FakeVersion, [switch]$Garbage)
    $dir = Join-Path $scratchRoot ('bin-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $emit = if ($Garbage) { 'this is not a version' } else { $Version }
    if ($IsWindows) {
        [System.IO.File]::WriteAllText((Join-Path $dir 'codex.cmd'), "@echo off`r`necho fired>>`"%~dp0probe-fired.txt`"`r`necho $emit", [System.Text.UTF8Encoding]::new($false))
    }
    else {
        $p = Join-Path $dir 'codex'
        [System.IO.File]::WriteAllText($p, "#!/usr/bin/env sh`necho fired >> `"`$(dirname `"`$0`")/probe-fired.txt`"`necho '$emit'`n", [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::SetUnixFileMode($p, [System.IO.UnixFileMode]'UserRead,UserWrite,UserExecute,GroupRead,GroupExecute,OtherRead,OtherExecute')
    }
    return $dir
}
function Reset-ProbeMarker { param([string]$BinDir) Remove-Item -LiteralPath (Join-Path $BinDir 'probe-fired.txt') -Force -ErrorAction SilentlyContinue }
function Test-ProbeFired { param([string]$BinDir) return (Test-Path -LiteralPath (Join-Path $BinDir 'probe-fired.txt') -PathType Leaf) }

function Invoke-Dispatcher {
    param([string]$Event = 'SessionStart', [string]$StdinJson = '', [hashtable]$ExtraEnv = @{}, [string]$PathPrepend)
    $stdoutPath = Join-Path $scratchRoot 'stdout.txt'; $stderrPath = Join-Path $scratchRoot 'stderr.txt'; $stdinPath = Join-Path $scratchRoot 'stdin.json'
    [System.IO.File]::WriteAllText($stdinPath, ($StdinJson ?? ''), [System.Text.UTF8Encoding]::new($false))
    $dispatcherArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', $Event, '-HostKind', 'codex')
    if (-not [string]::IsNullOrWhiteSpace($hostBinding)) { $dispatcherArgs += @('-HostBinding', $hostBinding) }
    $env0 = @{ SPECREW_MODULE_PATH = $repoRoot }
    if (-not [string]::IsNullOrWhiteSpace($PathPrepend)) { $env0['PATH'] = $PathPrepend + [System.IO.Path]::PathSeparator + $env:PATH }
    foreach ($k in $ExtraEnv.Keys) { $env0[$k] = $ExtraEnv[$k] }
    $saved = @{}
    foreach ($k in $env0.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k); [Environment]::SetEnvironmentVariable($k, $env0[$k]) }
    try {
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList $dispatcherArgs -WorkingDirectory $projectRoot -Wait -PassThru -NoNewWindow -RedirectStandardInput $stdinPath -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        return @{ ExitCode = $proc.ExitCode }
    }
    finally { foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) } }
}

function Invoke-SpecrewCli {
    param([string[]]$CliArgs, [string]$PathPrepend)
    $stdoutPath = Join-Path $scratchRoot 'cli-stdout.txt'; $stderrPath = Join-Path $scratchRoot 'cli-stderr.txt'
    $cli = Join-Path $repoRoot 'scripts/specrew.ps1'
    $savedMp = [Environment]::GetEnvironmentVariable('SPECREW_MODULE_PATH'); $savedPath = [Environment]::GetEnvironmentVariable('PATH')
    [Environment]::SetEnvironmentVariable('SPECREW_MODULE_PATH', $null)
    if (-not [string]::IsNullOrWhiteSpace($PathPrepend)) { [Environment]::SetEnvironmentVariable('PATH', $PathPrepend + [System.IO.Path]::PathSeparator + $savedPath) }
    try {
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $cli) + $CliArgs) -WorkingDirectory $repoRoot -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $out = ((Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue) ?? '') + "`n" + ((Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue) ?? '')
        return @{ ExitCode = $proc.ExitCode; Output = $out }
    }
    finally { [Environment]::SetEnvironmentVariable('SPECREW_MODULE_PATH', $savedMp); [Environment]::SetEnvironmentVariable('PATH', $savedPath) }
}

$validSessionStart = '{"session_id":"sess-abc-123","source":"startup"}'
$goodBin = New-FakeCodexBin

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- receipt is recorded ONLY after the host envelope validates ---" -ForegroundColor Cyan
Reset-HookHealthStore
$r = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -PathPrepend $goodBin
Assert-True ($r.ExitCode -eq 0) 'a valid SessionStart fire exits 0 (fail-open)'
Assert-True (@(Get-ReceiptFiles).Count -eq 1) 'a genuine host-shaped SessionStart fire records exactly one receipt'
foreach ($c in @(@{N = 'empty'; J = '' }, @{N = 'malformed'; J = 'NOT JSON {{{' }, @{N = 'array'; J = '[1,2,3]' }, @{N = 'no-session-id'; J = '{"foo":"bar"}' }, @{N = 'empty-object'; J = '{}' })) {
    Reset-HookHealthStore
    $rr = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $c.J -PathPrepend $goodBin
    Assert-True ($rr.ExitCode -eq 0) ("'{0}' still dispatches fail-open (exit 0)" -f $c.N)
    Assert-True (@(Get-ReceiptFiles).Count -eq 0) ("'{0}' records NO receipt" -f $c.N)
}

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- the version is the ambient probe (source=ambient-path-binding); no env value is the source or persisted ---" -ForegroundColor Cyan
Reset-HookHealthStore
$null = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -PathPrepend $goodBin -ExtraEnv @{ SPECREW_OBSERVED_HOST_VERSION = 'SECRET_token_123' }
Assert-True ((Get-ReceiptField -Event 'SessionStart' -Field 'observed_host_version') -eq $script:FakeVersion) 'the recorded version is the ambient probe result, not an env value'
Assert-True ((Get-ReceiptField -Event 'SessionStart' -Field 'version_source') -eq 'ambient-path-binding') 'the SessionStart receipt labels the version source ambient-path-binding'
$rawA = Get-ReceiptForEvent -Event 'SessionStart'
Assert-True ($null -ne $rawA -and ($rawA -notmatch 'SECRET_token_123')) 'an ambient env value never appears anywhere in the receipt'

$garbageBin = New-FakeCodexBin -Garbage
Reset-HookHealthStore
$null = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -PathPrepend $garbageBin -ExtraEnv @{ SPECREW_OBSERVED_HOST_VERSION = 'token_123' }
Assert-True ((Get-ReceiptField -Event 'SessionStart' -Field 'observed_host_version') -eq 'unknown') 'a probe that yields no version records unknown (env is not a fallback)'
Assert-True ((Get-ReceiptField -Event 'SessionStart' -Field 'version_source') -eq 'unavailable') 'a failed probe records version_source unavailable'

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- Stop launches NO probe and cannot clobber the SessionStart fact ---" -ForegroundColor Cyan
Reset-HookHealthStore; Reset-ProbeMarker -BinDir $goodBin
$null = Invoke-Dispatcher -Event 'Stop' -StdinJson $validSessionStart -PathPrepend $goodBin
Assert-True (-not (Test-ProbeFired -BinDir $goodBin)) 'a Stop fire does NOT launch the version probe (the fake was never executed)'
Assert-True ((Get-ReceiptField -Event 'Stop' -Field 'observed_host_version') -eq 'unknown') 'the Stop receipt records observed version unknown (proof-of-fire only)'
Reset-HookHealthStore
$null = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -PathPrepend $goodBin
$null = Invoke-Dispatcher -Event 'Stop' -StdinJson $validSessionStart -PathPrepend $goodBin
Assert-True ((Get-ReceiptField -Event 'SessionStart' -Field 'observed_host_version') -eq $script:FakeVersion) 'after a later Stop, the SessionStart receipt still holds the probed version'

# -----------------------------------------------------------------------------------------------------------
if ($IsWindows) {
    Write-Host "`n--- INTERPRETER TRUST (Windows): a hijacked ComSpec cannot substitute the shim interpreter ---" -ForegroundColor Cyan
    $evilComSpec = Join-Path $scratchRoot 'evil-comspec.exe'
    [System.IO.File]::WriteAllText($evilComSpec, 'not a real interpreter', [System.Text.UTF8Encoding]::new($false))
    Reset-HookHealthStore
    $null = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -PathPrepend $goodBin -ExtraEnv @{ ComSpec = $evilComSpec }
    Assert-True ((Get-ReceiptField -Event 'SessionStart' -Field 'observed_host_version') -eq $script:FakeVersion) 'a hijacked $env:ComSpec is ignored - the shim probe used the trusted System32 cmd.exe'
}

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- `specrew hooks doctor`: health = liveness; a substituted shim's version cannot create health/readiness ---" -ForegroundColor Cyan
function New-DoctorProject { param([string]$Name, [switch]$WithReceipt) $p = Join-Path $scratchRoot $Name; New-Item -ItemType Directory -Path (Join-Path $p '.specrew') -Force | Out-Null; if ($WithReceipt) { Write-SpecrewHookHealthReceipt -ProjectRoot $p -HostName 'codex' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion '1.2.3' | Out-Null }; return $p }
function Test-HasHealthyCodexRow { param([string]$Output) return [bool](@($Output -split "`r?`n" | Where-Object { $_ -match '^\s+codex\s+cli\s+healthy\b' }).Count) }

$dpNone = New-DoctorProject -Name 'doctor-none'
$d1 = Invoke-SpecrewCli -CliArgs @('hooks', 'doctor', '--project-path', $dpNone)
Assert-True ($d1.ExitCode -eq 0) '`specrew hooks doctor` exits 0'
Assert-True ($d1.Output -match 'host-support tiers') 'the report surfaces the host-support TIERS section'
Assert-True ($d1.Output -match 'hook-health evidence') 'the report surfaces the hook-health EVIDENCE section'
Assert-True ($d1.Output -match 'governance preflight') 'the report surfaces the Codex governance PREFLIGHT section'
Assert-True (-not (Test-HasHealthyCodexRow -Output $d1.Output)) 'a no-receipt project renders NO healthy hook-liveness row'
Assert-True ($d1.Output -match 'ready to govern a headless run:\s*NO') 'no receipt -> the Codex preflight renders NOT ready'

# THE FALSIFICATION: a matching-version shim on PATH but NO receipt -> still no health, not ready (version cannot create liveness).
$d1b = Invoke-SpecrewCli -CliArgs @('hooks', 'doctor', '--project-path', $dpNone) -PathPrepend (New-FakeCodexBin -Version 'codex-cli 1.2.3')
Assert-True (-not (Test-HasHealthyCodexRow -Output $d1b.Output)) 'a substituted PATH shim version does NOT create a healthy row without a receipt'
Assert-True ($d1b.Output -match 'ready to govern a headless run:\s*NO') 'a substituted PATH shim version does NOT flip the preflight ready without a receipt'

# A fresh receipt -> hook liveness healthy + ready, regardless of the ambient version diagnostic.
$dpFresh = New-DoctorProject -Name 'doctor-fresh' -WithReceipt
$d2 = Invoke-SpecrewCli -CliArgs @('hooks', 'doctor', '--project-path', $dpFresh)
Assert-True (Test-HasHealthyCodexRow -Output $d2.Output) 'a fresh codex receipt surfaces a healthy hook-liveness row (liveness, not the version)'
Assert-True ($d2.Output -match 'ready to govern a headless run:\s*YES') 'with a fresh codex receipt the preflight reports READY'
Assert-True ($d2.Output -notmatch '(?i)unforgeable' -and $d2.Output -notmatch '(?i)\bauthenticated\b') 'the doctor output never claims the receipt is unforgeable/authenticated'

# -----------------------------------------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue }
Write-Host ''
if ($script:Failures -gt 0) { Write-Host ("F-198 Prop-145 hook-health production-path suite: {0} assertion(s) FAILED" -f $script:Failures) -ForegroundColor Red; exit 1 }
Write-Host 'F-198 Prop-145 hook-health production-path suite: all assertions green.' -ForegroundColor Green
exit 0
