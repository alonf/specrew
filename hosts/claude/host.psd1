@{
    # Identity
    Kind          = 'claude'
    DisplayName   = 'Claude Code CLI'
    Status        = 'supported'
    SchemaVersion = 1
    MenuPriority  = 1  # Highest priority in interactive host-selection menu (iter-011)

    # Binary detection
    Binary           = 'claude'
    InstallUrl       = 'https://docs.anthropic.com/en/docs/claude-code/installation'
    InstallGuidance  = 'Claude Code CLI not found on PATH. Install: https://docs.anthropic.com/en/docs/claude-code/installation'

    # Runtime layout
    SkillRoot                  = '.claude/skills'
    HasUserSlashCommandSurface = $true
    SettingsPath               = '.claude/settings.json'
    AgentDir                   = '.claude/agents/'
    InstructionsFile           = 'CLAUDE.md'
    StructuredQuestionPrimitive = 'AskUserQuestion'
    StructuredQuestionGuidance  = 'Use Claude Code AskUserQuestion for human approval gates when it is available in the current session.'

    # Spec-kit + Squad coupling
    SpeckitAiFlag  = 'claude'
    PreferredAgent = 'claude'

    # Phase B handler file (not yet present)
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'

    # Feature 171 (FR-013): refocus hook-binding declaration. Claude has the full
    # documented hook surface; it binds B1 + B2 via SessionStart (see BoundTriggers
    # below), and B3 is delivered via channel 1 (the boundary-sync wrapper stdout),
    # not a hook — so BoundTriggers is @('b1','b2') by design (TG-004a). Consumed by
    # scripts/internal/deploy-refocus-hooks.ps1; deploys to the PER-USER
    # project-local settings file (C6 decision: never the shared settings.json,
    # so cloning a repo can never import auto-executing hooks).
    # NOTE: PreToolUse is deliberately ABSENT — the gate seat is dormant until
    # the first gate-kind provider row exists (F-165 coordination).
    # NOTE: PostToolUse is UNREGISTERED per TG-004 option (a), approved at the
    # iteration-001 review-signoff (measured ~920ms/call vs the 150ms bar; pwsh
    # spawn structural). B3 rides channel 1 (boundary-sync wrapper stdout) on
    # every host; iteration 002 re-evaluates (UserPromptSubmit / engine inlining).
    RefocusHookBindings = @{
        BoundTriggers       = @('b1', 'b2')   # b3 via channel 1 (TG-004 option a)
        Events              = @('SessionStart')
        SettingsFile        = '.claude/settings.local.json'
        OptOutMarkerFile    = '.specrew/runtime/refocus-hooks-optout'
        DispatcherPath      = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
        ConfigShape         = 'event-map'
        CommandMode         = 'project-placeholder'
        ProjectDirPlaceholder = '${CLAUDE_PROJECT_DIR}'
        ProjectRootEnvironmentVariables = @('CLAUDE_PROJECT_DIR')
        Registrations       = @(
            @{ Event = 'SessionStart'; DispatcherEvent = 'SessionStart'; HandlerShape = 'hooks-array' },
            @{ Event = 'Stop'; DispatcherEvent = 'Stop'; HandlerShape = 'hooks-array' },
            @{ Event = 'PostToolUse'; DispatcherEvent = 'PostToolUse'; HandlerShape = 'hooks-array' }
        )
    }
}
