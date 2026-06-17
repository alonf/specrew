# Feature 171 T010+T014 (FR-013/FR-014): merge-aware refocus hook deployment,
# multi-host. Host-specific paths, config shapes, command modes, registrations,
# versions, ownership rules, and opt-out marker paths live in
# hosts/<kind>/host.psd1 under RefocusHookBindings.
#
# C6 invariants: add-if-absent; update ONLY entries recognized as Specrew's
# (dispatcher or launcher token inside the command); user entries preserved exactly;
# re-deploys byte-idempotent; recorded opt-out respected; PreToolUse remains dormant
# unless a host manifest explicitly registers it.
# Cwd-independence: the deployed dispatcher self-locates the project root from its
# own location ($PSScriptRoot), while launcher command modes use one per-machine
# launcher (~/.specrew/specrew-hook-launch.ps1) to resolve the live project before
# handing off to that project's dispatcher.
[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [string]$HostKind,
    [switch]$Remove,
    [switch]$Force,
    # Test seam: override the user-home root so suites never touch the real one.
    [string]$UserHomeOverride
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath $ProjectPath).Path
$userHome = if (-not [string]::IsNullOrWhiteSpace($UserHomeOverride)) { $UserHomeOverride } else { [Environment]::GetFolderPath('UserProfile') }

function Test-ManifestKey {
    param($Map, [string]$Key)
    if ($null -eq $Map) { return $false }
    if ($Map -is [System.Collections.IDictionary]) { return $Map.Contains($Key) }
    return $null -ne $Map.PSObject.Properties[$Key]
}

function Get-ManifestValue {
    param($Map, [string]$Key, $Default = $null)
    if (-not (Test-ManifestKey -Map $Map -Key $Key)) { return $Default }
    if ($Map -is [System.Collections.IDictionary]) { return $Map[$Key] }
    return $Map.PSObject.Properties[$Key].Value
}

function Find-HostManifestPath {
    param([string]$Kind)
    foreach ($start in @($PSScriptRoot, $projectRoot)) {
        $candidate = $start
        while (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $probe = Join-Path $candidate ("hosts/{0}/host.psd1" -f $Kind)
            if (Test-Path -LiteralPath $probe -PathType Leaf) { return $probe }
            $parent = Split-Path -Parent $candidate
            if ($parent -eq $candidate) { break }
            $candidate = $parent
        }
    }
    throw "Host manifest for '$Kind' was not found under hosts/<kind>/host.psd1."
}

function Get-DefaultHookHostKind {
    foreach ($start in @($PSScriptRoot, $projectRoot)) {
        $candidate = $start
        while (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $hostsRoot = Join-Path $candidate 'hosts'
            if (Test-Path -LiteralPath $hostsRoot -PathType Container) {
                $rows = New-Object System.Collections.Generic.List[object]
                foreach ($dir in @(Get-ChildItem -LiteralPath $hostsRoot -Directory -ErrorAction SilentlyContinue)) {
                    $manifestPath = Join-Path $dir.FullName 'host.psd1'
                    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { continue }
                    try {
                        $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
                        if ((Get-ManifestValue -Map $manifest -Key 'Status') -eq 'supported' -and (Test-ManifestKey -Map $manifest -Key 'RefocusHookBindings')) {
                            $priority = Get-ManifestValue -Map $manifest -Key 'MenuPriority' -Default 999
                            $rows.Add([pscustomobject]@{
                                    Kind     = [string](Get-ManifestValue -Map $manifest -Key 'Kind' -Default $dir.Name)
                                    Priority = [double]$priority
                                }) | Out-Null
                        }
                    }
                    catch { $null = $_ }
                }
                $first = @($rows.ToArray() | Sort-Object Priority, Kind | Select-Object -First 1)
                if ($first.Count -gt 0) { return [string]$first[0].Kind }
            }
            $parent = Split-Path -Parent $candidate
            if ($parent -eq $candidate) { break }
            $candidate = $parent
        }
    }
    throw "No supported hook-capable host manifest was found under hosts/<kind>/host.psd1."
}

