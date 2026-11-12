# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 18/20 story_points
**Started**: 2026-11-10
**Completed**: 2026-11-12

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
| FR-001 | `index.yml` MUST be the only definition of the lens order and each lens's space. A parity test MUST check: | — |
| FR-004 | requirements-nfr MUST own the binding-constraint and scope questions, and architecture-core MUST NOT ask them. architecture-core's "Which constraints are binding, and which are preferences?" duplicates requirements-nfr's existing "Which constraints are mandatory rather than preferences?", so the two are merged into requirements-nfr's existing question. Only the scope question ("What is deliberately out of scope for this iteration?") is added to requirements-nfr. | — |
| FR-005 | Each lens file MUST carry `### Problem questions` and `### Solution questions` inside `## Design Decision Points`. A one-space lens MUST keep the empty heading with a one-line reason. Every decision point MUST sit under exactly one sub-heading. A test MUST prove these, prove that each file agrees with index.yml's `space`, and prove that `Get-SpecrewLensDecisionPoints` returns exactly the tagged points for every lens. | — |
| FR-013 | Agendas confirmed before this release MUST NOT be re-checked or reordered. The order check MUST run only when an agenda is confirmed. A test MUST prove that an old-order confirmed agenda resumes and completes. | — |
| FR-015 | `index.yml` MUST give each lens a `space` of `problem`, `solution` or `both`, and a lens's position in the list MUST be the order: | — |
| FR-016 | The agenda writer MUST refuse a new agenda whose selected lenses break index.yml's relative order. It MUST refuse through the existing refusal helper, naming the out-of-order lenses and the index.yml order, with one action, and MUST NOT reorder silently. | — |
| FR-017 | The workshop skill and methodology MUST describe the single-pass order from index.yml, with each lens's problem questions asked before its solution questions. | — |
| FR-018 | The workshop skill MUST state that if any list disagrees with index.yml, index.yml wins, and that a confirmed agenda keeps the order it was confirmed in. | — |
| FR-019 | A mismatch report MUST name the file and line, the expected order, the order found, and the fix, and one run MUST report every mismatch. For a deployed copy, the fix MUST name `deploy-speckit-extension.ps1 -ProjectPath . -RefreshExisting` and `deploy-squad-runtime.ps1 -ProjectPath .`, say they write inside the project only, and say they also restamp `.squad` runtime files. | — |
| FR-020 | The tagging pass MUST record a per-lens list of problem-side gaps as iteration 2's input, and MUST NOT add or reword questions, apart from the split rule and the FR-004 move. | — |
| FR-021 | Every existing workshop test MUST be run locally and its result reported. Named `specrew-ci.yml` steps MUST cover the new parity test, the extended agenda-confirmation test, and every existing workshop test that covers a file this feature touches and passes. An already-red workshop test MUST be reported as a finding. | — |
| FR-022 | Proposal 220 MUST move to `status: active` with `shipped-as: feature-205`. Its status history MUST gain a line recording the three iterations (1: order, tagging, parity, migration; 2: problem-space completeness; 3: two-pass split, back-check, amendments and sweeps after 203), the fifth order surface found at intake (the before-specify command list), and the choice of order option A. `proposals/INDEX.md` MUST follow in both its table row and its summary line. | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Parity test: scanner, full surfaces, sweep, copies, FR-005, extractor, report | FR-001, FR-005, FR-015, FR-018, FR-019, SC-003 | US2 | 4 | implementer | — | done | — | — | — |
| T002 | Parity test self-test cases (examples, multi-mismatch) | FR-001, FR-019 | US2 | 1 | implementer | — | done | — | — | — |
| T003 | Red-first run recorded in quality-evidence | SC-001 | US2 | 0.5 | implementer | — | done | — | — | — |
| T017 | Baseline: existing workshop tests on the unchanged tree (safety rule) | FR-021 | US2 | 1 | implementer | — | done | — | — | — |
| T004 | Agenda-confirmation test: refusal, in-order, FR-013 resume | FR-016, FR-013 | US4 | 1.5 | implementer | — | done | — | — | — |
| T005 | index.yml: problem-first order + space | FR-015 | US1 | 0.5 | implementer | — | done | — | — | — |
| T006 | Tag 11 lens files; S1-S3; FR-004 merge/move; gap list | FR-005, FR-004, FR-015, FR-020 | US3 | 2.5 | implementer | — | done | — | — | — |
| T007 | Agenda writer relative-order refusal | FR-016, FR-013 | US1 | 1 | implementer | — | done | — | — | — |
| T008 | Skill: list, index.yml-wins sentence, problem-first conduct | FR-017, FR-018 | US1 | 1 | implementer | — | done | — | — | — |
| T009 | Methodology lists rewritten | FR-017, FR-001 | US1 | 1 | implementer | — | done | — | — | — |
| T010 | before-specify + catalog README lists | FR-001 | US2 | 0.5 | implementer | — | done | — | — | — |
| T011 | Refresh deployed copies (two deploy scripts) | FR-001, FR-019 | US2 | 0.5 | implementer | — | done | — | — | — |
| T012 | Parity + agenda tests green; SC-002 counts | SC-001, SC-002, SC-004 | US2 | 0.5 | implementer | — | done | — | — | — |
| T013 | Run all existing workshop tests; report | FR-021 | US2 | 1 | implementer | — | done | — | — | — |
| T014 | Named specrew-ci.yml steps | FR-021, SC-005 | US2 | 0.5 | implementer | — | done | — | — | — |
| T015 | Proposal 220 status + INDEX | FR-022 | US2 | 0.5 | implementer | — | done | — | — | — |
| T016 | Pre-push gate, push, CI to conclusion | SC-005 | US2 | 0.5 | implementer | — | done | — | — | — |

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
- Technology and scope signals: PowerShell 7 scripts, lens markdown, YAML catalog and tests (the scaffold's "frontend" reading is the resolver misread, DRIFT-001).
- Task dependency graph: see tasks.md "Dependencies"; red-first T001-T004 gate everything, then T005 (index.yml) feeds T006-T010.
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: serial, single implementer; the surfaces share index.yml and the parity test, so parallel same-specialty work would conflict.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | spec, workshop, design analysis, plan, tasks |
| Discovery/Spikes | 0 | YAML parse and deploy scripts already verified in scratch |
| Implementation | 18 | T001-T017 |
| Review | in implementation estimate | codex co-review |
| Rework | 2 | buffer to the 20 SP cap |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-004, FR-005, FR-013, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021, FR-022
- User stories represented in current scope: US1 (FR-015, FR-016, FR-017), US2 (FR-001, FR-019), US3 (FR-005), US4 (FR-013, FR-018), US5 (FR-020); cross-cutting FR-004, FR-021, FR-022
- Task table populated from tasks.md; every FR/SC in scope maps to at least one task (traceability checked at after-tasks).
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- Planned effort 18 story_points against a 20 cap (T017 baseline added at the tasks verdict); proposal 220 estimated 10-15, the overshoot is the sweep/self-test machinery fixed at the plan verdict.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.
