# Iteration Plan: 001 — Session Mode Configuration & File Classification

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 11/20 story_points
**Started**: 2026-05-31
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

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | `session_mode` config flag in `.specrew/config.yml` (`single` or `multi`) | US1 |
| FR-002 | `specrew config set session_mode <value>` CLI command + validation | US1 |
| FR-003 | Default to `single` when no `session_mode` configured | US1 |
| FR-004 | Classify files into shared / per-session / append-only-shared / regenerable | US2 |
| FR-005 | Generate/update `.gitignore` for per-session files at init | US2 |
| FR-006 | Remove previously tracked per-session files via `git rm --cached` | US2 |

Iteration 1 is the foundation/dependency gate (TG-005): session_mode must be configurable and per-session files gitignored before any later coordination work. Out of scope for this iteration: collision detection, claims, auto-detection (Iter 2a/2b), upgrade + version fix (Iter 3), identity split + worktree detection (Iter 4).

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Module manifest scaffold for session-mode support | FR-001 | US1 | 0.5 | Implementer | `Specrew.psd1` | done | claude | 0.5 | pass |
| T002 | Add session_mode key to `.specrew/config.yml` schema | FR-001 | US1 | 0.5 | Implementer | `.specrew/config.yml` | done | claude | 0.5 | pass |
| T003 | File classification schema (data-driven rule set: 4 categories + canonical patterns) | FR-004 | US2 | 0.5 | Implementer | `scripts/internal/file-classification.ps1` (Get-FileClassification; per D-002 codebase idiom, not `.specify/config.yml`) | done | claude | 0.5 | pass |
| T004 | `Set-SessionMode` function + validation | FR-001, FR-002 | US1 | 1.0 | Implementer | `scripts/specrew-config.ps1`, `scripts/internal/session-config.ps1` | done | claude | 1.0 | pass |
| T005 | `specrew config set session_mode` CLI entry | FR-002 | US1 | 0.5 | Implementer | `scripts/specrew.ps1`, `scripts/specrew-config.ps1` | done | claude | 0.5 | pass |
| T006 | Default session_mode=single in `specrew init` (via governance scaffold) | FR-003 | US1 | 0.5 | Implementer | `extensions/specrew-speckit/scripts/scaffold-governance.ps1` (+ `.specify/` mirror) | done | claude | 0.5 | pass |
| T007 | Acceptance test: session-mode set/revert | FR-002 | US1 | 0.5 | Implementer | `tests/` | done | claude | 0.5 | pass |
| T008 | Acceptance test: fresh-init default single | FR-003 | US1 | 0.5 | Implementer | `tests/` | done | claude | 0.5 | pass |
| T009 | `file-classification.ps1` classification function | FR-004 | US2 | 1.0 | Implementer | `scripts/internal/file-classification.ps1` | done | claude | 1.0 | pass |
| T010 | Gitignore generation (merge without dup) | FR-005 | US2 | 1.0 | Implementer | `scripts/internal/file-classification.ps1` | done | claude | 1.0 | pass |
| T011 | Integrate gitignore generation into `specrew init` | FR-005 | US2 | 0.5 | Implementer | `scripts/specrew-init.ps1` | done | claude | 0.5 | pass |
| T012 | `git rm --cached` cleanup function | FR-006 | US2 | 0.5 | Implementer | `scripts/internal/file-classification.ps1` | done | claude | 0.5 | pass |
| T013 | Init cleanup step invoking git-rm-cached | FR-006 | US2 | 0.5 | Implementer | `scripts/specrew-init.ps1` | done | claude | 0.5 | pass |
| T014 | Acceptance test: gitignore excludes per-session patterns | FR-005 | US2 | 0.5 | Implementer | `tests/unit/feature-051-file-classification.tests.ps1` | done | claude | 0.5 | pass |
| T015 | Acceptance test: git-rm-cached without working-tree delete | FR-006 | US2 | 0.5 | Implementer | `tests/unit/feature-051-file-classification.tests.ps1` | done | claude | 0.5 | pass |
| T016 | Verify quickstart.md accurate vs shipped behavior | FR-001..006 | US1 | 0.5 | Implementer | `specs/051-multi-session-foundation/quickstart.md` | planned | claude | — | — |
| T017 | Verify data-model.md entities vs shipped schema | FR-001..006 | US2 | 0.5 | Implementer | `specs/051-multi-session-foundation/data-model.md` | planned | claude | — | — |
| T018 | Run Iteration-1 acceptance suite + record results | FR-001..006 | US1 | 0.5 | Implementer | `tests/` | planned | claude | — | — |
| T019 | Run Specrew validator — backward compat / no regressions | FR-001..006 | US2 | 0.5 | Reviewer | — | planned | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator (Security Specialist deferred to Iteration 2a before-implement when race-condition/lock scope lands).
- Workstream separability: within Iteration 1, T001-T003 (setup) run first; T004-T008 (session mode, US1) and T009-T015 (file classification, US2) are independent and may run in parallel after setup.
- Shared-surface conflict risk: `scripts/specrew-cli.ps1` is touched by T005/T006/T011/T013 — serialize those edits or coordinate a single owner to avoid churn.
- Recommendation: single-developer serial execution; no Junior/Senior same-specialty expansion for this 11 SP foundation slice.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Plan-boundary artifacts authored; capacity re-estimated to 11 SP |
| Discovery/Spikes | 0 | No spikes required; mechanisms decided in research.md |
| Implementation | ~8 SP | T001-T015 delivery tasks |
| Review | ~2 SP | T018-T019 + review-signoff |
| Rework | ~1 SP | Buffer if review finds gaps |

## Traceability Summary

- Requirement scope for Iteration 1: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006
- User stories represented: US1 (Configure Multi-Session Mode), US2 (Avoid Per-Session File Conflicts)
- Success criteria targeted: SC-001 (per-session merge conflicts eliminated), SC-005 (version sync — partial; full coverage in Iteration 3)
- All 19 tasks (T001-T019) map to ≥1 FR; all 6 in-scope FRs have ≥1 task. Capacity 11/20 SP — within cap.

## Notes

- Capacity 11 SP reflects the honest re-estimate (2026-05-31) that resolved drift D-001; supersedes the inflated 28 SP per-task markup from the 48→97 task expansion. See [capacity-reestimate.md](capacity-reestimate.md).
- Status stays `planning` until the before-implement hardening gate passes and human approval is granted.
