# Lens: test-integrity@v1.0.0 — Iteration 001

**Status**: executed — pass (2026-06-06)

## Focus

Proof-before-fix: repro-first ordering, genuine probe semantics for the
stale-canonical scenarios, and a verdict-gated fix budget.

## Checks executed

- Repro-first ordering is auditable in git: commit `d5e53b89` records
  S4/S4g/S7 as neutral probes observing the frozen outcome BEFORE any source
  change; commit `2a72d6bc` lands the fix and flips S7 to a regression
  assertion (failing-before/passing-after).
- T006/T007 stayed blocked until the T005 verdict recorded CONFIRMED =
  misclassified AND reachable, and were released by explicit human decision
  (ledger entry 2026-06-06T12:20:00Z).
- S4/S4g were NOT rewritten to assert current behavior — they remain recorded
  probes matching the approved deferral (F161-DEFER-001), so the residual
  stays visible instead of test-laundered.
- The F-160 fixture passed unchanged throughout (no test edits to make the
  fix pass).
- New harness wired into the CI integration lane (explicit step), so the
  regression surface executes in CI, not only locally.

## Outcome

Pass. No after-the-fact tests; the evidence chain (probe → verdict → human
release → fix → assertion flip) is reconstructible from commits.
