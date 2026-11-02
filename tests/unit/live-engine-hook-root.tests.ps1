# Feature 203 T002 (DA-8), maintainer condition (a): when the hooks run from a live-engine pin, the project root comes
# from the host (CLAUDE_PROJECT_DIR, or the payload's cwd for the per-machine launcher) and is passed explicitly. The
# pin is a checkout of the repository with its own .specrew, and the user profile holds a .specrew for the launcher,
# so a dispatcher that walked up from its own folder or from the process cwd would write approvals and state there.
#
# A hook event run through a configured pin must write only into the project: nothing into the pin, nothing into
# %USERPROFILE%\.specrew, and none of the project's own deployed engine copies may run. A pin record whose pin is gone,
# or whose pin has moved off the recorded commit, refuses visibly in the launcher and runs nothing.
#
# Mutation that turns this file red: drop -ProjectRoot from the launcher's pinned call, make the dispatcher ignore it,
# or resolve the catalog or provider commands from the project's .specify instead of the dispatcher's own tree.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$deployer = Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function ConvertTo-PlainStderr {
    # A refusal reaches stderr in pwsh's error view: wrapped at the console width behind a '|' gutter, colored with
    # ANSI escapes, and serialized as CLIXML when pwsh runs from -EncodedCommand. Which of these appear depends on how
    # pwsh was started and on the environment (the review checks pass only a few variables, 203 DRIFT-018), so the
    # message is reduced to its words: escapes removed, gutters dropped, whitespace collapsed.
    param([string]$Text)
    $plain = $Text -replace '\x1b\[[0-9;?]*[A-Za-z]', ''
    $plain = $plain -replace '_x001B_\[[0-9;?]*[A-Za-z]', ''
    $plain = $plain -replace '_x000D_|_x000A_', "`n"
    $plain = $plain -replace '#< CLIXML|<[^>]*>', ''
    $plain = $plain -replace '(?m)^\s*\|', ''
    return ($plain -replace '\s+', ' ')
}

$work = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-pinroot-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
$pin = Join-Path $work 'pin'
$project = Join-Path $work 'project'
$fakeHome = Join-Path $work 'home'
$marker = Join-Path $work 'worktree-engine-ran.txt'
$engineDirs = @('.specify', 'scripts/internal', 'hosts', 'extensions')

function Get-TreeSnapshot {
    # Every file under a root with its size and write time, so any write - new, changed or removed - shows.
    param([string]$Root)
    if (-not (Test-Path -LiteralPath $Root)) { return @() }
    return @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Sort-Object FullName |
            ForEach-Object { '{0}|{1}|{2}' -f $_.FullName.Substring($Root.Length), $_.Length, $_.LastWriteTimeUtc.Ticks })
}

function Write-TrapEngine {
    # The project's own deployed engine copies, replaced by traps: any of them running records its name.
    param([string]$Root)
    foreach ($rel in @('.specify/extensions/specrew-speckit/scripts', 'scripts/internal')) {
        $source = Join-Path $repoRoot $rel
        foreach ($file in @(Get-ChildItem -LiteralPath $source -Recurse -File -Filter '*.ps1')) {
            $target = Join-Path (Join-Path $Root $rel) $file.FullName.Substring($source.Length)
            New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
            Set-Content -LiteralPath $target -Value ("Add-Content -LiteralPath `$env:SPECREW_TEST_MARKER -Value '{0}'; exit 0" -f $file.Name)
        }
    }
    Copy-Item -LiteralPath (Join-Path $repoRoot '.specify/extensions/specrew-speckit/refocus-scopes.json') -Destination (Join-Path $Root '.specify/extensions/specrew-speckit/refocus-scopes.json')
}

function Invoke-Hook {
    param([string]$FileName = 'pwsh', [string[]]$Arguments, [string]$Stdin, [hashtable]$Environment)
    $psi = [System.Diagnostics.ProcessStartInfo]::new($FileName)
    foreach ($a in $Arguments) { $psi.ArgumentList.Add($a) }
    # The process cwd is the fake home, which holds a .specrew: a cwd walk-up would land there.
    $psi.WorkingDirectory = $fakeHome
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    foreach ($k in $Environment.Keys) { $psi.Environment[$k] = [string]$Environment[$k] }
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.StandardInput.Write($Stdin)
    $p.StandardInput.Close()
    $out = $p.StandardOutput.ReadToEndAsync()
    $err = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit(120000)) { try { $p.Kill($true) } catch { $null = $_ }; return [pscustomobject]@{ ExitCode = 'timeout'; StdOut = ''; StdErr = '' } }
    return [pscustomobject]@{ ExitCode = $p.ExitCode; StdOut = $out.Result; StdErr = $err.Result }
}

