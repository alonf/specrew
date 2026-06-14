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
  marker (the same shapes deploy-refocus-hooks.ps1 uses) and keys staleness on the STABLE ownership tokens
  (the dispatcher / launcher filenames + the ${CLAUDE_PROJECT_DIR} brace placeholder), which are the contract
  and do not change with command-format tweaks. Pure I/O + string building; never throws.
#>

Set-StrictMode -Version Latest

$script:HookHealthScriptRoot = $PSScriptRoot

function Get-SpecrewHookHealthHostList {
    # The hook-capable host set (registry-driven, single source of truth: a manifest carrying
    # RefocusHookBindings). Fail-open ladder mirrors the deploy orchestrator: (1) the function if loaded;
    # (2) dot-source the registry from the resolved repo path; (3) a last-resort known set.
    if (Get-Command Get-SpecrewHookCapableHosts -ErrorAction SilentlyContinue) {
        try { $h = @(Get-SpecrewHookCapableHosts); if ($h.Count -gt 0) { return $h } } catch { $null = $_ }
    }
    $repoRoot = Split-Path -Parent (Split-Path -Parent $script:HookHealthScriptRoot)
    $registry = Join-Path $repoRoot 'hosts/_registry.ps1'
    if (Test-Path -LiteralPath $registry -PathType Leaf) {
        try { . $registry; $h = @(Get-SpecrewHookCapableHosts); if ($h.Count -gt 0) { return $h } } catch { $null = $_ }
    }
    return @('claude', 'codex', 'copilot', 'cursor')
}

function Get-SpecrewHostHookConfigPath {
    # The per-host hook-config file path — the SAME shapes deploy-refocus-hooks.ps1 writes (claude is
    # PROJECT-level; codex/copilot/cursor are USER-level under the home root).
    param(
        [Parameter(Mandatory)][string]$HostKind,
        [Parameter(Mandatory)][string]$ProjectPath,
        [Parameter(Mandatory)][string]$UserHome
    )
    switch ($HostKind) {
        'claude' { return (Join-Path $ProjectPath '.claude/settings.local.json') }
        'codex' { return (Join-Path $UserHome '.codex/hooks.json') }
        'copilot' { return (Join-Path $UserHome '.copilot/hooks/specrew-refocus.json') }
        'cursor' { return (Join-Path $UserHome '.cursor/hooks.json') }
        default { return $null }
    }
}

function Get-SpecrewHostOptOutMarkerPath {
    # The opt-out marker path — claude has no suffix; user-level hosts are per-host (matches
    # deploy-refocus-hooks.ps1 line 64). Lives under the PROJECT (per-machine, .gitignored runtime).
    param([Parameter(Mandatory)][string]$HostKind, [Parameter(Mandatory)][string]$ProjectPath)
    $suffix = if ($HostKind -ne 'claude') { "-$HostKind" } else { '' }
    return (Join-Path $ProjectPath ('.specrew/runtime/refocus-hooks-optout' + $suffix))
}

function Get-SpecrewHooksStatus {
    # Per hook-capable host: installed | missing | stale | opted-out | failed. Fail-open (never throws).
    # State precedence: opted-out (marker present) > missing (no config file) > failed (config unparsable) >
    # installed/stale/missing (by ownership token). "stale" = a Specrew entry exists but in the OLD form (the
    # pre-ff34e776 bare/relative dispatcher entry instead of the cwd-robust ${CLAUDE_PROJECT_DIR} placeholder
    # (claude) or the per-machine launcher (user-level)) — i.e. `specrew hooks install` would change it.
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)][string]$ProjectPath,
        [string]$UserHomeOverride
    )
    $userHome = if (-not [string]::IsNullOrWhiteSpace($UserHomeOverride)) { $UserHomeOverride } else { [Environment]::GetFolderPath('UserProfile') }
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($hostKind in (Get-SpecrewHookHealthHostList)) {
        $configPath = Get-SpecrewHostHookConfigPath -HostKind $hostKind -ProjectPath $ProjectPath -UserHome $userHome
        $optOut = Get-SpecrewHostOptOutMarkerPath -HostKind $hostKind -ProjectPath $ProjectPath
        $state = 'missing'; $detail = 'no Specrew hook entry'

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
                    $hasDispatcher = $raw.Contains('specrew-hook-dispatcher.ps1')
                    $hasLauncher = $raw.Contains('specrew-hook-launch.ps1')
                    $hasBraced = $raw.Contains('${CLAUDE_PROJECT_DIR}')
                    if ($hostKind -eq 'claude') {
                        if ($hasDispatcher -and $hasBraced) { $state = 'installed'; $detail = 'dispatcher via ${CLAUDE_PROJECT_DIR} placeholder (cwd-robust)' }
                        elseif ($hasDispatcher) { $state = 'stale'; $detail = 'dispatcher entry present but NOT the cwd-robust ${CLAUDE_PROJECT_DIR} form (run: specrew hooks install --host claude)' }
                        else { $state = 'missing'; $detail = 'no Specrew hook entry' }
                    }
                    else {
                        if ($hasLauncher) { $state = 'installed'; $detail = 'per-machine launcher entry' }
                        elseif ($hasDispatcher) { $state = 'stale'; $detail = ("legacy dispatcher entry (pre-launcher form; run: specrew hooks install --host {0})" -f $hostKind) }
                        else { $state = 'missing'; $detail = 'no Specrew hook entry' }
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
