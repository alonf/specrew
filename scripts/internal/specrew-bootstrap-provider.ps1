# Specrew B2 bootstrap provider (Feature 174, FR-001/FR-002/FR-020).
# Registered as a provider row in refocus-scopes.json. The SpecrewHookDispatcher
# invokes this on SessionStart with `--event-json <json>` and injects its stdout.
# It fires on B2 ONLY (launch: source startup|resume|clear) and stays SILENT on B1
# (source compact) so F-171 B1 post-compaction behaviour is unchanged (FR-011).
# Fail-open doctrine (P1): any error -> no output, exit 0; never block a session.
#
#   --event-json <json>     the host SessionStart event (dispatcher contract)
#   --project-root <path>   optional override (testability); else resolve up to .specrew

$ErrorActionPreference = 'Stop'

function Get-BootstrapProjectRoot {
    $c = (Get-Location).Path
    while (-not [string]::IsNullOrWhiteSpace($c)) {
        if (Test-Path -LiteralPath (Join-Path $c '.specrew') -PathType Container) { return $c }
        $p = Split-Path -Parent $c
        if ($p -eq $c) { break }
        $c = $p
    }
    return (Get-Location).Path
}

function Format-BootstrapDirective {
    param($Result)
    $d = $Result.directive
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('[specrew-bootstrap] SessionStart B2 - render this as VISIBLE PROSE before any structured picker (render-first; FR-004/FR-020).')
    $lines.Add(("Bootstrap mode: {0}." -f $d.mode))
    $lines.Add('Render, in order: (1) orientation - Specrew version, host, project, lifecycle position; (2) any validated handover summary; (3) a one-line state reason when non-default; (4) the Resume / New / Pick-feature menu as TEXT. Offer Resume only when a valid active session exists.')
    if (@($d.validation_findings).Count -gt 0) {
        $lines.Add(("State notes: {0}." -f ((@($d.validation_findings)) -join '; ')))
    }
    $lines.Add('This directive is advisory and non-authorizing: it never advances a lifecycle boundary on its own.')
    return ($lines -join "`n")
}

try {
    $eventJson = ''
    $rootOverride = $null
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($args[$i] -eq '--event-json' -and ($i + 1) -lt $args.Count) { $eventJson = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--project-root' -and ($i + 1) -lt $args.Count) { $rootOverride = [string]$args[$i + 1] }
    }

    # B1 (compact) is unchanged - the bootstrap is B2 only (FR-011).
    $source = $null
    if (-not [string]::IsNullOrWhiteSpace($eventJson)) {
        try { $source = ($eventJson | ConvertFrom-Json).source } catch { $source = $null }
    }
    if ($source -eq 'compact') { exit 0 }

    $root = if ($rootOverride) { $rootOverride } else { Get-BootstrapProjectRoot }

    # Component resolution (D-001 downstream deploy): components sit beside the provider in the
    # self-host tree (scripts/internal/bootstrap); in a downstream project the provider deploys to
    # the extension tree while the components ship in the installed Specrew module (FileList), so
    # fall back to the module's scripts/internal/bootstrap. No 11-file duplication.
    $bdir = Join-Path $PSScriptRoot 'bootstrap'
    if (-not (Test-Path -LiteralPath $bdir)) {
        $mod = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending | Select-Object -First 1
        if ($mod) { $bdir = Join-Path $mod.ModuleBase 'scripts/internal/bootstrap' }
    }
    foreach ($f in 'HostEventAdapter', 'SessionStateAccessor', 'ProjectMetadataAccessor', 'HandoverStore', 'ClassificationEngine', 'ValidationEngine', 'DirectiveEngine', 'SessionBootstrapManager', 'LauncherIntegration') {
        . (Join-Path $bdir "$f.ps1")
    }

    # Launcher<->hook dedupe (FR-007, SC-002): if `specrew start` just bootstrapped this session,
    # stay silent so the startup yields exactly one bootstrap surface.
    $nowUtc = (Get-Date).ToUniversalTime().ToString('o')
    if (Test-SpecrewLauncherBootstrapRecent -ProjectRoot $root -NowUtc $nowUtc) { exit 0 }

    $journalPath = Join-Path $root '.specrew/runtime/bootstrap-journal.jsonl'
    $result = Invoke-SpecrewSessionBootstrap -RawEvent $eventJson -HostName claude -ProjectRoot $root -BaseBranch 'main' -JournalPath $journalPath

    Write-Output (Format-BootstrapDirective -Result $result)
    exit 0
}
catch {
    [Console]::Error.WriteLine("[specrew-bootstrap] WARN PROVIDER_FAILED $($_.Exception.Message)")
    exit 0
}
