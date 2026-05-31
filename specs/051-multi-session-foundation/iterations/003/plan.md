# Iteration Plan: 003 — Iteration 2b: Conflict Reduction & Multi-Developer Auto-Detection

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 13/20 story_points
**Started**: 2026-05-31
**Completed**: 2026-06-01

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status MUST be one of: planned | in-progress | done | needs-rework | deferred | blocked
  - On-disk dir is 003 (zero-padded); the "Iteration 2b" label is prose only.
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-017 | Split `.squad/decisions.md` into per-iteration files under `.squad/decisions/iteration-NNN/decisions.md` when multi-session mode is enabled. | US5 |
| FR-018 | Use JSON Lines append-only logs to enable atomic appends and mechanical conflict resolution. | US5 |
| FR-019 | Alphabetically sort the `Specrew.psd1` FileList array during boundary-sync writes to minimize merge conflicts. | US5 |
| FR-020 | Detect multi-developer signals: recent git authors, machine fingerprints, concurrent writes, and branch fan-out. | US6 |
| FR-021 | Display a multi-session recommendation during Welcome Orientation when signals are detected and `session_mode` is `single`. | US6 |
| FR-022 | Display a multi-developer indicator in `specrew where` with unique developer/machine counts. | US6 |
| FR-023 | Include multi-developer activity notes in boundary-sync output when signals are detected. | US6 |
| FR-024 | Suppress recommendations when `session_mode` is already `multi`. | US6 |

**Scope boundary**: Iteration 2b covers conflict-reduction + auto-detection only. It does not implement Spec-Kit upgrade/version-sync work (Iteration 3), identity split/brand-new worktree detection (Iteration 4), or Proposal 148 Layer 2+3 file-surface/predictive conflict selection.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T034 | decisions-split.ps1 per-iteration decision file splitter | FR-017 | US5 | 1.0 | Implementer | `scripts/decisions-split.ps1`, `.squad/decisions/` | done | codex | 1.0 | pass |
| T035 | Boundary-sync integration for decisions split in multi-session mode | FR-017 | US5 | 0.5 | Implementer | `scripts/internal/sync-boundary-state.ps1`, `scripts/decisions-split.ps1` | done | codex | 0.5 | pass |
| T036 | append-only-logs.ps1 JSON Lines append primitives | FR-018 | US5 | 1.0 | Implementer | `scripts/append-only-logs.ps1` | done | codex | 1.0 | pass |
| T037 | Lifecycle event JSON Lines writer integration | FR-018 | US5 | 0.5 | Implementer | `scripts/append-only-logs.ps1`, `scripts/internal/sync-boundary-state.ps1` | done | codex | 0.5 | pass |
| T038 | psd1-sort.ps1 FileList alphabetical sorter | FR-019 | US5 | 0.5 | Implementer | `scripts/psd1-sort.ps1`, `Specrew.psd1` | done | codex | 0.5 | pass |
| T039 | Boundary-sync FileList sort integration | FR-019 | US5 | 0.5 | Implementer | `scripts/internal/sync-boundary-state.ps1`, `scripts/psd1-sort.ps1`, `Specrew.psd1` | done | codex | 0.5 | pass |
| T040 | Acceptance: decisions split avoids shared-file merge conflict surface | FR-017 | US5 | 0.5 | Implementer | `tests/` | done | codex | 0.5 | pass |
| T041 | Acceptance: FileList remains alphabetically sorted after sync | FR-019 | US5 | 0.5 | Implementer | `tests/` | done | codex | 0.5 | pass |
| T042 | auto-detection.ps1 multi-developer signal detector scaffold | FR-020 | US6 | 1.0 | Implementer | `scripts/auto-detection.ps1` | done | codex | 1.0 | pass |
| T043 | Git author email detection over recent history | FR-020 | US6 | 0.5 | Implementer | `scripts/auto-detection.ps1` | done | codex | 0.5 | pass |
| T044 | Machine fingerprint detection from local session-state surfaces | FR-020 | US6 | 0.5 | Implementer | `scripts/auto-detection.ps1`, `.specrew/active-sessions.yml` | done | codex | 0.5 | pass |
| T045 | Concurrent write signal detection | FR-020 | US6 | 1.0 | Implementer | `scripts/auto-detection.ps1` | done | codex | 1.0 | pass |
| T046 | Branch fan-out signal detection | FR-020 | US6 | 0.5 | Implementer | `scripts/auto-detection.ps1` | done | codex | 0.5 | pass |
| T047 | Welcome Orientation recommendation for single-session multi-dev signals | FR-021 | US6 | 0.5 | Implementer | `scripts/specrew-start.ps1`, `scripts/auto-detection.ps1` | done | codex | 0.5 | pass |
| T048 | `specrew where` multi-developer indicator | FR-022 | US6 | 0.5 | Implementer | `scripts/specrew-where.ps1`, `scripts/internal/dashboard-renderer.ps1`, `scripts/auto-detection.ps1` | done | codex | 0.5 | pass |
| T049 | Boundary-sync multi-developer activity note | FR-023 | US6 | 0.5 | Implementer | `scripts/internal/sync-boundary-state.ps1`, `scripts/auto-detection.ps1` | done | codex | 0.5 | pass |
| T050 | Suppress recommendations when `session_mode` is already `multi` | FR-024 | US6 | 0.5 | Implementer | `scripts/auto-detection.ps1`, `scripts/specrew-start.ps1`, `scripts/specrew-where.ps1` | done | codex | 0.5 | pass |
| T051 | Acceptance: two git authors trigger Welcome Orientation recommendation within 2s | FR-020, FR-021 | US6 | 0.5 | Implementer | `tests/` | done | codex | 0.5 | pass |
| T052 | Acceptance: `session_mode: multi` suppresses redundant recommendation | FR-024 | US6 | 0.5 | Implementer | `tests/` | done | codex | 0.5 | pass |
| T053 | Data-model reconciliation for SessionLockEntry, FeatureClaimEntry, MultiDevSignal | FR-020 | US6 | 0.5 | Reviewer | `specs/051-multi-session-foundation/data-model.md`, `specs/051-multi-session-foundation/iterations/003/` | done | codex | 0.5 | pass |
| T054 | Run Iteration 2a+2b acceptance tests and record evidence | FR-017, FR-024 | US5, US6 | 0.5 | Reviewer | `tests/`, `specs/051-multi-session-foundation/iterations/003/` | done | codex | 0.5 | pass |
| T055 | Run Specrew validator and verify no regressions from Iterations 1/2a | FR-017, FR-024 | US5, US6 | 0.5 | Reviewer | `specs/051-multi-session-foundation/iterations/003/`, `.specrew/last-validator-summary.json` | done | codex | 0.5 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives suggest future capacity adjustments. |

