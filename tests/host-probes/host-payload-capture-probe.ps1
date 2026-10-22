#!/usr/bin/env pwsh
# Layer-1 host payload probe (feature 202 iteration 002; B4F-144, B4F-145 layer 1).
#
# WHY THIS EXISTS: B4F-129's fix passed its tests, ten review rounds and CI, and failed live at M1, because every Copilot
# fixture it was tested on came through Copilot's own hooks, while the bug is in Claude's hooks, which Copilot runs too
# and feeds a different payload. This probe runs the REAL host CLIs headless in scratch projects with a capture hook on
# every hook channel, saves the raw payloads, and replays each one through Specrew's real deployed hook. It fails when
# the dispatcher would write an unrecognized-payload record, when a Claude hook run by Copilot does not stand down, or
# when a host's own payload is not handled. Run it on every host version change and before every beta.
#
# CHANNELS:
#   copilot               Copilot's own hooks (COPILOT_HOME/hooks/*.json)
#   copilot-claude-hooks  Claude's hooks in .claude/settings.local.json, as Copilot runs them (B4F-129)
#   claude                Claude Code's own hooks
#   codex                 Codex's own hooks (CODEX_HOME/hooks.json)
# Each host runs a plain prompt and a prompt that starts a sub-agent, so sub-agent payloads are captured too.
#
# ISOLATION: every run is in a scratch folder outside any repository, never in a governed project. COPILOT_HOME and
# CODEX_HOME point at scratch homes (Codex gets a copy of auth.json, removed with the scratch homes); Claude reads only
# the scratch project's local settings (--setting-sources local). The real user hook files are hashed before and
# verified unchanged after. The captures stay in -OutDir: the payloads, and the NAMES (never values) of the
# environment variables each hook saw.
#
# -FixtureOut <dir> writes one fixture per distinct payload shape, per channel and event, with a provenance.json.
# DEGRADES HONESTLY: a host CLI that is absent or a run that cannot complete is reported as skipped, not passed.
[CmdletBinding()]
param(
    [ValidateSet('copilot', 'claude', 'codex')]
    [string[]]$Hosts = @('copilot', 'claude', 'codex'),
    [string]$OutDir,
    [string]$FixtureOut,
    [string]$ResultPath,
    [int]$PerRunTimeoutSec = 300
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot 'deployed-hook-harness.ps1')
. (Join-Path $PSScriptRoot 'probe-fixture-redaction.ps1')

$script:Passed = 0; $script:Failed = 0; $script:Skipped = 0
function Note([string]$m) { Write-Host $m }
function Check([string]$name, [bool]$ok, [string]$detail = '') {
    if ($ok) { $script:Passed++; Note ("PASS: {0}" -f $name) } else { $script:Failed++; Note ("FAIL: {0} {1}" -f $name, $detail) }
}
function Write-Result {
    $result = if ($script:Failed -gt 0) { 'failed' } elseif ($script:Passed -eq 0) { 'skipped' } else { 'passed' }
    if (-not [string]::IsNullOrWhiteSpace($ResultPath)) {
        (@{ schema_version = '1.0'; result = $result; counts = @{ passed = [int]$script:Passed; failed = [int]$script:Failed; skipped = [int]$script:Skipped } } | ConvertTo-Json) |
            Set-Content -LiteralPath $ResultPath -Encoding UTF8
    }
    return $result
}

