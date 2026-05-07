# Research: Specrew — Spec-Governed AI Crew Operating Model

**Date**: 2026-04-17
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

## Research Tasks

### R1: Squad Post-Task Hook Availability

**Question**: Does Squad's HookPipeline provide a post-task hook that can be used for per-task drift detection?

**Findings**: Squad's docs describe `PreToolUseHook` and `PostToolUseHook` in the `HookPipeline` API. These intercept tool calls (before/after), returning `allow`, `block`, or `modify` actions. The hooks operate at the tool-call level, not at the "task completion" level. A "task" in Specrew's iteration model is a higher-level concept than a Squad tool call.

**Decision**: Implement drift detection as a Squad **skill** (`drift-check.md`) that the Reviewer role invokes after each task's output is committed. The post-task trigger is implemented by including a directive that instructs agents to invoke the drift-check skill as the final step of every task. If Squad later adds a task-level lifecycle hook, migrate to it.

**Rationale**: Using a skill + directive pattern works within documented Squad extension surfaces. It avoids depending on an undocumented hook shape.

**Alternatives considered**:
- `PostToolUseHook` on write operations: Too granular; would fire on every file write, not per logical task.
- Review-gate-only drift check: Loses the "detect in same iteration" property (SC-003).
- Custom SDK hook in `squad.config.ts`: Would work but pulls in SDK dependency for MVP — deferred.

---

### R2: Spec Kit Extension Starter Template Capabilities

**Question**: What hook points and command types does the Spec Kit extension starter template support?

**Findings**: Spec Kit extensions support:
- **Commands**: Namespaced commands registered in config.yml, invoked via `/speckit.{namespace}.{command}`
- **Hooks**: `before_*` and `after_*` for each Spec Kit phase (constitution, specify, clarify, plan, tasks, implement, checklist, analyze, taskstoissues)
- **Templates**: Markdown templates that can override or extend Spec Kit's built-in templates
- **Config**: YAML-based extension configuration in `.specify/extensions.yml`
- **Scripts**: PowerShell/shell scripts invoked by hooks or commands

All Specrew governance needs map to available surfaces: `specrew init` as a command, governance validation as `before_plan`/`before_implement` hooks, drift diff as a script.

**Decision**: Use the Spec Kit extension starter template as-is. No custom hook types needed.

**Rationale**: All required capabilities are covered by documented surfaces.

**Alternatives considered**: None — the template covers the need.

---

### R3: Brownfield Merge Strategy for Squad Team Config

**Question**: How should `specrew init` merge baseline roles into an existing Squad team?

**Findings**: Squad team configuration lives in `.squad/` directory files. Team members are defined in team state files. Squad's `squad init` creates the default structure. Existing roles can be inspected by reading `.squad/` state files.

**Decision**: Additive merge only. `specrew init` reads existing `.squad/` team files, identifies currently defined roles, and adds missing baseline roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) without modifying existing roles. If a role name conflicts (e.g., user already has a "Reviewer" role), Specrew prompts the user: adopt the existing role config for that name, or rename Specrew's baseline role (e.g., "Specrew Reviewer").

**Rationale**: Additive-only merge eliminates data loss risk. User prompt on name conflicts preserves user intent.

**Alternatives considered**:
- Full overwrite: Too destructive (FR-020 requires preservation).
- Namespace all roles (e.g., "specrew-reviewer"): Adds noise; most projects won't have conflicts.
- Skip conflicting roles silently: Violates Constitution XI (explicit collision handling).

---

### R4: Iteration Artifact Parseability

**Question**: How should Markdown iteration artifacts be structured so that scripts can parse them for evaluation and drift detection?

**Findings**: Spec Kit already uses structured Markdown with consistent heading levels, `**bold-key**: value` patterns, and tables. The evaluation harness and drift-check skill need to extract: task-to-requirement mappings, effort estimates, review verdicts, and drift events.

