# Iteration 004 Closeout Validation

**Feature**: 197-continuous-co-review
**Iteration**: 004 (Phase B part 1 — #2885 latency fix + gate enforcement wiring)
**Date**: 2026-06-23
**Base**: merge `6c502c20` (origin/main = F-185 + 0.39.0-beta1)

## Scope delivered

| Task | Outcome |
| ---- | ------- |
| T070 | #2885 parse-once-and-share — the 3 Stop-hook handover consumers share ONE memoized transcript parse per stop. DONE. |
| T071 | Conformance-provider memo — SUBSUMED (measured unwarranted; see below). |
| T072 | Bootstrap parse-function tests (byte-identical goldens + non-vacuous parse-once witness). DONE. |
| T073 | Opt-in gate enforcement wired into `Invoke-SpecrewBoundaryStateSync` (default OFF). DONE. |
| T074 | Gate-wiring tests (refuse/allow/no-op). DONE. |
| T075 | This closeout-validation + the Proposal 145 review. |

## Evidence (runtime, not file-existence)

### #2885 latency — MEASURED before/after (no hard target; "reasonable effort" reduction)

On a representative 2000-line transcript, the handover 3-consumer parse:

- OLD (3 independent parses): **1,399.8 ms**
- NEW (1 parse + 2 cache hits): **342.3 ms**
- **75.5% reduction (~1.06 s saved per stop)**; scales with session size, so the issue's
  ~11s dominant handover cost drops to ~3-4s.
- Conformance provider's last-assistant read: **10 ms** (185's backward early-exit) — already
  cheap; nothing to dedup (the basis for T071 being subsumed).

### Correctness / regression — byte-identical, independently re-run

- `transcript-parse-once.Tests.ps1`: **28/0** — byte-identical goldens (recorded pre-refactor)
  across all 5 host schemas + a synthetic-user leak-guard + a non-vacuous parse-once witness
  (3 consumers = 1 parse, warm stop = 0). Goldens pinned to LF (`.gitattributes`) so a CRLF
  checkout cannot silently kill the guard.
- `verdict-capture-blocks.tests.ps1` (the human-verdict-capture path): **22/0**.
- `conformance-detection.tests.ps1`: **39/0**. `dispatcher-stop-block.tests.ps1`: green.
- `ConversationCapture` (Tier 1/2/3/Floor) + `ConversationOnlyCapture`: green.

### Gate enforcement (FR-025 / SC-019 / SC-020)

- `signoff-gate-wiring.Tests.ps1`: **12/0** — ON + no evidence -> refused (SC-019); ON + fresh
  passing run matching the current tree -> allowed (SC-020); the allow path returns NOTHING
  (boundary-sync result-pipeline guard); OFF + non-review-signoff -> no-op; config default OFF.

### Full suite + protected surfaces

- Full continuous-co-review suite: **188/0** across 39 files on the merged base.
- Protected-surface guard test: **1/0**. My Iteration 004 changes touch ONLY
  `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`,
  `scripts/internal/continuous-co-review/signoff-gate-wiring.ps1`,
  `scripts/internal/sync-boundary-state.ps1` — **NO F-184-protected surface**
  (verified `git diff 6c502c20..HEAD`; the dispatcher change in the wider range was the 185 merge).

## Capacity

10.50/20 story_points (T071's 1.50 recovered as subsumed).

## Proposal 145 review

Two adversarial read-only reviewers (T070 parse-once correctness/leak/mtime; T073 gate
bypass/fail-open/pipeline-guard). Findings + dispositions recorded in
[review.md](review.md).

## Deferred / next

- Iteration 005 = B (async Stop-hook navigator: self-limiting watchdog + pending registry +
  reaper). D (reviewer-runs-in-repo) dropped.
- SC-012 maintainer real-host smoke test after the async auto-fire lands (Iteration 005).
- The opt-in flag `co_review_gate_enforcement` is documented in `signoff-gate-wiring.ps1`;
  197's own dogfood can opt in to exercise the mandatory-co-review-at-signoff path.
