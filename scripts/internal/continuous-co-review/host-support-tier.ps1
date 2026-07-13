$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 Iteration 005 / T035 (FR-050): the truthful host+surface support-tier model.
#
# Beta2 is CLI-FIRST. The CLI is the AUTHORITATIVE supported surface; cloud agents and
# cloud-gated development are UNSUPPORTED. This file is the ONE place a host+surface support
# CLAIM is recorded (DATA), plus a pure lookup and a renderer for the doctor/status surface.
# Adding or changing a support claim is a ROW edit here - never a scattered doc assertion.
#
# CLOSED SET (exactly one classification per host+surface):
#   verified                  - exercised end-to-end on that surface (a real conformance probe passed).
#   configuration-compatible  - documented SHARED configuration with a verified surface; the lifecycle is
#                               NOT independently exercised on this surface (so it is not `verified`).
#   unsupported               - no reliable gated integration; MUST NOT be implied to be governed.
#   unverified                - intended support exists but the conformance probe has NOT passed
#                               (the honest default for anything not proven - NEVER a fabricated `verified`).
#
# HONESTY (NFR-001/NFR-006): a tier is a CLAIM about evidence, never file presence. `verified` is reserved
# for a surface whose Stop/SessionStart contract has been exercised end-to-end. Codex CLI and Copilot CLI are
# GATED surfaces whose Stop-contract conformance probes (FR-051/T036, FR-052/T037) have not yet passed, so they
# are `unverified` here and flip to `verified` only when those probes land - seeding them `verified` now would
# be exactly the false-green this feature exists to prevent. An unknown host/surface resolves to `unverified`.
#
# Richer desktop / IDE / cloud certification (host capability negotiation, multi-version + desktop/IDE
# certification) is the Beta3 modernization tracked in GitHub issue #3084 - OUT OF SCOPE for Beta2.

$script:SpecrewHostSupportTierSet = @(
    'verified'
    'configuration-compatible'
    'unsupported'
    'unverified'
)

# Beta3 follow-up reference (public GitHub issue - safe to surface; NOT a Specrew-internal identifier).
$script:SpecrewHostSupportBeta3Issue = 'https://github.com/alonf/specrew/issues/3084'

function Get-SpecrewHostSupportTierSet {
    # The closed classification set (the ONLY four tiers any host+surface may carry).
    return @($script:SpecrewHostSupportTierSet)
}

function Test-SpecrewHostSupportTierValue {
    # Is $Tier a member of the closed set? (Structural guard - used to reject a fabricated tier.)
    param([AllowNull()][string] $Tier)
    if ([string]::IsNullOrWhiteSpace($Tier)) { return $false }
    return @($script:SpecrewHostSupportTierSet) -contains $Tier
}

function ConvertTo-SpecrewHostSupportHostKey {
    # Normalize a host name to its canonical key (lowercase; a few documented aliases).
    param([AllowNull()][string] $HostName)
    if ([string]::IsNullOrWhiteSpace($HostName)) { return '' }
    $needle = $HostName.Trim().ToLowerInvariant()
    switch ($needle) {
        'claude-code'    { return 'claude' }
        'claude-cli'     { return 'claude' }
        'github-copilot' { return 'copilot' }
        'copilot-cli'    { return 'copilot' }
        'codex-cli'      { return 'codex' }
        'cursor-agent'   { return 'cursor' }
        default          { return $needle }
    }
}

function ConvertTo-SpecrewHostSupportSurfaceKey {
    # Normalize a surface name to its canonical key. Surfaces: cli | vscode | ide | desktop | cloud.
    param([AllowNull()][string] $Surface)
    if ([string]::IsNullOrWhiteSpace($Surface)) { return '' }
    $needle = ($Surface.Trim().ToLowerInvariant() -replace '\s+', '-')
    switch ($needle) {
        'vs-code'           { return 'vscode' }
        'code'              { return 'vscode' }
        'vscode-extension'  { return 'vscode' }
        'editor'            { return 'vscode' }
        'extension'         { return 'vscode' }
        'app'               { return 'desktop' }
        'cloud-agent'       { return 'cloud' }
        'cloud-agents'      { return 'cloud' }
        'web'               { return 'cloud' }
        default             { return $needle }
    }
}

