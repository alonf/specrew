# Review: Iteration 001

**Schema**: v1  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-15  
**Implementation Ref**: bounded repair `R-018-V2` implementation boundary commit (review acceptance still pending human terminal confirmation)  
**Overall Verdict**: needs-rework  
**Explicit Reviewer Verdict**: needs-rework  
**Review Boundary**: This artifact records review-verdict-signoff only. Retro-boundary, iteration-closeout, and feature-closeout remain unopened.

---

## Verdict

**NEEDS REWORK** — Bounded repair `R-018-V2` is now implemented and the automated dashboard lane is green again,
but review-verdict-signoff still cannot close because the required human terminal confirmation has not happened yet.
The branch must stop here until a human runs `.\scripts\specrew.ps1 where` in a fresh PowerShell terminal with no
manual `chcp` / encoding setup and confirms that rich rendering appears live.

---

## Repair Disposition

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
- **Remaining blocker before acceptance**: a human still must confirm the live terminal now shows the expected
  rich presentation (`█/░`, ANSI emphasis, `✓/◐/○`, `→`, sparkline) in a fresh PowerShell session.

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

---

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| --- | --- | --- | --- |
| I1-01 | FR-016, FR-017, FR-018, TG-004 | pass | Quality artifacts and fixture roots stayed intact through the repair-only signoff pass. |
| I1-02 | FR-001, FR-004, FR-005, FR-008, FR-019 | pass | Shared CLI/rendering policy still routes through the same dashboard renderer after `R-018-V1`. |
| I1-03 | FR-004, FR-006..FR-014, FR-016 | pass | Rich-mode Recent Shipped rows now preserve unique per-iteration labels without widening the rendering scope. |
| I1-04 | FR-001, FR-004, FR-005, FR-007, FR-008, FR-009, FR-010, FR-014, FR-017, TG-004 | pass | Monochrome-safe fallback and artifact-safe rendering keep the same combined labels, preserving parity. |
| I1-05 | FR-015, FR-016, FR-017, FR-018, FR-019, FR-020 | pass | Regression, docs, and render-budget evidence reran green, and live `specrew where --no-color` no longer emits duplicate Recent Shipped labels. |
| I1-06 | FR-001, FR-002, FR-003, FR-015, FR-016, FR-017, FR-018, TG-004 | pass | Validator-facing review/plan/state/hardening-gate surfaces now align truthfully at repaired-but-pending-human-confirmation review-verdict-signoff. |
| R-018-V1 | Recent Shipped label uniqueness / Feature 017 per-iteration granularity | pass | Recent Shipped rows now render combined feature-and-iteration labels (`F-017 · iter-001`, `F-017 · iter-002`) across live rich and monochrome dashboard surfaces, and regression coverage locks the fix in. |
| R-018-V2 | Direct-terminal rich-mode eligibility / visual parity confirmation | implemented-pending-human-confirmation | `dashboard-renderer.ps1` no longer uses the misleading IsOutputRedirected fallback branch, `specrew-where.ps1` now auto-primes UTF-8 with restore-on-exit, and automated replay proves the direct entrypoint can stay rich from a non-UTF-8 console; acceptance still waits on a human fresh-terminal confirmation run. |

---

## Gap Ledger

- fixed-now — `R-018-V1` removed duplicate Recent Shipped labels while preserving per-iteration granularity.
- fixed-now — `R-018-V2a` / `R-018-V2b` / `R-018-V2c` removed the misleading IsOutputRedirected fallback branch,
  restored truthful diagnostics, and added auto-UTF-8 priming with restore-on-exit for the live entrypoint.
- blocked-by-human-confirmation — review acceptance still waits on a human fresh-terminal check of
  `.\scripts\specrew.ps1 where` with no manual `chcp` / encoding setup.

---

## Next Action

Human reviewer must now run `.\scripts\specrew.ps1 where` in a fresh PowerShell terminal with no manual `chcp` /
encoding setup and confirm rich rendering. Do **not** mark this review accepted, open retro, or advance to
iteration-closeout / feature-closeout until that manual confirmation is recorded.

---

**Review-Verdict-Signoff Ref**: This artifact records a blocked review-verdict-signoff pass. Retro-boundary,
iteration-closeout, and feature-closeout remain separate future lifecycle steps.
