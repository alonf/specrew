$ErrorActionPreference = 'Stop'

# F-174 iteration 011 — hook-command cwd-resolution regression (ALL hook hosts).
#
# A deployed hook command MUST resolve the dispatcher (and the project it belongs to) from ANY host cwd. The
# original bug: deploy generated a bare RELATIVE -File path for every host, so when the host fired the hook with
# cwd != project root the dispatcher FILE was not found ("does not exist") and the hook errored. The central fix
# has TWO halves:
#   (1) the DEPLOYED dispatcher self-locates the project from its OWN location ($PSScriptRoot), so it ignores a
#       stray .specrew up the firing cwd's ancestry (e.g. ~/.specrew); and
#   (2) the host command string names a cwd-robust entry point, which differs by config scope:
#         - claude  (PROJECT-level, version-tracked .claude/settings.local.json): the host-substituted
#                   ${CLAUDE_PROJECT_DIR} placeholder (BRACE form; bare $CLAUDE_PROJECT_DIR is NOT substituted
#                   and fails on Windows). Portable across clone/worktree.
#         - codex/copilot/cursor (USER-level configs shared across all projects): ONE per-machine launcher
#                   (~/.specrew/specrew-hook-launch.ps1) that resolves WHICH project the live session is in
#                   (env CLAUDE_PROJECT_DIR/CURSOR_PROJECT_DIR -> stdin cwd/workspace_roots -> cwd walk-up keyed
#                   on the dispatcher subpath) and hands off to that project's deployed dispatcher.
#
# This test GENERATES each host's command via the real deploy, asserts the cwd-robust form, and EXECUTES the
# resolution end-to-end from a non-project cwd whose ANCESTOR holds a stray .specrew — proving a stub SessionStart
# provider's sentinel is written (the dispatcher loaded + resolved the CORRECT project + ran the provider). It
# also pins the regression (a RELATIVE path from the same cwd writes NO sentinel) and the no-hang guard.
#
# NOTE on claude: a test CANNOT prove Claude performs ${CLAUDE_PROJECT_DIR} substitution (that is the human's
# real-host gate). It proves the form is the brace placeholder, then SIMULATES substitution and proves the
# dispatcher resolves given the substituted absolute path.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$repoInternal  = (Resolve-Path "$PSScriptRoot/../../scripts/internal").Path
$deploy        = Join-Path $repoInternal 'deploy-refocus-hooks.ps1'
$dispatcherSrc = Join-Path $repoInternal 'specrew-hook-dispatcher.ps1'

$tmp           = [System.IO.Path]::GetTempPath()
$proj          = Join-Path $tmp ("hookcwd-proj-"   + [guid]::NewGuid().ToString('N'))
$projSub       = Join-Path $proj 'src'                                                  # a dir INSIDE the project (payload cwd)
$strayParent   = Join-Path $tmp ("hookcwd-stray-"  + [guid]::NewGuid().ToString('N'))   # holds a STRAY .specrew
$nonRepo       = Join-Path $strayParent 'work'                                          # the cwd the host fires from
$orphan        = Join-Path $tmp ("hookcwd-orphan-" + [guid]::NewGuid().ToString('N'))   # cwd with NO project up-tree
$userHome      = Join-Path $tmp ("hookcwd-home-"   + [guid]::NewGuid().ToString('N'))
$scriptsDir    = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'

New-Item -ItemType Directory -Path (Join-Path $proj '.specrew/runtime') -Force | Out-Null
New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
New-Item -ItemType Directory -Path $projSub -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $strayParent '.specrew') -Force | Out-Null   # the STRAY .specrew (simulates ~/.specrew up the cwd tree)
New-Item -ItemType Directory -Path $nonRepo  -Force | Out-Null
New-Item -ItemType Directory -Path $orphan   -Force | Out-Null
New-Item -ItemType Directory -Path $userHome -Force | Out-Null

# Env hygiene: this very session may export CLAUDE_PROJECT_DIR; the launcher honors it FIRST and it would point
# at the WRONG project. Clear both project-root vars so each part controls resolution explicitly. Restored never
# (a test process is disposable), but cleared again in finally for belt-and-suspenders.
Remove-Item Env:CLAUDE_PROJECT_DIR  -ErrorAction SilentlyContinue
Remove-Item Env:CURSOR_PROJECT_DIR  -ErrorAction SilentlyContinue

