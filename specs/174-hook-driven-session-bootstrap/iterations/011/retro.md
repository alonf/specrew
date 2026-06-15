# Retro: Iteration 011

**Schema**: v1
**Held**: 2026-06-14 (consolidated at iteration-closeout)

Iteration 011 delivered the DF-3/4/5/7 boundary-authoring + verdict-integrity cluster + the FR-028 hook
hardening, then — at the maintainer's real-host re-dogfood acceptance gate — found and fixed a host-delivery +
packaging cluster (P1/P2 + a StrictMode crash) that kept the bootstrap banner from surfacing on Claude.

## What went well

- **The real-host gate earned its keep.** Exactly as the iter-010 falsification lesson predicted, the
  deterministic suite (50→45 suites green) was necessary but NOT sufficient: the live Claude run surfaced three
  banner-blocking defects the synthetic tests passed clean over. Keeping the on-host dogfood as a hard gate is
  validated again.
- **Adversarial Proposal-145 review caught real design gaps.** The second pass found CAP-1 (a genuine
  budget-composition gap) and RES-1 (the handover budget spent on the wrong sections — the code did the opposite
  of its own comment), neither of which a single-pass review would have caught. The 6 refuted findings show the
  default-refute verification is discriminating, not rubber-stamping.
- **Integrity held under probing.** No fabricated verdict, no gate-skip; committed≠authorized surfaced honestly
  across the host switches. The verdict-integrity core was robust even while the bootstrap *surfacing* was broken.

## What to improve (the lessons)

- **Extraction tests must run under the runtime's strictness.** The `$null.Count` crash existed because the
  unit tests that extract `Format-BootstrapDirective` did NOT `Set-StrictMode -Version Latest`, while the real
  provider does — so `$null.Count` returned `$null` silently in tests but THREW live. Fixed for the directive
  tests; the broader lesson: a test that extracts a function from a strict-mode script must replicate strict mode
  or it tests a different language.
- **Fail-open that emits nothing is undiagnosable.** The provider swallowed two distinct errors (a component
  skew and the `.Count` crash) into an empty directive with only a stderr WARN Claude never shows — the human saw
  a bannerless agent and no error. Recorded as drift D-008 (silent-failure hardening) — fail-open should still
  surface *something*.
- **Self-bounding budgets don't compose.** P2 bounded the bootstrap directive in isolation, but the SessionStart
  payload is bootstrap + refocus joined; each self-bounds to its own ceiling and together they can exceed the
  cap (CAP-1). When two independently-budgeted producers share one capped channel, the budget must be reconciled
  at the join, not per-producer.
- **Dogfood setup is part of the test.** The first real-host run failed on a component version skew
  (`SPECREW_MODULE_PATH` at the stale install, not the dev tree) — a setup gap, not a product bug, but it cost a
  diagnosis cycle. The deployed-module dogfood method (import the dev module + point the env var at it) is the
  reliable recipe.

## Carry-forward

- CAP-1 dispatcher fragment-priority drop (drift D-007, proposal candidate).
- Silent-failure hardening (drift D-008, proposal candidate).
- D-001 host-neutral verdict-marker emission (fast-follow).
- Published-beta install validation of the bootstrap surfacing (a feature-closeout gate; the dev-tree real-host
  PASS is necessary-not-sufficient for the shipped bytes).
