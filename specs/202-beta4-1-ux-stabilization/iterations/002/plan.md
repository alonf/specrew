# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 20.25/20 story_points
**Started**: 2026-10-17
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

Iteration 002 is "one human act, one record" (spec US8, FR-027 to FR-034), scoped by the maintainer on 2026-10-17
("scope as recommended") and designed with the maintainer in `design-analysis.md` (DA-1 to DA-5). B4F-127 and B4F-129
are the release gate for beta4.1. FR-022 and FR-023 moved to beta5 (spec amendment, DRIFT-001).

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-027 | One human message, at most one recorded approval of each kind, keyed by the host's message identity (B4F-127, DA-2) | US8 |
| FR-028 | A hook stands down only on a positive match with another host; unknown shapes handled and logged once; receipt IDs unique (B4F-129, DA-1) | US8 |
| FR-029 | Approval form: paired paste tags, quoted menus refused, reset authorizes its round, no command offered (B4F-125, DA-3) | US8 |
| FR-030 | A reworded discussion question counts when its meaning matches (B4F-128) | US8 |
| FR-031 | Wide delegation forms, loud narrow case, reviewer choice at agenda confirmation (B4F-130, DA-4) | US8 |
| FR-032 | No host instruction permits a question tool for workshop questions (B4F-131) | US8 |
| FR-033 | Receipt outcome on the session's own turn record; shared journal retired and deleted on update (candidate 3, DA-5) | US8 |
| FR-034 | No unread draft copy (candidate 7) | US8 |

## Tasks

