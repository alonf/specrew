$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 Iteration 005 / T039 (FR-050 + FR-053 + FR-051): the doctor/status AGGREGATOR.
#
# WHY THIS FILE EXISTS: the three Beta2 host-integration truths a maintainer needs at a glance are produced by
# three separate leaf modules -
#   * the host+surface support TIERS      (host-support-tier.ps1  -> Format-SpecrewHostSupportTierReport)
#   * the hook-health EVIDENCE            (hook-health-receipt.ps1 -> Format-SpecrewHookHealthReport)
#   * the Codex untrusted-headless PREFLIGHT (hook-health-receipt.ps1 -> Test-SpecrewCodexHeadlessGovernanceReady)
# This module is the ONE narrow seam that stitches all three into a single doctor/status STRING, so a surface
# (see below) adds ONE call instead of wiring three renderers + a preflight and formatting the preflight itself.
#
# F-184 FOOTPRINT: NONE. This is a NEW, non-protected leaf module. It exists PRECISELY so the protected doctor
# surface (scripts/specrew-hooks.ps1) never has to be edited to gain three renderers: that protected file can, at
# the maintainer's discretion, add exactly ONE dot-source + ONE call (documented at the bottom of this file) and
# render everything. It is ALSO directly callable by any non-protected status path. Pure string building + the
# read-only resolvers of its two siblings; it NEVER writes a receipt, a config, or ~/.codex.
#
# HONESTY (NFR-001): this aggregator only FORMATS what its siblings return - it can never upgrade a tier or a
# health status. A missing/stale/malformed receipt stays unverified/degraded; an unknown host/surface stays
# unverified; the Codex preflight stays NOT-ready without a current receipt. There is no health-washing seam here.
#
# FAIL-OPEN: a doctor report must never throw. If a sibling renderer is unavailable (module not loaded) the
# corresponding section degrades to a single honest note rather than crashing the status surface.

# Best-effort load of the two sibling leaf modules so this aggregator is DROP-IN for a surface that has not
# already dot-sourced them (e.g. the protected specrew-hooks.ps1). Fail-open: a resolve/dot-source failure just
# leaves the corresponding Get-Command guard false, and that section degrades to a note.
foreach ($sibling in @('host-support-tier.ps1', 'hook-health-receipt.ps1')) {
    try {
        $siblingPath = Join-Path $PSScriptRoot $sibling
        if (Test-Path -LiteralPath $siblingPath -PathType Leaf) { . $siblingPath }
    }
    catch { $null = $_ }
}

function Format-SpecrewCodexHeadlessReadinessReport {
    # Render the Codex untrusted-headless governance PREFLIGHT (FR-051) as a doctor/status STRING. Consults the
    # read-only Test-SpecrewCodexHeadlessGovernanceReady (which NEVER writes ~/.codex). Returns a STRING; never
    # throws. NEVER reports ready on a missing/stale/malformed/drifted receipt - it renders exactly what the
    # preflight returned (no ready-washing).
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][string]$ExpectedHostVersion,
        [AllowNull()][datetime]$Now
    )
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('=== Codex untrusted-headless governance preflight (FR-051) ===')
    if (-not (Get-Command -Name 'Test-SpecrewCodexHeadlessGovernanceReady' -ErrorAction SilentlyContinue)) {
        [void]$sb.AppendLine('  (unavailable: hook-health-receipt module not loaded)')
        return $sb.ToString()
    }
    try {
        $preArgs = @{ ProjectRoot = $ProjectRoot }
        if ($PSBoundParameters.ContainsKey('ExpectedHostVersion') -and -not [string]::IsNullOrWhiteSpace($ExpectedHostVersion)) { $preArgs.ExpectedHostVersion = $ExpectedHostVersion }
        if ($PSBoundParameters.ContainsKey('Now')) { $preArgs.Now = $Now }
        $pre = Test-SpecrewCodexHeadlessGovernanceReady @preArgs
        [void]$sb.AppendLine(('  codex/cli ready to govern a headless run: {0}  (hook-health status: {1})' -f $(if ($pre.ready) { 'YES' } else { 'NO' }), $pre.status))
        [void]$sb.AppendLine(('  reason:      {0}' -f $pre.reason))
        [void]$sb.AppendLine(('  next step:   {0}' -f $pre.instruction))
    }
    catch {
        [void]$sb.AppendLine(('  (preflight error, treated as NOT ready: {0})' -f $_.Exception.Message))
    }
    return $sb.ToString()
}