function Resolve-HookSettingsPath {
    param([string]$SettingsFile)
    if ([string]::IsNullOrWhiteSpace($SettingsFile)) {
        throw "Host manifest for '$HostKind' is missing RefocusHookBindings.SettingsFile."
    }
    if ($SettingsFile.StartsWith('~/') -or $SettingsFile.StartsWith('~\')) {
        return (Join-Path $userHome $SettingsFile.Substring(2))
    }
    return (Join-Path $projectRoot $SettingsFile)
}

function Resolve-ProjectPathFromManifest {
    param([string]$RelativePath, [string]$FieldName)
    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        throw "Host manifest for '$HostKind' is missing RefocusHookBindings.$FieldName."
    }
    if ($RelativePath.StartsWith('~/') -or $RelativePath.StartsWith('~\')) {
        return (Join-Path $userHome $RelativePath.Substring(2))
    }
    return (Join-Path $projectRoot $RelativePath)
}

if ([string]::IsNullOrWhiteSpace($HostKind)) {
    $HostKind = Get-DefaultHookHostKind
}
if ($HostKind -notmatch '^[A-Za-z0-9_.-]+$') {
    throw "Invalid host kind '$HostKind'. Host kinds must be manifest folder names."
}
$hostManifestPath = Find-HostManifestPath -Kind $HostKind
$hostManifest = Import-PowerShellDataFile -LiteralPath $hostManifestPath
if (-not (Test-ManifestKey -Map $hostManifest -Key 'RefocusHookBindings') -or $null -eq (Get-ManifestValue -Map $hostManifest -Key 'RefocusHookBindings')) {
    throw "Host manifest '$hostManifestPath' is missing RefocusHookBindings."
}
$hookBindings = Get-ManifestValue -Map $hostManifest -Key 'RefocusHookBindings'
$dispatcherRelPath = [string](Get-ManifestValue -Map $hookBindings -Key 'DispatcherPath')
if ([string]::IsNullOrWhiteSpace($dispatcherRelPath)) {
    throw "Host manifest '$hostManifestPath' is missing RefocusHookBindings.DispatcherPath."
}
$hookConfigShape = [string](Get-ManifestValue -Map $hookBindings -Key 'ConfigShape' -Default 'event-map')
$hookCommandMode = [string](Get-ManifestValue -Map $hookBindings -Key 'CommandMode' -Default 'launcher-file')
$hookRegistrations = @(Get-ManifestValue -Map $hookBindings -Key 'Registrations')
if ($hookRegistrations.Count -eq 0) {
    throw "Host manifest '$hostManifestPath' is missing RefocusHookBindings.Registrations."
}
$settingsPath = Resolve-HookSettingsPath -SettingsFile ([string](Get-ManifestValue -Map $hookBindings -Key 'SettingsFile'))
$settingsVersion = Get-ManifestValue -Map $hookBindings -Key 'SettingsVersion'
$ownsSettingsFile = (Test-ManifestKey -Map $hookBindings -Key 'OwnsSettingsFile') -and [bool](Get-ManifestValue -Map $hookBindings -Key 'OwnsSettingsFile')
$migrateLegacyTopLevelEventMap = (Test-ManifestKey -Map $hookBindings -Key 'MigrateLegacyTopLevelEventMap') -and [bool](Get-ManifestValue -Map $hookBindings -Key 'MigrateLegacyTopLevelEventMap')
$definitionName = [string](Get-ManifestValue -Map $hookBindings -Key 'DefinitionName')
$definitionNameWhenOccupied = [string](Get-ManifestValue -Map $hookBindings -Key 'DefinitionNameWhenOccupied')
$launcherModulePath = $null
if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH) -and (Test-Path -LiteralPath $env:SPECREW_MODULE_PATH -PathType Container)) {
    $launcherModulePath = (Resolve-Path -LiteralPath $env:SPECREW_MODULE_PATH).Path
}
# The per-machine launcher used by launcher command modes. It lives outside any project
# because those configs may be shared across projects; it resolves whichever project the
# live session is in, then hands off to that project's deployed dispatcher.
$launcherPath = (Join-Path $userHome '.specrew/specrew-hook-launch.ps1') -replace '\\', '/'
$optOutMarker = Resolve-ProjectPathFromManifest -RelativePath ([string](Get-ManifestValue -Map $hookBindings -Key 'OptOutMarkerFile')) -FieldName 'OptOutMarkerFile'

