@{
    # Per-host coordinator-prompt surgery rules for Devin.
    # Loaded + applied in declared order by Invoke-SpecrewCoordinatorPromptSurgery
    # (after the engine's built-in universal header rewrite).
    #
    # Devin HAS a user-defined slash-command surface (HasUserSlashCommandSurface = $true),
    # so — like Claude — it needs NO slash-command -> pwsh rewrite (that Codex-only rule is
    # for hosts with no slash surface). Devin still strips the Squad-runtime-path directives
    # (Squad is not the Devin runtime), mirroring the Claude rule set.
    Rules = @(
        @{
            Kind        = 'Strip'
            Description = 'Squad-runtime-path directive — .squad/decisions.md reference'
            Pattern     = '(?m)^\s*\d+\.\s+.*\.squad[\\/]decisions\.md.*$'
        },
        @{
            Kind        = 'Strip'
            Description = 'Squad-runtime-path directive — agentModelOverrides reference'
            Pattern     = '(?m)^\s*\d+\.\s+.*agentModelOverrides.*$'
        },
        @{
            Kind        = 'Strip'
            Description = 'Squad-runtime-path directive — sync-squad-model-overrides.ps1 reference'
            Pattern     = '(?m)^\s*\d+\.\s+.*sync-squad-model-overrides\.ps1.*$'
        },
        @{
            Kind        = 'Strip'
            Description = 'Squad-runtime-path directive — .squad/config.json reference'
            Pattern     = '(?m)^\s*\d+\.\s+.*\.squad[\\/]config\.json.*$'
        }
    )
}
