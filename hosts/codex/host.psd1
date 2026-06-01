@{
    # Identity
    Kind          = 'codex'
    DisplayName   = 'OpenAI Codex CLI'
    Status        = 'supported'
    SchemaVersion = 1
    MenuPriority  = 2  # Interactive host-selection menu priority (iter-011)

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
    StructuredQuestionPrimitive = 'request_user_input'
    StructuredQuestionGuidance  = 'Use the Codex structured user-input/menu primitive for human approval gates when it is available in the current session.'

    # Spec-kit + Squad coupling
    SpeckitAiFlag  = 'codex'
    PreferredAgent = 'codex'

    # Phase B handler file (not yet present)
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'
}
