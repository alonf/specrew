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

function Get-SpecrewSupportedHostKinds {
    return @('copilot', 'claude', 'codex', 'antigravity')
}

function Get-SpecrewDeferredHostKinds {
    return @('auto')
}

function Get-SpecrewHostBinary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostKind
    )

    switch ($HostKind.ToLowerInvariant()) {
        'copilot'     { return 'copilot' }
        'claude'      { return 'claude' }
        'codex'       { return 'codex' }
        'antigravity' { return 'agy' }
        default       {
            throw "Unsupported host kind '$HostKind'. Supported: $((Get-SpecrewSupportedHostKinds) -join ', ')."
        }
    }
}

function Get-SpecrewHostSkillRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostKind,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    switch ($HostKind.ToLowerInvariant()) {
        'copilot'     { return (Join-Path $ProjectPath '.github\skills') }
        'claude'      { return (Join-Path $ProjectPath '.claude\skills') }
        'codex'       { return (Join-Path $ProjectPath '.agents\skills') }
        'antigravity' { return (Join-Path $ProjectPath '.agents\skills') }   # Antigravity's native skill convention
        default       {
            throw "Unsupported host kind '$HostKind' for skill root lookup."
        }
    }
}

function Get-SpecrewHostInstallGuidance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostKind
    )

    switch ($HostKind.ToLowerInvariant()) {
        'copilot' {
            return 'GitHub Copilot CLI not found on PATH. Install: https://docs.github.com/en/copilot/how-tos/copilot-cli'
        }
        'claude' {
            return 'Claude Code CLI not found on PATH. Install: https://docs.anthropic.com/en/docs/claude-code/installation'
        }
        'codex' {
            return 'Codex CLI not found on PATH. Install: https://developers.openai.com/codex/cli'
        }
        'antigravity' {
            return 'Antigravity CLI (agy) not found on PATH. Install via: irm https://antigravity.google/cli/install.ps1 | iex (Windows) or curl -fsSL https://antigravity.google/cli/install.sh | bash (macOS/Linux). See: https://antigravity.google/'
        }
        default {
            throw "Unsupported host kind '$HostKind' for install guidance."
        }
    }
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
    $hasUserSlashCommandSurface = ($HostKind.ToLowerInvariant() -ne 'codex')

    if (-not $exists) {
        if ($hasUserSlashCommandSurface) {
            $warnings.Add("Skill directory missing: $skillRoot. Run 'specrew init' to redeploy skill catalog.") | Out-Null
        }
        else {
            # Codex: not a warning, just informational
            $warnings.Add("Skill directory missing: $skillRoot. Note: Codex does not invoke skills as slash commands; .agents/skills/* is future-proof only.") | Out-Null
        }
    }
    else {
        # Look for SKILL.md (Claude convention) or *.md (Copilot convention)
        switch ($HostKind.ToLowerInvariant()) {
            'claude' {
                $skillFiles = Get-ChildItem -Path $skillRoot -Filter 'SKILL.md' -Recurse -ErrorAction SilentlyContinue
            }
            'copilot' {
                $skillFiles = Get-ChildItem -Path $skillRoot -Filter '*.md' -ErrorAction SilentlyContinue
            }
            'codex' {
                $skillFiles = Get-ChildItem -Path $skillRoot -Filter 'SKILL.md' -Recurse -ErrorAction SilentlyContinue
            }
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
        # FR-013: informational note for Codex
        $warnings.Add('INFO: Codex CLI has no user-defined slash-command surface. Skill files are deployed for future-proof but not invokable as /specrew-* on Codex.') | Out-Null
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
