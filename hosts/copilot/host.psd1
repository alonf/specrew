@{
    # Identity
    Kind          = 'copilot'
    DisplayName   = 'GitHub Copilot CLI'
    CrewRuntimeDisplayName = 'Squad'
    Status        = 'supported'
    SchemaVersion = 1
    MenuPriority  = 3  # Interactive host-selection menu priority (iter-011). Note: `--host` flag non-interactive default REMAINS `copilot` (specrew-start.ps1) for predictability in CI/automation.

    # Binary detection
    Binary           = 'copilot'
    InstallUrl       = 'https://docs.github.com/en/copilot/how-tos/copilot-cli'
    InstallGuidance  = 'GitHub Copilot CLI not found on PATH. Install: https://docs.github.com/en/copilot/how-tos/copilot-cli'

    # Runtime layout
    SkillRoot                  = '.github/skills'
    LegacySkillRoots           = @('.copilot/skills')
    HasUserSlashCommandSurface = $true
    InstructionsFile           = '.github/copilot-instructions.md'
    AgentDir                   = '.squad/agents/'

    # Spec-kit + Squad coupling
    SpeckitAiFlag  = 'copilot'
    PreferredAgent = 'copilot'

    # Phase B handler file (not yet present)
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'

    # Feature 171 (FR-013, T014): refocus hook bindings. Copilot hooks went GA
    # 2026-02-25 (research-matrix.md — the earlier no-surface finding is
    # obsolete). B2 via sessionStart (additionalContext verified); B1 pending
    # local source-value verification; B3 rides channel 1 (per-prompt injection
    # unverified on userPromptSubmitted; per-tool-call latency-rejected).
    RefocusHookBindings = @{
        BoundTriggers  = @('b2')
        Events         = @('sessionStart')
        SettingsFile   = '~/.copilot/hooks/specrew-refocus.json'   # hooks-dir model: wholly Specrew-owned file
        DispatcherPath = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
    }
}
