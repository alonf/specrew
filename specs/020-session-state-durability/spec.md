# Feature Specification: Session-State Durability & In-Flight Progress Tracking

**Feature Branch**: `020-session-state-durability`  
**Created**: 2026-05-19  
**Status**: Shipped  
**Input**: User description: "Session-State Durability & In-Flight Progress Tracking"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Post-Reboot Recovery (Priority: P1)

After a system reboot during mid-implementation work, Squad must accurately resume from the exact point where work stopped, without confusion about which feature is active or which task was in progress.

**Why this priority**: This is the core problem - the 2026-05-16 F-017 reboot incident showed that without this capability, Squad can actively work on the wrong feature, potentially causing data loss or wasted effort. This is a blocking issue for production use.

**Independent Test**: Can be fully tested by starting work on a feature, marking task T003 as complete, rebooting/exiting the session, then restarting Squad and verifying it correctly identifies the active feature, completed tasks T001-T003, and next task T004.

**Acceptance Scenarios**:

1. **Given** Squad is implementing Feature 020 with tasks T001-T003 complete and T004 in-progress, **When** the system reboots and Squad restarts, **Then** Squad correctly identifies Feature 020 as active, reports T001-T003 as complete, T004 as in-progress, and offers to continue with T004 or move to T005
2. **Given** a feature has just completed closeout and is merged to main, **When** Squad starts in the main worktree, **Then** Squad reports "no active feature" and does not reference the closed feature
3. **Given** session-state files reference Feature 016 but Feature 016 was merged 2 days ago, **When** Squad starts, **Then** Squad detects stale state, alerts the user with specific staleness details (what's stale and why), and prompts for re-orientation without taking any action
4. **Given** multiple worktrees exist with different features in flight, **When** Squad starts in any worktree, **Then** Squad accurately identifies which feature is active in the current worktree and lists other worktrees with their features

---

### User Story 2 - Boundary-Event State Synchronization (Priority: P1)

At every lifecycle boundary (specify completion, clarify completion, plan completion, tasks completion, review verdict, iteration closeout, feature closeout), all session-state files must update atomically to reflect the new boundary, so Squad never acts on stale state.

**Why this priority**: The 2026-05-18 F-019 closeout incident showed that stale state across multiple governance files causes ~30+ minutes of reconciliation work and erodes trust in Squad's coordination capability. Without this, every boundary crossing is a potential state-drift event.

**Independent Test**: Can be tested independently by completing a planning phase, committing the plan boundary, then immediately checking that `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, and `.squad/decisions.md` all reference "planning complete" and match each other.

**Acceptance Scenarios**:

1. **Given** `/speckit.specify` completes and creates a new feature spec, **When** the specify boundary commits, **Then** all session-state files (`.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, `.squad/decisions.md`) update to show "active feature: 020; current boundary: specification complete"
2. **Given** planning completes and the plan-boundary commits, **When** the commit completes, **Then** all session-state files update to "current boundary: planning complete; next step: hardening gate"
3. **Given** iteration 1 completes and closeout commits, **When** the closeout commit completes, **Then** all session-state files update to "iteration 1 complete; current state: iteration 2 planning" (or "ready for feature closeout" if no more iterations)
4. **Given** feature closeout completes, **When** the closeout commit merges to main, **Then** `.specify/feature.json` clears the feature_directory, `.specrew/last-start-prompt.md` shows "no active feature", and `.squad/identity/now.md` reflects the next roadmap item (informational only, not authorizing next feature activation)
5. **Given** any boundary update fails mid-write (disk full, crash, permission error), **When** Squad next starts, **Then** stale-state detection identifies the incomplete update and prompts for manual intervention (no silent corruption)

---

### User Story 3 - Authoritative Where-Am-I Query (Priority: P2)

Users must be able to run `specrew where --worktrees` and get an accurate, real-time report of: which feature is active, which worktree it's in, which boundary/iteration/task is current, and what worktrees exist with their features.

**Why this priority**: The Velocity Dashboard (F-017) provided iteration-level "where am I?" reporting, but couldn't show in-flight task progress because no durable state existed. This fills that gap and enables the dashboard follow-up work (~3-5 SP) referenced in Proposal 009.

**Independent Test**: Can be tested by activating Feature 020 in worktree A, marking task T005 as in-progress, creating worktree B with Feature 021, then running `specrew where --worktrees` from worktree A and verifying the output lists both worktrees with their features, boundaries, and task states.

