# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-29
**Baseline Ref**: b1b1ca0afff2c988cc4b94de0f96cd3a7d0b255c
**Test-to-Code Ratio**: 4:9

> **Review Evidence Disposition** _(Form-vs-Meaning heuristic — DISPOSITIONED, not a gap)_
>
> The heuristic flags that **10 completed task(s)** differ from **38 file(s)** in the
> baseline→HEAD diff. This is an expected over-delivery mismatch, NOT a form-vs-meaning gap:
> each task legitimately touches multiple files, and ~26 of the 38 are spec/iteration
> governance artifacts (spec.md, plan.md, tasks.md, data-model/quickstart/contracts/diagrams,
> iteration plan/state/drift-log/quality/reviewer artifacts) — not 1-task-per-file code.
> All 10 tasks are committed (619c2740) with passing tests; reviewed content is the 12 code/
> test files + the governance artifacts. No uncommitted work; baseline ref is correct.

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| Specrew.psd1 | 3 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| hosts/_registry.ps1 | 3 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| hosts/cursor/coordinator-rules.psd1 | 35 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| hosts/cursor/handlers.ps1 | 230 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| hosts/cursor/host.psd1 | 28 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/init/post-bootstrap-output.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/internal/coordinator-prompt-surgery.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/internal/detect-hosts.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/internal/host-flag-translation.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/internal/host-history.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| scripts/specrew-start.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/checklists/requirements.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/contracts/cursor-host.md | 12 | 9 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/current-architecture.md | 15 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/data-model.md | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/code-map.md | 85 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/coverage-evidence.md | 60 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/dashboard.md | 38 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/dependency-report.md | 46 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/drift-log.md | 72 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/plan.md | 97 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/quality/hardening-gate.md | 42 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/quality/mechanical-findings.json | 11 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/quality/trap-reapplication.md | 15 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/review-diagrams.md | 49 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/review.md | 54 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/reviewer-index.md | 53 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/iterations/001/state.md | 38 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/plan.md | 9 | 9 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/quickstart.md | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/review-diagrams.md | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| specs/050-cursor-host-support/spec.md | 4 | 4 | T002, T003, T004, T005, T006, T010 | Implementer |
| specs/050-cursor-host-support/tasks.md | 8 | 8 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010 | Implementer |
| tests/integration/host-cursor.tests.ps1 | 108 | 0 | T002, T003, T004, T005, T006, T010 | Implementer |
| tests/integration/host-registry.tests.ps1 | 23 | 20 | T002, T003, T004, T005, T006, T010 | Implementer |
| tests/integration/multi-host-launch-path.tests.ps1 | 2 | 2 | T002, T003, T004, T005, T006, T010 | Implementer |

## Public-API Delta

### Added

- New-CursorLaunchInvocation (hosts/cursor/handlers.ps1)
- ConvertTo-CursorFlag (hosts/cursor/handlers.ps1)
- Test-CursorRuntimeInstalled (hosts/cursor/handlers.ps1)
- Get-CursorSignals (hosts/cursor/handlers.ps1)
- ConvertTo-CursorAgentDescription (hosts/cursor/handlers.ps1)
- Install-CursorCrewRuntime (hosts/cursor/handlers.ps1)
- Write-Pass (tests/integration/host-cursor.tests.ps1)
- Write-Fail (tests/integration/host-cursor.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- none
