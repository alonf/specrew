# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 28.5/20 story_points
**Started**: 2026-10-31
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 001 is the authority core: US1 (review budget), US2 (capture), US3 (same-turn reports) and FR-046
(moved here at the clarify verdict). US4 to US7 belong to iteration 002.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | The plan states a review budget (rounds, host order) | US1 |
| FR-002 | A budget above the ceiling is refused at plan and at snapshot, naming the ceiling and where it is set | US1 |
| FR-003 | The before-implement verdict snapshots the budget into the single grant; the plan is never read live | US1 |
| FR-004 | One counter, rounds_used vs budget_total; reservation before invocation | US1 |
| FR-005 | Within budget: clean ends the review; fix-needed fixes and runs the next round, no stop | US1 |
| FR-006 | Human stops only for (a) to (d); never for a round; never outside implement | US1 |
| FR-007 | The top-up records the reset fact, grants another window and starts the next round; hook-minted, human reason | US1 |
| FR-008 | A plan without a budget gets zero rounds | US1 |
| FR-009 | Infrastructure failures spend no round; N in a row move to the next host; exhausted order is stop (d) | US1 |
| FR-010 | The per-round approval, the one-slot grant and `--approve-round` are removed | US1 |
| FR-011 | Review stop layout and phrases | US1 |
| FR-014 | One mint origin; other paths only recover | US2 |
| FR-015 | The four conditions on every path, including the hook | US2 |
| FR-016 | Per-host turn identity, explicit substitute where needed | US2 |
| FR-017 | Per-host pasted-content handling | US2 |
| FR-018 | One classifier, one act per typed turn | US2 |
| FR-019 | Verdict pairing against the pending-crossing record across a compaction | US2 |
| FR-020 | A verdict naming another boundary is reported and records nothing | US2 |
| FR-021 | Supersession of an older unspent act | US2 |
| FR-022 | Writers re-derive the act from the cited turn | US2 |
| FR-023 | Records keep ids and hashes | US2 |
| FR-024 | Audit trail and record-to-turn join | US2 |
| FR-025 | No script or `!` approval path | US2 |
| FR-026 | Every no-record branch reports in the same turn | US3 |
| FR-027 | Visible line, or a justified stop where the host has none | US3 |
| FR-041 | Turn identity and campaign id on records (iteration 001 part) | US2 |
| FR-042 | Mint-path and non-approval phrase fixtures; cross-host replay | US2 |
| FR-043 | Budget economics fixtures, RED-first | US1 |
| FR-045 | Claude-only capture check at the iteration end | US2 |
| FR-046 | The Stop check verifies the reply's decision parts | US4 (part) |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Host facts in scratch dirs: both Copilot firings for one prompt (one identity), Copilot and Codex paste, Claude systemMessage visibility, Claude compaction fixture | FR-016, FR-017, FR-027 | US2 | 2.0 | Implementer | tests/fixtures/hook-payloads/**, tests/unit/** | planned | | | |
| T002 | Live engine pin: resolution yields to SPECREW_MODULE_PATH; pin script; launcher wiring; twin parity; deployed alone after its own review | FR-014 | US2 | 2.0 | Implementer | extensions/specrew-speckit/scripts/specrew-*-provider.ps1, extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1, scripts/internal/specrew-hook-dispatcher.ps1, scripts/internal/live-engine-pin.ps1, tests/unit/** | planned | | | |
| T003 | Resolve-SpecrewTypedAct: act DTO, identity per binding, standalone rule, pending-state routing | FR-014, FR-015, FR-018, FR-020, FR-023 | US2 | 4.0 | Implementer | scripts/internal/bootstrap/HumanAuthorityStore.ps1, hosts/*/host.psd1, tests/unit/** | planned | | | |
| T004 | Write-SpecrewTypedAct with re-derivation; rewire router, turn-end recovery, backstop, CLIs; remove per-path rules and --approve-round; supersession | FR-010, FR-021, FR-022, FR-025 | US2 | 4.0 | Implementer | scripts/internal/bootstrap/*.ps1, scripts/internal/continuous-co-review/review-authority-core.ps1, tests/unit/** | planned | | | |
| T005 | Verdict pairing against the pending-crossing record; boundary mismatch reported | FR-019, FR-020 | US2 | 1.5 | Implementer | scripts/internal/bootstrap/HandoverStore.ps1, scripts/internal/bootstrap/ConversationCaptureAccessor.ps1, tests/unit/** | planned | | | |
| T006 | Not-recorded reporter: per-branch reasons incl. stage evidence absent; visible line or justified stop | FR-026, FR-027 | US3 | 2.0 | Implementer | scripts/internal/bootstrap/HumanAuthorityStore.ps1, scripts/internal/bootstrap/HandoverStore.ps1, tests/unit/** | planned | | | |
| T007 | Budget declaration and snapshot; ceiling validation at plan sync and snapshot; zero-rounds default | FR-001, FR-002, FR-003, FR-008 | US1 | 2.5 | Implementer | scripts/internal/sync-boundary-state.ps1, scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1, tests/unit/** | planned | | | |
| T008 | Orchestrator loop: single grant, reservation before invocation, top-up, infra cap, pause facts, navigator, stop layout and phrases | FR-004, FR-005, FR-006, FR-007, FR-009, FR-011 | US1 | 5.0 | Implementer | scripts/internal/continuous-co-review/*.ps1, tests/unit/** | planned | | | |
| T011 | Stop check verifies the reply's decision parts; word-for-word comparison removed | FR-046 | US4 | 1.5 | Implementer | extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1, extensions/specrew-speckit/scripts/turn-end-store.ps1, tests/unit/** | planned | | | |
| T012 | Audit and correlation: record-to-turn join, citations, turn identity and campaign id | FR-024, FR-041 | US2 | 1.5 | Implementer | scripts/internal/bootstrap/*.ps1, scripts/internal/continuous-co-review/review-authority-store.ps1, tests/unit/** | planned | | | |
| T013 | Test evidence suite: mint-path and non-approval phrase fixtures, cross-host replay incl. compaction, economics fixtures | FR-042, FR-043 | US2 | 1.5 | Implementer | tests/unit/**, tests/integration/** | planned | | | |
| T014 | Deployment point and the Claude-only capture check | FR-045 | US2 | 1.0 | Implementer | specs/203-beta5-stabilization/iterations/001/**, .specify/extensions/specrew-speckit/** | planned | | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | The maintainer fixed iteration 001's scope; overcommit is surfaced, not auto-deferred. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 28.5 planned exceeds 20 x 1.0; surfaced at the plan boundary and accepted by the plan verdict. |
| Defer Strategy | manual | Any deferral is the maintainer's decision. |
| Calibration Enabled | true | Retro compares actuals to these estimates. |

## Concurrency Rationale

- **Roster:** Spec Steward, Planner, Implementer, Reviewer (codex, then copilot, then claude), Retro Facilitator.
- **Conflict risk:** high. HumanAuthorityStore, HandoverStore and the orchestrator are shared by T003 to T008 and
  T012.
- **Recommendation:** serial in dependency order. T002 first and deployed alone (the pin), then T001 (its facts
  feed T003 and T006), then T003, T004, T005, T006, then T007, T008, then T011 and T012, T013 last
  before review, and T014 after the review sign-off.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Workshop, spec, clarify, design-analysis co-design complete |
| Discovery/Spikes | 2.0 | T001 host facts |
| Implementation | 25.5 | T002 to T008, T011 to T013 |
| Review | budget | Today's engine: per-round approvals, cap 4 per allowance (plan, Review budget) |
| Rework | from slack | No SP buffer; the overcommit is surfaced instead |

## Traceability Summary

- **Requirement scope:** FR-001 to FR-011, FR-014 to FR-027, FR-041 (part), FR-042, FR-043, FR-045, FR-046. FR-012 and FR-013 (T010, T009) moved to iteration 002 by the plan verdict.
- **User stories represented:** US1, US2, US3, and US4 for FR-046 only. US5 to US7 and the rest of US4 are in
  iteration 002.
- Every task traces to an FR and a story. Every FR in scope has at least one task.

## Notes

- **Capacity:** 28.5 planned against 20, an overcommit of 8.5 SP, accepted by the plan verdict (2026-10-31).
- **Plan verdict ruling (2026-10-31):** T009 (scoped rounds, FR-013) and T010 (token usage, FR-012) move to
  iteration 002. Both act only once the budget model is live, and iteration 001's own review runs on per-round
  approvals, so a smaller iteration 001 means fewer of them. They keep their feature-global IDs.
- **Live hooks:** see the feature plan's section on when 203's changes reach the live hooks. T002 is deployed
  alone after its own review; everything else reaches the live hooks at T014.
- **Design:** see design-analysis.md (Co-Design Record) and the feature plan.md work breakdown W0 to W13, which
  maps to T001 to T014 (W1 is T002, W0 is T001; the rest in order).
