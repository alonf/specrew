---
description: "Actionable tasks for Boundary Commit + Upstream Push Discipline (Proposal 082 Tier 1)"
---

# Tasks: Boundary Commit + Upstream Push Discipline (Proposal 082 Tier 1)

**Feature**: `031-commit-push-discipline`
**Iteration**: 001
**Scope**: Text-only methodology additions: coordinator governance prompt rule + 5 charters + user-guide section + mirror parity + verification test
**Capacity**: 5 story_points
**Planned Effort**: ~5 story_points

---

## Overview

Tier 1 of Proposal 082 closes the empirically-validated methodology gap: zero explicit instructions in any Crew-governing surface tell the Crew to commit at every boundary or push after every commit. F-029 had 4 boundary-discipline rejection cycles for this reason; F-030/083 has 1 so far.

**User Stories**:

- US-1 (P1): Implementer commits implementation work before signaling review-boundary
- US-2 (P1): Spec Steward oversees boundary cleanliness across the lifecycle
- US-3 (P1): Reviewer rejects PRs containing WIP at PR-open time
- US-4 (P2): Retro Facilitator captures commit-discipline lessons
- US-5 (P1): Coordinator governance prompt enforces commit-push at every gate

**Success Criteria**:

- SC-001: instructions visible in 6 files
- SC-002: empirical reduction in rejection cycles for next feature
- SC-003: mirror parity preserved
- SC-004: verification test passes

---

## Tasks (10 Total)

### T001: Verify Implementation Context (0.25 SP)

**Objective**: Confirm environment + locate all surfaces.

**Acceptance Criteria**:

- [ ] On branch `chore-082-t1-commit-push-discipline` off main
- [ ] All 7 surfaces locatable: coordinator/specrew-governance.md + 5 charters + docs/user-guide.md
- [ ] All 7 mirror paths exist at `.specify/extensions/specrew-speckit/...`

**Owner**: Spec Steward
**Trace**: All FRs (orientation)

---

### T002: Add Coordinator Governance Prompt Rule (0.5 SP)

**Objective**: Add explicit commit-at-boundary + push-after-commit rule to the coordinator governance prompt.

**Acceptance Criteria**:

- [ ] Edit `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`
- [ ] Add new numbered rule at the same authority level as existing 14A rule
- [ ] Rule text uses "the Crew" (proper noun)
- [ ] Rule explicitly mentions: commit before invoking boundary-sync, push to origin after commit, verify HEAD == origin/HEAD before signaling readiness

**Owner**: Spec Steward
**Trace**: FR-001, FR-009, US-5

---

### T003: Implementer Charter Addition (0.5 SP)

**Objective**: Implementer takes explicit commit responsibility.

**Acceptance Criteria**:

- [ ] Edit `extensions/specrew-speckit/squad-templates/agents/implementer/charter.md`
- [ ] Add responsibility: "Commits implementation work in semantic groups BEFORE invoking boundary-sync at the review-boundary transition. Pushes to origin AFTER each commit. Verifies HEAD == origin/HEAD before signaling readiness."
- [ ] Text uses "the Crew" terminology where the team-of-agents role is referenced

**Owner**: Spec Steward
**Trace**: FR-002, FR-009, US-1

---

### T004: Spec Steward Charter Addition (0.5 SP)

**Objective**: Spec Steward takes explicit oversight responsibility for boundary-commit discipline.

**Acceptance Criteria**:

- [ ] Edit `extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md`
- [ ] Add responsibility: "Verifies boundary handoffs include a non-`pending` commit reference. Confirms `git rev-parse HEAD == git rev-parse origin/<branch>` at every boundary advancement decision. Flags WIP-in-working-tree as a boundary-discipline violation."
- [ ] Text uses "the Crew" terminology

**Owner**: Spec Steward
**Trace**: FR-003, FR-009, US-2

---

### T005: Reviewer Charter Addition (0.5 SP)

**Objective**: Reviewer rejects PRs containing WIP at PR-open time.

**Acceptance Criteria**:

- [ ] Edit `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`
- [ ] Add a "Pre-merge committed-work check" section
- [ ] Reviewer's pre-merge audit confirms no WIP files exist on the branch at PR-open time. WIP at PR-open is a hard reject.
- [ ] Text uses "the Crew" terminology

**Owner**: Spec Steward
**Trace**: FR-004, FR-009, US-3

---

### T006: Retro Facilitator Charter Addition (0.5 SP)

**Objective**: Retro Facilitator includes commit-discipline as a standard retro prompt.

**Acceptance Criteria**:

- [ ] Edit `extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md`
- [ ] Add a standard retro prompt: "Were commits made at every boundary? Were pushes durable? Did any boundary signal with WIP present? Record `boundary-commit-discipline-violations: N` as a retro finding."
- [ ] Text uses "the Crew" terminology

**Owner**: Spec Steward
**Trace**: FR-005, FR-009, US-4

---

### T007: Planner Charter Addition (light, 0.25 SP)

**Objective**: Planner anticipates commit cadence in plan.md output.

**Acceptance Criteria**:

- [ ] Edit `extensions/specrew-speckit/squad-templates/agents/planner/charter.md`
- [ ] Add light reference: "When authoring iteration plans, anticipate the boundary-commit cadence — each boundary's tasks should map to a semantic commit group, not a single mega-commit at the end."
- [ ] Text uses "the Crew" terminology

**Owner**: Spec Steward
**Trace**: FR-006, FR-009

---

### T008: User-Guide Section (0.5 SP)

**Objective**: Downstream-user-facing documentation of boundary commit discipline.

**Acceptance Criteria**:

- [ ] Edit `docs/user-guide.md`
- [ ] Add a new `## Boundary Commit Discipline` section (or `### Boundary Commit Discipline` under an existing top-level section, whichever fits the existing structure)
- [ ] Section explains: what boundary-commit discipline is, why it matters (avoids resume-confusion + audit-trail drift), how the Crew enforces it (per Tier 1 charter additions), and when Tier 2/Tier 3 hard enforcement ships in later releases
- [ ] Text uses "the Crew" terminology

**Owner**: Spec Steward
**Trace**: FR-007, FR-009

---

### T009: Mirror Parity Sweep (0.5 SP)

**Objective**: Copy all 6 modified primary files to `.specify/extensions/specrew-speckit/` mirror.

**Acceptance Criteria**:

- [ ] `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` matches primary
- [ ] `.specify/extensions/specrew-speckit/squad-templates/agents/implementer/charter.md` matches primary
- [ ] `.specify/extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md` matches primary
- [ ] `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` matches primary
- [ ] `.specify/extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md` matches primary
- [ ] `.specify/extensions/specrew-speckit/squad-templates/agents/planner/charter.md` matches primary
- [ ] All 6 mirror files have identical content (verified by SHA256 hash or `Compare-Object`)

**Owner**: Implementer
**Trace**: FR-008

---

### T010: Methodology-Surface Verification Test (1 SP)

**Objective**: Mechanical verification that the new methodology content exists in the right files.

**Acceptance Criteria**:

- [ ] Create `tests/integration/boundary-commit-discipline.tests.ps1`
- [ ] Test 1: Coordinator governance prompt has commit-at-boundary rule
- [ ] Test 2: Implementer charter has commit responsibility
- [ ] Test 3: Spec Steward charter has oversight responsibility
- [ ] Test 4: Reviewer charter has pre-merge committed-work check
- [ ] Test 5: Retro Facilitator charter has commit-discipline retro prompt
- [ ] Test 6: Planner charter has light commit-cadence reference
- [ ] Test 7: User-guide has Boundary Commit Discipline section
- [ ] Test 8: Mirror parity for all 6 modified files
- [ ] Test exits 0 when all assertions pass

**Owner**: Reviewer
**Test Location**: `tests/integration/boundary-commit-discipline.tests.ps1`
**Trace**: FR-010, SC-001, SC-003, SC-004

---

## Polish Phase (post-implementation, pre-merge)

### T011: CHANGELOG Entry + INDEX update + Closeout artifacts (0.25 SP)

