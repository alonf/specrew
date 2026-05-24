@{
    # Identity
    Kind          = 'antigravity'
    DisplayName   = 'Google Antigravity CLI'
    Status        = 'supported'      # Promoted from deferred via antigravity-followup slice
    SchemaVersion = 1

    # Binary detection
    Binary         = 'agy'
    BinaryAliases  = @()             # agy is the only binary name (Antigravity is the brand)
    InstallUrl     = 'https://antigravity.google/'

    # Runtime layout
    SkillRoot                  = '.agents/skills'
    HasUserSlashCommandSurface = $true
    SharedSkillRootWith        = @('codex')
    AgentDir                   = '.agents/agents/'

    # Spec-kit + Squad coupling
    SpeckitAiFlag  = $null           # spec-kit's --ai flag does not accept antigravity (yet)
    PreferredAgent = 'antigravity'

    # Phase B handler file (not yet present)
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.md'
}