**Acceptance Scenarios**:

1. **Given** Feature 020 is active with tasks T001-T004 complete and T005 in-progress in worktree `Specrew-020`, **When** user runs `specrew where`, **Then** output shows "Feature 020 | Iteration 1 | Task T005 (in-progress) | Last completed: T004 at [timestamp] | Next: complete T005 or move to T006"
2. **Given** worktree A has Feature 020 in implementation and worktree B has Feature 021 in planning, **When** user runs `specrew where --worktrees`, **Then** output shows both worktrees with their feature numbers, paths, current boundaries, and last activity timestamps
3. **Given** no active feature (post-closeout), **When** user runs `specrew where`, **Then** output shows "No active feature | Last completed: Feature 019 at [timestamp] | Next roadmap item: [from roadmap.yml] (not yet authorized)"
4. **Given** validator warnings exist for the current feature, **When** user runs `specrew where`, **Then** output includes validator state summary (e.g., "3 warnings: 2 soft, 1 medium")

---

### User Story 4 - Module/Project Version Mismatch Detection (Priority: P3)

When the installed Specrew module version differs from the project's bootstrapped `specrew_version`, Squad warns at `specrew start` with a copy-paste update command, allowing the user to upgrade if desired (non-blocking).

**Why this priority**: Empirical evidence shows version drift causes subtle bugs (e.g., template changes not reflected, validator rule mismatches). This warning catches the problem early without blocking work. Lower priority than state-durability because it's informational.

**Independent Test**: Can be tested by artificially setting the project's `.specrew/config.yml` `specrew_version` to `0.6.0`, installing Specrew `0.7.3`, running `specrew start`, and verifying a clear warning appears with `specrew update` command to copy-paste.

**Acceptance Scenarios**:

1. **Given** installed Specrew is `0.7.3` and project's `.specrew/config.yml` `specrew_version` is `0.6.5`, **When** user runs `specrew start`, **Then** Squad displays "Module version mismatch detected: installed 0.7.3, project expects 0.6.5. To update: specrew update" (non-blocking warning)
2. **Given** installed Specrew matches project version, **When** user runs `specrew start`, **Then** no version mismatch warning appears
3. **Given** version check is performed, **When** the check completes, **Then** no interactive prompt occurs (copy-paste command only)

---

### User Story 5 - PSGallery Latest-Version Check (Priority: P3)

When PSGallery has a newer Specrew version available, Squad warns at `specrew start`/`specrew init`/`specrew update` with an `Update-Module Specrew` command (cached daily, skippable via flag or CI environment variable).

**Why this priority**: Keeps users aware of updates without requiring manual version checks. Lower priority because it's a convenience feature, not correctness-critical. Must not break automation pipelines.

**Independent Test**: Can be tested by mocking a PSGallery response showing version `0.8.0` available when `0.7.3` is installed, running `specrew start`, and verifying the warning appears with the update command. Then test `--skip-update-check` flag suppresses the warning.

**Acceptance Scenarios**:

1. **Given** installed Specrew is `0.7.3` and PSGallery has `0.8.0`, **When** user runs `specrew start` and cache is older than 24h, **Then** Squad fetches latest version, caches result in `.specrew/`, and displays "Newer version available: 0.8.0 (current: 0.7.3). To update: Update-Module Specrew" (non-blocking)
2. **Given** PSGallery check cache is less than 24h old, **When** user runs `specrew start`, **Then** cached result is used (no network request)
3. **Given** user runs `specrew start --skip-update-check`, **When** the command executes, **Then** no PSGallery check occurs and no update warning appears
4. **Given** environment variable `SPECREW_SKIP_UPDATE_CHECK=1` is set, **When** Squad starts in CI/automation environment, **Then** no PSGallery check occurs (preserves automation compatibility)
5. **Given** PSGallery is unreachable (network failure), **When** version check runs, **Then** check fails silently with verbose logging only (does not block startup)

---

### Edge Cases

- **What happens when sync-boundary-state.ps1 fails mid-write (disk full, permission denied)?** Each file is written to a temp location first, then renamed atomically. If rename fails, original file is preserved. On next startup, stale-state detection identifies inconsistency and prompts user for recovery.

