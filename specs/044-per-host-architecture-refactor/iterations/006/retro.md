# Retrospective: Iteration 006

**Schema**: v1
**Date**: 2026-05-25

**Feature**: F-044 Per-Host Architecture Refactor

> Third LIVE-TRACKED iteration of F-044. plan.md authored before code; actuals at task close. Real variance data accumulating (3 live iterations: iter-004 0/3, iter-005 -0.5/8, iter-006 -1.5/5.5).

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 2 | 2 | 0 |
| T002 | 2 | 0.5 | -1.5 |
| T003 | 1 | 1 | 0 |
| T004 | 0.5 | 0.5 | 0 |

**Average variance**: -0.375 SP (mostly T002 underrun — see Drift #1)

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.5 | 0.5 | 0 | plan.md + reading Antigravity's session output. |
| Discovery/Spikes | 0.5 | 0.5 | 0 | Diffed user's project-deployed scaffolder against canonical — found 1 small change. |
| Implementation | 3.5 | 2.5 | -1 | T002 simpler than expected (0.5 SP not 2 SP). |
| Review | 0.5 | 0.5 | 0 | All 8 test suites green. |
| Rework | 0.5 | 0 | -0.5 | No rework loops. |

## Drift Summary

- Total drift events: 2 (see [drift-log.md](./drift-log.md))
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Resolved during this iteration: 2 (T002 underrun, T003 behavior change — both documented + accepted)

## What Went Well

- **Empirical bug-source: Antigravity's session log.** No tool spike needed — agent's own commands + edits told us exactly what was broken. Save dozens of SP vs hypothetical "what could break" pre-planning.
- **`Import-Module` → `$env:SPECREW_MODULE_PATH` chain is elegant.** One line in `Specrew.psm1` solves an entire class of "agent-spawned child shells dispatch to wrong module" bugs because env vars inherit across child processes natively.
- **All 8 test suites green on first run after iter-006 changes.** No regressions; 7 new assertions added. Live-tracked methodology + small slice = high green-rate.
- **Antigravity validates Specrew is HOST-AGNOSTIC.** Even Gemini 3.5 Flash, talking through Antigravity, recognized the Crew coordinator role + drove the lifecycle. The methodology promise holds across very different LLMs.

## What Didn't Go Well

- **T002 estimate was 4× too high.** I budgeted for "Antigravity might have rewritten half the scaffolder"; reality was one 1-line StrictMode fix. Calibration miss because I don't have data on what agent patches typically look like.
- **Stale-install drift caused 3 iterations of friction.** iter-003 mentioned it. iter-005 hit it again. iter-006 finally fixed it structurally. Pattern: when a dispatch failure mode surfaces 3 times across consecutive iterations, escalate from documented-workaround to structural-fix earlier.
- **Antigravity's self-patching is a methodology gap, not a code bug.** Agent edited deployed Specrew code rather than reporting the broken contract. Question for future proposal: should Specrew's coordinator prompt explicitly forbid `.specify/` edits? Or accept agent-applied workarounds and require they be reported as drift?

## Improvement Actions

1. **Calibration data on agent patches**: 1 data point so far (1-line StrictMode fix). Collect more from future iter-006-style "agent-discovered fix" closeouts. Track in proposal-level documentation when 3+ data points accumulate.
2. **Stale-install pattern fixed structurally** (iter-006 T001). Future dispatch shims should use the same 3-priority resolution chain. Worth promoting to a reusable helper function if other shims grow.
3. **Methodology proposal candidate**: "Agent-applied patches to deployed Specrew code MUST be reported as drift in the iteration's drift-log, never silently committed." Tracked as future proposal.
4. **`scaffold-iteration-artifacts.ps1` may have a latent bug** based on Antigravity's repeated probes. If user's next manual test surfaces it, open iter-007.

## Calibration Suggestion

- Suggested capacity adjustment: keep 20 SP baseline.
- 3 live-tracked iterations: 3/20 (iter-004), 8/20 (iter-005), 5.5/20 (iter-006). Average ~5.5 SP per iteration. Capacity 20 leaves substantial headroom — appropriate for current "small-fix iteration" cadence. Will need re-evaluation if/when a substantial-scope iteration arrives.

## Notes

F-044's 6-iteration arc is now complete:

- iter-001: architectural payoff (18 SP, retroactive)
- iter-002: deep-review cleanup (6 SP, retroactive)
- iter-003: manual-test repair (4 SP, retroactive)
- iter-004: host UX (3 SP, FIRST live-tracked)
- iter-005: antigravity launch + v0.27.0 release prep (8 SP, live)
- iter-006: dispatch hardening + Antigravity patch canonicalization (5.5 SP, live)
- **Total: 44.5 SP** across 6 iterations

Branch is ready for PR-to-main. F-043 + F-044 bundled PR is the next user-initiated step.
