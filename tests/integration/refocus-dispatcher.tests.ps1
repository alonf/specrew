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
    $catalogPath = Join-Path $projectRoot '.specify\extensions\specrew-speckit\refocus-scopes.json'
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\refocus-scopes.json') -Destination (Join-Path $projectRoot '.specify\extensions\specrew-speckit') -Force
    $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
    # This fixture exercises the refocus dispatcher in isolation. Provider-fallback composition for bootstrap
    # is covered by DispatcherSessionStartPolicy.Tests.ps1; keeping only refocus here prevents that fallback from
    # obscuring breaker-suppression assertions.
    $catalog.providers = @($catalog.providers | Where-Object { [string]$_.id -eq 'refocus' })
    [System.IO.File]::WriteAllText($catalogPath, ($catalog | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
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
    $effectiveArgs = @($DispatcherArgs)
    if ($effectiveArgs -notcontains '-HostBinding') {
        $hostArgIndex = [array]::IndexOf($effectiveArgs, '-HostKind')
        if ($hostArgIndex -ge 0 -and ($hostArgIndex + 1) -lt $effectiveArgs.Count) {
            $manifestPath = Join-Path $repoRoot ("hosts\{0}\host.psd1" -f $effectiveArgs[$hostArgIndex + 1])
            if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
                $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
                $runtime = $manifest.RefocusHookBindings.DispatcherRuntime
                if ($null -ne $runtime) {
                    $binding = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($runtime | ConvertTo-Json -Depth 8 -Compress)))
                    $effectiveArgs += @('-HostBinding', $binding)
                }
            }
        }
    }
    $saved = @{}
    foreach ($key in $ExtraEnv.Keys) { $saved[$key] = [Environment]::GetEnvironmentVariable($key); [Environment]::SetEnvironmentVariable($key, $ExtraEnv[$key]) }
    try {
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Dispatcher) + $effectiveArgs) `
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

# --- 13. T008: journal + outcomes + ring bound + pruning -------------------------------
$dispatcher = New-ScratchProject
$eventJ = '{"session_id":"journal-1","source":"compact"}'
$jStatePath = Join-Path $projectRoot '.specrew\runtime\refocus-state-journal-1.json'

# 13a. B1 injection journals injected + tokens.
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson $eventJ
$state = Get-Content -LiteralPath $jStatePath -Raw | ConvertFrom-Json
$entry = @($state.journal) | Select-Object -Last 1
Assert-True ($null -ne $entry -and [string]$entry.trigger -eq 'b1' -and [string]$entry.outcome -eq 'injected' -and [int]$entry.tokens -gt 0) 'B1 injection journaled with tokens'
Assert-True ([string]$entry.channel -eq 'hook') 'journal records the channel'

# 13b. B3 dedupe journals deduped.
$eventJ3 = '{"session_id":"journal-1","tool_name":"Bash"}'
$null = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson $eventJ3   # anchor
$ctx = @{ session_state = @{ boundary_type = 'review-signoff'; feature_ref = 'dispatcher-fixture' } } | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $ctx, [System.Text.UTF8Encoding]::new($false))
$fingerprint = @{ boundary = 'review-signoff'; at = '2026-06-07T00:00:00Z' } | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\runtime\refocus-channel1.json'), $fingerprint, [System.Text.UTF8Encoding]::new($false))
$null = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson $eventJ3
$state = Get-Content -LiteralPath $jStatePath -Raw | ConvertFrom-Json
$entry = @($state.journal) | Select-Object -Last 1
Assert-True ($null -ne $entry -and [string]$entry.outcome -eq 'deduped' -and [string]$entry.trigger -eq 'b3') 'B3 dedupe journaled'

# 13c. Provider crash journals failed.
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\refocus.ps1'), 'exit 1', [System.Text.UTF8Encoding]::new($false))
$null = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson $eventJ
$state = Get-Content -LiteralPath $jStatePath -Raw | ConvertFrom-Json
$entry = @($state.journal) | Select-Object -Last 1
Assert-True ($null -ne $entry -and [string]$entry.outcome -eq 'failed') 'provider crash journaled as failed'

# 13d. Ring bound: journal never exceeds 20.
$dispatcher = New-ScratchProject
# Seed with b1 entries (tokens=1) so the b2 event neither runaway-trips (different
# trigger) nor token-trips (sum 20) — the ring bound is what's under test here.
$entries = @(1..25 | ForEach-Object { [pscustomobject]@{ at = '2026-06-07T00:00:00Z'; trigger = 'b1'; scope = 'general'; channel = 'hook'; tokens = 1; outcome = 'injected' } })
$seed = [pscustomobject]@{ session_id = 'journal-2'; last_seen_boundary = $null; context_mtime = $null; breaker = $null; journal = $entries[0..19] }
$jStatePath2 = Join-Path $projectRoot '.specrew\runtime\refocus-state-journal-2.json'
New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew\runtime') -Force | Out-Null
[System.IO.File]::WriteAllText($jStatePath2, ($seed | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
$null = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson '{"session_id":"journal-2","source":"startup"}'
$state = Get-Content -LiteralPath $jStatePath2 -Raw | ConvertFrom-Json
Assert-True (@($state.journal).Count -eq 20) 'journal ring stays bounded at 20'
$entry = @($state.journal) | Select-Object -Last 1
Assert-True ([string]$entry.trigger -eq 'b2' -and [string]$entry.outcome -eq 'injected') 'newest entry survives the ring'

# 13e. Pruning: stale state files swept at dispatcher start.
$stalePath = Join-Path $projectRoot '.specrew\runtime\refocus-state-old-one.json'
[System.IO.File]::WriteAllText($stalePath, '{}', [System.Text.UTF8Encoding]::new($false))
(Get-Item -LiteralPath $stalePath).LastWriteTime = (Get-Date).AddDays(-30)
$null = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson '{"session_id":"journal-2","source":"startup"}'
Assert-True (-not (Test-Path -LiteralPath $stalePath)) 'stale session state pruned (~7 days)'

# --- 14. T009: circuit breaker (runaway / token cap / reset / exemptions) -------------
$dispatcher = New-ScratchProject
$runtimeDir = Join-Path $projectRoot '.specrew\runtime'
New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
function New-SeedState {
    param([string]$SessionId, [object[]]$Journal)
    $seed = [pscustomobject]@{ session_id = $SessionId; last_seen_boundary = $null; context_mtime = $null; breaker = $null; journal = $Journal }
    $path = Join-Path $runtimeDir ("refocus-state-{0}.json" -f $SessionId)
    [System.IO.File]::WriteAllText($path, ($seed | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
    return $path
}
function New-JournalSeed { param([string]$Trigger, [int]$Count, [int]$Tokens = 100) @(1..$Count | ForEach-Object { [pscustomobject]@{ at = '2026-06-07T01:00:00Z'; trigger = $Trigger; scope = 'general'; channel = 'hook'; tokens = $Tokens; outcome = 'injected' } }) }

# 14a. Repeat-injection runaway trips ONLY that trigger, loudly once.
$b2State = New-SeedState -SessionId 'breaker-1' -Journal (New-JournalSeed -Trigger 'b2' -Count 3)
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson '{"session_id":"breaker-1","source":"startup"}'
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut)) 'runaway b2: no injection'
Assert-True ($result.StdErr.Contains('WARN BREAKER_TRIPPED') -and $result.StdErr.Contains('--reset-breaker')) 'runaway trip warns ONCE naming reason + re-enable paths'
$state = Get-Content -LiteralPath $b2State -Raw | ConvertFrom-Json
Assert-True ([bool]$state.breaker.tripped -and (@($state.breaker.scopes) -contains 'b2') -and -not (@($state.breaker.scopes) -contains 'all')) 'trip scope is the malfunctioning trigger only'
Assert-True ([string](@($state.journal) | Select-Object -Last 1).outcome -eq 'breaker-suppressed') 'suppression journaled'

# 14b. Subsequent suppression is SILENT (loud once).
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson '{"session_id":"breaker-1","source":"startup"}'
Assert-True ([string]::IsNullOrWhiteSpace($result.StdOut) -and -not $result.StdErr.Contains('BREAKER_TRIPPED')) 'tripped suppression stays silent (no warn spam)'

# 14c. Per-trigger scope: b3 still works while b2 is tripped.
$null = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson '{"session_id":"breaker-1","tool_name":"Bash"}'   # anchor
$ctx = @{ session_state = @{ boundary_type = 'review-signoff'; feature_ref = 'dispatcher-fixture' } } | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $ctx, [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse') -StdinJson '{"session_id":"breaker-1","tool_name":"Bash"}'
Assert-True ($result.StdOut.Contains('trigger=b3')) 'b3 keeps working while b2 is tripped (malfunction-focused scope)'

# 14d. Session token cap trips ALL hook triggers.
$dispatcher = New-ScratchProject
New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
$null = New-SeedState -SessionId 'breaker-2' -Journal (New-JournalSeed -Trigger 'b1' -Count 2 -Tokens 8000)
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson '{"session_id":"breaker-2","source":"startup"}'
Assert-True ($result.StdErr.Contains('WARN BREAKER_TRIPPED') -and $result.StdErr.Contains('token')) 'token cap trips with the token reason'
$state = Get-Content -LiteralPath (Join-Path $runtimeDir 'refocus-state-breaker-2.json') -Raw | ConvertFrom-Json
Assert-True (@($state.breaker.scopes) -contains 'all') 'token cap trips ALL hook triggers'

# 14e. --reset-breaker clears the trip flag.
Push-Location $projectRoot
$resetOut = & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\refocus.ps1') --reset-breaker 2>$null
Pop-Location
Assert-True (($resetOut -join '') -match '1 trip flag\(s\) cleared') '--reset-breaker reports the cleared trip'
$state = Get-Content -LiteralPath (Join-Path $runtimeDir 'refocus-state-breaker-2.json') -Raw | ConvertFrom-Json
Assert-True ($null -eq $state.breaker) 'trip flag cleared in state'

# 14f. Slash-command exemption: the engine emits even when the session is tripped.
$null = New-SeedState -SessionId 'breaker-3' -Journal (New-JournalSeed -Trigger 'b2' -Count 3)
$null = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart') -StdinJson '{"session_id":"breaker-3","source":"startup"}'   # trips
Push-Location $projectRoot
$slashOut = & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\refocus.ps1') --boundary implement 2>$null
Pop-Location
Assert-True (($slashOut -join "`n").Contains('trigger=manual')) 'human slash invocation is never breaker-suppressed'