- **How does system handle cross-worktree state when `git worktree list` shows a worktree that no longer exists on disk?** Derivation from `git worktree list` means stale worktree entries persist until `git worktree prune` is run. `specrew where --worktrees` annotates such entries with "(path not found)" and suggests prune command.

- **What happens if a user manually edits `.specrew/last-start-prompt.md` to reference a non-existent feature?** Stale-state detection at `specrew start` verifies the referenced feature exists in `specs/` or has an authorization record in `.squad/decisions.md`. If not found, prompts user to select correct feature or create new one.

- **How does system handle feature closeout when multiple worktrees have features in flight?** Feature closeout only clears `.specify/feature.json` in the worktree where closeout occurs. Other worktrees retain their independent feature state. `specrew where --worktrees` shows each worktree's independent feature lifecycle.

- **What happens if boundary-event state synchronization hook is disabled or removed?** Validator at `specrew start` checks for synchronization drift and warns if state files are out of sync with latest boundary commit. User is prompted to manually run sync or re-enable hook.

- **How does system handle task status when tasks are added or reordered after progress tracking starts?** Tasks identified by stable IDs (e.g., `T001`, `T002`). If `tasks.md` is regenerated and IDs change, `tasks-progress.yml` retains old IDs with annotation "task not found in current tasks.md". User prompted to reconcile manually or discard stale progress.

- **What happens when clarification is explicitly skipped (user says "no clarifications needed")?** Boundary-event sync records "clarify: skipped at [timestamp]" in session-state files. Next boundary (planning) verifies spec has no `[NEEDS CLARIFICATION]` markers; if markers exist, warns that clarify was skipped but spec is still incomplete.

## Requirements *(mandatory)*

### Functional Requirements

#### Pillar 1: Boundary-Event State Synchronization

- **FR-001**: System MUST provide a helper script `extensions/specrew-speckit/scripts/sync-boundary-state.ps1` that accepts boundary type, feature number, iteration number (optional), and task ID (optional), then updates `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, and `.squad/decisions.md` to reflect the new boundary
- **FR-002**: Helper script MUST use write-temp-then-rename pattern for each file to ensure atomic updates (no partial writes visible); cross-file atomicity is best-effort with stale-state detection compensating for inconsistencies (Q7 clarification)
- **FR-003**: System MUST invoke `sync-boundary-state.ps1` at exactly seven lifecycle boundaries: specify, clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout (Q10 clarification)
- **FR-004**: At feature closeout, system MUST clear `.specify/feature.json` `feature_directory` field to empty and update `.specrew/last-start-prompt.md` to "no active feature" with next roadmap item reference (informational only, not authorizing activation) and MUST update `.squad/identity/now.md` at closeout (Q9 clarification; companion chore per Q5 establishes this pattern)
- **FR-005**: Each boundary-event sync MUST record timestamp, boundary type, feature identifier, and any relevant context (iteration number, task ID, auth commit hash) in structured YAML format aligned with current frontmatter conventions (Q6 clarification)

#### Pillar 2: Mid-Iteration Task Progress Tracking

- **FR-006**: System MUST maintain a `specs/<feature>/iterations/<NNN>/tasks-progress.yml` file (sibling to `tasks.md` per Q2 clarification) with per-task status (`pending`, `in-progress`, `complete`, `blocked`), `started_at` timestamp, `completed_at` timestamp, and `blocked_reason` field
- **FR-007**: Coordinator resume logic MUST read `tasks-progress.yml` to surface in-progress task state in substantive welcome-back prompt (Q8 clarification: reuse F-016 handoff style)
- **FR-008**: When a task transitions to `in-progress`, system MUST record `started_at` timestamp; when transitioning to `complete`, MUST record `completed_at` timestamp
- **FR-009**: When a task is marked `blocked`, user MUST provide `blocked_reason` text (required field)
- **FR-010**: `tasks-progress.yml` MUST use stable task IDs (e.g., `T001`, `T002`) that remain consistent across task list edits

#### Pillar 3: Cross-Worktree State Awareness

- **FR-011**: System MUST derive cross-worktree awareness purely from `git worktree list --porcelain` combined with per-worktree `.specify/feature.json` scanning; no persistent cross-worktree state file is created (Q3 clarification: pure derivation mechanism)
- **FR-012**: `specrew where --worktrees` command MUST list all worktrees with their paths, active feature numbers (if any), current boundary states, and last activity timestamps
- **FR-013**: When a worktree path from `git worktree list` does not exist on disk, system MUST annotate that worktree with "(path not found)" and suggest `git worktree prune`
- **FR-014**: Cross-worktree derivation MUST complete within 2 seconds for up to 10 worktrees (performance requirement)

#### Pillar 4: Stale-State Detection at `specrew start`

- **FR-015**: At `specrew start`, system MUST verify that any "active feature" referenced in session-state files (using active-write approach per Q1 clarification) has not been merged to main (check `git log main` for merge commits)
- **FR-016**: System MUST verify that the active feature's branch still exists (`git rev-parse --verify <branch>`)
- **FR-017**: System MUST verify that any claimed in-progress boundary has a matching authorization record in `.squad/decisions.md` with commit reference
- **FR-018**: System MUST verify that `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, and `.squad/decisions.md` are mutually consistent (same feature, same boundary)
- **FR-019**: On staleness detection, system MUST stop and present user with explicit re-anchor/continue-anyway/investigate prompt (Q4 clarification) with options: (A) re-anchor to correct feature, (B) create new feature, (C) exit and manually fix state — system MUST NOT silently act on stale state or block user
- **FR-020**: Stale-state detection error messages MUST include specific details: what is stale, why it's stale (e.g., "Feature 016 merged to main 2 days ago"), and what user should do

