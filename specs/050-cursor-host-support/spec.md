# Feature Specification: Cursor Host Package

**Feature Branch**: `050-cursor-host-support`  
**Created**: 2026-05-28  
**Status**: Draft  
**Input**: Proposal 114 — Cursor Host Package — Tier-1 Multi-Host Expansion Following F-044 Per-Host Architecture
**Proposal Source**: `proposals/114-cursor-host-package.md`

## User Scenarios & Testing

### User Story 1 - Launch Specrew Session in Cursor (Priority: P1)

As a developer using Cursor as my primary AI code editor, I want to launch a Specrew feature session using `specrew start --host cursor "Add user authentication"` so that Specrew's governance model executes within Cursor's Agent mode while I continue editing in the same project workspace.

**Why this priority**: This is the core value proposition — enabling Cursor users to access Specrew without switching to a different AI environment. Without this, Cursor users cannot use Specrew at all.

**Independent Test**: Can be fully tested by running `specrew start --host cursor "test feature"` and verifying that Cursor's Agent panel opens with the Specrew coordinator prompt and begins the specify phase. Delivers immediate value: Cursor users can now use Specrew.

**Acceptance Scenarios**:

1. **Given** Cursor CLI is installed and on PATH, **When** user runs `specrew start --host cursor "Add OAuth login"`, **Then** Cursor's Agent mode launches with Specrew's coordinator prompt and begins specification workflow
2. **Given** Cursor is not installed, **When** user runs `specrew start --host cursor "feature"`, **Then** system displays InstallGuidance message with link to https://cursor.sh/install and instructions to verify binary name
3. **Given** Cursor CLI is installed but not on PATH, **When** user runs host detection, **Then** system signals `binary-missing` and provides PATH configuration guidance
4. **Given** user is in a project with existing `.cursor/` directory, **When** user runs `specrew start --host cursor`, **Then** system detects project-has-cursor-dir signal and prioritizes Cursor in the host menu
5. **Given** Cursor CLI invocation fails with error, **When** launch is attempted, **Then** system captures error output and displays actionable troubleshooting steps

---

### User Story 2 - Deploy Speckit Skills to Cursor (Priority: P2)

As a Specrew user working in Cursor, I want Speckit's skill catalog to be deployed to Cursor's native skill/rules location so that I can invoke Specrew commands (like `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`) directly from Cursor's Agent mode.

**Why this priority**: Enhances usability by making Specrew commands accessible through Cursor's native command surface. Users can still use Specrew without this (via manual text prompts), but this provides better UX.

**Independent Test**: Can be tested by running `specrew init` in a project, then checking that `.cursor/skills/` (or `.cursor/rules/` per clarify-boundary verification) contains the Speckit skill files. User can then type `/speckit.` in Cursor and see autocomplete suggestions.

**Acceptance Scenarios**:

1. **Given** Specrew is initialized in a project with `--host cursor`, **When** skill deployment runs, **Then** all Speckit skills are copied to `.cursor/skills/` (or verified target path) with correct format
2. **Given** Cursor's skill/rules location is `.cursor/rules/` instead of `.cursor/skills/`, **When** deployment runs, **Then** system uses the verified target path from host manifest
3. **Given** skills are already deployed, **When** `specrew update` runs, **Then** existing skills are updated without duplication
4. **Given** Cursor has skill name conflicts, **When** deployment runs, **Then** Specrew skills are namespaced (e.g., `specrew-`) to avoid collision

---

### User Story 3 - Crew Agent Translation for Cursor (Priority: P2)

As a Specrew team administrator, I want `.specrew/team/agents/<role>.md` files (canonical source) to be automatically translated into Cursor's native agent/rules format so that Squad team members appear as accessible agents in Cursor's interface.

**Why this priority**: Enables the full Squad team workflow in Cursor. Without this, users can use core Specrew commands but not the multi-agent team composition features. Lower priority than P1 because single-agent workflows still work.

