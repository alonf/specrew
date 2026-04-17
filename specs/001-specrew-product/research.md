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
