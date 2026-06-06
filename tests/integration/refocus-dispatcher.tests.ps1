# Feature 171 T006: SpecrewHookDispatcher tests (FR-008/FR-012; SC-001, SC-007).
# Simulated host-event JSON through the REAL dispatcher + REAL engine + REAL
# digests on a scratch project: routing per event/source, output shaping,
# kill-switch placement, self-gate, fail-open on every failure class, provider
# confinement, timeout, and the DORMANT F-165 gate path (fixture-only).
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scratchRoot = Join-Path $repoRoot '.scratch\refocus-dispatcher'
$projectRoot = Join-Path $scratchRoot 'project'

if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null

function New-ScratchProject {
    if (Test-Path -LiteralPath $projectRoot) { Remove-Item -LiteralPath $projectRoot -Recurse -Force }
    $scriptsDir = Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts'
    $refocusDir = Join-Path $projectRoot '.specify\extensions\specrew-speckit\refocus'
    New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $refocusDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts\internal\specrew-hook-dispatcher.ps1') -Destination $scriptsDir -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts\internal\refocus.ps1') -Destination $scriptsDir -Force
    Copy-Item -Path (Join-Path $repoRoot 'extensions\specrew-speckit\refocus\*.md') -Destination $refocusDir -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\refocus-scopes.json') -Destination (Join-Path $projectRoot '.specify\extensions\specrew-speckit') -Force
    $startContext = @{ session_state = @{ boundary_type = 'implement'; feature_ref = 'dispatcher-fixture' } } | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $startContext, [System.Text.UTF8Encoding]::new($false))
    return (Join-Path $scriptsDir 'specrew-hook-dispatcher.ps1')
}

function Invoke-Dispatcher {
    # Event JSON is delivered via STDIN REDIRECTION — the production path (Claude
    # hooks pipe event JSON on stdin) and immune to Start-Process quote mangling.
    param([string]$Dispatcher, [string[]]$DispatcherArgs, [string]$StdinJson, [string]$WorkingDirectory = $projectRoot, [hashtable]$ExtraEnv = @{})
    $stdoutPath = Join-Path $scratchRoot 'stdout.txt'
    $stderrPath = Join-Path $scratchRoot 'stderr.txt'
    $stdinPath = Join-Path $scratchRoot 'stdin.json'
    [System.IO.File]::WriteAllText($stdinPath, ($StdinJson ?? ''), [System.Text.UTF8Encoding]::new($false))
    $saved = @{}
    foreach ($key in $ExtraEnv.Keys) { $saved[$key] = [Environment]::GetEnvironmentVariable($key); [Environment]::SetEnvironmentVariable($key, $ExtraEnv[$key]) }
    try {
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Dispatcher) + $DispatcherArgs) `
            -WorkingDirectory $WorkingDirectory -Wait -PassThru -NoNewWindow `
            -RedirectStandardInput $stdinPath -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        return @{
            ExitCode = $proc.ExitCode
            StdOut   = (Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue) ?? ''
            StdErr   = (Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue) ?? ''
        }
    }
    finally {
        foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) }
    }
}

$eventCompact = '{"session_id":"sess-abc-123","source":"compact"}'
$eventStartup = '{"session_id":"sess-abc-123","source":"startup"}'
$eventTool = '{"session_id":"sess-abc-123","tool_name":"Bash"}'

# --- 1. B1: SessionStart source=compact -> plain stdout, current-stage scope ----
$dispatcher = New-ScratchProject
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson $eventCompact
Assert-True ($result.ExitCode -eq 0) 'B1 exits 0'
Assert-True ($result.StdOut -match '\[specrew-refocus\] trigger=b1 scope=general\+boundary\.implement ') 'B1 routes compact -> trigger b1 with current stage'
Assert-True (-not $result.StdOut.Contains('hookSpecificOutput')) 'SessionStart output is PLAIN stdout (host adds to context)'
Assert-True ($result.StdOut.Contains('Implement-stage discipline')) 'B1 payload carries the current-stage digest'

# --- 2. B2: SessionStart source=startup -> launch grounding ----------------------
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson $eventStartup
Assert-True ($result.ExitCode -eq 0) 'B2 exits 0'
Assert-True ($result.StdOut -match '\[specrew-refocus\] trigger=b2 scope=general ') 'B2 routes startup -> trigger b2 (general grounding)'

