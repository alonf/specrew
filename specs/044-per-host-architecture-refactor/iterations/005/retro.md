# Retrospective: Iteration 005

**Schema**: v1
**Date**: 2026-05-24

**Feature**: F-044 Per-Host Architecture Refactor

> Second LIVE-TRACKED iteration of F-044 (iter-004 was the first). Plan written before code; actuals filled at task close. Real variance data accumulating.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1.5 | 1.5 | 0 |
| T002 | 0.5 | 0.5 | 0 |
| T003 | 1 | 1 | 0 |
| T004 | 0.5 | 0.5 | 0 |
| T005 | 0.5 | 0.5 | 0 |
| T006 | 2 | 2 | 0 |
| T007 | 1 | 0.5 | -0.5 |
| T008 | 1 | 1 | 0 |

**Average variance**: -0.06 SP (T007 underran because INDEX.md update is deferred to on-main chore rather than executed here)

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.5 | 0.5 | 0 | plan.md + agy-help reverse-engineering from user's CLI output. |
| Discovery/Spikes | 0.5 | 0.5 | 0 | Confirmed agy actual flag set from user's pasted help text — no live spike needed. |
| Implementation | 5.5 | 5 | -0.5 | T001-T007 closed within estimates; T007 deferred portion saved 0.5 SP. |
| Review | 1 | 1 | 0 | All 7 test suites green; manual launch-shape inspection. |
| Rework | 0.5 | 0.5 | 0 | Spent on Test 3 (BinaryAliases canary) regex fix + Test 6 (antigravity args) -in operator instead of regex. |

## Drift Summary

- Total drift events: 1 (see [drift-log.md](./drift-log.md))
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 1 (T007 INDEX.md update → post-PR-merge chore)
- Resolved during this iteration: 1 (Drift #1 — agy CLI flag set diverged from antigravity-followup spec FR-005; resolved by trusting user's pasted `agy --help` output as canonical, not the spec text)

## What Went Well

- **User's pasted `agy --help` output was the canonical fix.** No tool call needed to figure out the right flag set — user provided it inline. Saved a discovery spike.
- **Three regression test suites written + passing on first try.** `host-detection-ux.tests.ps1` (7 assertions), `post-bootstrap-output.tests.ps1` (5), `skill-templates.tests.ps1` (1 across 11 templates). Test 3 (BinaryAliases canary) and Test 6 (antigravity args matcher) needed one round of regex/operator fixes — caught immediately by test failure, not in production.
- **iter-004's `Test-SpecrewHostBinaryAvailable` helper extraction paid off.** iter-005's antigravity Binary verification was trivially testable because the helper returns the resolved binary name; consumers just call it.
- **Two consecutive live-tracked iterations.** Pattern locks in. iter-001/002/003 backfills are now isolated retroactive disclaimers; iter-004 + iter-005 are the current-and-future shape.
- **Real variance data is starting to accumulate.** iter-004's all-zeros variance + iter-005's -0.5 SP underage gives the first signal that small live-tracked iterations are tightly bounded. Next iteration with ≥10 SP will be a better calibration test.

## What Didn't Go Well

- **Antigravity-followup spec FR-005 had the wrong flag set baked in.** Caught only when user dogfooded; the spec referenced `--output-format json --cwd` which agy CLI never accepted. The original spec author didn't have access to a real `agy --help` output. The fix lives in iter-005's code but the antigravity-followup spec text is still stale; queued as follow-up small-fix slice.
- **PowerShell regex gotchas tripped Test 6.** `\|-i\|` doesn't match `-i` at start-of-string because there's no leading pipe. Replaced with `-in $array` operator. Worth documenting alongside the earlier "if-expression-in-format-arg" gotcha.
- **CHANGELOG entry took a full pass + reread.** The drift-explanation section (versioning history F-019=0.19 → F-040=0.26 → F-044=0.27) is informational but maybe too long for a CHANGELOG entry. Reader might benefit from a separate `docs/versioning.md` ADR-style note instead.
- **PR-to-main not yet executed.** This iteration was the readiness gate; the actual PR creation is the next step (user-initiated).

## Improvement Actions

1. **Antigravity-followup spec FR-005 amendment** — Owner: next small-fix slice | Phase: post-PR-to-main | Type: docs | Expected effect: spec text matches shipped reality so future readers don't pull the wrong flag set.
2. **PowerShell gotchas section in `docs/how-to/add-a-new-host.md`** — Owner: opportunistic | Phase: opportunistic | Type: docs | Expected effect: document if-expression-in-format-arg + regex-pipe-anchor pitfalls.
3. **Consider splitting CHANGELOG entries** — Owner: maintainer | Phase: pre-v0.28.0 | Type: process | Expected effect: keep CHANGELOG entries focused on user-visible changes; methodology meta-notes (like the versioning drift explanation) move to `docs/versioning.md` or proposal-level notes.
4. **`Test-VersionAlignedToFeature` validator** — Owner: candidate proposal | Phase: TBD | Type: methodology | Expected effect: prevent version-number drift by warning when next minor version doesn't match next feature number.

## Calibration Suggestion

- Suggested capacity adjustment: keep 20 SP baseline.
- iter-005 used 8/20 (40%). Compared to iter-004 (3/20). Two data points suggest small fix slices comfortably sit in 3-8 SP range; capacity 20 leaves headroom for architectural iterations like iter-001 (18 SP).
- Calibration confidence: low (only 2 live-tracked iterations). Next iteration with substantial scope (e.g., F-045 or a fresh feature) will give better data.

## Notes

- F-044's 5-iteration arc is now complete: iter-001 (architectural payoff) + iter-002 (deep-analysis cleanup, 22 findings) + iter-003 (manual-test repair, 5 bugs) + iter-004 (UX, 3 changes, first live-tracked) + iter-005 (Antigravity launch + release prep, second live-tracked).
- Branch is **READY for PR-to-main** as the F-043 + F-044 bundled PR. PR description must surface the 5-iteration arc + the cross-feature bundle rationale (F-043 + F-044 co-evolved, share substrate).
- User's manual dogfood remains the canonical review boundary for the launch-shape fix. Re-test `specrew start --host antigravity` after this branch is loaded against fresh project.
