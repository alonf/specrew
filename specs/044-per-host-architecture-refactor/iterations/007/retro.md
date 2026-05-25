# Iteration Retrospective: 007

**Schema**: v1
**Date**: 2026-05-25

**Feature**: F-044 Per-Host Architecture Refactor

> Fourth LIVE-TRACKED iteration of F-044. plan.md authored before code; actuals at task close.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1.5 | 1.5 | 0 |
| T002 | 1 | 1 | 0 |
| T003 | 1.5 | 1.5 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 1 | 1 | 0 |
| T006 | 0.5 | 0.5 | 0 |
| T007 | 0.5 | 0.5 | 0 |

**Average variance**: 0 SP at the task level. But see Phase Variance below — T007's 1 SP rework buffer absorbed an unplanned test-assertion repair (drift #1), so the 0-variance reading is **buffer-cushioned**, not zero-surprise.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.5 | 0.5 | 0 | plan.md authored from clear user scope. |
| Discovery/Spikes | 0.5 | 0.5 | 0 | Audit grep found 1 sibling bug. |
| Implementation | 4.5 | 4.5 | 0 | T001 + T002 + T003 + T004 + T005 + T006. |
| Review | 0.5 | 0.5 | 0 | All test suites + validator green locally. |
| Rework | 1 | 1 | 0 | Buffer absorbed bootstrap-to-iteration assertion repair (drift #1). |

Without the 1 SP rework buffer, variance would have been +0.5-1 SP. Calibration insight: when the iteration starts from a user-stated scope ("fix X, audit Y, add Z, verify W"), the iteration-level SP estimate lands hard *because* the rework buffer absorbs the small surprises.

## Drift Summary

- Total drift events: 2 (see [drift-log.md](./drift-log.md))
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0 in iter-007 scope (baseline-hygiene + dashboard.md + INDEX.md are out-of-scope, not iter-007 deferrals)
- Resolved during this iteration: 2 (drift #1 bootstrap-to-iteration test-assertion repair; drift #2 process-scorer sibling-bug fix)

## Improvement Actions

- **Calibration data**: log the rework-buffer cushion pattern in future plans. When the buffer line item is non-zero, treat that as latent variance and budget accordingly.
- **Validate iter artifacts via full-repo validator before push**: local `--ChangedOnly` skipped the canonical-schema lens on iter-007 because the iteration directory was untracked. Future live-tracked iterations should run `validate-governance.ps1 -ProjectPath .` (no -ChangedOnly) at iter-close before commit.
- **Pre-existing test failure detection**: institutionalize the stash + checkout pattern used here. Mental rule: "is the failing file in my diff?" — if not, verify on origin/main before chasing. Worth a small-fix `tests/integration/lib/test-helpers.ps1` helper for future iterations.

## What Went Well

- **Proactive grep audit found 1 sibling bug** (process-scorer.ps1) BEFORE Antigravity's next dogfood would have surfaced it. ~5 minutes of grep saved a future surprise.
- **User-requested README enhancement landed cleanly** — the host-switching narrative is now a top-tier differentiator section, with a worked Mon/Tue/Wed/Thu example showing host swap mid-feature. This is the killer feature most external readers won't grok from prose alone.
- **Markdownlint --fix auto-resolved 9 violations** across all 7 iteration directories in one pass. No manual edits needed.
- **iter-007 hit exactly on plan** (7 SP, 0 variance). First time in F-044's 7-iteration arc.
- **Pre-existing test failures correctly identified as pre-existing**. Used stash + checkout pattern to verify on origin/main directly. Avoided false-alarm scope creep into iter-007.

## What Didn't Go Well

- **Pre-existing test failures look identical to regressions in the first glance**. The 30-second mental rule was "is the failing file in my diff?" — if not, stash + checkout main to verify pre-existing. Without that discipline, I would have spent significant time chasing baseline-hygiene's markdownlint-gate cascade.
- **Two separate `.specify/` vs `extensions/` files needed identical fixes**. The `.specify/` copy is git-tracked (in-repo dogfooding for Specrew itself). This is a known Specrew architecture wrinkle — fixed by mirroring T001's edit to both copies. Could be addressed by a `bin/sync-specify-mirror.ps1` script as a future small-fix; not iter-007 scope.

## Methodology Lessons

### "No remaining agent patches" is the empirical completion test

iter-006 thought it had closed all of Antigravity's patches. iter-007 found one more. The pattern: each fresh-environment dogfood surfaces the next-rarest bug class. No automated lint or grep can fully substitute — the agent stress-tests code paths that maintainers never deliberately exercise.

Methodology implication: Specrew's quality bar should treat "Antigravity drove specify→feature-closeout on a fresh Linux project without patching any Specrew file" as the canonical Linux-readiness gate. Tests 8 + 9 + 10 in `multi-host-lifecycle-smoke` are necessary but not sufficient.

### iter-007's value is the iteration cadence itself

When the user asked "OK, do that fix and analyze the result..." they could have gotten the same outcome by skipping the iteration boundary and just patching. The iteration produced: (a) durable artifacts capturing why the fix was needed + what it covered, (b) explicit drift entries for the 2 in-flight surprises (sibling-bug + test assertion), (c) a closeout decision (defer baseline-hygiene + dashboard.md vs scope creep), (d) a canonical record for the next dogfood. This is what governed-agentic-SDLC buys: the iteration boundary IS the SDLC artifact, not the code change.

## Carry-Over to Next Iteration / Feature

- F-043 + F-044 bundled PR opens after this iter-closes.
- Post-PR-merge: `proposals/INDEX.md` chore (entries for F-043 + F-044 + Proposal 108).
- Post-PR-merge: draft host-specific init deferral proposal (per memory candidate).
- Separate small-fix iteration candidate: investigate + fix `baseline-hygiene` + `lifecycle-boundary-sync` test failures (the markdownlint-gate auto-fix + commit cascade).
- Separate small-fix iteration candidate: dashboard.md auto-render for closed iterations (Proposal 046+048 — already drafted, just needs implementation slice).

## Velocity Snapshot

- F-044's 7 LIVE iterations totaled: 18 + 6 + 4 + 3 + 8 + 4 + 7 = 50 SP delivered against ~140 SP nominal capacity (20/iter × 7).
- True throughput including all 4 backfilled iterations: 50 SP across ~3 weeks of dogfood-driven discovery + repair work.
- Velocity is intentionally below capacity — F-044 was discovery-heavy (4 backfill iterations covering Phase A-D refactor) before live-tracked work resumed at iter-004.
