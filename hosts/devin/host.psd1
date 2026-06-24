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