**Decision**: Use consistent Markdown conventions:
- Headings for sections: `## Tasks`, `## Drift Events`, `## Verdicts`
- Tables for structured data: `| Task | Requirement | Effort | Owner | Verdict |`
- Bold key-value pairs for metadata: `**Iteration**: 001`, `**Status**: complete`
- Lists for drift events: `- **DR-001**: [requirement] → [deviation] → [resolution]`

Scripts parse using regex on these patterns. No JSON/YAML front matter required.

**Rationale**: Stays within the "all Markdown" decision from clarification. Consistent patterns are parseable without introducing a secondary format.

**Alternatives considered**:
- YAML front matter in Markdown: Adds complexity; not used by Spec Kit conventions.
- Separate JSON sidecar files: Contradicts the "Markdown files" clarification answer.

---

### R5: Evaluation Harness Execution Model

**Question**: How does the evaluation harness drive Squad agent execution programmatically?

**Findings**: Squad provides `squad watch` for autonomous polling and an interactive shell. For evaluation, the harness needs to: start an iteration, wait for completion, check artifacts, and score. Squad's CLI can be invoked from scripts. The `@copilot --agent squad` pattern drives work through Copilot.

**Decision**: The evaluation harness operates by:
1. Scaffolding a project and spec via Spec Kit CLI commands (scriptable)
2. Triggering iteration start by writing the plan and invoking Squad ceremonies via the CLI or file-based triggers
3. Checking iteration artifacts after each phase (Markdown file existence and content checks)
4. Scoring via dedicated scorer scripts that parse the Markdown artifacts

The harness does not need to drive the LLM directly — it validates the artifacts the LLM-driven crew produces.

**Rationale**: Artifact-based validation is more stable than trying to script LLM agent behavior. The harness checks outputs, not process internals.

**Alternatives considered**:
- Direct SDK-driven execution: Requires SDK-first mode (experimental, deferred).
- Mock agents: Would test the harness but not the real crew behavior.

---

### R6: Version Pin Strategy for Pre-1.0 Dependencies

**Question**: How should Specrew handle version compatibility with pre-1.0 upstream tools?

**Findings**: Both Spec Kit (0.7.3) and Squad (0.9.1) are pre-1.0 and may introduce breaking changes between minor versions. Neither guarantees semver stability.

**Decision**:
- Pin to `>=` minimum versions (Spec Kit >= 0.7.3, Squad >= 0.9.1) rather than exact pins.
- Maintain a compatibility test suite that runs against the minimum and latest versions.
- Subscribe to upstream changelogs and release notifications.
- Budget a "compatibility update" task in each Specrew iteration.
- Document known incompatibilities in `docs/` and in release notes.

**Rationale**: `>=` pins allow users to stay current while guaranteeing a known-good baseline. Compatibility test suite catches breakage early.

**Alternatives considered**:
- Exact version pins: Too restrictive; forces users to match exact versions.
- No version validation: Allows silent breakage (violates FR-002 version validation requirement).

---

### R7: Agent HQ Delegated-Agent Support (FR-021, FR-022)

**Question**: How should Specrew model GitHub Copilot Agent HQ support for selectable agents such as Claude/Codex without introducing standalone runtimes?

**Findings**:

**Copilot / Agent HQ**: GitHub Copilot remains the execution substrate. When Agent HQ exposes selectable agents such as Claude or Codex, those agents are chosen through Copilot rather than invoked as separate Squad runtimes.

**Standalone CLIs** (`claude`, `codex`): Direct CLI invocation would create an additional execution path outside Squad's Copilot runtime model. Specrew v1 should not depend on that path.

