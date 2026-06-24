# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 14/20 story_points
**Started**: 2026-06-24

## Scope Summary

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-001 | Replace three hardcoded host validators with live registry validation. | US2 |
| FR-002 | Generate deterministic host-package FileList membership and parity. | US2 |
| FR-003 | Add the permanent host-addition purity assertion and negative proof. | US2 |
| FR-004 | Remove the three Slice A firewall exceptions without adding a Devin exception. | US2 |
| FR-011 | Use the empirical Stop/export spike to select the handover mechanism. | US4 |
| FR-012 | Preserve the parser collision boundary and leave the accessor untouched. | US4 |
| FR-019 | Wire Slice A registry, firewall, generation, and prepublish checks into CI. | US2, US5 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- | ---: | --- |
| T001 | Empirical Devin Stop/export/normalization spike | FR-011, FR-012, SC-008 | US4 | 3 | Planner, Reviewer | specs/200-devin-cli-host/iterations/001/research/**; .scratch/** | done | codex | 3 | pass |
| T002 | Registry-driven validation at three production boundaries | FR-001, SC-002 | US2 | 2 | Implementer | hosts/_registry.ps1; scripts/specrew-start.ps1; scripts/internal/host-flag-translation.ps1; scripts/internal/coordinator-prompt-surgery.ps1; tests/integration/** | planned | codex |  |  |
| T003 | Deterministic host-package FileList generator and parity gate | FR-002, SC-004 | US2 | 3 | Implementer | hosts/_contract.md; hosts/_registry.ps1; scripts/internal/**; Specrew.psd1; tests/integration/**; tests/unit/** | planned | codex |  |  |
| T004 | Host-addition purity assertion and three-entry allow-list shrink | FR-003, FR-004, SC-002, SC-003 | US2 | 3 | Implementer, Reviewer | tests/integration/host-coupling-firewall.tests.ps1; tests/integration/fixtures/** | planned | codex |  |  |
| T005 | Slice A CI and FileList-faithful prepublish wiring | FR-019, SC-010 | US2, US5 | 2 | Implementer, Reviewer | .github/workflows/**; scripts/internal/test-publish-harness.ps1; tests/integration/** | planned | codex |  |  |
| T006 | Iteration review, traceability, and expected rework reserve | SC-012 | US2, US4 | 1 | Reviewer, Spec Steward | specs/200-devin-cli-host/**; tests/** | planned | codex |  |  |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Hard cap confirmed by the maintainer. |
| Iteration Bounding | scope | Scope remains fixed to the approved first Option B slice. |
| Time Limit (hours) | n/a | Not time-bounded. |
| Overcommit Threshold | 1.0 | Any plan above 20 SP requires a human split/defer decision. |
| Defer Strategy | manual | Do not silently move or add requirements. |
| Calibration Enabled | true | Retro records actual effort and planning variance. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro
  Facilitator.
- Technology and scope signals: PowerShell registry/runtime code, PSD1 package
  projection, PowerShell tests, and GitHub Actions.
- Task dependency graph: T002 establishes the reusable validation seam; T003
  establishes generated package membership; T004 relies on the post-cleanup
  source shape; T005 wires the resulting checks. Execute T002–T005 serially.
- Workstream separability: the completed T001 evidence is independent, but the
  remaining tasks overlap registry, firewall, package, and integration-test
  surfaces.
- Shared-surface conflict risk: high around `hosts/_registry.ps1`,
  `tests/integration/`, and generated `Specrew.psd1`.
- Recommendation: one implementer stream with reviewer checkpoints after T003
  and T005; no review fan-out that can change authorship without verification.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | ---: | --- |
| Planning and artifact authoring | 2 | Design gate, feature/iteration plans, and Wave B artifacts. |
| Discovery/spike | 3 | Completed real-host Stop/export/parser proof. |
| Implementation | 6 | Registry validator, FileList generator, and firewall cleanup. |
| Review and deterministic validation | 2 | Focused suites, CI/prepublish checks, diff classification. |
| Expected rework | 1 | Bounded repair reserve. |
| **Total** | **14** | Within the 20-SP cap. |

## Traceability Summary

- Requirement scope: FR-001, FR-002, FR-003, FR-004, FR-011, FR-012, FR-019.
- Success criteria represented: SC-002, SC-003, SC-004, SC-008, SC-010,
  SC-012.
- User stories represented: US2, US4, US5.
- Capacity check: 14/20 story_points; 6 SP reserve remains but is not implicit
  permission to pull work forward from iterations 002 or 003.
- Split guard: no Devin package implementation, coordinator migration, docs
  rollout, or promotion work enters iteration 001 unless the human explicitly
  re-baselines the iteration.

## Notes

- Design-analysis verdict: `approved for plan with Option B`.
- Feature plan:
  file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/plan.md
- Spike evidence:
  file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/iterations/001/research/devin-stop-payload-spike.md
- T001 proved outcome 2 byte-for-byte through the unchanged parser and found the
  pinned-build Windows `sh.exe` prerequisite.
- The direct-`pwsh` host-neutral fix attempt is iteration 002 work; iteration
  001 records the constraint but does not speculate a solution.
- `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` is forbidden
  throughout the feature.
