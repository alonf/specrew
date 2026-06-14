# Feature 171 T017 (FR-014/FR-018): refocus deploy integration for init/update.
# Dot-sourced by scripts/specrew-update.ps1 and scripts/specrew-init.ps1.
#
# Two responsibilities:
#   1. Catalog managed-with-overlay merge: the speckit-extension deploy mirrors
#      refocus-scopes.json WHOLESALE, which would clobber user keys. Capture the
#      user-owned keys BEFORE the deploy (per-trigger `enabled` flags + provider
#      rows whose id is not canonical) and re-apply them AFTER. Fail SAFE: an
#      unreadable pre-existing catalog aborts the overlay (capture returns the
#      abort marker) and the re-apply leaves the freshly-deployed canonical file
#      untouched rather than guessing.
#   2. Hook deployment wiring: invoke deploy-refocus-hooks.ps1 per host — claude
#      when the project carries .claude/, codex/copilot/cursor when the host
#      binary is on PATH. The deploy script itself respects recorded opt-outs
#      (no silent re-enable; the update-never-flips-disables principle).

function Get-RefocusCatalogOverlay {
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $catalogPath = Join-Path $ProjectPath '.specify/extensions/specrew-speckit/refocus-scopes.json'
    if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
        return [pscustomobject]@{ Present = $false; Aborted = $false; TriggerEnabled = @{}; UserProviders = @() }
    }
    try {
        $catalog = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        # Fail SAFE: unreadable catalog -> no overlay (the deploy will restore a
        # clean canonical file; we never merge into something we cannot parse).
        return [pscustomobject]@{ Present = $true; Aborted = $true; TriggerEnabled = @{}; UserProviders = @() }
    }
    $triggerEnabled = @{}
    if ($catalog.PSObject.Properties['triggers'] -and $null -ne $catalog.triggers) {
        foreach ($prop in $catalog.triggers.PSObject.Properties) {
            if ($prop.Value.PSObject.Properties['enabled']) {
                $triggerEnabled[$prop.Name] = [bool]$prop.Value.enabled
            }
        }
    }
    # Canonical Specrew provider ids (module-shipped): refocus (F-171) + bootstrap + handover
    # (F-174). Everything else in the project catalog is a user overlay row to capture + re-apply.
    $canonicalProviderIds = @('refocus', 'bootstrap', 'handover')
    $userProviders = @()
    if ($catalog.PSObject.Properties['providers'] -and $null -ne $catalog.providers) {
        $userProviders = @($catalog.providers | Where-Object { $canonicalProviderIds -notcontains [string]$_.id })
    }
    return [pscustomobject]@{ Present = $true; Aborted = $false; TriggerEnabled = $triggerEnabled; UserProviders = $userProviders }
}

function Set-RefocusCatalogOverlay {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)]$Overlay
    )
    if (-not $Overlay.Present -or $Overlay.Aborted) { return $false }
    if (($Overlay.TriggerEnabled.Count -eq 0) -and (@($Overlay.UserProviders).Count -eq 0)) { return $false }
    $catalogPath = Join-Path $ProjectPath '.specify/extensions/specrew-speckit/refocus-scopes.json'
    if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) { return $false }
    try {
        $catalog = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch { return $false }   # fail safe: never merge into an unparsable file

    $changed = $false
    if ($catalog.PSObject.Properties['triggers'] -and $null -ne $catalog.triggers) {
        foreach ($key in $Overlay.TriggerEnabled.Keys) {
            $trigger = $catalog.triggers.PSObject.Properties[$key]
            if ($null -ne $trigger -and $trigger.Value.PSObject.Properties['enabled'] -and ([bool]$trigger.Value.enabled) -ne $Overlay.TriggerEnabled[$key]) {
                $trigger.Value.PSObject.Properties['enabled'].Value = $Overlay.TriggerEnabled[$key]
                $changed = $true
            }
        }
    }
    if (@($Overlay.UserProviders).Count -gt 0 -and $catalog.PSObject.Properties['providers']) {
        # Dup-ID guard (PR #2152 review): if a newer canonical catalog now ships a
        # provider whose id matches a captured user row, do NOT re-append it — that would
        # duplicate the id and run the provider twice. Only restore user rows whose id is
        # absent from the freshly-deployed canonical set.
        $canonical = @($catalog.providers)
        $canonicalIds = @($canonical | ForEach-Object { [string]$_.id })
        $newUserProviders = @($Overlay.UserProviders | Where-Object { $canonicalIds -notcontains [string]$_.id })
        if (@($newUserProviders).Count -gt 0) {
            $catalog.PSObject.Properties['providers'].Value = @($canonical + $newUserProviders)
            $changed = $true
        }
    }
    if ($changed) {
        [System.IO.File]::WriteAllText($catalogPath, ($catalog | ConvertTo-Json -Depth 16), [System.Text.UTF8Encoding]::new($false))
    }
    return $changed
}