function Get-SpecrewHookCommand {
    param([string]$EventName)
    # Command shape is host manifest data (`RefocusHookBindings.CommandMode`),
    # not host-name branching. The deployer only knows generic strategies.
    $modulePathArg = if (-not [string]::IsNullOrWhiteSpace($launcherModulePath)) {
        ' -ModulePath "' + ($launcherModulePath.Replace('"', '\"')) + '"'
    }
    else {
        ''
    }
    switch ($hookCommandMode) {
        'project-placeholder' {
            $placeholder = [string](Get-ManifestValue -Map $hookBindings -Key 'ProjectDirPlaceholder' -Default '')
            if ([string]::IsNullOrWhiteSpace($placeholder)) {
                throw "Host manifest '$hostManifestPath' uses CommandMode=project-placeholder but has no ProjectDirPlaceholder."
            }
            $target = $placeholder.TrimEnd('/', '\') + '/' + $dispatcherRelPath
            return ('pwsh -NoProfile -ExecutionPolicy Bypass -File "{0}" -Event {1} -HostKind {2}' -f $target, $EventName, $HostKind)
        }
        'launcher-file' {
            return ('pwsh -NoProfile -ExecutionPolicy Bypass -File "{0}" -Event {1} -HostKind {2}{3}' -f $launcherPath, $EventName, $HostKind, $modulePathArg)
        }
        'launcher-encoded' {
            $escapedLauncher = $launcherPath.Replace("'", "''")
            $escapedEvent = $EventName.Replace("'", "''")
            $modulePathEncodedArg = ''
            if (-not [string]::IsNullOrWhiteSpace($launcherModulePath)) {
                $modulePathEncodedArg = " -ModulePath '" + ($launcherModulePath.Replace("'", "''")) + "'"
            }
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(("& '{0}' -Event '{1}' -HostKind {2}{3}" -f $escapedLauncher, $escapedEvent, $HostKind, $modulePathEncodedArg)))
            return ('pwsh -NoProfile -ExecutionPolicy Bypass -EncodedCommand {0}' -f $encoded)
        }
        default {
            throw "Unsupported RefocusHookBindings.CommandMode '$hookCommandMode' in '$hostManifestPath'."
        }
    }
}

function Test-IsSpecrewCommandText {
    param([AllowNull()][string]$CommandText)
    # Ownership = the command names one of our two entry points: the dispatcher or the launcher. Matching both
    # lets a re-deploy recognize-and-replace legacy dispatcher entries and current launcher entries.
    if ([string]::IsNullOrWhiteSpace($CommandText)) { return $false }
    if ($CommandText.Contains('specrew-hook-dispatcher.ps1') -or $CommandText.Contains('specrew-hook-launch.ps1')) {
        return $true
    }
    $match = [regex]::Match($CommandText, '(?i)(?:^|\s)-EncodedCommand\s+([A-Za-z0-9+/=]+)')
    if ($match.Success) {
        try {
            $decoded = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($match.Groups[1].Value))
            return $decoded.Contains('specrew-hook-dispatcher.ps1') -or $decoded.Contains('specrew-hook-launch.ps1')
        }
        catch { return $false }
    }
    return $false
}

