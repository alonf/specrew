# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 12/20 story_points
**Started**: 2026-06-08
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Scope Summary

Iteration 001 = US-1 (direct-launch full bootstrap) + US-4 (stale-anchor clearing),
Claude-first. Other requirements are iterations 002/003 (see ../../tasks.md).

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | SessionStart B2 becomes the primary bootstrap (Claude-first) | US-1 |
| FR-002 | B2 provider injects the orientation + menu directive | US-1 |
| FR-003 | Hook stays non-interactive | US-1 |
| FR-004 | Directive requires visible prose before any picker | US-1 |
| FR-005 | Per-host menu rendering (Claude in 001; others in 003) | US-1 |
| FR-013 | Clear active anchors when feature merged/closed | US-4 |
| FR-015 | Absolute-path anchors non-portable; re-resolve project-local | US-4 |
| FR-016 | Division of labor resolved at design-analysis; realized by T007 | US-1 |
| FR-017 | Validate state before resume (anchor stage; handover in 002) | US-1, US-4 |
| FR-020 | Render-first enforced mechanically (disallowed-tools skill) | US-1 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Normalize Claude SessionStart payload | FR-001, FR-005 | US-1 | 1 | Implementer | scripts/internal/bootstrap/HostEventAdapter.ps1 | planned | claude | — | — |
| T002 | Anchor read/write; non-portable absolute path | FR-013, FR-015 | US-4 | 2 | Implementer | scripts/internal/bootstrap/SessionStateAccessor.ps1 | planned | claude | — | — |
| T003 | Feature metadata + git merged/closed/portability reads | FR-014, FR-015 | US-4 | 2 | Implementer | scripts/internal/bootstrap/ProjectMetadataAccessor.ps1 | planned | claude | — | — |
| T004 | Pure mode decision (full / cleared-anchor; anchor stage) | FR-001, FR-017 | US-1, US-4 | 2 | Implementer | scripts/internal/bootstrap/ClassificationEngine.ps1 | planned | claude | — | — |
| T005 | Validate anchor vs project state; clear stale anchors | FR-013, FR-015, FR-017 | US-4 | 2 | Implementer | scripts/internal/bootstrap/ValidationEngine.ps1 | planned | claude | — | — |
| T006 | Build the data-oriented directive (render_first) | FR-002, FR-004 | US-1 | 1 | Implementer | scripts/internal/bootstrap/DirectiveEngine.ps1 | planned | claude | — | — |
| T007 | Orchestrate B2 + render-first skill + B2 register/FileList + basic journal record | FR-001, FR-002, FR-003, FR-016, FR-020 | US-1 | 2 | Implementer | scripts/internal/bootstrap/SessionBootstrapManager.ps1 | planned | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- IDesign layering forces a serial dependency chain (accessors/adapter → engines → manager),
  so iteration 001 runs serial; T001/T002/T003 are independent files (`[P]`-eligible) but the
  engines depend on them.
- Shared-surface risk: low — one new `scripts/internal/bootstrap/` folder, one file per
  component; the F-171 dispatcher is reused unchanged.
- Recommendation: serial single-Implementer execution; no Junior/Senior same-specialty split.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Spec + design-analysis (Option B) + tasks complete |
| Discovery/Spikes | 0 | No spike needed; design resolved at the workshop |
| Implementation | 12 | T001–T007 |
| Review | 2 | reviewer artifacts + per-path engine tests |
| Rework | 2 | needs-work buffer |

## Traceability Summary

- Iteration 001 requirement scope: FR-001, FR-002, FR-003, FR-004, FR-005, FR-013, FR-015,
  FR-016, FR-017, FR-020.
- User stories represented: US-1 (direct-launch bootstrap), US-4 (stale-anchor clearing).
- Deferred to later iterations: FR-006/007/008/009/010/011/012/014/018/019/021 (002/003).
- Per-task effort sums to 12 SP = declared Capacity 12/20 (no overcommit).

## Notes

- Capacity 12/20: per-task SP (1+2+2+2+2+1+2) = 12, within the 20 cap with headroom.
- FR-014's sync-side prevention (closeout not retaining a committed anchor) is partially read
  here via T003; its full sync-side guarantee is revisited at iteration 003 / closeout.
- Hardening gate `Overall Verdict: ready` (planning-time) at `quality/hardening-gate.md`;
  runtime evidence recorded at iteration close.