function Invoke-RefocusHookDeployment {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$DeployScriptPath,
        # Hermetic-test seam (PR #2152 review): deploy-refocus-hooks.ps1 already supports
        # -UserHomeOverride; expose it here so e2e/consumer test runners can keep codex/
        # copilot/cursor writes out of the REAL user home. Unset in production (no behavior
        # change — the deploy script defaults to the real home).
        [string]$UserHomeOverride
    )
    $actions = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path -LiteralPath $DeployScriptPath -PathType Leaf)) { return $actions.ToArray() }

    # F-174 iter-11 (FR-028 layer 1, T010, decision f174-i011-hook-deploy-hardening): PROACTIVE provisioning.
    # Provision hook configs for ALL hook-capable registry hosts, NOT only hosts detected on PATH. The old
    # PATH gate (Get-Command codex/copilot/cursor) left a SILENT degradation hole: a user who ran `specrew
    # init`, later installed Codex/Copilot/Cursor, and launched directly got hookless behavior with no
    # warning. The user-level configs point at the per-machine launcher, which no-ops outside a Specrew
    # project, so provisioning is SAFE even when the host binary is absent (the launcher install rides this
    # too — a later `specrew update` is all the user needs). claude is PROJECT-level
    # (.claude/settings.local.json), provisioned only when the project carries .claude/ (the Squad runtime
    # creates it before this runs — the ordering invariant). The deploy script preserves user entries,
    # replaces only Specrew-owned entries, and RESPECTS recorded opt-outs (no silent re-enable).
    #
    # Hook-capable hosts come from the registry (single source of truth: a manifest carrying
    # RefocusHookBindings — Get-SpecrewHookCapableHosts), with a fail-open ladder: (1) the function if already
    # loaded; (2) dot-source the registry from the resolved repo path; (3) a last-resort known set so a
    # registry-load failure never silently provisions NOTHING. Antigravity (hookless — no RefocusHookBindings)
    # is correctly excluded by the registry.
    $hookCapable = $null
    if (Get-Command Get-SpecrewHookCapableHosts -ErrorAction SilentlyContinue) {
        try { $hookCapable = @(Get-SpecrewHookCapableHosts) } catch { $hookCapable = $null }
    }
    if ($null -eq $hookCapable -or $hookCapable.Count -eq 0) {
        $registryPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'hosts/_registry.ps1'
        if (Test-Path -LiteralPath $registryPath -PathType Leaf) {
            try { . $registryPath; $hookCapable = @(Get-SpecrewHookCapableHosts) } catch { $hookCapable = $null }
        }
    }
    if ($null -eq $hookCapable -or $hookCapable.Count -eq 0) {
        $hookCapable = @('claude', 'codex', 'copilot', 'cursor')   # last-resort known hook-capable set
    }

    $hostTargets = New-Object System.Collections.Generic.List[string]
    foreach ($hostKind in $hookCapable) {
        if ($hostKind -eq 'claude') {
            # PROJECT-level config — only meaningful once the project carries .claude/ (created by the Squad
            # runtime before this runs). Skip if absent rather than create the directory here.
            if (Test-Path -LiteralPath (Join-Path $ProjectPath '.claude') -PathType Container) { $hostTargets.Add('claude') | Out-Null }
        }
        else {
            # USER-level config (codex/copilot/cursor) -> per-machine launcher; provisioned PROACTIVELY
            # regardless of whether the host binary is currently on PATH (the user may install it later).
            $hostTargets.Add($hostKind) | Out-Null
        }
    }

    foreach ($hostKind in $hostTargets) {
        try {
            $deployArgs = @{ ProjectPath = $ProjectPath; HostKind = $hostKind }
            if (-not [string]::IsNullOrWhiteSpace($UserHomeOverride)) { $deployArgs['UserHomeOverride'] = $UserHomeOverride }
            $output = @(& $DeployScriptPath @deployArgs 2>&1 | ForEach-Object { [string]$_ })
            $actions.Add([pscustomobject]@{ HostKind = $hostKind; Action = 'refocus-hooks'; Detail = ($output -join ' ') }) | Out-Null
        }
        catch {
            # Fail open: hook deployment problems never fail init/update.
            $actions.Add([pscustomobject]@{ HostKind = $hostKind; Action = 'refocus-hooks-failed'; Detail = $_.Exception.Message }) | Out-Null
        }
    }
    return $actions.ToArray()
}
