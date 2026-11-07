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
    [string]$UserHomeOverride,
    # Feature 203 (review round 3, finding 1): print this host's runtime binding and change nothing. The live-engine
    # pin script runs the PIN's deployer with it, so the binding the pinned hooks use comes from the reviewed commit.
    [switch]$EmitBindingOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath $ProjectPath).Path
# SPECREW_USER_HOME_OVERRIDE is the same seam for callers that cannot pass the parameter, such as specrew init run
# by a test (T002 round 5, finding 4): GetFolderPath ignores USERPROFILE, so without it a test's init writes the real
# home's hooks. Unset in normal use.
$userHome = if (-not [string]::IsNullOrWhiteSpace($UserHomeOverride)) { $UserHomeOverride }
elseif (-not [string]::IsNullOrWhiteSpace($env:SPECREW_USER_HOME_OVERRIDE)) { $env:SPECREW_USER_HOME_OVERRIDE }
else { [Environment]::GetFolderPath('UserProfile') }

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

function Get-ManifestKeys {
    param($Map)
    if ($null -eq $Map) { return @() }
    if ($Map -is [System.Collections.IDictionary]) { return @($Map.Keys) }
    return @($Map.PSObject.Properties | ForEach-Object { $_.Name })
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

function ConvertTo-StablePayloadSignature {
    # Feature 202 iteration 002, T016: a host's PayloadSignature as sorted, string-only data. An event's rule may list
    # alternatives (B4F-144); one alternative stays a single rule, so a binding without alternatives encodes as before.
    param($Signature)
    if ($null -eq $Signature) { return $null }
    $stable = [ordered]@{}
    foreach ($eventKey in @(Get-ManifestKeys -Map $Signature | Sort-Object)) {
        $alternatives = @(foreach ($rule in @(Get-ManifestValue -Map $Signature -Key ([string]$eventKey))) {
                if ($null -eq $rule) { continue }
                [ordered]@{
                    AllOf  = @(@(Get-ManifestValue -Map $rule -Key 'AllOf' -Default @()) | ForEach-Object { [string]$_ } | Sort-Object)
                    NoneOf = @(@(Get-ManifestValue -Map $rule -Key 'NoneOf' -Default @()) | ForEach-Object { [string]$_ } | Sort-Object)
                }
            })
        if ($alternatives.Count -eq 1) { $stable[[string]$eventKey] = $alternatives[0] }
        elseif ($alternatives.Count -gt 1) { $stable[[string]$eventKey] = $alternatives }
    }
    if ($stable.Count -eq 0) { return $null }
    return $stable
}

function Get-ForeignPayloadSignatures {
    # Every other host manifest beside this one that declares a PayloadSignature, keyed by host kind.
    $result = [ordered]@{}
    $hostsRoot = Split-Path -Parent (Split-Path -Parent $hostManifestPath)
    foreach ($dir in @(Get-ChildItem -LiteralPath $hostsRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
        if ($dir.Name -ceq $HostKind) { continue }
        $manifestFile = Join-Path $dir.FullName 'host.psd1'
        if (-not (Test-Path -LiteralPath $manifestFile -PathType Leaf)) { continue }
        try {
            $other = Import-PowerShellDataFile -LiteralPath $manifestFile
            $otherBindings = Get-ManifestValue -Map $other -Key 'RefocusHookBindings' -Default $null
            if ($null -eq $otherBindings) { continue }
            $otherRuntime = Get-ManifestValue -Map $otherBindings -Key 'DispatcherRuntime' -Default $null
            if ($null -eq $otherRuntime) { continue }
            $sig = ConvertTo-StablePayloadSignature -Signature (Get-ManifestValue -Map $otherRuntime -Key 'PayloadSignature' -Default $null)
            if ($null -ne $sig) { $result[$dir.Name] = $sig }
        }
        catch { continue }
    }
    return $result
}

function Get-HostRuntimeBindingEncoded {
    param($Bindings)
    if (-not (Test-ManifestKey -Map $Bindings -Key 'DispatcherRuntime')) { return $null }
    $runtime = Get-ManifestValue -Map $Bindings -Key 'DispatcherRuntime'
    if ($null -eq $runtime) { return $null }
    $triggerMap = [ordered]@{}
    $rawTriggerMap = Get-ManifestValue -Map $runtime -Key 'RefocusTriggerByEvent' -Default @{}
    foreach ($key in @(Get-ManifestKeys -Map $rawTriggerMap | Sort-Object)) {
        $triggerMap[[string]$key] = [string](Get-ManifestValue -Map $rawTriggerMap -Key ([string]$key))
    }
    $stableRuntime = [ordered]@{
        BootstrapDeliveryEvents = @(Get-ManifestValue -Map $runtime -Key 'BootstrapDeliveryEvents' -Default @())
        B3DeliveryEvents        = @(Get-ManifestValue -Map $runtime -Key 'B3DeliveryEvents' -Default @())
        RefocusTriggerByEvent   = $triggerMap
        SuppressedRefocusEvents = @(Get-ManifestValue -Map $runtime -Key 'SuppressedRefocusEvents' -Default @())
        OutputShape             = [string](Get-ManifestValue -Map $runtime -Key 'OutputShape' -Default 'plain-or-hookSpecificOutput')
        DecisionOnlyEvents      = @(Get-ManifestValue -Map $runtime -Key 'DecisionOnlyEvents' -Default @())
        BootstrapDeliveryMode   = [string](Get-ManifestValue -Map $runtime -Key 'BootstrapDeliveryMode' -Default 'inline')
        # FR-004 (185): the deployed hook bakes this binding and the dispatcher decodes it BEFORE the manifest
        # fallback - so StopBlockShape MUST be encoded here, or every deployed project resolves it to 'none' and
        # the entire stop-block delivery is inert in the field while the manifest-path tests stay green (145 F1/TI-1).
        StopBlockShape          = [string](Get-ManifestValue -Map $runtime -Key 'StopBlockShape' -Default 'none')
    }
    # Feature 202 T002 (DA-1, option B): the host's declared input contract rides the baked binding too, for the
    # same reason as StopBlockShape - the dispatcher decodes the baked binding first, so a contract left out here
    # would never reach a deployed project. Keys are emitted sorted so a re-deploy stays byte-idempotent.
    if (Test-ManifestKey -Map $runtime -Key 'InputFieldMap') {
        $rawFieldMap = Get-ManifestValue -Map $runtime -Key 'InputFieldMap'
        $fieldMap = [ordered]@{}
        foreach ($key in @(Get-ManifestKeys -Map $rawFieldMap | Sort-Object)) {
            $fieldMap[[string]$key] = @(@(Get-ManifestValue -Map $rawFieldMap -Key ([string]$key)) | ForEach-Object { [string]$_ })
        }
        $stableRuntime['InputFieldMap'] = $fieldMap
    }
    # Feature 203 T003 (FR-016, DA-2): a host with no message id declares how its stand-in identity is built.
    if (Test-ManifestKey -Map $runtime -Key 'MessageIdentity') {
        $rawIdentity = Get-ManifestValue -Map $runtime -Key 'MessageIdentity'
        $stableRuntime['MessageIdentity'] = [ordered]@{
            From = @(@(Get-ManifestValue -Map $rawIdentity -Key 'From' -Default @()) | ForEach-Object { [string]$_ })
            Kind = [string](Get-ManifestValue -Map $rawIdentity -Key 'Kind' -Default '')
        }
    }
    if (Test-ManifestKey -Map $runtime -Key 'OriginRules') {
        $rules = foreach ($rule in @(Get-ManifestValue -Map $runtime -Key 'OriginRules')) {
            $stableRule = [ordered]@{}
            foreach ($key in @(Get-ManifestKeys -Map $rule | Sort-Object)) {
                # A payload-field rule names a list of fields (T028); every other rule value is one string.
                $value = Get-ManifestValue -Map $rule -Key ([string]$key)
                $stableRule[[string]$key] = if ($value -is [System.Collections.IList]) { @($value | ForEach-Object { [string]$_ }) } else { [string]$value }
            }
            $stableRule
        }
        $stableRuntime['OriginRules'] = @($rules)
    }
    if (Test-ManifestKey -Map $runtime -Key 'InputTransform') {
        $stableRuntime['InputTransform'] = [string](Get-ManifestValue -Map $runtime -Key 'InputTransform')
    }
    # Feature 202 iteration 002, T016 (FR-028, DA-1): this host's payload signature, and every OTHER host's, ride the
    # baked binding. A host can read another host's hook settings (Copilot runs Claude's), so the hook has to be able
    # to recognise a payload that positively belongs to another host - and only then stand down. Sorted, so a
    # re-deploy stays byte-idempotent.
    $ownSignature = ConvertTo-StablePayloadSignature -Signature (Get-ManifestValue -Map $runtime -Key 'PayloadSignature' -Default $null)
    if ($null -ne $ownSignature) { $stableRuntime['PayloadSignature'] = $ownSignature }
    $foreign = Get-ForeignPayloadSignatures
    if ($foreign.Count -gt 0) { $stableRuntime['ForeignPayloadSignatures'] = $foreign }
    $json = $stableRuntime | ConvertTo-Json -Depth 8 -Compress
    return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
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
if ($EmitBindingOnly) {
    Write-Output (Get-HostRuntimeBindingEncoded -Bindings $hookBindings)
    exit 0
}
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
$hostRuntimeBinding = Get-HostRuntimeBindingEncoded -Bindings $hookBindings
$launcherModulePath = $null
if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH) -and (Test-Path -LiteralPath $env:SPECREW_MODULE_PATH -PathType Container)) {
    $launcherModulePath = (Resolve-Path -LiteralPath $env:SPECREW_MODULE_PATH).Path
}
# The per-machine launcher used by launcher command modes. It lives outside any project
# because those configs may be shared across projects; it resolves whichever project the
# live session is in, then hands off to that project's deployed dispatcher.
# Per-machine launchers and baked bindings live in one content-addressed store, each file named by the id of its
# content and written once (Feature 203 T002, review rounds 4 and 5): a command names the exact launcher and binding
# it needs, so a deploy from another project or another engine adds files instead of changing the ones it uses.
$hookStoreRoot = Join-Path $userHome '.specrew/hooks'
$script:launcherPath = $null
$script:launcherBodyCache = $null
$optOutMarker = Resolve-ProjectPathFromManifest -RelativePath ([string](Get-ManifestValue -Map $hookBindings -Key 'OptOutMarkerFile')) -FieldName 'OptOutMarkerFile'
# The generated launcher of a guarded-project-encoded host sits beside its project settings file; the command names
# it relative to the host's project root.
$settingsDirRel = (Split-Path -Parent ([string](Get-ManifestValue -Map $hookBindings -Key 'SettingsFile'))) -replace '\\', '/'
$projectLauncherRelPath = if ([string]::IsNullOrWhiteSpace($settingsDirRel)) { 'specrew-hook-launch.ps1' } else { $settingsDirRel.TrimEnd('/') + '/specrew-hook-launch.ps1' }
$projectLauncherPath = Join-Path (Split-Path -Parent $settingsPath) 'specrew-hook-launch.ps1'

function Get-LiveEnginePinLauncherText {
    # Feature 203 T002 (DA-8): the launcher half of the live-engine pin, shared by the per-machine launcher and the
    # generated project launcher. It reads $projectRoot and $dispatcher and leaves $pinArgs for the dispatcher call. With no pin
    # record it changes nothing. With one, $dispatcher becomes the pin's copy and $pinArgs carries the project root,
    # so the pinned dispatcher never walks up from the pin (which has its own .specrew). The pin is checked here,
    # before any of its code runs (a dispatcher checking its own pin would be unreviewed code deciding whether it may
    # run): its HEAD, read from its git files without starting git, must be the recorded commit. A record whose pin
    # cannot be found or is not at that commit refuses in plain words; nothing falls back to this project's copy.
    #
    # Feature 203 T006 (DRIFT-018): each refusal is written as plain text and exits 1. A throw reached the host in pwsh's
    # error view: a source excerpt, the message wrapped behind a '|' gutter, ANSI color codes, or CLIXML.
    #
    # The host binding comes from the pin too (review round 3, finding 1): it holds the rules for what counts as a typed
    # approval, so the one baked into this launcher by whatever deploy ran last does not apply. The pin script writes
    # the pin's bindings stamped with its commit; a stamp that is not the pin's commit refuses, before any pin code
    # runs. Both launchers name the host in $HostKind and leave the binding to pass in $HostBinding.
    param([string]$DispatcherRelPath)
    $refusal = 'Specrew could not load its reviewed engine for this project, so it recorded nothing from this turn. The pinned copy named in .specrew/runtime/live-engine.json could not be found, or is not at the reviewed commit it was set to. Your earlier approvals and answers are unchanged. To fix it, the crew can re-create the pinned copy with scripts/internal/live-engine-pin.ps1. Should it do that?'
    $bindingRefusal = 'Specrew could not load its reviewed engine for this project, so it recorded nothing from this turn. The host settings in .specrew/runtime/live-engine-bindings.json are missing, or were written for a different commit than the pinned copy. Your earlier approvals and answers are unchanged. To fix it, the crew can re-create the pinned copy with scripts/internal/live-engine-pin.ps1. Should it do that?'
    $text = @'
$pinArgs = @{};
$pinRecord = Join-Path $projectRoot '.specrew/runtime/live-engine.json';
if (Test-Path -LiteralPath $pinRecord -PathType Leaf) {
    $pinRoot = ''; $pinCommit = ''; $pinHead = '';
    try { $pinData = Get-Content -LiteralPath $pinRecord -Raw | ConvertFrom-Json; $pinRoot = [string]$pinData.path; $pinCommit = ([string]$pinData.commit).ToLowerInvariant() } catch { $pinRoot = '' };
    if (-not [string]::IsNullOrWhiteSpace($pinRoot)) {
        try {
            $pinGitDir = Join-Path $pinRoot '.git';
            if (Test-Path -LiteralPath $pinGitDir -PathType Leaf) { $pinGitDir = ([string](Get-Content -LiteralPath $pinGitDir -TotalCount 1) -replace '^gitdir:\s*', '').Trim(); if (-not [IO.Path]::IsPathRooted($pinGitDir)) { $pinGitDir = Join-Path $pinRoot $pinGitDir } };
            $pinHead = ([string](Get-Content -LiteralPath (Join-Path $pinGitDir 'HEAD') -TotalCount 1)).Trim().ToLowerInvariant()
        } catch { $pinHead = '' }
    };
    $pinned = if ([string]::IsNullOrWhiteSpace($pinRoot)) { '' } else { Join-Path $pinRoot '__DISPATCHER__' };
    if ([string]::IsNullOrWhiteSpace($pinned) -or $pinCommit -notmatch '^[0-9a-f]{40}$' -or $pinHead -ne $pinCommit -or -not (Test-Path -LiteralPath $pinned -PathType Leaf)) { [Console]::Error.WriteLine('__REFUSAL__'); exit 1 };
    $pinBinding = '';
    try { $pinBindings = Get-Content -LiteralPath (Join-Path $projectRoot '.specrew/runtime/live-engine-bindings.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop; if (([string]$pinBindings.commit).ToLowerInvariant() -eq $pinCommit -and $null -ne $pinBindings.bindings.PSObject.Properties[$HostKind]) { $pinBinding = [string]$pinBindings.bindings.$HostKind } } catch { $pinBinding = '' };
    if ([string]::IsNullOrWhiteSpace($pinBinding)) { [Console]::Error.WriteLine('__BINDING_REFUSAL__'); exit 1 };
    $dispatcher = $pinned; $HostBinding = $pinBinding; $pinArgs['ProjectRoot'] = $projectRoot
};
'@
    return $text.Replace('__DISPATCHER__', $DispatcherRelPath).Replace('__REFUSAL__', $refusal.Replace("'", "''")).Replace('__BINDING_REFUSAL__', $bindingRefusal.Replace("'", "''"))
}

function Get-GuardedProjectRootVariable {
    $projectRootVariables = @(Get-ManifestValue -Map $hookBindings -Key 'ProjectRootEnvironmentVariables' -Default @())
    $projectRootVariable = @($projectRootVariables | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -First 1)
    if ($projectRootVariable.Count -ne 1) {
        throw "Host manifest '$hostManifestPath' uses CommandMode=guarded-project-encoded but does not declare exactly one usable ProjectRootEnvironmentVariables entry."
    }
    return [string]$projectRootVariable[0]
}

function Install-ProjectHookLauncher {
    # Feature 203 T002 follow-up (DRIFT-016): the launcher of a guarded-project-encoded host, generated beside the
    # project's hook settings and tracked with them, so it is exactly as trusted as those settings. It holds what the
    # encoded command used to carry inline: the host's project-root variable, the live-engine pin check (which still
    # runs before any pin code) and the baked binding. Idempotent: same bytes every deploy.
    $escapedVariable = (Get-GuardedProjectRootVariable).Replace("'", "''")
    $escapedDispatcher = $dispatcherRelPath.Replace("'", "''")
    $body = @(
        '# Specrew project hook launcher - GENERATED by deploy-refocus-hooks.ps1 (do NOT edit by hand; re-deploy instead).'
        'param([Parameter(Mandatory = $true)][string]$Event)'
        ('$HostKind = ''{0}''' -f $HostKind.Replace("'", "''"))
        ('$HostBinding = ''{0}''' -f ([string]$hostRuntimeBinding).Replace("'", "''"))
        # The kill switch comes first, as in the per-machine launcher and the dispatcher, so it still works when the pin
        # check below would refuse (review round 3, finding 2). Decision-only events still get their no-op answer.
        'if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_REFOCUS_DISABLE)) {'
        '    try { if (@(([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($HostBinding)) | ConvertFrom-Json).DecisionOnlyEvents | ForEach-Object { [string]$_ }) -contains $Event) { @{} | ConvertTo-Json -Compress } } catch { $null = $_ }'
        '    exit 0'
        '}'
        ('$projectRoot = [Environment]::GetEnvironmentVariable(''{0}''); if ([string]::IsNullOrWhiteSpace($projectRoot)) {{ exit 0 }}' -f $escapedVariable)
        ('$dispatcher = Join-Path $projectRoot ''{0}''' -f $escapedDispatcher)
        (Get-LiveEnginePinLauncherText -DispatcherRelPath $escapedDispatcher).Trim()
        # Feature 203 T006 (DRIFT-018): a refusal is plain text; a throw reached the host in pwsh's error view.
        'if (-not (Test-Path -LiteralPath $dispatcher -PathType Leaf)) { [Console]::Error.WriteLine("Specrew could not find its hook dispatcher at ''$dispatcher'', so it recorded nothing from this turn. Your earlier approvals and answers are unchanged. To fix it, the crew can redeploy this project''s hooks with specrew update. Should it do that?"); exit 1 }'
        'if ([string]::IsNullOrWhiteSpace($HostBinding)) { & $dispatcher -Event $Event -HostKind $HostKind @pinArgs } else { & $dispatcher -Event $Event -HostKind $HostKind -HostBinding $HostBinding @pinArgs }'
    ) -join "`n"
    New-Item -ItemType Directory -Path (Split-Path -Parent $projectLauncherPath) -Force | Out-Null
    [System.IO.File]::WriteAllText($projectLauncherPath, $body + "`n", [System.Text.UTF8Encoding]::new($false))
}

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
    $hostBindingArg = if (-not [string]::IsNullOrWhiteSpace($hostRuntimeBinding)) {
        ' -HostBinding "' + $hostRuntimeBinding + '"'
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
            return ('pwsh -NoProfile -ExecutionPolicy Bypass -File "{0}" -Event {1} -HostKind {2}{3}' -f $target, $EventName, $HostKind, $hostBindingArg)
        }
        'guarded-project-encoded' {
            $escapedVariable = (Get-GuardedProjectRootVariable).Replace("'", "''")
            $escapedLauncher = $projectLauncherRelPath.Replace("'", "''")
            $escapedEvent = $EventName.Replace("'", "''")
            # Feature 203 T002 follow-up (DRIFT-016): the command only finds and runs the project's generated launcher
            # (Install-ProjectHookLauncher), which holds the baked binding and the live-engine pin check. Inline, they
            # made the encoded command longer than cmd.exe's 8,191-character limit, and every hook failed.
            $scriptText = ('$projectRoot = [Environment]::GetEnvironmentVariable(''{0}''); if ([string]::IsNullOrWhiteSpace($projectRoot)) {{ exit 0 }}; $launcher = Join-Path $projectRoot ''{1}''; if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {{ throw "Specrew hook launcher not found at ''$launcher''." }}; & $launcher -Event ''{2}''' -f $escapedVariable, $escapedLauncher, $escapedEvent)
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($scriptText))
            return ('pwsh -NoProfile -ExecutionPolicy Bypass -EncodedCommand {0}' -f $encoded)
        }
        'launcher-file' {
            return ('pwsh -NoProfile -ExecutionPolicy Bypass -File "{0}" -Event {1} -HostKind {2}{3}{4}' -f (Get-HookLauncherPath), $EventName, $HostKind, $modulePathArg, $hostBindingArg)
        }
        'launcher-encoded' {
            $escapedLauncher = (Get-HookLauncherPath).Replace("'", "''")
            $escapedEvent = $EventName.Replace("'", "''")
            $modulePathEncodedArg = ''
            if (-not [string]::IsNullOrWhiteSpace($launcherModulePath)) {
                $modulePathEncodedArg = " -ModulePath '" + ($launcherModulePath.Replace("'", "''")) + "'"
            }
            # The baked binding is not in this command: encoded, it alone took the command to about 7,350 characters
            # (DRIFT-016). Install-HookLauncher writes it to the store under its content id, and the command names
            # that id, so every project keeps the binding it was deployed with (round 4, finding 1).
            $bindingIdArg = ''
            if (-not [string]::IsNullOrWhiteSpace($hostRuntimeBinding)) {
                $bindingIdArg = ' -BindingId ' + (Get-HookContentId -Text $hostRuntimeBinding)
            }
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(("& '{0}' -Event '{1}' -HostKind {2}{3}{4}" -f $escapedLauncher, $escapedEvent, $HostKind, $modulePathEncodedArg, $bindingIdArg)))
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

function Get-HookContentId {
    # The content address of a store file: the first 32 hex digits of the SHA-256 of its text. Feature 203 T002
    # (review rounds 4 and 5): commands name launchers and bindings by this id, so a deploy from another project or
    # another engine writes a different file instead of changing the one an existing command uses.
    param([string]$Text)
    $hash = [System.Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text.Trim()))
    return ([Convert]::ToHexString($hash).Substring(0, 32).ToLowerInvariant())
}

function Write-HookStoreFile {
    # Writes a content-addressed store file once. An existing file with the same name already holds this content;
    # one that does not (damaged or edited) is restored, never replaced with other content.
    param([string]$Path, [string]$Text)
    $current = if (Test-Path -LiteralPath $Path -PathType Leaf) { [System.IO.File]::ReadAllText($Path) } else { $null }
    if ($current -ceq $Text) { return }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Get-HookLauncherPath {
    # ~/.specrew/hooks/<content id>/specrew-hook-launch.ps1 for this engine's launcher. The file name stays
    # specrew-hook-launch.ps1, which is how deploys and the health check recognize Specrew's own commands.
    if ([string]::IsNullOrWhiteSpace($script:launcherPath)) {
        $script:launcherPath = (Join-Path (Join-Path $hookStoreRoot (Get-HookContentId -Text (Get-HookLauncherBody))) 'specrew-hook-launch.ps1') -replace '\\', '/'
    }
    return $script:launcherPath
}

function Install-HookLauncher {
    # Write this engine's per-machine launcher, and the host's baked binding when its command leaves it out, to the
    # content-addressed store. Neither is ever replaced with other content: other projects' commands, deployed from
    # other engines, keep the files they name.
    Write-HookStoreFile -Path (Get-HookLauncherPath) -Text (Get-HookLauncherBody)
    if ($hookCommandMode -eq 'launcher-encoded' -and -not [string]::IsNullOrWhiteSpace($hostRuntimeBinding)) {
        $bindingText = $hostRuntimeBinding.Trim()
        Write-HookStoreFile -Path (Join-Path $hookStoreRoot ("bindings/{0}-{1}.binding" -f $HostKind, (Get-HookContentId -Text $bindingText))) -Text $bindingText
        # The shared ~/.specrew/hook-bindings/<host>.binding of 0999ff62 to 7abcd180 is left in place: this launcher never
        # reads it, but commands deployed from those commits still do (review round 6, finding 1).
    }
}

function Get-HookLauncherBody {
    # The per-machine launcher used by launcher command modes. The same engine always produces the same bytes, so
    # its content id is stable. The launcher is intentionally
    # SELF-CONTAINED — it runs BEFORE any project is known, so it cannot dot-source project files; it does only
    # the minimal bootstrap resolution needed to FIND the deployed dispatcher, then hands off (the dispatcher
    # re-resolves the project from its own $PSScriptRoot). A single-quoted here-string keeps the launcher's own
    # $env:/$raw/${...} literal — it is NOT expanded at deploy time. The launcher path is the only deploy-time
    # value, and it is baked into the command string (Get-SpecrewHookCommand), not into the launcher body.
    if (-not [string]::IsNullOrEmpty($script:launcherBodyCache)) { return $script:launcherBodyCache }
    $projectRootEnvVarLiteral = ConvertTo-PowerShellStringArrayLiteral -Values @(Get-HookLauncherProjectRootEnvVars)
    # This here-string GENERATES the launcher file, and the one internal id in it sits inside a
    # comment of that generated file - the sanctioned half of the provenance rule. The generator
    # carries it as a string only because the whole file body is one string.
    # specrew-internal-id-ok: generated-file comment; comments are the sanctioned half
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
    [string]$HostBinding,
    [string]$BindingId,
    [string]$ModulePath,
    [int]$ProviderTimeoutSeconds = 20
)
# An encoded host command leaves the baked binding out (it alone would near the command-line limit) and names it by
# content id instead; deploy writes it to the store beside this launcher's folder once. Only the file the command
# names is read, and only when its content still matches the id, so one project's deploy cannot change another's.
# A named binding that cannot be read or verified refuses below, after the kill switch: running without it would
# apply whatever rules a manifest found elsewhere holds (review round 6, finding 2).
$bindingUnverified = $false
if ([string]::IsNullOrWhiteSpace($HostBinding) -and -not [string]::IsNullOrWhiteSpace($BindingId)) {
    $bindingUnverified = $true
    if ($HostKind -match '^[A-Za-z0-9_.-]+$' -and $BindingId -match '^[0-9a-f]{32}$') {
        $bindingFile = Join-Path (Split-Path -Parent $PSScriptRoot) ("bindings/{0}-{1}.binding" -f $HostKind, $BindingId)
        try {
            $bindingText = ([IO.File]::ReadAllText($bindingFile)).Trim()
            $bindingHash = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($bindingText)))
            if ($bindingHash.Substring(0, 32).ToLowerInvariant() -eq $BindingId) { $HostBinding = $bindingText; $bindingUnverified = $false }
        }
        catch { $HostBinding = $null }
    }
}
function Test-LauncherDecisionOnlyEvent {
    param([string]$EventName, [string]$EncodedBinding)
    if ([string]::IsNullOrWhiteSpace($EncodedBinding)) { return $false }
    try {
        $runtime = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($EncodedBinding)) | ConvertFrom-Json -ErrorAction Stop
        return @($runtime.DecisionOnlyEvents | ForEach-Object { [string]$_ }) -contains $EventName
    }
    catch { return $false }
}