# --- 15. T014: per-host event/output shaping ------------------------------------------
$dispatcher = New-ScratchProject

# 15a. codex SessionStart -> {"additionalContext": ...}
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart', '-HostKind', 'codex') -StdinJson '{"session_id":"codex-1","source":"compact"}'
$json = $null
try { $json = $result.StdOut | ConvertFrom-Json } catch { }
Assert-True ($null -ne $json -and $null -ne $json.PSObject.Properties['hookSpecificOutput'] -and $null -ne $json.hookSpecificOutput.PSObject.Properties['additionalContext']) 'codex output is hookSpecificOutput.additionalContext JSON'
Assert-True ($null -ne $json -and $json.hookSpecificOutput.hookEventName -eq 'SessionStart') 'codex output carries hookSpecificOutput.hookEventName'
Assert-True ($null -ne $json -and ([string]$json.hookSpecificOutput.additionalContext) -match 'trigger=b1') 'codex compact routes to b1'

# 15b. codex UserPromptSubmit -> B3 with state-diff gating (anchor, then crossing)
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'UserPromptSubmit', '-HostKind', 'codex') -StdinJson '{"session_id":"codex-1","prompt":"hello"}'
Assert-True ([string]::IsNullOrWhiteSpace($result.StdOut)) 'codex UserPromptSubmit anchors on first sight (no injection)'
$ctx = @{ session_state = @{ boundary_type = 'review-signoff'; feature_ref = 'dispatcher-fixture' } } | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), $ctx, [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'UserPromptSubmit', '-HostKind', 'codex') -StdinJson '{"session_id":"codex-1","prompt":"hello again"}'
$json = $null
try { $json = $result.StdOut | ConvertFrom-Json } catch { }
Assert-True ($null -ne $json -and ([string]$json.hookSpecificOutput.additionalContext) -match 'trigger=b3 scope=general\+boundary\.retro') 'codex UserPromptSubmit crossing injects b3 (incoming stage)'

