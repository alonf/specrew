# Host detection helpers for Specrew multi-host launch path (F-040)
#
# Provides:
#   - Get-SpecrewSupportedHostKinds : canonical host kind list (copilot, claude, codex)
#   - Get-SpecrewDeferredHostKinds  : reserved-but-deferred kinds (antigravity, auto)
#   - Test-SpecrewHostAvailable     : PATH probe for a single host
#   - Get-SpecrewAvailableHosts     : parallel probe across all supported hosts
#   - Get-SpecrewHostBinary         : binary name for a given host kind
#   - Get-SpecrewHostInstallGuidance : actionable install URL/instructions per host
#   - Test-HostSkillRoot            : verify per-host skill directory presence + frontmatter
#
# Per F-040 research.md Task 3 (host validation flow) + Task 5 (capability matrix).

Set-StrictMode -Version Latest

# Phase D (Open-Closed cleanup, 2026-05-24): per-host lookups now derive from the
# hosts/<kind>/host.psd1 manifests via hosts/_registry.ps1. The previous switch arms
# duplicated manifest data and broke the architecture's "zero hardcoded host enums"
# promise. Function signatures preserved for backwards-compat — bodies are now
# manifest-driven so adding hosts/<new-kind>/ extends behavior with no edits here.

$script:RegistryPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'hosts\_registry.ps1'
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    # Module-mode lookup
    $script:RegistryPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'hosts\_registry.ps1'
}
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    throw "Host registry not found. Searched: $script:RegistryPath"
}
. $script:RegistryPath

function Get-SpecrewSupportedHostKinds {
    <#
    .SYNOPSIS
    Returns the canonical list of supported host kinds — registry-driven.
    Adding hosts/<new-kind>/host.psd1 with Status='supported' extends this set.
    #>
    return @(Get-SpecrewHostsByStatus -Status supported)
}

function Get-SpecrewDeferredHostKinds {
    <#
    .SYNOPSIS
    Returns the canonical list of deferred-but-reserved host kinds.
    Includes both Status='deferred' entries from manifests AND 'auto' (synthetic,
    no manifest — represents the future auto-selection mode of Proposal 104).
    #>
    $deferredFromManifests = @(Get-SpecrewHostsByStatus -Status deferred)
    return @($deferredFromManifests + @('auto'))
}

function Get-SpecrewHostBinary {
    <#
    .SYNOPSIS
    Returns the binary name for a host kind, read from the manifest.
    #>
    param([Parameter(Mandatory = $true)][string]$HostKind)
    $manifest = Get-HostManifest -Kind $HostKind
    return [string]$manifest.Binary
}

function Get-SpecrewHostSkillRoot {
    <#
    .SYNOPSIS
    Returns the absolute per-host skill root path. Manifest declares the relative path;
    this function joins with the project root and normalizes separators.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$HostKind,
        [Parameter(Mandatory = $true)][string]$ProjectPath
    )
    $manifest = Get-HostManifest -Kind $HostKind
    $relative = ([string]$manifest.SkillRoot) -replace '/', [System.IO.Path]::DirectorySeparatorChar
    return (Join-Path $ProjectPath $relative)
}

function Get-SpecrewHostInstallGuidance {
    <#
    .SYNOPSIS
    Returns user-facing install guidance for a host. Prefers manifest InstallGuidance
    (richer prose, may include install scripts); falls back to a generic format using
    Binary + InstallUrl from the manifest.
    #>
    param([Parameter(Mandatory = $true)][string]$HostKind)
    $manifest = Get-HostManifest -Kind $HostKind
    if ($manifest.PSObject -and $manifest.ContainsKey('InstallGuidance') -and -not [string]::IsNullOrWhiteSpace([string]$manifest.InstallGuidance)) {
        return [string]$manifest.InstallGuidance
    }
    # Fallback construction
    return ("{0} not found on PATH. Install: {1}" -f $manifest.DisplayName, $manifest.InstallUrl)
}

function Get-SpecrewDeferredHostGuidance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostKind
    )

    switch ($HostKind.ToLowerInvariant()) {
        'auto' {
            return @(
                'Auto-selection is deferred to Proposal 104 (Multi-Host Onboarding + Selection Flow).',
                'Use --host copilot|claude|codex|antigravity explicitly until F-043 ships.',
                'See file:///C:/Dev/Specrew/proposals/104-multi-host-onboarding-and-selection-flow.md.'
            ) -join ' '
        }
        default {
            throw "Unsupported deferred-host kind '$HostKind'."
        }
    }
}