**Objective**: Final polish before PR-at-feature-close.

**Acceptance Criteria**:

- [ ] CHANGELOG.md entry under `### Added` describing Tier 1 scope
- [ ] proposals/INDEX.md updated: 082 transitions from candidate to shipped (or keeps candidate with Tier 1 portion noted) — TBD per maintainer judgment at closeout
- [ ] specs/031-commit-push-discipline/iterations/001/review.md (self-review)
- [ ] specs/031-commit-push-discipline/iterations/001/retro.md
- [ ] specs/031-commit-push-discipline/iterations/001/state.md (final state)
- [ ] specs/031-commit-push-discipline/closeout-dashboard.md (closeout summary)

**Owner**: Spec Steward + Retro Facilitator
**Trace**: closeout requirements

---

### T012: Branch push + PR open + merge-commit (0.25 SP)

**Objective**: Complete feature delivery through PR-at-feature-close.

**Acceptance Criteria**:

- [ ] Branch `chore-082-t1-commit-push-discipline` pushed to origin
- [ ] PR opened on GitHub with:
  - Title referencing Proposal 082 Tier 1
  - Description citing FR-001 through FR-010 + empirical motivation (F-029 + F-030/083 rejection cycles)
- [ ] Self-review per Reviewer pre-merge committed-work check
- [ ] CI passes
- [ ] Merge with **merge-commit** (not squash, not rebase) per Specrew SDLC

**Owner**: Implementer + Reviewer
**Trace**: closeout requirements

---

## Dependencies & Execution Order

### Linear Execution

1. **T001**: Orientation
2. **T002**: Coordinator governance prompt rule (highest authority surface)
3. **T003-T007**: 5 charter additions in parallel (each independent)
4. **T008**: User-guide section
5. **T009**: Mirror parity sweep (depends on T002-T008 done)
6. **T010**: Verification test (depends on T002-T009 done)
7. **T011**: CHANGELOG + closeout artifacts
8. **T012**: Push + PR + merge

### Parallelization Opportunities

- T003-T007 can run in parallel (5 charter files are independent)
- T008 can run in parallel with T003-T007 (different file)
- T010 (test) depends on T002-T009 completion

---

## Effort Summary

| Task | Story | Effort | Owner |
|------|-------|--------|-------|
| T001 | Setup | 0.25 SP | Spec Steward |
| T002 | US-5 | 0.5 SP | Spec Steward |
| T003 | US-1 | 0.5 SP | Spec Steward |
| T004 | US-2 | 0.5 SP | Spec Steward |
| T005 | US-3 | 0.5 SP | Spec Steward |
| T006 | US-4 | 0.5 SP | Spec Steward |
| T007 | Cross-cutting | 0.25 SP | Spec Steward |
| T008 | User-facing | 0.5 SP | Spec Steward |
| T009 | Structural | 0.5 SP | Implementer |
| T010 | Verification | 1 SP | Reviewer |
| T011 | Polish | 0.25 SP | Spec Steward + Retro Facilitator |
| T012 | Polish | 0.25 SP | Implementer + Reviewer |
| **TOTAL** | **All** | **~5.5 SP** | — |

**Capacity**: 5 SP
**Planned**: 5.5 SP (slight overrun acceptable for small-fix slice; polish steps T011/T012 absorb capacity ceiling)

---

## Quality Gates

- [ ] T002-T008: text additions present in 7 files (coordinator + 5 charters + user-guide)
- [ ] T009: 6 mirror files match primaries (SHA256 or Compare-Object verification)
- [ ] T010: test exits 0
- [ ] T011: CHANGELOG entry + closeout artifacts present
- [ ] T012: PR opens, CI green, merge-commit lands

---

## Sign-Off

**Generated**: 2026-05-22
**Status**: ✅ **READY FOR IMPLEMENTATION KICKOFF**
**Feature**: 031-commit-push-discipline
**Iteration**: 001
**Total Tasks**: 12

All design artifacts complete. Tier 1 scope is bounded, text-only, and low-risk. No blockers identified.

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
