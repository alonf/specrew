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
    # documented hook surface and binds all three triggers. Consumed by
    # scripts/internal/deploy-refocus-hooks.ps1; deploys to the PER-USER
    # project-local settings file (C6 decision: never the shared settings.json,
    # so cloning a repo can never import auto-executing hooks).
    # NOTE: PreToolUse is deliberately ABSENT — the gate seat is dormant until
    # the first gate-kind provider row exists (F-165 coordination).
    RefocusHookBindings = @{
        BoundTriggers       = @('b1', 'b2', 'b3')
        Events              = @('SessionStart', 'PostToolUse')
        PostToolUseMatcher  = 'Bash'   # P4 narrowing: shell tools only
        SettingsFile        = '.claude/settings.local.json'
        DispatcherPath      = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
    }
}