function Test-AntigravityGeminiDeadlineWarning {
    <#
    .SYNOPSIS
    Determine whether to emit a 2026-06-18 Gemini free-tier deadline warning.

    .DESCRIPTION
    Per Antigravity follow-up slice FR-009: warning fires when --host antigravity
    is invoked AND current date is on or after 2026-06-01 (two weeks before
    deadline) AND no Google AI Pro/Ultra subscription evidence is configured.

    .OUTPUTS
    PSCustomObject with ShouldWarn (bool) + Message (string or null).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [DateTime]$CurrentDate = [DateTime]::UtcNow
    )

    $deadlineDate = [DateTime]::Parse('2026-06-18', [System.Globalization.CultureInfo]::InvariantCulture)
    $warningStartDate = $deadlineDate.AddDays(-17)   # two weeks + 3-day buffer

    if ($CurrentDate -lt $warningStartDate) {
        return [pscustomobject]@{ ShouldWarn = $false; Message = $null }
    }

    # Check if user has configured Google AI Pro/Ultra subscription evidence
    # in .specrew/config.yml. Field name TBD; for now look for an env var.
    if (-not [string]::IsNullOrWhiteSpace($env:GOOGLE_AI_SUBSCRIPTION_TIER) -or
        -not [string]::IsNullOrWhiteSpace($env:ANTIGRAVITY_API_KEY)) {
        return [pscustomobject]@{ ShouldWarn = $false; Message = $null }
    }

    $daysUntil = ($deadlineDate - $CurrentDate.Date).Days
    $msg = if ($daysUntil -gt 0) {
        "Antigravity uses Google's Gemini infrastructure. The Gemini CLI free tier stops on 2026-06-18 ($daysUntil day$(if ($daysUntil -ne 1) { 's' }) from now). Configure Google AI Pro/Ultra subscription or set ANTIGRAVITY_API_KEY environment variable to continue using Antigravity after that date."
    } else {
        "Antigravity uses Google's Gemini infrastructure. The Gemini CLI free tier ended on 2026-06-18 ($([Math]::Abs($daysUntil)) day$(if ([Math]::Abs($daysUntil) -ne 1) { 's' }) ago). Configure Google AI Pro/Ultra subscription or set ANTIGRAVITY_API_KEY environment variable; you may have already hit usage limits."
    }

    return [pscustomobject]@{ ShouldWarn = $true; Message = $msg }
}

function Test-SpecrewHostAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostKind
    )

    $binary = Get-SpecrewHostBinary -HostKind $HostKind
    $cmd = Get-Command $binary -ErrorAction SilentlyContinue
    return ($null -ne $cmd)
}

function Get-SpecrewAvailableHosts {
    # Probe all supported hosts. Sequential is fine — Get-Command is cheap.
    # ForEach-Object -Parallel adds runspace overhead that dominates for 3 cheap probes.
    $result = [ordered]@{}
    foreach ($kind in (Get-SpecrewSupportedHostKinds)) {
        $result[$kind] = Test-SpecrewHostAvailable -HostKind $kind
    }
    return $result
}

function Test-HostSkillRoot {
    <#
    .SYNOPSIS
    Verifies per-host skill directory presence and parses each SKILL.md frontmatter.

    .DESCRIPTION
    Returns a result object with:
      - HostKind
      - SkillRoot (absolute path)
      - Exists (bool — directory present)
      - SkillFiles (array of detected SKILL.md / *.md skill files)
      - Warnings (array of human-readable strings naming missing/malformed surfaces)
      - HasUserSlashCommandSurface (bool — false for codex per FR-013)

    Codex skill verification is intentionally shallow: Codex has no user-defined
    slash-command surface per 2026-05-23 research, so the .agents/skills/*
    files are deployed for future-proof but NOT invokable. The function returns
    an informational warning rather than treating missing files as a problem.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostKind,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $skillRoot = Get-SpecrewHostSkillRoot -HostKind $HostKind -ProjectPath $ProjectPath
    $exists = Test-Path -LiteralPath $skillRoot -PathType Container
    $warnings = New-Object System.Collections.Generic.List[string]
    $skillFiles = @()
    # Manifest declares HasUserSlashCommandSurface — no hardcoded host-name check
    $manifest = Get-HostManifest -Kind $HostKind
    $hasUserSlashCommandSurface = [bool]$manifest.HasUserSlashCommandSurface
    $displayName = [string]$manifest.DisplayName

    if (-not $exists) {
        if ($hasUserSlashCommandSurface) {
            $warnings.Add("Skill directory missing: $skillRoot. Run 'specrew init' to redeploy skill catalog.") | Out-Null
        }
        else {
            $warnings.Add("Skill directory missing: $skillRoot. Note: $displayName does not invoke skills as slash commands; skill files are deployed for future-proof but NOT invokable.") | Out-Null
        }
    }
    else {
        # Copilot convention is *.md flat in .github/skills/; others (Claude/Codex/Antigravity)
        # use SKILL.md nested. Could be manifest-declared but heuristic-by-skill-root works today;
        # capture via manifest field SkillFilePattern in a follow-up if more hosts diverge.
        if (([string]$manifest.Kind) -eq 'copilot') {
            $skillFiles = Get-ChildItem -Path $skillRoot -Filter '*.md' -ErrorAction SilentlyContinue
        }
        else {
            $skillFiles = Get-ChildItem -Path $skillRoot -Filter 'SKILL.md' -Recurse -ErrorAction SilentlyContinue
        }

        if ((-not $skillFiles -or $skillFiles.Count -eq 0) -and $hasUserSlashCommandSurface) {
            $warnings.Add("Skill directory exists but contains no skill files: $skillRoot") | Out-Null
        }

        # Validate frontmatter on each skill file (minimal: file is non-empty + has --- delimiters)
        foreach ($file in $skillFiles) {
            $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($content)) {
                $warnings.Add("Skill file is empty: $($file.FullName)") | Out-Null
                continue
            }
            if (-not ($content -match '(?m)^---\s*$')) {
                $warnings.Add("Skill file missing YAML frontmatter delimiters: $($file.FullName)") | Out-Null
            }
        }
    }

    if (-not $hasUserSlashCommandSurface) {
        # FR-013: informational note for any host without a user-defined slash-command surface
        $warnings.Add(("INFO: {0} has no user-defined slash-command surface. Skill files are deployed for future-proof but not invokable as /specrew-* on this host." -f $displayName)) | Out-Null
    }

    return [pscustomobject]@{
        HostKind                     = $HostKind.ToLowerInvariant()
        SkillRoot                    = $skillRoot
        Exists                       = $exists
        SkillFiles                   = @($skillFiles)
        Warnings                     = $warnings.ToArray()
        HasUserSlashCommandSurface   = $hasUserSlashCommandSurface
    }
}
