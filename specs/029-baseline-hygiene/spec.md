# Feature Specification: Baseline Hygiene for Session-Loaded File Change Detection

**Feature Branch**: `029-baseline-hygiene`  
**Created**: 2026-05-21  
**Status**: Draft  
**Input**: Expanded Pillar E scope: baseline_commit_hash frozen at specrew-start, causing persistent false positives in F-011's session-loaded file detection when Squad commits boundary work.

## Problem Statement

**Root Cause**: F-011 (Conditional Pause on specrew-start When Session-Loaded Files Changed) detects changes to session-loaded files by comparing `git diff baseline_commit_hash..HEAD` against watched globs (`.github/agents/*`, `.github/copilot-instructions.md`, `extensions/specrew-speckit/squad-templates/coordinator/*`, `.squad/agents/*/charter.md`).

The `baseline_commit_hash` value is read from `.specrew/last-start-prompt.md` frontmatter and is set once when the prompt is first generated, **but is never updated afterward**. Consequently, when Squad commits boundary-work changes (governance updates, agent edits, charter tweaks) across multiple lifecycle boundaries (specify, clarify, plan, tasks, implement, review, retro), those changes remain "visible" in `git diff baseline_commit_hash..HEAD` indefinitely, causing F-011's pause-and-confirm prompt to fire repeatedly at every `specrew start` invocation.

**Observed Impact**: Since F-024+ work began, the false-positive misfire rate is the rule, not the exception. Users must repeatedly confirm that Squad's internal boundary work (not user-facing session-loaded changes) should not trigger a pause, adding workflow friction and reducing confidence in the detection mechanism.

**Example Scenario**:

1. User runs `specrew start` at feature-start. `.specrew/last-start-prompt.md` is created with `baseline_commit_hash: abc123...`.
2. Squad progresses through specify → clarify → plan. At each boundary, `Invoke-SpecrewBoundaryStateSync` commits updates to `.squad/agents/*/charter.md`, `.github/copilot-instructions.md`, etc.
3. User runs `specrew start` again. F-011 compares `git diff abc123...HEAD` and finds the Squad-committed changes still in the diff.
4. F-011 fires a pause-and-confirm prompt, even though the changes are internal governance work and not out-of-band session-loaded file edits the user made.
5. This repeats at every lifecycle boundary, degrading the signal of the detector.

## Relationship to Existing Features

- **Spec 011 (specrew-start-conditional-pause)**: F-011 introduces `Get-BaselineCommitHash`, `Test-SessionLoadedFilesChanged`, and the pause-and-confirm behavior. This feature fixes the mechanism that F-011 relies on by ensuring `baseline_commit_hash` is kept current at lifecycle boundaries, not frozen forever.
- **Proposal 067 (small-fix slice methodology)**: This feature is scoped as a small-fix slice (~3-4 story points) per Proposal 067 conventions: focused scope, clear boundary, measurable success criteria, minimal scope creep.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Feature-lifecycle baseline hygiene (Priority: P1)

A human developer progresses a feature through multiple lifecycle boundaries (specify → clarify → plan → tasks → implement → review → retro → feature-closeout). Squad commits boundary-work updates at each boundary. When the user runs `specrew start` after a boundary transition, F-011 correctly detects **only** out-of-band user changes to session-loaded files, not Squad's internal governance work.

**Why this priority**: This is the core issue. Without fixing baseline hygiene, F-011 is unreliable, and users lose trust in the session-loaded file detection mechanism.

**Independent Test**: Execute a full feature lifecycle (specify through feature-closeout) with Squad making commits at each boundary. At each subsequent `specrew start`, verify that F-011 does not fire unless the user has made genuine out-of-band changes to watched files.

**Acceptance Scenarios**:

1. **Given** a Specrew-managed feature in the 'clarify' boundary state, **When** `Invoke-SpecrewBoundaryStateSync` is called at boundary-close to record the clarify boundary, **Then** `.specrew/last-start-prompt.md` frontmatter is updated so `baseline_commit_hash` reflects the current HEAD (the commit that just recorded the boundary transition).

2. **Given** Squad has committed boundary-work changes (e.g., updated `.squad/agents/*/charter.md` at the clarify boundary), **When** the user runs `specrew start` immediately after, **Then** `git diff baseline_commit_hash..HEAD` against watched globs returns empty (no false-positive fires).

3. **Given** a feature has cycled through multiple boundaries (clarify, plan, tasks), **When** the user runs `specrew start` at any subsequent invocation, **Then** F-011 correctly identifies baseline as the most recent boundary-close commit, not a stale baseline from feature-start.

---

### User Story 2 - Out-of-band user changes still trigger pause correctly (Priority: P1)

After baseline hygiene is fixed, F-011 must still correctly detect when the user makes genuine out-of-band changes to session-loaded files between boundary transitions and trigger the pause-and-confirm prompt.

