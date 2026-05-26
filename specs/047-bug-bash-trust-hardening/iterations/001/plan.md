# Iteration Plan: 001 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 20/20 story_points
**Started**: 2026-05-26
**Completed**: 2026-05-26

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
| FR-001 | Governance validation MUST detect when an iteration/boundary commit lacks a preceding `=== SPECREW HANDOFF ===` block and emit a WARN, using a shared `Test-SpecrewHandoffBlockPresent` helper in `shared-governance.ps1`. (Proposal 120 Pillar 1) | — |
| FR-002 | Governance validation MUST augment trigger-bypass diagnosis to differentiate "non-Specrew-managed iteration" from "auto-render code regression" when `dashboard.md` is missing, and emit the appropriate WARN. (Proposal 120 Pillar 2) | — |
| FR-003 | Governance validation MUST emit a WARN when canonical artifacts are detected in ephemeral host-scratch directories (e.g. paths under `.gemini/antigravity-cli/brain/`). (Proposal 120 Pillar 3) | — |
| FR-004 | An acceptance test MUST verify that an iteration commit with no preceding handoff block AND a compaction marker in session metadata triggers the WARN (Proposal 120 sub-trigger 3c), added to `tests/integration/non-specrew-session-bypass.tests.ps1`. | — |
| FR-005 | Governance validation MUST soft-WARN when `review-diagrams.md` exists but contains no ` ```mermaid ` block. (Proposal 121 Pillar 1) | — |
| FR-006 | The reviewer-artifacts scaffolder MUST emit a non-empty Mermaid skeleton (component `graph TD` + `sequenceDiagram` examples) in `review-diagrams.md` instead of empty fences. (Proposal 121 Pillar 2) | — |
| FR-007 | Per-host Reviewer charter templates MUST direct authors to use Mermaid for diagrams and not substitute ` ```text ` ASCII trees. (Proposal 121 Pillar 3) | — |
| FR-008 | All `installed-instructions/` files and coordinator-prompt templates MUST be audited and rewritten so user-facing prose names the methodology concept rather than an internal `\bF-\d{3,}\b` / `\bProposal \d{3,}\b` / `\bFeature \d{3,}\b` reference. (Proposal 078 Pillar 2b) | — |
| FR-009 | Governance validation MUST add a regex check that emits a WARN when internal feature/proposal references appear in handoff-block prose. (Proposal 078 Pillar 5) | — |
| FR-010 | `Get-SpecrewSkillCatalogState` MUST treat a skill root directory containing zero `SKILL.md` files as a missing root (content-based check, not existence-only) so auto-repair fires and no contradictory per-host "missing skill files" WARN survives. (F-046 Bug 5 follow-up, fix option a) | — |
| FR-011 | The coordinator-prompt feature-closeout HANDOFF template MUST embed the PR-at-feature-close SDLC sequence (push → open PR → address automated PR review → merge) as `HUMAN ACTION NEEDED` items across all per-host templates; the boundary-sync helper MAY additionally echo the same sequence in post-feature-closeout console output. (F-046 retro improvement #2) | — |
| FR-012 | The `specrew-start.ps1` `tasks-progress.yml` regeneration path MUST derive per-task status from `tasks.md` (`[x]` checkboxes) and `state.md` (`Last Completed Task`) — with `tasks.md` authoritative — instead of unconditionally writing all tasks as `planned`. (New 2026-05-26 finding, fix option a) | — |
| FR-013 | The feature MUST record per-item Surface / Repro / Validation Criterion / Evidence Pointer / Status in a durable `findings.md` ledger. | — |
| FR-014 | Any change to `extensions/specrew-speckit/scripts/*` MUST be mirrored byte-identical in `.specify/extensions/specrew-speckit/scripts/`. | — |
| FR-015 | The feature MUST bump the Specrew version to `v0.27.3` consistently across `.specrew/config.yml`, `extension.yml`, and `Specrew.psd1` (ModuleVersion), and record the change in `CHANGELOG.md`, per Rule 15. | — |
| FR-016 | All new detection rules added by this feature MUST be severity WARN (not FAIL) to remain backward-compatible. | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Handoff-block detection fixtures | FR-001,FR-002,FR-003,FR-016 | US1 | 1 | Implementer | tests/integration/non-specrew-session-bypass.tests.ps1 | done | codex | 1 | pass |
| T002 | Test-SpecrewHandoffBlockPresent helper + 3 WARN checks | FR-001,FR-002,FR-003,FR-016 | US1 | 2 | Implementer | extensions/specrew-speckit/scripts/{shared-governance,validate-governance}.ps1 | done | codex | 2 | pass |
| T003 | Mirror Item 1 to .specify/ | FR-014 | US1 | 1 | Implementer | .specify/extensions/specrew-speckit/scripts/* | done | codex | 1 | pass |
| T004 | Post-compaction sub-trigger 3c acceptance test | FR-004 | US2 | 1 | Implementer | tests/integration/non-specrew-session-bypass.tests.ps1 | done | codex | 1 | pass |
| T005 | Mermaid-absence + scaffolder-skeleton fixtures | FR-005,FR-006 | US3 | 1 | Reviewer | tests/integration/* | done | codex | 1 | pass |
| T006 | Validator soft-WARN + scaffolder Mermaid skeleton | FR-005,FR-006,FR-016 | US3 | 1 | Reviewer | extensions/specrew-speckit/scripts/{validate-governance,scaffold-reviewer-artifacts}.ps1 | done | codex | 1 | pass |
| T007 | Reviewer charter Mermaid directive + mirror | FR-007,FR-014 | US3 | 1 | Reviewer | per-host charters; .specify/extensions/specrew-speckit/scripts/* | done | codex | 1 | pass |
| T008 | Internal-reference regex fixtures (pos+neg) | FR-009 | US4 | 1 | Implementer | tests/integration/* | done | codex | 1 | pass |
| T009 | Audit + rewrite installed-instructions/ + templates | FR-008 | US4 | 1 | Spec Steward | installed-instructions/*; coordinator templates | done | codex | 1 | pass |
| T010 | Validator internal-reference regex WARN + mirror | FR-009,FR-014,FR-016 | US4 | 1 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1 (+mirror) | done | codex | 1 | pass |
| T011 | Empty-skill-dir fixture (HasMissingRoots true) | FR-010 | US5 | 1 | Implementer | tests/integration/* | done | codex | 1 | pass |
| T012 | Content-based Get-SpecrewSkillCatalogState check | FR-010 | US5 | 1 | Implementer | scripts/internal/skill-catalog-state.ps1 | done | codex | 1 | pass |
| T013 | Per-host closeout-template presence test | FR-011 | US6 | 1 | Spec Steward | tests/integration/* | done | codex | 1 | pass |
| T014 | Embed PR-at-close SDLC in closeout HANDOFF templates | FR-011 | US6 | 1 | Spec Steward | per-host coordinator templates | done | codex | 1 | pass |
| T015 | tasks-progress reconciliation fixture | FR-012 | US7 | 1 | Implementer | tests/integration/* | done | codex | 1 | pass |
| T016 | Derive-from-tasks.md regeneration in specrew-start.ps1 | FR-012 | US7 | 1 | Implementer | scripts/specrew-start.ps1 | done | codex | 1 | pass |
| T017 | v0.27.3 bump across 3 manifests + CHANGELOG | FR-015 | US1-US7 | 1 | Implementer | .specrew/config.yml; extension.yml; Specrew.psd1; CHANGELOG.md | done | codex | 1 | pass |
| T018 | Mirror-parity diff -q verification | FR-014,SC-010 | US1-US7 | 1 | Reviewer | extensions/ vs .specify/extensions/ | done | codex | 1 | pass |
| T019 | Mechanical checks + integration suites + findings.md | FR-013,SC-010 | US1-US7 | 1 | Reviewer | tests/integration/; findings.md | done | codex | 1 | pass |

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
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0 | Scaffolded ahead of implementation per plan baseline |
| Discovery/Spikes | 0 | No spike; tests-first integration coverage carries risk-reduction |
| Implementation | 17 | T001-T016: the 7 items (tests-first per item) |
| Review | 3 | T017-T019: version bump, mirror-parity verify, no-regression sweep + findings |
| Rework | 0 | No pre-allocated buffer; absorb in-iteration via tasks-first discipline |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016
- User stories represented in current scope:
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.