function Write-LauncherDecisionNoopIfNeeded {
    param([string]$EventName, [string]$EncodedBinding)
    if (Test-LauncherDecisionOnlyEvent -EventName $EventName -EncodedBinding $EncodedBinding) {
        @{} | ConvertTo-Json -Compress
    }
}

# KILL SWITCH FIRST — before any logic that could itself fail (FR-008 doctrine). Decision-only hosts still
# require no-op JSON; this helper reads only the baked binding and fails quiet.
if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_REFOCUS_DISABLE)) {
    Write-LauncherDecisionNoopIfNeeded -EventName $Event -EncodedBinding $HostBinding
    exit 0
}
if ($bindingUnverified) {
    # Plain text, not an error record: this is what the host shows the human.
    [Console]::Error.WriteLine('Specrew could not load the host settings this hook was set up with, so it recorded nothing from this turn. The settings file the hook names, in .specrew/hooks/bindings under your user folder, is missing or was changed after it was written. Your earlier approvals and answers are unchanged. To fix it, the crew can redeploy this project''s hooks with specrew update. Should it do that?')
    exit 1
}
$ErrorActionPreference = 'Stop'

# Dev-tree dogfood path: when specrew init/update ran from an imported development tree, bake that module
# root into the launcher command so host-spawned hook children do not fall through to stale installed modules.
if (-not [string]::IsNullOrWhiteSpace($ModulePath) -and (Test-Path -LiteralPath $ModulePath -PathType Container)) {
    $env:SPECREW_MODULE_PATH = $ModulePath
}

