# Retrospective: Iteration 001

**Schema**: v1
**Iteration**: 001
**Feature**: 035-validator-iteration-parallelization
**Facilitated By**: Retro Facilitator (Alon Fliess via Claude as authoring agent)
**Retro Date**: 2026-05-22
**Baseline Ref**: branch start (off `main@9f2bd44`)
**Delivery Ref**: (this commit)

---

## Summary

Feature 035 / Proposal 084 (Validator Iteration Parallelization) Iteration 001 delivered the full proposal scope — `Invoke-WithFileLock` helper, file-locked `Set-ValidatorCacheEntry`, `-NoParallel` + `-ThrottleLimit` parameters, pre-pass + parallel-misses refactor of the iteration loop, and 12 integration tests. Empirical timing: 1 cache hit + 2 parallel misses at throttle 3 → 101s wall-clock; 3 cache hits warm → 15s. Linear cold→warm reduction matches design intent.

**Status**: Review-approved implementation delivered; retro complete.

---

## Estimation Accuracy

| Aspect | Planned | Actual | Variance | Notes |
| ------ | ------- | ------ | -------- | ----- |
| Proposal 084 parallelization slice | 7.0 SP | 7.0 SP | 0% | Estimate held; subprocess-with-shared-cache pattern (instead of in-process runspaces) avoided the ~50-helper refactor that would have blown the estimate. |

### Effort & Capacity

| Metric | Value | Notes |
| ------ | ----- | ----- |
| Planned Effort | 7.0 SP | Proposal 084 estimate |
| Actual Effort | 7.0 SP | On target |
| Variance | 0% | Within tolerance |
| Capacity Utilization | 35% of 20 SP | Well within capacity |

---

## Drift Summary

- Total drift events: 0
- Resolution rate: 100% (0/0 resolved)
- Specification drift: None detected

---

## What Went Well

### Subprocess-with-Shared-Cache Pattern Avoided Major Refactor

- In-process runspace parallelism (ForEach-Object -Parallel with $using:) would have required extracting Test-IterationGovernance + ~50 helper functions into a parallel-safe module. That was estimated at 15-25 SP additional work.
- The subprocess pattern (each parallel branch runs `pwsh -File validator -IterationPath X -NoParallel`) sidesteps the refactor entirely. Subprocesses inherit nothing from the parent; they validate one iteration and write to the shared file-locked cache. The parent re-reads cache for results.
- Trade-off: ~1-2s subprocess startup overhead per cache miss. For cold-cache 44-iteration runs at throttle 6, the math still yields ~5× speedup. Warm-cache runs use the serial pre-pass and pay zero subprocess overhead.

### Pre-Pass Cache Check Preserves Warm-Cache Performance

- Without the pre-pass, every iteration would pay subprocess overhead even on cache hits — making the parallel mode SLOWER than serial on the common warm-cache case. The pre-pass restores the F-034 cache-hit fast path: 0.1ms reads instead of 1-2s subprocess spawns.
- This composition was the key insight enabling 084 to compose cleanly with 086 P1 rather than competing with it.

### File Lock Helper Design

- `Invoke-WithFileLock` is a small, reusable primitive (FileShare::None + retry + finally-release). Tested independently. Reusable for any future "atomic JSON file mutation under concurrent writers" need (likely candidates: 086 P3 metadata cache, future cost-tracking ledger from Proposal 070).

---

## What Didn't Go Well

### Subprocess Startup Overhead Eats Into Parallel Win

- Each subprocess pays ~1-2s for PowerShell startup + dot-sourcing + validator prelude (team validation, scope inference, etc.) before reaching the single-iteration validation. For a 44-iteration cold-cache run at throttle 6, that's 44 × 1-2s = ~60-90s of pure overhead. The validation itself dominates only when individual iterations are slow.
- **Action**: When in-process runspace parallelism becomes worth the refactor effort (post-Proposal 086 P5 perhaps), revisit this. Until then, the subprocess approach remains pragmatic.

### Could Not Validate the 5× Speedup Claim Empirically in This Session

- The proposal claimed ~5× speedup on cold-cache 44-iteration runs. Running a full 44-iteration cold benchmark would have taken ~22 minutes serial just to establish baseline. Skipped for this iteration; the 3-iteration smoke run (1 hit + 2 parallel misses) demonstrated the mechanism works.
- **Action**: Post-merge, add a CI timing snapshot job that benchmarks parallel vs serial on a representative corpus and emits the ratio to release notes.

---

## Improvement Actions

| Action | Owner | When | Expected Effect |
| ------ | ----- | ---- | --------------- |
| Post-merge: benchmark full-repo validator parallel vs serial; record empirical speedup in release notes. | Future small-fix | Post-v0.24.3 stable | Empirical data backing the proposal's 5× claim. |
| When Proposal 086 P3 (metadata cache) ships, also wrap its writes in Invoke-WithFileLock so parallel subprocesses don't corrupt the metadata file. | Future feature | Per Proposal 086 roadmap | Same concurrency guarantee for the metadata layer. |
| When in-process runspace parallelism becomes feasible (post the helper-extraction refactor), measure subprocess-vs-runspace overhead to decide whether to upgrade. | Future feature | Post-Proposal 086 P5 | Lower overhead per iteration; possibly 2× additional win on top of current. |

---

## Process Notes

This iteration composes Proposal 084 directly on top of Proposal 086 P1 (memoization). The pre-pass cache check is the key composition point — without it, parallel mode would degrade warm-cache performance. The lesson: optimization layers must compose, not collide. When designing the next pillars of Proposal 086, the same principle holds — each pillar must preserve the others' fast paths.

---

## Metrics

| Metric | Value |
| ------ | ----- |
| Implementation Range | (this commit) |
| Drift Events | 0 |
| Test Pass Rate | 100% (12/12 new + 12/12 F-034 no regression) |
| Scope Adherence | 100% (all 11 FRs delivered) |
| Empirical Cold→Warm Ratio | 101s / 15s ≈ 6.7× on 3-iteration mixed run |
| Files Touched | 7 |

---

## Retro Sign-Off

**Closed By**: Retro Facilitator (Alon Fliess via Claude as authoring agent)
**Closed At**: 2026-05-22T09:15:00Z
**Iteration 001 Status**: **RETRO COMPLETE**

---

**Maintained by**: Retro Facilitator
**Next Action**: Iteration-closeout + feature-closeout + PR open + Copilot review + merge.