# --- 3. B3: PostToolUse -> hookSpecificOutput JSON shape (after a real crossing) ---
# First call ANCHORS (T007 semantics: never inject on first sight); the crossing
# then triggers the JSON-shaped injection.
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson $eventTool
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut)) 'B3 first sight anchors (no injection)'
$ctx = @{ session_state = @{ boundary_type = 'review-signoff'; feature_ref = 'dispatcher-fixture' } } | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $ctx, [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson $eventTool
Assert-True ($result.ExitCode -eq 0) 'B3 crossing exits 0'
$json = $null
try { $json = $result.StdOut | ConvertFrom-Json } catch { }
Assert-True ($null -ne $json -and $null -ne $json.hookSpecificOutput) 'PostToolUse output is hookSpecificOutput JSON'
Assert-True ($null -ne $json -and $json.hookSpecificOutput.additionalContext -match 'trigger=b3') 'B3 additionalContext carries the b3 payload'

# --- 4. Kill switch is the FIRST executable line (works even with broken catalog) -
$dispatcher = New-ScratchProject
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\extensions\specrew-speckit\refocus-scopes.json'), '{not json', [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson $eventCompact -ExtraEnv @{ SPECREW_REFOCUS_DISABLE = '1' }
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut) -and [string]::IsNullOrWhiteSpace($result.StdErr)) 'kill switch silences BEFORE any parsing (broken catalog never reached)'

# --- 5. Broken catalog without kill switch: quiet + one WARN ----------------------
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson $eventCompact
Assert-True ($result.ExitCode -eq 0) 'broken catalog exits 0 (fail-open)'
Assert-True ($result.StdErr.Contains('WARN CATALOG_SCHEMA')) 'broken catalog warns CATALOG_SCHEMA once'
Assert-True ([string]::IsNullOrWhiteSpace($result.StdOut)) 'broken catalog: automation goes quiet'

# --- 6. Self-gate: non-Specrew directory is a silent no-op ------------------------
$bareDir = Join-Path ([System.IO.Path]::GetTempPath()) ('specrew-refocus-bare-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $bareDir -Force | Out-Null
$dispatcherCopy = Join-Path $bareDir 'specrew-hook-dispatcher.ps1'
Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts\internal\specrew-hook-dispatcher.ps1') -Destination $dispatcherCopy -Force
$result = Invoke-Dispatcher -Dispatcher $dispatcherCopy -DispatcherArgs @('-Event', 'SessionStart') -StdinJson $eventCompact -WorkingDirectory $bareDir
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut) -and [string]::IsNullOrWhiteSpace($result.StdErr)) 'non-Specrew directory: silent no-op'

# --- 7. Malformed event JSON: EVENT_PARSE + quiet ----------------------------------
$dispatcher = New-ScratchProject
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson '{broken'
Assert-True ($result.ExitCode -eq 0) 'malformed event JSON exits 0'
Assert-True ($result.StdErr.Contains('WARN EVENT_PARSE')) 'malformed event JSON warns EVENT_PARSE'
Assert-True ([string]::IsNullOrWhiteSpace($result.StdOut)) 'malformed event JSON: no injection'

# --- 8. Provider crash: PROVIDER_FAILED + session unaffected ------------------------
$dispatcher = New-ScratchProject
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\refocus.ps1'), "[Console]::Error.WriteLine('boom'); exit 1", [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson $eventCompact
Assert-True ($result.ExitCode -eq 0) 'provider crash: dispatcher exits 0'
Assert-True ($result.StdErr.Contains('WARN PROVIDER_FAILED')) 'provider crash warns PROVIDER_FAILED'

# --- 9. Provider timeout: skipped + WARN --------------------------------------------
$dispatcher = New-ScratchProject
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\refocus.ps1'), "Start-Sleep -Seconds 30", [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart', '-ProviderTimeoutSeconds', '1') -StdinJson $eventCompact
Assert-True ($result.ExitCode -eq 0) 'provider timeout: dispatcher exits 0'
Assert-True ($result.StdErr.Contains('timed out')) 'provider timeout warns and skips'

