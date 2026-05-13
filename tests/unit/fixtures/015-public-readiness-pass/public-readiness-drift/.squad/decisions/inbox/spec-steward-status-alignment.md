# Decision: Shipped Feature Spec Status Reconciliation (Feature 015 FR-017)

**Date**: 2026-05-13  
**Agent**: Spec Steward  
**Authoritative Requirement**: Feature 015 spec.md, FR-017 + tasks.md T019

## Decision Summary

Reconciled the Status field across four shipped feature specifications from the stale `Draft` label to the canonical shipped-spec status `Complete`:

- `specs/007-user-facing-progress-handoff/spec.md`
- `specs/009-project-path-resolution/spec.md`
- `specs/011-specrew-start-conditional-pause/spec.md`
- `specs/012-descriptive-id-handoffs/spec.md`

## Authority

**FR-017 source text** (Feature 015 spec.md):
> Four previously shipped and delivered feature specifications (…) MUST have their status field updated from the stale `Draft` label to the canonical shipped-spec status label `Complete` to accurately reflect their delivered and implemented state. **Canon choice**: Status label `Complete` aligns with spec 013 (validator hardening) as the standard label for shipped and fully delivered features.

**Task T019** (Feature 015 tasks.md):
> T019 [US2] [Owner: Governance steward] [Effort: M] Update the **Status** field in four shipped-feature specifications from the stale `Draft` label to the canonical shipped-spec status `Complete`… (Trace: FR-017, TG-002, SC-003)

## Rationale

1. **Canonical label alignment**: All four specs are previously delivered features with completed implementations and closed iterations. The status field must reflect that delivered state.
2. **Authoritative source**: Feature 015 FR-017 explicitly names these four specs and mandates the `Complete` label per spec 013 pattern.
3. **No scope expansion**: Only the Status field was changed; no other text edits were required because the header statements in all four specs remain truthful (they describe what was delivered and why).

## Verification

All four files verified after edit:
- `specs/007-user-facing-progress-handoff/spec.md` line 5: ✅ `Status: Complete`
- `specs/009-project-path-resolution/spec.md` line 5: ✅ `Status: Complete`
- `specs/011-specrew-start-conditional-pause/spec.md` line 5: ✅ `Status: Complete`
- `specs/012-descriptive-id-handoffs/spec.md` line 5: ✅ `Status: Complete`

## Scope Boundaries

- **In scope**: Status field reconciliation only; four specific specs as listed in FR-017.
- **Out of scope**: Any content edits beyond minimum adjacent repairs; broader feature-status audit across all specs.

---

This decision closes FR-017 (T019) for Feature 015 Iteration 002.