#### Pillar 5: Recovery Prompts at Session Resume

- **FR-021**: When `specrew start` completes with verified-current or re-anchored state, system MUST generate substantive welcome-back prompt including: active feature name, path, worktree, current boundary or task, last completed item with timestamp, validator state summary, suggested next actions
- **FR-022**: For in-progress implementation, welcome-back prompt MUST show which tasks are complete, in-progress, and pending (from `tasks-progress.yml`)
- **FR-023**: Welcome-back prompt MUST reference last completed boundary commit hash and recorded-at timestamp from `.squad/decisions.md`
- **FR-024**: If validator warnings exist, welcome-back prompt MUST include summary (e.g., "3 warnings: 2 soft, 1 medium") with command to view details

#### Scope Addition 1: Module-vs-Project Version Mismatch Warning

- **FR-025**: At `specrew start`, system MUST compare installed Specrew module version (from `Get-Module Specrew`) against project's `.specrew/config.yml` `specrew_version` field (Q11 clarification: always on, non-blocking, no opt-out; planning resolution aligned this anchor to `research.md` Blocker 1)
- **FR-026**: If versions differ, system MUST display non-blocking warning: "Module version mismatch detected: installed X.Y.Z, project expects A.B.C. To update: specrew update"
- **FR-027**: Version mismatch check MUST NOT prompt for interactive input (warning message only)
- **FR-028**: Version mismatch check MUST NOT prevent `specrew start` from continuing (non-blocking)

#### Scope Addition 2: PSGallery Latest-Version Check

- **FR-029**: At `specrew start`, `specrew init`, and `specrew update`, system MUST check PSGallery for latest available Specrew version (if cache is older than 24h) using shared cached check mechanism (Q12 clarification)
- **FR-030**: PSGallery latest-version result MUST be cached in `.specrew/version-check-cache.json` with timestamp; cache valid for 24 hours and shared across all three commands
- **FR-031**: If installed version is older than PSGallery latest, system MUST display non-blocking warning: "Newer version available: X.Y.Z (current: A.B.C). To update: Update-Module Specrew"
- **FR-032**: User MUST be able to skip PSGallery check via `--skip-update-check` flag on `specrew start`/`specrew init`/`specrew update`
- **FR-033**: System MUST skip PSGallery check when environment variable `SPECREW_SKIP_UPDATE_CHECK=1` is set (for CI/automation compatibility)
- **FR-034**: If PSGallery is unreachable (network error, timeout), check MUST fail silently with verbose logging only (does not block startup)
- **FR-035**: PSGallery version check MUST NOT prompt for interactive input (warning message only)

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story maps to functional requirements: US1→FR-015 through FR-024 (recovery), US2→FR-001 through FR-005 (boundary sync), US3→FR-011 through FR-014 plus FR-021 through FR-024 (where-am-i query), US4→FR-025 through FR-028 (module version), US5→FR-029 through FR-035 (PSGallery check)
- **TG-002**: Owner roles: Pillar 1-3 owned by Implementer; Pillar 4-5 owned by Reviewer (stale-state and recovery UX); Version checks owned by Implementer
- **TG-003**: Iteration 1 delivers Pillars 1, 4, and Scope Addition 1 (FR-001 through FR-005, FR-015 through FR-020, FR-025 through FR-028); Iteration 2 delivers Pillars 2, 3, 5, and Scope Addition 2 (FR-006 through FR-014, FR-021 through FR-024, FR-029 through FR-035)
- **TG-004**: Spec/implementation conflict: if write-temp-then-rename fails on any filesystem (permissions, quota), fallback to best-effort write with stale-detect compensation documented in implementation notes

