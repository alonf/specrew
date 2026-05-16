# Review: Iteration 001

**Schema**: v1  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-15  
**Implementation Ref**: bounded repairs `R-018-V1` and `R-018-V2` on the Feature 018 iteration 001 review tree  
**Overall Verdict**: accepted  
**Explicit Reviewer Verdict**: accepted  
**Review Boundary**: This artifact records review-verdict-signoff only. Retro-boundary, iteration-closeout, and feature-closeout remain unopened.

---

## Verdict

**ACCEPTED** — Feature `018`, velocity dashboard visual richness, iteration `001`, is signed off at
review-verdict-signoff after absorbing `R-018-V1` and `R-018-V2`. Alon Fliess directly confirmed from a fresh
PowerShell terminal that rich-mode rendering now appears live after `R-018-V2`, and the only remaining observation
is a deferred cosmetic roadmap phase marker uniformity follow-up that does not reopen acceptance.

---

## Repair Items Absorbed

- `R-018-V1` fixed in `scripts\internal\dashboard-renderer.ps1` by rendering Recent Shipped entries with a
  combined label (`F-017 · iter-001`) instead of feature-only text.
- Supporting regression coverage now asserts label uniqueness for repeated-feature shipped history and updates
  the rich / monochrome expected dashboard contracts accordingly.
- `R-018-V2a` removes the unreliable `[Console]::IsOutputRedirected` eligibility branch from
  `scripts\internal\dashboard-renderer.ps1`, so fallback diagnostics no longer blame redirected output during
  fresh-terminal review runs.
- `R-018-V2b` adds auto-UTF-8 priming with restore-on-exit at the top of `scripts\specrew-where.ps1` whenever
  rich mode is still allowed, so the live entrypoint can re-evaluate terminal eligibility truthfully without
  requiring manual `chcp` / encoding setup.
- `R-018-V2c` keeps fallback messaging bounded to truthful reasons only; the misleading IsOutputRedirected-based
  fallback branch and warning text are gone.
- Human direct-terminal verification by Alon Fliess confirmed that `.\scripts\specrew.ps1 where` now shows the
  expected rich presentation (`█/░`, ANSI emphasis, `✓/◐/○`, `→`, sparkline) in a fresh PowerShell session with
  no manual `chcp` / encoding setup after `R-018-V2`.
- Deferred, non-blocking cosmetic observation: roadmap phase status markers should be normalized for richer visual
  uniformity in a future polish pass; current roadmap meaning and acceptance criteria remain satisfied.

---

## Validation Evidence

1. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\feature-017-dashboard.tests.ps1`
2. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\feature-018-dashboard.tests.ps1`
3. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\feature-017-dashboard-core.ps1`
4. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\feature-018-rich-dashboard.ps1`
5. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\feature-018-render-budget.ps1`
6. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`
7. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\specrew.ps1 where --no-color` now renders unique Recent Shipped labels on the live repository.
8. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\feature-018-dashboard.tests.ps1` now also proves redirected output alone no longer forces fallback.
9. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\feature-018-rich-dashboard.ps1` now also proves `scripts\specrew-where.ps1` auto-primes UTF-8 from a non-UTF-8 console and restores the caller encoding afterward.
10. ✅ Human direct-terminal verification by Alon Fliess confirmed fresh-terminal rich-mode rendering after `R-018-V2` without manual encoding setup.

---

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| --- | --- | --- | --- |
| I1-01 | FR-016, FR-017, FR-018, TG-004 | pass | Quality artifacts and fixture roots stayed intact through the repair-only signoff pass. |
| I1-02 | FR-001, FR-004, FR-005, FR-008, FR-019 | pass | Shared CLI/rendering policy still routes through the same dashboard renderer after `R-018-V1`. |
| I1-03 | FR-004, FR-006..FR-014, FR-016 | pass | Rich-mode Recent Shipped rows now preserve unique per-iteration labels without widening the rendering scope. |
| I1-04 | FR-001, FR-004, FR-005, FR-007, FR-008, FR-009, FR-010, FR-014, FR-017, TG-004 | pass | Monochrome-safe fallback and artifact-safe rendering keep the same combined labels, preserving parity. |
| I1-05 | FR-015, FR-016, FR-017, FR-018, FR-019, FR-020 | pass | Regression, docs, and render-budget evidence reran green, and live `specrew where --no-color` no longer emits duplicate Recent Shipped labels. |
| I1-06 | FR-001, FR-002, FR-003, FR-015, FR-016, FR-017, FR-018, TG-004 | pass | Validator-facing review/plan/state/hardening-gate surfaces now align truthfully at accepted pre-retro review-verdict-signoff. |
| R-018-V1 | Recent Shipped label uniqueness / Feature 017 per-iteration granularity | pass | Recent Shipped rows now render combined feature-and-iteration labels (`F-017 · iter-001`, `F-017 · iter-002`) across live rich and monochrome dashboard surfaces, and regression coverage locks the fix in. |
| R-018-V2 | Direct-terminal rich-mode eligibility / visual parity confirmation | pass | `dashboard-renderer.ps1` no longer uses the misleading IsOutputRedirected fallback branch, `specrew-where.ps1` now auto-primes UTF-8 with restore-on-exit, automated replay proves the direct entrypoint can stay rich from a non-UTF-8 console, and Alon Fliess confirmed the live fresh-terminal rich surface directly. |

---

## Gap Ledger

- fixed-now — `R-018-V1` removed duplicate Recent Shipped labels while preserving per-iteration granularity.
- fixed-now — `R-018-V2a` / `R-018-V2b` / `R-018-V2c` removed the misleading IsOutputRedirected fallback branch, restored truthful diagnostics, and added auto-UTF-8 priming with restore-on-exit for the live entrypoint.
- deferred-cosmetic — `roadmap-phase-status-marker-uniformity` remains a future polish target; roadmap status meaning is already correct, so the observation is logged in `.specrew\quality\known-traps.md`, canonically deferred in `.squad\decisions.md`, and does not reopen acceptance.

---

## Next Action

Request explicit retro-boundary authorization before any retrospective work begins. Do **not** open retro-boundary,
iteration-closeout, or feature-closeout from this accepted review-verdict-signoff alone.

---

**Review-Verdict-Signoff Ref**: This artifact records an accepted review-verdict-signoff pass. Retro-boundary,
iteration-closeout, and feature-closeout remain separate future lifecycle steps.
