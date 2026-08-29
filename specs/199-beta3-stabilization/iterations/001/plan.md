# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 13.1/20 story_points
**Started**: 2026-08-10
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
| FR-001 | After every campaign round's ingest, the engine MUST render the decision | — |
| FR-002 | The decision surface MUST show findings grouped by severity with | — |
| FR-003 | Continuation MUST always be an explicit human choice consuming a | — |
| FR-004 | Minor findings MUST never gate sign-off; they are auto-carried as | — |
| FR-005 | The stop-here option MUST compose the full landing as one action: | — |
| FR-006 | The reviewer prompt contract changes from a findings-goal to a verdict-goal (added manually: the scaffold's FR extractor skipped this ID — its `(durable):` annotation broke the pattern) | — |
| FR-007 | The campaign stop surface MUST consult the signoff-gate decision store | — |
| FR-008 | An authorized in-flight review run MUST suppress the stop-block; a | — |
| FR-009 | Commits touching only governance/records files MUST NOT stale a reviewed | — |
| FR-010 | A leading recognized approval phrase MUST win over any instruction | — |
| FR-011 | The review engine's integrity check MUST discriminate reparse tags: | — |
| FR-012 | `specrew init` MUST scaffold a strict starter verification-plan.json plus a non-executable templates sidecar | — |
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

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Pause core (round terminal + pause facts + decision surface + per-campaign budget) | FR-001, FR-002, FR-003, FR-004 | US1 | 3.0 | Implementer | scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1, review-authority-core.ps1, review-authority-store.ps1, continuous-co-review-navigator.ps1, tests/continuous-co-review/** | done | | | |
| T002 | Composed stop-here landing | FR-005 | US1 | 1.0 | Implementer | scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1, tests/continuous-co-review/** | done | | | |
| T003 | Single-authority stop surface | FR-007, FR-008, FR-009 | US2 | 1.0 | Implementer | scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1, tests/continuous-co-review/** | done | | | |
| T004 | Verdict capture contract + wiring reconciliation | FR-010 | US3 | 1.5 | Implementer | scripts/internal/bootstrap/ConversationCaptureAccessor.ps1, scripts/internal/deploy-refocus-hooks.ps1, tests/bootstrap/**, tests/integration/** | done | | | |
| T005 | Verdict-goal reviewer prompt contract | FR-006 | US1 | 0.5 | Implementer | scripts/internal/continuous-co-review/worktree-reviewer.ps1, tests/continuous-co-review/** | done | | | |
| T006 | Reparse-tag discrimination + refusal messages + docs | FR-011 | US4 | 1.75 | Implementer | scripts/internal/continuous-co-review/review-authority-store.ps1, docs/**, tests/continuous-co-review/** | done | | | |
| T007 | Init verification-plan bootstrap + named errors | FR-012, FR-013 | US5 | 1.0 | Implementer | scripts/internal/continuous-co-review/verification-plan-*.ps1, scripts/specrew-init.ps1, tests/integration/** | done | | | |
| T008 | Reviewer-invoked-only spend accounting | FR-014 | US1 | 0.5 | Implementer | scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1, review-authority-core.ps1, tests/continuous-co-review/** | done | | | |
| T009 | Codex window 900 s + timeout message | FR-018 | US7 | 0.5 | Implementer | scripts/internal/continuous-co-review/reviewer-host-catalog.ps1, tests/continuous-co-review/** | done | | | |
| T010 | Consumer-language layer (gloss helper + banned nouns + surface pass + one-message stops) | FR-015, FR-016, FR-017 | US6 | 1.75 | Implementer | scripts/internal/continuous-co-review/*navigator*.ps1, templates/**, .claude/skills/**, tests/integration/** | done | | | |
| T011 | Banner full prerelease version | FR-019 | US6 | 0.25 | Implementer | scripts/internal/specrew-bootstrap-provider.ps1, scripts/internal/coordinator-prompt-surgery.ps1, extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1, tests/bootstrap/** | done | | | |
| T012 | Records: 009/010 wording + release-notes draft | FR-020, FR-021 | US6 | 0.25 | Spec Steward | specs/**, release notes draft | done | | | |
| T013 | markdownlint-cli CI install | FR-022 | US6 | 0.1 | Implementer | .github/workflows/** | done | | | |

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
- Technology and scope signals: No single specialty dominates yet; treat the slice as general product work until task decomposition adds sharper evidence.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Current scope does not yet prove enough safe parallelism for same-specialty expansion; default to a smaller serial team until tasks are clearer.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1.0 | Workshop + design-analysis + plan/tasks authoring (already spent) |
| Discovery/Spikes | 0.0 | No spikes; the machinery map grounded the design |
| Implementation | 13.1 | Sum of T001–T013 (the corrected plan total, DRIFT-199-I001-004) |
| Review | 2.0 | Codex campaign rounds under the new economics + certification |
| Rework | 1.5 | Needs-rework buffer inside the 20 SP envelope |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021, FR-022, FR-023
- User stories represented in current scope: US1, US2, US3, US4, US5, US6, US7
- Task table populated from tasks.md (T001–T013, one-to-one with plan work items W1–W13); both-directions FR/SC traceability recorded in tasks.md.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- Execution order (maintainer instruction at the tasks verdict, 2026-08-10): T009,
  T011, T013 first (cheap durable wins — the CI lane goes green before heavy work and
  the codex review window is in place before codex reviews this feature), then the
  economics core T001, T002, T003, then T004, T005, T006, T007, T008, T010, T012.
- Planned task effort: 13.1 SP of the 20 SP capacity (threshold 20 x 1.0 not
  exceeded; the maintainer's ~10–12 target is overshot by ~1.1 SP, surfaced at the
  tasks boundary for ruling — trim candidates named there).
- Status is retro: all planned implementation tasks are complete, review-signoff was
  authorized on 2026-08-27 against 66403e9b, and the retro verdict was given on 2026-08-29
  (retro.md authored; iteration-closeout is the remaining boundary).
- FR-006 was added to the Scope Summary manually; the scaffold's FR extractor
  skipped it (recorded observation, non-blocking).
