# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 3/20 story_points
**Started**: 2026-06-07
**Completed**: 2026-06-07

## Scope Summary

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-001 | Explain that the profile controls Specrew guidance behavior. | US1 |
| FR-002 | Use behavior-centered scale wording. | US1 |
| FR-003 | Add setup-specific prompt metadata. | US1 |
| FR-004 | Blank setup input normalizes to `auto`. | US2 |
| FR-005 | Case-insensitive `auto` normalizes to canonical `auto`. | US2 |
| FR-006 | Numeric setup input normalizes safely; invalid input rejects. | US2 |
| FR-007 | Existing display labels, keys, and persona IDs remain stable. | US2 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T001 | Proposal and traceability artifacts | FR-001..FR-007 | US1, US2 | 0.5 | Spec Steward | `proposals/170-new-user-profile-setup-copy.md`; `specs/172-profile-setup-ux-copy/**` | done | codex | 0.5 | accepted |
| T002 | First-run setup copy and input helper | FR-001..FR-007 | US1, US2 | 1.0 | Implementer | `scripts/internal/user-profile.ps1` | done | codex | 1.0 | accepted |
| T003 | Integration tests | FR-003..FR-007 | US1, US2 | 1.0 | Implementer | `tests/integration/f049-i003-intake-engine-tests.ps1` | done | codex | 1.0 | accepted |
| T004 | Evidence, lint, commit, push | SC-001..SC-003 | US1, US2 | 0.5 | Implementer | `specs/172-profile-setup-ux-copy/iterations/001/**` | done | codex | 0.5 | accepted |

## Traceability Summary

- Every FR maps to at least one task.
- Every task maps to at least one FR/SC.
- No schema migration is in scope.

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Small-fix scope was fixed by Proposal 170. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | No deferrals were needed. |
| Calibration Enabled | true | Retro records whether future capacity should change. |

## Notes

- The maintainer's 2026-06-07 instruction authorized implementation after
  proposal/worktree setup.
- Review evidence is captured in
  `specs/172-profile-setup-ux-copy/iterations/001/coverage-evidence.md`.
- No workshop artifact was added; maintainer explicitly requested no workshop
  backfill for this artifact-shape repair.