function Format-SpecrewHostSupportDoctorReport {
    # THE aggregator: one doctor/status STRING = host-support tiers + hook-health evidence + the Codex headless
    # preflight, in that order, each separated by a blank line. Given a ProjectRoot it resolves live hook-health;
    # -Hosts narrows the health rows (default: the CLI-first gated hosts). Never throws (fail-open per section).
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [string[]]$Hosts,
        [AllowNull()][datetime]$Now
    )
    $sections = New-Object System.Collections.Generic.List[string]

    # 1. host+surface support tiers (FR-050).
    if (Get-Command -Name 'Format-SpecrewHostSupportTierReport' -ErrorAction SilentlyContinue) {
        try { $sections.Add((Format-SpecrewHostSupportTierReport).TrimEnd()) | Out-Null }
        catch { $sections.Add('=== Specrew Beta2 host-support tiers ===' + [Environment]::NewLine + ('  (unavailable: {0})' -f $_.Exception.Message)) | Out-Null }
    }
    else {
        $sections.Add('=== Specrew Beta2 host-support tiers ===' + [Environment]::NewLine + '  (unavailable: host-support-tier module not loaded)') | Out-Null
    }

    # 2. hook-health evidence (FR-053).
    if (Get-Command -Name 'Format-SpecrewHookHealthReport' -ErrorAction SilentlyContinue) {
        try {
            $healthArgs = @{ ProjectRoot = $ProjectRoot }
            if ($null -ne $Hosts -and @($Hosts).Count -gt 0) { $healthArgs.Hosts = @($Hosts) }
            if ($PSBoundParameters.ContainsKey('Now')) { $healthArgs.Now = $Now }
            $sections.Add((Format-SpecrewHookHealthReport @healthArgs).TrimEnd()) | Out-Null
        }
        catch { $sections.Add('=== Specrew hook-health evidence (FR-053) ===' + [Environment]::NewLine + ('  (unavailable: {0})' -f $_.Exception.Message)) | Out-Null }
    }
    else {
        $sections.Add('=== Specrew hook-health evidence (FR-053) ===' + [Environment]::NewLine + '  (unavailable: hook-health-receipt module not loaded)') | Out-Null
    }

    # 3. Codex untrusted-headless preflight (FR-051).
    $preflightArgs = @{ ProjectRoot = $ProjectRoot }
    if ($PSBoundParameters.ContainsKey('Now')) { $preflightArgs.Now = $Now }
    $sections.Add((Format-SpecrewCodexHeadlessReadinessReport @preflightArgs).TrimEnd()) | Out-Null

    return (($sections -join ([Environment]::NewLine + [Environment]::NewLine)) + [Environment]::NewLine)
}

# ------------------------------------------------------------------------------------------------------------
# PRODUCTION SURFACING (F-198 iter-005 finding 4 - RESOLVED). This aggregator is WIRED into a real user command:
#
#     specrew hooks doctor
#
# routed by the non-protected CLI dispatcher (scripts/specrew.ps1, `hooks` arm) to the non-protected script
# scripts/specrew-hooks-doctor.ps1, which dot-sources THIS module and calls Format-SpecrewHostSupportDoctorReport.
# That seam was chosen because the natural home (`specrew hooks status` in scripts/specrew-hooks.ps1) and the
# hook inspector (scripts/internal/specrew-hook-health.ps1) are BOTH F-184-protected surfaces (enforced by
# tests/continuous-co-review/governance/protected-surface-guard.Tests.ps1), so editing them for surfacing was not
# authorized. `specrew hooks doctor` reaches this render WITHOUT touching any protected file. The command path is
# covered end-to-end by tests/integration/f198-iter005-hook-health-production-path.tests.ps1.
#
# Any OTHER non-protected status path may surface the same report with a single self-contained call (this module
# loads its own two siblings fail-open):
#   . (Join-Path $PSScriptRoot 'internal/continuous-co-review/host-support-doctor.ps1')
#   Write-Host (Format-SpecrewHostSupportDoctorReport -ProjectRoot $projectPath)
# ------------------------------------------------------------------------------------------------------------
