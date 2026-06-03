# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 10/20 story_points
**Started**: 2026-06-03
**Completed**:

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity format `<consumed>/<cap> <unit>` with no trailing prose. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

Greenfield / downstream hygiene — the remaining two smoke-bundle defects (FR-015 keeps them in
this feature). FR-012 (US5): a freshly bootstrapped greenfield project and a downstream project
MUST NOT surface spurious governance/runtime warnings that do not apply to them (e.g. multi-developer
collision, version-mismatch against a placeholder `0.0.0`, PSGallery update noise). FR-013 (US6): a
fresh greenfield project's baseline commit MUST be established and resolved to a real commit hash,
recorded consistently across `start-context.json` and boundary state. This is a **bug-fix / hardening
slice** (defect repair, no architectural fork) — the design-analysis gate is not required.
Reproduce-first per defect. Capacity 10/20, within cap.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-012 | Greenfield/downstream projects emit no spurious governance/runtime warnings outside their genuinely-actionable set | US5 |
| FR-013 | Fresh greenfield baseline commit resolves to a real hash, recorded consistently across start context + boundary state | US6 |
| FR-015 | The smoke-bundle defects (FR-011..FR-014) stay within Feature 141 (FR-011/FR-014 shipped iter 2; FR-012/FR-013 close here) | US0 |
| SC-008 | Greenfield + downstream emit no spurious warnings (test) | US5 |
| SC-009 | Fresh greenfield baseline commit resolves to a real hash + consistent recording (test) | US6 |
| TG-006 | Review classifies each behavior implemented/enforced/observable/documented + gap ledger | US0 |

Carried out of Iteration 3: FR-009/FR-010 (Proposal 156 Applicable Lenses) remain a deferred lens slice.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Confirm scope; reproduce spurious greenfield/downstream warnings (FR-012) and the fresh-greenfield baseline-commit defect (FR-013) in fixtures; record in drift-log | FR-012, FR-013, FR-015 | US0 | 1 | Spec Steward | specs/141-design-gate-runtime-hardening/** | planned | claude | — | — |
| T002 | Suppress spurious greenfield/downstream warnings: gate the multi-developer-collision, version-mismatch (placeholder version), and PSGallery/runtime warnings on genuine applicability so a freshly bootstrapped/downstream project emits none outside its actionable set | FR-012 | US5 | 3 | Implementer | scripts/internal/auto-detection.ps1, scripts/internal/version-check.ps1, scripts/specrew-start.ps1 | planned | claude | — | — |
| T003 | Fix fresh-greenfield baseline commit handling: establish + resolve the baseline to a real commit hash and record it consistently across start-context.json and boundary state (no missing/placeholder baseline) | FR-013 | US6 | 3 | Implementer | scripts/specrew-init.ps1, scripts/specrew-start.ps1, scripts/internal/sync-boundary-state.ps1 | planned | claude | — | — |
| T004 | Tests (reproduce-first): greenfield/downstream warning scope (SC-008) and fresh-greenfield baseline-commit resolution + cross-file consistency (SC-009) | SC-008, SC-009 | US5, US6 | 2 | Reviewer | tests/unit/**, tests/integration/** | planned | claude | — | — |
| T005 | Docs + review evidence (TG-006): quickstart/contract notes for greenfield/downstream warning scope + baseline-commit behavior; record the implemented/enforced/observable/documented gap ledger | TG-006 | US0 | 1 | Planner | specs/141-design-gate-runtime-hardening/** | planned | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 10/20 — comfortable headroom for unplanned-discovery buffer. |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Concurrency Rationale

- T002 (warning suppression) edits `auto-detection.ps1` + `version-check.ps1`; T003 (baseline commit) edits `specrew-init.ps1` + `sync-boundary-state.ps1`. Both touch `scripts/specrew-start.ps1` — sequence those edits to avoid conflicts. Serial baseline team; no Junior/Senior expansion justified for a small-fix slice.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | T001 scope + reproduction (greenfield/downstream warnings + baseline commit). |
| Implementation | 6 | T002 warning suppression (3), T003 baseline-commit fix (3). |
| Review | 3 | T004 SC-008/SC-009 tests (2), T005 docs/review evidence (1). |
| Rework | 0 | Buffer within the remaining 10 SP headroom. |

## Traceability Summary

- Iteration 3 scope: FR-012, FR-013, FR-015; SC-008, SC-009; TG-006.
- Design-analysis: not required (bug-fix / hardening slice; defect repair, no architectural fork).
- Estimate is 10 SP: FR-012 suppression (3) + FR-013 baseline (3) + reproduction (1) + tests (2) + docs (1). Within the 20 cap.
- Run specrew-traceability-check after the task table to confirm every FR/SC maps to a task and back.

## Notes

- Reproduction first (T001): the FR-012 spurious warnings + FR-013 baseline-commit defect reproduce in a fresh `specrew init` + `specrew start` greenfield fixture (and a downstream fixture for FR-012); reproduce before fixing so each test proves the fix.
- The `recorded_at` ISO->`MM/dd/yyyy` coercion remains a deferred follow-up; fold it in ONLY if the FR-013 start-context/baseline regeneration work directly touches that serialization path.
- This iteration writes code; it will stop at before-implement for the human start-implementation go-ahead, as usual.