**Independent Test**: Can be tested by defining a custom agent in `.specrew/team/agents/security-reviewer.md`, then verifying it appears in Cursor's agent list (or equivalent discovery mechanism). Delivers value: Squad team patterns work in Cursor.

**Acceptance Scenarios**:

1. **Given** `.specrew/team/agents/` contains 3 role definitions, **When** `Install-CursorCrewRuntime` runs, **Then** all 3 roles are translated to Cursor's agent format (path verified at clarify boundary: `.cursor/agents/` or `.cursorrules` or other)
2. **Given** an agent definition includes Specrew-specific metadata, **When** translation runs, **Then** metadata is preserved in Cursor-compatible format or stripped gracefully
3. **Given** Cursor's agent format changes (schema evolution), **When** Specrew detects incompatibility, **Then** system logs warning and falls back to generic AGENTS.md fallback
4. **Given** canonical source changes (agent added/removed), **When** re-sync occurs, **Then** Cursor's agent list reflects the change

---

### User Story 4 - Host Detection and Menu Integration (Priority: P3)

As a developer with multiple AI tools installed, I want Cursor to appear in the `specrew onboard` interactive host menu with appropriate priority (MenuPriority: 1.5) so that I can easily select Cursor if it's my preferred environment.

**Why this priority**: Improves discoverability and UX for new Specrew users. However, users can still explicitly specify `--host cursor`, so this is a convenience enhancement rather than a blocker.

**Independent Test**: Can be tested by running `specrew onboard` on a machine with Cursor + other hosts installed, verifying Cursor appears in the menu between Claude (priority 1) and Codex (priority 2), and selecting it completes onboarding.

**Acceptance Scenarios**:

1. **Given** Cursor CLI is installed, **When** `specrew onboard` runs, **Then** Cursor appears in the numbered menu with display name "Cursor (AI Code Editor)"
2. **Given** multiple Tier-1 hosts are installed (Cursor, Claude, Codex), **When** menu is displayed, **Then** hosts are ordered by MenuPriority (Claude=1, Cursor=1.5, Codex=2)
3. **Given** user selects Cursor from menu, **When** onboarding completes, **Then** `.specrew/config.json` records `"preferred_host": "cursor"`
4. **Given** Cursor is not installed, **When** menu is displayed, **Then** Cursor is not listed (or listed as "unavailable" with install link)

---

### Edge Cases

- **Cursor binary name ambiguity**: Cursor's CLI evolved through 2025; the binary might be `cursor-agent` (standalone CLI) or `cursor` (with `agent` subcommand). The host package must detect which exists on PATH and use the correct invocation. If both exist, prefer the one specified in host.psd1 after clarify-boundary empirical verification.
  
- **Cursor version incompatibility**: Older Cursor versions may not support non-interactive Agent mode or may have different CLI flag conventions. The host package should check `binary-version` signal and warn if version is below a tested minimum (TBD at clarify boundary).

- **Skill/rules path evolution**: Cursor's skill deployment target (`.cursor/skills/` vs `.cursor/rules/` vs `.cursorrules` file) may vary by version or configuration. The host package must verify the target path empirically during clarify boundary and document the resolution in the manifest.

- **Account tier limitations**: Cursor's Pro/Business features may gate certain capabilities (e.g., advanced Agent mode, custom rules). The host package should optionally probe for account tier as a 6th signal and warn users if quota limits may apply.

- **Project-level vs global skills**: Cursor may support both project-level (`.cursor/skills/`) and user-level (`~/.cursor/skills/`) skill locations. Specrew should prefer project-level to maintain project-specific governance context.

- **Concurrent host usage**: User runs Specrew in Cursor while also having Claude or Codex sessions active in the same project. The canonical source pattern (`.specrew/team/agents/` as single source of truth) prevents drift, but the host package should not interfere with other hosts' directories.

## Requirements

### Functional Requirements

