# Feature Specification: Hook-Driven Session Bootstrap

**Feature Branch**: `174-hook-driven-session-bootstrap`
**Created**: 2026-06-08
**Status**: Draft
**Input**: Proposal 172: `proposals/172-hook-driven-session-bootstrap.md`

## User Scenarios & Testing

### User Story 1 - Direct host launch bootstraps the session (Priority: P1)

A Specrew user who starts a supported host directly, without running
`specrew start`, receives the same practical session-start orientation Specrew is
expected to provide: project posture, lifecycle state, handover context when
available, and a Resume / New / Pick-feature decision point.

**Why this priority**: F-171 already shipped a SessionStart hook dispatcher that
fires on direct host launch. This feature's main value is turning that reliable
hook surface into the primary bootstrap path.

**Independent Test**: Launch each supported hook-bound host directly in a
Specrew project with no valid active session anchor and verify the SessionStart
hook injects a bootstrap directive that the agent renders as visible
orientation plus the Resume / New / Pick-feature menu.

**Acceptance Scenarios**:

1. **Given** a Specrew project with no valid active session anchor, **When** the
   user launches a hook-bound host directly, **Then** the SessionStart hook
   injects the full bootstrap directive.
2. **Given** a full bootstrap directive, **When** the agent receives it, **Then**
   the agent renders orientation and any handover context as visible prose
   before presenting the Resume / New / Pick-feature choice.
3. **Given** the menu is rendered on Claude, Codex, Copilot, or Cursor, **When**
   a structured selection primitive is available, **Then** the user can still
   see the rendered orientation and menu text before the picker is offered.

---

### User Story 2 - Launcher remains useful without double-bootstrap (Priority: P1)

A Specrew user who still runs `specrew start` can select the host and use
backward-compatible launcher behavior without receiving duplicate orientation
when the host SessionStart hook also fires.

**Why this priority**: Maintainer direction explicitly keeps `specrew start` for
compatibility and host selection. The posture changes, but the command remains
part of the product.

**Independent Test**: Run `specrew start` into a hook-bound host and verify the
launcher-owned behavior still works while hook dedupe prevents duplicate
bootstrap content in the same session.

**Acceptance Scenarios**:

1. **Given** the user invokes `specrew start` with a host selection, **When** the
   selected host starts, **Then** host selection and supported launcher flags
   continue to work.
2. **Given** the launcher and SessionStart hook both participate in one startup,
   **When** the hook dispatcher evaluates the event, **Then** the user receives
   at most one bootstrap surface for that session.
3. **Given** launcher-generated prompts or docs describe session orientation,
   **When** this feature ships, **Then** they no longer claim `specrew start` is
   the sole or recommended orientation path.

---

### User Story 3 - Handover round-trip informs the next launch (Priority: P2)

A Specrew user ending a session gets a durable handover written by the
SessionEnd path, and the next SessionStart bootstrap reads that handover so the
agent can summarize where to resume.

**Why this priority**: Proposal 172 composes with Proposal 130 Pillar 4 rather
than re-authoring handover semantics. The integration still needs to prove that
the shipped hooks round-trip the handover through the primary bootstrap.

**Independent Test**: End a session through the Proposal 130 SessionEnd source
set, then launch again and verify the SessionStart bootstrap surfaces the
handover timestamp and recommended next step.

**Acceptance Scenarios**:

1. **Given** a supported SessionEnd source, **When** the session exits cleanly,
   **Then** the handover writer records a Proposal 130-compatible handover.
2. **Given** a readable handover exists, **When** the next SessionStart
   bootstrap runs, **Then** the bootstrap directive references the handover and
   asks the agent to read and summarize it.
3. **Given** no handover is present or the handover is stale, **When** the
   bootstrap runs, **Then** the user still receives orientation and menu guidance
   without treating stale handover data as current state.

---

### User Story 4 - Stale and non-portable session anchors are cleared (Priority: P2)

A Specrew user launching from main after a feature has been merged or closed is
not offered recovery for that completed feature, especially when the saved
anchor points to an absolute path from a different or defunct worktree.