function New-Payload {
    param([string]$EventName, [string]$Session)
    $payload = [ordered]@{ session_id = $Session; transcript_path = (Join-Path $project 'transcript.jsonl'); cwd = $project; hook_event_name = $EventName }
    switch ($EventName) {
        'SessionStart' { $payload.source = 'startup' }
        'UserPromptSubmit' { $payload.prompt = 'what is the status?'; $payload.prompt_id = [guid]::NewGuid().ToString() }
        'PostToolUse' { $payload.tool_name = 'Read'; $payload.tool_input = @{ file_path = 'README.md' }; $payload.tool_response = @{} }
        'Stop' { $payload.stop_hook_active = $false }
    }
    return ($payload | ConvertTo-Json -Compress -Depth 4)
}

function Get-ClaudeHookCommands {
    # The encoded launcher scripts the deployer wrote, by event.
    $settings = Get-Content -LiteralPath (Join-Path $project '.claude/settings.local.json') -Raw | ConvertFrom-Json
    $commands = @{}
    foreach ($event in $settings.hooks.PSObject.Properties) {
        foreach ($group in @($event.Value)) {
            foreach ($hook in @($group.hooks)) {
                if ([string]$hook.command -match '-EncodedCommand\s+(\S+)') { $commands[$event.Name] = $Matches[1] }
            }
        }
    }
    return $commands
}

