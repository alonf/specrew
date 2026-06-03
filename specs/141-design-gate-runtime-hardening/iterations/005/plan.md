# Iteration Plan: 005

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: reviewing
**Capacity**: 17/20 story_points
**Started**: 2026-06-03

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity format `<consumed>/<cap> <unit>` with no trailing prose. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

The complete, state-of-the-art lens package (Amendment A2, **Option B**): make the design analysis
genuinely **lens-informed** (FR-009 — each selected lens's Design Decision Points feed the option
comparison itself, not a list of names) and **gate-enforced** (FR-026 — the pre-plan gate blocks
`plan.md` when a selected lens is unaddressed). The gate is a **deterministic, LLM/network-free
anti-omission backstop** — it guarantees no selected lens is silently omitted, *not* that engagement
is genuine. Genuine engagement is enforced by the human design-analysis gate plus a **blocking
delete-the-`Addressed:`-lines discriminator** at review-signoff. Grandfather-safe via an EXPLICIT
`fr026_grandfathered` marker (enforce-by-default): a pre-FR-026 questionnaire carries the marker to
stay exempt (Iteration 4 does), so deleting all `Addressed:` entries from an FR-026-era artifact
still FAILS rather than no-ops. Carried constraints: `index.yml` stays pure (gating map in the
sibling file); no deferred Proposal 156 deep automation (lens-file schema validation, standalone
command, auto-rationale, overrides); no release/Unix/wrapper surfaces; no push/PR while 141 is open.
Capacity 17/20, within cap.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-009 | Surface each selected lens's Design Decision Points so the option comparison is genuinely informed (not a name list) | US3 |
| FR-026 | Pre-plan gate enforces lens coverage: each selected lens needs a non-placeholder `Addressed:` entry, else block `plan` naming it; deterministic, LLM/network-free, anti-omission; grandfather-safe | US3 |
| FR-010 | Keep scope bounded: extractor + enriched render + coverage gate only; no schema-validation enforcement / standalone command / auto-rationale / overrides | US3 |
| SC-016 | Unaddressed selected lens FAILS the pre-plan gate (names it); all-addressed PASSES; placeholder entry FAILS; deterministic | US3 |
| TG-006 | Review classifies each behavior implemented/enforced/observable/documented + gap ledger; the delete-`Addressed:` discriminator is a blocking review step | US0 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | `Get-SpecrewLensDecisionPoints` — pure function extracting a lens file's `## Design Decision Points` bullets (graceful `@()` when the file/section is absent); no network/LLM | FR-009 | US3 | 3 | Implementer | scripts/internal/lens-applicability.ps1 | done | claude | — | — |
| T002 | Enrich `Format-SpecrewApplicableLensesSection`: render per selected lens its decision points + a non-placeholder `Addressed:` pointer entry; keep graceful degradation ("none available") + MD049 asterisk emphasis | FR-009, SC-006 | US3 | 3 | Implementer | scripts/internal/lens-applicability.ps1 | done | claude | — | — |
| T003 | FR-026 gate: `Test-SpecrewDesignAnalysisLensCoverage` reads `lens-applicability.json` `selected` + the artifact's Applicable Lenses `Addressed:` entries; each selected lens needs a non-placeholder entry, else error naming it. Wire into `Test-SpecrewDesignAnalysisArtifact`. Grandfather-safe (only FR-026-shaped artifacts); deterministic, LLM/network-free; honest "anti-omission" message | FR-026, FR-010 | US3 | 4 | Implementer | scripts/internal/design-analysis-gate.ps1 | done | claude | — | — |
| T004 | Coordinator nudge in the template: instruct that each selected lens's decision points must shape the option Trade-offs and the `Addressed:` entry must point into the option comparison (engagement in the options, not a checklist) | FR-009 | US3 | 1 | Spec Steward | extensions/specrew-speckit/templates/design-analysis.template.md | done | claude | — | — |
| T005 | Tests (reproduce-first): extraction present/absent/malformed; enriched render + graceful degradation + MD049 guard; FR-026 — SC-016 unaddressed-lens FAILS naming it, all-addressed PASSES, placeholder FAILS, no-json/no-lenses no-ops, explicit-marker grandfather (PASS) + bypass-closed (no marker + no `Addressed:` → FAIL), determinism | FR-026, SC-016, SC-006 | US3 | 4 | Reviewer | tests/unit/**, tests/integration/** | done | claude | — | — |
| T006 | Docs + dogfood + gap ledger (TG-006): quickstart Iteration-5 section; re-dogfood — the enriched render reproduces Iteration 5's own hand-authored Applicable Lenses section; apply the **blocking** delete-`Addressed:` discriminator; implemented/enforced/observable/documented gap ledger | TG-006, FR-009 | US0 | 2 | Planner | specs/141-design-gate-runtime-hardening/** | done | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 17/20 — headroom for the gate-wiring + grandfather-edge unplanned-discovery buffer. |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Concurrency Rationale

- T001 (extractor) is the root; T002 (enriched render) depends on T001; T003 (FR-026 gate) depends on
  the `Addressed:` contract T002 emits; T004 (template nudge) can proceed in parallel with T001–T003;
  T005 (tests) follows T001–T003; T006 (docs/dogfood) last. Serial baseline team; no Junior/Senior
  expansion for a ~17 SP slice. T002 and T004 both touch the render/template seam — sequence those edits.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Design-analysis gate completed (Option B, decision commit `0e758032`). |
| Implementation | 11 | T001 extractor (3) + T002 enriched render (3) + T003 FR-026 gate (4) + T004 template nudge (1). |
| Review | 6 | T005 tests (4) + T006 docs/dogfood/gap-ledger (2). |
| Rework | 0 | Buffer within the 17/20 headroom. |

## Traceability Summary

- Iteration 5 scope: FR-009, FR-010, FR-026; SC-006, SC-016; TG-006.
- Design-analysis: **completed** — gate passed (Valid=true), maintainer-selected **Option B**; decision
  commit `0e758032`, draft `d83082e2`. The selected option is authoritative plan input (FR-007).
- FR mapping: FR-009→T001/T002/T004; FR-010→T003 (bounded scope, deep automation deferred); FR-026→T003;
  SC-006→T002/T005; SC-016→T003/T005; TG-006→T006.
- Run specrew-traceability-check after the task table to confirm every FR/SC maps to a task and back.

## Notes

- **The value lives in the analysis, not the gate.** FR-026 is an honest anti-omission backstop;
  it cannot judge engagement quality. The acceptance criterion that *proves* the value (FR-009's
  intent) is the delete-the-`Addressed:`-lines discriminator at review-signoff (T006), which is a
  **blocking** step: if removing the coverage entries leaves the option comparison still visibly
  shaped by the lenses, engagement is real; if the analysis goes blank, the iteration is sent back
  to itself.
- **Grandfather-safe via an EXPLICIT marker** (T003): enforcement is the default; a pre-FR-026
  questionnaire carries `fr026_grandfathered: true` to be exempt (Iteration 4 does). Grandfathering
  is never inferred from missing `Addressed:` entries, so deleting them from an FR-026-era artifact
  FAILS rather than no-ops (the Proposal 145 Phase 5 gate-completeness fix). Mirrors the Proposal 144
  grandfather discipline.
- Reproduction/determinism first (T005): the extractor, render, and coverage check are pure
  functions, so SC-016 (unaddressed FAILS, all-addressed PASSES, placeholder FAILS) is a
  deterministic unit test, not a file-presence check.
- Decoupled discipline: the gating map stays a **sibling file**; `index.yml` is NOT modified.
  Deferred Proposal 156 deep automation (schema-validation enforcement, standalone command,
  auto-rationale, overrides) stays out (FR-010).
- This iteration writes code; it stops at before-implement for the human start-implementation
  go-ahead. No push/PR while Feature 141 is in progress.
