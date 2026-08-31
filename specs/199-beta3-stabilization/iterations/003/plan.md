# Iteration Plan: 003 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 0/20 story_points
**Started**: 2026-08-31
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
| FR-001 | After every campaign round's ingest that leaves a DECISION TO MAKE, the | — |
| FR-002 | The decision surface MUST show findings grouped by severity with | — |
| FR-003 | Continuation MUST always be an explicit human choice consuming a | — |
| FR-004 | Minor findings MUST never gate sign-off; they are auto-carried as | — |
| FR-005 | The stop-here option MUST compose the full landing as one action: | — |
| FR-007 | The campaign stop surface MUST consult the signoff-gate decision store | — |
| FR-008 | An authorized in-flight review run MUST suppress the stop-block; a | — |
| FR-009 | Commits touching only governance/records files MUST NOT stale a reviewed | — |
| FR-010 | A leading recognized approval phrase MUST win over any instruction | — |
| FR-011 | The review engine's integrity check MUST discriminate reparse tags: | — |
| FR-012 | `specrew init` MUST scaffold a strict starter verification-plan.json | — |
| FR-013 | Verification failures MUST name the missing piece (env_refs, plan | — |
| FR-014 | Only rounds that actually invoked a reviewer consume the round | — |
| FR-015 | Every human-visible sentence MUST be about the user's project and the | — |
| FR-016 | Human-visible prose MUST render task/requirement/finding IDs through the | — |
| FR-017 | Decision stops MUST render context packet and decision surface as ONE | — |
| FR-018 | The codex-class default review window MUST be 900 seconds | — |
| FR-019 | The orientation banner and every version render MUST show the full | — |
| FR-020 | The flagged 009/010 registry-vs-claim wording inconsistency is resolved | — |
| FR-021 | The release follows the beta2 discipline: certification review before | — |
| FR-022 | The markdownlint-cli CI install lands as release hygiene (198-carried | — |
| FR-023 | Every fix lands RED-first with an instance-pinned fixture through the | — |
| FR-024 | A boundary crossing is not minted until the stage it leaves has its owed | — |
| FR-025 | `pushed-head` is a delivery check scoped to iteration-closeout and | — |
| FR-026 | The constrained YAML readers for `product-domain.yml` and | — |
| FR-027 | A governed lens-checkpoint writer closes a lens: it consumes the typed-turn | — |
| FR-028 | When a lens reply is received without closing the lens, the next message opens | — |
| FR-029 | Feature creation replaces the scaffolded `spec.md` with a stub that carries a | — |
| FR-030 | The crossing writer writes every enumerated COPY of `last_authorized_boundary` - | — |
| FR-031 | The closeout sync writes the iteration seal after every record it produces, | — |
| FR-032 | A pending crossing is owed by the actor that recorded its arrival. The Stop-hook | — |
| FR-033 | Method, binding on every fix in the batch: a mutation that turns its own case | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |

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
- Technology and scope signals: Mixed frontend and backend/service signals are present in the scoped requirements.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Current scope does not yet prove enough safe parallelism for same-specialty expansion; default to a smaller serial team until tasks are clearer.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: Latest reviewer hotspots: .specify/extensions/specrew-speckit/.specrew-extension-runtime.json (659 changed lines); .specify/extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1 (257 changed lines); .specify/extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1 (286 changed lines); .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 (1510 changed lines); .specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 (727 changed lines); .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 (625 changed lines); .specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1 (533 changed lines); .specrew/release-gate-suites.txt (354 changed lines); extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1 (257 changed lines); extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1 (286 changed lines); extensions/specrew-speckit/scripts/shared-governance.ps1 (1510 changed lines); extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 (727 changed lines); extensions/specrew-speckit/scripts/validate-governance.ps1 (625 changed lines); extensions/specrew-speckit/scripts/workshop-authority-store.ps1 (533 changed lines); scripts/internal/bootstrap/ConversationCaptureAccessor.ps1 (278 changed lines); scripts/internal/bootstrap/HumanAuthorityStore.ps1 (1825 changed lines); scripts/internal/continuous-co-review/.specrew-runtime.json (252 changed lines); scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1 (472 changed lines); scripts/internal/continuous-co-review/review-authority-core.ps1 (501 changed lines); scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1 (971 changed lines); scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1 (685 changed lines); scripts/internal/module-packaging.ps1 (356 changed lines); scripts/internal/sync-boundary-state.ps1 (285 changed lines); scripts/specrew-review.ps1 (1089 changed lines); specs/199-beta3-stabilization/iterations/001/design-analysis.md (1113 changed lines); specs/199-beta3-stabilization/iterations/001/drift-log.md (8196 changed lines); tests/continuous-co-review/unit/advisory-names-the-humans-act.Tests.ps1 (359 changed lines); tests/continuous-co-review/unit/campaign-pause-core.Tests.ps1 (505 changed lines); tests/continuous-co-review/unit/campaign-pause-wiring.Tests.ps1 (838 changed lines); tests/continuous-co-review/unit/campaign-stop-authority.Tests.ps1 (440 changed lines); tests/continuous-co-review/unit/consumer-language.Tests.ps1 (385 changed lines); tests/continuous-co-review/unit/reparse-tag-policy.Tests.ps1 (394 changed lines); tests/continuous-co-review/unit/review-derived-independence.Tests.ps1 (417 changed lines); tests/continuous-co-review/unit/review-frame-and-evidence-honesty.Tests.ps1 (569 changed lines); tests/continuous-co-review/unit/review-spend-allowance.Tests.ps1 (313 changed lines); tests/integration/no-code-without-approval.tests.ps1 (257 changed lines); tests/integration/review-record-survives-its-own-commit.tests.ps1 (307 changed lines); tests/integration/workshop-agenda-confirmation.tests.ps1 (313 changed lines); tests/unit/round-approval-typed-authority.tests.ps1 (2578 changed lines)
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | TBD | Populate after task decomposition and approval gating |
| Discovery/Spikes | TBD | Capture any required risk-reduction work revealed during planning |
| Implementation | TBD | Sum planned delivery tasks once the task table is complete |
| Review | TBD | Estimate review/demo effort after verdict flow is defined |
| Rework | TBD | Expected needs-work buffer if review finds gaps |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021, FR-022, FR-023, FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030, FR-031, FR-032, FR-033
- User stories represented in current scope: 
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.