# The dispatcher's project-relative subpath — the SENTINEL we look for when walking up a candidate root. We key
# on the dispatcher FILE (not a .specrew dir) so a stray ~/.specrew up the cwd tree never mis-resolves a project
# (this launcher itself lives under ~/.specrew). A live-engine pin record is a sentinel too (Feature 203 T002, review
# rounds 4 to 6): a pinned project is found at its own folder even when its deployed dispatcher is missing, so the
# walk never passes it to reach an ancestor project's dispatcher, and the pin decides below.
$dispatcherSub = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
$pinRecordSub = '.specrew/runtime/live-engine.json'
$projectRootEnvVars = __SPECREW_PROJECT_ROOT_ENV_VARS__

function Find-ProjectUpTree {
    param([string]$Start)
    $candidate = $Start
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        if ((Test-Path -LiteralPath (Join-Path $candidate $dispatcherSub) -PathType Leaf) -or
            (Test-Path -LiteralPath (Join-Path $candidate $pinRecordSub) -PathType Leaf)) { return $candidate }
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
    # Hook payloads are UTF-8, but a host-spawned hook's console input code page is the OEM one (measured ibm437,
    # 202 research.md T001), and [Console]::In decodes with it - a Hebrew prompt arrived as mojibake. Read the raw
    # bytes and decode them as UTF-8 explicitly (a leading BOM is dropped).
    try {
        $stdinBytes = [IO.MemoryStream]::new()
        [Console]::OpenStandardInput().CopyTo($stdinBytes)
        $raw = [Text.UTF8Encoding]::new($false).GetString($stdinBytes.ToArray()).TrimStart([char]0xFEFF)
    }
    catch { $raw = '' }
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

$projectRoot = $null
foreach ($start in $candidates) {
    $found = Find-ProjectUpTree -Start $start
    if (-not [string]::IsNullOrWhiteSpace($found)) { $projectRoot = $found; break }
}
if ([string]::IsNullOrWhiteSpace($projectRoot)) {
    Write-LauncherDecisionNoopIfNeeded -EventName $Event -EncodedBinding $HostBinding
    exit 0
}

# A project with a live-engine pin runs the pin's dispatcher, told this project's root; a pin that cannot be
# found refuses (the one exit that is not 0), and nothing falls back to the project's deployed copy. A project
# found by its pin record alone has no deployed dispatcher, so only the pin can run it.
$dispatcher = Join-Path $projectRoot $dispatcherSub
__SPECREW_LIVE_ENGINE_PIN__

# Hand off to the project's deployed dispatcher. Pass the captured payload via -EventJson so the dispatcher does
# not try to re-read the now-consumed stdin (only when non-empty). The dispatcher's stdout (injection output)
# flows through this process to the host. Always exit 0.
$dispatchArgs = @{ Event = $Event; HostKind = $HostKind; ProviderTimeoutSeconds = $ProviderTimeoutSeconds } + $pinArgs
if (-not [string]::IsNullOrWhiteSpace($raw)) { $dispatchArgs['EventJson'] = $raw }
if (-not [string]::IsNullOrWhiteSpace($HostBinding)) { $dispatchArgs['HostBinding'] = $HostBinding }
try { & $dispatcher @dispatchArgs }
catch {
    [Console]::Error.WriteLine("[specrew-refocus] WARN LAUNCH_FAILED $($_.Exception.Message)")
    Write-LauncherDecisionNoopIfNeeded -EventName $Event -EncodedBinding $HostBinding
}
exit 0
'@
    $launcherBody = $launcherBody.Replace('__SPECREW_PROJECT_ROOT_ENV_VARS__', $projectRootEnvVarLiteral)
    $launcherBody = $launcherBody.Replace('__SPECREW_LIVE_ENGINE_PIN__', (Get-LiveEnginePinLauncherText -DispatcherRelPath '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'))
    $script:launcherBodyCache = $launcherBody
    return $launcherBody
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
        if ($hookCommandMode -eq 'guarded-project-encoded' -and (Test-Path -LiteralPath $projectLauncherPath -PathType Leaf)) { Remove-Item -LiteralPath $projectLauncherPath -Force }
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
    if ($hookCommandMode -eq 'guarded-project-encoded') { Install-ProjectHookLauncher }
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
    if ($hookCommandMode -eq 'guarded-project-encoded' -and (Test-Path -LiteralPath $projectLauncherPath -PathType Leaf)) { Remove-Item -LiteralPath $projectLauncherPath -Force }
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
if ($hookCommandMode -eq 'guarded-project-encoded') { Install-ProjectHookLauncher }

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