**Why this priority**: This validates that the fix does not break the original F-011 detection intent.

**Independent Test**: At any lifecycle boundary, commit a user-intentional change to `.github/agents/squad.agent.md`, run `specrew start`, and verify that F-011's pause-and-confirm prompt fires correctly.

**Acceptance Scenarios**:

1. **Given** baseline_commit_hash has been updated to reflect the current boundary state, **When** the user commits a change to `.github/agents/squad.agent.md` before the next `specrew start`, **Then** F-011 correctly detects the new change and fires the pause-and-confirm prompt.

2. **Given** the user makes multiple out-of-band changes to session-loaded files, **When** `specrew start` is invoked, **Then** F-011 lists all changed files in the pause-and-confirm prompt accurately.

---

### User Story 3 - Feature-closeout clears session state (Priority: P2)

At feature-closeout, `.specrew/last-start-prompt.md` is either deleted or invalidated to a sentinel state. The next `specrew start` after closeout does not attempt to resume a closed feature and treats the session as fresh.

**Why this priority**: Feature-closeout hygiene ensures a clean slate for the next feature. P2 because the feature can ship without this if needed (though E1 is in scope).

**Independent Test**: Complete a feature lifecycle through feature-closeout. Verify that `.specrew/last-start-prompt.md` is cleared or marked as inactive. Run `specrew start` and confirm the session does not attempt to resume the closed feature.

**Acceptance Scenarios**:

1. **Given** a feature has reached the feature-closeout boundary, **When** `Invoke-SpecrewBoundaryStateSync` is called at closeout, **Then** `.specrew/last-start-prompt.md` is either deleted or rewritten to a sentinel state (e.g., `session_state_active: false`).

2. **Given** a feature-closeout sentinel state is in place, **When** the user runs `specrew start` for a new feature, **Then** the session does not attempt to resume the closed feature and treats the new request as a fresh start.

---

### Edge Cases

- Baseline is updated at the feature-start boundary (specify). If the user makes genuine out-of-band changes between feature-start and specify-close, those are still correctly detected.
- A boundary-work commit happens but `Invoke-SpecrewBoundaryStateSync` is not called (e.g., user manually commits instead of using the helper). The next `specrew start` may still see the manual commit in the diff; this is acceptable (manual work is not guaranteed to be tracked).
- The user's out-of-band change is to a file covered by both session-loaded paths and other work (e.g., a `.squad/` charter modification that is also content-significant). The detector correctly identifies the change.
- A boundary is recorded but the user does not run `specrew start` until many commits later. Baseline hygiene correctly points to the last boundary, not feature-start.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001: Boundary-based Baseline Updates**: `Invoke-SpecrewBoundaryStateSync` MUST update `.specrew/last-start-prompt.md` frontmatter at each of the seven lifecycle boundaries (specify, clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout) so that `baseline_commit_hash` reflects the current HEAD commit at that boundary.

- **FR-002: Baseline Update Mechanism**: The baseline update logic MUST:
  - Read the existing `.specrew/last-start-prompt.md` frontmatter (if present).
  - Compute the current HEAD commit hash using `git rev-parse HEAD`.
  - Rewrite the frontmatter to set `baseline_commit_hash` to the newly computed HEAD.
  - Preserve all other frontmatter fields and the body content unchanged.

- **FR-003: Feature-Closeout Invalidation (E1)**: At the feature-closeout boundary, `Invoke-SpecrewBoundaryStateSync` MUST either delete `.specrew/last-start-prompt.md` or rewrite it to a sentinel state where `session_state_active: false` so that subsequent `specrew start` invocations do not attempt to resume a closed feature. *(Note: E1 is already implemented; this feature validates and tests that implementation.)*

- **FR-004: F-011 Integration**: After baseline updates are in place, `Get-BaselineCommitHash` (used by F-011) MUST correctly retrieve the updated `baseline_commit_hash` from the frontmatter so that F-011's change detection logic compares against the current boundary baseline, not a stale feature-start baseline.

- **FR-005: Idempotency**: Multiple invocations of baseline update at the same boundary MUST not cause corruption or loss of state. If `Invoke-SpecrewBoundaryStateSync` is called twice at the same boundary, the second call MUST preserve the updated baseline (not revert to an earlier one).

- **FR-006: Error Handling**: If the baseline update fails (e.g., `git rev-parse HEAD` fails, or the file cannot be written), `Invoke-SpecrewBoundaryStateSync` MUST log a clear error and not leave `.specrew/last-start-prompt.md` in a corrupted state.

### Non-Goals

- Changing the watched globs for F-011's session-loaded paths. Those are correctly defined in F-011.
- Backfilling existing closed features' session state files. Baseline hygiene applies prospectively to new features.
- Integrating baseline hygiene into other commands besides `specrew start` and `Invoke-SpecrewBoundaryStateSync`. The fix is scoped to the boundary-state sync helper and the baseline-reading logic.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After implementing E1 and E2, a developer progressing a feature through five or more lifecycle boundaries sees F-011's pause-and-confirm prompt fire **zero times** if no genuine out-of-band user changes are made to session-loaded files (baseline hygiene verified across full feature lifecycle).