# --- 10. Out-of-tree provider command refused ----------------------------------------
$dispatcher = New-ScratchProject
$catalogPath = Join-Path $projectRoot '.specify\extensions\specrew-speckit\refocus-scopes.json'
$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$catalog.providers[0].command = 'no-such-script.ps1'
[System.IO.File]::WriteAllText($catalogPath, ($catalog | ConvertTo-Json -Depth 6), [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson $eventCompact
Assert-True ($result.ExitCode -eq 0) 'unresolvable provider command exits 0'
Assert-True ($result.StdErr.Contains('WARN SOURCE_CONFINED')) 'unresolvable provider command warns SOURCE_CONFINED'

# --- 11. DORMANT gate path (F-165 seat; fixture-only — ships unregistered) -----------
$dispatcher = New-ScratchProject
$gateScript = Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\test-gate.ps1'
[System.IO.File]::WriteAllText($gateScript, '@{ hookSpecificOutput = @{ hookEventName = ''PreToolUse''; permissionDecision = ''deny''; permissionDecisionReason = ''fixture gate'' } } | ConvertTo-Json -Depth 4 -Compress | Write-Output; exit 0', [System.Text.UTF8Encoding]::new($false))
$catalog = Get-Content -LiteralPath $catalogPath -Raw -ErrorAction SilentlyContinue
$catalogPath = Join-Path $projectRoot '.specify\extensions\specrew-speckit\refocus-scopes.json'
$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$gateRow = [pscustomobject]@{ id = 'fixture-gate'; kind = 'gate'; events = @('PreToolUse'); order = 20; command = 'test-gate.ps1' }
$catalog.providers = @($catalog.providers) + @($gateRow)
[System.IO.File]::WriteAllText($catalogPath, ($catalog | ConvertTo-Json -Depth 6), [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PreToolUse') -StdinJson $eventTool
$json = $null
try { $json = $result.StdOut | ConvertFrom-Json } catch { }
Assert-True ($result.ExitCode -eq 0) 'gate event exits 0'
Assert-True ($null -ne $json -and [string]$json.hookSpecificOutput.permissionDecision -eq 'deny') 'gate provider permissionDecision passes through (fixture deny)'
# Gate provider does NOT run on SessionStart (event filtering).
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson $eventStartup
Assert-True (-not $result.StdOut.Contains('permissionDecision')) 'gate provider does not run on SessionStart'
# Gate crash fails OPEN to allow.
[System.IO.File]::WriteAllText($gateScript, 'exit 1', [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PreToolUse') -StdinJson $eventTool
$json = $null
try { $json = $result.StdOut | ConvertFrom-Json } catch { }
Assert-True ($null -ne $json -and [string]$json.hookSpecificOutput.permissionDecision -eq 'allow') 'crashed gate fails OPEN to allow'
Assert-True ($result.StdErr.Contains('failing OPEN')) 'crashed gate warns it failed open'

# --- 12. T007: B3 state-diff + dedupe (watch the state, never the actor) --------------
$dispatcher = New-ScratchProject
$eventB3 = '{"session_id":"b3-session-1","tool_name":"Bash"}'
$statePath = Join-Path $projectRoot '.specrew\runtime\refocus-state-b3-session-1.json'
function Set-Cursor {
    param([string]$Boundary)
    $ctx = @{ session_state = @{ boundary_type = $Boundary; feature_ref = 'dispatcher-fixture' } } | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $ctx, [System.Text.UTF8Encoding]::new($false))
}

# 12a. First sight: ANCHOR — no injection, state created.
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson $eventB3
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut)) 'B3 first sight anchors silently (no spurious injection)'
Assert-True (Test-Path -LiteralPath $statePath -PathType Leaf) 'B3 anchor creates the per-session state file'
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
Assert-True ([string]$state.last_seen_boundary -eq 'implement') 'anchor records the live cursor'

# 12b. Same cursor: silent.
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson $eventB3
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut)) 'unchanged cursor stays silent'

# 12c. Crossing WITHOUT channel-1 fingerprint (bypass path): inject.
Set-Cursor -Boundary 'review-signoff'
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson $eventB3
$json = $null
try { $json = $result.StdOut | ConvertFrom-Json } catch { }
Assert-True ($null -ne $json -and $json.hookSpecificOutput.additionalContext -match 'trigger=b3 scope=general\+boundary\.retro ') 'un-fingerprinted crossing injects the INCOMING stage (review-signoff -> retro)'
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
Assert-True ([string]$state.last_seen_boundary -eq 'review-signoff') 'injection updates last_seen'

# 12d. Crossing WITH channel-1 fingerprint: dedupe (silent).
Set-Cursor -Boundary 'retro'
$fingerprint = @{ boundary = 'retro'; at = '2026-06-07T00:00:00Z' } | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\runtime\refocus-channel1.json'), $fingerprint, [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson $eventB3
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut)) 'wrapper-fingerprinted crossing dedupes (no double payload)'
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
Assert-True ([string]$state.last_seen_boundary -eq 'retro') 'dedupe still advances last_seen'

# 12e. Corrupt state: STATE_UNAVAILABLE, quiet, session unaffected.
[System.IO.File]::WriteAllText($statePath, '{corrupt', [System.Text.UTF8Encoding]::new($false))
Set-Cursor -Boundary 'iteration-closeout'
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson $eventB3
Assert-True ($result.ExitCode -eq 0) 'corrupt state exits 0'
Assert-True ($result.StdErr.Contains('WARN STATE_UNAVAILABLE')) 'corrupt state warns STATE_UNAVAILABLE'
Assert-True ([string]::IsNullOrWhiteSpace($result.StdOut)) 'corrupt state: no automatic injection (manual + channel 1 unaffected)'

# --- summary --------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "refocus-dispatcher tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host 'refocus-dispatcher tests: all passed' -ForegroundColor Green
exit 0