# 15c. cursor: conversation_id session key + snake_case output
$dispatcher = New-ScratchProject
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart', '-HostKind', 'cursor') -StdinJson '{"conversation_id":"curs-1"}'
$json = $null
try { $json = $result.StdOut | ConvertFrom-Json } catch { }
Assert-True ($null -ne $json -and $null -ne $json.PSObject.Properties['additional_context']) 'cursor output is additional_context (snake_case)'
Assert-True (Test-Path -LiteralPath (Join-Path $projectRoot '.specrew\runtime\refocus-state-curs-1.json')) 'cursor conversation_id keys the session state'

# 15d. copilot sessionStart -> additionalContext JSON
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'SessionStart', '-HostKind', 'copilot') -StdinJson '{"sessionId":"copi-1","source":"startup"}'
$json = $null
try { $json = $result.StdOut | ConvertFrom-Json } catch { }
Assert-True ($null -ne $json -and ([string]$json.additionalContext) -match 'trigger=b2') 'copilot camelCase sessionId parsed; additionalContext b2 payload'

# 15e. antigravity: PreInvocation is the only B3 injection carrier; conversationId keys state.
$dispatcher = New-ScratchProject
$antiEvent = '{"conversationId":"anti-conv-1","workspacePaths":["C:/anti/project"],"transcriptPath":"C:/anti/transcript.jsonl","prompt":"SECRET_PROMPT_SHOULD_NOT_LEAK"}'
$antiStatePath = Join-Path $projectRoot '.specrew\runtime\refocus-state-anti-conv-1.json'
$unknownStatePath = Join-Path $projectRoot '.specrew\runtime\refocus-state-unknown.json'

