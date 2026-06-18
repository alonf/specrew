<#
.SYNOPSIS
  F-174 iteration 011 (FR-028, decision f174-i011-hook-deploy-hardening): hook-health inspection — the
  NON-MIRRORED single source of truth shared by the `specrew hooks` command (layer 2) and the degradation
  diagnostic (layer 3).
.DESCRIPTION
  Two pure, fail-open helpers:
    - Get-SpecrewHooksStatus: per hook-capable host, report installed / missing / stale / opted-out / failed.
    - Test-SpecrewBootstrapDirectiveArrived: did the SessionStart/bootstrap directive land THIS session?
      (layer-3 diagnostic input — see specrew-hook-health Test-* below; the warn-once gate rides it.)

  This file is deliberately NOT one of the 3-copy-mirrored hook scripts (deploy-refocus-hooks.ps1 /
  specrew-hook-dispatcher.ps1). It does NOT dot-source the mirrored deploy script (that script has top-level
  side effects — dot-sourcing it would TRIGGER a deploy). It re-derives the per-host config path + the opt-out
  marker (the same shapes deploy-refocus-hooks.ps1 uses) and keys staleness on manifest-declared stable
  ownership tokens such as dispatcher / launcher filenames and any project-root placeholder. Pure I/O +
  string building; never throws.
#>

Set-StrictMode -Version Latest

$script:HookHealthScriptRoot = $PSScriptRoot

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

function Get-SpecrewHookHealthRepoRoot {
    $candidate = $script:HookHealthScriptRoot
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'hosts') -PathType Container) { return $candidate }
        $parent = Split-Path -Parent $candidate
        if ($parent -eq $candidate) { break }
        $candidate = $parent
    }
    return (Split-Path -Parent (Split-Path -Parent $script:HookHealthScriptRoot))
}

function Find-SpecrewHookHealthManifestPath {
    param([Parameter(Mandatory)][string]$HostKind)
    $repoRoot = Get-SpecrewHookHealthRepoRoot
    $manifestPath = Join-Path $repoRoot ("hosts/{0}/host.psd1" -f $HostKind)
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) { return $manifestPath }
    return $null
}

function Get-SpecrewHookHealthManifest {
    param([Parameter(Mandatory)][string]$HostKind)
    try {
        $manifestPath = Find-SpecrewHookHealthManifestPath -HostKind $HostKind
        if ([string]::IsNullOrWhiteSpace($manifestPath)) { return $null }
        return (Import-PowerShellDataFile -LiteralPath $manifestPath)
    }
    catch {
        return $null
    }
}

function Get-SpecrewHookHealthBindings {
    param([Parameter(Mandatory)][string]$HostKind)
    $manifest = Get-SpecrewHookHealthManifest -HostKind $HostKind
    if ($null -eq $manifest -or -not (Test-ManifestKey -Map $manifest -Key 'RefocusHookBindings')) { return $null }
    return (Get-ManifestValue -Map $manifest -Key 'RefocusHookBindings')
}

function Resolve-SpecrewHookHealthPath {
    param(
        [AllowNull()][string]$PathFromManifest,
        [Parameter(Mandatory)][string]$ProjectPath,
        [Parameter(Mandatory)][string]$UserHome
    )
    if ([string]::IsNullOrWhiteSpace($PathFromManifest)) { return $null }
    if ($PathFromManifest.StartsWith('~/') -or $PathFromManifest.StartsWith('~\')) {
        return (Join-Path $UserHome $PathFromManifest.Substring(2))
    }
    return (Join-Path $ProjectPath $PathFromManifest)
}

function Get-SpecrewHookHealthHostList {
    # The hook-capable host set (registry-driven, single source of truth: a manifest carrying
    # RefocusHookBindings). Fail-open ladder mirrors the deploy orchestrator: (1) the function if loaded;
    # (2) dot-source the registry from the resolved repo path; (3) enumerate host manifests directly.
    if (Get-Command Get-SpecrewHookCapableHosts -ErrorAction SilentlyContinue) {
        try { $h = @(Get-SpecrewHookCapableHosts); if ($h.Count -gt 0) { return $h } } catch { $null = $_ }
    }
    $repoRoot = Get-SpecrewHookHealthRepoRoot
    $registry = Join-Path $repoRoot 'hosts/_registry.ps1'
    if (Test-Path -LiteralPath $registry -PathType Leaf) {
        try { . $registry; $h = @(Get-SpecrewHookCapableHosts); if ($h.Count -gt 0) { return $h } } catch { $null = $_ }
    }
    $hostsRoot = Join-Path $repoRoot 'hosts'
    $hosts = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $hostsRoot -PathType Container) {
        foreach ($dir in @(Get-ChildItem -LiteralPath $hostsRoot -Directory -ErrorAction SilentlyContinue)) {
            $manifestPath = Join-Path $dir.FullName 'host.psd1'
            if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { continue }
            try {
                $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
                if ((Get-ManifestValue -Map $manifest -Key 'Status') -eq 'supported' -and (Test-ManifestKey -Map $manifest -Key 'RefocusHookBindings')) {
                    $hosts.Add([string](Get-ManifestValue -Map $manifest -Key 'Kind' -Default $dir.Name)) | Out-Null
                }
            }
            catch { $null = $_ }
        }
    }
    return $hosts.ToArray()
}

