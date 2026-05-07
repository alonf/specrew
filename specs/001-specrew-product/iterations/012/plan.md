# Iteration Plan: 012

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 4/20 story_points
**Started**: 2026-05-07
**Completed**:

## Summary

Iteration 012 isolates the `specrew start` ergonomics repairs that were mixed into the same working tree as the reviewer-closeout correction. It keeps project-path defaulting, Windows same-window Copilot launch behavior, and the matching start-command regressions in their own forward slice.

This separation keeps start-flow behavior hardening from contaminating the governance correction, so each slice can be reviewed and committed on its own merits.

---

## Scope

### In Scope

- Ensure `specrew start` defaults `--project-path` to the caller repo when the wrapper omits it
- Keep Windows same-window Copilot launch interactive by using a separate child `pwsh` process
- Add regression coverage for the wrapper project-path behavior and same-window launch path

### Out of Scope

- Reviewer-closeout governance corrections
- Downstream repo hygiene work (`FR-055`)
- Boundary commit-offer workflow (`FR-056`)

---

## Requirements Traceability

| Spec Ref | Requirement | Planned Deliverables | Owner |
|----------|-------------|----------------------|-------|
| FR-024 | `specrew start` resolves the project context from the caller repo instead of the Specrew source repo | `scripts\specrew.ps1` wrapper hardening | Implementer |
| FR-024 | Same-window Copilot launch stays interactive on Windows | `scripts\specrew-start.ps1` launch-path hardening | Implementer |
| FR-024 | Start-command regressions prove both behaviors under scratch-project invocation | `tests\integration\start-command.ps1` | Reviewer |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-1201 | Default `specrew start` project-path injection to the caller working directory | FR-024 | US-1 | 1 | Implementer | done | copilot-agent | 1 | pass |
| T-1202 | Keep Windows same-window Copilot handoff interactive via a child PowerShell process | FR-024 | US-1 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-1203 | Lock the wrapper and launch behaviors down with start-command regressions | FR-024 | US-1 | 1 | Reviewer | done | copilot-agent | 1 | pass |

**Planned Total**: 4 story_points

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Keep the slice fixed to start-command behavior hardening. |
| Time Limit (hours) | n/a | Not used for this scope-bounded iteration. |
| Overcommit Threshold | 1.0 | No overcommit expected at planned capacity 4/20. |
| Defer Strategy | manual | If more start-flow UX improvements surface, plan them separately instead of widening this repair slice. |
| Calibration Enabled | true | Retro should confirm whether start-command hardening remains a small corrective slice. |

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Separate the start-command repairs from the governance correction before review |
| Implementation | 2 | Carry the wrapper, launch, and regression changes as one coherent slice |
| Review | 1 | The isolated start-command integration suite proved both repaired behaviors |
| Rework | 0 | The known defects were fixed directly without a second repair loop |

---

## Acceptance Checkpoints

1. `specrew start` without an explicit `--project-path` writes artifacts into the caller project rather than the Specrew source repo.
2. Windows same-window launch stays interactive instead of dropping out after the initial Copilot bootstrap prompt.
3. The start-command regressions cover both repaired behaviors without depending on the governance-correction slice.

## Notes

- Iteration 011 was temporarily set aside while this slice was validated and closed so the reviewer packet reflects only the `specrew start` repair.
- This iteration is intentionally a start-flow hardening follow-up, not the scheduled repo-hygiene or boundary-commit roadmap work.
