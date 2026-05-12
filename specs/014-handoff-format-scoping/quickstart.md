# Quickstart: Handoff Format Scoping

**Date**: 2026-05-12
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

This quickstart records the bounded implementation path for feature 014 while keeping planning limited to the approved scope: feature opening through Iteration 001 planning scaffold only.

## Prerequisites

- PowerShell 7+
- Approved `spec.md` for feature 014
- Planning artifacts created by this workflow:
  - `research.md`
  - `data-model.md`
  - `contracts/coordinator-handoff-scoping.md`
  - `plan.md`
- Existing handoff-governance surfaces from features 007 and 012 already present in the repository

## 1. Confirm the plan boundary

Before implementation starts, verify the plan still preserves the approved split:

- **Iteration 001**: selector/guidance rollout, warning-shape rollout, fixed placeholder list, and `human-handoff-id-context` applicability wording
- **Iteration 002**: deterministic violating/compliant fixtures, historical-sample calibration, validation-lane updates, and known-traps graduation
- No tasks or Iteration 002 governance scaffolding were created during planning

## 2. Implement Iteration 001 surfaces

Update these existing repository surfaces together:

- `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`
- `extensions/specrew-speckit/prompts/coordinator-response.md`
- `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`
- `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`
- `specs/001-specrew-product/contracts/coordinator-handoff-template.md`
- `.github/agents/squad.agent.md`
- `.squad/templates/squad.agent.md`
- `.specrew/quality/known-traps.md` (Iteration 002 graduation only)

Use the contract in `contracts/coordinator-handoff-scoping.md` as the normative selector for final stop message vs in-flight progress update behavior.

## 3. Keep the rollout bounded

During Iteration 001 implementation:

- Preserve the existing three-section stop-message format unchanged.
- Keep in-flight progress updates as single-line prose.
- Limit warning logic to the coordinator's top-level response surface.
- Use only the repository-maintained placeholder phrase list.
- Do not add `soft-info.well-scoped-handoff`.
- Do not add the reverse symmetric warning for silent real stops rendered as progress updates.

## 4. Prepare Iteration 002 proof work without pre-scaffolding it

When implementation is later authorized, Iteration 002 should add:

- `tests/integration/handoff-governance-empty-user-action-test.ps1`
- `tests/integration/handoff-governance-transitional-stop-claim-test.ps1`
- `tests/integration/fixtures/handoff-format-scoping/` with violating/compliant warning fixtures and a historical calibration sample
- Validation-lane updates in `extensions/specrew-speckit/governance/validation-lane.md`
- Known-traps graduation in `.specrew/quality/known-traps.md`

Do **not** create Iteration 002 planning artifacts until fresh authorization exists; the known-traps corpus already forbids unauthorized iteration scaffolding.

## 5. Run the preserved regression lane

Before closing Iteration 001 implementation, rerun the existing handoff-governance regressions:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-jargon-response-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-plain-language-response-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-review-file-reference-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-descriptive-narration-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-descriptive-stop-message-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

## 6. Run the Iteration 002 proof lane later

Once Iteration 002 is authorized and implemented, run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-empty-user-action-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\handoff-governance-transitional-stop-claim-test.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Also review the historical calibration sample to confirm the new warnings stay below the spec's false-positive threshold.
