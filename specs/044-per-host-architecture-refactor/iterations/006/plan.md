# Iteration Plan: 006

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 5.5/20 story_points
**Started**: 2026-05-24
**Completed**: 2026-05-25

> Third LIVE-TRACKED iteration of F-044 (iter-004 + iter-005 + iter-006). Plan written before code; actuals filled at task close.

## Scope Summary

Antigravity dogfood (post-iter-005) launched correctly but surfaced 3 real Specrew bugs while debugging around the stale-install dispatch. Antigravity ended up patching `.specify/.../scaffold-iteration-plan.ps1` in the user's test project. iter-006 canonicalizes the fixes + adds the diagnostic improvements that would have made Antigravity's debugging unnecessary.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-009 | `scripts/specrew-init.ps1` split + tooling robustness (extends to deployed shim hardening) | US5 |
| FR-011 | Adding a new host requires zero edits — preserved | US4 |
| FR-012 | Documentation updated for shipped state | US5 |
| FR-013 | Tests added; smoke-test for multi-host-lifecycle | (testing) |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | `sync-boundary-state.ps1` shim + Specrew.psm1 — $env:SPECREW_MODULE_PATH set on import; shim honors env override + walk-up + ListAvailable (highest version); stale-install detection refuses dispatch with actionable guidance | FR-009 | US5 | 2 | Implementer | extensions/specrew-speckit/scripts/sync-boundary-state.ps1; Specrew.psm1 | done | claude | 2 | pass |
| T002 | Canonicalized Antigravity's StrictMode fix: `$null -ne $RequirementScope -and $RequirementScope.Count` (was `$RequirementScope -and ...` — threw on unbound param) | FR-009 | US5 | 2 | Implementer | extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1 | done | claude | 0.5 | pass |
| T003 | scaffold-iteration-plan.ps1 degrades gracefully when spec has no canonical FRs — replaces hard `throw "No functional requirements"` with `Write-Warning` + FR-PLACEHOLDER row so iteration plan still scaffolds + retro can land | FR-009 | US5 | 1 | Implementer | extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1 | done | claude | 1 | pass |
| T004 | `tests/integration/multi-host-lifecycle-smoke.tests.ps1` — 7 assertions covering env var, stale-install detection, scaffolder tolerance, RequirementScope null-check, parse-check | FR-013 | (testing) | 0.5 | Implementer | tests/integration/multi-host-lifecycle-smoke.tests.ps1 | done | claude | 0.5 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | Project default. |
| Iteration Bounding | scope | 4 tasks bounded by Antigravity-empirical-findings scope. |
| Time Limit (hours) | n/a | |
| Overcommit Threshold | 1.0 | 5.5/20 = 0.275 — well under threshold. |
| Defer Strategy | manual | If T002 diff surfaces >3 SP of real fixes, surface for re-planning. |
| Calibration Enabled | true | Third live-tracked iteration. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- T001 + T002 + T003 all touch scaffolders/shims — serial execution.
- T004 (test capture) can run last; depends on T002/T003 outcomes.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.5 | This plan + reading Antigravity's session output to identify the 3 bugs. |
| Discovery/Spikes | 0.5 | Read C:/Temp/specrew-antigravity-stopwatch-test/.specify/.../scaffold-iteration-plan.ps1 to extract Antigravity's edits. |
| Implementation | 3.5 | T001 + T002 + T003. |
| Review | 0.5 | Parse-check + integration test pass on touched files. |
| Rework | 0.5 | Buffer if T002 surfaces a deeper bug class. |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Dispatch + scaffolder hardening | standard | Parse-check + unit tests + user re-run of Antigravity dogfood without any workarounds | n/a | User re-runs `specrew start --host antigravity` on a fresh project; if Antigravity doesn't have to patch anything, iter-006 verified. |

## Traceability Summary

- Task coverage: 4 tasks for 3 user-surfaced bugs + 1 test capture.
- Traceability check: PASS at plan-boundary.
- Overcommit guardrail: 5.5/20 = 27% capacity. Healthy.

## Notes

- **Empirical motivation**: Antigravity DID drive the Specrew lifecycle (specify → clarify → plan → tasks → iteration scaffold) on Gemini 3.5 Flash — that's a major methodology win. But it did so by patching `.specify/.../scaffold-iteration-plan.ps1` in the project, not by Specrew tooling working as designed. iter-006 closes that gap.
- **Stale install is recurring**: 0.24.1 → 0.25.0 → 0.26.0 dispatch failures have surfaced in EVERY multi-host test the user has run. T001 promotes this to a hard methodology check, not just a WARN.
- **User's test project preserved**: per the user's decision (option b), `C:\Temp\specrew-antigravity-stopwatch-test\.specify\.../scaffold-iteration-plan.ps1` is the canonical evidence for what Antigravity patched. T002 reads it.