- **FR-001**: System MUST provide a `hosts/cursor/host.psd1` manifest following the F-044 canonical schema with fields: Kind, DisplayName, Status, SchemaVersion, MenuPriority, Binary, InstallUrl, InstallGuidance, SkillRoot, HasUserSlashCommandSurface, SettingsPath, AgentDir, InstructionsFile, SpeckitAiFlag, PreferredAgent, HandlersFile, CoordinatorRulesFile
  - **Owner**: Implementation Team
  - **Iteration**: Iteration 1 (manifest authoring)
  
- **FR-002**: System MUST implement the 5-function contract in `hosts/cursor/host.ps1`:
  1. `New-CursorLaunchInvocation` — builds Cursor CLI invocation for `specrew start --host cursor`
  2. `Convert-CursorFlag` — translates universal Specrew flags to Cursor-CLI equivalents
  3. `Test-CursorRuntimeInstalled` — probes for binary + version check
  4. `Get-CursorSignals` — returns probe signals: `binary-present`, `binary-version`, `agent-mode-available`, `project-has-cursor-dir`
  5. `Install-CursorCrewRuntime` — translates `.specrew/team/agents/<role>.md` to Cursor's native agent/rules location
  - **Owner**: Implementation Team
  - **Iteration**: Iteration 1 (core functions)

- **FR-003**: System MUST add `.cursor/skills/` (or verified target path) to the skill deployment targets in `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`, maintaining alphabetical sort order among the 5 host targets (claude, cursor, github, agents)
  - **Owner**: Implementation Team
  - **Iteration**: Iteration 1 (skill deployment integration)

- **FR-004**: System MUST auto-discover the Cursor host package via `hosts/_registry.ps1`'s directory scan without requiring manual registry code changes
  - **Owner**: Implementation Team (verification only — registry pattern already exists from F-044)
  - **Iteration**: Iteration 1 (registry validation)

- **FR-005**: System MUST provide unit tests in `tests/hosts/cursor.tests.ps1` covering each of the 5 contract functions with mock and real binary fixtures
  - **Owner**: Implementation Team
  - **Iteration**: Iteration 2 (unit test coverage)

- **FR-006**: System MUST provide integration test in `tests/integration/host-cursor-launch.tests.ps1` for `specrew start --host cursor` end-to-end smoke test (skipped on CI without Cursor installed)
  - **Owner**: Implementation Team
  - **Iteration**: Iteration 2 (integration test coverage)

- **FR-007**: System MUST update `tests/integration/multi-host-detection.tests.ps1` to include cursor in the host-probe matrix
  - **Owner**: Implementation Team
  - **Iteration**: Iteration 2 (multi-host test update)

- **FR-008**: System MUST document Cursor quickstart and caveats in `docs/getting-started.md` and `docs/user-guide.md`
  - **Owner**: Implementation Team
  - **Iteration**: Iteration 3 (documentation)

- **FR-009**: [NEEDS CLARIFICATION: Canonical CLI binary name — is it `cursor-agent` (standalone) or `cursor` (with `agent` subcommand)?] System MUST use the empirically verified binary name in the manifest's `Binary` field and `New-CursorLaunchInvocation` function
  - **Owner**: Implementation Team
  - **Iteration**: Iteration 1 (clarify boundary empirical verification)

- **FR-010**: [NEEDS CLARIFICATION: Skill/agent deployment target — is it `.cursor/skills/`, `.cursor/rules/`, `.cursorrules` file, or other?] System MUST deploy skills to the empirically verified target path specified in the manifest's `SkillRoot` field
  - **Owner**: Implementation Team
  - **Iteration**: Iteration 1 (clarify boundary empirical verification)

- **FR-011**: [NEEDS CLARIFICATION: Cursor CLI non-interactive support — does Cursor CLI support non-interactive Agent mode with `--prompt` flag, or is it GUI-only?] If non-interactive mode is not supported, system MUST downgrade host status from `supported` to `preview` in manifest and document limitation in InstallGuidance
  - **Owner**: Implementation Team
  - **Iteration**: Iteration 1 (clarify boundary empirical verification)

