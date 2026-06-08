# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: reviewing
**Capacity**: 11/20 story_points
**Started**: 2026-06-08
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose.
  - Task Status MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 002 = US-2 (launcher remains useful without double-bootstrap) + US-3 (handover
round-trip informs the next launch). Builds on the iteration-001 IDesign seams.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-006 | `specrew start` retained for compatibility + host selection | US-2 |
| FR-007 | Launcher-then-hook startup is idempotent (<=1 bootstrap) | US-2 |
| FR-009 | SessionEnd handover writing through the shipped hook path | US-3 |
| FR-010 | SessionStart reads a valid handover and surfaces it | US-3 |
| FR-017 | Validate handover against project state (handover-first stage) | US-3 |
| FR-021 | SessionEnd handover writing is write-only by default | US-3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T008 | Read/write Proposal 130 handover (.md + index) | FR-009, FR-010 | US-3 | 2 | Implementer | scripts/internal/bootstrap/HandoverStore.ps1 | done | claude | 2 | — |
| T009 | Extend validation: handover vs project state | FR-010, FR-017 | US-3 | 2 | Implementer | scripts/internal/bootstrap/ValidationEngine.ps1 | done | claude | 2 | — |
| T010 | Extend classification: handover-first stage + welcome-back | FR-010, FR-017 | US-3 | 1 | Implementer | scripts/internal/bootstrap/ClassificationEngine.ps1 | done | claude | 1 | — |
| T011 | Write-only SessionEnd handover + opt-in scoped commit | FR-009, FR-021, SC-003 | US-3 | 2 | Implementer | scripts/internal/bootstrap/SessionEndHandoverManager.ps1 | done | claude | 2 | — |
| T012 | Full SessionEnd->SessionStart round-trip (read-validate-surface) | FR-010, FR-017, SC-003 | US-3 | 2 | Implementer | tests/bootstrap/SessionEndHandover.Tests.ps1 | done | claude | 2 | — |
| T013 | `specrew start` preface + launcher<->hook dedupe handshake | FR-006, FR-007, SC-002 | US-2 | 2 | Implementer | scripts/internal/bootstrap/LauncherIntegration.ps1 | done | claude | 2 | — |

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
- IDesign dependency chain (HandoverStore -> engine extensions -> manager -> round-trip;
  LauncherIntegration is independent) keeps execution mostly serial.
- Shared-surface risk: low; extends existing `scripts/internal/bootstrap/` components.
- Recommendation: serial single-Implementer execution; no Junior/Senior split.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Feature spec + design-analysis + tasks complete in iteration 001. |
| Discovery/Spikes | 0 | Proposal 130 handover format is the only external contract. |
| Implementation | 11 | T008-T013. |
| Review | 2 | reviewer artifacts + Proposal-145 review. |
| Rework | 2 | needs-work buffer. |

## Traceability Summary

- Iteration 002 requirement scope: FR-006, FR-007, FR-009, FR-010, FR-017, FR-021.
- User stories represented: US-2 (launcher dedupe), US-3 (handover round-trip).
- Deferred to iteration 003: FR-005 per-host, FR-011/FR-012 regression+negative, FR-018/FR-019
  concurrency, SC-007 journal-assertion, FR-008 docs.
- Per-task effort sums to 11 SP = declared Capacity 11/20 (no overcommit).

## Notes

- Capacity 11/20: per-task SP (2+2+1+2+2+2) = 11, within the 20 cap.
- Proposal 130 owns the handover format; HandoverStore (T008) reads/writes a Proposal
  130-compatible handover and does not re-author the format.
- FR-007 idempotency (launcher + hook = exactly one bootstrap, SC-002) is the retry-idempotency
  concern that returns as `addressed` in this iteration's hardening gate.
