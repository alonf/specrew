# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 17.0/20 story_points
**Started**: 2026-05-14
**Completed**:
**Planning Authority**: Resumed Iteration 002 planning authorized on 2026-05-14 for the original
FR-020 through FR-024 slice plus explicit carryover triage from accepted Iteration 001 review/retro
evidence.

## Scope Summary

| Scope Slice | Coverage | Planned Effort | Notes |
| ----------- | -------- | -------------- | ----- |
| Core Iteration 002 proof and graduation | FR-016 (Iteration 2 portion), FR-021 | 5.0 | Violating/compliant/exempt scaffold-replay fixtures plus config-only severity promotion |
| Core corpus and historical cross-references | FR-020, FR-024 | 3.5 | Four required Feature 016 rows plus selected passive-guidance graduation rows and historical links |
| Public documentation and handoff-template follow-through | FR-022, FR-023 | 4.0 | README, validator documentation, seven-boundary template examples, post-commit verification wording |
| Carryover stabilization | FR-008 follow-through + accepted review/retro carryovers | 4.5 | Pending -> post-commit Commit Reference synchronization, seconds-precision canonicalization, stale-reference scan mandate |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| I2-01 | Add violating/compliant/exempt replay fixtures for all new interaction-model rules | FR-021, FR-016 | US1/US2/US3 | 4.0 | Quality steward | `tests/integration/**`, `tests/unit/**`, `tests/**/fixtures/016-substantive-interaction-model/**` | done | copilot | 4.0 | pass |
| I2-02 | Promote `bare-path-in-boundary-handoff` by config/rule-table flip only after proof passes | FR-016, FR-021 | US3 | 1.0 | Validator steward | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | done | copilot | 1.0 | pass |
| I2-03 | Add the four required Feature 016 known-traps rows plus historical cross-references | FR-020, FR-024 | TG-004 | 2.0 | Quality steward | `.specrew/quality/known-traps.md` | done | copilot | 2.0 | pass |
| I2-04 | Graduate selected feature-local passive-guidance rows from Iteration 001 retro | FR-020, FR-024 + approved passive-guidance carryovers | US3/TG-004 | 1.5 | Quality steward | `.specrew/quality/known-traps.md`, `specs/016-substantive-interaction-model/iterations/001/*.md` | done | copilot | 1.5 | pass |
| I2-05 | Update README and validator documentation for the three-pillar model and post-commit verification protocol | FR-022 + carryover | US2/US3 | 2.0 | Documentation steward | `README.md`, `extensions/specrew-speckit/governance/validation-lane.md` | done | copilot | 2.0 | pass |
| I2-06 | Update the per-feature handoff template with seven worked examples and verification/stale-reference expectations | FR-023 + carryover | US2/US3 | 2.0 | Documentation steward | `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | done | copilot | 2.0 | pass |
| I2-07 | Implement pending -> post-commit Commit Reference synchronization for generated authorization entries | FR-008 carryover | US1 | 2.5 | Governance steward | `.squad/decisions.md`, `extensions/specrew-speckit/scripts/shared-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | done | copilot | 2.5 | pass |
| I2-08 | Enforce and document canonical UTC seconds-precision `Recorded At` format | timestamp carryover | US1 | 1.0 | Governance steward | `specs/016-substantive-interaction-model/contracts/*.md`, `README.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | done | copilot | 1.0 | pass |
| I2-09 | Mandate stale-reference scans after boundary commits and wire the rule into handoff/checklist wording | stale-reference carryover | US3 | 1.0 | Documentation steward | `README.md`, `extensions/specrew-speckit/governance/validation-lane.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | done | copilot | 1.0 | pass |

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
- Technology and scope signals: shared PowerShell validator surfaces and shared Markdown truth surfaces
  mean replay proof, corpus curation, docs/template work, and commit-reference helpers overlap but can
  be partitioned carefully.
- Task dependency graph: I2-01 stabilizes proof expectations before I2-02; I2-03 and I2-04 depend on
  final rule IDs and historical evidence selection; I2-05/I2-06/I2-09 can move in parallel once the
  carryover protocol wording is fixed.
