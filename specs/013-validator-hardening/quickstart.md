# Quickstart: Validator Hardening

**Date**: 2026-05-12
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

This quickstart now records the completed Iteration 001 implementation evidence for the canonical-schema and graceful-error slice while preserving the planned validation path for Iteration 002.

## 0. Iteration 001 implementation-start baseline

The approved six-script baseline lane was recorded on **2026-05-12** before any Iteration 001 validator changes landed.

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -File .\tests\integration\validation-contract-lane.ps1
pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

**Observed baseline verdict**: all six commands passed, including the repo-wide `validate-governance.ps1 -ProjectPath .` corpus pass and the approved planning artifact at `specs/013-validator-hardening/iterations/001`.

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

The Iteration 001 implementation evidence was recorded on **2026-05-12** with:

```powershell
# Fixture-based fail-closed proof for FR-001, FR-002, FR-005
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\validator-hardening-iteration1.ps1

# Backward-compatibility check (existing corpus must still pass)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

**Recorded Iteration 1 verdict**:

- `tests/integration/validator-hardening-iteration1.ps1` passed with compliant state and hardening-gate fixtures, non-canonical label failures, lowercase canonical-label case-drift failures, missing-field failures, grandfathered legacy pass coverage, missing-file failures, reordered/missing canonical-concern failures, and unexpected-input structured FAIL coverage.
- `tests/integration/hardening-gate-contract.ps1`, `tests/integration/quality-evidence-governance.ps1`, and `tests/integration/project-path-resolution-regression.ps1` stayed green after the validator changes.
- `extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` stayed green across the existing corpus under `specs/`, preserving feature 007 handoff checks, feature 012 readable-reference enforcement, and the pre-feature-013 historical iterations without new false positives.

## 4. Run Iteration 2 validation (post-implementation)

The Iteration 002 implementation-boundary evidence was recorded on **2026-05-12** with:

```powershell
# Fixture-based fail-closed proof for FR-003, FR-004, FR-006
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\validator-hardening-iteration2.ps1

# specrew-start regression coverage kept green after classifier integration
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\specrew-start-change-detector.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\specrew-start-auto-continue-preservation.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\specrew-start-pause-and-confirm.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\specrew-start-parameter-handling.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\specrew-start-end-to-end.ps1

# Full backward-compatibility pass
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

**Recorded Iteration 2 verdict**:

- `tests/integration/validator-hardening-iteration2.ps1` passed with duplicate normalized approval quotes rejected, blanket authorization exemptions accepted, distinct approval quotes accepted, clean closeout PASS coverage, missing review/retro failures, pending hardening-gate failures, dirty canonical-artifact failures, repo-level evidence-only dirt exclusions, direct classifier fixture checks, and `specrew-start.ps1` replay-path assertions.
- `tests/integration/specrew-start-change-detector.ps1`, `specrew-start-auto-continue-preservation.ps1`, `specrew-start-pause-and-confirm.ps1`, `specrew-start-parameter-handling.ps1`, and `specrew-start-end-to-end.ps1` all stayed green after the classifier helper was integrated into restart guidance.
- `extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` stayed green across the full repository corpus while smoke-checking classifier compatibility on `.github/copilot-instructions.md`.
- `.specrew/quality/known-traps.md` now marks approval-reuse, over-claim, canonical-schema, and canonical-concern rows as `validator-enforced` with citations to the implementing scripts and replay-path tests.

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
