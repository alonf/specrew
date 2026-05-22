# Feature Specification: Launch-Mode Boundary Enforcement

**Feature Branch**: `039-launch-mode-boundary-enforcement`  
**Created**: 2026-05-22  
**Status**: Draft  
**Input**: User description: "Quality Bar Mission — F-039 / Proposal 065 (Launch-Mode Boundary Enforcement). Hook-enforced boundaries via tool-level defense-in-depth to prevent agent boundary bypass even when --autonomous mode is active. Architectural reinforcement of Proposal 066's behavioral fix."

## Clarifications

### Session 2026-05-22

- Q: What happens when `--autonomous` is combined with `--prompt-approvals`? Should lifecycle boundary enforcement override tool-call approval mode, or should both layers be independently enforced? → A: Lifecycle boundary enforcement is independent from tool-call approval mode. Lifecycle boundaries must still stop for explicit human authorization even when tool approvals are relaxed or autonomous.
- Q: Where should BoundaryClassificationPolicy be stored: `.specrew/config.yml`, `.squad/config.json`, or per-feature in `specs/<N>/boundary-policy.yml`? → A: Policy lives in `.specrew/config.yml` (centralized project configuration).
- Q: What is the expected behavior when a user force-quits Copilot CLI mid-boundary (Ctrl+C)? Should restart recovery detect incomplete boundary transitions and prompt for continuation or rollback? → A: Use the existing recovery-mode choice flow (resume / rollback / bypass stale state) rather than silent auto-resume.

### Session Constraints (F-039 Delivery)

This feature work operates under the following hard constraints specified by the requestor:

- **Scope boundary**: F-039 only in this session; do not start F-040 work
- **Approval discipline**: No autopilot bypass of approval boundaries for F-039 itself (dogfooding the enforcement mechanism)
- **Integration context**: Compose with Proposal 066 / --autonomous opt-in context from commit `c55ec92` and retroactive proposal at `ecd7b6d`
- **Mirror parity**: Touched files in `extensions/specrew-speckit` must be mirrored to `.specify/` directory structure
- **Quality gates**:
  - Markdown lint pre-boundary gate is live and must pass before boundary advancement
  - Repetition detector is live; avoid redundant unchanged validator reruns
  - PR-open waits for GitHub Copilot review findings before merge authorization

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lifecycle Boundary Protection During Autonomous Mode (Priority: P1)

Platform engineers and project leads run Specrew with `--autonomous` for overnight unattended feature work. The system must enforce lifecycle approval boundaries (specify, clarify, plan, tasks, before-implement, review-signoff, retro, iteration-closeout, feature-closeout) regardless of agent behavior, ensuring no scope decisions or quality gates are bypassed without explicit human authorization.

**Why this priority**: Core value proposition of Specrew governance - boundaries exist to preserve human oversight at critical decision points. Without enforcement, autonomous mode could auto-resolve substantive scope, architecture, or quality decisions that require human judgment, undermining the entire governance model.

**Independent Test**: Can be fully tested by running `specrew start --autonomous` with a test feature and verifying that execution stops at each lifecycle boundary, waiting for explicit human authorization before advancing, even if the agent's response text suggests it should continue.

**Acceptance Scenarios**:

1. **Given** Specrew is running in `--autonomous` mode and has completed specification, **When** the agent reaches the `/speckit.clarify` boundary, **Then** the CLI runtime blocks further execution and prompts for explicit human authorization before proceeding
2. **Given** Specrew is at the `plan` boundary in `--autonomous` mode and the agent's response includes text suggesting auto-advancement, **When** the CLI evaluates the boundary condition, **Then** the runtime hook overrides the agent suggestion and enforces the approval gate
3. **Given** a feature is at the `review-signoff` boundary in `--autonomous` mode, **When** the reviewer agent completes its assessment, **Then** execution stops and requires explicit human signoff even if the review passed all checks
4. **Given** Specrew is running with `--allow-all` but NOT `--autonomous`, **When** any lifecycle boundary is reached, **Then** the boundary hook still enforces the stop (tool approval and lifecycle advancement are independent concerns)

