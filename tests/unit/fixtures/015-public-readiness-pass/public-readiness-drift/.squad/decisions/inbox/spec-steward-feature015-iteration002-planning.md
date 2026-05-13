# Spec Steward Decision: Feature 015 Iteration 002 Planning Authorization and Shipped-Feature Status Reconciliation

**Date**: 2026-05-13  
**Requestor**: Alon Fliess (Spec Steward)  
**Scope**: Feature 015 public-readiness-pass, Iteration 002 planning authorization and stale shipped-feature spec status alignment  
**Authority**: Spec Steward role — requirement traceability, drift detection, and alignment verification  

---

## What

Align the authoritative Feature 015 planning surfaces (spec.md, plan.md, tasks.md) to the newly authorized Iteration 002 planning scope delivered on 2026-05-13 by user directive, and establish the canonical shipped-feature spec status label for reconciliation.

### Scope Items Authorized (2026-05-13)

1. `.specrew/config.yml` version bump to `0.14.0` (FR-008)
2. Root `CHANGELOG.md` with Features 001-014 one-line entries (FR-009)
3. Retroactive tags `v0.13.0` at `21d9e7f` and `v0.14.0` at `3ff32d4` (FR-010)
4. Feature-closeout authorization template Step 10 for version bump / changelog / tag creation (FR-012, FR-013)
5. Coordinator prompt and template updates across `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, and `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (FR-013)
6. Versioning schema documentation in `docs/versioning.md` and README (FR-014)
7. Stale shipped-feature spec status reconciliation for specs 007, 009, 011, 012 (FR-017 — new requirement)

### Canonical Shipped-Feature Status Label

**Decision**: Use status label `Complete` as the canonical shipped-feature spec status, aligning with spec 013 (validator hardening) as the standard label for shipped and fully delivered features.

**Rationale**:
- Spec 013 (validator hardening) uses `Status: Complete` to indicate a shipped and fully delivered feature
- Four previously shipped features (007, 009, 011, 012) currently carry the stale `Draft` status that does not reflect their delivered and implemented state
- Status `Complete` signals that the feature is shipped, implemented, and ready for production use
- This aligns with the inventory of 14 shipped features that Feature 015 is reconciling
- `Draft` is inappropriate for shipped features; `Approved` is insufficient (indicates approved to ship, not shipped); `Complete` is the correct terminal state for delivered work

### Planning Surface Updates Made

1. **spec.md**:
   - Updated scope boundaries to clarify that Iteration 002 is now authorized (2026-05-13)
   - Added new FR-017 requirement for stale shipped-feature spec status reconciliation
   - Updated traceability requirements (TG-002, TG-005) to include FR-017 and Iteration 002 authorization
   - Updated Governance Alignment section to reflect Iteration 002 authorization and completed Iteration 001

2. **plan.md**:
   - Added "Iteration 002 Planning Authorization" section documenting the seven authorized scope items
   - Updated "Explicit Phase 2+ Deferrals" section to reflect that Iteration 002 is now authorized
   - Updated "Phase 2 Hardening and Specialist Review Planning" scope from "iteration-001-authorized" to "iteration-001-completed" and "iteration-002-authorized"
   - Updated "Explicit Later Deferrals" section to reflect Iteration 002 authorization and executor permissions

3. **tasks.md**:
   - Added task T019 (under Phase 4 User Story 2): Update status field in four shipped-feature specifications (007, 009, 011, 012) from `Draft` to `Complete`
   - Renumbered subsequent tasks (former T019-T024 → T020-T025) to accommodate the new task
   - Updated "Phase 6: Polish & Cross-Cutting Validation" section header to include shipped-feature spec status reconciliation
   - Updated Dependencies, Execution Order, Parallel Opportunities, Traceability Map, and Implementation Strategy sections to reflect:
     - Iteration 001 completion (2026-05-13) for T001-T009
     - Iteration 002 authorization (2026-05-13) for T010-T025
     - New T019 task for shipped-feature spec status reconciliation
     - FR-017 traceability