**Why this priority**: The 2026-06-08 Codex launch of v0.33.0-beta1 offered the
already-merged Feature 171 as a stale recovery candidate because committed
session-state files still anchored to an absolute path. This must not ride into
main again.

**Independent Test**: Seed session-state files with an anchored feature that is
already merged or closed, including an absolute-path anchor to another worktree,
then launch bootstrap and verify the anchor is invalidated before recovery is
offered.

**Acceptance Scenarios**:

1. **Given** session state anchors to an already merged or closed feature,
   **When** bootstrap evaluates the state, **Then** it clears the anchor instead
   of offering it as a resume or recovery candidate.
2. **Given** a session anchor contains an absolute worktree path, **When** the
   project root differs from that path, **Then** bootstrap treats the anchor as
   non-portable and requires re-resolution from project-local feature metadata
   before using it.
3. **Given** feature closeout or merge completes, **When** state is synchronized,
   **Then** committed session-state files do not retain an active anchor to the
   closed feature.

### Edge Cases

- The hook fires in a project with `.specrew/` present but no feature directory.
- A handover file exists but fails freshness, schema, or path-portability checks.
- A SessionStart event fires immediately after `specrew start` generated a
  launcher prompt for the same session.
- A structured picker tool is available but would hide or collapse the visible
  menu content unless the agent renders prose first.
- Multiple hosts differ in SessionStart / SessionEnd payload shape or in their
  support for structured user-choice primitives.

## Requirements

### Functional Requirements

- **FR-001**: The SessionStart B2 launch trigger MUST become the primary
  session bootstrap path for supported hook-bound hosts.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-002**: The B2 bootstrap provider MUST inject a directive that tells the
  agent to render Proposal 143 orientation content, read Proposal 130 handover
  context when present, and present Proposal 077 Resume / New / Pick-feature
  semantics.
  **Owner**: Implementer, Spec Steward. **Iteration**: 001.
- **FR-003**: The hook MUST remain non-interactive: it MUST NOT ask questions,
  wait for input, or branch on the user's menu response.
  **Owner**: Implementer, Security Specialist. **Iteration**: 001.
- **FR-004**: The agent-facing bootstrap directive MUST require visible prose
  rendering before any host structured selection primitive is offered.
  **Owner**: Implementer, Reviewer. **Iteration**: 001.
- **FR-005**: The implementation MUST empirically verify Resume / New /
  Pick-feature rendering behavior on Claude, Codex, Copilot, and Cursor before
  locking the final menu shape.
  **Owner**: Reviewer. **Iteration**: 001.
- **FR-006**: `specrew start` MUST remain available for backward compatibility,
  host selection, supported flag pass-through, and explicit resume/intake
  launch flows.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-007**: Launcher-then-hook startup MUST be idempotent so one session does
  not receive duplicate bootstrap orientation.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-008**: `specrew start` prompts and documentation MUST be updated so they
  no longer claim sole ownership of session orientation.
  **Owner**: Implementer, Spec Steward. **Iteration**: 001.
- **FR-009**: SessionEnd handover writing MUST be wired through the shipped
  hook deployment path while preserving Proposal 130's handover format and
  source discrimination.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-010**: SessionStart bootstrap MUST read a valid Proposal 130-compatible
  handover when present and surface its timestamp and recommended next step to
  the agent directive.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-011**: B2 MUST keep F-171 B1 post-compaction and B3 boundary-cross
  behavior unchanged.
  **Owner**: Implementer, Reviewer. **Iteration**: 001.
- **FR-012**: B4 pre-compaction capture and Antigravity binding MUST remain
  deferred and MUST NOT be implemented by this feature.
  **Owner**: Spec Steward, Reviewer. **Iteration**: 001.
- **FR-013**: The bootstrap state resolver MUST clear active session anchors
  when the anchored feature is already merged, closed, or otherwise no longer
  resumable.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-014**: Feature merge or feature closeout synchronization MUST prevent
  committed session-state files from retaining an active anchor to the closed
  feature.
  **Owner**: Implementer, Reviewer. **Iteration**: 001.