---

### User Story 2 - Boundary Enforcement Configuration and Observability (Priority: P2)

Project administrators need visibility into which boundaries are enforced, when enforcement events occur, and whether any bypass attempts were detected. The system must log all boundary enforcement events to `.squad/decisions.md` with sufficient detail for audit and debugging.

**Why this priority**: Governance without observability is governance theater. Teams need evidence that boundaries are actually being enforced and alerts when enforcement logic fires, so they can validate the system is protecting their decision-making process.

**Independent Test**: Can be fully tested by running a feature lifecycle and examining `.squad/decisions.md` for boundary enforcement entries at each lifecycle stage, verifying timestamp, boundary type, enforcement result, and any agent behavior that triggered the hook.

**Acceptance Scenarios**:

1. **Given** a feature progresses through the `specify` → `clarify` boundary, **When** the boundary hook enforces the gate, **Then** an enforcement entry is written to `.squad/decisions.md` with timestamp, boundary_type, enforcement_action, and agent_response_context
2. **Given** an agent attempts to auto-advance through a `human-judgment-required` boundary, **When** the hook detects the bypass attempt, **Then** the enforcement log includes a bypass_attempt flag and the text pattern that triggered detection
3. **Given** a project administrator runs `specrew where`, **When** the dashboard renders, **Then** it displays boundary enforcement status for the current feature including last-enforced boundary and total enforcement events

---

### User Story 3 - Boundary Classification Integration (Priority: P3)

When Proposal 038's boundary classification system ships (human-judgment-required, mechanical-execution, strategic-progression), the enforcement hooks must respect the per-class enforcement policies. Mechanical-execution boundaries allow announcement-and-continue; human-judgment-required boundaries enforce hard stops.

**Why this priority**: Deferred until Proposal 038 ships, but the hook architecture must be designed to accommodate per-class policies. Without this, every boundary becomes a hard stop, degrading the user experience for routine mechanical work (e.g., auto-repair from concrete review findings).

**Independent Test**: Can be fully tested (after Proposal 038 ships) by configuring a boundary as `mechanical-execution` class, triggering it during a feature, and verifying that the agent can announce-and-continue rather than stopping for paste-authorization.

**Acceptance Scenarios**:

1. **Given** Proposal 038 has shipped and the `review-repair` boundary is classified as `mechanical-execution`, **When** the reviewer agent completes assessment with concrete repair instructions, **Then** the enforcement hook allows announcement-and-continue behavior per the boundary class policy
2. **Given** a boundary is classified as `strategic-progression` (e.g., iteration advancement), **When** the coordinator reaches the boundary, **Then** the hook enforces a hard stop with explicit authorization prompt regardless of agent recommendation

---

### Edge Cases

- Tool-call approval mode (`--allow-all` vs `--prompt-approvals`) and lifecycle boundary enforcement are independent enforcement dimensions. Both layers operate simultaneously: `--autonomous` with `--prompt-approvals` will prompt for individual tool approvals while still enforcing hard stops at lifecycle boundaries requiring human judgment.
- Mid-feature configuration changes (e.g., user starts with default mode, then wants to switch to `--autonomous` mid-implementation) are implementation details best addressed during planning phase based on session-state transition logic.
- Hook failure behavior: Enforcement hooks are fail-safe per FR-006 - if hook execution fails, default behavior is to block advancement and log error to `.squad/log/enforcement-errors.log`.
- Session-state tracking composition: Boundary enforcement state is persisted alongside existing session state per FR-008 - stored in `.specrew/start-context.json` under a dedicated `boundary_enforcement` section with fields: last_enforced_boundary, enforcement_events_count, bypass_attempts_count.
- Force-quit recovery (Ctrl+C mid-boundary): On restart, the system uses the existing recovery-mode choice flow (resume from last checkpoint / rollback to previous stable state / bypass stale state with warning) rather than silently auto-resuming. Incomplete boundary transitions are detected via `.specrew/start-context.json` boundary_enforcement state and trigger the recovery prompt.

