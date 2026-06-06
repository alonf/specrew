# Iteration Plan: 009

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 18/20 story_points
**Started**: 2026-06-05
**Completed**: 2026-06-05

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Task Status one of planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

The **collaborative architecture & design** capability (Amendment A6, Option B — the proven A4/A5
behavioral-conduct + thin-deterministic-floor shape): make the design-analysis a **co-design session**, not a
questionnaire-then-unilateral-deliverable. The agent frames the phases (FR-034), co-decides the design
method/style (FR-035), co-builds the component/responsibility map + key flows WITH the human before
presenting options (FR-036), and surfaces visuals in-band (FR-037 — folding the iteration-8 surfacing gap #3/#5).
SC-024 (behavioral, the co-design dogfood) is the acceptance gate; SC-025 (the marker-gated
co-design-record floor) is the deterministic, unit-tested floor.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-034 | Phase-framing — workshop gathers inputs; structure co-designed with the human at design-analysis | US-CD |
| FR-035 | Design-method/style is a co-decided architecture-lens topic (discussion, expertise-adapted; not a bare MCQ) | US-CD |
| FR-036 | Design-analysis co-builds the component/responsibility map + flows WITH the human before options | US-CD |
| FR-037 | Visuals MUST surface in-band (inline render and/or clickable file:/// link); expected for structural + UI lenses | US-CD |
| SC-024 / SC-025 | Behavioral co-design dogfood + deterministic co-design-record floor (marker-gated, grandfather-safe, unit-tested) | US-CD |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Conduct: Rule 9a phase-framing + new Rule 9c collaborative co-design at design-analysis (co-build component/responsibility map + >=1 flow WITH the human, iterate to agreement, BEFORE options; expertise-adapted drive-more-for-novices but still confirm). The core behavioral capability | FR-034, FR-036 | US-CD | 4 | Spec Steward | scripts/specrew-start.ps1 | done | claude | 4 | pass |
| T002 | Conduct: Rule 9b surfacing strengthened MAY->MUST in-band (inline render and/or clickable file:/// link, never disk-only); a per-lens diagram is EXPECTED for structural lenses + any UI-bearing feature (folds i8 #3/#5) | FR-037 | US-CD | 2 | Implementer | scripts/specrew-start.ps1 | done | claude | 2 | pass |
| T003 | Lens data: add a design-method/decomposition-style decision point to architecture-core (DDD / IDesign / modular-monolith / microservices / layered) so the existing agenda generator raises it as a discussion (FR-035); verify Get-SpecrewLensWorkshopAgenda surfaces it | FR-035 | US-CD | 2 | Spec Steward | extensions/specrew-speckit/knowledge/design-lenses/architecture-core.md | done | claude | 2 | pass |
| T004 | Gate floor: Test-SpecrewDesignCoDesignRecord (marker-gated by co_design in lens-applicability.json; grandfather-safe — pre-A6 artifacts no-op) requires a non-placeholder ## Co-Design Record in design-analysis.md (component->responsibility map + >=1 agreed flow + a human-agreed marker); wire into Test-SpecrewDesignAnalysisArtifact; reuse the SC-021 placeholder helper + FR-026 resolution | SC-025, FR-036 | US-CD | 4 | Implementer | scripts/internal/design-analysis-gate.ps1 | done | claude | 4 | pass |
| T005 | Tests (reproduce-first, SC-025 floor): co_design marked + complete record -> PASS; marked + placeholder/missing -> FAIL naming the gap; unmarked (pre-A6) -> no-op (grandfather), modelling the real feature-vs-iteration layout; agenda-includes-design-method assertion. NOT a proof of co-design quality | SC-025, FR-035 | US-CD | 4 | Reviewer | tests/unit/** | done | claude | 4 | pass |
| T006 | SC-024 runtime co-design dogfood: a downstream run where the design-analysis is conducted as a co-design (the human shapes the component/responsibility map + a flow before options; the design method is discussed) and per-lens diagrams surface in-band (re-confirming SC-022). The behavioral acceptance gate (needs maintainer) | SC-024, FR-037 | US-CD | 2 | Planner | specs/141-design-gate-runtime-hardening/** | done | claude | 2 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 18/20. |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Concurrency Rationale

- T001 (the co-design conduct) and T002 (surfacing) are both prompt-rule edits in `specrew-start.ps1` —
  serialized to avoid here-string churn. T003 (lens data) and T004 (the gate floor) are independent of the
  conduct and of each other. T005 (tests) follows T004. T006 (the dogfood) is the human-run acceptance gate.
  Serial baseline team.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Design via the gate; Option B recorded (decision 1beb17ff). |
| Implementation | 12 | T001 conduct (4) + T002 surfacing (2) + T003 lens data (2) + T004 gate floor (4). |
| Review | 6 | T005 tests (4) + T006 the co-design dogfood (2). |
| Rework | 0 | Buffer via the 18/20 headroom. |

## Traceability Summary

- Iteration 9 scope: FR-034 (phase-framing), FR-035 (design-method discussion), FR-036 (co-design at
  design-analysis), FR-037 (in-band surfacing); SC-024 (dogfood), SC-025 (floor).
- Design-analysis: completed via the gate; Option B; decision `1beb17ff`, draft `abfe785e`.
- FR mapping: FR-034->T001; FR-035->T003; FR-036->T001/T004; FR-037->T002; SC-025->T004/T005; SC-024->T006.

## Notes

- **The value is the co-design experience**, and the collaboration *quality* is behavioral — T006's runtime
  dogfood, not T005's unit tests, is the acceptance evidence (SC-024; the i6/i7/i8 lesson, third time). The
  floor (SC-025) only records that co-design happened — it cannot judge whether it was genuine.
- Marker-gated + grandfather-safe: the co-design floor fires ONLY for artifacts that opt in via `co_design`
  in `lens-applicability.json`; iterations 1-8, Feature 140, and the testLenses4 run carry no marker and
  no-op. Iteration 9's own design-analysis is pre-A6 (no marker) — the floor no-ops on it.
- `index.yml` stays pure (the design-method is a decision point inside the architecture-core lens *file*, not
  a catalog-index field); helpers stay LLM/network-free; no release/push while 141 is in progress; the
  deferred Proposal 156 scope stays out.
- Stops at before-implement for the go-ahead; the maintainer's "Continue, fix all, as much time as it take"
  authorizes the build through to the dogfood handoff.