function Get-SpecrewHostHookConfigPath {
    # The per-host hook-config file path — the SAME manifest-declared shape deploy-refocus-hooks.ps1 writes.
    param(
        [Parameter(Mandatory)][string]$HostKind,
        [Parameter(Mandatory)][string]$ProjectPath,
        [Parameter(Mandatory)][string]$UserHome
    )
    $bindings = Get-SpecrewHookHealthBindings -HostKind $HostKind
    return (Resolve-SpecrewHookHealthPath -PathFromManifest ([string](Get-ManifestValue -Map $bindings -Key 'SettingsFile')) -ProjectPath $ProjectPath -UserHome $UserHome)
}

function Get-SpecrewHostOptOutMarkerPath {
    # The opt-out marker path is manifest-declared and normally lives under the project runtime directory.
    param([Parameter(Mandatory)][string]$HostKind, [Parameter(Mandatory)][string]$ProjectPath, [string]$UserHome)
    $bindings = Get-SpecrewHookHealthBindings -HostKind $HostKind
    $resolvedUserHome = if (-not [string]::IsNullOrWhiteSpace($UserHome)) { $UserHome } else { [Environment]::GetFolderPath('UserProfile') }
    return (Resolve-SpecrewHookHealthPath -PathFromManifest ([string](Get-ManifestValue -Map $bindings -Key 'OptOutMarkerFile')) -ProjectPath $ProjectPath -UserHome $resolvedUserHome)
}

