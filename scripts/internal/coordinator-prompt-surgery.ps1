# Coordinator-prompt surgery for Specrew multi-host launch path (F-040)
#
# Implements FR-011 (universal header rewrite for ALL hosts) and FR-012
# (Squad-runtime-path directive strip for non-Copilot hosts only) plus FR-014
# (Codex pwsh-form boundary-advance instructions). Documented in
# specs/040-multi-host-launch-path/spec.md.
#
# Two functions:
#   - Get-SpecrewUniversalCoordinatorHeader : the unified header line
#   - Invoke-SpecrewCoordinatorPromptSurgery : applies header rewrite + (for
#     non-Copilot hosts) strips Squad-runtime-path directives + (for Codex)
#     rewrites slash-command boundary-advance references as pwsh-form
#
# The original Squad header ("You are Squad running inside a
# Specrew-bootstrapped repository.") is replaced uniformly across all hosts
# with the Crew-coordinator framing.

Set-StrictMode -Version Latest

function Get-SpecrewUniversalCoordinatorHeader {
    return 'You are the Crew team coordinator running inside a Specrew-bootstrapped repository.'
}

function Get-SpecrewOriginalCoordinatorHeaderPattern {
    # Matches both common spellings in case prior prompts varied
    return '(?m)^You are Squad running inside a Specrew-bootstrapped repository\.'
}

function Get-SpecrewSquadRuntimePathDirectivePatterns {
    # Lines/paragraphs to strip for non-Copilot hosts. Each entry is a regex
    # that matches a full line (anchored multiline). Conservative — only removes
    # lines that clearly reference Squad-runtime paths.
    return @(
        # Rule 12: .squad\decisions.md skip rationale (a numbered list item that mentions .squad/decisions.md)
        '(?m)^\s*\d+\.\s+.*\.squad[\\/]decisions\.md.*$',
        # Rule 35: agentModelOverrides directive
        '(?m)^\s*\d+\.\s+.*agentModelOverrides.*$',
        # Rule 37: sync-squad-model-overrides.ps1 directive
        '(?m)^\s*\d+\.\s+.*sync-squad-model-overrides\.ps1.*$',
        # Rules 42-44: .squad/config.json directives
        '(?m)^\s*\d+\.\s+.*\.squad[\\/]config\.json.*$'
    )
}

function Get-SpecrewSlashCommandToPwshFormMap {
    # For Codex hosts: replace slash-command boundary-advance references with
    # pwsh-form invocations (FR-014). The slash commands don't exist on Codex
    # because Codex has no user-defined slash-command surface.
    #
    # Map shape: array of regex / replacement pairs applied in order.
    return @(
        @{
            Pattern     = '/speckit\.specrew-speckit\.sync-([a-z\-]+)'
            Replacement = 'pwsh -File .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 -BoundaryType $1'
        }
    )
}

function Invoke-SpecrewCoordinatorPromptSurgery {
    <#
    .SYNOPSIS
    Applies multi-host coordinator-prompt surgery per FR-011 / FR-012 / FR-014.

    .DESCRIPTION
    Three surgeries applied in order:
      1. Universal header rewrite (ALL hosts): replace the Squad-flavored
         opening line with the Crew-coordinator framing per FR-011.
      2. Squad-runtime-path directive strip (non-Copilot hosts only): remove
         numbered directives that reference .squad/decisions.md,
         .squad/config.json, agentModelOverrides, sync-squad-model-overrides.ps1
         per FR-012.
      3. Slash-command to pwsh-form rewrite (Codex only): replace
         /speckit.specrew-speckit.sync-<boundary> references with
         "pwsh -File .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1
         -BoundaryType <boundary>" per FR-014.

    Returns the rewritten prompt body.

    .PARAMETER Prompt
    The prompt body to surgically rewrite.

    .PARAMETER Host
    The selected host (copilot, claude, codex).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter(Mandatory = $true)]
        [ValidateSet('copilot', 'claude', 'codex')]
        [string]$HostKind
    )

    if ([string]::IsNullOrEmpty($Prompt)) {
        return $Prompt
    }

    $hostLower = $HostKind.ToLowerInvariant()
    $result = $Prompt

    # Surgery 1: universal header rewrite (FR-011) — applies to ALL hosts
    $headerPattern = Get-SpecrewOriginalCoordinatorHeaderPattern
    $newHeader = Get-SpecrewUniversalCoordinatorHeader
    $result = [regex]::Replace($result, $headerPattern, $newHeader)

    # Surgery 2: Squad-runtime-path directive strip (FR-012) — non-Copilot only
    if ($hostLower -ne 'copilot') {
        foreach ($pattern in (Get-SpecrewSquadRuntimePathDirectivePatterns)) {
            $result = [regex]::Replace($result, $pattern, '')
        }
        # Tidy: collapse 3+ blank lines down to 2 to avoid huge gaps where rules were
        $result = [regex]::Replace($result, '(?m)(^\s*$\r?\n){3,}', "`r`n`r`n")
    }

    # Surgery 3: slash-command to pwsh-form (FR-014) — Codex only
    if ($hostLower -eq 'codex') {
        foreach ($map in (Get-SpecrewSlashCommandToPwshFormMap)) {
            $result = [regex]::Replace($result, $map.Pattern, $map.Replacement)
        }
    }

    return $result
}