if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = Join-Path ([IO.Path]::GetTempPath()) ('host-payload-probe-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmss')) }
$OutDir = [IO.Path]::GetFullPath($OutDir)
$captureDir = Join-Path $OutDir 'captures'
New-Item -ItemType Directory -Force -Path $captureDir | Out-Null
$homesRoot = Join-Path ([IO.Path]::GetTempPath()) ('host-payload-homes-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $homesRoot | Out-Null
Note ("captures: {0}" -f $captureDir)

# The capture hook: raw stdin bytes to <channel>__<event>__<stamp>.json, and a .meta.json with the environment
# variable NAMES. It writes nothing to stdout, so the host carries on as if no hook ran.
$captureScript = Join-Path $homesRoot 'capture-hook.ps1'
@'
param([string]$Channel, [string]$Event, [string]$OutDir)
try {
    $ms = [IO.MemoryStream]::new(); [Console]::OpenStandardInput().CopyTo($ms); $bytes = $ms.ToArray()
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffff')
    $base = Join-Path $OutDir ('{0}__{1}__{2}__{3}' -f $Channel, $Event, $stamp, [guid]::NewGuid().ToString('N').Substring(0, 6))
    [IO.File]::WriteAllBytes($base + '.json', $bytes)
    $names = @([Environment]::GetEnvironmentVariables().Keys | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $meta = [ordered]@{ channel = $Channel; event = $Event; captured_utc = [DateTime]::UtcNow.ToString('o'); stdin_bytes = $bytes.Length
        sha256 = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant(); env_names = $names }
    [IO.File]::WriteAllText($base + '.meta.json', ($meta | ConvertTo-Json -Depth 4), [Text.UTF8Encoding]::new($false))
}
catch { $null = $_ }
exit 0
'@ | Set-Content -LiteralPath $captureScript -Encoding UTF8

function Get-CaptureCommand {
    param([string]$Channel, [string]$Event)
    return ('pwsh -NoProfile -ExecutionPolicy Bypass -File "{0}" -Channel {1} -Event {2} -OutDir "{3}"' -f ($captureScript -replace '\\', '/'), $Channel, $Event, ($captureDir -replace '\\', '/'))
}

function Write-ClaudeCaptureSettings {
    # Claude's hook settings, in the form `specrew init` writes them, with the capture hook on every event.
    param([string]$ProjectDir, [string]$Channel)
    $hooks = [ordered]@{}
    foreach ($ev in 'SessionStart', 'SessionEnd', 'UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'Stop', 'SubagentStart', 'SubagentStop', 'Notification', 'PreCompact') {
        $hooks[$ev] = @([ordered]@{ hooks = @([ordered]@{ type = 'command'; command = (Get-CaptureCommand -Channel $Channel -Event $ev); timeout = 30 }) })
    }
    New-Item -ItemType Directory -Force -Path (Join-Path $ProjectDir '.claude') | Out-Null
    ([ordered]@{ hooks = $hooks } | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath (Join-Path $ProjectDir '.claude/settings.local.json') -Encoding UTF8
}

$script:InheritedHostMarkerPattern = '^(CLAUDE_PROJECT_DIR|CURSOR_PROJECT_DIR|COPILOT_PROJECT_DIR|CLAUDECODE|CLAUDE_CODE_\w*|CLAUDE_PID|CLAUDE_EFFORT|AI_AGENT)$'
$script:LaunchEnvNames = @{}
function Invoke-HostCli {
    param([string]$HostLabel, [string]$FileName, [string[]]$Arguments, [string]$WorkDir, [hashtable]$Environment = @{})
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FileName
    foreach ($a in $Arguments) { [void]$psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $WorkDir
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.RedirectStandardInput = $true
    foreach ($k in $Environment.Keys) { $psi.Environment[$k] = [string]$Environment[$k] }
    # A run must never resolve to a governed project through an inherited project-root variable, and must not inherit
    # the markers of an agent session the probe itself was started from: each host sets its own.
    foreach ($var in @($psi.Environment.Keys)) { if ($var -match $script:InheritedHostMarkerPattern) { $psi.Environment.Remove($var) | Out-Null } }
    $script:LaunchEnvNames[$HostLabel] = @($psi.Environment.Keys | ForEach-Object { [string]$_ })
    $p = [System.Diagnostics.Process]::new(); $p.StartInfo = $psi
    [void]$p.Start(); $p.StandardInput.Close()
    $outTask = $p.StandardOutput.ReadToEndAsync(); $errTask = $p.StandardError.ReadToEndAsync()
    $timed = -not $p.WaitForExit($PerRunTimeoutSec * 1000)
    if ($timed) { try { $p.Kill($true) } catch { $null = $_ } }
    $out = try { $outTask.GetAwaiter().GetResult() } catch { '' }
    $null = try { $errTask.GetAwaiter().GetResult() } catch { '' }
    return [pscustomobject]@{ TimedOut = $timed; ExitCode = $(if ($timed) { -1 } else { $p.ExitCode }); Output = $out }
}

$plainPrompt = 'Reply with exactly the single word: PONG'
$subagentPrompt = @{
    copilot = 'Use your task tool to start exactly one sub-agent of type explore whose only job is to list the file names in the current directory. Wait for it to finish, then reply with exactly the single word: DONE'
    claude  = 'Use the Task tool to start exactly one general-purpose sub-agent whose only job is to list the file names in the current directory. Wait for it to finish, then reply with exactly the single word: DONE'
    codex   = 'List the file names in the current directory with one shell command, then reply with exactly the single word: DONE'
}

# Hash the real user hook and config files so the run can prove it left them alone.
$watched = @(
    (Join-Path $HOME '.copilot/hooks/specrew-refocus.json')
    (Join-Path $HOME '.claude/settings.json')
    (Join-Path $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }) 'hooks.json')
    (Join-Path $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }) 'config.toml')
) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
$before = @{}; foreach ($f in $watched) { $before[$f] = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash }

$versions = [ordered]@{}
$ranHosts = New-Object System.Collections.Generic.List[string]
try {
    foreach ($hostKind in $Hosts) {
        $cli = Get-Command $hostKind -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -eq $cli) { Note ("SKIP: {0} is not installed on PATH" -f $hostKind); $script:Skipped++; continue }
        $versions[$hostKind] = [string](& $cli.Source --version 2>$null | Select-Object -First 1)
        Note ("{0} version: {1}" -f $hostKind, $versions[$hostKind])
        $completed = 0
        foreach ($run in 'plain', 'subagent') {
            $prompt = if ($run -eq 'plain') { $plainPrompt } else { $subagentPrompt[$hostKind] }
            $work = Join-Path $homesRoot ("{0}-{1}-work" -f $hostKind, $run)
            New-Item -ItemType Directory -Force -Path $work | Out-Null
            Set-Content -LiteralPath (Join-Path $work 'notes.txt') -Value 'probe file' -Encoding UTF8
            # A git repository, as a walk project is: Copilot finds the Claude hook settings from the repository root.
            & git init -q $work 2>&1 | Out-Null
            switch ($hostKind) {
                'copilot' {
                    $copilotHome = Join-Path $homesRoot ("copilot-home-{0}" -f $run)
                    New-Item -ItemType Directory -Force -Path (Join-Path $copilotHome 'hooks') | Out-Null
                    $copilotHooks = [ordered]@{}
                    foreach ($ev in 'sessionStart', 'sessionEnd', 'userPromptSubmitted', 'preToolUse', 'postToolUse', 'agentStop', 'subagentStop', 'errorOccurred') {
                        $cmd = Get-CaptureCommand -Channel 'copilot' -Event $ev
                        $copilotHooks[$ev] = @([ordered]@{ type = 'command'; bash = $cmd; powershell = $cmd; timeoutSec = 30 })
                    }
                    ([ordered]@{ version = 1; hooks = $copilotHooks } | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath (Join-Path $copilotHome 'hooks/probe-capture.json') -Encoding UTF8
                    # The work folder is trusted, as a walk project is, so repo-level hook settings apply. Copilot keeps the
                    # trusted folders in config.json (measured on 1.0.101; settings.json holds user settings only).
                    (@{ trustedFolders = @($work) } | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $copilotHome 'config.json') -Encoding UTF8
                    Write-ClaudeCaptureSettings -ProjectDir $work -Channel 'copilot-claude-hooks'
                    $r = Invoke-HostCli -HostLabel 'copilot' -FileName $cli.Source -WorkDir $work -Environment @{ COPILOT_HOME = $copilotHome } -Arguments @('--allow-all-tools', '--no-ask-user', '--no-color', '--log-level', 'none', '-p', $prompt)
                }
                'claude' {
                    Write-ClaudeCaptureSettings -ProjectDir $work -Channel 'claude'
                    $r = Invoke-HostCli -HostLabel 'claude' -FileName $cli.Source -WorkDir $work -Arguments @('-p', $prompt, '--setting-sources', 'local', '--dangerously-skip-permissions')
                }
                'codex' {
                    $realCodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
                    $auth = Join-Path $realCodexHome 'auth.json'
                    if (-not (Test-Path -LiteralPath $auth -PathType Leaf)) { Note 'SKIP: no codex auth.json (headless exec cannot authenticate)'; $r = $null; break }
                    $codexHome = Join-Path $homesRoot ("codex-home-{0}" -f $run)
                    New-Item -ItemType Directory -Force -Path $codexHome | Out-Null
                    Copy-Item -LiteralPath $auth -Destination (Join-Path $codexHome 'auth.json') -Force
                    $codexHooks = [ordered]@{}
                    foreach ($ev in 'SessionStart', 'UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'Stop') {
                        $codexHooks[$ev] = @([ordered]@{ hooks = @([ordered]@{ type = 'command'; command = (Get-CaptureCommand -Channel 'codex' -Event $ev); timeout = 30 }) })
                    }
                    ([ordered]@{ hooks = $codexHooks } | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath (Join-Path $codexHome 'hooks.json') -Encoding UTF8
                    $r = Invoke-HostCli -HostLabel 'codex' -FileName $cli.Source -WorkDir $work -Environment @{ CODEX_HOME = $codexHome } -Arguments @('exec', '--json', '--skip-git-repo-check', '--dangerously-bypass-approvals-and-sandbox', '--dangerously-bypass-hook-trust', '-C', $work, $prompt)
                }
            }
            if ($null -eq $r -or $r.TimedOut) { Note ("SKIP: {0} {1} run did not complete" -f $hostKind, $run); $script:Skipped++; continue }
            Note ("{0} {1} run: exit {2}" -f $hostKind, $run, $r.ExitCode)
            $completed++
        }
        if ($completed -gt 0) { $ranHosts.Add($hostKind) | Out-Null }
    }

    # What came in, per channel and event, as sorted field-name sets.
    $captures = @(Get-ChildItem -LiteralPath $captureDir -Filter '*.json' | Where-Object { $_.Name -notlike '*.meta.json' } | Sort-Object Name | ForEach-Object {
            $parts = $_.BaseName -split '__'
            $payload = $null
            try { $payload = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8) | ConvertFrom-Json } catch { $payload = $null }
            $fields = if ($null -ne $payload -and $payload -is [psobject]) { @($payload.PSObject.Properties | ForEach-Object { [string]$_.Name } | Sort-Object) } else { @() }
            [pscustomobject]@{ File = $_; Channel = $parts[0]; Event = $parts[1]; Fields = $fields; Shape = ($fields -join ',') }
        })
    Note ''
    Note 'Payload shapes captured:'
    foreach ($g in @($captures | Group-Object Channel, Event, Shape | Sort-Object Name)) {
        $first = $g.Group[0]
        $sub = if ($first.Shape -match '(?i)(^|,)(agent_?id|parent_?agent_?id)(,|$)') { '  [sub-agent]' } else { '' }
        Note ("  {0} {1} x{2}: {3}{4}" -f $first.Channel, $first.Event, $g.Count, $first.Shape, $sub)
    }
    Note ''

    foreach ($hostKind in $ranHosts) {
        $own = @($captures | Where-Object { $_.Channel -eq $hostKind })
        Check ("{0}: its own hooks fired and were captured" -f $hostKind) ($own.Count -gt 0) ("captures=$($own.Count)")
        if ($hostKind -eq 'copilot') {
            $viaClaude = @($captures | Where-Object { $_.Channel -eq 'copilot-claude-hooks' })
            # The B4F-129 channel. A run that captured nothing here cannot vouch for the stand-down, so it fails: either this
            # Copilot version no longer runs Claude's hooks, or the probe no longer reaches them; a human decides which.
            Check 'copilot: Claude''s hooks, run by Copilot, fired and were captured (the B4F-129 channel)' ($viaClaude.Count -gt 0) 'captures=0'
        }
    }

    # Replay every capture through Specrew's real deployed hook for the host whose hook received it.
    $targets = @{ copilot = 'copilot'; 'copilot-claude-hooks' = 'claude'; claude = 'claude'; codex = 'codex' }
    $handledEvents = @('SessionStart', 'sessionStart', 'UserPromptSubmit', 'userPromptSubmitted', 'Stop', 'agentStop')
    $projects = @{}
    try {
        foreach ($c in $captures) {
            $target = $targets[$c.Channel]
            if (-not $projects.ContainsKey($target)) { $projects[$target] = New-TurnRecordProject -HostKind $target }
            $fx = $projects[$target]
            $deployed = $null
            try { $deployed = Get-DeployedHookCommand -Fixture $fx -NativeEvent $c.Event } catch { $deployed = $null }
            if ([string]::IsNullOrWhiteSpace($deployed)) { continue }   # Specrew deploys no hook on this event
            Clear-HarnessRuntime $fx
            $runtimeBefore = Get-HarnessRuntimeSnapshot $fx
            $r = Invoke-DeployedHook -Fixture $fx -NativeEvent $c.Event -StdinBytes ([IO.File]::ReadAllBytes($c.File.FullName))
            $label = "[{0} {1} -> {2} hook] {3}" -f $c.Channel, $c.Event, $target, $c.File.Name
            Check "$label - exits 0" ($r.ExitCode -eq 0) $r.StdErr
            $unrecognized = @(Get-HarnessUnrecognizedLogs $fx)
            Check "$label - the dispatcher recognizes the payload (no unrecognized-payload record)" ($unrecognized.Count -eq 0) ("fields: " + $c.Shape)
            $ran = @($r.Calls.Keys).Count -gt 0
            if ($c.Channel -eq 'copilot-claude-hooks') {
                Check "$label - Claude's hook run by Copilot stands down: nothing ran" (-not $ran)
                $changed = @(Compare-Object -ReferenceObject $runtimeBefore -DifferenceObject (Get-HarnessRuntimeSnapshot $fx) | ForEach-Object { [string]$_.InputObject })
                Check "$label - and wrote nothing under .specrew/runtime" ($changed.Count -eq 0) ($changed -join '; ')
            }
            elseif ($handledEvents -contains $c.Event -and $c.Event -in @('Stop', 'agentStop') -and $c.Shape -cmatch '(^|,)(agent_id|parent_agent_id|agentId|parentAgentId)(,|$)') {
                # Iteration 003 review round 2: a sub-agent's stop is not the end of the human's turn; the hook stands down.
                Check "$label - a sub-agent's stop stands down: nothing ran" (-not $ran)
                $changed = @(Compare-Object -ReferenceObject $runtimeBefore -DifferenceObject (Get-HarnessRuntimeSnapshot $fx) | ForEach-Object { [string]$_.InputObject })
                Check "$label - and wrote nothing under .specrew/runtime" ($changed.Count -eq 0) ($changed -join '; ')
            }
            elseif ($handledEvents -contains $c.Event) {
                Check "$label - the host's own payload is handled" $ran
            }
        }
    }
    finally {
        foreach ($p in $projects.Values) { if ($p -and (Test-Path -LiteralPath $p.Base)) { Remove-Item -LiteralPath $p.Base -Recurse -Force -ErrorAction SilentlyContinue } }
    }

    if (-not [string]::IsNullOrWhiteSpace($FixtureOut)) {
        # One fixture per distinct shape, per channel and event, with its provenance: the names (never values) of the
        # environment variables the host added for its hook, i.e. those the probe did not launch it with.
        foreach ($chan in @($captures | Select-Object -ExpandProperty Channel -Unique)) {
            $dir = Join-Path $FixtureOut $chan
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            $entries = New-Object System.Collections.Generic.List[object]
            foreach ($g in @($captures | Where-Object { $_.Channel -eq $chan } | Group-Object Event, Shape | Sort-Object Name)) {
                $c = $g.Group[0]
                $sub = if ($c.Shape -match '(?i)(^|,)(agent_?id|parent_?agent_?id)(,|$)') { '-subagent' } else { '' }
                $n = 1
                do { $leaf = ('probe-{0}{1}-{2}.json' -f $c.Event.ToLowerInvariant(), $sub, $n); $n++ } while (Test-Path -LiteralPath (Join-Path $dir $leaf))
                # The fixture is the captured payload with the user name in its profile paths replaced (review round 2).
                $fixtureText = ConvertTo-ProbeRedactedFixtureText -Text ([IO.File]::ReadAllText($c.File.FullName, [Text.UTF8Encoding]::new($false)))
                $fixtureBytes = [Text.UTF8Encoding]::new($false).GetBytes($fixtureText)
                [IO.File]::WriteAllBytes((Join-Path $dir $leaf), $fixtureBytes)
                $meta = Get-Content -LiteralPath ($c.File.FullName -replace '\.json$', '.meta.json') -Raw | ConvertFrom-Json
                # ConvertFrom-Json turns the ISO time into a DateTime; [string] of that drops the zone and the fraction.
                $capturedUtc = if ($meta.captured_utc -is [datetime]) { $meta.captured_utc.ToUniversalTime().ToString('o') } else { [string]$meta.captured_utc }
                $hostKind = if ($chan -like 'copilot*') { 'copilot' } else { $chan }
                $entries.Add([ordered]@{
                        fixture = $leaf; channel = $chan; event = $c.Event; captured_utc = $capturedUtc; host_version = $versions[$hostKind]
                        stdin_bytes = [int]$meta.stdin_bytes; sha256 = [string]$meta.sha256
                        fixture_sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($fixtureBytes)).ToLowerInvariant(); field_names = @($c.Fields)
                        host_env_names = @(@($meta.env_names) | Where-Object { @($script:LaunchEnvNames[$hostKind]) -notcontains $_ }); origin = 'recorded'
                    }) | Out-Null
            }
            $prov = [ordered]@{ task = 'B4F-144 fix (feature 202, iteration 002)'; channel = $chan
                method = 'tests/host-probes/host-payload-capture-probe.ps1: the real host CLI, headless, in a scratch folder outside any repository; a capture hook copied raw stdin bytes. Environment values are not recorded.'
                redaction = 'The user name in every profile path is replaced with probe-user (tests/host-probes/probe-fixture-redaction.ps1). sha256 is the captured bytes; fixture_sha256 is the file.'
                fixtures = $entries.ToArray() }
            [IO.File]::WriteAllText((Join-Path $dir 'provenance.json'), ($prov | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
            Note ("fixtures written: {0}" -f $dir)
        }
    }
}
finally {
    $mutated = @(); foreach ($f in $watched) { if ((Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash -ne $before[$f]) { $mutated += $f } }
    if ($mutated.Count -gt 0) { Note ("ATTESTATION FAILURE: real host files MUTATED: {0}" -f ($mutated -join ', ')); $script:Failed++ }
    else { Note ("isolation attestation: the real user hook and config files are byte-unchanged ({0} files)" -f $watched.Count) }
    # The scratch homes hold the copied Codex credential and the hosts' session state; the captures stay in -OutDir.
    Remove-Item -LiteralPath $homesRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$result = Write-Result
Note ("host payload probe: {0} (passed={1} failed={2} skipped={3}); captures in {4}" -f $result, $script:Passed, $script:Failed, $script:Skipped, $captureDir)
if ($script:Failed -gt 0) { exit 1 }
exit 0
