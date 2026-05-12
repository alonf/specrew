# Quickstart: Validator Hardening

**Date**: 2026-05-12
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

This quickstart is a **planning artifact only**. It defines the validation and verification path for the two-iteration validator hardening feature. It does **not** claim that implementation already exists.

## Prerequisites

- PowerShell 7+
- Existing Specrew bootstrap in the target repository
- Approved `spec.md` with clarifications from 2026-05-12
- Canonical contracts at `specs/013-validator-hardening/contracts/iteration-state-schema.md` and `contracts/hardening-gate-concerns.md`

## 1. Confirm the plan is bounded correctly

Review `specs/013-validator-hardening/plan.md` and confirm it:

- Addresses exactly six validator rigor gaps (FR-001 through FR-007 + FR-008 through FR-010 as support)
- Preserves the existing validator command surface (FR-010)
- Splits work across Iteration 1 (schema + concerns + errors + contracts + Iter-1 fixtures) and Iteration 2 (reuse + over-claim + classifier + corpus + Iter-2 fixtures)
- Does not introduce model-based review (TG-007)

## 2. Confirm the canonical contracts exist

Before Iteration 1 implementation starts, verify:

```text
specs/013-validator-hardening/contracts/iteration-state-schema.md   ← FR-009
specs/013-validator-hardening/contracts/hardening-gate-concerns.md  ← FR-009
```

These contracts are the normative references for FR-001 and FR-002. Implementation must not diverge from them without updating both the contracts and the tests.

## 3. Run Iteration 1 validation (post-implementation)

After Iteration 1 is implemented, run:

```powershell
# Fixture-based fail-closed proof for FR-001, FR-002, FR-005
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\validator-hardening-iteration1.ps1

# Backward-compatibility check (existing corpus must still pass)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

**Expected Iteration 1 pass conditions**:

- All violating `state.md` fixtures (non-canonical field names, missing fields) produce structured FAIL output naming the file, the missing field, and a remediation hint with zero unhandled exceptions.
- All compliant `state.md` fixtures (all eight canonical fields present) pass with no errors.
- All violating `hardening-gate.md` fixtures (missing or reordered canonical concerns) produce structured FAIL output naming the concern and expected position.
- All compliant `hardening-gate.md` fixtures (five canonical concerns as first five rows) pass.
- All parse-failure, missing-file, and empty-value edge-case fixtures produce structured FAIL output with non-zero exit codes and zero unhandled exceptions.
- The full existing iteration corpus under `specs/` passes `validate-governance.ps1` without regressions.

## 4. Run Iteration 2 validation (post-implementation)

After Iteration 2 is implemented, run:

```powershell
# Fixture-based fail-closed proof for FR-003, FR-004, FR-006
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\validator-hardening-iteration2.ps1

# Bookkeeping classifier self-test
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\validator-hardening-iteration2.ps1 -ClassifierOnly

# Full backward-compatibility pass
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

**Expected Iteration 2 pass conditions**:

- Sibling-iteration fixtures with duplicated approval evidence (byte-identical normalized quotes) produce structured FAIL output naming both iterations and the quote.
- Sibling-iteration fixtures with explicit blanket multi-iteration authorization pass the reuse check.
- Closed-iteration fixtures missing `retro.md`, `review.md` acceptance, post-implementation hardening evidence, or with uncommitted iteration-directory changes produce structured FAIL output naming the missing element.
- Bookkeeping-only `.github/copilot-instructions.md` diffs (timestamp, Active Technologies, Recent Changes only) are classified as `bookkeeping`.
- Behavior-affecting diffs are classified as `behavior`.
- Mixed diffs are classified as `behavior` (conservative rule).
- `.specrew/quality/known-traps.md` has all four targeted rows updated to `validator-enforced` with citations to the implementing requirements and proving tests.

## 5. Verify acceptance criteria

Cross-check each measurable success criterion from the spec:

| SC | Check |
| --- | --- |
| SC-001 | 100% of post-rollout `state.md` files either conform or produce explicit FAIL; zero raw exceptions |
| SC-002 | 100% of `hardening-gate.md` files either preserve canonical concerns or produce explicit FAIL |
| SC-003 | 100% of seeded duplicate approval fixtures rejected unless blanket-authorization present |
| SC-004 | 100% of seeded over-claim fixtures rejected |
| SC-005 | 0 unhandled exceptions across representative fixture sets |
| SC-006 | 100% of representative `.github/copilot-instructions.md` diff fixtures classified correctly |
| SC-007 | Known-traps corpus rows marked enforced with citations before feature closure |

## 6. Full governance lane

Run the complete six-script governance validation lane before any iteration closure claim:

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -File .\tests\integration\validation-contract-lane.ps1
pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

All six must succeed with zero FAIL lines and `git status --short` must be clean (excluding `.claude/settings.local.json`) before any closure claim is made.
