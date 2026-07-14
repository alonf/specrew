# F-198 Iteration 005 — PRODUCTION-PATH honesty regression suite for the co-review findings 2/3/4/5.
#
# The pre-existing T036/T038/T039 suites exercise the hook-health HELPERS directly (Write-SpecrewHookHealthReceipt,
# Resolve-SpecrewHookHealth) and therefore MISS the real firing paths. This suite drives the REAL surfaces:
#   * finding 2 (receipt-before-validation false-green): the REAL dispatcher via its -Event/-EventJson arg contract
#       - a malformed / empty / non-host-shaped lifecycle input records NO receipt; a genuine host-shaped
#         SessionStart/Stop fire DOES.
#   * finding 3 (a secret can enter the receipt): the REAL dispatcher reading the ambient SPECREW_OBSERVED_HOST_VERSION
#       - a secret / argument-bearing / whitespace value is NOT persisted (collapses to 'unknown'); a clean '1.2.3' passes.
#   * finding 5 ('unknown' reads healthy): the PRODUCTION default path (resolver + Codex preflight called WITHOUT an
#         expected version) - an 'unknown'/unobserved receipt is unverified (never healthy/ready); a real version is healthy.
#   * finding 4 (doctor aggregator unwired): the REAL `specrew hooks doctor` command surfaces tiers + hook-health +
#         the Codex preflight, and never health-washes.
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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scratchRoot = Join-Path $repoRoot '.scratch\f198-hook-health-prod'
$projectRoot = Join-Path $scratchRoot 'project'
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null

# The REAL governed-project fixture (deployed dispatcher copy + real refocus engine), reused so the dispatcher
# resolves its project root from $PSScriptRoot exactly as a downstream deploy does.
. (Join-Path $PSScriptRoot 'refocus-dispatcher-fixture.ps1')
$fixture = New-RefocusDispatcherFixture -ProjectRoot $projectRoot -RepoRoot $repoRoot
$dispatcher = $fixture.dispatcher
$hostBinding = $fixture.host_binding

$hookHealthStore = Join-Path $projectRoot '.specrew\runtime\hook-health'
function Reset-HookHealthStore { if (Test-Path -LiteralPath $hookHealthStore) { Remove-Item -LiteralPath $hookHealthStore -Recurse -Force } }
function Get-ReceiptFiles { if (-not (Test-Path -LiteralPath $hookHealthStore)) { return @() } return @(Get-ChildItem -LiteralPath $hookHealthStore -Filter '*.json' -File -ErrorAction SilentlyContinue) }

function Invoke-Dispatcher {
    # Drive the REAL dispatcher exactly as a host does: event JSON on stdin, the codex host binding, and the
    # project as the working directory. SPECREW_MODULE_PATH points the receipt-module resolver at this repo's
    # scripts/internal/continuous-co-review/hook-health-receipt.ps1 (a downstream deploy resolves the installed module).
    param([string]$Event = 'SessionStart', [string]$StdinJson = '', [hashtable]$ExtraEnv = @{})
    $stdoutPath = Join-Path $scratchRoot 'stdout.txt'
    $stderrPath = Join-Path $scratchRoot 'stderr.txt'
    $stdinPath = Join-Path $scratchRoot 'stdin.json'
    [System.IO.File]::WriteAllText($stdinPath, ($StdinJson ?? ''), [System.Text.UTF8Encoding]::new($false))
    $dispatcherArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', $Event, '-HostKind', 'codex')
    if (-not [string]::IsNullOrWhiteSpace($hostBinding)) { $dispatcherArgs += @('-HostBinding', $hostBinding) }
    $env0 = @{ SPECREW_MODULE_PATH = $repoRoot }
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
    # NOT set so the CLI runs in-place (no dev-tree re-dispatch); the doctor script resolves its module by $PSScriptRoot.
    param([string[]]$CliArgs)
    $stdoutPath = Join-Path $scratchRoot 'cli-stdout.txt'
    $stderrPath = Join-Path $scratchRoot 'cli-stderr.txt'
    $cli = Join-Path $repoRoot 'scripts\specrew.ps1'
    $savedMp = [Environment]::GetEnvironmentVariable('SPECREW_MODULE_PATH')
    [Environment]::SetEnvironmentVariable('SPECREW_MODULE_PATH', $null)
    try {
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $cli) + $CliArgs) `
            -WorkingDirectory $repoRoot -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $out = ((Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue) ?? '') + "`n" + ((Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue) ?? '')
        return @{ ExitCode = $proc.ExitCode; Output = $out }
    }
    finally {
        [Environment]::SetEnvironmentVariable('SPECREW_MODULE_PATH', $savedMp)
    }
}

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- FINDING 2: the dispatcher records a receipt ONLY after the host envelope validates ---" -ForegroundColor Cyan

