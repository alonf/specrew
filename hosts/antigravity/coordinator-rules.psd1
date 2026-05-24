@{
    # Per-host coordinator-prompt surgery rules for Antigravity.
    # Same shape as Claude — strips Squad-runtime-path directives (Antigravity is non-Copilot).
    # FR-014 pwsh-form is Codex-specific; Antigravity has a slash-command surface so the legacy
    # /speckit.* references remain intact.
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
