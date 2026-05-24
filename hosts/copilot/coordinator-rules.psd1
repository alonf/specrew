@{
    # Per-host coordinator-prompt surgery rules for Copilot.
    # Loaded + applied in declared order by Invoke-SpecrewCoordinatorPromptSurgery.
    #
    # Copilot retains all Squad-runtime-path directives (FR-012 excludes Copilot)
    # and continues to use slash-command boundary-advance forms (FR-014 only affects Codex).
    # So Copilot's only rule is the universal header rewrite, which the engine applies
    # to every host as a built-in baseline.
    Rules = @()
}