function Get-SpecrewHooksStatus {
    # Per hook-capable host: installed | missing | stale | opted-out | failed. Fail-open (never throws).
    # State precedence: opted-out (marker present) > missing (no config file) > failed (config unparsable) >
    # installed/stale/missing (by ownership token). "stale" = a Specrew entry exists but not in the
    # current manifest-declared command binding, i.e. `specrew hooks install` would change it.
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)][string]$ProjectPath,
        [string]$UserHomeOverride
    )
    $userHome = if (-not [string]::IsNullOrWhiteSpace($UserHomeOverride)) { $UserHomeOverride } else { [Environment]::GetFolderPath('UserProfile') }
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($hostKind in (Get-SpecrewHookHealthHostList)) {
        $configPath = Get-SpecrewHostHookConfigPath -HostKind $hostKind -ProjectPath $ProjectPath -UserHome $userHome
        $optOut = Get-SpecrewHostOptOutMarkerPath -HostKind $hostKind -ProjectPath $ProjectPath -UserHome $userHome
        $state = 'missing'; $detail = 'no Specrew hook entry'

        # Defensive: a malformed future manifest could omit path fields. Keep the "never throws" contract
        # real by reporting unknown rather than passing $null to Test-Path.
        if ($null -eq $configPath -or $null -eq $optOut) {
            $rows.Add([pscustomobject]@{ Host = $hostKind; State = 'unknown'; ConfigPath = $configPath; Detail = 'host manifest missing hook SettingsFile or OptOutMarkerFile' }) | Out-Null
            continue
        }

        if (Test-Path -LiteralPath $optOut -PathType Leaf) {
            $state = 'opted-out'; $detail = ("opt-out recorded (re-enable: specrew hooks install --host {0})" -f $hostKind)
        }
        elseif (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
            $state = 'missing'; $detail = 'no hook config file'
        }
        else {
            $raw = $null
            try { $raw = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 } catch { $raw = $null }
            if ($null -eq $raw) {
                $state = 'failed'; $detail = 'config unreadable'
            }
            else {
                $parseOk = $true
                try { $null = $raw | ConvertFrom-Json } catch { $parseOk = $false }
                if (-not $parseOk) {
                    $state = 'failed'; $detail = 'config is not valid JSON (left untouched; specrew hooks cannot repair a hand-broken file)'
                }
                else {
                    $decodedCommands = New-Object System.Collections.Generic.List[string]
                    foreach ($match in [regex]::Matches($raw, '(?i)(?:^|\s)-EncodedCommand\s+([A-Za-z0-9+/=]+)')) {
                        try {
                            $decodedCommands.Add([Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($match.Groups[1].Value))) | Out-Null
                        }
                        catch { $null = $_ }
                    }
                    $inspectionText = $raw + "`n" + ($decodedCommands.ToArray() -join "`n")
                    $hasDispatcher = $inspectionText.Contains('specrew-hook-dispatcher.ps1')
                    $hasLauncher = $inspectionText.Contains('specrew-hook-launch.ps1')
                    $bindings = Get-SpecrewHookHealthBindings -HostKind $hostKind
                    $commandMode = [string](Get-ManifestValue -Map $bindings -Key 'CommandMode' -Default 'launcher-file')
                    $configShape = [string](Get-ManifestValue -Map $bindings -Key 'ConfigShape' -Default 'event-map')
                    $requiredTokens = New-Object System.Collections.Generic.List[string]

                    switch ($commandMode) {
                        'project-placeholder' {
                            $requiredTokens.Add('specrew-hook-dispatcher.ps1') | Out-Null
                            $placeholder = [string](Get-ManifestValue -Map $bindings -Key 'ProjectDirPlaceholder' -Default '')
                            if (-not [string]::IsNullOrWhiteSpace($placeholder)) { $requiredTokens.Add($placeholder) | Out-Null }
                        }
                        'launcher-file' { $requiredTokens.Add('specrew-hook-launch.ps1') | Out-Null }
                        'launcher-encoded' { $requiredTokens.Add('specrew-hook-launch.ps1') | Out-Null }
                        default {
                            $state = 'failed'
                            $detail = ("manifest declares unsupported hook CommandMode '{0}'" -f $commandMode)
                        }
                    }

                    if ($state -ne 'failed' -and $configShape -eq 'named-definition') {
                        $definitionName = [string](Get-ManifestValue -Map $bindings -Key 'DefinitionName')
                        if (-not [string]::IsNullOrWhiteSpace($definitionName)) { $requiredTokens.Add($definitionName) | Out-Null }
                        foreach ($registration in @(Get-ManifestValue -Map $bindings -Key 'Registrations')) {
                            $eventName = [string](Get-ManifestValue -Map $registration -Key 'Event')
                            if (-not [string]::IsNullOrWhiteSpace($eventName)) { $requiredTokens.Add($eventName) | Out-Null }
                        }
                    }

                    if ($state -ne 'failed') {
                        $missingRequired = @($requiredTokens.ToArray() | Where-Object { -not $inspectionText.Contains($_) })
                        if ($missingRequired.Count -eq 0 -and $requiredTokens.Count -gt 0) {
                            $state = 'installed'
                            if ($commandMode -eq 'project-placeholder') {
                                $detail = 'dispatcher via manifest project placeholder (cwd-robust)'
                            }
                            elseif ($configShape -eq 'named-definition') {
                                $detail = 'named hook definition via cwd-robust launcher'
                            }
                            else {
                                $detail = 'per-machine launcher entry'
                            }
                        }
                        elseif ($hasDispatcher -or $hasLauncher) {
                            $state = 'stale'
                            $detail = ("Specrew entry present but not the current manifest binding (run: specrew hooks install --host {0})" -f $hostKind)
                        }
                        else {
                            $state = 'missing'
                            $detail = 'no Specrew hook entry'
                        }
                    }
                }
            }
        }
        $rows.Add([pscustomobject]@{ Host = $hostKind; State = $state; ConfigPath = $configPath; Detail = $detail }) | Out-Null
    }
    # Plain return: the caller wraps with @(). (Do NOT use a leading-comma anti-unwrap here — with the multi-row
    # result it NESTS the array, collapsing every row's fields into one Object[] row.)
    return $rows.ToArray()
}

