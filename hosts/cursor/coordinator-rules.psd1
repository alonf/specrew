@{
    # Per-host coordinator-prompt surgery rules for Cursor (F-050).
    # Cursor mirrors CODEX: it has NO user-defined slash-command surface
    # (HasUserSlashCommandSurface = $false), so in addition to stripping Squad-runtime-path
    # directives (FR-012), the slash-command boundary-advance references are rewritten to
    # pwsh-form (FR-014) because /speckit.* commands are not invokable in Cursor.
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
        },
        @{
            Kind        = 'Replace'
            Description = 'FR-014: slash-command boundary-advance → pwsh-form (Cursor has no slash surface)'
            Pattern     = '/speckit\.specrew-speckit\.sync-([a-z\-]+)'
            Replacement = 'pwsh -File .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 -BoundaryType $1'
        }
    )
}
