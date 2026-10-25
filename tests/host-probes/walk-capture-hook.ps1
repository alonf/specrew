# Feature 202 iteration 002, T030 (SC-011; B4F-144, B4F-145): a capture hook for a live walk.
#
# The 2026-10-20 re-walk saw payload shapes no test had, and kept only their field names. With this hook installed for
# the walk, every payload Copilot sends is kept as raw bytes, on both channels, so a shape seen live can become a
# fixture (tests/fixtures/hook-payloads/probe/) and be replayed through the deployed hooks.
#
#   -Install -Project <walk project> -OutDir <folder>
#       writes the capture script into -OutDir; adds <COPILOT_HOME>/hooks/specrew-walk-capture.json (Copilot's own
#       channel); adds a capture group per event to <project>/.claude/settings.local.json (Claude's hooks as Copilot runs
#       them). Specrew's deployer keeps user groups in that file as they are, so a session start does not remove them.
#   -Remove -Project <walk project> -OutDir <folder>
#       moves the Copilot capture file into -OutDir (nothing is deleted) and takes the capture groups back out of the
#       project's Claude settings, leaving Specrew's own groups as they were.
#   -Summary -OutDir <folder>
#       counts the captures per channel and event, with the field names of each shape.
#
# The capture hook writes nothing to stdout and always exits 0, so the host carries on as if it had not run. It keeps
# the payload bytes and the NAMES of the environment variables, never their values.
[CmdletBinding(DefaultParameterSetName = 'Summary')]
param(
    [Parameter(ParameterSetName = 'Install', Mandatory = $true)][switch]$Install,
    [Parameter(ParameterSetName = 'Remove', Mandatory = $true)][switch]$Remove,
    [Parameter(ParameterSetName = 'Summary')][switch]$Summary,
    [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
    [Parameter(ParameterSetName = 'Remove', Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$OutDir
)
$ErrorActionPreference = 'Stop'

$OutDir = [IO.Path]::GetFullPath($OutDir)
$captureDir = Join-Path $OutDir 'captures'
$captureScript = Join-Path $OutDir 'capture-hook.ps1'
$copilotHome = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { Join-Path $HOME '.copilot' }
$copilotCaptureFile = Join-Path $copilotHome 'hooks/specrew-walk-capture.json'
$claudeEvents = 'SessionStart', 'SessionEnd', 'UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'Stop', 'SubagentStart', 'SubagentStop', 'Notification', 'PreCompact'
$copilotEvents = 'sessionStart', 'sessionEnd', 'userPromptSubmitted', 'preToolUse', 'postToolUse', 'agentStop', 'subagentStop', 'errorOccurred'

function Get-CaptureCommand {
    param([string]$Channel, [string]$Event)
    return ('pwsh -NoProfile -ExecutionPolicy Bypass -File "{0}" -Channel {1} -Event {2} -OutDir "{3}"' -f ($captureScript -replace '\\', '/'), $Channel, $Event, ($captureDir -replace '\\', '/'))
}

function Test-CaptureGroup {
    # A Claude settings group that holds only this hook's capture command.
    param($Group)
    $hooks = @($Group.hooks)
    return ($hooks.Count -gt 0 -and @($hooks | Where-Object { [string]$_.command -notlike '*capture-hook.ps1*' }).Count -eq 0)
}

function Get-ClaudeSettingsPath { return (Join-Path ([IO.Path]::GetFullPath($Project)) '.claude/settings.local.json') }

if ($Install) {
    New-Item -ItemType Directory -Force -Path $captureDir | Out-Null
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

    # Copilot's own channel: a hooks file of its own, beside Specrew's.
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $copilotCaptureFile) | Out-Null
    $copilotHooks = [ordered]@{}
    foreach ($ev in $copilotEvents) {
        $cmd = Get-CaptureCommand -Channel 'copilot' -Event $ev
        $copilotHooks[$ev] = @([ordered]@{ type = 'command'; bash = $cmd; powershell = $cmd; timeoutSec = 30 })
    }
    ([ordered]@{ version = 1; hooks = $copilotHooks } | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $copilotCaptureFile -Encoding UTF8

    # Claude's hooks as Copilot runs them: one capture group per event, added after Specrew's.
    $settingsPath = Get-ClaudeSettingsPath
    if (-not (Test-Path -LiteralPath $settingsPath)) { throw "No Claude hook settings at $settingsPath. Run 'specrew init' in the project first." }
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json -AsHashtable
    if (-not $settings.ContainsKey('hooks')) { $settings['hooks'] = [ordered]@{} }
    foreach ($ev in $claudeEvents) {
        $groups = [System.Collections.Generic.List[object]]::new()
        if ($settings.hooks.Contains($ev)) { foreach ($g in @($settings.hooks[$ev])) { if (-not (Test-CaptureGroup $g)) { $groups.Add($g) } } }
        $groups.Add([ordered]@{ hooks = @([ordered]@{ type = 'command'; command = (Get-CaptureCommand -Channel 'copilot-claude-hooks' -Event $ev); timeout = 30 }) })
        $settings.hooks[$ev] = $groups.ToArray()
    }
    ($settings | ConvertTo-Json -Depth 20) | Set-Content -LiteralPath $settingsPath -Encoding UTF8
    Write-Host "Capture hook installed. Captures go to $captureDir"
    Write-Host "  Copilot's own channel: $copilotCaptureFile"
    Write-Host "  Claude's hooks under Copilot: $settingsPath"
    exit 0
}

if ($Remove) {
    if (Test-Path -LiteralPath $copilotCaptureFile) {
        $dest = Join-Path $OutDir ('specrew-walk-capture.{0}.json' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmss'))
        Move-Item -LiteralPath $copilotCaptureFile -Destination $dest
        Write-Host "Moved the Copilot capture file to $dest"
    }
    $settingsPath = Get-ClaudeSettingsPath
    if (Test-Path -LiteralPath $settingsPath) {
        $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json -AsHashtable
        $removed = 0
        if ($settings.ContainsKey('hooks')) {
            foreach ($ev in @($settings.hooks.Keys)) {
                $kept = @($settings.hooks[$ev] | Where-Object { -not (Test-CaptureGroup $_) })
                $removed += @($settings.hooks[$ev]).Count - $kept.Count
                if ($kept.Count -gt 0) { $settings.hooks[$ev] = $kept } else { $settings.hooks.Remove($ev) }
            }
        }
        ($settings | ConvertTo-Json -Depth 20) | Set-Content -LiteralPath $settingsPath -Encoding UTF8
        Write-Host "Took $removed capture group(s) out of $settingsPath"
    }
    exit 0
}

# Summary
$files = @(if (Test-Path -LiteralPath $captureDir) { Get-ChildItem -LiteralPath $captureDir -Filter '*.json' | Where-Object { $_.Name -notlike '*.meta.json' } })
Write-Host ("{0} payload(s) captured in {1}" -f $files.Count, $captureDir)
$rows = foreach ($f in $files) {
    $parts = $f.BaseName -split '__'
    $keys = try { @(([IO.File]::ReadAllText($f.FullName) | ConvertFrom-Json -AsHashtable).Keys | Sort-Object) -join ',' } catch { '<not JSON>' }
    [pscustomobject]@{ Channel = $parts[0]; Event = $parts[1]; Fields = $keys }
}
$rows | Group-Object Channel, Event, Fields | Sort-Object Name | ForEach-Object {
    [pscustomobject]@{ Count = $_.Count; Channel = $_.Group[0].Channel; Event = $_.Group[0].Event; Fields = $_.Group[0].Fields }
} | Format-Table -AutoSize -Wrap
exit 0
