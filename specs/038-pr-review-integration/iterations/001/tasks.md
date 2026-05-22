# Tasks: PR Review Integration (Proposal 089 — Minimal Viable Slice)

**Feature**: 038-pr-review-integration
**Proposal**: 089 (minimal viable slice)
**Version**: v0.24.3
**Spec**: [../../spec.md](../../spec.md)
**Plan**: [plan.md](plan.md)
**Branch**: `chore-089-pr-review-integration`
**Capacity**: 3 story_points

---

## T001: Add 2 Helpers to shared-governance.ps1 (1.0 SP)

**Acceptance Criteria**:

- [X] Get-SpecrewPrReviewResolutionPath: returns `specs/<feature>/iterations/<N>/pr-review-resolution.md`
- [X] Test-HostProvidesAutomatedPrReview: detects `gh` CLI + github.com remote; returns hashtable with Active/Host/Reviewer keys

**Owner**: Implementer
**Trace**: FR-001, FR-002

---

## T002: Validator Soft-Warning Surface (1.0 SP)

**Acceptance Criteria**:

- [X] After iteration enumeration, validator scans target iterations for PR/Copilot mentions in state.md
- [X] If host has auto-review AND artifact missing, emit `[pr-review-soft-warning] ...`
- [X] Warning is INFORMATIONAL ONLY — does NOT contribute to exit code
- [X] Wrapped in try/catch so detector failure never blocks validation

**Owner**: Implementer
**Trace**: FR-003, FR-004, FR-005

---

## T003: Integration Tests (0.75 SP)

**Acceptance Criteria**:

- [X] tests/integration/pr-review-integration.tests.ps1 with 7 assertions
- [X] Tests: helpers present + mirror parity + warning string + path helper correctness + host detection hashtable shape + non-blocking semantics

**Owner**: Test Owner
**Trace**: FR-006

---

## T004: CHANGELOG + INDEX + Closeout Artifacts (0.25 SP)

**Acceptance Criteria**:

- [X] CHANGELOG.md entry under `### Changed` referencing Proposal 089
- [X] proposals/INDEX.md: move 089 → Shipped (partial — minimal viable slice)
- [X] proposals/089 frontmatter: status partially-shipped; pillar-1-shipped-as: feature-038
- [X] iteration artifacts: plan + tasks + review + retro + drift-log + state + dashboard + quality/hardening-gate
- [X] closeout-dashboard.md

**Owner**: Spec Steward + Retro Facilitator
**Trace**: FR-007

---

## T005: Branch Push + PR + Copilot Review + Merge (0.25 SP)

**Acceptance Criteria**:

- [X] Branch pushed to origin
- [X] PR opened
- [X] Wait for GitHub Copilot review
- [X] Address every finding
- [X] CI passes
- [X] PR merged via merge commit

**Owner**: Spec Steward
**Trace**: closeout

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
