# Iteration 004 State

**Feature**: 197-continuous-co-review
**Iteration**: 004
**Current Phase**: tasks
**Iteration Status**: planning
**Last Completed Task**: design-analysis approved (maintainer, 2026-06-23): 004 = A (#2885) + C (gate wiring); B -> Iteration 005; D dropped
**Tasks Remaining**: T070, T071, T072, T073, T074, T075
**In Progress**: awaiting before-implement approval
**Updated**: 2026-06-23

## Scope (Phase B — Always-On, now unblocked by the F-185 merge)

Opened on merge commit `6c502c20` (origin/main = F-185 host-neutral hook surface +
0.39.0-beta1). Phase B delivers the live always-on behavior + the critical-issue fixes:

1. **Critical-issue fix — #2885 Stop-hook latency (~16s/stop).** The Stop hook is already
   slow (dominant ~11s F-174 handover transcript re-parsing + ~4s conformance). 197's
   navigator spawns a reviewer process, so the Stop path MUST be fast first. (F-184 status of
   the handover/dispatcher files under investigation.)
2. **Host-neutral Stop-hook co-review trigger (FR-026/030/031)** — register a 197 co-review
   provider into the merged 185 `specrew-hook-dispatcher` seat; the navigator runs
   ASYNC/non-blocking so it does not add to the Stop latency (#2885 constraint).
3. **Gate enforcement wiring (FR-025)** — wire `Assert-ContinuousCoReviewSignoffGate` into
   `Invoke-SpecrewBoundaryStateSync` (non-protected; 185 does not touch it).
4. **Reviewer-runs-in-repo execution model** — the spawned reviewer runs with repo read
   access + inherited env so it can read config + run tests on the real host (Proposal 145
   runtime evidence; enables the maintainer real-host smoke test).

## Carried in from Iteration 003

- F3/F4 override + run-record authentication/persistence (binding on this wiring).
- SC-012 maintainer real-host smoke test runs AFTER the always-on auto-fire lands.

## Design grounding (in progress)

- Explore: 185's merged hook/provider seam (how to register a Stop provider without editing
  the F-184 dispatcher; sync vs async).
- Explore: #2885 internals (the shared transcript parse-once fix location + F-184 status).
