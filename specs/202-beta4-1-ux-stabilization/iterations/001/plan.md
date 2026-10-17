# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 25.5/20 story_points
**Started**: 2026-10-13
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

Iteration 001 is Tier 1: B4F-108, 104, 106, 096, 107, 100, 102, 105, 109, 089 and 101. Tier 2's FR-022 and FR-023 belong to iteration 002 and are excluded here.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | Concurrent journal appends succeed without torn lines (share mode first; lock only if case (e) requires) | US1 |
| FR-002 | Bounded retry as backup; only persistent failure degrades | US1 |
| FR-003 | Degraded state self-clears on next append; legacy marker treated the same | US1 |
| FR-004 | Per-process outage buffer of hashes, read before the next prompt decision, flushed then removed | US1 |
| FR-005 | Refuse authority only on a real hook-output match; buffer-write failure fails only that turn | US1 |
| FR-006 | Standard turn record via declared, tested host contract; three-valued origin; only typed-user mints | US1 |
| FR-007 | Degraded state disclosed same turn (consumed status), in status/where, and in orientation | US1 |
| FR-008 | Health journal of transitions, hashes only | US1 |
| FR-009 | One plain recovery decision; no implied loss; approving receipt recorded | US1 |
| FR-010 | Refusal names the actual cause; never an unused channel | US1 |
| FR-011 | Unchanged crossing presented once per session and after a context gap; otherwise a one-line mention | US2 |
| FR-012 | Stop never blocks over formatting; substance only | US2 |
| FR-013 | Deterministic lines system-filled, marked and journaled; 0 cycles | US2 |
| FR-014 | Orientation reaches the maintainer before the first question | US2 |
| FR-015 | Presented check over the declared meaning-line set, not the whole draft | US2 |
| FR-016 | One shared prose dials sentence on every host | US3 |
| FR-017 | start-context is the single pointer, records its branch, updated by every feature writer | US4 |
| FR-018 | Feature precedence: in-flight controller or crossing, pointer for this branch, branch as hint; always disclosed | US4 |
| FR-019 | Resume lines from disk; narrative only as aged context | US4 |
| FR-020 | Gate refusal names the producing step | US5 |
| FR-021 | Per-session ignored draft path resolved by the script; skills name it | US6 |
| FR-024 | Real payload fixtures (scratch only); cross-host tests through real adapters | US1, US2, US3 |
| FR-025 | Fault-injection cases a-e; (e) on three operating systems | US1 |
| FR-026 | New-feature cycle reset; all per-feature runtime state keyed to the new feature; audit entry kept | US4 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Capture real hook payloads in scratch dirs; measure session-id presence and direct-display of hook output per host | FR-024 | US1 | 1.5 | Implementer | tests/fixtures/hook-payloads/** | planned | | | |
| T002 | Standard turn record, host field maps, origin rules, transform registry; remove both old normalizers; twin-copy parity test | FR-006 | US1 | 2.5 | Implementer | hosts/*/host.psd1, scripts/internal/specrew-hook-dispatcher.ps1, extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1, scripts/internal/bootstrap/HostEventAdapter.ps1, tests/unit/** | planned | | | |
| T003 | Journal share mode, bounded retry, outage buffer, health journal, legacy marker migration | FR-001, FR-002, FR-003, FR-004, FR-005, FR-008 | US1 | 3.0 | Implementer | scripts/internal/specrew-hook-dispatcher.ps1, extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1, extensions/specrew-speckit/scripts/workshop-authority-store.ps1, tests/unit/** | planned | | | |
| T004 | B4F-108 disclosures, status/where health line, recovery question, selection-channel inference removed | FR-007, FR-009, FR-010 | US1 | 2.0 | Implementer | scripts/internal/bootstrap/HandoverStore.ps1, extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1, scripts/specrew-where.ps1, tests/bootstrap/** | planned | | | |
| T005 | Cross-host workshop acceptance and fault-injection suite (a-e; e on 3 OS) | FR-024, FR-025 | US1 | 2.5 | Implementer | tests/unit/**, tests/integration/**, .github/workflows/** | planned | | | |
| T006 | Presented-crossing memory with context-gap rules; one-line mention | FR-011 | US2 | 2.0 | Implementer | extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1, extensions/specrew-speckit/scripts/turn-end-store.ps1, tests/unit/** | planned | | | |
| T007 | Substance-only Stop; declared meaning-line set; system-filled deterministic lines | FR-012, FR-013, FR-015 | US2 | 2.0 | Implementer | extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1, extensions/specrew-speckit/scripts/turn-end-store.ps1, extensions/specrew-speckit/scripts/declare-turn-end.ps1, tests/unit/** | planned | | | |
| T008 | Orientation first via system output; no duplicates on direct-display hosts; session-scoped bootstrap check | FR-014 | US2 | 1.5 | Implementer | scripts/internal/specrew-bootstrap-provider.ps1, extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1, extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1, tests/bootstrap/** | planned | | | |
| T009 | One shared prose dials sentence; numeric renderer removed | FR-016 | US3 | 1.0 | Implementer | scripts/internal/user-profile.ps1, extensions/specrew-speckit/scripts/turn-end-store.ps1, tests/unit/** | planned | | | |
| T010 | Single feature resolver with precedence and disclosure; pointer branch; create-governed-feature writes pointer; status uses resolver | FR-017, FR-018 | US4 | 2.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, scripts/internal/sync-boundary-state.ps1, extensions/specrew-speckit/scripts/create-governed-feature.ps1, scripts/internal/dashboard-renderer.ps1, scripts/specrew-where.ps1, tests/unit/** | planned | | | |
| T011 | Shared cycle-reset function, feature_ref on new entries and crossings, coverage line per feature | FR-026 | US4 | 2.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, scripts/internal/sync-boundary-state.ps1, tests/unit/** | planned | | | |
| T012 | Resume from disk; narrative as aged, flagged context | FR-019 | US4 | 1.0 | Implementer | scripts/internal/bootstrap/HandoverStore.ps1, scripts/internal/specrew-bootstrap-provider.ps1, scripts/internal/coordinator-resume.ps1, tests/bootstrap/** | planned | | | |
| T013 | Design-analysis gate refusal names the producing step | FR-020 | US5 | 0.5 | Implementer | scripts/internal/design-analysis-gate.ps1, tests/unit/** | planned | | | |
| T014 | Draft intake on stdin with explicit UTF-8 (Hebrew test on 3 OS); per-session path; skills name it | FR-021 | US6 | 1.0 | Implementer | extensions/specrew-speckit/scripts/declare-turn-end.ps1, extensions/specrew-speckit/scripts/turn-end-store.ps1, extensions/specrew-speckit/squad-templates/skills/**, tests/unit/** | planned | | | |
| T015 | Acceptance evidence: friction table, validator vs baseline, live-walk script | FR-024 | US1 | 1.0 | Implementer | specs/202-beta4-1-ux-stabilization/iterations/001/** | planned | | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Tier 1 scope is fixed by the maintainer; overcommit is surfaced, not auto-deferred. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 25.5 planned exceeds 20 x 1.0; surfaced at the plan boundary. |
| Defer Strategy | manual | Any deferral is the maintainer's decision. |
| Calibration Enabled | true | Retro compares actuals to these estimates. |

## Concurrency Rationale

- **Roster:** Spec Steward, Planner, Implementer, Reviewer (codex), Retro Facilitator.
- **Conflict risk:** high. The conformance provider, dispatcher and turn-end store are shared by T002, T003, T004, T006, T007 and T008.
- **Recommendation:** run serially in dependency order. T001 comes first, because T002, T005, T008 and T014 depend on its measurements. Then T002, then T003 and T004, then T006, T007 and T008. T009 to T014 can follow in any order, and T005 and T015 come last. No same-specialty parallel pair is proposed.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Workshop, spec, clarify, design-analysis co-design complete |
| Discovery/Spikes | 1.5 | T001 payload capture and host measurements |
| Implementation | 23.0 | T002-T014 |
| Review | allowance | Governed by the codex round allowance, not SP (199 retro ruling) |
| Rework | from slack | No SP buffer is planned; the overcommit is surfaced instead |

## Traceability Summary

- **Requirement scope:** FR-001 to FR-021 and FR-024 to FR-026. FR-022 and FR-023 are in iteration 002.
- **User stories represented:** US1 to US6. US7 is in iteration 002.
- Every task traces to an FR and a story. Every FR in scope has at least one task.

## Notes

- **Capacity:** 25.5 planned against 20, an overcommit of 5.5 SP, recorded by the maintainer's plan verdict (2026-10-13). All of Tier 1 stays in iteration 001. T012 stays because B4F-089 depends on the pointer work (T010).
- **Plan verdict rulings (2026-10-13):** the quality-profile override is agreed (concurrency, resiliency and retry required). T013 is widened by DRIFT-002 at 0.5 SP. T005's workflow change is a recorded exception to the devops-operations skip (DRIFT-003): kept minimal, with its workflow diff reviewed like code.
- **Review:** effort is not priced in SP. Codex reviews within its round allowance.
- **Design:** see design-analysis.md (Co-Design Record) and the feature plan.md work breakdown W1 to W15, which maps to T001 to T015 one-for-one.
