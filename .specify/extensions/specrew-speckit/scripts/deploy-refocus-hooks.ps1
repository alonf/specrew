# Feature 171 T010 (FR-014): merge-aware refocus hook deployment.
# Writes the SpecrewHookDispatcher registration into the PER-USER project-local
# settings file (.claude/settings.local.json for the claude host) — never the
# shared settings.json, so a cloned repo can never import auto-executing hooks.
#
# C6 invariants:
#   - add-if-absent; update ONLY entries recognized as Specrew's (identified by
#     the dispatcher path inside the hook command)
#   - user-authored entries are preserved exactly (semantic JSON identity); a
#     re-deploy over an unchanged file is byte-idempotent
#   - opt-out is RECORDED (marker file) and respected by subsequent installs;
#     `specrew update` never silently flips a human disable decision
#   - PreToolUse is NEVER registered while the gate seat is dormant (F-165)
#
# Canonical binding declaration: hosts/claude/host.psd1 :: RefocusHookBindings.
[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [ValidateSet('claude')][string]$HostKind = 'claude',
    [switch]$Remove,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath $ProjectPath).Path
$dispatcherRelPath = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
$settingsPath = Join-Path $projectRoot '.claude/settings.local.json'
$optOutMarker = Join-Path $projectRoot '.specrew/runtime/refocus-hooks-optout'

function Get-SpecrewHookCommand {
    param([string]$EventName)
    # Project-relative dispatcher path: hooks run with the project as CWD.
    return ('pwsh -NoProfile -ExecutionPolicy Bypass -File "{0}" -Event {1}' -f $dispatcherRelPath, $EventName)
}

function Test-IsSpecrewHook {
    param($HookEntry)
    return ($HookEntry.PSObject.Properties['command'] -and ([string]$HookEntry.command).Contains('specrew-hook-dispatcher.ps1'))
}

function Remove-SpecrewEntries {
    # Strips Specrew's hooks from every event group; user hooks survive exactly.
    # Mixed groups (user + specrew hooks in one matcher group) keep their user hooks.
    param($Settings)
    if (-not $Settings.PSObject.Properties['hooks'] -or $null -eq $Settings.hooks) { return $Settings }
    foreach ($eventProp in @($Settings.hooks.PSObject.Properties)) {
        $kept = New-Object System.Collections.Generic.List[object]
        foreach ($group in @($eventProp.Value)) {
            if (-not $group.PSObject.Properties['hooks']) { $kept.Add($group) | Out-Null; continue }
            $userHooks = @(@($group.hooks) | Where-Object { -not (Test-IsSpecrewHook -HookEntry $_) })
            if ($userHooks.Count -eq @($group.hooks).Count) {
                $kept.Add($group) | Out-Null          # purely user group: untouched
            }
            elseif ($userHooks.Count -gt 0) {
                $group.PSObject.Properties['hooks'].Value = $userHooks   # mixed group: drop only ours
                $kept.Add($group) | Out-Null
            }
            # else: purely Specrew group -> dropped
        }
        # Property-info setter: the dynamic `$obj.($name) = ...` member assignment
        # trips the PS binder ("Argument types do not match") on deserialized JSON.
        if ($kept.Count -gt 0) { $eventProp.Value = $kept.ToArray() }
        else { $Settings.hooks.PSObject.Properties.Remove($eventProp.Name) }
    }
    return $Settings
}

# --- load (or initialize) the settings file -----------------------------------
$settings = $null
if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
    try { $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { throw "settings file unreadable at $settingsPath — refusing to modify a file I cannot parse (user content safety): $($_.Exception.Message)" }
}
if ($null -eq $settings) { $settings = [pscustomobject]@{} }

if ($Remove) {
    $settings = Remove-SpecrewEntries -Settings $settings
    $json = $settings | ConvertTo-Json -Depth 16
    New-Item -ItemType Directory -Path (Split-Path -Parent $settingsPath) -Force | Out-Null
    [System.IO.File]::WriteAllText($settingsPath, $json, [System.Text.UTF8Encoding]::new($false))
    # Record the opt-out: subsequent plain installs respect it (no silent re-enable).
    New-Item -ItemType Directory -Path (Split-Path -Parent $optOutMarker) -Force | Out-Null
    [System.IO.File]::WriteAllText($optOutMarker, ("opted out {0}`n" -f (Get-Date).ToUniversalTime().ToString('o')), [System.Text.UTF8Encoding]::new($false))
    Write-Output '[specrew-refocus] hooks removed; opt-out recorded (re-enable: deploy-refocus-hooks.ps1 -Force)'
    exit 0
}

if ((Test-Path -LiteralPath $optOutMarker -PathType Leaf) -and -not $Force) {
    Write-Output '[specrew-refocus] hook deployment skipped: opt-out recorded (re-enable explicitly with -Force)'
    exit 0
}
if ($Force -and (Test-Path -LiteralPath $optOutMarker -PathType Leaf)) {
    Remove-Item -LiteralPath $optOutMarker -Force
}

# --- install: strip our old entries, append current ones -----------------------
$settings = Remove-SpecrewEntries -Settings $settings
if (-not $settings.PSObject.Properties['hooks'] -or $null -eq $settings.hooks) {
    $settings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([pscustomobject]@{}) -Force
}

# TG-004 option (a), approved at iteration-001 review-signoff: PostToolUse is NOT
# registered (measured ~920ms/call vs the 150ms bar; pwsh spawn structural).
# Channel-1 wrapper emission delivers B3 mechanically on every host; iteration 002
# re-evaluates (UserPromptSubmit + engine inlining).
# SessionStart: all sources (startup|resume|clear|compact) — the dispatcher routes.
$sessionStartGroup = [pscustomobject]@{
    hooks = @([pscustomobject]@{ type = 'command'; command = (Get-SpecrewHookCommand -EventName 'SessionStart') })
}

$eventGroups = [ordered]@{ SessionStart = $sessionStartGroup }
foreach ($eventName in $eventGroups.Keys) {
    $group = $eventGroups[$eventName]
    $existing = $settings.hooks.PSObject.Properties[$eventName]
    if ($null -ne $existing -and $null -ne $existing.Value) {
        $existing.Value = @(@($existing.Value) + @($group))
    }
    else {
        $settings.hooks | Add-Member -NotePropertyName $eventName -NotePropertyValue @($group) -Force
    }
}

$json = $settings | ConvertTo-Json -Depth 16
New-Item -ItemType Directory -Path (Split-Path -Parent $settingsPath) -Force | Out-Null
[System.IO.File]::WriteAllText($settingsPath, $json, [System.Text.UTF8Encoding]::new($false))
Write-Output ('[specrew-refocus] hooks deployed to {0} (SessionStart only per TG-004 option (a); PostToolUse unregistered - channel 1 carries B3; PreToolUse dormant)' -f $settingsPath)
exit 0
