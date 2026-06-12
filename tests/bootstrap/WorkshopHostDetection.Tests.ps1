# F-174 iter-10 (T004): the design-workshop refresh stamps the REAL host.
#
# The 2026-06-12 dogfood found the rolling handover written during the pre-specify design workshop carried
# `from_host: host` (the literal sentinel) on codex + copilot: the workshop refresh runs the handover
# provider WITHOUT --host-kind (it is agent-invoked, not via the per-host hook dispatcher), and in the
# pre-specify window the anchor has no committed host either, so resolution fell through to 'host'.
# Update-SpecrewRollingHandover now detects the LIVE host from env signals (Get-SpecrewRuntimeHostFromEnv)
# to fill that gap - correct across the shared .agents skill root (codex vs antigravity by distinct env
# vars), never stale, and degrading to the honest 'host' when nothing matches.
$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
. "$base/ProjectMetadataAccessor.ps1"

function Assert-Equal {
    param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-Null {
    param([AllowNull()]$Actual, [string]$Message)
    if ($null -ne $Actual) { throw "FAIL: $Message (expected `$null, got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# This test process is a CHILD of whatever host launched the suite (e.g. claude sets CLAUDECODE), so its
# env already carries a host signal. Snapshot + clear every signal so detection is deterministic, restore in finally.
$allSignals = @('CODEX_SESSION_ID', 'OPENAI_CODEX_CLI', 'CODEX_API_KEY',
    'CLAUDECODE', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_PROJECT_DIR',
    'COPILOT_AGENT_SESSION_ID', 'COPILOT_CLI', 'COPILOT_CLI_BINARY_VERSION',
    'CURSOR_AGENT', 'CURSOR_TRACE_ID', 'CURSOR_API_KEY',
    'ANTIGRAVITY_SESSION_ID', 'ANTIGRAVITY_API_KEY', 'GOOGLE_AI_SUBSCRIPTION_TIER')
$saved = @{}
foreach ($v in $allSignals) { $saved[$v] = [Environment]::GetEnvironmentVariable($v) }
function Clear-AllSignals { foreach ($v in $script:allSignals) { Set-Item -Path "env:$v" -Value '' -ErrorAction SilentlyContinue; [Environment]::SetEnvironmentVariable($v, $null) } }

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t004-host-" + [guid]::NewGuid().ToString('N'))
try {
    # --- 1. Get-SpecrewRuntimeHostFromEnv unit: each host detected by its own signal; none -> $null --------
    Clear-AllSignals
    Assert-Null (Get-SpecrewRuntimeHostFromEnv) 'no host env signal -> $null (caller keeps the honest "host" sentinel)'

    Clear-AllSignals; [Environment]::SetEnvironmentVariable('CODEX_SESSION_ID', 'abc')
    Assert-Equal (Get-SpecrewRuntimeHostFromEnv) 'codex' 'CODEX_SESSION_ID -> codex'

    Clear-AllSignals; [Environment]::SetEnvironmentVariable('CLAUDECODE', '1')
    Assert-Equal (Get-SpecrewRuntimeHostFromEnv) 'claude' 'CLAUDECODE -> claude'

    Clear-AllSignals; [Environment]::SetEnvironmentVariable('COPILOT_AGENT_SESSION_ID', 'x')
    Assert-Equal (Get-SpecrewRuntimeHostFromEnv) 'copilot' 'COPILOT_AGENT_SESSION_ID -> copilot'

    Clear-AllSignals; [Environment]::SetEnvironmentVariable('CURSOR_AGENT', '1')
    Assert-Equal (Get-SpecrewRuntimeHostFromEnv) 'cursor' 'CURSOR_AGENT -> cursor'

    # The shared .agents skill root case that per-host baking could NOT disambiguate:
    Clear-AllSignals; [Environment]::SetEnvironmentVariable('ANTIGRAVITY_SESSION_ID', 'g')
    Assert-Equal (Get-SpecrewRuntimeHostFromEnv) 'antigravity' 'ANTIGRAVITY_SESSION_ID -> antigravity (shared .agents root disambiguated by env, not folder)'

    # A credential var that is often GLOBALLY set must not, alone, masquerade as an active session:
    Clear-AllSignals; [Environment]::SetEnvironmentVariable('CODEX_API_KEY', 'k')
    Assert-Null (Get-SpecrewRuntimeHostFromEnv) 'a lone credential var (CODEX_API_KEY) does NOT trigger a false codex match'

    # --- 2. Resolution chain through Update-SpecrewRollingHandover (the workshop refresh path) -------------
    $proj = Join-Path $tmp 'proj'
    New-Item -ItemType Directory -Path (Join-Path $proj 'specs/001-notekeep') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t'; git -C $proj config user.name 't'
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    git -C $proj checkout -q -b '001-notekeep' 2>$null
    # Pre-specify workshop window: start-context names the feature but NOT a host (the anchorless case).
    (@{ session_state = @{ feature_ref = '001-notekeep'; boundary_type = 'before-implement' } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $proj '.specrew/start-context.json') -Encoding UTF8
    $hd = Join-Path $proj '.specrew/handover'
    function Dirty { param($n) Set-Content -LiteralPath (Join-Path $script:proj 'notekeep.py') -Value "print('$n')`n" -Encoding UTF8 }
    $proj | Out-Null

    # (a) no env, no --host-kind, no state host -> the honest 'host' sentinel (unchanged when undetectable).
    Clear-AllSignals
    Set-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('a')`n" -Encoding UTF8
    Update-SpecrewRollingHandover -ProjectRoot $proj -Source 'workshop' -NowUtc '2026-06-12T03:00:00Z' | Out-Null
    Assert-Equal (Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T03:00:01Z').from_host 'host' 'no signal + no --host-kind + no state host -> honest "host" sentinel'

    # (b) env signal present, still no --host-kind -> the LIVE host fills the gap (the dogfood fix).
    Clear-AllSignals; [Environment]::SetEnvironmentVariable('CODEX_SESSION_ID', 'sess')
    Set-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('b')`n" -Encoding UTF8
    Update-SpecrewRollingHandover -ProjectRoot $proj -Source 'workshop' -NowUtc '2026-06-12T03:01:00Z' | Out-Null
    Assert-Equal (Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T03:01:01Z').from_host 'codex' 'env CODEX_SESSION_ID fills the gap -> from_host=codex (no more literal "host" on the workshop refresh)'

    # (c) --host-kind is authoritative and still wins over the env signal.
    Clear-AllSignals; [Environment]::SetEnvironmentVariable('CODEX_SESSION_ID', 'sess')
    Set-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('c')`n" -Encoding UTF8
    Update-SpecrewRollingHandover -ProjectRoot $proj -HostKind 'claude' -Source 'workshop' -NowUtc '2026-06-12T03:02:00Z' | Out-Null
    Assert-Equal (Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T03:02:01Z').from_host 'claude' 'explicit --host-kind still wins over the env signal (authoritative)'

    # (d) a committed session-state host fills BEFORE env detection (env only fills the "host" gap).
    (@{ session_state = @{ feature_ref = '001-notekeep'; boundary_type = 'before-implement'; host = 'copilot' } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $proj '.specrew/start-context.json') -Encoding UTF8
    Clear-AllSignals; [Environment]::SetEnvironmentVariable('CODEX_SESSION_ID', 'sess')
    Set-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('d')`n" -Encoding UTF8
    Update-SpecrewRollingHandover -ProjectRoot $proj -Source 'workshop' -NowUtc '2026-06-12T03:03:00Z' | Out-Null
    Assert-Equal (Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T03:03:01Z').from_host 'copilot' 'a committed session-state host is used and env detection does NOT override it (env only fills the gap)'
}
finally {
    foreach ($v in $allSignals) {
        if ($null -eq $saved[$v]) { [Environment]::SetEnvironmentVariable($v, $null) }
        else { [Environment]::SetEnvironmentVariable($v, $saved[$v]) }
    }
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'WorkshopHostDetection: all tests passed.' -ForegroundColor Green