$validSessionStart = '{"session_id":"sess-abc-123","source":"startup"}'

# A genuine, host-shaped SessionStart fire DOES record a receipt (proof-of-fire).
Reset-HookHealthStore
$r = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart
Assert-True ($r.ExitCode -eq 0) 'F2: a valid SessionStart fire exits 0 (fail-open)'
Assert-True (@(Get-ReceiptFiles).Count -eq 1) 'F2: a GENUINE host-shaped SessionStart fire records exactly one receipt'

# Each false/broken lifecycle input records NO receipt (the pre-fix false-green).
$noReceiptCases = @(
    @{ Name = 'empty event (no stdin, no -EventJson)'; Json = '' }
    @{ Name = 'malformed JSON'; Json = 'THIS_IS_NOT_JSON {{{ <<<' }
    @{ Name = 'non-host-shaped JSON array'; Json = '[1,2,3]' }
    @{ Name = 'non-host-shaped object (no host session id)'; Json = '{"foo":"bar"}' }
    @{ Name = 'empty JSON object'; Json = '{}' }
)
foreach ($c in $noReceiptCases) {
    Reset-HookHealthStore
    $rr = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $c.Json
    Assert-True ($rr.ExitCode -eq 0) ("F2: '{0}' still dispatches fail-open (exit 0)" -f $c.Name)
    Assert-True (@(Get-ReceiptFiles).Count -eq 0) ("F2: '{0}' records NO receipt (no false-green)" -f $c.Name)
}

# A non-lifecycle event (PostToolUse) never records a receipt even when host-shaped.
Reset-HookHealthStore
$rp = Invoke-Dispatcher -Event 'PostToolUse' -StdinJson '{"session_id":"sess-abc-123","tool_name":"Bash"}'
Assert-True (@(Get-ReceiptFiles).Count -eq 0) 'F2: a host-shaped PostToolUse records NO receipt (only SessionStart/Stop are lifecycle proof points)'

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- FINDING 3: an ambient SPECREW_OBSERVED_HOST_VERSION secret is NEVER persisted ---" -ForegroundColor Cyan

function Get-DispatchedObservedVersion {
    param([string]$EnvVersion)
    Reset-HookHealthStore
    $extra = @{}
    if ($null -ne $EnvVersion) { $extra['SPECREW_OBSERVED_HOST_VERSION'] = $EnvVersion }
    $null = Invoke-Dispatcher -Event 'SessionStart' -StdinJson $validSessionStart -ExtraEnv $extra
    $files = @(Get-ReceiptFiles)
    if ($files.Count -ne 1) { return "<no-receipt:$($files.Count)>" }
    return [string](Get-Content -LiteralPath $files[0].FullName -Raw | ConvertFrom-Json).observed_host_version
}

