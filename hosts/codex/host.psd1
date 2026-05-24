@{
    # Identity
    Kind          = 'codex'
    DisplayName   = 'OpenAI Codex CLI'
    Status        = 'supported'
    SchemaVersion = 1

    # Binary detection
    Binary           = 'codex'
    InstallUrl       = 'https://developers.openai.com/codex/cli'
    InstallGuidance  = 'Codex CLI not found on PATH. Install: https://developers.openai.com/codex/cli'

    # Runtime layout
    SkillRoot                  = '.agents/skills'
    HasUserSlashCommandSurface = $false   # FR-013: Codex has no user-defined slash-command surface
    SharedSkillRootWith        = @('antigravity')
    AgentDir                   = '.codex/agents/'
    InstructionsFile           = 'AGENTS.md'

    # Spec-kit + Squad coupling
    SpeckitAiFlag  = 'codex'
    PreferredAgent = 'codex'

    # Phase B handler file (not yet present)
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'
}
