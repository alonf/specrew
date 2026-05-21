# Feature Specification: Boundary Commit + Upstream Push Discipline (Proposal 082 Tier 1)

**Feature Branch**: `chore-082-t1-commit-push-discipline`
**Proposal**: [Proposal 082](file:///C:/Dev/Specrew/proposals/082-boundary-commit-and-upstream-push-discipline.md)
**Created**: 2026-05-22
**Status**: Draft
**Version**: v0.24.2 small-fix slice (Proposal 067)

## Clarifications

### Session 2026-05-22

- **Q: Tier 1 is text-only — no validator rule, no `Invoke-SpecrewBoundaryStateSync` change, correct?** → **A: Confirmed.** Tier 1 is methodology-surface text only: coordinator governance prompt rule + 5 baseline agent charters + user-guide section. Tier 2 (validator `boundary-wip-uncommitted` rule, ~6 SP) and Tier 3 (hard enforcement in `Invoke-SpecrewBoundaryStateSync` + auto-push hook, ~10 SP) ship in later releases per Proposal 082's phased scope.
- **Q: Does Tier 1 mandate "always push to origin" or "push when commits exist"?** → **A: Push after every commit.** Local-only commits are not durable; the methodology mandates upstream backup. Conditional skip applies only when no remote is configured.
- **Q: Apply to the four core lifecycle boundaries or every Crew pause?** → **A: Every lifecycle boundary** (specify, clarify, plan, tasks, implementation, review-signoff, retro, iteration-closeout, feature-closeout) AND every voluntary pause-to-report state per Proposal 078's expanded scope.
- **Q: How does this compose with Proposal 078 (Handoff Conversation Quality)?** → **A: Sibling slices.** 082 T1 instructs WHEN to commit/push (every boundary); 078 instructs HOW to communicate boundary state (three-section format). Both ship in v0.24.2 and v0.25.0 respectively.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Implementer commits implementation work before signaling review-boundary (Priority: P1)

The Implementer agent (a Crew role) completes implementation work for an iteration. Per the updated charter, the Implementer commits the work in semantic groups BEFORE invoking `Invoke-SpecrewBoundaryStateSync` for the review-boundary transition. Pushes to `origin/<feature-branch>` AFTER each commit. Verifies `git rev-parse HEAD` matches `git rev-parse origin/<feature-branch>` before signaling readiness.

**Why this priority**: This is the most-empirically-painful boundary. F-029 had THREE rejection cycles at this boundary alone — all because the Implementer signaled completion with uncommitted work in the working tree. Implementer's charter is the primary enforcement point.

**Independent Test**: Read `extensions/specrew-speckit/squad-templates/agents/implementer/charter.md`. Find an explicit responsibility statement about commits at boundaries and pushes after commits. Charter mentions semantic commits, push-before-readiness, and the three-section handoff format.

**Acceptance Scenarios**:

1. **Given** the Implementer is about to signal review-boundary readiness, **When** they consult their charter, **Then** they see an explicit instruction: "Commit implementation work in semantic groups BEFORE invoking boundary-sync; push to origin AFTER each commit; verify HEAD matches origin/HEAD before signaling readiness."
2. **Given** the Implementer skips the commit step and runs boundary-sync, **When** the coordinator governance prompt is consulted, **Then** the coordinator instructs the Crew to halt advancement until commits land on origin.

---

### User Story 2 - Spec Steward oversees boundary cleanliness across the lifecycle (Priority: P1)

The Spec Steward agent verifies that boundary handoffs include a committed-and-pushed evidence reference before accepting boundary advancement. Spec Steward's charter explicitly flags WIP-in-working-tree as a boundary-discipline violation.

**Why this priority**: Spec Steward is the role responsible for spec authority and methodology integrity. They are the natural oversight role for commit discipline.

**Independent Test**: Read `extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md`. Find a section about boundary-discipline oversight. Charter explicitly mentions verifying commit-and-push parity (`git rev-parse HEAD == git rev-parse origin/<branch>`) at every boundary advancement decision.

**Acceptance Scenarios**:

1. **Given** the Implementer signals review-boundary readiness, **When** Spec Steward verifies the evidence, **Then** they confirm commit references are non-`pending` and local matches remote.
2. **Given** WIP files exist in the working tree at a boundary signal, **When** Spec Steward consults the charter, **Then** they reject the boundary advancement until the working tree is clean against HEAD.

---

### User Story 3 - Reviewer rejects PRs containing WIP at PR-open time (Priority: P1)

The Reviewer agent's pre-merge review confirms all in-scope work is committed. WIP files at PR-open time are a hard reject — the PR cannot merge until the working tree is clean and pushed to origin.

**Why this priority**: PR-time review is the last enforcement point before the feature lands on main. Reviewer's charter must catch any WIP that slipped through earlier boundaries.

**Independent Test**: Read `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`. Find a "Pre-merge committed-work check" or equivalent. Charter explicitly mentions that PR diff must match what was approved at the review-boundary and any WIP files are a hard reject.

**Acceptance Scenarios**:

1. **Given** the Implementer opens a PR after review-boundary approval, **When** the Reviewer audits the PR diff against the approved evidence, **Then** they confirm no WIP files exist on the branch and the diff matches what was approved.
2. **Given** WIP files exist on the feature branch at PR-open time, **When** the Reviewer reviews, **Then** they reject the PR and require the Implementer to commit/push the remaining work.

---

### User Story 4 - Retro Facilitator captures commit-discipline lessons (Priority: P2)

The Retro Facilitator includes "boundary-commit discipline" as a standard retro prompt: were commits made at every boundary, were pushes durable, did any boundary signal WIP. The retro outcome captures discipline-violation count for the iteration.

**Why this priority**: Retro is the methodology-improvement loop. Tracking commit-discipline retro signals enables continuous improvement and validates Tier 2/3 prioritization.

**Independent Test**: Read `extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md`. Find a retro-prompt about commit discipline.

**Acceptance Scenarios**:

1. **Given** the iteration ran with multiple boundaries, **When** the Retro Facilitator prepares retro.md, **Then** they evaluate commit-at-boundary discipline as a standard signal.
2. **Given** a boundary advanced with WIP files present, **When** the Retro Facilitator captures retro findings, **Then** they record "boundary commit discipline violation" as a retro finding.

---

### User Story 5 - Coordinator governance prompt enforces commit-push at every gate (Priority: P1)

The coordinator (Squad's orchestrator role) governance prompt carries an explicit rule: at every lifecycle boundary, before invoking `Invoke-SpecrewBoundaryStateSync` or emitting the boundary handoff, commit the iteration's work-in-progress with a clear boundary-scoped commit message. After the commit, push the feature branch to origin so the work is backed up.

**Why this priority**: The coordinator governance prompt is the highest-authority methodology surface. Adding the rule there ensures every boundary-sync invocation reads the discipline requirement.

**Independent Test**: Read `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`. Find a new rule (numbered alongside existing 14A, 1, 2, 3, etc.) explicitly instructing commit-at-boundary and push-after-commit.

**Acceptance Scenarios**:

1. **Given** the Crew is preparing to advance any boundary, **When** the coordinator governance prompt is consulted, **Then** they see "Rule: Commit + push at every lifecycle boundary before invoking boundary-sync. Verify push parity before signaling readiness."
2. **Given** the rule is in the governance prompt, **When** future features run their lifecycle, **Then** human rejection cycles for boundary-commit discipline decrease materially compared to pre-082 baseline.

---

### Edge Cases

- **No remote configured**: Auto-push skips silently with debug message; commit-at-boundary discipline still applies. Documentation notes the conditional skip.
- **Detached HEAD or no feature branch**: This is itself a discipline violation (Crew should always be on a feature branch during a lifecycle). Documentation surfaces this as a "do not work in detached HEAD" instruction.
- **Push rejection (remote ahead)**: Crew stops and surfaces the conflict; does NOT auto-fetch/rebase. Human resolves.
- **Commit-and-push noise on tiny boundaries**: Some boundaries produce trivial state-only changes (e.g., a status-tracking update). Charter wording accepts that boundary-sync MAY produce zero-line commits or status-only commits; the requirement is "commit-and-push" not "produce substantial code at every boundary."

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001: Coordinator Governance Prompt Rule** — `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` MUST carry an explicitly numbered rule instructing commit-at-boundary AND push-after-commit. The rule MUST be at the same authority level as the existing rules (14A, 1, 2, etc.).

- **FR-002: Implementer Charter Addition** — `extensions/specrew-speckit/squad-templates/agents/implementer/charter.md` MUST carry an explicit responsibility for committing implementation work in semantic groups before invoking boundary-sync. Push-after-commit and HEAD-matches-origin verification MUST be explicit.

- **FR-003: Spec Steward Charter Addition** — `extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md` MUST carry an explicit oversight responsibility for boundary-commit discipline. Verification of `git rev-parse HEAD == git rev-parse origin/<branch>` MUST be explicit at boundary advancement decisions.

- **FR-004: Reviewer Charter Addition** — `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` MUST carry a pre-merge committed-work check. WIP at PR-open time MUST be a documented hard reject.

- **FR-005: Retro Facilitator Charter Addition** — `extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md` MUST carry a retro prompt about commit-at-boundary discipline. Retro evaluation MUST be a standard step.

- **FR-006: Planner Charter Addition (light-touch)** — `extensions/specrew-speckit/squad-templates/agents/planner/charter.md` MUST carry a light reference to commit discipline so the Planner's plan.md output anticipates commit-and-push at boundary transitions.

- **FR-007: User-Guide Section** — `docs/user-guide.md` MUST carry a `## Boundary Commit Discipline` section explaining the methodology to downstream Specrew users.

- **FR-008: Mirror Parity** — All charter and governance-prompt edits MUST be mirrored to `.specify/extensions/specrew-speckit/` for parity with the deployed extension assets.

- **FR-009: Terminology Compliance** — All new prose MUST use "the Crew" (proper noun) for the team-of-agents role per the 2026-05-21 naming decision. "Squad" remains for the npm product / `.squad/` paths only.

- **FR-010: Acceptance-Signal Verification Test** — A test suite at `tests/integration/boundary-commit-discipline.tests.ps1` MUST verify that the new instructions appear in the right files (governance prompt, all 5 charters, user-guide). Mirror parity is verified as part of the test.

### Non-Goals

- Runtime enforcement (validator rule for `boundary-wip-uncommitted`) — that's Proposal 082 Tier 2.
- Hard enforcement in `Invoke-SpecrewBoundaryStateSync` to refuse advancement on WIP — that's Proposal 082 Tier 3.
- Auto-push hook — Tier 3.
- Configuration via `iteration-config.yml` for `boundary_discipline.commit_required` / `boundary_discipline.auto_push` — Tier 3.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After Tier 1 ships, the next feature to start lifecycle work has the commit-discipline instructions visible in coordinator governance prompt + all 5 charters + user-guide. Verified by file inspection.
- **SC-002**: Empirical reduction in human-rejection cycles for boundary-commit discipline. Pre-082 baseline (today's session): 4 rejection cycles in F-029 + 1 in F-030/083. Post-082 expectation: zero rejections for new features that read the updated methodology.
- **SC-003**: Mirror parity sweep across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` is verified by `Compare-Object` or equivalent hash check.
- **SC-004**: Test suite `tests/integration/boundary-commit-discipline.tests.ps1` passes; all 5 charter additions + governance-prompt rule + user-guide section + mirror parity are verified mechanically.

## Key Entities *(data involved)*

- **Coordinator governance prompt**: `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (+ `.specify/` mirror). Authority surface for the Crew's overall lifecycle behavior.
- **Agent charters**: `extensions/specrew-speckit/squad-templates/agents/<role>/charter.md` for each of: implementer, planner, reviewer, spec-steward, retro-facilitator. Per-agent responsibility surface.
- **User-guide**: `docs/user-guide.md`. Downstream-user-facing documentation.

## Assumptions

- The Crew's host runtime (Squad CLI today, future Claude Code / Codex agents) reads charters and governance prompt at session start AND when each agent context is loaded. Mid-session charter updates affect future agent invocations within the session.
- Empirical motivation evidence from the F-029 (4 rejection cycles) and F-030/083 (1 rejection cycle so far) sessions is sufficient justification for the methodology change without requiring a separate user-direction A/B-test.
- The text-only Tier 1 ships without disrupting in-flight Crew work; the next feature lifecycle will be the first empirical test of whether the instructions reduce rejection-cycle rate.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess (Specrew maintainer); authoring acting as Spec Steward role.
- **Iteration Facilitator**: Alon Fliess.
- **Capacity Model**: ~5 SP (small-fix slice per Proposal 067). Implementation is text-only — no code changes, no test fixtures, no scaffolder edits, no validator rule.
- **Drift Signals**:
  - Charter additions absent or worded ambiguously such that the Crew misses the discipline.
  - Mirror parity break between `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/`.
  - Coordinator governance prompt rule not numbered or not at the right authority level.
- **Human Oversight Points**:
  - Spec review: the charter additions and governance prompt rule wording must be reviewed for clarity and authority.
  - PR review: standard PR review before merge.

## Implementation Notes (Non-Binding)

- The coordinator governance prompt rule should be numbered alongside existing rules (14A, 1, 2, 3, etc.) and worded with the same authority tone as 14A's substantive-interaction rule.
- Per-agent charter additions should be scoped to each role's natural responsibility — Implementer commits, Spec Steward oversees, Reviewer rejects WIP at PR, Retro Facilitator audits commit discipline, Planner anticipates commit cadence.
- Mirror parity is preserved by simple file-copy from `extensions/specrew-speckit/` to `.specify/extensions/specrew-speckit/` (existing pattern).

---

## References & Rationale

- **Proposal 082**: file:///C:/Dev/Specrew/proposals/082-boundary-commit-and-upstream-push-discipline.md
- **F-029 boundary-discipline incidents**: empirical case study driving 082 Tier 1 priority. Memory `[[project-f029-boundary-discipline-incidents-2026-05-21]]`.
- **Post-F-029 sequencing**: 082 Tier 1 was queued as the next slice after 083 (Proposal 083 Local Validator Speedup). 083 is currently in flight; 082 T1 ships in parallel without disrupting it. Memory `[[project-post-f029-sequencing-2026-05-21]]`.
- **Concurrent slice (Proposal 083)**: in-flight on branch `chore-083-local-validator-speedup` (worktree at `C:/Dev/Specrew-083`). The two slices touch overlapping files (coordinator governance prompt + reviewer charter) — the merge order matters; 082 T1 may land first and 083 will rebase, OR 083 lands first and 082 T1 rebases. Either ordering is acceptable; conflicts are small text-edits.
- **PR #423 (closeout-body-clear)**: in-flight on `chore-closeout-body-clear`. Touches different files (sync-boundary-state.ps1); no expected conflict with 082 T1.
