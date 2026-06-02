# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 19/20 story_points
**Started**: 2026-06-02
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

Iteration 1 of the 2-iteration split: wrappers + generator + parity + installer + FileList (the platform-agnostic, unit-testable core). FR-007, FR-012, FR-014, FR-015 are deferred to Iteration 2 (install.sh, Ubuntu/macOS CI, docs, greenfield/brownfield release gate).

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | POSIX wrapper scripts for the root `specrew` + each exported alias. | US1 |
| FR-002 | Exact argument forwarding (quotes, spaces, globs, empty, passthrough). | US1 |
| FR-003 | Robust module-root resolution incl. via symlink (POSIX sh only). | US1 |
| FR-004 | Clear non-zero error when `pwsh` is missing (hint; no auto-install). | US1 |
| FR-005 | `specrew install-shell-wrappers` installs/refreshes wrappers (default `~/.local/bin`). | US2 |
| FR-006 | Installer idempotent + safe: `-WhatIf`, `-Force` to create, no out-of-dir mutation, PATH warn-only. | US2 |
| FR-008 | Thin forwarder; no duplicated option parsing; all args forwarded unchanged. | US1 |
| FR-009 | Generate-then-commit: generator is source of truth; committed wrappers; CI drift-diff. | US3 |
| FR-010 | `FileList` includes wrappers; packaging verifies presence. | US3 |
| FR-011 | Command-surface change triggers parity cascade (registry→wrappers→FileList→docs). | US3 |
| FR-013 | Windows unchanged; `install-shell-wrappers` explained no-op unless requested. | US2 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Canonical registry reader (AliasesToExport + root) | FR-001, FR-009 | US1 | 1 | Implementer | `scripts/internal/**` | planned | | | |
| T002 | POSIX sh wrapper template (module-root + pwsh check + exec) | FR-002, FR-003, FR-004, FR-008 | US1 | 2 | Implementer | `scripts/internal/**` | planned | | | |
| T003 | generate-shell-wrappers.ps1 generator (deterministic/idempotent) | FR-009, FR-001 | US3 | 3 | Implementer | `scripts/internal/**` | planned | | | |
| T004 | Generate + commit the 8 bin/ wrappers | FR-001 | US1 | 1 | Implementer | `bin/**` | planned | | | |
| T005 | Generator unit tests (parse, render, idempotency) | FR-009 | US3 | 2 | Implementer | `tests/unit/**` | planned | | | |
| T006 | Registry ↔ wrapper parity test | FR-009, FR-011 | US3 | 2 | Reviewer | `tests/unit/**` | planned | | | |
| T007 | install-shell-wrappers subcommand (copy/-Force/-WhatIf/PATH-warn/confine + dispatch) | FR-005, FR-006, FR-013 | US2 | 4 | Implementer | `scripts/**` | planned | | | |
| T008 | Installer unit tests (idempotency, -Force, -WhatIf, confinement) | FR-006 | US2 | 2 | Implementer | `tests/unit/**` | planned | | | |
| T009 | FileList inclusion + packaging parity test | FR-010, FR-011 | US3 | 2 | Reviewer | `Specrew.psd1`, `tests/unit/**` | planned | | | |

## Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `dead-field` | mechanical | `iterations/001/quality/mechanical-findings.json` | planned |
| `anti-pattern` | mechanical | `iterations/001/quality/mechanical-findings.json` | planned |
| `test-integrity` | mechanical | `iterations/001/quality/mechanical-findings.json` | planned |
| `stack-tooling-evidence` | tooling | `iterations/001/quality/quality-evidence.md` | planned |
| `quality-lens-review` | manual-evidence | `iterations/001/quality/quality-evidence.md` | planned |

## Phase 2 Hardening

Pre-implementation hardening is planned in `iterations/001/quality/hardening-gate.md` (planning-time analysis + expected controls; runtime proof deferred to closure). Required lenses under `iterations/001/quality/lenses/`: `security-baseline@v1.0.0`, `robustness-baseline@v1.0.0`, `test-integrity@v1.0.0`. Focus areas: security surface (bin-dir confinement, `curl|sh` trust, no pwsh auto-install), error-handling/failure semantics (pwsh-missing, missing bin dir, not-on-PATH), test-integrity targets (FR→named-test, negative paths). Retry/idempotency: idempotency required for the installer; network-retry not-applicable.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives may suggest future capacity adjustments. |

## Concurrency Rationale

- Roster: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Dependency graph: T001→T002→T003→T004 (generator chain) is serial; T005/T006 follow T003/T004; T007→T008 (installer) is a parallel workstream after T004; T009 follows T004/T007. No same-specialty Junior/Senior split is warranted at this size.
- Shared-surface risk: T004 (bin/) and T009 (FileList) both touch packaging surfaces; keep serial (T009 after T004).
- Recommendation: single serial Implementer + Reviewer; no parallel same-specialty expansion.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Spec/clarify/plan/tasks committed |
| Discovery/Spikes | 0 | Architecture resolved via Proposal 153 + clarify |
| Implementation | 15 | T001-T005, T007 (generator + template + bin/ + installer) |
| Review | 4 | T006, T009 (parity + packaging) + review pass |
| Rework | buffer | within the 1 SP headroom (19/20) |

## Traceability Summary

- Requirement scope (Iteration 1): FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-008, FR-009, FR-010, FR-011, FR-013.
- Deferred to Iteration 2: FR-007, FR-012, FR-014, FR-015.
- User stories: US1 (native command surface), US2 (install), US3 (registry parity); US4 (docs) is Iteration 2.
- Every task maps to ≥1 in-scope FR; every in-scope FR maps to ≥1 task (see Tasks + feature `tasks.md`).

## Notes

- Capacity 19/20 leaves 1 SP rework headroom; per the maintainer split decision, Iteration 2 carries install.sh + CI + docs + release gate.
- Status stays `planning` until before-implement approval; flips to `executing` at implementation start.