### Key Entities *(include if feature involves data)*

- **Session-State Record**: Represents current lifecycle position; attributes include active feature identifier, current boundary type, iteration number (optional), task ID (optional), last completed boundary commit hash, recorded-at timestamp; stored across `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/identity/now.md`, `.squad/decisions.md`
- **Task Progress Entry**: Represents per-task execution state; attributes include task ID, status (`pending`, `in-progress`, `complete`, `blocked`), started_at timestamp, completed_at timestamp, blocked_reason; stored in `specs/<feature>/iterations/<NNN>/tasks-progress.yml`
- **Worktree State**: Represents feature lifecycle in a specific worktree; attributes include worktree path, active feature number, current boundary, last activity timestamp; derived from `git worktree list --porcelain` + `.specify/feature.json` scanning
- **Version Check Cache**: Represents PSGallery latest-version query result; attributes include latest_version, checked_at timestamp, cache_valid_until timestamp; stored in `.specrew/version-check-cache.json`

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After any system restart during mid-implementation work, Squad resumes from the correct feature and task within 30 seconds without manual re-orientation
- **SC-002**: Zero incidents of Squad referencing a closed feature as active after feature closeout (measured over 10 consecutive features post-deployment)
- **SC-003**: `specrew where` command returns accurate feature/boundary/task state in under 2 seconds for projects with up to 10 worktrees
- **SC-004**: Boundary-event state synchronization completes atomically (all files updated or none) in 95% of events across 100 boundary crossings
- **SC-005**: Stale-state detection identifies and surfaces inconsistencies before Squad acts on them in 100% of test cases (no false negatives)
- **SC-006**: Welcome-back recovery prompts include substantive next-step guidance (not just "do a review") in 100% of session resumes, as judged by user feedback
- **SC-007**: Version mismatch and PSGallery update checks display non-blocking warnings without interactive prompts in 100% of cases (verified in CI environments)
- **SC-008**: PSGallery version check completes within 5 seconds when cache is stale and network is available; fails silently within 10 seconds when network is unavailable

## Assumptions