### Traceability & Governance Requirements

- **TG-001**: Each user story MUST map to one or more functional requirements:
  - User Story 1 (Launch) → FR-001, FR-002 (functions 1-4), FR-004, FR-009, FR-011
  - User Story 2 (Skills) → FR-003, FR-010
  - User Story 3 (Agents) → FR-002 (function 5), FR-010
  - User Story 4 (Menu) → FR-001 (MenuPriority field), FR-004

- **TG-002**: Each requirement MUST identify expected owner role(s):
  - All FRs owned by "Implementation Team" (the Crew executing F-050)

- **TG-003**: Each requirement MUST identify intended iteration or delivery window:
  - Iteration 1: FR-001, FR-002, FR-003, FR-004, FR-009, FR-010, FR-011 (core functionality + clarifications)
  - Iteration 2: FR-005, FR-006, FR-007 (test coverage)
  - Iteration 3: FR-008 (documentation)

- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path:
  - Binary name discrepancy (Proposal 114: `cursor`, Proposal 124: `cursor-agent`) → Reconciliation: Clarify-boundary empirical verification determines correct value; spec records the resolved answer as authoritative
  - Skill path ambiguity (`.cursor/skills/` vs `.cursor/rules/`) → Reconciliation: Clarify-boundary empirical verification determines correct path; manifest's `SkillRoot` field captures the resolved value

### Key Entities

- **Host Package**: A directory under `hosts/<kind>/` containing a manifest (`host.psd1`), contract implementation (`host.ps1`), handlers (`handlers.ps1`), and coordinator rules (`coordinator-rules.psd1`). Represents a single AI environment that Specrew can launch into.

- **Five-Function Contract**: The interface every host package must implement:
  1. `New-<Kind>LaunchInvocation` — CLI command builder
  2. `Convert-<Kind>Flag` — flag translator
  3. `Test-<Kind>RuntimeInstalled` — installation probe
  4. `Get-<Kind>Signals` — capability signals
  5. `Install-<Kind>CrewRuntime` — crew agent translator

- **Canonical Agent Source**: The `.specrew/team/agents/<role>.md` directory structure, established by F-044 as the single source of truth for Squad team definitions. Host packages translate these files into each host's native agent format.

- **Host Registry**: The `hosts/_registry.ps1` module that auto-discovers host packages by scanning the `hosts/` directory for subdirectories containing `host.psd1` manifests.

- **Skill Deployment Target**: The host-specific directory where Speckit skills are copied during `specrew init` or skill-sync operations. For Cursor, this is `.cursor/skills/` (subject to clarify-boundary verification).

## Success Criteria

### Measurable Outcomes

- **SC-001**: A Cursor user can complete the full Specrew lifecycle (specify → clarify → plan → tasks → implement → review) using only `specrew start --host cursor` without switching to a different AI environment
  
- **SC-002**: Cursor appears in the `specrew onboard` host menu within 2 seconds of running the command on a machine with Cursor installed
  
- **SC-003**: Skill deployment to Cursor completes in under 5 seconds for a typical 10-skill catalog
  
- **SC-004**: 100% of the 5 contract functions have passing unit tests with both mock and real-binary fixtures
  
- **SC-005**: Integration test `host-cursor-launch.tests.ps1` passes on a development machine with Cursor installed, demonstrating end-to-end launch capability
  
- **SC-006**: Cursor host package is the first post-F-044 host addition, validating that the per-host architecture scales to new hosts without requiring framework refactors
  
- **SC-007**: Documentation includes a "Cursor Quickstart" section that a new user can follow to go from zero to running their first Specrew feature in Cursor in under 10 minutes

## Assumptions