4. **.squad/identity/now.md**:
   - Updated status from "ITERATION 001 COMPLETE" to "ITERATION 001 COMPLETE; ITERATION 002 AUTHORIZED"
   - Updated focus_area and active_issues to reflect Iteration 002 authorization
   - Listed the seven authorized scope items in the status record
   - Updated Next Valid Action from "Await separate human authorization" to "Scaffold Iteration 002 planning artifacts"

---

## Why

### Requirement Authority

Feature 015 spec.md FR-015 and FR-017 establish planning and execution boundaries. FR-015 requires that planning artifacts preserve the authorization boundary, and FR-017 (new) requires reconciliation of stale shipped-feature spec status labels.

The user directive delivered on 2026-05-13 explicitly authorizes these seven scope items for Iteration 002 planning and execution. Without updating the planning surfaces, a Planner or Coordinator reviewing the artifacts would encounter:
1. Apparent ambiguity about whether Iteration 002 is deferred or authorized
2. Missing traceability from the new stale-status-reconciliation work back to a specification requirement
3. Stale governance records (spec.md scope, plan.md phase planning, .squad/identity/now.md next-valid-action) that would mislead decision-making

### Canonical Status Label Alignment

The four shipped specs (007, 009, 011, 012) currently carry `Draft` status despite being:
- Completed and shipped features
- Delivered to production in Specrew's alpha release
- Referenced in Feature 015 FR-011 as part of "14 shipped features"
- Intended as part of the "Active 0.14.0" product state

Using `Draft` for shipped features creates a governance signal misalignment: outside readers would see "Draft" status and infer these features are incomplete or intentionally unfinished, when in fact they are delivered. This contradicts the public-readiness goal of Feature 015 to accurately represent project state.

Status `Complete` is the correct terminal state because:
1. It aligns with spec 013 (validator-hardening) which uses `Complete` for a delivered feature
2. It signals that the feature is shipped and ready for use
3. It allows future status evolution (e.g., if a shipped feature later enters a "Deprecated" state)
4. It matches the validator's grandfathering rules for shipped features (no schema enforcement regression)

---

## Traceability

- **Spec Authority**: specs/015-public-readiness-pass/spec.md FR-015, FR-017, TG-005
- **Plan Authority**: specs/015-public-readiness-pass/plan.md Iteration 002 Planning Authorization section
- **Task Authority**: specs/015-public-readiness-pass/tasks.md T010-T025 (updated task decomposition)
- **User Directive**: Alon Fliess authorized the seven scope items on 2026-05-13 (captured in this decision and .squad/identity/now.md)
- **Pattern Reference**: Spec Steward History 2026-05-12 "Iteration Closeout Truth Requires Synchronized Lifecycle Surfaces" — when iteration boundaries change, all live artifacts must be synchronized

---

## Recommendation for Planners and Coordinators

1. **Before scaffolding Iteration 002 planning artifacts**: Verify that specs/015-public-readiness-pass/spec.md, plan.md, and tasks.md align with this decision. The planning surfaces are now authoritative for Iteration 002 scope.

2. **For Task T019 (shipped-feature spec status reconciliation)**: The canonical status label is `Complete`. Update the four specs' **Status** field from `Draft` to `Complete` in a single commit, with a message indicating the alignment to Feature 015 public-readiness and the canonical shipped-feature spec status pattern established in spec 013.

3. **For Iteration 002 scaffolding**: Use `specs/015-public-readiness-pass/iterations/002/plan.md` as the iteration-local planning surface. Do not scaffold review.md or retro.md placeholders during planning phase.

4. **Traceability verification**: Spot-check that the new FR-017 requirement is correctly traced in all downstream artifacts (plan.md, tasks.md, state.md, hardening-gate.md) once Iteration 002 artifacts are created.

---

## Sign-Off

**Spec Steward**: Alon Fliess  
**Decision Date**: 2026-05-13  
**Status**: Active — Planner may begin scaffolding Iteration 002 planning artifacts per this decision.
