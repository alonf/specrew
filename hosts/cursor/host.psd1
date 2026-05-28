@{
    # Identity
    Kind          = 'cursor'
    DisplayName   = 'Cursor (AI Code Editor)'
    Status        = 'supported'
    SchemaVersion = 1
    MenuPriority  = 1.5  # Between Claude (1) and Codex (2) — Tier-1 first wave (F-050). Fractional priority requires numeric registry sort (hosts/_registry.ps1).

    # Binary detection
    Binary           = 'cursor-agent'   # standalone Agent CLI (RESOLVED F-050 clarify 2026-05-28). The plain `cursor` is the editor launcher, NOT used for headless governance.
    BinaryAliases    = @()
    InstallUrl       = 'https://cursor.com/cli'
    InstallGuidance  = 'Cursor Agent CLI (cursor-agent) not found on PATH. Install from https://cursor.com/cli, then verify with `cursor-agent --version` and authenticate with `cursor-agent login`.'

    # Runtime layout
    SkillRoot                  = '.cursor/rules'   # Cursor Project Rules (.mdc) — its only auto-attach surface (RESOLVED F-050 clarify)
    HasUserSlashCommandSurface = $false            # Cursor has no user-typed slash-command palette (same as Codex); skills deploy as rules-context
    AgentDir                   = '.cursor/rules/'  # crew agents land as .mdc rules alongside the skill catalog
    InstructionsFile           = 'AGENTS.md'       # Cursor honors the AGENTS.md coordinator-prompt convention

    # Spec-kit + Squad coupling
    SpeckitAiFlag  = $null           # spec-kit's `specify init --ai` flag does not accept cursor (yet)
    PreferredAgent = 'cursor'

    # Phase B handler file
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'
}
