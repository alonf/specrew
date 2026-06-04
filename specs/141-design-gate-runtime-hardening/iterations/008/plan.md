# Iteration Plan: 008

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 17/20 story_points
**Started**: 2026-06-04
**Completed**: 2026-06-05

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Task Status one of planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

The **workshop-visuals** capability (Amendment A5, Option B — workshop-settled): a per-lens diagram
vocabulary rendered in tiers (inline → temp-file+`file:///` link → persisted), with bidirectional
per-lens intake. Same behavioral-content / deterministic-emit split as the i7 conduct: the agent authors
the diagram content; a deterministic helper emits the file + link (reusing the FR-028 console form).
SC-022 (behavioral, the visual dogfood) is the acceptance gate; SC-023 (catalog + emit helper) is the
unit-tested floor.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-030 | Per-lens diagram catalog (lens → diagram-type → render-form), sibling data file; index.yml pure | US-V |
| FR-031 | Tiered render+surface (inline / temp-file+file:/// / persisted), FR-028 form; agent authors, helper emits | US-V |
| FR-032 | Bidirectional per-lens intake (plot-from-description + bring-your-own → reference + transcribe) | US-V |
| FR-033 | Ephemeral temp under .specrew/workshop-visuals/ (gitignored, cleaned at close); mermaid-inline keepers | US-V |
| SC-022 / SC-023 | Behavioral (visual dogfood) + deterministic floor (catalog + emit helper, unit-tested) | US-V |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Per-lens diagram catalog (diagram-vocabulary.json, sibling to applicability-map.json; index.yml pure) + reader Get-SpecrewLensDiagramType (graceful) | FR-030 | US-V | 3 | Implementer | extensions/specrew-speckit/knowledge/design-lenses/**, scripts/internal/lens-applicability.ps1 | done | claude | 3 | pass |
| T002 | Emit helper Format-SpecrewWorkshopVisual: tiered inline (fenced) / temp-file (write under .specrew/workshop-visuals/ + clickable file:/// ref, FR-028 console form) / persisted (mermaid-inline; svg/html referenced); gitignore the temp dir (FR-033) | FR-031, FR-033 | US-V | 5 | Implementer | scripts/internal/lens-applicability.ps1, templates/** (.gitignore) | done | claude | 5 | pass |
| T003 | Intake-reference helper (record a provided artifact path/image as a referenced input) + conduct-rule addition: per applicable lens, offer the catalog diagram + ask for an existing artifact; render via the tier policy | FR-032, FR-030 | US-V | 3 | Spec Steward | scripts/internal/lens-applicability.ps1, scripts/specrew-start.ps1 | done | claude | 3 | pass |
| T004 | Tests (reproduce-first, SC-023 floor): catalog resolves diagram-type+render-form per lens (graceful on missing); emit helper inline/temp/persisted tiers (temp writes + returns file:/// ref; persisted mermaid-inline; svg/html referenced); intake-reference records the input. NOT a proof of diagram quality | SC-023, FR-030, FR-031 | US-V | 4 | Reviewer | tests/unit/** | done | claude | 4 | pass |
| T005 | SC-022 runtime visual dogfood: a downstream run where the workshop renders ≥1 per-lens diagram from the catalog, surfaced per the tier policy (inline and/or clickable file:/// temp link), with a keeper persisted as inline mermaid. The acceptance gate (behavioral) | SC-022 | US-V | 2 | Planner | specs/141-design-gate-runtime-hardening/** | done | claude | 2 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 17/20. |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Concurrency Rationale

- T001 (catalog + reader) is the root; T002 (emit helper) is independent of the catalog (takes content+form);
  T003 (intake + conduct rule) depends on T001/T002 conceptually; T004 (tests) follows the code; T005 (the
  visual dogfood) is the human-run acceptance gate. Serial baseline team.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Design via the workshop; Option B recorded (decision 18721b9e). |
| Implementation | 11 | T001 catalog (3) + T002 emit (5) + T003 intake/conduct (3). |
| Review | 6 | T004 tests (4) + T005 the visual dogfood (2). |
| Rework | 0 | Buffer via the 17/20 headroom. |

## Traceability Summary

- Iteration 8 scope: FR-030 (catalog), FR-031 (render+surface), FR-032 (intake), FR-033 (temp lifecycle); SC-022 (dogfood), SC-023 (floor).
- Design-analysis: completed via the workshop; Option B; decision `18721b9e`, draft `aed6dd60`.
- FR mapping: FR-030→T001/T003; FR-031→T002; FR-032→T003; FR-033→T002; SC-023→T004; SC-022→T005.

## Notes

- **The value is the per-lens diagram experience**, and the diagram *content* is behavioral — T005's visual
  dogfood, not T004's unit tests, is the acceptance evidence (SC-022; the i6/i7 lesson).
- Engine retained; `index.yml` stays pure (catalog is a sibling); emit reuses the FR-028 console form; no
  release/push while 141 is in progress.
- Stops at before-implement for the go-ahead (the maintainer's "yes, lets build it" authorizes it).
