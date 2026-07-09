@{
    # Identity
    Kind          = 'devin'
    DisplayName   = 'Devin for Terminal (Devin CLI)'
    Status        = 'experimental'   # FR-006: ships experimental; experimental->supported requires the
                                     # iteration-003 real-host promotion gate (FR-021). No MenuPriority by
                                     # design — an experimental, disabled-unless-selected host sorts last
                                     # (registry default 999) so it never reorders the interactive menu.
    SchemaVersion = 1

    # Binary detection
    Binary           = 'devin'
    InstallUrl       = 'https://docs.devin.ai/work-with-devin/devin-cli'
    InstallGuidance  = 'Devin CLI not found on PATH. Install: https://docs.devin.ai/work-with-devin/devin-cli'

    # Runtime layout (FR-008): instructions target root AGENTS.md; skills live under .devin/skills/ and
    # the documented shared .agents/skills/ surface; Crew subagents deploy nested under .devin/agents/.
    SkillRoot                  = '.devin/skills'
    HasUserSlashCommandSurface = $true
    SharedSkillRootWith        = @()
    AgentDir                   = '.devin/agents/'
    InstructionsFile           = 'AGENTS.md'

    # Spec-kit coupling (FR-010): declare the Spec Kit integration identifier as 'devin'. Generic
    # version-aware --ai / --integration flag-name selection stays Proposal 198 ownership and MUST NOT
    # become a Devin-specific shared-core conditional.
    SpeckitAiFlag  = 'devin'
    PreferredAgent = 'devin'

    # Contract files
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'

    # FR-006: tested-build + compatibility-monitor metadata. The pinned tested build is a date-style
    # opaque identifier, NOT a release-chronology claim. The fragile surfaces are recorded for the future
    # compatibility/transcript-drift monitor (Proposal 187/194); Feature 200 supplies the metadata but
    # does not build the scheduled monitor.
    TestedBuild = '2026.7.23 (3bd47f77)'
    CompatibilityMonitor = @{
        TestedBuild     = '2026.7.23 (3bd47f77)'
        VersionScheme   = 'date-style-opaque'   # no semver ordering is invented for date-style versions
        FragileSurfaces = @(
            'hook-config-shape:.devin/hooks.v1.json (root-level direct event map)',
            'stop-payload:{hook_event_name,stop_hook_active} only — no assistant-message field on the tested build',
            'export-format:ATIF v1.7 steps[] (source=user|agent, string message)',
            'handover-canary:in-package ATIF->Claude-like-JSONL normalizer consumed by the unchanged parser',
            'launch-flags:auto|smart|dangerous permission modes',
            'windows-hook-runner:tested build needs sh.exe on PATH for command hooks (pwsh host-neutral attempt is iteration 003)'
        )
        # FR-011 spike outcome: outcome 2 (ATIF export + in-package normalization). The unchanged parser
        # reads the normalized shape; no parser change and no accessor edit are required.
        HandoverOutcome      = 'export-normalization'
        HandoverMechanism    = 'in-package-atif-normalizer'
        AccessorEditRequired = $false
    }

    # FR-009 (iteration 002, T012): refocus hook bindings. Devin's .devin/hooks.v1.json stores the lifecycle
    # event map at the FILE ROOT (no `hooks` wrapper), so it selects the generic manifest-driven
    # ConfigShape='direct-event-map' added to the shared deployer. Events are Claude-compatible
    # (SessionStart/UserPromptSubmit/Stop, hooks-array groups) and Stop uses the existing decision-block envelope.
    # No SettingsVersion is declared: the `v1` lives in the filename, and a root `version` scalar would be wrapped
    # to an array by the event-map remove pass and break re-deploy idempotence. Project resolution rides
    # DEVIN_PROJECT_DIR via the per-machine launcher's manifest-enumerated ProjectRootEnvironmentVariables.
    # HONESTY (FR-009): on the tested build the Windows hook-runner needs sh.exe on PATH for command hooks, so
    # direct-launch hooks may not fire on Windows. This ships experimental/degraded — NOT full parity. The
    # sh.exe->pwsh host-neutral attempt and live validation are iteration 003.
    RefocusHookBindings = @{
        BoundTriggers  = @('b1', 'b2', 'b3')
        Events         = @('SessionStart', 'UserPromptSubmit')
        SettingsFile   = '.devin/hooks.v1.json'   # project-level; root-level direct event map (no `hooks` wrapper)
        OptOutMarkerFile = '.specrew/runtime/refocus-hooks-optout-devin'
        DispatcherPath = '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
        ConfigShape    = 'direct-event-map'
        CommandMode    = 'launcher-file'
        ProjectRootEnvironmentVariables = @('DEVIN_PROJECT_DIR')
        DispatcherRuntime = @{
            BootstrapDeliveryEvents = @('SessionStart')
            B3DeliveryEvents        = @('PostToolUse', 'UserPromptSubmit')
            RefocusTriggerByEvent   = @{ PostToolUse = 'b3'; UserPromptSubmit = 'b3' }
            SuppressedRefocusEvents = @()
            OutputShape             = 'hookSpecificOutput'
            # Stop expects JSON and only permits decision:"block"; non-blocking Stop nudges are suppressed as `{}`
            # while real stop-blocks short-circuit through StopBlockShape below (existing decision-block envelope).
            DecisionOnlyEvents      = @('Stop')
            StopBlockShape          = 'decision-block'
            BootstrapDeliveryMode   = 'pointer'
        }
        Registrations  = @(
            @{ Event = 'SessionStart'; DispatcherEvent = 'SessionStart'; HandlerShape = 'hooks-array'; Timeout = 30 },
            @{ Event = 'UserPromptSubmit'; DispatcherEvent = 'UserPromptSubmit'; HandlerShape = 'hooks-array'; Timeout = 30 },
            @{ Event = 'Stop'; DispatcherEvent = 'Stop'; HandlerShape = 'hooks-array'; Timeout = 30 }
        )
    }

    # FR-013 (coordinator eligibility) is owned by Slice D (iteration 004). Devin is coordinator-capable,
    # uses host_process access, and defaults to disabled-unless-selected. The coordinator metadata is
    # declared here so the manifest is the single source of truth; the registry consumers that DERIVE the
    # eligible host set from this field land in Slice D — this iteration only records the metadata.
    Coordinator = @{
        Capable        = $true
        AccessMode     = 'host_process'
        DefaultEnabled = $false   # disabled unless selected for the project
    }
}
