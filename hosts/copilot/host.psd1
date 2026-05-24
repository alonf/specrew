@{
    # Identity
    Kind          = 'copilot'
    DisplayName   = 'GitHub Copilot CLI'
    Status        = 'supported'
    SchemaVersion = 1

    # Binary detection
    Binary           = 'copilot'
    InstallUrl       = 'https://docs.github.com/en/copilot/how-tos/copilot-cli'
    InstallGuidance  = 'GitHub Copilot CLI not found on PATH. Install: https://docs.github.com/en/copilot/how-tos/copilot-cli'

    # Runtime layout
    SkillRoot                  = '.github/skills'
    LegacySkillRoots           = @('.copilot/skills')
    HasUserSlashCommandSurface = $true
    InstructionsFile           = '.github/copilot-instructions.md'

    # Spec-kit + Squad coupling
    SpeckitAiFlag  = 'copilot'
    PreferredAgent = 'copilot'

    # Phase B handler file (not yet present)
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'
}