function Test-SpecrewBootstrapDirectiveArrived {
    # F-174 iteration 011 (FR-028 layer 3, T012): did the SessionStart/bootstrap directive actually land this
    # session? The bootstrap provider writes a per-session runtime trail when its hooks fire
    # (.specrew/runtime/session-marker.json + bootstrap-journal.jsonl). Absence of BOTH in a Specrew project is
    # the signal that hooks are not active for this host. Best-effort + fail-open: an error/uncertainty returns
    # $true (assume arrived) so the layer-3 warning errs toward SILENCE on ambiguity rather than false alarms —
    # the warning is a fallback, not the integrity mechanism. Pass -SessionId to scope to the live session when
    # the host exposes one; without it, ANY recent runtime trail counts as arrived.
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$ProjectPath,
        [AllowNull()][string]$SessionId
    )
    try {
        $runtime = Join-Path $ProjectPath '.specrew/runtime'
        if (-not (Test-Path -LiteralPath $runtime -PathType Container)) { return $false }
        $marker = Join-Path $runtime 'session-marker.json'
        $journal = Join-Path $runtime 'bootstrap-journal.jsonl'
        if (-not (Test-Path -LiteralPath $marker -PathType Leaf) -and -not (Test-Path -LiteralPath $journal -PathType Leaf)) {
            return $false
        }
        # A session-scoped check when we have an id: the marker/journal must reference THIS session.
        if (-not [string]::IsNullOrWhiteSpace($SessionId)) {
            $idHit = $false
            foreach ($f in @($marker, $journal)) {
                if (Test-Path -LiteralPath $f -PathType Leaf) {
                    try { $txt = Get-Content -LiteralPath $f -Raw -Encoding UTF8 } catch { $txt = '' }
                    if (-not [string]::IsNullOrWhiteSpace($txt) -and $txt.Contains($SessionId)) { $idHit = $true; break }
                }
            }
            return $idHit
        }
        # No session id: presence of a runtime trail at all is the best signal we have.
        return $true
    }
    catch {
        return $true   # fail-open toward silence (never false-alarm the human)
    }
}

function Test-SpecrewIsProject {
    # A Specrew project = a .specrew/ directory AND the deployed speckit extension present. Both, so a bare
    # .specrew/ (or a non-Specrew repo that happens to have one) does not false-positive the diagnostic.
    [OutputType([bool])]
    param([Parameter(Mandatory)][string]$ProjectPath)
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath '.specrew') -PathType Container)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $ProjectPath '.specify/extensions/specrew-speckit') -PathType Container)
}

function Get-SpecrewHookDegradationWarning {
    # F-174 iteration 011 (FR-028 layer 3, T012, SC-018): the warn-ONCE degradation gate. Returns the warning
    # STRING when ALL hold — (1) in a Specrew project, (2) the SessionStart/bootstrap directive did NOT arrive
    # this session (hooks look inactive for this host), (3) not already warned this session — else $null. This is
    # a FALLBACK diagnostic the agent surfaces from an always-loaded instruction; it is NEVER the integrity
    # mechanism. Warn-once is enforced by a per-session marker so a multi-turn session does not spam. -Peek
    # computes the verdict WITHOUT recording the marker (for `specrew hooks status` / tests). Fail-open: any error
    # returns $null (err toward silence; never false-alarm). Pure-ish I/O; never throws.
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$ProjectPath,
        [AllowNull()][string]$SessionId,
        [switch]$Peek
    )
    try {
        if (-not (Test-SpecrewIsProject -ProjectPath $ProjectPath)) { return $null }
        if (Test-SpecrewBootstrapDirectiveArrived -ProjectPath $ProjectPath -SessionId $SessionId) { return $null }
        $key = if ([string]::IsNullOrWhiteSpace($SessionId)) { 'nosession' } else { ($SessionId -replace '[^A-Za-z0-9]', '-') }
        $marker = Join-Path $ProjectPath ('.specrew/runtime/hook-degradation-warned-' + $key)
        if (Test-Path -LiteralPath $marker -PathType Leaf) { return $null }
        if (-not $Peek) {
            try {
                $dir = Split-Path -Parent $marker
                if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                [System.IO.File]::WriteAllText($marker, ("warned {0}" -f $key), [System.Text.UTF8Encoding]::new($false))
            }
            catch { $null = $_ }
        }
        return 'Specrew hooks do not appear active for this host. Automatic handover and verdict capture may be unavailable. Run `specrew hooks status` or `specrew update` to repair.'
    }
    catch {
        return $null
    }
}
