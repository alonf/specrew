@{
    # Identity
    Kind          = 'antigravity'
    DisplayName   = 'Google Antigravity CLI'
    Status        = 'supported'      # Promoted from deferred via antigravity-followup slice
    SchemaVersion = 1
    MenuPriority  = 4  # Interactive host-selection menu priority (iter-011)

    # Binary detection
    Binary           = 'agy'
    BinaryAliases    = @()             # agy is the only binary name (Antigravity is the brand)
    InstallUrl       = 'https://antigravity.google/'
    InstallGuidance  = 'Antigravity CLI (agy) not found on PATH. Install via: irm https://antigravity.google/cli/install.ps1 | iex (Windows) or curl -fsSL https://antigravity.google/cli/install.sh | bash (macOS/Linux). See: https://antigravity.google/'

    # Runtime layout
    SkillRoot                  = '.agents/skills'
    HasUserSlashCommandSurface = $true
    SharedSkillRootWith        = @('codex')
    AgentDir                   = '.agents/agents/'
    InstructionsFile           = 'AGENTS.md'   # Antigravity reads same root-level convention as Codex

    # Spec-kit + Squad coupling
    SpeckitAiFlag  = $null           # spec-kit's --ai flag does not accept antigravity (yet)
    PreferredAgent = 'antigravity'

    # Phase B handler file (not yet present)
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'

    # F-184: verified Antigravity hook surface. Project-scoped .agents/hooks.json carries named hook
    # definitions; PreInvocation supports injectSteps for B2 bootstrap and B3 boundary refocus, and
    # Stop requires a decision JSON for handover. Antigravity has no B1 compaction carrier.
    RefocusHookBindings = @{
        BoundTriggers  = @('b2', 'b3')
        Events         = @('PreInvocation', 'Stop')
        SettingsFile   = '.agents/hooks.json'
        OptOutMarkerFile = '.specrew/runtime/refocus-hooks-optout-antigravity'
        DispatcherPath = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
        ConfigShape    = 'named-definition'
        DefinitionName = 'specrew-refocus'
        DefinitionNameWhenOccupied = 'specrew-refocus-managed'
        CommandMode    = 'launcher-encoded'
        DispatcherRuntime = @{
            BootstrapDeliveryEvents = @('PreInvocation')
            B3DeliveryEvents        = @('PreInvocation')
            RefocusTriggerByEvent   = @{ PreInvocation = 'b3' }
            SuppressedRefocusEvents = @('PostToolUse', 'UserPromptSubmit')
            OutputShape             = 'injectSteps'
            DecisionOnlyEvents      = @('Stop')
            BootstrapDeliveryMode   = 'pointer'
        }
        Registrations  = @(
            @{ Event = 'PreInvocation'; DispatcherEvent = 'PreInvocation'; HandlerShape = 'direct-command'; Timeout = 30 },
            @{ Event = 'Stop'; DispatcherEvent = 'Stop'; HandlerShape = 'direct-command'; Timeout = 30 }
        )
    }
}
