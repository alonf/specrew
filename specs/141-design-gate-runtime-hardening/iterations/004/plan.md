# Iteration Plan: 004

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 14/20 story_points
**Started**: 2026-06-03
**Completed**: 2026-06-03

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity format `<consumed>/<cap> <unit>` with no trailing prose. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

Applicable-Lenses, questionnaire-driven (FR-009/FR-010/FR-025; SC-006/SC-015; TG-006), per
Amendment A1. **Substantive** iteration — the design-analysis gate ran first and the maintainer
selected **Option B (decoupled)**: the question→lens gating map lives in a **separate sibling map
file** beside the Proposal 156 catalog (the catalog `index.yml` stays pure); a fixed applicability
questionnaire is recorded as a `lens-applicability.json` artifact; a **pure, deterministic** selector
maps answers → lenses (foundational lenses always-on; specialized lenses gated by their answer; no
network/LLM). C's standalone command / schema-validation enforcement / rationale automation remain
deferred (FR-010). Capacity 14/20, within cap.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-009 | Render an "Applicable Lenses" section naming the questionnaire-selected lenses (read-only) | US3 |
| FR-010 | Keep scope bounded: decoupled sibling map + selection only; no overrides/schema-enforcement/broad-automation/standalone-command | US3 |
| FR-025 | Fixed applicability questionnaire → `lens-applicability.json` → deterministic question→lens selection (always-on + gated) | US3 |
| SC-006 | Section lists exactly the selected lenses + degrades gracefully when catalog/answers absent (test) | US3 |
| SC-015 | Selection is a deterministic function of the JSON; identical answers → identical set; JSON records the per-lens rationale (test) | US3 |
| TG-006 | Review classifies each behavior implemented/enforced/observable/documented + gap ledger | US0 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Sibling question→lens map file (beside the catalog; `index.yml` UNTOUCHED) + the fixed 6-question set: UI→ui-ux, auth/secrets/PII→security-compliance, persistent-data→data-storage, external-API→integration-api, deploy/release→devops-operations, perf/resilience→observability-resilience; always-on foundational lenses architecture-core/component-design/requirements-nfr | FR-025, FR-010 | US3 | 2 | Spec Steward | extensions/specrew-speckit/knowledge/design-lenses/** | done | claude | — | — |
| T002 | Questionnaire intake + `lens-applicability.json` artifact: extend the design-analysis scaffold to pose the 6 questions (Crew + human confirmation) and write the answers JSON to the iteration dir; define the JSON shape (`{schema, answers, selected}`) | FR-025 | US3 | 3 | Implementer | scripts/internal/design-analysis-gate.ps1, extensions/specrew-speckit/templates/design-analysis.template.md | done | claude | — | — |
| T003 | Pure deterministic selector: read the JSON answers + the sibling map → compute selected = always-on ∪ {gated lens : answer = yes}; no network/LLM; same answers → same set | FR-025, FR-010 | US3 | 3 | Implementer | scripts/internal/design-analysis-gate.ps1 (or scripts/internal/lens-selector.ps1) | done | claude | — | — |
| T004 | Render the "Applicable Lenses" section in `design-analysis.md` from `selected`; degrade gracefully (no catalog/answers → "none available") | FR-009, FR-010, SC-006 | US3 | 2 | Implementer | scripts/internal/design-analysis-gate.ps1, extensions/specrew-speckit/templates/design-analysis.template.md | done | claude | — | — |
| T005 | Tests (reproduce-first): SC-015 determinism (same answers → same set) + JSON audit; SC-006 selection scope + graceful degradation; map-gating correctness; never hide an always-on lens | SC-006, SC-015 | US3 | 3 | Reviewer | tests/unit/**, tests/integration/** | done | claude | — | — |
| T006 | Docs + review evidence (TG-006): quickstart Iteration-4 section (questionnaire + decoupled map + JSON) + the implemented/enforced/observable/documented gap ledger | TG-006 | US0 | 1 | Planner | specs/141-design-gate-runtime-hardening/** | done | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 14/20 — headroom for the new-mechanism unplanned-discovery buffer. |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Concurrency Rationale

- T001 (sibling map file) and T002 (JSON shape + scaffold intake) can proceed largely in parallel.
  T003 (selector) depends on T001's map + T002's JSON shape; T004 (render) depends on T003; T005
  (tests) follows T003/T004; T006 (docs) last. Serial baseline team; no Junior/Senior expansion for
  a ~14 SP slice. Both T002 and T004 touch the scaffold + template — sequence those edits.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Design-analysis gate completed (Option B decoupled, decision commit 51b31aaf). |
| Implementation | 10 | T001 map (2) + T002 intake/JSON (3) + T003 selector (3) + T004 render/degrade (2). |
| Review | 3 | T005 tests (3) + T006 docs/gap-ledger absorbed into review headroom (1). |
| Rework | 0 | Buffer within the 14/20 headroom. |

## Traceability Summary

- Iteration 4 scope: FR-009, FR-010, FR-025; SC-006, SC-015; TG-006.
- Design-analysis: **completed** — gate passed (Valid=true), maintainer-selected **Option B (decoupled)**;
  decision commit `51b31aaf`, draft `fb4b31e0`. The selected option is authoritative plan input (FR-007).
- FR mapping: FR-009→T004; FR-010→T001/T003 (decoupled scope, deep automation deferred); FR-025→T001/T002/T003;
  SC-006→T004/T005; SC-015→T003/T005; TG-006→T006.
- Run specrew-traceability-check after the task table to confirm every FR/SC maps to a task and back.

## Notes

- Reproduction/determinism first (T005): the selector is a pure function, so SC-015 is a deterministic
  unit test (same answers → same set), not a file-presence check.
- Decoupled discipline (Option B decoupled): the gating map is a **sibling file**; the Proposal 156
  catalog `index.yml` is NOT modified. Truly-deep 156 automation (overrides, schema-validation
  enforcement, broad cross-phase automation, standalone `specrew lens` command, per-lens rationale)
  stays deferred (FR-010) — out of scope for this iteration.
- This iteration writes code; it will stop at before-implement for the human start-implementation
  go-ahead, as usual. No push/PR while Feature 141 is in progress.

### Approved-for-tasks (maintainer, 2026-06-03)

Plan approved (14/20 SP split + traceability accepted). Carried design-gate constraints (binding through implementation):

1. **Option B decoupled is authoritative.** The question-to-lens gating map lives in a SEPARATE sibling file; the Proposal 156 catalog `index.yml` stays PURE (not modified).
2. **Selection is deterministic and LLM/network-free.** The JSON-answers-to-selected-lenses step is a pure function; the only judgment input is the recorded questionnaire answers.
3. **Do NOT pull in deferred Proposal 156 scope** — no project-local overrides, no lens-schema validation enforcement, no broad cross-phase automation, no standalone `specrew lens` command, no per-lens rationale automation (FR-010 keeps these deferred).
