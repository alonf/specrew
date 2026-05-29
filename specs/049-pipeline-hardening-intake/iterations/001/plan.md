# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 17/20 story_points
**Started**: 2026-05-27
**Completed**: 2026-05-27

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
| FR-001 | System MUST supply a Docker-based test runner using a Linux-based PowerShell container (`mcr.microsoft.com/powershell:lts-ubuntu-22.04`). | — |
| FR-002 | The harness MUST download and install the previous stable version (`0.27.6`) in a clean environment as the baseline. | — |
| FR-003 | The harness MUST verify that **every** item listed in the packaged candidate's `Specrew.psd1` `FileList` successfully unpacked on disk. | — |
| FR-004 | The harness MUST run `specrew update` and verify that the local project structure is updated cleanly, and mirror parity checks return `PASS`. | — |
| FR-005 | `.github/workflows/publish-module.yml` MUST execute this Docker harness as a blocker before any release is pushed to PSGallery. | — |
| FR-006 | System MUST contain `docs/troubleshooting.md` addressing: PSGallery side-by-side caches, FileList drops, deploy-script exceptions, stale-state recovery, and clean-reinstall flows. | — |
| FR-007 | `docs/troubleshooting.md` MUST be registered in `Specrew.psd1` `FileList` immediately upon creation. | — |
| FR-008 | `/speckit.specify` MUST support **4 target personas**. | — |
| FR-009 | The system MUST supply a **12-category intake catalog** representing comprehensive software parameters. | — |
| FR-010 | Intake MUST dynamically branch into **Mode A (Direct Confirmation)**, **Mode B (Targeted Clarify)**, or **Mode C (Full Interview)** based on the completeness of initial input. | — |
| FR-011 | Intake forms MUST support `"Other"` and `"I don't know, you decide"` options, triggering proactive agent domain research when selected. | — |
| FR-012 | Harness MUST fail E2E validation if version mismatch drift is detected in manifests (Prop 134 version pin check). | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Add failing E2E publish-module test assertions | FR-003,FR-012,SC-001 | US1 | 1 | Reviewer | tests/integration/* | done | antigravity | 1 | ✅ |
| T002 | Create tests/Dockerfile.publish-test | FR-001,FR-002,SC-001 | US1 | 2 | Implementer | tests/Dockerfile.publish-test | done | antigravity | 2 | ✅ |
| T003 | Create scripts/internal/test-publish-harness.ps1 | FR-003,SC-001 | US1 | 3 | Implementer | scripts/internal/test-publish-harness.ps1 | done | antigravity | 3 | ✅ |
| T004 | Add manifest version pin drift assertions | FR-012,SC-001 | US1 | 1 | Implementer | scripts/internal/test-publish-harness.ps1 | done | antigravity | 1 | ✅ |
| T005 | Add specrew update execution and layout validation | FR-004,SC-001 | US1 | 2 | Implementer | scripts/internal/test-publish-harness.ps1 | done | antigravity | 2 | ✅ |
| T006 | Wire Docker harness execution into workflows | FR-005,SC-001 | US1 | 1 | Implementer | .github/workflows/publish-module.yml | done | antigravity | 1 | ✅ |
| T007 | Run focused harness tests locally and in CI | FR-005,SC-001 | US1 | 2 | Reviewer | tests/* | done | antigravity | 2 | ✅ |
| T018 | Fix duplicate-row deploy bug | FR-013 | US1 | 2 | Implementer | scripts/specrew-update.ps1 | done | antigravity | 2 | ✅ |
| T019 | Add duplicate-row regression integration test | FR-013 | US1 | 1 | Reviewer | tests/integration/* | done | antigravity | 1 | ✅ |
| T020 | Implement PSGallery version check in update --info | FR-014 | US1 | 2 | Implementer | scripts/specrew-update.ps1 | done | antigravity | 2 | ✅ |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: Linux-based Docker testing and GitHub Actions workflow scripting. High implementation slice density.
- Task dependency graph: T002 (Dockerfile) and T003 (test harness) are structural prerequisites for the assertion enhancements T004/T005 and integration T006. T001 (failing tests) must precede implementing the pass states, and T007 validates final integration.
- Workstream separability: The implementation tasks are tightly coupled around `test-publish-harness.ps1`, recommending serial execution to avoid merge conflicts on the same file.
- Shared-surface conflict risk: elevated if parallelized due to shared implementation in `test-publish-harness.ps1`.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion; keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0 | Completed prior to boundary execution |
| Discovery/Spikes | 0 | No spikes planned |
| Implementation | 13 | Sum of Implementer tasks T002-T006, T018, T020 |
| Review | 4 | Sum of Reviewer tasks T001, T007, and T019 |
| Rework | 0 | Absorb via tests-first discipline |

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-012, FR-013, FR-014
- User stories represented in current scope: US1
- Overcommit guardrail: 17 story_points consumed of 20 story_points capacity (well below threshold).

## Notes

- This plan decompositions Iteration 001 tasks focusing on pipeline hardening and version pin validation.
- All status values are planning until approved.