function Get-SpecrewHostSupportTierRows {
    # The canonical host+surface support claims (DATA). Each row carries EXACTLY ONE tier from the closed set
    # plus a one-line consumer-legible rationale. This is the seed per the maintainer ruling (F-198 iter-005):
    #   * CLI is the authoritative supported surface (claude/codex/copilot CLI are the gated surfaces).
    #   * claude VS Code + codex IDE/desktop = configuration-compatible (shared config; lifecycle not exercised).
    #   * copilot VS Code = unsupported for CLI Stop-hook enforcement (its CLI hooks are a DIFFERENT surface;
    #     it MUST NOT claim hook-gated CLI compatibility).
    #   * cursor desktop = unverified.
    #   * cloud = unsupported (categorical; handled in the lookup for EVERY host, plus this display row).
    $rows = @(
        [pscustomobject][ordered]@{ host = 'claude'; surface = 'cli'; tier = 'verified'
            rationale = 'CLI Stop/SessionStart hook contract exercised end-to-end; the authoritative gated surface.' }
        [pscustomobject][ordered]@{ host = 'claude'; surface = 'vscode'; tier = 'configuration-compatible'
            rationale = 'Shares Claude settings/hooks with the CLI; the lifecycle is not independently exercised here.' }
        [pscustomobject][ordered]@{ host = 'codex'; surface = 'cli'; tier = 'unverified'
            rationale = 'Gated surface, but its CLI Stop-contract conformance probe has not yet passed (not proven end-to-end).' }
        [pscustomobject][ordered]@{ host = 'codex'; surface = 'ide'; tier = 'configuration-compatible'
            rationale = 'Shares Codex config layers with the CLI; the lifecycle is not independently exercised here.' }
        [pscustomobject][ordered]@{ host = 'codex'; surface = 'desktop'; tier = 'configuration-compatible'
            rationale = 'Shares Codex config layers with the CLI; the lifecycle is not independently exercised here.' }
        [pscustomobject][ordered]@{ host = 'copilot'; surface = 'cli'; tier = 'unverified'
            rationale = 'Gated surface, but its CLI hook-discovery / agentStop conformance probe has not yet passed.' }
        [pscustomobject][ordered]@{ host = 'copilot'; surface = 'vscode'; tier = 'unsupported'
            rationale = 'Does NOT receive CLI Stop-hook enforcement; its CLI hooks are a different surface - no reliable gated integration.' }
        [pscustomobject][ordered]@{ host = 'cursor'; surface = 'desktop'; tier = 'unverified'
            rationale = 'Intended support exists but no conformance probe has passed.' }
        [pscustomobject][ordered]@{ host = '(any)'; surface = 'cloud'; tier = 'unsupported'
            rationale = 'Beta2 is CLI-first; no cloud-agent Stop-hook enforcement or governance. Richer certification is Beta3 (issue #3084).' }
    )

    # Structural closed-set guard: a row carrying a tier outside the closed set is a build-time error, so a
    # fabricated tier can never enter the model (NFR-001 - no false-green, enforced at the data seam).
    foreach ($row in $rows) {
        if (-not (Test-SpecrewHostSupportTierValue -Tier $row.tier)) {
            throw "Host-support-tier row for $($row.host)/$($row.surface) uses an invalid tier '$($row.tier)'. Allowed: $((Get-SpecrewHostSupportTierSet) -join ', ')."
        }
    }
    return $rows
}

function Get-SpecrewHostSupportTier {
    # PURE lookup: given a host + surface, return its tier + one-line rationale.
    #   * cloud (any host) -> `unsupported`, categorically (NO cloud-agent support may be implied).
    #   * a seeded host+surface -> its recorded tier.
    #   * anything else -> `unverified` (NEVER a fabricated `verified`).
    # Returns @{ host; surface; tier; rationale; known }. `known` = the pair was in the seeded model.
    param(
        [Parameter(Mandatory)][string] $HostName,
        [Parameter(Mandatory)][string] $Surface
    )
    $hostKey = ConvertTo-SpecrewHostSupportHostKey -HostName $HostName
    $surfaceKey = ConvertTo-SpecrewHostSupportSurfaceKey -Surface $Surface

    # Cloud is categorically unsupported for EVERY host (known or unknown) - the ruling admits no cloud support.
    if ($surfaceKey -eq 'cloud') {
        return [pscustomobject][ordered]@{
            host      = $hostKey
            surface   = 'cloud'
            tier      = 'unsupported'
            rationale = 'Beta2 is CLI-first; no cloud-agent Stop-hook enforcement or governance. Richer certification is Beta3 (issue #3084).'
            known     = $true
        }
    }

    $match = @(Get-SpecrewHostSupportTierRows) |
        Where-Object { $_.host -eq $hostKey -and $_.surface -eq $surfaceKey } |
        Select-Object -First 1

    if ($null -ne $match) {
        return [pscustomobject][ordered]@{
            host      = $match.host
            surface   = $match.surface
            tier      = $match.tier
            rationale = $match.rationale
            known     = $true
        }
    }

    # Unknown host/surface: fail-honest to `unverified`. Support is never ASSUMED - only a passed probe earns
    # `verified`, and only a recorded shared-config claim earns `configuration-compatible`.
    return [pscustomobject][ordered]@{
        host      = $hostKey
        surface   = $surfaceKey
        tier      = 'unverified'
        rationale = 'No support claim on record for this host/surface; unverified until a conformance probe passes (never assume verified).'
        known     = $false
    }
}

function Format-SpecrewHostSupportTierReport {
    # Renderer for the doctor/status surface: a deterministic, aligned host+surface -> tier table with a
    # tier legend and the Beta2/Beta3 framing. Returns a STRING (testable; no direct console writes here).
    param(
        [object[]] $Rows
    )
    $data = if ($null -ne $Rows -and @($Rows).Count -gt 0) { @($Rows) } else { @(Get-SpecrewHostSupportTierRows) }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('=== Specrew Beta2 host-support tiers ===')
    [void]$sb.AppendLine('CLI is the AUTHORITATIVE supported surface. Cloud agents are UNSUPPORTED in Beta2.')
    [void]$sb.AppendLine('Richer desktop / IDE / cloud certification is tracked in issue #3084 (Beta3).')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(('  {0,-9} {1,-9} {2,-25} {3}' -f 'HOST', 'SURFACE', 'TIER', 'RATIONALE'))
    [void]$sb.AppendLine(('  {0,-9} {1,-9} {2,-25} {3}' -f '----', '-------', '----', '---------'))
    foreach ($row in $data) {
        [void]$sb.AppendLine(('  {0,-9} {1,-9} {2,-25} {3}' -f $row.host, $row.surface, $row.tier, $row.rationale))
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Tiers:')
    [void]$sb.AppendLine('  verified                  - exercised end-to-end on that surface (a real conformance probe passed)')
    [void]$sb.AppendLine('  configuration-compatible  - documented shared configuration; lifecycle NOT independently exercised')
    [void]$sb.AppendLine('  unsupported               - no reliable gated integration (never implied to be governed)')
    [void]$sb.AppendLine('  unverified                - intended support exists but the conformance probe has not passed')
    return $sb.ToString()
}