try {
    New-Item -ItemType Directory -Path $work, $fakeHome | Out-Null
    $hookEnv = @{ USERPROFILE = $fakeHome; HOME = $fakeHome; SPECREW_TEST_MARKER = $marker; SPECREW_MODULE_PATH = ''; CLAUDE_PROJECT_DIR = $project }

    # The pin: this repository's engine, a .specrew of its own (as a real checkout has), detached at a commit.
    # Like a `git worktree`, its .git is a file naming a gitdir whose HEAD holds the detached commit.
    foreach ($rel in $engineDirs) { Copy-Item -LiteralPath (Join-Path $repoRoot $rel) -Destination (Join-Path $pin $rel) -Recurse -Force }
    $pinGitDir = Join-Path $work 'pin-gitdir'
    New-Item -ItemType Directory -Path (Join-Path $pin '.specrew'), $pinGitDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot '.specrew/config.yml') -Destination (Join-Path $pin '.specrew/config.yml')
    $pinCommit = ([guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')).Substring(0, 40)
    Set-Content -LiteralPath (Join-Path $pin '.git') -Value ("gitdir: {0}" -f $pinGitDir)
    Set-Content -LiteralPath (Join-Path $pinGitDir 'HEAD') -Value $pinCommit

    # The project: a Specrew project whose deployed engine copies are all traps.
    New-Item -ItemType Directory -Path (Join-Path $project '.specrew/runtime') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot '.specrew/config.yml') -Destination (Join-Path $project '.specrew/config.yml')
    Write-TrapEngine -Root $project
    & git -C $project init -q 2>&1 | Out-Null
    & git -C $project -c user.email=t@example.invalid -c user.name=t commit -q --allow-empty -m init 2>&1 | Out-Null

    # Deploy the real hook commands: Claude's per-project command and the per-machine launcher (Codex's shape).
    & pwsh -NoProfile -File $deployer -ProjectPath $project -HostKind claude -UserHomeOverride $fakeHome | Out-Null
    & pwsh -NoProfile -File $deployer -ProjectPath $project -HostKind codex -UserHomeOverride $fakeHome | Out-Null
    $launcher = [string](@(Get-ChildItem -Path (Join-Path $fakeHome '.specrew/hooks') -Recurse -Filter 'specrew-hook-launch.ps1' -ErrorAction SilentlyContinue | ForEach-Object FullName) + '')[0]
    $claudeCommands = Get-ClaudeHookCommands
    Assert-True ($claudeCommands.Count -ge 4) ("the deployer wrote the Claude hook commands (got {0})" -f $claudeCommands.Count)
    Assert-True (Test-Path -LiteralPath $launcher -PathType Leaf) 'the deployer wrote the per-machine launcher'

    Set-Content -LiteralPath (Join-Path $project '.specrew/runtime/live-engine.json') -Value (([ordered]@{ schema_version = '1'; path = $pin; commit = $pinCommit }) | ConvertTo-Json)
    # The pin's host bindings, stamped with its commit, as the pin script writes them at Create and Advance.
    . (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/live-engine-resolution.ps1')
    Write-SpecrewLiveEngineBindings -ProjectRoot $project -PinRoot $pin -Commit $pinCommit
    $bindingsPath = Get-SpecrewLiveEngineBindingsPath -ProjectRoot $project
    $pinBindings = Get-Content -LiteralPath $bindingsPath -Raw | ConvertFrom-Json
    Assert-True ($pinBindings.commit -eq $pinCommit -and $null -ne $pinBindings.bindings.PSObject.Properties['claude'] -and $null -ne $pinBindings.bindings.PSObject.Properties['codex']) 'the pin bindings are written from the pin and stamped with its commit'

    # The profile's .specrew only: pwsh itself keeps caches under the profile's AppData.
    $homeSpecrew = Join-Path $fakeHome '.specrew'
    $pinBefore = Get-TreeSnapshot -Root $pin
    $homeBefore = Get-TreeSnapshot -Root $homeSpecrew
    $runtimeBefore = Get-TreeSnapshot -Root (Join-Path $project '.specrew')

    # --- Claude: the deployed command, CLAUDE_PROJECT_DIR = the project ---
    $claudeExits = @()
    foreach ($eventName in @('SessionStart', 'UserPromptSubmit', 'PostToolUse', 'Stop')) {
        $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $claudeCommands[$eventName]) -Stdin (New-Payload -EventName $eventName -Session 'pinroot-claude') -Environment $hookEnv
        $claudeExits += ('{0}={1}' -f $eventName, $r.ExitCode)
    }
    Assert-True (@($claudeExits | Where-Object { $_ -notmatch '=0$' }).Count -eq 0) ("Claude events through the pin exit 0 ({0})" -f ($claudeExits -join ', '))

    # --- the per-machine launcher: the project comes from the payload's cwd ---
    $launcherEnv = $hookEnv.Clone(); $launcherEnv.Remove('CLAUDE_PROJECT_DIR')
    $launcherExits = @()
    foreach ($eventName in @('SessionStart', 'UserPromptSubmit', 'Stop')) {
        $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $launcher, '-Event', $eventName, '-HostKind', 'codex') -Stdin (New-Payload -EventName $eventName -Session 'pinroot-codex') -Environment $launcherEnv
        $launcherExits += ('{0}={1}' -f $eventName, $r.ExitCode)
    }
    Assert-True (@($launcherExits | Where-Object { $_ -notmatch '=0$' }).Count -eq 0) ("launcher events through the pin exit 0 ({0})" -f ($launcherExits -join ', '))

    $ran = if (Test-Path -LiteralPath $marker) { (Get-Content -LiteralPath $marker) -join ', ' } else { '' }
    Assert-True ([string]::IsNullOrEmpty($ran)) ("none of the project's own deployed engine copies ran (ran: '{0}')" -f $ran)
    $pinAfter = Get-TreeSnapshot -Root $pin
    $pinDiff = @(Compare-Object -ReferenceObject $pinBefore -DifferenceObject $pinAfter | ForEach-Object { $_.InputObject })
    Assert-True ($pinDiff.Count -eq 0) ("nothing was written into the pin (changed: {0})" -f (($pinDiff | Select-Object -First 5) -join '; '))
    $homeAfter = Get-TreeSnapshot -Root $homeSpecrew
    $homeDiff = @(Compare-Object -ReferenceObject $homeBefore -DifferenceObject $homeAfter | ForEach-Object { $_.InputObject })
    Assert-True ($homeDiff.Count -eq 0) ("nothing was written into the user profile's .specrew (changed: {0})" -f (($homeDiff | Select-Object -First 5) -join '; '))
    $runtimeAfter = Get-TreeSnapshot -Root (Join-Path $project '.specrew')
    $runtimeNew = @(Compare-Object -ReferenceObject $runtimeBefore -DifferenceObject $runtimeAfter | Where-Object { $_.SideIndicator -eq '=>' })
    Assert-True ($runtimeNew.Count -gt 0) ("the hooks' writes landed in the project ({0} file(s) new or changed)" -f $runtimeNew.Count)

    # The turn-end store's module-file lookup tries a self-hosting project root; with a pin it must use the pin only
    # (round 1: it loaded the project's scripts/internal/user-profile.ps1 on a path the events above do not reach).
    $storePath = Join-Path $pin '.specify/extensions/specrew-speckit/scripts/turn-end-store.ps1'
    $resolved = (& pwsh -NoProfile -Command ". '$storePath'; Resolve-SpecrewModuleFile -RelativePath 'scripts/internal/user-profile.ps1' -ProjectRoot '$project'" 2>$null | Select-Object -Last 1)
    Assert-True ([string]$resolved -eq (Join-Path $pin 'scripts/internal/user-profile.ps1')) ("turn-end store: a module file resolves to the pin, not the project (got '{0}')" -f $resolved)

    # --- the binding the dispatcher gets is the pin's, not the one baked into the hook settings (round 3, finding 1) ---
    # Observable through the dispatcher's per-event switch: a disabled event answers {} only when the binding it was
    # given lists that event as decision-only. The baked Claude binding lists none; the pin's is given one here.
    $disabledEnv = $hookEnv.Clone(); $disabledEnv['SPECREW_DISABLE_EVENTS'] = 'UserPromptSubmit'
    $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $claudeCommands['UserPromptSubmit']) -Stdin (New-Payload -EventName 'UserPromptSubmit' -Session 'pinroot-binding') -Environment $disabledEnv
    Assert-True ($r.ExitCode -eq 0 -and $r.StdOut.Trim() -eq '') ("control: with the pin's own binding, the disabled event answers nothing (got '{0}')" -f $r.StdOut.Trim())
    $marked = $pinBindings | ConvertTo-Json -Depth 4 | ConvertFrom-Json
    foreach ($kind in @('claude', 'codex')) {
        $runtime = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($marked.bindings.$kind)) | ConvertFrom-Json
        $runtime.DecisionOnlyEvents = @(@($runtime.DecisionOnlyEvents) + 'UserPromptSubmit')
        $marked.bindings.$kind = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($runtime | ConvertTo-Json -Depth 8 -Compress)))
    }
    Set-Content -LiteralPath $bindingsPath -Value ($marked | ConvertTo-Json -Depth 4)
    $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $claudeCommands['UserPromptSubmit']) -Stdin (New-Payload -EventName 'UserPromptSubmit' -Session 'pinroot-binding') -Environment $disabledEnv
    Assert-True ($r.ExitCode -eq 0 -and $r.StdOut.Trim() -eq '{}') ("Claude: the pinned dispatcher got the pin's binding (got '{0}')" -f $r.StdOut.Trim())
    $disabledLauncherEnv = $launcherEnv.Clone(); $disabledLauncherEnv['SPECREW_DISABLE_EVENTS'] = 'UserPromptSubmit'
    $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $launcher, '-Event', 'UserPromptSubmit', '-HostKind', 'codex') -Stdin (New-Payload -EventName 'UserPromptSubmit' -Session 'pinroot-binding') -Environment $disabledLauncherEnv
    Assert-True ($r.ExitCode -eq 0 -and $r.StdOut.Trim() -eq '{}') ("launcher: the pinned dispatcher got the pin's binding (got '{0}')" -f $r.StdOut.Trim())
    Set-Content -LiteralPath $bindingsPath -Value ($pinBindings | ConvertTo-Json -Depth 4)

    # --- a binding stamped for another commit, or none at all: the launcher refuses before any pin code runs ---
    foreach ($case in @('stamped for another commit', 'missing')) {
        if ($case -eq 'missing') { Remove-Item -LiteralPath $bindingsPath -Force }
        else {
            $stale = $pinBindings | ConvertTo-Json -Depth 4 | ConvertFrom-Json
            $stale.commit = ([guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')).Substring(0, 40)
            Set-Content -LiteralPath $bindingsPath -Value ($stale | ConvertTo-Json -Depth 4)
        }
        $runtimeBefore = Get-TreeSnapshot -Root (Join-Path $project '.specrew')
        $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $claudeCommands['Stop']) -Stdin (New-Payload -EventName 'Stop' -Session 'pinroot-stamp') -Environment $hookEnv
        Assert-True ($r.ExitCode -ne 0 -and (ConvertTo-PlainStderr $r.StdErr) -match 'host settings in') ("binding {0}, Claude: the launcher refuses (exit {1})" -f $case, $r.ExitCode)
        $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $launcher, '-Event', 'UserPromptSubmit', '-HostKind', 'codex') -Stdin (New-Payload -EventName 'UserPromptSubmit' -Session 'pinroot-stamp') -Environment $launcherEnv
        Assert-True ($r.ExitCode -ne 0 -and (ConvertTo-PlainStderr $r.StdErr) -match 'host settings in') ("binding {0}, launcher: the launcher refuses (exit {1})" -f $case, $r.ExitCode)
        $runtimeAfter = Get-TreeSnapshot -Root (Join-Path $project '.specrew')
        Assert-True (@(Compare-Object -ReferenceObject $runtimeBefore -DifferenceObject $runtimeAfter).Count -eq 0) ("binding {0}: no pin code ran (nothing was recorded)" -f $case)
    }
    Set-Content -LiteralPath $bindingsPath -Value ($pinBindings | ConvertTo-Json -Depth 4)

    # --- the pin's helper is missing: the providers refuse instead of loading the project's code (round 5, finding 3) ---
    # The launcher accepts the pin (its HEAD, dispatcher and stamped binding are all in order); the pinned providers
    # then cannot resolve the pin. Read as "no pin", their fallback would load the project's scripts/internal - the
    # traps here, which record their name when they run.
    $pinHelpers = @(Get-ChildItem -LiteralPath $pin -Recurse -File -Filter 'live-engine-resolution.ps1')
    $helperBackup = Join-Path $work 'helper-backup'
    New-Item -ItemType Directory -Path $helperBackup -Force | Out-Null
    $saved = @(foreach ($h in $pinHelpers) { $copy = Join-Path $helperBackup ([guid]::NewGuid().ToString('N')); Copy-Item -LiteralPath $h.FullName -Destination $copy; [pscustomobject]@{ Path = $h.FullName; Copy = $copy } })
    foreach ($h in $pinHelpers) { Remove-Item -LiteralPath $h.FullName -Force }
    if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }
    $helperOutput = ''
    foreach ($eventName in @('SessionStart', 'UserPromptSubmit', 'Stop')) {
        $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $claudeCommands[$eventName]) -Stdin (New-Payload -EventName $eventName -Session 'pinroot-helper') -Environment $hookEnv
        $helperOutput += $r.StdOut
    }
    $ran = if (Test-Path -LiteralPath $marker) { (Get-Content -LiteralPath $marker) -join ', ' } else { '' }
    Assert-True ($pinHelpers.Count -ge 1 -and [string]::IsNullOrEmpty($ran)) ("pin helper missing: none of the project's own engine copies ran (ran: '{0}')" -f $ran)
    Assert-True ((ConvertTo-PlainStderr $helperOutput) -match 'missing its pin helper') 'pin helper missing: the hooks say in plain words that the reviewed engine could not be loaded'
    foreach ($s in $saved) { Copy-Item -LiteralPath $s.Copy -Destination $s.Path -Force }

    # --- a pin moved off its recorded commit: the launcher refuses before any pin code runs ---
    # The launcher's own check, not the pin's: a dispatcher checking its own pin would be the unreviewed code deciding
    # whether it may run. Any pin code that ran would write into the project.
    $otherCommit = ([guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')).Substring(0, 40)
    Set-Content -LiteralPath (Join-Path $project '.specrew/runtime/live-engine.json') -Value (([ordered]@{ schema_version = '1'; path = $pin; commit = $otherCommit }) | ConvertTo-Json)
    $runtimeBefore = Get-TreeSnapshot -Root (Join-Path $project '.specrew')
    $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $claudeCommands['Stop']) -Stdin (New-Payload -EventName 'Stop' -Session 'pinroot-moved') -Environment $hookEnv
    Assert-True ($r.ExitCode -ne 0 -and (ConvertTo-PlainStderr $r.StdErr) -match 'not at the reviewed commit') ("pin off its commit, Claude: the launcher refuses (exit {0})" -f $r.ExitCode)
    $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $launcher, '-Event', 'UserPromptSubmit', '-HostKind', 'codex') -Stdin (New-Payload -EventName 'UserPromptSubmit' -Session 'pinroot-moved') -Environment $launcherEnv
    Assert-True ($r.ExitCode -ne 0 -and (ConvertTo-PlainStderr $r.StdErr) -match 'not at the reviewed commit') ("pin off its commit, launcher: the launcher refuses (exit {0})" -f $r.ExitCode)
    $runtimeAfter = Get-TreeSnapshot -Root (Join-Path $project '.specrew')
    Assert-True (@(Compare-Object -ReferenceObject $runtimeBefore -DifferenceObject $runtimeAfter).Count -eq 0) 'pin off its commit: no pin code ran (nothing was recorded)'
    Assert-True (-not (Test-Path -LiteralPath $marker)) "pin off its commit: nothing falls back to the project's deployed copy"

    # --- a record whose pin is gone refuses visibly and runs nothing ---
    Set-Content -LiteralPath (Join-Path $project '.specrew/runtime/live-engine.json') -Value (([ordered]@{ schema_version = '1'; path = (Join-Path $work 'absent'); commit = $pinCommit }) | ConvertTo-Json)
    if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }
    $runtimeBefore = Get-TreeSnapshot -Root (Join-Path $project '.specrew')
    $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $claudeCommands['UserPromptSubmit']) -Stdin (New-Payload -EventName 'UserPromptSubmit' -Session 'pinroot-gone') -Environment $hookEnv
    Assert-True ($r.ExitCode -ne 0 -and (ConvertTo-PlainStderr $r.StdErr) -match 'could not load its reviewed engine') ("missing pin, Claude: the hook refuses in plain words (exit {0})" -f $r.ExitCode)
    $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $launcher, '-Event', 'Stop', '-HostKind', 'codex') -Stdin (New-Payload -EventName 'Stop' -Session 'pinroot-gone') -Environment $launcherEnv
    Assert-True ($r.ExitCode -ne 0 -and (ConvertTo-PlainStderr $r.StdErr) -match 'could not load its reviewed engine') ("missing pin, launcher: the hook refuses in plain words (exit {0})" -f $r.ExitCode)
    Assert-True (-not (Test-Path -LiteralPath $marker)) "missing pin: nothing falls back to the project's deployed copy"
    $runtimeAfter = Get-TreeSnapshot -Root (Join-Path $project '.specrew')
    Assert-True (@(Compare-Object -ReferenceObject $runtimeBefore -DifferenceObject $runtimeAfter).Count -eq 0) 'missing pin: nothing was recorded'

    # --- the kill switch works while the pin is broken (round 3, finding 2) ---
    # It comes before the pin check in both launchers, so turning the hooks off is a recovery that cannot be refused.
    $offEnv = $hookEnv.Clone(); $offEnv['SPECREW_REFOCUS_DISABLE'] = '1'
    $offLauncherEnv = $launcherEnv.Clone(); $offLauncherEnv['SPECREW_REFOCUS_DISABLE'] = '1'
    $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $claudeCommands['Stop']) -Stdin (New-Payload -EventName 'Stop' -Session 'pinroot-off') -Environment $offEnv
    Assert-True ($r.ExitCode -eq 0 -and (ConvertTo-PlainStderr $r.StdErr) -notmatch 'could not load') ("hooks switched off, pin missing, Claude: exits 0 without the refusal (exit {0})" -f $r.ExitCode)
    $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $launcher, '-Event', 'Stop', '-HostKind', 'codex') -Stdin (New-Payload -EventName 'Stop' -Session 'pinroot-off') -Environment $offLauncherEnv
    Assert-True ($r.ExitCode -eq 0 -and (ConvertTo-PlainStderr $r.StdErr) -notmatch 'could not load') ("hooks switched off, pin missing, launcher: exits 0 without the refusal (exit {0})" -f $r.ExitCode)
    Assert-True (-not (Test-Path -LiteralPath $marker)) 'hooks switched off: nothing ran'

    # --- no record: the launcher runs the project's own deployed dispatcher, as before ---
    Remove-Item -LiteralPath (Join-Path $project '.specrew/runtime/live-engine.json') -Force
    $r = Invoke-Hook -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $claudeCommands['UserPromptSubmit']) -Stdin (New-Payload -EventName 'UserPromptSubmit' -Session 'pinroot-none') -Environment $hookEnv
    $ran = if (Test-Path -LiteralPath $marker) { (Get-Content -LiteralPath $marker) -join ', ' } else { '' }
    Assert-True ($ran -eq 'specrew-hook-dispatcher.ps1') ("no pin configured: the project's deployed dispatcher runs, as today (ran: '{0}')" -f $ran)
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

if ($script:failCount -gt 0) { Write-Host "$script:failCount failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'All live-engine hook-root checks passed.' -ForegroundColor Green
exit 0
