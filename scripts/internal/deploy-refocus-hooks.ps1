# Feature 171 T010+T014 (FR-013/FR-014): merge-aware refocus hook deployment,
# multi-host. Per-host formats verified live 2026-06-07 (see
# specs/171-specrew-refocus/research-matrix.md for citations):
#
#   claude  : .claude/settings.local.json  (per-user project-local; merge-aware
#             groups under hooks.<Event>)  — SessionStart only (TG-004 option a)
#   codex   : ~/.codex/hooks.json          (top-level event keys -> groups with
#             matcher + hooks[]) — SessionStart (B1+B2) + UserPromptSubmit (B3)
#   copilot : ~/.copilot/hooks/specrew-refocus.json (hooks-DIR model: this file
#             is wholly Specrew-owned; {version,hooks.<event>[]} with type=command
#             + bash/powershell pair) — sessionStart (B2)
#   cursor  : ~/.cursor/hooks.json         ({version,hooks.<event>[]} with bare
#             {command} entries) — sessionStart (B2)
#
# C6 invariants (every host): add-if-absent; update ONLY entries recognized as
# Specrew's (dispatcher path inside the command); user entries preserved exactly;
# re-deploys byte-idempotent; recorded opt-out respected (never silently
# re-enabled); PreToolUse NEVER registered (dormant F-165 gate seat).
# User-level configs are safe because the dispatcher self-gates on `.specrew/`
# in the session cwd and resolves the PROJECT-LOCAL dispatcher via relative path.
[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [ValidateSet('claude', 'codex', 'copilot', 'cursor')][string]$HostKind = 'claude',
    [switch]$Remove,
    [switch]$Force,
    # Test seam: override the user-home root so suites never touch the real one.
    [string]$UserHomeOverride
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath $ProjectPath).Path
$userHome = if (-not [string]::IsNullOrWhiteSpace($UserHomeOverride)) { $UserHomeOverride } else { [Environment]::GetFolderPath('UserProfile') }
$dispatcherRelPath = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'

$settingsPath = switch ($HostKind) {
    'claude'  { Join-Path $projectRoot '.claude/settings.local.json' }
    'codex'   { Join-Path $userHome '.codex/hooks.json' }
    'copilot' { Join-Path $userHome '.copilot/hooks/specrew-refocus.json' }
    'cursor'  { Join-Path $userHome '.cursor/hooks.json' }
}
$optOutMarker = Join-Path $projectRoot ('.specrew/runtime/refocus-hooks-optout' + $(if ($HostKind -ne 'claude') { "-$HostKind" } else { '' }))

function Get-SpecrewHookCommand {
    param([string]$EventName)
    return ('pwsh -NoProfile -ExecutionPolicy Bypass -File "{0}" -Event {1} -HostKind {2}' -f $dispatcherRelPath, $EventName, $HostKind)
}

function Test-IsSpecrewCommandText {
    param([AllowNull()][string]$CommandText)
    return (-not [string]::IsNullOrWhiteSpace($CommandText)) -and $CommandText.Contains('specrew-hook-dispatcher.ps1')
}

function Test-IsSpecrewGroup {
    # A group is Specrew's when EVERY command inside it is ours. Group shapes vary:
    #   claude/codex: { matcher?, hooks: [ { type, command } ] }
    #   cursor:       { command }
    #   copilot:      { type, bash, powershell }
    param($Group)
    $commands = @()
    if ($Group.PSObject.Properties['hooks'] -and $null -ne $Group.hooks) {
        $commands = @(@($Group.hooks) | ForEach-Object { if ($_.PSObject.Properties['command']) { [string]$_.command } })
    }
    elseif ($Group.PSObject.Properties['command']) { $commands = @([string]$Group.command) }
    elseif ($Group.PSObject.Properties['bash'] -or $Group.PSObject.Properties['powershell']) {
        $commands = @(
            $(if ($Group.PSObject.Properties['bash']) { [string]$Group.bash }),
            $(if ($Group.PSObject.Properties['powershell']) { [string]$Group.powershell })
        ) | Where-Object { $_ }
    }
    if ($commands.Count -eq 0) { return $false }
    return @($commands | Where-Object { -not (Test-IsSpecrewCommandText -CommandText $_) }).Count -eq 0
}

function Remove-SpecrewEntriesFromEventMap {
    # Strips Specrew groups from an event map (PSCustomObject of event -> group[]).
    # Mixed claude/codex-style groups keep their user hooks; user groups untouched.
    param($EventMap)
    if ($null -eq $EventMap) { return }
    foreach ($eventProp in @($EventMap.PSObject.Properties)) {
        $kept = New-Object System.Collections.Generic.List[object]
        foreach ($group in @($eventProp.Value)) {
            if (Test-IsSpecrewGroup -Group $group) { continue }   # wholly ours: dropped
            if ($group.PSObject.Properties['hooks'] -and $null -ne $group.hooks) {
                $userHooks = @(@($group.hooks) | Where-Object {
                        -not ($_.PSObject.Properties['command'] -and (Test-IsSpecrewCommandText -CommandText ([string]$_.command)))
                    })
                if ($userHooks.Count -lt @($group.hooks).Count -and $userHooks.Count -gt 0) {
                    $group.PSObject.Properties['hooks'].Value = $userHooks
                }
                elseif ($userHooks.Count -eq 0) { continue }
            }
            $kept.Add($group) | Out-Null
        }
        # PSPropertyInfo setter — dynamic `$obj.($name) =` trips the binder on JSON objects.
        if ($kept.Count -gt 0) { $eventProp.Value = $kept.ToArray() }
        else { $EventMap.PSObject.Properties.Remove($eventProp.Name) }
    }
}