- Workstream separability: Quality-steward fixture/corpus work can proceed in parallel with
  documentation/template work after the carryover protocol is settled; shared validator/helper edits
  should stay serial.
- Shared-surface conflict risk: moderate on `.squad/decisions.md`, `shared-governance.ps1`, and the
  mirrored validator entrypoints; lower on README/template/corpus once contract wording is fixed.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: keep governance/helper mutations serial; allow docs/template and corpus curation to
  parallelize only after the contract wording is frozen. No same-specialty expansion is needed at the
  planning stage.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1.0 | Resume-scope reconciliation, carryover triage, and artifact updates |
| Discovery/Spikes | 0.5 | Limited to carryover policy decisions already grounded by Iteration 001 evidence |
| Implementation | 12.0 | Planned task execution across fixtures, docs/template, corpus, and helper updates |
| Review | 2.0 | Expected review/demo and post-commit verification confirmation |
| Rework | 1.5 | Small bounded repair reserve for corpus/doc or replay-proof drift |

## Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
| --- | --- | --- | --- |
| `dead-field` | mechanical | `specs/016-substantive-interaction-model/iterations/002/quality/mechanical-findings.json` | planned |
| `anti-pattern` | mechanical | `specs/016-substantive-interaction-model/iterations/002/quality/mechanical-findings.json` | planned |
| `test-integrity` | mechanical | `specs/016-substantive-interaction-model/iterations/002/quality/mechanical-findings.json` | planned |
| `stack-tooling-evidence` | tooling | `specs/016-substantive-interaction-model/iterations/002/quality/quality-evidence.md` | planned |
| `quality-lens-review` | manual-evidence | `specs/016-substantive-interaction-model/iterations/002/quality/quality-evidence.md` | planned |
| `known-trap-cross-reference-completeness` | manual-evidence | `.specrew/quality/known-traps.md` | planned |
| `post-commit-verification-truth` | manual-evidence | README, validation docs, handoff template, quickstart | planned |
| `repo-validator-clean` | tooling | `extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` | planned |

## Quality Scaffold Targets

- Planning-time quality artifacts should exist at `specs/016-substantive-interaction-model/iterations/002/quality/hardening-gate.md`, `specs/016-substantive-interaction-model/iterations/002/quality/quality-evidence.md`, `specs/016-substantive-interaction-model/iterations/002/quality/mechanical-findings.json`, and `specs/016-substantive-interaction-model/iterations/002/quality/trap-reapplication.md`.
- Iteration 002 remains planning-scoped; these artifacts are scaffolds for later hardening, evidence capture, and drift control, not execution proof.

## Traceability Summary

- Requirement scope for this iteration: FR-016 (Iteration 2 graduation), FR-020, FR-021, FR-022,
  FR-023, FR-024, plus the accepted FR-008 / review / retro carryovers that keep post-commit truth
  surfaces aligned.
- User stories represented in current scope: US1 (authorization fidelity), US2 (substantive docs and
  handoff expectations), US3 (click-through navigation and stale-reference hygiene).
- Carryover rows planned in scope: `fr-008-pending-commit-reference-vs-validator-hash-match`,
  `nfr-budget-calibrated-against-pre-refactor-baseline`, `boundary-regex-substring-match`, and
  `validator-catch-22-pre-commit-vs-post-commit`.
- Explicit deferrals: standalone fractional-second parser support, standalone stale-reference
  soft-validator support, validator performance optimization, `self-referential-feature-sp-surcharge`,
  and `decisions-ledger-parser-fractional-second-timestamp-incompatibility`.
- Overcommit guardrail: total effort remains 17.0 / 20.0 story_points, below capacity and within the
  requested 15-19 SP target band.

## Notes

- Iteration 001 is closed; this artifact plans Iteration 002 only.
- Carryover absorption is intentional and bounded. The plan is explicit about what was brought in and
  what remains deferred so the feature does not hide accepted review/retro lessons.
- Keep `Status: planning` until the human authorizes movement beyond the planning boundary.
