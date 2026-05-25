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

    # Spec-kit + Squad coupling
    SpeckitAiFlag  = 'claude'
    PreferredAgent = 'claude'

    # Phase B handler file (not yet present)
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'
}
