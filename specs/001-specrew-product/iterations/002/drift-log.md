# Drift Log: Iteration 002

**Schema**: v1

## Summary

**Total drift events**: 6
**Resolution rate**: 100% (6/6 resolved)
**Specification drift**: Resolved implementation and contract-alignment gaps closed during execution

## Events

- **DR-001**: Detected 2026-04-20 during T-205 spec review (Picard FR-020 brownfield audit)
  - **Requirement**: FR-020
  - **Deviation**: Implementation code missing 7 collision-detection safety gates (role-name, ceremony-name, charter conflict detection, dry-run conflict surfacing, -Force bypass prevention, non-empty directory handling, config staleness)
  - **Resolution**: implementation-corrected-and-accepted
  - **Detail**: Picard's audit gates were closed by the narrow FR-020 revision accepted on 2026-05-03. Worf's binding acceptance recorded T-205/T-206 as PASS after verifying the conflict gate, persistent dry-run artifact, `-Force` non-bypass rule, and entrypoint-level brownfield coverage in `tests\integration\brownfield-conflict-handling.ps1`.

- **DR-002**: Detected 2026-04-20 during T-204 spec review (FR-019 resume command scope)
  - **Requirement**: FR-019
  - **Deviation**: Resume flow trusted stale `Tasks Remaining` metadata instead of repairing execution state from the authoritative task table, leaving the FR-019 recovery path partially integrated.
  - **Resolution**: implementation-corrected
  - **Detail**: T-204 now reconciles stale or partial `state.md` metadata against `plan.md`, updates repaired execution fields during resume, refreshes the deployed `specrew-iteration-resume` guidance, and extends `tests\integration\iteration-resume.ps1` to cover stale-state repair. `docs\user-guide.md` now documents the recovery behavior.

- **DR-003**: Detected 2026-05-03 during T-202 planning-flow audit (FR-017 overcommit guidance)
  - **Requirement**: FR-017
  - **Deviation**: Planning validation only suggested tail-task deferral by task order, so overcommit guidance was not anchored to requirement priority as required by the spec.
  - **Resolution**: implementation-corrected-and-accepted
  - **Detail**: `validate-governance.ps1` now ranks deferral candidates by mapped requirement/user-story priority, `scaffold-iteration-plan.ps1` and planning guidance require the defer decision to be written explicitly, and `tests\integration\planning-overcommit.ps1` verifies lowest-priority guidance. Worf accepted the FR-017 slice on 2026-05-03 after re-running the validator and targeted integration coverage.

- **DR-004**: Detected 2026-05-03 during T-207 evaluation-slice audit (FR-015 process scorer)
  - **Requirement**: FR-015
  - **Deviation**: `evaluation\` only documented the future harness; there was no executable scorer for artifact and phase adherence, leaving the Iteration 2 process-quality slice incomplete.
  - **Resolution**: implementation-corrected-and-accepted
  - **Detail**: Added `evaluation\scorers\process-scorer.ps1` with structured artifact/phase adherence output, updated evaluation/user documentation, and added `tests\integration\process-quality-scorer.ps1` so T-208 can focus on report output rather than core scoring logic. Worf accepted the Iteration 2 process-slice implementation on 2026-05-03 after confirming structured scorer output and clean repo-level scoring.

- **DR-005**: Detected 2026-05-03 during T-203 planning-artifact audit (FR-007 / FR-017)
  - **Requirement**: FR-007, FR-017
  - **Deviation**: The planning scaffold emitted an `## Effort Model` snapshot, but the lifecycle contract and governance validator did not require or verify that snapshot against `.specrew\iteration-config.yml`, leaving room for plan/config drift after generation.
  - **Resolution**: implementation-corrected
  - **Detail**: Updated the iteration-artifact contract, data model, planning ceremony guidance, and `validate-governance.ps1` so planning artifacts must retain the effort-model snapshot and keep Capacity metadata aligned with configured effort unit/capacity. Added `tests\integration\planning-effort-model.ps1` to prove custom-unit scaffolding and mismatch rejection end to end.

- **DR-006**: Detected 2026-05-03 during T-208 evaluation report audit (FR-015 process slice)
  - **Requirement**: FR-015
  - **Deviation**: The process scorer returned structured JSON only; there was no persisted Markdown report under `evaluation\`, and report-location guidance was inconsistent between the spec clarification and harness contract.
  - **Resolution**: implementation-corrected
  - **Detail**: `evaluation\scorers\process-scorer.ps1` now writes `evaluation\report.md` via `-WriteReport`, documentation now distinguishes lifecycle artifact storage from harness report output, and `tests\integration\process-quality-report.ps1` verifies the generated report includes process quality, deferred outcome quality, and per-iteration breakdown sections.