- **SC-002**: When the developer makes a genuine out-of-band change to a watched file (e.g., `.github/agents/squad.agent.md`) at any lifecycle boundary, F-011's pause-and-confirm prompt fires **immediately** on the next `specrew start` (correctness of detection preserved).

- **SC-003**: At feature-closeout, `.specrew/last-start-prompt.md` is invalidated (deleted or marked `session_state_active: false`) so that subsequent `specrew start` invocations do not attempt to resume the closed feature (cleanness validated by inspection).

- **SC-004**: All test cases covering boundary-state sync, baseline updates, and feature-closeout invalidation pass without regression (confidence in implementation).

## Key Entities *(data involved)*

- **`.specrew/last-start-prompt.md`**: Session handoff file with YAML frontmatter. Contains `baseline_commit_hash`, `session_state_*` fields, and a markdown body with directives.
- **Frontmatter fields**:
  - `baseline_commit_hash`: Full 40-character SHA-1 commit hash (updated at each boundary).
  - `session_state_active`: Boolean flag (`true` or `false`), set to `false` at feature-closeout.
  - `session_state_boundary`, `session_state_feature`, `session_state_recorded_at`: Existing fields, preserved.
- **Git commits**: Commits recorded by `Invoke-SpecrewBoundaryStateSync` at lifecycle boundaries become the new baseline for F-011's change detection.

## Assumptions

- `git rev-parse HEAD` is always available and returns a valid 40-character commit hash in the Specrew environment.
- `.specrew/last-start-prompt.md` frontmatter is always well-formed YAML or empty (the template and existing code maintain this invariant).
- Squad's boundary work commits are always recorded **before** `.specrew/last-start-prompt.md` is updated, so the updated baseline reflects the boundary-close state post-commit.
- F-011's pause-and-confirm logic correctly interprets `baseline_commit_hash` as the baseline for `git diff` comparison (no changes to F-011's logic required, only to how baseline is managed).
- The user understands that baseline hygiene requires running `Invoke-SpecrewBoundaryStateSync` at each boundary; the fix is transparent and requires no user education.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess (Specrew maintainer).
- **Iteration Facilitator**: Alon Fliess.
- **Capacity Model**: ~3-4 story points (small-fix slice per Proposal 067). E1 (~1 SP), E2 (~2-3 SP). Core implementation in `scripts/internal/sync-boundary-state.ps1` and tested via integration tests.
- **Drift Signals**:
  - F-011's pause-and-confirm prompt fires more than once per feature lifecycle for the same unchanged session-loaded file (sign of baseline staleness).
  - Integration tests for `Invoke-SpecrewBoundaryStateSync` show baseline values that do not match the current boundary commit (sign of drift).
  - `.specrew/last-start-prompt.md` is present after feature-closeout with `session_state_active: true` (sign of closeout invalidation failure).
- **Human Oversight Points**:
  - Code review: Changes to `scripts/internal/sync-boundary-state.ps1` and baseline-update logic in `specrew-start.ps1`.
  - Test review: New or updated integration tests covering all seven lifecycle boundaries.
  - Manual validation: Progressing a test feature through a full lifecycle and confirming F-011 behavior is correct.

## Implementation Notes (Non-Binding)

- **E1 Approach**: At feature-closeout boundary, delete `.specrew/last-start-prompt.md` (simpler) or set `session_state_active: false` (preserves audit trail). User preference may guide the choice.
- **E2 Scope**: The seven boundaries are `specify, clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout` (per `Get-SpecrewBoundaryOrder` in sync-boundary-state.ps1). Baseline updates apply to all seven in a single consistent pattern.
- **Testing Strategy**: Integration tests should exercise:
  - Baseline update at each boundary.
  - F-011 behavior with updated baseline (no false positives, correct genuine-change detection).
  - Feature-closeout invalidation.
  - Idempotency (re-running boundary-sync at the same boundary).
  - Error scenarios (git failure, file write failure).
- **Artifacts in Scope**: Code (sync-boundary-state.ps1, specrew-start.ps1 baseline-reading logic), tests (integration and unit), CHANGELOG (entry documenting the fix and the observance of false-positive misfires addressed).

---

## References & Rationale

This feature is the superseding expanded Pillar E scope per the 2026-06-24 user request, replacing a narrower prior direction. The root-cause analysis (baseline_commit_hash frozen at feature-start) is well-established. The fix is scoped to two specific gaps: (E1) cleaning up closed features, (E2) keeping baseline fresh at lifecycle boundaries. The implementation is straightforward and non-invasive; it does not change F-011's detection logic or user-facing contracts, only the management of the baseline reference point.
