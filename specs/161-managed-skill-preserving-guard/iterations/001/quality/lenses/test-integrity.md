# Lens: test-integrity@v1.0.0 — Iteration 001

**Status**: planned (executed during review phase)

## Focus

Proof-before-fix: repro-first ordering, genuine probe semantics for S4, and a
verdict-gated fix budget.

## Planned checks

- T003/T004/T005 complete before any source change; T006/T007 blocked unless
  T005 = CONFIRMED (misclassified AND reachable).
- S4 authored as a neutral probe; promoted to regression assertion only with a
  landed fix (failing-before/passing-after evidence captured).
- F-160 fixture passes unchanged throughout; no after-the-fact tests that only
  prove the final implementation.

## Execution record

Pending implementation.
