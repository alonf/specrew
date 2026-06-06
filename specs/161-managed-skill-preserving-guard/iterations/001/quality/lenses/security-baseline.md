# Lens: security-baseline@v1.0.0 — Iteration 001

**Status**: executed — pass (2026-06-06)

## Focus

The managed/preserve classification is a trust boundary protecting
user-authored skill content from deletion during legacy cleanup.

## Checks executed

- S2 (front-matter user content) and S8 (plain non-signature user content)
  reported preserved AND byte-identical after every deploy run — pre-fix,
  post-fix, and across idempotency re-runs (no-loss invariant; harness
  assertions, both runs).
- Harness writes confined to its temp sandbox; working-repo runtime dirs
  untouched (sandbox path asserted; cleanup in `finally`).
- The fix cannot widen what is classified managed beyond Specrew-owned
  provenance: the new generic branch requires the directory-name heading plus
  the structural `**Type**:` and `**Schema**: v1` lines, only after the
  front-matter check has already excluded front-matter content (contract
  invariants I1/I2/I6 verified in review).

## Outcome

Pass. No user-data-loss path identified; the accepted S4/S4g residual is a
preserve-side (safe) outcome by construction.
