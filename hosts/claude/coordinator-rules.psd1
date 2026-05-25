@{
    # Per-host coordinator-prompt surgery rules for Claude.
    # Loaded + applied in declared order by Invoke-SpecrewCoordinatorPromptSurgery
    # (after the engine's built-in universal header rewrite).
    Rules = @(
        @{
            Kind        = 'Strip'
            Description = 'FR-012: Squad-runtime-path directive — .squad/decisions.md reference'
            Pattern     = '(?m)^\s*\d+\.\s+.*\.squad[\\/]decisions\.md.*$'
        },
        @{
            Kind        = 'Strip'
            Description = 'FR-012: Squad-runtime-path directive — agentModelOverrides reference'
            Pattern     = '(?m)^\s*\d+\.\s+.*agentModelOverrides.*$'
        },
        @{
            Kind        = 'Strip'
            Description = 'FR-012: Squad-runtime-path directive — sync-squad-model-overrides.ps1 reference'
            Pattern     = '(?m)^\s*\d+\.\s+.*sync-squad-model-overrides\.ps1.*$'
        },
        @{
            Kind        = 'Strip'
            Description = 'FR-012: Squad-runtime-path directive — .squad/config.json reference'
            Pattern     = '(?m)^\s*\d+\.\s+.*\.squad[\\/]config\.json.*$'
        }
    )
}