- **FR-015**: Absolute worktree-path anchors MUST be treated as non-portable;
  bootstrap MUST re-resolve them against project-local feature metadata before
  offering resume or recovery.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-016**: The design-analysis workshop MUST resolve, before planning, the
  exact `specrew start` versus hook division of labor, the per-host menu
  rendering shape, and the B2 full-bootstrap versus lightweight trigger.
  **Owner**: Planner, Spec Steward. **Iteration**: 001.

### Traceability & Governance Requirements

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery
  window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit
  reconciliation path.
- **TG-005**: The plan MUST reference Proposal 130, Proposal 143, Proposal 077,
  and Proposal 078 as composed sources rather than re-specifying their owned
  formats or semantics.
- **TG-006**: The review MUST classify hook bootstrap behavior as implemented,
  enforced, observable, and documented, with a gap ledger for any missing
  dimension.

### Key Entities

- **Bootstrap Directive**: Structured hook-injected instruction consumed by the
  agent. It carries orientation scope, handover-read guidance, menu-rendering
  requirements, and idempotency metadata without becoming interactive itself.
- **Session Anchor**: Saved lifecycle state pointing at a feature, boundary,
  iteration, task, timestamp, and source path. It is resumable only when the
  referenced feature is project-local, active, and not merged or closed.
- **Handover Record**: Proposal 130-compatible markdown handover plus index
  metadata written by SessionEnd and read by SessionStart.
- **Bootstrap Mode**: Classification for B2 behavior: full bootstrap for fresh
  or cleared state, lighter welcome-back for valid active recent state, or
  cleared-state intake when anchors are invalid.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Direct-launch tests for Claude, Codex, Copilot, and Cursor show
  the bootstrap orientation and Resume / New / Pick-feature menu rendered
  before any structured picker.
- **SC-002**: A launcher-then-hook startup emits no duplicate bootstrap content
  in the same session.
- **SC-003**: A SessionEnd-to-SessionStart test writes a Proposal
  130-compatible handover and surfaces it on the next launch.
- **SC-004**: Tests prove merged, closed, and non-portable absolute-path
  session anchors are cleared before resume or recovery is offered.
- **SC-005**: Regression tests prove B1 post-compaction and B3 boundary-cross
  behavior remain unchanged from F-171.
- **SC-006**: Documentation and generated prompts identify the SessionStart
  hook as the primary bootstrap and `specrew start` as a retained compatibility
  and host-selection path.

## Assumptions

- Proposal 146 / Feature 171 is already shipped in v0.33.0-beta1 and provides
  the hook dispatcher, kill switch, circuit breaker, journal, dedupe, and B2
  trigger substrate.
- Proposal 130 Pillar 4 owns handover format and source discrimination; this
  feature wires those behaviors and only carries missing script integration if
  the substrate has not shipped by implementation time.
- Proposal 143 owns orientation and recovery menu content; Proposal 077 owns
  Resume / New / Pick-feature semantics; Proposal 078 owns handoff prose
  conventions.
- This feature is one iteration unless empirical host verification exposes a
  menu-rendering blocker that requires explicit human defer or scope split.
- No Antigravity hook binding or B4 pre-compaction capture behavior will be
  added in this feature.

## Governance Alignment

- **Spec Steward**: Spec Steward (delegated: codex) owns synthesis boundaries
  and prevents re-authoring referenced proposals.
- **Iteration Facilitator**: Planner (delegated: codex) owns design-analysis
  resolution and before-implement readiness.
- **Capacity Model**: Story points; expected 8-13 SP when Proposal 130 Pillar 4
  substrate is available, plus 5-8 SP only if handover scripts must be carried.
- **Drift Signals**: `iterations/001/drift-log.md`, traceability check after
  tasks, and reviewer gap ledger at review.
- **Human Oversight Points**: Human approval is required at specify, clarify,
  design-analysis, plan, tasks, before-implement, review, retro, and feature
  closeout boundaries.

