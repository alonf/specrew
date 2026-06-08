# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: reviewing
**Capacity**: 18/20 story_points
**Started**: 2026-06-08
**Completed**:

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity `<consumed>/<cap> <unit>` no trailing prose. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Scope Summary

Iteration 003 (the final one): make the bootstrap + handover LIVE across hosts and add the
remaining hardening. **Live-wiring is SEQUENCED FIRST** (T021/T022) so any SessionEnd-dispatch
difficulty surfaces early, and both wiring closures are **proven with real dispatcher smokes**, not
test-only (the D-001 self-host bar applied to D-001 + D-002 — see `.squad/decisions.md`
`f174-i003-livewiring-first`).

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | B2 bootstrap live across hosts (downstream deploy, D-001) | US-1 |
| FR-005 | Per-host Codex/Copilot/Cursor normalization + empirical verification | US-1 |
| FR-008 | Docs/prompts: hook = primary bootstrap, specrew start = compat | US-2 |
| FR-009 | SessionEnd handover writer registered + live (D-002) | US-3 |
| FR-011 | B1/B3 unchanged from F-171 (regression) | US-1 |
| FR-012 | B4/Antigravity deferred (negative test) | US-1 |
| FR-018 | Advisory SessionStart marker | US-4 |
| FR-019 | Local same-worktree concurrency detection (1h window) | US-4 |
| SC-007 | Distinguishable journal record per mode (asserted) | — |

## Tasks

Build order: **live-wiring first** (T021, T022), then per-host, concurrency, journal, regression, docs.

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T021 | D-001 downstream extension-tree deploy + LIVE SessionStart cross-host dispatcher smoke | FR-001, FR-005 | US-1 | 3 | Implementer | extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1 | done | claude | 3 | — |
| T022 | D-002 SessionEnd hook registration (handover provider, events:SessionEnd) + LIVE SessionEnd->SessionStart round-trip smoke | FR-009 | US-3 | 3 | Implementer | scripts/internal/specrew-handover-provider.ps1 | done | claude | 3 | — |
| T016 | Per-host SessionStart/SessionEnd normalization (Codex/Copilot/Cursor) | FR-005 | US-1 | 2 | Implementer | scripts/internal/bootstrap/HostEventAdapter.ps1 | done | claude | 2 | — |
| T017 | Per-host empirical verification (render-before-picker, all 4 hosts) | FR-005, SC-001, SC-005 | US-1 | 2 | Implementer | tests/bootstrap/PerHost.Tests.ps1 | done | claude | 2 | — |
| T014 | SessionStart marker write + 1h-window freshness state | FR-018 | US-4 | 2 | Implementer | scripts/internal/bootstrap/SessionStateAccessor.ps1 | done | claude | 2 | — |
| T015 | Advisory local same-worktree concurrency + unclean-exit detection | FR-018, FR-019 | US-4 | 2 | Implementer | scripts/internal/bootstrap/ClassificationEngine.ps1 | done | claude | 2 | — |
| T018 | HookJournalAccessor + per-path journal-assertion tests (every mode + unclean-exit) | SC-007 | US-1 | 2 | Implementer | scripts/internal/bootstrap/HookJournalAccessor.ps1 | done | claude | 2 | — |
| T019 | B1/B3 regression + FR-012 negative test (no B4/Antigravity path executes) | FR-011, FR-012, SC-005 | US-1 | 1 | Implementer | tests/bootstrap/Regression.Tests.ps1 | done | claude | 1 | — |
| T020 | Update docs/prompts: hook = primary bootstrap, specrew start = compat | FR-008, SC-006 | US-2 | 1 | Implementer | docs/getting-started.md | done | claude | 1 | — |

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
- T021/T022 (live-wiring) are sequenced first and serial; per-host (T016/T017) and concurrency
  (T014/T015) are largely independent afterward but small.
- Shared-surface risk: low - T022 adds a SessionEnd provider ROW + SCRIPT, no F-171 dispatcher-logic
  edit (the dispatcher already dispatches by event), so B1/B3 are unchanged by construction (FR-011).
- Recommendation: serial single-Implementer execution; no Junior/Senior split.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Feature spec + design-analysis + tasks complete. |
| Discovery/Spikes | 0 | The SessionEnd-dispatch difficulty is surfaced early by sequencing T022 first. |
| Implementation | 18 | T021/T022 (live-wiring) + T014-T020. |
| Review | 2 | reviewer artifacts + Proposal-145 review (with the build+test!=live live-wiring check). |
| Rework | 2 | needs-work buffer. |

## Traceability Summary

- Iteration 003 requirement scope: FR-001, FR-005, FR-008, FR-009, FR-011, FR-012, FR-018, FR-019,
  SC-007 (+ SC-001/SC-005/SC-006 via verification/docs).
- User stories: US-1 (live + multi-host), US-3 (SessionEnd live), US-4 (concurrency), US-2 (docs).
- Carries closed: D-001 (downstream deploy, T021) + D-002 (SessionEnd registration, T022) - both
  proven LIVE via real dispatcher smokes.
- Per-task effort sums to 18 SP = declared Capacity 18/20 (no overcommit).

## Notes

- Capacity 18/20: per-task SP (3+3+2+2+2+2+2+1+1) = 18, under the 20 cap.
- Live-wiring proof bar (decisions `f174-i003-livewiring-first`): T021 proven by a real
  cross-host SessionStart dispatcher smoke; T022 by a real SessionEnd->SessionStart round-trip
  dispatcher smoke. Test-only is NOT sufficient for these two.
- T022 needed NO F-171 dispatcher-logic edit: the dispatcher already dispatches any event to
  providers whose `events` array contains it, so SessionEnd was added purely as a provider ROW +
  a provider SCRIPT. B1/B3 are therefore byte-unchanged by construction (no dispatcher edit);
  T019 still regression-verifies them.