### Additional Acceptance Criteria (from Proposal 065)

- **AC3 - Ambiguous Verdict Handling**: When a maintainer types an ambiguous verdict such as "looks good", "yep", "continue", "fine", or "okay" (i.e., phrases that do not match the recognized verdict shapes defined in Proposal 065 Pillar 2), the verdict parser MUST return `Authorized = $false`, the skill MUST block execution, and the system MUST surface a directive containing the recognized verdict shapes. This ensures that only explicit, structured verdicts are accepted for boundary authorization.

- **AC6 - Schema Migration for Pre-065 Sessions**: When a pre-065 Specrew installation (session-state files without `boundary_enforcement` section in `.specrew/start-context.json`) is upgraded, the first `specrew start` after upgrade MUST surface a migration directive to the user. After human acknowledgment, the system MUST write the `boundary_enforcement` section with `enabled = true` and empty verdict/bypass history. This ensures graceful migration from permissive legacy behavior to enforcement-enabled behavior.

- **AC9 - Compound Verdict Syntax**: The verdict parser MUST recognize compound verdict syntax of the form `approved for <boundary-A> AND <boundary-B>` (e.g., `approved for review-boundary AND review-signoff`), authorizing advancement across two boundaries in a single verdict. The parser MUST use an AND-form regex pattern as specified in Proposal 065 Pillar 2 to detect and parse compound verdicts. This enables efficient authorization for substantive-review workflows that legitimately progress multiple boundaries.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST enforce lifecycle approval boundaries (specify, clarify, plan, tasks, before-implement, review-signoff, retro, iteration-closeout, feature-closeout) in all launch modes (default gate-respecting, `--autonomous`, and `--prompt-approvals`)
- **FR-002**: System MUST implement enforcement via CLI-level hooks that intercept agent responses at boundary detection points, independent of agent prose discipline
- **FR-003**: Enforcement hooks MUST block CLI continuation when a `human-judgment-required` boundary is detected, requiring explicit user authorization (enter/Y/approve) before advancing
- **FR-004**: System MUST log every boundary enforcement event to `.squad/decisions.md` with fields: timestamp, boundary_type, enforcement_action (blocked/allowed), launch_mode, agent_response_snippet (first 200 chars)
- **FR-005**: System MUST detect bypass attempts when agent response text includes advancement signals (e.g., "Continuing to next phase", "Proceeding with implementation") at a hard-stop boundary and override the suggestion
- **FR-006**: Enforcement hooks MUST be fail-safe: if hook execution fails, default behavior is to block advancement and log error to `.squad/log/enforcement-errors.log`
- **FR-007**: System MUST distinguish between tool-call approval (`--allow-all` vs `--prompt-approvals`) and lifecycle-gate advancement (`--autonomous` vs default) as independent enforcement dimensions
- **FR-008**: Boundary enforcement state MUST be persisted to `.specrew/start-context.json` under a new `boundary_enforcement` section with fields: last_enforced_boundary, enforcement_events_count, bypass_attempts_count
- **FR-009**: The `specrew where` dashboard MUST display boundary enforcement summary: current boundary status, last enforcement timestamp, total enforcement events for the active feature
- **FR-010**: System MUST provide a bypass mechanism for emergency recovery (e.g., `specrew start --bypass-boundary-enforcement`) that logs the bypass event with mandatory reason parameter

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 maps to FR-001, FR-002, FR-003, FR-005, FR-006, FR-007 (core enforcement mechanics)
- **TG-002**: User Story 2 maps to FR-004, FR-008, FR-009 (observability and audit trail)
- **TG-003**: User Story 3 maps to FR-003 (boundary classification integration - deferred until Proposal 038 ships)
- **TG-004**: Expected owner roles:
  - **Implementer**: Build enforcement hooks, CLI intercept logic, state persistence
  - **Reviewer**: Validate fail-safe behavior, audit log completeness, integration with session state
  - **Security Specialist** (if available): Review bypass mechanism, ensure no privilege escalation paths
