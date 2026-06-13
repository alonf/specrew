# Feature Specification: Hook-Driven Session Bootstrap

**Feature Branch**: `174-hook-driven-session-bootstrap`
**Created**: 2026-06-08
**Status**: Draft
**Input**: Proposal 172: `proposals/172-hook-driven-session-bootstrap.md`

## Clarifications

### Session 2026-06-08

- Q: Default freshness window for the FR-019 local same-worktree concurrency
  warning (how long a SessionStart marker keeps a session "possibly active")?
  → A: 1 hour, configurable and overridable. A marker older than one hour is
  treated as stale and does not raise an active-session warning.
- Q: Shape of the FR-021 "commit/push to continue on another machine"
  affordance at the next bootstrap? → A: An advisory state line only — surface
  "uncommitted handover/work from last session" and let the user commit/push
  manually; no new persistent menu item beyond Resume / New / Pick-feature.

### Session 2026-06-13

- Q: After the iteration-010 multi-host dogfood surfaced the DF-3/4/5/7
  boundary-authoring + verdict-integrity cluster, how does the spec evolve
  (iteration 011)? → A: FR-022's PERSIST mechanism is refined — the rendered
  packet is captured mechanically, unlocked by T002's Stop-hook transcript
  access (the premise absent at iteration-005's detect-only decision); the
  "agent-authored body" and "authoring not forced" guarantees are UNCHANGED
  (capture ≠ author). Two new requirements add boundary-authorization
  INTEGRITY: FR-026 (the recorded verdict derives from captured human input,
  never fabricated nor attributed to the git committer) and FR-027 (a committed
  boundary ≠ an authorized boundary on resume). Guarantees only; mechanism
  (capture timing, match-strictness, the Antigravity fallback specifics) is the
  iteration-011 plan's job. Decisions locked in
  `iterations/011/fix-plan-draft.md`; deferral
  `f174-i010-defer-integrity-cluster-to-011`.

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

A Specrew user gets a durable, always-latest handover refreshed by the per-host
Stop (end-of-turn) path, and the next SessionStart bootstrap reads that handover
so the agent can summarize where to resume. Because every material turn refreshes
it in place, the handover survives a hard-kill with no clean exit (crash-safe,
SC-009).

**Why this priority**: Proposal 172 composes with Proposal 130 Pillar 4 rather
than re-authoring handover semantics. The integration still needs to prove that
the shipped hooks round-trip the handover through the primary bootstrap.

**Independent Test**: Trigger a per-host Stop (end-of-turn) after material work so
the rolling handover is refreshed, then launch again and verify the SessionStart
bootstrap surfaces the agent-authored handover body (or a hollow-handover warning
when the body is a placeholder), not merely the timestamp (iteration 005).

**Acceptance Scenarios**:

1. **Given** a per-host Stop event after a material change, **When** the turn
   completes, **Then** the Stop hook refreshes the always-latest Proposal
   130-compatible handover FLOOR and preserves the agent-authored body, writing a
   placeholder body only when none exists (iteration 005).
2. **Given** a readable handover with an agent-authored body exists, **When** the
   next SessionStart bootstrap runs, **Then** the bootstrap directive carries the
   authored body content (not just the timestamp) for the agent to surface
   (iteration 005).
3. **Given** no handover is present or the handover is stale, **When** the
   bootstrap runs, **Then** the user still receives orientation and menu guidance
   without treating stale handover data as current state.
4. **Given** a readable handover whose body is a placeholder (the previous session
   did not author it), **When** the next SessionStart bootstrap runs, **Then** the
   directive surfaces a PROMINENT hollow-handover warning and the user is the
   backstop - never a rich resume that does not exist (iteration 005, FR-022).

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
- Multiple hosts differ in SessionStart / Stop (end-of-turn) payload shape or in
  their support for structured user-choice primitives.

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
- **FR-009**: Handover writing MUST be wired through the shipped hook deployment
  path on the per-host **Stop (end-of-turn)** event (Claude `Stop`, Codex `Stop`,
  Copilot `agentStop`, Cursor `stop`) - PORTABLE across hosts, no SessionEnd
  dependency. It refreshes ONE local, always-latest rolling handover
  `.specrew/handover/session-handover.md` (overwrite-in-place; gitignored, never
  pushed; no timestamped files or index) ONLY on a material change (boundary moved
  OR tracked-file change since the last write). Preserve Proposal 130's schema -
  `schema: v1` frontmatter + the Pillar-2 6-section body
  (`proposals/130-specrew-switch-to-host-handover.md`, cross-referenced in code);
  24h default read freshness. The iteration-003 SessionEnd-only handover is
  SUPERSEDED (the Claude SessionEnd hook is removed). Iteration 005 splits the file
  into a hook-owned FLOOR (the `schema: v1` frontmatter, freshness, and the six
  section headers) and an AGENT-owned BODY (the section content): the Stop hook is
  transcript-blind, so it refreshes the floor and PRESERVES the agent body for the
  current boundary, writing a placeholder body only when none exists (FR-022); the
  agent authors the body via `Write-SpecrewHandoverContext`.
  **Owner**: Implementer. **Iteration**: 004, 005.
- **FR-010**: SessionStart bootstrap MUST read a valid Proposal 130-compatible
  handover when present and surface its recommended next step and the agent-authored
  body content (iteration 005) - not merely its timestamp - to the agent directive.
  When the body is a placeholder (the previous session did not author it), the
  bootstrap MUST surface a PROMINENT hollow-handover warning instead of a rich resume
  it does not have (FR-022).
  **Owner**: Implementer. **Iteration**: 001, 005.
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
  rendering shape, and the B2 full-bootstrap versus lightweight trigger. The
  2026-06-08 lens intake workshop resolved these design questions
  (see `lens-applicability.json` and `workshop/`); the design-analysis stop
  builds the component map and flows on those confirmed decisions.
  **Owner**: Planner, Spec Steward. **Iteration**: 001.
- **FR-017**: B2 bootstrap MUST validate a present handover against current
  project state (recorded-commit reachability, feature not merged or closed,
  branch/worktree portability, artifact consistency) before anchor
  classification, and MUST NOT treat a recent-but-invalid handover as
  authoritative resume state.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-018**: Bootstrap MAY write an advisory, local-only SessionStart marker
  (started_at, host, project_root, branch, head_commit) through the F-171
  journal, never committed and never rewriting the handover on startup, so a
  later launch can detect an unclean prior exit when the marker is newer than
  the latest handover.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-019**: Bootstrap MUST detect and surface a local same-worktree
  concurrent-session signal as advisory, non-blocking state using
  freshness-based metadata, with no lock or lease semantics. The default
  freshness window is 1 hour and MUST be configurable; a marker older than the
  window is treated as stale and raises no active-session warning.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-020**: The render-first contract in FR-004 MUST be enforced mechanically
  on hosts where a structured picker collapses prose (a `disallowed-tools`
  AskUserQuestion skill on Claude), not by directive instruction alone; a prose
  menu floor applies on every host, and a structured picker is layered on only
  where FR-005 host evidence proves it does not hide the rendered text.
  **Owner**: Implementer, Reviewer. **Iteration**: 001.
- **FR-021**: Stop-event rolling-handover writing MUST be write-only by default (no
  git add, commit, or push) - and since the handover is gitignored, it is local by
  construction; an opt-in configuration flag MAY enable a scoped local commit of the
  handover only (off by default), and the commit-or-push to continue on another
  machine MUST be offered at the next bootstrap as an advisory state line (no new
  persistent menu item) rather than at the per-turn Stop.
  **Owner**: Implementer. **Iteration**: 001.
- **FR-022**: The rolling-handover BODY MUST be agent-authored (the Stop hook is
  transcript-blind and cannot author rich content). The agent persists its
  re-entry/boundary packet AS the body via `Write-SpecrewHandoverContext` and renders
  the packet FROM that file, so what the human sees at a boundary equals what the next
  session inherits. The Stop hook MUST preserve an authored body for the current
  boundary and write a placeholder ONLY when none exists. A NON-BLOCKING mechanical
  detector MUST flag a hollow (placeholder) body - a same-session detection at the
  Stop (a self-documenting placeholder + a `.specrew/runtime/handover-journal.jsonl`
  record) AND a prominent warning at the next SessionStart. Authoring MUST NOT be
  forced, only DETECTED (the transcript-blindness ceiling; the human is the backstop).
  A Stop-event hook cannot warn the agent in-session (Stop is not an injection event
  and the P1 doctrine forbids blocking), so the proactive author-before-stop nudge is
  carried by the SessionStart directive (drift D-008).
  **Acceptance (iteration 005, qualified)**: the body-authoring machinery (the floor/body
  split, `Write-SpecrewHandoverContext`, the non-blocking detector, the bootstrap render) is
  BUILT and unit-tested in the dev tree. The LIVE behavior - the agent-authored handover firing
  in a DEPLOYED downstream project - is NOT MET in iteration 005 and is DEFERRED to iteration 006
  (the Stop provider cannot resolve its bootstrap components in a deployed tree; drift D-009,
  defer `f174-i005-defer-live-wiring`). Iteration 006 must carry a live-wiring floor that asserts
  a real deployed session writes the handover (and the launch contract) to disk.
  **Owner**: Implementer. **Iteration**: 005-006.
  **Amendment (iteration 011 — DF-3/DF-7, capture ≠ author)**: the iteration-010 multi-host
  dogfood proved (artifact-confirmed) that `Write-SpecrewHandoverContext` is NOT agent-callable —
  the module exports no such command — so the persist-path clause above is UNFOLLOWABLE, and the
  boundary handover sat at placeholders exactly when it should be richest. REFINED: the agent still
  RENDERS/authors the packet CONTENT, but its PERSISTENCE MUST NOT depend on the agent invoking a
  function. The rendered boundary packet MUST be captured into the body by a mechanism the agent
  cannot skip — the transcript-capable Stop hook capturing the rendered packet and/or an exposed
  authoring command — and the same write MUST set the boundary state (`active_boundary`). The
  "BODY MUST be agent-authored" and "authoring MUST NOT be forced" guarantees are UNCHANGED (the
  agent authors content; only PERSISTENCE becomes reliable). This evolution is unlocked by a real
  premise change: the "Stop hook is transcript-blind" justification for detect-only no longer
  holds — T002 (iteration 010) gave the Stop hook transcript access, so mechanical capture of the
  already-rendered packet is now feasible. Scope: hook-capable hosts; on a no-Stop-hook host
  (Antigravity) the body is recovered via `specrew start` reconciliation (FR-023). Mechanism
  (capture timing, exposed-command shape) is the iteration-011 plan's job; decisions locked in
  `iterations/011/fix-plan-draft.md` (defer `f174-i010-defer-integrity-cluster-to-011`).
  **Owner**: Implementer. **Iteration**: 011.
- **FR-023**: The B2 SessionStart bootstrap MUST hand the agent the SAME launch
  contract and session state as `specrew start` - the full launch prompt persisted to
  `.specrew/last-start-prompt.md` AND an initialized `boundary_enforcement` block in
  `.specrew/start-context.json` - by REUSING `specrew start`'s contract generator
  (`Get-StartPrompt`) and the existing boundary-enforcement state functions, NOT a
  separately authored directive (no drift). The injected directive MUST instruct the
  agent to READ those files and follow the governed lifecycle (do not bypass gates).
  The state write MUST be a preserve-merge of `boundary_enforcement` that keeps the
  existing session anchor intact - never the launcher-only fields, never a wholesale
  rewrite.
  **Owner**: Implementer. **Iteration**: 006.
- **FR-024**: Per-host INJECTION of the bootstrap contract (whether the SessionStart
  hook output actually reaches the model's context) MUST be EMPIRICALLY established, not
  assumed - in TWO parts, mirroring the SC-009-vs-SC-008 auto-vs-manual split. (a) The
  deployed live-wiring floor (SC-011) AUTO-proves the PLUMBING: the contract + state are
  written and read back on disk in a deployed layout AND the provider EMITS the per-host
  injection. (b) Whether that injection actually REACHES the model's context is a
  host-runtime behavior provable ONLY by a clean per-host dogfood OBSERVATION - it CANNOT
  be asserted by an on-disk test (a green plumbing floor on a host says nothing about
  whether its runtime delivered the additionalContext to the model). A host enters the
  PARITY SET (the hook DRIVES there) only when BOTH hold: the plumbing floor is green AND
  injection is observed to reach the model. Claude is satisfied by direct observation
  this iteration; codex / copilot / cursor are the enumerated clean re-tests (FR-005).
  `specrew start` remains the driver for the no-hook fallback host (Antigravity) and any
  hooked-but-non-injecting host. Hook DEPLOYMENT coverage is already resolved (claude /
  codex / copilot / cursor are hooked; Antigravity is the no-hook fallback) and MUST NOT
  be re-derived. The on-disk contract + state writes are host-agnostic and MUST happen
  regardless of injection, so a non-injecting host still has the files for a subsequent
  `specrew start`.
  **Owner**: Implementer, Reviewer. **Iteration**: 006.
- **FR-025**: The user-profile expertise intake (the four interaction dials) MUST be
  capturable at `specrew init`, not only at first `specrew start`, so a user who only
  ever opens a hook-driven host still gets the user-profile adaptation in the bootstrap
  banner. At init it MUST ask ONLY when the profile is ABSENT and the session is
  INTERACTIVE; non-interactive / `-Force` / CI inits MUST skip silently and never block
  automation. The profile remains user-level (`~/.specrew/user-profile.yml`, set once
  across all projects). `specrew start`'s existing first-run prompt is RETAINED as a
  fallback, and the SessionStart bootstrap directive MUST nudge the agent to surface
  `/specrew-user-profile` when the profile is absent (the hook cannot ask).
  **Owner**: Implementer. **Iteration**: 008.
- **FR-026**: The recorded boundary AUTHORIZATION (the
  `boundary_enforcement.verdict_history` entry and `last_authorized_boundary`) MUST derive from
  CAPTURED human input — the human's actual response to the boundary verdict packet. Boundary-sync
  MUST NOT fabricate a verdict (e.g. auto-generating `approved for <boundary>`) and MUST NOT
  attribute the approving human to the git committer. When no captured human verdict is available
  for the target boundary, the crossing MUST be recorded as UN-AUTHORIZED / agent-initiated — an
  honest audit trail — never as an approval. Scope: hook-capable hosts capture the verdict from the
  Stop / UserPromptSubmit transcript; on a no-hook host (Antigravity), where transcript capture is
  impossible, the crossing is recorded un-authorized and reconciled via `specrew start`. (Surfaced
  as DF-5: an agent advanced a boundary on a bare "continue" and the sync wrote
  `approved for clarify by <git committer>` with no human in the loop.)
  **Owner**: Implementer. **Iteration**: 011.
- **FR-027**: A resume MUST treat a committed boundary ARTIFACT (a `boundary(<stage>)` commit) as
  NOT an authorized boundary. The resume directive and `specrew where` MUST read
  `boundary_enforcement.last_authorized_boundary` as decisive and surface "awaiting your verdict
  for <stage>" when a boundary is committed but not human-authorized — never inferring closure from
  the commit, and never auto-advancing on a bare "continue". This complements FR-017 (handover
  validity) on the AUTHORIZATION axis. (Surfaced as DF-4: a resuming host read a `boundary(specify)`
  commit as approval and was poised to skip two un-authorized gates.)
  **Owner**: Implementer. **Iteration**: 011.

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

### Lens-Informed Requirements

- **LIR-001 (Architecture)**: Planning MUST compare at least two explicit
  structure options for the bootstrap provider and state why the selected
  decomposition keeps F-171 dispatcher behavior stable while adding B2
  bootstrap behavior.
- **LIR-002 (Integration)**: Planning MUST define producer/consumer contracts
  for SessionStart input, bootstrap directive output, Stop-event handover
  writing, and agent-rendered menu handling across Claude, Codex, Copilot, and
  Cursor.
- **LIR-003 (UI/UX)**: Planning MUST define the visible menu sequence and
  fallback behavior for hosts where a structured picker risks hiding the
  rendered orientation.
- **LIR-004 (Data)**: Planning MUST define validity checks for session anchors,
  handover freshness, project-local feature resolution, and absolute-path
  portability before any resume candidate is surfaced.
- **LIR-005 (Security)**: Planning MUST identify trust boundaries for hook
  event input, handover/session-state file reads, absolute paths, and generated
  agent directives, including failure-safe behavior for untrusted or stale
  state.
- **LIR-006 (Observability)**: Planning MUST specify journal, breaker, dedupe,
  and test evidence that proves full bootstrap, light welcome-back, and
  cleared-anchor paths are distinguishable after execution.
- **LIR-007 (NFR)**: Planning MUST preserve backward compatibility,
  idempotency, B1/B3 regression safety, and deferred B4/Antigravity scope as
  measurable review criteria.
- **LIR-008 (DevOps)**: Planning MUST describe deployment-loop and
  kill-switch impact for registering the per-host Stop handover writer and B2
  bootstrap provider without requiring a new install path.

### Key Entities

- **Bootstrap Directive**: Structured hook-injected instruction consumed by the
  agent. It carries orientation scope, handover-read guidance, menu-rendering
  requirements, and idempotency metadata without becoming interactive itself.
- **Session Anchor**: Saved lifecycle state pointing at a feature, boundary,
  iteration, task, timestamp, and source path. It is resumable only when the
  referenced feature is project-local, active, and not merged or closed.
- **Handover Record**: Proposal 130-compatible markdown rolling handover - one
  local, always-latest file (no index) refreshed on the per-host Stop event and
  read by SessionStart.
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
- **SC-003**: A Stop-to-SessionStart round-trip test refreshes the rolling
  Proposal 130-compatible handover and surfaces it on the next launch - the
  agent-authored body when present, or the hollow-handover warning when the body is a
  placeholder (iteration 005).
- **SC-004**: Tests prove merged, closed, and non-portable absolute-path
  session anchors are cleared before resume or recovery is offered.
- **SC-005**: Regression tests prove B1 post-compaction and B3 boundary-cross
  behavior remain unchanged from F-171.
- **SC-006**: Documentation and generated prompts identify the SessionStart
  hook as the primary bootstrap and `specrew start` as a retained compatibility
  and host-selection path.
- **SC-007**: The bootstrap emits a distinguishable journal record for each mode
  (full bootstrap, welcome-back, cleared-anchor), for the unclean-exit warning, and
  for a hollow-handover detection (iteration 005: `handover_placeholder` on the
  bootstrap record + the `hollow-handover-at-stop` Stop-event record), asserted by
  tests so the executed path is reconstructable after the fact.
- **SC-009**: The rolling handover is current after each material Stop (the file
  reflects the last completed turn), proven by tests (the auto-provable property);
  a true hard-kill mid-turn is the SC-008 manual-beta confirmation.
- **SC-010**: The agent-authored handover splits into two honestly-scoped halves
  (iteration 005). Failure-mode A (plumbing) is test-GUARANTEED and CI-blocking: an
  authored body survives a material Stop (the hook preserves it), the bootstrap
  carries the persisted body in the directive, and the persisted bytes equal the
  surfaced bytes (render==persist; NOT an agent-display claim). Failure-mode B (the
  agent never authors a rich body) is DETECTED, not prevented: the non-blocking
  detector flags a placeholder body at the Stop and at the next SessionStart, but
  cannot force authoring (transcript-blindness) - the human is the backstop. Tests
  MUST encode this split so the detector is never mistaken for a guarantee.
- **SC-011**: The deployed live-wiring floor is the AUTO-PROVABLE PLUMBING property: in a
  real installed-module scratch project (NOT the dev tree; `evidence_locus: deployed`), a
  SessionStart writes `boundary_enforcement` to `start-context.json` on disk AND the full
  launch contract to `last-start-prompt.md`; a working turn + Stop captures the iteration
  intent (when no start prompt) plus the agent-authored handover on disk; a fresh resume
  reads them back; AND the provider EMITS the per-host injection. This is the assertion
  that catches a dev-tree-only "works" claim (drift D-009). It does NOT assert that the
  injection REACHES the model on a given host - that is the manual per-host confirmation
  (FR-024, the SC-008-style observation). A host joins the PARITY SET only when the
  plumbing floor is green AND injection-reaches-model is observed; Claude is satisfied by
  observation this iteration, codex / copilot / cursor are enumerated follow-on.
- **SC-012**: A focused re-dogfood of the DF-3 scenario proves a boundary handover carries the
  agent-rendered packet AND `active_boundary` at a boundary (mechanically captured, not
  agent-function-dependent), and a DIFFERENT host's resume inherits the AUTHORED packet — not
  placeholders. (FR-022 iteration-011 amendment)
- **SC-013**: A boundary-sync with no captured human verdict records the crossing as un-authorized
  (never `approved for <boundary>` attributed to the git committer); a real captured human verdict
  records the real human. Proven by a deterministic test AND the re-dogfood. (FR-026)
- **SC-014**: A resume on a committed-but-unverdicted boundary surfaces "awaiting your verdict",
  not "approved", and does not auto-advance on a bare "continue". (FR-027)

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
- Cross-machine concurrent work on the same feature cannot be prevented by hook
  bootstrap alone; this feature provides best-effort advisory warning only, and a
  distributed lease or coordination mechanism is deferred to a future proposal.
- The trust boundary for this feature is the local project tree; bootstrap inputs
  are validated for correctness and fail-safety, not as anti-adversarial
  hardening. Adversarial or untrusted-artifact hardening for cross-machine, CI,
  hosted, or multi-tenant contexts is deferred to a separate proposal.
- Session recovery uses advisory freshness-based detection only; no lock or lease
  semantics are introduced.

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