## Concurrency Rationale

- Critical path: T034/T036/T038 create reusable conflict-reduction primitives; T035/T037/T039 integrate them into boundary sync. T042 gates T043-T052.
- Shared-surface conflict risk is high: `scripts/internal/sync-boundary-state.ps1`, `scripts/specrew-start.ps1`, `scripts/specrew-where.ps1`, `scripts/internal/dashboard-renderer.ps1`, and `Specrew.psd1` are central shared files. Keep edits serial unless an ownership split is explicit.
- Data privacy: T044 reads local machine fingerprints from session-state surfaces but must not commit rich fingerprints or transmit them. Recommendation surfaces use counts and coarse explanations only.
- Recommendation: single-developer serial execution for this slice. Do not add Junior/Senior same-specialty parallelism unless the human explicitly approves a split after file ownership is narrowed.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Iteration 2b scope selected after 2a closeout; plan/hardening/state artifacts authored under dir 003. |
| Discovery/Spikes | 0 | Prior F-051 design already scoped US5+US6; no additional spike planned. |
| Implementation | ~9.0 SP | T034-T039 conflict reduction + T042-T050 auto-detection and recommendation surfaces. |
| Review | ~2.0 SP | T040/T041/T051/T052 acceptance plus artifact/data-model validation. |
| Rework | ~2.0 SP | Buffer for shared-surface wiring and validator/reviewer remediation. |

## Traceability Summary

- Requirement scope: FR-017 through FR-024.
- User stories: US5 (Reduce Shared-File Merge Conflicts), US6 (Detect Multi-Developer Activity).
- Success criteria: SC-003 (multi-dev detection), SC-006 (merge conflict elimination), SC-007 (recommendation within 0-2s).
- All 22 tasks (T034-T055) map to >=1 FR; all 8 in-scope FRs (017-024) have >=1 task. Capacity 13/20 story_points, within cap.

## Notes

- On-disk dir is `003`; pass `-IterationNumber 003` (quoted) to every boundary sync. "Iteration 2b" is prose-only.
- Retro carry-forward from Iteration 2a is active: keep state/prose/report artifacts coherent after every remediation round, and update `review-report.yml` whenever review remediation changes findings.
- The small-fix slice immediately before this opening shipped Proposal 150 (`d5e61b36`) so closeout sync now normalizes unpadded iteration numbers; still use padded strings in lifecycle commands.