- **TG-005**: Intended delivery:
  - **Iteration 1 (MVP)**: FR-001 through FR-009 (core enforcement + observability)
  - **Iteration 2 (optional)**: Integration with Proposal 038 boundary classification when available
- **TG-006**: Known spec/implementation conflict: Proposal 038 is still candidate status; FR-003 enforcement logic must be designed with extension points for per-class policies but initially implements uniform `human-judgment-required` behavior across all boundaries. Reconciliation path: when Proposal 038 ships, add boundary-class configuration layer that modulates enforcement strictness per boundary type.

### Key Entities *(include if feature involves data)*

- **BoundaryEnforcementEvent**: Represents a single enforcement action at a lifecycle boundary
  - Attributes: timestamp, boundary_type (specify|clarify|plan|tasks|before-implement|review-signoff|retro|iteration-closeout|feature-closeout), enforcement_action (blocked|allowed|bypassed), launch_mode, agent_response_snippet, bypass_attempt_detected (boolean)
  - Persisted to: `.squad/decisions.md` (append-only log format)

- **BoundaryEnforcementState**: Tracks cumulative enforcement activity for the active feature
  - Attributes: last_enforced_boundary, enforcement_events_count, bypass_attempts_count, emergency_bypass_active (boolean)
  - Persisted to: `.specrew/start-context.json` under `boundary_enforcement` section

- **BoundaryClassificationPolicy**: [Future - Proposal 038 integration] Maps boundary types to enforcement policies
  - Attributes: boundary_type, enforcement_class (human-judgment-required|mechanical-execution|strategic-progression), allow_auto_advance (boolean)
  - Persisted to: `.specrew/config.yml` (centralized project configuration for boundary classification policies)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero lifecycle boundaries are bypassed without explicit human authorization across 100 test runs with `--autonomous` flag active
- **SC-002**: Every boundary enforcement event is logged to `.squad/decisions.md` with complete required fields (timestamp, boundary_type, enforcement_action, launch_mode) achieving 100% log completeness
- **SC-003**: Enforcement hook execution overhead adds less than 200ms latency to boundary transitions (measured from agent-response-complete to authorization-prompt-displayed)
- **SC-004**: Emergency bypass mechanism (if invoked) requires mandatory reason parameter and logs bypass event, achieving 100% audit trail coverage even for override scenarios
- **SC-005**: Integration tests validate fail-safe behavior: simulated hook failures result in blocked advancement rather than silent bypass, achieving 100% fail-safe compliance
- **SC-006**: Dashboard displays accurate boundary enforcement status with no more than 5-second lag between enforcement event and dashboard visibility
- **SC-007**: Enforcement hooks correctly distinguish tool-call approval from lifecycle-gate advancement, allowing `--allow-all --autonomous` to run tools freely while still stopping at lifecycle boundaries

## Assumptions

- Enforcement hooks will integrate with the existing Copilot CLI launch infrastructure in `scripts/specrew-start.ps1` without requiring Copilot CLI upstream modifications
- Boundary detection can be reliably performed via pattern matching on coordinator agent responses combined with Squad skill exit markers (e.g., `/speckit.clarify` skill completion signals specify→clarify boundary)
- The existing `.squad/decisions.md` format can accommodate enforcement log entries without schema conflicts with boundary-sync entries from F-020
- Platform support: enforcement hooks will work uniformly across Windows PowerShell, macOS/Linux bash, and any future multi-host runtimes (Claude Code, Codex, VS Code Chat per Proposals 024/069)
- Force-quit recovery integrates with existing `.specrew/start-context.json` session state and recovery prompt logic to handle incomplete boundary transitions gracefully