function Get-HookLauncherProjectRootEnvVars {
    $vars = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    foreach ($start in @($PSScriptRoot, $projectRoot)) {
        $candidate = $start
        while (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $hostsRoot = Join-Path $candidate 'hosts'
            if (Test-Path -LiteralPath $hostsRoot -PathType Container) {
                foreach ($dir in @(Get-ChildItem -LiteralPath $hostsRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
                    $manifestPath = Join-Path $dir.FullName 'host.psd1'
                    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { continue }
                    try {
                        $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
                        if (-not (Test-ManifestKey -Map $manifest -Key 'RefocusHookBindings')) { continue }
                        $bindings = Get-ManifestValue -Map $manifest -Key 'RefocusHookBindings'
                        foreach ($envVar in @(Get-ManifestValue -Map $bindings -Key 'ProjectRootEnvironmentVariables')) {
                            $name = [string]$envVar
                            if ([string]::IsNullOrWhiteSpace($name) -or $seen.ContainsKey($name)) { continue }
                            $seen[$name] = $true
                            $vars.Add($name) | Out-Null
                        }
                    }
                    catch { $null = $_ }
                }
                return $vars.ToArray()
            }
            $parent = Split-Path -Parent $candidate
            if ($parent -eq $candidate) { break }
            $candidate = $parent
        }
    }
    return $vars.ToArray()
}

function ConvertTo-PowerShellStringArrayLiteral {
    param([string[]]$Values)
    $items = @($Values | ForEach-Object { "'" + ([string]$_).Replace("'", "''") + "'" })
    if ($items.Count -eq 0) { return '@()' }
    return ('@({0})' -f ($items -join ', '))
}

function Install-HookLauncher {
    # Generate the per-machine launcher (~/.specrew/specrew-hook-launch.ps1) used by launcher command modes.
    # Idempotent: same bytes every deploy. The launcher is intentionally
    # SELF-CONTAINED — it runs BEFORE any project is known, so it cannot dot-source project files; it does only
    # the minimal bootstrap resolution needed to FIND the deployed dispatcher, then hands off (the dispatcher
    # re-resolves the project from its own $PSScriptRoot). A single-quoted here-string keeps the launcher's own
    # $env:/$raw/${...} literal — it is NOT expanded at deploy time. The launcher path is the only deploy-time
    # value, and it is baked into the command string (Get-SpecrewHookCommand), not into the launcher body.
    $projectRootEnvVarLiteral = ConvertTo-PowerShellStringArrayLiteral -Values @(Get-HookLauncherProjectRootEnvVars)
    $launcherBody = @'
# Specrew user-level hook launcher — GENERATED per-machine by deploy-refocus-hooks.ps1 (do NOT edit by hand).
# Some host configs are shared across projects, so their command string cannot name a per-project dispatcher path.
# This launcher resolves
# WHICH project the live session belongs to, then hands off to that project's DEPLOYED dispatcher. It holds only
# the minimal bootstrap resolution needed to FIND the dispatcher file; the dispatcher itself re-resolves the
# project root from its own location. ALWAYS exits 0 (fail-open) — a launcher failure may never block a session.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Event,
    [string]$HostKind = 'unknown',
    [string]$ModulePath,
    [int]$ProviderTimeoutSeconds = 20
)
# KILL SWITCH FIRST — before any logic that could itself fail (FR-008 doctrine).
if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_REFOCUS_DISABLE)) { exit 0 }
$ErrorActionPreference = 'Stop'

# Dev-tree dogfood path: when specrew init/update ran from an imported development tree, bake that module
# root into the launcher command so host-spawned hook children do not fall through to stale installed modules.
if (-not [string]::IsNullOrWhiteSpace($ModulePath) -and (Test-Path -LiteralPath $ModulePath -PathType Container)) {
    $env:SPECREW_MODULE_PATH = $ModulePath
}

# The dispatcher's project-relative subpath — the SENTINEL we look for when walking up a candidate root. We key
# on the dispatcher FILE (not a .specrew dir) so a stray ~/.specrew up the cwd tree never mis-resolves a project
# (this launcher itself lives under ~/.specrew).
$dispatcherSub = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
$projectRootEnvVars = __SPECREW_PROJECT_ROOT_ENV_VARS__

function Find-DispatcherUpTree {
    param([string]$Start, [string]$Sub)
    $candidate = $Start
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        $probe = Join-Path $candidate $Sub
        if (Test-Path -LiteralPath $probe -PathType Leaf) { return $probe }
        $parent = Split-Path -Parent $candidate
        if ($parent -eq $candidate) { break }
        $candidate = $parent
    }
    return $null
}

