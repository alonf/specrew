# Iteration Plan: 007

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 19/20 story_points
**Started**: 2026-06-04

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity format `<consumed>/<cap> <unit>`. Task Status one of planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

The lens intake becomes a **per-lens facilitated design workshop** (Amendment A4, Option B): the AI
**infers** applicability (human confirms — no obvious yes/no), then for each applicable lens acts as
**workshop coordinator** — raising that lens's design questions (from its decision points), capturing
the human's decisions and explicit agreement, adapting depth to the expertise dial, and iterating
**until the human says "move on"** before the next lens; right-sized, not a fixed nine-lens marathon.
**Honest scope:** the workshop *conduct* is behavioral (prompt-driven) — the FR-026 gate cannot enforce
its quality, so SC-020 is validated by a **runtime dogfood**; the deterministic floor (SC-021) only
requires a non-placeholder per-lens record. Builds on the Iteration 4-6 engine (selector, decision-point
extractor, dial→depth, coverage gate); the architecture book informs question phrasing only — no new
parallel question bank; `index.yml` stays pure. Carries FR-009 (the decision-point flow, from i006).

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-025 | Per-lens facilitated workshop: infer-then-confirm applicability; per-lens discussion from decision points; depth-adapted; iterate until "move on"; right-sized | US3 |
| FR-009 | Selected lenses' decision points drive the per-lens discussion and the recorded decisions inform requirements/clarify/plan (carried from i006) | US3 |
| FR-026 / SC-021 | Coverage gate requires a non-placeholder per-lens record (agenda + decision/agreement + depth + "move on" marker) per selected lens; presence only, not quality | US3 |
| SC-020 | Workshop conduct is exercised in a real downstream run (behavioral; runtime-dogfood-validated, not unit-only) | US0 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Discussable-prompt (agenda) generator: turn each selected lens's `## Design Decision Points` (Get-SpecrewLensDecisionPoints) into the per-lens discussion agenda the coordinator raises; book-informed phrasing baked into the lens `.md` decision points (no parallel bank; index.yml pure). Pure, deterministic | FR-009, FR-025 | US3 | 4 | Implementer | scripts/internal/lens-applicability.ps1, extensions/specrew-speckit/knowledge/design-lenses/** | planned | claude | — | — |
| T002 | Per-lens decision schema + SC-021 gate: extend `lens-applicability.json` with a per-lens record (agenda, decision/agreement summary, depth used, explicit "move on" marker); extend the FR-026 coverage gate to require a NON-PLACEHOLDER per-lens record for each selected lens (presence only — never quality); names the lens on failure | FR-026 | US3 | 4 | Implementer | scripts/internal/design-analysis-gate.ps1, scripts/internal/lens-applicability.ps1 | planned | claude | — | — |
| T003 | Workshop conduct prompt rule: rewrite the lens-intake lifecycle rule so the Crew infers applicability + asks the human only to confirm/adjust (no obvious yes/no), then per applicable lens raises the agenda, captures decisions + explicit agreement, adapts depth (Get-SpecrewLensQuestionDepth), and advances only on "move on"; right-sized. Behavioral | FR-025 | US3 | 3 | Spec Steward | scripts/specrew-start.ps1, scripts/internal/** | planned | claude | — | — |
| T004 | FR-009 per-phase flow (carried from i006): the recorded per-lens decisions inform specify (requirements), clarify, and plan — the workshop output is consumed downstream, not only in design-analysis | FR-009 | US3 | 2 | Implementer | scripts/specrew-start.ps1, scripts/internal/lens-applicability.ps1 | planned | claude | — | — |
| T005 | Tests (reproduce-first, the deterministic floor): agenda generated from decision points; per-lens schema fields; SC-021 gate FAILs + names the lens when any per-lens record is missing/placeholder; back-compat (grandfather). NOT a proof of conduct quality | FR-026, SC-021, FR-009 | US3 | 4 | Reviewer | tests/unit/**, tests/integration/** | planned | claude | — | — |
| T006 | Docs + the MANDATORY runtime dogfood (SC-020): a real downstream `specrew start --host claude` run where the Crew facilitates the workshop lens by lens (infer→confirm→per-lens discussion→"move on"), evidence recorded; TG ledger | SC-020 | US0 | 2 | Planner | specs/141-design-gate-runtime-hardening/** | planned | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 19/20 — tight; T004 (FR-009 flow) splits to a follow-up if T003 overruns. |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Concurrency Rationale

- T001 (agenda generator) is the root; T002 (schema + SC-021 gate) consumes the per-lens record shape;
  T003 (conduct prompt rule) depends on T001's agenda + the retained dial→depth helper; T004 (FR-009
  flow) depends on T003. T005 (tests) follows the code; T006 (docs + the mandatory dogfood) last.
  Serial baseline team.
- **Contingency (cap discipline):** if T003 (the prompt rule — the riskiest, behavioral surface)
  overruns, T004 (FR-009 flow) splits to a follow-up so the workshop conduct + the deterministic floor
  (T001/T002/T005) ship within cap.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Design-analysis gate (Option B + 5 maintainer instructions, decision commit `57974536`). |
| Implementation | 13 | T001 agenda (4) + T002 schema/gate (4) + T003 prompt rule (3) + T004 flow (2). |
| Review | 6 | T005 tests (4) + T006 docs + the mandatory runtime dogfood (2). |
| Rework | 0 | Buffer via the contingency split, not headroom. |

## Traceability Summary

- Iteration 7 scope: FR-025 (workshop conduct), FR-009 (decision-point flow, carried from i006), FR-026/SC-021 (per-lens decision floor), SC-020 (runtime dogfood).
- Design-analysis: **completed** — gate passed; maintainer-selected **Option B**; decision commit `57974536`, draft `ad7bea7e`. Authoritative plan input (FR-007).
- FR mapping: FR-025→T001/T003; FR-009→T001/T004; FR-026/SC-021→T002/T005; SC-020→T006. Run specrew-traceability-check after the task table.

## Maintainer instructions (binding acceptance criteria — from the design-analysis verdict)

Carried verbatim from the Option B verdict; binding on this iteration:

1. **006 closeout clean before planning** — SATISFIED (validator PASS for i006; T003 carried here).
2. **Boundary packet shape** — every boundary stop is the canonical six-section human re-entry packet (Rule 46), not ad-hoc prose. The before-implement stop uses it.
3. **SC-021 precise** — the per-lens record captures agenda + decision/agreement + depth + "move on" marker; the gate enforces non-placeholder PRESENCE only (T002). It never claims to prove quality.
4. **Runtime dogfood is mandatory acceptance evidence (SC-020)** — review MUST require a real downstream workshop run (T006); unit tests (T005) cover the deterministic floor only and are NOT sufficient acceptance.
5. **Dogfood FR-028** — persisted `.md` artifacts use markdown links; console packets use visible `file:///` URLs. Plan + review hold the line (this plan uses a markdown-link Spec reference).

## Notes

- **The value is the workshop experience**, and it is behavioral. T006's runtime dogfood — not T005's
  unit tests — is the acceptance evidence (Iteration 6's retro lesson; instruction #4).
- Engine retained (selector, decision-point extractor, dial→depth, coverage gate); deferred Proposal 156
  deep automation stays out (FR-010); `index.yml` stays pure; no release/Unix/wrapper surfaces; no
  push/PR while Feature 141 is in progress.
- This iteration writes code + a prompt rule; it stops at before-implement for the go-ahead (Rule 46 packet).