## Out of Scope *(mandatory)*

- **Launch posture visibility**: Companion Proposal 098 (Launch Posture Visibility) will surface enforcement state at launch (e.g., `[BYPASS ACTIVE]` banner in startup diagnostics, boundary enforcement mode in `.squad/identity/now.md`). F-039 ships enforcement mechanics without visibility surfaces; Proposal 098 is composable and independent.

## Composition with Other Proposals *(mandatory)*

- **Proposal 066 (Gate-Respecting Default, shipped 2026-05-20)**: Predecessor. Proposal 066 made `--autopilot` opt-in at the host level; F-039 institutes mechanical enforcement at the tool-call level. Together: Proposal 066 prevents host-level continuation between turns; F-039 prevents agent-driven chaining across tool calls.

- **Proposal 063 (Substantive Intake Questioning, F-040 next)**: Hard prerequisite consumer. Without F-039's mechanical enforcement, Proposal 063's intake questions can be auto-chained past by the agent in a single turn. F-039 ships FIRST to establish enforcement baseline before F-040 intake work begins.

- **Proposal 090 (Closeout Lifecycle Sync Commands, shipped 2026-05-22)**: Composes with schema validator. Test-SessionStateBoundaryCanonical (added by Proposal 090) extends to validate the new `boundary_enforcement` section in `.specrew/start-context.json`. F-039 leverages Proposal 090's validation infrastructure.

- **Proposal 098 (Launch Posture Visibility, candidate)**: Companion. Proposal 098 reads F-039's `boundary_enforcement` state from `.specrew/start-context.json` and surfaces enforcement mode, bypass status, and boundary history in launch diagnostics. Composable; F-039 ships enforcement mechanics without visibility surfaces.

- **Proposal 015 (Expertise-Aware Adaptive Interaction, candidate)**: Future composition. Proposal 015's expertise dial may modulate verbosity of directive messages emitted by F-039's authorization gate — concise for experts, explanatory for beginners. F-039 ships with fixed directive shape; Proposal 015 modulates presentation when it ships.

- **Proposal 069 (Multi-Host Launch Path, candidate)**: Host-agnostic by design. F-039's skill-level authorization gate (Pillar 1) operates at tool-call layer, not host layer. When Proposal 069 ships multi-host support (Claude Code, Codex CLI, VS Code Chat), F-039's enforcement mechanism extends to all hosts without modification.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Codex (preferred) / Copilot (fallback per `.specrew/start-context.json`)
- **Iteration Facilitator**: Squad Coordinator (per Specrew baseline roster)
- **Capacity Model**: Story Points + 2-week iteration cadence (standard Specrew delivery model)
- **Drift Signals**:
  - Boundary enforcement events logged to `.squad/decisions.md` will be monitored for bypass attempts; any detected bypass triggers immediate review
  - Validator Hardening (Proposal 004) gap analysis should add enforcement-log completeness check as new gap item
  - Integration with Proposal 054 pre-merge lifecycle verification gate: add Scenario D (boundary enforcement verification) to the gate baseline
- **Human Oversight Points**:
  - **Specify boundary** (this document): Approve feature scope and clarification questions
  - **Clarify boundary**: All clarification questions resolved - spec ready for planning
  - **Plan boundary**: Approve implementation design including enforcement hook architecture (intercept points, state schema, fail-safe strategy)
  - **Before-Implement boundary**: Authorize implementation start after plan validation
  - **Review-Signoff boundary**: Explicit signoff that enforcement hooks meet security and fail-safe requirements
  - **Iteration-Closeout boundary**: Approve iteration artifacts including enforcement event audit trail
  - **Feature-Closeout boundary**: Final signoff before merge to main