$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PreInvocation', '-HostKind', 'antigravity') -StdinJson $antiEvent
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut)) 'antigravity PreInvocation first sight anchors silently'
Assert-True (Test-Path -LiteralPath $antiStatePath -PathType Leaf) 'antigravity conversationId creates a per-session refocus state file'
Assert-True (-not (Test-Path -LiteralPath $unknownStatePath)) 'antigravity conversationId never creates global unknown state'
$antiState = Get-Content -LiteralPath $antiStatePath -Raw | ConvertFrom-Json
Assert-True ([string]$antiState.session_id -eq 'anti-conv-1' -and [string]$antiState.last_seen_boundary -eq 'implement') 'antigravity state records session id and anchor cursor'

$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PreInvocation', '-HostKind', 'antigravity') -StdinJson $antiEvent
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut)) 'antigravity unchanged PreInvocation remains silent'

Set-Cursor -Boundary 'review-signoff'
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PreInvocation', '-HostKind', 'antigravity') -StdinJson $antiEvent
$json = $null
try { $json = $result.StdOut | ConvertFrom-Json } catch { }
Assert-True ($result.ExitCode -eq 0) 'antigravity B3 crossing exits 0'
Assert-True ($null -ne $json -and $null -ne $json.PSObject.Properties['injectSteps']) 'antigravity B3 output uses injectSteps'
Assert-True ($null -ne $json -and ([string]$json.injectSteps[0].ephemeralMessage) -match 'trigger=b3 scope=general\+boundary\.retro') 'antigravity B3 payload carries incoming-stage refocus'
$antiState = Get-Content -LiteralPath $antiStatePath -Raw | ConvertFrom-Json
Assert-True ([string]$antiState.last_seen_boundary -eq 'review-signoff') 'antigravity B3 crossing updates last_seen'

