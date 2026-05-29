# Proposal 144 — Grandfather Closed-Iteration Capacity in the Governance Validator

**Status**: draft (small-fix slice — implemented in this PR)
**Phase**: phase-2
**Estimated SP**: 3-5
**Type**: bug-fix / validator-hygiene

## Problem

`validate-governance.ps1` (`Test-PlanEffortModel`) compares each iteration plan's Effort Model
`Capacity per Iteration` and `Capacity` line total against the **current** `.specrew/iteration-config.yml`
`capacity_per_iteration`. When the repo-wide baseline changes (e.g., F-049 raised it 20 → 25 for
iteration 003's 23.45 SP engine pivot), every **closed** historical iteration that planned against the
old baseline retroactively FAILs — 58 such FAILs surfaced in the F-049 closeout PR's full-repo
validation. Closed iterations carry **historical truth** (the baseline at their time), not current-policy
truth, so enforcing the current config against them is incorrect. Mass-editing dozens of closed plans
(or reverting the baseline, which would misrepresent iteration 003) are both wrong fixes.

## Fix

In `Test-PlanEffortModel`, detect closed iterations from the **durable closeout signal** — not plan
status text alone — and **grandfather** their capacity. Closedness is established by either:

1. **The authoritative Proposal-085 closed-iteration index** (`.specrew/closed-iterations.yml`), keyed
   `<feature-slug>/<iteration>` and checked via `Test-SpecrewIterationClosed` (the iteration path +
   project root are now threaded into `Test-PlanEffortModel`); **or**
2. **A broadened terminal/closed plan-`**Status**:` pattern** — `complete` | `completed` | `abandoned` |
   `closed` | `done` | `retro-complete` | `retrospective-complete` | `closeout-complete` |
   `closure-complete` (covers the non-canonical closed status forms the historical corpus uses, e.g.
   `retro-complete`), plus `Test-ClosedIterationStatus`.

Detecting only `complete`/`abandoned` was too narrow: many historical `/20` plans use status forms like
`retro-complete` and several closed iterations are recorded only in the index, so a status-only check
left residual FAILs. With both signals, grandfathering applies whenever an iteration is genuinely closed:

- The `Capacity per Iteration` Effort Model setting is **not** compared to the current config for closed
  iterations.
- The `Capacity` line total is validated for **self-consistency** against the plan's own stated
  `Capacity per Iteration` value (historical truth) rather than the current config baseline.
- Active / in-flight iterations (any non-closed status) continue to validate against the current config,
  so live planning still respects the baseline.

Mirrored byte-identical to `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`.

## Acceptance

- A closed iteration (`Status: complete`) with `Capacity per Iteration: 20` + `Capacity: 20/20` under
  `capacity_per_iteration: 25` produces **no** capacity-vs-config FAIL.
- A closed iteration using a **historical status form** (`Status: retro-complete`) under the same drift
  is also grandfathered (**no** FAIL).
- An iteration recorded in `.specrew/closed-iterations.yml` is grandfathered **even when its plan
  `Status` is a non-terminal form** (e.g. `reviewing`).
- An active iteration (`Status: planning`, not in the index) with the same drift **still** FAILs against
  the current config.
- Empirically: with `capacity_per_iteration: 25` on the real corpus, residual closed-iteration
  capacity-vs-config FAILs drop from 58 → 0; active-iteration enforcement is unchanged.
- Covered by `tests/integration/capacity-grandfather-closed-iterations.tests.ps1` (four cases above).

## Composition

- Precursor to the F-049 feature-closeout PR (#1152): merges to main first so F-049's full-repo CI passes
  (Charter Item 5 ordering preserved — this is not F-050).
- Sibling to the deferred B-001 + A-001 framework-fix slice (drift-log F-049 iterations 004/005) and to
  Proposal 142 (State-Truth Integrity Validator).