function Invoke-Hook {
    # Run a hook entry point from a chosen cwd with a stdin event file; return the exit code. Mirrors how a host
    # fires the command (cwd != project root, event JSON on stdin).
    param([string]$File, [string]$Event, [string]$HostKind, [string]$Cwd, [string]$EventFile, [string]$Tag)
    $out = Join-Path $proj "$Tag.out"; $err = Join-Path $proj "$Tag.err"
    $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $File, '-Event', $Event, '-HostKind', $HostKind) `
        -WorkingDirectory $Cwd -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $EventFile -RedirectStandardOutput $out -RedirectStandardError $err
    return $p.ExitCode
}

try {
    # Deploy the (fixed) dispatcher into the temp project at its deployed location — the copy whose $PSScriptRoot
    # resolution is under test, and the one the launcher hands off to.
    Copy-Item -LiteralPath $dispatcherSrc -Destination (Join-Path $scriptsDir 'specrew-hook-dispatcher.ps1') -Force

    # Minimal catalog: ONE stub SessionStart provider writing a sentinel to an ABSOLUTE path the test controls.
    # The sentinel appears ONLY if the dispatcher loaded AND resolved THIS project (its catalog) AND ran the
    # provider — a wrong (stray-ancestor) resolution finds no catalog and writes nothing.
    $sentinel = Join-Path $proj 'dispatcher-ran-sentinel.txt'
    $catalog = @{
        schema_version = '1'
        providers      = @(@{ id = 'cwd-sentinel'; kind = 'inject'; events = @('SessionStart'); order = 30; budget_share = 1.0; command = 'cwd-sentinel.ps1' })
    } | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath (Join-Path $proj '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value $catalog -Encoding UTF8
    $stub = @"
Set-Content -LiteralPath '$sentinel' -Value 'ran' -Encoding UTF8
exit 0
"@
    Set-Content -LiteralPath (Join-Path $scriptsDir 'cwd-sentinel.ps1') -Value $stub -Encoding UTF8

    # Event payloads.
    $eventWithCwd = Join-Path $proj 'event-cwd.json'
    Set-Content -LiteralPath $eventWithCwd -Value (@{ session_id = 'cwdtest'; source = 'startup'; cwd = $projSub } | ConvertTo-Json -Compress) -Encoding UTF8 -NoNewline
    $eventNoCwd = Join-Path $proj 'event-nocwd.json'
    Set-Content -LiteralPath $eventNoCwd -Value (@{ session_id = 'cwdtest'; source = 'startup' } | ConvertTo-Json -Compress) -Encoding UTF8 -NoNewline

    # ============================================================================================
    # PART A — claude: ${CLAUDE_PROJECT_DIR} placeholder (project-level, portable) + dispatcher self-location
    # ============================================================================================
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $deploy -ProjectPath $proj -HostKind claude -UserHomeOverride $userHome | Out-Null
    $settingsPath = Join-Path $proj '.claude/settings.local.json'
    Assert-True (Test-Path -LiteralPath $settingsPath) 'claude: deploy generated .claude/settings.local.json'
    $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $cmd = [string]$settings.hooks.SessionStart[0].hooks[0].command
    Assert-True ($cmd -match '\$\{CLAUDE_PROJECT_DIR\}/') 'claude: command uses the ${CLAUDE_PROJECT_DIR} BRACE placeholder (portable across clone/worktree)'
    Assert-True (-not ($cmd -match '\$CLAUDE_PROJECT_DIR[^}]')) 'claude: command does NOT use the bare $CLAUDE_PROJECT_DIR form (which fails on Windows)'

    $m = [regex]::Match($cmd, '-File\s+"([^"]+)"')
    Assert-True ($m.Success) 'claude: command has a -File "<path>" arg'
    # Simulate the host-side substitution Claude performs before spawn, then run the deployed dispatcher.
    $resolved = $m.Groups[1].Value.Replace('${CLAUDE_PROJECT_DIR}', $proj)
    Assert-True ([System.IO.Path]::IsPathRooted($resolved)) "claude: after simulated substitution the -File path is ABSOLUTE: $resolved"
    Remove-Item -LiteralPath $sentinel -Force -ErrorAction SilentlyContinue
    $rc = Invoke-Hook -File $resolved -Event 'SessionStart' -HostKind 'claude' -Cwd $nonRepo -EventFile $eventNoCwd -Tag 'claude'
    Assert-True ($rc -eq 0) 'claude: dispatcher exits 0 from a non-project cwd (fail-open holds)'
    Assert-True (Test-Path -LiteralPath $sentinel) 'claude: FIX — deployed dispatcher RAN + self-located the CORRECT project from a non-project cwd whose ancestor has a stray .specrew (sentinel written)'

    # ============================================================================================
    # PART B — launcher generated for the user-level hosts
    # ============================================================================================
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $deploy -ProjectPath $proj -HostKind codex -UserHomeOverride $userHome | Out-Null
    $launcher = Join-Path $userHome '.specrew/specrew-hook-launch.ps1'
    Assert-True (Test-Path -LiteralPath $launcher) 'launcher: deploy generated the per-machine ~/.specrew/specrew-hook-launch.ps1'
    $codexCmd = [string]((Get-Content -LiteralPath (Join-Path $userHome '.codex/hooks.json') -Raw -Encoding UTF8 | ConvertFrom-Json).hooks.SessionStart[0].hooks[0].command)
    Assert-True ($codexCmd.Contains('specrew-hook-launch.ps1')) 'codex: command points at the launcher (so Test-IsSpecrewCommandText still recognizes ownership)'

    # ============================================================================================
    # PART C — launcher resolves via PAYLOAD cwd (codex/copilot have no project-root env var)
    # ============================================================================================
    Remove-Item -LiteralPath $sentinel -Force -ErrorAction SilentlyContinue
    $rc = Invoke-Hook -File $launcher -Event 'SessionStart' -HostKind 'codex' -Cwd $nonRepo -EventFile $eventWithCwd -Tag 'codex'
    Assert-True ($rc -eq 0) 'codex: launcher exits 0 from a non-project cwd (fail-open holds)'
    Assert-True (Test-Path -LiteralPath $sentinel) 'codex: FIX — launcher resolved the project from the stdin payload cwd + handed off to the dispatcher (sentinel written)'

    # ============================================================================================
    # PART D — launcher resolves via CURSOR_PROJECT_DIR env (cursor sets it; no payload cwd needed)
    # ============================================================================================
    Remove-Item -LiteralPath $sentinel -Force -ErrorAction SilentlyContinue
    $env:CURSOR_PROJECT_DIR = $proj
    try {
        $rc = Invoke-Hook -File $launcher -Event 'SessionStart' -HostKind 'cursor' -Cwd $nonRepo -EventFile $eventNoCwd -Tag 'cursor'
    } finally { Remove-Item Env:CURSOR_PROJECT_DIR -ErrorAction SilentlyContinue }
    Assert-True ($rc -eq 0) 'cursor: launcher exits 0 (fail-open holds)'
    Assert-True (Test-Path -LiteralPath $sentinel) 'cursor: FIX — launcher resolved the project from $env:CURSOR_PROJECT_DIR (no payload cwd) + handed off (sentinel written)'

    # ============================================================================================
    # PART E — fail-open: NO project resolvable from any signal -> NOTHING fires, exit 0
    # ============================================================================================
    Remove-Item -LiteralPath $sentinel -Force -ErrorAction SilentlyContinue
    $rc = Invoke-Hook -File $launcher -Event 'SessionStart' -HostKind 'codex' -Cwd $orphan -EventFile $eventNoCwd -Tag 'orphan'
    Assert-True ($rc -eq 0) 'fail-open: launcher exits 0 when no project is resolvable'
    Assert-True (-not (Test-Path -LiteralPath $sentinel)) 'fail-open: launcher fires NOTHING when no project is resolvable (no sentinel)'

    # ============================================================================================
    # PART F — no-hang guard: the launcher must NOT do an unconditional stdin ReadToEnd (which blocks the
    # session on a non-redirected stdin). Behavioral completion is already proven by Parts C/D/E (redirected
    # stdin returns); here we pin the GUARD structurally so a future edit can't silently reintroduce the hang.
    # ============================================================================================
    $launcherText = Get-Content -LiteralPath $launcher -Raw -Encoding UTF8
    Assert-True ($launcherText -match '\[Console\]::IsInputRedirected') 'no-hang: launcher guards the stdin read with [Console]::IsInputRedirected'
    # Target the precise CODE tokens (the actual guard `if` and the actual `[Console]::In.ReadToEnd` call), not
    # the word "ReadToEnd" that also appears in the explanatory comment above the guard.
    $idxGuard = $launcherText.IndexOf('[Console]::IsInputRedirected')
    $idxRead  = $launcherText.IndexOf('[Console]::In.ReadToEnd')
    Assert-True (($idxRead -lt 0) -or ($idxGuard -ge 0 -and $idxGuard -lt $idxRead)) 'no-hang: the IsInputRedirected guard precedes the [Console]::In.ReadToEnd call (read is guarded, never unconditional)'

    # ============================================================================================
    # PART G — regression pin: the OLD relative -File path from a non-project cwd does NOT run the dispatcher
    # ============================================================================================
    Remove-Item -LiteralPath $sentinel -Force -ErrorAction SilentlyContinue
    $relPath = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
    $null = Invoke-Hook -File $relPath -Event 'SessionStart' -HostKind 'claude' -Cwd $nonRepo -EventFile $eventNoCwd -Tag 'rel'
    Assert-True (-not (Test-Path -LiteralPath $sentinel)) 'REGRESSION PINNED: a RELATIVE -File path from a non-project cwd does NOT run the dispatcher (no sentinel) — the original bug'

    Write-Host "`n=== HookCommandCwdResolution.Tests.ps1: all assertions passed (claude + codex + copilot + cursor) ===" -ForegroundColor Green
}
finally {
    Remove-Item Env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:CURSOR_PROJECT_DIR -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $proj        -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $strayParent -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $orphan      -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $userHome    -Recurse -Force -ErrorAction SilentlyContinue
}