Assert-True ((Get-DispatchedObservedVersion -EnvVersion '1.2.3') -eq '1.2.3') 'F3: a CLEAN version (1.2.3) is persisted verbatim'
Assert-True ((Get-DispatchedObservedVersion -EnvVersion 'codex-cli-0.144.1') -eq 'codex-cli-0.144.1') 'F3: a clean hyphenated version token passes'
Assert-True ((Get-DispatchedObservedVersion -EnvVersion 'SECRET=abc123 export TOKEN=zzz') -eq 'unknown') 'F3: a SECRET/argument-bearing value is NOT persisted (collapses to unknown)'
Assert-True ((Get-DispatchedObservedVersion -EnvVersion 'codex cli 0.144.1') -eq 'unknown') 'F3: a whitespace-laden value is rejected to unknown'
Assert-True ((Get-DispatchedObservedVersion -EnvVersion "1.2.3`n--dangerously-bypass-hook-trust") -eq 'unknown') 'F3: a multi-line value is rejected to unknown'
Assert-True ((Get-DispatchedObservedVersion -EnvVersion ('a' * 200)) -eq 'unknown') 'F3: an over-long value is rejected to unknown'
Assert-True ((Get-DispatchedObservedVersion -EnvVersion $null) -eq 'unknown') 'F3: an unset version records the honest unknown sentinel'

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- FINDING 5: an 'unknown' observed version is UNVERIFIED on the production default path ---" -ForegroundColor Cyan

. (Join-Path $repoRoot 'scripts\internal\continuous-co-review\hook-health-receipt.ps1')
$baseTime = [datetime]::Parse('2026-07-14T12:00:00Z').ToUniversalTime()

