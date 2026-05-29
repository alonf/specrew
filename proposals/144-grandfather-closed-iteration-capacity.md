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

The capacity check is a **planning-time guard**. The correct grandfather rule is therefore an
**in-flight blacklist**, not a closed-status whitelist: in `Test-PlanEffortModel`, only iterations whose
plan `**Status**:` is **in-flight** — `planning` | `executing` — are validated against the **current**
`iteration-config`. Every iteration past implementation — `reviewing` | `retro` | `complete` |
`abandoned` | `*-complete` | `closed` | … — carries **historical truth** and is grandfathered.

- The `Capacity per Iteration` Effort Model setting is **not** compared to the current config for
  grandfathered iterations.
- The `Capacity` line total is validated for **self-consistency** against the plan's own stated
  `Capacity per Iteration` value (historical truth) rather than the current config baseline.
- A status-less plan is treated as in-flight (enforce config) **unless** the durable Proposal-085
  closed-iteration index (`.specrew/closed-iterations.yml`, via `Test-SpecrewIterationClosed`) records
  it — the index acts as belt-and-suspenders for explicit closed entries. The iteration path + project
  root are threaded into `Test-PlanEffortModel` for this lookup.

**Why a blacklist, not a whitelist.** An earlier attempt grandfathered only `complete`/`abandoned`, then
`complete|abandoned|retro-complete|…`. Both were too narrow: the historical corpus froze old iterations
at **bare `retro`** (10 such iterations: `001-specrew-product/006–012`, `005/001`, `045/002`, `048/001`)
without formal closeout and they are **not** in the index, so a whitelist left residual FAILs and is
fragile against the next unlisted form. The in-flight blacklist is forward-compatible: any future or
non-canonical post-implementation status grandfathers automatically. The index lookup is **not**
load-bearing on the CI path (indexed iterations are filtered out upstream of this check, and CI does not
pass `-IncludeClosed`) — the **status rule** is what clears CI; the index covers manual `-IncludeClosed`
audits.

Mirrored byte-identical to `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`.

## Acceptance

- A grandfathered iteration (`Status` ∈ {`complete`, `retro-complete`, **bare `retro`**, `reviewing`})
  with `Capacity per Iteration: 20` + `Capacity: 20/20` under `capacity_per_iteration: 25` produces
  **no** capacity-vs-config FAIL.
- An **in-flight** iteration (`Status: planning` **or** `Status: executing`, not in the index) with the
  same drift **still** FAILs against the current config.
- An iteration recorded in `.specrew/closed-iterations.yml` is grandfathered **even when its plan
  `Status` is in-flight** (belt-and-suspenders).
- Empirically: with `capacity_per_iteration: 25` on the real corpus (`-FullRun -IncludeClosed`), the
  29 failing iterations / 58 FAIL lines from F-049's CI drop to **0**; in-flight enforcement unchanged.
- Covered by `tests/integration/capacity-grandfather-closed-iterations.tests.ps1` (seven cases above).

## Composition

- Precursor to the F-049 feature-closeout PR (#1152): merges to main first so F-049's full-repo CI passes
  (Charter Item 5 ordering preserved — this is not F-050).
- Sibling to the deferred B-001 + A-001 framework-fix slice (drift-log F-049 iterations 004/005) and to
  Proposal 142 (State-Truth Integrity Validator).

## Queued follow-up (separate small-fix slice, ~1-2 SP, after F-049 PR merges)

Maintainer methodology correction (2026-05-29): **20 SP per iteration is intentional** — sized for AI
scope + context window, not arbitrary. F-049's Decision 2 (formalize 25 as the baseline) was a mistake;
the correct response to iteration 003's 23.45 SP was to **split** it into smaller iterations, not raise
the cap. Queued, separate from F-049 closeout to keep scope clean:

- Revert `.specrew/iteration-config.yml` `capacity_per_iteration` 25 → 20.
- CHANGELOG note that 25 was incorrect-historical; 20 is the intended cap.
- Forward iterations cap at 20; historical iterations grandfathered under **this** PR's in-flight rule
  (iteration 003 stays grandfathered as closed/historical truth — the rule protects it in both baseline
  directions).