- **Cross-worktree use case is single-developer only**: Multi-developer state reconciliation (multiple people working on different features across worktrees) is out of scope (Proposal 010's territory)
- **Git worktree list is authoritative for worktree discovery**: The system assumes `git worktree list --porcelain` output is reliable and up-to-date; stale entries are annotated but not automatically pruned
- **Write-temp-then-rename is universally supported**: The atomic file update pattern is assumed to work on all target filesystems (NTFS, ext4, APFS); if not, fallback is best-effort write with explicit stale-detect compensation
- **PowerShell 5.1+ or PowerShell Core 7+ is available**: All scripts use PowerShell; no bash/sh fallback is provided
- **Network access for PSGallery check is best-effort**: The latest-version check assumes PSGallery.org is reachable but gracefully degrades to silent failure on network errors
- **Task IDs remain stable across edits**: The system assumes that once `tasks.md` assigns IDs like `T001`, `T002`, those IDs are not reassigned to different tasks; if tasks are regenerated, progress reconciliation is manual
- **Session-state files are not manually edited during active sessions**: The system assumes `.specrew/` and `.squad/` files are only modified by Specrew tooling, not by users directly; manual edits may cause stale-state warnings
- **Validator tool is run before production deployment**: The system assumes that validator checks for session-state consistency are part of pre-merge CI; this feature adds runtime stale-detect but does not replace validator discipline

## Governance Alignment *(mandatory)*

- **Spec Steward**: Specification Owner (Alon Fliess) — accountable for specification integrity, clarification decisions, and reconciling source-draft with Spec Kit template structure
- **Planner**: Accountable for iteration cadence and cross-pillar dependency management; implementation ownership remains with baseline delivery roles only
- **Capacity Model**: Story points (SP) — 33 SP total (refined from initial 25-30 SP estimate during planning; companion chore 2 SP, Iteration 1 16 SP, Iteration 2 15 SP; +3 SP variance from detailed task breakdown accepted at planning-boundary signoff)
- **Drift Signals**: Drift detected via (1) validator warnings for session-state inconsistencies, (2) manual review of `.squad/decisions.md` for missing boundary records, (3) user-reported "Squad confused about feature state" incidents
- **Human Oversight Points**: (1) Clarify gate: resolve 12 open questions from source-draft (active-write vs derived-state, task progress location, cross-worktree mechanism, stale-state failure mode, etc.); (2) Hardening gate post-Iteration 1: verify boundary-event sync works for specify/clarify/plan/tasks boundaries before authorizing implementation; (3) Review gate post-Iteration 2: verify cross-worktree awareness and recovery prompts meet substantive-content bar via manual test scenarios

## Clarifications

### Session 2026-05-19

- Q1: Active-write vs derived-state approach for session-state files? → A: Active-write with stale-state detection for performance; derivation as verification fallback
- Q2: Where should per-task progress be stored? → A: Sibling file `specs/<feature>/iterations/<NNN>/tasks-progress.yml` to keep `tasks.md` stable
- Q3: Cross-worktree awareness mechanism? → A: Pure derivation from `git worktree list --porcelain`; no persistent cross-worktree state file
- Q4: Stale-state failure mode? → A: Explicit user-facing re-anchor/continue-anyway/investigate prompt; never silent action
- Q5: Ship companion chore for `.squad/identity/now.md` closeout bug? → A: Yes, small chore commit immediately before iteration 1 starts
- Q6: Session-state sidecar format (if needed post-clarify)? → A: YAML schema v1 aligned with current frontmatter conventions
- Q7: Atomicity guarantee across multiple session-state files? → A: Write-temp-then-rename per file; cross-file atomicity best-effort with stale-state detection compensating
- Q8: Recovery prompt style? → A: Reuse substantive F-016 handoff style as specialized welcome-back section
- Q9: Feature-closeout behavior for `.specify/feature.json`? → A: Clear to empty, mark no active feature; roadmap next item informational only
- Q10: Covered boundary event types? → A: Seven refined lifecycle boundaries: specify, clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout
- Q11: Module-vs-project version check always on? → A: Yes, always on, non-blocking, no opt-out
- Q12: PSGallery check shared across `specrew init`/`start`/`update`? → A: Yes, share cached PSGallery latest-version check

**Integration notes**: All 12 clarifications accepted as recommended. Functional requirements (FR-001 through FR-035) updated to reflect clarified decisions. The active-write approach (Q1) with stale-state detection provides performance and correctness; sibling `tasks-progress.yml` (Q2) preserves planning stability; pure derivation for cross-worktree awareness (Q3) eliminates sync drift risk; explicit user prompts on staleness (Q4) prevent silent corruption; companion chore (Q5) establishes `.squad/identity/now.md` closeout pattern before feature 020 formalizes full boundary event coverage (Q10).

**Two-iteration breakdown validation**: The recommended shape remains realistic with clarified scope. Iteration 1 (boundary sync + stale-detect + module version check) establishes the correctness foundation at 16 SP, and Iteration 2 (task progress + cross-worktree + recovery UX + PSGallery check) adds visibility features at 15 SP. Including the 2 SP companion chore, the refined total is 33 SP, which was accepted at planning-boundary signoff as a +3 SP variance from the initial 25-30 SP estimate.

## Cross-References

- **Composes with Feature 017 (Velocity Dashboard)**: This feature's `tasks-progress.yml` and session-state files become data sources for dashboard rendering; estimated ~3-5 SP dashboard follow-up to surface task-level progress (see Proposal 009)
- **Composes with Feature 011 (Specrew Start Conditional Pause)**: F-011 pauses on file-change detection; this feature extends F-011 with content-staleness checks (not just modification timestamps)
- **Extends Proposal 002 (Specrew Start Conditional Pause)**: Original proposal was file-change detection; this feature generalizes to content-consistency validation
- **Predecessor to Phase 5 Multi-Developer Reconciliation (Proposal 010)**: Multi-developer state reconciliation requires reliable single-developer state durability first; this feature is the foundation
- **Source artifacts**: Proposal 035 (`proposals/035-session-state-durability.md`), source-draft (`file:///C:/Dev/SpecrewDraft/session-state-durability.md`)