function New-HealthTempRoot {
    $root = Join-Path $scratchRoot ('recon-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    return $root
}

# The resolver, called with NO expected version (exactly how Format-SpecrewHookHealthReport and the Codex
# preflight call it): an 'unknown'/unobserved receipt is unverified; a real version is healthy.
$rootUnknown = New-HealthTempRoot
Write-SpecrewHookHealthReceipt -ProjectRoot $rootUnknown -HostName 'codex' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion 'unknown' -TimestampUtc $baseTime | Out-Null
$hUnknown = Resolve-SpecrewHookHealth -ProjectRoot $rootUnknown -HostName 'codex' -Surface 'cli' -Now $baseTime.AddHours(1)
Assert-True ($hUnknown.status -eq 'unverified') "F5: default path - an 'unknown' observed version resolves UNVERIFIED"
Assert-True ($hUnknown.status -ne 'healthy') "F5: default path - an 'unknown' observed version is NEVER healthy"

$rootReal = New-HealthTempRoot
Write-SpecrewHookHealthReceipt -ProjectRoot $rootReal -HostName 'codex' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion '1.2.3' -TimestampUtc $baseTime | Out-Null
$hReal = Resolve-SpecrewHookHealth -ProjectRoot $rootReal -HostName 'codex' -Surface 'cli' -Now $baseTime.AddHours(1)
Assert-True ($hReal.status -eq 'healthy') 'F5: default path - a REAL observed version resolves healthy'

# A literal EMPTY observed version cannot occur on the production path (the dispatcher emits 'unknown', never ''),
# and an empty required field is caught EARLIER as a MALFORMED receipt -> degraded (the pre-existing T038
# malformed-empty contract). Either way it is NEVER healthy - assert that honestly.
$rootEmpty = New-HealthTempRoot
Write-SpecrewHookHealthReceipt -ProjectRoot $rootEmpty -HostName 'codex' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion '' -TimestampUtc $baseTime | Out-Null
$hEmpty = Resolve-SpecrewHookHealth -ProjectRoot $rootEmpty -HostName 'codex' -Surface 'cli' -Now $baseTime.AddHours(1)
Assert-True ($hEmpty.status -ne 'healthy') 'F5: an empty observed version is never healthy'
Assert-True (@('unverified', 'degraded') -contains $hEmpty.status) 'F5: an empty observed version is a non-healthy closed-set status (degraded via the malformed-empty contract)'

# The Codex headless preflight (which calls the resolver WITHOUT an expected version) must not report ready on 'unknown'.
$pfUnknown = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $rootUnknown -Now $baseTime.AddHours(1)
Assert-True (-not $pfUnknown.ready) "F5: the Codex preflight is NOT ready on an 'unknown' receipt"
Assert-True ($pfUnknown.status -eq 'unverified') "F5: the Codex preflight reports unverified on 'unknown'"
$pfReal = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $rootReal -Now $baseTime.AddHours(1)
Assert-True ($pfReal.ready) 'F5: the Codex preflight IS ready on a real-version fresh receipt'

# -----------------------------------------------------------------------------------------------------------
Write-Host "`n--- FINDING 4: `specrew hooks doctor` surfaces tiers + hook-health + the Codex preflight ---" -ForegroundColor Cyan

$doctorProject = Join-Path $scratchRoot 'doctor-project'
New-Item -ItemType Directory -Path (Join-Path $doctorProject '.specrew') -Force | Out-Null

# No receipts yet -> all three sections render, health is unverified (no healthy row), preflight NOT ready.
$d1 = Invoke-SpecrewCli -CliArgs @('hooks', 'doctor', '--project-path', $doctorProject)
Assert-True ($d1.ExitCode -eq 0) 'F4: `specrew hooks doctor` exits 0'
Assert-True ($d1.Output -match 'host-support tiers') 'F4: the doctor report surfaces the host-support TIERS section'
Assert-True ($d1.Output -match 'hook-health evidence') 'F4: the doctor report surfaces the hook-health EVIDENCE section'
Assert-True ($d1.Output -match 'governance preflight') 'F4: the doctor report surfaces the Codex untrusted-headless PREFLIGHT section'
Assert-True ($d1.Output -match 'ready to govern a headless run:\s*NO') 'F4: no receipt -> the Codex preflight renders NOT ready'
Assert-True (-not (@($d1.Output -split "`r?`n" | Where-Object { $_ -match '^\s+(claude|codex|codex|copilot)\s+cli\s+healthy\b' }).Count)) 'F4: a no-receipt project renders NO healthy health row (never health-washed)'

# A fresh codex/cli receipt with a REAL observed version -> the SAME command reports it healthy + ready (honest surfacing).
Write-SpecrewHookHealthReceipt -ProjectRoot $doctorProject -HostName 'codex' -Event 'Stop' -Surface 'cli' -ObservedHostVersion '1.2.3' | Out-Null
$d2 = Invoke-SpecrewCli -CliArgs @('hooks', 'doctor', '--project-path', $doctorProject)
Assert-True (@($d2.Output -split "`r?`n" | Where-Object { $_ -match '^\s+codex\s+cli\s+healthy\b' }).Count -ge 1) 'F4: a fresh real-version codex receipt surfaces a healthy codex row through the REAL command'
Assert-True ($d2.Output -match 'ready to govern a headless run:\s*YES') 'F4: with a current codex receipt the command reports the Codex preflight READY'

# An 'unknown'-version receipt must NOT flip the command to healthy/ready (finding 5 through the real command).
$doctorProject2 = Join-Path $scratchRoot 'doctor-project-unknown'
New-Item -ItemType Directory -Path (Join-Path $doctorProject2 '.specrew') -Force | Out-Null
Write-SpecrewHookHealthReceipt -ProjectRoot $doctorProject2 -HostName 'codex' -Event 'Stop' -Surface 'cli' -ObservedHostVersion 'unknown' | Out-Null
$d3 = Invoke-SpecrewCli -CliArgs @('hooks', 'doctor', '--project-path', $doctorProject2)
Assert-True (-not (@($d3.Output -split "`r?`n" | Where-Object { $_ -match '^\s+codex\s+cli\s+healthy\b' }).Count)) 'F4: an unknown-version codex receipt does NOT surface a healthy row through the command (finding 5)'
Assert-True ($d3.Output -match 'ready to govern a headless run:\s*NO') 'F4: an unknown-version codex receipt keeps the Codex preflight NOT ready through the command'

# -----------------------------------------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host ''
if ($script:Failures -gt 0) {
    Write-Host ("F-198 iter-005 hook-health production-path suite: {0} assertion(s) FAILED" -f $script:Failures) -ForegroundColor Red
    exit 1
}
Write-Host 'F-198 iter-005 hook-health production-path suite: all assertions green.' -ForegroundColor Green
exit 0
