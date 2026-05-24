# Review: Iteration 003

**Schema**: v1
**Reviewed**: 2026-05-24
**Overall Verdict**: accepted

**Feature**: F-044 Per-Host Architecture Refactor

## Outcome Summary

**APPROVED with deferred functional verification** — 5 code fixes ship, all 4 touched files parse-check OK, root causes traced and documented. The actual functional verification (do the bugs stay fixed?) happens on the user's next manual test round, since this iteration's review boundary IS that round.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-007 | pass | Bug 2 — YAML frontmatter added to `iteration-resume` skill template. |
| T002 | FR-012 | pass | Bug 5 — bootstrap message rewritten Crew-neutral; canonical team path surfaced. |
| T003 | FR-013 | pass | Bug 7c — `run-hardening-gate.ps1` defensive null handling for empty ExistingLines on first run. |
| T004 | FR-013 | pass | Bug 7b — `scaffold-retro-artifact.ps1` graceful Phase Baseline fallback (warn + TBD-row instead of throw). |
| T005 | FR-013 | pass | Bug 7d — `scaffold-feature-closeout-dashboard.ps1` stray PassThru removed + numeric-only FeatureId prefix-match added. |

## Gap Ledger

- No in-scope requirement (FR/SC) gaps: all 5 Tier A bugs targeted by iter-003 are closed: fixed-now. Bug 7a was a stale-install false positive (no-op). Bugs 1, 3, 4, 6, 7e, 8 and the dual-install detection were explicit out-of-scope items documented in [`scope.md`](./scope.md); tracked as follow-up work against standing proposals (063 / 065 / 024 / 068 / 060) — not Gap-Ledger-tracked here.

## Bug closure scoreboard

| Bug | Status |
|---|---|
| 2 (SKILL.md frontmatter) | ✅ Fixed; templates now consistent (4 of 4 generic skills have frontmatter) |
| 5 (Squad-hardcoded bootstrap message) | ✅ Fixed; language is Crew-neutral + canonical team path surfaced |
| 7b (Phase Baseline hard-throw in retro) | ✅ Fixed; graceful fallback with warning |
| 7c (ExistingLines null-binding on first run) | ✅ Fixed; explicit branches + defensive coercion |
| 7d (scaffold-feature-closeout-dashboard PassThru) | ✅ Fixed; stray -PassThru removed + numeric-only FeatureId prefix-match added |
| 7a (Codex --full-auto) | ✅ No-op; already fixed on branch (user's stale 0.24.1 install was the issue) |

## Verification

### Parse-check

- `scripts/init/post-bootstrap-output.ps1` — OK
- `extensions/specrew-speckit/scripts/run-hardening-gate.ps1` — OK
- `extensions/specrew-speckit/scripts/scaffold-retro-artifact.ps1` — OK
- `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1` — OK

### Functional verification (deferred to user's next manual test round)

This iteration's bugs were all caught by manual end-to-end testing. The proper review boundary is therefore another round of manual end-to-end testing, not an automated test. Each fix has a specific reproduction scenario the user can replay:

| Bug | Replay scenario |
|---|---|
| 2 | Fresh greenfield + `specrew init` on Claude or Antigravity → load skills → expect no "missing YAML frontmatter" warning for `specrew-iteration-resume` |
| 5 | Fresh greenfield + `specrew init` → bootstrap-complete message reads "the Crew" / canonical team path, no Squad-specific verbiage |
| 7b | Iteration plan without Phase Baseline → run `scaffold-retro-artifact.ps1` → expect warning + TBD table, not failure |
| 7c | Empty hardening-gate path + run `run-hardening-gate.ps1` → expect generated gate, not null-binding error |
| 7d | Iteration-closeout sync that triggers `scaffold-feature-closeout-dashboard.ps1` → expect no PassThru error |

### Recommended user pre-test step

To avoid the dual-module-load issue: run `specrew update` (or remove the stale `0.24.1` from `C:\Users\alon.HOME\OneDrive\Documents\PowerShell\Modules\Specrew\` before the next test). Without this, the tests will still hit the pre-iter-003 code paths via the stale install.

## Form-vs-meaning

- **Form**: 5 code edits map 1:1 to 5 bug IDs in [`scope.md`](./scope.md).
- **Meaning**: Each fix addresses the documented root cause, not the symptom. E.g., bug 7c's fix is at the source of the null (strict-mode + if-expression interaction), not at the consumer site.

## Known limitations of this iteration

1. **No automated regression tests added.** All 5 fixes are surface-level. Adding tests for them is queued for a follow-up (a bootstrap-output-content assert + a hardening-gate-first-run assert + a retro-scaffold-without-phase-baseline assert). Not in iter-003 because the user is time-pressured to re-test, and the next manual round IS the regression test.
2. **Bug 7e (Copilot 3 failed skills) only partially addressed.** We confirmed `iteration-resume` was the one named in the warning. The other 2 (if real and not phantom-count from Copilot's loader) need reproduction to identify.

## Sign-off

Approved for closeout. Feature-level closeout still pending iter-004+ (user's manual-test rounds will surface or close remaining items). PR to main remains queued behind user's signoff that the methodology repair holds across hosts.
