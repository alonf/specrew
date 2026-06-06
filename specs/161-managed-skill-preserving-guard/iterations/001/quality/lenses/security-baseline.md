# Lens: security-baseline@v1.0.0 — Iteration 001

**Status**: planned (executed during review phase)

## Focus

The managed/preserve classification is a trust boundary protecting
user-authored skill content from deletion during legacy cleanup.

## Planned checks

- S2 user-authored legacy dir reported preserved AND byte-identical after
  every deploy run — pre-fix, post-fix, refuted-no-fix (no-loss invariant).
- Harness writes confined to its temp sandbox; working-repo runtime dirs
  untouched.
- Any conditional fix cannot widen what is classified managed beyond
  Specrew-owned provenance (contract invariants I1/I2/I6).

## Execution record

Pending implementation.