# Read the host event JSON from stdin ONCE — but ONLY when stdin is actually redirected. A bare ReadToEnd() on a
# NON-redirected stdin BLOCKS until EOF, and a hanging hook blocks the session (the exact fail-open violation we
# must avoid; a try/catch does NOT rescue a blocking read). Mirrors the dispatcher's own guard.
$raw = ''
if ([Console]::IsInputRedirected) {
    try { $raw = [Console]::In.ReadToEnd() } catch { $raw = '' }
}
$payloadCwd = $null
$payloadRoots = @()
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    try {
        $obj = $raw | ConvertFrom-Json
        if ($obj.PSObject.Properties['cwd']) { $payloadCwd = [string]$obj.cwd }
        if ($obj.PSObject.Properties['workspace_roots'] -and $null -ne $obj.workspace_roots) {
            $payloadRoots = @($obj.workspace_roots | ForEach-Object { [string]$_ })
        }
        if ($obj.PSObject.Properties['workspacePaths'] -and $null -ne $obj.workspacePaths) {
            $payloadRoots = @($payloadRoots + @($obj.workspacePaths | ForEach-Object { [string]$_ }))
        }
    } catch { $null = $_ }   # malformed payload -> fall through to env/cwd resolution
}

# Candidate project roots, in priority order: known host project-root env vars, then the payload
# cwd/workspace_roots/workspacePaths, then the live cwd. For each, walk up looking for the dispatcher subpath.
$candidates = New-Object System.Collections.Generic.List[string]
foreach ($variableName in $projectRootEnvVars) {
    try { $c = [Environment]::GetEnvironmentVariable($variableName) } catch { $c = $null }
    if (-not [string]::IsNullOrWhiteSpace($c)) { $candidates.Add($c) }
}
if (-not [string]::IsNullOrWhiteSpace($payloadCwd)) { $candidates.Add($payloadCwd) }
foreach ($r in $payloadRoots) { if (-not [string]::IsNullOrWhiteSpace($r)) { $candidates.Add($r) } }
try { $candidates.Add((Get-Location).Path) } catch { $null = $_ }

$dispatcher = $null
foreach ($start in $candidates) {
    $found = Find-DispatcherUpTree -Start $start -Sub $dispatcherSub
    if (-not [string]::IsNullOrWhiteSpace($found)) { $dispatcher = $found; break }
}
if ([string]::IsNullOrWhiteSpace($dispatcher)) { exit 0 }   # no project resolvable from any signal -> fire nothing (fail-open)

# Hand off to the project's deployed dispatcher. Pass the captured payload via -EventJson so the dispatcher does
# not try to re-read the now-consumed stdin (only when non-empty). The dispatcher's stdout (injection output)
# flows through this process to the host. Always exit 0.
$dispatchArgs = @{ Event = $Event; HostKind = $HostKind; ProviderTimeoutSeconds = $ProviderTimeoutSeconds }
if (-not [string]::IsNullOrWhiteSpace($raw)) { $dispatchArgs['EventJson'] = $raw }
try { & $dispatcher @dispatchArgs }
catch { [Console]::Error.WriteLine("[specrew-refocus] WARN LAUNCH_FAILED $($_.Exception.Message)") }
exit 0
'@
    $launcherBody = $launcherBody.Replace('__SPECREW_PROJECT_ROOT_ENV_VARS__', $projectRootEnvVarLiteral)
    New-Item -ItemType Directory -Path (Split-Path -Parent $launcherPath) -Force | Out-Null
    [System.IO.File]::WriteAllText($launcherPath, $launcherBody, [System.Text.UTF8Encoding]::new($false))
}