Set-Cursor -Boundary 'retro'
$fingerprint = @{ boundary = 'retro'; at = '2026-06-17T00:00:00Z' } | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\runtime\refocus-channel1.json'), $fingerprint, [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PreInvocation', '-HostKind', 'antigravity') -StdinJson $antiEvent
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut)) 'antigravity channel-1 fingerprint dedupes B3 crossing'

Set-Cursor -Boundary 'iteration-closeout'
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PostToolUse', '-HostKind', 'antigravity') -StdinJson $antiEvent
Assert-True ($result.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($result.StdOut)) 'antigravity PostToolUse is not used for refocus injection'
Assert-True (-not $result.StdOut.Contains('injectSteps')) 'antigravity PostToolUse never emits injectSteps'

# 15f. antigravity fail-open diagnostics stay bounded and do not leak prompt text.
$dispatcher = New-ScratchProject
$antiSecretEvent = '{"conversationId":"anti-fail-1","workspacePaths":["C:/anti/project"],"transcriptPath":"C:/anti/transcript.jsonl","prompt":"SECRET_PROMPT_SHOULD_NOT_LEAK"}'
$null = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PreInvocation', '-HostKind', 'antigravity') -StdinJson $antiSecretEvent
Set-Cursor -Boundary 'review-signoff'
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\refocus.ps1'), "exit 1", [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PreInvocation', '-HostKind', 'antigravity') -StdinJson $antiSecretEvent
Assert-True ($result.ExitCode -eq 0) 'antigravity provider crash fails open'
Assert-True ($result.StdErr.Contains('WARN PROVIDER_FAILED')) 'antigravity provider crash warns PROVIDER_FAILED'
Assert-True ($result.StdOut.Contains('degraded governed fallback') -and $result.StdOut.Contains('specrew start --host antigravity')) 'antigravity provider crash injects governed recovery fallback'
Assert-True (-not (($result.StdErr + $result.StdOut).Contains('SECRET_PROMPT_SHOULD_NOT_LEAK'))) 'antigravity provider crash diagnostic does not leak prompt text'

$dispatcher = New-ScratchProject
$corruptAntiState = Join-Path $projectRoot '.specrew\runtime\refocus-state-anti-corrupt-1.json'
New-Item -ItemType Directory -Path (Split-Path -Parent $corruptAntiState) -Force | Out-Null
[System.IO.File]::WriteAllText($corruptAntiState, '{corrupt', [System.Text.UTF8Encoding]::new($false))
$result = Invoke-Dispatcher -Dispatcher $dispatcher -DispatcherArgs @('-Event', 'PreInvocation', '-HostKind', 'antigravity') -StdinJson '{"conversationId":"anti-corrupt-1","prompt":"SECRET_PROMPT_SHOULD_NOT_LEAK"}'
Assert-True ($result.ExitCode -eq 0) 'antigravity corrupt state fails open'
Assert-True ($result.StdErr.Contains('WARN STATE_UNAVAILABLE')) 'antigravity corrupt state warns STATE_UNAVAILABLE'
Assert-True ([string]::IsNullOrWhiteSpace($result.StdOut)) 'antigravity corrupt state produces no injection'
Assert-True (-not (($result.StdErr + $result.StdOut).Contains('SECRET_PROMPT_SHOULD_NOT_LEAK'))) 'antigravity corrupt-state diagnostic does not leak prompt text'

# --- summary --------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "refocus-dispatcher tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host 'refocus-dispatcher tests: all passed' -ForegroundColor Green
exit 0
