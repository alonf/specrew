# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 17/20 story_points
**Started**: 2026-06-11
**Completed**: 2026-06-12

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of: planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status MUST be one of: planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 002 = the **runtime layer** (the CI work-kind validator + capability detection + the GitHub
adapter + on-the-fly synthesis + the Specrew dogfood). Architecture + contracts were set in the
design workshop (Iteration 1 shipped the catalog, schemas, methodology surfaces, and the provider-
neutral `ProviderAdapter` contract + generic fallback). This iteration consumes those.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-007 | Provider-neutral CI validator (one kind? changed-files match? closeout evidence?); advisory default | US4 |
| FR-011 | Emergency/bypass path leaves a durable audit artifact | US4 |
| FR-012 | Capability detection reports the achievable mechanism; ci-only/manual fallback | US5 |
| FR-013 | Dogfood on Specrew's own repo (work-kind declaration + governance capture) | US1 |
| FR-015 | GitHub reference adapter detection (gh/API) | US5 |
| FR-016 | On-the-fly adapter synthesis exercised (read-only until verified) | US5 |
| FR-020 | apply_protection human-approved; never auto-applied / unverified; no Specrew secret | US5 |
| FR-021 | Brownfield: detect existing CI/CD + protection; adapt-or-change | US6 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T201 | WorkKindValidator core (advisory; gap-naming; fail-open) | FR-007 | US4 | 2 | Implementer | extensions/specrew-speckit/scripts/work-kind-validator.ps1 | done | claude | done | i2-validator (T211 green) |
| T202 | ChangedFileClassifier (scope match + allow-list) | FR-007 | US4 | 1 | Implementer | extensions/specrew-speckit/scripts/work-kind-validator.ps1 | done | claude | done | i2-validator (T211 green) |
| T203 | CloseoutEvidenceChecker (required evidence / open boundary) | FR-007 | US4 | 1.5 | Implementer | extensions/specrew-speckit/scripts/work-kind-validator.ps1 | done | claude | done | i2-validator (T211 green) |
| T204 | CapabilityDetector (honest mechanism; describe-only default) | FR-012 | US5 | 1.5 | Implementer | extensions/specrew-speckit/scripts/capability-detector.ps1 | done | claude | done | T212 green |
| T205 | GitHubAdapter detection + apply (gh/API; gh confined here) | FR-015 | US5 | 2 | Implementer | extensions/specrew-speckit/scripts/provider-github.ps1 | done | claude | done | gh-confined; fail-open; apply guarded (T212) |
| T206 | Brownfield detector (existing posture; adapt-or-change) | FR-021 | US6 | 1.5 | Implementer | extensions/specrew-speckit/scripts/capability-detector.ps1 | done | claude | done | T212 green |
| T207 | CI workflow template (provider-neutral invocation) | FR-007 | US4 | 0.5 | Implementer | templates/github/workflows/specrew-work-kind.yml | done | claude | done | advisory-default workflow |
| T208 | On-the-fly synthesis exercised (read-only until verified) | FR-016 | US5 | 1.5 | Implementer | templates/work-kind/synthesized-adapter.example.ps1 | done | claude | done | conduct (lens) + read-only example + tested (T015/T212) |
| T209 | Emergency bypass audit (durable who/why/when/what) | FR-011 | US4 | 1 | Implementer | extensions/specrew-speckit/scripts/work-kind-validator.ps1 | done | claude | done | i2-validator (T211 green) |
| T210 | Dogfood Specrew + SC-014 self-consistency (describe-only) | FR-013 | US1 | 1.5 | Reviewer | .specrew/work-kind.yml | done | claude | done | .specrew/work-kind.yml + repository-governance.yml; SC-014 (T212) |
| T211 | i2 tests — validator (capability + brownfield added with T204/T206) | FR-007 | US4 | 1.5 | Implementer | tests/unit/work-kind-validator.tests.ps1 | done | claude | done | 12 assertions green |
| T212 | i2 denial-path + fail-open + parity tests | FR-020 | US5 | 1.5 | Implementer | tests/unit/work-kind-runtime.tests.ps1 | done | claude | done | 19 assertions green |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning should choose deferrals when over capacity. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Task dependency graph: T201–T203 (validator) precede T211/T212 (validator tests); T204–T206
  (capability/adapter/brownfield) precede T211; serial single-developer execution.
- Workstream separability: no safe same-specialty parallelism inferred; run serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Implementation | ~14 SP | T201–T210 runtime + dogfood. |
| Review | ~2 SP | validator/capability/denial-path evidence. |
| Rework | small | needs-work buffer. |

## Traceability Summary

- Requirement scope for **iteration 002 (runtime layer)**: FR-007, FR-011, FR-012, FR-013, FR-015,
  FR-016, FR-020, FR-021. (FR-019 decouple migration = Iteration 3; T013b release-prep carried here.)
- User stories: US1 (dogfood), US4 (CI enforcement), US5 (capability + synthesis), US6 (brownfield).
- Success criteria targeted: SC-005, SC-006, SC-007, SC-009, SC-010 (runtime on non-GitHub), SC-012,
  SC-014.
- Overcommit: ~16 SP planned vs cap 20 — within capacity.

## Notes

- The GitHub adapter's **live** detection (T205) and `apply_protection` (in T205/T209) require `gh` +
  a real token + a real repo; their logic is unit-tested with the generic/fallback path and mocks,
  and **live** GitHub behavior is validated at the dogfood/beta (honest phased posture). The dogfood
  (T210) is **describe-only** — it authors Specrew's governance capture + checks consistency; it does
  NOT auto-`apply_protection` against the real repo (that stays a human-approved action).
- `gh` / GitHub API stays confined to `provider-github.ps1`; the validator core remains forge-neutral.
- T013b (extension.yml version bump + deploy-time `.specify` coverage) remains the release/deploy step
  (drift-log D-001), resolved at feature-closeout — not in this iteration's implementation.