Order: the two release-gate items first, then the receipt simplification before the receipt-touching items. Review
rounds sit after the tasks that touch approval handling (after T017 and T016, and after T018 and T019). Every task lands
red first, through the shipped entry point, with recorded payloads.

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T017 | Message identity: `prompt_id` and `turn_id` in the host field maps and the turn record; identity hash without the source event; turn-end transcript path reads `prompt_id` from typed entries, skips injected ones, handles the compaction summary; spent-from-same-message is final; Copilot turn-end records no approvals and reports an unrecorded approval-shaped message; per-host replay test (SC-010) | FR-027 | US8 | 4.5 | Implementer | `scripts/internal/bootstrap/HandoverStore.ps1`, `scripts/internal/bootstrap/HumanAuthorityStore.ps1`, `hosts/*/host.psd1`, dispatcher twins | done | | | |
| T016 | Host binding: declared host fields per binding and event; positive-match stand-down in the shared path; unknown shape handled and logged once; receipt store refuses a duplicate ID; fixture matrix over every recorded payload | FR-028 | US8 | 3.0 | Implementer | `hosts/*/host.psd1`, dispatcher twins, `extensions/specrew-speckit/scripts/workshop-authority-store.ps1` | done | | | |
| T022 | Retire the receipt-outcomes journal: outcome on the session's turn record, both readers switched, writer removed, `specrew update` deletes the file, R5-5 two-session test | FR-033 | US8 | 2.25 | Implementer | `workshop-authority-store.ps1`, dispatcher twins, `specrew-conformance-provider.ps1`, `specrew-update.ps1` | done | | | |
| T018 | Approval form: paired paste-tag parsing, quoted-menu refusal, refusal reasons, the coverage-deferral copy, reset authorizes its round, no command offered; tests from `b4f-125-live-messages.json` and the observed paste-size boundary | FR-029 | US8 | 3.0 | Implementer | `HumanAuthorityStore.ps1`, `shared-governance.ps1` | done | | | |
| T019 | Discussion question meaning match, failing test from B4F-128's two exact lines | FR-030 | US8 | 0.5 | Implementer | `turn-end-store.ps1` | done | | | |
| T020 | Wide delegation forms, loud narrow line, reviewer choice at agenda confirmation, mixed-receipt lens close | FR-031 | US8 | 2.0 | Implementer | `workshop-authority-store.ps1`, `confirm-workshop-lens.ps1`, workshop skill | done | | | |
| T021 | Find and fix the instruction that permits Copilot's question box; text test across every shipped host instruction | FR-032 | US8 | 1.0 | Implementer | `extensions/specrew-speckit/squad-templates/**`, host instruction files | done | | | |
| T023 | Remove the `turn-message.md` writer and its mentions | FR-034 | US8 | 0.25 | Implementer | `declare-turn-end.ps1`, `turn-end-store.ps1`, skills | done | | | |
| T024 | Acceptance: evidence file, validator run, Copilot re-walk script for the maintainer (SC-011) | SC-010, SC-011 | US8 | 0.5 | Implementer | `iterations/002/` | done | | | |
| T025 | Committed payload probe on Copilot, Claude and Codex, with sub-agents; the deployed-hook test harness; the captured payloads as fixtures (B4F-145 layer 1) | FR-028 | US8 | 1.0 | Implementer | `tests/host-probes/**`, `tests/fixtures/hook-payloads/probe/**` | done | | | |
| T026 | Copilot's second payload shape: failing test on the probe payloads first, signature alternatives in the dispatcher and deployer, Copilot's rule for Claude's hooks, Claude's rules refuse `timestamp` (B4F-144) | FR-028 | US8 | 0.75 | Implementer | `hosts/*/host.psd1`, dispatcher and deployer twins, `tests/unit/host-binding-match.tests.ps1` | done | | | |
| T027 | A reader for the unrecognized-payload record: the binding suite, the probe and the re-walk each fail on any record | FR-028 | US8 | 0.25 | Implementer | `tests/unit/host-binding-match.tests.ps1`, `tests/host-probes/**`, `iterations/002/copilot-rewalk.md` | done | | | |
| T028 | A payload carrying a sub-agent field is never typed by the human and never records an approval, on every channel (B4F-147) | FR-027, FR-028 | US8 | 0.5 | Implementer | `hosts/*/host.psd1`, dispatcher twins, `tests/unit/subagent-prompt-authority.tests.ps1` | done | | | |
| T029 | Product-domain and grounding questions are workshop questions in prose on every host; the text test reaches every shipped instruction (B4F-131, T021's rule) | FR-032 | US8 | 0.5 | Implementer | host bindings, launch and coordinator guidance, templates, `tests/unit/workshop-question-tool.tests.ps1` | done | | | |
| T030 | Acceptance: evidence, and the re-walk with a capture hook (SC-011) | SC-011 | US8 | 0.25 | Implementer | `iterations/002/`, `tests/host-probes/walk-capture-hook.ps1` | in-progress | | | |

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

- Roster: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Dependencies: T017 before T016 (both change the turn record and the dispatcher twins); T022 before T020 and T021
  (receipt area); T018 after T017 (the approval writers); T019 and T023 are independent; T024 last.
- Shared-surface risk is high: T016, T017 and T022 all touch the dispatcher twins, and T017, T018 and T022 the
  authority and receipt stores. The work stays serial, one implementer.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Scope ruling and DA-1 to DA-5, 2026-10-17 |
| Discovery/Spikes | 0 | The code map is in `design-analysis.md`; paste tagging settled from transcripts |
| Implementation | 16.5 | T016 to T023 |
| Review | rounds, not SP | Governed by the codex round allowance (199 retro ruling); rounds after T016/T017 and after T018/T019 |
| Rework | inside the round allowance | Iteration 001's review loop was the cost driver; the retro's lessons apply |
| Acceptance | 0.5 | T024 |

## Traceability Summary

- Requirement scope: FR-027 to FR-034 (US8); SC-010 and SC-011. FR-022 and FR-023 moved to beta5 (DRIFT-001).
- Every task maps to one requirement, and every requirement has a task.

## Notes

- **Size: 17 SP against the 15.25 SP the maintainer accepted at the scope ruling.** The 1.75 SP of growth comes from the
  design decisions and the release-gate proof: DA-2's two conditions (+0.5 on T017), DA-4's reviewer choice and loud
  narrow case (+0.5 on T020), DA-5's deletion on update (+0.25 on T022), and the Copilot re-walk for SC-011 (+0.5, T024).
  It is within the 20 SP convention, above the maintainer's 15 SP line, and decided at the plan stop.
- Task IDs continue from iteration 001 (T001 to T015).
- Out of iteration 002: B4F-055 and B4F-121 (beta5, review engine); B4F-132 to B4F-136 (queue after iteration 002).
- **T025 to T030 (3.25 SP) were added on 2026-10-21**, when the maintainer approved the fix plan for the failed SC-011
  re-walk (`go with the fix plan`, DRIFT-006), with three additions: B4F-131's product-domain question (T029), the
  closeout sync's early write logged as B4F-146, and sub-agent payloads (T028, B4F-147). The total, 20.25 SP, is 0.25
  over the 20 SP convention.
- The release gate: beta4.1 does not ship until B4F-127 (T017) and B4F-129 (T016) are fixed.