function Test-IsSpecrewGroup {
    # A group is Specrew's when EVERY command inside it is ours. Group shapes vary:
    # Supported shapes include { matcher?, hooks: [ { type, command } ] }, { command },
    # and { type, bash, powershell }.
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
    # Mixed hooks-array groups keep their user hooks; user groups untouched.
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

function Get-HookCommandTexts {
    param($Node)
    $commands = New-Object System.Collections.Generic.List[string]
    if ($null -eq $Node) { return $commands.ToArray() }

    foreach ($item in @($Node)) {
        if ($null -eq $item -or $item -is [string]) { continue }
        foreach ($commandField in @('command', 'bash', 'powershell')) {
            $prop = $item.PSObject.Properties[$commandField]
            if ($prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
                $commands.Add([string]$prop.Value) | Out-Null
            }
        }
        $hooks = $item.PSObject.Properties['hooks']
        if ($hooks -and $null -ne $hooks.Value) {
            foreach ($nested in @(Get-HookCommandTexts -Node $hooks.Value)) {
                $commands.Add($nested) | Out-Null
            }
        }
    }
    return $commands.ToArray()
}

function Get-NamedHookDefinitionCommands {
    param($Definition)
    $commands = New-Object System.Collections.Generic.List[string]
    if ($null -eq $Definition) { return $commands.ToArray() }
    foreach ($prop in @($Definition.PSObject.Properties)) {
        foreach ($command in @(Get-HookCommandTexts -Node $prop.Value)) {
            $commands.Add($command) | Out-Null
        }
    }
    return $commands.ToArray()
}

function Test-IsSpecrewNamedHookDefinition {
    param($Definition)
    $commands = @(Get-NamedHookDefinitionCommands -Definition $Definition)
    if ($commands.Count -eq 0) { return $false }
    return @($commands | Where-Object { -not (Test-IsSpecrewCommandText -CommandText $_) }).Count -eq 0
}

function Remove-SpecrewNamedHookDefinitions {
    param($SettingsObject)
    if ($null -eq $SettingsObject) { return }
    foreach ($prop in @($SettingsObject.PSObject.Properties)) {
        if ($prop.Value -is [System.Array]) { continue }
        if (Test-IsSpecrewNamedHookDefinition -Definition $prop.Value) {
            $SettingsObject.PSObject.Properties.Remove($prop.Name) | Out-Null
        }
    }
}

function Get-SpecrewNamedHookName {
    param($SettingsObject)
    if ([string]::IsNullOrWhiteSpace($definitionName)) {
        throw "Host manifest '$hostManifestPath' uses ConfigShape=named-definition but has no DefinitionName."
    }
    if ($SettingsObject.PSObject.Properties[$definitionName] -and -not [string]::IsNullOrWhiteSpace($definitionNameWhenOccupied)) {
        return $definitionNameWhenOccupied
    }
    return $definitionName
}

function Get-HostEventGroups {
    # The per-host registrations are manifest data; the deployer only knows generic handler shapes.
    $result = [ordered]@{}
    foreach ($registration in $hookRegistrations) {
        $eventName = [string](Get-ManifestValue -Map $registration -Key 'Event')
        if ([string]::IsNullOrWhiteSpace($eventName)) {
            throw "Host manifest '$hostManifestPath' contains a RefocusHookBindings.Registrations row without Event."
        }
        $dispatcherEvent = [string](Get-ManifestValue -Map $registration -Key 'DispatcherEvent' -Default $eventName)
        $handlerShape = [string](Get-ManifestValue -Map $registration -Key 'HandlerShape' -Default 'hooks-array')
        $commandType = [string](Get-ManifestValue -Map $registration -Key 'Type' -Default 'command')
        $command = Get-SpecrewHookCommand -EventName $dispatcherEvent

        switch ($handlerShape) {
            'hooks-array' {
                $hook = [ordered]@{ type = $commandType; command = $command }
                if (Test-ManifestKey -Map $registration -Key 'Timeout') { $hook['timeout'] = Get-ManifestValue -Map $registration -Key 'Timeout' }
                $group = [ordered]@{ hooks = @([pscustomobject]$hook) }
                if (Test-ManifestKey -Map $registration -Key 'Matcher') { $group['matcher'] = Get-ManifestValue -Map $registration -Key 'Matcher' }
                $result[$eventName] = [pscustomobject]$group
            }
            'command-entry' {
                $entry = [ordered]@{ command = $command }
                if (Test-ManifestKey -Map $registration -Key 'Timeout') { $entry['timeout'] = Get-ManifestValue -Map $registration -Key 'Timeout' }
                $result[$eventName] = [pscustomobject]$entry
            }
            'dual-shell-entry' {
                $entry = [ordered]@{ type = $commandType; bash = $command; powershell = $command }
                if (Test-ManifestKey -Map $registration -Key 'TimeoutSec') { $entry['timeoutSec'] = Get-ManifestValue -Map $registration -Key 'TimeoutSec' }
                if (Test-ManifestKey -Map $registration -Key 'Timeout') { $entry['timeout'] = Get-ManifestValue -Map $registration -Key 'Timeout' }
                $result[$eventName] = [pscustomobject]$entry
            }
            'direct-command' {
                $entry = [ordered]@{ type = $commandType; command = $command }
                if (Test-ManifestKey -Map $registration -Key 'Timeout') { $entry['timeout'] = Get-ManifestValue -Map $registration -Key 'Timeout' }
                $result[$eventName] = [pscustomobject]$entry
            }
            default {
                throw "Unsupported RefocusHookBindings.Registrations.HandlerShape '$handlerShape' in '$hostManifestPath'."
            }
        }
    }
    return $result
}

function Save-Target {
    param($SettingsObject)
    if ($null -ne $settingsVersion -and -not $SettingsObject.PSObject.Properties['version']) {
        $SettingsObject | Add-Member -NotePropertyName 'version' -NotePropertyValue $settingsVersion -Force
    }
    $json = $SettingsObject | ConvertTo-Json -Depth 16
    New-Item -ItemType Directory -Path (Split-Path -Parent $settingsPath) -Force | Out-Null
    [System.IO.File]::WriteAllText($settingsPath, $json, [System.Text.UTF8Encoding]::new($false))
}

# --- load (or initialize) the target file --------------------------------------
$settings = $null
if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
    try { $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { throw "config file unreadable at $settingsPath — refusing to modify a file I cannot parse (user content safety): $($_.Exception.Message)" }
}
if ($null -eq $settings) { $settings = [pscustomobject]@{} }

if ($hookConfigShape -eq 'named-definition') {
    if ($Remove) {
        Remove-SpecrewNamedHookDefinitions -SettingsObject $settings
        Save-Target -SettingsObject $settings
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

    if ($hookCommandMode -in @('launcher-file', 'launcher-encoded')) { Install-HookLauncher }
    Remove-SpecrewNamedHookDefinitions -SettingsObject $settings
    $hookName = Get-SpecrewNamedHookName -SettingsObject $settings
    $eventGroups = Get-HostEventGroups
    $hookDefinition = [pscustomobject]@{ enabled = $true }
    foreach ($eventName in $eventGroups.Keys) {
        $hookDefinition | Add-Member -NotePropertyName $eventName -NotePropertyValue @($eventGroups[$eventName]) -Force
    }
    $settings | Add-Member -NotePropertyName $hookName -NotePropertyValue $hookDefinition -Force
    Save-Target -SettingsObject $settings
    $boundEvents = ($eventGroups.Keys -join ' + ')
    Write-Output ("[specrew-refocus] {0} hooks deployed to {1} ({2}; PreToolUse dormant)" -f $HostKind, $settingsPath, $boundEvents)
    exit 0
}

if ($hookConfigShape -ne 'event-map') {
    throw "Unsupported RefocusHookBindings.ConfigShape '$hookConfigShape' in '$hostManifestPath'."
}

# Locate the event map for event-map configs. Some hosts previously wrote top-level event keys
# (no `hooks` wrapper); manifests opt into a one-time migration that strips only Specrew entries
# before switching to the wrapped map, so no orphaned duplicate hooks remain.
if ($migrateLegacyTopLevelEventMap -and -not ($settings.PSObject.Properties['hooks'] -and $null -ne $settings.hooks -and -not ($settings.hooks -is [System.Array]))) {
    Remove-SpecrewEntriesFromEventMap -EventMap $settings
}
if (-not $settings.PSObject.Properties['hooks'] -or $null -eq $settings.hooks -or ($settings.hooks -is [System.Array])) {
    # Defensiveness: a stale `hooks` written as a JSON ARRAY by a corrupted prior deploy is NOT a valid
    # event map. The old code passed it straight into Remove-SpecrewEntriesFromEventMap, which iterated the
    # array's intrinsic members and crashed setting the read-only `Length` ("Length is a ReadOnly property"),
    # aborting the deploy and leaving the target hook file unparseable ("invalid type: map, expected
    # a sequence"). Drop the malformed `hooks` and reset it to a clean map so the deploy self-heals.
    if ($settings.PSObject.Properties['hooks']) { $settings.PSObject.Properties.Remove('hooks') | Out-Null }
    $settings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([pscustomobject]@{}) -Force
}
$eventMap = $settings.hooks

if ($Remove) {
    if ($ownsSettingsFile) {
        # Some hook-dir models give Specrew a wholly owned file.
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
# Launcher command modes point at a per-machine launcher, so it must exist before their hooks fire.
if ($hookCommandMode -in @('launcher-file', 'launcher-encoded')) { Install-HookLauncher }

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
