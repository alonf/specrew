# Lens: robustness-baseline@v1.0.0 — Iteration 001

**Status**: executed — pass (2026-06-06)

## Focus

Silent misclassification is the suspected failure mode; the investigation must
make every classification decision observable and the fallback chain explicit.

## Checks executed

- Every scenario outcome (S1–S8) captured from the deployment-action record +
  on-disk state, never inferred; neutral probes recorded raw outcomes before
  interpretation.
- S5 idempotency: second consecutive real deploy run produced a stable
  end-state (no further removals, no active-root updates, legacy set
  unchanged) — both harness runs.
- Edge inputs exercised: non-catalog `specrew-*` dir (no-definition path,
  S2b), plain non-signature content under a catalog name (S8); missing/empty
  `SKILL.md` and encoding/line-ending divergence documented as classifier
  behavior in the data model (rule chain) and spec edge cases.
- Fallback chain after the fix remains explicit and ordered: marker →
  exact-canonical → front-matter → slash signature / generic equality →
  generic legacy signature → preserve.

## Outcome

Pass. The previously-silent freeze is now observable (harness) and the
reachable branch is fixed; the deferred branch is documented.
