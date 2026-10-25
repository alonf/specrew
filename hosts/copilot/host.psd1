@{
    # Identity
    Kind          = 'copilot'
    DisplayName   = 'GitHub Copilot CLI'
    # Feature 202 iteration 002, T029 (B4F-131): Copilot's question box. It is named so the guidance can keep it out of
    # workshop questions; it is not a StructuredQuestionPrimitive, because a box answer is never captured.
    QuestionTool = 'ask_user'
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
            # Feature 202 iteration 002, T016 (FR-028, DA-1): the payload fields ONLY this host sends, on both of the channels
            # it uses; a payload matching either alternative is Copilot's. Copilot runs Claude's hooks too (B4F-129), and
            # this is what lets those hooks stand down.
            #   1. Copilot's own hooks: camelCase sessionId, never session_id or hook_event_name (every fixture under
            #      tests/fixtures/hook-payloads/copilot and probe/copilot).
            #   2. Claude's hooks, as Copilot runs them (B4F-144): snake_case like Claude's, but always with a timestamp,
            #      which no Claude or Codex payload carries, and never Claude's prompt_id or permission_mode, nor Codex's
            #      turn_id or model. Measured by the layer-1 probe on Copilot 1.0.101 (probe/copilot-claude-hooks), every
            #      event, sub-agents included.
            PayloadSignature = @{
                Default = @(
                    @{ AllOf = @('sessionId'); NoneOf = @('session_id', 'hook_event_name') },
                    @{ AllOf = @('hook_event_name', 'session_id', 'timestamp'); NoneOf = @('prompt_id', 'permission_mode', 'turn_id', 'model', 'sessionId') }
                )
            }
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
                # Feature 202 iteration 002, T028 (B4F-147): a sub-agent's task text reaches the prompt hook as a prompt. A payload
                # carrying a sub-agent field was not typed by the human, whatever its text, so it can never be an approval.
                # Copilot marks its own channel's sub-agent payloads agentId and parentAgentId (probe/copilot, 1.0.101).
                @{ Origin = 'host-injected'; Rule = 'payload-field'; Fields = @('agentId', 'parentAgentId', 'agent_id', 'parent_agent_id') },
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
