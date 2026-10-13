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
    # local source-value verification; B3 and the T070 turn baseline use the
    # documented userPromptSubmitted event (per-tool-call delivery remains latency-rejected).
    RefocusHookBindings = @{
        BoundTriggers  = @('b2', 'b3')
        Events         = @('sessionStart', 'userPromptSubmitted')
        TurnStartCapability = @{ Mode = 'exact'; NativeEvent = 'userPromptSubmitted'; DispatcherEvent = 'UserPromptSubmit' }
        SettingsFile   = '~/.copilot/hooks/specrew-refocus.json'   # hooks-dir model: wholly Specrew-owned file
        OptOutMarkerFile = '.specrew/runtime/refocus-hooks-optout-copilot'
        DispatcherPath = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
        ConfigShape    = 'event-map'
        CommandMode    = 'launcher-file'
        SettingsVersion = 1
        OwnsSettingsFile = $true
        DispatcherRuntime = @{
            BootstrapDeliveryEvents = @('SessionStart')
            B3DeliveryEvents        = @('PostToolUse', 'UserPromptSubmit')
            RefocusTriggerByEvent   = @{ PostToolUse = 'b3'; UserPromptSubmit = 'b3' }
            SuppressedRefocusEvents = @()
            OutputShape             = 'additionalContext'
            DecisionOnlyEvents      = @()
            # FR-004 (185) stop-block lever (verified, research/stop-block-capability-matrix.md): Copilot agentStop
            # {"decision":"block","reason":...} forces another agent turn. CAVEATS: fail-open (a non-zero exit lets
            # the turn end packet-less -> best-effort, not bulletproof) and NO built-in loop guard -> the provider's
            # own consecutive-block cap is the loop guard here.
            StopBlockShape          = 'decision-block'
            BootstrapDeliveryMode   = 'inline'
            # Feature 202 T002 (DA-1, option B): this host's INPUT contract is data. The dispatcher's single
            # normalizer (ConvertTo-SpecrewTurnRecord) reads it; shared code names no host. Field paths may be
            # dotted (a.b.c). Measured payloads: tests/fixtures/hook-payloads/<host>/ (202 research.md, T001).
            InputFieldMap           = @{
                SessionId      = @('sessionId')
                Prompt         = @('prompt')
                TranscriptPath = @('transcriptPath')
                Source         = @('source')
                ToolName       = @('toolName')
                ToolOutcome    = @('toolResult.toolTelemetry.properties.outcome')
                ToolQuestion   = @('toolResult.toolTelemetry.restrictedProperties.question')
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
            # Named transform from the dispatcher's shared registry: a dismissed ask_user form is an absence,
            # never an answer (B4F-113; 1.0.96 emits no hook event for it, the legacy string is kept under test).
            InputTransform          = 'ask-user-dismissal-text'
        }
        Registrations  = @(
            @{ Event = 'sessionStart'; DispatcherEvent = 'SessionStart'; HandlerShape = 'dual-shell-entry'; TimeoutSec = 30 },
            @{ Event = 'userPromptSubmitted'; DispatcherEvent = 'UserPromptSubmit'; HandlerShape = 'dual-shell-entry'; TimeoutSec = 30 },
            @{ Event = 'agentStop'; DispatcherEvent = 'agentStop'; HandlerShape = 'dual-shell-entry'; TimeoutSec = 30 }
        )
    }
}
