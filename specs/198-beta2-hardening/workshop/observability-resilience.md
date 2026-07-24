# Workshop Record: observability-resilience (light)

**Feature**: 198-beta2-hardening
**Date**: 2026-07-09
**Confirmation**: human-confirmed ("Confirm")

## Failure-mode traces (agreed): symptom → diagnosis evidence → next step

```text
  reviewer timeout (budget kill)
    watchdog reaps the tree (proven) → durable failure record in
    .specrew/review/** → record + CLI message TEACH the doors: "re-run with a
    larger explicit budget, or raise co_review_timeout_seconds" (increase
    stays human-typed, T096) → if the kill followed an explicit downgrade,
    the W14 warning already fired AT RESOLUTION TIME

  containment violation (W4)
    detector marks run containment-violated → run FAILS loud → origin-side
    durable record names the observed access (process, command line, path,
    timestamp) — never silent, never a mid-flight kill; nothing
    origin-flavored enters the reviewer-visible bundle (consistent with W2)

  ceiling halt (W11/W12)
    fix-responsive rounds do not increment the counter → a true no-movement
    halt renders the exact remediation command + "a bare --live rerun will
    NOT re-review past the ceiling" → never points at state surgery

  checkpoint drift (W10)
    detached child materializes the FROZEN fire-time tree → run labeled
    stale-vs-current when the tree moved → label rides the run record and
    the status surface

  skipped boundary (#2906)
    ratchet refusal / validator FAIL finding names the skipped boundary +
    both reconciliation doors → .specrew/runtime/pending-verdict-stop.md
    stays authoritative for what verdict is owed
```

## Cross-cutting (agreed)

- **Correlation**: the existing run-ID scheme ties CLI message ↔ durable
  record ↔ gate output; every gate claim traces to a run record by ID.
- **Idempotency**: checkpoint reviews dedup on the frozen digest (W10 makes
  the dedup honest); sync crossings idempotent per boundary; update healing
  idempotent (hash-guarded).
- **Not logged**: no secrets in any record; origin paths only in origin-side
  records, never in reviewer-visible artifacts.
