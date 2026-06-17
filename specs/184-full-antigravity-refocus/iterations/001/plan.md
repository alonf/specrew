# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 26/26 story_points
**Started**: 2026-06-17
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
| FR-001 | Normalize real Antigravity `conversationId` into session identity; never global `unknown`. | US1 |
| FR-002 | Use existing `SessionStateAccessor` and refocus-state model for Antigravity state/anchor. | US1, US2 |
| FR-003 | Map B3 boundary refocus to Antigravity `PreInvocation` `injectSteps`. | US2 |
| FR-004 | Distinguish Antigravity's own active marker from a real competing session. | US3 |
| FR-005 | Preserve F-183 bootstrap, Stop handover, resume, and real conversation-id behavior. | US1, US4 |
| FR-006 | Fail open with bounded diagnostics and no prompt/transcript leakage. | US2, US3, US4 |
| FR-007 | Preserve user-owned `.agents/hooks.json` entries on deploy/remove. | US5 |
| FR-008 | Bring Antigravity docs to host-level content depth with permission/recovery guidance. | US5 |
| FR-009 | Gate full/verified/stable status claims on real-host `agy` evidence. | US5 |
| FR-010 | Reuse existing refocus machinery and enforce falsifiable split-guard triggers. | US2 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Discovery spike: B3-on-PreInvocation split-guard proof | FR-003, FR-010, SC-009, TG-004, TG-005 | US2 | 3 | Planner, Reviewer | scripts/internal/bootstrap/**; scripts/internal/specrew-hook-dispatcher.ps1; extensions/specrew-speckit/scripts/**; hosts/antigravity/**; specs/184-full-antigravity-refocus/** | done | codex | 3 | pass |
| T002 | Antigravity session identity and per-session refocus state/anchor | FR-001, FR-002, FR-005, SC-001, SC-002 | US1, US4 | 4 | Implementer | scripts/internal/bootstrap/**; scripts/internal/specrew-hook-dispatcher.ps1; extensions/specrew-speckit/scripts/**; tests/bootstrap/**; tests/integration/refocus-dispatcher.tests.ps1 | done | codex | 4 | pass |
| T003 | B3 `PreInvocation` injection with dedupe/breaker and fail-open diagnostics | FR-003, FR-006, FR-010, SC-003, SC-007, SC-009 | US2 | 5 | Implementer | scripts/internal/bootstrap/**; scripts/internal/specrew-hook-dispatcher.ps1; extensions/specrew-speckit/scripts/**; tests/bootstrap/**; tests/integration/refocus-dispatcher.tests.ps1 | done | codex | 5 | pass |
| T004 | Antigravity self-marker concurrency classifier | FR-004, FR-006, SC-004 | US3 | 3 | Implementer | scripts/internal/bootstrap/**; tests/bootstrap/ClassificationEngine.Tests.ps1; tests/bootstrap/SessionBootstrapManager.Tests.ps1 | done | codex | 3 | pass |
| T005 | Hook config preservation and F-183 Antigravity regression guards | FR-005, FR-007, SC-005, SC-006 | US4, US5 | 3 | Implementer, Reviewer | hosts/antigravity/**; scripts/internal/deploy-refocus-hooks.ps1; extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1; tests/integration/refocus-deploy.tests.ps1; tests/integration/specrew-hooks-command.tests.ps1 | planned | codex | — | — |
| T006 | Antigravity documentation, permission, recovery, and evidence-gated status wording | FR-008, FR-009, TG-006, SC-008, SC-010 | US5 | 2 | Spec Steward, Reviewer | README.md; docs/**; specs/184-full-antigravity-refocus/** | planned | codex | — | — |
| T007 | Automated validation, mirror parity, and FileList/release readiness | TG-001, TG-002, TG-003, SC-001, SC-004, SC-006, SC-007, SC-008, SC-010 | US1-US5 | 3 | Reviewer | tests/**; extensions/specrew-speckit/**; .specify/extensions/specrew-speckit/**; Specrew.psd1; specs/184-full-antigravity-refocus/** | planned | codex | — | — |
| T008 | Real-host `agy` validation and Proposal 145 review evidence | FR-009, TG-004, TG-005, TG-006, SC-002, SC-003, SC-005, SC-009, SC-010 | US1-US5 | 3 | Reviewer | specs/184-full-antigravity-refocus/iterations/001/** | planned | codex | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 26 | Temporary F-184 override from the baseline 20 SP cap, authorized by the user's 2026-06-17 completeness instruction. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 26 story_points (capacity 26 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: PowerShell runtime/governance code, JSON/YAML host manifests, Markdown docs, and Pester tests dominate.
- Task dependency graph: T001 gates T002-T005 because it can trigger split/defer; T002 precedes T003 because B3 state keys depend on session identity; T004 can start after T002 state identity is stable; T006 can run after T001 but status wording remains evidence-gated until T008.
- Workstream separability: Docs can run in parallel with implementation after T001, but runtime tasks share dispatcher/state/test surfaces and should remain serial.
- Shared-surface conflict risk: elevated around `scripts/internal/bootstrap/**`, `scripts/internal/specrew-hook-dispatcher.ps1`, mirrored extension scripts, and `tests/bootstrap/**`.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 3 | Specify/clarify carry, design-analysis, plan, Wave B artifacts, and over-cap recording |
| Discovery/Spikes | 3 | T001 falsifiable B3 split-guard spike |
| Implementation | 14 | T002-T006 runtime, hook config, tests, and docs |
| Review | 4 | T007-T008 automated validation, real-host evidence, and Proposal 145 review |
| Rework | 2 | Expected repair buffer during review/fix/rerun loop |

## Traceability Summary

- Requirement scope: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, TG-001, TG-002, TG-003, TG-004, TG-005, TG-006.
- User stories represented in current scope: US1, US2, US3, US4, US5.
- Requirement coverage: every FR has at least one task; every SC has at least one task through T001-T008.
- Task traceability: every task maps to at least one FR, SC, or TG.
- Capacity check: 26/26 story_points, using a temporary F-184 override from the baseline 20 SP cap authorized by the user's 2026-06-17 completeness instruction.
- Overcommit guardrail: no deferral selected because the override binds this iteration only. If T001 fails any split-guard trigger, stop for a human split/defer verdict despite the broad implementation authorization.

## After-Tasks Traceability Check

**Verdict**: PASS. The task table is also rendered for the Speckit task surface
at file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/tasks.md.

| Check | Result |
| --- | --- |
| Every task maps to at least one FR, SC, or TG | PASS |
| Every FR-001 through FR-010 has at least one task | PASS |
| Every SC-001 through SC-010 has at least one task | PASS |
| Every TG-001 through TG-006 has at least one task | PASS |
| Tasks include owner, effort, story, and verification metadata | PASS |
| Invalid or stale requirement references | None |
| Orphan tasks | None |
| Uncovered requirements | None |

Traceability matrix: FR-001 -> T002; FR-002 -> T002; FR-003 -> T001/T003;
FR-004 -> T004; FR-005 -> T002/T005; FR-006 -> T003/T004; FR-007 -> T005;
FR-008 -> T006; FR-009 -> T006/T008; FR-010 -> T001/T003; SC-001 -> T002/T007;
SC-002 -> T002/T008; SC-003 -> T003/T008; SC-004 -> T004/T007; SC-005 -> T005/T008;
SC-006 -> T005/T007; SC-007 -> T003/T007; SC-008 -> T006/T007;
SC-009 -> T001/T003/T008; SC-010 -> T006/T007/T008; TG-001/TG-002/TG-003 -> T007;
TG-004/TG-005 -> T001/T008; TG-006 -> T006/T008.

## Notes

- Design-analysis decision: Option B, complete bounded Antigravity refocus in one temporarily expanded 26 SP iteration.
- Wave B artifacts: file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/data-model.md, file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/quickstart.md, file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/contracts/full-antigravity-refocus.md, file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/review-diagrams.md
- User instruction: proceed through implementation and stop for the next human gate after complete implementation. Boundary commits and syncs still occur; Proposal 145-style review/fix/rerun applies at every stop.
- T001 is a hard split-guard task, not optional research. A FAIL row blocks runtime work.
- T001 discovery recorded PASS rows for `fresh-boundary-cursor`,
  `exactly-once-b3`, and `bounded-host-model` at
  file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/iterations/001/discovery-antigravity-b3-preinvocation.md.
- T002 completed with automated evidence that Antigravity `conversationId` keys
  `.specrew/runtime/refocus-state-<session>.json`, anchors on first
  `PreInvocation`, remains silent when the boundary cursor is unchanged, and
  never creates `refocus-state-unknown.json` when a real conversation id exists.
- T003 completed with automated evidence that Antigravity B3 injects through
  `PreInvocation` `injectSteps` on real boundary crossings, dedupes channel-1
  fingerprints, never emits `injectSteps` from `PostToolUse`, and fails open
  with bounded diagnostics that do not echo prompt text.
- T004 completed with automated evidence that a marker owned by the current
  Antigravity conversation is classified as `same-session` with no advisory,
  while a different fresh same-worktree marker still emits the existing
  concurrency advisory.
- Retro and iteration-closeout must restore `.specrew/iteration-config.yml` to the baseline 20 SP cap after F-184 closes.
- Status is `executing` after tasks and before-implement readiness were committed
  and lifecycle state was synchronized.
