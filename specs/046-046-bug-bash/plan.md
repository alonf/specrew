# Plan: F-046 Specrew Bug-Bash Bundle

**Feature**: `046-046-bug-bash`  
**Date**: 2026-05-25  
**Status**: Draft  
**Input**: F-046 Bug-Bash Brief  

---

## 1. Summary & Goals

This plan unifies the resolutions for five post-release defects surfaced during the F-045 v0.27.1 closeout session on 2026-05-25. The goal is to deliver a reliable, highly aligned v0.27.2 release.

---

## 2. Substantive Decisions

We have grounded the following key planning and architectural decisions:

### Decision 1: Bug 2 Architectural Fork = Option A
- **Decision**: `sync-boundary-state.ps1` will invoke the verdict writer inline.
- **Rationale**: This provides maximum atomicity. By updating BOTH the session cursor (`session_state.boundary_type`) and the audit trail (`boundary_enforcement.verdict_history` & `last_authorized_boundary`) in a single atomic file write, we eliminate the window for cursor-to-audit-trail drift.

### Decision 2: Single Iteration for All 5 Bugs
- **Decision**: Resolve all 5 bugs under a single iteration (`Iteration 001`) for maximum velocity, in accordance with the operator's preference.
- **Execution Order**: P1 bugs (US1, US2, US3) will be implemented first, followed by P2 (US4) and P3 (US5 documentation).

### Decision 3: Tests-First Rhythm
- **Decision**: Every bug fix MUST have a fixture-driven validation test implemented and verified *before* the runtime changes are applied. This guarantees regression coverage and validates correct defect classification.

### Decision 4: Mirror Parity (FR-007)
- **Decision**: Every change to `extensions/specrew-speckit/scripts/*` will be mirrored in `.specify/extensions/specrew-speckit/scripts/*` to maintain perfect parity between the template/extension sources and the active specification runners.

---

## 3. Reference to Existing Specify-Phase Artifacts

Per the phase-boundary acknowledgment, several Wave B and planning artifacts were already created during the `specify` phase. This plan explicitly acknowledges their existence and locks their content:
- **Data Model**: [data-model.md](file:///C:/Dev/Specrew/specs/046-046-bug-bash/data-model.md) defines `BoundarySyncTransition` and `ScaffolderProtectionVerdict` entities.
- **Quickstart Guide**: [quickstart.md](file:///C:/Dev/Specrew/specs/046-046-bug-bash/quickstart.md) provides under-5-minute operator verification commands and scenarios.
- **Review Diagrams**: [review-diagrams.md](file:///C:/Dev/Specrew/specs/046-046-bug-bash/review-diagrams.md) describes the component and sequence layouts.
- **API Contracts**: [sync-contract.md](file:///C:/Dev/Specrew/specs/046-046-bug-bash/contracts/sync-contract.md) locks down the alias mappings and atomic transactional invariants.
- **Requirements Checklist**: [requirements.md](file:///C:/Dev/Specrew/specs/046-046-bug-bash/checklists/requirements.md) governs functional validation checks.
- **Findings Ledger**: [findings.md](file:///C:/Dev/Specrew/specs/046-046-bug-bash/findings.md) acts as the single source of truth for the 5 bugs.

*Note: These files must not be re-scaffolded or overwritten. Any future planning adjustments will be appended as versioned updates rather than overwrites.*

---

## 4. Implementation Slices

### Slice 1: US1 - Stale-State Allow-List
- **Files**: `scripts/specrew-start.ps1`, `scripts/specrew-review.ps1`
- **Focus**: Map `retro` as a valid allowed boundary when `review.md` is accepted.

### Slice 2: US2 - Atomic Verdict History Append
- **Files**: `scripts/internal/sync-boundary-state.ps1`
- **Focus**: Invoke `Add-SpecrewBoundaryAuthorization` inline during cursor updates.

### Slice 3: US3 - Scaffolder Protection
- **Files**: `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`, `scaffold-review-artifact.ps1`, `scaffold-retro-artifact.ps1`
- **Focus**: Validate existing files for populated verdicts; skip overwrite and output to `.pending` when found.

### Slice 4: US4 - Resilient Prose-Name Mapping
- **Files**: `extensions/specrew-speckit/scripts/sync-boundary-state.ps1`, `scripts/internal/sync-boundary-state.ps1`
- **Focus**: Remove parameter `ValidateSet` and perform dynamic alias translation.

### Slice 5: US5 - Documentation and Ledger Verification
- **Files**: `specs/046-046-bug-bash/findings.md`
- **Focus**: Review and document Bug 5 findings and mark all defects closed.

---

## 5. Risks & Mitigation

- **Scaffolder Divergence**: Ensuring that `.specify/` copies of scaffolders are updated along with `extensions/`. Mitigation: Handled strictly via FR-007 mirror parity checks.
- **Idempotency Failures**: Atomic syncing might write duplicate entries on multiple sync invocations. Mitigation: Explicit check to verify if the boundary is already authorized before appending to `verdict_history`.
