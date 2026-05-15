# Review: Iteration 001

**Schema**: v1  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-15  
**Implementation Ref**: review-verdict-signoff boundary commit for repair `R-018-V1`  
**Overall Verdict**: needs-rework  
**Explicit Reviewer Verdict**: needs-rework  
**Review Boundary**: This artifact records review-verdict-signoff only. Retro-boundary, iteration-closeout, and feature-closeout remain unopened.

---

## Verdict

**NEEDS REWORK** — Review-verdict-signoff absorbed repair `R-018-V1`, but the required direct-terminal rich-mode
inspection surfaced an additional blocker before signoff could close. The new blocker is that a live PowerShell
terminal run still rendered `monochrome-safe fallback` instead of the expected rich presentation, so the boundary
must stop pending a bounded follow-up repair.

---

## Repair Disposition

- `R-018-V1` fixed in `scripts\internal\dashboard-renderer.ps1` by rendering Recent Shipped entries with a
  combined label (`F-017 · iter-001`) instead of feature-only text.
- Supporting regression coverage now asserts label uniqueness for repeated-feature shipped history and updates
  the rich / monochrome expected dashboard contracts accordingly.
- **New blocker discovered during signoff inspection**: the required direct terminal run still rendered
  `monochrome-safe fallback`, so the rich-mode acceptance check for Unicode block bars, ANSI emphasis, semantic
  status markers, active-feature arrow, and sparkline did not pass.

---

## Validation Evidence

1. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\feature-017-dashboard.tests.ps1`
2. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\feature-018-dashboard.tests.ps1`
3. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\feature-017-dashboard-core.ps1`
4. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\feature-018-rich-dashboard.ps1`
5. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\feature-018-render-budget.ps1`
6. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`
7. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\specrew.ps1 where --no-color` now renders unique Recent Shipped labels on the live repository.

---

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| --- | --- | --- | --- |
| I1-01 | FR-016, FR-017, FR-018, TG-004 | pass | Quality artifacts and fixture roots stayed intact through the repair-only signoff pass. |
| I1-02 | FR-001, FR-004, FR-005, FR-008, FR-019 | pass | Shared CLI/rendering policy still routes through the same dashboard renderer after `R-018-V1`. |
| I1-03 | FR-004, FR-006..FR-014, FR-016 | pass | Rich-mode Recent Shipped rows now preserve unique per-iteration labels without widening the rendering scope. |
| I1-04 | FR-001, FR-004, FR-005, FR-007, FR-008, FR-009, FR-010, FR-014, FR-017, TG-004 | pass | Monochrome-safe fallback and artifact-safe rendering keep the same combined labels, preserving parity. |
| I1-05 | FR-015, FR-016, FR-017, FR-018, FR-019, FR-020 | pass | Regression, docs, and render-budget evidence reran green, and live `specrew where --no-color` no longer emits duplicate Recent Shipped labels. |
| I1-06 | FR-001, FR-002, FR-003, FR-015, FR-016, FR-017, FR-018, TG-004 | pass | Validator-facing review/plan/state/hardening-gate surfaces now align truthfully at review-verdict-signoff. |
| R-018-V1 | Recent Shipped label uniqueness / Feature 017 per-iteration granularity | pass | Recent Shipped rows now render combined feature-and-iteration labels (`F-017 · iter-001`, `F-017 · iter-002`) across live rich and monochrome dashboard surfaces, and regression coverage locks the fix in. |
| R-018-V2 | Direct-terminal rich-mode eligibility / visual parity confirmation | needs-rework | A direct `specrew where` terminal run still rendered `monochrome-safe fallback`, so `█/░`, ANSI color emphasis, `✓/◐/○`, `→`, and the velocity sparkline did not appear for the required signoff inspection. |

---

## Gap Ledger

- fixed-now — `R-018-V1` removed duplicate Recent Shipped labels while preserving per-iteration granularity.
- needs-rework — `R-018-V2` direct-terminal rich-mode rendering remains blocked because signoff inspection still
  hit monochrome fallback in a live PowerShell session.

---

## Next Action

Request explicit bounded repair authorization for `R-018-V2` before re-running review-verdict-signoff. Do **not**
advance to retro, iteration-closeout, or feature-closeout from this blocked review state.

---

**Review-Verdict-Signoff Ref**: This artifact records a blocked review-verdict-signoff pass. Retro-boundary,
iteration-closeout, and feature-closeout remain separate future lifecycle steps.
