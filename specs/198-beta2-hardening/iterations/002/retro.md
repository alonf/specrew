# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-07-11

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T007 | 1.5 | 2 | +0.5 |
| T008 | 1.5 | 1 | -0.5 |
| T009 | 0.5 | 1.5 | +1.0 |
| T010 | 2.0 | 2 | 0 |
| T011 | 1.0 | 1 | 0 |
| T012 | 0.5 | 0.75 | +0.25 |
| T019a | 1.0 | 1 | 0 |

**Average variance**: +16% on planned tasks (8.0 → 9.25 SP), almost
identical to iteration 001's +17%. The one real outlier is T009 (3x):
the "re-confirm surface" task turned out to contain the iteration
cycle-reset field discovery — the root cause of every missed verdict this
feature had experienced — which was the right place to fix it but three
times the surface the estimate assumed.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | light | light | 0 | Design-analysis 002 passed the gate first-try — the 001 form lessons (per-option mermaid, single-option recommendation, per-lens Addressed) held. |
| Discovery/Spikes | 0 | 0 | 0 | No spikes planned; the cycle-reset discovery emerged inside T009 rather than a spike. |
| Implementation | 6.5 | 7.25 | +0.75 | Spread thin across T007/T009/T012; no single blowout beyond T009's scope growth. |
| Review | 1.0 | 1.75 | +0.75 | Signoff rounds: one codex double-empty flake (host switch), one ceiling latch + human more-time approval, then clean 237849f1; the evidence-staleness re-round 485cbb03 caught a real bug (worth the round); final clean 8bf11302. |
| Rework | 0 | 0.25 | +0.25 | One same-hour fix: Test 5 hermeticity (run-485cbb03 catch), proven green in a tracked-files-only checkout. |

## Drift Summary

- Total drift events: 1 (post-retro annotation, 2026-07-11: zero at the
  time this retro was approved; DRIFT-198-I002-001 was detected AFTER
  retro approval, during the iteration-closeout arc - the shipped
  ratchet primitive diverged from FR-001/FR-002 (cycle-blind
  reconciliation + fail-open on a malformed ledger), was escalated via
  the maintainer's closeout send-back, and was reworked with paired
  regressions before the iteration closed; see drift-log.md)
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 1 (DRIFT-198-I002-001, resolution
  human-decision + rework; the cycle-reset discovery during execution
  remains in-scope FR-004 work, recorded in review.md's Gap Ledger, not
  spec drift)

## What Went Well

- **The iteration's own machinery governed the iteration** (the dogfood
  recursion working as designed): the cycle-reset + capture pipeline
  retroactively recorded this iteration's own missed plan/tasks/
  before-implement verdicts; the budget chain resolved copilot's catalog
  300s for the signoff runs; independence provenance recorded `flag`; and
  the tracker-only bypass correctly DECLINED a mixed delta (state.md +
  a lint auto-fix) — strict exactly where designed.
- **Evidence-staleness strictness paid for itself the same day**: the
  extra round forced by two housekeeping commits (485cbb03) ran the unit
  suite inside the stripped review worktree and caught provenance Test 5
  silently depending on the untracked ambient reviewer-hosts.json —
  a false-green that repo-local runs could never surface.
- **Both independent-review catches were test-integrity bugs** (codex:
  deny-list version lock; copilot: fixture hermeticity) — the
  falsification stance is catching exactly the class that makes suites
  lie, not surface nits.
- **The truth gate refused its own author's stale state.md**: the
  review-signoff sync blocked on a scaffold Execution Summary until the
  file told the truth — honest-state enforcement working with no
  special-casing for the machinery's own maintainers.
- **First-try gate passes across the board** on planning artifacts —
  the 001 retro's form lessons transferred cleanly.

## What Didn't Go Well

- **Reviewer-host infrastructure fragility again** (carried from 001):
  one codex double-empty flake (run 32dbb878) cost a loud failure, a host
  switch, and human round-trips before the first clean pass.
- **The pre-T020 loop tax is still being paid**: the ceiling latch fired
  on a converging round and consumed a human more-time approval; the
  spend-allowance UX that retires this lands as T020 in iteration 003.
- **Scaffold staleness reached the signoff gate**: state.md's header
  fields were updated but the scaffold Execution Summary body was missed,
  costing a sync refusal + fix + evidence re-round. A pre-sync
  scaffold-phrase sweep would have caught it for free.
- **Test 5 shipped non-hermetic in a file whose other tests had the
  fixture pattern** — self-inconsistency within one suite that authoring
  and review both missed; only the in-worktree suite run caught it.

## Improvement Actions

1. Owner: Implementer | Phase: iteration 003 (T013-T015 containment
   contract) | Type: implementation | Expected effect: the containment
   contract REQUIRES (maintainer instruction: requirement, not advisory)
   an in-worktree verification step BOUNDED to declared relevant test
   commands — with timeout/process containment, bounded output capture,
   and post-run mutation detection — never an unrestricted
   whole-repository suite run. This is the mechanism that caught Test 5,
   made deterministic and safe.
2. Owner: Implementer | Phase: iteration 003 (T020) | Type:
   implementation | Expected effect: the spend-allowance halt UX retires
   the latch-on-converging-round friction measured again this iteration
   (one latch + one human approval of pure loop mechanics).
3. Owner: Implementer | Phase: iteration 003 (feasibility, then
   continuous) | Type: implementation | Expected effect: promote the
   scaffold-phrase sweep from a manual reminder to a DETERMINISTIC
   pre-signoff check over truth-gate-read artifacts (scaffold phrases
   like "has not started yet", "TBD", "pending task decomposition",
   "Populate after") — this iteration proved a prose-only sweep
   unreliable twice: state.md reached the signoff gate stale, and
   plan.md's scaffold sections survived to the retro gate itself
   (maintainer send-back).
4. Owner: Reviewer | Phase: continuous | Type: process | Expected
   effect: fixture hermeticity is now a named review lens ("does every
   test build its own state, or does it lean on ambient repo files that a
   clean checkout lacks?") — two test-integrity catches in one iteration
   say the lens earns its slot.

## Calibration Suggestion

- Suggested capacity adjustment: keep the 5-8 SP planned envelope;
  planned-task variance is stable (+16-17% two iterations running), so
  estimates need no correction — but keep budgeting review at ~2x its
  naive estimate until T020 lands and the loop-mechanics tax drops.
- Rationale: this iteration's review overrun was one flake + one latch +
  one honest staleness re-round; two of those three shrink when the
  spend-allowance UX and the containment contract land in 003.

## Notes

- Retro verdict history: sent back once — the maintainer caught plan.md's
  scaffold sections (Phase Baseline TBDs, "pending task decomposition",
  stub Notes) still standing while this retro claimed the scaffold sweep
  as a corrective action; approving would have immediately disproved
  action 3. Fixed before re-submission; the recurrence is itself the
  evidence that action 3 must be deterministic, not prose.
- Capture-latency keystroke tax: stays a retro note per maintainer
  ruling — address in iteration 003 only if a small generic fix emerges
  during planning; it must not displace containment or T020 work.
- Signoff evidence chain for this iteration: clean 237849f1 → staleness
  re-round 485cbb03 (real catch: Test 5 hermeticity, fixed 14222c86) →
  clean 8bf11302 promoted as gate evidence; review-signoff approved by
  the maintainer with defaults (option 1).
- Reviewer timing data banked: copilot 58-122s across three signoff-round
  runs on the new catalog budget chain (resolved 300s); codex flake run
  recorded loud with durable evidence.