function Get-HostEventGroups {
    # The per-host registrations (verified formats; matrix-gated trigger set).
    switch ($HostKind) {
        'claude' {
            # TG-004 option (a): SessionStart (B1/B2 + F-174 bootstrap) + SessionEnd (F-174 handover,
            # Proposal 130 Pillar 4a - Claude's SessionEnd surface is documented). PostToolUse unregistered.
            return [ordered]@{
                'SessionStart' = [pscustomobject]@{ hooks = @([pscustomobject]@{ type = 'command'; command = (Get-SpecrewHookCommand -EventName 'SessionStart') }) }
                'SessionEnd'   = [pscustomobject]@{ hooks = @([pscustomobject]@{ type = 'command'; command = (Get-SpecrewHookCommand -EventName 'SessionEnd') }) }
            }
        }
        'codex' {
            # Full triad: SessionStart (source matchers route B1/B2 in-dispatcher)
            # + UserPromptSubmit as the per-human-prompt B3 carrier.
            return [ordered]@{
                'SessionStart'     = [pscustomobject]@{ hooks = @([pscustomobject]@{ type = 'command'; command = (Get-SpecrewHookCommand -EventName 'SessionStart'); timeout = 30 }) }
                'UserPromptSubmit' = [pscustomobject]@{ hooks = @([pscustomobject]@{ type = 'command'; command = (Get-SpecrewHookCommand -EventName 'UserPromptSubmit'); timeout = 30 }) }
            }
        }
        'copilot' {
            # B2 only (B1 pending local source-value verification; per-prompt
            # injection unverified on userPromptSubmitted -> channel 1 carries B3).
            $cmd = Get-SpecrewHookCommand -EventName 'SessionStart'
            return [ordered]@{
                'sessionStart' = [pscustomobject]@{ type = 'command'; bash = $cmd; powershell = $cmd; timeoutSec = 30 }
            }
        }
        'cursor' {
            # B2 only (B1 = documented variance: no post-compaction injection event;
            # B3 per-tool-call latency-rejected, per-prompt injection unverified).
            return [ordered]@{
                'sessionStart' = [pscustomobject]@{ command = (Get-SpecrewHookCommand -EventName 'SessionStart') }
            }
        }
    }
}

# --- load (or initialize) the target file --------------------------------------
$settings = $null
if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
    try { $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { throw "config file unreadable at $settingsPath — refusing to modify a file I cannot parse (user content safety): $($_.Exception.Message)" }
}
if ($null -eq $settings) { $settings = [pscustomobject]@{} }

# Locate the event map per host file shape.
#   claude/cursor/copilot: { ..., hooks: { event: [...] } } (+ version for cursor/copilot)
#   codex: top-level event keys ARE the map.
$eventMap = $null
if ($HostKind -eq 'codex') {
    $eventMap = $settings
}
else {
    if (-not $settings.PSObject.Properties['hooks'] -or $null -eq $settings.hooks) {
        $settings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $eventMap = $settings.hooks
}

function Save-Target {
    param($SettingsObject)
    if ($HostKind -in @('cursor', 'copilot') -and -not $SettingsObject.PSObject.Properties['version']) {
        $SettingsObject | Add-Member -NotePropertyName 'version' -NotePropertyValue 1 -Force
    }
    $json = $SettingsObject | ConvertTo-Json -Depth 16
    New-Item -ItemType Directory -Path (Split-Path -Parent $settingsPath) -Force | Out-Null
    [System.IO.File]::WriteAllText($settingsPath, $json, [System.Text.UTF8Encoding]::new($false))
}

if ($Remove) {
    if ($HostKind -eq 'copilot') {
        # Hooks-dir model: the whole file is ours — remove it.
        if (Test-Path -LiteralPath $settingsPath -PathType Leaf) { Remove-Item -LiteralPath $settingsPath -Force }
    }
    else {
        Remove-SpecrewEntriesFromEventMap -EventMap $eventMap
        Save-Target -SettingsObject $settings
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $optOutMarker) -Force | Out-Null
    [System.IO.File]::WriteAllText($optOutMarker, ("opted out {0}`n" -f (Get-Date).ToUniversalTime().ToString('o')), [System.Text.UTF8Encoding]::new($false))
    Write-Output ("[specrew-refocus] {0} hooks removed; opt-out recorded (re-enable: deploy-refocus-hooks.ps1 -HostKind {0} -Force)" -f $HostKind)
    exit 0
}

if ((Test-Path -LiteralPath $optOutMarker -PathType Leaf) -and -not $Force) {
    Write-Output ("[specrew-refocus] {0} hook deployment skipped: opt-out recorded (re-enable explicitly with -Force)" -f $HostKind)
    exit 0
}
if ($Force -and (Test-Path -LiteralPath $optOutMarker -PathType Leaf)) {
    Remove-Item -LiteralPath $optOutMarker -Force
}

# --- install: strip our old entries, append current ones -------------------------
Remove-SpecrewEntriesFromEventMap -EventMap $eventMap

$eventGroups = Get-HostEventGroups
foreach ($eventName in $eventGroups.Keys) {
    $group = $eventGroups[$eventName]
    $existing = $eventMap.PSObject.Properties[$eventName]
    if ($null -ne $existing -and $null -ne $existing.Value) {
        $existing.Value = @(@($existing.Value) + @($group))
    }
    else {
        $eventMap | Add-Member -NotePropertyName $eventName -NotePropertyValue @($group) -Force
    }
}

Save-Target -SettingsObject $settings
$boundEvents = ($eventGroups.Keys -join ' + ')
Write-Output ("[specrew-refocus] {0} hooks deployed to {1} ({2}; PreToolUse dormant)" -f $HostKind, $settingsPath, $boundEvents)
exit 0
