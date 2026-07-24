# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-07-10

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.5 | 0.5 | 0 |
| T002 | 1 | 1.25 | +0.25 |
| T003 | 0.5 | 0.5 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 1.5 | 2.25 | +0.75 |
| T006 | 0.5 | 0.5 | 0 |

**Average variance**: +17% on planned tasks (5.0 → 6.0 SP). Unplanned
absorbed work beyond the task table: ~1.5 SP reviewer-runtime field fixes
(console-encoding guard, 32K pathspec collapse, copilot vector + honest
no-vector diagnosis) and ~1.0 SP maintainer-directed old-debt cleanup
(squad seeds, histories, dangling deep-sources). Iteration total ~8.5 SP
against the 26 cap — accepted at signoff with defaults.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | light | light | 0 | Workshop decisions held; design-analysis gate found 3 form findings, fixed in one pass. |
| Discovery/Spikes | 0.5 | 0.5 | 0 | The T001 probe answered every migration question before code moved; zero surprises at migration time. |
| Implementation | 3.5 | 4.5 | +1.0 | T005's condition-c debt triage (32 lint findings, human scope decision) and T002's test-surface migration were the growth. |
| Review | 1.0 | 3.5 | +2.5 | Thirteen+ live rounds: 4 real defect classes caught (worth every round), but ~1.5 rounds were burned on pre-W12 loop mechanics (stale latch, evidence-staleness on count nits, stale queued rounds surfacing late). |
| Rework | 0 | 0.5 | +0.5 | All reviewer catches fixed same-day; no needs-rework verdicts. |

## Drift Summary

- Total drift events: 1
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 1 (DRIFT-198-I001-001 — reviewer-side
  materialization artifact refuted with git evidence, closed by
  maintainer-typed ack; carried as field input to iteration 003)

## What Went Well

- **Probe-first toolchain discipline**: the scratch-dir probe (T001)
  resolved every 0.12.9 unknown (flag survey, multi-integration behind
  --force, git-extension conflict with boundary commits, hooks-schema
  load) before any pin moved; the migration itself then landed without a
  single surprise.
- **The firewall earned its keep on day one**: 32 real findings on the
  first scan, including a class no proposal predicted (Specrew's own dev
  snapshots shipped as squad seed templates) — exactly the
  born-clean-then-detect design intent.
- **The review loop caught four real defect classes the implementer
  missed** — including the release-validation Dockerfile that would have
  installed the retired toolchain during the beta2 publish, and two
  false-green paths in the firewall itself (annotation form, reason
  transparency). The falsification stance is paying for itself.
- **Loud-failure doctrine held under real fire**: codex double-empties,
  a console-encoding crash, a command-line-limit crash, and a
  no-vector-host request all failed loud with durable records; none read
  as green.
- **The mid-iteration UX rulings improved the loop immediately**: the
  approve/deny question pattern (approvals bind the decision, not the
  keystrokes) replaced command copy-paste for the last five remediations.
- **copilot wired as a reviewer host** (probe-validated vector, honest
  no-vector diagnosis fixed) — and it promptly caught a real finding on
  its first round.

## What Didn't Go Well

- **Pre-W12 review-loop economics** (the known beta-1 class, now felt
  first-hand): the stale latch blocked the very re-review that would
  clear it; evidence-staleness forced fresh rounds for two count-nit
  corrections; two stale queued rounds surfaced after their findings were
  already fixed. Roughly 1.5 paid rounds + several human round-trips of
  pure loop mechanics.
- **Hand-written evidence counts** (the 18/18 nit class): ledger numbers
  authored by hand drifted from the executed suite twice; counts should
  be derived from run output, not typed.
- **Reviewer-host infrastructure fragility** cost an evening: quota
  double-empties are indistinguishable from finalization gaps to the
  operator, and the copilot failure was misdiagnosed by its own error
  message ("catalog unreachable" for a missing agentic vector).
- **Verdict-capture latency** at the first boundary (the specify "1"
  recorded a full stop-cycle late) — the F-174 backstop bridged it
  correctly, but the mechanics surprised the human.

## Improvement Actions

1. Owner: Implementer | Phase: iteration 002 (T007-T011) | Type:
   implementation | Expected effect: the ratchet + verdict-history work
   uses THIS session's field instances (capture latency, retroactive
   re-confirm) as direct test fixtures; catalog rows get the measured
   budgets (copilot 61-82s, codex 240-400s observed).
2. Owner: Implementer | Phase: iteration 003 (T020 as amended) | Type:
   implementation | Expected effect: the spend-allowance halt UX
   (consumer-legible, approve/deny via the agent, zero internal
   identifiers) removes the loop-mechanics tax measured this iteration;
   W10's stale-vs-current labeling retires the stale-queued-round
   confusion; the materialization fix (FR-012/FR-017) retires the
   mode-bit false-positive class.
3. Owner: Planner | Phase: next planning | Type: process | Expected
   effect: derive ledger counts (coverage-evidence Tests Run rows) from
   executed suite output instead of hand-writing them — candidate small
   task for iteration 002; prevents the 18/18 nit class.
4. Owner: Spec Steward | Phase: continuous | Type: process | Expected
   effect: wrong-diagnosis machinery messages are now a named review lens
   ("does the error name its actual cause and teach the door?") — two
   instances fixed this iteration (catalog-unreachable, ceiling
   state-surgery text owned by 003).

## Calibration Suggestion

- Suggested capacity adjustment: keep the 5-8 SP planned envelope, but
  plan review effort at ~2x the historic estimate while iterations 002-003
  still run on the pre-W12 loop (the review tax shrinks when T020 lands).
- Rationale: planned-task variance was small (+17%); the real variance
  lived in review mechanics (+2.5 SP) and absorbed field fixes (+1.5 SP),
  both of which this feature itself is in the middle of fixing.

## Notes

- Maintainer decisions recorded mid-iteration and already spec'd: the
  spend-allowance semantics (every round counts; the halt message is the
  fix) and approvals-bind-the-decision-not-the-keystrokes — both in
  spec.md Clarifications with FR-018/FR-019/FR-022/SC-007 amendments.
- Reviewer timing data banked for the iteration-002 catalog task:
  copilot 61-82s (two runs), codex 240-410s (five completed runs),
  antigravity unmeasured this iteration.
