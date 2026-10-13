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
        TurnStartCapability = @{ Mode = 'exact'; NativeEvent = 'PreInvocation'; DispatcherEvent = 'PreInvocation' }
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
            # FR-004 (185) stop-block lever (verified, research/stop-block-capability-matrix.md): Antigravity Stop
            # {"decision":"continue","reason":...} re-enters the loop (any other value allows the stop) - a SOFT
            # block (the model can retry stopping next loop). NO built-in loop guard -> the provider's own
            # consecutive-block cap is the loop guard here.
            StopBlockShape          = 'decision-continue'
            BootstrapDeliveryMode   = 'pointer'
            # Feature 202 T002 (DA-1, option B): this host's INPUT contract is data. The dispatcher's single
            # normalizer (ConvertTo-SpecrewTurnRecord) reads it; shared code names no host. Field paths may be
            # dotted (a.b.c). Measured payloads: tests/fixtures/hook-payloads/<host>/ (202 research.md, T001).
            InputFieldMap           = @{
                SessionId      = @('conversationId')
                Prompt         = @('prompt', 'userPrompt', 'user_prompt', 'message', 'text', 'content')
                TranscriptPath = @('transcriptPath')
                Source         = @('source', 'trigger')
                ToolName       = @('toolName', 'tool_name')
            }
            # Evaluated in order; the first matching rule decides. A prompt that matches no host-injected rule
            # is typed-user, and only typed-user can produce a receipt (FR-006). hook-output-journal: the prompt
            # equals text this dispatcher emitted (a replayed Stop reason). prompt-pattern: a host envelope or a
            # replayed Specrew directive.
            OriginRules             = @(
                @{ Origin = 'host-injected'; Rule = 'hook-output-journal' },
                @{ Origin = 'host-injected'; Rule = 'prompt-pattern'; Pattern = '(?is)^\s*<(?:task-notification|hook_prompt|turn_aborted|system-reminder|environment_context)\b' },
                @{ Origin = 'host-injected'; Rule = 'prompt-pattern'; Pattern = '(?is)^\s*(?:Specrew:|Specrew\s+review\s+[-\u2014]|\[specrew-|AWAITING YOUR VERDICT:|BOUNDARY NOT READY FOR A VERDICT:|Campaign review authority\b)' },
                @{ Origin = 'typed-user'; Rule = 'prompt-present' }
            )
        }
        Registrations  = @(
            @{ Event = 'PreInvocation'; DispatcherEvent = 'PreInvocation'; HandlerShape = 'direct-command'; Timeout = 30 },
            @{ Event = 'Stop'; DispatcherEvent = 'Stop'; HandlerShape = 'direct-command'; Timeout = 30 }
        )
    }
}