**Actual probe shape in this environment**:
- `gh copilot` is **not** the active runtime surface here; `gh copilot --help` returns `unknown command "copilot" for "gh"`.
- The active Copilot runtime surface is the standalone `copilot` CLI. `copilot --version` succeeds (`GitHub Copilot CLI 1.0.31`) and `copilot --help`/`copilot help config` are the documented local metadata surfaces.
- When `specrew init` runs inside an active Copilot CLI session, environment markers `COPILOT_CLI`, `COPILOT_AGENT_SESSION_ID`, and `COPILOT_CLI_BINARY_VERSION` are present and can confirm that the bootstrap is already running under Copilot.
- The documented delegated-agent metadata surface available locally is the `model` section of `copilot help config`. In this environment that section enumerates Claude-family model IDs and Codex-family model IDs, which is sufficient for a non-executing consent probe.
- `gh api /user` still works as an auth-context probe, but it does **not** enumerate delegated-agent availability; it only confirms GitHub identity context.

**User validation**: Manual testing confirmed that using a *different* delegated agent for review (e.g., Claude for review, Copilot for implementation) yields higher-quality review feedback than same-agent self-check. This independent-perspective principle is the foundation for FR-021 (cross-agent routing).

**Decision**:

- FR-022: `specrew init` detects Copilot availability and which Copilot-accessible delegated agents (Copilot, Claude, Codex) are currently exposed, then prompts the user interactively for per-agent consent. Non-interactive default: Copilot-only. Detected-but-disabled agents remain available for opt-in via re-run. Billing/cost context is not collected or displayed by Specrew — consent is the only gate, and any cost implications are between the user and GitHub.
- FR-021: When multiple delegated agents are enabled, Reviewer and Spec Steward roles preferentially route to a non-Implementer agent, preserving independent perspective. Agent preference is per-role, configurable in `role-assignments.yml`.
- V-R7-1 implementation probe: use `copilot --version` plus active-session env markers to detect Copilot runtime, and use `copilot help config` to detect Claude/Codex family exposure. If `copilot help config` is unavailable or unparseable, mark delegated-agent availability as unavailable and continue bootstrap without failure.

**Rationale**:

- Explicit opt-in respects user agency; billing is GitHub's surface to manage.
- Independent-reviewer principle improves review quality (validated by user practice).
- Per-role delegation flexibility allows projects to choose review isolation level without adding a second Squad runtime.

**Alternatives considered**:

- Copilot-only with no delegated review-agent support: Leaves user unable to leverage independent review benefit.
- Direct standalone CLI invocation of Claude/Codex: Breaks the v1 Copilot-only Squad runtime model and complicates governance.
- Auto-enable all detected agents: Violates the explicit-consent principle; user must opt in per agent.
- Fixed agent assignment (e.g., always use Claude for review): Reduces flexibility for users with different agent access levels.
- Surfacing billing/cost context in the consent prompt: Rejected. Specrew cannot reliably enumerate GitHub's billing model, and duplicating it would risk drift from the authoritative source. Consent alone is the gate.

**Validation tasks (tracked in iteration plans)**:

- **V-R7-1 (Iteration 1, blocks T-011)**: Confirm the GitHub Copilot / Agent HQ detection API shape used to enumerate selectable agents (Copilot default, Claude, Codex). Verify that `gh copilot` or the equivalent CLI/API surface returns a deterministic list; document the exact command, expected output schema, and graceful-degradation behavior if Agent HQ is not exposed for the user's org/plan.
- **V-R7-2 (Iteration 2, completed 2026-05-02)**: Squad already exposes a viable routing surface for FR-021. The installed Squad runtime resolves per-agent model overrides from `.squad/config.json` via `agentModelOverrides`, and the SDK config schema also supports role-to-model mapping through `config.models.roleMapping`. For Specrew's markdown-first integration, no Specrew-side wrapper is required: `preferred_agent` in `.specrew/role-assignments.yml` can be translated into the corresponding Squad agent override entries for `spec-steward`, `reviewer`, `implementer`, and other baseline roles. Remaining implementation work is translation and guardrails: map `copilot` / `claude` / `codex` consented families to concrete model IDs exposed by `copilot help config`, persist those IDs into `.squad/config.json`, and fall back to Copilot when the preferred family is unavailable or not consented.
