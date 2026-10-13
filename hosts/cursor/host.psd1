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

    # Feature 171 (FR-013, T014): refocus hook bindings. B2 via sessionStart
    # (additional_context verified, snake_case contract). B1 = documented
    # variance (no post-compaction injection event exists); B3 and the T070 turn
    # baseline use the documented beforeSubmitPrompt event (postToolUse remains latency-rejected).
    RefocusHookBindings = @{
        BoundTriggers  = @('b2', 'b3')
        Events         = @('sessionStart', 'beforeSubmitPrompt')
        TurnStartCapability = @{ Mode = 'exact'; NativeEvent = 'beforeSubmitPrompt'; DispatcherEvent = 'UserPromptSubmit' }
        SettingsFile   = '~/.cursor/hooks.json'   # user-level; dispatcher self-gates per project
        OptOutMarkerFile = '.specrew/runtime/refocus-hooks-optout-cursor'
        DispatcherPath = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
        ConfigShape    = 'event-map'
        CommandMode    = 'launcher-file'
        SettingsVersion = 1
        ProjectRootEnvironmentVariables = @('CURSOR_PROJECT_DIR', 'CLAUDE_PROJECT_DIR')
        DispatcherRuntime = @{
            BootstrapDeliveryEvents = @('SessionStart')
            B3DeliveryEvents        = @('PostToolUse', 'UserPromptSubmit')
            RefocusTriggerByEvent   = @{ PostToolUse = 'b3'; UserPromptSubmit = 'b3' }
            SuppressedRefocusEvents = @()
            OutputShape             = 'additional_context'
            DecisionOnlyEvents      = @()
            # FR-004 (185) stop-block lever (verified, research/stop-block-capability-matrix.md): Cursor's 'stop'
            # hook is observational - NO same-turn hard block. Strongest lever is followup_message, which auto-submits
            # a NEW user turn (the human may glimpse the packet-less stop first), capped by loop_limit (default 5).
            # DECLARED degraded mode: best-effort re-triggered turn, NOT a hard block.
            StopBlockShape          = 'followup-message'
            BootstrapDeliveryMode   = 'inline'
            # Feature 202 T002 (DA-1, option B): this host's INPUT contract is data. The dispatcher's single
            # normalizer (ConvertTo-SpecrewTurnRecord) reads it; shared code names no host. Field paths may be
            # dotted (a.b.c). Measured payloads: tests/fixtures/hook-payloads/<host>/ (202 research.md, T001).
            InputFieldMap           = @{
                SessionId      = @('conversation_id')
                Prompt         = @('prompt')
                TranscriptPath = @('transcript_path')
                Source         = @('source')
                ToolName       = @('tool_name')
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
            @{ Event = 'sessionStart'; DispatcherEvent = 'SessionStart'; HandlerShape = 'command-entry' },
            @{ Event = 'beforeSubmitPrompt'; DispatcherEvent = 'UserPromptSubmit'; HandlerShape = 'command-entry' },
            @{ Event = 'stop'; DispatcherEvent = 'stop'; HandlerShape = 'command-entry' }
        )
    }
}