- **Cursor CLI availability**: Cursor provides a CLI binary (`cursor-agent` or `cursor`) that is installable and can be added to PATH. This is confirmed by user reports and Cursor's documentation, but the exact binary name and invocation shape are subject to clarify-boundary empirical verification.

- **Non-interactive Agent mode**: Cursor's CLI supports a non-interactive Agent mode that can be triggered with a prompt and working directory, similar to `gh copilot` or `claude-cli`. If this assumption proves false, host status downgrades to `preview` and the feature documents GUI-launcher workarounds.

- **Skill/rules surface exists**: Cursor has a mechanism for project-level or user-level custom skills, rules, or agent definitions that Specrew can deploy to. The exact path and format are subject to clarify-boundary verification.

- **Stable CLI contract**: Cursor's CLI flag conventions and invocation patterns are stable enough across recent versions (2025-2026) that a single host package can support the installed base. If major version fragmentation exists, the host package may need version-specific logic.

- **F-044 architecture is stable**: The per-host architecture shipped in F-044 (5-function contract + registry pattern + canonical source) is considered stable and will not require breaking changes during F-050 implementation. Any discovered gaps are treated as proposals for future architecture iterations, not in-place edits.

- **Parallel work coordination**: F-050 runs concurrently with F-049 on the main branch. The Parallel-Work Coordination Charter (Proposal 114, section "Parallel-Work Coordination Charter") is authoritative for merge sequencing, ModuleVersion assignment (`0.29.0` pre-allocated to F-050), and framework-file protection rules.

- **Clarify-boundary as gate**: The three empirically unresolved questions (binary name, skill path, non-interactive support) are intentionally left as clarification items rather than pre-specify blockers. The implementing Crew resolves them at the clarify boundary as part of substantive intake, and the spec is updated with the resolved answers as authoritative scope inputs.

## Governance Alignment

- **Spec Steward**: Alon Fliess (project maintainer) — accountable for specification integrity and cross-feature coordination (especially parallel-work sequencing with F-049)

- **Iteration Facilitator**: Implementation Team (the Crew executing F-050) — accountable for cadence, blockers, and boundary signaling when empirical verification is needed

- **Capacity Model**: Story Points (8-12 SP estimated per Proposal 114), with 3 planned iterations:
  - Iteration 1: Core functionality (manifest, contract, skill deployment) + clarify-boundary empirical verification → ~4-6 SP
  - Iteration 2: Test coverage (unit + integration) → ~2-3 SP
  - Iteration 3: Documentation + manual smoke test → ~2-3 SP

- **Drift Signals**: 
  - **Spec-to-plan drift**: Plan introduces implementation choices not grounded in the spec (e.g., choosing a Cursor binary name without empirical verification) → Escalate to spec update with clarification resolution
  - **Plan-to-tasks drift**: Tasks include changes to framework files (`.specify/extensions/specrew-speckit/**`) in violation of Parallel-Work Coordination Charter Item 2 → Block task, surface as proposal
  - **Tasks-to-implementation drift**: Implementation runs `specrew update` (violates Charter Item 3) or merges PR before F-049 (violates Charter Item 5) → Halt, escalate to maintainer for sequencing decision

- **Human Oversight Points**:
  1. **Clarify-boundary empirical verification** — Required before Iteration 1 completes. Crew must report findings for binary name, skill path, and non-interactive support; spec is updated with authoritative answers.
  2. **Post-Iteration-1 checkpoint** — Maintainer reviews core functionality (manifest + contract) for compliance with F-044 pattern before test coverage begins.
  3. **Pre-PR merge checkpoint** — Maintainer confirms F-049 has merged to main before F-050's PR is approved (Charter Item 5).
  4. **Cross-reviewer signoff** — A different model session than the implementing Crew performs review (Charter Item 8), validated empirically in F-049 lifecycle.
  5. **Beta-before-stable gate** — Feature ships to PSGallery as `v0.29.0-beta.N`, awaits manual install validation, then promotes to stable (Charter Item 6).
